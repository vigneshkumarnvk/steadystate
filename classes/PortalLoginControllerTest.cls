@IsTest
private class PortalLoginControllerTest {
    private static testMethod void test() {
        SiteTestData.createData();
    
        Account acct = [SELECT Id FROM Account LIMIT 1];
        
        List<Id> contIds = new List<Id>();
        for (Contact cont : [SELECT Id FROM Contact WHERE Contact_Type__c INCLUDES('Billing')]) {
            contIds.add(cont.Id);
        }
        
        List<Portal_Login__c> logins = PortalLoginController.CreatePortalLoginsFromContacts(contIds, 5, true); //insert test
        
        Contact cont = new Contact();
        cont.AccountId = acct.Id;
        cont.Contact_Type__c = 'Billing';
        cont.LastName = 'Marcotte';
        cont.FirstName = 'Jay';
        cont.Phone = '1111111111111';
        cont.Email = 'jmarcotte@acvenviro.com';
        cont.MailingStreet = '456 ABC Ave';
        cont.MailingCity = 'New York';
        cont.MailingState = 'New York';
        cont.MailingPostalCode = '12345';
        cont.MailingCountry = 'United States';
        insert cont;
        contIds.add(cont.Id);
        logins = PortalLoginController.CreatePortalLoginsFromContacts(contIds, 5, true); //update test
        
        if (logins.size() > 0) {
            Portal_Login__c login = logins[0];
            ApexPages.StandardController sc = new ApexPages.StandardController(login);
            PortalLoginController controller = new PortalLoginController(sc);

            controller.SendLoginCredential();
        }
    }
    
    private static testMethod void testBatchEmail() {
        SiteTestData.createData();
    
        List<Id> contIds = new List<Id>();
        for (Contact cont : [SELECT Id FROM Contact WHERE Contact_Type__c INCLUDES('Billing')]) {
            contIds.add(cont.Id);
        }
        
        List<Portal_Login__c> logins = PortalLoginController.CreatePortalLoginsFromContacts(contIds, 5, true);
        
        if (logins.size() > 0) {
            ApexPages.StandardSetController sc = new ApexPages.StandardSetController(logins);
            PortalLoginController controller = new PortalLoginController(sc);
            controller.SendLoginCredentials();
        }
    }
}