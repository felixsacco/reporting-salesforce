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
     * @description Builds a SOQL query with type-aware value formatting.
     *              Validates operators, determines field types, and formats values accordingly.
     *              Accessible objects and fields must be handled by the caller.
     * 
     * @param objectName The API name of the SObject to query
     * @param fields List of field API names to select
     * @param filters List of filter conditions (can be null or empty)
     * @param limitVal The maximum number of records to return (will be clamped to MIN_LIMIT/MAX_LIMIT)
     * @return A complete SOQL query string
     * @throws IllegalArgumentException if operator is invalid or value doesn't match field type
     */
    public static String buildQuery(String objectName, List<String> fields, List<QueryFilterDto> filters, Integer limitVal) {
        // Build SELECT clause. Accessible fields should have been validated by caller.
        String query = 'SELECT ' + String.join(fields, ', ') + 
                      ' FROM ' + String.escapeSingleQuotes(objectName);
        
        // Build WHERE clause if filters provided
        if (filters != null && !filters.isEmpty()) {
            query += ' WHERE ' + buildWhereClauseTyped(objectName, filters);
        }
        
        // Add LIMIT with validation
        query += ' LIMIT ' + Utils.validateLimit(limitVal);

        query = applySecurityEnforcementIfCompatible(query);
        
        return query;
    }

    /**
     * DEPRECATED - Use buildQuery instead for enhanced type-aware query building.
     * Retained for backward compatibility.
     */
    @Deprecated
    public static String buildTyped(String objectName, List<String> fields, List<QueryFilterDto> filters, Integer limitVal) {
        return buildQuery(objectName, fields, filters, limitVal);
    }
    
    /**
     * DEPRECATED - Use buildQuery instead for enhanced type-aware query building.
     * Will be removed in future versions.
     * @description Legacy build method for backward compatibility.
     *              Delegates to buildQuery for consistent behavior.
     * 
     * @param objectName The API name of the SObject to query
     * @param fields List of field API names to select
     * @param filters List of filter conditions (can be null or empty)
     * @param limitVal The maximum number of records to return
     * @return A complete SOQL query string
     */
    @Deprecated
    public static String build(String objectName, List<String> fields, List<QueryFilterDto> filters, Integer limitVal) {
        return buildQuery(objectName, fields, filters, limitVal);
    }

    /**
     * @description Helper to append WITH SECURITY_ENFORCED when the query is compatible.
     *
     * @param query The complete SOQL query string
     * @return Query string with WITH SECURITY_ENFORCED appended when compatible; original otherwise
     */
    public static String applySecurityEnforcementIfCompatible(String query) {
        if (isCompatibleWithSecurityEnforced(query)) {
            return query + ' WITH SECURITY_ENFORCED';
        }
        return query;
    }

    /**
     * @description Determines whether a query is compatible with WITH SECURITY_ENFORCED.
     *              Incompatible when:
     *                - Aggregate functions present
     *                - TYPEOF expression present
     *
     * @param query The SOQL query string
     * @return True if compatible, false otherwise
     */
    public static Boolean isCompatibleWithSecurityEnforced(String query) {
        if (query == null) return false;

        String upper = query.toUpperCase();

        // Malformed query check that AgentForce decided to implement.
        // Keeping it because it doesn´t seem to hurt the functionallity.
        Integer selectPos = upper.indexOf('SELECT');
        Integer fromPos = upper.indexOf('FROM');
        if (selectPos == -1 || fromPos == -1 || fromPos <= selectPos) {
            return false;
        }

        String selectClause = query.substring(selectPos + 6, fromPos).trim();

        // Aggregate functions
        if (upper.contains('COUNT(') || upper.contains('SUM(') ||
            upper.contains('AVG(') || upper.contains('MAX(') || upper.contains('MIN(')) {
            return false;
        }

        // TYPEOF expressions
        if (upper.contains('TYPEOF')) {
            return false;
        }

        return true;
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