({
    calculateJobHours : function(component, event) {
        var tmLine = component.get("v.tmLine");
        var jobStartTime = component.get("v.tmLine.Job_Start_Time__c");
        var jobEndTime = component.get("v.tmLine.Job_End_Time__c");
        var jobHours = this.calculateHours(jobStartTime, jobEndTime);
        if (jobHours < 0) {
            jobHours = 0;
        }
        tmLine.Total_Job_Hours__c = jobHours;
        this.calculateQuantity(component, tmLine);
        component.set("v.tmLine", tmLine);
    }
})