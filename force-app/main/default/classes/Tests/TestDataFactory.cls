@IsTest
public class TestDataFactory {
    public static void createAttachment() {
        // Create parent account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Attachment att = new Attachment();
        att.Name = 'TestFile.txt';
        att.Body = Blob.valueOf('Test Content');
        att.ParentId = acc.Id;
        insert att;
    }
}