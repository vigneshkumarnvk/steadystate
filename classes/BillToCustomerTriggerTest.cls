@isTest
public class BillToCustomerTriggerTest {
    public testMethod static void test() {
        Account acct = new Account(Name = 'account');
        insert acct;
        
        Bill_to_Customer__c cust = new Bill_to_Customer__c(Name = 'Test', Account__c = acct.Id, Customer_No__c = '00-000001');
        insert cust;
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator'];        
        User u = new User(Alias = 'user', Email = 'test@testorg.com', EmailEncodingKey = 'UTF-8', LastName = 'user', LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'America/Los_Angeles', UserName = 'test@steinway.com', Allow_Deleting_Bill_to_Customer__c = true);
        insert u;
        
        System.runAs(u) {
            try {
                delete cust;
            }
            catch(exception ex) {
            
            }
        }
    }
}