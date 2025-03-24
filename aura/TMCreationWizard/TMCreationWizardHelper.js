({
    getSalesOrder : function(component, event) {
        var recordId = component.get("v.recordId");
        if (recordId) {
            var params = { "salesOrderId": recordId };
            this.callServerMethod(component, event, "c.getSalesOrder", params, function(response) {
                var salesOrderWrapper = JSON.parse(response);
                var jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
                for (var i = 0; i < jobTaskWrappers.length; i++) {
                    jobTaskWrappers[i].Collapsed = true; //default to collapsed
                    for (var j = 0; j < jobTaskWrappers[i].SalesLines.length; j++) {
                        var salesLine = jobTaskWrappers[i].SalesLines[j];
                        if (salesLine.System_Calculated_Line__c == true) {
                            jobTaskWrappers[i].SalesLines.splice(j, 1);
                            j--;
                        }
                        else if (salesLine.Parent_Line__r && (!salesLine.Quantity__c || salesLine.Quantity__c == 0)) {
                            jobTaskWrappers[i].SalesLines.splice(j, 1);
                            j--;
                        }
                        
                        //ticket 21929 <<
                        delete salesLine.Sales_Order_Job_Task__r.TM_Job_Tasks__r;
                        //ticket 21929 >>
                    }
                }

                if (jobTaskWrappers.length == 1) {
                    jobTaskWrappers[0].Selected = true;
                    jobTaskWrappers[0].disableCheck = true;
                }
				component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
                component.set("v.jobTaskWrappers", jobTaskWrappers);
                if(salesOrderWrapper.SalesOrder.Pay_Rule__c){
                	component.set("v.payruleBlocked", salesOrderWrapper.SalesOrder.Pay_Rule__r.Blocked__c);
                }else{
                    component.set("v.nopayruleSelected", true);
                }
                if(salesOrderWrapper.SalesOrder.SO_Submitted_to_EQAI__c ==false && salesOrderWrapper.SalesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c){
                    component.set("v.groupASC", true);
                }


                //var message = component.find("message");
                //if (salesOrderWrapper.SalesOrder.Approval_Status__c == 'Approved') {
                //    $A.util.removeClass(message, "slds-hide");
                //}
            });
        }
    },

    confirmTMCreation : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        if (salesOrder.Bill_to_Customer_No__r) {
            if (salesOrder.Bill_to_Customer_No__r.Credit_Hold__c == true) {
                var buttons = [];
                buttons.push({ "label": 'No', "variant": 'neutral', "action": { "callback": this.cancelCreationCancelled.bind(this, component, event) }});
                buttons.push({ "label": 'Yes', "variant": 'brand', "action": { "callback": this.createTM.bind(this, component, event) }});

                this.openModal(component, event, "Create T&M", 'Customer is on credit hold. Are you sure you want to continue?', buttons, null, null, null);
            }
            else {
                this.createTM(component, event);
            }
        }
        else {
            this.showToast(component, "", "Bill-to Customer is invalid.", "error", "dismissible");
        }
    },
    createTM : function(component, event) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var selectedJobTaskWrappers = [];
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTask = jobTaskWrappers[i].JobTask;
            var selectedJobTaskWrapper = { "JobTask": jobTask, "SalesLines": []};

            var selectedCount = 0;
            if (jobTaskWrappers[i].Selected == true) {
                for (var j = 0; j < jobTaskWrappers[i].SalesLines.length; j++) {
                    var jobTaskWrapper = jobTaskWrappers[i];
                    var salesLine = jobTaskWrapper.SalesLines[j];
                    if (salesLine.Selected == true && salesLine.Category__c != 'Bundled') {
                        selectedJobTaskWrapper.SalesLines.push(salesLine);
                        selectedCount++;
                    }
                }
                selectedJobTaskWrappers.push(selectedJobTaskWrapper);
            }
        }
        if (selectedJobTaskWrappers.length == 0) {
            this.showToast(component, "Error", "You must select at least one job task create T&M.", "error", "dismissible");
            return;
        }


        var salesOrderId = component.get("v.recordId");
        var params = { "salesOrderId": salesOrderId, "JSONSalesOrderJobTaskWrappers": JSON.stringify(selectedJobTaskWrappers) };
        //ticket 19861 <<
        /*
        this.callServerMethod(component, event, "c.createTMFromSalesOrder", params, function (tmId) {
            this.navigateToSObject(component, event, tmId);
        });
        */
        //console.log('******' + JSON.stringify(selectedJobTaskWrappers) );
        this.callServerMethod(component, event, "c.createTMFromSalesOrder", params, function (tmId) {
            this.navigateToSObject(component, event, tmId);
        }, function(err) {
            this.showToast(component, "", err, "error", "dismissible");
        });
        //ticket 19861 <<

    },
    confirmCancelCreation : function (component, event) {
        var buttons = [];
        buttons.push({
            "label": 'No',
            "variant": 'neutral',
            "action": {"callback": this.cancelCreationCancelled.bind(this, component, event)}
        });
        buttons.push({
            "label": 'Yes',
            "variant": 'brand',
            "action": {"callback": this.cancelCreationConfirmed.bind(this, component, event)}
        });
        this.openModal(component, event, "Cancel", 'Are you sure you want to cancel T&M creation?', buttons, null, null, null);
    },
    cancelCreationCancelled : function(component, event) {
        this.closeModal(component, event);
    },
    cancelCreationConfirmed : function(component, event) {
        this.closeModal(component, event);
        $A.get("e.force:closeQuickAction").fire();
    },
    //Task#78352
    getFacility : function(component, event) {
        var recordId = component.get("v.recordId");
        if (recordId) {
            var params = { "salesOrderId": recordId };
            this.callServerMethod(component, event, "c.getThirdFacility", params, function(response) {
            component.set("v.faciltyas3rdParty", response);   
            });
        }
    },    
});