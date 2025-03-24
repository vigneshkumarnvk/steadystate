({
    doInit : function(component, event, helper) {
        var pageRef = component.get("v.pageReference");
        var salesOrderId = pageRef.state.c__id;
        component.set("v.salesOrderId", salesOrderId);
        helper.getSetupData(component, event);
        helper.getSalesOrder(component, event);
        helper.getWorksheets(component, event);
        component.set("v.activeWorksheets", []);

        document.title = "Edit Billing Worksheet";
    },
    handlePageChange : function(component, event, helper) {
        //handle cache issue where doInit is not loaded every time the page is open
        var pageRef = component.get("v.pageReference");
        var salesOrderId = pageRef.state.c__id;
        component.set("v.salesOrderId", salesOrderId);
        helper.getSetupData(component, event);
        helper.getSalesOrder(component, event);
        helper.getWorksheets(component, event);
        component.set("v.activeWorksheets", []);
        //component.set("v.xJobTaskGroups", []);
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");

        if (name == 'select' && action == "change") {
            var worksheets = component.get("v.worksheets");
            var worksheet = worksheets[rowIndex];
            if (worksheet.Selected) {
                helper.getWorksheet(component, event, rowIndex);
            }
            else {
                helper.confirmDeselectWorksheet(component, event, rowIndex);
            }
        }
    },
    handleWorksheetsChange : function(component, event, helper) {
        var activeWorksheets = component.get("v.activeWorksheets");
        helper.setNextWorksheetLineNo(component, activeWorksheets);
        helper.calculateProfitAndMargin(component, activeWorksheets);

        var jobTaskOptions = [];
        for (var i = 0; i < activeWorksheets.length; i++) {
            var activeWorksheet = activeWorksheets[i];
            var jobTaskOption = {};
            jobTaskOption.label = 'Task ' + activeWorksheet.SalesOrderJobTask.Task_No__c + ' -' + activeWorksheet.SalesOrderJobTask.Name;
            jobTaskOption.value = activeWorksheet.SalesOrderJobTask.Line_No__c;
            jobTaskOption.Name = activeWorksheet.SalesOrderJobTask.Name;
            jobTaskOption.Task_No__c = activeWorksheet.SalesOrderJobTask.Task_No__c;
            jobTaskOptions.push(jobTaskOption);
        }
        component.set("v.jobTaskOptions", jobTaskOptions);
    },
    quickSave : function(component, event, helper) {
        var activeWorksheets = component.get("v.activeWorksheets");
        if (helper.validateWorksheets(component, event, false)) {
            helper.save(component, event, activeWorksheets, false);
        }
    },
    save : function(component, event, helper) {
        var activeWorksheets = component.get("v.activeWorksheets");
        if (helper.validateWorksheets(component, event, false)) {
            helper.save(component, event, activeWorksheets, true);
        }
    },
    createInvoice : function(component, event, helper) {
        var activeWorksheets = component.get("v.activeWorksheets");
        if (helper.validateWorksheets(component, event, true)) {
            var calls = [];
            calls.push(helper.promptWizard.bind(helper, component, event, activeWorksheets));
            calls.push(helper.validateWorksheets.bind(helper, component, event, true));
            calls.push(helper.confirmCreateInvoice.bind(helper,component, event, activeWorksheets));
            helper.makeStackedCalls(component, event, helper, calls);
        }
    },
    print : function(component, event, helper) {
        var activeWorksheets = component.get("v.activeWorksheets");
        var ids = [];
        for (var i = 0; i < activeWorksheets.length; i++) {
            ids.push(activeWorksheets[i].SalesOrderJobTask.Id);
        }
        if (ids.length > 0) {
            var params = { "ids": JSON.stringify(ids) };
            helper.callServerMethod(component, event, "c.getTMBillingPDFUrl", params, function(url) {
                helper.navigateToUrl(component, event, url);
            });
        }
    },
    cancel : function(component, event, helper) {
        helper.confirmCancel(component, event);
    },
    handleUnsavedChangesEvent : function(component, event, helper) {
        var unsaved = event.getParam("unsaved");
        var unsavedChanges = component.get("v.unsavedChanges");
        if (unsavedChanges != true) {
            component.set("v.unsavedChanges", unsaved);
        }
    },
    handleWorksheetUpdateEvent : function(component, event, helper) {
        var index = event.getParam("index");
        var worksheet = event.getParam("worksheet");
        var activeWorksheets = component.get("v.activeWorksheets");
        activeWorksheets[index] = worksheet;
        helper.setNextWorksheetLineNo(component, activeWorksheets);
        helper.calculateProfitAndMargin(component, activeWorksheets);
    },
    handleWorksheetLinesMoveEvent : function(component, event, helper) {
        var fromJobTask = event.getParam("fromJobTask");
        var toJobTask = event.getParam("toJobTask");
        var worksheetLines = event.getParam("taskLines");
        helper.moveLines(component, event, fromJobTask, toJobTask, worksheetLines);
    }
});