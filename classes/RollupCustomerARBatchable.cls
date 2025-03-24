global class RollupCustomerARBatchable implements Database.Batchable<Account> {
    global List<Account> start(Database.BatchableContext bc) {
        return [SELECT Id FROM Account WHERE Type = 'Customer' ORDER BY AccountNumber];
    }

    global void execute(Database.BatchableContext bc, list<Account> accts) {
        List<Id> acctIds = new List<Id>();
        for (Account acct : accts) {
            acctIds.add(acct.Id);
        }    
        try {
            AccountController.RollupCustomerAR(acctIds);
        }
        catch(exception ex) {
            OrganizationConfigurations__c config = OrganizationConfigurations__c.getOrgDefaults();
            Helper.EmailGroupUsers(config.Data_Admin_Public_Group__c, 'Customer AR Rollup Error ' + System.today(), ex.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        //rollup corporate AR
        Database.executeBatch(new RollupVendorAPBatchable(), 100);
    }
}