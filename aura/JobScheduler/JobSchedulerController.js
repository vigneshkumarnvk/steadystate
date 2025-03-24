({
    doInit : function(component, event, helper) {
        helper.getJobs(component);
    },
    addJob : function (component, event, helper) {
        helper.showAddJobDialog(component, event);
    },
    runNow : function (component, event, helper) {
        var jobs = component.get("v.jobs");
        var index = parseInt(event.getSource().get("v.value"));
        var job = jobs[index];

        var calls = [];
        calls.push(helper.runApexJobNow.bind(helper, component, event, job));
        calls.push(helper.getJobs.bind(helper, component, event));
        helper.makeStackedCalls(component, event, helper, calls);
    },
    schedule : function(component, event, helper) {
        var jobs = component.get("v.jobs");
        var index = parseInt(event.getSource().get("v.value"));
        var job = jobs[index];
        if (helper.validate(component, job, 'schedule') == true) {
            var calls = [];
            calls.push(helper.scheduleApexJob.bind(helper, component, event, job));
            calls.push(helper.getJobs.bind(helper, component, event));
            helper.makeStackedCalls(component, event, helper, calls);
        }
    },
    unschedule : function(component, event, helper) {
        var jobs = component.get("v.jobs");
        var index = parseInt(event.getSource().get("v.value"));
        var job = jobs[index];
        var calls = [];
        calls.push(helper.unscheduleApexJob.bind(helper, component, event, job));
        calls.push(helper.getJobs.bind(helper, component, event));
        helper.makeStackedCalls(component, event, helper, calls);
    }

});