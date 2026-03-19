/**
 * @description DEPRECATED compatibility wrapper for QueryController.
 *              Keeps existing AuraEnabled endpoints available for legacy callers.
 *
 * @author Mritesh
 * @date 2026-03-19
 * @version 1.2.1
 */
public with sharing class AttachmentQueryController {

    /**
     * DEPRECATED - Use getObjectFieldOptions instead for enhanced field metadata retrieval.
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
            // Security Check (Object and Field Level Security)
            SecurityService.validateReadAccess(objectName, fields);

            // Validate operators against whitelist
            if (filters != null) {
                List<String> filterFields = new List<String>();
                Set<String> allowedOps = SoqlQueryBuilder.ALLOWED_OPERATORS;

                for (QueryFilterDto filter : filters) {
                    String op = filter.operator.toUpperCase().trim();
                    if (!allowedOps.contains(op)) {
                        throw new IllegalArgumentException(
                            'Unsupported operator: ' + filter.operator
                        );
                    }
                    filterFields.add(filter.fieldName);
                }

                // Validate field access for filter fields
                SecurityService.validateReadAccess(objectName, filterFields);
            }

            // Build Query with type-aware value formatting
            String query = SoqlQueryBuilder.buildQuery(objectName, fields, filters, limitValue);

            // Execute with security enforcement (delegated to SoqlQueryBuilder)
            return Database.query(query);

        } catch (IllegalArgumentException iae) {
            throw new AuraHandledException('Validation Error: ' + iae.getMessage());
        } catch (SecurityException se) {
            throw new AuraHandledException('Security Error: ' + se.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected Error: ' + e.getMessage());
        }
    }
}