@isTest
public class ContentVersionTest {
    
    @testSetup static void setup(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord; //needed for numbering series data

        Service_Center__c serviceCenter = TestDataUtil.ServiceCenterRecord;
        User testUser = TestDataUtil.UserRecord;
    }
    
    @isTest
    static void testContentVersionRecord() {
         CompanyMgmt.byPassTrigger = true;
        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Order';
        salesOrder.Site_Name__c = 'MDN Test';
        salesOrder.Create_Site_Address__c = true;
        salesOrder.Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.subsidiarycompanyRecord.id;
        salesOrder.Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id;
        salesOrder.Total_Margin_Pct__c = 10;
        salesOrder.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        salesOrder.Approved__c = true;
        salesOrder.Approved_Profit_Margin__c = 40;
        salesOrder.Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25);
        salesOrder.OwnerId = UserInfo.getUserId();
        insert salesOrder;

        Sales_Invoice__c salesInvoice = new Sales_Invoice__c();
        salesInvoice.Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id;
        salesInvoice.Salesperson__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Account_Executive__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesInvoice.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        salesInvoice.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesInvoice.Document_Status__c = 'Posted';
        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        salesInvoice.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        salesInvoice.OwnerId = UserInfo.getUserId();
        insert salesInvoice;
        
        CompanyMgmt.byPassTrigger = false;
        
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body to be insert in test class for testing the'); 
        
        ContentVersion contentVersion_1 = new ContentVersion(
            Title='SampleTitle', 
            PathOnClient ='SampleTitle.jpg',
            VersionData = bodyBlob, 
            origin = 'H',
            FirstPublishLocationId = salesInvoice.Id,
            Type_fileupload__c = 'Manifest_BOL'
        );
        insert contentVersion_1;
        contentVersion_1.IsAllow20__c = true;
        contentVersion_1.IsAllow50__c = true;
        contentVersion_1.IsAllow1Mb__c = true;
        try{
            update contentVersion_1;  
        }catch(Exception e){
            
        }
        
        //US135128
        ContentVersion cntVr = new ContentVersion();
        cntVr.Title = 'Test Document Updated';
        cntVr.PathOnClient = 'TestDocument.pdf';
        cntVr.VersionData = Blob.valueOf('Test Content Updated');
        cntVr.IsMajorVersion = true;
        Insert cntVr;
        
        Id contDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cntVr.Id].ContentDocumentId;
        
        ContentVersion uploadNewVersion = new ContentVersion();
        uploadNewVersion.Title = 'Test Document Updated';
        uploadNewVersion.PathOnClient = 'TestDocument.pdf';
        uploadNewVersion.VersionData = Blob.valueOf('Test Content Updated');
        uploadNewVersion.IsMajorVersion = true;
        uploadNewVersion.Custom_N_A_fileupload__c = 'Custom_NotesAndAttachment-'+contDocId;
        Insert uploadNewVersion;
        
        
    }
}