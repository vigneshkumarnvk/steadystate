({
    sendSalesInvToEQAIHelper: function (component, event) {
        console.log('check====>')
        var recordId = component.get("v.recordId");
        var action = component.get("c.sendBillingProjectToEQAI");
        action.setParams({
            "contractId": recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var salesInv = response.getReturnValue();
                if(salesInv == '200'){
                    this.showToast(component, "Success", "Billing Project has been submitted to EQAI.", "success", "dismissible");
                }else{
                    this.showToast(component, "Error","Please try again after sometimes","error"); 
                    
                }
                this.closeQA(component, event, helper);  
            } else {
                this.showToast(component, "Error",salesInv,"error"); 
                this.closeQA(component, event, helper);  
            }
        });
        
        $A.enqueueAction(action);
    },
    showToast : function(component, title, message, type, mode, duration) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type": type,
            "mode": mode
        });
        if (duration) {
            toastEvent.setParam('duration', duration);
        }
        toastEvent.fire();
    },
    closeQA : function(component, event, helper) { 
        $A.get("e.force:closeQuickAction").fire(); 
        $A.get("e.force:refreshView").fire(); 
    }
})