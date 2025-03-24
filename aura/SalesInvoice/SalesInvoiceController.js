({
    doInit : function(component, event, helper) {
        helper.getSetupData(component, event);
        helper.getSalesInvoice(component, event);
    },
    handlePageChange : function(component, event, helper) {
        helper.getSalesInvoice(component, event);
    },
    doSave : function(component, event, helper) {
        var ok = true;
        var salesInvoice = component.get("v.salesInvoice");
        if (salesInvoice.Document_Type__c == 'Misc. Credit Memo') {
            ok = helper.validateFields(component)
        }
        
        if (ok) {
            helper.saveSalesInvoice(component, event);
        }
    },
    doCancel : function(component, event, helper) {
        var salesInvoiceId = component.get("v.salesInvoice.Id");
        helper.navigateToSObject(component, event, salesInvoiceId);
    }
});