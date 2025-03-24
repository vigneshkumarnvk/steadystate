@isTest
private class WorkOrderAttachmentInfoTest {
    
    @isTest
    static void testGetCustomMetadataRecords() {
        Test.startTest();
        List<Map<String, Object>> customMetadata = WorkOrderAttachmentInfo.getCustomMetadataRecords();
        Test.stopTest();
        
        System.assertNotEquals(null, customMetadata, 'Custom metadata should not be null');
        System.assertEquals(1, customMetadata.size(), 'Expected one custom metadata record');
        
        Map<String, Object> metadataRecord = customMetadata[0];
        System.assertEquals('GetWorkOrderAttachmentInfo', metadataRecord.get('API_Extension_Name__c'),
                            'Expected API_Extension_Name__c to be GetWorkOrderAttachmentInfo');
    }
    
    @isTest
    static void testGetDocumentTypeID() {
        Test.startTest();
        String documentTypeID = WorkOrderAttachmentInfo.getDocumentTypeID('TestDocumentType');
        Test.stopTest();
        
        System.assertEquals(null, documentTypeID, 'Expected document type ID to be null for TestDocumentType');
        
    }
    
    @IsTest
    private static void testSalesInvoiceService(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord; //needed for numbering series data
        CompanyMgmt.byPassTrigger = true;
         Account corporate = TestDataUtil.corporateAccountRecord;
        corporate.Invoice_Submission_Channels__c ='INVOICE_PORTAL';
        corporate.PO_Number_Type__c = 'ALPHANUMERICAL';
        update corporate;
        Salesperson__c salesPerson = TestDataUtil.SalespersonRecord;
        salesPerson.Territory_Code__c = 'test123';
        salesPerson.Internal_Contact__c = true;  
        update salesPerson;

        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Order';
        salesOrder.Site_Name__c = 'MDN Test';
        salesOrder.Create_Site_Address__c = true;
        salesOrder.Bill_to_Customer_No__c = corporate.Id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.Id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesOrder.Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id;
        salesOrder.Total_Margin_Pct__c = 10;
        salesOrder.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        salesOrder.Approved__c = true;
        salesOrder.Approved_Profit_Margin__c = 40;
        salesOrder.Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25);
        salesOrder.OwnerId = UserInfo.getUserId();
        salesOrder.EqaiGeneratorId__c = 343003;
        salesOrder.Internal_Comments__c = 'During UAT for billing project creation,several fields were found to be errors and also new requirements needed';
        salesOrder.Account_Executives__c = salesPerson.id;
        insert salesOrder;
        
        
        Service_Center__c sc = new Service_Center__c();
        sc.id = TestDataUtil.ServiceCenterRecord.Id;
        sc.Name = '64';
        sc.Include_SO_in_EQAI_Invoice_Integration__c = True;
        update sc;
        
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c();
        salesInvoice.Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id;
        salesInvoice.Salesperson__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Account_Executive__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesInvoice.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        salesInvoice.Service_Center__c = sc.Id;
        salesInvoice.Document_Status__c = 'Open';
        salesInvoice.Approval_Status__c = 'Approved';
        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        salesInvoice.OwnerId = UserInfo.getUserId();
        salesInvoice.Contract__c = TestDataUtil.ContractRecord.Id;
        insert salesInvoice;
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpBillingJobResponseGenerator());
        WorkOrderAttachmentInfo.updateDocumentTypeID(salesInvoice.id);
        salesInvoice.Document_Status__c = 'Sent to EQAI';
        update salesInvoice; 
        
        HttpCalloutMock mock = new MockHttpResponse();
        Test.setMock(HttpCalloutMock.class, mock);
                String result = WorkOrderAttachmentInfo.executeTransactionCompleteCallout(salesInvoice.id);
        //System.debug('Run Test');
        Test.stopTest();
    }
    @isTest
    static void testGetRecordTypesForUser() {
        // Create a test user with the desired profile
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User testUser =  new User(LastName = 'recordtype',
                               FirstName='Testing',
                               Alias = 'jliv',
                               Email = 'recordTypeTetinging@republicservices.com',
                               Username = 'recordTypeTetinging12@republicservices.com',
                               ProfileId = profile.id,
                               TimeZoneSidKey = 'GMT',
                               LanguageLocaleKey = 'en_US',
                               EmailEncodingKey = 'UTF-8',
                               LocaleSidKey = 'en_US'
                               );
                    insert testUser ;
        System.runAs(testUser) {

            List<Map<String, String>> recordTypes = WorkOrderAttachmentInfo.getRecordTypesForUser();
           
        }
    }
}