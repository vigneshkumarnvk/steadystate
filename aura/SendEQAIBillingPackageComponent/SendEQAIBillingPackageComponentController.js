({
    doInit : function(component, event, helper) {
        console.log('send billing package to eqai initialized...');
        helper.getInvoiceDetails(component, event);      
    },
    closeQuickAction : function(component, event, helper) { 
        helper.closeQA(component, event, helper);
    },
    closeQuickAction1 : function(component, event, helper) { 
        component.set("v.hasSubmitted",true);
    },
    handleSave : function(component, event, helper) {
        helper.sendJobBillingProjectToEQAIHelper(component, event, helper);
    }

})