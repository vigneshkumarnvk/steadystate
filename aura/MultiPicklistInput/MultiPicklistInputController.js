({
    doInit: function(component, event, helper) {
        helper.fetchPickListValues(component, event);
    },
    handleChange : function(component, event, helper) {
        helper.setValue(component, event);
    },
    showHelpMessageIfInvalid : function(component, event, helper) {
		var input = component.find("picklist");    
        input.showHelpMessageIfInvalid();
		component.set("v.validity", input.get("v.validity"));
    },
})