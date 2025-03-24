/*************************************************************************************************
* Name         :  WorkOrderQuoteService 
* Description  :  Apex Class for API call out of the work order Quote Service
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Praneeth Yalamati         08-17-2023             US94501: Create Work Order in EQAI when Convert Quote to Order button is pressed
* Praneeth Yalamati         10-06-2023             US97655: ACV: WorkOrderQuoteDetail JSON updates for Tasks
* Prabhu Rathakrishnan      11-13-2023             Task74219: Salesforce - Generator ID - Add Generator ID to JSON msg
* Sanjana Ravichandran      11-24-2023             Task72439: Resource Sync – Salesforce Send - Add Salesforce CSID as column to API
* Prabhu Rathakrishnan      12-28-2023             Task74716: The Sales quote which was created in Salesforce without utilizing the generator  lookup was not integrated in EQAI.
* Shahwaz Khan              01-09-2024             Task75619: Salesforce - Save ALL Site Addresses
* Prabhu Rathakrishnan      01-10-2024             Task75621: Salesforce - Add Fields for "Generator ID and "EPA ID"
* Vennila Paramasivam		02-16-2024			   Task78892: Updating D365_Account_Number mapping
* Vennila Paramasivam       02-19-2024			   78904: Once SO submitted to EQAI, updating the field SO_Submitted_to_EQAI as true.
														  If integration is successful updating SO_Sent_to_EQAI as true.
* Vennila Paramasivam		03-04-2024			   80209: removed getInstance functionality and queried custom metadata due to character limitation
* Sanjana Ravichandran      03-06-2024             Requirement 80420: Salesforce - Pass the @confirm_author to EQAI in WOQ and WO
* Prabhu Rathakrishnan      11-13-2023             Task81356: Salesforce - WOQ - Generator Phone # Formatting is Incorrect
* Vennila Paramasivam		03-22-2024			   Task81412 - Added employee_id
* Vennila Paramasivam		04-11-2024			   Task84551  - Added order by Bundle_line__c DESC NULLS FIRST
* Sanjana Ravichandran      05/13/2024	           Bug 84930: Salesforce Equipment Resources Mapping to EQAI Type Supply Are Failing to Integrate on the Work Order Quote & Work Oder
* Andrew Simons             05-13-2024             Task 87270: added Sent_to_EQAI_Date field and update to current date and time api was successful
* Prabhu Rathakrishnan      05-14-2024             Task83367: Salesforce API - Create Fully Transactional Salesforce and EQAI Integration API's
* Vennila P					05-20-2024			   Task 86632: Added Order by Bundle_Line__c NULLS FIRST
* Pavithra P				08-05-2024			   US118581 - Salesforce - Add integration log 
* Prabhu Rathakrishnan      07-27-2024             US117946:Salesforce - Send work order header information to EQAI upon creation of Sales order with waste disposal  
* Pavithra Periyasamy		11/21/2024             US133594: [Unplanned] Salesforce - Use single JSON format to create Work Order at time of Sales Order creation in Salesforce
*************************************************************************************************/

public class workOrderQuoteService{
    
