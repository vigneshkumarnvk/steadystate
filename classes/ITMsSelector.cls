public interface ITMsSelector extends fflib_ISObjectSelector{
    List<TM__c> selectByIds(Set<Id> idSet);
    List<TM__c> selectByIdWithTMLines(Set<Id> idSet);
    List<TM__c> selectCreateInvoiceRequiredFieldsById(Set<Id> idSet);
    List<TM__c> selectCreateInvoiceHeaderRequiredFieldsById(Set<Id> idSet);
    List<TM__c> selectTMLineNOById(Set<Id> idSet);
    List<TM__c> selectPOBySalesOrderId(Set<Id> idSet);
    List<TM__c> selectOpenTMsBySalesOrderIdWithLines(Id salesOrderId);
    List<TM__c> selectOpenTMsBySalesOrderIdAndInvoiceIdWithLines(Id salesOrderId, Set<Id> invIds);
    List<TM__c> selectTMsBySalesOrderIds(Set<Id> salesOrderIds); //Sales Order Route
}