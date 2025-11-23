// The container class for interacting with the Model and View Components
public with sharing class AttachmentQueryController {

    @AuraEnabled(cacheable=true)
    public static List<String> getObjectFields(String objectName) {
        try {
            // Delegates the work entirely to the Security Service
            return SecurityService.getAccessibleFields(objectName); 
        } catch (Exception e) {
            // Note: AuraHandledException is usually preferred for LWC/Aura errors
            throw new AuraHandledException('Error retrieving fields: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<SObject> executeQuery(String objectName, List<String> fields, List<QueryFilterDto> filters, Integer limitValue) {
        try {
            // 1. Security Check
            SecurityService.validateReadAccess(objectName, fields);
            
            // 2. Build Query
            String query = SoqlQueryBuilder.build(objectName, fields, filters, limitValue);
            
            // 3. Execute (Data Access)
            return Database.query(query);
            
        } catch (SecurityException se) {
            throw new AuraHandledException('Security Error: ' + se.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Unexpected Error: ' + e.getMessage());
        }
    }
}