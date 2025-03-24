global with sharing class ACVSalesOrderJobTaskWrapper {
    @AuraEnabled
    public Sales_Order_Job_Task__c JobTask { set; get; }

    @AuraEnabled
    public List<Sales_Line__c> SalesLines { set; get; }

    @AuraEnabled
    public Boolean Collapsed { set; get; }

    //ticket 20177 <<
    @AuraEnabled
    public Boolean HasTMs { set; get; }
    @AuraEnabled
    public Boolean HasInvoices { set; get; }
    //ticket 20177 >>

    //ticket 19130 05.03.2023 <<
    @AuraEnabled
    public Integer NextSalesLineNo { set; get; }
    //ticket 19130 05.03.2023 >>

    public ACVSalesOrderJobTaskWrapper() {
        this.SalesLines = new List<Sales_Line__c>();
    }

    public ACVSalesOrderJobTaskWrapper(Sales_Order_Job_Task__c jobTask, List<Sales_Line__c> salesLines) {
        this.JobTask = jobTask;
        this.SalesLines = salesLines;
    }
}