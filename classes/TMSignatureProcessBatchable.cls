//ticket 21113 <<
/*
public with sharing class TMSignatureProcessBatchable implements Database.Batchable<TM__c> {
    public String Task;

    public List<TM__c> start(Database.BatchableContext bc) {
        //additional signature request changes <<
        //return [SELECT Id FROM TM__c WHERE Status__c = 'Mobile Review' AND Signature_Request_Pending__c = TRUE AND Mobile_TM__c = TRUE];
        //ticket 20126 <<
        //return [SELECT Id, Signature_Request_Pending__c, Last_Signature_Request_Date__c, Signature_Request_Task_Created__c FROM TM__c WHERE Status__c = 'Mobile Review' AND Signature_Request_Pending__c = TRUE AND Mobile_TM__c = TRUE];
        return [SELECT Id, Name, Signature_Request_Pending__c, Last_Signature_Request_Date__c, Signature_Request_Task_Created__c FROM TM__c
        WHERE (Status__c = 'Mobile Review' OR Status__c = 'Confirmed') AND Signature_Request_Pending__c = TRUE];
        //ticket 20126 >>
        //additional signature request changes >>
    }

    public void execute(Database.BatchableContext bc, List<TM__c> tms) {
        if (tms.size() != 1) {
            throw new DataException('Batch size must be 1.');
        }
        TM__c tm = tms[0];

        //separate signature attachment process from the email process. PDF RenderAs process cannot not happen in the same context as teh signature process as it won't see the attachments made by the signature prcoess
        try {
            if (this.Task == 'Signature') {
                SignatureRequestController.processSignature(tm);
            }
            else if (this.Task == 'Email') {
                SignatureRequestController.processEmail(tm);
            }
        }
        catch(exception ex) {

        }
    }

    public void finish(Database.BatchableContext bc) {
        if (this.Task == 'Signature') {
            TMSignatureProcessBatchable batch = new TMSignatureProcessBatchable();
            batch.Task = 'Email';
            Database.executeBatch(batch, 1);
        }
    }
}
*/

public with sharing class TMSignatureProcessBatchable implements Database.Stateful, Database.Batchable<List<Signature_Request__c>> {
    public String Task;
    public List<List<Signature_Request__c>> start(Database.BatchableContext bc) {
        //group signature requests by document
        List<Signature_Request__c> signatureRequests;
        if (Task == 'Signature') {
            signatureRequests = SignatureProcessController.getUnprocessedSignatureRequests(null);

            if (signatureRequests == null || signatureRequests.size() == 0) { //no signatures to process, move to next task
                Task = 'Email';
            }
        }

        if (Task == 'Email') {
            signatureRequests = SignatureProcessController.getProcessedNotEmailedSignatureRequests(null);

            if (signatureRequests == null || signatureRequests.size() == 0) { //no signatures to process, move to next task
                Task = 'Reminder';
            }
        }

        if (Task == 'Reminder') { //loop through signature requests and email the created by if not signed yet after 2 days
            signatureRequests = SignatureProcessController.getUnansweredSignatureRequests(null);
        }

        Map<Id, List<Signature_Request__c>> mapSignatureRequestsBySourceRecordId = new Map<Id, List<Signature_Request__c>>();
        for (Signature_Request__c signatureRequest : signatureRequests) {
            List<Signature_Request__c> signatureRequestsByDocument;
            if (mapSignatureRequestsBySourceRecordId.containsKey(signatureRequest.Related_To_Id__c)) {
                signatureRequestsByDocument = mapSignatureRequestsBySourceRecordId.get(signatureRequest.Related_To_Id__c);
            }
            else {
                signatureRequestsByDocument = new List<Signature_Request__c>();
                mapSignatureRequestsBySourceRecordId.put(signatureRequest.Related_To_Id__c, signatureRequestsByDocument);
            }
            signatureRequestsByDocument.add(signatureRequest);
        }
        return mapSignatureRequestsBySourceRecordId.values();
    }

    public void execute(Database.BatchableContext bc, List<List<Signature_Request__c>> signatureRequestsByDocument) {
        Savepoint sp = Database.setSavepoint();
        try {
            if (Task == 'Signature') {
                for (List<Signature_Request__c> signatureRequests : signatureRequestsByDocument) {
                    SignatureProcessController.processCustomerSignaturesByDocument(signatureRequests);
                }
            }
            else if (Task == 'Email') {
                for (List<Signature_Request__c> signatureRequests : signatureRequestsByDocument) {
                    SignatureProcessController.processEmailByDocument(signatureRequests);
                }
            }
            else if (Task == 'Reminder') {
                for (List<Signature_Request__c> signatureRequests : signatureRequestsByDocument) {
                    SignatureProcessController.sendUnansweredSignatureRequestReminderEmail(signatureRequests);
                }
            }
        }
        catch (Exception ex) {
            //continue with the next batch
        }
    }

    public void finish(Database.BatchableContext bc) {
        if (this.Task == 'Signature') {
            TMSignatureProcessBatchable batch = new TMSignatureProcessBatchable();
            batch.Task = 'Email';
            Database.executeBatch(batch, 1);
        }
        else if (this.Task == 'Email') {
            TMSignatureProcessBatchable batch = new TMSignatureProcessBatchable();
            batch.Task = 'Reminder';
            Database.executeBatch(batch, 1);
        }
    }
}
//ticket 21113 >>