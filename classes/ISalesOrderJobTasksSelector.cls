public interface ISalesOrderJobTasksSelector {
    List<Sales_Order_Job_Task__c> selectById(Set<Id> idSet);
    List<Sales_Order_Job_Task__c> selectBySalesOrderId(Set<Id> idSet);
    //ticket 20566 <<
    List<Sales_Order_Job_Task__c> selectBySalesOrderId2(Set<Id> idSet);
    //ticket 20566 >>
    List<Sales_Order_Job_Task__c> selectByJobTaskId(Set<Id> salesOrderIds, Set<Id> jobTaskIds);
}