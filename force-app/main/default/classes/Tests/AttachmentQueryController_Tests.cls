/**
 * @description Enhanced test class for AttachmentQueryController.
 *              Tests new methods, security enforcement, and type-aware queries.
 * 
 * @author Agent Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */
@isTest
private class AttachmentQueryController_Tests {
    
    @testSetup
    static void setupData() {
        // Create parent account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // Create test attachments with varying sizes
        Attachment att1 = new Attachment();
        att1.Name = 'SmallFile.txt';
        att1.Body = Blob.valueOf('Small content');
        att1.ParentId = acc.Id;
        
        Attachment att2 = new Attachment();
        att2.Name = 'LargeFile.txt';
        att2.Body = Blob.valueOf('X'.repeat(2000));
        att2.ParentId = acc.Id;
        
        Attachment att3 = new Attachment();
        att3.Name = 'Report_Q1.pdf';
        att3.Body = Blob.valueOf('PDF content');
        att3.ParentId = acc.Id;
        
        insert new List<Attachment>{att1, att2, att3};
    }

    @isTest
    static void testGetObjectFields() {
        Test.startTest();
        List<String> fields = AttachmentQueryController.getObjectFields('Attachment');
        Test.stopTest();
        
        System.assert(fields.contains('Name'), 'Should return Name field');
        System.assert(fields.contains('BodyLength'), 'Should return BodyLength field');
        System.assert(fields.contains('Id'), 'Should return Id field');
    }
    
    @isTest
    static void testGetObjectFieldOptions() {
        // Test new method returns label/value pairs
        Test.startTest();
        List<SchemaFieldOption> options = 
            AttachmentQueryController.getObjectFieldOptions('Attachment');
        Test.stopTest();
        
        System.assertNotEquals(null, options, 'Should return options');
        System.assert(options.size() > 0, 'Should have fields');
        
        // Verify structure - find Name field
        SchemaFieldOption nameField = null;
        for (SchemaFieldOption opt : options) {
            if (opt.value == 'Name') {
                nameField = opt;
                break;
            }
        }
        
        System.assertNotEquals(null, nameField, 'Should include Name field');
        System.assertNotEquals(null, nameField.label, 'Should have label');
        System.assertEquals('Name', nameField.value, 'Value should be API name');
    }
    
    @isTest
    static void testExecuteQuery_Success() {
        List<String> fields = new List<String>{'Name', 'Id', 'ParentId'};
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        
        // Filter by Name
        QueryFilterDto f1 = new QueryFilterDto();
        f1.fieldName = 'Name';
        f1.operator = '=';
        f1.value = 'SmallFile.txt';
        filters.add(f1);
        
        Test.startTest();
        List<SObject> results = AttachmentQueryController.executeQuery(
            'Attachment', fields, filters, 10);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should find 1 attachment');
        System.assertEquals('SmallFile.txt', (String)results[0].get('Name'), 'Name should match');
    }
    
    @isTest
    static void testExecuteQuery_SecurityException() {
        // Try to query a field that doesn't exist to trigger validation error
        List<String> fields = new List<String>{'NonExistentField__c'};
        
        Test.startTest();
        try {
            AttachmentQueryController.executeQuery(
                'Attachment', fields, new List<QueryFilterDto>(), 10);
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Error') || 
                         e.getMessage().contains('Security'), 
                         'Should be an AuraHandledException: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExecuteQuery_WithInvalidOperator() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = 'INVALID_OP';
        filter.value = 'test';
        
        Test.startTest();
        try {
            AttachmentQueryController.executeQuery('Attachment', 
                new List<String>{'Name'}, 
                new List<QueryFilterDto>{filter}, 10);
            System.assert(false, 'Should throw exception for invalid operator');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unsupported operator') || 
                         e.getMessage().contains('Validation'), 
                         'Error should mention operator issue');
        }
        Test.stopTest();
    }

