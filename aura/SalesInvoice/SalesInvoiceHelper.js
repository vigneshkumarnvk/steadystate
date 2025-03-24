({
    getSetupData : function(component, event) {
        this.callServerMethod(component, event, "c.getSetupData", null, function(response) {
            var setupData = JSON.parse(response);
            component.set("v.setupData", setupData);
        });
    },
    getSalesInvoice : function(component, event) {
        var recordId = component.get("v.recordId");
        var params = { "salesInvoiceId": recordId };
        this.callServerMethod(component, event, "c.getSalesInvoice", params, function(response) {
            var salesInvoiceWrapper = JSON.parse(response);
            var salesInvoice = salesInvoiceWrapper.SalesInvoice;
            var jobTaskWrappers = salesInvoiceWrapper.JobTaskWrappers;

            component.set("v.salesInvoice", salesInvoice);

            var nextJobTaskLineNo = 0;
            var nextInvoiceLineNo = 0;
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                if (jobTaskWrapper.JobTask.Line_No__c > nextJobTaskLineNo) {
                    nextJobTaskLineNo = jobTaskWrapper.JobTask.Line_No__c;
                }
                for (var j = 0; j < jobTaskWrapper.SalesInvoiceLines.length; j++) {
                    if (jobTaskWrapper.SalesInvoiceLines[j].Line_No__c > nextInvoiceLineNo) {
                        nextInvoiceLineNo = jobTaskWrapper.SalesInvoiceLines[j].Line_No__c;
                    }
                }
                this.sortInvoiceLines(jobTaskWrapper.SalesInvoiceLines);
            }
            component.set("v.jobTaskWrappers", jobTaskWrappers);
            component.set("v.nextJobTaskLineNo", nextJobTaskLineNo + 1);
            component.set("v.nextInvoiceLineNo", nextInvoiceLineNo + 1);
        });
    },
    saveSalesInvoice : function(component, event) {
        var salesInvoice = component.get("v.salesInvoice");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");

        var params = { "JSONSalesInvoice": JSON.stringify(salesInvoice), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.saveSalesInvoice", params, function(response) {
            this.navigateToSObject(component, event, salesInvoice.Id);
        }, function(error) {
            this.showToast(component, "Error", error, "error", "dismissible");
        });
    },
    /*
    confirmPostSalesInvoice : function(component, event) {
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'OK', "variant": 'brand', "action": { "callback": this.confirmPostSalesInvoiceCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Document Posting', 'Are you sure you want to post this sales invoice?', buttons, null, null, null);
    },
    confirmPostSalesInvoiceCallback : function(component, event) {
        this.closeModal(component, event);
    },*/
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    validateFields : function(component) {
        try {
            var errors = [];
            //calling child components' validateField method
            var cmps = component.find("step");
            cmps.push(component.find("invoice-lines"));
            var ok = cmps.reduce(function(valid, step) {
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

            if (ok) {
                return true;
            }
            else {
                for (var i = 0; i < cmps.length; i++) {
                    if (errors[0] == cmps[i].getName()) { //go to the first tab with validation error

                        component.find("tabset").set("v.selectedTabId", 'tab' + i);
                        break;
                    }
                }

                this.showToast(component, 'Error', 'You must enter all required fields.', 'error', 'dismissible');
                return false;
            }
        }
        catch(error) {
            alert(error);
        }
    }
});