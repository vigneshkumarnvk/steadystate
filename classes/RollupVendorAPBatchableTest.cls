@IsTest
private class RollupVendorAPBatchableTest {
    @IsTest
    static void testBehavior() {
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Subsidiary_Vendor__c subsidiaryVendor = TestDataUtil.SubsidiaryRecord;
        Subsidiary_Company__c subsidiaryCompany = TestDataUtil.SubsidiaryCompanyRecord;
        Account vendor = TestDataUtil.VendorAccount;
        Service_Center__c serviceCenter = TestDataUtil.ServiceCenterRecord;
        Vendor_Ledger_Entry__c vendorLedgerEntry = new Vendor_Ledger_Entry__c();
        vendorLedgerEntry.Subsidiary_Company__c = subsidiaryCompany.Id;
        vendorLedgerEntry.Vendor__c = vendor.Id;
        vendorLedgerEntry.Name = '1';
        vendorLedgerEntry.Service_Center__c = serviceCenter.Id;
        vendorLedgerEntry.Document_Type__c = 'Sales Invoice';
        vendorLedgerEntry.Document_No__c = 'SI-00001';
        vendorLedgerEntry.Posting_Date__c = Date.today();
        vendorLedgerEntry.Due_Date__c = Date.today();
        vendorLedgerEntry.Amount__c = 1000;
        vendorLedgerEntry.Amount_LCY__c = 1000;
        vendorLedgerEntry.Purchase_LCY__c = 1000;
        vendorLedgerEntry.NAV_Vendor_No__c = subsidiaryVendor.Name;
        insert vendorLedgerEntry;
    }
}