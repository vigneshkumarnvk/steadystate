global class RollupCustomerRevenueBatch implements Database.Batchable<SObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Sales_Order__c, Document_Type__c, Amount__c, Sales_Order__r.Name, Service_Center__c, Service_Center__r.Code__c, Customer__c, Customer__r.AccountNumber, Customer__r.Subsidiary_Company__r.Name, Customer__r.Salesperson__c, Customer__r.Account_Executive__c, Sales_LCY__c, Amount_LCY__c, Posting_Date__c FROM Customer_Ledger_Entry__c WHERE (Document_Type__c = \'Invoice\' OR Document_Type__c = \'Credit_Memo\') AND Processed__c = FALSE ORDER BY Customer__c';
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            List<Customer_Ledger_Entry__c> customerLedgerEntries = new List<Customer_Ledger_Entry__c>();
            customerLedgerEntries.addAll((List<Customer_Ledger_Entry__c>)scope);
            AccountController.RollupCustomerRevenueByCLE(customerLedgerEntries);
        }
        catch(Exception ex) {
            OrganizationConfigurations__c config = OrganizationConfigurations__c.getOrgDefaults();
            Helper.EmailGroupUsers(config.Data_Admin_Public_Group__c, 'Customer Revenue Rollup Error ' + System.today(), ex.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {

    }
}