({
    getSalesOrder : function(component, event) {
        var recordId = component.get("v.recordId");
        
        if (recordId) {
            var params = { "salesOrderId": recordId };
            this.callServerMethod(component, event, "c.getSalesOrder", params, function(response) {
                
                //fix.null.fields <<
                /*
                //include "attributes", owner field relationship without "attributes" causes JSON deserialize error in the apex controller
                response.SalesOrder.Owner.attributes = { "type": 'User' };
                component.set("v.salesOrder", response.SalesOrder);
                component.set("v.salesLines", this.sortSalesLines(response.SalesLines));
                */
                //include "attributes", owner field relationship without "attributes" causes JSON deserialize error in the apex controller
                //job task <<
                /*
                var salesOrder = JSON.parse(response.JSONSalesOrder);
                var salesLines = JSON.parse(response.JSONSalesLines);
                salesOrder.Owner.attributes = { "type": 'User' };
                component.set("v.salesOrder", salesOrder);
                component.set("v.salesLines", this.sortSalesLines(salesLines));
                */
                var salesOrderWrapper = JSON.parse(response);
                var jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
                var billToContacts = salesOrderWrapper.SObillToContacts;
                component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
                
                component.set("v.soType", {
                    operation: "edit",
                    existingSalesOrderType: component.get("v.salesOrder.Sales_Order_Type__c"),
                    displayWaringMsg: false
                });	//US114833
                
                for (var i = 0; i < jobTaskWrappers.length; i++) {
                    //jobTaskWrappers[i].Collapsed = true; //default to collapsed
                    this.sortSalesLines(jobTaskWrappers[i].SalesLines);
                    
                    //ticket 20566 << - move the code to server side to reduce json size
                    /*
                    //ticket 20177 <<
                    var jobTaskWrapper = jobTaskWrappers[i];
                    if (jobTaskWrapper.JobTask.TM_Job_Tasks__r && jobTaskWrapper.JobTask.TM_Job_Tasks__r.records) {
                        jobTaskWrapper.HasTMs = true;
                        for (var j = 0; j < jobTaskWrapper.JobTask.TM_Job_Tasks__r.records.length; j++) {
                            if (jobTaskWrapper.JobTask.TM_Job_Tasks__r.records[j].TM__r.Sales_Invoice__c) {
                                jobTaskWrapper.HasInvoices = true;
                            }
                        }
                    }
                    //ticket 20177 >>
                    */
                    //ticket 20566 >>
                }
                
                component.set("v.jobTaskWrappers", jobTaskWrappers);
                component.set("v.billToContacts", billToContacts);    
                var projectId = salesOrderWrapper.SalesOrder.EQAI_Billing_Project_Id__c;
                var projectName = salesOrderWrapper.SalesOrder.EQAI_Billing_Project_Name__c;
                
                var billingProjectDisplay = '';
                if (projectId && projectName) {
                    billingProjectDisplay = `${projectId} - ${projectName}`;
                } else if (projectId) {
                    billingProjectDisplay = `${projectId}`;
                }
                
                // Set the billing project name
                component.set("v.billingProjectName", billingProjectDisplay);
                
                component.set("v.isBillingProjectVisible", !!billingProjectDisplay);
                
                
                //job task >>
                
                //fix.null.fields >>
                var params1 = { "accountRecordId": salesOrderWrapper.SalesOrder.Bill_to_Customer_No__c };
                this.callServerMethod(component, event, "c.getAccountData", params1, function (response) {
                    component.set("v.accountExecutiveIds", response);               
                }, function(error){
                    this.showToast(component, "Error", error, "error", "Sticky");
                    
                });
            });
        }
        else {
            throw ('Please create sales orders/quotes from the customer account.');
        }
        this.getUserInfo(component, event);
    },
    getUserInfo : function(component, event) {
        //contract specific resource <<
        /*
        this.callServerMethod(component, event, "c.getUserInfo", null, function(response) {
            component.set("v.userInfoWrapper", response);
        });
        */
        this.callServerMethod(component, event, "c.getSetupData", null, function(response) {
            var setupData = JSON.parse(response);
            component.set("v.setupData", setupData);
        });
        //contract specific resource >>
    },
    //job task <<
    validateFields : function(component, event) {
        try {
            var ok = true;
            ok = this.validateJobTasks(component, event);
            if (ok) {
                var errors = [];
                //calling child components' validateField method
                var cmps = component.find("step");
                cmps.push(component.find("sales-lines"));
                ok = cmps.reduce(function (valid, step) {
                    if (step["validateFields"] != null) { //if the component support validateFields method
                        var validStep = step.validateFields();
                        if (!validStep) {
                            errors.push(step.getName());
                        }
                        return valid && validStep;
                    } else {
                        return valid;
                    }
                }, true);
                
                if (!ok) {
                    var steps = component.find("step");
                    steps.push(component.find("sales-lines"));
                    for (var i = 0; i < steps.length; i++) {
                        if (errors[0] == steps[i].getName()) { //go to the first tab with validation error
                            component.find("tabset").set("v.selectedTabId", 'tab' + i);
                            break;
                        }
                    }
                    
                    this.showToast(component, 'Error', 'You must enter all required fields.', 'error', 'dismissible');
                }
            }
            return ok;
        }
        catch(error) {
            alert(error);
        }
    }
    //job task >>
})