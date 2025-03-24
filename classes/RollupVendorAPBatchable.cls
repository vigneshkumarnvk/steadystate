global with sharing class RollupVendorAPBatchable implements Database.Batchable<Account> {
    global List<Account> start(Database.BatchableContext bc) {
        return [SELECT Id FROM Account WHERE Type = 'Vendor' ORDER BY AccountNumber];
    }

    global void execute(Database.BatchableContext bc, list<Account> accts) {
        List<Id> acctIds = new List<Id>();
        for (Account acct : accts) {
            acctIds.add(acct.Id);
        }
        try {
            AccountController.RollupVendorAP(acctIds);
        }
        catch(exception ex) {
            OrganizationConfigurations__c config = OrganizationConfigurations__c.getOrgDefaults();
            Helper.EmailGroupUsers(config.Data_Admin_Public_Group__c, 'Vendor AP Rollup Error ' + System.today(), ex.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
        //rollup corporate
        Database.executeBatch(new RollupCorporateARBatchable(), 100);
    }
}