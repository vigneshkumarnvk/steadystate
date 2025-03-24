/******************************************************************************************************************
* Name         :  DataUploadHandler 
* Description  :  Handles record upload logics for BatchDataUpload class.
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vignesh Kumar N         01-15-2024             Initial Version
***********************************************************************************************************************/
public with sharing class DataUploadHandler {
    
    public static Map<Integer, String> csvRecMap;
    
    @AuraEnabled
    public static String executeDataUploadBatch(Id recordId, Id contVerId, String objectName) {
        try {            
            ContentVersion contVersion =  [SELECT Id, Title, FileExtension, FileType, VersionData
                                           FROM ContentVersion WHERE Id =:contVerId];
            
            //FileType check before passing to batch class.
            if (contVersion == NULL || contVersion.FileExtension != 'csv' || 
                contVersion.FileType != 'CSV' || contVersion.VersionData == NULL) 
            {
                return null;
            } else {
                String csvFileContent = contVersion.VersionData.toString();
                List<String> csvRecordList = csvFileContent.split('\n');
                csvRecordList.remove(0);	//remove ColumnName
                if (csvRecordList.isEmpty()) {
                    return 'Empty';
                }
                Integer batchSize = Integer.valueOf(BatchSettings__mdt.getInstance('uploadContractLineBatchSize').value__c);
                Id jobId = Database.executeBatch(new BatchDataUpload(recordId, objectName, csvFileContent, contVersion.Title), batchSize);
                return jobId;    
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    //Query Custom Metadata based on Object Name for CSV Column Name and Object Field Name Mapping
    public static Map<String, String> getCSVFieldMapping(String objectApiName) {
        Map<String, String> csvColumnFieldMap = new Map<String, String>();
        try {
            for (Data_Upload__mdt dataUpload: [SELECT Id, Object_API_Name__c, Label, Column_Name__c, DeveloperName 
                                               FROM Data_Upload__mdt
                                               WHERE Object_API_Name__c =: objectApiName
                                               AND Column_Name__c != NULL]) 
            {            
                csvColumnFieldMap.put(dataUpload.Column_Name__c.toLowerCase(), dataUpload.Label) ;
            }                
        } catch (Exception e) {
            String request = 'ClassName: DataUploadHandler, MethodName: getCSVFieldMapping';
            String response = 'Cause: '+e.getCause();
            DataUploadHandler.insertErrorLog(request, response, e.getMessage(), objectApiName,'' , 
                                             e.getStackTraceString(), e.getLineNumber(), e.getTypeName());
        }
        return csvColumnFieldMap;
    }   
    
    //Get field dataType dynamically by passing field Name
    public static Map<String, Schema.DisplayType> getFieldDataType(String objectName) {
        Map<String, Schema.DisplayType> fieldDataType = new Map<String, Schema.DisplayType>();       
        try {
            
            Map <String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            Schema.SObjectType sobjType = globalDescribe.get(objectName);
            Schema.DescribeSObjectResult describeResult = sobjType.getDescribe();
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap();
            for(String fieldName : fieldMap.keySet()) 
            {
                Schema.SObjectField field = fieldMap.get(fieldName);
                Schema.DescribeFieldResult describeField = field.getDescribe();
                fieldDataType.put(describeField.getName().toLowerCase(), describeField.getType());
            }
            
        } catch (Exception e) {
            String request = 'ClassName: DataUploadHandler, MethodName: getFieldDataType';
            String response = 'Cause: '+e.getCause();
            DataUploadHandler.insertErrorLog(request, response, e.getMessage(), '','' , 
                                             e.getStackTraceString(), e.getLineNumber(), e.getTypeName());
        }
        return fieldDataType;
    }
    
    //Maps csv row values with contract Line Object
    public static List<sObject> mapContractLineCsvRecords(Map<String, String> csvColumnFieldMap,
                                                          Map<String, Schema.DisplayType> sObjectFieldDataTypeMap,
                                                          List<List<String>> csvRecordList, String objectName, 
                                                          String recordId, List<String> csvColumnNameList,
                                                          List<String> records) 
    {        
        csvRecMap = new Map<Integer, String>();
        Map<String, sObject> sObjectMap = new Map<String, sObject>();
        Set<String> uniqueCompositeKeySet = new Set<String>();
        Integer j = 0, index = 0;
        //Get existing records and creating composite key at run-time. Used regex to replace zeros in the currency field
        for (Contract_Line__c ctrctLine : [SELECT Id, Resource_Type__c, Unit_of_Measure__c,
                                           Customer_Item_No__c, Regular_Rate__c
                                           FROM Contract_Line__c WHERE Contract__c =: recordId])
        {
            String resourceType = ctrctLine.Resource_Type__c != null ? String.valueOf(ctrctLine.Resource_Type__c) : '';
            String unitOfMeasure = ctrctLine.Unit_of_Measure__c != null ? String.valueOf(ctrctLine.Unit_of_Measure__c) : '';
            String customerItemNo = ctrctLine.Customer_Item_No__c != null ? (ctrctLine.Customer_Item_No__c) : '';
            String regularRate = ctrctLine.Regular_Rate__c != null ? 
                String.valueOf(ctrctLine.Regular_Rate__c)?.replaceAll('\\.0|0$','') : ''; //Eg: 22.60 = 22.6, 22.00 = 22
            
            uniqueCompositeKeySet.add(resourceType + unitOfMeasure + customerItemNo + regularRate);            
        }
        
        SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        
        while (csvRecordList.size() > 0) {
            SObject newSobjectRecord = objectType.newSObject();
            List<String> csvRowValues = csvRecordList.remove(0);
            // Read each value, matching it up to the correct field
            // based on the position of the value in the row
            if (csvRowValues.size() > 0) {
                //Creates value by combining multiple values.
                String uniqueString = csvRowValues[0]+csvRowValues[2]+csvRowValues[3]+csvRowValues[5];
                if (! uniqueCompositeKeySet.contains(uniqueString)) { //check with the unique value to skip duplication
                    Boolean hasKey = sObjectMap.containsKey(uniqueString); 
                    for (Integer i = 0; i < csvColumnNameList.size(); i++) {
                        String fieldName = csvColumnFieldMap.get(csvColumnNameList.get(i).toLowerCase());
                        Schema.DisplayType fieldDataType = sObjectFieldDataTypeMap.get(fieldName.toLowerCase());
                        
                        if (objectName == 'Contract_Line__c') {
                            newSobjectRecord.put('Contract__c', recordId);
                        }
                        
                        if (String.isNotBlank(csvRowValues.get(i)) ) { 
                            
                            switch on fieldDataType {
                                when BOOLEAN {
                                    Boolean fieldValue = Boolean.valueOf(csvRowValues.get(i));
                                    newSobjectRecord.put(fieldName, fieldValue);
                                }
                                when DATE {
                                    Date fieldValue = Date.valueOf(csvRowValues.get(i));
                                    newSobjectRecord.put(fieldName, fieldValue);
                                }
                                when INTEGER {
                                    Integer fieldValue = Integer.valueOf(csvRowValues.get(i));
                                    newSobjectRecord.put(fieldName, fieldValue);
                                }
                                when CURRENCY, DOUBLE {	
                                    Decimal fieldValue = Decimal.valueOf(csvRowValues.get(i));
                                    newSobjectRecord.put(fieldName, fieldValue);
                                } 
                                when else {	//Id, String, Reference
                                    String fieldValue = String.ValueOf(csvRowValues.get(i));
                                    newSobjectRecord.put(fieldName, fieldValue);
                                } 
                            }
                        }
                        sObjectMap.put(uniqueString, newSobjectRecord); //Using Map to prevent duplicates in the same batch using unique col value.
                    }
                    if (! hasKey) {
                        csvRecMap.put(j, records.get(index)); //Used to store original csv after skipping non unique
                    }
                    j++;
                }
                index++;
            }            
        } 
        return sObjectMap.values();
    }
    
    public static void handleFinish(Database.BatchableContext bc, String csvFile, String csvFileName,
                                    Integer successCount, Integer failureCount, Integer totalRecordsCount, Id recordId) 
    {
        try {
            AsyncApexJob asynJob = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, 
                                    CreatedBy.Email,  CreatedBy.Name
                                    FROM AsyncApexJob WHERE Id =:bc.getJobId()];
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage(); 
            // Sets the paramaters of the email
            Set<String> toAddresses = new Set<String>{asynJob.CreatedBy.Email};
                if (System.label.UploadContractLineEmail != null) {
                    for (String emailAddr: System.label.UploadContractLineEmail.split(',')) {
                        toAddresses.add(emailAddr.deleteWhitespace());
                    }
                }
            email.setToAddresses(new List<String>(toAddresses));
            EmailTemplate emailTmplt;
            if (failureCount > 0 && successCount == 0) {		//If any of the records fail in DML
                emailTmplt = [SELECT Id, Name, Subject, HtmlValue FROM EmailTemplate
                              WHERE Name = 'Upload Contract Lines Failure Email Template' LIMIT 1];
                if (emailTmplt != NULL) {
                    Blob b = Blob.valueOf(csvFile);
                    //Create the email attachment
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName( csvFileName + '_Result.csv');
                    efa.setBody(b);
                    email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                    email.setSubject(emailTmplt.Subject);                          
                    emailTmplt.HtmlValue = emailTmplt.HtmlValue.replace('[User Name]', asynJob.CreatedBy.Name);
                    email.setHtmlBody(emailTmplt.HtmlValue); 
                }
            } else if (asynJob.TotalJobItems == asynJob.JobItemsProcessed && 
                       (totalRecordsCount == successCount || (failureCount == 0 && successCount > 0))) { //All records uploaded
                           emailTmplt = [SELECT Id, Name, Subject, HtmlValue 
                                         FROM EmailTemplate
                                         WHERE Name = 'Upload Contract Lines Success Email Template'
                                         LIMIT 1];
                           if (emailTmplt != NULL) {
                               email.setSubject(emailTmplt.Subject); 
                               Contract ctrct = [SELECT Name, ContractNumber FROM Contract WHERE Id =: recordId LIMIT 1];
                               emailTmplt.HtmlValue = emailTmplt.HtmlValue.replace('[User Name]', asynJob.CreatedBy.Name);
                               if (ctrct != null) {
                                   emailTmplt.HtmlValue = emailTmplt.HtmlValue.replace('[Contract Name]', ctrct.Name);
                                   emailTmplt.HtmlValue = emailTmplt.HtmlValue.replace('[Contract #]', ctrct.ContractNumber);
                               }
                               email.setHtmlBody(emailTmplt.HtmlValue); 
                           }
                       } else if (failureCount == 0 && successCount == 0) {
                           //Exception occured
                           return;
                       } else {
                           emailTmplt = [SELECT Id, Name, Subject, HtmlValue 
                                         FROM EmailTemplate
                                         WHERE Name = 'Upload Contract Lines Partial Success Email Template'
                                         LIMIT 1];
                           if (emailTmplt != NULL) {
                               Blob b = Blob.valueOf(csvFile);
                               //Create the email attachment
                               Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                               efa.setFileName( csvFileName + '_Result.csv');
                               efa.setBody(b);
                               email.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
                               email.setSubject(emailTmplt.Subject);                     
                               email.setHtmlBody(emailTmplt.HtmlValue);  
                           }
                       }        
            // Sends the email
            Messaging.SendEmailResult [] r = 
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        } catch (Exception e) {
            String request = 'ClassName: BatchDataUpload, MethodName: finish, Contract Id: '+recordId+', JobId: '+bc.getJobId();
            String response = 'Cause: '+e.getCause();
            insertErrorLog(request, response, e.getMessage(), 'Contract_Line__c', '', 
                           e.getStackTraceString(), e.getLineNumber(), e.getTypeName());
        }
    } 
    
    public static void insertErrorLog(String request, String response, String message, 
                                      String objectApiName, String recordId, String stackTrace,
                                      integer lineNumber, String errorType) 
    {
        insert new cwbtool__ErrorLog__c (
            Http_Request__c = request,
            Http_Response__c = message,
            cwbtool__Message__c = message,
            Object_Name__c = objectApiName,
            Record_Id__c = recordId,
            cwbtool__StackTrace__c = stackTrace,
            cwbtool__LineNumber__c = lineNumber,
            cwbtool__ErrorType__c = errorType
        );
    }
}