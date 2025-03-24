@IsTest
private class StagingAccountControllerTest {
    private static testMethod void test() {
        SiteTestData.createData();
    
        Account acct = [SELECT Id FROM Account LIMIT 1];
        Portal_Login__c login = [SELECT Id, Name FROM Portal_Login__c LIMIT 1];
        
        StagingAccountController.StageAccount(acct.Id);
        
        Staging_Account__c sa = [SELECT Id FROM Staging_Account__c LIMIT 1];
        sa.Is_Updated__c = true;
        sa.Last_Updated_By__c = login.Id;
        sa.Last_Updated_Date__c = system.today();
        sa.Notes__c = 'test note';
        update sa;
        
        String jsonString = JSON.serialize(sa);
        try {
            StagingAccountController.validateBillingAddress(jsonString);
        }
        catch(exception ex) {
        }
        
        StagingAccountController.saveStagingAccount(jsonString);
        
        ApexPages.StandardController sc = new ApexPages.StandardController(sa);  
        StagingAccountController controller = new StagingAccountController(sc);        
        controller.copyName();
        controller.copyBillingStreet();
        controller.copyBillingCity();
        controller.copyBillingState();
        controller.copyBillingPostalCode();
        controller.copyBillingCountry();
        controller.copyAll();
        controller.SyncAccount();
    }
    
    private static testMethod void testBatch() {
        SiteTestData.createData();
        
        List<Staging_Account__c> sas = new List<Staging_Account__c>();
        
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(sas);  
        StagingAccountController controller = new StagingAccountController(sc);
        controller.ResetUpdateRequestEmailSentFlag = true;
        controller.ImportAccounts();
        
        controller.ImportAccounts(); ///upate
        sas = [SELECT Id FROM Staging_Account__c];
                
        controller.SendAccountUpdateRequestEmails();
    }
    
}