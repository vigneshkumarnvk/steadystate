({
    getTM : function(component, event) {
        this.callServerMethod(component, event, "c.getVariables", null, function(response) {
            component.set("v.variables", JSON.parse(response));
        });

        var recordId = component.get("v.recordId");
        var params = { "tmId": recordId };
        this.callServerMethod(component, event, "c.getTM", params, function(response) {
            var tmWrapper = JSON.parse(response);
            var tm = tmWrapper.TM;
            var jobTaskWrappers = tmWrapper.JobTaskWrappers;
            component.set("v.tm", tm);
            component.set("v.jobTaskWrappers", jobTaskWrappers);

            if (tm.Status__c != 'Open') {
                component.set("v.selectedTabId", "tab3");
            }

            this.calculateNextTMLineNo(component);
        });
    },
    saveAsStatus : function(component, event, helper, status, redirect) {
        var tm = component.get("v.tm");
        //ticket 19130 05.13.2023 << - make a copy of jobTaskWrappers so any changes made during the call like removing child lines with qty 0 won't update the screen when error occurs
        //var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var jobTaskWrappers = JSON.parse(JSON.stringify(component.get("v.jobTaskWrappers")));
        //ticket 19130 05.13.2023 >>

        var helper = this;
        var prompt = false;
        var wizardCompleted = component.get("v.wizardCompleted");
        //if (status == 'Confirmed' && status != tm.Status__c && wizardCompleted != true) {
        if (status == 'Confirmed' && wizardCompleted != true) {
            /*
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                    var tmLine = jobTaskWrapper.TMLines[j];
                    if (tmLine.Wizard_Question_Answered__c != true) {
                        if (tmLine.Parent_Line__r && tmLine.Parent_Line__r.Line_No__c && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                            prompt = true;
                            break;
                        }
                    }
                }
                if (prompt == true) {
                    break;
                }
            }*/
            prompt = true;
        }

        var calls = [];
        calls.push(helper.closeInlineEdit.bind(helper, component, event)); //close inline edit rows in all tasks
        calls.push(helper.validateFields.bind(helper, component, status));
        if (prompt == true) {
            calls.push(helper.promptWizard.bind(helper, component, event, jobTaskWrappers));
        }

        calls.push(helper.calculateTMJobTasks.bind(helper, component, event, tm, jobTaskWrappers));
        calls.push(helper.validateFields.bind(helper, component, status)); //validate fields again after calculate. Calculate could result inserting system lines with quantity 0
        calls.push(helper.saveTM.bind(helper, component, event, tm, jobTaskWrappers, status, redirect));
        this.makeStackedCalls(component, event, helper, calls);
    },
    validateFields : function(component, validateAsStatus, resolve, reject) {
        var ok = true;
        if (validateAsStatus == 'Scheduled' || validateAsStatus == 'Mobile Review' || validateAsStatus == 'Confirmed') {
            var errors = [];
            ok = component.find("step").reduce(function (valid, step) {
                if (step["validateFields"] != null) { //if the component support validateFields method
                    var validStep = step.validateFields(validateAsStatus);
                    if (!validStep) {
                        errors.push(step.getName());
                    }
                    return valid && validStep;
                } else {
                    return valid;
                }
            }, true);
        }

        if (ok) {
            var tmlines = component.find("tm-lines");
            //tmlines.combineTMLines();
            ok = tmlines.validate(validateAsStatus);
        }
        else {
            var steps = component.find("step");
            for (var i = 0; i < steps.length; i++) {
                if (errors[0] == steps[i].getName()) { //go to the first tab with validation error
                    component.find("tabset").set("v.selectedTabId", 'tab' + i);
                    break;
                }
            }
            this.showToast(component, "Error", "Please complete all required fields.", "error", "dismissible");
        }

        //return allValid;
        if (ok) {
            if (resolve) {
                resolve();
            }
        }
        else {
            if (reject) {
                reject('You must resolve all validation errors to continue.');
            }
        }
    },
    saveTM : function(component, event, tm, jobTaskWrappers, newTMStatus, redirect) {
        //remove child lines with qty 0 and don't have a parent line
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var linesDeleted = 0;
            var jobTaskWrapper= jobTaskWrappers[i];

            //remove child lines with zero qty and don't have a parent
            for (var j = jobTaskWrapper.TMLines.length - 1; j >= 0; j--) {
                var tmLine = jobTaskWrapper.TMLines[j];

                //ticket 19130 <<
                /*
                if (!tmLine.Parent_Line__r && tmLine.Is_Child_Resource__c == true && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                    jobTaskWrapper.TMLines.splice(j, 1);
                    linesDeleted++;
                }
                */
                if (newTMStatus == 'Confirmed' && tmLine.Is_Child_Resource__c == true && (!tmLine.Quantity__c || tmLine.Quantity__c == 0)) {
                    //remove relationship
                    for (var k = 0; k < jobTaskWrapper.TMLines.length; k++) {
                        var tmLine2 = jobTaskWrapper.TMLines[k];
                        if (tmLine2.TM_Child_Lines__r && tmLine2.TM_Child_Lines__r.records) {
                            for (var l = 0; l < tmLine2.TM_Child_Lines__r.records.length; l++) {
                                var relation = tmLine2.TM_Child_Lines__r.records[l];
                                if (relation.Child_Line__r && parseInt(relation.Child_Line__r.Line_No__c) == parseInt(tmLine.Line_No__c)) {
                                    tmLine2.TM_Child_Lines__r.records.splice(l, 1);
                                    l--;
                                }
                            }
                            tmLine2.TM_Child_Lines__r.totalSize = tmLine2.TM_Child_Lines__r.records.length;
                            tmLine2.TM_Child_Lines__r.done = "true";
                        }
                    }
                    jobTaskWrapper.TMLines.splice(j, 1);
                    j--;
                }
                else {
                    if (tmLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r.records) {
                        tmLine.TM_Child_Lines__r.totalSize = tmLine.TM_Child_Lines__r.records.length;
                    }
                    jobTaskWrapper.TMLines[j] = tmLine;
                }
                //ticket 19130 >>
            }
        }

        var clonedTM = JSON.parse(JSON.stringify(tm)); //make a copy of the TM and assign the new status, if error occurs on the server side, TM status remains the same on the client side
        clonedTM.Status__c = newTMStatus;
        var params = { "JSONTM": JSON.stringify(clonedTM), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };

        this.callServerMethod(component, event, "c.saveTM", params, function(response) {
            var recordId = component.get("v.recordId");
            if (redirect == true) {
                this.navigateToSObject(component, event, recordId);
            }
            else {
                var tmWrapper = JSON.parse(response);
                var tm = tmWrapper.TM;
                var jobTaskWrappers = tmWrapper.JobTaskWrappers;
                component.set("v.tm", tm);
                component.set("v.jobTaskWrappers", jobTaskWrappers);
                this.calculateNextTMLineNo(component);
                this.showToast(component, "", "Your changes are saved.", "success", "dismissible");
            }
        })
    },
    refreshLines : function(component, event) {
        var tmlines = component.find("tm-lines");
        tmlines.refreshLines();
    },
    closeInlineEdit : function(component, event, resolve) {
        var tmlines = component.find("tm-lines");
        tmlines.closeInlineEdit();
        if (resolve) {
            resolve();
        }
    }
})