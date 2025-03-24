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

                /*
                var value = component.get("v.value");
                var items = [];
                if (value) {
                    items = value.split(';');
                }
                
                var leftOptionList = [];
                var rightOptionList = [];
                for (var key in data) {
                    var option = { "label": data[key], "value": key };
                    if (items.includes(key)) {
                        rightOptionList.push(option);
                    }
                    else {
                        leftOptionList.push(option);
                    }
                }
                
                component.set("v.leftOptionList", leftOptionList);
                component.set("v.rightOptionList", rightOptionList);
                */
                
                var value = component.get("v.value");
                var values = [];
                if (value) {
                    values = value.split(';');
                }
                
                var options = [];
                for (var key in data) {
                    var option = { "label": data[key], "value": key };
                    options.push(option);
                }
                
                component.set("v.options", options);
                component.set("v.values", values);
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
    setValue : function(component, event) {
        var values = component.get("v.values");
        component.set("v.value", values.join(';'));
    }
})