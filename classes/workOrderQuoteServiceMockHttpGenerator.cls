/*************************************************************************************************
* Name         :  workOrderQuoteServiceMockHttpGenerator
* Description  :  Apex Class for MOCK API call out of the work order Quote Service
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Praneeth Yalamati         08-17-2023             US94501: Create Work Order in EQAI when Convert Quote to Order button is pressed

*************************************************************************************************/
@isTest
    global class workOrderQuoteServiceMockHttpGenerator implements HttpCalloutMock {
        
        global HTTPResponse respond(HTTPRequest req){
            try{
           
            HttpResponse res= new HttpResponse();
            res.setHeader('Content-Type','application/json');            
            res.setHeader('x-api-key','Key');
            res.setHeader('x-secret-token','Token');
            res.setBody('Integration Successful');
            res.setStatusCode(200);
            res.setStatus('OK');            
            return res;
            
        }catch(Exception ex){
                System.debug('ERROR Message>>>'+ex.getMessage()+' Error Line Number>>> '+ex.getLineNumber());
        }
            return null;
         }
    }