({
    fetchPickListOptions: function(component, helper) {
        var action = component.get("c.getOptions");
        action.setParams({
            "objectName": component.get("v.objectName"),
            "fieldName": component.get("v.fieldName"),
            "controlValue" : component.get("v.controlValue")
        });
        
        action.setCallback(this, function(response) {
            if (response.getState() == "SUCCESS") {
                var data = response.getReturnValue();

                var options = [];
                options.push({
                    label: "---None---",
                    value: ""
                });

                for (var key in data) {
                    options.push({
                        label: data[key],
                        value: key
                    });
                }
                component.set("v.options", options);
            }
        });
        $A.enqueueAction(action);
    },
})