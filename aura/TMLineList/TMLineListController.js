({
    doInit : function(component, event, helper) {
        //activate all tabs
        var calls = [];
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        if (jobTaskWrappers.length > 0) {
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var tabId = 'tab' + i;
                calls.push(helper.activateTab.bind(helper, component, tabId));
            }
        }
        if (calls.length > 1) {
            calls.push(helper.activateTab.bind(helper, component, 'tab0'));
            helper.makeStackedCalls(component, event, helper, calls);
        }
        helper.updateJobTaskOptions(component, jobTaskWrappers);
    },
    importJobTasks : function(component, event, helper) {
        helper.importJobTasksFromSalesOrder(component, event);
    },
    handleJobTaskWrappersChange : function(component, event, helper) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        helper.updateJobTaskOptions(component, jobTaskWrappers);
        helper.calculateNextTMLineNo(component);
    },
    handleJobTaskWrapperChange : function(component, event, helper) {
        var jobTaskWrapperIndex = event.getParam("jobTaskWrapperIndex");
        var jobTaskWrapper = event.getParam("jobTaskWrapper");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        jobTaskWrappers[jobTaskWrapperIndex] = jobTaskWrapper;
        helper.calculateNextTMLineNo(component);
    },
    handleJobTaskWrapperDelete : function(component, event, helper) {
        var jobTaskWrapperIndex = event.getParam("jobTaskWrapperIndex");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        jobTaskWrappers.splice(jobTaskWrapperIndex, 1);
        //component.set("v.jobTaskWrappers", []); //re-render tab id from the index
        component.set("v.jobTaskWrappers", jobTaskWrappers);
        if (jobTaskWrapperIndex >= jobTaskWrappers.length) {
            component.set("v.selectedTabId", "tab0");
        }
    },
    /*
    combineTMLines : function(component, event, helper) {
        var error = '';
        var jobTaskLines = helper.getJobTaskLineComponents(component);
        for (var i = 0; i < jobTaskLines.length; i++) {
            jobTaskLines[i].combineTMLines();
        }
    },*/
    handleTMLinesMoveEvent : function(component, event, helper) {
        var fromJobTask = event.getParam("fromJobTask");
        var toJobTask = event.getParam("toJobTask");
        var tmLines = event.getParam("taskLines");
        helper.moveLines(component, event, tmLines, fromJobTask, toJobTask);
    },
    validate : function(component, event, helper) {
        var status = event.getParams().arguments.status;
        var taskTabs = helper.getTaskTabs(component);
        var jobTaskWrappers = component.get("v.jobTaskWrappers");

        /*
        //discover inactive tabs and activate them
        var tabIds = [];
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            tabIds.push(i);
        }
        for (var i = 0; i < taskTabs.length; i++) {
            var jobTaskWrapperIndex = taskTabs[i].get("v.jobTaskWrapperIndex");
            var index = tabIds.indexOf(jobTaskWrapperIndex);
            if (index !== -1) {
                tabIds.splice(index, 1);
            }
        }
        //activate all tabs
        var selectedTabId = component.get("v.selectedTabId"); //save the tab id
        for (var i = 0; i < tabIds.length; i++) {
            var tabId = 'tab' + tabIds[i];
            component.set("v.selectedTabId", tabId);
        }
        component.set("v.selectedTabId", selectedTabId); //display the original tab
        */

        taskTabs = helper.getTaskTabs(component); //get the tabs again
        var ok = true;
        for (var i = 0; i < taskTabs.length; i++) {
            var valid = taskTabs[i].validate(status);
            ok = ok && valid;

        }

        //move the message to TM.cmp level
        /*
        if (!ok) {
            helper.showToast(component, "Validation Errors", "You must resolve all validation errors to continue.", "error", "pester");
        }*/
        return ok;
    },
    refreshTasks : function(component, event, helper) {
        helper.refreshTasks(component);
    },
    closeInlineEdit : function(component, event, helper) {
        var taskTabs = helper.getTaskTabs(component);
        for (var i = 0; i < taskTabs.length; i++) {
            taskTabs[i].closeInlineEdit();
        }
    }
});