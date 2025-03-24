public interface ISalesInvoiceJobTasksSelector {
    List<Sales_Invoice_Job_Task__c> selectById(Set<Id> idSet);
    List<Sales_Invoice_Job_Task__c> selectBySalesInvoiceId(Set<Id> idSet);
    List<Sales_Invoice_Job_Task__c> selectByJobTaskId(Set<Id> salesInvoiceIds, Set<Id> jobTaskIds);
    List<Sales_Invoice_Job_Task__c> selectBySalesInvoiceIdForPrint(Set<Id> idSet); //Ticket#20402
}