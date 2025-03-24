({
    doNewLine : function(component, event, helper) {
        helper.addLine(component, event);
    },
    doDeleteLines : function(component, event, helper) {
        helper.confirmDeleteLines(component, event);
    },
    handleCopyTimeEvent : function(component, event, helper) {
        helper.confirmCopyTime(component, event);
    }, 
    handleTMLinesChange : function(component, event, helper) {
        var tmLines = component.get("v.jobTaskWrapper.TMLines");
        var totalHours = 0;
        tmLines.forEach(function(tmLine) {
            var hours = (tmLine.Total_Job_Hours__c != null ? tmLine.Total_Job_Hours__c : 0);
            totalHours += Math.round(hours * 100) / 100;
        });
        component.set("v.totalHours", totalHours);
    },
    toggleView : function(component, event, helper) {
        var mode = event.getSource().get("v.value");
        component.set("v.mode", mode);
        helper.toggleView(component, event, mode);
    },
})