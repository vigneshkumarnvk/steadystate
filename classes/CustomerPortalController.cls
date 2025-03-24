public without sharing class CustomerPortalController {
    /*
    private ApexPages.StandardSetController setController;
    
    public CustomerPortalController(ApexPages.StandardSetController controller) {
        this.setController = controller;
    }
    
    
    public PageReference SendAccountUpdateRequestEmails() {
        try {
            StagingAccountUpdateRequestEmailBatch batch = new StagingAccountUpdateRequestEmailBatch ();
            batch.EmailAddress = userInfo.getUserEmail();
            Database.executeBatch(batch, 100);
            return new ApexPages.Action('{!List}').invoke();
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }
  */  
    
    @AuraEnabled
    public static LoginInfo checkSession(String session) {
        try {
            List<Portal_Login__c> portalLogins = [SELECT Id, Name, Account__c, Account__r.Name, Contact__c, Password__c, Disabled__c, Expiration_Date__c, Session_Token__c, Session_Expires__c FROM Portal_Login__c WHERE Session_Token__c != null AND Session_Token__c = :session];
            if (portalLogins.size() == 0) {
                throw new AuraException('INVALID_SESSION');
            }
            
            if (portalLogins[0].Session_Expires__c < system.now()) {
                throw new AuraException('EXPIRED_SESSION');
            }
            
            if (portalLogins[0].Disabled__c == true) {
                throw new AuraException('DISABLED_LOGIN');
            }
            
            if (portalLogins[0].Expiration_Date__c != null && portalLogins[0].Expiration_Date__c < system.today()) {
                throw new AuraException('EXPIRED_LOGIN');
            }
            
            LoginInfo loginInfo = new LoginInfo();
            loginInfo.PortalLogin = portalLogins[0];      
            loginInfo.PortalLogin.Session_Expires__c = system.now().addHours(1); //refresh hours to expire
            update loginInfo.PortalLogin;

            Staging_Account__c sa = StagingAccountController.getRecord(null, loginInfo.PortalLogin.Account__c);
            if (sa != null) {
                loginInfo.StagingAccountId = sa.Id;
            }

            Staging_Contact__c sc = StagingContactController.getRecord(null, loginInfo.PortalLogin.Contact__c);
            if (sc != null) {
                loginInfo.StagingContactId = sc.Id;
            }
            loginInfo.Authorized = true;
            
            return loginInfo;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static LoginInfo login(String username, String password) {
        try {
            List<Portal_Login__c> portalLogins = [SELECT Id, Name, Account__c, Account__r.Name, Contact__c, Password__c, Disabled__c, Expiration_Date__c, Session_Token__c, Session_Expires__c FROM Portal_Login__c WHERE Username__c = :username];
            if (portalLogins.size() == 0) {
                throw new AuraException('INVALID_CREDENTIAL');
            }
            
            if (!portalLogins[0].Password__c.equals(password)) {
                throw new AuraException('INVALID_CREDENTIAL');
            }
            
            if (portalLogins[0].Disabled__c == true) {
                throw new AuraException('DISABLED_LOGIN');
            }
            
            if (portalLogins[0].Expiration_Date__c != null && portalLogins[0].Expiration_Date__c < system.today()) {
                throw new AuraException('EXPIRED_LOGIN');
            }
            
            LoginInfo loginInfo = new LoginInfo();
            loginInfo.PortalLogin = portalLogins[0];
            
            String session = generateRandomString(20);
            while ([SELECT Id FROM Portal_Login__c WHERE Session_Token__c = :session FOR UPDATE].size() > 0) {
                session = generateRandomString(20);
            }
            loginInfo.PortalLogin.Session_Token__c = session;            
            loginInfo.PortalLogin.Session_Expires__c = system.now().addHours(1); //1 hours to expire
            loginInfo.PortalLogin.Last_Login_Date__c= system.now();
            update loginInfo.PortalLogin;

            Staging_Account__c sa = StagingAccountController.getRecord(null, loginInfo.PortalLogin.Account__c);
            if (sa != null) {
                loginInfo.StagingAccountId = sa.Id;
            }

            Staging_Contact__c sc = StagingContactController.getRecord(null, loginInfo.PortalLogin.Contact__c);
            if (sc != null) {
                loginInfo.StagingContactId = sc.Id;
            }
            loginInfo.Authorized = true;
            
            return loginInfo;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    public class LoginInfo {
        @AuraEnabled
        public Portal_Login__c PortalLogin { set; get; }
        
        @AuraEnabled
        public Id StagingAccountId { set; get; }
        
        @AuraEnabled
        public Id StagingContactId { set; get; }
        
        @AuraEnabled
        public Boolean Authorized { set; get; }
        
    }

}