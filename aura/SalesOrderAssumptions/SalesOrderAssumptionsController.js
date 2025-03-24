({
    calculateManifest : function(component, event, helper) {
        //job task <<
        //helper.calculateSalesOrder(component, event, false);
        helper.confirmCheckOffManifestFee(component, event);
        //job task >>
    },
    calculateRinseOutFee : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        helper.calculateSalesOrder(component, event, salesOrder, jobTaskWrappers, false);
    },
    handleAssumptionChange : function(component, event, helper) {
        var assumptionOptions = component.find("assumption-option");
        if (Array.isArray(assumptionOptions)) {
            for (var i = 0; i < assumptionOptions.length; i++) {
                if (assumptionOptions[i].get("v.value") != event.getSource().get("v.value")) {
                    assumptionOptions[i].set("v.checked", false);
                }
            }
        }
        //Ticket#24650 >>
        //job task <<
        //helper.reinitializeSalesLineDetails(component, event, false);
        //helper.recalculateSalesLineDetails(component, event, false);
        //job task >>
        helper.handleAssumptionChange(component,event,true);
        //Ticket#24650 <<
    },
    validateFields : function(component, event, helper) {
        var fields = new Array();

        var allValid = fields.reduce(function(valid, inputField) {
            if (inputField) {
            	inputField.showHelpMessageIfInvalid();
            }
            return valid && inputField.get("v.validity").valid;
        }, true);
        
        return allValid;
    }
})