({
    validate : function(component, event) {
        var tm = component.get("v.tm");
        if (tm.Status__c == null) {
            throw Error('Status is required.');
        }
        if (tm.Scheduled_Date__c == null) {
            throw Error('Schedule date is required');
        }
        return true;
    },
    saveTM : function(component, event) {
        var tm = component.get("v.tm");
        var params = { "JSONTM": JSON.stringify(tm) };
        this.callServerMethod(component, event, "c.saveTM", params, function (response) {
            component.set("v.unsavedChanges", false);
            this.showToast(component, "Save", "Successful", "success", "dismissible");
        })
    },
    confirmStatusChange : function(component, event) {
        var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.statusChangeCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Change Status', 'Are you sure you want to change the status back to Scheduled?', buttons, null, null, null);
    },
    statusChangeCallback : function(component, event) {
        var tm = component.get("v.tm");
        var params = { "tmId": tm.Id };
        this.callServerMethod(component, event, "c.changeToScheduled", params, function(response) {
            this.closeModal(component, event);
            var tm = JSON.parse(response);
            component.set("v.tm", tm);
            component.set("v.unsavedChanges", false);
            this.showToast(component, 'Status Change', 'Status is changed to Scheduled!', 'success', 'dismissible');
        });
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    }
})