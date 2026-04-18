import { createElement } from "lwc";
import QueryBuilder from "c/queryBuilder";
import getObjectFieldOptions from "@salesforce/apex/QueryController.getObjectFieldOptions";
import executeQuery from "@salesforce/apex/QueryController.executeQuery";

// Mock Apex Calls
jest.mock(
  "@salesforce/apex/QueryController.getObjectFieldOptions",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/QueryController.executeQuery",
  () => {
    return {
      default: jest.fn()
    };
  },
  { virtual: true }
);

const MOCK_FIELDS = ["Id", "Name", "BodyLength"];
const MOCK_RESULTS = [{ Id: "00P000000000001", Name: "Test File" }];
const flushPromises = () => Promise.resolve();

describe("c-query-builder", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  it("loads fields on initialization", async () => {
    // Assign mock value for resolved promise
    getObjectFieldOptions.mockResolvedValue(
      MOCK_FIELDS.map((fieldName) => ({ label: fieldName, value: fieldName }))
    );

    const element = createElement("c-query-builder", {
      is: QueryBuilder
    });
    document.body.appendChild(element);

    // Wait for connectedCallback + fetchFields async updates
    await flushPromises();
    await flushPromises();

    // Verify Apex was called
    expect(getObjectFieldOptions).toHaveBeenCalledWith({
      objectName: "Attachment"
    });

    // Verify fields are populated in dual listbox
    const listbox = element.shadowRoot.querySelector("lightning-dual-listbox");
    expect(listbox.options.length).toBe(3);
  });

  it("dispatches querystart and querysuccess with event contract payload", async () => {
    getObjectFieldOptions.mockResolvedValue(
      MOCK_FIELDS.map((fieldName) => ({ label: fieldName, value: fieldName }))
    );
    executeQuery.mockResolvedValue(MOCK_RESULTS);

    const element = createElement("c-query-builder", {
      is: QueryBuilder
    });

    const startHandler = jest.fn();
    const successHandler = jest.fn();
    element.addEventListener("querystart", startHandler);
    element.addEventListener("querysuccess", successHandler);

    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const listbox = element.shadowRoot.querySelector("lightning-dual-listbox");
    listbox.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: ["Name"] }
      })
    );

    const executeButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Execute Query");
    expect(executeButton).toBeDefined();
    executeButton.click();

    await flushPromises();
    await flushPromises();

    expect(executeQuery).toHaveBeenCalledWith({
      objectName: "Attachment",
      fields: ["Name"],
      filters: [],
      limitValue: 50
    });

    expect(startHandler).toHaveBeenCalledTimes(1);
    expect(successHandler).toHaveBeenCalledTimes(1);

    const startDetail = startHandler.mock.calls[0][0].detail;
    const successDetail = successHandler.mock.calls[0][0].detail;

    expect(startDetail.eventType).toBe("querystart");
    expect(startDetail.source).toBe("queryBuilder");
    expect(typeof startDetail.requestId).toBe("string");
    expect(typeof startDetail.timestamp).toBe("string");

    expect(successDetail.eventType).toBe("querysuccess");
    expect(successDetail.source).toBe("queryBuilder");
    expect(successDetail.requestId).toBe(startDetail.requestId);
    expect(successDetail.objectType).toBe("Attachment");
    expect(successDetail.fields).toEqual(["Name"]);
    expect(successDetail.fieldLabels).toEqual({ Name: "Name" });
    expect(successDetail.records).toEqual(MOCK_RESULTS);
    expect(successDetail.recordCount).toBe(1);
  });

  it("dispatches queryerror with error contract payload", async () => {
    getObjectFieldOptions.mockResolvedValue(
      MOCK_FIELDS.map((fieldName) => ({ label: fieldName, value: fieldName }))
    );
    executeQuery.mockRejectedValue({ body: { message: "SOQL parser error" } });

    const element = createElement("c-query-builder", {
      is: QueryBuilder
    });

    const startHandler = jest.fn();
    const errorHandler = jest.fn();
    element.addEventListener("querystart", startHandler);
    element.addEventListener("queryerror", errorHandler);

    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const listbox = element.shadowRoot.querySelector("lightning-dual-listbox");
    listbox.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: ["Name"] }
      })
    );

    const executeButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Execute Query");
    expect(executeButton).toBeDefined();
    executeButton.click();

    await flushPromises();
    await flushPromises();

    expect(startHandler).toHaveBeenCalledTimes(1);
    expect(errorHandler).toHaveBeenCalledTimes(1);

    const startDetail = startHandler.mock.calls[0][0].detail;
    const errorDetail = errorHandler.mock.calls[0][0].detail;

    expect(errorDetail.eventType).toBe("queryerror");
    expect(errorDetail.source).toBe("queryBuilder");
    expect(errorDetail.requestId).toBe(startDetail.requestId);
    expect(errorDetail.errorCode).toBe("QUERY_EXECUTION_ERROR");
    expect(errorDetail.errorMessage).toBe("SOQL parser error");
    expect(errorDetail.userSafeMessage).toBe(
      "Unable to run query right now. Please review inputs and try again."
    );
  });

  it("blocks lifecycle dispatch and Apex call when validation fails", async () => {
    getObjectFieldOptions.mockResolvedValue(
      MOCK_FIELDS.map((fieldName) => ({ label: fieldName, value: fieldName }))
    );

    const element = createElement("c-query-builder", {
      is: QueryBuilder
    });

    const startHandler = jest.fn();
    element.addEventListener("querystart", startHandler);

    document.body.appendChild(element);

    await flushPromises();
    await flushPromises();

    const executeButton = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    ).find((button) => button.label === "Execute Query");
    expect(executeButton).toBeDefined();
    executeButton.click();

    await flushPromises();

    expect(startHandler).not.toHaveBeenCalled();
    expect(executeQuery).not.toHaveBeenCalled();
  });
});
