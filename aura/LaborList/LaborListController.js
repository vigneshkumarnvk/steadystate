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
    handleCopyTimeEvent : function(component, event, helper) {
        helper.confirmCopyTime(component, event);
    },
    handlePendingChangesStatus : function(component, event, helper) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
        if (pendingChangesStatus == 'Pending_Changes') {
            helper.calculateHours(component, event);
        }  
    },
    doExpandAll : function(component, event, helper) {
        var laborItems = component.find("laborItem");
        if (laborItems) {
            for (var i = 0 ; i < laborItems.length; i++) {
                var laborItem = laborItems[i];
                laborItem.expand();
            }
        }
    },
    doCollapseAll : function(component, event, helper) {
        var laborItems = component.find("laborItem");
        if (laborItems) {
            for (var i = 0 ; i < laborItems.length; i++) {
                var laborItem = laborItems[i];
                laborItem.collapse();
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