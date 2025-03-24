({
    //Ticket#18812
    validateBillToCustomer : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.validateCustomer", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);
            component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
            component.set("v.jobTaskWrappers", salesOrderWrapper.JobTaskWrappers);
        }, function (error){
            this.showToast(component, "Error", error, "error", "dismissible");
        });
    },
	validateCustomerPONumber : function (component, event){
        var customerId = component.get("v.salesOrder.Bill_to_Customer_No__c");
        var poNumber = component.get("v.salesOrder.Customer_PO_No__c");
        var params = { "customerId":  customerId, "poNumber": poNumber };
        this.callServerMethod(component, event, "c.isValidCustomerPONumber", params, function(response) {
            component.set("v.salesOrder.Customer_PO_No__c", poNumber);
        })
    },
    navigateTobillingProjectLookup : function (component, event) {
        //var overlayLibrary = component.find("overlayLib");
        console.log('in helper');
        let overlayLibrary = component.find("overlayLibCreateSalesOrder");
        let billingProjectLookup = "c:billingProjectLookup";
        let salesOrder = component.get("v.salesOrder");
        var customerId = salesOrder.Bill_to_Customer_No__r.Sage_Customer_No__c;
        var serviceCenter = salesOrder.Service_Center__r.Name;
        $A.createComponent( billingProjectLookup, {
                    "customerId": customerId,
                    "serviceCenter":serviceCenter
            },
            function(content, status, errorMessage) {
                if (status === 'SUCCESS') {
                   let modelPromise = overlayLibrary.showCustomModal({
                        header: "Billing Project Lookup",
                        body: content,
                        showCloseButton: true,
                        cssClass: "custom-createoverlay-class",
                        closeCallback: function() {
                            closeQA();
                        }
                    });
                    component.set("v.modelCreatePromise", modelPromise);
                } else {
                    console.log("Error Loading the Component :" + errorMessage);
                }
            }
        )
    }
})