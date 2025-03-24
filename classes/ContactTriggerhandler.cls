/*************************************************************************************************
* Name         :  ContactEQAIService 
* Description  :  Apex Class for API call out of the work order Quote Service
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vennila Paramasivam		07/08/2024				Whenever a Contact insert/update it will sync to EQAI
* Andrew Simons             07/17/2024              Check to see if the contact type is only "Site" and do not sync with EQAI on insert or update
* Pavithra P				07/30/2024              DE34746 - [Continued] SF - New EQAI Contact is getting created while cloning the record  but it shouldn't be (All users except admin )
* Shahwaz Khan              16/12/2024              Salesforce - Incl. web_access_flag field in contact sync integration (SF -> EQAI).
****************************************************************************************************************************************/
public class ContactTriggerhandler {
    public static User currentUser = [SELECT Id, Profile.Name FROM USER WHERE Id = :userinfo.getUserId()];
    public static String conRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contacts').getRecordTypeId();
    
    Public Static Void onAfterInsert(List<Contact> ContactService){
        List<Contact> contactList = new List<Contact>();
        User currUser = [SELECT Id, Profile.Name FROM USER WHERE Id = :userinfo.getUserId()];
        String conRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contacts').getRecordTypeId();

        for(Contact currCon : contactService) {
            Boolean isOnlySite = currCon.Contact_Type__c != null && currCon.Contact_Type__c.split(';').size() == 1 && currCon.Contact_Type__c.contains('Site');
            if( currUser.Profile.Name != 'Salesforce API Only System Integrations'
               && currCon.RecordTypeId == conRecTypeId && !isOnlySite && Label.Contact_Sync == 'True')
            {
                contactList.add(currCon);
            }
        }
        if(!contactList.isEmpty()) {
            ContactEQAIService.sendContacttoEQAI(contactList[0].id, 'Insert');
    }         
}

Public Static Void onAfterUpdate(List<Contact> ContactService, Map<Id,Contact> oldContactMap){
    List<Contact> contactList = new List<Contact>();
    User currUser = [SELECT Id, Profile.Name FROM USER WHERE Id = :userinfo.getUserId()];
    String conRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contacts').getRecordTypeId();
    for(Contact con : contactService) {
        Boolean isOnlySite = con.Contact_Type__c != null && con.Contact_Type__c.split(';').size() == 1 && con.Contact_Type__c.contains('Site');
        Boolean wasMultipleContactTypes = oldContactMap.get(con.Id).Contact_Type__c != null && oldContactMap.get(con.Id).Contact_Type__c.split(';').size() > 1;
        Contact oldCon = oldContactMap.get(con.id);
        if((con.FirstName != oldCon.FirstName || con.Lastname != oldCon.Lastname || con.AccountId != oldCon.AccountId 
            || con.Email != oldCon.Email
            || con.COR2_Portal_Contact__c != oldCon.COR2_Portal_Contact__c 
            || con.Phone != oldCon.Phone || con.MobilePhone!= oldCon.MobilePhone || con.Title != oldCon.Title
            || con.Contact_Type__c != oldCon.Contact_Type__c || con.MailingAddress != oldCon.MailingAddress
            || con.MailingCity != oldCon.MailingCity || con.MailingStateCode != oldCon.MailingStateCode
            || con.MailingCountry != oldCon.MailingCountry || con.Blocked__c != oldCon.Blocked__c 
            || con.Fax != oldCon.Fax || con.Salutation != oldCon.Salutation || con.MiddleName != oldCon.MiddleName || con.Suffix != oldCon.Suffix)
           && (((wasMultipleContactTypes && isOnlySite) || con.Contact_Sync_d_with_EQAI__c) || !isOnlySite)
           && currUser.Profile.Name != 'Salesforce API Only System Integrations'
           && con.RecordTypeId == conRecTypeId && Label.Contact_Sync == 'True')
        {
            contactList.add(con);
        }
    }
    if(!contactList.isEmpty()) {
        if(contactList[0].Contact_Sync_d_with_EQAI__c == True) {
            ContactEQAIService.sendContacttoEQAI(contactList[0].id, 'Update');
        } else {
            ContactEQAIService.sendContacttoEQAI(contactList[0].id, 'Insert');
        }
    }
}
public static void onBeforeUpdate(List<Contact> ContactService, Map<Id,Contact> oldContactMap)
{
    Set<Id> accountIds = new Set<Id>();
    Map<Id, Integer> billingContactCountMap = new Map<Id, Integer>();
    Set<Id> contactIds = new Set<Id>();
    for (Contact con : ContactService) {
        Contact oldCon = oldContactMap.get(con.Id);    
        //DE34746 - Validate EQAI fields
        if(!ContactEQAIServiceJson.isSkipValidation && currentUser.Profile.Name != 'Salesforce API Only System Integrations' && currentUser.Profile.Name != 'System Administrator' && con.RecordTypeId == conRecordTypeId){
            if(oldCon.EQAI_Contact_Id__c != con.EQAI_Contact_Id__c || oldCon.EQAI_Created_By__c != con.EQAI_Created_By__c ||
               oldCon.EQAI_Last_Modified_By__c != con.EQAI_Last_Modified_By__c || oldCon.Contact_Sync_d_with_EQAI__c != con.Contact_Sync_d_with_EQAI__c){
                con.addError('EQAI Contact Id, EQAI Created By, EQAI Last Modified,Contact Sync\'d with EQAI By cannot be modified.');
            }
        }

        // Check if the Billing contact type is being removed
        if (((oldCon.Contact_Type__c != null && oldCon.Contact_Type__c.contains('Billing')) && (con.Contact_Type__c == null || !con.Contact_Type__c.contains('Billing'))) 
                || ((oldCon.Contact_Type__c != null && oldCon.Contact_Type__c.contains('Billing')) && con.Blocked__c == True && oldCon.Blocked__c == False)) {
                accountIds.add(con.AccountId);
                contactIds.add(con.Id);
            }
    }
    // Only proceed if there are account IDs to check
    if (!accountIds.isEmpty()) {
        // Query for other Billing contacts for the affected accounts
        List<Contact> otherBillingContacts = [
            SELECT AccountId 
            FROM Contact 
            WHERE AccountId IN :accountIds 
            AND Contact_Type__c includes ('Billing')
            AND Blocked__c = False
            AND Id NOT IN :contactIds
        ];
        
        // Populate the billingContactCountMap with the count of other Billing contacts
        for (Contact con : otherBillingContacts) {
            if (billingContactCountMap.containsKey(con.AccountId)) {
                billingContactCountMap.put(con.AccountId, billingContactCountMap.get(con.AccountId) + 1);
            } else {
                billingContactCountMap.put(con.AccountId, 1);
            }
        }
        
        // Loop through the contacts being updated again to apply the validation
        for (Contact con : ContactService) {
            Contact oldCon = oldContactMap.get(con.Id);
            
            if ((oldCon.Contact_Type__c.contains('Billing') && !con.Contact_Type__c.contains('Billing')) ||
                (oldCon.Contact_Type__c.contains('Billing') && con.Blocked__c == True && oldCon.Blocked__c == False)){
                    Integer otherBillingCount = billingContactCountMap.get(con.AccountId);
                    
                    // If there are no other Billing contacts for the Account, add an error
                    if (otherBillingCount == null || otherBillingCount == 0) {
                        con.addError('Error – update cannot be made; at least 1 contact on the customer account must be set to “Billing”');
                    }
                }
        }
    }
}

public static void onBeforeInsert(List<Contact> ContactService){
    
    Map<Id,Contact> clonedContactRecordId = new Map<Id,Contact>();
    for (Contact con : ContactService) {
        //DE34746 - Validate EQAI Fields
        if(!ContactEQAIServiceJson.isSkipValidation && currentUser.Profile.Name != 'Salesforce API Only System Integrations' && currentUser.Profile.Name != 'System Administrator' && con.RecordTypeId == conRecordTypeId){
            if(!con.isClone() && (con.EQAI_Contact_Id__c != null || con.EQAI_Created_By__c != null || con.EQAI_Last_Modified_By__c != null || con.Contact_Sync_d_with_EQAI__c)){
                con.addError('EQAI Contact Id, EQAI Created By, EQAI Last Modified,Contact Sync\'d with EQAI By cannot be modified.');
            }else if(con.isClone()){
                clonedContactRecordId.put(con.getCloneSourceId(),con);
            }
        }            
    }
    if(!clonedContactRecordId.isEmpty()){
        for(Contact sourceContact : [SELECT Id, EQAI_Contact_Id__c,EQAI_Created_By__c, EQAI_Last_Modified_By__c,Contact_Sync_d_with_EQAI__c FROM Contact WHERE Id IN: clonedContactRecordId.KeySet()]){
            if(sourceContact.EQAI_Contact_Id__c != clonedContactRecordId.get(sourceContact.Id).EQAI_Contact_Id__c ||
               sourceContact.EQAI_Created_By__c != clonedContactRecordId.get(sourceContact.Id).EQAI_Created_By__c ||
               sourceContact.EQAI_Last_Modified_By__c != clonedContactRecordId.get(sourceContact.Id).EQAI_Last_Modified_By__c ||
              sourceContact.Contact_Sync_d_with_EQAI__c != clonedContactRecordId.get(sourceContact.Id).Contact_Sync_d_with_EQAI__c ){
                clonedContactRecordId.get(sourceContact.Id).addError('EQAI Contact Id, EQAI Created By, EQAI Last Modified,Contact Sync\'d with EQAI By cannot be modified.');
            }
        }
    }
}
}