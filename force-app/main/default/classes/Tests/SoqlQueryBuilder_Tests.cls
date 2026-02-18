/**
 * @description Comprehensive test class for SoqlQueryBuilder.
 *              Tests type-aware query building, operator validation, and security features.
 * 
 * @author Agent Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */
@isTest
private class SoqlQueryBuilder_Tests {

    // ========== BASIC QUERY BUILDING TESTS ==========
    
    @isTest
    static void testBuildQuery_Simple() {
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name', 'Id'};
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        Integer limitVal = 10;
        
        Test.startTest();
        String query = SoqlQueryBuilder.build(objectName, fields, filters, limitVal);
        Test.stopTest();
        
        System.assert(query.contains('SELECT'), 'Should contain SELECT');
        System.assert(query.contains('Name'), 'Should select Name field');
        System.assert(query.contains('FROM Account'), 'Should query Account');
        System.assert(query.contains('LIMIT 10'), 'Should have limit');
    }

    @isTest
    static void testBuildQuery_WithFilters() {
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name'};
        Integer limitVal = 5;
        
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        QueryFilterDto f1 = new QueryFilterDto();
        f1.fieldName = 'Name';
        f1.operator = '=';
        f1.value = 'TestAccount';
        filters.add(f1);
        
        Test.startTest();
        String query = SoqlQueryBuilder.build(objectName, fields, filters, limitVal);
        Test.stopTest();
        
        System.assert(query.contains('WHERE'), 'Should contain WHERE clause');
        System.assert(query.contains('Name ='), 'Should contain filter condition');
    }

    // ========== NUMERIC FIELD TESTS ==========
    
