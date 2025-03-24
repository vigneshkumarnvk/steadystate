//ticket 19130 <<
//trigger JobTaskTemplateLineTrigger on Job_Task_Template_Line__c (after insert, after update, after delete) {
trigger JobTaskTemplateLineTrigger on Job_Task_Template_Line__c (before insert, before update, after insert, after update, after delete) {
//ticket 19130 >>
    if (JobTaskTemplateController.ByPassTrigger == true) {
        return;
    }

    //ticket 19130 <<
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Job_Task_Template_Line__c jobTaskTemplateLine : Trigger.new) {
                jobTaskTemplateLine.UID__c = jobTaskTemplateLine.Job_Task_Template__c + ';' + jobTaskTemplateLine.Line_No__c.intValue();
            }
        }
    }
    //ticket 19130 >>

    if (Trigger.isAfter) {
        Set<Id> parentTemplateLineIds = new Set<Id>();
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Job_Task_Template_Line__c templateLine : Trigger.new) {
                if (templateLine.Parent_Line__c != null) {
                    parentTemplateLineIds.add(templateLine.Parent_Line__c);
                }
            }
        }
        else if (Trigger.isDelete) {
            for (Job_Task_Template_Line__c templateLine : Trigger.old) {
                if (templateLine.Parent_Line__c != null) {
                    parentTemplateLineIds.add(templateLine.Parent_Line__c);
                }
            }
        }

        //ticket 19130 <<
        /*
        if (parentTemplateLineIds.size() > 0) {
            List<Job_Task_Template_Line__c> jobTaskTemplateLines = [SELECT Id, (SELECT Id FROM Job_Task_Template_Lines__r) FROM Job_Task_Template_Line__c WHERE Id IN :parentTemplateLineIds];
            for (Job_Task_Template_Line__c templateLine : jobTaskTemplateLines) {
                templateLine.Has_Child_Lines__c = (templateLine.Job_Task_Template_Lines__r.size() > 0);
            }
            JobTaskTemplateController.ByPassTrigger = true; 
            update jobTaskTemplateLines;
            JobTaskTemplateController.ByPassTrigger = false;
        }
        */
        //ticket 19130 >>
    }
}