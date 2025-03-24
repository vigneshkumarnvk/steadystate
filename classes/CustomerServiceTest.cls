/*************************************************************************************************
* Name         :  CustomerServiceTest
* Description  :  Test class for CustomerService
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Sanjana Ravichandran     02-07-2025             US140550: Salesforce: Create New Customer in SF from EQAI
* Sanjana Ravichandran     02-18-2025 			  US140555: Salesforce: Process update to Customer record received from EQAI
***********************************************************************************************************/
@isTest
private class CustomerServiceTest {
    @testSetup
    static void setupTestData() {
        Subsidiary_Company__c subsidiary = new Subsidiary_Company__c(Name = '1-REPUBLIC SERVICES');
        insert subsidiary;

        Payment_Term__c paymentTerm = new Payment_Term__c(EQAI_Terms_Code__c = 'NET30');
        insert paymentTerm;

        Salesperson__c salesperson = new Salesperson__c(
            Territory_Code__c = 'TX01', 
            Salesperson_Code__c = 'SP01', 
            Status__c = 'Active' 
        );
        insert salesperson;

        Account existingAccount = new Account(
            Name = 'Test Customer',
            Sage_Customer_No__c = 'D365-001',
            EQAI_Customer_ID__c = 'EQAI-123',
            Subsidiary_Company__c = subsidiary.Id
        );
        insert existingAccount;
    }

    @isTest
    static void testCreateOrUpdateCustomers() {
        Test.startTest();

        String jsonRequest = '[{"cust_name":"New Customer","Salesforce_Account_CSID":"","customer_ID":"EQAI-456","ax_customer_id":"D365-002","cust_website":"www.newcustomer.com","cust_phone":"1234567890","cust_fax":"0987654321","bill_to_addr1":"123 Billing St","bill_to_city":"Dallas","bill_to_state":"TX","bill_to_zip_code":"75001","bill_to_country":"USA","cust_addr1":"456 Shipping St","cust_city":"Houston","cust_state":"TX","cust_zip_code":"77001","cust_country":"USA","terms_code":"NET30","CustomerBilling":[{"territory_code":"TX01","PO_required_flag":"T"}]}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonRequest);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/CustomerService/';

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        CustomerService.createOrUpdateCustomers();

        Test.stopTest();

        Account newAccount = [SELECT Name, Sage_Customer_No__c, EQAI_Customer_ID__c, Payment_Term__c FROM Account WHERE EQAI_Customer_ID__c = 'EQAI-456' LIMIT 1];
        System.assertEquals('NEW CUSTOMER', newAccount.Name);
        System.assertEquals('D365-002', newAccount.Sage_Customer_No__c);
        System.assertNotEquals(null, newAccount.Payment_Term__c);
    }

    @isTest
    static void testUpdateExistingCustomer() {
        Test.startTest();

        String jsonRequest = '[{"cust_name":"Updated Customer","customer_ID":"EQAI-123","ax_customer_id":"D365-001","bill_to_city":"Austin","cust_city":"San Antonio"}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonRequest);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/CustomerService/';

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        CustomerService.createOrUpdateCustomers();

        Test.stopTest();

        Account updatedAccount = [SELECT Name, BillingCity, ShippingCity FROM Account WHERE EQAI_Customer_ID__c = 'EQAI-123' LIMIT 1];
        System.assertEquals('TEST CUSTOMER', updatedAccount.Name);
    }

    @isTest
    static void testErrorHandling() {
        Test.startTest();

        String jsonRequest = '[{"cust_name": "Invalid Customer"}]';

        RestRequest req = new RestRequest();
        req.requestBody = Blob.valueOf(jsonRequest);
        req.httpMethod = 'PUT';
        req.requestURI = '/services/apexrest/CustomerService/';

        RestResponse res = new RestResponse();
        RestContext.request = req;
        RestContext.response = res;

        try {
            CustomerService.createOrUpdateCustomers();
            System.assert(true);
        } catch (Exception ex) {
            System.assert(false, 'Method should handle errors gracefully.');
        }

        Test.stopTest();
    }
}