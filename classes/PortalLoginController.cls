public with sharing class PortalLoginController {
    public static Boolean SkipTrigger;

    private final ApexPages.standardController controller;
    public Portal_Login__c PortalLogin { set; get; }    
    
    public PortalLoginController(ApexPages.StandardController controller) {
        this.controller = controller;

        List<Portal_Login__c> logins = getRecords(new List<Id> { this.controller.getId() }, null, null, false, null);
        if (logins.size() > 0) {
            this.PortalLogin = logins[0];
        }
    }
    
   
    
    public PortalLoginController(ApexPages.StandardSetController controller) {

    }

    public PageReference SendLoginCredential() {
        try {
            List<Portal_Login__c> logins = getRecords(new List<Id> { this.controller.getId() }, null, null, true, null);
            if (logins.size() > 0) {
                if (logins[0].Login_Credential_Sent__c == true) {
                    throw new DataException('The credential was sent for this login. Please uncheck "Login Credential Sent" to send the credential again.');
                }
                SendLoginCredentials(logins);
            }
            else {
                throw new DataException('This login is disabled or expired. Unable to send the credential.');
            }
            return this.controller.view().setRedirect(true);
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }
    

    public PageReference SendLoginCredentials() {
        try {
            PortalLoginSendLoginCredentialsBatchable batch = new PortalLoginSendLoginCredentialsBatchable();
            batch.EmailAddress = userInfo.getUserEmail();
            Database.executeBatch(batch, 100);
            return new ApexPages.Action('{!List}').invoke();
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }    
    
    public static void SendLoginCredentials(List<Portal_Login__c> logins) {
        EmailTemplate emailTemplate;
        
        List<EmailTemplate> templates = [SELECT Id, Name FROM EmailTemplate WHERE Name = 'Customer Portal Login Credential Email'];
        if (templates.size() > 0) {
            emailTemplate = templates[0];
        }
        else {
            throw new DataException('Lightning email template \'Customer Portal Login Credential Email\' is not found.');
        }
        
        OrgWideEmailAddress owa = [SELECT Id, DisplayName, Address FROM OrgWideEmailAddress WHERE DisplayName = 'Republic Services' LIMIT 1];
        
        
        //*** disable sending emails to real clients in sandbox ****
        Id prodOrgId = '00Df40000000Ns9';
        List<String> allowedEmails = new List<String>();
        allowedEmails.add('kchen@micro-datanet.com');
        allowedEmails.add('dscerbo@acvenviro.com');
        allowedEmails.add('jmarcotte@acvenviro.com');
        allowedEmails.add('rvandra@acvenviro.com');
        

        //ticket 19130 <<
        if (!Test.isRunningTest()) {
        //ticket 19130 >>
            for (Integer i = 0; i < logins.size(); i++) {
                Portal_Login__c login = logins[i];

                if (!userInfo.getOrganizationId().contains(prodOrgId) && !allowedEmails.contains(login.Email__c)) {
                    logins.remove(i);
                    i--;
                } else if (login.Contact__r.IsEmailBounced == true) {
                    logins.remove(i);
                    i--;
                }
            }
        //ticket 19130 <<
        }
        //ticket 19130 >>

        if (logins.size() == 0) {
            throw new DataException('The email addresses are limited to: ' + String.join(allowedEmails, '; ') + ' in this sandbox.');
        }
        //*** disable sending emails to real clients in sandbox ****

        
        Map<Id, Portal_Login__c> mapLogins = new Map<Id, Portal_Login__c>();
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();
        for (Portal_Login__c login : logins) {    
        
            if (!userInfo.getOrganizationId().contains(prodOrgId)) {
                if (!allowedEmails.contains(login.Email__c)) {
                    throw new DataException('Email ' + login.Email__c + ' is NOT allowed in the sandbox.');
                }
            }
            
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setOrgWideEmailAddressId(owa.Id);
            //19130 <<
            //if(CompanySettingUtil.isSandbox() != true) {
            if(CompanySettingUtil.isSandbox() != true || Test.isRunningTest() == true) {
            //19130 >>
                message.setTargetObjectId(login.Contact__c);
            }

            message.setToAddresses(new List<String> { login.Email__c });
            message.setWhatId(login.Id);
            message.setTemplateId(emailTemplate.Id);
            message.setSaveAsActivity(true);
            messages.add(message);
            
            mapLogins.put(login.Id, login);
        }
        
        if (messages.size() > 0) {    
            //!!!bypass setTargetObjectId requirements for using template
            Savepoint sp = Database.setSavepoint();
            Messaging.sendEmail(messages);
            Database.rollback(sp);
            
            List<Messaging.SingleEmailMessage> messagesToSend = new List<Messaging.SingleEmailMessage>();
            for (Messaging.SingleEmailMessage message : messages) {
                Portal_Login__c login = mapLogins.get(message.getWhatId());
                            
                Messaging.SingleEmailMessage messageToSend = new Messaging.SingleEmailMessage();
                messageToSend.setOrgWideEmailAddressId(owa.Id);
                //ticket 19130 <<
                //if(CompanySettingUtil.isSandbox() != true) {
                if(CompanySettingUtil.isSandbox() != true || Test.isRunningTest()) {
                    //ticket 19130 >>
                    messageToSend.setTargetObjectId(login.Contact__c);
                }
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
                    logins[i].Login_Credential_Sent__c = true;
                    logins[i].Login_Credential_Sent_Date__c = system.now();
                }
            }
        }
        update logins;
    }
    
    public static List<Portal_Login__c> CreatePortalLoginsFromContacts(List<Id> contactIds, Integer daysToExpire, Boolean resetExpirationDate) {
        List<Contact> contacts = [SELECT Id, Name, AccountId, Email FROM Contact WHERE Id IN :contactIds AND Email != null];
        
        List<String> emails = new List<String>();
        for (Contact contact : contacts) {
            emails.add(contact.Email);
        }
        
        //query logins with username like the email addresses
        List<String> filters = new List<String>();
        for (String email : emails) {
            Integer p = email.indexOf('@');
            string filter;
            if (p >= 0) {
                String name = email.substring(0, p);
                String domain = email.substring(p);
                filter = name + '%' + domain;
            }
            filters.add(filter);
        }
        Map<String, Portal_Login__c> mapLoginsByUsername = new Map<String, Portal_Login__c>();
        for (Portal_Login__c login : [SELECT Id, Username__c FROM Portal_Login__c WHERE Username__c LIKE :filters]) {
            mapLoginsByUsername.put(login.Username__c, login);
        }
        
        Map<Id, Portal_Login__c> mapLoginsByContactId = new Map<Id, Portal_Login__c>();
        for (Portal_Login__c login : [SELECT Id, Name, Account__c, Contact__c, Email__c, Expiration_Date__c, Disabled__c FROM Portal_Login__c WHERE Contact__c IN :contactIds]) {
            mapLoginsByContactId.put(login.Contact__c, login);
        }
        
        List<Portal_Login__c> loginsToUpsert = new List<Portal_Login__c>();
        for (Contact contact : contacts) {
            Portal_Login__c login;
            if (!mapLoginsByContactId.containsKey(contact.Id)) {
                Integer nextNumber = 0;
                String username = contact.Email;
                while (mapLoginsByUsername.containsKey(username)) {
                    nextNumber++;
                    String tempname = contact.Email;
                    String part1 = tempname.substring(0, tempname.indexOf('@'));
                    String part2 = tempname.substring(tempname.indexOf('@'));
                    username = part1 + nextNumber + part2;
                }
                
                String password = GeneratePassword(8);
                    
                login = new Portal_Login__c();
                login.Account__c = contact.AccountId;
                login.Contact__c = contact.Id;
                login.Email__c = contact.Email;
                login.Name = contact.Name;
                login.Username__c = username;
                login.Password__c = password;

                String session = CustomerPortalController.generateRandomString(20);
                login.Session_Token__c = session;
                login.Session_Expires__c = system.now().addDays(daysToExpire);

                if (daysToExpire > 0) {
                    login.Expiration_Date__c = system.today().addDays(daysToExpire);
                }
                loginsToUpsert.add(login);
                
                //include the login in the map for unique username check
                mapLoginsByUsername.put(username, login);
            }
            else {
                login = mapLoginsByContactId.get(contact.Id);
                Boolean updateLogin = false;
                /*
                if (login.Email__c != contact.Email) {
                    login.Email__c = contact.Email; //email changed detected, reset login credentail sent to send the credentails again
                    updateLogin = true;
                }*/
                
                if (login.Account__c != contact.AccountId) { //account change detected
                    login.Account__c = contact.AccountId;
                    updateLogin = true;
                }
                
                if (resetExpirationDate == true && login.Expiration_Date__c != system.today().addDays(daysToExpire) && login.Disabled__c != true) {
                    login.Expiration_Date__c = system.today().addDays(daysToExpire);
                    login.Login_Credential_Sent__c = false;
                    updateLogin = true;
                }
                
                if (updateLogin == true) {
                    loginsToUpsert.add(login);
                }
            }
        }
        upsert loginsToUpsert;
        return loginsToUpsert;
    }
    
    private static String GeneratePassword(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz!@#$%^';
        String randStr = '';
        while (randStr.length() < len) {
            Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
            randStr += chars.substring(idx, idx+1);
        }
        return randStr;
    }

    public static List<Portal_Login__c> getRecords(List<Id> recordIds, List<Id> accountIds, List<Id> contactIds, Boolean valid, List<String> additionalFilters) {
        List<String> fields = new List<String>();
        for (String fieldName : Portal_Login__c.getSObjectType().getDescribe().fields.getMap().keySet()) {
            fields.add(fieldName);
        }
        fields.add('Contact__r.IsEmailBounced');
        
        List<String> filters = new List<String>();
        if (recordIds != null) {
            filters.add('Id IN :recordIds');
        }
        
        if (accountIds != null) {
            filters.add('Account__c IN :accountIds');
        }
        
        if (contactIds != null) {
            filters.add('Contact__c IN :contactIds');
            filters.add('Contact__r.Blocked__c != TRUE');
        }
        
        if (valid == true) {
            filters.add('Disabled__c <> TRUE');
            Date today = system.today();
            filters.add('((Expiration_Date__c = NULL) OR (Expiration_Date__c >= :today))');
        }
        
        if (additionalFilters != null) {
            filters.addAll(additionalFilters);
        }
        
        String queryString = 'SELECT ' + String.join(fields, ',') + ' FROM Portal_Login__c';
        
        queryString += ' WHERE  ' + String.join(filters, ' AND ');
        
        return (List<Portal_Login__c>)Database.query(queryString);
    }
}