/**
 * @description Service class responsible for building dynamic SOQL queries with type-aware value formatting.
 *              Supports all standard field types and validates operators against a whitelist.
 *              Changed to 'with sharing' for explicit sharing enforcement.
 * 
 * @author Mritesh
 * @date 2026-02-17
 * @version 1.2.1
 */
public with sharing class SoqlQueryBuilder {

    // DEPRECATED: use Utils.ALLOWED_OPERATORS as the source of truth.
    public static final Set<String> ALLOWED_OPERATORS = Utils.ALLOWED_OPERATORS;
    
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
        query += ' LIMIT ' + Utils.validateLimit(limitVal);
        
        return query;
    }
    
    /**
     * DEPRECATED - Use buildTyped instead for enhanced type-aware query building.
     * Will be removed in future versions.
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

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        
        List<String> conditions = new List<String>();
        
        for (QueryFilterDto filter : filters) {

            Schema.SObjectField fieldToken = fieldMap.get(filter.fieldName);
            if (fieldToken == null) {
                throw new IllegalArgumentException('Invalid field: ' + filter.fieldName);
            }
            
            Schema.DescribeFieldResult fieldDescribe = fieldToken.getDescribe();

            String operator = Utils.validateOperator(filter.operator);

            String formattedValue = Utils.formatValueByType(fieldDescribe, operator, filter.value, filter.fieldName);
            
            // Build condition
            String field = String.escapeSingleQuotes(fieldDescribe.getName());
            conditions.add(field + ' ' + operator + ' ' + formattedValue);
        }
        
        return String.join(conditions, ' AND ');
    }
}