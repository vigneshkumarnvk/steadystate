/*
* Class Name: SFJobBillingProjectService
* Summary  : 

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Sathish Rosekumar           09/04/2024              79107 - Send SF Sales Order Close Date to EQAI job level billing project
Shahwaz Khan                09/04/2024              80447 - Reopen sales order & billing project
Sathish Rosekumar           30/04/2024              79107 - Updated the EQAI API and Payload, then handled error response
Pavithra P					08-05-2024			    US118581 - Salesforce - Add integration log 
*************************************************************************************************************/
public class SFJobBillingProjectService {
    //Task#80447
   
    public static String reOpenSalesOrderInfo(Id reOpenSaleOrderIds){
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        logData.className = 'SFJobBillingProjectService';
        logData.methodName = 'reOpenSalesOrderInfo';
        logData.recordId = reOpenSaleOrderIds;
        try
        {
            List<SFJobBillingProjectJSON> jobBillingProjectJson = new list<SFJobBillingProjectJSON>();
            map<String,String> company_Id_EQIMap = new map<String,String>();
            map<String,String> profit_Ctr_Id_EQIMap = new map<String,String>();
            String employeeId = [SELECT RSG_EIN__c from User WHERE Id =: userinfo.getUserId() limit 1].RSG_EIN__c;
             // reterving the data from the Sales_Order_EQAI_Mapping__mdt  Custom metadata and storing them in a map so that we can send the salesforce equivalent value to EQAI system.
            for(Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord :[select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,EQAI_Table_Name__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c from Sales_Order_EQAI_Mapping__mdt]){
                if(salesOrderEQIMappingRecord.EQAI_Field_Name__c =='company_id'){
                    company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
                else if(salesOrderEQIMappingRecord.EQAI_Field_Name__c=='profit_ctr_id'){
                    profit_Ctr_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
            }
            for(
                Sales_Order__c salesOrder: [Select Id,Name,Bill_to_Customer_No__c,Document_Status__c,Bill_to_Customer_No__r.AccountNumber,Bill_to_Customer_No__r.Sage_Customer_No__c,Close_Date__c,CSID__c,Service_Center__c,Service_Center__r.Name,
                                            Bill_to_Contact__c,Bill_to_Contact__r.Email,Bill_to_Contact__r.Name,Bill_to_Customer_No__r.Invoice_Submission_Channels__c,Payment_Term__c,Payment_Term__r.EQAI_Terms_Code__c,
                                            Internal_Comments__c,Account_Executives__c,Account_Executives__r.Internal_Contact__c,Account_Executives__r.Territory_Code__c ,Account_Executives__r.RSG_EIN__c,
                                            LastModifiedBy.Name,CreatedBy.Name,CreatedDate,LastModifiedDate,
                                            Bill_to_Customer_No__r.Invoice_Backup_Documents__c,
                                            Bill_to_Customer_No__r.PO_Number_Type__c,
                                            Bill_to_Customer_No__r.Invoice_Portal__c,
                                            Bill_to_Customer_No__r.Payment_Term__c,
                                            Bill_to_Customer_No__r.Payment_Term__r.EQAI_Terms_Code__c,
                                            Bill_to_Customer_No__r.Invoice_Email_Contact_Types__c,
                                            Bill_to_Contact__r.Title
                                            FROM sales_Order__c where Id = :reOpenSaleOrderIds]
            ){   
                SFJobBillingProjectJSON jobBillingJson = new SFJobBillingProjectJSON(salesOrder,employeeId,true,null,company_Id_EQIMap,profit_Ctr_Id_EQIMap);
                jobBillingProjectJson.add(jobBillingJson);  
            }
            EQAI_API_URL_Extensions__mdt getWOHeaderInfo = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='GetJobBillingInfo'];
            System.debug('payload::'+System.Json.serialize(jobBillingProjectJson));
            String jobBillingResponse = WorkOrderQuoteService.getPostCalloutResponseContents(getWOHeaderInfo.API_Extension__c, System.Json.serialize(jobBillingProjectJson),'POST',getWOHeaderInfo.API_Key__c,getWOHeaderInfo.API_Token__c);
            System.debug('response::'+jobBillingResponse);
            logData.serviceRequest = 'jobBillingpayload >>'+System.Json.serialize(jobBillingProjectJson);
        	logData.serviceResponse = 'jobBillingResponse >>' +jobBillingResponse;
            String convertedJobResponse = jobBillingResponse.toLowercase();
             if(jobBillingResponse != '200' && (!convertedJobResponse.contains('billing project already exists'))){
            ApplicationLog.startLog(JSON.serialize(logData));
              String errorMsg =  ErrorHandlingController.parseJSON('salesforceJobBillingProjectCsid',jobBillingResponse, 'Error in Reopen Job level billing project', 'EQAI-JOB Billing Error','Medium');
                return errorMsg ;
            }
            else
            {
                
                return 'Integration Successful' ; 
            }
        }
        Catch(Exception e)
        {
            logData.message = e.getMessage();        
        	ApplicationLog.startLog(JSON.serialize(logData));
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());            
        }
        return null;
    }
    
    //Task#79107
    public static String updateCloseDateInSalesOrderInfo(Id saleOrderId){
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
		logData.className = 'SFJobBillingProjectService';
		logData.methodName = 'updateCloseDateInSalesOrderInfo';
        logData.recordId = saleOrderId;
        try
        {
            String employeeId = [SELECT RSG_EIN__c from User WHERE Id =: userinfo.getUserId() limit 1].RSG_EIN__c;
            
            
            Sales_Order__c salesOrder = [Select Id,Document_Status__c,Bill_to_Customer_No__c,Bill_to_Customer_No__r.AccountNumber,End_Date__c,CSID__c,
                                         CreatedDate,LastModifiedDate FROM sales_Order__c where Id =:saleOrderId];
                
            SFJobBillingProjectUpdateJSON jobBillingJson = new SFJobBillingProjectUpdateJSON(salesOrder,employeeId);
            
            EQAI_API_URL_Extensions__mdt getWOHeaderInfo = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='UpdateJobBillingCloseDateInfo'];
            System.debug('payload::'+System.Json.serialize(jobBillingJson));
            String jobBillingResponse = WorkOrderQuoteService.getPostCalloutResponseContents(getWOHeaderInfo.API_Extension__c, System.Json.serialize(jobBillingJson),'POST',getWOHeaderInfo.API_Key__c,getWOHeaderInfo.API_Token__c);
            System.debug('response::'+jobBillingResponse);
            if(!jobBillingResponse.Startswith('Update Succesful')){  
				Case errorCase = ErrorHandlingController.createMultipleCaseWithParentId(saleOrderId,'Error in Close Job level billing project',ErrorHandlingController.splitSuccessMessage(jobBillingResponse), 'EQAI-JOB Billing Error','Medium');
            	insert errorCase;
            }			
			logData.serviceRequest = 'updateCloseDateInSalesOrderInfoReq' + System.Json.serialize(jobBillingJson);
			logData.serviceResponse = 'updateCloseDateInSalesOrderInfoRes' + jobBillingResponse;
			ApplicationLog.startLog(JSON.serialize(logData));
            return jobBillingResponse;
        }
        Catch(Exception e)
        {
            logData.message = e.getMessage();
			ApplicationLog.startLog(JSON.serialize(logData));
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause()); 
            return '400';
        }
    }      
}