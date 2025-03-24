({
    doInit : function(component, event, helper) {
        helper.getSalesOrder(component, event);
        //Task#78352
        if($A.get("$Label.c.Release_Flag")==='true'){
        helper.getFacility(component, event);
        }
        //disable the escape key closing the page
        window.addEventListener("keydown", function(event) {
            var keycode = event.code;
            if(keycode == 'Escape'){
                event.preventDefault();
                event.stopImmediatePropagation();
            }
        }, true);
    },
    create : function(component, event, helper) {
        helper.confirmTMCreation(component, event);
    },
    cancelCreation : function(component, event, helper) {
        //$A.get("e.force:closeQuickAction").fire();
        helper.confirmCancelCreation(component, event);
    }
});