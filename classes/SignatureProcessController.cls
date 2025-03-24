public with sharing class SignatureProcessController {
    public Id sourceRecordId;
    public List<Signature_Request__c> signatureRequests { set; get; }

    //ticket 21113 <<
    public SignatureProcessController() {
        this.sourceRecordId = (Id)ApexPages.currentPage().getParameters().get('id');
        this.signatureRequests = getUnprocessedSignatureRequests(this.sourceRecordId);
    }

    public PageReference processSignatures() {
        try {
            List<Signature_Request__c> signatureRequests = getUnprocessedSignatureRequests(this.sourceRecordId);
            processCustomerSignaturesByDocument(signatureRequests);
            processEmailByDocument(this.sourceRecordId);
            return new PageReference('/' + this.sourceRecordId).setRedirect(true);
        }
        catch (Exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }
    }

    public PageReference cancel() {
        return new PageReference('/' + this.sourceRecordId);
    }

    public static List<Signature_Request__c> getUnansweredSignatureRequests(String relatedToId) {
        Integer days = 2;

        List<String> filters = new List<String>();
        filters.add('Voided__c != TRUE');
        filters.add('Signed__c != TRUE');
        filters.add('Declined__c != TRUE');
        filters.add('Processed__c != TRUE');
        filters.add('Request_Email_Sent__c = TRUE');
        filters.add('Reminder_Sent__c != TRUE');
        filters.add('Request_Date__c < LAST_N_DAYS:' + days); //last days

        filters.add('Related_To_Object_Name__c = \'Sales_Order__c\'');//quote only
        if (relatedToId != null) {
            filters.add('Related_To_Id__c = :relatedToId');
        }
        filters.add('CreatedDate >= 2023-02-24T12:00:00.000Z');
        String queryString = 'SELECT Id, Email__c, Print_Name__c, Signature_Date__c, Request_Date__c, Reminder_Sent__c, Accept_Terms_and_Conditions__c, Related_To_Object_Name__c, Related_To_Id__c, Signed__c, Declined__c, Customer_PO_No__c, Customer_Comment__c, Processed__c '
                + ' FROM Signature_Request__c'
                + ' WHERE ' + String.join(filters, ' AND ');
        List<Signature_Request__c> signatureRequests = Database.query(queryString);
        return signatureRequests;
    }

    public static List<Signature_Request__c> getUnprocessedSignatureRequests(String relatedToId) {

        List<String> filters = new List<String>();
        filters.add('Voided__c != TRUE');
        filters.add('(Signed__c = TRUE OR Declined__c = TRUE)');
        filters.add('Processed__c != TRUE');
        if (relatedToId != null) {
            filters.add('Related_To_Id__c = :relatedToId');
        }
        String queryString = 'SELECT Id, Email__c, Print_Name__c, Signature_Date__c, Request_Date__c, Reminder_Sent__c, Accept_Terms_and_Conditions__c, Related_To_Object_Name__c, Related_To_Id__c, Signed__c, Declined__c, Customer_PO_No__c, Customer_Comment__c, Processed__c '
                + ' FROM Signature_Request__c'
                + ' WHERE ' + String.join(filters, ' AND ');
        List<Signature_Request__c> signatureRequests = Database.query(queryString);
        return signatureRequests;
    }
    public static List<Signature_Request__c> getProcessedNotEmailedSignatureRequests(String relatedToId) {

        List<String> filters = new List<String>();
        filters.add('Voided__c != TRUE');
        filters.add('(Signed__c = TRUE OR Declined__c = TRUE)');
        filters.add('Processed__c = TRUE');
        filters.add('PDF_Email_Pending__c = TRUE');
        if (relatedToId != null) {
            filters.add('Related_To_Id__c = :relatedToId');
        }
        String queryString = 'SELECT Id, Email__c, Print_Name__c, Signature_Date__c, Request_Date__c, Reminder_Sent__c, Related_To_Object_Name__c, Related_To_Id__c, Signed__c, Declined__c, Customer_PO_No__c, Customer_Comment__c, Processed__c '
                + ' FROM Signature_Request__c'
                + ' WHERE ' + String.join(filters, ' AND ');
        List<Signature_Request__c> signatureRequests = Database.query(queryString);
        return signatureRequests;
    }


    public static void processCustomerSignaturesByDocument(List<Signature_Request__c> signatureRequests) {
        Savepoint sp = Database.setSavepoint();
        try {
            //check for the source records. This routine process signatures for a single document
            String sourceRecordId;
            for (Signature_Request__c signatureRequest : signatureRequests) {
                if (sourceRecordId != null && sourceRecordId != signatureRequest.Related_To_Id__c) {
                    throw new DataException('processCustomerSignaturesByDocument handle only document per call.');
                }
                sourceRecordId = signatureRequest.Related_To_Id__c;
            }

            Set<Id> signatureRequestIds = new Set<Id>();
            Map<String, Set<Id>> mapSourceRecordIdsByObjectName = new Map<String, Set<Id>>();
            for (Signature_Request__c signatureRequest : signatureRequests) {
                signatureRequestIds.add(signatureRequest.Id);

                Set<Id> sourceRecordIds;
                if (mapSourceRecordIdsByObjectName.containsKey(signatureRequest.Related_To_Object_Name__c)) {
                    sourceRecordIds = mapSourceRecordIdsByObjectName.get(signatureRequest.Related_To_Object_Name__c);
                }
                else {
                    sourceRecordIds = new Set<Id>();
                    mapSourceRecordIdsByObjectName.put(signatureRequest.Related_To_Object_Name__c, sourceRecordIds);
                }
                sourceRecordIds.add(signatureRequest.Related_To_Id__c);
            }

            Map<Id, Signature__c> mapSignaturesBySignatureRequestId = new Map<Id, Signature__c>();
            for (Signature__c signature : [SELECT Id, Signature_Request__c, (SELECT Id FROM Attachments) FROM Signature__c WHERE Signature_Request__c IN :signatureRequestIds]) {
                mapSignaturesBySignatureRequestId.put(signature.Signature_Request__c, signature);
            }

            //attach customer signatures to the signature records
            Map<Id, Attachment> mapAttachmentsBySignatureRequestId = new Map<Id, Attachment>();
            for (Attachment attachment : [SELECT Id, Name, ParentId, Body, ContentType, IsPrivate FROM Attachment WHERE ParentId IN :signatureRequestIds]) {
                mapAttachmentsBySignatureRequestId.put(attachment.ParentId, attachment);
            }

            List<Attachment> newAttachments = new List<Attachment>();
            for (Signature_Request__c signatureRequest : signatureRequests) {
                if (mapSignaturesBySignatureRequestId.containsKey(signatureRequest.Id)) {
                    Signature__c signature = mapSignaturesBySignatureRequestId.get(signatureRequest.Id);

                    signature.Customer_Not_Available__c = false;
                    signature.Signed__c = signatureRequest.Signed__c;
                    signature.Declined__c = signatureRequest.Declined__c;
                    signature.Print_Name__c = signatureRequest.Print_Name__c;
                    signature.Signature_Date__c = signatureRequest.Signature_Date__c;
                    signature.Email__c = signatureRequest.Email__c;
                    signature.Accept_Terms_and_Conditions__c = signatureRequest.Accept_Terms_and_Conditions__c;
                    signature.Customer_Comment__c = signatureRequest.Customer_Comment__c;
                    signature.Customer_PO_No__c = signatureRequest.Customer_PO_No__c;

                    //create attachment
                    if (mapAttachmentsBySignatureRequestId.containsKey(signatureRequest.Id)) {
                        Attachment newAttachment = mapAttachmentsBySignatureRequestId.get(signatureRequest.Id).clone(false, false);
                        if (signature.Attachments.size() > 0) {
                            newAttachment.Id = signature.Attachments[0].Id;
                        } else {
                            newAttachment.ParentId = signature.Id;
                        }
                        newAttachment.Name = 'customer signature';
                        newAttachments.add(newAttachment);
                    }

                    //update signature request
                    signatureRequest.Id = signature.Signature_Request__c;
                    signatureRequest.Signature_Pending__c = false;
                    signatureRequest.PDF_Email_Pending__c = true;
                    signatureRequest.Processed__c = true;
                }
            }

            upsert newAttachments;
            update signatureRequests;
            update mapSignaturesBySignatureRequestId.values();

            //update source records Signature_Request_Pending__c by object type
            for (String objectName : mapSourceRecordIdsByObjectName.keySet()) {
                Set<Id> sourceRecordIds = mapSourceRecordIdsByObjectName.get(objectName);

                List<SObject> sourceRecordsToUpdate = new List<SObject>();
                String queryString = 'SELECT Id, Name, Signature_Request_Pending__c FROM ' + objectName + ' WHERE Id IN :sourceRecordIds';
                for (SObject sourceRecord : Database.query(queryString)) {
                    List<Signature__c> signatures = [SELECT Id, Request_Signature__c, Email__c, Signed__c, Declined__c, Customer_PO_No__c, Customer_Comment__c FROM Signature__c WHERE Related_To_Id__c = :sourceRecord.Id AND Voided__c != TRUE];
                    if ((Boolean)sourceRecord.get('Signature_Request_Pending__c') == true) {
                        Boolean signatureRequestPending = false;
                        String status = null;
                        for (Signature__c signature : signatures) {
                            if (signature.Request_Signature__c == true && signature.Signed__c != true && signature.Declined__c != true) {
                                signatureRequestPending = true;
                            }
                            if (objectName == 'Sales_Order__c') { //there should only be one signature for quote
                                if (signature.Signed__c == true) {
                                    status = 'Customer Accepted';
                                }
                                else if (signature.Declined__c == true) {
                                    status = 'Rejected';
                                }
                                if (status != null) {
                                    sourceRecord.put('Signature_Request_Status__c', status);
                                }
                                if (signature.Customer_PO_No__c != null) {
                                    sourceRecord.put('Customer_PO_No__c', signature.Customer_PO_No__c);
                                }
                                if (signature.Customer_Comment__c != null) {
                                    sourceRecord.put('Customer_Comment__c', signature.Customer_Comment__c);
                                }
                            }
                        }
                        sourceRecord.put('Signature_Request_Pending__c', signatureRequestPending);
                        sourceRecordsToUpdate.add(sourceRecord);
                    }
                }
                update sourceRecordsToUpdate;
            }
        }
        catch (Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    @future(callout=true)
    public static void processEmailByDocument(Id relatedToId) {
        List<Signature_Request__c> signatureRequests = getProcessedNotEmailedSignatureRequests(relatedToId);
        if (signatureRequests.size() > 0) {
            processEmailByDocument(signatureRequests);
        }
    }

    public static void processEmailByDocument(List<Signature_Request__c> signatureRequests) {
        Savepoint sp = Database.setSavepoint();
        try {
            String sourceRecordId;
            String objectName;
            for (Signature_Request__c signatureRequest : signatureRequests) { //tm can take up to 2 customer signatures
                if (sourceRecordId != null && sourceRecordId != signatureRequest.Related_To_Id__c) {
                    throw new DataException('processEmailByDocument handle only document per call.');
                }
                sourceRecordId = signatureRequest.Related_To_Id__c;
                objectName = signatureRequest.Related_To_Object_Name__c;
            }

            if (objectName == 'TM__c') {
                TM__c tm = [SELECT Id, Name FROM TM__c WHERE Id = :sourceRecordId LIMIT 1];
                Blob pdf = MobileTMController.GenerateFieldTMPDF(tm.Id);
                //ticket 29960 >>
                //MobileTMController.SaveFieldTMPDF(tm, pdf);
                MobileTMController.SaveFieldTMPDF(tm, pdf, tm.Name + '_' + + System.now().format('yyyy_MM_dd_hh_mm_ss') + '_Signed.pdf');
                //ticket 29960 <<
                MobileTMController.sendFieldTMPDF(tm, pdf);
            }
            else if (objectName == 'Sales_Order__c') {
                Signature_Request__c signatureRequest = signatureRequests[0]; // quote only takes one signature from the quote contact

                if (signatureRequest.Signed__c == true) {
                    Sales_Order__c quote = [SELECT Id, Name, CreatedBy.Email FROM Sales_Order__c WHERE Id = :sourceRecordId LIMIT 1];
                    Blob pdf = SalesQuoteEmailing.generateQuotePDF(quote.Id);
                    String filename = quote.Name + '_' + System.now().format('yyyyMMddhhmmss') + '_Signed.pdf';
                    SalesQuoteEmailing.saveQuotePDF(quote, pdf, filename);
                    SalesQuoteEmailing.sendQuotePDF(quote, pdf);
                    SalesQuoteEmailing.notifySignedQuote(signatureRequest);
                }
                else if (signatureRequest.Declined__c == true) {
                    SalesQuoteEmailing.notifyRejectedQuote(signatureRequest);
                }
            }

            for (Signature_Request__c signatureRequest : signatureRequests) {
                signatureRequest.PDF_Email_Pending__c = false;
            }

            update signatureRequests;

        } catch (Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void sendUnansweredSignatureRequestReminderEmail(List<Signature_Request__c> signatureRequests) {
        try {
            String sourceRecordId;
            String objectName;
            for (Signature_Request__c signatureRequest : signatureRequests) { //tm can take up to 2 customer signatures
                if (sourceRecordId != null && sourceRecordId != signatureRequest.Related_To_Id__c) {
                    throw new DataException('sendUnansweredSignatureRequestReminderEmail handle only document per call.');
                }
                sourceRecordId = signatureRequest.Related_To_Id__c;
                objectName = signatureRequest.Related_To_Object_Name__c;
            }

            if (objectName == 'Sales_Order__c') {
                Signature_Request__c signatureRequest = [SELECT Id, Voided__c, Signed__c, Declined__c, Request_Email_Sent__c, Request_Date__c, Reminder_Sent__c, Related_To_Object_Name__c, Related_To_Id__c, Print_Name__c, Email__c, Processed__c, CreatedById FROM Signature_Request__c WHERE Id = :signatureRequests[0].Id LIMIT 1];
                if (signatureRequest.Request_Email_Sent__c = TRUE && signatureRequest.Voided__c != true && signatureRequest.Signed__c != true
                        && signatureRequest.Declined__c != true && signatureRequest.Processed__c != true && signatureRequest.Reminder_Sent__c != true) {
                    SalesQuoteEmailing.notifyUnansweredSignatureRequest(signatureRequest);
                }


                signatureRequest.Reminder_Sent__c = true;
                signatureRequest.Reminder_Sent_Date__c = Datetime.now();
                update signatureRequest;

                Sales_Order__c quote = new Sales_Order__c();
                quote.Id = sourceRecordId;
                quote.Signature_Request_Status__c = 'Fail to Respond';
                CompanyMgmt.byPassTrigger = true;
                update quote;
            }
        }
        catch (Exception ex) {
            //ignore email error
        }
    }

    //ticket 21113 >>
}