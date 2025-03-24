/*
* Class Name: BillingProjectLookupController
* Created By  : Prabhu Rathakrishnan
*
* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Prabhu Rathakrishnan        09/09/2024              US121824: Salesforce - Billing Project lookup on Sales Order
*************************************************************************************************************/
@isTest
public class BillingProjectLookupControllerTest {

    @IsTest
    private static void ctor() {
        Test.startTest();
        BillingProjectLookupController bpLookupController = new BillingProjectLookupController();
        Test.stopTest();

        System.assert(bpLookupController != null, 'Expected the class to be initialized.');
    }

    @IsTest
    private static void getBillingProjectLookup() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new EQAIGetBillingProjectInfoHttpMockResponse());
        BillingProjectLookupController.Model resModel = BillingProjectLookupController.getBillingPackageLookup('C318554', '04');
        Test.stopTest();

    }

    public class EQAIGetBillingProjectInfoHttpMockResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            System.assertEquals('GET', req.getMethod());
            res.setBody('[{\"Billing Project ID\":12345,\"Billing Project Name\":\"Standard Customer Billing\",\"Fee\":\"EIR\",\"Status\":\"Apply\",\"Purchase Order\":\"IAT200011187\",\"Release\":\"Test Release\",\"PO Description\":\"IAT200011187\",\"PO Amount\":null,\"Start Date\":null,\"Expiration Date\":null,\"ES Territory\":\"212\",\"ES AE\":\"Kami Label\",\"FIS Territory\":\"212\",\"FIS AE\":\"212\",\"Distribution Method\":\"M\",\"Contact Name\":\"Elizabeth Hellige\",\"Contact E-mail\":\"abc@abc.com\",\"Fee Type\":\"C\",\"E-manifest Fee\":0,\"Link Reqd\":\"No\"}]');
            res.setStatusCode(200);
            return res;
       }
   }
}