({
    doInit : function(component, event, helper) {

    },
    handleSelectAll : function(component, event, helper) {
        var checked = event.getParam("checked");
        if (checked == true) {
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            jobTaskWrapper.Selected = true;
            component.set("v.jobTaskWrapper", jobTaskWrapper);
        }

    },
    handleJobTaskSelect : function(component, event, helper) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            jobTaskWrapper.SalesLines[i].Selected = jobTaskWrapper.Selected;
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        if (rowIndex < jobTaskWrapper.SalesLines.length) {
            switch(name) {
                case 'select':
                    if (action == 'change') {
                        var salesLine = jobTaskWrapper.SalesLines[rowIndex];
                        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                            if (salesLine.Category__c == 'Bundled') {
                                if (jobTaskWrapper.SalesLines[i].Bundle_Line__r) {
                                    if (jobTaskWrapper.SalesLines[i].Bundle_Line__r.Line_No__c == salesLine.Line_No__c) {
                                        jobTaskWrapper.SalesLines[i].Selected = salesLine.Selected;
                                    }
                                }
                            }
                        }

                        var selectCount = 0;
                        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                            if (jobTaskWrapper.SalesLines[i].Selected == true) {
                                selectCount++;
                            }
                        }
                        jobTaskWrapper.Selected = (selectCount > 0);
                        component.set("v.jobTaskWrapper", jobTaskWrapper);
                    }
                    break;
            }
        }
    }
});