/*
* Class Name: EQAIGetContactInfoAPI
* Created By  : Sanjana Ravichandran 
*
* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Sanjana Ravichandran        08/07/2024              US116101: [Continued] Salesforce - Add "Contact Lookup" function to lookup contacts currently in EQAI
Pavithra P				    08-05-2024			    US118581 - Salesforce - Add integration log 
Sanjana Ravichandran		01/15/2024				US137295: [Unplanned] Salesforce - EQAI Contact ID not populating when Contact selected via Lookup
*************************************************************************************************************/
public class EQAIGetContactInfoAPI {
    
    public static ContactLookupController.ResponseWrapper getMatchingContacts(String email, String firstName, String lastName, String phone, String customer) {
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        logData.className = 'EQAIGetContactInfoAPI'; 
        logData.methodName = 'getMatchingContacts';
        EQAI_API_URL_Extensions__mdt getContactInfo = [SELECT API_Extension__c, API_Key__c, API_Token__c, DeveloperName FROM EQAI_API_URL_Extensions__mdt WHERE DeveloperName = 'GetContactInfo'];
        String endpoint = 'callout:EQAI_Base_URL' + getContactInfo.API_Extension__c + 
            '?FirstName=' + EncodingUtil.urlEncode(firstName, 'UTF-8') + 
            '&LastName=' + EncodingUtil.urlEncode(lastName, 'UTF-8') + 
            '&Phone=' + EncodingUtil.urlEncode(phone, 'UTF-8') + 
            '&Email=' + EncodingUtil.urlEncode(email, 'UTF-8') + 
            '&ContactCompany=' + EncodingUtil.urlEncode(customer, 'UTF-8'); 
      
        System.debug('Endpoint: ' + endpoint);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setHeader('x-api-key', getContactInfo.API_Key__c);
        req.setHeader('x-secret-token', getContactInfo.API_Token__c);
        req.setHeader('Content-Type', 'application/json');
        req.setMethod('GET');
        req.setTimeout(30000);
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        String responseBody = res.getBody();
        System.debug('Response Body: ' + responseBody);
        logData.serviceRequest = 'contactLookupReq>>' + endpoint;
		logData.serviceResponse = 'contactLookupRes>>' + responseBody;
        ContactLookupController.ResponseWrapper resWrapper = new ContactLookupController.ResponseWrapper();
        
        if (res.getStatusCode() == 200) {
            try {
                List<ContactLookupController.ContactResponse> contacts = new List<ContactLookupController.ContactResponse>();
                
                List<Object> parsedResponse = (List<Object>) JSON.deserializeUntyped(responseBody);
                for (Object obj : parsedResponse) {
                    Map<String, Object> contactMap = (Map<String, Object>) obj;
                    ContactLookupController.ContactResponse contact = new ContactLookupController.ContactResponse();
                    system.debug('contactMap'+contactMap.get('contact_company'));
                    contact.FirstName = (String) contactMap.get('first_name');
                    contact.LastName = (String) contactMap.get('last_name');
                    contact.Email = (String) contactMap.get('email');
                    contact.Phone = (String) contactMap.get('phone');
    				contact.ContactCompany = (String) contactMap.get('contact_company'); // Ensure correct field name
                    contact.ContactId = (Integer) contactMap.get('contact_id');
                    system.debug('------->'+(String) contactMap.get('contact_company'));
                    contacts.add(contact);
                    system.debug('contact--->'+contact);
                }
                
                resWrapper.contactList = contacts;
                resWrapper.error = null;
            } catch (Exception ex) {
                logData.message = ex.getMessage();
                System.debug('Error parsing response: ' + ex.getMessage());
                
                resWrapper.contactList = null;
                resWrapper.error = 'Error parsing response: ' + ex.getMessage();
            }
        } else {
            resWrapper.contactList = null;
            resWrapper.error = 'Error response from EQAI: ' + res.getBody();
        }
        
        System.debug('Response Wrapper: ' + resWrapper);
        ApplicationLog.startLog(JSON.serialize(logData));
        return resWrapper;
    }
}