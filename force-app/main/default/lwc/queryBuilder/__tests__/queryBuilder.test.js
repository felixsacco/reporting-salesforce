import { createElement } from "@lwc/engine-dom";
import QueryBuilder from "c/queryBuilder";
import getObjectFieldOptions from "@salesforce/apex/QueryController.getObjectFieldOptions";
// import executeQuery from '@salesforce/apex/QueryController.executeQuery';

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
// const MOCK_RESULTS = [{ Id: '001', Name: 'Test File' }];

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

    // Wait for async connectedCallback
    await Promise.resolve();
    await Promise.resolve();

    // Verify Apex was called
    expect(getObjectFieldOptions).toHaveBeenCalled();

    // Verify fields are populated in dual listbox
    const listbox = element.shadowRoot.querySelector("lightning-dual-listbox");
    expect(listbox.options.length).toBe(3);
  });

  // it('executes query when button clicked', async () => {
  //     getObjectFieldOptions.mockResolvedValue(MOCK_FIELDS.map((fieldName) => ({ label: fieldName, value: fieldName })));
  //     executeQuery.mockResolvedValue(MOCK_RESULTS);

  //     const element = createElement('c-query-builder', {
  //         is: QueryBuilder
  //     });
  //     document.body.appendChild(element);

  //     // Wait for init
  //     await Promise.resolve();

  //     // Simulate user selecting fields
  //     const listbox = element.shadowRoot.querySelector('lightning-dual-listbox');
  //     listbox.value = ['Name'];
  //     listbox.dispatchEvent(new CustomEvent('change', { detail: { value: ['Name'] } }));

  //     // Simulate click execute
  //     const btn = element.shadowRoot.querySelector('lightning-button[label="Execute Query"]');
  //     btn.click();

  //     // Verify Apex was called
  //     expect(executeQuery).toHaveBeenCalled();

  //     // Verify event dispatch
  //     // Note: verifying custom events in Jest requires attaching a listener or spying on dispatchEvent
  // });
});
