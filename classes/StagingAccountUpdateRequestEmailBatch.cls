public with sharing class StagingAccountUpdateRequestEmailBatch implements Database.Batchable<SObject>, Database.Stateful {
    public List<Id> StagingAccountIds { set; get; }
    
    public String EmailAddress { set; get; }
    public Integer success;
    public Integer failure;
    public EmailTemplate emailTemplate;
    public OrgWideEmailAddress owa;

    public List<Staging_Account__c> start(Database.BatchableContext bc) {
        this.success= 0;
        this.failure= 0;
        
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE Name = 'Customer Address Verification Request Email' LIMIT 1];
        if (templates.size() > 0) {
            this.emailTemplate = templates[0];
        }
        else {
            throw new DataException('Lightning email template \'Customer Address Verification Request Email\' is not found.');
        }
        this.owa = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Republic Services' LIMIT 1];

        return StagingAccountController.getRecords(this.StagingAccountIds, null, new List<String>{ 'Update_Request_Email_Sent__c <> TRUE' });
    }
    
    public void execute(Database.BatchableContext bc, List<Staging_Account__c> sas) {
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        Map<Id, Staging_Account__c> mapStagingAccountsByAccountId = new Map<Id, Staging_Account__c>();
        List<Id> acctIds = new List<Id>();
        for (Staging_Account__c sa: sas) {
            sa.Error_Text__c = null; //reset error text
            acctIds.add(sa.Account__c);
            mapStagingAccountsByAccountId.put(sa.Account__c, sa);
        }
        
        List<Portal_Login__c> logins = PortalLoginController.getRecords(null, acctIds, null, true, null);
        
        //*** disable sending emails to real clients in sandbox ****
        Id prodOrgId = '00Df40000000Ns9';
        List<String> allowedEmails = new List<String>();
        allowedEmails.add('kchen@micro-datanet.com');
        allowedEmails.add('dscerbo@acvenviro.com');
        allowedEmails.add('jmarcotte@acvenviro.com');
        allowedEmails.add('rvandra@acvenviro.com');
        

        for (Integer i = 0 ; i < logins.size(); i++) {
            Portal_Login__c login = logins[i];
            
            Staging_Account__c sa = mapStagingAccountsByAccountId.get(login.Account__c);
            
            if (!userInfo.getOrganizationId().contains(prodOrgId) && !allowedEmails.contains(login.Email__c)) {
                sa.Error_Text__c = 'Email address "' + login.Email__c + '" is not allowed in this sandbox.';
                logins.remove(i);
                i--;
            }
            else if (login.Contact__r.IsEmailBounced == true) {
                sa.Error_Text__c = 'At least one contact\'s email address is flagged bounced.';
                
                logins.remove(i);
                i--;
            }
        }
        //*** disable sending emails to real clients in sandbox ****
        
        
        Map<Id, Portal_Login__c> mapLoginsById = new Map<Id, Portal_Login__c>();
        for (Portal_Login__c login : logins) {
        
            if (!userInfo.getOrganizationId().contains(prodOrgId)) {
                if (!allowedEmails.contains(login.Email__c)) {
                    throw new DataException('Email ' + login.Email__c + ' is NOT allowed in the sandbox.');
                }
            }
            
            Staging_Account__c account = mapStagingAccountsByAccountId.get(login.Account__c);
    
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setOrgWideEmailAddressId(owa.Id);
            //ticket 19130 <<
            //if(CompanySettingUtil.isSandbox() != true) {
            if(CompanySettingUtil.isSandbox() != true || Test.isRunningTest()) {
            //ticket 19130 >>
                message.setTargetObjectId(login.Contact__c);
            }
            message.setToAddresses(new List<String> { login.Email__c });
            message.setWhatId(login.Id);
            message.setTemplateId(this.emailTemplate.Id);
            message.setSaveAsActivity(true);
            messages.add(message);
            
            mapLoginsById.put(login.Id, login);
        }
        
        if (messages.size() > 0) {
            //!!!bypass setTargetObjectId requirements for using template
            Savepoint sp = Database.setSavepoint();
            Messaging.sendEmail(messages);
            Database.rollback(sp);

            List<Messaging.SingleEmailMessage> messagesToSend = new List<Messaging.SingleEmailMessage>();
            for (Messaging.SingleEmailMessage message : messages) {
                Portal_Login__c login = mapLoginsById.get(message.getWhatId());
                Staging_Account__c sa = mapStagingAccountsByAccountId.get(login.Account__c);
            
                Messaging.SingleEmailMessage messageToSend = new Messaging.SingleEmailMessage();
                //ticket 19130 <<
                //if (login.Contact__c != null && CompanySettingUtil.isSandbox() != true) {
                if (login.Contact__c != null && (CompanySettingUtil.isSandbox() != true || Test.isRunningTest())) {
                    //ticket 19130 >>
                    messageToSend.setTargetObjectId(login.Contact__c);
                }
                messageToSend.setOrgWideEmailAddressId(owa.Id);            
                messageToSend.setWhatId(sa.Id); //change whatId to be the staging account                         
                messageToSend.setHTMLBody(message.getHTMLBody().replace('{PortalLogin.Password}', login.Password__c));
                messageToSend.setPlainTextBody(message.getPlainTextBody().replace('{PortalLogin.Password}', login.Password__c));
                messageToSend.setSubject(message.getSubject());
                messageToSend.setSaveAsActivity(true);
                messagesToSend.add(messageToSend);
            }
        
            List<Portal_Login__c> loginsToUpdate = new List<Portal_Login__c>();
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(messagesToSend);
            for (Integer i = 0; i < results.size(); i++) {
                Messaging.SendEmailResult result = results[i];                

                Portal_Login__c login = logins[i];                
                Staging_Account__c sa = mapStagingAccountsByAccountId.get(login.Account__c);                
                
                if (result.isSuccess()) {         
                    login.Login_Credential_Sent__c = true;
                    login.Login_Credential_Sent_Date__c = system.now();
                    loginsToUpdate.add(login);
                                           
                    sa.Update_Request_Email_Sent__c = true;
                    sa.Update_Request_Email_Sent_Date__c = system.now();
                }
                else {
                    sa.Update_Request_Email_Sent__c = false;
                    List<String> errors = new List<String>();
                    for (Messaging.SendEmailError error : result.getErrors()) {
                        errors.add(error.getStatusCode() + ': ' + error.getMessage());
                    }
                    sa.Error_Text__c = String.join(errors, '; ');
                }
            }
            
            for (Staging_Account__c sa : sas) {
                if (sa.Update_Request_Email_Sent__c == true) {
                    success++;
                }
                else {
                    failure++;
                }
            }
            
            if (loginsToUpdate.size() > 0) {
                update loginsToUpdate;
            }
        }
        update sas; // update accounts        
    }
    
    public void finish(Database.BatchableContext bc) {
        if (this.EmailAddress != null) {
            if (this.StagingAccountIds == null) {
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.toAddresses = new String[] { this.EmailAddress };
                message.subject = 'Customer Update Request Emails - Send Result';
                message.plainTextBody = 'Emails Sent: ' + this.success + '\n' + 'Failed: ' + this.failure + ' (please review the error text on the staging accounts)';
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                Messaging.sendEmail(messages);
            }
        }
    }
}