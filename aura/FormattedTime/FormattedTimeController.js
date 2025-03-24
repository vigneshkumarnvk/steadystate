({
    doInit : function(component, event, helper) {
        //console.log('init formattedTime')
        helper.displayTime(component, event); 
    },
    handleValueChange : function(component, event, helper) {
        //console.log('change formattedTime')
        helper.displayTime(component, event);
    }
});