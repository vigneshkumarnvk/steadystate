@isTest
public class CustomerDetailsServiceTest {
    @IsTest
    private static void TestCustomer(){
        //test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpBillingJobResponseGenerator());
        CustomerDetailsService.getCustomerDetails('C300439');
        Test.stopTest();
    }
    @IsTest
    private static void TestCustomer1(){
        //test
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpBillingJobResponseGenerator2());
        CustomerDetailsService.getCustomerDetails('C300439');
        Test.stopTest();
    }
    
    public class MockHttpBillingJobResponseGenerator2 implements HttpCalloutMock {
         public HTTPResponse respond(HTTPRequest req) 
    {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('[{"status":200,"cust_city":"WESTBOROUGH", "cust_country":"USA", "cust_name":"CUMBERLAND FARMS", "cust_state":"MA", "cust_zip_code":"01581", "customer Address":"165 FLANDERS ROAD", "customer_id":"602245", "eq_flag":"F", "msg_customer_flag":"F", "national_account_flag":"T"}]');
        res.setStatusCode(200);
        return res;
    }
    }
    
}