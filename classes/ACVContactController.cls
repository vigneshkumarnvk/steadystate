/**
 * Created by Kevin on 9/25/2019.
 */

public with sharing class ACVContactController {
    @AuraEnabled
    public static Contact getContact(Id contactId) {
        try {
            List<Contact> contacts = ContactsSelector.newInstance().selectContactsByIds(new Set<Id>{
                    contactId
            });
            if (contacts.size() > 0) {
                return contacts[0];
            }
            return null;
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Contact saveContact(String JSONContact) {
        try {
            Contact contact = (Contact) JSON.deserialize(JSONContact, Contact.class);
            upsert contact;
            return [SELECT Id, Name, FirstName, LastName FROM Contact WHERE Id = :contact.Id];
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Account getAccount(Id accountId) {
        try {
            List<Account> accounts = AccountsSelector.newInstance().selectById(new Set<Id>{
                    accountId
            });
            if (accounts.size() > 0) {
                return accounts[0];
            }
            return null;
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}