({
    /*
    showTMWizard : function(component, event) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var jobTaskTemplateId = component.get("v.tm.Sales_Order__r.Sales_Order_Type__r.Job_Task_Template__c");
        if (jobTaskTemplateId != null) {
            var tm = component.get("v.tm");
            var nextTMLineNo = 0;
            jobTaskWrappers.forEach(function(jobTaskWrapper) {
                jobTaskWrapper.TMLines.forEach(function (tmLine) {
                    if (nextTMLineNo < tmLine.Line_No__c) {
                        nextTMLineNo = tmLine.Line_No__c;
                    }
                });
            });
            nextTMLineNo++;

            var params = {
                "tm": tm,
                "jobTaskWrappers": jobTaskWrappers,
                "nextTMLineNo": nextTMLineNo,
                "jobTaskTemplateId": jobTaskTemplateId,
                "completeCallback": this.completeCallback.bind(this, component, event),
                "cancelCallback": this.cancelCallback.bind(this, component, event)
            }
            this.openModal(component, event, "T&M Wizard", null, null, "c:TMWizard", params, null, null, null);
        }
        else {
            this.completeCallback(component, event, jobTaskWrappers);
        }
    },
    completeCallback : function(component, event, jobTaskWrappers) {
        this.closeModal(component, event);
        component.set("v.jobTaskWrappers", jobTaskWrappers);
        this.groupTMLines(component, jobTaskWrappers);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },*/
    getTMLines : function(component, event) {
        var tm = component.get("v.tm");

        //signature request <<
        var supervisorSignatureWrapper = { "TMId": tm.Id, "Name": 'supervisor_signature', "NotAvailable": false, "SignerRole": 'Supervisor' };
        var customerASignatureWrapper = { "TMId": tm.Id, "Name": 'customer_signature', "NotAvailable": false, "Email": tm.Site_Email_Address__c, "SignerRole": 'Customer A' };
        var customerBSignatureWrapper = { "TMId": tm.Id, "Name": 'customer_signature_2', "NotAvailable": false, "SignerRole": 'Customer B' };
        //signature request >>
        component.set("v.supervisorSignatureWrapper", supervisorSignatureWrapper);
        component.set("v.customerASignatureWrapper", customerASignatureWrapper);
        component.set("v.customerBSignatureWrapper", customerBSignatureWrapper);

        var params = { "tmId": tm.Id };
        this.callServerMethod(component, event, "c.getTMLines", params, function(response){
            var jobTaskWrappers = JSON.parse(response);
            component.set("v.jobTaskWrappers", jobTaskWrappers);
            this.groupTMLines(component, jobTaskWrappers);
            component.set("v.siteEmailAddress", tm.Site_Email_Address__c);
        });
    },
    validate : function(component, event, helper) {
        var ok = true;
        var tm = component.get("v.tm");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var errors = [];

        //ticket 19408 <<
        /*
        var jobLog = component.get("v.jobLog");
        if (!jobLog|| jobLog == '') {
            addError('Job log must not be blank');
        }
        */
        if (!tm.Customer_Comments__c || tm.Customer_Comments__c == '') {
            addError('Job log must not be blank');
        }
        //ticket 19408 <<

        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTaskWrapper = jobTaskWrappers[i];
            for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                var tmLine = jobTaskWrapper.TMLines[j];
                switch(tmLine.Category__c) {
                    case 'Labor':
                        if (tmLine.Resource_Type__c || tmLine.Resource__c) {
                            if (tmLine.Resource__c && !tmLine.Resource_Type__c) {
                                addError('Labor title must not be blank');
                            }
                            if (!tmLine.Job_Start_Time__c || !tmLine.Job_End_Time__c || !tmLine.Site_Start_Time__c || !tmLine.Site_End_Time__c) {
                                addError('Labor job times and site times must not be blank');
                            }
                        }
                        break;
                    case 'Equipment':
                        if (tmLine.Resource_Type__c || tmLine.Resource__c) {
                            if (tmLine.Resource__c && !tmLine.Resource_Type__c) {
                                addError('Equipment type must not be blank');
                            }
                            if (tmLine.Resource_Type__r && tmLine.Resource_Type__r.Fleet_No_Required__c == true && (!tmLine.Job_Start_Time__c || !tmLine.Job_End_Time__c)) {
                                addError('Equipment job times must not be blank');
                            }
                            if (!tmLine.Quantity__c) {
                                addError('Equipment quantity must not be blank');
                            }
                            if (!tmLine.Unit_of_Measure__c) {
                                addError('Equipment unit of measure must not blank');
                            }
                        }
                        break;
                    case 'Materials':
                        if (tmLine.Resource__c) {
                            if (!tmLine.Quantity__c) {
                                addError('Material quantity must not be blank');
                            }
                            if (!tmLine.Unit_of_Measure__c) {
                                addError('Material unit of measure must not blank');
                            }
                        }
                        break;
                    case 'Subcontractors':
                        if (tmLine.Description__c) {
                            if (!tmLine.Quantity__c) {
                                addError('Cost Plus quantity must not be blank');
                            }
                            if (!tmLine.Unit_of_Measure__c) {
                                addError('Cost Plus unit of measure must not blank');
                            }
                        }
                        break;
                    case 'Waste Disposal':
                        if (tmLine.Resource__c) {
                            if (!tmLine.Quantity__c) {
                                addError('Waste Disposal quantity must not be blank');
                            }
                            if (!tmLine.Unit_of_Measure__c) {
                                addError('Waste Disposal unit of measure must not blank');
                            }
                        }
                        break;
                }
            }
        }
        //ticket 19408 <<
        /*
        if (errors.length > 5) {
            errors.splice(5, errors.length - 5);
        }
        for (var i = 0; i < errors.length; i++) {
            this.showToast(component, "", errors[i], "error", "sticky");
        }
        */
        if (errors.length > 0) {
            this.showToast(component, "Validation Error", "Please see errors above the signature box.", "error", "dismissible");
        }
        component.set("v.errors", errors);
        //ticket 19408 >>

        return (errors.length == 0);

        function addError(message) {
            if (!errors.includes(message)) {
                errors.push(message);
            }
        }
    },
    save : function(component, event) {
        var tm = component.get("v.tm");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var helper = this;
        var calls = [];
        calls.push(helper.getJobTaskWrappers.bind(helper, component, event, tm.Id, jobTaskWrappers));
        calls.push(helper.promptWizard.bind(helper, component, event, jobTaskWrappers));
        calls.push(helper.saveTM.bind(helper, component, event, tm, jobTaskWrappers));
        //ticket 19408 <<
        calls.push(helper.saveSupervisorSignature.bind(helper, component, event));
        //ticket 19408 >>
        this.makeStackedCalls(component, event, helper, calls);
    },
    getJobTaskWrappers : function(component, event, tmId, jobTaskWrappers, resolve, reject) {
        var params = { "tmId": tmId }
        this.callServerMethod(component, event, "c.getJobTaskWrappers", params, function(response) {
            Object.assign(jobTaskWrappers, JSON.parse(response));
            resolve();
        }, function(error) {
            reject();
        });
    },
    saveTM : function(component, event, tm, jobTaskWrappers, resolve, reject) {
        var jobLog = component.get("v.jobLog");
        var tm2 = JSON.parse(JSON.stringify(tm));
        //ticket 19408 <<
        //tm2.Customer_Comments__c = jobLog;
        //ticket 19408 >>
        var params = { "JSONTM": JSON.stringify(tm2), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.SaveTMAndLines", params, function (response) {
            //ticket 19408 <<
            //component.set("v.tm.Customer_Comments__c", jobLog);
            //ticket 19408 >>
            component.set("v.unsavedChanges", false);            
            this.groupTMLines(component, jobTaskWrappers);
            //ticket 19408 <<
            //this.showToast(component, "", "T&M is saved", "success", "dismissible");
            //ticket 19408 >>
            resolve();
        }, function(error) {
            this.showToast(component, "Error", error, "error", "dismissible");
            reject();
        });
    },
    //ticket 19408 <<
    saveTMHeader : function(component, event) {
        var tm = component.get("v.tm");
        var params = { "JSONTM": JSON.stringify(tm) };
        this.callServerMethod(component, event, "c.SaveTMHeader", params, function(response) {
            component.set("v.unsavedChanges", false);
            this.showToast(component, "", "Successful", "success", "dismissible");
        })
    },
    saveSupervisorSignature : function(component, event, resolve, reject) {
        try {
            var supervisorSignatureBox = component.find("supervisor-signature-box");
            supervisorSignatureBox.set("v.fireBeforeSaveEvent", false);
            supervisorSignatureBox.save(true);
            if (resolve) {
                resolve();
            }
        }
        catch(err) {
            if (reject) {
                reject(err);
            }
            else {
                alert(err);
            }
        }
    },
    //ticket 19408 >>
    showTermsDialog : function(component, event) {
        var salesOrderId = component.get("v.tm.Sales_Order__c");
        var buttons = [];
        buttons.push({ "label": 'Close', "variant": 'brand', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        var params = { "salesOrderId": salesOrderId };
        this.openModal(component, event, 'Terms and Conditions', null, buttons, "c:MobileTMTerms", params, "large");
    },
    processPDF : function(component, event, resolve, reject) {
        var tm = component.get("v.tm");
        if (tm.Field_TM_PDF_Sent__c != true || tm.Field_TM_PDF_Saved__c != true) {
            this.showToast(component, '', 'Processing T&M Field PDF. Please wait.', 'info', 'dismissible');
            var params = { "tmId": tm.Id};
            this.callServerMethod(component, event, "c.processPDF", params, function(response) {
                this.showToast(component, '', 'T&M Field PDF process is complete!', 'success', 'dismissible');
                if (resolve) {
                    resolve();
                }
            }, function (err) {
                this.showToast(component, '', err, 'error', 'dismissible');
                if (reject) {
                    reject();
                }
            });
        }
    },
    groupTMLines : function(component, jobTaskWrappers) {
        var groupedJobTaskWrappers = [];

        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTaskWrapper = jobTaskWrappers[i];
            var groupedJobTaskWrapper = {};
            groupedJobTaskWrapper.JobTask = jobTaskWrapper.JobTask;

            var laborLines = [];
            var equipmentLines = [];
            var materialLines = [];
            var subcontractorLines = [];
            var wasteDisposalLines = [];
            var totalLaborHours = 0;
            var totalEquipmentHours = 0;

            for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                var tmLine = JSON.parse(JSON.stringify(jobTaskWrapper.TMLines[j]));
                switch(tmLine.Category__c) {
                    case 'Labor':
                        tmLine.TotalHours = this.calculateHours(tmLine.Job_Start_Time__c, tmLine.Job_End_Time__c);
                        laborLines.push(tmLine);
                        if (tmLine.TotalHours != null) {
                            totalLaborHours += tmLine.TotalHours;
                        }
                        break;
                    case 'Equipment':
                        equipmentLines.push(tmLine);
                        if (tmLine.Total_Job_Hours__c != null) {
                            totalEquipmentHours += tmLine.Total_Job_Hours__c;
                        }
                        break;
                    case 'Materials':
                        materialLines.push(tmLine);
                        break;
                    case 'Subcontractors':
                        subcontractorLines.push(tmLine);
                        break;
                    case 'Waste Disposal':
                        wasteDisposalLines.push(tmLine);
                        break;
                }
            }

            groupedJobTaskWrapper.LaborLines = laborLines;
            groupedJobTaskWrapper.TotalLaborHours = totalLaborHours;
            groupedJobTaskWrapper.EquipmentLines = equipmentLines;
            groupedJobTaskWrapper.TotalEquipmentHours = totalEquipmentHours;
            groupedJobTaskWrapper.MaterialLines = materialLines;
            groupedJobTaskWrapper.SubcontractorLines = subcontractorLines;
            groupedJobTaskWrapper.WasteDisposalLines = wasteDisposalLines;

            groupedJobTaskWrappers.push(groupedJobTaskWrapper);
        }

        component.set("v.groupedJobTaskWrappers", groupedJobTaskWrappers);
    },
    showSurvey : function(component, event, customerName, email, resolve) {
        var tm = component.get("v.tm");
        var params = { "tmId": tm.Id, "customerName": customerName, "customerEmail": email };
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.showSurveyCancelCallback.bind(this, component, event, resolve) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "saveServiceRating", "callback": this.showSurveyCallback.bind(this, component, event, resolve) }});
        this.openModal(component, event, 'Customer Feedback', null, buttons, 'c:TMServiceRating', params, "large");
    },
    showSurveyCallback : function(component, event, resolve) {
        this.closeModal(component, event);
        this.showToast(component, '', 'Thank you for your feedback.', 'success', 'dismissible');
        if (resolve) {
            resolve();
        }
    },
    showSurveyCancelCallback : function(component, event, resolve) {
        this.closeModal(component, event);
        if (resolve) {
            resolve();
        }
    },
    redirectToDetailTab : function(component, event, resolve) {
        var tmId = component.get("v.tm.Id");
        this.fireTMNavigationEvent(component, event,  tmId,"details", true);
        if (resolve) {
            resolve();
        }
    }
})