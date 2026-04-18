/**
 * @description Utility module for queryBuilder component.
 *              Contains constants, factory functions, and validation logic.
 *
 * @author Mritesh
 * @date 2026-04-18
 * @version 2.0.0
 */

// Object options for the dropdown
export const OBJECT_OPTIONS = [
  { label: "Attachment", value: "Attachment" },
  { label: "Content Document", value: "ContentDocument" }
];

// Operator options with multi-value flags
export const OPERATOR_OPTIONS = [
  { label: "Equals", value: "=", requiresMultiValue: false },
  { label: "Not Equals", value: "!=", requiresMultiValue: false },
  { label: "Less Than", value: "<", requiresMultiValue: false },
  { label: "Less or Equal", value: "<=", requiresMultiValue: false },
  { label: "Greater Than", value: ">", requiresMultiValue: false },
  { label: "Greater or Equal", value: ">=", requiresMultiValue: false },
  { label: "Contains", value: "LIKE", requiresMultiValue: false },
  { label: "IN", value: "IN", requiresMultiValue: true },
  { label: "NOT IN", value: "NOT IN", requiresMultiValue: true },
  {
    label: "Includes (Multi-Select)",
    value: "INCLUDES",
    requiresMultiValue: true
  },
  {
    label: "Excludes (Multi-Select)",
    value: "EXCLUDES",
    requiresMultiValue: true
  }
];

export const MULTI_VALUE_OPERATORS = new Set([
  "IN",
  "NOT IN",
  "INCLUDES",
  "EXCLUDES"
]);
const MULTI_SELECT_OPERATORS = new Set(["INCLUDES", "EXCLUDES"]);

/**
 * @description Factory function to create a new empty filter with default values.
 * @returns {Object} New filter object.
 */
export const createNewFilter = () => {
  return {
    id: Date.now(),
    fieldName: "",
    operator: "=",
    value: "",
    requiresMultiValue: false,
    valueItems: [],
    currentInputValue: ""
  };
};

/**
 * @description Serializes pill values into backend-safe delimiter format.
 * @param {Array} valueItems Array of pill items.
 * @param {String} operator Active filter operator.
 * @returns {String} Serialized value payload.
 */
export const serializeMultiValueItems = (valueItems = [], operator = "") => {
  const serializedValues = Array.isArray(valueItems)
    ? valueItems
        .map((item) => {
          if (typeof item === "string") {
            return item.trim();
          }

          return String(item?.label ?? "").trim();
        })
        .filter((item) => item.length > 0)
    : [];

  const delimiter = MULTI_SELECT_OPERATORS.has(operator) ? ";" : ",";
  return serializedValues.join(delimiter);
};

/**
 * @description Validates query builder inputs for inline control-level feedback.
 * @param {Object} params Validation input parameters.
 * @param {String} params.selectedObject Selected object API name.
 * @param {Array} params.selectedFields Selected field API names.
 * @param {Array} params.filters Active filter definitions.
 * @returns {Object} Validation contract with field-level errors.
 */
export const validateFilterInputs = ({
  selectedObject,
  selectedFields,
  filters
}) => {
  const fieldErrors = {
    object: "",
    fields: "",
    filters: {}
  };

  if (!selectedObject || !selectedObject.trim()) {
    fieldErrors.object = "Select an object to query.";
  }

  if (!Array.isArray(selectedFields) || selectedFields.length === 0) {
    fieldErrors.fields = "Select at least one field.";
  }

  (filters || []).forEach((filter) => {
    const filterErrors = {
      fieldName: "",
      operator: "",
      value: "",
      pillContainerHasError: false,
      pillContainerErrorMessage: ""
    };

    if (!filter?.fieldName) {
      filterErrors.fieldName = "Select a field for this condition.";
    }

    if (!filter?.operator) {
      filterErrors.operator = "Select an operator for this condition.";
    }

    const isMultiValue =
      Boolean(filter?.requiresMultiValue) ||
      MULTI_VALUE_OPERATORS.has(filter?.operator);
    if (isMultiValue) {
      const serializedValues = serializeMultiValueItems(
        filter?.valueItems || [],
        filter?.operator
      );
      if (!serializedValues) {
        filterErrors.value =
          "Add at least one value for the selected operator.";
        filterErrors.pillContainerHasError = true;
        filterErrors.pillContainerErrorMessage =
          "Add at least one value for the selected operator.";
      }
    } else if (!String(filter?.value ?? "").trim()) {
      filterErrors.value = "Enter a value for this condition.";
    }

    if (
      filterErrors.fieldName ||
      filterErrors.operator ||
      filterErrors.value ||
      filterErrors.pillContainerHasError
    ) {
      fieldErrors.filters[filter.id] = filterErrors;
    }
  });

  const hasFilterErrors = Object.keys(fieldErrors.filters).length > 0;
  const hasErrors = Boolean(
    fieldErrors.object || fieldErrors.fields || hasFilterErrors
  );

  return {
    isValid: !hasErrors,
    fieldErrors,
    formErrorMessage: hasErrors
      ? "Please fix validation errors before running the query."
      : ""
  };
};
