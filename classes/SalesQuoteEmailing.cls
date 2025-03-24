public class SalesQuoteEmailing {
    private final ApexPages.StandardController theController;
    public final Sales_Order__c theSO{get; set;}
    public final Contact[] theContactList{get; set;}
    public final Company_Setup__c theCompanySetup {get;set;}
    public static String theToAddresses{get;set;}
    public static String theCcAddresses{get;set;}
    public static String theBody{get;set;}
    public static String theSubject{get;set;}
    private String SOId;
    public Boolean showEmail{get;set;}
    public Boolean isTest{get; set;}
    public Boolean allowToEmail{get; set;}
    //Ticket# 13610 >>
    public String selPrintType {
        get{
            if (selPrintType == null) {
                selPrintType = 'Detail';
            }
            return selPrintType;
        } set;
    }
    public List<SelectOption> lstPrintType {
        get {
            if (lstPrintType == null) {
                lstPrintType = new List<SelectOption>();
                lstPrintType.add(new SelectOption('Detail', 'Detail'));
                lstPrintType.add(new SelectOption('Consolidated', 'Consolidated'));
            }
            return lstPrintType;
        }
        set;
    }

    public Attachment file {
        get {
            if (file == null) file = new Attachment();
            return file;
        }
        set;
    }
    public Boolean printEstimatedDuration {get; set; } //Ticket#21772

    //Ticket# 13610 >>
    public SalesQuoteEmailing(ApexPages.StandardController controller){
        theController = controller;
        SOId = ApexPages.currentPage().getParameters().get('id');

        theSO = [SELECT Id, Name, Bill_to_Contact__c, Bill_to_Contact__r.Name, Owner.Name, CreatedBy.Name, Expired__c,
                 Bill_to_Contact__r.Email, Quote_Contact__c, Quote_Contact__r.Name, Quote_Contact__r.Email,
                Bill_to_Customer_No__r.Name, Site_Scope__c, Approval_Status__c, Service_Center__r.Display_Company_Name__c,
                Service_Center__r.Subsidiary_Company__r.Display_Name__c
                 FROM Sales_Order__c WHERE Id = :SOId LIMIT 1];

        showEmail = true;
        printEstimatedDuration = true; //Ticket#21772
        
        if(theSO.Approval_Status__c == EnumUtil.ApprovalStatus.APPROVED.name()) allowToEmail = true;

        if(theSO.Expired__c == true){
            allowToEmail = false;
            showEmail = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'This Sales Quote is expired. Please create a new Sales Quote.'));
        }

        if(theSO.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name()){
            allowToEmail = false;
            showEmail = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'This quote cannot be emailed because it is not approved yet!'));
        }

        if (String.isBlank(theSO.Site_Scope__c)) {
            showEmail = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must enter Project Scope before you can print.'));
        }

        //Ticket#18522 change email address to quote contact
        theContactList = [SELECT Id, Name, Email FROM Contact WHERE Id =: theSO.Quote_Contact__c];

        if(theContactList.size() == 0){
            showEmail = false;
            //job task <<
            //ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Billing Contact is blank for quote: ' + theSO.Name));
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Quote Contact is blank.'));
            //job task >>
        }
        
        if(showEmail){
            String companyName = theSO.Service_Center__r.Subsidiary_Company__r.Display_Name__c;
            if(String.isNotBlank(theSO.Service_Center__r.Display_Company_Name__c)){
                companyName = theSO.Service_Center__r.Display_Company_Name__c;
            }
            if(CompanySettingUtil.isSandbox() == true){
                theToAddresses = UserInfo.getUserEmail();
            } else {
                theToAddresses = theContactList[0].Email;
            }

            theSubject = companyName + ' ' + theSO.Name + ' --- ' + theSO.Bill_to_Customer_No__r.Name;
            theBody = '<p>Thank you for considering '+ companyName + ' for your environmental needs. ' +
                    'Attached please find a custom sales quote for the services requested. ' +
                    'If you would like to schedule the project or, have any questions, ' +
                    'please contact us at your earliest convenience.</p> \n\n<p>Regards,</p>'
+ theSO.CreatedBy.Name;
        }
    }
    
    public String title {
        get {
            if (SOId == null) {
                return 'New Sales Quote';
            } else {
                return theSO.Name;
            }
        }
    }
    
    public PageReference EmailSalesQuote() {
        Messaging.SingleEmailMessage theEmail = new Messaging.SingleEmailMessage();
        PageReference pdf =  Page.SalesQuotePDF;
        pdf.getParameters().put('id',(String)theSO.Id);
        pdf.getParameters().put('printType', selPrintType);
        pdf.getParameters().put('printEstimatedDuration', String.valueOf(printEstimatedDuration));
        pdf.setRedirect(true);
        Blob b;
        if (Test.isRunningTest())
        {
            b = Blob.valueOf('UNIT.TEST');
        }
        else {
            b = pdf.getContent();
        }

        List<Messaging.EmailFileAttachment> attachments = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(theSO.Name+'.pdf');
        efa.setBody(b);
        attachments.add(efa);

        if(file.Body != null){
            Messaging.EmailFileAttachment efa2 = new Messaging.EmailFileAttachment();
            efa2.setFileName(file.Name);
            efa2.setBody(file.Body);
            attachments.add(efa2);
        }

        if (Test.isRunningTest())
        {
            theToAddresses = 'test@test.com;abc@abc.com';
        }
        /*else if (UserInfo.getOrganizationId() != '00Df40000000Ns9EAE') {
            theToAddresses = 'rvandra@acvenviro.com;dscerbo@acvenviro.com;jmarcotte@acvenviro.com';
        }*/

        String[] toAddressesNew = new String[]{};
        if (theToAddresses != null) {
            toAddressesNew = theToAddresses.split(';');
        }

        for(Integer i = 0; i < toAddressesNew.size(); i++){
            if(String.isEmpty(toAddressesNew[i])){
                toAddressesNew.remove(i);
            }
        }

        if (Test.isRunningTest())
        {
            theCcAddresses = 'test@test.com;abc@abc.com';
        }

        if(CompanySettingUtil.isSandbox() == true){
            toAddressesNew = new List<String>{UserInfo.getUserEmail()};
        }

        String[] ccNew = new String[]{};
        if (theCcAddresses != null) {
            ccNew = theCcAddresses.split(';');
        }

        for(Integer i = 0; i < ccNew.size();i++){
            if(String.isEmpty(ccNew[i])){
                ccNew.remove(i);
            }
        }

        //Ticket#19910 add sender to cc address
        if(String.isNotBlank(UserInfo.getUserEmail())) {
            ccNew.add(UserInfo.getUserEmail());
            theEmail.setReplyTo(UserInfo.getUserEmail());
        }

        theEmail.setSubject(theSubject);
        theEmail.setToAddresses(toAddressesNew);
        theEmail.setCcAddresses(ccNew);

        //theEmail.setPlainTextBody(theBody);
        theEmail.setHtmlBody(theBody);
        theEmail.setSenderDisplayName(UserInfo.getName());

        if(isTest != true && CompanySettingUtil.isSandbox() != true){
            theEmail.setTargetObjectId(theContactList[0].Id);
            theEmail.setWhatId(theSO.Id);
            theEmail.setSaveAsActivity(true);
        }

        theEmail.setFileAttachments(attachments);
        
        try {
            Messaging.SendEmailResult [] r =
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {theEmail});

            List<String> errors = new List<String>();
            for (Messaging.SendEmailResult result : r) {
                if (result.isSuccess() != true) {
                    List<Messaging.SendEmailError> sendEmailErrors = result.getErrors();
                    for (Messaging.SendEmailError sendEmailError : sendEmailErrors) {
                        errors.add(sendEmailError.message);
                    }
                }
            }
            if (errors.size() > 0) {
                throw new DataException(String.join(errors, ';'));
            }
        } catch(Exception e) {
            System.debug('Error: ' + e.getMessage() + ' ' + e.getStackTraceString());
            ApexPages.addMessages(e);
            return  null;
        }
        return theController.view();
    }
    
    public PageReference returnBack() {
        return theController.view();
    }

    //ticket 21113 <<
    public static Blob generateQuotePDF(Id quoteId) {
        Sales_Order__c quote = [SELECT Id, Report_Parameter_Print_Type__c, Report_Parameter_Print_Estimate_Duration__c FROM Sales_Order__c WHERE Id = :quoteId LIMIT 1];
        if (quote.Report_Parameter_Print_Type__c == null) {
            quote.Report_Parameter_Print_Type__c = 'Detail';
        }

        Blob pdf;
        if (Test.isRunningTest()) {
            pdf = Blob.valueOf('test');
        }
        else {
            PageReference pageRef = Page.SalesQuotePDF;
            pageRef.getParameters().put('id', (String) quote.Id);
            pageRef.getParameters().put('printType', quote.Report_Parameter_Print_Type__c);
            pageRef.getParameters().put('printEstimatedDuration', String.valueOf(quote.Report_Parameter_Print_Estimate_Duration__c == true));
            pageRef.setRedirect(true);
            pdf = pageRef.getContentAsPDF();
        }
        return pdf;
    }

    public static void saveQuotePDF(Sales_Order__c quote, Blob pdf, String filename) {
        //String filename = quote.Name + '_' + System.now().format('yyyyMMddhhmmss') + '.pdf';
        Attachment attachment = new Attachment();
        attachment.Name = filename;
        attachment.body = pdf;
        attachment.ParentId = quote.Id;
        attachment.IsPrivate = false;
        insert attachment;
    }

    public static void sendQuotePDF(Sales_Order__c quote, Blob pdf) {
        List<Signature__c> signatures = [SELECT Id, Email__c, Request_Signature__c, Signed__c FROM Signature__c WHERE Sales_Order__c = :quote.Id AND Voided__c != TRUE];
        //ticket 21113 >>
        if (CompanyMgmt.getEmailDeliverability() == true) {
            List<String> recipients = new List<String>();
            for (Signature__c signature : signatures) {
                if (signature.Email__c != null) {
                    if (!recipients.contains(signature.Email__c)) {
                        recipients.add(signature.Email__c);
                    }
                }
            }

            List<String> ccs = new List<String>();
            if(!Test.isRunningTest())
                ccs.add(quote.CreatedBy.Email);
  
            if (MobileTMController.testRecipients(recipients) == true) {
                Integer signedCount = 0;
                Integer requestCount = 0;
                for (Signature__c signature : signatures) {
                    if (signature.Signed__c == true) {
                        signedCount++;
                    }
                    else if (signature.Request_Signature__c == true) {
                        requestCount++;
                    }
                }
                String emailTemplateName = 'Quote PDF Email';
                List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE Name = :emailTemplateName];
                if (emailTemplates.size() == 0) {
                    throw new DataException('Email template "Quote PDF Email" must be set up to send the pdf to customers.');
                }

                Id emailTemplateId = emailTemplates[0].Id;
                List<Messaging.SingleEmailMessage> messages = new List<Messaging.SingleEmailMessage>();

                messages.add(createEmail(quote.Id, emailTemplateId, recipients, ccs, quote.Name, pdf));
                Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                if (results.size() > 0) {
                    Messaging.SendEmailResult result = results[0];
                    if (!result.success) {
                        throw new DataException(String.join(result.getErrors(), ';'));
                    }
                }
            }
        }
    }

    //Ticket#24977 - add account executives as one of the notification recipient
    public static void notifySignedQuote(Signature_Request__c signatureRequest) {
        try {
            if (signatureRequest.Related_To_Id__c != null) {
                List<Sales_Order__c> salesOrders = [SELECT Name, CreatedById, Account_Executives__r.User__c FROM Sales_Order__c WHERE Id = :signatureRequest.Related_To_Id__c];
                if (salesOrders.size() > 0) {
                    Sales_Order__c quote = salesOrders[0];
                    String emailBody = 'Customer has signed ' + quote.Name + '.\n'
                            + 'Customer Name: ' + (signatureRequest.Print_Name__c != null ? signatureRequest.Print_Name__c : '') + '\n'
                            + 'Customer Email: ' + (signatureRequest.Email__c != null ? signatureRequest.Email__c : '') + '\n'
                            + 'Customer PO No.: ' + (signatureRequest.Customer_PO_No__c != null ? signatureRequest.Customer_PO_No__c : '') + '\n'
                            + 'Customer Comment: ' + (signatureRequest.Customer_Comment__c != null ? signatureRequest.Customer_Comment__c : '');
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.setToAddresses(new List<String>{
                            quote.CreatedById, quote.Account_Executives__r.User__c
                    });
                    message.setSubject('Quote Signed ' + quote.Name);
                    message.setPlainTextBody(emailBody);
                    message.setWhatId(quote.Id);
                    message.setSaveAsActivity(true);
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{
                            message
                    });
                }
            }
        }
        catch (Exception ex) {
            //email error should not affect the signature update
        }
    }

    //Ticket#24977 - add account executives as one of the notification recipient
    public static void notifyRejectedQuote(Signature_Request__c signatureRequest) {
        try {
            if (signatureRequest.Related_To_Id__c != null) {
                List<Sales_Order__c> salesOrders = [SELECT Name, Quote_Contact__c, CreatedById, Account_Executives__r.User__c FROM Sales_Order__c WHERE Id = :signatureRequest.Related_To_Id__c];
                if (salesOrders.size() > 0) {
                    Sales_Order__c quote = salesOrders[0];

                    createTask(quote.Id, quote.Quote_Contact__c, 'Customer has REJECTED the signature request. Please follow up.', quote.CreatedById);

                    String emailBody = 'Customer has rejected ' + quote.Name + '.\n'
                            + 'Customer Name: ' + (signatureRequest.Print_Name__c != null ? signatureRequest.Print_Name__c : '') + '\n'
                            + 'Customer Email: ' + (signatureRequest.Email__c != null ? signatureRequest.Email__c : '') + '\n'
                            + 'Customer PO No.: ' + (signatureRequest.Customer_PO_No__c != null ? signatureRequest.Customer_PO_No__c : '') + '\n'
                            + 'Customer Comment: ' + (signatureRequest.Customer_Comment__c != null ? signatureRequest.Customer_Comment__c : '');
                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.setToAddresses(new List<String>{
                            quote.CreatedById, quote.Account_Executives__r.User__c
                    });
                    message.setSubject('Quote Rejected ' + quote.Name);
                    message.setPlainTextBody(emailBody);
                    message.setWhatId(quote.Id);
                    message.setSaveAsActivity(true);
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{
                            message
                    });
                }
            }
        }
        catch (Exception ex) {
            //email error should not affect the signature update
        }
    }

    //Ticket#24977 - add account executives as one of the notification recipient
    public static void notifyUnansweredSignatureRequest(Signature_Request__c signatureRequest) {
        try {
            if (signatureRequest.Related_To_Id__c != null) {
                List<Sales_Order__c> salesOrders = [SELECT Name, Quote_Contact__c, CreatedById, Account_Executives__r.User__c FROM Sales_Order__c WHERE Id = :signatureRequest.Related_To_Id__c];
                if (salesOrders.size() > 0) {
                    Sales_Order__c quote = salesOrders[0];

                    createTask(quote.Id, quote.Quote_Contact__c, 'Customer has NOT YET RESPONDED to the signature request. Please follow up.', quote.CreatedById);

                    String emailBody = 'Customer has not responded to the signature request for ' + quote.Name + '.\n'
                            + 'Customer Name: ' + (signatureRequest.Print_Name__c != null ? signatureRequest.Print_Name__c : '') + '\n'
                            + 'Customer Email: ' + (signatureRequest.Email__c != null ? signatureRequest.Email__c : '') + '\n'
                            + 'Signature Request Date: ' + signatureRequest.Request_Date__c.date() + '\n';

                    Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                    message.setToAddresses(new List<String>{
                            quote.CreatedById, quote.Account_Executives__r.User__c
                    });
                    message.setSubject('Quote Signature Request Unanswered Reminder ' + quote.Name);
                    message.setPlainTextBody(emailBody);
                    message.setWhatId(quote.Id);
                    message.setSaveAsActivity(true);
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{
                            message
                    });
                }
            }
        }
        catch (Exception ex) {
            //email error should not affect the signature update
        }
    }

    public static Messaging.SingleEmailMessage createEmail(Id whatId, Id emailTemplateId, List<String> recipients, List<String> ccs, String filename, Blob pdf) {
        OrgWideEmailAddress orgWideEmailAddr = [SELECT Id FROM OrgWideEmailAddress WHERE DisplayName = 'Republic Services' LIMIT 1]; //Ticket#25097

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setWhatId(whatId);
        message.setToAddresses(recipients);
        if (ccs != null) {
            message.setCcAddresses(ccs);
        }
        
        if(Test.isRunningTest())
        {
          ccs.add('test@gamil.com');
          message.setCcAddresses(ccs);
        }
          
        message.setTreatTargetObjectAsRecipient(true);
        message.setOrgWideEmailAddressId(orgWideEmailAddr.Id);
        message.setTemplateId(emailTemplateId);

        //generate email subject and body from the template
        Savepoint sp = Database.setSavepoint();
        Contact contact = new Contact(LastName='DummyContact');
        contact.Contact_Type__c = 'Site';
        contact.Email = 'dummyemail@fromdummycontact.com';
        insert contact;
        message.setTargetObjectId(contact.Id);
        system.debug('Message++++++++++++ ' +message);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
        Database.rollback(sp);

        //create a message utilizing the email subject and body
        Messaging.SingleEmailMessage messageToSend = new Messaging.SingleEmailMessage();
        messageToSend.setOrgWideEmailAddressId(message.getOrgWideEmailAddressId());
        messageToSend.setToAddresses(message.getToAddresses());
        messageToSend.setPlainTextBody(message.getPlainTextBody());
        messageToSend.setHtmlBody(message.getHtmlBody());
        messageToSend.setSubject(message.getSubject());
        messageToSend.setWhatId(message.getWhatId());
        messageToSend.setSaveAsActivity(true);

        if (pdf != null) {
            Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
            attachment.setFileName(filename + '.pdf');
            attachment.setBody(pdf);
            messageToSend.setFileAttachments(new Messaging.EmailFileAttachment[]{
                    attachment
            });
        }

        return messageToSend;
    }


    public static void createTask(Id recordId, Id contactId, String subject, Id assignToId) {
        Task task = new Task();
        task.WhoId = contactId;
        task.OwnerId = assignToId;
        task.Subject = subject;
        task.WhatId = recordId;
        task.Priority = 'Normal';
        task.Status = 'Open';
        task.ActivityDate = system.today();
        insert task;
    }
    //ticket 21113 >>
}
