({
    doInit : function(component, event, helper) {
        component.set("v.dateOption", 'Today');
        component.set("v.ownership", 'MyTMs');
        component.set("v.scheduledDate", $A.localizationService.formatDate(new Date(), "yyyy-MM-dd"));
        helper.getTMs(component, event);
    },
    handleOwnershipOptionChange : function(component, event, helper) {
        helper.getTMs(component, event);
    },
    handleDateOptionChange : function(component, event, helper) {
        var value = event.getSource().get("v.value");
        if (value == 'Today') {
            component.set("v.scheduledDate", $A.localizationService.formatDate(new Date(), "yyyy-MM-dd"));
        }
        else {
            component.set("v.scheduledDate", null);
        }
        helper.getTMs(component, event);
    },
    handleScheduledDateChange : function(component, event, helper) {
        var value = event.getSource().get("v.value");
        if (value == $A.localizationService.formatDate(new Date(), "yyyy-MM-dd")) {
            component.set("v.dateOption", 'Today');
        }
        else {
            component.set("v.dateOption", 'All');
        }
        helper.getTMs(component);
    },
    doSearch : function(component, event, helper) {
        helper.getTMs(component);
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        if (action == 'click') {
            var tms = component.get("v.tms");
            var tm = tms[rowIndex];

            var tmNavigationEvent = component.getEvent("tmNavigationEvent");
            tmNavigationEvent.setParams({ "tmId": tm.Id, "page": "details" });
            tmNavigationEvent.fire();
        }
    }
});