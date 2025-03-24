({
	doInit : function(component, event, helper) {
        helper.getData(component, event);

        //disable the escape key closing the page
        window.addEventListener("keydown", function(event) {
            var keycode = event.code;
            if(keycode == 'Escape'){
                event.preventDefault();
                event.stopImmediatePropagation();
            }
        }, true);
	},
    /*
    handleStepChange : function(component, event, helper) {
        var step = component.get("v.currentStep");
        if (step == 7) { //sales lines tab
            var salesOrder = component.get("v.salesOrder");
            //validate other tabs before going to the sales lines tab
            if (helper.validateFields(component, event)) {
                component.set("v.currentStep", step);
                helper.showStep(component, event);
            }
        }
        else {
			helper.showStep(component, event);
        }
    },*/
    handleStepNameChange : function(component, event, helper) {
	    var stepName = component.get("v.stepName");
        //Ticket#27427
        var ok = helper.validateServiceCenter(component, event);
        if(ok == false){
            if(stepName != 'document-type') {
                component.set('v.stepName', 'order-information');
            }
        }
        if (stepName == 'sales-lines') { //sales lines tab
            if (helper.validateFields(component, event, true)) {
                helper.showStep(component, event);
            }
        }
        else {
            helper.showStep(component, event);
        }
    },
    moveToNextStep : function(component, event, helper) {
        console.log('moveToNEXTStep called');
        /*
        var currentStep = component.get("v.currentStep");
        var steps = component.get("v.tabs");
        if (currentStep < steps.length) {
            currentStep++;
            component.set("v.currentStep", currentStep);
        }*/
        var stepName = component.get("v.stepName");
        var tabs = component.get("v.tabs");
        for (var i = 0; i < tabs.length; i++) {
            if (tabs[i] == stepName) {
                if (i < tabs.length -  1) {
                    stepName = tabs[i + 1];
                    component.set("v.stepName", stepName);
                    break;
                }
            }
        }
        helper.showStep(component, event);
    },
    moveToStep : function(component, event, helper) {
        console.log('moveToStep called');
        var stepName = event.getSource().get("v.value");
        //component.set("v.currentStep", step);
        component.set("v.stepName", stepName);
    },
    //job task <<
    /*
    createDocument : function(component, event, helper) {
        try {

            if (helper.validateFields(component, event)) {
                helper.saveSalesOrder(component, event);
            }
        }
        catch(error) {
            alert(error);
        }
    },*/
    cancelCreation : function (component, event, helper) {
        //$A.get("e.force:closeQuickAction").fire();
        helper.confirmCancelCreation(component, event);
    },
    handleCreateSalesOrderMessage : function (component, event, helper) {
        helper.handleCreateSalesOrderMessage(component, event);
    }
})