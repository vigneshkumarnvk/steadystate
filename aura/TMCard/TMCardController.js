({
	doInit : function(component, event, helper) {
		helper.getData(component, event, false);
	},
    handleSiteContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record != null) {
            component.set("v.tm.Site_Contact_2__c", record.Contact.Id);
            component.set("v.tm.Site_Contact_2__r", record.Contact);
        }
        else {
            component.set("v.tm.Site_Contact_2__c", null);
            component.set("v.tm.Site_Contact_2__r", null);
        }
    },
    handleStatusChange : function(component, event, helper) {
        if (component.get("v.tm.Status__c") == 'Scheduled') {
            var dt = $A.localizationService.formatDate(new Date(), "yyyy-MM-dd");
            component.set("v.tm.Scheduled_Date__c", dt);
        }
    },
    handleBillingContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record != null) {
            component.set("v.tm.Contact__c", record.Id);
            component.set("v.tm.Contact__r", record);
        }
        else {
            component.set("v.tm.Contact__c", null);
            component.set("v.tm.Contact__r", null);
        }
    },
    doStatusChange : function(component, event, helper) {
        helper.confirmStatusChange(component, event);
    },
    doSave : function(component, event, helper) {
        helper.saveData(component, event);
	},
    doCancel : function(component, event, helper) {
	    /*
        var navigationEvent = $A.get("e.c:ApplicationNavigationEvent");
        navigationEvent.setParams({ "pageName": 'TMHome' });
        navigationEvent.fire();
	    */
        var tmNavigationEvent = component.getEvent("tmNavigationEvent");
        tmNavigationEvent.setParams({ "pageName": "TMSearch" });
        tmNavigationEvent.fire();
    },
    doRefresh : function(component, event, helper) {
        helper.confirmRefresh(component, event);
    },
    doPendingChangesStatus : function(component, event, helper) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
        if (pendingChangesStatus != null && pendingChangesStatus != 'Pending_Changes') {
            component.set("v.pendingChangesStatus", 'Pending_Changes');
    	}
    },
})