import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import executeQuery from "@salesforce/apex/AttachmentQueryController.executeQuery";
import getObjectFields from "@salesforce/apex/AttachmentQueryController.getObjectFields";

// Import from our Utility Module
import {
  OBJECT_OPTIONS,
  OPERATOR_OPTIONS,
  createNewFilter,
  validateRequest
} from "./queryUtils";

export default class QueryBuilder extends LightningElement {
  // Constants from Utils
  objectOptions = OBJECT_OPTIONS;
  operatorOptions = OPERATOR_OPTIONS;

  // State
  selectedObject = "Attachment";
  selectedFields = [];
  filters = [];
  limitValue = 50;
  fieldOptions = [];
  isLoading = false;

  // --- Lifecycle ---
  connectedCallback() {
    this.fetchFields();
  }

  // --- Data Fetching ---
  async fetchFields() {
    this.isLoading = true;
    try {
      // 1. Call the secure Apex method
      const fields = await getObjectFields({ objectName: this.selectedObject });

      // 2. Map the results into LWC dual-listbox/combobox format
      this.fieldOptions = fields.map((f) => ({
        label: f,
        value: f
      }));

      // Reset selected fields if they no longer exist on the new object
      this.selectedFields = [];
      this.filters = [];
    } catch (error) {
      this.showToast(
        "Error",
        "Could not load fields: " + (error.body?.message || error.message),
        "error"
      );
    } finally {
      this.isLoading = false;
    }
  }

  // --- User Actions (Revised handler for object change) ---
  handleObjectChange(event) {
    this.selectedObject = event.detail.value;
    this.fetchFields(); // Call the now-implemented fetchFields method
  }

  // --- User Actions ---
  handleFieldChange(event) {
    this.selectedFields = event.detail.value;
  }

  handleAddFilter() {
    // Delegate logic to Utility
    this.filters = [...this.filters, createNewFilter()];
  }

  handleFilterChange(event) {
    const { id, name } = event.currentTarget.dataset;
    const value = event.detail.value;

    // Guard against malformed events
    const targetId = Number.parseInt(id, 10);
    if (!name || Number.isNaN(targetId)) {
      return;
    }

    // Update only the changed filter immutably; keep others as-is
    const idx = this.filters.findIndex((f) => f.id === targetId);
    if (idx === -1) {
      return;
    }

    const updated = { ...this.filters[idx], [name]: value };
    // Reconstruct array with a single element replaced to preserve reactivity and avoid O(n) object cloning
    this.filters = [
      ...this.filters.slice(0, idx),
      updated,
      ...this.filters.slice(idx + 1)
    ];
  }

  handleRemoveFilter(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10);
    this.filters = this.filters.filter((f) => f.id !== id);
  }

  handleLimitChange(event) {
    this.limitValue = event.detail.value;
  }

  async handleRunQuery() {
    // 1. Delegate Validation to Utility
    const validation = validateRequest(this.selectedFields, this.filters);
    if (!validation.isValid) {
      this.showToast("Error", validation.errorMessage, "error");
      return;
    }

    this.isLoading = true;
    try {
      // 2. Call API
      const results = await executeQuery({
        objectName: this.selectedObject,
        fields: this.selectedFields,
        filters: this.filters,
        limitValue: this.limitValue
      });

      // 3. Dispatch Success
      this.dispatchEvent(
        new CustomEvent("queryresults", {
          detail: {
            results: results,
            fields: this.selectedFields,
            objectType: this.selectedObject
          }
        })
      );

      this.showToast("Success", `Found ${results.length} records`, "success");
    } catch (error) {
      this.showToast("Error", error.body?.message || error.message, "error");
    } finally {
      this.isLoading = false;
    }
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
