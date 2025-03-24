/*************************************************************************************************
* Name         :  WorkOrderAttachmentInfo 
* Description  :  Apex class to query the metadata and pass to LWC
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Sanjana Ravichandran	    01-08-2024           63067: Created a method to query all the necessary data from the metadata
Implemented logic to update the salesInvoice documentType field.
* Vennila Paramasivam		03-22-2024			 Task81412 - Added employee_id
* Sanjana Ravichandran      04-08-2024           Requirement 76997: Salesforce - Create new billing project within EQAI 
from Salesforce "SF Job Billing Project" - send JSON
* Sanjana Ravichandran		04-15-2024			Updated the code for error handling
* Sanjana Ravichandran		04-26-2024			Added new fields in the query to map in the JSON
* Prabhu Rathakrishnan      05-14-2024          Task83367: Salesforce API - Create Fully Transactional Salesforce and EQAI Integration API's
* Sanjana Ravichandran 		05-15-2024 			Added Invoice Backup Document field from customer in the query
*************************************************************************************************/

public with sharing class WorkOrderAttachmentInfo {
    
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getCustomMetadataRecords() {
        List<Map<String, Object>> records = new List<Map<String, Object>>();
        
        List<EQAI_API_URL_Extensions__mdt> metadataRecords = [
            SELECT Id, API_Extension_Name__c, API_Token__c, API_Key__c, API_Extension__c 
            FROM EQAI_API_URL_Extensions__mdt 
            WHERE API_Extension_Name__c = 'GetWorkOrderAttachmentInfo'
        ];
        
        Map<String, String> company_Id_EQIMap = new Map<String, String>();
        Map<String, String> profit_Ctr_Id_EQIMap = new Map<String, String>();
        
        for (Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord : [SELECT Id, EQAI_Field_Name__c, EQAI_Field_Value__c, EQAI_Table_Name__c, Salesforce_Field_API_Name__c, Salesforce_Field_Value__c FROM Sales_Order_EQAI_Mapping__mdt]) {
            if (salesOrderEQIMappingRecord.EQAI_Field_Name__c == 'company_id') {
                company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c, salesOrderEQIMappingRecord.EQAI_Field_Value__c);
            } else if (salesOrderEQIMappingRecord.EQAI_Field_Name__c == 'profit_ctr_id') {
                profit_Ctr_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c, salesOrderEQIMappingRecord.EQAI_Field_Value__c);
            }
        }
        String rsgEINId = [SELECT RSG_EIN__c FROM User WHERE Id = :userinfo.getUserId() limit 1].RSG_EIN__c;
        String EQAI_Base_URL = [SELECT Id, endpoint FROM NamedCredential WHERE DeveloperName = 'EQAI_Base_URL' LIMIT 1].endpoint;
        for (EQAI_API_URL_Extensions__mdt record : metadataRecords) {
            Map<String, Object> modifiedRecord = new Map<String, Object>{
                'Id' => record.Id,
                    'API_Extension_Name__c' => record.API_Extension_Name__c,
                    'API_Token__c' => record.API_Token__c,
                    'API_Key__c' => record.API_Key__c,
                    'API_Extension__c' => EQAI_Base_URL + record.API_Extension__c,
                    'company_Id_EQIMap' => company_Id_EQIMap,
                    'profit_Ctr_Id_EQIMap' => profit_Ctr_Id_EQIMap,
                    'employeeId' => rsgEINId
                    };
                        records.add(modifiedRecord);
        }  
        
        return records;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getDocumentTypeID(String documentType) {
        String documentTypeID = null;
        
        try {
            List<SI_Document_Type_EQAI_Mappping__mdt> metadataRecords = [
                SELECT EQAI_Field_Value__c
                FROM SI_Document_Type_EQAI_Mappping__mdt
                WHERE Salesforce_Field_Value__c = :documentType
                LIMIT 1
            ];
            
            if (!metadataRecords.isEmpty()) {
                documentTypeID = metadataRecords[0].EQAI_Field_Value__c;
            } else {
                System.debug('No matching document type found for: ' + documentType);
            }
        } catch (Exception e) {
            System.debug('An error occurred: ' + e.getMessage());
        }
        
        return documentTypeID;
    }
    
       @AuraEnabled
    public static void updateDocumentTypeID(Id salesInvoiceId) {
        jobLevelBillingInfo(salesInvoiceId);
        Sales_Invoice__c objInvoice = New Sales_Invoice__c(Id = salesInvoiceId, Document_Status__c = 'Sent to EQAI', Sent_to_EQAI_Date__c = DateTime.now()); 
        update objInvoice; 
        List<Sales_Invoice__c> salesInvoiceList = [
            SELECT Id, Sales_Order__r.Id 
            FROM Sales_Invoice__c 
            WHERE Id = :salesInvoiceId 
            AND Sales_Order__r.Site_Address_Changed__c = true
            LIMIT 1
        ];
        if(!salesInvoiceList.isEmpty() && String.IsNotBlank(salesInvoiceList[0].Id))
        {
        Sales_Order__c objSalesOrder = New Sales_Order__c(); 
        objSalesOrder.Id = salesInvoiceList[0].Sales_Order__r.Id;
        objSalesOrder.Site_Address_Changed__c = false;
        update objSalesOrder;  
        }
    }
    
    @AuraEnabled
    public static void updateSalesInvoice(Id salesInvoiceId) {
        try{
             String Response = WorkOrderAttachmentInfo.executeTransactionCompleteCallout(salesInvoiceId);
            if(Response == '200' || Response == 'SUCCESS')
            {
                    Sales_Invoice__c objInvoice = New Sales_Invoice__c(Id = salesInvoiceId, Document_Status__c = 'Sent to EQAI', Sent_to_EQAI_Date__c = DateTime.now()); 
                    update objInvoice;
                    List<Sales_Invoice__c> salesInvoiceList = [
                    SELECT Id, Sales_Order__r.Id 
                    FROM Sales_Invoice__c 
                    WHERE Id = :salesInvoiceId 
                    AND Sales_Order__r.Site_Address_Changed__c = true
                    LIMIT 1
                    ];
                if(!salesInvoiceList.isEmpty() && String.IsNotBlank(salesInvoiceList[0].Id))
                {
                    Sales_Order__c objSalesOrder = New Sales_Order__c(); 
                    objSalesOrder.Id = salesInvoiceList[0].Sales_Order__r.Id;
                    objSalesOrder.Site_Address_Changed__c = false;
                    update objSalesOrder;  
                }
            }
            else
            {
                 SalesInvoiceWorkOrderService.createCaseWithParentId(salesInvoiceId,'Error in WO Complete Transaction API',Response,null);
            }
        	  
        }
      
        catch(Exception e){
            throw new AurahandledException('Please try again after sometimes');
        }
        
    }
    
    
    
    public static String jobLevelBillingInfo(Id salesInvoiceId){           
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        JSONGenerator jsonGen = JSON.createGenerator(true); 
        String request = '';
        String employeeId;
        
        try
        {
            EQAI_API_URL_Extensions__mdt getWOHeaderInfo = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='GetJobBillingInfo'];
            employeeId = [SELECT RSG_EIN__c from User WHERE Id =: userinfo.getUserId() limit 1].RSG_EIN__c;
            map<String,String> company_Id_EQIMap = new map<String,String>();
            map<String,String> profit_Ctr_Id_EQIMap = new map<String,String>();
            
            // reterving the data from the Sales_Order_EQAI_Mapping__mdt  Custom metadata and storing them in a map so that we can send the salesforce equivalent value to EQAI system.
            for(Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord :[select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,EQAI_Table_Name__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c from Sales_Order_EQAI_Mapping__mdt]){
                if(salesOrderEQIMappingRecord.EQAI_Field_Name__c =='company_id'){
                    company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
                else if(salesOrderEQIMappingRecord.EQAI_Field_Name__c=='profit_ctr_id'){
                    profit_Ctr_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
            }
            
            Sales_Invoice__c salesInvoiceRec = [SELECT Id,Sales_Order__r.Id,CSID__c FROM Sales_Invoice__c WHERE Id = :salesInvoiceId];
            Sales_Order__c salesOrder = [Select Id,Bill_to_Customer_No__c,Bill_to_Customer_No__r.Sage_Customer_No__c,
                                         End_Date__c,CSID__c,CreatedDate,LastModifiedDate,Document_Status__c,Payment_Term__c,
                                         Bill_to_Contact__r.Name,Bill_to_Contact__r.Email,Bill_to_Customer_No__r.Invoice_Submission_Channels__c,
                                         Payment_Term__r.EQAI_Terms_Code__c,Name,Internal_Comments__c,CreatedBy.Name,LastModifiedBy.Name,
                                         Bill_to_Customer_No__r.PO_Number_Type__c,Bill_to_Customer_No__r.Invoice_Backup_Documents__c,Bill_to_Customer_No__r.Invoice_Portal__c,
                                         Service_Center__c,Service_Center__r.Name,
                                         Account_Executives__r.Territory_Code__c, Account_Executives__r.Internal_Contact__c, Account_Executives__r.RSG_EIN__c,
                                         Bill_to_Customer_No__r.Payment_Term__c,
                                         Bill_to_Customer_No__r.Payment_Term__r.EQAI_Terms_Code__c,Bill_to_Contact__r.Title,Bill_to_Customer_No__r.PO_Required__c
                                         from sales_Order__c 
                                         where Id=:salesInvoiceRec.Sales_Order__c LIMIT 1];
            List<SFJobBillingProjectJSON> jobBillingProjectJson = new list<SFJobBillingProjectJSON>();
            logData.className = 'WorkOrderAttachmentInfo';
            logData.methodName = 'jobLevelBillingInfo';
            logData.recordId = salesInvoiceRec.Id;
            
            SFJobBillingProjectJSON jobBillingJson = new SFJobBillingProjectJSON(salesOrder,employeeId,false,salesInvoiceRec.CSID__c,company_Id_EQIMap,profit_Ctr_Id_EQIMap);
            jobBillingProjectJson.add(jobBillingJson);
            System.debug('request++++++++++++++++++++++'+System.Json.serialize(jobBillingProjectJson));
            String jobBillingResponse = WorkOrderQuoteService.getPostCalloutResponseContents(getWOHeaderInfo.API_Extension__c, System.Json.serialize(jobBillingProjectJson),'POST',getWOHeaderInfo.API_Key__c,getWOHeaderInfo.API_Token__c);
            String convertedJobResponse = jobBillingResponse.toLowerCase();
            System.debug('response====>'+jobBillingResponse);
            if(jobBillingResponse != '200' && !convertedJobResponse.contains('billing project already exists') ){
                Map<String, Object> jobBillingMap = (Map<String, Object>) JSON.deserializeUntyped(jobBillingResponse);
                String salesInvId = (String) salesInvoiceId;
                if(jobBillingMap.get('status') != 200){
                    Set<Id> salesOrderCSId = new Set<Id>();
                    Map<String,String> CSIDToErrorMessageMap = new Map<String,String>();
                    List<Case> casesToInsert = new List<Case>();
                    List<Object> details = (List<Object>) jobBillingMap.get('details');
                    List<Object> resultObjs = new List<Object>();
                    for(Object detailObj : details){
                        Map<String,Object> resultObj = (Map<String,Object>) detailObj;
                        resultObj.put('salesInv',(Object)salesInvoiceId);
                        resultObjs.add(resultObj);
                    }
                    jobBillingMap.put('details', (Object)resultObjs);   
                    
                }
                
                logData.serviceRequest = 'jobLevelBillingInfoReq >>' + System.Json.serialize(jobBillingProjectJson);
                logData.serviceResponse = 'jobLevelBillingInfoRes >>' + JSON.serialize(jobBillingMap);
                ApplicationLog.startLog(JSON.serialize(logData));
                ErrorHandlingController.parseJSON('salesInv',JSON.serialize(jobBillingMap), 'Error in Job level billing project', 'EQAI-JOB Billing Error','Medium');
                return jobBillingResponse;
            }
            
            return jobBillingResponse;
            
        }
        Catch(Exception e)
        {
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());    
            throw new AurahandledException(e.getMessage());
        }
    } 
    public static String executeTransactionCompleteCallout(String invoiceId){
        EQAI_API_URL_Extensions__mdt workOrderDetailsTransactional = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='workOrderDetailsTransactional'];
        String endpoint = workOrderDetailsTransactional.API_Extension__c;
        endpoint = endpoint.replace('{invoiceId}',invoiceId);
        try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:EQAI_Base_URL'+endpoint);    
            req.setHeader('x-api-key',workOrderDetailsTransactional.API_Key__c);
            req.setHeader('x-secret-token',workOrderDetailsTransactional.API_Token__c);
            req.setHeader('Content-Type','application/json');
            
            req.setMethod('GET');
            req.setTimeout(120000);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String response = res.getBody();
            System.debug('Response: '+ response);            
            return string.valueof(res.getStatusCode()) != '200' ? response : (string.valueof(res.getStatusCode()) == '200' && response.trim() == 'Integration Successful') ?string.valueof(res.getStatusCode()) : response ;
        }catch(Exception e){
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return e.getMessage();
        } 
        //return null;
    }
    
   @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getRecordTypesForUser() {
        String userProfileName = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1].Profile.Name;
        List<Map<String, String>> recordTypeOptions = new List<Map<String, String>>();
        
        // Retrieve record type info for Contact object
        List<RecordTypeInfo> recordTypeInfos = Contact.SObjectType.getDescribe().getRecordTypeInfos();
        system.debug('recordTypeInfos'+recordTypeInfos);
        
        for (RecordTypeInfo info : recordTypeInfos) {
            if (info.isAvailable()) {
                    if (info.getName() != 'Master') {
                        recordTypeOptions.add(new Map<String, String>{
                            'label' => info.getName(),
                                'value' => info.getRecordTypeId()
                                });
                    }
                } 
            }
        
        return recordTypeOptions;
    }
}