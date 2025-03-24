global with sharing class BillingWorksheetWrapper {
    @AuraEnabled
    public Sales_Order_Job_Task__c SalesOrderJobTask { set; get; }
    @AuraEnabled
    public List<RelatedInfo> RelatedInfos { set; get; }
    @AuraEnabled
    public List<Sales_Line__c> LumpSumLines { set; get; }
    @AuraEnabled
    public List<Billing_Worksheet_Line__c> WorksheetLines { set; get; }
    @AuraEnabled
    public List<Billing_Worksheet_Line__c> DeletedWorksheetLines { set; get; }
    @AuraEnabled
    public Boolean Collapsed { set; get; }
    //Ticket#19663 >>
    @AuraEnabled
    public Id PayRuleId {set; get; }
    @AuraEnabled
    public Boolean IsPayRuleCostUpdateCall {set; get;}
    //Ticket#19663 >>
    public BillingWorksheetWrapper() {
        this.RelatedInfos = new List<RelatedInfo>(); //by sales order job task
        this.LumpSumLines = new List<Sales_Line__c>();
        this.WorksheetLines = new List<Billing_Worksheet_Line__c>();
        this.DeletedWorksheetLines = new List<Billing_Worksheet_Line__c>();
        //Ticket#19663 >>
        this.PayRuleId = null;
        this.IsPayRuleCostUpdateCall = false;
        //Ticket#19663 >>
    }

    public class RelatedInfo {
        @AuraEnabled
        public TM__c TM { set; get; }
        @AuraEnabled
        //public List<TM_Job_Task__c> TMJobTasks;
        public TM_Job_Task__c TMJobTask;
        @AuraEnabled
        public String FieldTMPDFUrl { set; get; }
        @AuraEnabled
        public Boolean HasToInvoiceLines { set; get; }

        public RelatedInfo() {
            //this.TMJobTasks = new List<TM_Job_Task__c>();
        } 
    }
}