/******************************************************************************************************************
* Name         :  CustomNotesAndAttachment 
* Description  :  Class to handle customNotesAndAttachment LWC component logics.
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Vignesh Kumar N         12-19-2024             US135128: Initial Version - getObjectInfo and fetchUploadedFiles
* Vignesh Kumar N         12-31-2024             US135129: Levels of Authority Documentation - Contract - Added else if
***********************************************************************************************************************/
public class CustomNotesAndAttachment {
    
    @AuraEnabled(cacheable=True)
    public static Map<String, String> getObjectInfo(Id recordId) {
        
        if (recordId == null) {
            return null;
        }
        try {
            Map<String, String> objectInfo = new Map<String, String>();
            String sObjName = recordId.getSObjectType().getDescribe().getName();  
            String recordName;
            
            if (sObjName == 'Sales_Order__c') {
                recordName = [SELECT Name FROM Sales_Order__c WHERE Id =: recordId].Name;                
            } else if (sObjName == 'Contract') {	//US135129
                recordName = [SELECT ContractNumber FROM Contract WHERE Id =: recordId].ContractNumber;     
            }
            
            objectInfo.put('recordName', recordName);
            objectInfo.put('objectApiName', recordId.getSObjectType().getDescribe().getName());
            objectInfo.put('labelName', recordId.getSObjectType().getDescribe().getLabel());
            objectInfo.put('pluralName', recordId.getSObjectType().getDescribe().getLabelPlural());
            
            return objectInfo;
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static List<ContentVersion> fetchUploadedFiles(Id recordId) {  
        Set<Id> contentDocIds = new Set<Id>();
        
        try {
            for(ContentDocumentLink cntLink: [SELECT Id, ContentDocumentId 
                                              FROM ContentDocumentLink 
                                              WHERE LinkedEntityId =: recordId]) 
            {
                contentDocIds.add(cntLink.ContentDocumentId);
            }
            if(!contentDocIds.isEmpty()) {
                return [SELECT Id, ContentDocumentId, Title, FileExtension, Custom_N_A_fileupload__c ,
                        VersionData, ContentSize, CreatedDate, LastModifiedDate, Createdby.Name, CreatedById
                        FROM ContentVersion
                        WHERE ContentDocumentId IN :contentDocIds
                        AND Custom_N_A_fileupload__c != NULL AND IsLatest = true
                        ORDER BY LastModifiedDate DESC];
            } else {
                return null;
            }        
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}