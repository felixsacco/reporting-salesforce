/**
 * @description Test class for QueryFilterDto.
 *              Tests the parseValues method for multi-value operator support.
 * 
 * @author Agent Mritesh
 * @date 2026-02-17
 * @version 1.2.0
 */
@isTest
private class QueryFilterDto_Tests {
    
    @isTest
    static void testParseValues_CommaSeparated() {
        // Test parsing comma-separated values
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = 'value1, value2, value3';
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        System.assertEquals(3, values.size(), 'Should parse 3 values');
        System.assertEquals('value1', values[0], 'First value should be trimmed');
        System.assertEquals('value2', values[1], 'Second value should be trimmed');
        System.assertEquals('value3', values[2], 'Third value should be trimmed');
    }
    
    @isTest
    static void testParseValues_SemicolonSeparated() {
        // Test parsing semicolon-separated values
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = 'value1;value2;value3';
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        System.assertEquals(3, values.size(), 'Should parse 3 values');
        System.assertEquals('value1', values[0], 'Values should be parsed with semicolon');
        System.assertEquals('value2', values[1], 'Values should be parsed with semicolon');
        System.assertEquals('value3', values[2], 'Values should be parsed with semicolon');
    }
    
    @isTest
    static void testParseValues_MixedWhitespace() {
        // Test parsing with various whitespace
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = '  value1  ,  value2  , value3  ';
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        System.assertEquals(3, values.size(), 'Should handle whitespace');
        System.assertEquals('value1', values[0], 'Should trim leading/trailing whitespace');
        System.assertEquals('value2', values[1], 'Should trim leading/trailing whitespace');
        System.assertEquals('value3', values[2], 'Should trim leading/trailing whitespace');
    }
    
    @isTest
    static void testParseValues_EmptyString() {
        // Test with empty value
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = '';
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        System.assertEquals(0, values.size(), 'Should return empty list for empty string');
    }
    
    @isTest
    static void testParseValues_NullValue() {
        // Test with null value
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = null;
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        System.assertEquals(0, values.size(), 'Should return empty list for null');
    }
    
    @isTest
    static void testParseValues_SingleValue() {
        // Test with single value (no delimiter)
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = 'singlevalue';
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        System.assertEquals(1, values.size(), 'Should return single value');
        System.assertEquals('singlevalue', values[0], 'Value should match');
    }
    
    @isTest
    static void testParseValues_EmptyElements() {
        // Test with empty elements (e.g., "value1,,value2")
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = 'value1,,value2,  ,value3';
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        // Should skip empty/whitespace-only elements
        System.assertEquals(3, values.size(), 'Should skip empty elements');
        System.assertEquals('value1', values[0], 'First non-empty value');
        System.assertEquals('value2', values[1], 'Second non-empty value');
        System.assertEquals('value3', values[2], 'Third non-empty value');
    }
    
    @isTest
    static void testParseValues_OnlyDelimiters() {
        // Test with only delimiters
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = ',,,';
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        System.assertEquals(0, values.size(), 'Should return empty list when only delimiters');
    }
    
    @isTest
    static void testParseValues_SpecialCharacters() {
        // Test with special characters in values
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = 'value@1, value#2, value$3';
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        System.assertEquals(3, values.size(), 'Should parse values with special chars');
        System.assertEquals('value@1', values[0], 'Should preserve special characters');
        System.assertEquals('value#2', values[1], 'Should preserve special characters');
        System.assertEquals('value$3', values[2], 'Should preserve special characters');
    }
    
    @isTest
    static void testParseValues_PrefersSemicolon() {
        // Test that semicolon is preferred when both delimiters present
        QueryFilterDto filter = new QueryFilterDto();
        filter.value = 'val1,val2;val3,val4';
        
        Test.startTest();
        List<String> values = filter.parseValues();
        Test.stopTest();
        
        // Should split by semicolon when both present
        System.assertEquals(2, values.size(), 'Should use semicolon when both delimiters present');
        System.assertEquals('val1,val2', values[0], 'First part before semicolon');
        System.assertEquals('val3,val4', values[1], 'Second part after semicolon');
    }
}