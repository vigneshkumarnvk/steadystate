public interface ISalesInvoiceLinesSelector {
    List<Sales_Invoice_Line__c> selectByIds(Set<Id> ids);
    List<Sales_Invoice_Line__c> selectPostedInvoiceLinesByTMLineIds(Set<Id> ids);
    List<Sales_Invoice_Line__c> selectByInvoiceId(Id id);
    List<Sales_Invoice_Line__c> selectByInvoiceIds(Set<Id> ids);
    List<Sales_Invoice_Line__c> selectLinesByInvoiceId(Id id);
    List<Sales_Invoice_Line__c> selectApprovedCreditMemoWorksheetByTMLineIds(Set<Id> tmLineIds);
}