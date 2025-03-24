({
    handleMenuButtonClick : function(component, event, helper) {
        var menuItemsVisible = component.get("v.menuItemsVisible");
        component.set("v.menuItemsVisible", !menuItemsVisible);
    },
    handleMouseLeave : function(component, event, helper) {
        component.set("v.mouseLeaveTime", Date.now());
        setTimeout($A.getCallback(function() {
            var mouseLeaveTime = component.get("v.mouseLeaveTime");
            if (mouseLeaveTime != null) {
                component.set("v.menuItemsVisible", false);
            }
        }), 200);
    },
    handleMouseEnter : function(component, event, helper) {
        component.set("v.mouseLeaveTime", null);
    }
});