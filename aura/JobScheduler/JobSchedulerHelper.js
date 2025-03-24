({
    getJobs : function(component, event) {
        component.set("v.showSpinner", true);
        this.callServerMethod(component, event, "c.getAllSchedulableClasses", null, function(response) {
            var jobs = JSON.parse(response);
            component.set("v.jobs", jobs);
        });
    },
    showAddJobDialog : function(component, event) {
        let buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.addSchedulableApexJob.bind(this, component, event) }});
        this.openModal(component, event, 'Add Schedulable Apex Class', null, buttons, 'c:AddSchedulableApexJob', null);
    },
    addSchedulableApexJob : function(component, event, job) {
        this.closeModal(component, event);
        this.getJobs(component);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    validate : function(component, job, forWhat) {
        var ok = true;
        if (forWhat == 'schedule') {
            if (!job.Frequency || (job.Frequency == 'Hourly' && !job.Minute) || (job.Frequency == 'Daily' && (!job.Hour || !job.Minute || !job.Meridiem)) || (job.Frequency == 'Weekly' && (!job.Hour || !job.Minute || !job.Meridiem || !job.WeekDay))) {
                this.showToast(component, null, "You must specify the frequency fields to schedule.", "error", "dismissible");
                ok = false;
            }
        }
        if (ok && !job.BatchSize) {
            this.showToast(component, null, "Batch Size is required.", "error", "dismissible");
            ok = false;
        }
        return ok;
    },
    runApexJobNow : function (component, event, job, resolve) {
        var params = { "jobName": job.valueName};
        this.callServerMethod(component, event, "c.runApexJobNow", params, function(response) {
            this.showToast(component, null, "Job is started.", "success", "dismissible");
            if (resolve) resolve();
        });
    },
    scheduleApexJob : function(component, event, job, resolve) {
        var params = { "JSONJob": JSON.stringify(job)};
        this.callServerMethod(component, event, "c.scheduleApexJob", params, function(response) {

            this.showToast(component, null, "Job is scheduled successfully.", "success", "dismissible");
            if (resolve) resolve();
        });
    },
    unscheduleApexJob : function(component, event, job, resolve) {
        var params = { "JSONJob": JSON.stringify(job)};
        this.callServerMethod(component, event, "c.abortApexJob", params, function (response) {
            this.showToast(component, null, "Job is unscheduled successfully.", "success", "dismissible");
            if (resolve) resolve();
        });
    },
    cancel : function(component) {
        this.closeModal(component);
    }
});