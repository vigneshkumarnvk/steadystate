public interface IJobTaskTemplateLinesSelector extends fflib_ISObjectSelector {
    List<Job_Task_Template_Line__c> selectByTemplateId(Set<Id> idSet, List<String> filters);
}