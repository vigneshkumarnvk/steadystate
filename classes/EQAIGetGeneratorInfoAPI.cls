/*
Dated    : 07/31/2023
Summary  : Apex class for EQAI callouts
* Modification Log :
 * Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Harika Madapathi           07/31/2023              67233 - Building GetGeneratorInfo API Callout
Avinash Panda              09/11/2023              US95612 - Add Street Address to ES Generator Look Up Button on Quote/Order
Pavithra P				   08-05-2024			   US118581 - Salesforce - Add integration log 
Sanjana R				   01/21/2025			   US138841: SF - Add Site Location to Generator Lookup
*************************************************************************************************************/
public class EQAIGetGeneratorInfoAPI extends EQAIWrapper{
     
     public static ResponseWrapper getMatchingSitesFromEQAI(String epaId, String generatorName,String generatorAddress, String generatorCity, String generatorZipCode, String generatorState){
         
            ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        	logData.className = 'EQAIGetGeneratorInfoAPI';
        	logData.methodName = 'getMatchingSitesFromEQAI'; 
           // string getGeneratorInfoEndPoint = EQAI_API_URL_Extensions__mdt.getInstance('GetGeneratorInfo').API_Extension__c;
           // ticket 80209
            EQAI_API_URL_Extensions__mdt getGeneratorInfo = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='GetGeneratorInfo'];
         
            string requestBody = getRequestBody(epaId,generatorName, generatorAddress,generatorCity,generatorZipCode,generatorState);
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:EQAI_Base_URL'+getGeneratorInfo.API_Extension__c);
            req.setHeader('x-api-key',getGeneratorInfo.API_Key__c);
            req.setHeader('x-secret-token',getGeneratorInfo.API_Token__c);
            req.setHeader('Content-Type','application/json');
            req.setMethod('POST');
            req.setBody(requestBody);
         	req.setTimeOut(20000);
            Http http = new Http();
            System.debug('Request: '+req.getEndpoint());
            HTTPResponse res = http.send(req);
            String response = res.getBody();
            System.debug('Response: '+ response);
           
            
         	ResponseWrapper resWrapper = new ResponseWrapper();
            //Handling successful API callout and parsing the JSON returned
             if(res.getStatusCode() == 200){
                
                 List<GetGeneratorInfoResponseWrapper> siteList = new List<GetGeneratorInfoResponseWrapper>();
                 if(response.contains('"EPA ID":') || response.contains('"Business Phone":') || response.contains('"Street Address":') || (response.contains('"NAICS ID":')) || (response.contains('"EQAI generator ID":')) || response.contains('"Site Location":') || response.contains('"Site Country"') ){
                    while (response.contains('"EPA ID"')) {
                        response = response.replace('"EPA ID":', '"EPA_ID":');
                    }
                    while (response.contains('"Street Address"')) {
                        response = response.replace('"Street Address":', '"Street_Address":');
                    }
                    while (response.contains('"Business Phone"')) {
                        response = response.replace('"Business Phone":', '"Business_Phone":');
                    }
                    while (response.contains('"NAICS ID"')) {
                        response = response.replace('"NAICS ID":', '"NAICS_ID":');
                    }
                    while (response.contains('"EQAI generator ID"')) {
                        response = response.replace('"EQAI generator ID":', '"EQAI_generator_ID":');
                    }
                     //US138841
                     while (response.contains('"Site Location"')){
                         response = response.replace('"Site Location":', '"Site_Location":'); 
                     }
                     while(response.contains('"Site Country"')){
                         response = response.replace('"Site Country":', '"generator_country":'); 
                     }
        		}
                //When matching sites are found or matching site List is empty
                List<GetGeneratorInfoResponseWrapper> matchingSiteWrapperList = (List<GetGeneratorInfoResponseWrapper>)System.JSON.deserialize(response,List<GetGeneratorInfoResponseWrapper>.class);
                resWrapper.siteList = matchingSiteWrapperList;
                resWrapper.Error = null;
                for(Integer i = 0 ; i<matchingSiteWrapperList.size() ; i++){
                     System.debug('Site:'+i+''+matchingSiteWrapperList[i]);
                }
             }
            
            //When Invalid EPA ID is sent in the request and an error is thrown
            else if(res.getStatusCode() == 400){
                  resWrapper.siteList = null;
                  resWrapper.Error = res.getBody();
                  System.debug('errorWrapper:'+ resWrapper.Error);
            }
         logData.serviceRequest = 'GeneratorLookupReq>>' + requestBody;
         logData.serviceResponse = 'GeneratorLookupRes>>' + response;
         ApplicationLog.startLog(JSON.serialize(logData));
            return resWrapper;
         
     }
    
    
    
    //Method to build Request Body
    public static String getRequestBody(String epaId, String generatorName,String generatorAddress, String generatorCity, String generatorZipCode,String generatorState){
        String body;
        GetGeneratorInfoRequestWrapper requestWrapper = new GetGeneratorInfoRequestWrapper();
        requestWrapper.epa_id = epaId;
        requestWrapper.generator_name = generatorName;
        requestWrapper.generator_address_1 = generatorAddress;
        requestWrapper.generator_city = generatorCity;
        requestWrapper.generator_state = generatorState;
        requestWrapper.generator_zip_code  = generatorZipCode;
        body = JSON.serialize(requestWrapper);
        System.debug('body: '+ body);
        return body;
    } 
    
}