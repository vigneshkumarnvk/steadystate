/*************************************************************************************************
* Name         :  ManifestService
* Description  :  Sends request to external service and retrieves manifest records
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             12-09-2024             US117942:  Salesforce - Manifest lookup on T&M
*************************************************************************************************/
public class ManifestService {
    public static HTTPResponse sendRequestToEQAI(String tsdfApprovalCode, String tmId) {
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        logData.className = 'ManifestService';
        logData.methodName = 'sendRequestToEQAI'; 
        Map<String, String> company_Id_EQIMap = new Map<String, String>();
        Map<String, String> profit_Ctr_Id_EQIMap = new Map<String, String>();
        try {
            for (Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord : [SELECT Id, EQAI_Field_Name__c, EQAI_Field_Value__c, EQAI_Table_Name__c, Salesforce_Field_API_Name__c, Salesforce_Field_Value__c FROM Sales_Order_EQAI_Mapping__mdt]) {
                if (salesOrderEQIMappingRecord.EQAI_Field_Name__c == 'company_id') {
                    company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c, salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                } else if (salesOrderEQIMappingRecord.EQAI_Field_Name__c == 'profit_ctr_id') {
                    profit_Ctr_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c, salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
            }
            
            TM__c tm = [SELECT Id, Sales_Order__r.Service_Center__r.Name,Sales_Order__r.Name FROM TM__c WHERE Id = :tmId LIMIT 1];

            Integer company_id;
            Integer profit_ctr_id;
            if (tm.Sales_Order__r.Service_Center__r.Name != null) {
                company_id = Integer.valueOf(company_Id_EQIMap.get(tm.Sales_Order__r.Service_Center__r.Name));
                profit_ctr_id = Integer.valueOf(profit_Ctr_Id_EQIMap.get(tm.Sales_Order__r.Service_Center__r.Name));
            }

            EQAI_API_URL_Extensions__mdt apiDetails = [SELECT API_Extension__c, API_Key__c, API_Token__c FROM EQAI_API_URL_Extensions__mdt WHERE DeveloperName = 'GetManifestDetails' LIMIT 1];
            String endpoint = apiDetails.API_Extension__c;
            endpoint += 'TsdfApprovalCode=' + EncodingUtil.urlEncode(tsdfApprovalCode, 'UTF-8');
            endpoint += '&CompanyId=' + company_id;
            endpoint += '&ProfitCenterId=' + profit_ctr_id;
            endpoint += '&QuoteProject='+ EncodingUtil.urlEncode(tm.Sales_Order__r.Name, 'UTF-8');

            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:EQAI_Base_URL' + endpoint);
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('x-api-key', apiDetails.API_Key__c);
            req.setHeader('x-secret-token', apiDetails.API_Token__c);
            req.setMethod('GET');
            req.setTimeout(20000);

            Http http = new Http();
            HTTPResponse res = http.send(req);
            logData.serviceRequest = 'ManifestServiceReq>>' + 'callout:EQAI_Base_URL'+endpoint;
            logData.serviceResponse = 'ManifestServiceRes>>' + res.getBody();
            ApplicationLog.startLog(JSON.serialize(logData));

            return res;

        } catch (Exception e) {
            System.debug('Error in sendRequestToEQAI: ' + e.getMessage());
            System.debug('line::'+e.getLineNumber());
            return null;
        }
    }
}