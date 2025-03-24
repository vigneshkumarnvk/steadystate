({
    doInit : function(component, event, helper) {
        var value = component.get("v.value");
        if (value != null) {
            component.set("v.displayValue", $A.localizationService.formatDate(value, "MM-dd-yyyy"));
        }
        else {
            component.set("v.displayValue", '');
        }
    }
});