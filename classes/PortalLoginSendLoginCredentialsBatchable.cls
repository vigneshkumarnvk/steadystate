public with sharing class PortalLoginSendLoginCredentialsBatchable implements Database.Batchable<Portal_Login__c>, Database.Stateful {
    public List<Id> LoginIds { set; get; }
    public String EmailAddress { set; get; }
    public Integer success;
    public Integer failure;

    public List<Portal_Login__c> start(Database.BatchableContext bc) {
        this.success = 0;
        this.failure = 0;
        List<Portal_Login__c> logins = PortalLoginController.getRecords(null, null, null, true, new List<String>{ 'Login_Credential_Sent__c <> TRUE' });
        return logins;
    }
    
    public void execute(Database.BatchableContext bc, List<Portal_Login__c> logins) {        
        PortalLoginController.SendLoginCredentials(logins);
        
        List<Id> loginIds = new List<Id>();
        for (Portal_Login__c login : logins) {
            if (login.Login_Credential_Sent__c == true) {
                this.success++;
            }
            else {
                this.failure++;
            }
        }
    }
    
    public void finish(Database.BatchableContext bc) {
        if (this.EmailAddress != null && this.loginIds == null) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { this.EmailAddress };
            message.subject = 'Portal login credentail emails - send result';
            message.plainTextBody = 'Logins sent: ' + this.success + '\nFailed: ' + this.failure;
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            Messaging.sendEmail(messages);
        }
    }
}