@isTest
private class SalesInvoicePDFControllerTest {
    private static testMethod void test() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
        PageReference pdfPage = Page.NewSalesInvoicePDF;
        Test.setCurrentPage(pdfPage);
        ApexPages.currentPage().getParameters().put('id', salesInvoice.Id);

        ApexPages.currentPage().getParameters().put('InvoiceType', 'TM by Date by Category');
        SalesInvoicePDFController salesInvoicePDFController = new SalesInvoicePDFController();

        Test.stopTest();
    }
    private static testMethod void test1() {
        NewTestData.createTestData();
        Test.startTest();
		List<Contract> contractList = [SELECT ID, Name,Override_Remittance_on_Invoice__c FROM Contract];

        for(Contract updContract : contractList){
            updContract.Override_Remittance_on_Invoice__c = false;
        }
        update contractList;
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');

        PageReference pdfPage = Page.NewSalesInvoicePDF;
        Test.setCurrentPage(pdfPage);
        ApexPages.currentPage().getParameters().put('id', salesInvoice.Id);

        ApexPages.currentPage().getParameters().put('InvoiceType', 'TM by Date by Category');
        SalesInvoicePDFController salesInvoicePDFController = new SalesInvoicePDFController();

        Test.stopTest();
    }    
    private static testMethod void test2() {
        NewTestData.createTestData();
        Test.startTest();
        List<Service_Center__c> serviceCenterList = [SELECT Id, Name,Override_Remittance_on_Invoice__c FROM Service_Center__c];
        for(Service_Center__c srvCent: serviceCenterList){
            srvCent.Override_Remittance_on_Invoice__c = true;
        }
        update serviceCenterList;
        
        List<Contract> contractList = [SELECT ID, Name,Override_Remittance_on_Invoice__c FROM Contract];
        for(Contract updContract : contractList){
            updContract.Override_Remittance_on_Invoice__c = false;
        }
        update contractList;

        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');

        PageReference pdfPage = Page.NewSalesInvoicePDF;
        Test.setCurrentPage(pdfPage);
        ApexPages.currentPage().getParameters().put('id', salesInvoice.Id);

        ApexPages.currentPage().getParameters().put('InvoiceType', 'TM by Date by Category');
        SalesInvoicePDFController salesInvoicePDFController = new SalesInvoicePDFController();

        Test.stopTest();
    }
}