({
    addAttributesToTab : function(component, tab) {
        if (tab) {
            if (!tab.attributes) {
                tab.attributes = {};
            }
            if (!tab.attributes.values) {
                tab.attributes.values = {};
            }

            tab.attributes.values.selectedTabId = {
                "descriptor": "selectedTabId",
                "value": {
                    "exprType": "PROPERTY",
                    "byValue": false,
                    "target": "c:FlexTabSet",
                    "path": "v.selectedTabId"
                }
            }
        }
    }
});