/*
* Class Name:BillingPkgSingleJSONMockResponse
* Created By  :  

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
* Pavithra Periyasamy      11/25/2024             Mock class for SingleJSON during Send EQAI Billing Package
*************************************************************************************************************/
@isTest
global class BillingPkgSingleJSONMockResponse implements HttpCalloutMock 
{
    global HTTPResponse respond(HTTPRequest req) 
    {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"status":200,"details":[{"isSuccess":true,"statusMessage":"WorkOrderHeader Integration Successful (so CSID updated with actual invoice CSID)"}]}');
        res.setStatusCode(200);
        return res;
    }
}