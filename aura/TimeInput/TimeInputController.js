({
    //fix.null.fields <<
    doInit : function(component, event, helper) {
        var value = component.get("v.value");
        component.set("v.xValue", value);
    },
    handleFocus : function(component, event, helper) {
        var ignoreFocusEvent = component.get("v.ignoreFocusEvent");
        if (ignoreFocusEvent == true) return null;

        var value = component.get("v.value");
        if (value == null) {
            var defaultTimeOption = component.get("v.defaultTimeOption");
            if (defaultTimeOption != null) {
                component.set("v.value", defaultTimeOption);
                component.set("v.ignoreFocusEvent", true);
                setTimeout(function () {
                    component.set("v.value", null);
                    component.set("v.ignoreFocusEvent", false);
                }, 1);
            }
        }
    },
    //fix.null.fields >>
    handleValueChange : function(component, event, helper) {
        //fix.null.fields <<
        /*
        var value = component.get("v.value");
        var stringValue = helper.integerToTime(value);
        component.set("v.stringValue", stringValue);
        */
        //fix.null.fields >>
    },
    handleTimeChange : function(component, event, helper) {
        //fix.null.fields <<
        /*
        var stringValue = component.get("v.stringValue");
        var value = helper.timeToInteger(stringValue);
        var xValue = component.get("v.value");
        if (value != xValue) {
            component.set("v.value", value);
            var onchange = component.getEvent("onchange");
            onchange.setParams({ "value": value });
            onchange.fire();
        }
        */
        var value = component.get("v.value");
        if (value != null) {
            value = value + 'Z';
            component.set("v.value", value);
        }

        console.log(xValue + ' = ' + value);

        var xValue = component.get("v.xValue");
        if (value != xValue) {
            component.set("v.xValue", value);
            var onchange = component.getEvent("onchange");
            onchange.setParams({ "value": value });
            onchange.fire();
        }
        //fix.null.fields >>
    },
    focus : function(component, event, helper) {
        helper.getTimeInput(component).focus();
    },
    setCustomValidity : function(component, event, helper) {
        var input = helper.getTimeInput(component);
        var params = event.getParams().arguments;
        //helper.showLookupInput(component, event);
        input.setCustomValidity(params.message);
        input.set('v.validity', { valid:false, badInput:true });
    },
    reportValidity : function(component, event, helper) {
        var timeInput = helper.getTimeInput(component);
        var validity = timeInput.get("v.validity");;
        timeInput.reportValidity();
    },
    showHelpMessageIfInvalid : function(component, event, helper) {
        var required = component.get("v.required");
        var input = helper.getTimeInput(component);
        if (required == true) {
            if (component.get("v.value") == null) { //check pill value, not the input value, input is always blank
                input.set("v.required", true);
            }
            else {
                input.set("v.required", false);
            }
            input.showHelpMessageIfInvalid();
        }
        component.set("v.validity", input.get("v.validity"));
    },

})