/*
* Class Name: SFJobBillingProjectJSONParsing
* Summary  : Dynamic class for JSON parsing

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Shahwaz Khan                16/04/2024              Job Level Billing Project.//Case Creation error fix(Description)
*************************************************************************************************************/
public class ErrorHandlingController {
    public static String parseJSON(String recordIdKey,String jobBillingResponse,String caseSubject,String reason,String priority)
    {
        try
        {
            Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeuntyped(jobBillingResponse);
            if(responseMap.get('status') != 200){
                Set<Id> salesOrderCSId = new Set<Id>();
                Map<String,String> CSIDToErrorMessageMap = new Map<String,String>();
                List<Case> casesToInsert = new List<Case>();
                List<Object> details = (List<Object>) responseMap.get('details');
                Case errorCase = new Case();
                String errorMsg='';
                String recordId;
                for(Object detailObj : details){
                    Map<String,Object> resultObj = (Map<String,Object>) detailObj;
                    Boolean isSuccess = (Boolean)resultObj.get('isSuccess');
                    if(!isSuccess){
                        errorMsg =errorMsg + splitSuccessMessage((String)resultObj.get('statusMessage'))+'\n';                        
                     if(resultObj.containsKey(recordIdKey))
                         recordId = (String)resultObj.get(recordIdKey);
                     else
                         recordId = recordIdKey;
                    }
                }
                errorCase = createMultipleCaseWithParentId(recordId,caseSubject,errorMsg,reason,priority);
                casesToInsert.add(errorCase);
                if(casesToInsert.size()>0){
                    insert casesToInsert;
                }  
                
                 return errorMsg;
            }
            else
            {
                System.debug('Intigration Successful::'+jobBillingResponse);
                return 'Success';
            }
           
        }
        Catch(Exception e)
        {
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());            
        }
        return null;
    }
    
    
    public static Case createMultipleCaseWithParentId(Id recordId,String subject,String caseDescription,String reason,String priority) {
        try
        {
            Schema.SObjectType sobjectType = recordId.getSObjectType();
            String sobjectName = sobjectType.getDescribe().getName();

            Group newCaseQueue = [SELECT Id FROM Group WHERE Type = 'Queue' and Name = 'Case Owners'];
            Id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Case_Record').getRecordTypeId();
            Case newCase = new Case();
            newCase.Subject = subject;
            newCase.RecordTypeId = recordTypeId;
            newCase.Description = (splitSuccessMessage(caseDescription).length()>32000)?splitSuccessMessage(caseDescription).substring(0,32000):splitSuccessMessage(caseDescription);
           // newCase.Http_Request__c = httpRequest;
            if(sobjectName =='Sales_Order__c')
                newCase.Sales_Order_Number__c = recordId; 
            if(sobjectName =='Sales_Invoice__c')
                newCase.Billing_Package__c = recordId;
            newCase.Reason = reason; 
            newCase.Priority = priority;    
            newCase.OwnerId = newCaseQueue.Id; 
            return newCase;
        }Catch(Exception ex)
        {
            return null;
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
    }
}