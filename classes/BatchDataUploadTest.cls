/******************************************************************************************************************
* Name         :  BatchDataUploadTest 
* Description  :  TestClass for BatchDataUpload class.
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vignesh Kumar N         01-15-2024             Initial Version
***********************************************************************************************************************/
@isTest
public class BatchDataUploadTest {
    
    @testSetup static void setupData() {
        NewTestData.createTestData();
        Contract ctrct = [SELECT Id, Name FROM Contract WHERE Name = 'Contract' LIMIT 1];
        Assert.areEqual('Contract', ctrct.Name, 'Contract not created');
    }
    
    @isTest static void batchUploadPositive() {
        Test.startTest();
        Id recordId = [SELECT Id, Name FROM Contract WHERE Name = 'Contract' LIMIT 1].Id;        
        Resource_Type__c rtype = [SELECT Id, Unit_of_Measure__C FROM Resource_Type__c LIMIT 1];
        
        String csvTestData = 'Resource_Type__c,Resource__c,Unit_of_Measure__c,Customer_Item_No__c,Customer_Description__c,Regular_Rate__c,Customer_Overtime_Item_No__c,Customer_Overtime_Description__c,Overtime_Rate__c\n'+
            rtype.Id+', ,'+rtype.Unit_of_Measure__c+', \'Test Customer Item No\', \"Test Customer Desc\",100,150,Test OverTime Desc,200';
        
        ContentVersion cv = createTestContentVersion('Test document', '.csv', csvTestData);        
        DataUploadHandler.executeDataUploadBatch(recordId, cv.Id, 'Contract_Line__c');
        
        Test.stopTest();
    }
    
    @isTest static void batchUploadNegative() {
        Test.startTest();
        Id recordId = [SELECT Id, Name FROM Contract WHERE Name = 'Contract' LIMIT 1].Id;  
        String csvTestDataFail = 'Resource_Type__c,Resource__c,Unit_of_Measure__c,Customer_Item_No__c,Customer_Description__c,Regular_Rate__c,Customer_Overtime_Item_No__c,Customer_Overtime_Description__c,Overtime_Rate__c\n'+
            ' , , , \'Test Customer Item No\', \"Test Customer Desc\",100.2,150.65,Test OverTime Desc,200';
        
        ContentVersion cv1 = createTestContentVersion('Test Document','.csv', csvTestDataFail);         
        DataUploadHandler.executeDataUploadBatch(recordId, cv1.Id, 'Contract_Line__c');
        DataUploadHandler.executeDataUploadBatch(recordId, cv1.Id, 'Contract_Lines__c');
        
        String csvTestDataFail1 = 'Resource_Type__c,Resource__c,Unit_of_Measure__c\n'+
            ' , , ';
        
        ContentVersion cv2 = createTestContentVersion('Test Document','.csv', csvTestDataFail1);     
        DataUploadHandler.executeDataUploadBatch(recordId, cv2.Id, 'Contract_Line__c');
        
        ContentVersion contVer = createTestContentVersion('Test Document','.pdf', 'Test Document pdf');     
        DataUploadHandler.executeDataUploadBatch(recordId, contVer.Id, 'Contract_Line__c');
        
        Test.stopTest();
    }
    
    private static ContentVersion createTestContentVersion(String title, String fileType, String content) {
        ContentVersion contVer = new ContentVersion();
        contVer.Title = title;
        contVer.PathOnClient = title + fileType;
        contVer.VersionData = Blob.valueOf(content);
        contVer.IsMajorVersion = true;
        Insert contVer; 
        return contVer;
    }   
}