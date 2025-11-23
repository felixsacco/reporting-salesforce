// Storing options for filter and validating the filter

export const OBJECT_OPTIONS = [
    { label: 'Attachment', value: 'Attachment' },
    { label: 'ContentDocument', value: 'ContentDocument' }
];

export const OPERATOR_OPTIONS = [
    { label: 'Equals', value: '=' },
    { label: 'Contains', value: 'LIKE' },
    { label: 'Greater Than', value: '>' }
];

// Factory function to create a new empty filter
export const createNewFilter = () => {
    return {
        id: Date.now(),
        fieldName: '',
        operator: '=',
        value: ''
    };
};

// Helper to validate the request before sending to server
export const validateRequest = (fields, filters) => {
    const errors = [];
    if (!fields || fields.length === 0) errors.push('Select at least one field.');
    
    const incompleteFilter = filters.find(f => !f.fieldName || !f.value);
    if (incompleteFilter) errors.push('Complete all filter conditions.');
    
    return {
        isValid: errors.length === 0,
        errorMessage: errors.join(' ')
    };
};