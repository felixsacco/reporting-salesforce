import { createElement } from "lwc";
import ReportsOnFiles from "c/reportsOnFiles";

const flushPromises = () => Promise.resolve();

const makeLifecycleDetail = (requestId, overrides = {}) => ({
  requestId,
  timestamp: "2026-04-18T00:00:00.000Z",
  source: "queryBuilder",
  eventType: "querysuccess",
  objectType: "Attachment",
  fields: ["Id", "Name"],
  fieldLabels: { Id: "Record ID", Name: "Name" },
  records: [{ Id: "00P000000000001", Name: "Sample Attachment" }],
  recordCount: 1,
  ...overrides
});

describe("c-reports-on-files", () => {
  afterEach(() => {
    // The jsdom instance is shared across test cases in a single file so reset the DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }

    jest.clearAllMocks();
  });

  it("binds declarative lifecycle events from queryBuilder", async () => {
    const element = createElement("c-reports-on-files", {
      is: ReportsOnFiles
    });
    document.body.appendChild(element);

    const queryBuilder = element.shadowRoot.querySelector("c-query-builder");
    const resultsDisplay =
      element.shadowRoot.querySelector("c-results-display");
    expect(queryBuilder).not.toBeNull();
    expect(resultsDisplay).not.toBeNull();

    queryBuilder.dispatchEvent(
      new CustomEvent("querystart", {
        detail: {
          requestId: "req-1",
          timestamp: "2026-04-18T00:00:00.000Z",
          source: "queryBuilder",
          eventType: "querystart"
        }
      })
    );

    await flushPromises();

    expect(resultsDisplay.isLoading).toBe(true);
    expect(resultsDisplay.errorState).toBeNull();
  });

  it("applies success state only when requestId matches latestRequestId", async () => {
    const element = createElement("c-reports-on-files", {
      is: ReportsOnFiles
    });
    document.body.appendChild(element);

    const queryBuilder = element.shadowRoot.querySelector("c-query-builder");
    const resultsDisplay =
      element.shadowRoot.querySelector("c-results-display");

    queryBuilder.dispatchEvent(
      new CustomEvent("querystart", {
        detail: {
          requestId: "req-1",
          timestamp: "2026-04-18T00:00:00.000Z",
          source: "queryBuilder",
          eventType: "querystart"
        }
      })
    );
    queryBuilder.dispatchEvent(
      new CustomEvent("querystart", {
        detail: {
          requestId: "req-2",
          timestamp: "2026-04-18T00:00:01.000Z",
          source: "queryBuilder",
          eventType: "querystart"
        }
      })
    );

    queryBuilder.dispatchEvent(
      new CustomEvent("querysuccess", {
        detail: makeLifecycleDetail("req-1")
      })
    );

    await flushPromises();

    expect(resultsDisplay.resultsState).toBeNull();
    expect(resultsDisplay.isLoading).toBe(true);

    queryBuilder.dispatchEvent(
      new CustomEvent("querysuccess", {
        detail: makeLifecycleDetail("req-2")
      })
    );

    await flushPromises();

    expect(resultsDisplay.resultsState).not.toBeNull();
    expect(resultsDisplay.resultsState.recordCount).toBe(1);
    expect(resultsDisplay.isLoading).toBe(false);
    expect(resultsDisplay.errorState).toBeNull();
  });

  it("retains prior results and sets errorState when latest request fails", async () => {
    const element = createElement("c-reports-on-files", {
      is: ReportsOnFiles
    });
    document.body.appendChild(element);

    const queryBuilder = element.shadowRoot.querySelector("c-query-builder");
    const resultsDisplay =
      element.shadowRoot.querySelector("c-results-display");

    queryBuilder.dispatchEvent(
      new CustomEvent("querystart", {
        detail: {
          requestId: "req-1",
          timestamp: "2026-04-18T00:00:00.000Z",
          source: "queryBuilder",
          eventType: "querystart"
        }
      })
    );

    queryBuilder.dispatchEvent(
      new CustomEvent("querysuccess", {
        detail: makeLifecycleDetail("req-1")
      })
    );

    await flushPromises();

    const baselineResults = resultsDisplay.resultsState;
    expect(baselineResults).not.toBeNull();

    queryBuilder.dispatchEvent(
      new CustomEvent("querystart", {
        detail: {
          requestId: "req-2",
          timestamp: "2026-04-18T00:00:01.000Z",
          source: "queryBuilder",
          eventType: "querystart"
        }
      })
    );

    queryBuilder.dispatchEvent(
      new CustomEvent("queryerror", {
        detail: {
          requestId: "req-2",
          timestamp: "2026-04-18T00:00:02.000Z",
          source: "queryBuilder",
          eventType: "queryerror",
          errorCode: "QUERY_EXECUTION_ERROR",
          errorMessage: "Server timeout",
          userSafeMessage: "Unable to run query right now."
        }
      })
    );

    await flushPromises();

    expect(resultsDisplay.resultsState).toEqual(baselineResults);
    expect(resultsDisplay.errorState).toEqual({
      errorCode: "QUERY_EXECUTION_ERROR",
      errorMessage: "Server timeout",
      userSafeMessage: "Unable to run query right now."
    });
    expect(resultsDisplay.isLoading).toBe(false);
  });

  it("captures error when no prior results exist", async () => {
    const element = createElement("c-reports-on-files", {
      is: ReportsOnFiles
    });
    document.body.appendChild(element);

    const queryBuilder = element.shadowRoot.querySelector("c-query-builder");
    const resultsDisplay =
      element.shadowRoot.querySelector("c-results-display");

    queryBuilder.dispatchEvent(
      new CustomEvent("querystart", {
        detail: {
          requestId: "req-1",
          timestamp: "2026-04-18T00:00:00.000Z",
          source: "queryBuilder",
          eventType: "querystart"
        }
      })
    );

    queryBuilder.dispatchEvent(
      new CustomEvent("queryerror", {
        detail: {
          requestId: "req-1",
          timestamp: "2026-04-18T00:00:02.000Z",
          source: "queryBuilder",
          eventType: "queryerror",
          errorCode: "QUERY_EXECUTION_ERROR",
          errorMessage: "SOQL parse error",
          userSafeMessage: "Please review your query filters and try again."
        }
      })
    );

    await flushPromises();

    expect(resultsDisplay.resultsState).toBeNull();
    expect(resultsDisplay.errorState).not.toBeNull();
    expect(resultsDisplay.errorState.errorCode).toBe("QUERY_EXECUTION_ERROR");
    expect(resultsDisplay.isLoading).toBe(false);
  });
});
