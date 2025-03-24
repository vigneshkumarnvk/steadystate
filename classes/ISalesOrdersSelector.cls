public interface ISalesOrdersSelector extends fflib_ISObjectSelector{
    List<Sales_Order__c> selectById(Set<Id> idSet);
    List<Sales_Order__c> selectCreateInvoiceRequiredFieldsById(Set<Id> idSet);
	List<Sales_Order__c> selectByIdWithLinesForClone(Set<Id> idSet);
    List<Sales_Order__c> selectConvertRelatedFieldsById(Set<Id> idSet);
	List<Sales_Order__c> selectTMsById(Set<Id> idSet);
	List<Sales_Order__c> selectServiceCenterById(Set<Id> idSet);
	List<Sales_Order__c> selectServiceCenterAndSubCompanyById(Set<Id> idSet);
	List<Sales_Order__c> selectQuotesByBillToCustomer(Id billToCustomer);
    List<Sales_Order__c> selectConvertCountById(Set<Id> idSet);
    List<Sales_Order__c> selectByIdWithSalesLines(Set<Id> ids);
    List<Sales_Order__c> selectByIdWithLinesAndProcessSteps(Set<Id> ids);
    List<Sales_Order__c> selectByContractIdsWithLines(Set<Id> contractIds);
}