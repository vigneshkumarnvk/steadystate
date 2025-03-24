({
	doInit : function(component, event, helper) {  
        helper.getData(component, event, false);
	},
	doNewLine : function(component, event, helper) {
        helper.addNewLine(component, event);
    },
    doSave : function(component, event, helper) {
    	helper.saveData(component, event);
    },
    doRefresh : function(component, event, helper) {
        helper.confirmRefresh(component, event);
    },
    doDeleteLines : function(component, event, helper) {
        helper.confirmDeleteLines(component, event);
    },
    handleDeleteLineEvent : function(component, event, helper) {
        helper.confirmDeleteLine(component, event);
	},
    handlePendingChangesStatus : function(component, event, helper) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
    },
    doExpandAll : function(component, event, helper) {
        var materialItems  = component.find("materialItem");
        if (materialItems) {
            for (var i = 0 ; i < materialItems.length; i++) {
                var materialItem = materialItems[i];
                materialItem.expand();
            }
        }
    },
    doCollapseAll : function(component, event, helper) {
        var materialItems = component.find("materialItem");
        if (materialItems) {
            for (var i = 0 ; i < materialItems.length; i++) {
                var materialItem = materialItems[i];
                materialItem.collapse();
            }
        }
    },
    scrollToTop : function(component, event, helper) {
        component.find("scroller").scrollTo('top');
    },
    scrollToBottom : function(component, event, helper) {
        component.find("scroller").scrollTo('bottom');
    }
})