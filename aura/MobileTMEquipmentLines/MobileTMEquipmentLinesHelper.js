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
            jobTaskWrapper.TMLines[i].Total_Job_Hours__c = jobTaskWrapper.TMLines[rowIndex].Total_Job_Hours__c;
            this.calculateQuantity(component, jobTaskWrapper.TMLines[i]);
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
        //this.showToast(component, 'Copy Time', 'Successful', 'success', 'dismissible');
    },

})