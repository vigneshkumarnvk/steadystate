({
    doInit : function(component, event, helper) {

    },
	openModal : function(component, event, helper) {
        var params = event.getParams().arguments;
        component.set("v.caller", params.caller);
        component.set("v.title", params.title);
        component.set("v.message", params.message);
        component.set("v.variant", params.variant);
        component.set("v.callerComponent", params.callerComponent);
        component.set("v.callerEvent", params.callerEvent);
        component.set("v.callback", params.callback);

		helper.showModal(component, event);
        
        return params.callback;
	},
    doYes : function(component, event, helper) {
        var callback = component.get("v.callback");
        if (!$A.util.isUndefinedOrNull(callback)) {
        	var callerComponent = component.get("v.callerComponent");
            var callerEvent = component.get("v.callerEvent");
            callback(callerComponent, callerEvent, true);
        }
        helper.hideModal(component, event);
    },
    doNo : function(component, event, helper) {
        helper.hideModal(component, event);
        
        var callback = component.get("v.callback");
        if (!$A.util.isUndefinedOrNull(callback)) {
            var callerComponent = component.get("v.callerComponent");
            var callerEvent = component.get("v.callerEvent");
            callback(callerComponent, callerEvent, false);
        }
        helper.hideModal(component, event);
    }
    
})