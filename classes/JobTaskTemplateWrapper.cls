public with sharing class JobTaskTemplateWrapper {
    @AuraEnabled
    public Job_Task_Template__c JobTaskTemplate { set; get; }

    @AuraEnabled
    public List<Job_Task_Template_Line__c> JobTaskTemplateLines { set; get; }

    public JobTaskTemplateWrapper() {

    }

    public JobTaskTemplateWrapper(Job_Task_Template__c jobTaskTemplate, List<Job_Task_Template_Line__c> jobTaskTemplateLines) {
        this.JobTaskTemplate = jobTaskTemplate;
        this.JobTaskTemplateLines = jobTaskTemplateLines;
    }
}