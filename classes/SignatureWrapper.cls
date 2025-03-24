public with sharing class SignatureWrapper {

    @AuraEnabled
    public Id SignatureId { set; get; }
    @AuraEnabled
    public String Name { set; get; }
    @AuraEnabled
    public String PrintName { set; get; }
    @AuraEnabled
    public Boolean AcceptTerms { set; get; }
    @AuraEnabled
    public DateTime SignatureDate { set; get; }
    @AuraEnabled
    public Boolean NotAvailable { set; get; }
    @AuraEnabled
    public String Email { set; get; }
    @AuraEnabled
    public String SignatureData { set; get; }
    @AuraEnabled
    public Boolean Signed { set; get; }
    @AuraEnabled
    public Boolean RequestSignature { set; get; }
    @AuraEnabled
    public Id SignatureRequestId { set; get; }
    @AuraEnabled
    public Boolean SignatureRequestEmailSent { set; get; }
    @AuraEnabled
    public Id TMId { set; get; }
    //ticket 21113 <<
    @AuraEnabled
    public String RelatedToObjectName { set; get; }
    @AuraEnabled
    public String RelatedToId { set; get; }
    @AuraEnabled
    public String CustomerPONo { set; get; }
    @AuraEnabled
    public String CustomerComment { set; get; }
    @AuraEnabled
    public Boolean Declined { set; get; }
    //ticket 21113 >>
    @AuraEnabled
    public String SiteAccessToken { set; get; }
    @AuraEnabled
    public String IPAddress { set; get; }
    @AuraEnabled
    public String SignerRole { set; get; }

    //ticket 21770 <<
    @AuraEnabled
    public String TermsAndConditions { set; get; }
    //ticket 21770 >>

    public SignatureWrapper() {
    }

    public SignatureWrapper(Signature__c signature) {
        this.SignatureId = signature.Id;
        this.Name = signature.Name;
        this.PrintName = signature.Print_Name__c;
        this.AcceptTerms = signature.Accept_Terms_and_Conditions__c;
        this.SignatureDate = signature.Signature_Date__c;
        this.NotAvailable = signature.Customer_Not_Available__c;
        this.Email = signature.Email__c;
        this.Signed = signature.Signed__c;
        this.TMId = signature.TM__c;
        //ticket 21113 <<
        this.RelatedToObjectName = signature.Related_To_Object_Name__c;
        if (signature.Related_To_Object_Name__c == 'Sales_Order__c') {
            this.RelatedToId = signature.Sales_Order__c;
        }
        else {
            this.RelatedToId = signature.TM__c;
        }
        this.Declined = signature.Declined__c;
        this.CustomerPONo = signature.Customer_PO_No__c;
        this.CustomerComment = signature.Customer_Comment__c;
        //ticket 21113 >>
        this.RequestSignature = signature.Request_Signature__c;
        this.SignatureRequestEmailSent = signature.Signature_Request_Email_Sent__c;
        this.SignatureRequestId = signature.Signature_Request__c;
        this.SiteAccessToken = signature.Site_Access_Token__c;
        this.SignerRole = signature.Signer_Role__c;
    }

    public Signature__c toRecord() { 
        if (this.TMId == null) {
            throw new DataException('TM Id is required.');
        }
        Signature__c signature = new Signature__c();
        signature.Id = this.SignatureId;
        signature.Name = this.Name;
        signature.Print_Name__c = this.PrintName;
        signature.Accept_Terms_and_Conditions__c = (this.AcceptTerms == true);
        signature.Signature_Date__c = this.SignatureDate;
        signature.Customer_Not_Available__c = (this.NotAvailable == true);
        signature.Email__c = this.Email;
        if (this.SignatureId == null) {
            signature.TM__c = this.TMId;
        }
        signature.Request_Signature__c = (this.RequestSignature == true);
        signature.Signature_Request__c = this.SignatureRequestId;
        signature.Signed__c = (this.SignatureData != null);
        signature.Signer_Role__c = this.SignerRole;
        //ticket 21113 <<
        signature.Related_To_Object_Name__c = 'TM__c';
        signature.Related_To_Id__c = this.TMId;
        signature.Declined__c = (this.Declined == true);
        signature.Customer_PO_No__c = this.CustomerPONo;
        signature.Customer_Comment__c = this.CustomerComment;
        //ticket 21113 >>
        return signature;
    }
}