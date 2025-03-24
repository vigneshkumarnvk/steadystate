@IsTest
public class ContactTestClass {
    @IsTest
    static void testGetContactLookup_Success() {
        Test.setMock(HttpCalloutMock.class, new EQAIGetContactInfoAPIMock());

        String model = '{"email":"test@example.com","firstName":"John","lastName":"Doe","phone":"1234567890","customer":"TestCustomer"}';

        ContactLookupController.ResponseWrapper response = ContactLookupController.getContactLookup(model);

        System.assert(response.error == null, 'Expected no error');
        System.assert(response.contactList.size() > 0, 'Expected some contacts in the response');
      
    }

    @IsTest
    static void testGetContactLookup_Error() {
        // Mocking the API callout to return an error
        Test.setMock(HttpCalloutMock.class, new EQAIGetContactInfoAPIMock(true));

        // Create test data test commit
        String model = '{"email":"test@example.com","firstName":"John","lastName":"Doe","phone":"1234567890","customer":"TestCustomer"}';

        // Call the method and verify results
        try {
            ContactLookupController.getContactLookup(model);
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            // System.assert(e.getMessage().contains('Error fetching contacts'), 'Expected error message');
        }
    }

    @IsTest
    static void testGetAccountDetails_Success() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Call the method and verify results
        Account account = ContactLookupController.getAccountDetails(testAccount.Id);
    }

 @IsTest
    static void testGetAccountDetails_Error() {
        // Call the method with a non-existent account ID and verify results
        try {
            ContactLookupController.getAccountDetails('nonExistentId');
            System.assert(false, 'Expected AuraHandledException');
        } catch (AuraHandledException e) {
            //System.assert(e.getMessage().contains('Error fetching account details'), 'Expected error message');
        }
    }

    private class EQAIGetContactInfoAPIMock implements HttpCalloutMock {
        private Boolean shouldError;

        EQAIGetContactInfoAPIMock(Boolean shouldError) {
            this.shouldError = shouldError;
        }

        EQAIGetContactInfoAPIMock() {
            this(false);
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            if (shouldError) {
                res.setStatusCode(500);
                res.setBody('Internal Server Error');
            } else {
                res.setStatusCode(200);
                res.setBody('[{"FirstName":"John","LastName":"Doe","Email":"john.doe@example.com","Phone":"1234567890","Account":{"Name":"TestAccount"}}]');
            }
            return res;
        }
    }
}
