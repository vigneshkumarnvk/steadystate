({
    doInit : function(component, event, helper) {
    	var data = component.get("v.data");
        if (data) {
            component.set("v.expanded", data.Id == null);
        }
    },
    handleResourceChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.data.Resource__c", record.Id);
            component.set("v.data.Resource_Name__c", record.Description__c);
            component.set("v.data.ResourceName", record.Description__c);
            component.set("v.data.Description__c", record.Description__c);
            component.set("v.data.Unit_of_Measure__c", record.Unit_of_Measure__c);
            component.set("v.data.Unit_of_Measure__r", record.Unit_of_Measure__r);
            if (record.Unit_of_Measure__r != null) {
            	component.set("v.data.UnitOfMeasureName", record.Unit_of_Measure__r.Name);
            }
            else {
                component.set("v.data.UnitOfMeasureName", null);
            }
        }
        else {
            component.set("v.data.Resource__c", null);
            component.set("v.data.Resource_Name__c", null);
            component.set("v.data.ResourceName", null);
            component.set("v.data.Description__c", null);
            component.set("v.data.Unit_of_Measure__c", null);
            component.set("v.data.Unit_of_Measure__r", null);
            component.set("v.data.UnitOfMeasureName", null);
        }
    },
    handleUnitOfMeasureChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.data.Unit_of_Measure__c", record.Id);
            component.set("v.data.UnitOfMeasureName", record.Name);
        }
        else {
            component.set("v.data.Unit_of_Measure__c", null);
            component.set("v.data.Unit_of_Measure__r", null);
            component.set("v.data.UnitOfMeasureName", null);
        }
    },
    doScanResource : function(component, event, helper) {
		helper.scanResource(component, event);
    },
    handleScanComplete : function(component, event, helper) {
        var data = component.get("v.data");
        var resourceTypeId = data.Resource_Type__c;
        alert(event.getSource().getLocalId() + ', ' + resourceTypeId);
        var barcode = event.getParam("barcode");
        if (barcode != '') {
            helper.getResource(component, event, barcode);
        }
    },
    doPendingChangesStatus : function(component, event, helper) {
        var pendingChangesStatus = component.get("v.pendingChangesStatus");
        
        if (pendingChangesStatus != null) { // && pendingChangesStatus != 'Pending_Changes') {
            component.set("v.pendingChangesStatus", 'Pending_Changes_Dummy_Status'); //change status values to trigger event
            component.set("v.pendingChangesStatus", 'Pending_Changes');
    	}
    },
    doDelete : function(component, event, helper) {
        var tmlId = component.get("v.tmlId");
        var lineIndex = component.get("v.lineIndex")
        var deleteEvent = component.getEvent("deleteTMLineEvent");
        deleteEvent.setParams({ 
            "recordId": tmlId, 
            "lineIndex": lineIndex 
        });
        deleteEvent.fire();
    },
    toggleDetail : function(component, event, helper) {
        var card = component.find("card");
        $A.util.removeClass(card, "slds-card__header");
        var state = component.get("v.expanded");
        component.set("v.expanded", !state);        

        $A.util.addClass("card", "slds-card__header");
    },
    expand : function(component, event, helper) {
        component.set("v.expanded", true);
    },
    collapse : function(component, event, helper) {
        component.set("v.expanded", false);
    }
})