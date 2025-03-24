public interface ITMJobTasksSelector {
    List<TM_Job_Task__c> selectById(Set<Id> idSet);
    List<TM_Job_Task__c> selectByTMId(Set<Id> idSet);
    List<TM_Job_Task__c> selectBySalesOrderJobTaskId(Set<Id> idSet);
}