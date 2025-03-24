global with sharing class ACVSalesInvoiceJobTaskWrapper {
    @AuraEnabled
    public Sales_Invoice_Job_Task__c JobTask { get; set; }

    @AuraEnabled
    public List<Sales_Invoice_Line__c> SalesInvoiceLines { set; get; }

    @AuraEnabled
    public Boolean Collapsed { set; get; }

    public ACVSalesInvoiceJobTaskWrapper() {
        this.JobTask = new Sales_Invoice_Job_Task__c();
        this.SalesInvoiceLines = new List<Sales_Invoice_Line__c>();
    }

    public ACVSalesInvoiceJobTaskWrapper(Sales_Invoice_Job_Task__c jobTask, List<Sales_Invoice_Line__c> invoiceLines) {
        this.JobTask = jobTask;
        this.SalesInvoiceLines = invoiceLines;
    }
}