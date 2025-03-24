({
    fetchPickListValues: function(component, helper) {
        var action = component.get("c.GetPicklistOptions");
        action.setParams({
            "SObjectName": component.get("v.SObjectName"),
            "fieldName": component.get("v.fieldName"),
            "controllingValue" : component.get("v.controllingValue")
        });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
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
            else if (state == "INCOMPLETE") {
                alert('An error has occurred while retrieving pick list values.');
            }
            else if (state == "ERROR") {
                var message = 'An error has occurred while retrieving pick list values.';
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        message = errors[0].message;
                    }
                }
                alert(message);
            }
        });
        $A.enqueueAction(action);
    },
})