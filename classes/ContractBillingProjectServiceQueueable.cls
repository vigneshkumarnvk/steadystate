/*
* Class Name: ContractBillingProjectServiceQueueable
* Summary  : Apex class for Sending the contract details to EQAI

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Sathish Rosekumar           14/02/2024              75101 - Send Contract Details to EQAI
Shahwaz Khan                21/02/2024              Bug#78506 Billing project - Payment term value is missing in JSON which needs to send to EQAI from SF
Andrew Simons               04/03/2024              Added flag to track when integration to EQAI is successful
Sanjana 					05/04/2024              Requirement 80445: Salesforce - Update "SF Contract Billing Project" JSON
Sanjana						04/23/2024				Requirement 85160: Salesforce - Contract Level Billing Projects - PO Required Field - Pull from Salesforce Account
Sanjana						04/26/2024			    Requirement 84934: Salesforce - Update Contract Billing Project Data Mapping & JSON
Sanjana 					04/20/2024				Requirement 84934: Salesforce - Update Contract Billing Project Data Mapping & JSON
*************************************************************************************************************/
public class ContractBillingProjectServiceQueueable implements Queueable, Database.AllowsCallouts  {
    public  List<Id> contractIds;
    
    
    public ContractBillingProjectServiceQueueable(List<Id> contractIds){
        this.contractIds = contractIds;
    }
    public void execute(QueueableContext context) {
        if(this.contractIds.isEmpty()) {
            return;
        }     
        Id contractId= this.contractIds.remove(0);
        String requestJSON;
        String employeeId;
        try{ 
           // ticket 80209
         	employeeId = [SELECT RSG_EIN__c from User WHERE Id =: userinfo.getUserId() limit 1].RSG_EIN__c;
            EQAI_API_URL_Extensions__mdt getWOHeaderInfo = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getContractBillingInfo'];
			Contract contractRec = [SELECT Id, Name, AccountId, Account.Invoice_Submission_Channels__c, Payment_Term__c, 
                                    Payment_Term__r.EQAI_Terms_Code__c, Account.Sage_Customer_No__c, ContractNumber, CreatedDate, 
                                    LastModifiedDate,Contract_Billing_Project_created_in_EQAI__c, Account.PO_Number_Type__c,CreatedBy.Name,LastModifiedBy.Name,
                                    Internal_Comments__c,Account.Account_Executive__r.Territory_Code__c,
                                    Account.Account_Executive__r.Internal_Contact__c,Account.Account_Executive__r.RSG_EIN__c,Account.Invoice_Portal__c,
                                    (SELECT Id, Contact__c from Sales_Invoices__r ORDER BY CreatedDate DESC Limit 1)
								    FROM Contract WHERE Id = :contractId];
    	 	Contact billToContact = new Contact();
            List<Sales_Invoice__c> salesInvoice = [SELECT Id,Contact__c FROM Sales_Invoice__c WHERE Bill_to_Customer__c = :contractRec.AccountId AND Document_Status__c = 'Sent to EQAI' ORDER BY LastActivityDate DESC LIMIT 1];
            if(!salesInvoice.isEmpty())
            	billToContact = [SELECT Id, Name, Email FROM Contact WHERE Id = :salesInvoice[0].Contact__c LIMIT 1];
            ContractBillingProjectJSON contractBillingJson = new ContractBillingProjectJSON(contractRec,employeeId,billToContact);
            requestJSON = String.valueOf(contractBillingJson);
            System.debug('contractBillingJson++'+System.Json.serialize(contractBillingJson));
            String response = WorkOrderQuoteService.getPostCalloutResponseContents(getWOHeaderInfo.API_Extension__c, System.Json.serialize(contractBillingJson),'POST',getWOHeaderInfo.API_Key__c,getWOHeaderInfo.API_Token__c);
            System.debug('response ++'+response);
            contractRec.Contract_Billing_Project_created_in_EQAI__c = true;
            update contractRec;
            if(response!='200'){
                createCaseWithParentId(contractRec.Id,'Error in Contract Billing Project',splitSuccessMessage(response),Json.serialize(contractBillingJson));               
            }
        }
        
        Catch(Exception e){
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());            
            insertErrorLog(contractId,string.valueOf(e.getMessage()),e.getLineNumber(),string.valueOf(e.getCause()),requestJSON); 
            
        }
        
        if(contractIds.size()>0){
            System.enqueueJob(new ContractBillingProjectServiceQueueable(contractIds));
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