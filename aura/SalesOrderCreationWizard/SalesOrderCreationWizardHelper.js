({
    getData : function(component, event) {
        console.log('get data running');
        //contract specific resource <<
        /*
        this.callServerMethod(component, event, "c.getUserInfo", null, function(userInfoWrapper) {
            component.set("v.userInfoWrapper", userInfoWrapper);
            var accountId = component.get("v.recordId");

            var params = { "customerId": accountId };
            this.callServerMethod(component, event, "c.isValidCustomer", params, function (isValid) {
                component.set("v.salesOrder", {"Bill_to_Customer_No__c": accountId, "Document_Status__c": 'Open'});
            }, function (err) {
                this.showToast(component, "Invalid Customer", err, "error", "Sticky");
                $A.get("e.force:closeQuickAction").fire();
            });
        });
        */
        this.callServerMethod(component, event, "c.getSetupData", null, function(response) {
            var setupData = JSON.parse(response);
            component.set("v.setupData", setupData);

            var accountId = component.get("v.recordId");

            var params = { "customerId": accountId };
            this.callServerMethod(component, event, "c.isValidCustomer", params, function (isValid) {
                component.set("v.salesOrder", {"Bill_to_Customer_No__c": accountId, "Document_Status__c": 'Open'});
            }, function (err) {
                this.showToast(component, "Invalid Customer", err, "error", "Sticky");
                $A.get("e.force:closeQuickAction").fire();
            });
            var params1 = { "accountRecordId": accountId };
            this.callServerMethod(component, event, "c.getAccountData", params1, function (response) {
                component.set("v.accountExecutiveIds", response);               
            }, function(error){
            this.showToast(component, "Error", error, "error", "Sticky");
        
            });
        });
        //contract specific resource >>
    },
    showStep : function(component, event) {
        //var currentStep = component.get("v.currentStep");
        var stepName = component.get("v.stepName");
        var containers = component.find("step-container");
        for (var i = 0; i < containers.length; i++) {
            var container = containers[i];
            if (container.getElement().getAttribute("data-value") == stepName) {
                $A.util.addClass(container, "slds-show");
                $A.util.removeClass(container, "slds-hide");
            }
            else {
                $A.util.addClass(container, "slds-hide");
                $A.util.removeClass(container, "slds-show");
            }
        }

        //job task <<
        if (stepName == 'sales-lines') {
            this.showTemplateWizard(component, event);
        }
        //job task >>
    },
    validateFields : function(component, event, skipSalesLines) {
        var ok = true;
        ok = this.validateJobTasks(component, event);
        console.log(ok, "OKAY");
        if (ok) {            
            var tabsWithError = [];
            var cmps = component.find("step");
            if (skipSalesLines != true) {
                cmps.push(component.find("sales-lines"));
            }
            ok = cmps.reduce(function (valid, step) {
                if (step["validateFields"] != null) { //if the component support validateFields method
                    var validStep = step.validateFields();
                    if (!validStep) {
                        tabsWithError.push(step.get("v.name"));
                    }
                    return valid && validStep;
                } else {
                    return valid;
                }
            }, true);

            if (tabsWithError.length > 0) {
                //find first tab
                console.log(tabsWithError);
                var stepName;
                var tabs = component.get("v.tabs");
                for (var i = 0; i < tabs.length; i++) {
                    for (var j = 0; j < tabsWithError.length; j++) {
                        if (tabs[i] == tabsWithError[j]) {
                            stepName = tabs[i];
                            break;
                        }
                    }
                    if (stepName != null) {
                        break;
                    }
                }

                component.set("v.stepName", stepName);
                this.showToast(component, 'Field Validation Error', 'You must complete all required fields before continuing.', 'error', 'dismissible');
            }
        }
        return ok;
    },
    //Ticket#27427
    validateServiceCenter : function (component, event) {
        var salesOrder = component.get('v.salesOrder');
        if((salesOrder.Service_Center__c != null || salesOrder.Service_Center__c != undefined) &&
            salesOrder.Service_Center__r.Prevent_New_and_Cloned_Sales_Orders__c == true &&
            salesOrder.Document_Type__c == 'Sales Order'){
                this.showToast(component, "Error", 'Service Center ' + salesOrder.Service_Center__r.Name + ' is prevented from creating new Sales Orders.', "error", "dismissible");
                return false;
        }
        return true;
    },
    cancelCreateDocumentCallback : function(component, event, result) {
        component.find("modal").close();
    },
    confirmCancelCreation : function (component, event, helper) {
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
        this.openModal(component, event, "Cancel", 'Are you sure you want to cancel the quote/order creation?', buttons, null, null, null);
    },
    cancelCreationCancelled : function(component, event, helper) {
        this.closeModal(component, event);
    },
    cancelCreationConfirmed : function(component, event) {
        this.closeModal(component, event);
        $A.get("e.force:closeQuickAction").fire();
    },
    showTemplateWizard : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        if (salesOrder.Sales_Order_Type__r && salesOrder.Sales_Order_Type__r.Job_Task_Template__r != null && jobTaskWrappers.length <= 0) {
            this.addJobTask(component, event, salesOrder.Sales_Order_Type__r.Job_Task_Template__r);
        }
    },
    handleCreateSalesOrderMessage : function(component, event) {
        let message = event.getParam("dataToSend");
        let salesOrder = component.get("v.salesOrder");
        if (message === 'close'){
            component.get("v.modelCreatePromise").then(
                function (model) {
                    model.close();
                }
            );
        } else {
            salesOrder.Alternate_Site_Address__c = message.epaId;
            salesOrder.Site_Name__c = message.name;
            salesOrder.Site_Street__c = message.streetAddress;
            salesOrder.Site_City__c = message.city;
            salesOrder.Site_State__c = message.state;
            salesOrder.Site_Postal_Code__c = message.zip;
            salesOrder.Site_Phone_No__c = message.businessPhone;
            salesOrder.EqaiGeneratorId__c = message.eqaiGeneratorId;
            salesOrder.EPA_ID__c = message.epaId;
            component.set("v.salesOrder", salesOrder);
            component.get("v.modelCreatePromise").then(
                function (model) {
                    model.close();
                }
            );
        }
    }
})