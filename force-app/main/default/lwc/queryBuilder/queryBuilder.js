/**
 * @description Query builder component for dynamic SOQL queries.
 *              Enhanced with pill container UI for multi-value operators and field labels.
 *
 * @author Agent Mritesh
 * @date 2026-02-17
 * @version 1.3.0
 */
import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import executeQuery from "@salesforce/apex/QueryController.executeQuery";
import getObjectFieldOptions from "@salesforce/apex/QueryController.getObjectFieldOptions";

// Import from our Utility Module
import {
  OBJECT_OPTIONS,
  OPERATOR_OPTIONS,
  createNewFilter,
  serializeMultiValueItems,
  validateFilterInputs
} from "./queryUtils";

export default class QueryBuilder extends LightningElement {
  static EVENT_SOURCE = "queryBuilder";

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
  formErrorMessage = "";

  // --- Lifecycle ---
  connectedCallback() {
    this.fetchFields();
  }

  // --- Data Fetching ---
  async fetchFields() {
    this.isLoading = true;
    try {
      // Call the enhanced Apex method that returns {label, value} pairs
      const fieldOptions = await getObjectFieldOptions({
        objectName: this.selectedObject
      });

      // Options are already in {label, value} format for display
      this.fieldOptions = fieldOptions;

      // Reset selected fields and filters when object changes
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

  // --- User Actions ---
  handleObjectChange(event) {
    this.selectedObject = event.detail.value;
    this.formErrorMessage = "";
    this.applyControlValidity(event.target, "");
    this.fetchFields();
  }

  handleFieldChange(event) {
    // event.detail.value contains API names (value property)
    this.selectedFields = event.detail.value;
    this.formErrorMessage = "";
    this.applyControlValidity(event.target, "");
  }

  handleAddFilter() {
    // Delegate logic to Utility
    this.filters = [...this.filters, this.decorateFilter(createNewFilter())];
    this.formErrorMessage = "";
  }

  handleFilterChange(event) {
    const { id, name } = event.currentTarget.dataset;
    const value = event.detail.value;

    // Guard against malformed events
    const targetId = Number.parseInt(id, 10);
    if (!name || Number.isNaN(targetId)) {
      return;
    }

    // Update only the changed filter immutably
    const idx = this.filters.findIndex((f) => f.id === targetId);
    if (idx === -1) {
      return;
    }

    let updated = { ...this.filters[idx], [name]: value };

    // If operator changed, update requiresMultiValue flag
    if (name === "operator") {
      const operatorConfig = OPERATOR_OPTIONS.find((op) => op.value === value);
      updated.requiresMultiValue = operatorConfig?.requiresMultiValue || false;

      if (updated.requiresMultiValue) {
        // Initialize multi-value state
        const valueItems = Array.isArray(updated.valueItems)
          ? updated.valueItems
          : [];
        updated.valueItems = valueItems;
        updated.currentInputValue = updated.currentInputValue || "";
        updated.value = serializeMultiValueItems(valueItems, updated.operator);
      } else {
        // Single value operator: clear multi-value state
        updated.valueItems = [];
        updated.currentInputValue = "";
        updated.value = "";
      }
    }

    updated = this.decorateFilter(updated);
    this.formErrorMessage = "";
    this.applyControlValidity(event.target, "");

    this.filters = [
      ...this.filters.slice(0, idx),
      updated,
      ...this.filters.slice(idx + 1)
    ];
  }

  handleRemoveFilter(event) {
    const id = parseInt(event.currentTarget.dataset.id, 10);
    this.filters = this.filters.filter((f) => f.id !== id);
    this.formErrorMessage = "";
  }

  handleLimitChange(event) {
    this.limitValue = event.detail.value;
  }

  // --- Multi-Value Input Handlers (Pill Container) ---

  handleMultiValueInput(event) {
    const { id, name } = event.currentTarget.dataset;
    const value = event.detail.value;

    const targetId = Number.parseInt(id, 10);
    const idx = this.filters.findIndex((f) => f.id === targetId);
    if (idx === -1) {
      return;
    }

    const updated = this.decorateFilter({
      ...this.filters[idx],
      [name]: value,
      pillContainerHasError: false,
      pillContainerErrorMessage: "",
      valueErrorMessage: ""
    });

    this.formErrorMessage = "";
    this.applyControlValidity(event.target, "");

    this.filters = [
      ...this.filters.slice(0, idx),
      updated,
      ...this.filters.slice(idx + 1)
    ];
  }

  handleMultiValueKeyup(event) {
    if (event.key !== "Enter") {
      return;
    }

    event.preventDefault();

    const { id } = event.currentTarget.dataset;
    const targetId = Number.parseInt(id, 10);
    const idx = this.filters.findIndex((f) => f.id === targetId);
    if (idx === -1) {
      return;
    }

    const filter = this.filters[idx];
    const inputValue = filter.currentInputValue?.trim();
    if (!inputValue) {
      return;
    }

    const newPill = {
      label: inputValue,
      name: `pill-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
      type: "plain"
    };

    const valueItems = [...(filter.valueItems || []), newPill];
    const updated = this.decorateFilter({
      ...filter,
      valueItems,
      value: serializeMultiValueItems(valueItems, filter.operator),
      currentInputValue: "",
      pillContainerHasError: false,
      pillContainerErrorMessage: "",
      valueErrorMessage: ""
    });

    this.formErrorMessage = "";
    this.applyControlValidity(event.currentTarget, "");

    this.filters = [
      ...this.filters.slice(0, idx),
      updated,
      ...this.filters.slice(idx + 1)
    ];
  }

  handlePillRemove(event) {
    const { id } = event.currentTarget.dataset;
    const pillName = event.detail.item.name;

    const targetId = Number.parseInt(id, 10);
    const idx = this.filters.findIndex((f) => f.id === targetId);
    if (idx === -1) {
      return;
    }

    const filter = this.filters[idx];
    const valueItems = filter.valueItems.filter(
      (item) => item.name !== pillName
    );
    const updated = this.decorateFilter({
      ...filter,
      valueItems,
      value: serializeMultiValueItems(valueItems, filter.operator),
      pillContainerHasError: false,
      pillContainerErrorMessage: "",
      valueErrorMessage: ""
    });

    this.formErrorMessage = "";

    this.filters = [
      ...this.filters.slice(0, idx),
      updated,
      ...this.filters.slice(idx + 1)
    ];
  }

  // --- Query Execution ---

  async handleRunQuery() {
    // 1. Delegate Validation to Utility
    const validation = validateFilterInputs({
      selectedObject: this.selectedObject,
      selectedFields: this.selectedFields,
      filters: this.filters
    });
    this.applyValidationFeedback(validation);
    if (!validation.isValid) {
      return;
    }

    const apexFilters = this.buildApexFilters();

    const requestId = this.generateRequestId();
    this.dispatchLifecycleEvent(requestId, "querystart", {
      objectType: this.selectedObject,
      fields: this.selectedFields
    });

    this.isLoading = true;
    try {
      // 2. Call API
      const results = await executeQuery({
        objectName: this.selectedObject,
        fields: this.selectedFields,
        filters: apexFilters,
        limitValue: this.limitValue
      });

      // 3. Dispatch success payload through lifecycle event contract
      this.dispatchLifecycleEvent(requestId, "querysuccess", {
        objectType: this.selectedObject,
        fields: this.selectedFields,
        fieldLabels: this.buildFieldLabels(),
        records: Array.isArray(results) ? results : [],
        recordCount: Array.isArray(results) ? results.length : 0,
        fieldTypeMap: undefined
      });

      this.showToast("Success", `Found ${results.length} records`, "success");
    } catch (error) {
      this.dispatchLifecycleEvent(requestId, "queryerror", {
        errorCode: "QUERY_EXECUTION_ERROR",
        errorMessage: this.getErrorMessage(error),
        userSafeMessage:
          "Unable to run query right now. Please review inputs and try again."
      });

      this.showToast("Error", this.getErrorMessage(error), "error");
    } finally {
      this.isLoading = false;
    }
  }

  dispatchLifecycleEvent(requestId, eventType, eventPayload = {}) {
    this.dispatchEvent(
      new CustomEvent(eventType, {
        detail: {
          requestId,
          timestamp: new Date().toISOString(),
          source: QueryBuilder.EVENT_SOURCE,
          eventType,
          ...eventPayload
        }
      })
    );
  }

  buildApexFilters() {
    return this.filters.map((filter) => ({
      fieldName: filter.fieldName,
      operator: filter.operator,
      value: filter.requiresMultiValue
        ? serializeMultiValueItems(filter.valueItems || [], filter.operator)
        : String(filter.value ?? "").trim()
    }));
  }

  /**
   * @description Applies inline validity and filter-level wrapper errors.
   * @param {Object} validation Validation result from queryUtils.
   * @returns {void}
   */
  applyValidationFeedback(validation) {
    const fieldErrors = validation?.fieldErrors || {};
    const filterErrors = fieldErrors.filters || {};

    this.formErrorMessage = validation?.formErrorMessage || "";

    this.applyControlValidity(
      this.template.querySelector('[data-control="object-selector"]'),
      fieldErrors.object
    );
    this.applyControlValidity(
      this.template.querySelector('[data-control="field-selector"]'),
      fieldErrors.fields
    );

    this.filters = this.filters.map((filter) =>
      this.decorateFilter(filter, filterErrors[filter.id])
    );

    Promise.resolve().then(() => {
      this.filters.forEach((filter) => {
        const currentFilterErrors = filterErrors[filter.id] || {};
        this.applyControlValidity(
          this.template.querySelector(
            `[data-control="filter-field"][data-id="${filter.id}"]`
          ),
          currentFilterErrors.fieldName
        );
        this.applyControlValidity(
          this.template.querySelector(
            `[data-control="filter-operator"][data-id="${filter.id}"]`
          ),
          currentFilterErrors.operator
        );

        const valueSelector = filter.requiresMultiValue
          ? `[data-control="filter-multivalue-input"][data-id="${filter.id}"]`
          : `[data-control="filter-value"][data-id="${filter.id}"]`;

        this.applyControlValidity(
          this.template.querySelector(valueSelector),
          currentFilterErrors.value
        );
      });
    });
  }

  decorateFilter(filter, filterErrors = {}) {
    const pillContainerHasError = Boolean(filterErrors.pillContainerHasError);
    return {
      ...filter,
      valueItems: Array.isArray(filter.valueItems) ? filter.valueItems : [],
      currentInputValue: filter.currentInputValue || "",
      fieldErrorMessage: filterErrors.fieldName || "",
      operatorErrorMessage: filterErrors.operator || "",
      valueErrorMessage: filterErrors.value || "",
      pillContainerHasError,
      pillContainerErrorMessage: filterErrors.pillContainerErrorMessage || "",
      pillErrorHelpId: `pill-error-${filter.id}`,
      multiValueFormElementClass: pillContainerHasError
        ? "slds-form-element slds-has-error"
        : "slds-form-element"
    };
  }

  applyControlValidity(control, message = "") {
    if (!control || typeof control.setCustomValidity !== "function") {
      return;
    }

    control.setCustomValidity(message || "");
    if (typeof control.reportValidity === "function") {
      control.reportValidity();
    }
  }

  buildFieldLabels() {
    const labels = {};
    this.selectedFields.forEach((apiName) => {
      const option = this.fieldOptions.find(
        (fieldOption) => fieldOption.value === apiName
      );
      labels[apiName] = option ? option.label : apiName;
    });
    return labels;
  }

  generateRequestId() {
    return `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
  }

  getErrorMessage(error) {
    return error?.body?.message || error?.message || "Unexpected query error.";
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
