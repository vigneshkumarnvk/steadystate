({
    doInit : function(component, event, helper) {

    },
    rollbackValue : function(component, event, helper) {
        component.set("v.value", component.get("v.xValue"));
    },
    handleFocus : function(component, event, helper) {
        component.set("v.xValue", component.get("v.value"));
    },
    handleBlur : function(component, event, helper) {
        //clear the validity message upon leaving the field
        helper.clearCustomValidity(component, event);

        var value = component.get("v.value");
        var xValue = component.get("v.xValue");
        if (value != xValue) {
            var onchange = component.getEvent("onchange");
            onchange.fire();
        }
    },
    focus : function(component, event, helper) {
        helper.focus(component, event);
    },
    clearCustomValidity : function(component, event, helper) {
        helper.clearCustomValidity(component, event);
    },
    reportValidity : function(component, event, helper) {
        helper.reportCustomValidity(component, event);

    },
    showHelpMessageIfInvalid : function(component, event, helper) {
        var input =  component.find("custom-lightning-input");
        if (input) {
            input.showHelpMessageIfInvalid();
        }
    }
})