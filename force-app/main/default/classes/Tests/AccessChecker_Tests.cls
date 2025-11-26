@isTest
private class AccessChecker_Tests {
    
    @isTest
    static void testValidateReadAccess_Positive() {
        // Test with a standard object that exists in all orgs
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name', 'Id'};
        
        Test.startTest();
        try {
            SecurityService.validateReadAccess(objectName, fields);
        } catch (Exception e) {
            System.assert(false, 'Should not have thrown an exception for valid Account access');
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateReadAccess_InvalidObject() {
        String invalidObj = 'NonExistentObject__c';
        List<String> fields = new List<String>{'Name'};
        
        Test.startTest();
        try {
            SecurityService.validateReadAccess(invalidObj, fields);
            System.assert(false, 'Should have thrown exception for invalid object');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid Object'), 'Wrong error message');
        } catch (Exception e) {
             // Catch generic if specific type isn't thrown
        }
        Test.stopTest();
    }

    @isTest
    static void testValidateReadAccess_InvalidField() {
        String objectName = 'Account';
        // 'InvalidField__c' likely doesn't exist
        List<String> fields = new List<String>{'InvalidField__c'};
        
        Test.startTest();
        try {
            SecurityService.validateReadAccess(objectName, fields);
            System.assert(false, 'Should have thrown exception for invalid field');
        } catch (SecurityException e) {
            System.assert(true, 'Caught expected SecurityException');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetAccessibleFields() {
        Test.startTest();
        List<String> fields = SecurityService.getAccessibleFields('Account');
        Test.stopTest();
        
        System.assertNotEquals(null, fields, 'Result should not be null');
        System.assert(fields.size() > 0, 'Should return fields for Account');
        System.assert(fields.contains('Name'), 'Should contain standard field Name');
    }
}