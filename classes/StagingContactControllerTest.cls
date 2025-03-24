@IsTest
private class StagingContactControllerTest {
    private static testMethod void test() {
        SiteTestData.createData();
    
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Contact cont = [SELECT Id FROM Contact LIMIT 1];
        Portal_Login__c login = [SELECT Id, Name FROM Portal_Login__c LIMIT 1];
        
        StagingContactController.StageContact(cont.Id);
        
        Staging_Contact__c sa = [SELECT Id FROM Staging_Contact__c LIMIT 1];
        sa.Is_Updated__c = true;
        sa.Last_Updated_By__c = login.Id;
        sa.Last_Updated_Date__c = system.today();
        sa.Notes__c = 'test note';
        update sa;
        
        String jsonString = JSON.serialize(sa);
        try {
            StagingContactController.validateBillingAddress(jsonString);
        }
        catch(exception ex) {
        }
        
        StagingContactController.saveStagingContact(jsonString);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(sa);  
        StagingContactController controller = new StagingContactController(sc);        
        controller.copyFirstName();
        controller.copyMiddleName();
        controller.copyLastName();
        controller.copyStreet();
        controller.copyCity();
        controller.copyState();
        controller.copyPostalCode();
        controller.copyCountry();
        controller.copyPhone();
        controller.copyEmail();
        controller.copyMobilePhone();
        controller.copyTitle();
        controller.copyAll();
        controller.SyncContact();
    }
    
    private static testMethod void testBatch() {
        SiteTestData.createData();
        
        List<Staging_Contact__c> sas = new List<Staging_Contact__c>();
        
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(sas);  
        StagingContactController controller = new StagingContactController(sc);
        controller.ResetUpdateRequestEmailSentFlag = true;
        controller.ImportContacts();
        
        controller.ImportContacts(); ///upate
        sas = [SELECT Id FROM Staging_Contact__c];
                
        controller.SendContactUpdateRequestEmails();
    }
}