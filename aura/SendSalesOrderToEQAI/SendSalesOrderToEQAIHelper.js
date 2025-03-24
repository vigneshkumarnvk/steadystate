({
    SendSalesOrderToEQAIHelper: function (component, event) {
        var recordId = component.get("v.recordId");
        var action = component.get("c.sendSalesOrderToEQAI"); 

        action.setParams({
            "recordId": recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var salesOrder = response.getReturnValue();
                if (salesOrder == 'Service Center Disabled') {
                    this.showToast(component, "Error", "This function is disabled for this service center.", "error", "dismissible"); 
                    this.closeQA(component, event, helper);  
                }
                else if (salesOrder == 'Sent to EQAI') {
                    this.showToast(component, "Error", "The Sales Order has already been sent to EQAI.", "error", "dismissible"); 
                    this.closeQA(component, event, helper);  
                }
                else if (salesOrder == 'Missing Fields Required') {
                    this.showToast(component, "Error", "You cannot Send your Sales Order to EQAI. You must enter all required fields.", "error", "dismissible"); 
                    this.closeQA(component, event, helper);  
                }
                //Task#78352
                else if(salesOrder == '3rdPartyFacility')
                {
                    this.showToast(component, "Error", "You cannot Send your Sales Order to EQAI. Your have a Waste Line referencing 3rd Party. You must select an approved facility.", "error", "dismissible"); 
                    this.closeQA(component, event, helper); 
                }
                else if(salesOrder == 'True')
                {
                    // this.showToast(component, "Success", "The Sales Order has been submitted to EQAI.", "success", "dismissible");
                    this.closeQA(component, event, helper); 
                }
                else if(salesOrder == 'Salesperson is not AE')
                {
                    this.showToast(component, "Success", "Value does not exist or does not match filter criteria.: [Account_Executives__c] cause null", "error", "dismissible");
                    this.closeQA(component, event, helper); 
                }
                    else {
                        console.log('response.getState inner else:::::::::::::::::::::::::::::::::'+String(salesOrder));
                        // this.showToast(component, "Error",salesOrder,"error",'sticky'); 
                        this.closeQA(component, event, helper);  
                    }
                
            } else {
                console.log('response.getState part 2:::::::::::::::::::::::'+response.getState());
                // this.showToast(component, "Error",salesOrder,"error"); 
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
        console.log('closeqa');
        $A.get("e.force:closeQuickAction").fire(); 
        $A.get("e.force:refreshView").fire(); 
    } 
})