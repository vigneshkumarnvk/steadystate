@isTest
private class SalesInvoiceUnitCostUpdateControllerTest {

    private static testMethod void test() {
        List<Sales_Invoice__c> sis = new List<Sales_Invoice__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(sis);
        SalesInvoiceUnitCostUpdateController controller = new SalesInvoiceUnitCostUpdateController(sc);
        Test.setCurrentPage(Page.SalesInvoiceUnitCostUpdate);
        controller.UpdateUnitCost();
    }
}