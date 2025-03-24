({
    validate : function(component, event) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");

        var ok = true;
        var taskNames = [];
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTaskWrapper = jobTaskWrappers[i];
            var ok2 = true;
            for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                var tmLine = jobTaskWrapper.TMLines[j];
                /*
                if (tmLine.Resource__c) {
                    if (!tmLine.Quantity__c) {
                        ok2 = false;
                        break;
                    }
                }*/
            }
            if (!ok2) {
                taskNames.push(jobTaskWrapper.JobTask.Name);
                ok = ok2;
            }
        }
        if (!ok) {
            this.showToast(component, "", "Please complete required fields in task(s) " + taskNames.join(', '), "error", "dismissible");
        }
        return ok;
    }
});