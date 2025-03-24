({
    handleProjectCoordinatorChange : function(component, event, helper) {
        var tm = component.get("v.tm");
        var record = event.getParam("record");
        if (record != null) {
            tm.Project_Coordinator__c = record.Id;
        }
        else {
            tm.Project_Coordinator__c = null;
        }
        component.set("v.tm", tm);
    }
});