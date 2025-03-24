@isTest
public class SiteTestData {

    public static void createData() {
        List<Account> accts = new List<Account>();
        Account acct = new Account();
        acct.Type = 'Customer';
        acct.Name = 'Site Customer';
        acct.BillingStreet = '123 ABC Ave';
        acct.BillingCity = 'New York';
        acct.BillingState = 'New York';
        acct.BillingPostalCode = '10002';
        acct.BillingCountry = 'United States';
        acct.Phone = '1234567890';
        acct.Fax = '1234567890';
        
        accts.add(acct);
        
        insert accts;
        
        List<Contact> conts = new List<Contact>();
        Contact cont = new Contact();
        cont.AccountId = acct.Id;
        cont.Contact_Type__c = 'Billing';
        cont.LastName = 'Smith';
        cont.FirstName = 'John';
        cont.Phone = '1234567890';
        cont.Email = 'kchen@micro-datanet.com';
        cont.MailingStreet = '123 ABC Ave';
        cont.MailingCity = 'New York';
        cont.MailingState = 'New York';
        cont.MailingPostalCode = '12345';
        cont.MailingCountry = 'United States';
        
        conts.add(cont);
        insert conts;
        
        Portal_Login__c login = new Portal_Login__c();
        login.Account__c = acct.Id;
        login.Contact__c = cont.Id;
        login.Username__c = 'kchen@micro-datanet.com';
        login.Password__c = 'password';
        login.Email__c = 'kchen@micro-datanet.com';
        insert login;
        
    }
}