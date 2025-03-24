public without sharing class StagingContactController {
    private final ApexPages.StandardController controller;
    private final ApexPages.StandardSetController setController;
    public Staging_Contact__C StagingContact { get; set; }
    public Contact Contact { get; set; }
    
    public Boolean ResetUpdateRequestEmailSentFlag { set; get; }
        
    public StagingContactController(ApexPages.StandardController controller) {
        this.controller = controller;

        this.StagingContact = getRecord(controller.getId(), null);
        if (this.StagingContact != null) {
            this.Contact = getContact(this.StagingContact.Contact__c);
        }
    }
    
    public StagingContactController(ApexPages.StandardSetController controller) {
        this.setController = controller;
    }
    
    public PageReference ImportContacts() {
        try {
            StagingContactImportBatchable batch = new StagingContactImportBatchable();
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
    
    public PageReference SyncContact() {
        Savepoint sp = Database.setSavepoint();
        try {
            update this.Contact;
            
            //create note
            if (this.StagingContact.Is_Synced__c != true) { //prevent multiple notes get created
                if (String.isNotEmpty(this.StagingContact.Notes__c)) {                    
                    ContentNote note = new ContentNote();
                    note.Title = 'Notes from customer - ' + this.StagingContact.Last_Updated_By__r.Name + ' ' + this.StagingContact.Last_Updated_Date__c.format('MM/dd/yyyy');
                    note.Content = Blob.valueOf(this.StagingContact.Notes__c);
                    
                    if (this.StagingContact.Note_Id__c != null) {
                        note.Id = this.StagingContact.Note_Id__c;
                        update note;
                    }
                    else {
                        insert note;
                        ContentDocumentLink docLink = new ContentDocumentLink();
                        docLink.LinkedEntityId = this.StagingContact.Contact__c;
                        docLink.ContentDocumentId = note.Id;
                        docLink.shareType = 'V'; 
                        insert docLink;
                    }
                    
                    this.StagingContact.Note_Id__c = note.Id;
                }
            }
            
            this.StagingContact.Is_Updated__c = false;
            this.StagingContact.Is_Synced__c = true;
            this.StagingContact.Last_Sync_Date__c = system.now();
            update this.StagingContact;
            
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Salesforce contact is saved.'));
            return null;
        }
        catch(exception ex) {
            Database.rollback(sp);
            ApexPages.addMessages(ex);
            return null;
        }
    }    
    
    /*
    public PageReference SyncContacts() {
        try {
            StagingContactSyncBatchable batch = new StagingContactSyncBatchable();
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
    
    public void copyFirstName() {
        this.Contact.FirstName = this.StagingContact.First_Name__c;
    }
    public void copyMiddleName() {
        this.Contact.MiddleName = this.StagingContact.Middle_Name__c;
    }
    public void copyLastName() {
        this.Contact.LastName = this.StagingContact.Last_Name__c;
    }
    public void copyStreet() {
        this.Contact.MailingStreet = this.StagingContact.Street__c;
    }
    public void copyCity() {
        this.Contact.MailingCity = this.StagingContact.City__c;
    }
    public void copyState() {
        this.Contact.MailingStateCode = this.StagingContact.State__c;
    }
    public void copyPostalCode() {
        this.Contact.MailingPostalCode = this.StagingContact.Postal_Code__c;
    }
    public void copyCountry() {
        this.Contact.MailingCountryCode = this.StagingContact.Country__c;
    }
    public void copyPhone() {
        this.Contact.Phone = this.StagingContact.Phone__c;
    }
    public void copyEmail() {
        this.Contact.Email = this.StagingContact.Email__c;
    }
    public void copyMobilePhone() {
        this.Contact.Phone = this.StagingContact.Mobile_Phone__c;
    }
    public void copyTitle() {
        this.Contact.Title = this.StagingContact.Title__c;
    }
    
    public void copyAll() {   
        this.Contact.FirstName = this.StagingContact.First_Name__c;
        this.Contact.MiddleName = this.StagingContact.Middle_Name__c;
        this.Contact.LastName = this.StagingContact.Last_Name__c;
        this.Contact.Title = this.StagingContact.Title__c;        
        this.Contact.MailingStreet = this.StagingContact.Street__c;
        this.Contact.MailingCity = this.StagingContact.City__c;
        this.Contact.MailingStateCode = this.StagingContact.State__c;
        this.Contact.MailingPostalCode = this.StagingContact.Postal_Code__c;
        this.Contact.MailingCountryCode = this.StagingContact.Country__c;
        this.Contact.Phone = this.StagingContact.Phone__c;
        this.Contact.Email = this.StagingContact.Email__c;    
        this.Contact.MobilePhone = this.StagingContact.Mobile_Phone__c;        
    }
    
    public PageReference SendContactUpdateRequestEmails() {
        try {
            SendContactUpdateRequestEmails(null);
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
    
    public PageReference GoToContact() {
        return new PageReference('/' + this.Contact.Id);
    }

    public static void StageContact(Id contId) {
        Savepoint sp = Database.setSavepoint();
        try {
            Staging_Contact__c sc = getRecord(null, contId);
            if (sc == null) {
                Contact cont = getContact(contId);
                sc = InitStagingContact(cont, true);
                insert sc;
            

                List<Id> contactIds = new List<Id>();
                contactIds.add(cont.Id);
                List<Portal_Login__c> logins = PortalLoginController.CreatePortalLoginsFromContacts(contactIds, 5, false); //5 days to expire
                SendContactUpdateRequestEmails(new List<Id> { sc.Id });
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
            
    public static Staging_Contact__c InitStagingContact(Contact cnt, Boolean resetSentFlag) {
        Staging_Contact__c sc = new Staging_Contact__c();
        sc.Account__c = cnt.AccountId;
        sc.Contact__c = cnt.Id;
        sc.Name = cnt.Name;
        sc.Title__c = cnt.Title;
        sc.Last_Name__c = cnt.LastName;
        sc.First_Name__c = cnt.FirstName;
        sc.Middle_Name__c = cnt.MiddleName;
        sc.Street__c = cnt.MailingStreet;
        sc.City__c = cnt.MailingCity;
        sc.State__c = cnt.MailingStateCode;
        sc.Postal_Code__c = cnt.MailingPostalCode;
        sc.Country__c = cnt.MailingCountryCode;
        sc.Phone__c = cnt.Phone;
        sc.Mobile_Phone__c = cnt.MobilePhone;
        sc.Email__c = cnt.Email;
        sc.Is_Synced__c = false;
        sc.Is_Updated__c = false;
        sc.Error_Text__c = null;
        if (resetSentFlag == true) {
            sc.Update_Request_Email_Sent__c = false;
            sc.Note_Id__c = null;
        }
        return sc;
    }
    
    private static void SendContactUpdateRequestEmails(List<Id> scIds) {
        StagingContactUpdateRequestEmailBatch batch = new StagingContactUpdateRequestEmailBatch();
        batch.StagingContactIds = scIds;
        batch.EmailAddress = userInfo.getUserEmail();
        Database.executeBatch(batch, 50);
    }
    
    @AuraEnabled
    public static USPSAddress validateBillingAddress(String JSONContact) {
        try {
            Staging_Contact__c stagingContact  = (Staging_Contact__c)JSON.deserialize(JSONContact, Staging_Contact__c.class);
        
            OrganizationConfigurations__c setting = OrganizationConfigurations__c.getOrgDefaults();        
            String USPS_USERID = setting.USPS_User_ID__c; //'836MICRO5325';
                    
            USPSAddress address2Check = new USPSAddress();
            address2Check.Address2 = stagingContact.Street__c;
            address2Check.City = stagingContact.City__c;
            address2Check.State = stagingContact.State__c;
            address2Check.Zip5 = stagingContact.Postal_Code__c;

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
    public static Staging_Contact__c getStagingContactById(Id recordId) {
        try {
            return getRecord(recordId, null);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public static Staging_Contact__c getRecord(Id recordId, Id contactId) {
        List<Id> recordIds;
        if (recordId != null) {
            recordIds = new List<Id> { recordId };
        }
        
        List<Id> contactIds;        
        if (contactId != null) {
            contactIds = new List<Id> { contactId };
        }
        List<Staging_Contact__c> scs = getRecords(recordIds, contactIds, null);
        if (scs.size() > 0) {
            return scs[0];
        }
        return null;
    }
    
    public static List<Staging_Contact__c> getRecords(List<Id> recordIds, List<Id> contactIds, List<String> additionalFilters) {
        List<String> filters = new List<String>();
        
        List<String> fields = new List<String>();
        for (String fieldName : Staging_Contact__c.getSObjectType().getDescribe().fields.getMap().keySet()) {
            fields.add(fieldName);
        }
        fields.add('Last_Updated_By__r.Name');
        
        if (recordIds != null) {
            filters.add('Id IN :recordIds');
        }
        if (contactIds != null) {
            filters.add('Contact__c IN :contactIds');
            filters.add('Contact__r.Blocked__c != TRUE');
        }

        if (additionalFilters != null) {
            filters.addAll(additionalFilters);
        }
        
        String queryString = 'SELECT ' + String.join(fields, ',') + ' FROM Staging_Contact__c';
        if (filters.size() > 0) {
            queryString += ' WHERE ' + String.join(filters, ' AND ');
        }
        return (List<Staging_Contact__c>)Database.query(queryString);
    }
    
    private static Contact getContact(Id contactId) {
        List<Contact> conts = [SELECT Id, Name, FirstName, MiddleName, LastName, AccountId, MailingStreet, MailingCity, MailingStateCode, MailingPostalCode, MailingCountryCode, Phone, Email, MobilePhone, Title FROM Contact WHERE Id = :contactId];
        if (conts.size() > 0) {
            return conts[0];
        }
        return null;
    }
    
    @AuraEnabled
    public static Staging_Contact__c saveStagingContact(String JSONContact) {
        try {
            Staging_Contact__c sc = (Staging_Contact__c)JSON.deserialize(JSONContact, Staging_Contact__c.class);
            sc.Is_Updated__c = true;
            sc.Last_Updated_Date__c = system.now();
            sc.Is_Synced__c = false;
            update sc;
            return getStagingContactById(sc.Id);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
}