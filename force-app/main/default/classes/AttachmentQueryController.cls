/**
 * @description Controller class for the Reporting on Files application.
 *              Provides @AuraEnabled methods for LWC components to interact with data securely.
 *              Enforces WITH SECURITY_ENFORCED when compatible.
 * 
 * @author Agent Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */
public with sharing class AttachmentQueryController {

    /**
     * @description Retrieves accessible field API names for a given object.
     *              Legacy method maintained for potential backward compatibility.
     * 
     * @param objectName The API name of the SObject
     * @return List of accessible field API names
     * @throws AuraHandledException if an error occurs
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getObjectFields(String objectName) {
        try {
            return SecurityService.getAccessibleFields(objectName); 
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving fields: ' + e.getMessage());
        }
    }

    /**
     * @description Retrieves accessible field options (label + API name) for a given object.
     *              This is the new enhanced method that returns SchemaFieldOption DTOs.
     * 
     * @param objectName The API name of the SObject
     * @return List of SchemaFieldOption objects containing label and value pairs
     * @throws AuraHandledException if an error occurs
     */
    @AuraEnabled(cacheable=true)
    public static List<SchemaFieldOption> getObjectFieldOptions(String objectName) {
        try {
            return SecurityService.getAccessibleFieldOptions(objectName);
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving field options: ' + e.getMessage());
        }
    }
    
    /**
     * @description Executes a dynamic SOQL query with security enforcement.
     *              Validates object/field access, operators, and builds type-aware query.
     * 
     * @param objectName The API name of the SObject to query
     * @param fields List of field API names to select
     * @param filters List of filter conditions (can be null or empty)
     * @param limitValue Maximum number of records to return (clamped server-side)
     * @return List of SObject records matching the query
     * @throws AuraHandledException if security validation fails or query is invalid
     */
    @AuraEnabled
    public static List<SObject> executeQuery(String objectName, 
                                             List<String> fields, 
                                             List<QueryFilterDto> filters, 
                                             Integer limitValue) {
        try {
            // 1. Security Check (Object and Field Level Security)
            SecurityService.validateReadAccess(objectName, fields);
            
            // 2. Validate operators against whitelist
            if (filters != null) {
                Set<String> allowedOps = SecurityService.getAllowedOperators();
                for (QueryFilterDto filter : filters) {
                    String op = filter.operator.toUpperCase().trim();
                    if (!allowedOps.contains(op)) {
                        throw new IllegalArgumentException(
                            'Unsupported operator: ' + filter.operator
                        );
                    }
                }
            }
            
            // 3. Build Query with type-aware value formatting
            String query = SoqlQueryBuilder.buildTyped(objectName, fields, filters, limitValue);
            
            // 4. Execute with security enforcement
            return executeQueryWithSecurity(query, objectName, fields);
            
        } catch (IllegalArgumentException iae) {
            throw new AuraHandledException('Validation Error: ' + iae.getMessage());
        } catch (SecurityException se) {
            throw new AuraHandledException('Security Error: ' + se.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected Error: ' + e.getMessage());
        }
    }

    /**
     * @description Executes the query with WITH SECURITY_ENFORCED when compatible.
     *              Falls back to pre-validated execution if incompatible.
     * 
     * @param query The complete SOQL query string
     * @param objectName The object being queried (for logging)
     * @param fields The fields being selected (for logging)
     * @return List of SObject records
     */
    private static List<SObject> executeQueryWithSecurity(String query, 
                                                           String objectName, 
                                                           List<String> fields) {
        // Check if query is compatible with WITH SECURITY_ENFORCED
        if (isCompatibleWithSecurityEnforced(query)) {
            try {
                // Attempt with WITH SECURITY_ENFORCED
                String secureQuery = query + ' WITH SECURITY_ENFORCED';
                System.debug(LoggingLevel.FINE, 
                    'Executing query with SECURITY_ENFORCED: ' + secureQuery);
                return Database.query(secureQuery);
            } catch (System.QueryException qe) {
                // Log warning and fallback
                System.debug(LoggingLevel.WARN, 
                    'WITH SECURITY_ENFORCED failed, using pre-validation fallback: ' + qe.getMessage());
            }
        }
        
        // Fallback: rely on pre-validation (already done in validateReadAccess)
        System.debug(LoggingLevel.FINE, 
            'Executing query with pre-validation (FLS checked): ' + query);
        return Database.query(query);
    }

    /**
     * @description Checks if a query is compatible with WITH SECURITY_ENFORCED.
     *              Returns false if query contains incompatible constructs.
     * 
     * @param query The SOQL query string to check
     * @return True if compatible, false otherwise
     */
    private static Boolean isCompatibleWithSecurityEnforced(String query) {
        String upper = query.toUpperCase();
        
        // Extract SELECT clause
        Integer selectPos = upper.indexOf('SELECT');
        Integer fromPos = upper.indexOf('FROM');
        if (selectPos == -1 || fromPos == -1) {
            return false;
        }
        
        String selectClause = query.substring(selectPos + 6, fromPos).trim();
        
        // WITH SECURITY_ENFORCED is incompatible with:
        // 1. Relationship queries (dots in field names)
        if (selectClause.contains('.')) {
            return false;
        }
        
        // 2. Aggregate functions
        if (upper.contains('COUNT(') || upper.contains('SUM(') || 
            upper.contains('AVG(') || upper.contains('MAX(') || upper.contains('MIN(')) {
            return false;
        }
        
        // 3. TYPEOF expressions
        if (upper.contains('TYPEOF')) {
            return false;
        }
        
        // Query is compatible
        return true;
    }
}