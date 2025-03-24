public interface IBillingWorksheetLinesSelector {
    List<Billing_Worksheet_Line__c> selectById(Set<Id> idSet);
    List<Billing_Worksheet_Line__c> selectBySalesOrderJobTaskId(Set<Id> salesOrderJobTaskIds, List<String> filters);
    List<Billing_Worksheet_Line__c> selectOpenLinesBySalesOrderId(Set<Id> salesOrderIds);
    List<Billing_Worksheet_Line__c> selectOpenLinesByTMIds(Set<Id> tmIds);
    List<Billing_Worksheet_Line__c> selectBillingWorksheetLinesWithZeroCost();
}