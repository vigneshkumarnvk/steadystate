({
    doInit : function(component, event, helper) {
    },
    collapseSection : function(component, event, helper) {
        var section = component.find("section");
        var collapsed = !component.get("v.collapsed");
        component.set("v.collapsed", collapsed);
        if (collapsed == true) {
            $A.util.addClass(section, "slds-is-open");
            $A.util.removeClass(section, "slds-is-close");
        }
        else {
            $A.util.removeClass(section, "slds-is-open");
            $A.util.addClass(section, "slds-is-close");
        }
    }
});