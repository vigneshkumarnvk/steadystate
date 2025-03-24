({
    doInit : function(component, event, helper) {
        console.log('base init method***************************************'+JSON.stringify(component));
       // helper.setBillingMethod(component);
        helper.showFields(component);
        
    },
    handleWorksheetLineChange : function(component, event, helper) {
        helper.showFields(component);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
});