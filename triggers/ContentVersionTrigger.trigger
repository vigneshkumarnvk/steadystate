trigger ContentVersionTrigger on ContentVersion (before insert,after insert,before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            Set<Id> parentIds = new Set<Id>();
            Set<Id> contentDocumentIdSet = new Set<Id>();            
            for (ContentVersion contentVersion : Trigger.new) { 
                if (contentVersion.Title != null && contentVersion.Title.length() > 80) {
                    contentVersion.addError('Document type file name cannot exceed 80 characters.  Please rename the file to be 80 characters or less.');
                }
                
                //US135128 -Handles CustomNotesandAttachment - Upload New Version logic
                if (String.isNotBlank(contentVersion.Custom_N_A_fileupload__c) && 
                    contentVersion.Custom_N_A_fileupload__c.containsAny('-') &&
                    String.isNotBlank(contentVersion.Custom_N_A_fileupload__c.substringAfter('-'))) {                           
                        String customNAfileUploadValue = contentVersion.Custom_N_A_fileupload__c;
                        Id contentDocId = (Id)customNAfileUploadValue.substringAfter('-'); 
                        contentDocumentIdSet.add(contentDocId);                    
                    }               
            }
            
            
            Map<Id, ContentDocument> contentDocumentMap = new 
                Map<Id, ContentDocument>([SELECT Id, OwnerId FROM ContentDocument WHERE Id IN :contentDocumentIdSet]);
            
            if (!contentDocumentMap.isEmpty()) {
                for (ContentVersion contentVersion : Trigger.new) { 
                    Id existingContentDocumentId = (Id)contentVersion.Custom_N_A_fileupload__c.substringAfter('-');
                    if (contentDocumentMap.containsKey(existingContentDocumentId)) {
                        contentVersion.ContentDocumentId = existingContentDocumentId;
                        contentVersion.OwnerId = contentDocumentMap.get(existingContentDocumentId).OwnerId;
                        contentVersion.FirstPublishLocationId = null;
                    } 
                }
            }   //US135128    
        }
    }
    Set<Id> parentIds = new Set<Id>();
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            for (ContentVersion contentVersion : Trigger.new) { 
                if (contentVersion.Type_fileupload__c != null) {
                    Set<Id> linkedEntityIds = new Set<Id>();
                    for (ContentDocumentLink contentDocumentLink : [SELECT Id, ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :contentVersion.ContentDocumentId]) {
                        linkedEntityIds.add(contentDocumentLink.LinkedEntityId);
                    }
                    for (TM__c tm : [SELECT Id, Name FROM TM__c WHERE Id IN :linkedEntityIds]) {
                        FileUploaderController.updateTitle(tm.Id, contentVersion.ContentDocumentId);
                    }
                }
                if(contentVersion.FirstPublishLocationId != null){
                    Schema.SObjectType sobjectType = contentVersion.FirstPublishLocationId.getSObjectType();
                    String sobjectName = sobjectType.getDescribe().getName();
                    if(sobjectName == 'Sales_Invoice__c'){
                        parentIds.add(contentVersion.FirstPublishLocationId); 
                    } 
                }
                
            }
            if(parentIds.size()>0){
                FileUploadHandler.validateDocumentFileSize(parentIds,Trigger.new);
            }
        }
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        for(ContentVersion conVers:Trigger.new){
            if(conVers.IsAllow20__c){
                conVers.IsAllow20__c = false;
                conVers.addError('File cannot be uploaded it exceeds 20 mb');
            }
            if(conVers.IsAllow50__c){
                conVers.IsAllow50__c = false;
                conVers.addError('Total files cannot exceed 50 mb');
            }
            if(conVers.IsAllow1Mb__c){
                conVers.IsAllow1Mb__c = false;
                conVers.addError('Excel File cannot be uploaded it exceeds 985kb');
            }
        }
    }
}