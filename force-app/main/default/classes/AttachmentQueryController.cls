public with sharing class AttachmentQueryController {
    
    @AuraEnabled(cacheable=true)
    public static List<String> getObjectFields(String objectName) {
        try {
            List<String> fieldNames = new List<String>();
            
            // Get the object describe
            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
            if (objectType == null) {
                throw new AuraHandledException('Invalid object name: ' + objectName);
            }
            
            // Get all fields for the object
            Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
            
            // Add accessible fields to the list
            for (String fieldName : fieldMap.keySet()) {
                Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
                if (fieldDescribe.isAccessible()) {
                    fieldNames.add(fieldDescribe.getName());
                }
            }
            
            // Sort alphabetically
            fieldNames.sort();
            
            return fieldNames;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving fields: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<Attachment> queryAttachments(String fields, String whereClause, Integer limitValue) {
        try {
            // Validate inputs
            if (String.isBlank(fields)) {
                throw new AuraHandledException('Fields parameter is required');
            }
            
            // Build the query
            String query = 'SELECT ' + String.escapeSingleQuotes(fields) + ' FROM Attachment';
            
            if (!String.isBlank(whereClause)) {
                query += ' WHERE ' + whereClause;
            }
            
            if (limitValue != null && limitValue > 0) {
                query += ' LIMIT ' + limitValue;
            }
            
            // Execute and return results
            return Database.query(query);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error querying Attachments: ' + e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<ContentDocument> queryContentDocuments(String fields, String whereClause, Integer limitValue) {
        try {
            // Validate inputs
            if (String.isBlank(fields)) {
                throw new AuraHandledException('Fields parameter is required');
            }
            
            // Build the query
            String query = 'SELECT ' + String.escapeSingleQuotes(fields) + ' FROM ContentDocument';
            
            if (!String.isBlank(whereClause)) {
                query += ' WHERE ' + whereClause;
            }
            
            if (limitValue != null && limitValue > 0) {
                query += ' LIMIT ' + limitValue;
            }
            
            // Execute and return results
            return Database.query(query);
            
        } catch (Exception e) {
            throw new AuraHandledException('Error querying ContentDocuments: ' + e.getMessage());
        }
    }
}