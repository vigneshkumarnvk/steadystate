/*************************************************************************************************
* Name         :  SalesInvoiceWorkOrderService 
* Description  :  Construct JSON for SalesInvoiceWorkOrderService
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vennila P       		11-24-2023             73779: Create Work order header in EQAI 
													  when Sales Invoice and Sales Invoice Lines created in Salesforce
* Shahwaz Khan          12-24-2023             75277: Status should change to closed once "Submit EQAI Billing Package" Button 
													  is pressed
* Prabhu Rathakrishnan  01-08-2024      	   75097: Salesforce - Send contract number to match to existing billing project EQAI - JSON
* Sanjana	      		01-08-2024             63067: Implemented the logic to pass the string value to component when 
													  the workorderdetailjson is success
* Shahwaz Khan          02/07/2024  		   77453: Error Handling - Salesforce - Detailed error message to be received from EQAI & create pop up error message in Salesforce (SIL integration)
* Vennila Paramasivam	02-16-2024			   Task78892: Updating D365_Account_Number mapping
* Sathish Rosekumar		02-23-2024			   Task79200: added the Last_Service_Dates__c First_Service_Date__c field in query
* Vennila Paramasivam	03-04-2024			   80209: removed getInstance functionality and queried custom metadata due to character limitation
* Vennila Paramasivam	03-22-2024			   Task81412 - Added employee_id
* Prabhu Rathakrishnan  03-28-2024      	   82299: Site Sent to EQAI WO and Site Display Name is Different 
* Vennila Paramasivam	03-29-2024			   81405: Updated Project_name mapping from Job_description to CMR Description.
* Andrew Simons         04-10-2024             83646 Added invoice_tax
* Andrew Simons         05-14-2024             87675  Sent to EQAI Date updated to current date/time on successful integration
* Vennila P				05-20-2024			   Task 86632: Added Order by Bundle_Line__c NULLS FIRST
* Vennila Paramasivam	06-18-2024			   US115603: Adding SalesInvoiceNumber 
  Shahwaz Khan          07-10-2024             US117390: Salesforce - Updates to Site Address
* Pavithra P			08-05-2024			   US118581 - Salesforce - Add integration log  
* Prabhu Rathakrishnan      09/09/2024             US121824: Salesforce - Billing Project lookup on Sales Order
* Pavithra Periyasamy	11/07/2024			   US129598: [Continued] SF -  Create single JSON object for billing package integration
* Prabhu Rathakrishnan      12/03/2024             US132386: Salesforce - Move 'Disposal Billing Method' field to be on Sales Lines of Sales Quote/Order
*************************************************************************************************/

