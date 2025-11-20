public with sharing class AttachmentQueryController {
    
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