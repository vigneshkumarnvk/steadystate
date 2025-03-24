({
	doInit : function(component, event, helper) {  
        component.set("v.dateScope", 'Today');
        component.set("v.userScope", 'My');
        component.set("v.scheduledDate", $A.localizationService.formatDate(new Date(), "yyyy-MM-dd"));
        
		helper.getUserInfo(component);
        helper.getResources(component);
        helper.getData(component);
	},
    doSearch : function(component, event, helper) {
        helper.getData(component);
    },
	doScan : function(component, event, helper) {
		helper.getBarcode(component, event);
    },
    doClear : function(component, event, helper) {
    	component.set("v.barcode", '');
        helper.getData(component);
    },
    handleUserScopeChange : function(component, event, helper) {
        helper.getData(component);
    },
    handleDateScopeChange : function(component, event, helper) {
        if (component.get("v.dateScope") == 'Today') {
        	component.set("v.scheduledDate", $A.localizationService.formatDate(new Date(), "yyyy-MM-dd"));
        }
        else {
            component.set("v.scheduledDate", null);
        }
        helper.getData(component);
    },
    handleScheduledDateChange : function(component, event, helper) {
        if (component.get("v.scheduledDate") == $A.localizationService.formatDate(new Date(), "yyyy-MM-dd")) {
            component.set("v.dateScope", 'Today');
        }
        else {
            component.set("v.dateScope", 'All');
        }
        helper.getData(component);
    },
	handleScanComplete : function(component, event, helper) {
        component.set("v.barcode", event.getParam("barcode"));
    },
    doOpenTM : function(component, event, helper) {
        var target = event.currentTarget;
        var recordId = target.getAttribute("data-id");
        var tmNavigationEvent = component.getEvent("tmNavigationEvent");
        tmNavigationEvent.setParams({ "pageName": "TMCard", "tmId": recordId });
        tmNavigationEvent.fire();
    },
})