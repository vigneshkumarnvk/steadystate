({
	doInit : function(component, event, helper) {
		var fieldName = component.get("v.fieldName");
        component.set("v.fieldValue", component.getReference("v.oRecord." + fieldName));
	}
})