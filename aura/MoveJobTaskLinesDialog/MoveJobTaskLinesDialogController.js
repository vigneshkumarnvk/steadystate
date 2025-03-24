({
    doInit : function(component, event, helper) {
        component.set("v.toJobTask", {});
    },
    move : function(component, event, helper) {
        var toJobTaskComp = component.find("to-job-task");
        toJobTaskComp.showHelpMessageIfInvalid();
        if (toJobTaskComp.get("v.validity").valid) {
            var toJobTask = component.get("v.toJobTask");
            if (toJobTask.Line_No__c) {
                var jobTaskOptions = component.get("v.jobTaskOptions");
                for (var i = 0; i < jobTaskOptions.length; i++) {
                    var jobTaskOption = jobTaskOptions[i];
                    if (jobTaskOption.value == toJobTask.Line_No__c) {
                        toJobTask.Task_No__c = jobTaskOption.Task_No__c;
                        toJobTask.Name = jobTaskOption.Name;
                    }
                }
                var actionParams = event.getParams().arguments;
                if (actionParams.callback) {
                    actionParams.callback(toJobTask);
                }
            }
        }
    }
});