({
    doInit : function(component, event, helper) {
        var options = [];
        for (var i = 0; i < 24; i++) {
            for (var j = 0; j < 60; j+=15) {
                var d = new Date();
                d.setHours(i);
                d.setMinutes(j);
                d.setSeconds(0);
                options.push({ "value": d.toTimeString().slice(0,8) + '.000Z', "label": d.toTimeString().slice(0,5) });
            }
        }
        component.set("v.options", options);

        var value = component.get("v.value");
        component.set("v.xValue", value);
    },
    handleValueChange : function(component, event, helper) {
        var value = component.get("v.value");
        component.set("v.xValue", value);
    },
    handleTimeChange : function(component, event, helper) {
        var xValue = component.get("v.xValue");
        if (xValue) {
            component.set("v.value", xValue);
        }
        else {
            component.set("v.value", null);
        }
        var onchange = component.getEvent("onchange");
        onchange.fire();
    },
    focus : function(component, event, helper) {
        var name = component.get("v.name");
        component.find("input").focus();
    }
})