    /**
     * This method is called by the CovertSalesQuoteToSalesOrderController apex class 
     * This method would make an API Callout to create Quote Order EQI System
     * @param salesOrderId the id of the Sales Order would be passed as the input parameter 
     * @return String with information about the API Response. 
     */
    public static string workOrderQuoteHeaderInfo(String salesOrderId){
        //EQAI_API_URL_Extensions__mdt getWorkOrderQuoteHeaderEQAIAPIURLExtensions = EQAI_API_URL_Extensions__mdt.getInstance('getWorkOrderQuoteHeaderInfo');
        // ticket # 80209
        //Prabhu_ReleaseFlag
        if(System.Label.Release_Flag != 'true'){
           return'';  
        }
           
        EQAI_API_URL_Extensions__mdt getWorkOrderQuoteHeaderEQAIAPIURLExtensions = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getWorkOrderQuoteHeaderInfo'];
        JSONGenerator jsonGen = JSON.createGenerator(true); 
        map<String,String> company_Id_EQIMap = new map<String,String>();
        map<String,String> profit_Ctr_Id_EQIMap = new map<String,String>();
        map<String,String> project_code_EQIMap = new map<String,String>();
        String employeeId;
        boolean wasteDisposal = false;
        
        try{     
            
            employeeId = [SELECT RSG_EIN__c from User WHERE Id =: userinfo.getUserId() limit 1].RSG_EIN__c;
            
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
            
            //Quering the Sales Order & Sales Lines object data by the salesOrderId
            Sales_Order__c[] salesOrderList = [ Select Id,EQAI_Billing_Project_Id__c,Surcharge_Amount__c,Contract__c ,Site_Address_Changed__c ,Surcharge_Type__c ,From_Sales_Quote__c ,Customer_PO_No__c,Internal_Comments__c ,Customer_Billing_Instructions__c ,D365_Project_ID__c,Billing_Instructions__c,Contract_Name__c,Surcharge_Pct__c,Contract_Surcharge_Type__c,EqaiGeneratorId__c,Site_Phone_No__c,EPA_ID__c,Bill_to_Customer_No__r.AccountNumber,  Bill_to_Customer_No__r.Sage_Customer_No__c ,Pay_Rule__r.Name,Payment_Term__r.Name,Project_Coordinator__r.Name,
                                                Service_Center__r.Name,Subsidiary_Company__r.Name,Tax_Area__r.Name,Account_Executives__c,Account_Executives__r.Name,
                                                Bill_to_Contact__r.Name,Bill_to_Contact__c,Bill_to_Customer_No__c,Bill_to_Customer_No__r.Name,City__c,Country__c,
                                                Estimated_Job_End_Date__c,Estimated_Job_End_Time__c,Estimated_Job_Start_Date__c,Estimated_Job_Start_Time__c,
                                                CMR_Description__c,Name,Order_Total_Amount__c,Order_Total_Amount_Incl_Tax__c,Order_Total_Tax__c,Pay_Rule__c,
                                                Payment_Term__c,Sales_Order_Type__r.Work_Order_Type_ID__c,Phone_No__c,Postal_Code__c,Prevailing_Wage_Job__c,Project_Coordinator__c,Site_Scope__c,Service_Center__c,
                                                Site_City__c,Site_Name__c,Site_Country__c,Site_Postal_Code__c,Site_State__c,Site_Street__c,State__c,Subsidiary_Company__c,Tax_Area__c,
                                                Tax_Liable__c,Total_Cost__c,Alternate_Site_Address__c,SO_sent_to_EQAI__c,SO_Submitted_to_EQAI__c,CreatedBy.Name,
                                                Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c, Service_Center__r.Advanced_Disposal__c,Contract__r.ContractNumber,
                                                (SELECT Id,Category__c,Number_of_Day__c,Description__c,Premium_Hours__c,Premium_Rate__c,Line_Amount__c,Line_Amt_Incl_Tax__c,
                                                Line_Cost__c,Line_No__c,Markup__c,Markup_Option__c,Overtime_Hours__c,Overtime_Rate__c,Quantity__c,Regular_Hours__c,
                                                Regular_Rate__c,Resource__c,Resource_Type__c,Tax__c,Tax_Pct__c,Tax_Group__c,Unit_Cost__c,Unit_of_Measure__c,Unit_of_Measure__r.Name,
                                                Unit_Price__c,Name,xUnit_Cost__c,
                                                UOM_Qty__c,Resource__r.Resource_Class_Code__c,Resource__r.EQAI_Other__c,Resource_Type__r.Resource_Class_Code__c,Sales_Order__r.Name,Bundle_Line__c,
                                                Bundle_Line__r.Name,Bundle_Line__r.Resource_Type__c,Bundle_Line__r.Resource_Type__r.Name,Sales_Order_Job_Task__r.Name,
                                                Sales_Order_Job_Task__c,Resource__r.CSID__c,Resource__r.name,Resource__r.External_ID__c,
                                                Resource_Type__r.External_ID__c,Resource_Type__r.EQAI_Supply__c from Sales_Lines__r Order by Bundle_Line__c NULLS FIRST)
                                                from Sales_Order__c Where Id = :salesOrderId];
            
            Sales_Order__c orderRecord = new Sales_Order__c();
            if(salesOrderList.size()>0) orderRecord = salesOrderList[0];
            if(orderRecord.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c != true){
                return '';
            }
            if(orderRecord.Service_Center__r.Advanced_Disposal__c && orderRecord.Sales_Lines__r.size()>0)
                wasteDisposal = containsWasteDisposalSalesLine(orderRecord);
            //creating the JSON body to send it to EQI System 
            WorkOrderQuoteHeaderJSON  QuoteHeaderRecord = new WorkOrderQuoteHeaderJSON(orderRecord ,project_Code_EQIMap,company_Id_EQIMap,profit_Ctr_Id_EQIMap,employeeId);
            System.debug('body: '+ System.Json.serialize(QuoteHeaderRecord));
            String WorkOrderQuoteHeaderResponse = getPostCalloutResponseContents(getWorkOrderQuoteHeaderEQAIAPIURLExtensions.API_Extension__c, System.Json.serialize(QuoteHeaderRecord ),'POST',getWorkOrderQuoteHeaderEQAIAPIURLExtensions.API_Key__c,getWorkOrderQuoteHeaderEQAIAPIURLExtensions.API_Token__c);
            orderRecord.EQAI_Response__c = splitSuccessMessage(WorkOrderQuoteHeaderResponse);

            String WorkOrderQuoteDetailResponse; 
            //WorkOrderQuoteHeader
            ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
            logData.className = 'workOrderQuoteService';
            logData.methodName = 'workOrderQuoteHeaderInfo';
            logData.serviceRequest = 'WorkOrderQuoteHeader ' + System.Json.serialize(QuoteHeaderRecord );
            logData.serviceResponse = 'WorkOrderQuoteHeaderResponse >>'+WorkOrderQuoteHeaderResponse;
            logData.recordId = orderRecord.id;
            ApplicationLog.logRecordsList.add(logData);
            
            if(WorkOrderQuoteHeaderResponse == '200'){
                if(orderRecord.Sales_Lines__r.size() > 0){
                     WorkOrderQuoteDetailResponse = WorkOrderQuoteDetailsInfo(orderRecord,QuoteHeaderRecord.company_id,QuoteHeaderRecord.profit_ctr_id,employeeId);    
                	 orderRecord.EQAI_Response__c = splitSuccessMessage(WorkOrderQuoteDetailResponse);
                }
               
                orderRecord.SO_Submitted_to_EQAI__c = true;
                //WorkOrderQuoteDetail
                ApplicationLog.ApplicationlogInformation workOrderdetailData = new ApplicationLog.ApplicationlogInformation();
                workOrderdetailData.className = 'workOrderQuoteService';
                workOrderdetailData.methodName = 'WorkOrderQuoteDetailsInfo';
                workOrderdetailData.serviceRequest = '\nWorkOrderQuoteDetailReq >> ' + System.Json.serialize(orderRecord );
                workOrderdetailData.serviceResponse = '\nWorkOrderQuoteDetailResponse >>'+WorkOrderQuoteDetailResponse;
                workOrderdetailData.recordId = orderRecord.id;
                ApplicationLog.logRecordsList.add(workOrderdetailData);
                 //78904 
                
                if (WorkOrderQuoteDetailResponse == '200' || (orderRecord.Sales_Lines__r.size() == 0)) {
                        //This call is to make the WorkOrderQuote integration with EQAI transactional
            				
                        EQAI_API_URL_Extensions__mdt workOrderQuoteDetailsTransactional = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='workOrderQuoteDetailsTransactional'];
                        String endpoint = workOrderQuoteDetailsTransactional.API_Extension__c;
                        system.debug('inside staging'+endpoint);
                        endpoint = endpoint.replace('{QuoteId}',orderRecord.Name);
                    
                            //executeTransactionCompleteCallout
                            ApplicationLog.ApplicationlogInformation transactionData = new ApplicationLog.ApplicationlogInformation();
                            transactionData.className = 'WorkOrderQuoteService';
                            transactionData.methodName = 'Staging Callout';
                            transactionData.recordId = orderRecord.id;    
                            if(wasteDisposal){
                                //US133594
                                String workOrderHeaderResponse;
                                SalesInvoiceWOHeaderJSON  invoiceHeaderJson;
                                    EQAI_API_URL_Extensions__mdt getWODetailInfo = [SELECT API_Extension__c, API_Key__c, API_Token__c, DeveloperName FROM EQAI_API_URL_Extensions__mdt WHERE DeveloperName='WorkOrderCreate'];
                                    
                                    BillingPackageJSON eqiBillingPackageJSON = new BillingPackageJSON(orderRecord,project_Code_EQIMap,company_Id_EQIMap,profit_Ctr_Id_EQIMap,employeeId);
                                    String singleJSONendPoint = 'callout:EQAI_NEW_URL'+getWODetailInfo.API_Extension__c;                    
                                    System.debug('eqiBillingPackageJSON Jsonstring>> '+System.Json.serialize(eqiBillingPackageJSON));
                                    workOrderHeaderResponse = HttpCalloutController.getResponse(getWODetailInfo.API_Key__c,singleJSONendPoint,120000,System.Json.serialize(eqiBillingPackageJSON) , 'POST',getWODetailInfo.API_Token__c);
                                    System.debug('eqiBillingPackageResponse >>'+workOrderHeaderResponse);
                                
                                    ApplicationLog.ApplicationlogInformation singleJSON = new ApplicationLog.ApplicationlogInformation();
                                    singleJSON.className = 'WorkOrderQuoteService';
                                    singleJSON.methodName = 'Quote Single JSON';
                                    singleJSON.recordId = orderRecord.id;
                                	singleJSON.serviceRequest = '\nSingleJSONReq >> ' + singleJSONendPoint + System.Json.serialize(eqiBillingPackageJSON);
                					singleJSON.serviceResponse = '\nSingleJSONRes >>'+workOrderHeaderResponse;
                					ApplicationLog.logRecordsList.add(singleJSON);
                                if(WorkOrderHeaderResponse == '200')
                                {
                                    String completecalloutResponse = executeTransactionCompleteCallout(endpoint,'GET',workOrderQuoteDetailsTransactional.API_Key__c,workOrderQuoteDetailsTransactional.API_Token__c);
                                    transactionData.serviceRequest =  '\nexecuteTransactionCompleteReq >> ' + endpoint;
                                	transactionData.serviceResponse = '\nexecuteTransactionCompleteRes >>'+ completecalloutResponse;
                                    if(completecalloutResponse == 'SUCCESS')
                                    {
                                      orderRecord.SO_sent_to_EQAI__c = true;
                           			  orderRecord.Sent_to_EQAI_Date__c = DateTime.now();  
                                    }
                                    else
                                      createCaseWithParentId(orderRecord.Id,'Error in WOQ Complete Trasaction API',splitSuccessMessage(completecalloutResponse),null);
                                    // return workOrderDetailResponse;
                                }
                                else{
                                    System.debug('inside else before setting the value to successMEssage:::::::::::::::'+workOrderHeaderResponse);
                                    String successMessage = workOrderHeaderResponse;
                                    //Task#77453 
                                    createCaseWithParentId(orderRecord.Id,'Error in  Quote single JSON',successMessage,System.Json.serialize(invoiceHeaderJson));
                                    // ErrorHandlingController.parseJSON(salesInvoiceRec.Id,workOrderHeaderResponse, 'Error in Work order header', 'EQAI-WO Error','Medium');
                                }
                            }
                            else{
                                String completecalloutResponse = executeTransactionCompleteCallout(endpoint,'GET',workOrderQuoteDetailsTransactional.API_Key__c,workOrderQuoteDetailsTransactional.API_Token__c);
                                if(completecalloutResponse == 'SUCCESS')
                                 {                                      
                                     orderRecord.SO_sent_to_EQAI__c = true;
                           			 orderRecord.Sent_to_EQAI_Date__c = DateTime.now();  
                                 }
                                else
                                    createCaseWithParentId(orderRecord.Id,'Error in WOQ Complete Trasaction API',splitSuccessMessage(completecalloutResponse),null);
                                    
                                transactionData.serviceRequest =  '\nexecuteTransactionCompleteReq >> ' + endpoint;
                                transactionData.serviceResponse = '\nexecuteTransactionCompleteRes >>'+ completecalloutResponse;
                                
                            }
            			ApplicationLog.logRecordsList.add(transactionData);
                    
        		 } 
       
       			ApplicationLog.insertbulkLog(ApplicationLog.logRecordsList);
				update  orderRecord;        
                return WorkOrderQuoteDetailResponse ; 
            }
            else {
                orderRecord.SO_Submitted_to_EQAI__c = true;
                update  orderRecord; 
                createCaseWithParentId(orderRecord.Id,'Error in Work order header',splitSuccessMessage(WorkOrderQuoteHeaderResponse),Json.serialize(QuoteHeaderRecord));
              //  ErrorHandlingController.parseJSON(orderRecord.id,WorkOrderQuoteHeaderResponse, 'Error in Work order header', 'EQAI-WOQ Error','Medium'); 
                return WorkOrderQuoteHeaderResponse;
            }
                           
        }catch(Exception e){
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            // Logging Exception details
            ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
			logData.className = 'WorkorderQuoteService';
            logData.message = e.getMessage();
            ApplicationLog.startLog(JSON.serialize(logData));
            System.Debug('Error at >>> - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            createCaseWithParentId(salesOrderId,'Error in apex class','Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause(),null);
            //System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            return e.getMessage();
        } 
       
    }



    /**
     * This method is used to call make the API Callout to the EQI System. 
     * This method would make an API Callout to create Quote Order EQI System
     * @param endPointURL - the end point of the API will be passed
     * @param jsonBody- this is the body which we would pass it to the API in an JSON format. 
     * @param methodType - this determines which operation we would be doing either GET or POST
     *  @return String with information about the API Response. 
     */ 
    public static String getPostCalloutResponseContents(String endPointURL, String requestBody, String methodType , String Key, String Token) {
            
        try{
           System.debug('Api key:::::::::::::::::::::::::'+Key); 
            System.debug('Api Token:::::::::::::::::::::::::'+Token); 
            //Key = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAscBGNlaAnyE9RgNIyW0ciHMSRCKc8sK4Bu7jDion/3DUC7dfmeWX/qpmLCiBFXlRXFrRDd5MbRO2Gc03TZVKaGwyQV0gZijzPaVs/MPNDeZsxB8igwy0baC91i7lx83jyLKqo5N1xH1zSSs3TnzdRQimFjM5l701UMz+sWXmav1L3LyAskF1jYzPvHHSttqpFS50VGviCACE6xrvv6lsjRXvMNnWxx7e0QWeN8T2Elo1CTepJ+KB70nSmN3Fn0NSTpJFVExwFtEXKpYPRT3K2n7Pmi03y/qIDF+f6lqyrR8Zxov5Srdeg7meM3RdFWxssYyaICsfeFhwvjTsp85VGQIDAQAB';
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:EQAI_Base_URL'+endPointURL);  
            req.setHeader('Content-Type','application/json');
            req.setHeader('x-api-key',Key);
            req.setHeader('x-secret-token',Token);
            req.setMethod(methodType);
            req.setBody(requestBody);
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
        
   }
   
   /**
     * This method is called by the after posting the of Quote in the EQI  
     * This method would make an API Callout to create Quote Details Order EQI System
     * @param salesOrderRecord - Sales_order__c data is passed as the input paramater to this method
     * @return String with information about the API Response. 
     */
   public static String workOrderQuoteDetailsInfo(Sales_Order__c salesOrderRecord, Integer companyId, Integer profitCtrId, String employeeId){
    
       // EQAI_API_URL_Extensions__mdt getWorkOrderQuoteDetailEQAIAPIURLExtensions = EQAI_API_URL_Extensions__mdt.getInstance('getWorkOrderQuoteDetailInfo');
       // ticket # 80209
       EQAI_API_URL_Extensions__mdt getWorkOrderQuoteDetailEQAIAPIURLExtensions = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getWorkOrderQuoteDetailInfo'];
        map<String,String> resource_Type_EQIMap = new map<String,String>();
        map<String,String> bill_Unit_Code_EQIMap = new map<String,String>();
       
        try{
           
            //reterving the data from the Sales_Line_EQAI_Mapping__mdt Custom metadata and storing them in a map so that we can send the salesforce equivalent value to EQAI system.
            for(Sales_Line_EQAI_Mapping__mdt salesLineEQIMappingRecord : [select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,Salesforce_Field_Value__c from Sales_Line_EQAI_Mapping__mdt  ]){
                if(salesLineEQIMappingRecord.EQAI_Field_Name__c =='resource_type'){
                    resource_Type_EQIMap.put(salesLineEQIMappingRecord.Salesforce_Field_Value__c ,salesLineEQIMappingRecord.EQAI_Field_Value__c);
                }
                else if(salesLineEQIMappingRecord.EQAI_Field_Name__c =='bill_unit_code'){
                    bill_Unit_Code_EQIMap.put(salesLineEQIMappingRecord.Salesforce_Field_Value__c ,salesLineEQIMappingRecord.EQAI_Field_Value__c);
                }
            }
            
            //creating the JSON body in a array format to send it to EQI System           
            list<WorkOrderQuoteDetailsJSON> QuoteDetailsList = new list<WorkOrderQuoteDetailsJSON>();
            for(Sales_Line__c salesLineRecord : salesOrderRecord.Sales_Lines__r){
                
                WorkOrderQuoteDetailsJSON QuoteDetailsRecord = new WorkOrderQuoteDetailsJSON(salesLineRecord, profitCtrId, companyId, resource_Type_EQIMap, bill_Unit_Code_EQIMap,employeeId);
                QuoteDetailsList.add(QuoteDetailsRecord);
           }
           
            System.debug('body: '+ System.Json.serialize(QuoteDetailsList));
            String Response  = getPostCalloutResponseContents(getWorkOrderQuoteDetailEQAIAPIURLExtensions.API_Extension__c, System.Json.serialize(QuoteDetailsList),'POST',getWorkOrderQuoteDetailEQAIAPIURLExtensions.API_Key__c,getWorkOrderQuoteDetailEQAIAPIURLExtensions.API_Token__c);
            if(Response!='200'){
               // createCaseWithParentId(salesOrderRecord.Id,'Error in Work order Detail',splitSuccessMessage(Response),Json.serialize(QuoteDetailsList));
                 ErrorHandlingController.parseJSON(salesOrderRecord.Id,Response, 'Error in Work order Detail', 'EQAI-WOQ Error','Medium');
            
            }
            return Response;
        }catch(Exception e){
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return e.getMessage();
        }        
    }

    public static void createCaseWithParentId(string parentId,String subject,String caseDescription,String httpRequest) {
       try
        {
        Group newCaseQueue = [SELECT Id FROM Group WHERE Type = 'Queue' and Name = 'Case Owners'];
        Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Record').getRecordTypeId();
        Case newCase = new Case();
        newCase.Subject = subject;
        newCase.RecordTypeId = recordTypeId;
        newCase.Description = (splitSuccessMessage(caseDescription).length()>32000)?splitSuccessMessage(caseDescription).substring(0,32000):splitSuccessMessage(caseDescription);
        //newCase.Error_Description__c = (splitSuccessMessage(caseDescription).length()>131000)?splitSuccessMessage(caseDescription).substring(0,131000):splitSuccessMessage(caseDescription);
        //newCase.Http_Request__c = httpRequest;
        newCase.Reason = 'EQAI-WOQ Error'; 
        if(parentId.substring(0,3) == '003')
        {
            newCase.ContactId = parentId;
            newCase.Reason = 'Contact Sync Issue';
        }
             
        else
        	newCase.Sales_Order_Number__c = parentId; 
       
        
        newCase.Priority = 'Medium';    
        newCase.OwnerId = newCaseQueue.Id; 
        insert newCase;
        System.debug('Case created successfully with Id: ' + newCase.Id);
        }Catch(Exception ex)
        {
            System.Debug('Error::'+ex.getMessage());
        }
    }    

     public Static string splitSuccessMessage(String message)
     {
        List<String> messages = message.split(';');
         String generalErrorMessage = messages.remove(0);
         String finalErrorMessage = generalErrorMessage + '\n';
         for(Integer i = 0; i < messages.size(); i++) {
             finalErrorMessage += '('+(i+1)+')' + '.' + messages[i];
             if(i < messages.size() - 1) {
                 finalErrorMessage += '\n';
             }
         } 
         System.debug(finalErrorMessage);
         return finalErrorMessage; 
         //return null;
     }
    
   public static String executeTransactionCompleteCallout(String endPointURL, String methodType , String Key, String Token) {
            
        try{
            HttpRequest req = new HttpRequest();
           /* if(UserInfo.getUserId().equals('0058H000005YqOZQA0') || UserInfo.getUserId().equals('0058H000005YqOUQA01')){
            	req.setEndpoint('callout:EQAI_Prod_Base_URL'+endPointURL);    
                Key = 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1TbKPKhNZF13MhY6P6SekPXiMXemjdomTzxFmdvMkklejIFtqdZB8fndTjpWY9jLXXnSBz76XG9avpj9PHsc6EE68OTTYaU89TO4Y4hUkT9poIZjqGc29k447lWH1s6ZjG4bkNtlqk/tnq3XUYIyU688ISv3jIW/s3NDyRCat4n5oqnHmtx6aTSLfgIs61aqjVu6xTAbVt86tB095zEoJaCNDMXXrqusDKrIEbMr9YYZJyo4SugZVWwq7c1Cy/iElADNoYf+E1h814b0o/IlbzmvYjwu0WZTPgxtMdSJYRymqe8k8xWwCbWUHr+yTDK8L7gIDdVdjbX7P7J1Uu3TVQIDAQAB';
                Token = 'eyJvcmdpbiI6IkhTMjU2IiwidHlwIjoiSldUIn0.eyJzdWIiOiJDUk0ifQ.8MHUchX7WDu1lO87rZ358sRMmDkIyx3rz5G-jTpZxJY';
            }
            else{
                req.setEndpoint('callout:EQAI_Base_URL'+endPointURL);
                
            }*/
            req.setEndpoint('callout:EQAI_Base_URL'+endPointURL);
            req.setHeader('x-api-key',Key);
            req.setHeader('x-secret-token',Token);
            
            req.setHeader('Content-Type','application/json');
            req.setMethod(methodType);
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
        
   }
    public static boolean containsWasteDisposalSalesLine(Sales_Order__c orderRecord) {
        System.debug('inside waste disposal method**********************');
        boolean wasteDisposal = false;
        for(Sales_Line__c line : orderRecord.Sales_Lines__r){
            if(line.Category__c == 'Waste Disposal'){
                wasteDisposal = true;
                break;
            }
        }
		System.debug('waste disposal boolean value::::::::::::::::::::::::::::::::::::::::::'+ wasteDisposal);
        return wasteDisposal;
    }
    
    public static boolean containsWasteDisposalInvoiceLine(Sales_Invoice__c  orderRecord) {
       /* //String SOId = 'a0uW4000000AXcDIAW';
        boolean wasteDisposal = false;
        //List<Sales_Line__c >lines = [select id,Billing_Type__c, Category__c, Description__c,Sales_Order__c, Sales_Order__r.Service_Center__r.Name, Sales_Order__r.Service_Center__r.Advanced_Disposal__c from Sales_Line__c where  Sales_Order__c =:orderRecord.Id];
        for(Sales_Line__c line : orderRecord.Sales_Lines__r){
            if(line.Category__c == 'Waste Disposal'){
                wasteDisposal = true;
                break;
            }
        }
		System.debug( wasteDisposal);
        return wasteDisposal;*/
        return false;
    }

}