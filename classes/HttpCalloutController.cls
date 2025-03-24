/*************************************************************************************************************
* Name         :  HttpCalloutController 
* Description  :  Common class to Integration
*
* @author 
* @date 
*
*
* Modification Log :
* Developer                 Date                   Description
* ----------------------------------------------------------------------------                 
* Pavithra Periyasamy		11/07/2024             US129598: [Continued] SF -  Create single JSON object for billing package integration
*************************************************************************************************************/
public class HttpCalloutController {
    
	//callout method - POST / PUT
    public static string getResponse(String APIKey, String endpoint, Integer timeout, String requestBody,String method, String Token){
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();        
        
        try{
            req.setMethod(method);
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');            
            req.setHeader('x-api-key',APIKey);
            req.setHeader('x-secret-token',Token);
            
            String dateTimeStamp = System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX');            
            
            if(String.isNotBlank(requestBody)){
                req.setBody(requestBody);
            }
            
            req.setEndpoint(endpoint);              
            req.setTimeout(timeout);
            
            system.debug('starting call at ' + System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX') + ' Request: ' +  req.getBody());
            system.debug('ending call at ' + System.now().format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX'));
            
            HTTPResponse res = http.send(req);
            String response = res.getBody();
            System.debug('Response: '+ response); 
            return string.valueof(res.getStatusCode()) != '200' ? response : (string.valueof(res.getStatusCode()) == '200') ?string.valueof(res.getStatusCode()) : response ;
            
        }
        catch (Exception e) {
            
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return e.getMessage();
        }
    }
}