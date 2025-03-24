({
    handleMouseEnter : function(component, event, helper) {
        component.set("v.lostFocusTime", new Date());
    },
    handleMouseLeave : function(component,event,helper) {
        setTimeout($A.getCallback(
            function() {
                var lostFocusTime = component.get("v.lostFocusTime");
                if (new Date() - lostFocusTime > 250) {
                    component.set("v.xValue", component.get("v.value"));
                    helper.hideDialog(component);
                }
            }
        ), 250); //allow .5 second room to close the dropdown
    },
    showDialog : function(component, event, helper) {
        helper.showDialog(component);
    },
    hideDialog : function(component, event, helper) {
        component.set("v.xValue", component.get("v.value"));
        helper.hideDialog(component)
    },
    applyFilter : function(component, event, helper) {
        var xValue = component.get("v.xValue");
        component.set("v.value", xValue);
        helper.fireFilterEvent(component);
    },
    removeFilter : function(component, event, helper) {
        component.set("v.xValue", null);
        component.set("v.value", null);
        helper.fireFilterEvent(component);
    },
    handleKeyPress : function(component, event, helper) {
        if (event.which == 13) { //enter key
            component.set("v.value", component.get("v.xValue"));
            helper.fireFilterEvent(component);
        }
    }
});