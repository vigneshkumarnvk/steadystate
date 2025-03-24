/*
* Class Name:MockHttpBillingJobResponseGenerator
* Created By  : Shahwaz Khan 

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Shahwaz Khan                09/04/2024             Mock class for SFJobBillingProjectService
*************************************************************************************************************/
@isTest
global class MockHttpBillingJobResponseGenerator implements HttpCalloutMock 
{
    global HTTPResponse respond(HTTPRequest req) 
    {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":400,"details":[{"isSuccess":false,"statusMessage":"Error: Integration failed due to the following reason;D365customer id:00-0235986 not exist in EQAI customer table or not an active status;already exists in EQAI CustomerBilling table","breakCode1":null,"breakCode2":null,"breakCode3":null,"d365CustomerId":"00-0235986","invoicePackageContent":null,"mailToBillToAddressFlag":null,"poRequiredFlag":null,"termsCode":null,"distributionMethod":null,"dateAdded":"2024-04-12T18:45:05Z","dateModified":"2024-04-12T18:54:32Z","eManifestFlag":null,"recordType":null,"employeeId":"100027997","salesforceJobBillingProjectCsid":"a0uW400000054ivIAA","salesforceSalesOrderCloseDate":"2024-04-23T00:00:00Z","reopenFlag":null}]}');
        res.setStatusCode(400);
        return res;
    }
}