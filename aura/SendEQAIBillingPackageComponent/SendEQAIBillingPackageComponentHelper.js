({
    sendJobBillingProjectToEQAIHelper: function (component, event) {
         var recordId = component.get("v.recordId");
         var action = component.get("c.updateDocumentTypeID");
        var salesOrderId = component.get("v.salesInvoice").Sales_Order__c;

        action.setParams({
            "salesInvoiceId": recordId,
            "salesOrderId" :salesOrderId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var salesInv = response.getReturnValue();
            if (state === "SUCCESS") {
                if(salesInv != "200"){
                    let convertedResponse = salesInv.toLowerCase();
                    if(convertedResponse.includes('salesforce jobbillingproject csid') || convertedResponse.includes('billing project already exists') ){
                        //this.updateStatusInSalesOrder(component, event);
                        this.showToast(component, "Success", "Job Billing Package Already Exists.", "success", "dismissible");  
                    }else{
                        let obj = JSON.parse(salesInv);
                        let message = obj.details[0].statusMessage;
                        this.showToast(component, "Error", "A Billing Project could not be created. Your SF Admin has been alerted.", "error");    
                    }
                }else{
                  this.showToast(component, "Success", "Job Billing Package Successfully Created .", "success", "dismissible");  
                }
                this.closeQA(component, event, helper); 
            } else {
                console.log('error===>'+salesInv);
                this.showToast(component, "Error", action.getError()[0].message, "error", "dismissible"); 
               // this.showToast(component, "Error",salesInv,"error"); 
                this.closeQA(component, event, helper);  
            }
        });
        
        $A.enqueueAction(action);
    },
    updateStatusInSalesOrder:function (component, event) {
         var recordId = component.get("v.recordId");
         var action = component.get("c.updateStatusInSalesOrder");
        action.setParams({
            "salesInvoiceId": recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            var salesInv = response.getReturnValue();
            if (state === "SUCCESS") {
                this.showToast(component, "Success", "Job Billing Package Already Exists .", "success", "dismissible");  
                this.closeQA(component, event, helper); 
            } else {
                console.log('error===>'+salesInv);
                this.showToast(component, "Error", action.getError()[0].message, "error", "dismissible"); 
               // this.showToast(component, "Error",salesInv,"error"); 
                this.closeQA(component, event, helper);  
            }
        });
        
        $A.enqueueAction(action);
    },
    sendSalesInvToEQAIHelper: function (component, event) {
        console.log('check====>')
        var recordId = component.get("v.recordId");
        var action = component.get("c.sendSalesInvoiceToEQAI");
        var fileUploader = component.find("Attachment"); // Get a reference to the LWC component
        action.setParams({
            "recordId": recordId
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('response.getState:::::::::::::::::::::::'+response.getState());
            console.log('response :::::::::::::::::::::::'+JSON.stringify(response));
            if (state === "SUCCESS") {
                console.log('state'+state);
                var salesInv = response.getReturnValue();
                if (salesInv == 'Service Center Disabled') {
                    this.showToast(component, "Error", "This function is disabled for this service center.", "error", "dismissible"); 
                    this.closeQA(component, event, helper);  
                } 
                else if (salesInv == 'D365_Project_ID is null') {
                    this.showToast(component, "Error", "Cannot send billing package to EQAI if D365 project id does not exist.", "error", "dismissible"); 
                    this.closeQA(component, event, helper);  
                }
                else if (salesInv == 'Sent to EQAI') {
                    this.showToast(component, "Error", "The Billing Package is already sent to EQAI.", "error", "dismissible"); 
                    this.closeQA(component, event, helper);  
                }
                else if (salesInv == 'Not Approved') {
                    this.showToast(component, "Error", "The Billing Package is not Approved. The Billing Package must be approved before submitting to EQAI.", "error", "dismissible"); 
                    this.closeQA(component, event, helper);  
                }
                    else if (salesInv.includes("on waste disposal line is invalid. Based on the selected profile approval")) {
                        this.showToast(component, "Error",salesInv, "error", "dismissible"); 
                        this.closeQA(component, event, helper); 
                    }
                else if( salesInv == 'True')
                {
                   console.log('makeCallout');
			        fileUploader.makeCallout();
                    //this.showToast(component, "Success", "The Billing Package has been submitted to EQAI.", "success", "dismissible");
                    //this.closeQA(component, event, helper); 
                }
                else if(salesInv == 'on submit validation.'){

                    this.showToast(component, "Error", "Both a BOL/Manifest and Profile Approval are required for Waste Disposal.", "error", "dismissible"); 
                    this.closeQA(component, event, helper);  
                }
                    else {

                        this.showToast(component, "Error",salesInv,"error",'sticky'); 
                        this.closeQA(component, event, helper);  
                    }
                
            } else {
                console.log('response.getState part 2:::::::::::::::::::::::'+response.getState());
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
    },
    getInvoiceDetails : function(component,event) {

        var recordId = component.get("v.recordId");
        var params = { "salesInvoiceId": recordId };
        this.callServerMethod(component, event, "c.getSalesInvoice", params, function(response) {
            var salesInvoice = JSON.parse(response);
            component.set("v.salesInvoice",salesInvoice);
            component.set("v.channel",salesInvoice.Bill_to_Customer__r.Invoice_Submission_Channels__c);
            //component.set("v.preventBilling",salesInvoice.Bill_to_Customer__r.Prevent_Billing_Project__c);
           
            if(!salesInvoice.Sales_Order__r.SO_sent_to_EQAI__c){
                //this.showToast(component, "Error",salesInv,"error"); 
                this.showToast(component, "Error", "Associated Sales Order does not sync with the  EQAI", "error", "dismissible");
                this.closeQA(component, event, helper); 
            }else{
                if(salesInvoice.BP_Sent_to_EQAI__c){
                    if(!salesInvoice.Sales_Order__r.JB_Sent_to_EQAI__c ){
                        component.set("v.hasSubmitted",true);
                        
                    }else{
                        component.set("v.hasSubmitted",false);
                        this.sendSalesInvToEQAIHelper(component, event); 
                         
                    }
                }else{
                    component.set("v.hasSubmitted",false);
                    this.sendSalesInvToEQAIHelper(component, event); 
                   
                }
                
                
            }
            
           
        });
    }
})