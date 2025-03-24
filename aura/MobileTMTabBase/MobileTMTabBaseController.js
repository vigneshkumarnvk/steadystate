({
    doInit : function(component, event, helper) {
        helper.getTMLines(component, event);
    },
    handleUnsavedChangesEvent : function(component, event, helper) {
        component.set("v.unsavedChanges", true);
    },
    handleTMLinesMoveEvent : function(component, event, helper) {
        helper.moveTMLines(component, event);
    }
});