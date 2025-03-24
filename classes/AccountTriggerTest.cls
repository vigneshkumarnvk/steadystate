@isTest
private class AccountTriggerTest {
    static testMethod void test() {
        Subsidiary_Company__c company = new Subsidiary_Company__c(Name = 'ACV');
        insert company;
        
        Auto_Number__c an = new Auto_Number__c(Name = 'Corporate No. Series', Displaying_Format__c = 'CORP-{00000}', Starting_Number__c = 1);
        insert an;
        
        Account corp= new Account(Name = 'CORP', Type = 'Corporate');
        insert corp;
        update corp;

        Account pros = new Account(Name = 'CORP', Type = 'Prospect');
        try{
            insert pros;
        } catch (Exception ex){

        }
        //83014test test
        Account acct = new Account(Name = 'ABC', Type = 'Customer');
        try {
            insert acct;
        }
        catch(exception ex) {
        }
        
        Salesperson__c sp = new Salesperson__c(Name = 'Smith', Salesperson_Code__c = 'S000', Account_Executive__c = true,  User__c = userInfo.getUserId(), Status__c='Active');
        insert sp;
        
        try {
            acct.Type = 'Customer';     
            acct.BillingStreet = '123';
            acct.BillingCity = 'New York';
            acct.BillingStateCode = 'NY';
            acct.BillingPostalCode = '12335';
            acct.BillingCountry = 'US'; 
            acct.Customer_Type__c = 'OTHER';
            acct.Account_Executive__c = sp.Id;
            acct.Salesperson__c = sp.Id;
            acct.Subsidiary_Company__c = company.Id;
            insert acct;
        }
        catch(exception ex) {
        }
                
        try {
            acct.Type = 'Customer';            
            update acct;
        }
        catch(exception ex) {
        }

        try{
            pros.Type = 'Prospect';
            pros.BillingStreet = '123';
            pros.BillingCity = 'New York';
            pros.BillingStateCode = 'NY';
            pros.BillingPostalCode = '12335';
            pros.BillingCountry = 'US';
            pros.Customer_Type__c = 'OTHER';
            pros.Account_Executive__c = sp.Id;
            pros.Salesperson__c = sp.Id;
            pros.Subsidiary_Company__c = company.Id;
        } catch (Exception ex){

        }

        try{
            pros.Type = 'Prospect';
            update pros;
        } catch (Exception e){

        }

        try {
            UserRole ur = new UserRole(Name = 'AE', DeveloperName = 'AE');
            insert ur;
            Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
            User u = new User(Alias = 'ae', Email='ae@testorg.com', EmailEncodingKey='UTF-8', LastName='AE', FirstName = 'AE', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName='ae@testorg.com', UserRoleId = ur.Id);
            insert u;
            
            acct.OwnerId = u.Id;
            update acct;
        }
        catch(exception ex) {
        }

        
        try {
            delete acct;
        }
        catch(exception ex) {
        }
    }
}