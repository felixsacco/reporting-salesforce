@IsTest
/**
 * Test data factory for creating records used by Apex unit tests.
 *
 * This factory currently provides helpers to create parent records and
 * related Attachments for file-reporting test scenarios.
 */
public class TestDataFactory {

    public static void createAttachment() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Attachment att = new Attachment();
        att.Name = 'TestFile.txt';
        att.Body = Blob.valueOf('Test Content');
        att.ParentId = acc.Id;
        insert att;
    }
}