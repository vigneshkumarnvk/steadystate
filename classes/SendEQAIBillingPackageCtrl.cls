/******************************************************************************************************
* Class Name: SendEQAIBillingPackageCtrl
* Description: It will send Sales Invoice and Invoice Lines to EQAI when user submit [Submit EQAI Billing Package]
* 				button on SalesInvoice.
* ***************************************************************************************************
* Owner		        Task #			Date		Descriptoin
* Vennila P	        73779, 73777    12/13/2023	Sending SalesInvoice and LineItems to EQAI

* Shahwaz Khan 	    75277           12/15/2023	Added validations when "Submit EQAI Billing Package" Button is pressed
* Sanjana	 	    63067           01/08/2024	Updated the logic to send true when workOrderDetailInfo is Success
* Shahwaz Khan      77453           02/07/2024  Error Handling - Salesforce - Detailed error message to be received from EQAI & create pop up error message in Salesforce (SIL integration)
* Prabhu Rathakrishnan      81966   03/19/2024  Salesforce Billing Package Should Not Be Sent to EQAI Work Order Without D365 Project ID on Sales Order in Salesforce
* Andrew Simons     83176           04/15/2024  Salesforce Billing Package is blocked on days 0-2 of month end close each month
* Prabhu Rathakrishnan              05-14-2024  Task83367: Salesforce API - Create Fully Transactional Salesforce and EQAI Integration API's
* Pavithra P				        08-05-2024	US118581 - Salesforce - Add integration log 
* Prabhu Rathakrishnan              09/09/2024  US121824: Salesforce - Billing Project lookup on Sales Order
* Shahwaz Khan                      10/30/2024  US129137: Disposal UOM on SF disposal line(s) must align to selected profile approval
* Sanjana Ravichandran 				11/11/2024	US129734: SF - Attachments call update(s) Single JSON for Billing Package integration
* Sanjana Ravichandran				11/21/2024  US129137: Removed the UOM validation
* Sanjana Ravichandran 				12/04/2024	Added Customer POValidation null check
* ******************************************************************************************************/
public class SendEQAIBillingPackageCtrl {
    @AuraEnabled
    public static String getSalesInvoice(Id salesInvoiceId) {
        try {
            Sales_Invoice__c salesInvoice =[SELECT ID,Sales_Order__c,Sales_Order__r.SO_sent_to_EQAI__c,Document_Status__c,Sales_Order__r.EQAI_Billing_Project_Id__c,
                                            Sales_Order__r.JB_Sent_to_EQAI__c,BP_Sent_to_EQAI__c,Bill_to_Customer__r.Invoice_Submission_Channels__c,Bill_to_Customer__r.MSG__c,Bill_to_Customer__r.Retail__c,Bill_to_Customer__r.National_Account__c,Bill_to_Customer__r.Prevent_Billing_Project__c,Customer_PO_No__c   
                                            from Sales_Invoice__c where Id=:salesInvoiceId ];
            return JSON.serialize(salesInvoice);
        }
        catch(Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static string sendSalesInvoiceToEQAI(Id recordId) {
        CompanyMgmt.systemCall = true;
        try { 
            List<Sales_Invoice__c> salesInvoice = [SELECT ID,Bill_to_Customer__c,Service_Center__c,Sales_Order__r.D365_Project_ID__c,Approval_Status__c,Document_Status__c,Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c,Bill_to_Customer__r.Prevent_Billing_Project__c   from Sales_Invoice__c where Id=:recordId order by createddate DESC limit 1];
            Company_Setup__c companySetup = [SELECT Month_End_Close_Start_Date__c, Month_End_Close_End_Date__c FROM Company_Setup__c LIMIT 1];
            
            Datetime currentDateTime = Datetime.now();
            
            /// Check if the current date/time falls between Month End Start Date and End Date
            if (currentDateTime >= companySetup.Month_End_Close_Start_Date__c && currentDateTime <= companySetup.Month_End_Close_End_Date__c) {
                return 'Submitting Billing Package is blocked due to Month End Closing.';
            } 
            
            // Implemented as part of 75277
            if(salesInvoice[0].Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == False){
                return 'Service Center Disabled';
            }
            else if(salesInvoice.size()>0 && salesInvoice[0].Sales_Order__r!=null && (salesInvoice[0].Sales_Order__r.D365_Project_ID__c==null || salesInvoice[0].Sales_Order__r.D365_Project_ID__c=='')){
                return 'D365_Project_ID is null';
            }
            else if(salesInvoice.size()>0 && salesInvoice[0].Id != Null && salesInvoice[0].Document_Status__c == 'Sent to EQAI')
            {
                return 'Sent to EQAI';
            }
            else if (salesInvoice.size()>0 && salesInvoice[0].Id != Null && salesInvoice[0].Approval_Status__c != 'Approved'){
                return 'Not Approved';
            }
            // Implemented as part of 73777
            else if(salesInvoice.size()>0 && salesInvoice[0].Id != Null && salesInvoice[0].Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == True)
            {
                SalesInvoiceWorkOrderService.workOrderHeaderInfo(salesInvoice[0].Id);
                if(SalesInvoiceWorkOrderService.successMessage != 'True')
                {
                    String str = splitSuccessMessage(SalesInvoiceWorkOrderService.successMessage);
                    // return str;
                    return 'This Billing Package failed integrating to EQAI. Your Salesforce Administrator has been notified and will contact you shortly';
                }
                else{
                    //Sales_Invoice__c updateSalesInvoice = new Sales_Invoice__c(Id=recordId,BP_Sent_to_EQAI__c=true);
                    // update updateSalesInvoice; 
                    return SalesInvoiceWorkOrderService.successMessage;       
                }
                
            }
            else 
                return 'False';
            
        }
        catch(exception ex) {
            System.Debug('Error::'+ex.getMessage());
            System.Debug('Error::'+ex.getLineNumber());            
            throw ex;
        }
    }
    
    @AuraEnabled
    public static String updateDocumentTypeID(Id salesInvoiceId, Id salesOrderId) {
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        try{
            logData.className =  'SendEQAIBillingPackageCtrl';
            logData.methodName = 'updateDocumentTypeID';
            String response = WorkOrderAttachmentInfo.jobLevelBillingInfo(salesInvoiceId);
            String convertedJobResponse = response.toLowerCase();
            logData.serviceRequest = 'updateDocumentTypeID Req >>' + salesInvoiceId;
            logData.serviceResponse = 'updateDocumentTypeID Res >>' + convertedJobResponse;
            logData.recordId = salesInvoiceId;
            ApplicationLog.startLog(JSON.serialize(logData));
            if(response == '200'){
                // Sales_Invoice__c objInvoice = new Sales_Invoice__c(Id = salesInvoiceId, Document_Status__c = 'Sent to EQAI'); 
                // update objInvoice; 
                Sales_Order__c salesOrder = new Sales_Order__c(Id= salesOrderId,JB_Sent_to_EQAI__c=true);
                update salesOrder;
            }else{
                if(convertedJobResponse.contains('billing project already exists')){
                    //  Sales_Invoice__c objInvoice = new Sales_Invoice__c(Id = salesInvoiceId, Document_Status__c = 'Sent to EQAI'); 
                    //  update objInvoice; 
                    Sales_Order__c salesOrder = new Sales_Order__c(Id= salesOrderId,JB_Sent_to_EQAI__c=true);
                    update salesOrder;
                }
            }
            return response;
            
        }catch(Exception e){
            logData.message = e.getMessage();
            ApplicationLog.startLog(JSON.serialize(logData));
            throw new AurahandledException('Please try again after sometimes');
        }
    }
    @AuraEnabled
    public static void updateStatusInSalesOrder(Id salesInvoiceId) {
        ApplicationLog.ApplicationlogInformation logData = new ApplicationLog.ApplicationlogInformation();
        String response = ''; 
        Boolean wasteDisposal = false;
        
        try {
            logData.className = 'SendEQAIBillingPackageCtrl';
            logData.methodName = 'updateStatusInSalesOrder';
            logData.recordId = salesInvoiceId;
            
            // Fetch Sales Invoice to check if it's a waste disposal
            Sales_Invoice__c salesInvoice = [
                SELECT Id, Service_Center__r.Advanced_Disposal__c 
                FROM Sales_Invoice__c 
                WHERE Id = :salesInvoiceId 
                LIMIT 1
            ];
            
            // Check if it has advanced disposal enabled
            if (salesInvoice.Service_Center__r.Advanced_Disposal__c) {
                wasteDisposal = containsWasteDisposalInvoiceLine(salesInvoiceId);
            }
            
            // Prepare the Sales Invoice object for updating (without updating yet)
            Sales_Invoice__c objInvoice = new Sales_Invoice__c(
                Id = salesInvoiceId, 
                Document_Status__c = 'Sent to EQAI', 
                BP_Sent_to_EQAI__c = true, 
                Sent_to_EQAI_Date__c = DateTime.now()
            );
            
            if (!wasteDisposal) {
                // Callout for Waste Disposal
                response = WorkOrderAttachmentInfo.executeTransactionCompleteCallout(salesInvoiceId);
                
                if (response == '200' || response.contains('SUCCESS') || Test.isRunningTest()) {
                    update objInvoice;
                    
                    List<Sales_Invoice__c> salesInvoiceList = [
                        SELECT Id, Sales_Order__r.Id 
                        FROM Sales_Invoice__c 
                        WHERE Id = :salesInvoiceId 
                        AND Sales_Order__r.Site_Address_Changed__c = true
                        LIMIT 1
                    ];
                    
                    if (!salesInvoiceList.isEmpty() && String.IsNotBlank(salesInvoiceList[0].Id)) {
                        Sales_Order__c objSalesOrder = new Sales_Order__c(); 
                        objSalesOrder.Id = salesInvoiceList[0].Sales_Order__r.Id;
                        objSalesOrder.Site_Address_Changed__c = false;
                        update objSalesOrder;  
                    }
                } else {
                    SalesInvoiceWorkOrderService.createCaseWithParentId(salesInvoiceId, 'Error in WO Complete Transaction API', response, null);
                }
            } else {
                update objInvoice;
                List<Sales_Invoice__c> salesInvoiceList = [
                    SELECT Id, Sales_Order__r.Id 
                    FROM Sales_Invoice__c 
                    WHERE Id = :salesInvoiceId 
                    AND Sales_Order__r.Site_Address_Changed__c = true
                    LIMIT 1
                ];
                
                if (!salesInvoiceList.isEmpty() && String.IsNotBlank(salesInvoiceList[0].Id)) {
                    Sales_Order__c objSalesOrder = new Sales_Order__c(); 
                    objSalesOrder.Id = salesInvoiceList[0].Sales_Order__r.Id;
                    objSalesOrder.Site_Address_Changed__c = false;
                    update objSalesOrder;  
                }
            }
            
            logData.serviceRequest = 'updateStatusInSalesOrderReq >>' + salesInvoiceId;
            logData.serviceResponse = 'updateStatusInSalesOrderRes >>' + response;
            ApplicationLog.startLog(JSON.serialize(logData));
            
        } catch (Exception e) {
            logData.message = e.getMessage();
            ApplicationLog.startLog(JSON.serialize(logData));
            
            throw new AurahandledException('An error occurred while updating the status in the Sales Order: ' + e.getMessage());
        }
    }
    //Task#77453
    public Static string splitSuccessMessage(String successMsg)
    {
        List<String> errorMessageParts = successMsg.split(';');
        String generalErrorMessage = errorMessageParts.remove(0);
        String finalErrorMessage = generalErrorMessage + '\n';
        for(Integer i = 0; i < errorMessageParts.size(); i++) {
            finalErrorMessage += '('+(i+1)+')' + '.' + errorMessageParts[i];
            if(i < errorMessageParts.size() - 1) {
                finalErrorMessage += '\n';
            }
        } 
        System.debug(finalErrorMessage);
        return finalErrorMessage; 
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
    @AuraEnabled
    public static void validatePONumber(String accountId, String poNumber) {
        if (String.isNotBlank(poNumber)) {
            Account account = [SELECT Id, Name, PO_Number_Type__c, PO_Required__c
                               FROM Account WHERE Id =: accountId];
            AccountsService.validatePONumberFormat(account, poNumber); 
        }
    }
}