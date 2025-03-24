({
    validateAppliesToDoc : function(component, event, salesInvoice) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        if (salesInvoice.Reversed_from_SI__c != null) {
            var params = {"JSONSalesInvoice": JSON.stringify(salesInvoice), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
            this.callServerMethod(component, event, "c.validateAppliesToDoc", params, function(response) {
                var jobTaskWrappers = JSON.parse(response);
                component.set("v.jobTaskWrappers", jobTaskWrappers);
            });
        }
    },
    validatePaymentTerm : function (component, event, salesInvoice){
        if(salesInvoice.Payment_Term__c != null){
            var params = {"JSONSalesInvoice": JSON.stringify(salesInvoice)};
            this.callServerMethod(component, event, "c.validatePaymentTerm", params, function(response) {
                salesInvoice = JSON.parse(response);
                component.set("v.salesInvoice", salesInvoice);
            });
        }
    }
});