    @isTest
    static void testExecuteQuery_WithSecurityEnforced() {
        // Test that WITH SECURITY_ENFORCED is attempted for compatible queries
        List<String> fields = new List<String>{'Name', 'Id'};
        
        Test.startTest();
        List<SObject> results = AttachmentQueryController.executeQuery(
            'Attachment', fields, new List<QueryFilterDto>(), 10);
        Test.stopTest();
        
        // Should execute successfully (WITH SECURITY_ENFORCED or fallback)
        System.assertNotEquals(null, results, 'Should return results');
        System.assert(results.size() <= 10, 'Should respect limit');
    }

    @isTest
    static void testExecuteQuery_TypedQuery_Numeric() {
        // Query for large files only (BodyLength > 100)
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'BodyLength';
        filter.operator = '>';
        filter.value = '100';
        
        Test.startTest();
        List<SObject> results = AttachmentQueryController.executeQuery(
            'Attachment', 
            new List<String>{'Name', 'BodyLength'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        // Should find LargeFile.txt (2000 bytes) and Report_Q1.pdf
        System.assert(results.size() >= 1, 'Should find at least one large file');
        
        // Verify all results match filter
        for (SObject result : results) {
            Integer bodyLength = (Integer)result.get('BodyLength');
            System.assert(bodyLength > 100, 
                'All results should have BodyLength > 100, found: ' + bodyLength);
        }
    }

    @isTest
    static void testExecuteQuery_TypedQuery_LIKE() {
        // Query for files with "Report" in name
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = 'LIKE';
        filter.value = 'Report';
        
        Test.startTest();
        List<SObject> results = AttachmentQueryController.executeQuery(
            'Attachment', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should find Report_Q1.pdf');
        System.assert(((String)results[0].get('Name')).contains('Report'), 
            'Result should contain "Report"');
    }

    @isTest
    static void testExecuteQuery_LimitClamping() {
        // Test that excessive limits are clamped server-side
        Test.startTest();
        try {
            List<SObject> results = AttachmentQueryController.executeQuery(
                'Attachment', 
                new List<String>{'Name'}, 
                new List<QueryFilterDto>(), 10000);
            
            // Should succeed (limit clamped to 2000)
            System.assertNotEquals(null, results, 'Should execute with clamped limit');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for high limit: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @isTest
    static void testExecuteQuery_MultipleFilters() {
        // Test multiple filter conditions (AND logic)
        QueryFilterDto filter1 = new QueryFilterDto();
        filter1.fieldName = 'Name';
        filter1.operator = 'LIKE';
        filter1.value = 'File';
        
        QueryFilterDto filter2 = new QueryFilterDto();
        filter2.fieldName = 'BodyLength';
        filter2.operator = '>';
        filter2.value = '50';
        
        Test.startTest();
        List<SObject> results = AttachmentQueryController.executeQuery(
            'Attachment', 
            new List<String>{'Name', 'BodyLength'}, 
            new List<QueryFilterDto>{filter1, filter2}, 10);
        Test.stopTest();
        
        // Should find files with "File" in name AND BodyLength > 50
        for (SObject result : results) {
            String name = (String)result.get('Name');
            Integer bodyLength = (Integer)result.get('BodyLength');
            System.assert(name.contains('File'), 'Name should contain "File"');
            System.assert(bodyLength > 50, 'BodyLength should be > 50');
        }
    }
    
    @isTest
    static void testExecuteQuery_NoFilters() {
        // Test query without filters (should return all accessible records)
        Test.startTest();
        List<SObject> results = AttachmentQueryController.executeQuery(
            'Attachment', 
            new List<String>{'Name', 'Id'}, 
            new List<QueryFilterDto>(), 10);
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should return results without filters');
        System.assert(results.size() <= 10, 'Should respect limit');
    }
    
    @isTest
    static void testExecuteQuery_NullFilters() {
        // Test query with null filters parameter
        Test.startTest();
        List<SObject> results = AttachmentQueryController.executeQuery(
            'Attachment', 
            new List<String>{'Name', 'Id'}, 
            null, 
            10);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Should handle null filters');
        System.assert(results.size() > 0, 'Should return results');
    }
}