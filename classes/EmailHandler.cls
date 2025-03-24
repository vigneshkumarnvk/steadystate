public with sharing class EmailHandler {
    //ticket 21113 <<
    /*
    @AuraEnabled
    public static EmailWrap prepareEmailWrapByRecordId(Id recordId){
        List<String> mailTos = new List<String>();
        String mailBody = '';
        String mailSubject = '';
        String targetId = '';
        String whatId = '';
        Boolean isRecordApproved = false;
        if(recordId.getSobjectType() == Schema.Sales_Invoice__c.SObjectType){
            List<Sales_Invoice__c> salesInvoices = [SELECT Id, Name, Contact__c, Contact__r.Email, Bill_to_Customer__r.Name,
                    Approval_Status__c, Document_Status__c, Subsidiary_Company__r.Display_Name__c, Service_Center__r.Display_Company_Name__c
                    FROM Sales_Invoice__c WHERE Id =: recordId LIMIT 1];
            if(salesInvoices.size() > 0 && String.isNotBlank(salesInvoices[0].Contact__r.Email)){
                String companyName = salesInvoices[0].Subsidiary_Company__r.Display_Name__c;
                if(String.isNotBlank(salesInvoices[0].Service_Center__r.Display_Company_Name__c)){
                    companyName = salesInvoices[0].Service_Center__r.Display_Company_Name__c;
                }
                mailSubject = 'Sales Invoice ' + salesInvoices[0].Name + ' --- ' + salesInvoices[0].Bill_to_Customer__r.Name;
                mailTos.add(salesInvoices[0].Contact__r.Email);
                mailBody = 'Attached please find ' + companyName + ' Sales Invoice number ' + salesInvoices[0].Name + '. <br />';
                mailBody = mailBody + 'Should you have any questions, please contact us. If no questions, please confirm receipt of the sales invoice by replying to this email. <br />';
                mailBody += 'Thank you for your prompt attention.';
                targetId = salesInvoices[0].Contact__c;
                whatId = salesInvoices[0].Id;
                if(salesInvoices[0].Approval_Status__c == EnumUtil.ApprovalStatus.APPROVED.name() && salesInvoices[0].Document_Status__c == 'Posted'){
                    isRecordApproved = true;
                }
            }
        }
        EmailWrap emailWrap = new EmailWrap(mailTos, mailSubject, mailBody);
        if(CompanySettingUtil.isSandbox() == true){
            emailWrap.mailTo = new List<String>{UserInfo.getUserEmail()};
            targetId = null;
        }
        emailWrap.targetId = targetId;
        emailWrap.whatId = whatId;
        emailWrap.senderName = UserInfo.getName();
        emailWrap.replyTo = UserInfo.getUserEmail();
        emailWrap.isRecordApproved = isRecordApproved;
        return emailWrap;
    }
    */

    @AuraEnabled
    public static Sales_Order__c getSalesQuote(Id recordId) {
        try {
            return [SELECT Id, Name, Approval_Status__c, Document_Status__c, Document_Type__c, Quote_Contact__c, Quote_Contact__r.Email, Report_Parameter_Print_Type__c, Report_Parameter_Print_Estimate_Duration__c FROM Sales_Order__c WHERE Id = :recordId LIMIT 1];
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Sales_Invoice__c getSalesInvoice(Id recordId) {
        try {
            return [SELECT Id, Name, Approval_Status__c, Document_Status__c, Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c, Document_Type__c, Contact__c, Contact__r.Email FROM Sales_Invoice__c WHERE Id = :recordId LIMIT 1];
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void saveQuotePDFReportParameters(Id id, String printType, Boolean printEstimatedDuration) {
        try {
            Sales_Order__c quote = new Sales_Order__c();
            quote.Id = id;
            quote.Report_Parameter_Print_Type__c = printType;
            quote.Report_Parameter_Print_Estimate_Duration__c = printEstimatedDuration;
            CompanyMgmt.byPassTrigger = true;
            update quote;
            CompanyMgmt.byPassTrigger = false;
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static EmailWrap initInvoiceEmailMessage(Id recordId) {
        try {
            EmailWrap emailMessage = new EmailWrap();

            List<Sales_Invoice__c> salesInvoices = [
                    SELECT Id, Name, Contact__c, Contract__c, Contact__r.Email, Bill_to_Customer__r.Name,
                            Approval_Status__c, Document_Status__c, Subsidiary_Company__r.Display_Name__c, Service_Center__r.Display_Company_Name__c
                    FROM Sales_Invoice__c
                    WHERE Id = :recordId
                    LIMIT 1
            ];

            if (salesInvoices.size() > 0 && String.isNotBlank(salesInvoices[0].Contact__r.Email)) {
                String companyName = salesInvoices[0].Subsidiary_Company__r.Display_Name__c;
                if (String.isNotBlank(salesInvoices[0].Service_Center__r.Display_Company_Name__c)) {
                    companyName = salesInvoices[0].Service_Center__r.Display_Company_Name__c;
                }
                emailMessage.senderName = UserInfo.getName();
                emailMessage.replyTo = UserInfo.getUserEmail();
                emailMessage.mailSubject = 'Sales Invoice ' + salesInvoices[0].Name + ' --- ' + salesInvoices[0].Bill_to_Customer__r.Name;
                emailMessage.mailTo = salesInvoices[0].Contact__r.Email;
                emailMessage.mailBody = 'Attached please find ' + companyName + ' Sales Invoice number ' + salesInvoices[0].Name + '. <br />'
                        + 'Should you have any questions, please contact us. If no questions, please confirm receipt of the sales invoice by replying to this email. <br />'
                        + 'Thank you for your prompt attention. <br /><br /><br />';
                emailMessage.targetId = salesInvoices[0].Contact__c;
                emailMessage.whatId = salesInvoices[0].Id;
            }
            if (emailMessage.isTest == true || CompanySettingUtil.isSandbox() == true) {
                emailMessage.mailTo = UserInfo.getUserEmail();
                emailMessage.targetId = null;
            }
            return emailMessage;
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static EmailWrap initQuoteEmailMessage(Id recordId){
        try {
            EmailWrap emailMessage = new EmailWrap();
            List<Sales_Order__c> salesOrders = [
                    SELECT Id, Name, Document_Type__c, Quote_Contact__c, Contract__c, Quote_Contact__r.Email, Bill_to_Customer_No__r.Name,
                            Approval_Status__c, Document_Status__c, Subsidiary_Company__r.Display_Name__c, Service_Center__r.Display_Company_Name__c,
                            CreatedBy.Name
                    FROM Sales_Order__c
                    WHERE Id = :recordId
                    LIMIT 1
            ];
            String siteUrl = CompanySettingUtil.acvSetting.TM_Signature_Site_URL__c;
            if (siteUrl == null) {
                throw new DataException('Signature site URL is not defined on the company setting.');
            }
            if (salesOrders.size() > 0 && String.isNotBlank(salesOrders[0].Quote_Contact__r.Email)) {
                Sales_Order__c salesOrder = salesOrders[0];
                if (salesOrder.Document_Type__c == 'Sales Quote') {

                    Integer tokenExpirationHours = 48;
                    if (CompanySettingUtil.acvSetting.Quote_Signature_Token_Expiration_Hours__c != null) {
                        tokenExpirationHours = CompanySettingUtil.acvSetting.Quote_Signature_Token_Expiration_Hours__c.intValue();
                    }
                    String companyName = salesOrder.Subsidiary_Company__r.Display_Name__c;
                    if (String.isNotBlank(salesOrder.Service_Center__r.Display_Company_Name__c)) {
                        companyName = salesOrder.Service_Center__r.Display_Company_Name__c;
                    }
                    emailMessage.senderName = UserInfo.getName();
                    emailMessage.replyTo = UserInfo.getUserEmail();
                    emailMessage.mailSubject = companyName + ' ' + salesOrder.Name + ' --- ' + salesOrder.Bill_to_Customer_No__r.Name; //Ticket#24977
                    emailMessage.mailTo = salesOrder.Quote_Contact__r.Email;
                    emailMessage.mailCc = UserInfo.getUserEmail();
                    emailMessage.mailBody = 'Thank you for considering ' + companyName + ' for your environmental needs. Attached please find a custom sales quote for the services requested. If you would like to schedule the project or, have any questions, please contact us at your earliest convenience.&nbsp;<br/>&nbsp;<br/>'
                            + 'We need your signature for the quote. Please review the attached quote and use the link below to sign the quote. We will send you the final copy after signature is received. Please note the link will expire in ' + tokenExpirationHours + ' hours.&nbsp;<br/>&nbsp;<br/>&nbsp;<br/>'
                            + '<a href="' + siteUrl + '/?token=00000000-0000-0000-0000-000000000000" style="text-decoration:none"><span style="width:125px;display:block;background:green;color:white;font-family:sans-serif;font-weight:normal;text-align:center;text-decoration:none;border:2px solid darkgreen;"><span style="display:block;border:6px solid green;">Sign Quote</span></span></a>&nbsp;<br/>&nbsp;<br/>'
                            + 'Regards,&nbsp;<br/>&nbsp;<br/>' + salesOrder.CreatedBy.Name;

                    emailMessage.targetId = salesOrder.Quote_Contact__c;
                    emailMessage.whatId = salesOrder.Id;
                }
            }

            if (emailMessage.isTest == true || CompanySettingUtil.isSandbox() == true) {
            //if (emailMessage.isTest == true) {
                emailMessage.mailTo = UserInfo.getUserEmail();
                emailMessage.targetId = null;
            }
            return emailMessage;
        }
        catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //ticket 21113 >>

    //ticket 21113 <<
    /*
    @AuraEnabled
    public static void sendEmail(List<String> toAddress, String ccAddress, String subject, String body, String contentDocIds, String senderName, String replyTo, String targetId, String whatId){
        Messaging.reserveMassEmailCapacity(1);
        try{
            messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
            List<String> ccAddresses = new List<String>();
            if(String.isNotBlank(ccAddress)){
                ccAddresses = ccAddress.split(';');
            }

            //Ticket#19910 add sender to cc address
            String userEmailAddress = UserInfo.getUserEmail();
            if(ccAddresses.contains(userEmailAddress) == false){
                ccAddresses.add(userEmailAddress);
            }

            mail.setToAddresses(toAddress);
            mail.setCcAddresses(ccAddresses);
            mail.setReplyTo(replyTo);
            mail.setSenderDisplayName(senderName);
            mail.setSubject(subject);
            mail.setHtmlBody(body);
            mail.setTargetObjectId(targetId);
            mail.setWhatId(whatId);
            mail.setSaveAsActivity(true);

            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            //   return ['.pdf', '.doc', 'docx', '.jpg', '.png', '.jpeg', '.xlsx', '.xls', '.csv', 'zip'];
            List<String> docIds = new List<String>();
            if(String.isNotBlank(contentDocIds)) {
                docIds = contentDocIds.split(',');

                //include latest document only.
                List<ContentVersion> contentVersions = [
                        SELECT Id, FileType, Title, FileExtension, VersionData, ContentDocumentId, LastModifiedDate
                        FROM ContentVersion
                        WHERE ContentDocumentId IN :docIds
                        ORDER BY LastModifiedDate DESC, ContentDocumentId
                ];

                List<ContentVersion> cvs = new List<ContentVersion>();
                Set<Id> processedContentDocIds = new Set<Id>();
                for (ContentVersion cv : contentVersions) {
                    if (processedContentDocIds.contains(cv.ContentDocumentId)) {
                        continue;
                    } else {
                        processedContentDocIds.add(cv.ContentDocumentId);
                        cvs.add(cv);
                    }
                }

                for (ContentVersion cv : cvs) {
                    String fileExtension = cv.FileExtension;
                    String contentTypeMIME = '';
                    String fileName = cv.Title;
                    switch on cv.FileExtension {
                        when 'pdf' {
                            contentTypeMIME = 'application/pdf';
                            if(fileName.contains('.pdf') == false){
                                fileName = fileName + '.pdf';
                            }
                        }
                        when 'zip' {
                            contentTypeMIME = 'application/zip';
                        }
                        when 'jpg', 'jpeg' {
                            contentTypeMIME = 'image/jpeg';
                        }
                        when 'png' {
                            contentTypeMIME = 'image/png';
                        }
                        when 'csv' {
                            contentTypeMIME = 'text/csv';
                        }
                        when 'doc', 'docx' {
                            contentTypeMIME = 'application/msword';
                        }
                        when 'xls', 'xlsx' {
                            contentTypeMIME = 'application/vnd.ms-excel';
                        }
                        when else {
                            throw new DataException('Content Type ' + fileExtension + ' is not supported!');
                        }
                    }
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(fileName);
                    efa.setBody(cv.VersionData);
                    efa.setContentType(contentTypeMIME);
                    attachments.add(efa);
                }
            }

            if(attachments.size() > 0){
                mail.setFileAttachments(attachments);
            } else {
                throw new DataException('Please attach the invoice document!');
            }

            Messaging.sendEmail(new List<messaging.SingleEmailMessage> {mail});

            ContentDocumentsService.createEmailedContentDocumentHistroy(whatId, docIds);

            updateTargetRecord(whatId);
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    */

    @AuraEnabled
    public static void sendEmail(String JSONEmailMessage) {
        try{
            EmailWrap emailMessage = (EmailWrap)JSON.deserialize(JSONEmailMessage, EmailWrap.class);
            Messaging.reserveMassEmailCapacity(1);

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

            List<String> toAddresses = new List<String>();
            if (String.isNotBlank(emailMessage.mailTo)) {
                toAddresses = emailMessage.mailTo.split(';');
            }

            List<String> ccAddresses = new List<String>();
            if(String.isNotBlank(emailMessage.mailCc)){
                ccAddresses = emailMessage.mailCc.split(';');
            }

            String userEmailAddress = UserInfo.getUserEmail();
            if(ccAddresses.contains(userEmailAddress) == false){
                ccAddresses.add(userEmailAddress);
            }

            mail.setToAddresses(toAddresses);
            mail.setCcAddresses(ccAddresses);
            mail.setReplyTo(emailMessage.replyTo);
            mail.setSenderDisplayName(emailMessage.senderName);
            mail.setSubject(emailMessage.mailSubject);
            mail.setHtmlBody(emailMessage.mailBody);

            if(emailMessage.isTest != true && CompanySettingUtil.isSandbox() != true){
                mail.setTargetObjectId(emailMessage.targetId);
                mail.setWhatId(emailMessage.whatId);
                mail.setSaveAsActivity(true);
            }

            List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
            //   return ['.pdf', '.doc', 'docx', '.jpg', '.png', '.jpeg', '.xlsx', '.xls', '.csv', 'zip'];
            List<String> contentDocumentIds = new List<String>();
            if(String.isNotBlank(emailMessage.contentDocumentIds)) {
                contentDocumentIds = emailMessage.contentDocumentIds.split(';');
                //include latest document only.
                List<ContentVersion> contentVersions = [
                        SELECT Id, FileType, Title, FileExtension, VersionData, ContentDocumentId, LastModifiedDate
                        FROM ContentVersion
                        WHERE ContentDocumentId IN :contentDocumentIds
                        ORDER BY LastModifiedDate DESC, ContentDocumentId
                ];

                List<ContentVersion> cvs = new List<ContentVersion>();
                Set<Id> processedContentDocIds = new Set<Id>();
                for (ContentVersion cv : contentVersions) {
                    if (processedContentDocIds.contains(cv.ContentDocumentId)) {
                        continue;
                    } else {
                        processedContentDocIds.add(cv.ContentDocumentId);
                        cvs.add(cv);
                    }
                }

                for (ContentVersion cv : cvs) {
                    String fileExtension = cv.FileExtension;
                    String contentTypeMIME = '';
                    String fileName = cv.Title;
                    switch on cv.FileExtension {
                        when 'pdf' {
                            contentTypeMIME = 'application/pdf';
                        }
                        when 'zip' {
                            contentTypeMIME = 'application/zip';
                        }
                        when 'jpg', 'jpeg' {
                            contentTypeMIME = 'image/jpeg';
                        }
                        when 'png' {
                            contentTypeMIME = 'image/png';
                        }
                        when 'csv' {
                            contentTypeMIME = 'text/csv';
                        }
                        when 'doc', 'docx' {
                            contentTypeMIME = 'application/msword';
                        }
                        when 'xls' {
                            contentTypeMIME = 'application/vnd.ms-excel';
                        }
                        when 'xlsx' {
                            contentTypeMIME = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
                        }
                        when else {
                            throw new DataException('Content Type ' + fileExtension + ' is not supported!');
                        }
                    }
                    fileExtension = '.' + fileExtension;
                    if(fileName.contains(fileExtension) == false){
                        fileName = fileName + fileExtension;
                    }
                    Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                    efa.setFileName(fileName);
                    efa.setBody(cv.VersionData);
                    efa.setContentType(contentTypeMIME);
                    attachments.add(efa);
                }
            }

            if(attachments.size() > 0){
                mail.setFileAttachments(attachments);
            } else if (!Test.isRunningTest()) {
                throw new DataException('Please select at least one document to attach to the email!');
            }

            List<Messaging.SendEmailResult> results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> { mail });
            if  (results.size() > 0) {
                if (results[0].success == true) {
                    ContentDocumentsService.createEmailedContentDocumentHistroy(emailMessage.whatId, contentDocumentIds);
                    updateTargetRecord(emailMessage);
                }
                else {
                    throw new DataException(results[0].errors[0].message);
                }
            }

        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }
    //ticket 21113 >>

    public class EmailWrap{
        //ticket 21113 <<
        //@AuraEnabled public List<String> mailTo;
        @AuraEnabled public Boolean isTest;
        @AuraEnabled public String mailTo;
        @AuraEnabled public String mailCc;
        @AuraEnabled public String contentDocumentIds;
        //ticket 21113 >>

        @AuraEnabled public String mailBody;
        @AuraEnabled public String mailSubject;
        @AuraEnabled public String targetId {get; set;}
        @AuraEnabled public String replyTo {get; set;}
        @AuraEnabled public String whatId {get; set;}
        @AuraEnabled public String senderName {get; set;}
        //ticket 21113 <<
        //@AuraEnabled public Boolean isRecordApproved {get; set;}
        //ticket 21113 >>

        //ticket 21113 <<
        /*
        public EmailWrap(List<String> mailTo, String mailSubject, String mailBody){
            this.mailTo = mailTo;
            this.mailBody = mailBody;
            this.mailSubject = mailSubject;
        }
        */
        //ticket 21113 >>
    }

    //ticket 21113 <<
    /*
    private static void updateTargetRecord(Id recordId){
        try{

            if(recordId.getSobjectType() == Schema.Sales_Invoice__c.SObjectType){
                Sales_Invoice__c salesInvoice = [SELECT Id, Sales_Invoice_Emailed__c FROM Sales_Invoice__c WHERE Id = :recordId LIMIT 1];
                salesInvoice.Sales_Invoice_Emailed__c = true;
                update salesInvoice;
            }
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw e;
        }
    }
    */
    private static void updateTargetRecord(EmailWrap emailMessage){
        try{
            if (emailMessage == null) {
                throw new DataException('The email has not been initiated.');
            }
            if (emailMessage.whatId == null) {
                throw new DataException('The email is not currently related to a source document. WhatId is required.');
            }
            SObjectType sourceRecordType = ((Id)emailMessage.whatId).getSobjectType();
            if (sourceRecordType == Schema.Sales_Invoice__c.SObjectType){
                Sales_Invoice__c salesInvoice = [SELECT Id, Sales_Invoice_Emailed__c FROM Sales_Invoice__c WHERE Id = :emailMessage.whatId LIMIT 1];
                salesInvoice.Sales_Invoice_Emailed__c = true;
                update salesInvoice;
            }
            else if (sourceRecordType == Schema.Sales_Order__c.getSObjectType()) {
                /* replace by created by
                Sales_Order__c quote = [SELECT Id FROM Sales_Order__c WHERE Id = :emailMessage.whatId LIMIT 1];
                quote.Last_Quote_Email_Sent_By__c = UserInfo.getUserId();
                CompanyMgmt.byPassTrigger = true;
                update quote;
                CompanyMgmt.byPassTrigger = false;
                */
            }
        } catch (Exception e){
            System.debug('Error: ' + e.getStackTraceString());
            throw e;
        }
    }
    //ticket 21113 >>
}