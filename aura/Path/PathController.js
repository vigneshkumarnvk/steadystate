({
    doInit : function(component, event, helper) {
        var value = component.get("v.value");
        component.set("v.xValue", value);

        var stages = component.get("v.stages");
        var stageValues = [];
        stages.forEach(function(stage) {
            stageValues.push(stage.value);
        });

        helper.setStages(component, value);
    },
    handleValueChange : function(component, event, helper) {
        var value = component.get("v.value");
        component.set("v.xValue", value);
        helper.setStages(component, value);
    },
    handleSingleStageChange : function(component, event, helper) {
        var xValue = component.get("v.xValue");
        component.set("v.value", xValue);
        helper.setStages(component, xValue);
    },
    setStage : function(component, event, helper) {
        var status = event.getParams().arguments.status;
        helper.setStages(component, status);
    },
    markStage : function(component, event, helper) {
        var newValue = event.currentTarget.name;
        var value = component.get("v.value");
        /*
        var stages = component.get("v.stages");
        var valueIndex = -1;
        var newValueIndex =  -1;
        for (var i = 0; i < stages.length; i++) {
            if (stages[i].value == value) {
                valueIndex = i;
            }
            if (stages[i].value == newValue) {
                newValueIndex = i;
            }
        }
        */

        var stages = component.get("v.stages");
        for (var i = 0; i < stages.length; i++) {
            //ticket 19792 <<
            //if (stages[i].value == newValue && stages[i].disabled == true) {
            if (stages[i].value == newValue && (stages[i].disabled == true || stages[i].disableClick == true)) {
                //ticket 19792 >>
                return;
            }
        }

        var stageValues = component.get("v.stageValues");
        var valueIndex = stageValues.indexOf(value);
        var newValueIndex = stageValues.indexOf(newValue);


        var noSkip = component.get("v.noSkip");
        if (noSkip == true) {
            if (newValueIndex > valueIndex && valueIndex + 1 != newValueIndex) {
                helper.showToast(component, "Error", "You must not skip status.", "error", "dismissible");
                return;
            }
        }

        var forwardOnly = component.get("v.forwardOnly");
        if (forwardOnly == true) {
            if (valueIndex > newValueIndex) {
                helper.showToast(component, "Error", "You can only move the status forward.", "error", "dismissible");
                return;
            }
        }

        component.set("v.xValue", newValue);
        helper.setStages(component, newValue);

        if (newValue != value) {
            var onstagechange = component.getEvent("onstagechange");
            onstagechange.setParams({"value": newValue});
            onstagechange.fire();
        }
    },
    markComplete : function(component, event, helper) {
        var xValue = component.get("v.xValue");
        var onstagecomplete = component.getEvent("onstagecomplete");
        onstagecomplete.setParams({ "value": xValue });
        onstagecomplete.fire();
    }
});