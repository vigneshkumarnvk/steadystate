({
    doInit : function(component, event, helper) {
        var tabIndex = component.get("v.tabIndex");
        component.set("v.tabId", 'tab' + tabIndex);
    },
    handleTabClick : function(component, event, helper) {
        var tabId = component.get("v.tabId");
        component.set("v.selectedTabId", tabId);
    }
});