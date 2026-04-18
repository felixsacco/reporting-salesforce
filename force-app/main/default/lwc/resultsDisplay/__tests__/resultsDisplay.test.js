import { createElement } from "lwc";
import ResultsDisplay from "c/resultsDisplay";

const flushPromises = () => Promise.resolve();

const buildRecords = (count) =>
  Array.from({ length: count }, (_, index) => ({
    Id: `00P0000000000${String(index + 1).padStart(3, "0")}`,
    Name: `File ${index + 1}`,
    BodyLength: index + 1
  }));

const buildResultsState = (records, overrides = {}) => ({
  objectType: "Attachment",
  fields: ["Name", "BodyLength"],
  fieldLabels: { Name: "Name", BodyLength: "Body Length" },
  records,
  recordCount: records.length,
  fieldTypeMap: {},
  ...overrides
});

describe("c-results-display", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    jest.clearAllMocks();
  });

  it("renders loading state", async () => {
    const element = createElement("c-results-display", {
      is: ResultsDisplay
    });
    element.isLoading = true;
    document.body.appendChild(element);

    await flushPromises();

    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });

  it("renders error banner and empty state when no results exist", async () => {
    const element = createElement("c-results-display", {
      is: ResultsDisplay
    });
    element.errorState = {
      errorCode: "QUERY_EXECUTION_ERROR",
      errorMessage: "Server timeout",
      userSafeMessage: "Unable to run query right now."
    };

    document.body.appendChild(element);

    await flushPromises();

    const errorAlert = element.shadowRoot.querySelector('[role="alert"]');
    expect(errorAlert).not.toBeNull();
    expect(errorAlert.textContent).toContain("Unable to run query right now.");

    const noResultsMsg = element.shadowRoot.querySelector(
      ".slds-text-align_center"
    );
    expect(noResultsMsg).not.toBeNull();
  });

  it("paginates rows and enforces boundary-safe navigation", async () => {
    const element = createElement("c-results-display", {
      is: ResultsDisplay
    });
    element.resultsState = buildResultsState(buildRecords(120));
    document.body.appendChild(element);

    await flushPromises();

    let datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable).not.toBeNull();
    expect(datatable.data.length).toBe(50);
    expect(datatable.data[0].Name).toBe("File 1");

    const buttons = Array.from(
      element.shadowRoot.querySelectorAll("lightning-button")
    );
    const nextButton = buttons.find((button) => button.label === "Next");
    expect(nextButton).toBeDefined();
    nextButton.click();
    await flushPromises();

    datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable.data.length).toBe(50);
    expect(datatable.data[0].Name).toBe("File 51");

    nextButton.click();
    await flushPromises();

    datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable.data.length).toBe(20);
    expect(datatable.data[0].Name).toBe("File 101");

    nextButton.click();
    await flushPromises();

    datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable.data.length).toBe(20);
    expect(datatable.data[0].Name).toBe("File 101");

    const previousButton = buttons.find(
      (button) => button.label === "Previous"
    );
    expect(previousButton).toBeDefined();
    previousButton.click();
    await flushPromises();

    datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable.data.length).toBe(50);
    expect(datatable.data[0].Name).toBe("File 51");
  });

  it("creates collision-safe synthetic URL keys without overwriting source fields", async () => {
    const element = createElement("c-results-display", {
      is: ResultsDisplay
    });

    element.resultsState = buildResultsState(
      [
        {
          Id: "00P000000000001",
          Name: "Quarterly Report",
          __url_Name: "existing-url-value",
          __url_Id: "existing-id-url"
        }
      ],
      {
        fields: ["Name", "Id"],
        fieldLabels: { Name: "Name", Id: "Record ID" }
      }
    );

    document.body.appendChild(element);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    const nameColumn = datatable.columns.find(
      (column) => column.typeAttributes?.label?.fieldName === "Name"
    );
    const idColumn = datatable.columns.find(
      (column) => column.typeAttributes?.label?.fieldName === "Id"
    );

    expect(nameColumn).toBeDefined();
    expect(idColumn).toBeDefined();
    expect(nameColumn.type).toBe("url");
    expect(idColumn.type).toBe("url");
    expect(nameColumn.fieldName).toMatch(/^__url_Name(_\d+)?$/);
    expect(nameColumn.fieldName).not.toBe("__url_Name");
    expect(idColumn.fieldName).toMatch(/^__url_Id(_\d+)?$/);
    expect(idColumn.fieldName).not.toBe("__url_Id");

    const firstRow = datatable.data[0];
    expect(firstRow.__url_Name).toBe("existing-url-value");
    expect(firstRow.__url_Id).toBe("existing-id-url");
    expect(firstRow[nameColumn.fieldName]).toBe("/00P000000000001");
    expect(firstRow[idColumn.fieldName]).toBe("/00P000000000001");
  });

  it("falls back to text type for unknown field type metadata", async () => {
    const element = createElement("c-results-display", {
      is: ResultsDisplay
    });

    element.resultsState = {
      objectType: "Attachment",
      fields: ["MysteryField"],
      fieldLabels: { MysteryField: "Mystery" },
      records: [{ MysteryField: "Some Value" }],
      recordCount: 1,
      fieldTypeMap: { MysteryField: "CUSTOM_UNMAPPED_TYPE" }
    };

    document.body.appendChild(element);
    await flushPromises();

    const datatable = element.shadowRoot.querySelector("lightning-datatable");
    expect(datatable.columns[0].type).toBe("text");
  });
});
