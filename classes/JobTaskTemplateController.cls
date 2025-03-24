public with sharing class JobTaskTemplateController {
    public static Boolean ByPassTrigger { set; get; }
    
    @AuraEnabled
    public static String getJobTaskTemplate(Id jobTaskTemplateId) {
        try {
            Set<Id> jobTaskTemplateIds = new Set<Id>{ jobTaskTemplateId };
            List<Job_Task_Template__c> jobTaskTemplates = JobTaskTemplatesSelector.newInstance().selectById(jobTaskTemplateIds);
            if (jobTaskTemplates.size() > 0) {
                JobTaskTemplateWrapper jobTaskTemplateWrapper = new JobTaskTemplateWrapper();
                jobTaskTemplateWrapper.JobTaskTemplate = jobTaskTemplates[0];
                jobTaskTemplateWrapper.JobTaskTemplateLines = JobTaskTemplateLinesSelector.newInstance().selectByTemplateId(jobTaskTemplateIds, null);
                return JSON.serialize(jobTaskTemplateWrapper);
            }
            else {
                throw new DataException('Invalid job task template id ' + jobTaskTemplateId + '.');
            }
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getJobTaskTemplateLines(Id jobTaskTemplateId) {
        try {
            List<Job_Task_Template_Line__c> jobTaskTemplateLines = JobTaskTemplateLinesSelector.newInstance().selectByTemplateId(new Set<Id>{ jobTaskTemplateId }, null);
            return JSON.serialize(jobTaskTemplateLines);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Id saveJobTaskTemplate(String JSONJobTaskTemplate, String JSONJobTaskTemplateLines) {
        Savepoint sp = Database.setSavepoint();
        try {
            Job_Task_Template__c jobTaskTemplate = (Job_Task_Template__c)JSON.deserialize(JSONJobTaskTemplate, Job_Task_Template__c.class);
            List<Job_Task_Template_Line__c> jobTaskTemplateLines = (List<Job_Task_Template_Line__c>)JSON.deserialize(JSONJobTaskTemplateLines, List<Job_Task_Template_Line__c>.class);

            //empty quantity gets converted to 0, don't want zero
            for (Job_Task_Template_Line__c jobTaskTemplateLine : jobTaskTemplateLines) {
                if (jobTaskTemplateLine.Quantity__c == 0) {
                    jobTaskTemplateLine.Quantity__c = null;
                }
            }
            //delete removed lines
            //ticket 19130X <<
            /*if (jobTaskTemplate.Id != null) {
                List<Id> lineIds = new List<Id>();
                for (Job_Task_Template_Line__c jobTaskTemplateLine : jobTaskTemplateLines) {
                    if (jobTaskTemplateLine.Id != null) {
                        lineIds.add(jobTaskTemplateLine.Id);
                    }
                }
                delete [SELECT Id FROM Job_Task_Template_Line__c WHERE Job_Task_Template__c = :jobTaskTemplate.Id AND Id NOT IN :lineIds];
            }
            */
            if (jobTaskTemplate.Id != null) {
                List<Id> lineIds = new List<Id>();
                for (Job_Task_Template_Line__c jobTaskTemplateLine : jobTaskTemplateLines) {
                    if (jobTaskTemplateLine.Id != null) {
                        lineIds.add(jobTaskTemplateLine.Id);
                    }
                }
                List<Job_Task_Template_Line__c> templateLinesToDelete = [SELECT Id FROM Job_Task_Template_Line__c WHERE Job_Task_Template__c = :jobTaskTemplate.Id AND Id NOT IN :lineIds];
                Set<Id> lineToDeleteIds = new Set<Id>();
                for (Job_Task_Template_Line__c templateLineToDelete : templateLinesToDelete) {
                    lineToDeleteIds.add(templateLineToDelete.Id);
                }
                delete templateLinesToDelete;
            }
            //ticket 19130X >>
            upsert jobTaskTemplate;

            if (jobTaskTemplateLines.size() > 0) {
                for (Job_Task_Template_Line__c jobTaskTemplateLine : jobTaskTemplateLines) {
                    if (jobTaskTemplateLine.Job_Task_Template__c == null) {
                        jobTaskTemplateLine.Job_Task_Template__c = jobTaskTemplate.Id;
                    }
                }
                upsert jobTaskTemplateLines;
            }

            return jobTaskTemplate.Id;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }
}