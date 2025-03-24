/*************************************************************************************************
* Name         :  ResourcesService
* Description  :  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Pavithra Periyasamy		03/20/2025             US144300: Resource Sync : Salesforce : Labor : New/Termed Labor Resources sync from EQAI to Salesforce
***********************************************************************************************************/

@RestResource(urlMapping='/ResourceService/*')
global with sharing class ResourcesService {
    @HttpPut
    global static void upsertResources() {
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        logData.className = 'ResourcesService';
        logData.methodName = 'upsertResources'; 
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        List<Resource__c> recordsToUpsert = new List<Resource__c>(); 
        List<String> responseList = new List<String>();
        Boolean hasErrors = false;
        Map<String, Resource_Type__c> resourceTypeRecords = new Map<String,Resource_Type__c>();
        Map<String,String> serviceCenterMap = new Map<String,String>();
        Map<String,String> companyIdMap = new Map<String,String>();
        Map<String,String> profitCenterIdMap = new Map<String,String>();
        Set<String> serviceCenterNames = new Set<String>();
        Map<String,Id> serviceCenterIdMap = new Map<String,Id>();
        Set<String> resourceId = new Set<String>();
        Map<Id,Resource__c> existingResources = new Map<Id,Resource__c>();
        Set<String> rsgEmpNumberSet = new Set<String>();
        Set<String> userRsgEmpSet = new Set<String>();
        Map<String,User> userRecordMap = new Map<String,User>();
        
        // Custom metadata for company_Id and Profit_Center_Id
        Sales_Order_EQAI_Mapping__mdt[] salesOrderEQIMappingRecords = [
            SELECT EQAI_Field_Value__c, Salesforce_Field_Value__c, EQAI_Field_Name__c 
            FROM Sales_Order_EQAI_Mapping__mdt 
            WHERE EQAI_Field_Name__c ='company_id' OR EQAI_Field_Name__c = 'profit_ctr_id' ];
        for (Sales_Order_EQAI_Mapping__mdt record : salesOrderEQIMappingRecords) {
            if(record.EQAI_Field_Name__c =='company_id'){
                companyIdMap.put(record.Salesforce_Field_Value__c, record.EQAI_Field_Value__c);
            }else if(record.EQAI_Field_Name__c == 'profit_ctr_id'){
                profitCenterIdMap.put(record.Salesforce_Field_Value__c,record.EQAI_Field_Value__c);
            }
            
        }
        if(companyIdMap != null){
            for(String serviceCenterkey : companyIdMap.KeySet()){
                String companyId = companyIdMap.get(serviceCenterkey);
                String profitCenterId = profitCenterIdMap.get(serviceCenterkey);
                serviceCenterMap.put(companyId+'_'+profitCenterId,serviceCenterkey);
            }
        }
        //Getting all Service centers to Map to resource.Service_Center__c based on company_Id and default_profit_center_id
        ServiceCentersSelector selector = new ServiceCentersSelector();
        List<Service_Center__c> serviceCenterList = selector.selectAll();
        for(Service_Center__c sc : serviceCenterList){
            serviceCenterIdMap.put(sc.Name,sc.Id);
        }
        
        try {
            
            String jsonString = req.requestBody.toString();
            logData.serviceRequest = 'ResourcesService>>'+jsonString;
            ResourceRequest requestBody = (ResourceRequest) JSON.deserialize(jsonString, ResourceRequest.class);
            List<ResourceRequest.ResourceInfo> resourceInfoList = requestBody.resources;
            
            //Getting all Resource_Type to Map to resource.Resource_Type based on Resource_Class
            for(Resource_Type__c record : [SELECT Id,Name,Resource_Class_Code__c FROM Resource_Type__c Order By CreatedDate]){
                if(!resourceTypeRecords.containsKey(record.Resource_Class_Code__c)){
                    resourceTypeRecords.put(record.Resource_Class_Code__c,record);
                }
            }
            for (ResourceRequest.ResourceInfo resourceInfo : resourceInfoList) {               
                if(resourceInfo.Resource_CSID != null && resourceInfo.Resource_CSID != '')
                    resourceId.add(resourceInfo.Resource_CSID);
                if(resourceInfo.employee_Id != null){
                    userRsgEmpSet.add(resourceInfo.employee_Id);
                }
            }
            
            if(!resourceId.isEmpty()){
                for(Resource__c resource : [SELECT Id,Name FROM Resource__c WHERE Id IN: resourceId]){
                    existingResources.put(resource.Id,resource);
                }
            }
            if(!userRsgEmpSet.isEmpty()){
                for(User userRecord : [SELECT Id,Name,RSG_EIN__c FROM User WHERE RSG_EIN__c IN: userRsgEmpSet]){
                    if(!userRecordMap.containsKey(userRecord.RSG_EIN__c)){
                        userRecordMap.put(userRecord.RSG_EIN__c,userRecord);
                    }
                }
            }
            
            for (ResourceRequest.ResourceInfo resourceInfo : resourceInfoList) {
                Resource__c resource;
                if(resourceInfo.Resource_CSID != null && !existingResources.isEmpty() && existingResources.containsKey(resourceInfo.Resource_CSID)){
                    resource = existingResources.get(resourceInfo.Resource_CSID);
                }else{
                    resource = new Resource__c();
                }
                
                resource.Category__c = resourceInfo.resource_type;
                resource.First_Name__c = resourceInfo.First_Name;
                resource.Last_Name__c = resourceInfo.Last_Name;
                resource.Name = resourceInfo.employee_ID;
                if(resourceTypeRecords !=null && resourceTypeRecords.containsKey(resourceInfo.Resource_Class)){
                    resource.Resource_Type__c =  resourceTypeRecords.get(resourceInfo.Resource_Class).Id;
                    resource.Resource_Class_Code__c = resourceTypeRecords.get(resourceInfo.Resource_Class).Resource_Class_Code__c;
                }
                if(serviceCenterMap != null && serviceCenterMap.containsKey(resourceInfo.company_id+'_'+resourceInfo.default_profit_ctr_id)){
                    String sckey = serviceCenterMap.get(resourceInfo.company_id+'_'+resourceInfo.default_profit_ctr_id);
                    resource.Service_Center__c = serviceCenterIdMap != null && serviceCenterIdMap.containsKey(sckey) ? serviceCenterIdMap.get(sckey) : null;
                }
                resource.Description__c = resourceInfo.employee_ID;
                resource.Status__c = resourceInfo.resource_status;
                resource.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get(resource.Category__c).getRecordTypeId();
                resource.user__c = userRecordMap.containsKey(resourceInfo.employee_ID) ? userRecordMap.get(resourceInfo.employee_ID).Id : null;
                
                
                //resource.First_Name__c = resourceInfo.First_Name;
                //resource.First_Name__c = resourceInfo.First_Name;
                recordsToUpsert.add(resource);
                
            }
            
            Database.UpsertResult[] results = Database.upsert(recordsToUpsert, false);
            for (Integer i = 0; i < results.size(); i++) {
                Database.UpsertResult result = results[i];
                String response;
                if (result.isSuccess()) {
                    res.statusCode = 200;
                    response = '{"isSuccess":true,"statusMessage":"' + (result.isCreated() ? 'Resource created successfully' : 'Resource updated successfully') + '","Resource_CSID":"' + recordsToUpsert[i].Id + '}';
                    if(recordsToUpsert[i].Status__c == 'Inactive'){
                        rsgEmpNumberSet.add(recordsToUpsert[i].Name);
                    }
                    responseList.add(response);
                } else {
                    hasErrors = true;
                    res.statusCode = 400;
                    response = '{"isSuccess":false,"statusMessage":"' + result.getErrors()[0].getMessage() + '","Resource_CSID":"' + recordsToUpsert[i].Id + '}';
                    responseList.add(response);
                }
            }
            if(!rsgEmpNumberSet.isEmpty()){
                UserController.InactivateUser(rsgEmpNumberSet);
            }
            res.responseBody = Blob.valueOf('[' + String.join(responseList, ',') + ']');
            ApplicationLog.startLog(JSON.serialize(logData));
        }catch (Exception e) {            
            logData.message = e.getMessage();
            ApplicationLog.startLog(JSON.serialize(logData));
            System.debug('Error: ' + e.getMessage());
            System.debug('Error Line ' + e.getLineNumber());
            res.statusCode = 500;
            String errorResponse = '[{"isSuccess":false,"statusMessage":"Error:' + e.getMessage() + '",""}]';
            res.responseBody = Blob.valueOf(errorResponse); 
        } 
    }
}