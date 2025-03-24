/******************************************************************************************************************
* Name         :  CustomNotesAndAttachmentTest
* Description  :  Test Class for CustomNotesAndAttachment.
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vignesh Kumar N         12-19-2024             US135128: Initial Version
* Vignesh Kumar N         12-31-2024             US135129: Levels of Authority Documentation - Contract
***********************************************************************************************************************/
@isTest
Public class CustomNotesAndAttachmentTest {
    
    @testSetup static void setupTestData() {
        NewTestData.createTestData(); 
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        Assert.areEqual('SO1', salesOrder.Name, 'Sales Order SO1 not created');
    }
    
    @isTest static void testGetObjectInfo() {
        Test.startTest();
        Sales_Order__c salesOrder = [SELECT Id FROM Sales_Order__c WHERE Name = 'SO1' LIMIT 1];
        CustomNotesAndAttachment.getObjectInfo(null);
        Map<String, String> objectInfo = new Map<String, String>();
        if (salesOrder != NULL) {
            objectInfo = CustomNotesAndAttachment.getObjectInfo(salesOrder.Id);
            Assert.areEqual('Sales_Order__c', objectInfo.get('objectApiName'), 'Not Sales Order Object Info'); 
        }         
        
        //US135129
        Contract cntrct = [SELECT Id FROM Contract WHERE Name = 'Contract' LIMIT 1];
        if (cntrct != NULL) {
            CustomNotesAndAttachment.getObjectInfo(cntrct.Id);
        }
        
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.pdf';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.Custom_N_A_fileupload__c = 'Custom_NotesAndAttachment';
        Insert cv; 
        
        Id contDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        //Create ContentDocumentLink 
        ContentDocumentLink contDocLink = New ContentDocumentLink();
        contDocLink.LinkedEntityId = salesOrder.Id;
        contDocLink.ContentDocumentId = contDocId;
        Insert contDocLink;
        
        CustomNotesAndAttachment.fetchUploadedFiles(salesOrder.Id);
        
        String contDocVer = [SELECT Custom_N_A_fileupload__c FROM ContentVersion 
                             WHERE Id =:cv.Id].Custom_N_A_fileupload__c;       
        
        ContentVersion uploadNewVersion = new ContentVersion();
        uploadNewVersion.Title = 'Test Document Updated';
        uploadNewVersion.PathOnClient = 'TestDocument.pdf';
        uploadNewVersion.VersionData = Blob.valueOf('Test Content Updated');
        uploadNewVersion.IsMajorVersion = true;
        uploadNewVersion.ContentDocumentId = contDocId;
        uploadNewVersion.Custom_N_A_fileupload__c = 'Custom_NotesAndAttachment-'+(String)contDocId;
        Insert uploadNewVersion;
        
        CustomNotesAndAttachment.fetchUploadedFiles(contDocId); 
        
        Test.stopTest();
    }
}