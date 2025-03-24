({
	myAction : function(component, event, helper) {
		
	},

	doInit: function(component, event, helper) {
		var action = component.get("c.getCostPlusMESResourceId");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state = "SUCCESS") {
                var resourceId = response.getReturnValue();
                component.set("v.costPlusMESResourceId", resourceId);
            } else {
                console.error("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
	}
})