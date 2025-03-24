({
    doInit : function(component, event, helper) {
        var defaultJobTaskTemplate = component.get("v.defaultJobTaskTemplate");

        if (defaultJobTaskTemplate) {
            var jobTask = component.get("v.jobTask");
            jobTask.Job_Task_Template__c = defaultJobTaskTemplate.Id;
            jobTask.Job_Task_Template__r = defaultJobTaskTemplate;
            //jobTask.Name = defaultJobTaskTemplate.Name;
            component.set("v.jobTask", jobTask);
            helper.getTemplateLines(component, event, jobTask.Job_Task_Template__c);
        }
    },
    handleBillTypeChange : function(component, event, helper) {
        var jobTask = component.get("v.jobTask");
        if (jobTask.Billing_Type__c != 'Fixed Price') {
            jobTask.Fixed_Price__c = null;
        }
        component.set("v.jobTask", jobTask);
    },
    handleJobTaskTemplateChange : function(component, event, helper) {
        var record = event.getParam("record");
        var jobTask = component.get("v.jobTask");
        var mode = component.get("v.mode");
        if (record != null) {
            jobTask.Job_Task_Template__c = record.Id;
            //if (!jobTask.Name) {
            //    if (record.Name && record.Name.length > 30) {
            //        record.Name = record.Name.substring(0, 30);
            //    }
            //    jobTask.Name = record.Name;
            //}
            helper.getTemplateLines(component, event, jobTask.Job_Task_Template__c);
        }
        else {
            jobTask.Job_Task_Template__c = null;
            component.set("v.jobTaskTemplateLines", []);
        }
        component.set("v.jobTask", jobTask);
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
        if (rowIndex < jobTaskTemplateLines.length) {
            switch (name) {
                //ticket 19130X <<
                    /*
                case 'select':
                    if (action == 'change') {
                        var jobTaskTemplateLine = jobTaskTemplateLines[rowIndex];
                        for (var i = 0; i < jobTaskTemplateLines.length; i++) {
                            if (jobTaskTemplateLines[i].Parent_Line__r && jobTaskTemplateLines[i].Parent_Line__r.Line_No__c == jobTaskTemplateLine.Line_No__c) {
                                jobTaskTemplateLines[i].Selected = jobTaskTemplateLine.Selected;
                                component.set("v.jobTaskTemplateLines[" + i + "]", jobTaskTemplateLines[i]);
                            }
                        }
                    }
                    break;
                */
                //ticket 19130X >>
                case 'quantity':
                    if (action == 'focusout') {
                        var jobTaskTemplateLine = jobTaskTemplateLines[rowIndex];
                        if (jobTaskTemplateLine.Quantity__c != null && jobTaskTemplateLine.Quantity__c > 0) {
                            jobTaskTemplateLine.Selected = true;
                            //ticket 19130X <<
                            /*
                            for (var i = 0; i < jobTaskTemplateLines.length; i++) {
                                if (jobTaskTemplateLines[i].Parent_Line__r && jobTaskTemplateLines[i].Parent_Line__r.Line_No__c == jobTaskTemplateLine.Line_No__c) {
                                    jobTaskTemplateLines[i].Selected = jobTaskTemplateLine.Selected;
                                    component.set("v.jobTaskTemplateLines[" + i + "]", jobTaskTemplateLines[i]);
                                }
                            }
                            component.set("v.jobTaskTemplateLines[" + rowIndex + "]", jobTaskTemplateLine);
                            */
                            //ticket 19130X >>
                        }
                    }
                    break;
                case 'clear':
                    if (action == 'click') {
                        component.set("v.jobTaskTemplateLines[" + rowIndex + "].Quantity__c", null);
                    }
                    break;
            }
        }
    },
    doSave : function(component, event, helper) {
        if (helper.validateFields(component, event)) {
            helper.save(component, event);
        }
    }
});