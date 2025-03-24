public interface ISalesInvoiceLinesService {
    void initStaticVariables(Sales_Invoice__c salesInvoice, List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers);
    void assignDescription(Sales_Invoice_Line__c salesInvoiceLine);
    void assignUnitOfMeasure(Sales_Invoice_Line__c salesInvoiceLine);
    void assignResourceTypeUOM(Sales_Invoice_Line__c salesInvoiceLine);
    void assignResourceUOM(Sales_Invoice_Line__c salesInvoiceLine);
    void calcUnitCost(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine);
    void assignTaxPercent(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine);
    void calculateLineTotals(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine);
}