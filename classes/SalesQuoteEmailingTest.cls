@IsTest
private class SalesQuoteEmailingTest {
    @IsTest
    private static void testEmailSalesQuote(){
        Company_Setup__c setup = TestDataUtil.CompanySetupRecord;
        Test.startTest();


        Sales_Order__c salesQuote = TestDataUtil.SalesOrderRecord;
        salesQuote.Document_Type__c = 'Sales Quote';
        salesQuote.Quote_Contact__c = TestDataUtil.Contact2Record.Id;
        salesQuote.Site_Scope__c = 'test';
        salesQuote.Approval_Status__c = 'Approved';
        update salesQuote;
        
        Signature__c currSign = new Signature__c();
        currSign.Sales_Order__c = salesQuote.id;
        currSign.Email__c = 'Test@gmail.com';
        currSign.Signed__c = True;
        currSign.Request_Signature__c = True;
        insert currSign;

        PageReference pageReference = Page.EmailSalesQuote;
        Test.setCurrentPage(pageReference);
        pageReference.getParameters().put('id', salesQuote.Id);
        ApexPages.StandardController stdCon = new ApexPages.StandardController(salesQuote);
        SalesQuoteEmailing controller = new SalesQuoteEmailing(stdCon);
        List<SelectOption> options = controller.lstPrintType;
        String title = controller.title;
        controller.EmailSalesQuote();
        controller.returnBack();


        Blob pdf = SalesQuoteEmailing.generateQuotePDF(salesQuote.Id);
        

        Signature_Request__c signatureRequest = new Signature_Request__c();
        signatureRequest.Related_To_Id__c = salesQuote.Id;
        signatureRequest.Related_To_Object_Name__c = 'Sales_Order__c';
        signatureRequest.Print_Name__c = 'Smith';
        signatureRequest.Email__c = 'test@abc.com';
        signatureRequest.Customer_PO_No__c = '1222';
        signatureRequest.Customer_Comment__c = 'Comment';
        signatureRequest.Request_Date__c = System.today().addDays(-2);
        insert signatureRequest;

        salesQuoteEmailing.notifySignedQuote(signatureRequest);
        salesQuoteEmailing.notifyRejectedQuote(signatureRequest);
        salesQuoteEmailing.notifyUnansweredSignatureRequest(signatureRequest);
        SalesQuoteEmailing.saveQuotePDF(salesQuote,pdf,'test');
        SalesQuoteEmailing.sendQuotePDF(salesQuote, pdf);
       

    }
}
