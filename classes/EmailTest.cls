@IsTest
private class EmailTest {
    @IsTest
    static void testSalesInvoiceEmailing() {
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Sales_Invoice__c salesInvoice = TestDataUtil.SalesInvoiceRecord;
        //ticket 21113 <<
        //EmailHandler.EmailWrap emailWrap = EmailHandler.prepareEmailWrapByRecordId(salesInvoice.Id);
        EmailHandler.getSalesInvoice(salesInvoice.Id);
        EmailHandler.EmailWrap salesInvoiceEmailMessage = EmailHandler.initInvoiceEmailMessage(salesInvoice.Id);

        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecord;
        salesOrder.Document_Type__c = 'Sales Quote';
        Contact quoteContact = TestDataUtil.Contact2Record;
        salesOrder.Quote_Contact__c = quoteContact.Id;
        update salesOrder;
        EmailHandler.getSalesQuote(salesOrder.Id);
        EmailHandler.saveQuotePDFReportParameters(salesOrder.Id, 'Detail', true);
        EmailHandler.EmailWrap salesOrderEmailMessage = EmailHandler.initQuoteEmailMessage(salesOrder.Id);
        //ticket 21113 >>

        List<String> toAddress = new List<String>{ 'abc@abc.com' };
        ContentVersion contentVersionInsert = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
                IsMajorVersion = true
        );
        insert contentVersionInsert;

        Id docId;
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        for (ContentDocument document : documents) {
            docId = document.Id;
        }

        //ticket 21113 <<
        //EmailHandler.sendEmail(toAddress, 'abc@abc.com', 'subject', 'body', docId, 'Sender Name', 'sender@emailaddress.com', null, salesInvoice.Id);
        salesInvoiceEmailMessage.contentDocumentIds = docId;
        EmailHandler.sendEmail(JSON.serialize(salesInvoiceEmailMessage));
        //ticket 21113 >>

        //ticket 19127 <<
        //FileUploadHandler.generateAndSaveDocument(salesInvoice.Id, 'Detail');

        Sales_Invoice_Job_Task__c salesInvoiceJobTask = new Sales_Invoice_Job_Task__c();
        salesInvoiceJobTask.Sales_Invoice__c = salesInvoice.Id;
        salesInvoiceJobTask.Line_No__c = 1;
        salesInvoiceJobTask.Name = 'Test';
        salesInvoiceJobTask.Invoice_Format__c = 'Detail';
        insert salesInvoiceJobTask;

        //ticket 21113 <<
        //FileUploadHandler.generateAndSaveDocument(salesInvoice.Id);
        Map<String, String> params = new Map<String, String>();
        params.put('Id', salesInvoice.Id);
        Id salesInvoicePDFContentDocumentId = FileUploadHandler.generateAndSaveDocument(salesInvoice.Id, 'NewSalesInvoicePDF', JSON.serialize(params), null);

        Map<Integer, String> mapContentDocumentIdsBySequence = new Map<Integer, String>();
        Integer i = 0;
        for (ContentDocument document : [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument]) {
            i++;
            mapContentDocumentIdsBySequence.put(i, document.Id);
        }
      
        FileUploadHandler.createContentDistribution(JSON.serialize(mapContentDocumentIdsBySequence));
        //ticket 21113 >>
        FileUploadHandler.getRelatedFiles(salesInvoice.Id);


        FileUploadHandler.getJobTasks(salesInvoice.Id);

        FileUploadHandler.saveInvoiceFormat(JSON.serialize(new List<Sales_Invoice_Job_Task__c>{ salesInvoiceJobTask }));
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        FileUploadHandler.mergeDocuments(salesInvoice.Id, JSON.serialize(mapContentDocumentIdsBySequence),null);
       
        Test.stopTest();
        //ticket 19127 >>
    }

    @IsTest
    static void testDeleteContentDocument(){

        ContentVersion contentVersionInsert = new ContentVersion(
                Title = 'Test',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
                IsMajorVersion = true
        );
        insert contentVersionInsert;

        // Test INSERT
        ContentVersion contentVersionSelect = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionInsert.Id LIMIT 1];
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1);

        ContentDocumentsService.createEmailedContentDocumentHistroy(documents[0].Id, new List<Id>{documents[0].Id});
        String uploadedFileResponse = '{"documentId":"' + documents[0].Id + '"}';
        FileUploadHandler.processUploadedDocuments(uploadedFileResponse,null);
        
          Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
      
        FileUploadHandler.convertFilesToPdf('https://www.google.com');
        Test.stopTest();
        try {
            // Test DELETE
            documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            try {
                delete documents;
            } catch (Exception ex) {
            }
        }
        catch (exception ex) {

        }

        try {
            List<Emailed_Document__c> emailedDocuments = [SELECT Id FROM Emailed_Document__c];
            delete emailedDocuments;
            delete documents;
        } catch (Exception ex){
        }
    }
     @IsTest
    static void testValidateErrorMessage() {
        String EXPECTED_ERROR_MESSAGE = 'Insert failed. First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, Document type file name cannot exceed 80 characters.  Please rename the file to be 80 characters or less.: []';
        String ACTUAL_ERROR_MESSAGE;
        Test.StartTest();
        try{
              ContentVersion contentVersionInsert = new ContentVersion(
                Title = 'this_is_a_sample_file_name_with_100_characters_and_numbers_1234567890_and_special_characters_!@#$%^&()-_=+[{]};',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
                IsMajorVersion = true
        );
        insert contentVersionInsert;
        }catch (Exception ex){
            ACTUAL_ERROR_MESSAGE = ex.getMessage();
        }
              
        Test.StopTest();
        System.assertEquals(EXPECTED_ERROR_MESSAGE,ACTUAL_ERROR_MESSAGE);
    }
    
      @IsTest
    static void testValidateTypeFieldIsNull() {
        Test.StartTest();
                ContentVersion contentVersionInsert = new ContentVersion(
                Title = 'this_is_a_sample_file_name',
                PathOnClient = 'Test.jpg',
                VersionData = Blob.valueOf('Test Content Data'),
				Type_fileupload__c = 'Manifest_BOL',
                IsMajorVersion = true
        );
        insert contentVersionInsert;
        Test.StopTest();
    }
  
}