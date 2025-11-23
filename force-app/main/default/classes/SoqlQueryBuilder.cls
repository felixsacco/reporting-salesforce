// Builds an SOQL query with an optional WHERE clause
public inherited sharing class SoqlQueryBuilder {
    
    public static String build(String objectName, List<String> fields, List<QueryFilterDto> filters, Integer limitVal) {
        String query = 'SELECT ' + String.join(fields, ',') + ' FROM ' + String.escapeSingleQuotes(objectName);
        
        if (filters != null && !filters.isEmpty()) {
            query += ' WHERE ' + buildWhereClause(filters);
        }
        
        query += ' LIMIT ' + Integer.valueOf(limitVal);
        return query;
    }

    private static String buildWhereClause(List<QueryFilterDto> filters) {
        List<String> conditions = new List<String>();
        for (QueryFilterDto filter : filters) {
            // Securely escapes inputs here
            String field = String.escapeSingleQuotes(filter.fieldName);
            String value = String.escapeSingleQuotes(filter.value);
            
            if (filter.operator.equalsIgnoreCase('LIKE')) {
                conditions.add(field + ' LIKE \'%' + value + '%\'');
            } else {
                // Add logic for numeric vs string quoting here if needed
                conditions.add(field + ' ' + filter.operator + ' \'' + value + '\'');
            }
        }
        return String.join(conditions, ' AND ');
    }
}