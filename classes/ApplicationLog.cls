/*************************************************************************************************
* Name         :  ApplicationLog
* Description  :  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Pavithra P				07-23-2024			   US118581 - Salesforce - Add integration log 
***********************************************************************************************************/

public class ApplicationLog {
   public static Integer maxLength = 131072;
   public static List<ApplicationlogInformation> logRecordsList = new List<ApplicationlogInformation>();
    
    public static void startLog(String logInformation) {
        ApplicationlogInformation loginfo = (ApplicationlogInformation)JSON.deserialize(logInformation, ApplicationlogInformation.class);
        insertLog(loginfo);     
    }

    public static void insertLog(ApplicationlogInformation logData){
        Application_Debug_Log__c logReq = new Application_Debug_Log__c();
        
        logReq.Class_Name__c = logData.className;  
        logReq.Method_Name__c = logData.methodName;
        logReq.Endpoint__c = logData.endpoint; 
        logReq.Service_Request__c = prepareMessageForInsert(logData.serviceRequest,maxLength);
        logReq.Service_Response__c = prepareMessageForInsert(logData.serviceResponse,maxLength);        
        logReq.Exception_Message__c = prepareMessageForInsert(logData.message,maxLength);
        
        insert logReq;
        resetLog();
    }
    
    //Method to track bulk records
    public static void insertbulkLog(List<ApplicationlogInformation> logRecords){ 
        
        List<Application_Debug_Log__c> recordsToInsert = new List<Application_Debug_Log__c>();
        
        for(ApplicationlogInformation logData : logRecords){
            Application_Debug_Log__c logReq = new Application_Debug_Log__c();
            logReq.Class_Name__c = logData.className;  
            logReq.Method_Name__c = logData.methodName;
            logReq.Endpoint__c = logData.endpoint; 
            logReq.Service_Request__c = prepareMessageForInsert(logData.serviceRequest,maxLength);
            logReq.Service_Response__c = prepareMessageForInsert(logData.serviceResponse,maxLength);        
            logReq.Exception_Message__c = prepareMessageForInsert(logData.message,maxLength);
            logReq.Record_Id__c = logData.recordId;
            recordsToInsert.add(logReq);        
        }
        if(!recordsToInsert.isEmpty()){
            insert recordsToInsert;
        
        }
        resetLog();
    }
    public static void resetLog() {
        ApplicationlogInformation resetdata = new ApplicationlogInformation();
    }
    
    
    public static String prepareMessageForInsert(String customMessage, Integer maxLength){
         customMessage = (customMessage != null && customMessage.length() > maxLength)
                                      ?customMessage.substring(0,maxLength)
                                      :customMessage;
        return customMessage;   
    }

    public class ApplicationlogInformation{
    public String className;
    public String methodName;
    public String recordIds;
    public String serviceRequest;
    public String serviceResponse;
    public String endpoint;
    public String message;
    public String recordId;
    }
}