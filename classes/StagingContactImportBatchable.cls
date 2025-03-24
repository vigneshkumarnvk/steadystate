public with sharing class StagingContactImportBatchable implements Database.Batchable<Contact>, Database.Stateful {
    public Boolean ResetUpdateRequestEmailSentFlag { set; get; }
    
    public String EmailAddress { set; get; }
    public Integer contactsUpdated;
    public Integer contactsSkipped;
    public Integer contactsCreated;

    public List<Contact> start(Database.BatchableContext bc) {
        this.contactsUpdated = 0;
        this.contactsCreated = 0;
        this.contactsSkipped = 0;
        
        List<Contact> contacts;
        contacts = [SELECT Id, AccountId, Name, FirstName, MiddleName, LastName, MailingStreet, MailingCity, MailingState, MailingStateCode, MailingPostalCode, MailingCountry, MailingCountryCode, Phone, Email, MobilePhone, Title FROM Contact WHERE Email != null AND Contact_Type__c INCLUDES ('Billing')];
        return contacts;
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> contacts) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Id> cntIds = new List<Id>();
            for (Integer i = 0; i < contacts.size(); i++) {
                Contact cnt = contacts[i];
                cntIds.add(cnt.Id);
            }
            
            Map<Id, Staging_Contact__c> mapStagingContacts = new Map<Id, Staging_Contact__c>();
            for (Staging_Contact__c sc : [SELECT Id, Contact__c, Is_Updated__c FROM Staging_Contact__c WHERE Contact__c IN :cntIds]) {
                mapStagingContacts.put(sc.Contact__c, sc);
            }
            
            List<Staging_Contact__c> stagingContacts = new List<Staging_Contact__c>();
            for (Contact cnt : contacts) {
                Staging_Contact__c stagingContact;
                if (mapStagingContacts.containsKey(cnt.Id)) {
                    stagingContact = mapStagingContacts.get(cnt.Id);
                    if (stagingContact.Is_Updated__c != true) { //don't overwrite if the staging contact has been updated
                        Id scId = stagingContact.Id;
                        stagingContact = StagingContactController.InitStagingContact(cnt, this.ResetUpdateRequestEmailSentFlag);
                        stagingContact.Id = scId;
                        
                        stagingContacts.add(stagingContact);
                        this.contactsUpdated++;
                    }
                    else {
                        this.contactsSkipped++;
                    }
                }
                else {
                    stagingContact = StagingContactController.InitStagingContact(cnt, this.ResetUpdateRequestEmailSentFlag);
                    stagingContacts.add(stagingContact);
                    this.contactsCreated++;
                }
            }
    
            if (stagingContacts.size() > 0) {
                upsert stagingContacts;
                PortalLoginController.CreatePortalLoginsFromContacts(cntIds, 5, this.ResetUpdateRequestEmailSentFlag);
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
                
    }
    
    
    
    public void finish(Database.BatchableContext bc) {
        try {
            if (this.EmailAddress != null) {
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.toAddresses = new String[] { this.EmailAddress };
                message.subject = 'Staging account import result';
                message.plainTextBody = 'Contacts Created: ' + this.contactsCreated + '\n' + 'Contacts Updated: ' + this.contactsUpdated + '\n' + 'Contacts Skipped: ' + this.contactsSkipped + ' (these contacts are updated by customers but not yet synchronized to Salesforce contact)';
                Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
                Messaging.sendEmail(messages);
            }
        }
        catch(exception ex) {
        }
    }
}