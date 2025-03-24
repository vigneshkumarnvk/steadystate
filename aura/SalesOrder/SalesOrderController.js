({
	doInit : function(component, event, helper) {
        helper.getSalesOrder(component, event);
	},
    //job task <<
    handlePageChange : function(component, event, helper) {
        //handle cache issue where doInit is not loaded every time the page is open
        helper.getSalesOrder(component, event);
    },
    //job task >>
    //job task << moved to SalesOrderBase, and the helper
    /*
    doSave : function(component, event, helper) {
        try {
            var errors = [];
            //calling child components' validateField method
            var allValid = component.find("step").reduce(function(valid, step) {
                if (step["validateFields"] != null) { //if the component support validateFields method
                    var validStep = step.validateFields();
                    if (!validStep) {
                        errors.push(step.getName());
                    }
                    return valid && validStep;
                }
                else {
                    return valid;
                }
            }, true);

            if (allValid) {
                //job task <<
                //helper.saveSalesOrder(component, event);
                //helper.calculateAndSaveSalesOrder(component, event);
                helper.save(component, event);
                //job task >>
            }
            else {
                var steps = component.find("step");
                for (var i = 0; i < steps.length; i++) {
                    if (errors[0] == steps[i].getName()) { //go to the first tab with validation error
                        component.find("tabset").set("v.selectedTabId", 'tab' + i);
                        break;
                    }
                }
                helper.showToast(component, 'Error', 'You must enter all required fields.', 'error', 'dismissible');
            }
        }
        catch(error) {
            alert(error);
        }
    },
    */
    //job task >>
    doCancel : function(component, event, helper) {
        var recordId = component.get("v.recordId");
        helper.navigateToSObject(component, event, recordId);
    },
    //ticket 19130 <<
    handleTabChange : function (component, event, helper) {
        var tabId = event.getParam("tabId");
        if (tabId == 'tab5') {
            if (helper.validateFields(component, event) != true) {
                component.set("v.selectedTabId", "tab0");
            }
        }
    }
    //ticket 19130 >>
})