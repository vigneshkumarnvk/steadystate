public with sharing class StagingAccountImportBatchable implements Database.Batchable<Account>, Database.Stateful {
    public Boolean ResetUpdateRequestEmailSentFlag { set; get; }
    
    public String EmailAddress { set; get; }
    public Integer accountsUpdated;
    public Integer accountsCreated;
    public Integer accountsSkipped;

    public List<Account> start(Database.BatchableContext bc) {
        this.accountsUpdated = 0;
        this.accountsCreated = 0;
        this.accountsSkipped = 0;
        
        List<Account> accounts;
        accounts = [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingStateCode, BillingPostalCode, BillingCountry, BillingCountryCode, (SELECT Id, Name, Email FROM Contacts WHERE Email != null AND Contact_Type__c INCLUDES ('Billing')) FROM Account WHERE Type = 'Customer'];
        return accounts;
    }
    
    public void execute(Database.BatchableContext bc, List<Account> accounts) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Id> acctIds = new List<Id>();
            List<Id> contIds = new List<Id>();
            for (Integer i = 0; i < accounts.size(); i++) {
                Account acct = accounts[i];
                if (acct.Contacts != null && acct.Contacts.size() > 0) {
                    acctIds.add(acct.Id);
                    for (Contact cont : acct.Contacts) {
                        contIds.add(cont.Id);
                    }
                }
                else {
                    accounts.remove(i);
                    i--;
                }
            }
            
            Map<Id, Staging_Account__c> mapStagingAccounts = new Map<Id, Staging_Account__c>();
            for (Staging_Account__c sa : [SELECT Id, Account__c, Is_Updated__c FROM Staging_Account__c WHERE Account__c IN :acctIds]) {
                mapStagingAccounts.put(sa.Account__c, sa);
            }
            
            List<Staging_Account__c> stagingAccountsToUpsert = new List<Staging_Account__c>();
            for (Account acct : accounts) {
                Staging_Account__c stagingAccount;
                if (mapStagingAccounts.containsKey(acct.Id)) {
                    stagingAccount = mapStagingAccounts.get(acct.Id);
                    if (stagingAccount.Is_Updated__c != true) {
                        Id raId = stagingAccount.Id;
                        stagingAccount = StagingAccountController.InitStagingAccount(acct, this.ResetUpdateRequestEmailSentFlag);
                        stagingAccount.Id = raId;
                        
                        stagingAccountsToUpsert.add(stagingAccount);
                        this.accountsUpdated++;
                    }
                    else {
                        this.accountsSkipped++;
                    }
                }
                else {
                    stagingAccount = StagingAccountController.InitStagingAccount(acct, this.ResetUpdateRequestEmailSentFlag);
                    stagingAccountsToUpsert.add(stagingAccount);
                    this.accountsCreated++;
                }
            }
            if (stagingAccountsToUpsert.size() > 0) {
                upsert stagingAccountsToUpsert;
                PortalLoginController.CreatePortalLoginsFromContacts(contIds, 5, this.ResetUpdateRequestEmailSentFlag);
            }
            
            StagingAccountController.LinkStagingAcountsToPortalLogins(acctIds);
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
        
    }

    
    public void finish(Database.BatchableContext bc) {
        if (this.EmailAddress != null) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { this.EmailAddress };
            message.subject = 'Staging accounts import result';
            message.plainTextBody = 'Accounts Created: ' + this.accountsCreated + '\n' + 'Accounts Updated: ' + this.accountsUpdated + '\n' + 'Accounts Skipped: ' + this.accountsSkipped + ' (these accounts are updated by customers but not yet synchronized to Salesforce account)';
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            Messaging.sendEmail(messages);
        }
    }
}