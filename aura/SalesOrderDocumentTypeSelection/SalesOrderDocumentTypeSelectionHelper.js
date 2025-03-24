({
	getContracts : function(component, event) {
        //var accountId = component.get("v.salesOrder.Bill_to_Customer_No__c");
        var accountId = component.get("v.recordId"); //recordId = customer id
        var params = { "accountId": accountId };
		this.callServerMethod(component, event, "c.getContracts", params, function(response) {

            component.set("v.contracts", response);
            var options = [];
            if (response.length > 0) {
                for (var i = 0; i < response.length; i++) {
                    var contract = response[i];
                    options.push({"label": contract.ContractNumber + ' - ' + contract.Name + ' - Exp ' + $A.localizationService.formatDate(contract.EndDate, 'MM/dd/yyyy'), "value": contract.Id});
                }
            }
            component.set("v.contractSelectOptions", options);
        });
	},
    allowNewSalesOrders : function(component, event) {
        var accountId = component.get("v.recordId"); //recordId = customer id
        console.log('in helper1'+component.get("v.setupData"));
        var params = { "accountId": accountId };
        this.callServerMethod(component, event, "c.allowNewSalesOrders", params, function(response) {
            component.set("v.allowNewSalesOrders", response);
            console.log('allowNewSalesOrders response:::::::'+response);
            if (response != true) {
                var documentType = 'Sales Quote';
                var contractId = null;
                //contract specific resource <<
                /*
                var userInfoWrapper = component.get("v.userInfoWrapper");
                var serviceCenter = userInfoWrapper.ServiceCenter.Name;
                */
                var setupData = component.get("v.setupData");
                
                var serviceCenter = setupData.ServiceCenter.Name;
                //contract specific resource >>
                this.createSalesDocument(component, event, documentType, accountId, serviceCenter, contractId);
            }
        });
    },
    isCustomerInActive : function(component, event) {
        console.log('inside new method');
        var accountId = component.get("v.recordId"); //recordId = customer id
        var params = { "accountId": accountId };
        this.callServerMethod(component, event, "c.isCustomerInActive", params, function(response) {
            component.set("v.isCustomerInActive", response);
            console.log('response in new method::::::::'+response);
        });
    },
    getCompanyDefaultBillingRule : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        this.callServerMethod(component, event, "c.getCompanySetup", null, function(response) {
            salesOrder.Billing_Rule__c = response.Default_Billing_Rule__c;
            salesOrder.Billing_Rule__r = response.Default_Billing_Rule__r;
            component.set("v.salesOrder", salesOrder);
            //job task <<
            //this.calculateSalesOrder(component, event, true);
            var salesOrder = component.get("v.salesOrder");
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            this.calculateSalesOrder(component, event, salesOrder, jobTaskWrappers, true);
            //job task >>
        })
    },
    newSalesDocument : function(component, event) {
        //var documentType = event.getSource().get("v.value");
        var documentType = component.get("v.salesOrder.Document_Type__c");
        var accountId = component.get("v.salesOrder.Bill_to_Customer_No__c");
        var contractId = component.get("v.salesOrder.Contract__c");
        //contract specific resource <<
        /*
        var userInfoWrapper = component.get("v.userInfoWrapper");
        var serviceCenter = userInfoWrapper.ServiceCenter.Name;
        */
        var setupData = component.get("v.setupData");
        var serviceCenter = setupData.ServiceCenter.Name;
        //contract specific resource >>
        this.createSalesDocument(component, event, documentType, accountId, serviceCenter, contractId);
    },
    createSalesDocument : function(component, event, documentType, accountId, serviceCenter, contractId) {
        var params = { "documentType":  documentType, "customerId": accountId, "serviceCenter": serviceCenter, "contractId": contractId };
        this.callServerMethod(component, event, "c.createNewSalesOrder", params, function(response) {
            //fix.null.fields <<
            /*
            //set owner
            var userInfoWrapper = component.get("v.userInfoWrapper");
            response.SalesOrder.OwnerId = userInfoWrapper.User.Id;
            response.SalesOrder.Owner = userInfoWrapper.User;
            response.SalesOrder.Owner.attributes = { "type" : 'User' };

            //correct quote status and quote type -- EnumUtil uses the upper case values
            response.SalesOrder.Quote_Status__c = 'Pending';
            response.SalesOrder.Quote_Type__c = 'One_Time';

            component.set("v.salesOrder", response.SalesOrder);
            component.set("v.salesLines", response.SalesLines);
            */

            //set owner
            //job task <<
            /*
            var salesOrder = JSON.parse(response.JSONSalesOrder);
            var salesLines = JSON.parse(response.JSONSalesLines);

            var userInfoWrapper = component.get("v.userInfoWrapper");
            salesOrder.OwnerId = userInfoWrapper.User.Id;
            salesOrder.Owner = userInfoWrapper.User;
            salesOrder.Owner.attributes = { "type" : 'User' };

            //correct quote status and quote type -- EnumUtil uses the upper case values
            salesOrder.Quote_Status__c = 'Pending';
            salesOrder.Quote_Type__c = 'One_Time';

            component.set("v.salesOrder", salesOrder);
            component.set("v.salesLines", salesLines);
            */
            var salesOrderWrapper = JSON.parse(response);
            var salesOrder = salesOrderWrapper.SalesOrder;
            var jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;

            //contract specific resource <<
            /*
            var userInfoWrapper = component.get("v.userInfoWrapper");
            salesOrder.OwnerId = userInfoWrapper.User.Id;
            salesOrder.Owner = userInfoWrapper.User;
            */
            var setupData = component.get("v.setupData");
            salesOrder.OwnerId = setupData.User.Id;
            salesOrder.Owner = setupData.User;
            //contract specific resource >>

            salesOrder.Owner.attributes = { "type" : 'User' };

            //correct quote status and quote type -- EnumUtil uses the upper case values
            salesOrder.Quote_Status__c = 'Pending';
            salesOrder.Quote_Type__c = 'One_Time';

            component.set("v.salesOrder", salesOrder);
            component.set("v.jobTaskWrappers", jobTaskWrappers);
            //job task >>
            //fix.null.fields >>
        }, function(error){
            this.showToast(component, "Error", error, "error", "dismissible");
        });
    },
    //job task <<
    /*
    validateContract : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var salesLines = component.get("v.salesLines");

        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONSalesLines": JSON.stringify(salesLines) };
        this.callServerMethod(component, event, "c.validateContract", params, function(response) {
            salesOrder = JSON.parse(response.JSONSalesOrder);
            salesLines = JSON.parse(response.JSONSalesLines);
            component.set("v.salesOrder", salesOrder);
            component.set("v.salesLines", this.sortSalesLines(salesLines));
        })
        this.validateContract(component, event);
    }
    */
    //job task >>
})