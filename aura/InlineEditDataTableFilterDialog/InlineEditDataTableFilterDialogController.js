({
    handleMouseEnter : function(component, event, helper) {
        component.set("v.lostFocusTime", new Date());
        component.set("v.entered", true);
    },
    handleMouseLeave : function(component,event,helper) {
        setTimeout($A.getCallback(
            function() {
                var entered = component.get("v.entered");
                if (!entered) {
                    var lostFocusTime = component.get("v.lostFocusTime");
                    if (new Date() - lostFocusTime > 250) {
                        component.set("v.xValue", component.get("v.value"));
                        helper.hideDialog(component);
                    }
                }
            }
        ), 300); //allow .5 second room to close the dropdown
        component.set("v.entered", false)
    },
    showDialog : function(component, event, helper) {
        helper.showDialog(component);
    },
    hideDialog : function(component, event, helper) {
        component.set("v.xValue", component.get("v.value"));
        helper.hideDialog(component)
    },
    applyFilter : function(component, event, helper) {
        var type = component.get("v.type");
        var xValue = '';
        if (type == 'option') {
            var options = component.get("v.options");
            var values = [];
            for (var i = 0; i < options.length; i++) {
                if (options[i].checked) {
                    values.push(options[i].value);
                }
            }
            xValue = values.join('|');
        }
        else {
            xValue = component.get("v.xValue");
        }
        component.set("v.value", xValue);
        component.set("v.iconClass", "brand");
        helper.fireFilterEvent(component, 'filter');
    },
    removeFilter : function(component, event, helper) {
        component.set("v.xValue", null);
        component.set("v.value", null);
        component.set("v.iconClass", "");
        var options = component.get("v.options");
        if (options) {
            for (var i = 0; i < options.length; i++) {
                options[i].checked = false;
            }
        }
        component.set("v.iconClass", "");
        component.set("v.options", options);
        helper.fireFilterEvent(component, 'clear');
    },
    handleKeyPress : function(component, event, helper) {
        if (event.which == 13) { //enter key
            var xValue = component.get("v.xValue");
            component.set("v.value", xValue);
            /*
            if (xValue) {
                component.set("v.iconClass", "brand");
            }
            else {
                component.set("v.iconClass", "");
            }*/
            component.set("v.iconClass", "brand");
            helper.fireFilterEvent(component, 'filter');
        }
    }
});