({
    handleDeleteLineEvent : function(component, event, helper) {
        helper.confirmDeleteLine(component, event);
    }, 
    handleUpdateLineEvent : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        var tmLine = event.getParam("tmLine");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        if (rowIndex < jobTaskWrapper.TMLines.length) { 
            component.set("v.jobTaskWrapper.TMLines[" + rowIndex + "]", tmLine);
        }
    },
    fireUnsavedChangesEvent : function(component, event) {
        var unsavedChangesEvent = component.getEvent("unsavedChangesEvent");
        unsavedChangesEvent.setParams({ "unsaved": true });
        unsavedChangesEvent.fire();
    },
    doMoveLines : function(component, event, helper) {
        helper.confirmMoveLines(component, event);
    }
});