({
	initTabs : function(component, event) {
        var tabs = component.get("v.tabs");
        
		var newComponents = [];
        for (var i = 0; i < tabs.length; i++) {
            var tab = tabs[i];
            newComponents.push(["aura:html", {
                "tag": "div",
                "id": tab.id,
                "aura:id": tab.id,
                "HTMLAttributes": { 
                    "class": 'slds-tabs_scoped__content slds-hide ' + (tab.class != null ? tab.class : ''),
                    "style": tab.style,
                    "role": 'tabpanel'
                }
            }]);
		}

        $A.createComponents(newComponents, function(components, status, error) {
            if (status === "SUCCESS") {
                var container = component.find("container");        
                var body = container.get("v.body");
                for (var i = 0; i < components.length; i++) {
                    components[i].set("v.body", tabs[i].body);
                    body.push(components[i]); // need to use push
                }
                container.set("v.body", body);
            }
            else {
                alert(error);
			}
        });
	},
    handleTabChange : function(component, event) {
		var tabId = component.get("v.selectedTabId");
        var tabs = component.get("v.tabs");
        for (var i = 0; i < tabs.length; i++) {
            var tab = component.find(tabs[i].id);
            if (tabs[i].id == tabId) {
                $A.util.addClass(tab, 'slds-show');
                $A.util.removeClass(tab, 'slds-hide');
            }
            else {
                $A.util.removeClass(tab, 'slds-show');
                $A.util.addClass(tab, 'slds-hide');
            }
        }
    },
    //ticket 19130 <<
    fireTabChangeEvent : function(component) {
        var tabId = component.get("v.selectedTabId");
        var onchange = component.getEvent("onchange");
        onchange.setParams({ "tabId": tabId });
        onchange.fire();
    }
    //ticket 19130 >>
})