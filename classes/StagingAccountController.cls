public without sharing class StagingAccountController {
    private final ApexPages.StandardController controller;
    private final ApexPages.StandardSetController setController;
    public Staging_Account__c StagingAccount { get; set; }
    public Account Account { get; set; }
    
    public Boolean ResetUpdateRequestEmailSentFlag { set; get; }
    
    
    public StagingAccountController(ApexPages.StandardController controller) {
        this.controller = controller;
        
        this.StagingAccount = getRecord(controller.getId(), null);
        if (this.StagingAccount != null) {
            this.Account = getAccount(this.StagingAccount.Account__c);
        }
    }
        
    public StagingAccountController(ApexPages.StandardSetController controller) {
        this.setController = controller;
    }
    
    public PageReference ImportAccounts() {
        try {
            StagingAccountImportBatchable batch = new StagingAccountImportBatchable();
            
            batch.EmailAddress = userInfo.getUserEmail();
            batch.ResetUpdateRequestEmailSentFlag = this.ResetUpdateRequestEmailSentFlag;
            Database.executeBatch(batch, 200);
            return new ApexPages.Action('{!List}').invoke();
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }

    public PageReference SyncAccount() {
        Savepoint sp = Database.setSavepoint();
        try {        
            update this.Account;
            
            //create note
            if (this.StagingAccount.Is_Synced__c != true) { //prevent multiple notes get created
                if (String.isNotEmpty(this.StagingAccount.Notes__c)) {                    
                    ContentNote note = new ContentNote();
                    note.Title = 'Notes from customer - ' + this.StagingAccount.Last_Updated_By__r.Name + ' ' + this.StagingAccount.Last_Updated_Date__c.format('MM/dd/yyyy');
                    note.Content = Blob.valueOf(this.StagingAccount.Notes__c);
                    
                    if (this.StagingAccount.Note_Id__c != null) {
                        note.Id = this.StagingAccount.Note_Id__c;
                        update note;
                    }
                    else {
                        insert note;
                        ContentDocumentLink docLink = new ContentDocumentLink();
                        docLink.LinkedEntityId = this.StagingAccount.Account__c;
                        docLink.ContentDocumentId = note.Id;
                        docLink.shareType = 'V'; 
                        insert docLink;
                    }
                    
                    this.StagingAccount.Note_Id__c = note.Id;
                }
            }
            
            this.StagingAccount.Is_Updated__c = false;
            this.StagingAccount.Is_Synced__c = true;
            this.StagingAccount.Last_Sync_Date__c = system.now();
            update this.StagingAccount;
            
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Salesforce account is saved.'));
            return null;
        }
        catch(exception ex) {
            Database.rollback(sp);
            ApexPages.addMessages(ex);
            return null;
        }
    }
        
    /*
    public PageReference SyncAccounts() {
        try {
            StagingAccountSyncBatchable batch = new StagingAccountSyncBatchable();
            batch.EmailAddress = userInfo.getUserEmail();
            Database.executeBatch(batch, 200);
            return new ApexPages.Action('{!List}').invoke();
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }
    */
    
    public void copyName() {
        this.Account.Name = this.StagingAccount.Name;
    }
    public void copyBillingStreet() {
        this.Account.BillingStreet = this.StagingAccount.Billing_Street__c;
    }
    public void copyBillingCity() {
        this.Account.BillingCity = this.StagingAccount.Billing_City__c;
    }
    public void copyBillingState() {
        this.Account.BillingStateCode = this.StagingAccount.Billing_State__c;
    }
    public void copyBillingPostalCode() {
        this.Account.BillingPostalCode = this.StagingAccount.Billing_Postal_Code__c;
    }
    public void copyBillingCountry() {
        this.Account.BillingCountryCode = this.StagingAccount.Billing_Country__c;
    }
    
    public void copyAll() {
        this.Account.Name = this.StagingAccount.Name;
        this.Account.BillingStreet = this.StagingAccount.Billing_Street__c;
        this.Account.BillingCity = this.StagingAccount.Billing_City__c;
        this.Account.BillingStateCode = this.StagingAccount.BIlling_State__c;
        this.Account.BillingPostalCode = this.StagingAccount.Billing_Postal_Code__c;
        this.Account.BillingCountryCode = this.StagingAccount.Billing_Country__c;    
    }
    
    public PageReference SendAccountUpdateRequestEmails() {
        try {            
            SendAccountUpdateRequestEmails(null);
        
            return new ApexPages.Action('{!List}').invoke();
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }
    
    public PageReference Close() {
        return new ApexPages.Action('{!List}').invoke();
    }
    
    public PageReference GoToAccount() {
        return new PageReference('/' + this.Account.Id);
    }
        
    public static Staging_Account__c InitStagingAccount(Account acct, Boolean resetSentFlag) {
        Staging_Account__c sa = new Staging_Account__c();
        sa.Account__c = acct.Id;
        sa.Name = acct.Name;
        sa.Billing_Street__c = acct.BillingStreet;
        sa.Billing_City__c = acct.BillingCity;
        sa.Billing_State__c = acct.BillingStateCode;
        sa.Billing_Postal_Code__c = acct.BillingPostalCode;
        sa.Billing_Country__c = acct.BillingCountryCode;
        sa.Is_Synced__c = false;
        sa.Is_Updated__c = false;
        sa.Error_Text__c = null;
        if (resetSentFlag == true) {
            sa.Update_Request_Email_Sent__c = false;
            sa.Note_Id__c = null;
        }
        return sa;
    }
    
    
    public static void LinkStagingAcountsToPortalLogins(List<Id> acctIds) {
        List<Staging_Account__c> sas = [SELECT Id, Account__c FROM Staging_Account__c WHERE Account__c IN :acctIds];
        
        Map<Id, List<Portal_Login__c>> mapLoginsByAccountId = new Map<Id, List<Portal_Login__c>>();
        for (Portal_Login__c login : [SELECT Id, Account__c FROM Portal_Login__c WHERE Account__c IN :acctIds]) {
            List<Portal_Login__c> logins;
            if (mapLoginsByAccountId.containsKey(login.Account__c)) {
                logins = mapLoginsByAccountId.get(login.Account__c);
            }
            else {
                logins = new List<Portal_Login__c>();
                mapLoginsByAccountId.put(login.Account__c, logins);
            }
            
            logins.add(login);
        }
        
        List<Id> saIds = new List<Id>();
        for (Staging_Account__c sa : sas) {
            saIds.add(sa.Id);
        }
        
        Map<Id, Map<Id, Staging_Account_Login_Activity__c>> mapActivitiesByLoginIdByAccountId = new Map<Id, Map<Id, Staging_Account_Login_Activity__c>>();
        for (Staging_Account_Login_Activity__c activity : [SELECT Id, Staging_Account__c, Staging_Account__r.Account__c, Portal_Login__c, Portal_Login__r.Account__c FROM Staging_Account_Login_Activity__c WHERE Staging_Account__c IN :saIds]) {
            Map<Id, Staging_Account_Login_Activity__c> mapActivitiesByLoginId;
            if (mapActivitiesByLoginIdByAccountId.containsKey(activity.Staging_Account__c)) {
                mapActivitiesByLoginId = mapActivitiesByLoginIdByAccountId.get(activity.Staging_Account__c);
            }
            else {
                mapActivitiesByLoginId = new Map<Id, Staging_Account_Login_Activity__c>();
                mapActivitiesByLoginIdByAccountId.put(activity.Staging_Account__c, mapActivitiesByLoginId);
            }
            mapActivitiesByLoginId.put(activity.Portal_Login__c, activity);
        }
        
        List<Staging_Account_Login_Activity__c> activitiesToInsert = new List<Staging_Account_Login_Activity__c>();
        for (Staging_Account__c sa : sas) {
            if (mapLoginsByAccountId.containsKey(sa.Account__c)) {
                List<Portal_Login__c> logins = mapLoginsByAccountId.get(sa.Account__c);
                if (mapActivitiesByLoginIdByAccountId.containsKey(sa.Id)) {
                    Map<Id, Staging_Account_Login_Activity__c> mapActivitiesByLoginId = mapActivitiesByLoginIdByAccountId.get(sa.Id);
                    for (Portal_Login__c login : logins) {
                        if (!mapActivitiesByLoginId.containsKey(login.Id)) {
                            activitiesToInsert.add(new Staging_Account_Login_Activity__c(Staging_Account__c = sa.Id, Portal_Login__c = login.Id));
                        }
                    }
                }
                else {
                    for (Portal_Login__c login : logins) {
                        activitiesToInsert.add(new Staging_Account_Login_Activity__c(Staging_Account__c = sa.Id, Portal_Login__c = login.Id));
                    }
                }
            }
        }
        
        if (activitiesToInsert.size() > 0) {
            insert activitiesToInsert;
        }
    }
    
    //stage the account to send email when a prospect is converted to customer
    public static void StageAccount(Id acctId) {
        Savepoint sp = Database.setSavepoint();
        try {
            Staging_Account__c sa = getRecord(null, acctId);
            if (sa == null) {
                Account acct = getAccount(acctId);
                sa = InitStagingAccount(acct, true);
                insert sa;
            
                if (acct.Contacts != null && acct.Contacts.size() > 0) {
                    //create portal login
                    List<Id> contactIds = new List<Id>();
                    for (Contact contact : acct.Contacts) {
                        contactIds.add(contact.Id);
                    }
                    List<Portal_Login__c> logins = PortalLoginController.CreatePortalLoginsFromContacts(contactIds, 5, false); //5 days to expire
                    SendAccountUpdateRequestEmails(new List<Id> { sa.Id });
                }
            }
            
            LinkStagingAcountsToPortalLogins(new List<Id>{acctId});
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    
    private static void SendAccountUpdateRequestEmails(List<Id> saIds) {
        StagingAccountUpdateRequestEmailBatch batch = new StagingAccountUpdateRequestEmailBatch();
        batch.StagingAccountIds = saIds;
        batch.EmailAddress = userInfo.getUserEmail();
        Database.executeBatch(batch, 50);
    }
    
    @AuraEnabled
    public static USPSAddress validateBillingAddress(String JSONAccount) {
        try {
            Staging_Account__c sa = (Staging_Account__c)JSON.deserialize(JSONAccount, Staging_Account__c.class);
        
            OrganizationConfigurations__c setting = OrganizationConfigurations__c.getOrgDefaults();        
            String USPS_USERID = setting.USPS_User_ID__c; //'836MICRO5325';
                    
            USPSAddress address2Check = new USPSAddress();
            address2Check.Address2 = sa.Billing_Street__c;
            address2Check.City = sa.Billing_City__c;
            address2Check.State = sa.Billing_State__c;
            address2Check.Zip5 = sa.Billing_Postal_Code__c;

            USPSAddress addressFromUSPS;
            if (address2Check.CanCheckAddress() == true) {
                addressFromUSPS = USPS.CheckAddress(address2check, USPS_USERID);
                if (addressFromUSPS.USPS_Returned_Error == true) {
                    throw new AuraException(addressFromUSPS.USPS_ERROR_DESC);
                }
            }
            else {
                throw new AuraException('Invalid address');
            }
            return addressFromUSPS;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Staging_Account__c getStagingAccountById(Id recordId) {
        try {
           return getRecord(recordId, null);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public static Staging_Account__c getRecord(Id recordId, Id accountId) {
        List<Id> recordIds;
        if (recordId != null) {
            recordIds = new List<Id> { recordId };
        }
        
        List<Id> accountIds;        
        if (accountId != null) {
            accountIds = new List<Id> { accountId };
        }
    
        List<Staging_Account__c> sas = getRecords(recordIds, accountIds, null);
        if (sas.size() > 0) {
            return sas[0];
        }
        return null;
    }
    
    public static List<Staging_Account__c> getRecords(List<Id> recordIds, List<Id> accountIds, List<String> additionalFilters) {
        List<String> filters = new List<String>();
        
        List<String> fields = new List<String>();
        for (String fieldName : Staging_Account__c.getSObjectType().getDescribe().fields.getMap().keySet()) {
            fields.add(fieldName);
        }
        fields.add('Last_Updated_By__r.Name');

        if (recordIds != null) {
            filters.add('Id IN :recordIds');
        }
        if (accountIds != null) {
            filters.add('Account__c IN :accountIds');
        }
        
        if (additionalFilters != null) {
            filters.addAll(additionalFilters);
        }

        String queryString = 'SELECT ' + String.join(fields, ',') + ' FROM Staging_Account__c';
        
        if (filters.size() > 0) {
            queryString += ' WHERE ' + String.join(filters, ' AND ');
        }

        return (List<Staging_Account__c>)Database.query(queryString);
    }
    
    
    
    private static Account getAccount(Id accountId) {
        List<Account> accts = [SELECT Id, Name, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode, BillingCountryCode, (SELECT Id, Name, Email FROM Contacts WHERE Contact_Type__c INCLUDES ('Billing') AND Email <> NULL) FROM Account WHERE Id = :accountId];
        if (accts.size() > 0) {
            return accts[0];
        }
        return null;
    }
    
    @AuraEnabled
    public static Staging_Account__c saveStagingAccount(String JSONAccount) {
        try {
            Staging_Account__c sa = (Staging_Account__c)JSON.deserializeStrict(JSONAccount, Staging_Account__c.class);
            sa.Is_Updated__c = true;
            sa.Note_Id__c = null;
            sa.Last_Updated_Date__c = system.now();
            sa.Is_Synced__c = false;
            update sa;
            return getStagingAccountById(sa.Id);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}