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
    handleCopyManifestEvent : function(component, event, helper) {
        helper.confirmCopyManifest(component, event);
    },
    handlePendingChangesStatus : function(component, event, helper) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
    },
    doExpandAll : function(component, event, helper) {
        var disposalItems  = component.find("disposalItem");
        if (disposalItems) {
            for (var i = 0 ; i < disposalItems.length; i++) {
                var disposalItem = disposalItems[i];
                disposalItem.expand();
            }
        }
    },
    doCollapseAll : function(component, event, helper) {
        var disposalItems = component.find("disposalItem");
        if (disposalItems) {
            for (var i = 0 ; i < disposalItems.length; i++) {
                var disposalItem = disposalItems[i];
                disposalItem.collapse();
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