public with sharing class StagingContactUpdateRequestEmailBatch implements Database.Batchable<SObject>, Database.Stateful {
    public List<Id> StagingContactIds{ set; get; }
    public String EmailAddress { set; get; }
    public Integer success;
    public Integer failure;
    public EmailTemplate emailTemplate;
    public OrgWideEmailAddress owa;

    public List<Staging_Contact__c> start(Database.BatchableContext bc) {
        this.success= 0;
        this.failure= 0;
        
        List<EmailTemplate> templates = [SELECT Id FROM EmailTemplate WHERE Name = 'Contact Information Verification Request Email' LIMIT 1];
        if (templates.size() > 0) {
            this.emailTemplate = templates[0];
        }
        else {
            throw new DataException('Lightning email template \'Contact Information Verification Request Email\' is not found.');
        }
        this.owa = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Republic Services' LIMIT 1];
        
        return StagingContactController.getRecords(this.StagingContactIds, null, null);
    }
    
    public void execute(Database.BatchableContext bc, List<Staging_Contact__c> scs) {
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        Map<Id, Staging_Contact__c> mapStagingContactsByContactId = new Map<Id, Staging_Contact__c>();
        List<Id> contIds = new List<Id>();
        for (Staging_Contact__c sc : scs) {
            sc.Error_Text__c = null;
            contIds.add(sc.Contact__c);
            mapStagingContactsByContactId.put(sc.Contact__c, sc);
        }
        
        List<Portal_Login__c> logins = PortalLoginController.getRecords(null, null, contIds, true, null);
        
        //*** disable sending emails to real clients in sandbox ****
        Id prodOrgId = '00Df40000000Ns9';
        List<String> allowedEmails = new List<String>();
        allowedEmails.add('kchen@micro-datanet.com');
        allowedEmails.add('dscerbo@acvenviro.com');
        allowedEmails.add('jmarcotte@acvenviro.com');
        allowedEmails.add('rvandra@acvenviro.com');
        
        for (Integer i = 0 ; i < logins.size(); i++) {
            Portal_Login__c login = logins[i];
            Staging_Contact__c sc = mapStagingContactsByContactId.get(login.Contact__c);
            
            if (!userInfo.getOrganizationId().contains(prodOrgId) && !allowedEmails.contains(login.Email__c)) {
                sc.Error_Text__c = 'Email address "' + login.Email__c + '" is not allowed in this sandbox.';
                logins.remove(i);
                i--;
            }
            else if (login.Contact__r.IsEmailBounced == true) {
                sc.Error_Text__c = 'The contact\'s email address is flagged bounced.';
                
                logins.remove(i);
                i--;
            }
        }
        //*** disable sending emails to real clients in sandbox ****
        
        Map<Id, Portal_Login__c> mapLoginsById = new Map<Id, Portal_Login__c>();
        for (Portal_Login__c login : logins) {
            if (!userInfo.getOrganizationId().contains(prodOrgId)) {
                if (!allowedEmails.contains(login.Email__c)) {
                    throw new DataException('Email ' + login.Email__c + ' is NOT allowed in a sandbox.');
                }
            }
            
            Staging_Contact__c account = mapStagingContactsByContactId.get(login.Contact__c);
    
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
                Staging_Contact__c sc = mapStagingContactsByContactId.get(login.Contact__c);

                Messaging.SingleEmailMessage messageToSend = new Messaging.SingleEmailMessage();
                //ticket 19130 <<
                //if (login.Contact__c != null && CompanySettingUtil.isSandbox() != true) {
                if (login.Contact__c != null && (CompanySettingUtil.isSandbox() != true || Test.isRunningTest())) {
                //ticket 19130 >>
                    messageToSend.setTargetObjectId(login.Contact__c);
                }
                messageToSend.setOrgWideEmailAddressId(owa.Id);  
                messageToSend.setWhatId(sc.Id); //change whatId to be the staging account
                messageToSend.setHTMLBody(message.getHTMLBody().replace('{PortalLogin.Password}', login.Password__c));
                messageToSend.setPlainTextBody(message.getPlainTextBody().replace('{PortalLogin.Password}', login.Password__c));
                messageToSend.setSubject(message.getSubject());
                messageToSend.setSaveAsActivity(true);
                messagesToSend.add(messageToSend);
            }
        
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(messagesToSend);
            for (Integer i = 0; i < results.size(); i++) {
                Messaging.SendEmailResult result = results[i];
                if (result.isSuccess()) {
                    Portal_Login__c login = logins[i];
                    Staging_Contact__c sc = mapStagingContactsByContactId.get(login.Contact__c);
                    sc.Update_Request_Email_Sent__c = true;
                    sc.Update_Request_Email_Sent_Date__c = system.now();
                }
            }
            
            for (Staging_Contact__c sc : scs) {
                if (sc.Update_Request_Email_Sent__c == true) {
                    success++;
                }
                else {
                    failure++;
                }
            }
        }
        update scs; // update contacts
    }
    
    public void finish(Database.BatchableContext bc) {
        if (this.EmailAddress != null) {
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { this.EmailAddress };
            message.subject = 'Contact information update request email result';
            message.plainTextBody = 'Succeeded: ' + this.success + '\n' + 'Failed: ' + this.failure + ' (please review the error text on the staging contact)';
            Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
            Messaging.sendEmail(messages);
        }
    }
}