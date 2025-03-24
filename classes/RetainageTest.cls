@IsTest
private class RetainageTest {
    @IsTest
    static void testBehavior() {
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Sales_Invoice__c salesInvoice = TestDataUtil.SalesInvoiceRecord;
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecord;
        Retainage_Ledger_Entry__c retainageLedgerEntry = new Retainage_Ledger_Entry__c();
        retainageLedgerEntry.Sales_Order__c = salesOrder.Id;
        retainageLedgerEntry.Sales_Invoice__c = salesInvoice.Id;
        retainageLedgerEntry.Amount__c = 0;
        try{
            insert retainageLedgerEntry;
        } catch (Exception e){

        }
        try{
            CompanyMgmt.systemCall = true;
            insert retainageLedgerEntry;
        } catch (Exception e){

        }
    }
}