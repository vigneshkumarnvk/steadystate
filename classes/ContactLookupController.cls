/*
* Class Name: ContactLookupController
* Created By  : Sanjana Ravichandran 
*
* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Sanjana Ravichandran        08/07/2024              US116101: [Continued] Salesforce - Add "Contact Lookup" function to lookup contacts currently in EQAI
Sanjana Ravichandran		01/15/2024				US137295: [Unplanned] Salesforce - EQAI Contact ID not populating when Contact selected via Lookup
*************************************************************************************************************/
public class ContactLookupController {
    
    @AuraEnabled
    public static ResponseWrapper getContactLookup(String model) {
        try {
            Map<String, Object> searchCriteria = (Map<String, Object>) JSON.deserializeUntyped(model);
            
            String email = (String) searchCriteria.get('email');
            String firstName = (String) searchCriteria.get('firstName');
            String lastName = (String) searchCriteria.get('lastName');
            String phone = (String) searchCriteria.get('phone');
            String customer = (String) searchCriteria.get('customer');
            
            if (email == null) {
                throw new AuraHandledException('Email is required.');
            }
            
            firstName = firstName != null ? firstName : '';
            lastName = lastName != null ? lastName : '';
            phone = phone != null ? phone : '';
            customer = customer != null ? customer : '';
            
            ResponseWrapper resWrapper = EQAIGetContactInfoAPI.getMatchingContacts(email, firstName, lastName, phone, customer);
            
            if (resWrapper.error != null) {
                throw new AuraHandledException('Error fetching contacts: ' + resWrapper.error);
            }
            
            return resWrapper;
            
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
            throw new AuraHandledException('Error fetching contacts: ' + e.getMessage());
        }
    }
    
    
    public class ResponseWrapper {
        @AuraEnabled public List<ContactResponse> contactList;
        @AuraEnabled public String error;
        
        public ResponseWrapper() {
            contactList = new List<ContactResponse>();
            error = null;
        }
    }
    
    public class ContactResponse {
        @AuraEnabled public String FirstName;
        @AuraEnabled public String LastName;
        @AuraEnabled public String Email;
        @AuraEnabled public String Phone;
        @AuraEnabled public String ContactCompany; 
        @AuraEnabled public Integer ContactId; 
        
        public ContactResponse() {
            ContactCompany = null;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Account getAccountDetails(String accountId) {
        try {
            return [SELECT Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry,BillingCountryCode,BillingStateCode FROM Account WHERE Id = :accountId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching account details: ' + e.getMessage());
        }
    }
}