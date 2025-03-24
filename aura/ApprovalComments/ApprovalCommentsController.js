({
    doInit: function (component, event, helper) {
        var action = component.get("c.getProcessInstanceHistories");
        action.setParams({
            recordId: component.get("v.recordId"),
        })

        action.setCallback(this, function (response) {
            var processInstanceHistories = response.getReturnValue();
            component.set("v.processInstanceHistories", processInstanceHistories);
            console.log("f: ", component.get("v.processInstanceHistories"));
        })
        $A.enqueueAction(action);
    }
});