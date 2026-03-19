/**
 * @description Service class responsible for enforcing data access security.
 *              Validates object-level security, field-level security (FLS), and provides
 *              accessible field metadata. Changed to 'with sharing' for explicit sharing enforcement.
 * 
 * @author Mritesh
 * @date 2026-02-17
 * @version 1.2.1
 */
public with sharing class SecurityService {
    
    /**
     * @description Validates that the current user has read access to the SObject and all specified fields.
     * @param objectName The API name of the SObject (e.g., 'Attachment').
     * @param fields A list of field API names to check.
     * @throws IllegalArgumentException if the object does not exist
     * @throws SecurityException if the user lacks access to the object or any field
     */
    public static void validateReadAccess(String objectName, List<String> fields) {
        if(String.isBlank(objectName) || fields == null || fields.isEmpty()) {
            throw new IllegalArgumentException('Invalid input: Object name and fields must be provided');
        }
        
        // Validate Object Access
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) {
            throw new IllegalArgumentException('Invalid Object: ' + objectName);
        }
        if (!objectType.getDescribe().isAccessible()) {
            throw new SecurityException('Cannot access object: ' + objectName);
        }

        // Validate Field Access (FLS)
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();
        for (String field : fields) {
            if (!fieldMap.containsKey(field) || !fieldMap.get(field).getDescribe().isAccessible()) {
                throw new SecurityException('Access denied or invalid field: ' + field);
            }
        }
        
        // Log successful validation for audit trail
        System.debug(LoggingLevel.FINE, 
            'Security validation passed: Object=' + objectName + 
            ', User=' + UserInfo.getUserId() + 
            ', Fields=' + String.join(fields, ','));
    }

    /**
     * DEPRECATED: Use getAccessibleFieldOptions instead for richer metadata.
     * Will be removed in future versions.
     * @description Retrieves a sorted list of field API names for a given SObject 
     *              that the current user has access to view.
     * @param objectName The API name of the SObject.
     * @return A List of accessible field API names.
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAccessibleFields(String objectName) {
        if (String.isBlank(objectName)) {
            return new List<String>();
        }
        
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null || !objectType.getDescribe().isAccessible()) {
            return new List<String>();
        }

        List<String> accessibleFields = new List<String>();
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult describe = field.getDescribe();
            if (describe.isAccessible()) {
                accessibleFields.add(describe.getName());
            }
        }
        
        accessibleFields.sort();
        return accessibleFields;
    }

    /**
     * @description Retrieves a sorted list of field options (label + API name) for a given SObject
     *              that the current user has access to view. Returns SchemaFieldOption DTOs.
     * @param objectName The API name of the SObject.
     * @return A List of SchemaFieldOption objects containing label and value (API name) pairs.
     */
    @AuraEnabled(cacheable=true)
    public static List<SchemaFieldOption> getAccessibleFieldOptions(String objectName) {
        if (String.isBlank(objectName)) {
            return new List<SchemaFieldOption>();
        }

        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null || !objectType.getDescribe().isAccessible()) {
            return new List<SchemaFieldOption>();
        }

        List<SchemaFieldOption> fieldOptions = new List<SchemaFieldOption>();
        Map<String, Schema.SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

        for (Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult describe = field.getDescribe();
            if (describe.isAccessible()) {
                // Create DTO with label (for display) and API name (for queries)
                SchemaFieldOption option = new SchemaFieldOption(
                    describe.getLabel(),  
                    describe.getName()    
                );
                fieldOptions.add(option);
            }
        }
        
        // Sorting by label for better user experience in dropdowns
        for (Integer i = 0; i < fieldOptions.size() - 1; i++) {
            for (Integer j = i + 1; j < fieldOptions.size(); j++) {
                String labelI = fieldOptions[i].label != null ? fieldOptions[i].label.toLowerCase() : '';
                String labelJ = fieldOptions[j].label != null ? fieldOptions[j].label.toLowerCase() : '';
                if (labelI > labelJ) {
                    SchemaFieldOption temp = fieldOptions[i];
                    fieldOptions[i] = fieldOptions[j];
                    fieldOptions[j] = temp;
                }
            }
        }
        
        return fieldOptions;
    }

}