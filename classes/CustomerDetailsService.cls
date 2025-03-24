/*************************************************************************************************
* Name         :  CustomerDetailsService
* Description  :  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             16-05-2024             Task85892: Salesforce - Logic for MSG, Retail, National Accounts, US Ecology Internal Account.
* Prabhu Rathakrishnan     10-22-2024             US126260   Salesforce - Reflect NA/MSG/Retail and Prevent BP flag in Salesforce account
* Prabhu Rathakrishnan     11-25-2024             US131817 Salesforce - Only consider "Prevent Billing Project" for creation of new billing project (remove NA, Retail, MSG, Intercompany considerations)
*************************************************************************************************/
public with sharing class CustomerDetailsService {
    public static EQAIflagStatus getCustomerDetails(String customerId) {
        EQAI_API_URL_Extensions__mdt CustomerDetails = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getCustomerDetails'];
        String endpoint = CustomerDetails.API_Extension__c;
        EQAIflagStatus eqaiflags = new EQAIflagStatus();
        try{
           
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:EQAI_Base_URL'+endpoint+customerId);
            req.setHeader('Content-Type','application/json');
            req.setHeader('x-api-key',CustomerDetails.API_Key__c);
            req.setHeader('x-secret-token',CustomerDetails.API_Token__c);
            req.setMethod('GET');
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String response = res.getBody();
            System.debug('RESPONSE::'+res.getBody()); 
            if (res.getStatusCode() == 200 && res.getBody() != '[]') {
                List<Object> jsonResponse1 = (List<Object>) JSON.deserializeUntyped(res.getBody());
                Map<String, Object> objMap = (Map<String, Object>)jsonResponse1[0];
                System.debug(':Response_Map:: ' + objMap);
                if(objMap.get('msg_customer_flag') == 'T' || objMap.get('retail_customer_flag') == 'T' || objMap.get('national_account_flag') == 'T' || objMap.get('eq_flag') == 'T'){
                    if(objMap.get('msg_customer_flag') == 'T')
                    {
                        eqaiflags.msg = 'T';
                    }
                    else{
                        eqaiflags.msg = 'F';
                    }
                    if(objMap.get('retail_customer_flag') == 'T')
                    {
                        eqaiflags.retail = 'T';
                    }
                    else{
                        eqaiflags.retail = 'F';
                    }
                    if(objMap.get('national_account_flag') == 'T')
                    {
                        eqaiflags.nationalAccount = 'T';
                    }
                    else{
                        eqaiflags.nationalAccount = 'F';
                    }
                    if(objMap.get('eq_flag') == 'T')
                    {
                        eqaiflags.eq_flag = 'T';
                    }
                    else{
                        eqaiflags.eq_flag = 'F';
                    }
                    eqaiflags.customerFlag = 'T';
                } 
                else
                {
                    eqaiflags.customerFlag = 'F';
                }
                if(objMap.get('sfdc_billing_package_flag')=='T')
                {
                    eqaiflags.preventBPFlag = 'T';
                }
                else{
                    eqaiflags.preventBPFlag = 'F';
                } 
            } 
            else {
                eqaiflags.customerFlag = 'F';
                eqaiflags.preventBPFlag = 'F';
            }
        }
        catch(Exception e){
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            //return e.getMessage();
        } 
        return eqaiflags;
    }
   public class EQAIflagStatus
    {
         public String customerFlag;
         public String msg;
         public String retail;
         public String nationalAccount;
         public String preventBPFlag;
		 public String eq_flag;        
    }
    
}