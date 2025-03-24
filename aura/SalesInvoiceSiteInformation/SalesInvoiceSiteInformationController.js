({
    handleSiteContactChange : function(component, event, helper) {
        var record = event.getParam("record");
        var salesInvoice = component.get("v.salesInvoice");
        if (record) {
            salesInvoice.Site_Contact_2__c = record.Id;
            salesInvoice.Site_Phone_No__c = record.Phone;
            salesInvoice.Site_Email_Address__c = record.Email;
        }
        else {
            salesInvoice.Site_Contact_2__c = null;
            salesInvoice.Site_Phone_No__c = null;
            salesInvoice.Site_Email_Address__c = null;
        }
        component.set("v.salesInvoice", salesInvoice)
    },
    handleTaxAreaChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesInvoice.Tax_Area__c", record.Id);
            var salesInvoice = component.get("v.salesInvoice");
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            helper.calculateSalesInvoice(component, event, salesInvoice, jobTaskWrappers, false);
        }
        else {
            component.set("v.salesInvoice.Tax_Area__c", null);
        }
    },
    handleTaxLiableChange : function(component, event, helper) {
        var salesInvoice = component.get("v.salesInvoice");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        helper.calculateSalesInvoice(component, event, salesInvoice, jobTaskWrappers, false);
    },
    validateFields : function(component, event, helper) {
        var fields = [];
        fields.push(component.find("tax-area"));
        var ok = fields.reduce(function(valid, inputField) {
            if (inputField) {
                inputField.showHelpMessageIfInvalid();
            }
            return valid && inputField.get("v.validity").valid;
        }, true);

        return ok;
    }
});