@isTest
private class SoqlQueryBuilder_Tests {

    @isTest
    static void testBuildQuery_Simple() {
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name', 'Id'};
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        Integer limitVal = 10;
        
        String query = SoqlQueryBuilder.build(objectName, fields, filters, limitVal);
        
        String expected = 'SELECT Name,Id FROM Account LIMIT 10';
        // Normalize spaces for comparison
        System.assertEquals(expected, query.remove(' '), 'Basic query structure mismatch');
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
        f1.value = 'TestUser';
        filters.add(f1);
        
        String query = SoqlQueryBuilder.build(objectName, fields, filters, limitVal);
        
        System.assert(query.contains('WHERE'), 'Should contain WHERE clause');
        System.assert(query.contains('Name = \'TestUser\''), 'Should contain filter condition');
    }
    
    @isTest
    static void testBuildQuery_WithLikeOperator() {
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name'};
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        
        QueryFilterDto f1 = new QueryFilterDto();
        f1.fieldName = 'Name';
        f1.operator = 'LIKE';
        f1.value = 'Acme';
        filters.add(f1);
        
        String query = SoqlQueryBuilder.build(objectName, fields, filters, 10);
        
        // The builder adds % wildcards for LIKE
        System.assert(query.contains('LIKE \'%Acme%\''), 'Should handle LIKE operator with wildcards');
    }
    
    @isTest
    static void testBuildQuery_InjectionProtection() {
        // Attempt SOQL Injection
        String objectName = 'Account';
        List<String> fields = new List<String>{'Name'};
        List<QueryFilterDto> filters = new List<QueryFilterDto>();
        
        QueryFilterDto f1 = new QueryFilterDto();
        f1.fieldName = 'Name';
        f1.operator = '=';
        f1.value = 'test\' OR Name != \''; // Malicious input
        filters.add(f1);
        
        String query = SoqlQueryBuilder.build(objectName, fields, filters, 1);
        
        // Assert that the single quote was escaped
        System.assert(query.contains('test\\\''), 'Should escape single quotes');
    }
}