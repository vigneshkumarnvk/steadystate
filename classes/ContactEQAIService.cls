/*************************************************************************************************
* Name         :  ContactEQAIService 
* Description  :  Apex Class for API call out of the work order Quote Service
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vennila Paramasivam		07/08/2024				Whenever a Contact insert/update it will sync to EQAI
* Shahwaz Khan              16/12/2024              Salesforce - Incl. web_access_flag field in contact sync integration (SF -> EQAI).
****************************************************************************************************************************************/
public class ContactEQAIService {
    
    @future(callout=true)
    Public static void sendContacttoEQAI(Id conId, String event)
    {
        ContactEQAIServiceJson.countryCodeMap = new Map<String,string>();
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
		logData.className = 'ContactEQAIService';
		logData.methodName = 'sendContacttoEQAI';
        logData.recordId = conId;

        Contact contactRec = [SELECT Id, Name,account.accountNumber, account.Name, FirstName,LastName, Email, Phone, MobilePhone,
                              Contact_Type__c, Title, MailingStreet, MailingCity, MailingState,MailingStateCode, Fax, Salutation, MiddleName, Suffix,
                              account.Sage_Customer_No__c,
                              MailingPostalCode,MailingCountry,MailingCountryCode,
                              Contact_Sync_d_with_EQAI__c,Blocked__c,EQAI_Contact_Id__c,COR2_Portal_Contact__c
                              FROM Contact WHERE Id =: conId and RecordType.Developername = 'Contacts'];
                            
        if(contactRec.MailingCountry != null){            
            Sales_Order_EQAI_Mapping__mdt[] salesOrderEQIMappingRecord = [SELECT Id,EQAI_Field_Name__c,EQAI_Field_Value__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c FROM Sales_Order_EQAI_Mapping__mdt WHERE EQAI_Field_Name__c = 'Country_Code' AND Salesforce_Field_Value__c =: contactRec.MailingCountry.toUpperCase()]; 
            if(salesOrderEQIMappingRecord.size()>0){
                
                ContactEQAIServiceJson.countryCodeMap.put(contactRec.MailingCountry,salesOrderEQIMappingRecord[0].EQAI_Field_Value__c);
                
            }
            
            
        }
        
        
        //Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord = [SELECT Id,EQAI_Field_Name__c,EQAI_Field_Value__c,,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c FROM Sales_Order_EQAI_Mapping__mdt WHERE EQAI_Field_Name__c = 'Country_Code' AND 
        User currUser = [SELECT Id, RSG_EIN__c FROM USER WHERE Id =:userinfo.getUserId()];
        try
        {
            if(contactRec != Null)
           	{
               String metadataName;
               String methodType;
               if(event == 'Insert')
               {
                   metadataName = 'getContactInsert'; 
                   methodType = 'POST';
               }
               else
               {
                   metadataName = 'getContactUpdate';  
                   methodType = 'PUT';
               }
                 
              
               EQAI_API_URL_Extensions__mdt contactAPIs = [SELECT API_Extension__c, API_Key__c, API_Token__c, DeveloperName 
                                                           FROM EQAI_API_URL_Extensions__mdt 
                                                           WHERE DeveloperName=:metadataName];
               JSONGenerator jsonGen = JSON.createGenerator(true); 
               ContactEQAIServiceJson contactJSON = new ContactEQAIServiceJson(contactRec,currUser.RSG_EIN__c,event);
               System.debug('body: '+ System.Json.serialize(contactJSON));
               String contactResponse = workOrderQuoteService.getPostCalloutResponseContents(contactAPIs.API_Extension__c, System.Json.serialize(contactJSON),methodType,contactAPIs.API_Key__c,contactAPIs.API_Token__c);
               System.debug('contactResponse+++++++++++'+contactResponse);
               logData.serviceRequest = 'contactRequest>>'+System.Json.serialize(contactJSON);
			   logData.serviceResponse = 'contactResponse>>'+contactResponse;
               if(contactResponse.contains('Integration Successful') || contactResponse == '200')
               {
                   ContactEQAIServiceJson.isSkipValidation = true;
                   String contactId;
                   if(contactResponse.contains('Contact Id'))
                   {
                        contactId = contactResponse.remove('Integration Successful;Contact Id:');
                        contactRec.Eqai_Contact_Id__c = contactId;
                   }
                   contactRec.Contact_Sync_d_with_EQAI__c = true;                   
                   update contactRec;
               }
               else
               {
                  workOrderQuoteService.createCaseWithParentId(conId,'Error in Contact Insert',workOrderQuoteService.splitSuccessMessage(contactResponse),Json.serialize(contactJSON));  
               }
       		}
            ApplicationLog.startLog(JSON.serialize(logData));
        }
        Catch(Exception e)
        {  
            logData.message = e.getMessage();
			ApplicationLog.startLog(JSON.serialize(logData));
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            workOrderQuoteService.createCaseWithParentId(conId,'Error in apex class','Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause(),null); 
        }
    }
}