public class SalesInvoiceWorkOrderService {
    Static string request;
    public static String successMessage = ''; 
    Static Boolean wasteDisposal = false;
    //@future(callout=true)
    public static void workOrderHeaderInfo(String salesInvoiceId){  
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        logData.className = 'SalesInvoiceWorkOrderService';
        logData.methodName = 'workOrderHeaderInfo';
        JSONGenerator jsonGen = JSON.createGenerator(true); 
        map<String,String> company_Id_EQIMap = new map<String,String>();
        map<String,String> profit_Ctr_Id_EQIMap = new map<String,String>();
        map<String,String> project_code_EQIMap = new map<String,String>();
        String employeeId;
        try
        {
            employeeId = [SELECT RSG_EIN__c from User WHERE Id =: userinfo.getUserId() limit 1].RSG_EIN__c;
            /// ticket # 80209
           ///EQAI_API_URL_Extensions__mdt getWOHeaderInfo = EQAI_API_URL_Extensions__mdt.getInstance('getWorkOrderHeaderInfo'); 
            EQAI_API_URL_Extensions__mdt getWOHeaderInfo = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getWorkOrderHeaderInfo'];
            
             // reterving the data from the Sales_Order_EQAI_Mapping__mdt  Custom metadata and storing them in a map so that we can send the salesforce equivalent value to EQAI system.
            for(Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord :[select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,EQAI_Table_Name__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c from Sales_Order_EQAI_Mapping__mdt]){
                if(salesOrderEQIMappingRecord.EQAI_Field_Name__c =='company_id'){
                    company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
                else if(salesOrderEQIMappingRecord.EQAI_Field_Name__c=='profit_ctr_id'){
                    profit_Ctr_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
                else if(salesOrderEQIMappingRecord.EQAI_Field_Name__c=='project_code'){
                    project_code_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
            }
            // US117390 added site details field from Sales Order
            Sales_Invoice__c salesInvoiceRec = [SELECT First_Service_Date__c,Last_Service_Dates__c,Approval_Status__c,Bill_to_Customer__r.Name,Bill_to_Customer__r.Sage_Customer_No__c,
                                                createdby.name,createdby.RSG_EIN__c, CSID__c,Customer_PO_No__c,Sales_Order__c,Service_Center__r.Name,LastModifiedBy.Name, LastModifiedBy.RSG_EIN__c,
                                                Sales_Order_type__c,/*Contract_Line__c,Line_Amt_Incl_Tax__c,TM__c,*/Account_Executive__c,Billing_Instructions__c,Approved__c,Approved_Amount__c,
                                                Contact__c,Contract_Name__c,Contract_Surcharge_Prct__c,Contract_Surcharge_Type__c,Corrected_Customer_PO_No__c,Country__c,
                                                Customer_Billing_Instructions__c,Expected_Payment_Date__c,I_C__c,Internal_Comments__c,Invoice_Note__c,Name,
                                                LastModifiedById,OwnerId,Payment_Term__c,Remit_To__c,Rent_Billing_Amount__c,Rental_Invoice__c,Rental_Order__c,Sales_Quote__c,
                                                Salesperson__c,Service_Days__c,Subsidiary_Company__c,Surcharge_Pct__c,Surcharge_Amount__c,Surcharge_Amt_Incl_Tax__c,Sales_Order__r.Name,
                                                Surcharge_Type__c,Tax_Area__c,Tax_Liable__c,Work_Order_Type_ID__c,Id,Sales_Order__r.Payment_Term__c,Sales_Order__r.Payment_Term__r.Name,
                                                Sales_Order__r.D365_Project_ID__c,EQAI_Billing_Project_ID__c,Bill_to_Customer__r.AccountNumber,Sales_order__r.EqaiGeneratorId__c,Contract__c,
                                                Contract__r.ContractNumber,Site_Scope__c,Sales_Order__r.Bill_to_Contact__c,Sales_Order__r.Bill_to_Contact__r.Name,Sales_order__r.Job_Description__c,
                                                Sales_order__r.CMR_Description__c,Sales_Order__r.Alternate_Site_Address__c, Invoice_Tax__c, Sent_to_EQAI_Date__c,
                                                Sales_Order__r.Site_City__c, Sales_Order__r.Site_Country__c, 
                                                Sales_Order__r.Site_Postal_Code__c, Sales_Order__r.Site_State__c, 
                                                Sales_Order__r.EQAI_Billing_Project_Id__c,
                                                Sales_Order__r.Site_Street__c, Sales_Order__r.Site_Name__c, 
                                                Sales_Order__r.Site_Phone_No__c, Sales_Order__r.Site_Address_Changed__c,Bill_to_Customer__r.NAICS_code__c,Service_Center__r.Advanced_Disposal__c
                                                FROM Sales_Invoice__c WHERE Id = :salesInvoiceId];
            
            SalesInvoiceWOHeaderJSON invoiceHeaderJson = new SalesInvoiceWOHeaderJSON(salesInvoiceRec,project_Code_EQIMap,company_Id_EQIMap,profit_Ctr_Id_EQIMap,employeeId);
            request = String.valueOf(invoiceHeaderJson);
            System.debug('request++++++++++++++++++++++'+System.Json.serialize(invoiceHeaderJson));
            system.debug('advanced'+salesInvoiceRec.Service_Center__r.Advanced_Disposal__c);
            if(salesInvoiceRec.Service_Center__r.Advanced_Disposal__c){
                wasteDisposal = containsWasteDisposalInvoiceLine(salesInvoiceRec.id);
                system.debug('wasteDisposal'+wasteDisposal);
                
            }
            if(wasteDisposal){
                //US129598
                    EQAI_API_URL_Extensions__mdt getWODetailInfo = [SELECT API_Extension__c, API_Key__c, API_Token__c, DeveloperName FROM EQAI_API_URL_Extensions__mdt WHERE DeveloperName='WorkOrderCreate'];

                    BillingPackageJSON eqiBillingPackageJSON = new BillingPackageJSON(salesInvoiceRec,project_Code_EQIMap,company_Id_EQIMap,profit_Ctr_Id_EQIMap,employeeId);
                    String endPoint = 'callout:EQAI_NEW_URL'+getWODetailInfo.API_Extension__c;                    
                    System.debug('eqiBillingPackageJSON Jsonstring>> '+System.Json.serialize(eqiBillingPackageJSON));
                    String eqiBillingPackageResponse = HttpCalloutController.getResponse(getWODetailInfo.API_Key__c,endPoint,120000,System.Json.serialize(eqiBillingPackageJSON) , 'POST',getWODetailInfo.API_Token__c);
                    System.debug('eqiBillingPackageResponse >>'+eqiBillingPackageResponse);
                
                   //  successMessage = 'True';
                if(eqiBillingPackageResponse != '200'){
                    SalesInvoiceWorkOrderService.createCaseWithParentId(salesInvoiceRec.Id,'Error in single json',eqiBillingPackageResponse,null);
                    successMessage = 'False';
                }
               else{
                    successMessage = 'True';
                }
                         
                
           
                //String detailResponse = workOrderDetailInfo(salesInvoiceId,invoiceHeaderJson.CompanyId,invoiceHeaderJson.ProfitCenterId,employeeId);
                ApplicationLog.ApplicationlogInformation woDetailData = new ApplicationLog.ApplicationlogInformation();
                woDetailData.className = 'SalesInvoiceWorkOrderService';
                woDetailData.methodName = 'workOrderDetailInfo'; 
                woDetailData.serviceRequest =  'SingleJSONReq' + endPoint + ' ' +System.Json.serialize(eqiBillingPackageJSON);
                woDetailData.serviceResponse = 'SingleJSONRes'+eqiBillingPackageResponse;
                woDetailData.recordId = salesInvoiceId;
                ApplicationLog.logRecordsList.add(woDetailData);
            
            }else{
                
                String workOrderHeaderResponse = WorkOrderQuoteService.getPostCalloutResponseContents(getWOHeaderInfo.API_Extension__c, System.Json.serialize(invoiceHeaderJson),'POST',getWOHeaderInfo.API_Key__c,getWOHeaderInfo.API_Token__c);
                //  String workOrderDetailResponse;
                System.debug('workOrderHeaderResponse::::::::::::::'+workOrderHeaderResponse);
                logData.serviceRequest =  'WorkOrderHeaderReq' + System.Json.serialize(invoiceHeaderJson);
                logData.serviceResponse = 'WorkOrderHeaderRes' + workOrderHeaderResponse;  
                logData.recordId = salesInvoiceId;
                ApplicationLog.logRecordsList.add(logData);
                if(WorkOrderHeaderResponse == '200')
                {
                    String detailResponse = workOrderDetailInfo(salesInvoiceId,invoiceHeaderJson.CompanyId,invoiceHeaderJson.ProfitCenterId,employeeId);
                    // salesInvoiceRec.Sent_to_EQAI_Date__c = DateTime.now();
                    // update salesInvoiceRec;
                    // return workOrderDetailResponse;
                    //WorkOrderDetail
                    ApplicationLog.ApplicationlogInformation woDetailData = new ApplicationLog.ApplicationlogInformation();
                    woDetailData.className = 'SalesInvoiceWorkOrderService';
                    woDetailData.methodName = 'workOrderDetailInfo'; 
                    woDetailData.serviceRequest =  'WorkOrderDetailReq' + salesInvoiceId + ' ' +System.Json.serialize(invoiceHeaderJson) + ' ' + employeeId;
                    woDetailData.serviceResponse = detailResponse;  
                    woDetailData.recordId = salesInvoiceId;
                    ApplicationLog.logRecordsList.add(woDetailData);
                    
                }
                else{
                    System.debug('inside else before setting the value to successMEssage:::::::::::::::'+workOrderHeaderResponse);
                    successMessage = workOrderHeaderResponse;
                    //Task#77453 
                    SalesInvoiceWorkOrderService.createCaseWithParentId(salesInvoiceRec.Id,'Error in Work order header',System.Json.serialize(invoiceHeaderJson),null);
                    // ErrorHandlingController.parseJSON(salesInvoiceRec.Id,workOrderHeaderResponse, 'Error in Work order header', 'EQAI-WO Error','Medium');
                }
            }
            ApplicationLog.insertbulkLog(ApplicationLog.logRecordsList);
        }
        Catch(Exception e)
        {
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());            
            logData.message = e.getMessage();
			ApplicationLog.startLog(JSON.serialize(logData));
            createCaseWithParentId(salesInvoiceId,'Error in apex class','Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause(),null);         
            
        }
        
        
    }
    
    public static String workOrderDetailInfo(String salesInvoiceId,Integer companyId, Integer profitCtrId, String employeeId){
        // ticket # 80209
        EQAI_API_URL_Extensions__mdt getWODetailInfo = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getWorkOrderDetailInfo'];
       // EQAI_API_URL_Extensions__mdt getWODetailInfo = EQAI_API_URL_Extensions__mdt.getInstance('getWorkOrderDetailInfo'); 
        map<String,String> resource_Type_EQIMap = new map<String,String>();
        map<String,String> bill_Unit_Code_EQIMap = new map<String,String>();
        map<String,String> company_Id_EQIMap = new map<String,String>();
        Integer resourceCompanyId;
        for(Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord :[select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,EQAI_Table_Name__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c from Sales_Order_EQAI_Mapping__mdt]){
                if(salesOrderEQIMappingRecord.EQAI_Field_Name__c =='company_id'){
                    company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
                }
        }
        for(Sales_Line_EQAI_Mapping__mdt salesLineEQIMappingRecord : [select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,Salesforce_Field_Value__c from Sales_Line_EQAI_Mapping__mdt  ]){
            if(salesLineEQIMappingRecord.EQAI_Field_Name__c =='resource_type'){
                resource_Type_EQIMap.put(salesLineEQIMappingRecord.Salesforce_Field_Value__c ,salesLineEQIMappingRecord.EQAI_Field_Value__c);
            }
            else if(salesLineEQIMappingRecord.EQAI_Field_Name__c =='bill_unit_code'){
                bill_Unit_Code_EQIMap.put(salesLineEQIMappingRecord.Salesforce_Field_Value__c ,salesLineEQIMappingRecord.EQAI_Field_Value__c);
            }
        }
        List<Sales_Invoice_Line__c> invoiceLineRec = [SELECT Id,Disposal_Billing_Method__c, BOL_Manifest__c,Resource_Class_Code__c,Bundle_Line__c,Category__c,CreatedById,Description__c,Facility__c,LastModifiedById,
                                                      CreatedBy.Name,LastModifiedBy.RSG_EIN__c,CreatedBy.RSG_EIN__c,Bundle_Line__r.Name,Bundle_Line__r.Id,
                                                      Facility__r.Name, Facility__r.TSDF_Code__c,LastModifiedBy.Name,Line_Amount__c,Line_Cost__c,Name,Pricing_Source_2__c,Qty_to_Display__c,
                                                      Quantity__c,Resource__r.Name,Resource__r.Service_Center__c,Resource__r.Service_Center__r.name,Resource_Type__r.Resource_Class_Code__c,Sales_Invoice_Job_Task__r.Name,Scheduled_Date__c,Unit_Price__c,
                                                      Unit_Cost__c,Unit_of_Measure__c,Unit_of_Measure__r.Name,Service_Center__r.Name,Print_Line__c,Sales_Invoice__r.CSID__c,
                                                      Contract_Line__c, Line_Amt_Incl_Tax__c,TM__c, Non_billable__c,Time_Rate_Code__c,Resource__r.CSID__c,
                                                      Resource__r.Resource_Class_Code__c,Resource__r.EQAI_Other__c, Resource__r.External_ID__c,Resource_Type__r.External_ID__c,Sales_Invoice__r.Invoice_Tax__c,
                                                      Sales_Invoice__r.Sales_Order__r.Name,Resource_Type__r.EQAI_Supply__c,TM__r.Name,Sales_Invoice__r.Sales_Order__r.Disposal_Billing_Method__c,TM_Line__r.Approval_Id__c,Sales_Invoice__r.Sales_Order__r.CSID__c,
                                                      Sales_Invoice__r.Last_Service_Dates__c,Sales_Invoice__r.First_Service_Date__c
                                                      FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c = : salesInvoiceId Order by Bundle_Line__c NULLS FIRST];
        
        //creating the JSON body in a array format to send it to EQI System           
        List<SalesInvLineWODetailsJSON> invoiceLineDetailsList = new list<SalesInvLineWODetailsJSON>();
        ///InvoiceLineWODetailsJSON invoiceLineJson = new InvoiceLineWODetailsJSON(invoiceLineRec[0]);
        Sales_Invoice_Line__c salesInvLneRecord;
        
        for(Sales_Invoice_Line__c salesInvLineRecord : invoiceLineRec) 
        { 
            System.debug('salesInvLineRecord++++++++++++' + salesInvLineRecord.non_billable__c);
            
            if(salesInvLineRecord.Resource__r!= null && salesInvLineRecord.Resource__r.Service_Center__c!=null && salesInvLineRecord.Resource__r.Service_Center__r.name!=null){
                if(salesInvLineRecord.Resource__r.Service_Center__r.name.equals('99 - Temp')){
                    resourceCompanyId = companyId;
                }
                else{
                	resourceCompanyId = company_Id_EQIMap.get(salesInvLineRecord.Resource__r.Service_Center__r.name)!= null ?Integer.ValueOf(company_Id_EQIMap.get(salesInvLineRecord.Resource__r.Service_Center__r.name)) : null;
                }
            }
            else{
                resourceCompanyId = null;
            }
            system.debug('wasteDisposal'+wasteDisposal);
            SalesInvLineWODetailsJSON invoiceLineJson = new SalesInvLineWODetailsJSON(salesInvLineRecord, companyId,  profitCtrId,resource_Type_EQIMap,bill_Unit_Code_EQIMap,employeeId,false,resourceCompanyId,wasteDisposal);
            invoiceLineDetailsList.add(invoiceLineJson);            
            salesInvLneRecord = salesInvLineRecord;
        }
        //87220
        if(invoiceLineRec[0].Sales_Invoice__r.Invoice_Tax__c > 0 || Test.isRunningTest())
            invoiceLineDetailsList.add(new SalesInvLineWODetailsJSON(salesInvLneRecord, companyId,  profitCtrId,resource_Type_EQIMap,bill_Unit_Code_EQIMap,employeeId, true,resourceCompanyId,wasteDisposal));  
        
        
        try
        {
            System.debug('request++++++++++++++++++++++'+System.Json.serialize(invoiceLineDetailsList));
            String workOrderDetailResponse = WorkOrderQuoteService.getPostCalloutResponseContents(getWODetailInfo.API_Extension__c, System.Json.serialize(invoiceLineDetailsList),'POST',getWODetailInfo.API_Key__c,getWODetailInfo.API_Token__c);
            // Implemented as part of 75277
            System.debug('workOrderDetailResponse'+workOrderDetailResponse);
            if(workOrderDetailResponse == '200')
            {
                //Sales_Invoice__c objInvoice = New Sales_Invoice__c(Id = salesInvoiceId, Document_Status__c = 'Sent to EQAI'); 
                ///update objInvoice; 
                successMessage = 'True';
            }
            else
            {
                //Task#77453 
                successMessage = workOrderDetailResponse;
               // SalesInvoiceWorkOrderService.createCaseWithParentId(salesInvoiceId,'Error in Work order details',workOrderDetailResponse,System.Json.serialize(invoiceLineDetailsList));
           		ErrorHandlingController.parseJSON(salesInvoiceId,workOrderDetailResponse, 'Error in Work order details', 'EQAI-WO Error','Medium');
            }
            
            return workOrderDetailResponse;
        }
        Catch(Exception e)
        {
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            createCaseWithParentId(salesInvoiceId,'Error in apex class','Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause(),null);
        }
       return null;  
    }   
    
   
    //Task#77453
    @AuraEnabled 
    public static void createCaseWithParentId(Id parentId,String subject,String caseDescription,String httpRequest) {
        try
        {
        Group newCaseQueue = [SELECT Id FROM Group WHERE Type = 'Queue' and Name = 'Case Owners'];
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Record').getRecordTypeId();
        Case newCase = new Case();
        newCase.Subject = subject;
        newCase.RecordTypeId = recordTypeId;
        if(subject == 'Error in Single Json')
        {
            newCase.Description = caseDescription.length()>32000?caseDescription.substring(0,32000):caseDescription;
        }
        else
            newCase.Description = (SendEQAIBillingPackageCtrl.splitSuccessMessage(caseDescription).length()>32000)?SendEQAIBillingPackageCtrl.splitSuccessMessage(caseDescription).substring(0,32000):SendEQAIBillingPackageCtrl.splitSuccessMessage(caseDescription);
        //newCase.Error_Description__c = (splitSuccessMessage(caseDescription).length()>131000)?splitSuccessMessage(caseDescription).substring(0,131000):splitSuccessMessage(caseDescription);            
        //newCase.Http_Request__c = httpRequest;   
        newCase.Billing_Package__c = parentId; 
        newCase.Reason = 'EQAI-WO Error'; 
        newCase.Priority = 'Medium';    
        newCase.OwnerId = newCaseQueue.Id; 
        insert newCase;
        }Catch(Exception ex)
        {
            System.Debug('Error::'+ex.getMessage());
        }
    } 
    
    public static String executeTransactionCompleteCallout(String invoiceId){
        /*EQAI_API_URL_Extensions__mdt workOrderDetailsTransactional = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='workOrderDetailsTransactional'];
        String endpoint = workOrderDetailsTransactional.API_Extension__c;
        endpoint = endpoint.replace('{invoiceId}',invoiceId);
        try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:EQAI_Base_URL'+endpoint);
            req.setHeader('Content-Type','application/json');
            req.setHeader('x-api-key',workOrderDetailsTransactional.API_Key__c);
            req.setHeader('x-secret-token',workOrderDetailsTransactional.API_Token__c);
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
        } */
        return null;
    }
    
    public static Boolean containsWasteDisposalInvoiceLine(Id salesInvoiceId) {
        Boolean wasteDisposal = false;
        
        try {
            List<Sales_Invoice_Line__c> invoiceLines = [SELECT Id, Category__c 
                                                        FROM Sales_Invoice_Line__c 
                                                        WHERE Sales_Invoice__c = :salesInvoiceId];
            
            for (Sales_Invoice_Line__c line : invoiceLines) {
                if (line.Category__c == 'Waste Disposal') {
                    wasteDisposal = true;
                    break;
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        
        System.debug('Waste Disposal: ' + wasteDisposal);
        return wasteDisposal;
    }
}