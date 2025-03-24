({
    doInit : function(component, event, helper) {
        var tabs = component.get("v.tabs");
        for (var i = 0; i < tabs.length; i++) {
            var tab = tabs[i];
            if (tab.componentDef.descriptor == 'markup://aura:iteration') {
                if (tab.attributes.values.body && tab.attributes.values.body.value) {
                    var containedComponents = tab.attributes.values.body.value;
                    for (var j = 0; j < containedComponents.length; j++) {
                        var childComponent = containedComponents[j];
                        if (childComponent.componentDef.descriptor == 'markup://c:FlexTab') {
                            helper.addAttributesToTab(component, childComponent);
                        }
                    }
                }
            }
            else if (tab.componentDef.descriptor == 'markup://c:FlexTab') {
                helper.addAttributesToTab(component, tab);
            }
        }
        //component.set("v.tabs", tabs);

        var contents = component.get("v.contents");
        for (var i = 0; i < contents.length; i++) {
            var content = contents[i];
            if (content.componentDef.descriptor == 'markup://aura:iteration') {
                if (content.attributes.values.body && content.attributes.values.body.value) {
                    var containedComponents = content.attributes.values.body.value;
                    for (var j = 0; j < containedComponents.length; j++) {
                        var childComponent = containedComponents[j];
                        if (childComponent.componentDef.descriptor == 'markup://c:FlexTabContent') {
                            helper.addAttributesToTab(component, childComponent);
                        }
                    }
                }
            }
            else if (content.componentDef.descriptor == 'markup://c:FlexTabContent') {
                helper.addAttributesToTab(component, content);
            }
        }
    },
    handleTabSelect : function(component, event, helper) {
    }

});