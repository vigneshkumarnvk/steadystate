({
    doInit : function(component, event, helper) {
        //move the tab body out of <li> 
        var tabs = [];
        var tabItems = component.get("v.body");
        for (var i = 0 ; i < tabItems.length; i++) {
            var tabItem = tabItems[i];
            tabs.push({ "id": tabItem.get("v.id"), "label": tabItem.get("v.label"), "iconName": tabItem.get("v.iconName"), "class": tabItem.get("v.class"), "style": tabItem.get("v.style"), "body": tabItem.get("v.body") });
            tabItem.set("v.body", null);
        }
        component.set("v.tabs", tabs);
        helper.initTabs(component, event);
        helper.handleTabChange(component, event);
    },
    handleTabClick : function(component, event, helper) {
        var tabId = event.target.getAttribute("id");
        component.set("v.selectedTabId", tabId);
        //ticket 19130 <<
        helper.fireTabChangeEvent(component);
        //ticket 19130 >>
    },
    handleSelectedTableIdChange : function(component, event, helper) {
		helper.handleTabChange(component, event);
    }
})