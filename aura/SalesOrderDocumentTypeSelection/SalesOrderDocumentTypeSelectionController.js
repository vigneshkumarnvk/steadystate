({
    doInit : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        var record = event.getParam("record");
        var accountId = component.get("v.recordId");
        console.log('in initiitititi:::::::'+accountId);
        //console.log('in initiitititi2:::::::'+$Label.c.Account_Number_Validation);
        helper.isCustomerInActive(component, event);
        helper.allowNewSalesOrders(component, event);
        helper.getContracts(component, event);
    },
    handleDocumentTypeChange : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        var record = event.getParam("record");
        console.log('in init1::::::::'+salesOrder.Bill_to_Customer_No__c);
        console.log('in v.salesOrder.Bill_to_Customer_No__r.AccountNumber::::::::'+salesOrder.Bill_to_Customer_No__r);
        
        helper.newSalesDocument(component, event);
    },
    handleSalesOrderTypeChange : function(component, event, helper) {
        //job task <<
        /*
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        if (record) {
            salesOrder.Sales_Order_Type__c = record.Id;
            salesOrder.Emergency_Sales_Order__c = record.Emergency_Response__c;
            salesOrder.Rate_Sheet__c = record.Rate_Sheet__c;
            salesOrder.Rate_Sheet__r = record.Rate_Sheet__r; //{"Name": record.Rate_Sheet__r.Name}
        }
        else {
            salesOrder.Sales_Order_Type__c = null;
            salesOrder.Emergency_Sales_Order__c = false;
            salesOrder.Rate_Sheet__c = null;
            salesOrder.Rate_Sheet__r = null;
        }
        component.set("v.salesOrder", salesOrder);
        */
        helper.validateSalesOrderType(component, event);
        //job task >>
    },
    handlePrevailingWageJobChange : function(component, event, helper) {
        component.set("v.salesOrder", component.get("v.salesOrder")); //update the field on the sales order information tab
    },
    handlePayRuleChange : function(component, event, helper) {
        //job task << move to SalesOrderBase
        /*
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesOrder.Pay_Rule__c", record.Id);
            component.set("v.salesOrder.Prevailing_Wage_Job__c", true);
        }
        else {
            component.set("v.salesOrder.Pay_Rule__c", null);
        }
        component.set("v.salesOrder", component.get("v.salesOrder")); //update the field on the sales order information tab
        */
        helper.validatePayRule(component, event);
        //job task >>
    },
    handleContractNotRequiredChange : function(component, event, helper) {
        var contractNotRequired = component.get("v.contractNotRequired");
        if (contractNotRequired == true) {
            component.set("v.salesOrder.Contract__c", null);
            component.set("v.salesOrder.Contract__r", null);
            component.set("v.salesOrder.Contract_Name__c", null);
            //surcharge <<
            //component.set("v.salesOrder.Surcharge_Type__c", 'Energy & Insurance');
            component.set("v.salesOrder.Surcharge_Type__c", null);
            //surcharge >>
            component.set("v.salesOrder.Surcharge_Pct__c", null);

            //billing rule mapping <<
            //helper.getCompanyDefaultBillingRule(component, event);
            //billing rule mapping >>

            //surcharge <<
            helper.validateContract(component, event);
            //surcharge >>
        }
    },
	handleContractChange : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        if (salesOrder.Contract__c == null) {
            return;
        }
        
        var contract;
		var contracts = component.get("v.contracts");
        if (contracts) {
            for (var i = 0; i < contracts.length; i++) {
                if (contracts[i].Id == salesOrder.Contract__c) {
                    contract = contracts[i];
                    break;
                }
            }
        }

        if(contract != null && contract.Name != null){
            salesOrder.Contract_Name__c = contract.Name;
        }

        if(contract != null && contract.Payment_Term__c != null){
            salesOrder.Payment_Term__c = contract.Payment_Term__c;
            salesOrder.Payment_Term__r = contract.Payment_Term__r;
        }

        //surcharge <<
        /*
        salesOrder.Contract__r = contract; //{ "Name": contract.Name, "ContractNumber": contract.ContractNumber };
        salesOrder.Contract_Name__c = contract.Name;
        if (contract.Billing_Rule__c != null) {
            salesOrder.Billing_Rule__c = contract.Billing_Rule__c;
            salesOrder.Billing_Rule__r = contract.Billing_Rule__r;
        }

        var calcSurchargePct;
        if (contract.Surcharge_Type__c != null) {
            salesOrder.Surcharge_Type__c = contract.Surcharge_Type__c;
            salesOrder.Surcharge_Pct__c = contract.Surcharge_Pct__c;
            calcSurchargePct = false;
        }
        else {
            salesOrder.Surcharge_Type__c = 'Energy & Insurance';
            calcSurchargePct = true;
        }
        component.set("v.salesOrder", salesOrder);
        helper.calculateSalesOrder(component, event, calcSurchargePct);
        */
        helper.validateContract(component, event);
        //surcharge >>
	},
    handleQuoteChange : function(component, event, helper) {
		var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        if (record) {
            salesOrder.From_Sales_Quote__c = record.Id;
            salesOrder.From_Sales_Quote__r = record;
            salesOrder.Quote_Date__c = record.Quote_Date__c;
        }
        else {
            salesOrder.From_Sales_Quote__c = null;
            salesOrder.From_Sales_Quote__r = null;
            salesOrder.Quote_Date__c = null;
        }
        component.set("v.salesOrder", salesOrder);
	},
    validateFields : function(component, event, helper) {
        var fields = new Array();
        var salesOrder = component.get("v.salesOrder");

        if (salesOrder.Document_Type__c == 'Sales Order') {
            fields.push(component.find("document-type"));
        }
        fields.push(component.find("sales-order-type"));

        var contractSelectOptions = component.get("v.contractSelectOptions");
        if (salesOrder.From_Sales_Quote__c == null && contractSelectOptions.length > 0) {
            if (component.get("v.contractNotRequired") != true) {
                fields.push(component.find("contract"));
            }
        }

        //prevailing wage job <<
        if (salesOrder.Prevailing_Wage_Job__c == true) {
            fields.push(component.find("pay-rule"));
        }
        if (salesOrder.Pay_Rule__c != null) {
            fields.push(component.find("prevailing-wage-job"));
        }
        //prevailing wage job >>
        
        var allValid = fields.reduce(function(valid, inputField) {
            if (inputField) {
                if (Array.isArray(inputField)) {
                    for (var i = 0; i < inputField.length; i++) {
                        inputField[i].showHelpMessageIfInvalid();
                        valid = valid && inputField[i].get("v.validity").valid;
                    }
                }
                else {
                    inputField.showHelpMessageIfInvalid();
                    valid = valid && inputField.get("v.validity").valid;
                }
            }
            //return valid && inputField.get("v.validity").valid;
            return valid;
        }, true);
        return allValid;
    }
})