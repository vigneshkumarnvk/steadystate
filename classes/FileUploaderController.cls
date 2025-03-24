public with sharing class FileUploaderController {
    @AuraEnabled
    public static void updateTitle(Id tmId, Id documentId) {
        Savepoint sp = Database.setSavepoint();
        try {
            TM__c tm = [SELECT Id, Name FROM TM__c WHERE Id = :tmId LIMIT 1];
            List<ContentVersion> contentVersions = [SELECT Id, Title, Type_fileupload__c, PathOnClient FROM ContentVersion WHERE ContentDocumentId = :documentId AND Type_fileupload__c != NULL];
            if (contentVersions.size() > 0) {
                ContentVersion contentVersion = contentVersions[0];
                String type = contentVersion.Type_fileupload__c;
                String filename = contentVersion.PathOnClient;
                String title = type.replaceAll(' ', '_') + '_' + tm.Name + '%';
                String fileExt = '';
                Integer pos = fileName.lastIndexOf('.');
                if (pos > 0) {
                    fileExt = fileName.substring(pos);
                }

                Integer nextSequenceNo = 0;
                List<ContentDocument> contentDocuments = [SELECT Id, Title FROM ContentDocument WHERE Title LIKE :title ORDER BY Title DESC];
                for (ContentDocument contentDocument : contentDocuments) {
                    pos = contentDocument.Title.lastIndexOf('_');
                    if (pos > 0) {
                        String num = contentDocument.Title.substring(pos + 1);
                        pos = num.lastIndexOf('.');
                        if (pos > 0) {
                            num = num.substring(0, pos);
                        }
                        if (num.isNumeric()) {
                            nextSequenceNo = Integer.valueOf(num);
                            break;
                        }
                    }
                }
                nextSequenceNo++;


                contentVersion.Title = type.replaceAll(' ', '_') + '_' + tm.Name + '_' + String.valueOf(nextSequenceNo) + fileExt;
                update contentVersion;
            }
        }
        catch (exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
    @AuraEnabled
    public static void appendContentVersion(Id contentVersionId, String base64Data) {
        try {
            ContentVersion contentVersion = [SELECT Id, VersionData FROM ContentVersion WHERE Id = :contentVersionId LIMIT 1];
            String versionData = EncodingUtil.base64Encode(contentVersion.VersionData);
            contentVersion.VersionData = EncodingUtil.base64Decode(versionData + base64Data);
            update contentVersion;
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static List<ContentDocumentLink> getContentDocumentLinks(String JSONLinkedEntityIds) {
        try {
            List<String> linkedEntityIds = (List<String>)JSON.deserialize(JSONLinkedEntityIds, List<String>.class);
            return [SELECT Id, ContentDocument.Title, ContentDocument.Description FROM ContentDocumentLink WHERE LinkedEntityId IN :linkedEntityIds];
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    */


}