public interface ISalesInvoicesService {
	Sales_Invoice__c createCreditMemo(Sales_Invoice__c recordToReverse, Id creditMemoWorksheetId);
	void submitForApproval(Id recordId);
    void submitForApproval(Id recordId, Boolean isInitialApprovalRequest);
    /*
     * Ticket#16912
     * add approval comment
     */
    void submitForApproval(Id recordId, Boolean isInitialApprovalRequest, String comment);
	Map<Id, String> getParentInvIdWithNextReversionInvNum(Set<Id> tmIds, Set<Id> tmlIds);
	Decimal calcSurchargeAmount(Sales_Invoice__c salesInvoice, List<Sales_Invoice_Line__c> salesInvoiceLines);
}