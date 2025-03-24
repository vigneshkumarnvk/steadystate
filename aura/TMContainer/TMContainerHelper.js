({
    GetData : function(component, event) {
        var tmId = component.get("v.tmId");
        var params = { "tmId": tmId };
        this.callServerMethod(component, event, "c.GetTMDetail", params, function(response) {
            component.set("v.tm", response);
            component.set("v.pendingChangesStatus", '');
        });
    },
    confirmNavigate : function(component, event) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
        if (pendingChangesStatus == 'Pending_Changes') {
            var targetPageName = event.getParam("pageName"); 
            var currentPageName = component.get("v.pageName");
            var message;
            if (targetPageName == currentPageName) {
                message = 'You have unsaved changes! Are you sure you want to refresh this page?';
            }
            else {
                message = 'You have unsaved changes! Are you sure you want to navigate away from this page?'; 
            }            
            
            var buttons = [];
            buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelNavigate.bind(this, component, event) }});
            buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.navigateCallback.bind(this, component, event) }});
            this.openModal(component, event, 'Navigate', message, buttons, null, null, null);
        }
        else {
            this.navigate(component, event);
        }

	},
    navigateCallback : function(component, event) {
        this.navigate(component, event);
        this.closeModal(component, event);
    },
    cancelNavigate : function(component, event) {
        this.closeModal(component, event);
    },
    navigate : function(component, event) {
        var pageName = event.getSource().get("v.value");
        var tmId = component.get("v.tmId");
        
        var tmNavigationEvent = component.getEvent("tmNavigationEvent");
        tmNavigationEvent.setParams({ "pageName": pageName, "tmId": tmId });
        tmNavigationEvent.fire();
    }
})