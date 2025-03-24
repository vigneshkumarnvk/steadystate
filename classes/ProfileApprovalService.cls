/*************************************************************************************************
* Name         :  ProfileApprovalService
* Description  :  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             15-08-2024             US117942:  Add a Waste profile approval lookup in Salesforce T&M
*************************************************************************************************/
public class ProfileApprovalService {
    Public static httpResponse approvalJsonfromEQAI(String tmId,String description,string facilityId,string genId, String scId){
        map<String,String> company_Id_EQIMap = new map<String,String>();
        map<String,String> profit_Ctr_Id_EQIMap = new map<String,String>();
        try
        {
            for(Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord :[select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,EQAI_Table_Name__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c from Sales_Order_EQAI_Mapping__mdt]){
                if(salesOrderEQIMappingRecord.EQAI_Field_Name__c =='company_id'){
                    company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
                else if(salesOrderEQIMappingRecord.EQAI_Field_Name__c=='profit_ctr_id'){
                    profit_Ctr_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
            }
            HTTPResponse res = new HttpResponse();
            List<Facility__c> facility = [SELECT Id,TSDF_Code__c FROM Facility__c WHERE id=:facilityId LIMIT 1];
            String tsdfCode= (facility.size()>0 && String.isNotBlank(facility[0].TSDF_Code__c)) ? facility[0].TSDF_Code__c : '';
            System.debug('tmId++++++++++'+tmId);
            System.debug('genId++++++++++'+genId);
            System.debug('scId++++++++++'+scId);
            Integer companyId;
            Integer profitCenId;
            String gneratorId;            
            Boolean tmFlag = false;
            
            if(tmId != null)
            {
                if(tmId.startsWith('a1X'))
                {
                    tmflag = true;
                }
            }
            
                if(tmflag)
                {
                    TM__c tm = [Select Id,Sales_Order__r.Alternate_Site_Address__r.Id,
                                     Sales_Order__r.EqaiGeneratorId__c,
                                     Sales_Order__r.Bill_to_Customer_No__r.Sage_Customer_No__c,
                                     Sales_Order__r.Service_Center__r.Name
                                     FROM TM__c where Id=:tmId limit 1];
                    if(tm.Sales_Order__r.Service_Center__r.Name != null && company_Id_EQIMap !=null && company_Id_EQIMap.containskey(tm.Sales_Order__r.Service_Center__r.Name)) 
                        companyId = Integer.valueOf(company_Id_EQIMap.get(tm.Sales_Order__r.Service_Center__r.Name));
                    if(tm.Sales_Order__r.Service_Center__r.Name != null && profit_Ctr_Id_EQIMap !=null && profit_Ctr_Id_EQIMap.containskey(tm.Sales_Order__r.Service_Center__r.Name)) 
                        profitCenId = Integer.valueOf(profit_Ctr_Id_EQIMap.get(tm.Sales_Order__r.Service_Center__r.Name)); 
                     gneratorId = String.ValueOf(tm.Sales_Order__r.EqaiGeneratorId__c) != null ? String.ValueOf(tm.Sales_Order__r.EqaiGeneratorId__c) : '';
                     res = getApprovedProfiles(tm,null,companyId,profitCenId,description,tsdfCode,gneratorId);
                }
                else
                {
                   List<Sales_Order__c> salesOrder = [SELECT Id,Alternate_Site_Address__r.Id,
                                              EqaiGeneratorId__c,
                                 			  Bill_to_Customer_No__r.Sage_Customer_No__c,
                                   			  Service_Center__r.Name
                                 			  FROM Sales_Order__c WHERE Id=:tmId limit 1];
                   Service_Center__c sc = [SELECT Name FROM Service_Center__c WHERE Id = :scId];
                   if(company_Id_EQIMap.containskey(sc.Name)) 
                        companyId = Integer.valueOf(company_Id_EQIMap.get(sc.Name));
                  if( profit_Ctr_Id_EQIMap.containskey(sc.Name)) 
                        profitCenId = Integer.valueOf(profit_Ctr_Id_EQIMap.get(sc.Name));
                  gneratorId = genId;
                 
                  res = getApprovedProfiles(null,salesOrder,companyId,profitCenId,description,tsdfCode,gneratorId);  
               }
          
           return res;
        } catch (Exception e) {
            System.debug('Error in sendContactToEQAI: ' + e.getMessage());
            System.debug('line::'+e.getLineNumber());
            return null; 
        }
    }
    Public static httpResponse getApprovedProfiles(TM__c tmRecord ,List<Sales_Order__c> salesOrderList, Integer companyId, Integer prId,String description,String tsdfCode, String genId){
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        logData.className = 'ProfileApprovalService';
        logData.methodName = 'getApprovedProfiles'; 
        Integer company_id;
        Integer profit_ctr_id;
        String GeneratorId; 
        String SalesforceSiteCsid;
        String D365CustomerId; 
        
        company_id = companyId;
        profit_ctr_id = prId;
        GeneratorId= genId;
        
        try
        {
           
            EQAI_API_URL_Extensions__mdt CustomerDetails = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='GetProfileApprovalDetails'];
            String endpoint = CustomerDetails.API_Extension__c;
           	if(tmRecord!=null)
            {
               D365CustomerId = tmRecord.Sales_Order__r.Bill_to_Customer_No__r.Sage_Customer_No__c != null ? tmRecord.Sales_Order__r.Bill_to_Customer_No__r.Sage_Customer_No__c : null;
               SalesforceSiteCsid = (tmRecord.Sales_Order__r.Alternate_Site_Address__r.Id != null ? tmRecord.Sales_Order__r.Alternate_Site_Address__r.Id : null);

            }
            else if(!salesOrderList.isEmpty())
            {
               Sales_Order__c salesOrderRecord = salesOrderList[0];
               SalesforceSiteCsid = (salesOrderRecord.Alternate_Site_Address__r.Id != null ? salesOrderRecord.Alternate_Site_Address__r.Id : null);
           	   D365CustomerId =  salesOrderRecord.Bill_to_Customer_No__r.Sage_Customer_No__c != null ? salesOrderRecord.Bill_to_Customer_No__r.Sage_Customer_No__c : null;
            }
                
            //company_id = 21;
            //profit_ctr_id = 0;
           // D365CustomerId = 'C322006';
            endpoint += 'TsdfCode=' + EncodingUtil.urlEncode(tsdfCode, 'UTF-8');
            endpoint += '&SalesforceSiteCsid=' + SalesforceSiteCsid;
            endpoint += '&D365CustomerId=' + D365CustomerId;
            endpoint += '&CompanyId=' + company_id;
            endpoint += '&ProfitCenterId=' + profit_ctr_id;
            endpoint += '&Description=' + (description != null ? description : '');
            endpoint += '&GeneratorId=' + GeneratorId;
            system.debug('callout:EQAI_Base_URL'+endpoint);
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:EQAI_Base_URL'+endpoint);
            req.setHeader('Content-Type','application/json');
            req.setHeader('x-api-key',CustomerDetails.API_Key__c);
            req.setHeader('x-secret-token',CustomerDetails.API_Token__c);
            req.setMethod('GET');
            req.setTimeout(20000);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String response = res.getBody();
            logData.serviceRequest = 'ProfileApprovalReq>>' + 'callout:EQAI_Base_URL'+endpoint;
            logData.serviceResponse = 'ProfileApprovalRes>>' + res.getBody();
            ApplicationLog.startLog(JSON.serialize(logData));
            if (res.getStatusCode() == 200) {
                return res;
            } else {
                System.debug('Error in API response: ' + res.getStatusCode() + ' - ' + res.getBody());
                return res;
            }
            
        } catch (Exception e) {
            System.debug('Error in getApprovedProfiles: ' + e.getMessage());
            return null;
        }
    }
}