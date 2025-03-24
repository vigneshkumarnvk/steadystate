({
    doInit : function(component, event, helper) {
        helper.showFields(component);
    },
    handleWorksheetLineChange : function(component, event, helper) {
        helper.showFields(component);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
});