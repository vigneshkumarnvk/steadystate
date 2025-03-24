({
	 doInit : function(component, event, helper) {
        helper.sendSalesInvToEQAIHelper(component, event);      
    },
    closeQuickAction : function(component, event, helper) { 
        helper.closeQA(component, event, helper);
    }
})