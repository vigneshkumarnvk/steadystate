public interface ISalesInvoicesSelector extends fflib_ISObjectSelector{
    List<Sales_Invoice__c> selectById(Set<Id> idSet);
    List<Sales_Invoice__c> selectLineCountById(Set<Id> idSet);
    List<Sales_Invoice__c> selectByIdWithSILines(Set<Id> idSet);
    List<Sales_Invoice__c> selectByIdWithSILinesForReverse(Set<Id> idSet);
    List<Sales_Invoice__c> selectPOBySalesOrderId(Set<Id> idSet);
    List<Sales_Invoice__c> selectOpenCreditMemoWorksheetWithLines(Id id);
    List<Sales_Invoice__c> selectCreditMemoWorksheetsWithChangedLines(Id id);
    List<Sales_Invoice__c> selectByIdWithLinesAndProcessSteps(Set<Id> ids);
}