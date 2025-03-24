/*************************************************************************************************
* Name         :  D365CustomerService
* Description  :  D365 Project Lookup Functionality Service Class 
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             02-14-2025            US141063:  Add D365 Project Lookup Functionality
  Shahwaz Khan             03-06-2025            US142841:  Update D365 Project Lookup(Update Request Endpint)
*************************************************************************************************/
public class D365CustomerService {
    public static HttpResponse fetchCustomerIds(String d365CustomerId,Service_Center__c serviceCenter,String keyword) {
        try {
            ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
            logData.className = 'D365CustomerService';
            logData.methodName = 'fetchCustomerIds'; 
            Integer companyId;
            Integer profitCenId;
            /*Commented as part of US142841*/
            /*map<String,String> company_Id_EQIMap = new map<String,String>();
            map<String,String> profit_Ctr_Id_EQIMap = new map<String,String>();
            for(Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord :[select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,EQAI_Table_Name__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c from Sales_Order_EQAI_Mapping__mdt]){
                if(salesOrderEQIMappingRecord.EQAI_Field_Name__c =='company_id'){
                    company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
                else if(salesOrderEQIMappingRecord.EQAI_Field_Name__c=='profit_ctr_id'){
                    profit_Ctr_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
            }
            if(serviceCenter.Name != null && company_Id_EQIMap !=null && company_Id_EQIMap.containskey(serviceCenter.Name)) 
                companyId = Integer.valueOf(company_Id_EQIMap.get(serviceCenter.Name));
            if(serviceCenter.Name != null && profit_Ctr_Id_EQIMap !=null && profit_Ctr_Id_EQIMap.containskey(serviceCenter.Name)) 
                profitCenId = Integer.valueOf(profit_Ctr_Id_EQIMap.get(serviceCenter.Name));
            */
            EQAI_API_URL_Extensions__mdt CustomerDetails = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='get365CustomerDetails'];
            String endpoint = CustomerDetails.API_Extension__c;
            endpoint += d365CustomerId;
            endpoint += '&D365LegalEntity=' + serviceCenter.D365_LE__c;
            endpoint += '&D365BusinessUnit=' + serviceCenter.D365_Business_Unit__c;
            /*Commented as part of US142841*/
            //endpoint += '&D365ProjectId=' + (keyword != null ? keyword : '');
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:EQAI_Base_URL'+endpoint);
            req.setHeader('Content-Type','application/json');
            req.setHeader('x-api-key',CustomerDetails.API_Key__c);
            req.setHeader('x-secret-token',CustomerDetails.API_Token__c);
            req.setMethod('GET');
            req.setTimeout(120000);
            Http http = new Http();
            HttpResponse res = http.send(req);
            logData.serviceRequest = 'D365CustomerReq>>' + 'callout:EQAI_Base_URL'+endpoint;
            logData.serviceResponse = 'D365CustomerRes>>' + res.getBody();
            ApplicationLog.startLog(JSON.serialize(logData));           
            if (res.getStatusCode() == 200) {
                return res;
            } else {
                System.debug('Error in API response: ' + res.getStatusCode() + ' - ' + res.getBody());
                return res;
            }
        } catch (Exception e) {
            System.debug('Error in Customer D365 API: ' + e.getMessage());
            return null;
        }
    }
}