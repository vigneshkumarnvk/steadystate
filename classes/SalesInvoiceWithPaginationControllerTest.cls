/**
 * Created by Steven on 3/30/2020..
 */

@IsTest
public with sharing class SalesInvoiceWithPaginationControllerTest {
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @TestSetup static void SetupData() {
        //Setup Data
        CompanyMgmt.byPassTrigger = true;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceRecord;
        List<Sales_Invoice_Line__c> testSalesInvoiceLineRecords = TestDataUtil.SalesInvoiceLineRecords;
        Resource__c ResourceRecord = TestDataUtil.ResourceRecord;
        GL_Entry__c GLEntryRecord = TestDataUtil.GLEntryRecord;
        Tax_Jurisdiction__c taxJurisdiction = TestDataUtil.TaxJurisdictionRecord;
        Tax_Detail__c taxDetail = TestDataUtil.TaxDetailRecord;
        Tax_Area__c taxArea = TestDataUtil.TaxAreaRecord;
        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        Account AccountRecord = TestDataUtil.AccountRecord;
        Salesperson__c SalespersonRecord = TestDataUtil.SalespersonRecord;
        Subsidiary_Company__c SubsidiaryCompanyRecord = TestDataUtil.SubsidiaryCompanyRecord;
        Service_Center__c ServiceCenterRecord = TestDataUtil.ServiceCenterRecord;
        Payment_Term__c PaymentTermRecord = TestDataUtil.PaymentTermRecord;
    }

    @IsTest
    private static void Test_SalesInvoiceWithPaginationController() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        Test.startTest();
        Sales_Invoice__c SalesInvoiceRecord = [SELECT Id FROM Sales_Invoice__c LIMIT 1];
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);
        SalesInvoiceWithPaginationController inst_SIC = new SalesInvoiceWithPaginationController(StdCon);

        Boolean allowDataOverride = inst_SIC.allowDataOverride;

        Sales_Invoice__c SI = inst_SIC.SI;
        Company_Setup__c CompanySetup = inst_SIC.CompanySetup;
        String[] messagesWS = inst_SIC.getMessages();

        inst_SIC.validateBillToCustomer();
        inst_SIC.validateTaxArea();
        inst_SIC.validateTaxLiable();
        inst_SIC.validateContact();
        inst_SIC.save();
        inst_SIC.cancel();
        inst_SIC.returnBack();
        inst_SIC.quickSaveForLinePaginationPage();

        Test.stopTest();
    }

    @IsTest
    private static void Test_Pagination() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        Test.startTest();
        Sales_Invoice__c SalesInvoiceRecord = [SELECT Id FROM Sales_Invoice__c LIMIT 1];
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);
        SalesInvoiceWithPaginationController inst_SIC = new SalesInvoiceWithPaginationController(StdCon);
        List<Sales_Invoice_Line__c> salesInvoiceLines = inst_SIC.salesInvoiceLines;
        Boolean hasNext = inst_SIC.hasNext;
        Boolean hasPrevious = inst_SIC.hasPrevious;
        Integer pageNumber = inst_SIC.pageNumber;
        inst_SIC.previous();
        inst_SIC.next();

        Test.stopTest();
    }
}