({
    doInit : function(component, event, helper) {
        helper.getJobTaskTemplate(component, event);
    },
    handlePageChange : function(component, event, helper) {
        helper.getJobTaskTemplate(component, event);
    },
    doSave : function(component, event, helper) {
        if (helper.validate(component, event)) {
            helper.saveJobTaskTemplate(component, event);
        }
    },
    doCancel : function(component, event, helper) {
        window.history.back();
    },
    handleTypeChange : function(component, event, helper) {
        var jobTaskTemplate = component.get("v.jobTaskTemplate");
        component.set("v.jobTaskTemplate", jobTaskTemplate);
    },
    doAddNewLine : function(component, event, helper) {
        helper.addTemplateLine(component, event, null);
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
        var action = event.getParam("action");

        if (jobTaskTemplateLines && jobTaskTemplateLines.length > rowIndex) {
            switch (name) {
                case 'edit':
                    if (action == 'click') {
                        helper.editTemplateLine(component, event, rowIndex);
                    }
                    break;
                case 'delete':
                    if (action == 'click') {
                        helper.deleteTemplateLine(component, event, rowIndex);
                    }
                    break;
            }
        }
    },
    handleTemplateLinesChange : function(component, event, helper) {
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");

        if (!jobTaskTemplateLines) {
            return;
        }

        var byPassJobTaskTemplateLinesChange = component.get("v.byPassJobTaskTemplateLinesChange");
        if (byPassJobTaskTemplateLinesChange != true) {
            var nextTemplateLineNo = 0;
            for (var i = 0; i < jobTaskTemplateLines.length; i++) {
                var jobTaskTemplateLine = jobTaskTemplateLines[i];
                if (jobTaskTemplateLine.Line_No__c > nextTemplateLineNo) {
                    nextTemplateLineNo = jobTaskTemplateLine.Line_No__c;
                }
            }
            nextTemplateLineNo++;

            component.set("v.nextTemplateLineNo", nextTemplateLineNo);

            //component.set("v.byPassJobTaskTemplateLinesChange", true);
            //helper.sortTemplateLines(component);
            //component.set("v.byPassJobTaskTemplateLinesChange", false);
        }
    }
});