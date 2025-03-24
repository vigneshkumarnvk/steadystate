({
    handleContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesInvoice.Contact__c", record.Id);
        }
        else {
            component.set("v.salesInvoice.Contact__c", null);
        }
    },
    handlePaymentTermChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesInvoice = component.get("v.salesInvoice");
        if (record) {
            component.set("v.salesInvoice.Payment_Term__c", record.Id);
            component.set("v.salesInvoice", salesInvoice);
            helper.validatePaymentTerm(component, event, salesInvoice);
        }
        else {
            component.set("v.salesInvoice.Payment_Term__c", null);
        }
    },
    handleInvoiceDateChange : function (componet, event, helper){
        var salesInvoice = componet.get("v.salesInvoice");
        if(salesInvoice.Invoice_Date__c != null){
            helper.validatePaymentTerm(componet, event, salesInvoice);
        }
        componet.set("v.salesInvoice", salesInvoice);
    },
    handleRetainagePctChange : function(component, event, helper) {
        var salesInvoice = component.get("v.salesInvoice");
        var invoiceAmount = salesInvoice.Invoice_Amt_Incl_Tax__c;
        var retainagePct = salesInvoice.Retainage_Pct__c;
        if (!invoiceAmount) invoiceAmount = 0;
        if (!retainagePct) retainagePct = 0;
        var retainageAmount = Math.round(invoiceAmount * retainagePct) / 100;
        component.set("v.salesInvoice.Retainage_Amount__c", retainageAmount);
    },
    handleApplyToSalesInvoiceChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesInvoice = component.get("v.salesInvoice");
        if (record) {
            salesInvoice.Reversed_from_SI__c = record.Id;
            component.set("v.salesInvoice", salesInvoice);
            helper.validateAppliesToDoc(component, event, salesInvoice);
        }
        else {
            salesInvoice.Reversed_from_SI__r = null;
            component.set("v.salesInvoice", salesInvoice);
        }
    },
    validateFields : function(component, event, helper) {
        var fields = [];
        fields.push(component.find("applies-to-invoice"));
        var ok = fields.reduce(function(valid, inputField) {
            if (inputField) {
                inputField.showHelpMessageIfInvalid();
            }
            return valid && inputField.get("v.validity").valid;
        }, true);

        return ok;
    }
});