    @isTest
    static void testBuildTyped_NumericField_Integer() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'NumberOfEmployees';
        filter.operator = '>';
        filter.value = '100';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name', 'NumberOfEmployees'}, 
            new List<QueryFilterDto>{filter}, 50);
        Test.stopTest();
        
        System.assert(query.contains('NumberOfEmployees > 100'), 
            'Should format numeric without quotes: ' + query);
        System.assert(!query.contains('\'100\''), 
            'Should not quote numeric values');
    }
    
    @isTest
    static void testBuildTyped_NumericField_Equals() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'NumberOfEmployees';
        filter.operator = '=';
        filter.value = '500';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name', 'NumberOfEmployees'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('NumberOfEmployees = 500'), 
            'Should handle = operator with numeric');
    }

    @isTest
    static void testBuildTyped_NumericField_Invalid() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'NumberOfEmployees';
        filter.operator = '=';
        filter.value = 'not_a_number';
        
        Test.startTest();
        try {
            SoqlQueryBuilder.buildTyped('Account', 
                new List<String>{'Name', 'NumberOfEmployees'}, 
                new List<QueryFilterDto>{filter}, 10);
            System.assert(false, 'Should throw exception for invalid numeric');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('numeric'), 
                'Error message should indicate numeric validation failure');
            System.assert(e.getMessage().contains('NumberOfEmployees'), 
                'Error message should include field name');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBuildTyped_NumericField_LIKE_NotSupported() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'NumberOfEmployees';
        filter.operator = 'LIKE';
        filter.value = '100';
        
        Test.startTest();
        try {
            SoqlQueryBuilder.buildTyped('Account', 
                new List<String>{'Name', 'NumberOfEmployees'}, 
                new List<QueryFilterDto>{filter}, 10);
            System.assert(false, 'Should throw exception for LIKE on numeric');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('LIKE'), 
                'Should mention LIKE operator');
            System.assert(e.getMessage().contains('NumberOfEmployees'), 
                'Should mention field name');
            System.assert(e.getMessage().contains('not supported'), 
                'Should indicate operator not supported');
        }
        Test.stopTest();
    }

    // ========== BOOLEAN FIELD TESTS ==========
    
    @isTest
    static void testBuildTyped_BooleanField_True() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'IsDeleted';
        filter.operator = '=';
        filter.value = 'true';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name', 'IsDeleted'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('IsDeleted = TRUE'), 
            'Should normalize boolean to TRUE: ' + query);
    }

    @isTest
    static void testBuildTyped_BooleanField_False() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'IsDeleted';
        filter.operator = '=';
        filter.value = 'false';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name', 'IsDeleted'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('IsDeleted = FALSE'), 
            'Should normalize boolean to FALSE');
    }

    @isTest
    static void testBuildTyped_BooleanField_Variations() {
        // Test various boolean representations
        List<String> trueValues = new List<String>{'true', 'TRUE', '1', 'yes', 'YES'};
        List<String> falseValues = new List<String>{'false', 'FALSE', '0', 'no', 'NO'};
        
        for (String val : trueValues) {
            QueryFilterDto filter = new QueryFilterDto();
            filter.fieldName = 'IsDeleted';
            filter.operator = '=';
            filter.value = val;
            
            String query = SoqlQueryBuilder.buildTyped('Account', 
                new List<String>{'Name', 'IsDeleted'}, 
                new List<QueryFilterDto>{filter}, 10);
            
            System.assert(query.contains('IsDeleted = TRUE'), 
                'Value "' + val + '" should normalize to TRUE');
        }
        
        for (String val : falseValues) {
            QueryFilterDto filter = new QueryFilterDto();
            filter.fieldName = 'IsDeleted';
            filter.operator = '=';
            filter.value = val;
            
            String query = SoqlQueryBuilder.buildTyped('Account', 
                new List<String>{'Name', 'IsDeleted'}, 
                new List<QueryFilterDto>{filter}, 10);
            
            System.assert(query.contains('IsDeleted = FALSE'), 
                'Value "' + val + '" should normalize to FALSE');
        }
    }

    @isTest
    static void testBuildTyped_BooleanField_Invalid() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'IsDeleted';
        filter.operator = '=';
        filter.value = 'maybe';
        
        Test.startTest();
        try {
            SoqlQueryBuilder.buildTyped('Account', 
                new List<String>{'Name', 'IsDeleted'}, 
                new List<QueryFilterDto>{filter}, 10);
            System.assert(false, 'Should throw exception for invalid boolean');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('boolean'), 
                'Error should mention boolean');
            System.assert(e.getMessage().contains('IsDeleted'), 
                'Error should include field name');
        }
        Test.stopTest();
    }

    // Tests continue in next section...

    // ========== DATE FIELD TESTS ==========
    
    @isTest
    static void testBuildTyped_DateField_Literal() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'CreatedDate';
        filter.operator = '>';
        filter.value = 'LAST_N_DAYS:30';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name', 'CreatedDate'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('CreatedDate > LAST_N_DAYS:30'), 
            'Should handle date literal: ' + query);
    }

    @isTest
    static void testBuildTyped_DateField_ISOFormat() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'CreatedDate';
        filter.operator = '=';
        filter.value = '2024-01-15';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name', 'CreatedDate'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('2024-01-15'), 
            'Should handle ISO date format');
    }
    
    @isTest
    static void testBuildTyped_DateField_InvalidFormat() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'CreatedDate';
        filter.operator = '=';
        filter.value = '01/15/2024';
        
        Test.startTest();
        try {
            SoqlQueryBuilder.buildTyped('Account', 
                new List<String>{'Name', 'CreatedDate'}, 
                new List<QueryFilterDto>{filter}, 10);
            System.assert(false, 'Should throw exception for invalid date format');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('YYYY-MM-DD'), 
                'Should mention correct date format');
            System.assert(e.getMessage().contains('CreatedDate'), 
                'Should include field name');
        }
        Test.stopTest();
    }

    // ========== TEXT FIELD TESTS ==========
    
    @isTest
    static void testBuildTyped_TextField_LIKE() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = 'LIKE';
        filter.value = 'test';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('Name LIKE \'%test%\''), 
            'LIKE should add wildcards: ' + query);
    }

    @isTest
    static void testBuildTyped_TextField_LIKEWithExistingWildcards() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = 'LIKE';
        filter.value = '%test%';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('LIKE \'%test%\''), 
            'Should not add duplicate wildcards');
    }
    
    @isTest
    static void testBuildTyped_TextField_Equals() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = '=';
        filter.value = 'TestAccount';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('Name = \'TestAccount\''), 
            'Should quote text values');
    }

    // ========== IN OPERATOR TESTS ==========
    
    @isTest
    static void testBuildTyped_IN_Operator_Text() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = 'IN';
        filter.value = 'Account1, Account2, Account3';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('IN ('), 'Should format as IN list');
        System.assert(query.contains('\'Account1\''), 'Should include first value');
        System.assert(query.contains('\'Account2\''), 'Should include second value');
        System.assert(query.contains('\'Account3\''), 'Should include third value');
    }

    @isTest
    static void testBuildTyped_IN_Operator_Numeric() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'NumberOfEmployees';
        filter.operator = 'IN';
        filter.value = '100, 200, 300';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name', 'NumberOfEmployees'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assert(query.contains('IN (100, 200, 300)'), 
            'Numeric IN should not have quotes: ' + query);
    }

    @isTest
    static void testBuildTyped_IN_Operator_Empty() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = 'IN';
        filter.value = '';
        
        Test.startTest();
        try {
            SoqlQueryBuilder.buildTyped('Account', 
                new List<String>{'Name'}, 
                new List<QueryFilterDto>{filter}, 10);
            System.assert(false, 'Should throw exception for empty IN list');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('at least one'), 
                'Should indicate empty list error');
        }
        Test.stopTest();
    }

    // ========== LIMIT CLAMPING TESTS ==========
    
    @isTest
    static void testBuildTyped_LimitClamping_TooLow() {
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>(), 0);
        Test.stopTest();
        
        System.assert(query.contains('LIMIT 1'), 
            'Should clamp limit to minimum of 1: ' + query);
    }

    @isTest
    static void testBuildTyped_LimitClamping_TooHigh() {
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>(), 5000);
        Test.stopTest();
        
        System.assert(query.contains('LIMIT 2000'), 
            'Should clamp limit to maximum of 2000: ' + query);
    }

    @isTest
    static void testBuildTyped_LimitClamping_Null() {
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>(), null);
        Test.stopTest();
        
        System.assert(query.contains('LIMIT 50'), 
            'Should default to 50 for null limit: ' + query);
    }

    // ========== OPERATOR VALIDATION TESTS ==========
    
    @isTest
    static void testBuildTyped_InvalidOperator() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = 'INVALID_OP';
        filter.value = 'test';
        
        Test.startTest();
        try {
            SoqlQueryBuilder.buildTyped('Account', 
                new List<String>{'Name'}, 
                new List<QueryFilterDto>{filter}, 10);
            System.assert(false, 'Should throw exception for invalid operator');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Unsupported operator'), 
                'Should indicate operator validation failure');
        }
        Test.stopTest();
    }

    // ========== MULTIPLE FILTERS TESTS ==========
    
    @isTest
    static void testBuildTyped_MultipleFilters_AND() {
        QueryFilterDto filter1 = new QueryFilterDto();
        filter1.fieldName = 'Name';
        filter1.operator = 'LIKE';
        filter1.value = 'test';
        
        QueryFilterDto filter2 = new QueryFilterDto();
        filter2.fieldName = 'NumberOfEmployees';
        filter2.operator = '>';
        filter2.value = '100';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name', 'NumberOfEmployees'}, 
            new List<QueryFilterDto>{filter1, filter2}, 10);
        Test.stopTest();
        
        System.assert(query.contains(' AND '), 
            'Multiple filters should be AND-joined');
        System.assert(query.contains('Name LIKE'), 'Should include first filter');
        System.assert(query.contains('NumberOfEmployees >'), 'Should include second filter');
    }

    // ========== SQL INJECTION PREVENTION TESTS ==========
    
    @isTest
    static void testBuildTyped_SQLInjectionAttempt() {
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = '=';
        filter.value = 'test\' OR 1=1 --';
        
        Test.startTest();
        String query = SoqlQueryBuilder.buildTyped('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        // Should escape the single quote
        System.assert(query.contains('\\\''), 
            'Should escape single quotes: ' + query);
    }

    // ========== BACKWARD COMPATIBILITY TEST ==========
    
    @isTest
    static void testBuild_BackwardCompatibility() {
        // Test that old build() method still works
        QueryFilterDto filter = new QueryFilterDto();
        filter.fieldName = 'Name';
        filter.operator = '=';
        filter.value = 'test';
        
        Test.startTest();
        String query = SoqlQueryBuilder.build('Account', 
            new List<String>{'Name'}, 
            new List<QueryFilterDto>{filter}, 10);
        Test.stopTest();
        
        System.assertNotEquals(null, query, 'Old method should still work');
        System.assert(query.contains('SELECT'), 'Should generate valid query');
    }
}