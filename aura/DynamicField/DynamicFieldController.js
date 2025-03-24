({
	doInit : function(component, event, helper) {
		var fieldName = component.get("v.fieldName");
        var value = component.getReference("v.record." + fieldName);
        component.set("v.value", value);
	}
})