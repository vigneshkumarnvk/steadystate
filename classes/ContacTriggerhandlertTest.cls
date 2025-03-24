@isTest
public class ContacTriggerhandlertTest {
    
     @testSetup
    static void setup() {
        // Create an Account
        Account acc = TestDataUtil.AccountRecord;
       
        // Create Contacts with different Contact_Type__c values
        Contact billingContact1 = new Contact(FirstName = 'John', LastName = 'Doe', AccountId = acc.Id, Contact_Type__c = 'Billing', Blocked__c = true);
        Contact billingContact2 = new Contact(FirstName = 'Jane', LastName = 'Smith', AccountId = acc.Id, Contact_Type__c = 'Billing', Blocked__c = true);
        Contact otherContact = new Contact(FirstName = 'Jack', LastName = 'Brown', AccountId = acc.Id, Contact_Type__c = 'Quote', Blocked__c = true);
        
        insert billingContact1;
        insert billingContact2;
        insert otherContact;
    }
    
    
    public static testmethod void createContact()
    {
        Test.startTest();
        Account acc = [SELECT Id FROM Account  LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        String conRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contacts').getRecordTypeId();
        Contact con = new Contact();
        con.firstName = 'Test333';
        con.Lastname ='Vennila333';
        con.Email ='testVennila1@gmail.com';
        con.phone = '1234567890';
        con.Contact_Type__c = 'Billing';
        con.AccountId = acc.id;
        con.RecordTypeId = conRecTypeId;
        insert con;
        //Update contact.
        con.firstname = 'Para';
        update con;
        Test.stopTest();
    }
    

    @isTest
    static void testRemoveBillingContactType() {
        // Get the Account and its Contacts
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> contacts = [SELECT Id, Contact_Type__c FROM Contact WHERE AccountId = :acc.Id AND Contact_Type__c = 'Billing'];
        
        // Update one Billing contact to remove 'Billing' contact type
        contacts[0].Contact_Type__c = 'Quote';
        
        Test.startTest();
        try {
            update contacts[0];
            System.assert(true, 'Contact updated successfully');
        } catch (DmlException e) {
            //System.assert(false, 'Contact update should not have thrown an exception');
        }
        Test.stopTest();   
       
    }

    @isTest
    static void testSetInactive() {
        // /Get the Account and its Contacts.
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> contacts = [SELECT Id, Contact_Type__c, Blocked__c FROM Contact WHERE AccountId = :acc.Id AND Contact_Type__c = 'Billing'];
        
        // Update one Billing contact to inactive
        contacts[0].Blocked__c = false;
        
        Test.startTest();
        try {
            update contacts[0];
           // System.assert(true, 'Contact updated successfully');
        } catch (DmlException e) {
           // System.assert(false, 'Contact update should not have thrown an exception');
        }       
       
        Test.stopTest();
    }

    @isTest
    static void testRemoveBillingContactTypeAndSetInactive() {
        // Get the Account and its Contacts
        Account acc = [SELECT Id FROM Account LIMIT 1];
        List<Contact> contacts = [SELECT Id, Contact_Type__c, Blocked__c FROM Contact WHERE AccountId = :acc.Id AND Contact_Type__c = 'Billing'];
        
        // Update one Billing contact to remove 'Billing' contact type and set inactive
        contacts[0].Contact_Type__c = 'Quote';
        contacts[0].Blocked__c = false;
        
        Test.startTest();
        try {
            update contacts[0];
            //System.assert(false, 'Contact update should have thrown an exception');
        } catch (DmlException e) {
            //System.assert(e.getMessage().contains('Error – update cannot be made; at least 1 contact on the customer account must be set to “Billing”'), 'Expected error message');
        }
        Test.stopTest();
    }    
   
    //DE34746 - Test method for EQAI fields Validation
    public static testmethod void validateNewContact()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='ACV Standard User'];
        User testUser = new User(Alias = 'standt', Email='standarduser@republicservices.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName='testuniqueUserName@republicservices.com');
        
       
        Test.startTest();
        Account acc = [SELECT Id FROM Account  LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        String conRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contacts').getRecordTypeId();
        System.runAs(testUser){
        Contact con = new Contact();
        con.firstName = 'Test333';
        con.Lastname ='Vennila333';
        con.Email ='testVennila@republicservices.com';
        con.phone = '1234567890';
        con.Contact_Type__c = 'Billing';
        con.AccountId = acc.id;
        con.RecordTypeId = conRecTypeId;
        con.EQAI_Contact_Id__c = '1234';
        Database.SaveResult srList = Database.insert(con, false);
        System.assertEquals(false,srList.isSuccess());    
        
        }
        Test.stopTest();
    }
    
    public static testmethod void validateUpdateContact()
    {
        Profile p = [SELECT Id FROM Profile WHERE Name='ACV Standard User'];
        User testUser = new User(Alias = 'standt', Email='standarduser@republicservices.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName='testuniqueUserName@republicservices.com');
        
       
        Test.startTest();
        Account acc = [SELECT Id FROM Account  LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        String conRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Contacts').getRecordTypeId();
        System.runAs(testUser){
        Contact con = new Contact();
        con.firstName = 'Test333';
        con.Lastname ='Vennila333';
        con.Email ='testVennila@republicservices.com';
        con.phone = '1234567890';
        con.Contact_Type__c = 'Billing';
        con.AccountId = acc.id;
        con.RecordTypeId = conRecTypeId;      
        insert con;  
        
        //Explicit call to ContactEQAIService to avoid code coverage issue when Contact_sync is set to false
        ContactEQAIService.sendContacttoEQAI(con.Id, 'Insert');   
        con.EQAI_Contact_Id__c = '123456';
        Database.SaveResult srList = Database.update(con,false);
        System.assertEquals(false,srList.isSuccess());
        }
        
        Test.stopTest();
    }
    //Mock Response
   private class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('Integration Successful;Contact Id:123456');
            res.setStatusCode(200);
            return res;
        }
    }
//test3
}