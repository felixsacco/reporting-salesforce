/**
 * @description Query builder component for dynamic SOQL queries.
 *              Enhanced with pill container UI for multi-value operators and field labels.
 * 
 * @author Agent Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */
import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import executeQuery from "@salesforce/apex/AttachmentQueryController.executeQuery";
import getObjectFieldOptions from "@salesforce/apex/AttachmentQueryController.getObjectFieldOptions";

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
    this.fetchFields();
  }

  handleFieldChange(event) {
    // event.detail.value contains API names (value property)
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

    // Update only the changed filter immutably
    const idx = this.filters.findIndex((f) => f.id === targetId);
    if (idx === -1) {
      return;
    }

    let updated = { ...this.filters[idx], [name]: value };
    
    // If operator changed, update requiresMultiValue flag
    if (name === 'operator') {
      const operatorConfig = OPERATOR_OPTIONS.find(op => op.value === value);
      updated.requiresMultiValue = operatorConfig?.requiresMultiValue || false;
      
      if (updated.requiresMultiValue) {
        // Initialize multi-value state
        updated.valueItems = [];
        updated.currentInputValue = '';
        updated.value = '';
      } else {
        // Single value operator: clear multi-value state
        updated.valueItems = undefined;
        updated.currentInputValue = undefined;
      }
    }

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

  // --- Multi-Value Input Handlers (Pill Container) ---

  handleMultiValueInput(event) {
    const { id, name } = event.currentTarget.dataset;
    const value = event.detail.value;
    
    const targetId = Number.parseInt(id, 10);
    const idx = this.filters.findIndex((f) => f.id === targetId);
    if (idx === -1) return;
    
    const updated = { ...this.filters[idx], [name]: value };
    this.filters = [
      ...this.filters.slice(0, idx),
      updated,
      ...this.filters.slice(idx + 1)
    ];
  }

  handleMultiValueKeyup(event) {
    if (event.key === 'Enter') {
      const { id } = event.currentTarget.dataset;
      const targetId = Number.parseInt(id, 10);
      const idx = this.filters.findIndex((f) => f.id === targetId);
      if (idx === -1) return;
      
      const filter = this.filters[idx];
      const inputValue = filter.currentInputValue?.trim();
      
      if (inputValue) {
        // Add pill
        const newPill = {
          label: inputValue,
          name: `pill-${Date.now()}`,
          type: 'plain'
        };
        
        const valueItems = [...(filter.valueItems || []), newPill];
        
        // Build comma-separated value string for backend
        const value = valueItems.map(item => item.label).join(',');
        
        const updated = {
          ...filter,
          valueItems: valueItems,
          value: value,
          currentInputValue: ''
        };
        
        this.filters = [
          ...this.filters.slice(0, idx),
          updated,
          ...this.filters.slice(idx + 1)
        ];
      }
    }
  }

  handlePillRemove(event) {
    const { id } = event.currentTarget.dataset;
    const pillName = event.detail.item.name;
    
    const targetId = Number.parseInt(id, 10);
    const idx = this.filters.findIndex((f) => f.id === targetId);
    if (idx === -1) return;
    
    const filter = this.filters[idx];
    const valueItems = filter.valueItems.filter(item => item.name !== pillName);
    const value = valueItems.map(item => item.label).join(',');
    
    const updated = {
      ...filter,
      valueItems: valueItems,
      value: value
    };
    
    this.filters = [
      ...this.filters.slice(0, idx),
      updated,
      ...this.filters.slice(idx + 1)
    ];
  }

  // --- Query Execution ---

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

      // 3. Build fieldLabels map from fieldOptions
      const fieldLabels = {};
      this.selectedFields.forEach(apiName => {
        const option = this.fieldOptions.find(opt => opt.value === apiName);
        fieldLabels[apiName] = option ? option.label : apiName;
      });

      // 4. Dispatch Success with field labels
      this.dispatchEvent(
        new CustomEvent('queryresults', {
          detail: {
            results: results,
            fields: this.selectedFields,
            objectType: this.selectedObject,
            fieldLabels: fieldLabels
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