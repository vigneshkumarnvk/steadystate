({
    doInit : function(component, event, helper) {
    },
    handleUnitOfMeasureChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        if (record != null) {
            tmLine.Unit_of_Measure__c = record.Id;
        }
        else {
            tmLine.Unit_of_Measure__c = null;
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    doDelete : function(component, event, helper) {
        helper.fireTMLineDeleteEvent(component, event);
    }
})