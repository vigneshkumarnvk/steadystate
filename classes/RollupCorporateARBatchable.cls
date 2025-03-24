global class RollupCorporateARBatchable implements Database.Batchable<Account> {
    global List<Account> start(Database.BatchableContext bc) {
        return [SELECT Id FROM Account WHERE Type = 'Corporate'];
    }

    global void execute(Database.BatchableContext bc, list<Account> accts) {
        List<Id> acctIds = new List<Id>();
        for (Account acct : accts) {
            acctIds.add(acct.Id);
        }
        try {
            AccountController.RollupCorporateAR(acctIds);
        }
        catch(exception ex) {
            OrganizationConfigurations__c config = OrganizationConfigurations__c.getOrgDefaults();
            Helper.EmailGroupUsers(config.Data_Admin_Public_Group__c, 'Corporate AR Rollup Error ' + System.today(), ex.getMessage());
        }
    }

    global void finish(Database.BatchableContext bc) {
    }
}