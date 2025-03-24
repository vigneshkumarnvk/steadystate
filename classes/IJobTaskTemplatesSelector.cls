public interface IJobTaskTemplatesSelector extends fflib_ISObjectSelector {
    List<Job_Task_Template__c> selectById(Set<Id> idSet);
}