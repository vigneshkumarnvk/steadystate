({
    doInit : function(component, event, helper) {
        var tabIndex = component.get("v.tabIndex");
        component.set("v.tabId", 'tab' + tabIndex);
    }
});