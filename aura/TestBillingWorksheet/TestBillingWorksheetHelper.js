({
    getSetupData: function (component, event) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = {"salesOrderId": salesOrderId};
        this.callServerMethod(component, event, "c.getSetupData", params, function (response) {
            var setupData = JSON.parse(response);

            //convert apex map to javascript map
            /*
            var TMTasksByTMIdByOrderTaskLineNo = setupData.TMTasksByTMIdByOrderTaskLineNo;
            var mapTMTasksByTMIdByOrderTaskLineNo = new Map();
            Object.keys(TMTasksByTMIdByOrderTaskLineNo).forEach(function(salesOrderJobTaskLineNo) {
                var mapTMTasksByTMId = new Map();
                mapTMTasksByTMIdByOrderTaskLineNo.set(salesOrderJobTaskLineNo, mapTMTasksByTMId);

                var TMTasksByTMId = TMTasksByTMIdByOrderTaskLineNo[salesOrderJobTaskLineNo];
                Object.keys(TMTasksByTMId).forEach(function(tmId) {
                    mapTMTasksByTMId.set(tmId, TMTasksByTMId[tmId]);
                });
            });
            setupData.TMTasksByTMIdByOrderTaskLineNo = mapTMTasksByTMIdByOrderTaskLineNo;
            */
            var TMTasksByOrderTaskLineNoByTMId = setupData.TMTasksByOrderTaskLineNoByTMId;
            var mapTMTasksByOrderTaskLineNoByTMId = new Map();
            Object.keys(TMTasksByOrderTaskLineNoByTMId).forEach(function (tmId) {
                var mapTMTasksByOrderTaskLineNo = new Map();
                mapTMTasksByOrderTaskLineNoByTMId.set(tmId, mapTMTasksByOrderTaskLineNo);

                var TMTasksByOrderTaskLineNo = TMTasksByOrderTaskLineNoByTMId[tmId];
                Object.keys(TMTasksByOrderTaskLineNo).forEach(function (orderTaskLineNo) {
                    mapTMTasksByOrderTaskLineNo.set(parseInt(orderTaskLineNo), TMTasksByOrderTaskLineNo[orderTaskLineNo]);
                });
            });
            setupData.TMTasksByOrderTaskLineNoByTMId = mapTMTasksByOrderTaskLineNoByTMId;
            component.set("v.setupData", setupData);
        });
    },
    getSalesOrder: function (component, event) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = {"salesOrderId": salesOrderId};
        this.callServerMethod(component, event, "c.getSalesOrder", params, function (response) {
            var salesOrder = JSON.parse(response);
            component.set("v.salesOrder", salesOrder);
        });
    },
    getWorksheets: function (component, event) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = {"salesOrderId": salesOrderId};
        this.callServerMethod(component, event, "c.getUnbilledTasks", params, function (response) {
            var worksheets = JSON.parse(response);
            component.set("v.worksheets", worksheets);
            component.set("v.setUnsavedChanges", false);
        });

        this.callServerMethod(component, event, "c.getNextWorksheetLineNo", params, function (response) {
            component.set("v.nextWorksheetLineNo", response);
        }, null, true);
    },
    getWorksheet: function (component, event, rowIndex) {
        var worksheets = component.get("v.worksheets");
        var worksheet = worksheets[rowIndex];
        var salesOrderId = component.get("v.salesOrderId");
        var salesOrderJobTaskId = worksheet.SalesOrderJobTask.Id;

        var params = {"salesOrderId": salesOrderId, "salesOrderJobTaskId": salesOrderJobTaskId};
        this.callServerMethod(component, event, "c.getWorksheet", params, function (response) {
            var activeWorksheet = JSON.parse(response);
            var activeWorksheets = component.get("v.activeWorksheets");
            this.sortLines(activeWorksheet.WorksheetLines);
            activeWorksheets.push(activeWorksheet);
            component.set("v.activeWorksheets", activeWorksheets);
            /*
            var activeWorksheets2 = [];
            for (var i = 0; i < activeWorksheets.length; i++) {
                activeWorksheets2.push(activeWorksheets[i]);
            }
            activeWorksheets2.push(activeWorksheet);
            Object.assign(activeWorksheets, activeWorksheets2);*/
            var worksheetIndex = activeWorksheets.length - 1;
            component.set("v.selectedTabId", 'tab' + worksheetIndex); //activate the tab
        });
    },
    validateWorksheets: function (component, event, invoice, resolve, reject) {
        var worksheetTabs = this.getWorksheetTabs(component);
        var valid = worksheetTabs.reduce(function (valid, worksheetTab) {
            valid = valid && worksheetTab.validateLines(invoice);
            return valid;
        }, true);

        if (valid) {
            if (resolve) {
                resolve();
            }
            else {
                return valid;
            }
        }
        else {
            if (reject) {
                reject();
            }
            else {
                return valid;
            }
        }
    },
    confirmCancel: function (component, event) {
        var unsavedChanges = component.get("v.unsavedChanges");
        if (unsavedChanges == true) {
            var buttons = [];
            buttons.push({
                "label": 'No',
                "variant": 'neutral',
                "action": {"callback": this.cancelCallback.bind(this, component, event)}
            });
            buttons.push({
                "label": 'Yes',
                "variant": 'brand',
                "action": {"callback": this.confirmCancelCallback.bind(this, component, event)}
            });

            this.openModal(component, event, 'Unsaved Changes', 'You have unsaved changes. Are you sure you want to exit?', buttons, null, null, null);
        } else {
            this.confirmCancelCallback(component, event);
        }
    },
    confirmCancelCallback: function (component, event) {
        this.closeModal(component, event);
        var salesOrderId = component.get("v.salesOrderId");
        this.navigateToSObject(component, event, salesOrderId);
    },
    save: function(component, event, activeWorksheets, redirect) {
        var calls = [];
        var helper = this;
        var activeWorksheets = component.get("v.activeWorksheets");
        calls.push(this.promptWizard.bind(helper, component, event, activeWorksheets));
        calls.push(this.validateWorksheets.bind(helper, component, event, false));
        calls.push(this.saveWorksheets.bind(helper, component, event, activeWorksheets, redirect));
        this.makeStackedCalls(component, event, helper, calls);
    },
    confirmCreateInvoice: function (component, event, activeWorksheets) {
        //var activeWorksheets = component.get("v.activeWorksheets");
        var amount = 0;
        var bundleLineNos = [];
        var lineCount = 0;
        for (var i = 0; i < activeWorksheets.length; i++) {
            var activeWorksheet = activeWorksheets[i];
            if (activeWorksheet.SalesOrderJobTask.Billing_Type__c == 'Fixed Price') {
                amount += (activeWorksheet.SalesOrderJobTask.Amount_To_Bill__c);
            }

            for (var j = 0; j < activeWorksheet.WorksheetLines.length; j++) {
                var worksheetLine = activeWorksheet.WorksheetLines[j];
                if (worksheetLine.To_Invoice__c == true) {
                    if (worksheetLine.Category__c == 'Bundled') {
                        bundleLineNos.push(worksheetLine.Line_No__c);
                    }

                    if (activeWorksheet.SalesOrderJobTask.Billing_Type__c != 'Fixed Price') {
                        amount += (worksheetLine.Line_Amount__c ? worksheetLine.Line_Amount__c : 0);
                    }

                    lineCount++;
                }
            }
        }
        if (lineCount == 0) {
            this.showToast(component, "Error", "You have not select lines to invoice.", "error", "dismissible");
            return;
        }
        /*
        if (amount == 0) {
            this.showToast(component, "Error", "There is nothing to invoice. The invoice amount is 0.", "error", "dismissible");
            return;
        }*/

        if (bundleLineNos.length > 0) {
            for (var i = 0; i < bundleLineNos.length; i++) {
                for (var j = 0; j < activeWorksheets.length; j++) {
                    var bundleLinesSelected = true;
                    var activeWorksheet = activeWorksheets[j];
                    for (var k = 0; k < activeWorksheet.WorksheetLines.length; k++) {
                        var worksheetLine = activeWorksheet.WorksheetLines[k];
                        if (worksheetLine.Bundle_Line__r && worksheetLine.Bundle_Line__r.Line_No__c == bundleLineNos[i] && worksheetLine.To_Invoice__c != true) {
                            bundleLinesSelected = false;
                            break;
                        }
                    }
                    if (bundleLinesSelected == true) {
                        bundleLineNos.splice(i, 1);
                        i--;
                        break;
                    }
                }
                ;
            }
        }
        if (bundleLineNos.length > 0) {
            this.showToast(component, "Error", "You must select all bundled resource lines after line numbers " + bundleLineNos.join(', ') + ".", "error", "dismissible");
            return;
        }

        var buttons = [];
        buttons.push({
            "label": 'Cancel',
            "variant": 'neutral',
            "action": {"callback": this.cancelCallback.bind(this, component, event)}
        });
        buttons.push({
            "label": 'Create',
            "variant": 'brand',
            "action": {"callback": this.confirmCreateInvoiceCallback.bind(this, component, event, activeWorksheets)}
        });
        this.openModal(component, event, 'Create Invoice', 'You are about to create an invoice of amount $' + amount.toFixed(2) + '. Do you want to continue?',
            buttons, null, null, null, null, null, "300px");
    },
    confirmCreateInvoiceCallback: function (component, event, activeWorksheets) {
        this.closeModal(component, event);

        var calls = [];
        var helper = this;
        //var activeWorksheets = component.get("v.activeWorksheets");
        calls.push(this.saveWorksheets.bind(helper, component, event, activeWorksheets, false));
        calls.push(this.createSalesInvoice.bind(helper, component, event, activeWorksheets));
        this.makeStackedCalls(component, event, helper, calls);
    },
    createSalesInvoice: function (component, event, activeWorksheets2, resolve) {
        var salesOrderId = component.get("v.salesOrderId");
        var activeWorksheets = component.get("v.activeWorksheets");

        for (var i = 0; i < activeWorksheets2.length; i ++) {
            var activeWorksheet2 = activeWorksheets2[i];
            for (var j = 0; j < activeWorksheet2.WorksheetLines.length; j++) {
                activeWorksheets[i].WorksheetLines[j].To_Invoice__c = activeWorksheet2.WorksheetLines[j].To_Invoice__c;
            }
        }

        var params = {"salesOrderId": salesOrderId, "JSONWorksheets": JSON.stringify(activeWorksheets)};
        this.callServerMethod(component, event, "c.createSalesInvoice", params, function (response) {
            var salesInvoiceId = response;
            this.navigateToSObject(component, event, salesInvoiceId);
        });
    },
    promptWizard : function(component, event, activeWorksheets, resolve, reject) {
        var salesOrder = component.get("v.salesOrder");
        var nextWorksheetLineNo = component.get("v.nextWorksheetLineNo");
        var params = { "salesOrderId": salesOrder.Id, "JSONWorksheets": JSON.stringify(activeWorksheets), "nextWorksheetLineNo": nextWorksheetLineNo };
        this.callServerMethod(component, event, "c.prepareWizardQuestions", params, function (response) {
            var mapQuestionsByIndex = JSON.parse(response);
            var jobTaskQuestionSets = [];
            if (Object.keys(mapQuestionsByIndex).length > 0) {
                for (var worksheetIndex in mapQuestionsByIndex) {
                    var questions = mapQuestionsByIndex[worksheetIndex];
                    var activeWorksheet = activeWorksheets[worksheetIndex];
                    var jobTaskTemplate = {
                        "jobTaskWrapperIndex": worksheetIndex,
                        "title": 'Task ' + activeWorksheet.SalesOrderJobTask.Task_No__c + ' - ' + activeWorksheet.SalesOrderJobTask.Name,
                        "templateLines": questions
                    };
                    jobTaskQuestionSets.push(jobTaskTemplate);
                }
            }
            if (jobTaskQuestionSets.length > 0) {
                var buttons = [];
                var params = {
                    "questionSets": jobTaskQuestionSets,
                    "contractId": salesOrder.Contract__c,
                    "completeCallback": this.completeWizardCallback.bind(this, component, event, activeWorksheets, resolve),
                    "cancelCallback": this.cancelCallback.bind(this, component, event),
                    "resolve": resolve
                };
                this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, "medium", null, null);
            }
            else {
                resolve();
            }
        }, function(error) {
            this.showToast(component, "Error", error, "error", "dismissible");
            if (reject) {
                reject(error);
            }
        });
    },
    completeWizardCallback : function(component, event, activeWorksheets, resolve, jobTaskQuestionSets) {
        this.closeModal(component, event);

        var salesOrder = component.get("v.salesOrder");
        //var activeWorksheets = component.get("v.activeWorksheets");
        var tempWorksheets = []; //store child lines for recalculation

        for (var i = 0; i < jobTaskQuestionSets.length; i++) {
            var jobTaskQuestionSet = jobTaskQuestionSets[i];
            var mapTemplateLinesByIndex = new Map();
            for (var j = 0; j < jobTaskQuestionSet.templateLines.length; j++) {
                var templateLine = jobTaskQuestionSet.templateLines[j];
                mapTemplateLinesByIndex.set(templateLine.Line_No__c, templateLine);
            }

            var mapWorksheetLinesByLineNo = new Map();
            var parentLineNos = [];
            var worksheetIndex = jobTaskQuestionSet.jobTaskWrapperIndex;
            var activeWorksheet = activeWorksheets[worksheetIndex];
            var tempWorksheet = { "SalesOrderJobTask": activeWorksheet.SalesOrderJobTask, "WorksheetLines": [] };
            tempWorksheets.push(tempWorksheet);
            for (var j = 0; j < activeWorksheet.WorksheetLines.length; j++) {
                var worksheetLine = activeWorksheet.WorksheetLines[j];
                if (mapTemplateLinesByIndex.has(worksheetLine.Line_No__c)) {
                    var templateLine = mapTemplateLinesByIndex.get(worksheetLine.Line_No__c);
                    if (templateLine.Quantity__c) {
                        worksheetLine.Quantity__c = templateLine.Quantity__c;
                        worksheetLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        worksheetLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                        worksheetLine.Contract_Line__c = null; //null for pricing recalculation
                        worksheetLine.Contract_Line__r = null;
                    }
                    worksheetLine.Wizard_Question_Answered__c = true;
                    parentLineNos.push(worksheetLine.Parent_Line__r.Line_No__c);
                    mapTemplateLinesByIndex.delete(worksheetLine.Line_No__c);

                    tempWorksheet.WorksheetLines.push(worksheetLine);
                }
                mapWorksheetLinesByLineNo.set(worksheetLine.Line_No__c, worksheetLine);
            }

            //insert new child lines
            if (mapTemplateLinesByIndex.size > 0) {
                for (const [key, templateLine] of mapTemplateLinesByIndex.entries()) {
                    var parentLine = mapWorksheetLinesByLineNo.get(templateLine.Parent_Line__r.Line_No__c);
                    parentLineNos.push(parentLine.Line_No__c);
                    if (templateLine.Quantity__c != null && templateLine.Quantity__c > 0) {
                        var childLine = {};
                        childLine.Line_No__c = templateLine.Line_No__c;
                        childLine.Sales_Order_Job_Task__c = parentLine.Sales_Order_Job_Task__c;
                        childLine.Sales_Order_Job_Task__r = parentLine.Sales_Order_Job_Task__r;
                        childLine.Sales_Order__c = salesOrder.Id;
                        childLine.Sales_Order__r = { "Id": salesOrder.Id, "Name": salesOrder.Name };
                        childLine.Category__c = templateLine.Category__c;
                        if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment') {
                            childLine.Service_Center__c = parentLine.Service_Center__c;
                            childLine.Service_Center__r = parentLine.Service_Center__r;
                        }
                        childLine.Parent_Line__c = parentLine.Id;
                        childLine.Parent_Line__r = { "Id": parentLine.Id, "Line_No__c": parentLine.Line_No__c};
                        childLine.Resource_Type__c = templateLine.Resource_Type__c;
                        childLine.Resource_Type__r = templateLine.Resource_Type__r;
                        childLine.Resource__c = templateLine.Resource__c;
                        childLine.Resource__r = templateLine.Resource__r;
                        if (templateLine.Resource_Type__r) {
                            childLine.Description__c = templateLine.Description__c;
                            if (childLine.Resource__r) {
                                childLine.Resource_Name__c = templateLine.Resource__r.Name;
                            }
                        }
                        else {
                            childLine.Description__c = templateLine.Description__c;
                        }
                        childLine.Quantity__c = templateLine.Quantity__c;
                        childLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        childLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                        childLine.Cost_Method__c = templateLine.Cost_Method__c;
                        childLine.Container_Size__c = templateLine.Container_Size__c;
                        childLine.Container_Size__r = templateLine.Container_Size__r;
                        childLine.Unit_Weight_Vol__c = templateLine.Unit_Weight_Vol__c;
                        childLine.Unit_Weight_Vol__r = templateLine.Unit_Weight_Vol__r;
                        childLine.Resource_Type_UOM__c = templateLine.Resource_Type_UOM__c;
                        childLine.Resource_Type_UOM__r = templateLine.Resource_Type_UOM__r;
                        childLine.Resource_UOM__c = templateLine.Resource_UOM__c;
                        childLine.Resource_UOM__r = templateLine.Resource_UOM__r;
                        childLine.Unit_Price__c = templateLine.Unit_Price__c;
                        childLine.xUnit_Price__c = templateLine.xUnit_Price__c;
                        childLine.Unit_Cost__c = templateLine.Unit_Cost__c;
                        childLine.xUnit_Cost__c = templateLine.xUnit_Cost__c;
                        childLine.Tax_Group__c = templateLine.Tax_Group__c;
                        childLine.Tax_Pct__c = templateLine.Tax_Pct__c;
                        childLine.Tax__c = templateLine.Tax__c;
                        childLine.Regular_Rate__c = templateLine.Regular_Rate__c;
                        childLine.Overtime_Rate__c = templateLine.Overtime_Rate__c;
                        childLine.Premium_Rate__c = templateLine.Premium_Rate__c;
                        childLine.xRegular_Rate__c = templateLine.xRegular_Rate__c;
                        childLine.xOvertime_Rate__c = templateLine.xOvertime_Rate__c;
                        childLine.xPremium_Rate__c = templateLine.xPremium_Rate__c;
                        childLine.Pricing_Source_2__c = templateLine.Pricing_Source_2__c;
                        childLine.Line_Amount__c = templateLine.Line_Amount__c;
                        childLine.xLine_Amount__c = templateLine.xLine_Amount__c;
                        childLine.Line_Amt_Incl_Tax__c = templateLine.Line_Amt_Incl_Tax__c;
                        childLine.Line_Cost__c = templateLine.Line_Cost__c;
                        childLine.xLine_Cost__c = templateLine.xLine_Cost__c;
                        childLine.TM__c = templateLine.TM__c;
                        childLine.TM__r = templateLine.TM__r;
                        childLine.TM_Job_Task__c = templateLine.TM_Job_Task__c;
                        childLine.TM_Job_Task__r = templateLine.TM_Job_Task__r;

                        childLine.Wizard_Question_Answered__c = true;
                        activeWorksheet.WorksheetLines.push(childLine);
                        tempWorksheet.WorksheetLines.push(childLine);
                    }
                }
            }

            for (var j = 0; j < activeWorksheet.WorksheetLines.length; j++) {
                var worksheetLine = activeWorksheet.WorksheetLines[j];
                if (parentLineNos.includes(worksheetLine.Line_No__c)) {
                    worksheetLine.Wizard_Question_Answered__c = true;
                }
            }
        }

        var params = { "salesOrderId": salesOrder.Id, "JSONWorksheets": JSON.stringify(tempWorksheets) };
        this.callServerMethod(component, event, "c.calculatePriceInfo", params, function(response) {
            var activeWorksheets2 = JSON.parse(response);
            var mapWorksheetLinesByLineNo = new Map();

            for (var i = 0; i < activeWorksheets2.length; i++) {
                var activeWorksheet2 = activeWorksheets2[i];
                for (var j = 0; j < activeWorksheet2.WorksheetLines.length; j++) {
                    var worksheetLine = activeWorksheet2.WorksheetLines[j];
                    mapWorksheetLinesByLineNo.set(worksheetLine.Line_No__c, worksheetLine);
                }
            }

            for (var i = 0; i < activeWorksheets.length; i++) {
                var activeWorksheet = activeWorksheets[i];
                for (var j = 0; j < activeWorksheet.WorksheetLines.length; j++) {
                    var worksheetLine = activeWorksheet.WorksheetLines[j];
                    if (mapWorksheetLinesByLineNo.has(worksheetLine.Line_No__c)) {
                        activeWorksheet.WorksheetLines[j] = mapWorksheetLinesByLineNo.get(worksheetLine.Line_No__c);
                    }
                }
            }
            resolve(); //recalculate lines
        });

    },
    saveWorksheets: function (component, event, activeWorksheets, redirect, resolve) {
        var salesOrderId = component.get("v.salesOrderId");
        //var activeWorksheets = component.get("v.activeWorksheets");
        var params = {"salesOrderId": salesOrderId, "JSONWorksheets": JSON.stringify(activeWorksheets)};
        this.callServerMethod(component, event, "c.saveWorksheets", params, function(response) {
            if (redirect == true) {
                this.navigateToSObject(component, event, salesOrderId);
            } else {
                var savedWorksheets = JSON.parse(response);
                this.setUnsavedChanges(component, false);

                for (var i = 0; i < savedWorksheets.length; i++) {
                    this.sortLines(savedWorksheets[i].WorksheetLines);
                }

                component.set("v.activeWorksheets", savedWorksheets);
                //recover the active worksheet lines section <<

                this.callServerMethod(component, event, "c.getNextWorksheetLineNo", params, function (response) {
                    component.set("v.nextWorksheetLineNo", response);
                }, null, true);

                if (resolve) {
                    resolve();
                }
            }
        });
    },
    moveLines : function(component, event, fromJobTask, toJobTask, worksheetLines) {
        var activeWorksheets = component.get("v.activeWorksheets");
        var fromWorksheetIndex = -1;
        var toWorksheetIndex = -1;
        for (var i = 0; i < activeWorksheets.length; i++) {
            var activeWorksheet = activeWorksheets[i];
            if (activeWorksheet.SalesOrderJobTask.Line_No__c == fromJobTask.Line_No__c) {
                fromWorksheetIndex = i;
            }
            if (activeWorksheet.SalesOrderJobTask.Line_No__c == toJobTask.Line_No__c) {
                toWorksheetIndex = i;
            }
        }

        if (fromWorksheetIndex >= 0 && toWorksheetIndex >= 0) {
            var fromWorksheet = activeWorksheets[fromWorksheetIndex];
            var toWorksheet = activeWorksheets[toWorksheetIndex];

            var worksheetLineNos = [];
            for (var i = 0; i < worksheetLines.length; i++) {
                worksheetLineNos.push(worksheetLines[i].Line_No__c);
            }

            var nextWorksheetLineNo = 0;
            for (var i = 0; i < toWorksheet.WorksheetLines.length; i++) {
                var worksheetLine = toWorksheet.WorksheetLines[i];

                if (worksheetLine.Line_No__c > nextWorksheetLineNo) {
                    nextWorksheetLineNo = worksheetLine.Line_No__c;
                }
            }
            nextWorksheetLineNo++;

            var setupData = component.get("v.setupData");
            /*
            var mapTMTasksByTMIdByOrderTaskLineNo = setupData.TMTasksByTMIdByOrderTaskLineNo;

            //test T&M job tasks
            for (var i = 0; i < worksheetLines.length; i++) {
                worksheetLine = worksheetLines[i];
                if (!mapTMTasksByTMIdByOrderTaskLineNo.has(toWorksheet.SalesOrderJobTask.Line_No__c)) {
                    this.showToast(component, "", "Sales order job task " + toWorksheet.SalesOrderJobTask.Name + " is not found.");
                    return;
                }
                var mapTMTasksByTMId = mapTMTasksByTMIdByOrderTaskLineNo.get(toWorksheet.SalesOrderJobTask.Line_No__c);
                if (!mapTMTasksByTMId.has(worksheetLine.TM__c)) {
                    this.showToast(component, "", 'You cannot move worksheet line ' + worksheetLine.Line_No__c + ' to the job task "' + toJobTask.Name + '" because the job task does not exist on the T&M "' + worksheetLine.TM__r.Name + '".', 'error', 'dismissible');
                    return;
                }
            }*/

            var mapTMTasksByOrderTaskLineNoByTMId = setupData.TMTasksByOrderTaskLineNoByTMId;
            //add lines to the to worksheet
            for (var i = 0; i < worksheetLines.length; i++) {
                worksheetLine = worksheetLines[i];

                var mapTMTasksByOrderTaskLineNo = mapTMTasksByOrderTaskLineNoByTMId.get(worksheetLine.TM__c);
                var tmJobTask = mapTMTasksByOrderTaskLineNo.get(toWorksheet.SalesOrderJobTask.Line_No__c);

                worksheetLine.Line_No__c = nextWorksheetLineNo;
                worksheetLine.Sales_Order_Job_Task__c = toWorksheet.SalesOrderJobTask.Id;
                worksheetLine.Sales_Order_Job_Task__r = toWorksheet.SalesOrderJobTask;
                worksheetLine.TM_Job_Task__c = tmJobTask.Id;
                worksheetLine.TM_Job_Task__r = tmJobTask;
                worksheetLine.Selected = false;
                worksheetLine.Parent_Line__c = null;
                worksheetLine.Parent_Line__r = null;
                worksheetLine.Bundle_Line__c = null;
                worksheetLine.Bundle_Line__r = null;
                toWorksheet.WorksheetLines.push(worksheetLine);
                nextWorksheetLineNo++;
            }

            //remove lines from the from worksheet
            for (var i = 0; i < fromWorksheet.WorksheetLines.length; i++) {
                var worksheetLine = fromWorksheet.WorksheetLines[i];

                if (worksheetLineNos.includes(worksheetLine.Line_No__c)) {
                    fromWorksheet.WorksheetLines.splice(i, 1);
                    i--;
                }
            }

            this.sortLines(fromWorksheet.WorksheetLines);
            this.sortLines(toWorksheet.WorksheetLines);
            component.set("v.activeWorksheets[" + fromWorksheetIndex + "]", fromWorksheet);
            component.set("v.activeWorksheets[" + toWorksheetIndex + "]", toWorksheet);
        }

    },
    confirmDeselectWorksheet: function(component, event, rowIndex) {
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelDeselectWorksheetCallback.bind(this, component, event, rowIndex) }});
        buttons.push({ "label": 'OK', "variant": 'brand', "action": { "callback": this.confirmDeselectWorksheetCallback.bind(this, component, event, rowIndex) }});
        this.openModal(component, event, 'Deselect Worksheet', 'Are you sure you want to deselect this worksheet?', buttons, null, null, null);
    },
    confirmDeselectWorksheetCallback : function(component, event, rowIndex) {
        this.closeModal(component, event);
        var worksheets = component.get("v.worksheets");
        var worksheet = worksheets[rowIndex];
        var activeWorksheets = component.get("v.activeWorksheets");

        for (var i = 0; i < activeWorksheets.length; i++) {
            if (activeWorksheets[i].SalesOrderJobTask.Id == worksheet.SalesOrderJobTask.Id) {
                activeWorksheets.splice(i, 1);
                break;
            }
        }
        component.set("v.activeWorksheets", activeWorksheets);

        if (rowIndex >= activeWorksheets.length) {
            component.set("v.selectedTabId", "tab0")
        }
    },
    cancelDeselectWorksheetCallback : function(component, event, rowIndex) {
        this.closeModal(component, event);
        var worksheets = component.get("v.worksheets");
        worksheets[rowIndex].Selected = true;
        component.set("v.worksheets[" + rowIndex + "]", worksheets[rowIndex]);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    setUnsavedChanges : function(component, unsaved) {
        component.set("v.unsavedChanges", unsaved);
    },
    getWorksheetTabs : function(component) {
        var worksheetTabs = [];
        var worksheetTabCmp = component.find("active-worksheet");
        if (worksheetTabCmp) {
            if (Array.isArray(worksheetTabCmp)) {
                worksheetTabs = worksheetTabCmp;
            }
            else {
                worksheetTabs.push(worksheetTabCmp);
            }
        }
        return worksheetTabs;
    },
    calculateProfitAndMargin : function(component, worksheets) {
        var lineTotals = [];
        var items = new Map();

        var showInvoiceTotals = false;

        if (worksheets) {
            var actualTotalAmount = 0;
            var actualTotalTax = 0;
            var actualTotalAmountInclTax = 0;
            var actualTotalCost = 0;

            var invoiceTotalAmount = 0;
            var invoiceTotalTax = 0;
            var invoiceTotalAmountInclTax = 0;

            for (var i = 0 ; i < worksheets.length; i++) {
                var worksheet = worksheets[i];

                var worksheetAmount = 0;
                var worksheetTax = 0;
                var worksheetAmountInclTax = 0;
                var worksheetCost = 0;

                if (worksheet.WorksheetLines != null) {
                    for (var j = 0; j < worksheet.WorksheetLines.length; j++) {
                        var worksheetLine = worksheet.WorksheetLines[j];
                        if (worksheetLine.To_Invoice__c == true) {
                            var rollupAmount = true;
                            var rollupCost = true;
                            if (worksheetLine.Bill_as_Lump_Sum__c == true) {
                                rollupAmount = false;
                                //rollupCost = false;
                            } else if (worksheetLine.Non_Billable__c == true) {
                                rollupAmount = false;
                            }

                            if (rollupAmount || rollupCost) {
                                //roll up totals by category
                                var item;
                                var category = worksheetLine.Category__c;
                                //change category description
                                if (category == 'Demurrage') {
                                    category = 'Transportation, Demurrage and Fees';
                                } else if (category == 'Subcontractors') {
                                    category = 'Cost Plus Materials, Equipment and Services';
                                } else if (category == 'Bundled') {
                                    category = 'Bundled';
                                }

                                if (items.has(category)) {
                                    item = items.get(category);
                                } else {
                                    item = {
                                        "Category": category,
                                        "LineAmount": 0,
                                        "Tax": 0,
                                        "LineAmountIncludingTax": 0,
                                        "LineCost": 0
                                    };
                                    items.set(category, item);
                                }

                                if (rollupAmount) {
                                    item.LineAmount += worksheetLine.Line_Amount__c;
                                    item.Tax += worksheetLine.Tax__c;
                                    item.LineAmountIncludingTax += worksheetLine.Line_Amt_Incl_Tax__c;

                                    worksheetAmount += worksheetLine.Line_Amount__c;
                                    worksheetTax += +worksheetLine.Tax__c;
                                    worksheetAmountInclTax += worksheetLine.Line_Amt_Incl_Tax__c;
                                }
                                if (rollupCost) {
                                    item.LineCost += worksheetLine.Line_Cost__c;

                                    worksheetCost += worksheetLine.Line_Cost__c;
                                }
                            }
                        }
                    }
                }

                actualTotalAmount += worksheetAmount;
                actualTotalTax += worksheetTax;
                actualTotalAmountInclTax += worksheetAmountInclTax;
                actualTotalCost += worksheetCost;


                if (worksheet.SalesOrderJobTask.Billing_Type__c == 'Fixed Price') {
                    var invoiceAmount = (worksheet.SalesOrderJobTask.Amount_To_Bill__c ? worksheet.SalesOrderJobTask.Amount_To_Bill__c : 0);
                    var taxPct = 0;
                    if (worksheet.SalesOrderJobTask.Tax_Group__c == 'TX') {
                        taxPct = (worksheet.SalesOrderJobTask.Tax_Pct__c ? worksheet.SalesOrderJobTask.Tax_Pct__c : 0);
                    }
                    invoiceTotalAmount += invoiceAmount;
                    invoiceTotalTax += Math.round(invoiceAmount * taxPct) / 100;
                    showInvoiceTotals = true;
                }
                else {
                    invoiceTotalAmount += worksheetAmount;
                    invoiceTotalTax += worksheetTax;
                }
                invoiceTotalAmountInclTax += invoiceTotalAmount + invoiceTotalTax;
            }

            //invoice totals
            if (showInvoiceTotals) {
                var item = {
                    "Category": "Suggested Totals",
                    "LineAmount": actualTotalAmount,
                    "Tax": actualTotalTax,
                    "LineAmountIncludingTax": actualTotalAmountInclTax,
                    "LineCost": actualTotalCost,
                    "class": 'total-bold '
                };
                items.set("Suggested Totals", item);

                item = {
                    "Category": "Fixed Price Totals",
                    "LineAmount": invoiceTotalAmount,
                    "Tax": invoiceTotalTax,
                    "LineAmountIncludingTax": invoiceTotalAmountInclTax,
                    "LineCost": actualTotalCost,
                    "class": 'total-bold '
                };
                items.set("Fixed Price Total", item);
            }
            else {
                var item = {
                    "Category": "Totals",
                    "LineAmount": actualTotalAmount,
                    "Tax": actualTotalTax,
                    "LineAmountIncludingTax": actualTotalAmountInclTax,
                    "LineCost": actualTotalCost,
                    "class": 'total-bold '
                };
                items.set("Totals", item);
            }

            for (const [key, item] of items.entries()) {
                item.ProfitMargin = 0;
                if (item.LineAmount != 0) {
                    item.ProfitMargin = (1 - item.LineCost / item.LineAmount);
                }
                if (!item.class) {
                    item.class = '';
                }
                item.class += 'slds-cell-wrap';
                lineTotals.push(item);
            }
        }
        component.set("v.lineTotals", lineTotals);
    },
    setNextWorksheetLineNo : function(component, activeWorksheets) {
        var nextWorksheetLineNo = 0;
        activeWorksheets.forEach(function(activeWorksheet) {
            activeWorksheet.WorksheetLines.forEach(function(worksheetLine) {
                if (nextWorksheetLineNo < worksheetLine.Line_No__c) {
                    nextWorksheetLineNo = worksheetLine.Line_No__c;
                }
            });
        });
        nextWorksheetLineNo++;
        component.set("v.nextWorksheetLineNo", nextWorksheetLineNo);
    }
});