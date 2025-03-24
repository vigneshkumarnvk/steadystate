({
    doInit : function(component, event, helper) {
        helper.getTM(component, event);
    },
    handlePageChange : function(component, event, helper) {
        //handle cache issue where doInit is not loaded every time the page is open
        helper.getTM(component, event);
    },
    quickSave : function(component, event, helper) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var count = 0;
        for (var i = 0 ; i< jobTaskWrappers.length; i++) {
            count += jobTaskWrappers[i].TMLines.length;
        }
        //alert("total lines: " +count);

        var status = component.get("v.tm.Status__c");
        helper.saveAsStatus(component, event, helper, status, false);
    },
    save : function(component, event, helper) {
        var status = component.get("v.tm.Status__c");
        helper.saveAsStatus(component, event, helper, status, true);
    },
    saveAsScheduled : function(component, event, helper) {
        helper.saveAsStatus(component, event, helper, 'Scheduled', true);
    },
    saveAsMobileReview : function(component, event, helper) {
        helper.saveAsStatus(component, event, helper, 'Mobile Review', true);
    },
    saveAsConfirmed : function(component, event, helper) {
        helper.saveAsStatus(component, event, helper, 'Confirmed', true);
    },
    cancel : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        helper.navigateToSObject(component, event, recordId);
    },
    /*
    calculate : function(component, event, helper) {
        var tm = component.get("v.tm");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        helper.calculateTMJobTasks(component, event, tm, jobTaskWrappers);
    }*/
});