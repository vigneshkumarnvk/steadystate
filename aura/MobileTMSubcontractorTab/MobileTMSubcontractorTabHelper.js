({
    validate: function(component, event) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");

        var ok = true;
        var taskNames = [];

        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTaskWrapper = jobTaskWrappers[i];
            var ok2 = true;

            jobTaskWrapper.TMLines = jobTaskWrapper.TMLines.filter(function(tmLine) {
                return tmLine.Description__c != null && tmLine.Description__c.trim() !== "";
            });

            for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                var tmLine = jobTaskWrapper.TMLines[j];
                /*if (tmLine.Description__c == null || tmLine.Description__c.trim() === "") {
                    ok2 = false;
                    break; 
                }*/
            }

            if (!ok2) {
                taskNames.push(jobTaskWrapper.JobTask.Name);
                ok = false;
            }
        }

        component.set("v.jobTaskWrappers", jobTaskWrappers);

        if (!ok) {
            this.showToast(
                component,
                "",
                "Please complete required fields in task(s) " + taskNames.join(', '),
                "error",
                "dismissible"
            );
        }

        return ok;
    }
});