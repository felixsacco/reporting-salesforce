// Enables Data Access Security

public inherited sharing class AccessChecker {
    
    /**
     * @description Validates that the current user has read access to the SObject and all specified fields.
     * @param objectName The API name of the SObject (e.g., 'Attachment').
     * @param fields A list of field API names to check.
     */
    public static void validateReadAccess(String objectName, List<String> fields) {
        // 1. Validate Object Access
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            throw new IllegalArgumentException('Invalid Object: ' + objectName);
        }
        if (!objectType.getDescribe().isAccessible()) {
            throw new SecurityException('No access to object: ' + objectName);
        }

        // 2. Validate Field Access (FLS)
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        for (String field : fields) {
            if (!fieldMap.containsKey(field) || !fieldMap.get(field).getDescribe().isAccessible()) {
                throw new SecurityException('Access denied or invalid field: ' + field);
            }
        }
    }

    /**
     * @description Retrieves a sorted list of field API names for a given SObject 
     * that the current user has access to view.
     * @param objectName The API name of the SObject.
     * @return A List of accessible field API names.
     */
    @AuraEnabled(cacheable=true) // Can be cached if called directly from LWC
    public static List<String> getAccessibleFields(String objectName) {
        if (String.isBlank(objectName)) return new List<String>();

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null || !objectType.getDescribe().isAccessible()) {
            return new List<String>(); // No access, return empty list
        }

        List<String> accessibleFields = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        // Iterate through all fields and check FLS
        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult describe = field.getDescribe();
            if (describe.isAccessible()) {
                accessibleFields.add(describe.getName());
            }
        }
        
        accessibleFields.sort();
        return accessibleFields;
    }
}
