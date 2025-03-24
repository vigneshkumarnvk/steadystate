/**
 * Created by Steven on 6/5/2018.
 */

public with sharing class SalesInvoiceEmailing {
    private final ApexPages.StandardController theController;
    public final Sales_Invoice__c theSI{get; set;}
    public final Contact[] theContactList{get; set;}
    public final Company_Setup__c theCompanySetup {get;set;}
    public static String theToAddresses{get;set;}
    public static String theCcAddresses{get;set;}
    public static String theBody{get;set;}
    public static String theSubject{get;set;}
    private String SalesInvId;
    public Boolean showEmail{get;set;}
    public String selInvoiceType { get; set; }
    public Boolean isTest{get; set;}
    public Attachment file {
        get {
            if (file == null) file = new Attachment();
            return file;
        }
        set;
    }

    public SalesInvoiceEmailing(ApexPages.StandardController controller){
        theController = controller;
        SalesInvId = ApexPages.currentPage().getParameters().get('id');
        System.debug('<==SalesInvId==>'+SalesInvId);
        theSI = [SELECT Id, Name, Contact__c, Contact__r.Name,
                Contact__r.Email,Bill_to_Customer__r.Name
        FROM Sales_Invoice__c WHERE Id = :SalesInvId LIMIT 1];

        theContactList = [SELECT Id, Name, Email FROM Contact WHERE Id =: theSI.Contact__c];

        showEmail = true;

        if(theContactList.size() == 0){
            showEmail = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Billing Contact is blank for invoice: ' + theSI.Name));
        }

        if(showEmail){
            theToAddresses = theContactList[0].Email;
            theSubject = 'Sales Invoice ' + theSI.Name + '---' + theSI.Bill_to_Customer__r.Name;
            theBody = 'Attached please find Republic Services Sales Invoice number ' + theSI.Name + '.\r\n' +
                    'Should you have any questions, please contact us. If no questions, please confirm receipt of the sales invoice by replying to this email.' + '\r\n' +
                    'Thank you for your prompt attention,';
        }
    }

    public String title {
        get {
            if (SalesInvId == null) {
                return 'New Purchase Order';
            } else {
                return theSI.Name;
            }
        }
    }

    public PageReference EmailSI() {

        Messaging.SingleEmailMessage theEmail = new Messaging.SingleEmailMessage();
        PageReference pdf =  Page.SalesInvoicePdf;

        pdf.getParameters().put('id',(String)theSI.Id);
        pdf.getParameters().put('PrintCopy', 'None');
        pdf.getParameters().put('InvoiceType', selInvoiceType);
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
        efa.setFileName(theSI.Name+'.pdf');
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
        //fix null error <<
        //String[] toAddressesNew = theToAddresses.split(';');
        String[] toAddressesNew = new String[]{};
        if (theToAddresses != null) {
            toAddressesNew = theToAddresses.split(';');
        }
        //fix null error >>

        for(Integer i = 0; i < toAddressesNew.size(); i++){
            if(String.isEmpty(toAddressesNew[i])){
                toAddressesNew.remove(i);
            }
        }


        if (Test.isRunningTest())
        {
            theCcAddresses = 'test@test.com;abc@abc.com';
        }

        //fix null error <<
        //String[] ccNew = theCcAddresses.split(';');
        String[] ccNew = new String[]{};
        if (theCcAddresses != null) {
            ccNew = theCcAddresses.split(';');
        }
        //fix null error >>

        for(Integer i = 0; i < ccNew.size();i++){
            if(String.isEmpty(ccNew[i])){
                ccNew.remove(i);
            }
        }

        if(CompanySettingUtil.isSandbox() == true){
            //toAddressesNew = CompanySettingUtil.getSandboxEmailRecipients();
            toAddressesNew = new List<String>{UserInfo.getUserEmail()};
        }

        theEmail.setSubject(theSubject);
        theEmail.setToAddresses(toAddressesNew);
        theEmail.setCcAddresses(ccNew);
        theEmail.setPlainTextBody(theBody);
        theEmail.setSenderDisplayName(UserInfo.getName());
        if(isTest != true && CompanySettingUtil.isSandbox() != true) {
            theEmail.setTargetObjectId(theContactList[0].Id);
            theEmail.setWhatId(theSI.Id);
            theEmail.setSaveAsActivity(true);
        }

        theEmail.setFileAttachments(attachments);

        try {
            Messaging.SendEmailResult [] r =
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {theEmail});

            theSI.Sales_Invoice_Emailed__c = true;

            CompanyMgmt.byPassLineTrigger = true;
            CompanyMgmt.byPassTrigger = true;
            update theSI;

        } catch(Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        return theController.view();
    }

    public PageReference returnBack() {
        return theController.view();
    }

    public List<SelectOption> lstInvoiceType {
        get {
            if (lstInvoiceType == null) {
                lstInvoiceType = new List<SelectOption>();
                lstInvoiceType.add(new SelectOption('TM Detail', 'T&M Detail'));
                lstInvoiceType.add(new SelectOption('TM Summary', 'T&M Summary'));
                lstInvoiceType.add(new SelectOption('TM Lump Sum', 'T&M Lump Sum'));
                lstInvoiceType.add(new SelectOption('TM by Date by Category', 'T&M by Date by Category'));
            }
            return lstInvoiceType;
        }
        set;
    }
}