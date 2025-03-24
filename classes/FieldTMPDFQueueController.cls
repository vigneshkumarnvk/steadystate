public with sharing class FieldTMPDFQueueController {
    /*
    public static Boolean ByPassTrigger;
    
    public static void Queue(Set<Id> tmIds) {
        QueueSend(new Set<Id>(tmIds));
        QueueSave(new Set<Id>(tmIds));
    }
    
    public static void UndoPDF(Set<Id> tmIds) {
        UndoSendAndSave(new Set<Id>(tmIds));
    }
    
    public static void QueueSend(Set<Id> tmIds) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Id> queueIds = new List<Id>();
            for (Field_TM_PDF_Queue__c record : getRecords(tmIds, new List<String> { 'Email' })) {
                queueIds.add(record.TM__c);
            }
            
            //remove tms which exist in the queue already
            for (Integer i = 0; i < queueIds.size(); i++) {
                if (tmIds.contains(queueIds[i])) {
                    tmIds.remove(queueIds[i]);
                }
            }
                
            if (tmIds.size() > 0) {
                Map<Id, Signature__c> mapSignaturesByTMId = new Map<Id, Signature__c>(); 
                for (Signature__c sig : [SELECT Id, Name, Accept_Terms_and_Conditions__c, Customer_Not_Available__c, Related_To_Id__c, Email__c FROM Signature__c WHERE Related_to_Object_Name__c = 'TM__c' AND Related_To_Id__c IN :tmIds AND Name = 'customer_signature' AND Voided__c <> TRUE]) {
                    mapSignaturesByTMId.put(sig.Related_To_Id__c, sig);
                }
        
                List<TM__c> tmsToUpdate = new List<TM__c>();
                List<Field_TM_PDF_Queue__c> tmsToSend = new List<Field_TM_PDF_Queue__c>();
                for (TM__c tm : [SELECT Id, Name, Status__c, Mobile_TM__c, Site_Email_Address__c, Field_TM_PDF_Saved__c, Field_TM_PDF_Sent__c FROM TM__c WHERE Id IN :tmIds AND Mobile_TM__c = TRUE AND (Status__c = 'Scheduled' OR Status__c = 'Mobile Review')]) {
                    if (mapSignaturesByTMId.containsKey(tm.Id)) {
                        Signature__c sig = mapSignaturesByTMId.get(tm.Id);
                        if (sig.Accept_Terms_and_Conditions__c == true || sig.Customer_Not_Available__c == true) {
                            if (tm.Field_TM_PDF_Sent__c != true && tm.Site_Email_Address__c != null) {
                                Field_TM_PDF_Queue__c record = new Field_TM_PDF_Queue__c();
                                record.TM__c = tm.Id;
                                record.Type__c = 'Email';
                                record.Status__c = 'Queued';
                                tmsToSend.add(record);                        
                            }
                        }
                    }
                }
                
                if (tmsToSend.size() > 0) {
                    insert tmsToSend;
                }
                
                if (tmsToUpdate.size() > 0) {
                    CompanyMgmt.byPassTrigger = true;
                    ByPassTrigger = true;
                    update tmsToUpdate;
                    ByPassTrigger = false;
                }
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    
    public static void QueueSave(Set<Id> tmIds) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Id> queueIds = new List<Id>();
            for (Field_TM_PDF_Queue__c record : getRecords(tmIds, new List<String> { 'Save' })) {
                queueIds.add(record.TM__c);
            }

            //remove tms which exist in the queue already
            for (Integer i = 0; i < queueIds.size(); i++) {
                if (tmIds.contains(queueIds[i])) {
                    tmIds.remove(queueIds[i]);
                }
            }
                
            if (tmIds.size() > 0) {
                Map<Id, Signature__c> mapSignaturesByTMId = new Map<Id, Signature__c>(); 
                for (Signature__c sig : [SELECT Id, Name, Accept_Terms_and_Conditions__c, Customer_Not_Available__c, Related_To_Id__c, Email__c FROM Signature__c WHERE Related_to_Object_Name__c = 'TM__c' AND Related_To_Id__c IN :tmIds AND Name = 'customer_signature' AND Voided__c <> TRUE]) {
                    mapSignaturesByTMId.put(sig.Related_To_Id__c, sig);
                }
        
                List<TM__c> tmsToUpdate = new List<TM__c>();
                List<Field_TM_PDF_Queue__c> tmsToSave = new List<Field_TM_PDF_Queue__c>();
                for (TM__c tm : [SELECT Id, Name, Status__c, Mobile_TM__c, Site_Email_Address__c, Field_TM_PDF_Saved__c, Field_TM_PDF_Sent__c FROM TM__c WHERE Id IN :tmIds AND Mobile_TM__c = TRUE AND (Status__c = 'Scheduled' OR Status__c = 'Mobile Review')]) {
                    if (mapSignaturesByTMId.containsKey(tm.Id)) {
                        Signature__c sig = mapSignaturesByTMId.get(tm.Id);
                        if (sig.Accept_Terms_and_Conditions__c == true || sig.Customer_Not_Available__c == true) {                                                
                            if (tm.Field_TM_PDF_Saved__c != true) {
                                Field_TM_PDF_Queue__c record = new Field_TM_PDF_Queue__c();
                                record.TM__c = tm.Id;
                                record.Type__c = 'Save';
                                record.Status__c = 'Queued';
                                tmsToSave.add(record);
                                
                                tm.Status__c = 'Mobile Review';
                                tmsToUpdate.add(tm);
                            }
                            
                        }
                    }
                }

                if (tmsToSave.size() > 0) {
                    insert tmsToSave;
                }
                
                if (tmsToUpdate.size() > 0) {
                    CompanyMgmt.byPassTrigger = true;
                    ByPassTrigger = true;
                    update tmsToUpdate;
                    ByPassTrigger = false;
                }
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    
    public static void UndoSendAndSave(set<Id> tmIds) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Field_TM_PDF_Queue__c> records = getRecords(tmIds, new List<String> { 'Save', 'Email' });
            if (records.size() > 0) {
                for (Field_TM_PDF_Queue__c record : records) {
                    record.Voided__c =  true;
                }
                update records;
            }
            
            List<Signature__c> signatures = [SELECT Id FROM Signature__c WHERE Related_To_Object_Name__c = 'TM__c' AND Related_To_Id__c IN :tmIds];
            if (signatures.size() > 0) {
                for (Signature__c signature : signatures) {
                    signature.Voided__c = true;
                }
                update signatures;
            }
            
            List<TM__c> tms = [SELECT Id FROM TM__c WHERE Id IN :tmIds];
            if (tms.size() > 0) {
                for (TM__c tm : tms) {
                    tm.Field_TM_PDF_Saved__c = false;
                    tm.Field_TM_PDF_Sent__c = false;
                    tm.Accept_Terms_And_Conditions__c = false;
                    tm.Customer_Not_Available__c = false;
                }
                update tms;
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void Process() {
        List<Field_TM_PDF_Queue__c> queued = getQueued();
        for (Field_TM_PDF_Queue__c record : queued) {
            record.Status__c = 'In Progress';
        }
        update queued;
        
        for (Field_TM_PDF_Queue__c record : queued) {
            if (record.Type__c == 'Save') {
                SaveFieldTMPDF(record.Id);
            }
            else if (record.Type__c == 'Email') {
                SendFieldTMPDF(record.Id);
            }
        }

    }

    //save TM PDF
    @future(callout=true) 
    public static void SaveFieldTMPDF(Id recordId) {
        Savepoint sp = Database.setSavepoint();
        
        Field_TM_PDF_Queue__c record  = getRecord(recordId);
        try {
            if (record != null) {
                Blob fileContent;
                if (Test.isRunningTest()) {
                    fileContent = Blob.valueOf('test');
                } else {
                    PageReference pdf = new PageReference('/apex/TMFieldPDF2');
                    pdf.getParameters().put('id', record.TM__c);
                    pdf.setRedirect(true);
                    fileContent = pdf.getContent();

                    Attachment attach = new Attachment(ParentId = record.TM__c);
                    attach.body = fileContent;
                    attach.Name = record.TM__r.Name + ' ' + System.now().format('yyyy_MM_dd_hh_mm_ss') + '.pdf';
                    insert attach;

                    TM__c tm = new TM__c(Id = record.TM__c);
                    //tm.Status__c = 'Mobile Review';
                    tm.Field_TM_PDF_Saved__c = true;

                    CompanyMgmt.ByPassTrigger = true;
                    ByPassTrigger = true;
                    update tm;
                    ByPassTrigger = false;                    
                    
                    record.Status__c = 'Complete';
                    record.Complete_Date__c = system.now();
                    update record;
                }
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            String message = ex.getMessage();
            if (message.length() >= 131000) {
                message = message.substring(0, 131000);
            }
            record.Message__c = message;
            record.Status__c = 'Error';
            update record;
            throw ex;
        }
    }
    
    //send TM PDF    
    @future(callout=true)
    public static void SendFieldTMPDF(Id recordId) {
        Savepoint sp = Database.setSavepoint();

        Id prodOrgId = '00Df40000000Ns9';
        Field_TM_PDF_Queue__c record = getRecord(recordId);
        try {

            if (record.TM__r.Site_Email_Address__c != null) {
        
                List<String> toAddrs = new List<String>();
                toAddrs.add(record.TM__r.Site_Email_Address__c);
    
                OrgWideEmailAddress orgWideEmailAddr = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'ACV Salesforce' LIMIT 1];
                String body = 'Dear Customer, \n\nAttached please find a copy of the TM you signed.';
    
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setSubject(record.TM__r.Name);
                message.setWhatId(record.TM__c);
                message.setToAddresses(toAddrs);
                message.setTreatTargetObjectAsRecipient(true);
                message.setOrgWideEmailAddressId(orgWideEmailAddr.Id);
                message.setSaveAsActivity(true);
                message.setPlaintextBody(body);
    
                Blob fileContent;
                if (Test.isRunningTest()) {
                    fileContent = Blob.valueOf('test');
                } else {
                    PageReference pdf = new PageReference('/apex/TMFieldPDF2');
                    pdf.getParameters().put('id', record.TM__c);
                    pdf.setRedirect(true);
                    fileContent = pdf.getContent();
                }
    
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                efa.setFileName(record.TM__r.Name + '.pdf');
                efa.setBody(fileContent);
                message.setFileAttachments(new Messaging.EmailFileAttachment[]{ efa });
    
                if (userInfo.getOrganizationId().contains(prodOrgId) || record.TM__r.Site_Email_Address__c == 'kchen@micro-datanet.com' || record.TM__r.Site_Email_Address__c == 'dscerbo@acvenvico.com' || record.TM__r.Site_Email_Address__c == 'jmarcotte@acvenviro.com') {
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
                    for (Integer i = 0; i < results.size(); i++) {
                        Messaging.SendEmailResult result = results[i];
                        if (result.success) {
                            TM__c tm = new TM__c(Id = record.TM__c);
                            tm.Field_TM_PDF_Sent__c = true;
                            CompanyMgmt.ByPassTrigger = true;
                            ByPassTrigger = true;                            
                            update tm;
                            ByPassTrigger = false;
                            
                            record.Status__c = 'Complete';
                            record.Complete_Date__c = system.now();
                            update record;
                        }
                        else {
                            throw new DataException(String.join(result.getErrors(), ';'));
                        }
                    }
                }
                else {
                    throw new DataException('This record is not allowed for sending Field TM PDF email in this org.');
                }
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            String error = ex.getMessage();
            if (error.length() >= 131000) {
                error = error.substring(0, 131000);
            }
            record.Status__c = 'Error';
            record.Message__c = error;
            update record;
            throw ex;
        }
    }
    //send TM PDF
    
    public static Field_TM_PDF_Queue__c getRecord(Id recordId) {
        List<Field_TM_PDF_Queue__c> records = [SELECT Id, Name, Type__c, TM__c, TM__r.Name, TM__r.Site_Email_Address__c, Complete_Date__c, Status__c FROM Field_TM_PDF_Queue__c WHERE Id = :recordId];
        if (records.size() > 0) {
            return records[0];
        }
        return null;
    }
    
    public static List<Field_TM_PDF_Queue__c> getQueued() {
        return [SELECT Id, Name, Type__c, TM__c, TM__r.Name, Complete_Date__c, Status__c FROM Field_TM_PDF_Queue__c WHERE Status__c = 'Queued'];
    }
    
    public static List<Field_TM_PDF_Queue__c> getRecords(Set<Id> tmIds, List<String> types) {
        return [SELECT Id, Name, Type__c, TM__c, TM__r.Name, Complete_Date__c, Status__c FROM Field_TM_PDF_Queue__c WHERE TM__c IN :tmIds AND Type__c IN :types AND Voided__c <> TRUE];
    }
    */
}