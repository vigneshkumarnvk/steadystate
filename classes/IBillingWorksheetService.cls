public interface IBillingWorksheetService {
    void initStaticVariables(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers);
    void calcUnitPrice(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine);
    void calcUnitCost(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine);
    void assignResourceTypeUOM(Billing_Worksheet_Line__c worksheetLine);
    void assignResourceUOM(Billing_Worksheet_Line__c worksheetLine);
    void assignTaxPercent(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine);
    void assignDescription(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine);
    void validateContractLine(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine);
    void calculateLineTotals(Billing_Worksheet_Line__c worksheetLine, Boolean reCalCostQty);
    //ticket 19130 <<
    //List<Billing_Worksheet_Line__c> calculatePresumptiveChildLines(Billing_Worksheet_Line__c worksheetLine, Integer nextWorksheetLineNo);
    //ticket 19130 >>
    void validateSalesInvoice(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers);
    Sales_Invoice__c createSalesInvoice(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers);
    void calculateLaborHours(Id salesOrderId, List<Billing_Worksheet_Line__c> worksheetLines);
    void calculateLaborHours(Id salesOrderId, List<Billing_Worksheet_Line__c> worksheetLines, Billing_Worksheet_Line__c worksheetLine);
    void populateWasteDisposalLineInfo(List<Billing_Worksheet_Line__c> worksheetLines);
}