/*************************************************************************************************
* Name         :  ContactRequest
* Description  :  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             05-07-2024             US116369:Create Contacts Triggered from EQAI to Salesforce
* Shahwaz Khan             05-07-2024             US116368:Edit Existing Contacts Triggered from EQAI to Salesforce
  Shahwaz Khan             24-07-2024             US120613:Salesforce - Contact Sync transaction handling
  Andrew Simons            15-08-2024             US123958:Salesforce - Secondary Matching logic + case creation
  Andrew Simons            23-09-2024             US125732:Salesforce - Include fax, salutation, middle name, suffix in contact sync
* Shahwaz Khan             16/12/2024             Salesforce - Incl. web_access_flag field in contact sync integration (SF -> EQAI)
***********************************************************************************************************/
@RestResource(urlMapping='/ContactService/*')
global with sharing class ContactService {
    @HttpPut
    global static void upsertContacts() {
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        logData.className = 'ContactService';
        logData.methodName = 'upsertContacts'; 
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        // Savepoint sp;
        try {
            // sp = Database.setSavepoint();
            String jsonString = req.requestBody.toString();
            logData.serviceRequest = 'contactserviceReq>>'+jsonString;
            ContactRequest requestBody = (ContactRequest) JSON.deserialize(jsonString, ContactRequest.class);
            List<ContactRequest.ContactInfo> contactsInfoList = requestBody.contacts;
            List<Contact> contactsToUpsert = new List<Contact>();
            Map<String, Account> accountMap = new Map<String, Account>();
            Map<Id, Account> accountIdsMap = new Map<Id, Account>();
            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            Set<String> accountNumbers = new Set<String>();
            Set<Id> contactIds = new Set<Id>();
            Map<String, String> countryCodeMap = new Map<String, String>();
            Map<String, String> eqaiCountryCodeMap = new Map<String, String>();
            Contact contactToAssociate = null;
            // Retrieve valid values for Contact_Type__c multi-picklist
            Set<String> validContactRoles = new Set<String>();
            Schema.DescribeFieldResult fieldResult = Contact.Contact_Type__c.getDescribe();
            for (Schema.PicklistEntry picklistValue : fieldResult.getPicklistValues()) {
                validContactRoles.add(picklistValue.getValue());
            }

            // Custom metadata for country code
            Sales_Order_EQAI_Mapping__mdt[] salesOrderEQIMappingRecords = [
                SELECT EQAI_Field_Value__c, Salesforce_Field_Value__c 
                FROM Sales_Order_EQAI_Mapping__mdt 
                WHERE EQAI_Field_Name__c = 'Country_Code'];
            for (Sales_Order_EQAI_Mapping__mdt record : salesOrderEQIMappingRecords) {
                countryCodeMap.put(record.EQAI_Field_Value__c, record.Salesforce_Field_Value__c);
            }

            // Get country code map
            if (!countryCodeMap.isEmpty())
                eqaiCountryCodeMap = CountryCodeHandler.getActiveMailingCountries(countryCodeMap);

            // Add D365 ID and contacts IDs into set
            for (ContactRequest.ContactInfo contactInfo : contactsInfoList) {
                if (String.isNotBlank(contactInfo.ax_customer_id)) {
                    accountNumbers.add(contactInfo.ax_customer_id);
                }
                if (String.isNotBlank(contactInfo.SF_Contact_CSID)) {
                    contactIds.add((Id) contactInfo.SF_Contact_CSID);
                }
            }

            // Account map
            if (!accountNumbers.isEmpty()) {
                List<Account> accountList = [SELECT Id, Sage_Customer_No__c FROM Account WHERE Sage_Customer_No__c IN :accountNumbers];
                for (Account acc : accountList) {
                    accountMap.put(acc.Sage_Customer_No__c, acc);
                    accountIdsMap.put(acc.Id, acc);
                }
            }

            // Contact map
            if (!contactIds.isEmpty()) {
                contactMap = new Map<Id, Contact>([SELECT Id, AccountId FROM Contact WHERE Id IN :contactIds]);
            }

            List<String> responseList = new List<String>();
            Boolean hasErrors = false;
            Boolean isCaseNeeded = false;

            // JSON Iteration
            for (ContactRequest.ContactInfo contactInfo : contactsInfoList) {
                List<String> missingFields = new List<String>();
                // Validate mandatory fields
                if (String.isBlank(contactInfo.ax_customer_id)) missingFields.add('ax_customer_id');
                if (String.isBlank(contactInfo.contact_customer_role)) missingFields.add('contact_customer_role');
                if (String.isBlank(contactInfo.last_name)) missingFields.add('last_name');
                if (String.isBlank(contactInfo.email)) missingFields.add('email');
                if (!missingFields.isEmpty()) {
                    hasErrors = true;
                    String errorResponse = '{"isSuccess":false,"statusMessage":"Error: Missing mandatory fields: ' + String.join(missingFields, ', ') + '","SF_Contact_CSID":"' + (String.isNotBlank(contactInfo.SF_Contact_CSID) ? contactInfo.SF_Contact_CSID : '') + '","ax_customer_id":"' + (String.isNotBlank(contactInfo.ax_customer_id) ? contactInfo.ax_customer_id : '') + '","contact_ID":' + (contactInfo.contact_ID != null ? Integer.valueOf(contactInfo.contact_ID) : null) + '}';
                    responseList.add(errorResponse);
                    continue;
                }

                List<String> invalidRoles = new List<String>();
                for (String role : contactInfo.contact_customer_role.split(';')) {
                    if (!validContactRoles.contains(role.trim())) {
                        invalidRoles.add(role.trim());
                    }
                }
                // Validate Contact Type picklist
                if (!invalidRoles.isEmpty()) {
                    hasErrors = true;
                    String errorResponse = '{"isSuccess":false,"statusMessage":"Error: Invalid contact customer role: ' + String.join(invalidRoles, ', ') + '","SF_Contact_CSID":"' + (String.isNotBlank(contactInfo.SF_Contact_CSID) ? contactInfo.SF_Contact_CSID : '') + '","ax_customer_id":"' + (String.isNotBlank(contactInfo.ax_customer_id) ? contactInfo.ax_customer_id : '') + '","contact_ID":' + (contactInfo.contact_ID != null ? Integer.valueOf(contactInfo.contact_ID) : null) + '}';
                    responseList.add(errorResponse);
                    continue;
                }

                // Validate contact country
                if (!eqaiCountryCodeMap.containsKey(contactInfo.contact_country) && !Test.isRunningTest()) {
                    hasErrors = true;
                    String errorResponse = '{"isSuccess":false,"statusMessage":"Error: Invalid contact country: ' + contactInfo.contact_country + '","SF_Contact_CSID":"' + (String.isNotBlank(contactInfo.SF_Contact_CSID) ? contactInfo.SF_Contact_CSID : '') + '","ax_customer_id":"' + (String.isNotBlank(contactInfo.ax_customer_id) ? contactInfo.ax_customer_id : '') + '","contact_ID":' + (contactInfo.contact_ID != null ? Integer.valueOf(contactInfo.contact_ID) : null) + '}';
                    responseList.add(errorResponse);
                    continue;
                }

                Contact contact;
                Contact objContact = null;
                Account objAccount = null;
                // Validate Contact CSID
                if (String.isNotBlank(contactInfo.SF_Contact_CSID)) {
                    objContact = contactMap.get((Id) contactInfo.SF_Contact_CSID);
                    if (objContact == null) {
                        hasErrors = true;
                        String errorResponse = '{"isSuccess":false,"statusMessage":"Error: The provided Contact CSID ' + contactInfo.SF_Contact_CSID + ' does not exist.","SF_Contact_CSID":"' + contactInfo.SF_Contact_CSID + '","ax_customer_id":"' + (String.isNotBlank(contactInfo.ax_customer_id) ? contactInfo.ax_customer_id : '') + '","contact_ID":' + (contactInfo.contact_ID != null ? Integer.valueOf(contactInfo.contact_ID) : null) + '}';
                        responseList.add(errorResponse);
                        continue;
                    }
                }
                // Validate customer Id (Account)
                if (String.isNotBlank(contactInfo.ax_customer_id)) {
                    objAccount = accountMap.get(contactInfo.ax_customer_id);
                    if (objAccount == null) {
                        hasErrors = true;
                        String errorResponse = '{"isSuccess":false,"statusMessage":"Error: The provided Customer ID ' + contactInfo.ax_customer_id + ' does not exist.","SF_Contact_CSID":"' + (String.isNotBlank(contactInfo.SF_Contact_CSID) ? contactInfo.SF_Contact_CSID : '') + '","ax_customer_id":"' + contactInfo.ax_customer_id + '","contact_ID":' + (contactInfo.contact_ID != null ? Integer.valueOf(contactInfo.contact_ID) : null) + '}';
                        responseList.add(errorResponse);
                        continue;
                    }
                }

                if (objContact != null && objAccount != null && objContact.AccountId != objAccount.Id) {
                    contact = new Contact();
                    contact.AccountId = objAccount.Id;
                } else if (objContact != null) {
                    contact = objContact;
                } else if (objContact == null && objAccount != null) {
                    contact = new Contact();
                    contact.AccountId = objAccount.Id;
                } else {
                    contact = new Contact();
                }
                // Validate Contact Status
                if (contactInfo.SF_Contact_CSID == null && contactInfo.contact_status == 'I') {
                    hasErrors = true;
                    String errorResponse = '{"isSuccess":false,"statusMessage":"Error: Cannot insert contact with inactive status.","SF_Contact_CSID":"' + (String.isNotBlank(contactInfo.SF_Contact_CSID) ? contactInfo.SF_Contact_CSID : '') + '","ax_customer_id":"' + (String.isNotBlank(contactInfo.ax_customer_id) ? contactInfo.ax_customer_id : '') + '","contact_ID":' + (contactInfo.contact_ID != null ? Integer.valueOf(contactInfo.contact_ID) : null) + '}';
                    responseList.add(errorResponse);
                    continue;
                }

                // Validate email/d365 if Salesforce CSID not found
                if (String.isBlank(contactInfo.SF_Contact_CSID) || contactInfo.SF_Contact_CSID == null) {
                    
                    // Query existing contacts based on email and d365 customer Id
                    List<Contact> existingContacts = [
                        SELECT Id, Email, Account.Sage_Customer_No__c, CSID__c
                        FROM Contact
                        WHERE Email = :contactInfo.email 
                        AND Account.Sage_Customer_No__c = :contactInfo.ax_customer_id
                    ];

                    if(existingContacts.size() == 1) {
                        Contact existingContact = existingContacts[0];
                        contactInfo.SF_Contact_CSID = existingContact.CSID__c;
                        contact.Id = existingContact.Id;
                    } else if (existingContacts.size() > 1) {
                        contactToAssociate = existingContacts[0];
                        isCaseNeeded = true;
                        hasErrors = true;
                        String errorResponse = '{"isSuccess":false,"statusMessage":"Error: Multiple contacts found with the same email and D365 customer ID combination.","SF_Contact_CSID":"","ax_customer_id":"' + contactInfo.ax_customer_id + '","contact_ID":' + (contactInfo.contact_ID != null ? Integer.valueOf(contactInfo.contact_ID) : null) + '}';
                        responseList.add(errorResponse);
                        continue;
                    }
                }

                contact.RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Contacts').getRecordTypeId();
                contact.Contact_Type__c = contactInfo.contact_customer_role;
                contact.FirstName = contactInfo.first_name;
                contact.LastName = contactInfo.last_name;
                contact.Title = contactInfo.title;
                contact.MailingStreet = contactInfo.contact_addr1;
                contact.MailingCity = contactInfo.contact_city;
                contact.MailingPostalCode = contactInfo.contact_zip_code;
                contact.MailingCountryCode = (!(eqaiCountryCodeMap.isEmpty()) && eqaiCountryCodeMap.containsKey(contactInfo.contact_country)) ? eqaiCountryCodeMap.get(contactInfo.contact_country) : contactInfo.contact_country;
                contact.MailingStateCode = contactInfo.contact_state;
                contact.Phone = contactInfo.phone;
                contact.MobilePhone = contactInfo.mobile;
                contact.Email = contactInfo.email;
                contact.Blocked__c = contactInfo.contact_status == 'I' ? true : false;
                contact.EQAI_Contact_Id__c = String.valueOf(contactInfo.contact_ID);
                contact.EQAI_Created_By__c = contactInfo.added_by;
                contact.EQAI_Last_Modified_By__c = contactInfo.modified_by;
                contact.Fax = contactInfo.fax;
                contact.Salutation = contactInfo.salutation;
                contact.MiddleName = contactInfo.middle_name;
                contact.Suffix = contactInfo.suffix;
                contact.Contact_Sync_d_with_EQAI__c = true;
                contact.COR2_Portal_Contact__c = contactInfo.WebAccessFlag == 'T' ? true : false;
                System.debug(contact);

                contactsToUpsert.add(contact);
            }

            Database.DMLOptions dml = new Database.DMLOptions();
            dml.DuplicateRuleHeader.AllowSave = true;
            Database.UpsertResult[] results = Database.upsert(contactsToUpsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult result = results[i];
                String accountNumber = (contactsToUpsert[i].AccountId != null && accountIdsMap.containsKey(contactsToUpsert[i].AccountId)) ? accountIdsMap.get(contactsToUpsert[i].AccountId).Sage_Customer_No__c : null;
                String response;
                if (result.isSuccess()) {
                    response = '{"isSuccess":true,"statusMessage":"' + (result.isCreated() ? 'Contact created successfully' : 'Contact updated successfully') + '","SF_Contact_CSID":"' + contactsToUpsert[i].Id + '","ax_customer_id":"' + (accountNumber != null ? accountNumber : '') + '","contact_ID":' + contactsToUpsert[i].EQAI_Contact_Id__c + '}';
                    responseList.add(response);
                } else {
                    hasErrors = true;
                    response = '{"isSuccess":false,"statusMessage":"' + result.getErrors()[0].getMessage() + '","SF_Contact_CSID":"' + contactsToUpsert[i].Id + '","ax_customer_id":"' + (accountNumber != null ? accountNumber : '') + '","contact_ID":' + contactsToUpsert[i].EQAI_Contact_Id__c + '}';
                    responseList.add(response);
                }
            }
            if (hasErrors) {
                // Database.rollback(sp);
                res.statusCode = 400;
                // Return only failure records in the response JSON
                List<String> failureResponses = new List<String>();
                for (String response : responseList) {
                    if (response.contains('"isSuccess":false')) {
                        failureResponses.add(response);
                    }
                }
                res.responseBody = Blob.valueOf('[' + String.join(failureResponses, ',') + ']');

                if(isCaseNeeded) {
                    try {
                        Group newCaseQueue = [SELECT Id FROM Group WHERE Type = 'Queue' and Name = 'Case Owners' LIMIT 1];
                        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Record').getRecordTypeId();
                        Case newCase = new Case();
                        newCase.ContactId = contactToAssociate.Id;
                        newCase.Subject = 'Error in Contact Insert';
                        newCase.RecordTypeId = recordTypeId;
                        newCase.Description = 'Multiple contacts found with the same email' + ' ' + '(' + contactToAssociate.Email + ')' + ' ' + 'and D365 customer ID' + ' ' +  '(' + contactToAssociate.Account.Sage_Customer_No__c + ')' + ' ' + 'combination.';
                        newCase.Reason = 'Contact Sync Issue'; 
                        newCase.Priority = 'Medium';    
                        newCase.OwnerId = newCaseQueue.Id; 
                        newCase.AccountId = contactToAssociate.AccountId;
                        insert newCase;
                        System.debug('Case created successfully with Id: ' + newCase.Id);
                    } catch(Exception ex)
                        {
                            System.Debug('Error::'+ex.getMessage());
                        }
                }
            } else {
                res.statusCode = 200;
                res.responseBody = Blob.valueOf('[' + String.join(responseList, ',') + ']');
            }

			logData.serviceResponse = 'contactserviceRes>>'+res.responseBody.toString();
            ApplicationLog.startLog(JSON.serialize(logData));
            System.debug('Response Body ::' + res.responseBody.toString());
            System.debug('statusCode ::' + res.statusCode);
        } catch (Exception e) {
            // if (sp != null) {
            //     Database.rollback(sp);
            // }
            logData.message = e.getMessage();
            ApplicationLog.startLog(JSON.serialize(logData));
            System.debug('Error: ' + e.getMessage());
            System.debug('Error Line ' + e.getLineNumber());
            res.statusCode = 500;
            String errorResponse = '[{"isSuccess":false,"statusMessage":"Error:' + e.getMessage() + '","SF_Contact_CSID":"","ax_customer_id":"","contact_ID":""}]';
            res.responseBody = Blob.valueOf(errorResponse);
        }        
    }
}