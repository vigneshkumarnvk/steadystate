({
    doInit : function(component, event, helper) {
        helper.getTMLines(component, event);
        //ticket 19408 <<
        /*
        var tm = component.get("v.tm");
        component.set("v.jobLog", tm.Customer_Comments__c);
        */
        //ticket 19408 >>
    },
    handleTMChange : function(component, event, helper) {
        component.set("v.unsavedChanges", true);
    },
    doSave :function(component, event, helper) {
        /*
        var tm = component.get("v.tm");
        if (!tm.Customer_Comments__c || tm.Customer_Comments__c == '') {
            return;
        }*/

        //ticket 19408 <<
        /*
        if (helper.validate(component, event) == true) {
            helper.save(component, event, helper);
        }
        */
        helper.saveTMHeader(component, event);
        //ticket 19408 >>
    },
    doRefresh : function(component, event, helper) {
        helper.confirmRefresh(component, event);
    },
    handleJobComplete : function(component, event, helper) {
        var jobComplete = component.get("v.tm.Job_Complete__c");
        /*
        if (jobComplete == true) {
            helper.showTMWizard(component, event);
        }*/
    },
    showTermsDialog : function(component, event, helper) {
        helper.showTermsDialog(component, event);
    },
    //ticket 19408 <<
    beforeSupervisorSignatureSave : function(component, event, helper) {
        if (helper.validate(component, event) == true) {
            helper.save(component, event);
        }
    },
    //ticket 19408 >>
    afterSignatureSaved : function(component, event, helper) {
        var dualSignaturesRequired = component.get("v.tm.Bill_to_Customer__r.Requires_2_Signatures_on_TM__c");
        if (dualSignaturesRequired == true) {
            var customerASignatureWrapper = component.get("v.customerASignatureWrapper");
            var customerBSignatureWrapper = component.get("v.customerBSignatureWrapper");

            //signature request <<
            /*
            if (customerASignatureWrapper.Signed == true && customerBSignatureWrapper.Signed == true) {
                helper.processPDF(component, event);
            }
            */
            /*
            var signerRole = event.getParam("signerRole");
            if (customerASignatureWrapper.Signed == true && signerRole == 'Customer A') {
                helper.showSurvey(component, event, customerASignatureWrapper.PrintName, customerASignatureWrapper.Email);
            }

            if ((customerASignatureWrapper.Signed == true || customerASignatureWrapper.NotAvailable == true) && (customerBSignatureWrapper.Signed == true || customerBSignatureWrapper.NotAvailable == true)) {
                helper.processPDF(component, event);
            }*/
            var calls = [];

            if ((customerASignatureWrapper.Signed == true || customerASignatureWrapper.NotAvailable == true) && (customerBSignatureWrapper.Signed == true || customerBSignatureWrapper.NotAvailable == true)) {
                calls.push(helper.processPDF.bind(helper, component, event));
            }

            //Ticket#28274 Temporary Disable Customer Rating workflow
            /*
            var signerRole = event.getParam("signerRole");
            if (customerASignatureWrapper.Signed == true && signerRole == 'Customer A') {
                calls.push(helper.showSurvey.bind(helper, component, event, customerASignatureWrapper.PrintName, customerASignatureWrapper.Email));
            }
             */

            if ((customerASignatureWrapper.Signed == true || customerASignatureWrapper.NotAvailable == true) && (customerBSignatureWrapper.Signed == true || customerBSignatureWrapper.NotAvailable == true)) {
                calls.push(helper.redirectToDetailTab.bind(helper, component, event));
            }
            if (calls.length > 0) {
                helper.makeStackedCalls(component, event, helper, calls);
            }
            //signature request >>
        }
        else {

            //signature request <<
            /*
            helper.processPDF(component, event);
            */

            /*
            var customerASignatureWrapper = component.get("v.customerASignatureWrapper");
            if (customerASignatureWrapper.Signed == true && customerASignatureWrapper.NotAvailable != true) {
                helper.showSurvey(component, event, customerASignatureWrapper.PrintName, customerASignatureWrapper.Email);
            }

            if (customerASignatureWrapper.Signed == true || customerASignatureWrapper.NotAvailable == true) {
                helper.processPDF(component, event);
            }*/
            var customerASignatureWrapper = component.get("v.customerASignatureWrapper");

            var calls = [];
            if (customerASignatureWrapper.Signed == true || customerASignatureWrapper.NotAvailable == true) {
                calls.push(helper.processPDF.bind(helper, component, event));
            }

            //Ticket#28274 Temporary Disable Customer Rating workflow
            /*
            if (customerASignatureWrapper.Signed == true && customerASignatureWrapper.NotAvailable != true) {
                calls.push(helper.showSurvey.bind(helper, component, event, customerASignatureWrapper.PrintName, customerASignatureWrapper.Email));
            }
             */

            if (customerASignatureWrapper.Signed == true || customerASignatureWrapper.NotAvailable == true) {
                calls.push(helper.redirectToDetailTab.bind(helper, component, event));
            }
            if (calls.length > 0) {
                helper.makeStackedCalls(component, event, helper, calls);
            }
            //signature request >>
        }
    }
})