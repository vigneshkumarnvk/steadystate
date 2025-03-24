public with sharing class TMPathStatusController {
    /*
    @AuraEnabled
    public static String getTM(Id recordId) {
        try {
            List<TM__c> tms = [SELECT Id, Status__c, Mobile_TM__c, Sales_Order__r.Sales_Order_Type__r.Job_Task_Template__c FROM TM__c WHERE Id = :recordId];
            if (tms.size() > 0) {
                return JSON.serialize(tms[0]);
            }
            return null;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getTMLines(Id tmId) {
        try {
            return TMBaseController.getTMLines(tmId, null);
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
    public static void SaveTMAndLines(String JSONTM, String JSONJobTaskWrappers) {
        try {
            TMBaseController.SaveTMAndLines(JSONTM, JSONJobTaskWrappers);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }*/
}