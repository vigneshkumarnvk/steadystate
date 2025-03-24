({
    saveData : function(component, event) {
        var tmId = component.get("v.tmId");
        var tm = component.get("v.tm");
        if (tm.Contact__r) {
            tm.Contact__c = tm.Contact__r.Id;
        }
        var params = { "data": JSON.stringify(tm) };
        this.callServerMethod(component, event, "c.SaveTM", params, function(data) {
            this.refresh(component, event);
            this.showToast(component, 'success', 'T&M', 'Your changes are saved!', 'dismissable');
        });
	},
    confirmStatusChange : function(component, event) {
        var buttons = [];
        buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.statusChangeCallback.bind(this, component, event) }});       
        this.openModal(component, event, 'Change Status', 'Are you sure you want to change status to Scheduled?', buttons, null, null, null);
    },
    statusChangeCallback : function(component, event) {
        var tmId = component.get("v.tmId");
        var params = { "tmId": tmId };
        this.callServerMethod(component, event, "c.ChangeToScheduled", params, function(data) {
            this.refresh(component, event);
            this.closeModal(component, event);
            this.showToast(component, 'success', 'T&M', 'Status is changed to Scheduled!', 'dismissable');
        });
    },
    confirmRefresh : function(component, event) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
        if (pendingChangesStatus == 'Pending_Changes') {
            var buttons = [];
            buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.refreshCallback.bind(this, component, event) }});       
            this.openModal(component, event, 'Refresh', 'You have unsaved changes! Are you sure you want to refresh this page?', buttons, null, null, null);
        }
        else {
            this.refresh(component, event);
        }
    },
    refreshCallback : function(component, event) {
        this.refresh(component, event);
        this.closeModal(component, event);
	},
    refresh : function(component, event) {
        var tm = component.get("v.tm");
        var tmNavigationEvent = component.getEvent("tmNavigationEvent");
        tmNavigationEvent.setParams({ "pageName": "TMCard", "tmId": tm.Id });
        tmNavigationEvent.fire();
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    }
})