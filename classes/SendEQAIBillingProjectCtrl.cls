public class SendEQAIBillingProjectCtrl {
    @AuraEnabled
    public static String sendBillingProjectToEQAI(Id contractId) {
        CompanyMgmt.systemCall = true;
        
        String requestJSON ='';
        try{ 
            String employeeId = [SELECT RSG_EIN__c from User WHERE Id =: userinfo.getUserId() limit 1].RSG_EIN__c;
            EQAI_API_URL_Extensions__mdt getWOHeaderInfo = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getContractBillingInfo'];
            Contract contractRec = [SELECT Id, Name, AccountId, Account.Invoice_Submission_Channels__c, Payment_Term__c, 
                                    Payment_Term__r.EQAI_Terms_Code__c, Account.Sage_Customer_No__c, ContractNumber, CreatedDate, 
                                    LastModifiedDate,Contract_Billing_Project_created_in_EQAI__c, Account.PO_Number_Type__c,CreatedBy.Name,LastModifiedBy.Name,
                                    Internal_Comments__c,Account.Account_Executive__r.Territory_Code__c,
                                    Account.Account_Executive__r.Internal_Contact__c,Account.Account_Executive__r.RSG_EIN__c,Account.Invoice_Portal__c,
                                    (SELECT Contact__r.Name, Contact__r.Email FROM Sales_Invoices__r LIMIT 1) FROM Contract WHERE Id = :contractId];
            Contact billToContact = [SELECT Id, Name, Email FROM Contact WHERE AccountId = :contractRec.AccountId ORDER BY LastActivityDate DESC LIMIT 1];
            ContractBillingProjectJSON contractBillingJson = new ContractBillingProjectJSON(contractRec,employeeId,billToContact);
            requestJSON = String.valueOf(contractBillingJson);
            System.debug('contractBillingJson++'+System.Json.serialize(getWOHeaderInfo));
            String response = WorkOrderQuoteService.getPostCalloutResponseContents(getWOHeaderInfo.API_Extension__c, System.Json.serialize(contractBillingJson),'POST',getWOHeaderInfo.API_Key__c,getWOHeaderInfo.API_Token__c);
            System.debug('response ++'+response);
            if(response == '200'){
                contractRec.Status = 'Activated';
                contractRec.Contract_Billing_Project_created_in_EQAI__c = true;
                update contractRec;  
            }else{
                createCaseWithParentId(contractRec.Id,'Error in Contract Billing Project',splitSuccessMessage(response),Json.serialize(contractBillingJson));               
            }
            return response;
            
        }
        
        Catch(Exception e){
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());            
            insertErrorLog(contractId,string.valueOf(e.getMessage()),e.getLineNumber(),string.valueOf(e.getCause()),requestJSON); 
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static void insertErrorLog(
        String contractId,String errorMessage,Integer lineNumber,
        String strackTrace,String request
    ){
        cwbtool__ErrorLog__c errorlog = new cwbtool__ErrorLog__c(Object_Name__c = 'Contract Billing Project', Record_Id__c = contractId, 
                                                                 Http_Response__c = errorMessage, cwbtool__LineNumber__c = decimal.valueOf(lineNumber),
                                                                 cwbtool__StackTrace__c = strackTrace, Http_Request__c = request);
        insert errorlog;
    }
    
    
    public static void createCaseWithParentId(Id parentId,String subject,String caseDescription,String httpRequest) {
        try{
            Group newCaseQueue = [SELECT Id FROM Group WHERE Type = 'Queue' and Name = 'Case Owners'];
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Record').getRecordTypeId();
            Case newCase = new Case();
            newCase.Subject = subject;
            newCase.RecordTypeId = recordTypeId;
            newCase.Description = caseDescription;
            newCase.Http_Request__c = httpRequest;
            newCase.Contract__c = parentId; 
            newCase.Reason = 'EQAI-Contract Error'; 
            newCase.Priority = 'Medium';    
            newCase.OwnerId = newCaseQueue.Id; 
            insert newCase;
            System.debug('Case created successfully with Id: ' + newCase.Id);
        }Catch(Exception ex)
        {
            System.Debug('Error::'+ex.getMessage());
        }
    }    
    
    public Static string splitSuccessMessage(String message){
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
    }
    
}