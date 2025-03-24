({
    doInit: function(component, event, helper) {
        helper.fetchPickListOptions(component, event);
    },
    fireEvent: function(component, event, helper) {
        var name = component.get("v.name");
        var value = component.get("v.value");
        var valueChangeEvent = component.getEvent("valueChangeEvent");
        valueChangeEvent.setParams({ "name": name, "value": value });
        valueChangeEvent.fire();
    },
})