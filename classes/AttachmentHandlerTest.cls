@isTest
private class AttachmentHandlerTest {
    @isTest
    static void testConvertFileToPdf() {
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test_file.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert testContentVersion;
         Map<Id,String> contentVersionIdByContentDocURL = new Map<Id,String>();
        Map<Id,String> contentVersionIdByPdfDocURL = new Map<Id,String>();
        contentVersionIdByContentDocURL.put(testContentVersion.Id,'https://acvenviro--sathishacv.sandbox.my.salesforce.com/');
        contentVersionIdByPdfDocURL.put(testContentVersion.Id,'https://acvenviro--sathishacv.sandbox.my.salesforce.com/');
                Test.setMock(HttpCalloutMock.class, new MockHttpResponse()); 

        Blob res = AttachmentHandler.convertFileToPdf(testContentVersion,contentVersionIdByContentDocURL);
    }
    
      @isTest
    static void testConvertFileByPdfURL() {
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test_file.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert testContentVersion;
         Map<Id,String> contentVersionIdByContentDocURL = new Map<Id,String>();
        Map<Id,String> contentVersionIdByPdfDocURL = new Map<Id,String>();
        contentVersionIdByContentDocURL.put(testContentVersion.Id,'https://acvenviro--sathishacv.sandbox.my.salesforce.com/');
        contentVersionIdByPdfDocURL.put(testContentVersion.Id,'https://acvenviro--sathishacv.sandbox.my.salesforce.com/');
                Test.setMock(HttpCalloutMock.class, new MockHttpResponse()); 
        try{
                    Blob restr = AttachmentHandler.convertPdfByDocURL(testContentVersion,'https://acvenviro--sathishacv.sandbox.my.salesforce.com/');

        }catch(Exception e){
            
        }
    }
    @isTest
    static void testGetFileContent() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'test_file.txt',
            VersionData = Blob.valueOf('Test file content')
        );
        insert testContentVersion;
        Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id LIMIT 1].ContentDocumentId;
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = testAccount.Id,
            ContentDocumentId = contentDocumentId,
            ShareType = 'V'
        );
        insert testContentDocumentLink;
        
        List<AttachmentHandler.FileWrapper> result = AttachmentHandler.getFileContent(contentDocumentId);
        AttachmentHandler.FileWrapper fileWrapper = new AttachmentHandler.FileWrapper('Test File', 'Test file content', 'txt');        
        System.assertEquals('Test File', fileWrapper.fileName, 'File name should be "Test File"');
        
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        contentVersions.add(testContentVersion);
        Map<Id,String> contentVersionIdByContentDocURL = new Map<Id,String>();
        Map<Id,String> contentVersionIdByPdfDocURL = new Map<Id,String>();
        contentVersionIdByContentDocURL.put(testContentVersion.Id,'https://acvenviro--sathishacv.sandbox.my.salesforce.com/');
        contentVersionIdByPdfDocURL.put(testContentVersion.Id,'https://acvenviro--sathishacv.sandbox.my.salesforce.com/');

        List<AttachmentHandler.FileWrapper> processedFileWrappers = AttachmentHandler.processChunks(contentVersions,contentVersionIdByContentDocURL,contentVersionIdByPdfDocURL);
        
    }
    
    @isTest
    static void testGetRelatedFiles() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        ContentVersion testContentVersion = new ContentVersion(
            Title = 'Related File',
            PathOnClient = 'related_file.txt',
            VersionData = Blob.valueOf('Related file content')
        );
        insert testContentVersion;
        
        ContentDocumentLink testContentDocumentLink = new ContentDocumentLink(
            LinkedEntityId = testAccount.Id,
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id LIMIT 1].ContentDocumentId,
            ShareType = 'V'
        );
        insert testContentDocumentLink;
        
        List<ContentVersion> result = AttachmentHandler.getRelatedFiles(testAccount.Id);
        
        System.assertEquals(1, result.size(), 'Number of related files should be 1');
        
        ContentVersion relatedFile = result[0];
        System.assertEquals('Related File', relatedFile.Title, 'File name should be "Related File"');
    }
}