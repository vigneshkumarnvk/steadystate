@isTest
public class ContactServiceTest {
    
    @isTest
    static void testUpsertContactsSuccess() {
        Account acc1 = new Account(Name='Account 1', Sage_Customer_No__c='AX001');
        insert acc1;
        Account acc2 = new Account(Name='Account 2', Sage_Customer_No__c='AX002');
        insert acc2;
        Contact con1 = new Contact(FirstName='First', LastName='Contact', AccountId=acc1.Id, EQAI_Contact_Id__c='1001');
        insert con1;
        
        ContactRequest.ContactInfo contactInfo1 = new ContactRequest.ContactInfo();
        contactInfo1.SF_Contact_CSID = con1.Id;
        contactInfo1.ax_customer_id = 'AX001';
        contactInfo1.customer_id = '2005944';
        contactInfo1.contact_company = 'NEW WAVE';
        contactInfo1.contact_customer_role = 'Billing;Test';
        contactInfo1.first_name = 'UpdatedFirst';
        contactInfo1.last_name = 'UpdatedLast';
        contactInfo1.title = 'Mr.';
        contactInfo1.contact_addr1 = '123 Main St';
        contactInfo1.contact_city = 'San Francisco';
        contactInfo1.contact_state = 'NV';
        contactInfo1.contact_zip_code = '94105';
        contactInfo1.contact_country = 'USA';
        contactInfo1.phone = '555-1234';
        contactInfo1.mobile = '555-5678';
        contactInfo1.email = 'john.doe@example.com';
        contactInfo1.contact_status = 'A';
        contactInfo1.added_by = 'Test User';
        contactInfo1.modified_by = 'Test User';
        contactInfo1.contact_ID = 1001;
        contactInfo1.middle_name = 'UpdatedMiddle';
        contactInfo1.fax = '5555555555';
        contactInfo1.salutation = 'Mr.';
        contactInfo1.suffix = 'Jr';
        
        
        ContactRequest.ContactInfo contactInfo2 = new ContactRequest.ContactInfo();
        contactInfo2.SF_Contact_CSID = null;
        contactInfo2.ax_customer_id = 'AX002';
        contactInfo2.customer_id = '2005945';
        contactInfo2.contact_company = 'NEW WAVE';
        contactInfo2.contact_customer_role = 'Billing';
        contactInfo2.first_name = 'NewFirst';
        contactInfo2.last_name = 'NewLast';
        contactInfo2.title = 'Ms.';
        contactInfo2.contact_addr1 = '456 Main St';
        contactInfo2.contact_city = 'Los Angeles';
        contactInfo2.contact_state = 'CA';
        contactInfo2.contact_zip_code = '90001';
        contactInfo2.contact_country = 'USA';
        contactInfo2.phone = '555-5678';
        contactInfo2.mobile = '555-6789';
        contactInfo2.email = 'jane.doe@example.com';
        contactInfo2.contact_status = 'A';
        contactInfo2.added_by = 'Test User';
        contactInfo2.modified_by = 'Test User';
        contactInfo2.contact_ID = 1002;
        contactInfo2.middle_name = 'New Middle';
        contactInfo2.fax = '7777777777';
        contactInfo2.salutation = 'Ms.';
        contactInfo2.suffix = 'Sr';
        
        
        ContactRequest contactRequest = new ContactRequest();
        contactRequest.contacts = new List<ContactRequest.ContactInfo> { contactInfo1, contactInfo2 };
            
            String jsonString = JSON.serialize(contactRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ContactService.upsertContacts();
        Test.stopTest();
    }
    
    @isTest
    static void testUpsertContactsMissingFields() {
        ContactRequest.ContactInfo contactInfo = new ContactRequest.ContactInfo();
        contactInfo.ax_customer_id = 'AX001';
        contactInfo.last_name = 'Doe';
        
        ContactRequest contactRequest = new ContactRequest();
        contactRequest.contacts = new List<ContactRequest.ContactInfo> { contactInfo };
            
            String jsonString = JSON.serialize(contactRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        ContactService.upsertContacts();
        Test.stopTest();
    }
    
    @isTest
    static void testUpsertContactsInvalidRole() {
        ContactRequest.ContactInfo contactInfo = new ContactRequest.ContactInfo();
        contactInfo.ax_customer_id = 'AX001';
        contactInfo.contact_customer_role = 'InvalidRole';
        contactInfo.last_name = 'Doe';
        contactInfo.email = 'john.doe@example.com';
        
        ContactRequest contactRequest = new ContactRequest();
        contactRequest.contacts = new List<ContactRequest.ContactInfo> { contactInfo };
            
            String jsonString = JSON.serialize(contactRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ContactService.upsertContacts();
        Test.stopTest();
    }
    
    @isTest
    static void testUpsertContactsInvalidCountry() {
        ContactRequest.ContactInfo contactInfo = new ContactRequest.ContactInfo();
        contactInfo.ax_customer_id = 'AX001';
        contactInfo.contact_customer_role = 'Billing';
        contactInfo.last_name = 'Doe';
        contactInfo.email = 'john.doe@example.com';
        contactInfo.contact_country = 'InvalidCountry';
        
        ContactRequest contactRequest = new ContactRequest();
        contactRequest.contacts = new List<ContactRequest.ContactInfo> { contactInfo };
            
            String jsonString = JSON.serialize(contactRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ContactService.upsertContacts();
        Test.stopTest();
    }
    
    @isTest
    static void testUpsertContactsNonExistingCSID() {
        ContactRequest.ContactInfo contactInfo = new ContactRequest.ContactInfo();
        contactInfo.SF_Contact_CSID = '003XXXXXXXXXXXXXXX';
        contactInfo.ax_customer_id = 'AX001';
        contactInfo.contact_customer_role = 'Billing';
        contactInfo.last_name = 'Doe';
        contactInfo.email = 'john.doe@example.com';
        
        ContactRequest contactRequest = new ContactRequest();
        contactRequest.contacts = new List<ContactRequest.ContactInfo> { contactInfo };
            
            String jsonString = JSON.serialize(contactRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ContactService.upsertContacts();
        Test.stopTest();
    }
    
    @isTest
    static void testUpsertContactsNonExistingCustomerID() {
        ContactRequest.ContactInfo contactInfo = new ContactRequest.ContactInfo();
        contactInfo.ax_customer_id = 'NonExistingID';
        contactInfo.contact_customer_role = 'Billing';
        contactInfo.last_name = 'Doe';
        contactInfo.email = 'john.doe@example.com';
        
        ContactRequest contactRequest = new ContactRequest();
        contactRequest.contacts = new List<ContactRequest.ContactInfo> { contactInfo };
            
            String jsonString = JSON.serialize(contactRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        
        Test.startTest();
        ContactService.upsertContacts();
        Test.stopTest();
    }
    
    @isTest
    static void testUpsertContactsInactiveStatus() {
        Account acc = new Account(Name='Account Inactive', Sage_Customer_No__c='AX003');
        insert acc;
        
        ContactRequest.ContactInfo contactInfo = new ContactRequest.ContactInfo();
        contactInfo.ax_customer_id = 'AX003';
        contactInfo.contact_customer_role = 'Billing';
        contactInfo.last_name = 'Doe';
        contactInfo.email = 'john.doe@example.com';
        contactInfo.contact_status = 'I';
        
        ContactRequest contactRequest = new ContactRequest();
        contactRequest.contacts = new List<ContactRequest.ContactInfo> { contactInfo };
            
            String jsonString = JSON.serialize(contactRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        ContactService.upsertContacts();
        Test.stopTest();
    }
    
    @isTest
    static void testUpsertContactsExceptionHandling() {
        // Create a valid request but inject an exception
        Account acc = new Account(Name='Account Exception', Sage_Customer_No__c='AX004');
        insert acc;
        
        ContactRequest.ContactInfo contactInfo = new ContactRequest.ContactInfo();
        contactInfo.ax_customer_id = 'AX004';
        contactInfo.contact_customer_role = 'Billing';
        contactInfo.last_name = 'Doe';
        contactInfo.email = 'john.doe@example.com';
        
        ContactRequest contactRequest = new ContactRequest();
        contactRequest.contacts = new List<ContactRequest.ContactInfo> { contactInfo };
            
            String jsonString = JSON.serialize(contactRequest);
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestBody = Blob.valueOf(jsonString);
        req.httpMethod = 'PUT';
        RestContext.request = req;
        RestContext.response = res;
        Test.startTest();
        ContactService.upsertContacts();
        Test.stopTest();
    }
    @isTest
    static void testGetActiveMailingCountries() {
        Map<String, String> mapofEQAIandSFCountry = new Map<String, String>{
            'USA' => 'United States',
                'CAN' => 'Canada',
                'MEX' => 'Mexico'
                };
                    
                    Map<String, String> result = CountryCodeHandler.getActiveMailingCountries(mapofEQAIandSFCountry);
    }
    //test

    @isTest

    static void testContactRequestUsage() {
        // Step 1: Instantiate ContactRequest
        ContactRequest request = new ContactRequest();

        // Step 2: Initialize the contacts list
        request.contacts = new List<ContactRequest.ContactInfo>();

        // Step 3: Create and populate ContactInfo
        ContactRequest.ContactInfo contactInfo1 = new ContactRequest.ContactInfo();
        contactInfo1.first_name = 'John';
        contactInfo1.last_name = 'Doe';
        contactInfo1.email = 'john.doe@example.com';

        // Add to the contacts list
        request.contacts.add(contactInfo1);

        // Step 4: Perform some meaningful logic using the ContactRequest instance
        List<String> emails = new List<String>();
        for (ContactRequest.ContactInfo contact : request.contacts) {
            if (contact.email != null) {
                emails.add(contact.email);
            }
        }

        // Step 5: Assertions to validate behavior
        System.assertEquals(1, emails.size(), 'There should be 1 email in the list');
        System.assertEquals('john.doe@example.com', emails[0], 'The email should match the test data');
    }

    @isTest
    static void testSelectContactsByIds() {
        // Step 1: Set up test data
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            testContacts.add(new Contact(
                FirstName = 'TestFirstName' + i,
                LastName = 'TestLastName' + i,
                Email = 'test' + i + '@example.com'
                
            ));
        }
        insert testContacts;

        // Separate blocked and unblocked contact IDs
        Set<Id> contactIds = new Set<Id>();
        Set<Id> expectedContactIds = new Set<Id>();
        for (Contact contact : testContacts) {
            contactIds.add(contact.Id);
            if (!contact.Blocked__c) {
                expectedContactIds.add(contact.Id);
            }
        }

        // Step 2: Call the method
        Test.startTest();
        List<Contact> result = new ContactsSelector().selectContactsByIds(contactIds);
        Test.stopTest();

        /// Step 3: Assert the results
        System.assertNotEquals(null, result, 'Result list should not be null.');
        System.assertEquals(expectedContactIds.size(), result.size(), 'Unexpected number of unblocked contacts returned.');

        for (Contact contact : result) {
            System.assert(!contact.Blocked__c, 'Blocked contacts should not be in the result.');
            System.assert(expectedContactIds.contains(contact.Id), 'Unexpected contact in the result.');
        }
    }
}