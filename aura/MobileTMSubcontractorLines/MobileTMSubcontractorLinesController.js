({
    doNewLine : function(component, event, helper) {
        helper.addLine(component, event);
    },
    doDeleteLines : function(component, event, helper) {
        helper.confirmDeleteLines(component, event);
    },
    handleTMLinesChange : function(component, event, helper) {

    },
    toggleView : function(component, event, helper) {
        var mode = event.getSource().get("v.value");
        component.set("v.mode", mode);
        helper.toggleView(component, event, mode); 
    },
})