({
    save : function(component, event) {
        var jobTaskLine = component.get("v.jobTaskLine");
        var jobTasks = component.get("v.jobTasks");

        if (!jobTaskLine) {
            this.showToast(component, "Error", "Please choose a job task to move the lines.", "error", "dismissible");
            return;
        }

        var jobTask = null;
        for (var i = 0; i < jobTasks.length; i++) {
            if (jobTasks[i].Line_No__c == jobTaskLine) {
                jobTask = jobTasks[i];
            }
        }
        var actionParams = event.getParams().arguments;
        if (actionParams.callback) {
            actionParams.callback(jobTask);
        }
    },
});