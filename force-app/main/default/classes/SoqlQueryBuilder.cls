/**
 * @description Service class responsible for building dynamic SOQL queries with type-aware value formatting.
 *              Supports all standard field types and validates operators against a whitelist.
 *              Changed to 'with sharing' for explicit sharing enforcement.
 * 
 * @author Agent Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */
public with sharing class SoqlQueryBuilder {
    
    // Constants for limit validation
    private static final Integer MIN_LIMIT = 1;
    private static final Integer MAX_LIMIT = 2000;
    private static final Integer DEFAULT_LIMIT = 50;
    
    /**
     * @description Builds a SOQL query with type-aware value formatting (new enhanced version).
     *              Validates operators, determines field types, and formats values accordingly.
     * 
     * @param objectName The API name of the SObject to query
     * @param fields List of field API names to select
     * @param filters List of filter conditions (can be null or empty)
     * @param limitVal The maximum number of records to return (will be clamped to MIN_LIMIT/MAX_LIMIT)
     * @return A complete SOQL query string
     * @throws IllegalArgumentException if operator is invalid or value doesn't match field type
     */
    public static String buildTyped(String objectName, List<String> fields, List<QueryFilterDto> filters, Integer limitVal) {
        // Build SELECT clause
        String query = 'SELECT ' + String.join(fields, ', ') + 
                      ' FROM ' + String.escapeSingleQuotes(objectName);
        
        // Build WHERE clause if filters provided
        if (filters != null && !filters.isEmpty()) {
            query += ' WHERE ' + buildWhereClauseTyped(objectName, filters);
        }
        
        // Add LIMIT with validation
        query += ' LIMIT ' + validateLimit(limitVal);
        
        return query;
    }
    
    /**
     * @description Legacy build method for backward compatibility.
     *              Delegates to buildTyped for consistent behavior.
     * 
     * @param objectName The API name of the SObject to query
     * @param fields List of field API names to select
     * @param filters List of filter conditions (can be null or empty)
     * @param limitVal The maximum number of records to return
     * @return A complete SOQL query string
     */
    public static String build(String objectName, List<String> fields, List<QueryFilterDto> filters, Integer limitVal) {
        return buildTyped(objectName, fields, filters, limitVal);
    }

    /**
     * @description Builds the WHERE clause of the query with type-aware value formatting.
     * 
     * @param objectName The API name of the SObject being queried
     * @param filters List of filter conditions
     * @return The WHERE clause string (without the 'WHERE' keyword)
     * @throws IllegalArgumentException if operator or value is invalid for field type
     */
    private static String buildWhereClauseTyped(String objectName, List<QueryFilterDto> filters) {
        // Get object describe for field type information
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        
        List<String> conditions = new List<String>();
        
        for (QueryFilterDto filter : filters) {
            // Get field describe
            Schema.SObjectField fieldToken = fieldMap.get(filter.fieldName);
            if (fieldToken == null) {
                throw new IllegalArgumentException('Invalid field: ' + filter.fieldName);
            }
            
            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();
            
            // Validate and normalize operator
            String operator = validateOperator(filter.operator);
            
            // Format value based on field type
            String formattedValue = formatValueByType(fieldDescribe, operator, filter.value, filter.fieldName);
            
            // Build condition
            String field = String.escapeSingleQuotes(filter.fieldName);
            conditions.add(field + ' ' + operator + ' ' + formattedValue);
        }
        
        return String.join(conditions, ' AND ');
    }

    /**
     * @description Validates and normalizes the operator string.
     * 
     * @param operator The operator to validate
     * @return The normalized (uppercased) operator
     * @throws IllegalArgumentException if operator is not in the whitelist
     */
    private static String validateOperator(String operator) {
        String normalized = operator.toUpperCase().trim();
        Set<String> allowedOperators = SecurityService.getAllowedOperators();
        
        if (!allowedOperators.contains(normalized)) {
            throw new IllegalArgumentException('Unsupported operator: ' + operator);
        }
        
        return normalized;
    }

    /**
     * @description Validates and clamps the LIMIT value to acceptable range.
     * 
     * @param limitVal The requested limit value
     * @return The clamped limit value between MIN_LIMIT and MAX_LIMIT
     */
    private static Integer validateLimit(Integer limitVal) {
        if (limitVal == null) {
            return DEFAULT_LIMIT;
        }
        return Math.min(Math.max(limitVal, MIN_LIMIT), MAX_LIMIT);
    }

    /**
     * @description Routes value formatting based on field type.
     * 
     * @param fieldDescribe The field's describe result
     * @param operator The operator being used
     * @param value The raw value string from the filter
     * @param fieldName The field name (for error messages)
     * @return The formatted value string ready for SOQL
     * @throws IllegalArgumentException if value is invalid for the field type
     */
    private static String formatValueByType(Schema.DescribeFieldResult fieldDescribe, 
                                            String operator, 
                                            String value,
                                            String fieldName) {
        Schema.DisplayType fieldType = fieldDescribe.getType();
        
        try {
            switch on fieldType {
                when INTEGER, DOUBLE, CURRENCY, PERCENT {
                    return formatNumericValue(value, operator, fieldName);
                }
                when BOOLEAN {
                    return formatBooleanValue(value, fieldName);
                }
                when DATE {
                    return formatDateValue(value, fieldName);
                }
                when DATETIME {
                    return formatDateTimeValue(value, fieldName);
                }
                when MULTIPICKLIST {
                    return formatMultiSelectValue(value, operator, fieldName);
                }
                when else {
                    // TEXT, TEXTAREA, PICKLIST, EMAIL, PHONE, URL, ID, REFERENCE, etc.
                    return formatTextValue(value, operator, fieldDescribe, fieldName);
                }
            }
        } catch (IllegalArgumentException e) {
            // Re-throw with context preserved
            throw e;
        }
    }

    // Type-specific formatting methods continue in next part...

    /**
     * @description Formats numeric values (Integer, Double, Currency, Percent).
     *              Validates that the value is numeric and handles IN/NOT IN operators.
     * 
     * @param value The raw value string
     * @param operator The operator being used
     * @param fieldName The field name (for error messages)
     * @return Unquoted numeric value or parenthesized list for IN/NOT IN
     * @throws IllegalArgumentException if value is not numeric or operator is incompatible
     */
    private static String formatNumericValue(String value, String operator, String fieldName) {
        // Validate operator compatibility
        if (operator == 'LIKE') {
            throw new IllegalArgumentException(
                'LIKE operator is not supported for numeric field "' + fieldName + 
                '". Use =, !=, <, >, <=, >= instead.'
            );
        }
        
        // Handle IN/NOT IN operators
        if (operator == 'IN' || operator == 'NOT IN') {
            List<String> values = value.split('[,;]');
            if (values.isEmpty()) {
                throw new IllegalArgumentException(
                    'Field "' + fieldName + '" with ' + operator + ' operator requires at least one value in the list.'
                );
            }
            
            List<String> formatted = new List<String>();
            for (String val : values) {
                String trimmed = val.trim();
                try {
                    Decimal.valueOf(trimmed); // Validate each value
                    formatted.add(trimmed);
                } catch (Exception e) {
                    throw new IllegalArgumentException(
                        'Field "' + fieldName + '" requires numeric values in the list. Invalid value: "' + trimmed + '"'
                    );
                }
            }
            return '(' + String.join(formatted, ', ') + ')';
        }
        
        // Single value - validate numeric
        try {
            Decimal.valueOf(value.trim());
        } catch (Exception e) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" requires a numeric value. Provided: "' + value + '"'
            );
        }
        
        return value.trim();
    }

    /**
     * @description Formats boolean values. Normalizes various representations to TRUE/FALSE.
     * 
     * @param value The raw value string
     * @param fieldName The field name (for error messages)
     * @return 'TRUE' or 'FALSE'
     * @throws IllegalArgumentException if value is not a valid boolean representation
     */
    private static String formatBooleanValue(String value, String fieldName) {
        String normalized = value.trim().toLowerCase();
        
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
            return 'TRUE';
        } else if (normalized == 'false' || normalized == '0' || normalized == 'no') {
            return 'FALSE';
        }
        
        throw new IllegalArgumentException(
            'Field "' + fieldName + '" requires a boolean value (true/false, yes/no, 1/0). Provided: "' + value + '"'
        );
    }

    /**
     * @description Formats date values. Supports date literals and YYYY-MM-DD format.
     * 
     * @param value The raw value string
     * @param fieldName The field name (for error messages)
     * @return Unquoted date literal or validated date string
     * @throws IllegalArgumentException if value is not a valid date format
     */
    private static String formatDateValue(String value, String fieldName) {
        String trimmed = value.trim();
        
        // Check for date literals (e.g., TODAY, YESTERDAY, LAST_N_DAYS:30)
        if (isDateLiteral(trimmed)) {
            return trimmed;
        }
        
        // Enforce Salesforce standard date format (YYYY-MM-DD)
        try {
            Date.valueOf(trimmed);
            return trimmed;
        } catch (Exception e) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" requires a date in YYYY-MM-DD format (e.g., 2024-01-15) ' +
                'or a date literal (e.g., LAST_N_DAYS:30). Provided: "' + value + '"'
            );
        }
    }

    /**
     * @description Checks if a value is a Salesforce date literal.
     * 
     * @param value The value to check
     * @return True if value is a recognized date literal
     */
    private static Boolean isDateLiteral(String value) {
        String upper = value.toUpperCase();
        return upper == 'TODAY' || 
               upper == 'YESTERDAY' || 
               upper == 'TOMORROW' ||
               upper.startsWith('LAST_N_DAYS:') ||
               upper.startsWith('NEXT_N_DAYS:') ||
               upper.startsWith('LAST_N_WEEKS:') ||
               upper.startsWith('NEXT_N_WEEKS:') ||
               upper.startsWith('LAST_N_MONTHS:') ||
               upper.startsWith('NEXT_N_MONTHS:') ||
               upper.startsWith('LAST_N_YEARS:') ||
               upper.startsWith('NEXT_N_YEARS:');
    }

    /**
     * @description Formats datetime values. Supports date literals and ISO format with Z suffix.
     * 
     * @param value The raw value string
     * @param fieldName The field name (for error messages)
     * @return Formatted datetime string with Z suffix
     * @throws IllegalArgumentException if value is not a valid datetime format
     */
    private static String formatDateTimeValue(String value, String fieldName) {
        String trimmed = value.trim();
        
        // Check for datetime literals
        if (isDateLiteral(trimmed)) {
            return trimmed;
        }
        
        // Validate ISO datetime format and ensure Z suffix
        try {
            Datetime dt;
            if (trimmed.endsWith('Z')) {
                dt = Datetime.valueOf(trimmed.replace('T', ' ').replace('Z', ''));
            } else {
                dt = Datetime.valueOf(trimmed.replace('T', ' '));
            }
            
            // Format back with Z
            return dt.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        } catch (Exception e) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" requires a datetime in ISO format (e.g., 2024-01-15T10:30:00Z) ' +
                'or a date literal. Provided: "' + value + '"'
            );
        }
    }

    /**
     * @description Formats text values. Handles escaping, LIKE wildcards, and IN/NOT IN lists.
     * 
     * @param value The raw value string
     * @param operator The operator being used
     * @param fieldDescribe The field's describe result
     * @param fieldName The field name (for error messages)
     * @return Quoted and escaped text value
     * @throws IllegalArgumentException if value is invalid for operator
     */
    private static String formatTextValue(String value, String operator, 
                                          Schema.DescribeFieldResult fieldDescribe,
                                          String fieldName) {
        String escaped = String.escapeSingleQuotes(value);
        
        if (operator == 'LIKE') {
            // Add wildcards for LIKE if not already present
            if (!escaped.startsWith('%') && !escaped.endsWith('%')) {
                escaped = '%' + escaped + '%';
            }
            return '\'' + escaped + '\'';
        }
        
        if (operator == 'IN' || operator == 'NOT IN') {
            List<String> values = value.split('[,;]');
            if (values.isEmpty()) {
                throw new IllegalArgumentException(
                    'Field "' + fieldName + '" with ' + operator + ' operator requires at least one value in the list.'
                );
            }
            
            List<String> formatted = new List<String>();
            for (String val : values) {
                String trimmed = String.escapeSingleQuotes(val.trim());
                if (String.isNotBlank(trimmed)) {
                    formatted.add('\'' + trimmed + '\'');
                }
            }
            
            if (formatted.isEmpty()) {
                throw new IllegalArgumentException(
                    'Field "' + fieldName + '" with ' + operator + ' operator requires at least one non-empty value.'
                );
            }
            
            return '(' + String.join(formatted, ', ') + ')';
        }
        
        return '\'' + escaped + '\'';
    }

    /**
     * @description Formats multi-select picklist values. Only supports INCLUDES/EXCLUDES operators.
     * 
     * @param value The raw value string (semicolon-separated)
     * @param operator The operator being used (must be INCLUDES or EXCLUDES)
     * @param fieldName The field name (for error messages)
     * @return Formatted multi-select value string
     * @throws IllegalArgumentException if operator is not INCLUDES/EXCLUDES or value is empty
     */
    private static String formatMultiSelectValue(String value, String operator, String fieldName) {
        if (operator != 'INCLUDES' && operator != 'EXCLUDES') {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" is a multi-select picklist and only supports INCLUDES or EXCLUDES operators. ' +
                'Operator used: ' + operator
            );
        }
        
        // Multi-select uses semicolon-delimited values
        List<String> values = value.split(';');
        if (values.isEmpty()) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" with ' + operator + ' operator requires at least one value.'
            );
        }
        
        List<String> formatted = new List<String>();
        for (String val : values) {
            String trimmed = String.escapeSingleQuotes(val.trim());
            if (String.isNotBlank(trimmed)) {
                formatted.add('\'' + trimmed + '\'');
            }
        }
        
        if (formatted.isEmpty()) {
            throw new IllegalArgumentException(
                'Field "' + fieldName + '" with ' + operator + ' operator requires at least one non-empty value.'
            );
        }
        
        return '(' + String.join(formatted, ';') + ')';
    }
}