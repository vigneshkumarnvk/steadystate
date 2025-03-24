({
    deleteLine : function(component, event, helper) {
        helper.fireWorksheetLineDeleteEvent(component, event);
    },
    selectLines : function(component, event, helper) {
        helper.fireWorksheetLineSelectEvent(component, event, 'Selected');
    },
    selectToInvoiceLines : function(component, event, helper) {
        helper.fireWorksheetLineSelectEvent(component, event, 'To_Invoice__c');
    },

    doInit: function(component, event, handler) {
        var action = component.get("c.getCostPlusMESResourceId");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state = "SUCCESS") {
                var resourceId = response.getReturnValue();
                component.set("v.costPlusMESResourceId", resourceId);
            } else {
                console.error("Failed with state: " + state);
            }
        });
        $A.enqueueAction(action);
    },
    handleManifestChange : function(component, event, helper) {
        var record = event.getParam("record");
        var worksheetLine = component.get("v.worksheetLine");
        if (record) {
            worksheetLine.BOL_Manifest__c  = record.Manifest;
            helper.fireWorksheetLineUpdateEvent(component);
        } else {
            worksheetLine.BOL_Manifest__c  = null;
            helper.fireWorksheetLineUpdateEvent(component);
        }
    },

    handleComponentEvent : function(component, event, helper) {
        var valueFromChild = event.getParam("message");
        var worksheetLine = component.get("v.worksheetLine");
        if (valueFromChild.Manifest != null) {
            worksheetLine.BOL_Manifest__c  = valueFromChild.Manifest;
            helper.fireWorksheetLineUpdateEvent(component);
        } 
    }
   
});