({
    confirmCopyTime : function(component, event) {
        var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.copyTimeCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Copy Time', 'Are you sure you want to times from this line to all the lines below it?', buttons, null, null, null);
    },
    copyTimeCallback : function(component, event) {
        this.closeModal(component, event);
        this.copyTime(component, event);
    }, 
    copyTime : function(component, event) {
        var rowIndex = event.getParam("rowIndex");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        for (var i = rowIndex + 1; i < jobTaskWrapper.TMLines.length; i++) {
            jobTaskWrapper.TMLines[i].Job_Start_Time__c = jobTaskWrapper.TMLines[rowIndex].Job_Start_Time__c;
            jobTaskWrapper.TMLines[i].Job_End_Time__c = jobTaskWrapper.TMLines[rowIndex].Job_End_Time__c;
            jobTaskWrapper.TMLines[i].Site_Start_Time__c = jobTaskWrapper.TMLines[rowIndex].Site_Start_Time__c;
            jobTaskWrapper.TMLines[i].Site_End_Time__c = jobTaskWrapper.TMLines[rowIndex].Site_End_Time__c;
            jobTaskWrapper.TMLines[i].Lunch_Start_Time__c = jobTaskWrapper.TMLines[rowIndex].Lunch_Start_Time__c;
            jobTaskWrapper.TMLines[i].Lunch_End_Time__c = jobTaskWrapper.TMLines[rowIndex].Lunch_End_Time__c;
            jobTaskWrapper.TMLines[i].Total_Job_Hours__c = jobTaskWrapper.TMLines[rowIndex].Total_Job_Hours__c;
            jobTaskWrapper.TMLines[i].Total_Site_Hours__c = jobTaskWrapper.TMLines[rowIndex].Total_Site_Hours__c;
            if (jobTaskWrapper.TMLines[i].Unit_of_Measure__c && jobTaskWrapper.TMLines[rowIndex].Unit_of_Measure__c) {
                jobTaskWrapper.TMLines[i].Quantity__c = jobTaskWrapper.TMLines[rowIndex].Quantity__c;
            }
            else {
                if (jobTaskWrapper.TMLines[i].Unit_of_Measure__r && jobTaskWrapper.TMLines[i].Unit_of_Measure__r.Hours_UOM__c != true) {
                    if (jobTaskWrapper.TMLines[i].Total_Job_Hours__c > 0) {
                        jobTaskWrapper.TMLines[i].Quantity__c = 1;
                    }
                    else {
                        jobTaskWrapper.TMLines[i].Quantity__c = 0;
                    }
                }
            }
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
        //this.showToast(component, 'Copy Time', 'Successful', 'success', 'dismissible');
    },

})