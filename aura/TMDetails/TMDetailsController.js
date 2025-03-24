({
    //ticket 19674 <<
    doInit : function(component, event, helper) {
        var variables = component.get("v.variables");
        var tm = component.get("v.tm");
        if (tm.Status__c == 'Open' || tm.Status__c == 'Scheduled' || tm.Status__c == 'Mobile Review') {
            if (variables.User.Super_User__c == true || tm.Emergency_TM__c == true) {
                var invoicedLinesFound = false;
                var jobTaskWrappers = component.get("v.jobTaskWrappers");
                for (var i = 0; i < jobTaskWrappers.length; i++) {
                    var jobTaskWrapper = jobTaskWrappers[i];
                    for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                        if (jobTaskWrapper.TMLines[j].Invoiced__c == true) {
                            invoicedLinesFound = true;
                            break;
                        }
                    }
                    if (invoicedLinesFound) {
                        break;
                    }
                }

                if (!invoicedLinesFound) {
                    component.set("v.allowChangeSalesOrder", true);
                }
            }
        }
        //US115867
        helper.getUnvoicedPick(component, event);
    },
    //ticket 19674 >>
    handleLinkToSalesOrder : function(component, event, helper) {
        helper.linkToSalesOrder(component, event);
    },
    handleFromSalesOrderChange : function(component, event, helper) {
        var tm = component.get("v.tm");
        var record = event.getParam("record");
        if (record != null) {
            tm.Sales_Order__c = record.Id;
        }
        else {
            tm.Sales_Order__c = null;
        }
    },
    handleFromSalesQuoteChange : function(component, event, helper) {
        var tm = component.get("v.tm");
        var record = event.getParam("record");
        if (record != null) {
            tm.From_Sales_Quote__c = record.Id;
        }
        else {
            tm.From_Sales_Quote__c = null;
        }
        component.set("v.tm", tm);
    },
    handleContractChange : function(component, event, helper) {
        var tm = component.get("v.tm");
        var record = event.getParam("record");
        if (record != null) {
            tm.Contract__c = record.Id;
        }
        else {
            tm.Contract__c = null;
        }
        component.set("v.tm", tm);
    },
    handleRateSheetChange : function(component, event, helper) {
        var tm = component.get("v.tm");
        var record = event.getParam("record");
        if (record != null) {
            tm.Rate_Sheet__c = record.Id;
        }
        else {
            tm.Rate_Sheet__c = null;
        }
        component.set("v.tm", tm);
    },
    handleBillToContactChange : function(component, event, helper) {
        var tm = component.get("v.tm");
        var record = event.getParam("record");
        if (record != null) {
            tm.Contact__c = record.Id;
        }
        else {
            tm.Contact__c = null;
        }
        component.set("v.tm", tm);
    },
    handleProjectCoordinatorChange : function(component, event, helper) {
        var tm = component.get("v.tm");
        var record = event.getParam("record");
        if (record != null) {
            tm.Project_Coordinator__c = record.Id;
        }
        else {
            tm.Project_Coordinator__c = null;
        }
        component.set("v.tm", tm);
    },
    validateFields : function(component, event, helper) {
        var fields = new Array();
        fields.push(component.find("sales-order"));

        var params = event.getParams().arguments; 
        var status = params.validateAsStatus;
        if (status == 'Scheduled' || status == 'Confirmed') {
            component.set("v.validateAsStatus", status);
            fields.push(component.find("scheduled-date"));
        }

        var allValid = fields.reduce(function(valid, inputField) {
            if (inputField) {
                inputField.showHelpMessageIfInvalid();
            }
            return valid && inputField.get("v.validity").valid;
        }, true);

        return allValid;
    }
});