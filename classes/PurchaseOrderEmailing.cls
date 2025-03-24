public class PurchaseOrderEmailing {

    private final ApexPages.StandardController theController;
    public final Purchase_Order__c thePO{get; set;}
    public final Contact[] theContactList{get; set;}
    public final Company_setup__c theCompanySetup {get;set;}
    public static String theToAddresses{get;set;}
    public static String theCcAddresses{get;set;}
    public static String theBody{get;set;}
    public static String theSubject{get;set;}
    private String POId;
    public boolean showEmail{get;set;}
    public Boolean isTest{get; set;}
    public Attachment file {
        get {
            if (file == null) file = new Attachment();
            return file;
        }
        set;
    }

    public  PurchaseOrderEmailing(ApexPages.StandardController controller) {
        theController = controller;
        POId = ApexPages.CurrentPage().getParameters().get('id');
        thePO = [SELECT Id, Name, Document_Status__c, E_Mail__c, Billing_Contact__c, Billing_Contact__r.Name,
                    Buy_from_Vendor__c, Buy_from_Vendor__r.Name
                    FROM Purchase_Order__c WHERE Id =: POId];
        theContactList = [SELECT Id, Name, Email FROM Contact WHERE Id =: thePO.Billing_Contact__c];

        showEmail = true;

        if(theContactList.size() == 0){
            showEmail = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Purchasing Contact cannot be blank for purchase order ' + thePO.Name));
        }

        if((thePO.Document_Status__c == 'Open') || thePO.Document_Status__c =='Pending Approval') {
            showEmail = false;
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Document Status must be approved'));
        }

        if(showEmail){
            
            theToAddresses = theContactList[0].Email;
            theSubject = 'Purchase Order ' + thePO.Name + '---' + thePO.Buy_from_Vendor__r.Name;
            theBody = 'Attached please find PO No. ' + thePO.Name + '. Let me know if you have any question. Otherwise, please confirm receipt.';
        }
    }

    public String title {
        get {
            if (POId == null) {
                return 'New Invoice';
            } else {
                return thePO.Name;
            }
        }
    }

    public PageReference EmailPO() {

        Messaging.SingleEmailMessage theEmail = new Messaging.SingleEmailMessage();
        PageReference pdf =  Page.PurchaseOrderPDF;
        pdf.getParameters().put('id',(String)thePO.Id);
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
        efa.setFileName(thePO.Name+'.pdf');
        efa.setBody(b);
        attachments.add(efa);

        if(file.Body != null){
            Messaging.EmailFileAttachment efa2 = new Messaging.EmailFileAttachment();
            efa2.setFileName(file.Name);
            efa2.setBody(file.Body);
            attachments.add(efa2);
        }

        if (Test.isRunningTest()) {
            theToAddresses = 'test@test.com;abc@abc.com';
        }
        /*else if (UserInfo.getOrganizationId() != '00Df40000000Ns9EAE') {
            theToAddresses = 'rvandra@acvenviro.com;dscerbo@acvenviro.com;jmarcotte@acvenviro.com';
        }*/

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

        if (Test.isRunningTest()) {
            theCcAddresses = 'test@test.com;abc@abc.com';
        }

        //fix null error <<
        //String[] ccNew = theCcAddresses.split(';');
        String[] ccNew = new String[]{};
        if (theCcAddresses != null) {
            ccNew = theCcAddresses.split(';');
        }
        //fix null error >>

        for(Integer i = 0; i < ccNew.size(); i++){
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
            theEmail.setWhatId(thePO.Id);
            theEmail.setSaveAsActivity(true);
        }

        //theEmail.setFileAttachments(new Messaging.EmailFileAttachment[] {efa});
        theEmail.setFileAttachments(attachments);

        try {
            Messaging.SendEmailResult [] r =
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] {theEmail});
        } catch(Exception e) {
            System.debug('Error: ' + e.getMessage());
        }
        return theController.view();
    }

    public PageReference returnBack() {
        return theController.view();
    }
}