({
    doInit : function(component, event, helper) {
        var defaultJobTaskTemplate = component.get("v.defaultJobTaskTemplate");
        var jobTask = component.get("v.jobTask");
        var salesOrder = component.get("v.salesOrder")
		if (defaultJobTaskTemplate) {
            jobTask.Job_Task_Template__c = defaultJobTaskTemplate.Id;
            jobTask.Job_Task_Template__r = defaultJobTaskTemplate;
            component.set("v.jobTask", jobTask);
            helper.getTemplateLines(component, event, jobTask.Job_Task_Template__c);
        }
        if(jobTask.Sales_Order__r != null && jobTask.Sales_Order__r.Quote_Type__c == 'Rate_Sheet'){
            jobTask.Billing_Type__c = 'T&M';
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
    handleSelectAllChange : function (component, event, helper) {
        var selectAll = component.get("v.selectAll");
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
        for (var i = 0; i < jobTaskTemplateLines.length; i++) {
            jobTaskTemplateLines[i].Selected = selectAll;
            if (selectAll != true) {
                jobTaskTemplateLines[i].Quantity__c = null;
            }
        }
        component.set("v.jobTaskTemplateLines", jobTaskTemplateLines);
    },
    doSave : function(component, event, helper) {
        if (helper.validateFields(component, event)) {
            helper.save(component, event);
        }
    }
});