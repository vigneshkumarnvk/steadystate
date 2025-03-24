({
    doInit : function(component, event, helper) {
        helper.handleSalesInvoiceLinesChanged(component, event);
    },
    handleSalesInvoiceLinesChanged : function(component, event, helper) {
        helper.handleSalesInvoiceLinesChanged(component, event);
    },
    validateLines : function(component, event) {
        var jobTaskLines = [];
        var cmp = component.find('job-task-line');
        if (Array.isArray(cmp)) {
            jobTaskLines = cmp;
        }
        else {
            jobTaskLines.push(cmp);
        }

        var ok = jobTaskLines.reduce(function(valid, jobTaskLine) {
            valid = valid && jobTaskLine.validateLines();
            return valid;
        }, true);

        return ok;
    }

});