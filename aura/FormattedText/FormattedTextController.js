({
    handleValueChange : function(component, event, helper) {
        var value = component.get("v.value");
        var options = component.get("v.options");
        var displayValue = value;
        if (options) {
            if (typeof options == 'string') {
                options = JSON.parse(options);
            }
            if (options[value]) {
                displayValue = options[value];
            }
        }
        component.set("v.displayValue", displayValue);
    }
});