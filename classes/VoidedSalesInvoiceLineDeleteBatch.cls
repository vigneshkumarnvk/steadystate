public with sharing class VoidedSalesInvoiceLineDeleteBatch implements Database.Batchable<Sales_Invoice__c>{
    public List<Sales_Invoice__c> start(Database.BatchableContext bc) {
        List<Sales_Invoice__c> salesInvoices = [
                SELECT Id, Invoice_Date__c, TempProcessed__c
                FROM Sales_Invoice__c
                WHERE Invoice_Date__c < 2021-01-01 AND Document_Status__c = 'Void' AND TempProcessed__c = FALSE
                ORDER BY Invoice_Date__c ASC
        ];
        return salesInvoices;
    }

    public void execute(Database.BatchableContext BC, List<Sales_Invoice__c> salesInvoices){

        Set<Id> invoiceIds = new Set<Id>();

        for (Sales_Invoice__c salesInvoice : salesInvoices) {
            invoiceIds.add(salesInvoice.Id);
            salesInvoice.TempProcessed__c = true;
        }

        List<Sales_Invoice_Line__c> salesInvoiceLines = [SELECT Id FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c IN :invoiceIds];

        CompanyMgmt.byPassLineTrigger = true;
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.systemCall = true;

        if(salesInvoiceLines.size() > 0) {
            Database.delete(salesInvoiceLines, false);
        }

        Database.update(salesInvoices, false);
    }

    public void finish(Database.BatchableContext BC){

    }
}