/**
 * @description Controller class for the Reporting on Files application.
 *              Provides @AuraEnabled methods for LWC components to interact with data securely.
 *              Enforces WITH SECURITY_ENFORCED when compatible.
 * 
 * @author Mritesh
 * @date 2026-02-17
 * @version 1.2.1
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
                Set<String> allowedOps = SoqlQueryBuilder.ALLOWED_OPERATORS;
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
            
            // 4. Execute with security enforcement (delegated to SoqlQueryBuilder)
            return SoqlQueryBuilder.executeQueryWithSecurity(query);
            
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

    /**
     * @description Checks if a query is compatible with WITH SECURITY_ENFORCED.
     *              Returns false if query contains incompatible constructs.
     * 
     * @param query The SOQL query string to check
     * @return True if compatible, false otherwise
     */
}