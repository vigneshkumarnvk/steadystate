/*
 *  Ticket#19950
 *      Not allow to delete emailed content document.
 */
global with sharing class ContentDocumentsService {

    global static void createEmailedContentDocumentHistroy(Id recordId, List<Id> contentDocumentIds){
        List<Emailed_Document__c> emailedDocuments = new List<Emailed_Document__c>();
        for(Id contentDocumentId : contentDocumentIds){
            Emailed_Document__c emailedDocument = new Emailed_Document__c();
            emailedDocument.RecordId__c = recordId;
            emailedDocument.ContentDocumentId__c = contentDocumentId;
            emailedDocuments.add(emailedDocument);
        }

        if(emailedDocuments.size() > 0){
            insert emailedDocuments;
        }
    }

    global static Boolean isContentDocumentEmailed(Set<Id> contentDocumentIds){
        List<Emailed_Document__c> emailedDocuments = new List<Emailed_Document__c>();
        emailedDocuments = [SELECT Id FROM Emailed_Document__c WHERE ContentDocumentId__c = :contentDocumentIds];

        if(emailedDocuments.size() > 0){
            return true;
        } else {
            return false;
        }
    }
}