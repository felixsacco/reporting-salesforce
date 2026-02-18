/**
 * @description Utility module for queryBuilder component.
 *              Contains constants, factory functions, and validation logic.
 * 
 * @author Agent Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */

// Object options for the dropdown
export const OBJECT_OPTIONS = [
    { label: 'Attachment', value: 'Attachment' },
    { label: 'ContentDocument', value: 'ContentDocument' }
];

// Operator options with multi-value flags
export const OPERATOR_OPTIONS = [
    { label: 'Equals (=)', value: '=', requiresMultiValue: false },
    { label: 'Not Equals (!=)', value: '!=', requiresMultiValue: false },
    { label: 'Less Than (<)', value: '<', requiresMultiValue: false },
    { label: 'Less or Equal (<=)', value: '<=', requiresMultiValue: false },
    { label: 'Greater Than (>)', value: '>', requiresMultiValue: false },
    { label: 'Greater or Equal (>=)', value: '>=', requiresMultiValue: false },
    { label: 'Contains (LIKE)', value: 'LIKE', requiresMultiValue: false },
    { label: 'In List (IN)', value: 'IN', requiresMultiValue: true },
    { label: 'Not In List (NOT IN)', value: 'NOT IN', requiresMultiValue: true },
    { label: 'Includes (Multi-Select)', value: 'INCLUDES', requiresMultiValue: true },
    { label: 'Excludes (Multi-Select)', value: 'EXCLUDES', requiresMultiValue: true }
];

/**
 * Factory function to create a new empty filter with default values
 * @returns {Object} New filter object
 */
export const createNewFilter = () => {
    return {
        id: Date.now(),
        fieldName: '',
        operator: '=',
        value: '',
        requiresMultiValue: false,
        valueItems: [],
        currentInputValue: ''
    };
};

/**
 * Helper to validate the request before sending to server
 * @param {Array} fields - Selected field API names
 * @param {Array} filters - Filter conditions
 * @returns {Object} Validation result with isValid flag and errorMessage
 */
export const validateRequest = (fields, filters) => {
    const errors = [];
    
    if (!fields || fields.length === 0) {
        errors.push('Select at least one field.');
    }
    
    // Validate each filter
    for (const filter of filters) {
        if (!filter.fieldName) {
            errors.push('All filters must have a field selected.');
            break;
        }
        if (!filter.operator) {
            errors.push('All filters must have an operator selected.');
            break;
        }
        
        // Check multi-value operators have values
        if (filter.requiresMultiValue) {
            if (!filter.valueItems || filter.valueItems.length === 0) {
                errors.push(`${filter.operator} operator requires at least one value.`);
                break;
            }
        } else {
            // Single value operators
            if (!filter.value || filter.value.trim() === '') {
                errors.push('All filters must have a value.');
                break;
            }
        }
    }
    
    return {
        isValid: errors.length === 0,
        errorMessage: errors.join(' ')
    };
};