@isTest
private inherited sharing class AttachmentQueryController_Tests {
    
    @testSetup
    static void setupData() {
        // Create parent account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Attachment att = new Attachment();
        att.Name = 'TestFile.txt';
        att.Body = Blob.valueOf('Test Content');
        att.ParentId = acc.Id;
        insert att;
    }

    @isTest
    static void testGetObjectFields() {
        Test.startTest();
        List<String> fields = AttachmentQueryController.getObjectFields('Attachment');
        Test.stopTest();
        
        System.assert(fields.contains('Name'), 'Should return Name field');
        System.assert(fields.contains('BodyLength'), 'Should return BodyLength field');
    }
    
    @isTest
    static void testExecuteQuery_Success() {
        List<String> fields = new List<String>{'Name', 'Id', 'ParentId'};
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        
        // Filter by Name
        QueryFilterDto f1 = new QueryFilterDto();
        f1.fieldName = 'Name';
        f1.operator = '=';
        f1.value = 'TestFile.txt';
        filters.add(f1);
        
        Test.startTest();
        List<SObject> results = AttachmentQueryController.executeQuery('Attachment', fields, filters, 10);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should find 1 attachment');
        System.assertEquals('TestFile.txt', (String)results[0].get('Name'), 'Name should match');
    }
    
    @isTest
    static void testExecuteQuery_SecurityException() {
        // Try to query a field that doesn't exist to trigger security/validation error
        List<String> fields = new List<String>{'NonExistentField__c'};
        
        Test.startTest();
        try {
            AttachmentQueryController.executeQuery('Attachment', fields, new List<QueryFilterDto>(), 10);
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Script-thrown exception') || e.getMessage().contains('Error'), 'Should be an AuraHandledException');
        }
        Test.stopTest();
    }
}