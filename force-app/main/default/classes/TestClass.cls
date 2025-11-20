public with sharing class TestClass {
    public TestClass() {
        Account acc = new Account();
        acc.Name = 'Test Account Do Nothing';
        insert acc;
    }
}