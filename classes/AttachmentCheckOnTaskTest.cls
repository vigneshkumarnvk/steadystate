@isTest
public class AttachmentCheckOnTaskTest {
    
     @isTest static void TestTaskwithAttachment(){
        //Test data setup
        //Create an task
        
        Task tsk = new task();
        insert tsk;
        
        //Create a ContentVersion
    
        ContentVersion ContentDoc = new ContentVersion();
        ContentDoc.Title = 'My Doc';
        ContentDoc.ContentUrl= 'test.com';
        Insert ContentDoc;
        
		ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :ContentDoc.Id];
        
        // Create a ContentDocumentLink
        ContentDocumentLink ContentDL = new ContentDocumentLink();
        ContentDL.ContentDocumentId = testcontent.contentdocumentid;
        ContentDL.LinkedEntityId=tsk.id;
        ContentDL.ShareType='I';
        Insert ContentDL;
        
        //Assert checkbox field
        System.assert(tsk.HasAttachement__c=TRUE);
    }

}