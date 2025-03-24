public with sharing class FileExplorerController {

    @AuraEnabled
    public static String getFiles(String recordId, String childRelationshipName) {
        try {
            Set<Id> linkedEntityIds = new Set<Id>{ recordId };
            Map<Id, SObject> mapRecordsById = new Map<Id, SObject>();

            String SObjectType = getSObjectTypeByPrefix(recordId);
            if (childRelationshipName != null) {
                Set<String> relationshipNames = new Set<String>();

                String childSObjectTpe;
                String parentFieldName;
                for (ChildRelationship relationship : Schema.getGlobalDescribe().get(SObjectType).getDescribe().getChildRelationships()) {
                    if (relationship.getRelationshipName() == childRelationshipName) {
                        childSObjectTpe = relationship.getChildSObject().getDescribe().getName();
                        parentFieldName = relationship.getField().getDescribe().getName();
                        break;
                    }
                }
                if (childSObjectTpe == null) {
                    throw new DataException('Invalid child record relationship name: ' + childRelationshipName);
                }
                String queryString = 'SELECT Id, Name FROM ' + childSObjectTpe + ' WHERE ' + parentFieldName + ' = :recordId';
                //System.debug('********* ' + queryString);
                for (SObject record : Database.query(queryString)) {
                    linkedEntityIds.add(record.Id);
                    mapRecordsById.put(record.Id, record);
                }
            }

            linkedEntityIds.add(recordId);
            String queryString = 'SELECT Id, Name FROM ' + SObjectType + ' WHERE Id = :recordId';
            for (SObject record : Database.query(queryString)) {
                mapRecordsById.put(record.Id, record);
            }

            /*
            Map<String, SObjectField> mapFieldsByName = Schema.getGlobalDescribe().get(SObjectType).getDescribe().fields.getMap();
            if (childRelationshipName != null) {
                for (String fieldName : mapFieldsByName.keySet()) {
                    SObjectField field = mapFieldsByName.get(fieldName);
                    DescribeFieldResult fieldResult = field.getDescribe();
                }
            }
            */
            Map<Id, List<ContentDocumentLink>> mapContentDocumentLinksByDocumentId = new Map<Id, List<ContentDocumentLink>>();
            Set<Id> contentDocumentIds = new Set<Id>();
            for (ContentDocumentLink contentDocumentLink : [SELECT Id, LinkedEntityId, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN :linkedEntityIds]) {
                contentDocumentIds.add(contentDocumentLink.ContentDocumentId);

                List<ContentDocumentLink> contentDocumentLinks;
                if (mapContentDocumentLinksByDocumentId.containsKey(contentDocumentLink.ContentDocumentId)) {
                    contentDocumentLinks = mapContentDocumentLinksByDocumentId.get(contentDocumentLink.ContentDocumentId);
                }
                else {
                    contentDocumentLinks = new List<ContentDocumentLink>();
                    mapContentDocumentLinksByDocumentId.put(contentDocumentLink.ContentDocumentId, contentDocumentLinks);
                }
                contentDocumentLinks.add(contentDocumentLink);
            }
            List<ContentVersion> contentVersions = [SELECT Id, ContentDocumentId, Title, Type_fileupload__c, PathOnClient, CreatedDate FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds AND IsLatest = TRUE ORDER BY CreatedDate DESC];

            List<File> files = new List<File>();
            for (ContentVersion contentVersion : contentVersions) {
                File file = new File('ContentDocument');
                file.DocumentId = contentVersion.ContentDocumentId;
                file.Filename = contentVersion.PathOnClient;
                file.Type = contentVersion.Type_fileupload__c;
                file.Title = contentVersion.Title;
                file.CreatedDate = contentVersion.CreatedDate.date();
                if (mapContentDocumentLinksByDocumentId.containsKey(contentVersion.ContentDocumentId)) {
                    for (ContentDocumentLink contentDocumentLink : mapContentDocumentLinksByDocumentId.get(contentVersion.ContentDocumentId)) {
                        if (mapRecordsById.containsKey(contentDocumentLink.LinkedEntityId)) {
                            SObject record = mapRecordsById.get(contentDocumentLink.LinkedEntityId);
                            file.LinkedEntities.add(new LinkedEntity(record.Id, (String)record.get('Name')));
                        }
                    }
                }
                files.add(file);
            }

            Set<String> tmNames = new Set<String>();
            for (TM__c tm : [SELECT Id, Name FROM TM__c WHERE Id IN :mapRecordsById.keySet()]) {
                tmNames.add(tm.Name);
            }

            for (Attachment attachment : [SELECT Id, Name, Description, ParentId, CreatedDate FROM Attachment WHERE ParentId IN :mapRecordsById.keySet()]) {
                File file = new File('Attachment');
                file.DocumentId = attachment.Id;
                file.Filename = attachment.Name;
                if (file.Filename.contains('.pdf')) {
                    String tmName = file.Filename.remove('.pdf');
                    Integer pos = tmName.indexOf(' ');
                    if (pos > 0) {
                        tmName = tmName.left(pos);
                    }
                    if (tmNames.contains(tmName)) {
                        file.Type = 'T&M';
                    }
                }
                file.Title = attachment.Name;
                file.CreatedDate = attachment.CreatedDate.date();
                if (mapRecordsById.containsKey(attachment.ParentId)) {
                    SObject record = mapRecordsById.get(attachment.ParentId);
                    file.LinkedEntities.add(new LinkedEntity(attachment.ParentId, (String) record.get('Name')));
                }
                files.add(file);
            }

            //ticket 20808 <<
            linkedEntityIds = new Set<Id>();
            for (File file : files) {
                for (LinkedEntity linkedEntity : file.LinkedEntities) {
                    linkedEntityIds.add(linkedEntity.Id);
                }
            }
            Map<Id, TM__c> mapTMsById = new Map<Id, TM__c>();
            for (TM__c tm : [SELECT Id, Name, Scheduled_Date__c FROM TM__c WHERE Id IN :linkedEntityIds]) {
                mapTMsById.put(tm.Id, tm);
            }
            for (File file : files) {
                for (LinkedEntity linkedEntity : file.LinkedEntities) {
                    if (mapTMsById.containsKey(linkedEntity.Id)) {
                        TM__c tm = mapTMsById.get(linkedEntity.Id);
                        file.ScheduledDate = tm.Scheduled_Date__c;
                        break;
                    }
                }
            }
            //ticket 20808 >>

            return JSON.serialize(files);
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void deleteFile(String contentDocumentId) {
        try {
            delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocumentId];
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static String getSObjectTypeByPrefix(Id recordId) {
        Map<String,String> keys = new Map<String,String>();
        Map<String,Schema.SobjectType> describe = Schema.getGlobalDescribe();
        for(String s:describe.keyset()) {
            keys.put(describe.get(s).getDescribe().getKeyPrefix(), s);
        }
        return keys.get(String.valueOf(recordId).substring(0,3));
    }

    private class File {
        @AuraEnabled
        public String DocumentId { set; get; }
        @AuraEnabled
        public String Filename { set; get; }
        @AuraEnabled
        public String Type { set; get; }
        @AuraEnabled
        public String Title { set; get; }
        @AuraEnabled
        public List<LinkedEntity> LinkedEntities { set; get; }
        //ticket 20808 <<
        @AuraEnabled
        public Date ScheduledDate { set; get; }
        //ticket 20808 >>
        @AuraEnabled
        public Date CreatedDate { set; get; }
        @AuraEnabled
        public String DocumentSource { set; get; }

        public File(String source) {
            this.DocumentSource = source;
            this.LinkedEntities = new List<LinkedEntity>();
        }
    }

    private class LinkedEntity {
        @AuraEnabled
        public String Id { set; get; }
        @AuraEnabled
        public String Name { set; get; }

        public LinkedEntity(Id id, String name) {
            this.Id = id;
            this.Name = name;
        }
    }
}