@isTest
public class SalesInvoiceEmailingTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }

    private static testMethod void Test_SalesInvoiceEmailing() {
        Sales_Invoice__c SalesInvoiceRecord=TestDataUtil.SalesInvoiceRecord;
        SalesInvoiceRecord.Contact__c=TestDataUtil.Contact2Record.id;
        update SalesInvoiceRecord;
        Test.setCurrentPageReference(new PageReference('Page.EmailSalesInvoicePreview'));
        System.currentPageReference().getParameters().put('Id', SalesInvoiceRecord.id);
        ApexPages.StandardController sc = new ApexPages.standardController(SalesInvoiceRecord);
        SalesInvoiceEmailing RO = new SalesInvoiceEmailing(sc);
        String title=RO.title;
        RO.EmailSI();
        RO.returnBack();
        List<SelectOption> lstInvoiceType=RO.lstInvoiceType;
    }

}