({
    calculateJobHours : function(component, tmLine) {
        /*
        var tmLine = component.get("v.tmLine");
        var jobStartTime = component.get("v.tmLine.Job_Start_Time__c");
        var jobEndTime = component.get("v.tmLine.Job_End_Time__c");
        var lunchStartTime = component.get("v.tmLine.Lunch_Start_Time__c");
        var lunchEndTime = component.get("v.tmLine.Lunch_End_Time__c");
        */
        var jobStartTime = tmLine.Job_Start_Time__c;
        var jobEndTime = tmLine.Job_End_Time__c;
        var lunchStartTime = tmLine.Lunch_Start_Time__c;
        var lunchEndTime = tmLine.Lunch_End_Time__c;
        var jobHours = this.calculateHours(jobStartTime, jobEndTime);// - this.calculateHours(lunchStartTime, lunchEndTime);
        if (jobHours < 0) {
            jobHours = 0;
        }
        //Ticket#24285 >>
        if(tmLine.Category__c === 'Labor' && tmLine.Job_Start_Time__c === tmLine.Site_Start_Time__c
            && tmLine.Site_Start_Time__c === tmLine.Site_End_Time__c && tmLine.Site_End_Time__c === tmLine.Job_End_Time__c && tmLine.Lunch_Start_Time__c == null && tmLine.Lunch_End_Time__c == null){
            tmLine.Total_Job_Hours__c = 0;
        } else {
            tmLine.Total_Job_Hours__c = jobHours;
        }
        //tmLine.Total_Job_Hours__c = jobHours;
        //Ticket#24285 <<
        //this.calculateQuantity(component, tmLine);
        //component.set("v.tmLine", tmLine);
    },
    calculateSiteHours : function(component, tmLine) {
        /*
        var siteStartTime = component.get("v.tmLine.Site_Start_Time__c");
        var siteEndTime = component.get("v.tmLine.Site_End_Time__c");
        var lunchStartTime = component.get("v.tmLine.Lunch_Start_Time__c");
        var lunchEndTime = component.get("v.tmLine.Lunch_End_Time__c");
        */
        var siteStartTime = tmLine.Site_Start_Time__c;
        var siteEndTime = tmLine.Site_End_Time__c;
        var lunchStartTime = tmLine.Lunch_Start_Time__c;
        var lunchEndTime = tmLine.Lunch_End_Time__c;
        var siteHours = this.calculateHours(siteStartTime, siteEndTime);// - this.calculateHours(lunchStartTime, lunchEndTime);
        //Ticket#16848
        if (siteHours < 0 || siteStartTime === siteEndTime) {
            siteHours = 0;
        }
        //component.set("v.tmLine.Total_Site_Hours__c", siteHours);
        tmLine.Total_Site_Hours__c = siteHours;
        this.calculateJobHours(component, tmLine); //Ticket#24285
    }
})