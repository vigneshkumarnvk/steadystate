public with sharing class TMWizardController {

    /*
    @AuraEnabled
    public static String getJobTaskTemplateQuestionLines(Id jobTaskTemplateId) {
        try {
            List<Job_Task_Template_Line__c> jobTaskTemplateLines = JobTaskTemplateLinesSelector.newInstance().selectQuestionLinesByTemplateId(new Set<Id>{ jobTaskTemplateId });
            return JSON.serialize(jobTaskTemplateLines);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }*/
}