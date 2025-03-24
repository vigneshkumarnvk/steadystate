({
    //before-save calculation <<
    calculateAll : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        if (helper.validateSalesOrder(component, event, salesOrder, jobTaskWrappers) == true) {
            helper.calculateSalesOrder(component, event, salesOrder, jobTaskWrappers, false);
        }
    },
    navigateToGeneratorLookup : function(component, event, helper) {
        console.log('navigate to gen look up Place 1');
        var overlayLibrary = component.find("overlayLib");
        var generatorLookup = "c:generatorLookup";
        var salesOrder = component.get("v.salesOrder");
        $A.createComponent( generatorLookup, {
                    "epaId": salesOrder.Alternate_Site_Address__c,
                    "siteName":  salesOrder.Site_Name__c,
                    "siteStreet": salesOrder.Site_Street__c,
                    "siteCity": salesOrder.Site_City__c,
                    "siteState": salesOrder.Site_State__c,
                    "sitePostalCode": salesOrder.Site_Postal_Code__c,
                    "mode" : "edit"
            },
            function(content, status, errorMessage) {
                if (status === 'SUCCESS') {
                   var modelPromise = overlayLibrary.showCustomModal({
                        header: "Generator Lookup",
                        body: content,
                        showCloseButton: true,
                        cssClass: "custom-overlay-class",
                        closeCallback: function() {
                            component.find("overlayLib").notifyClose();
                        }
                    });
                    component.set("v.modelPromise", modelPromise);
                } else {
                    console.log("Error Loading the Component :" + errorMessage);
                }
            }
        )
    },
    handleMessage : function(component, event, helper) {
        var message = event.getParam("dataToSend");
        var salesOrder = component.get("v.salesOrder");
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
        console.log('component.get("v.modelPromise") in gen flow::::::::'+component.get("v.modelPromise"));
        component.get("v.modelPromise").then(
            function (model) {
                model.close();
            }
        )
    },
    handleBillingProjectLookupMessage2 : function(component, event, helper) {
        var message = event.getParam("dataToSend");
        var salesOrder = component.get("v.salesOrder");
        salesOrder.EQAI_Billing_Project_Id__c = message.projectId;
        component.set("v.salesOrder", salesOrder);
        console.log('component.get("v.modelCreatePromise")'+component.get("v.modelCreatePromise"));
        console.log('component.get("v.modelPromise")'+component.get("v.modelPromise"));
        console.log('componentas whole'+JSON.stringify(component));
        component.get("v.modelCreatePromise").then(
            function (model) {
                model.close();
            }
        )
    },
    doSave : function(component, event, helper) {
        var hasError = false;
        var errorMessage = '';
        if (helper.validateFields(component, event)) {
            var salesOrder = component.get("v.salesOrder");
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            //Task#78352
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                for (var j = 0; j < jobTaskWrapper.SalesLines.length; j++) {
                    var salesLine = jobTaskWrapper.SalesLines[j];
                    //Bug#80870
                    if (salesLine.Facility__c && salesLine.Facility__r.Third_Party_Facility__c && salesOrder.Document_Type__c =='Sales Quote' && salesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c && $A.get("$Label.c.Release_Flag")==='true')
                    {
                        helper.showToast(component, 'Warning', 'You have chosen a 3rd Party Facility. Please create an approved facility in EQAI before converting this quote to an order.', 'warning','dismissible');
                    }
                    else if (salesLine.Facility__c && salesLine.Facility__r.Third_Party_Facility__c && salesOrder.Document_Type__c =='Sales Order' && salesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c && $A.get("$Label.c.Release_Flag")==='true'){
                        helper.showToast(component, 'Warning', 'You have chosen 3rd Party. Please create an approved facility in EQAI before Sending your Sales Order to EQAI.', 'warning','dismissible');
                    }
                if (salesLine.Category__c == 'Waste Disposal' && salesOrder.Service_Center__r.Advanced_Disposal__c &&
                        (salesOrder.Disposal_Billing_Method__c == null || salesOrder.Disposal_Billing_Method__c.trim() == '')) {
                        errorMessage = 'You have chosen Waste Disposal sales line. Please select Disposal billing method.';
                        hasError = true;
                    }
                    
                }
            }
            
            if (hasError) {
                helper.showToast(component, 'Error', errorMessage, 'Error', 'dismissible');
                return; 
            
            }
            new Promise(
                $A.getCallback(function(resolve, reject) {
                    helper.promptWizard(component, event, jobTaskWrappers, resolve, reject);
                }),
                $A.getCallback(function() {
                    reject();
                })
            ).then(
                $A.getCallback(function() {
                    return new Promise($A.getCallback(function (resolve, reject) {
                        helper.calculateSalesOrder(component, event, salesOrder, jobTaskWrappers, false, resolve, reject);
                    }));
                }),
                $A.getCallback(function(error) {
                    reject(error);
                })
            ).then(
                $A.getCallback(function(jobTaskWrappers2) {
                    jobTaskWrappers = jobTaskWrappers2;
                    return new Promise($A.getCallback(function (resolve, reject) {
                        helper.validateSalesOrder(component, event, salesOrder, jobTaskWrappers, resolve, reject);
                    }));
                }),
                $A.getCallback(function() {
                    reject();
                })
            ).then(
                $A.getCallback(function() {
                    helper.saveSalesOrder(component, event, jobTaskWrappers);
                }),
                $A.getCallback(function() {

                })
            ).catch(function() {
                $A.reportError("Error", error);
            });
        }
    },
    //job task >>
    //US141018 - handle response(true/false) from lwc  
    handleLWCResponse: function (component, event, helper) {
        component.set("v.callQuoteOrderLOAReminder", false);
        let response = event.getParam('result'); 
        component.set("v.showWarning", response);
        //If true proceed further, if false close the warning(lwc)
        if (response) {
            helper.saveSalesOrder(component, event);
        }
    },
})