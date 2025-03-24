({
    groupTMLines : function(component, jobTaskWrapper) {
        //var tmLines = JSON.parse(JSON.stringify(jobTaskWrapper.TMLines));

        var laborLines = jobTaskWrapper.TMLines.filter(function(tmLine) {
            return tmLine.Category__c == 'Labor';
        });
        var equipmentLines = jobTaskWrapper.TMLines.filter(function(tmLine) {
            return tmLine.Category__c == 'Equipment';
        });
        var materialLines = jobTaskWrapper.TMLines.filter(function(tmLine) {
            return tmLine.Category__c == 'Materials';
        });
        var subcontractorLines = jobTaskWrapper.TMLines.filter(function(tmLine) {
            return tmLine.Category__c == 'Subcontractors';
        });
        var wasteDisposalLines = jobTaskWrapper.TMLines.filter(function(tmLine) {
            return tmLine.Category__c == 'Waste Disposal';
        });
        var miscChargeLines = jobTaskWrapper.TMLines.filter(function(tmLine) {
            return tmLine.Category__c == 'Misc. Charges And Taxes';
        });
        var demurrageLines = jobTaskWrapper.TMLines.filter(function(tmLine) {
            return tmLine.Category__c == 'Demurrage';
        });

        var sectionLinesList = [];
        sectionLinesList.push(laborLines);
        sectionLinesList.push(equipmentLines);
        sectionLinesList.push(materialLines);
        sectionLinesList.push(subcontractorLines);
        sectionLinesList.push(wasteDisposalLines);
        sectionLinesList.push(demurrageLines);
        sectionLinesList.push(miscChargeLines);
        component.set("v.sectionLinesList", sectionLinesList);
    },
    updateJobTaskWrapperFromSections : function(component) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var tmLines = [];
        var sectionLinesList = component.get("v.sectionLinesList");
        for (var i = 0; i < sectionLinesList.length; i++) {
            tmLines = tmLines.concat(sectionLinesList[i]);
        }
        jobTaskWrapper.TMLines = tmLines;
        component.set("v.jobTaskWrapper", jobTaskWrapper);
        //return jobTaskWrapper;
    },
    createTMLinesFromTemplate : function(component, event) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        //blank out the old job task template field
        jobTaskWrapper.JobTask.Job_Task_Template__c = null;
        jobTaskWrapper.JobTask.Job_Task_Template__r = null;

        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.createTMLinesFromTemplateCallback.bind(this, component, event) }});
        var params = { "jobTask": jobTaskWrapper.JobTask, "mode": 'create-lines-from-template' };
        //ticket 19130 <<
        //this.openModal(component, event, 'Insert T&M Lines', null, buttons, 'c:JobTaskCard', params, 'medium');
        this.openModal(component, event, 'Insert T&M Lines', null, buttons, 'c:SelectJobTaskTemplateLines', params, 'medium');
        //ticket 19130 >>
    },
    createTMLinesFromTemplateCallback : function(component, event, jobTask, templateLines) {
        this.closeModal(component, event);
        var jobTaskTemplate = {"jobTaskWrapperIndex": 0, "title": jobTask.Name, "templateLines": []}; //use index 0
        for (var i = 0; i < templateLines.length; i++) {
            var templateLine = JSON.parse(JSON.stringify(templateLines[i]));
            //ticket 19130 <<
            /*
            if (templateLine.Parent_Line__r && templateLine.Parent_Line__r.Line_No__c && (!templateLine.Quantity__c || templateLine.Quantity__c == 0)) {
                templateLine.Parent_Line__r = null;
                templateLine.Parent_Line__c = null;
                jobTaskTemplate.templateLines.push(templateLine);
            }
            */
            if (templateLine.Is_Child_Resource__c == true && (!templateLine.Quantity__c || templateLine.Quantity__c == 0)) {
                jobTaskTemplate.templateLines.push(templateLine);
            }
            //ticket 19130 >>
        }
        if (jobTaskTemplate.templateLines.length > 0) {
            var jobTaskQuestionSets = [jobTaskTemplate];
            var buttons = [];
            var params = {
                "questionSets": jobTaskQuestionSets,
                "completeCallback": this.completeWizardCallback.bind(this, component, event, jobTask, templateLines),
                "cancelCallback": this.insertTMLinesFromSelectedTemplateLines.bind(this, component, event, jobTask, templateLines)
            };
            this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, null, null);
        }
        else {
            this.insertTMLinesFromSelectedTemplateLines(component, event, jobTask, templateLines);
        }
    },
    completeWizardCallback : function(component, event, jobTask, templateLines, jobTaskQuestionSets) {
        this.closeModal(component, event);
        var mapTemplateLinesByLineNo = new Map();
        var jobTaskQuestionSet = jobTaskQuestionSets[0];
        for (var i = 0; i < jobTaskQuestionSet.templateLines.length; i++) {
            var templateLine = jobTaskQuestionSet.templateLines[i];
            mapTemplateLinesByLineNo.set(templateLine.Line_No__c, templateLine);
        }
        for (var i = 0; i < templateLines.length; i++) {
            if (mapTemplateLinesByLineNo.has(templateLines[i].Line_No__c)) {
                var templateLine = mapTemplateLinesByLineNo.get(templateLines[i].Line_No__c);
                if (templateLine.Quantity__c) {
                    templateLines[i].Quantity__c = templateLine.Quantity__c;
                }
            }
        }
        this.insertTMLinesFromSelectedTemplateLines(component, event, jobTask, templateLines);
    },
    insertTMLinesFromSelectedTemplateLines : function(component, event, jobTask, templateLines) {
        this.closeModal(component, event);
        var tm = component.get("v.tm");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var nextTMLineNo = component.get("v.nextTMLineNo");

        jobTaskWrapper.JobTask.Name = jobTask.Name;
        jobTaskWrapper.JobTask.Billing_Type__c = jobTask.Billing_Type__c;
        jobTaskWrapper.JobTask.Fixed_Price__c = jobTask.Fixed_Price__c;
        jobTaskWrapper.JobTask.Job_Task_Template__c = jobTask.Job_Task_Template__c;
        jobTaskWrapper.JobTask.Job_Task_Template__r = jobTask.Job_Task_Template__r;
        this.createTMLines(component, templateLines, tm, jobTaskWrapper.JobTask, nextTMLineNo).forEach(function(tmLine) {
            jobTaskWrapper.TMLines.push(tmLine);
        });

        this.calculateTMJobTask(component, event, jobTaskWrapper);
    },
    createTMLines : function(component, templateLines, tm, jobTask, nextTMLineNo) {
        var variables = component.get("v.variables");
        var tmLines = [];
        for (var i = 0; i < templateLines.length; i++) {
            var templateLine = templateLines[i];

            var tmLine = {};
            tmLine.Line_No__c = nextTMLineNo;
            tmLine.TM__c = tm.Id;
            tmLine.TM_Job_Task__c = jobTask.Id;
            tmLine.TM_Job_Task__r = jobTask;
            tmLine.Category__c = templateLine.Category__c;
            if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment') {
                if (tm.Status__c == 'Confirmed') {
                    tmLine.Service_Center__c = variables.TemporaryServiceCenter.Id;
                    tmLine.Service_Center__r = variables.TemporaryServiceCenter;
                }
                else {
                    tmLine.Service_Center__c = tm.Service_Center__c;
                    tmLine.Service_Center__r = tm.Service_Center__r;
                }
            }
            tmLine.Resource_Type__c = templateLine.Resource_Type__c;
            tmLine.Resource_Type__r = templateLine.Resource_Type__r;
            tmLine.Resource__c = templateLine.Resource__c;
            tmLine.Resource__r = templateLine.Resource__r;
            if ((tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment') && tmLine.Resource__r != null) {
                tmLine.Resource_Name__c = tmLine.Resource__r.Name;
            }
            tmLine.Description__c = templateLine.Description__c;
            tmLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
            tmLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
            /*Waste001
            tmLine.Cost_Method__c = templateLine.Cost_Method__c;
            tmLine.Unit_Weight_Vol__c = templateLine.Unit_Weight_Vol__c;
            tmLine.Unit_Weight_Vol__r = templateLine.Unit_Weight_Vol__r;
            tmLine.Container_Size__c = templateLine.Container_Size__c;
            tmLine.Container_Size__r = templateLine.Container_Size__r;
             */
            tmLine.Cost_Method__c = null;
            tmLine.Unit_Weight_Vol__c = null;
            tmLine.Container_Size__c = null;

            tmLine.Quantity__c = templateLine.Quantity__c;
            tmLines.push(tmLine);

            nextTMLineNo++;
        }
        return tmLines;
    },
    createTMLinesFromSalesOrder : function(component, event) {
        var tm = component.get("v.tm");
        if (tm.Sales_Order__c == null) {
            this.showToast(component, 'Error', 'This T&M is not associated with a sales order.', 'error', 'dismissible');
            return;
        }

        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Import', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.createTMLinesFromSalesOrderCallback.bind(this, component, event) }});
        var params = { "salesOrderId": tm.Sales_Order__c, "salesOrderJobTaskId":  jobTaskWrapper.JobTask.Sales_Order_Job_Task__c };
        //ticket 19130 <<
        //this.openModal(component, event, 'Import Sales Lines', null, buttons, 'c:TMImportJobTasks', params, 'medium');
        this.openModal(component, event, 'Import Sales Lines', null, buttons, 'c:TMImportJobTasks', params, 'large');
        //ticket 19130 >>
    },
    createTMLinesFromSalesOrderCallback : function(component, event, salesOrderJobTaskWrappers) {
        this.closeModal(component, event);

        var salesOrderJobTaskWrapper = salesOrderJobTaskWrappers[0];
        var tm = component.get("v.tm");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var nextTMLineNo = component.get("v.nextTMLineNo");

        //var params = { "JSONTM": JSON.stringify(tm), "JSONSalesOrderJobTaskWrappers": JSON.stringify(salesOrderJobTaskWrappers), "nextJobTaskLineNo": 0, "nextTMLineNo": nextTMLineNo };
        var params = { "JSONTM": JSON.stringify(tm), "JSONSalesOrderJobTaskWrapper": JSON.stringify(salesOrderJobTaskWrapper), "JSONTMJobTaskWrapper": JSON.stringify(jobTaskWrapper) ,"nextTMLineNo": nextTMLineNo };
        this.callServerMethod(component, event, "c.createTMLinesFromSalesOrder", params, function (response) {
            var jobTaskWrapper2 = JSON.parse(response);
            Object.assign(jobTaskWrapper, jobTaskWrapper2);
            this.groupTMLines(component, jobTaskWrapper);

            //ticket 19130 <<
            //this.fireJobTaskWrapperUpdateEvent(component, event);
            this.fireJobTaskWrapperUpdateEvent(component, jobTaskWrapper);
            //ticket 19130 >>
        });
    },
    confirmMoveLines : function(component, event) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var tmLines = [];
        var invoicedLines = [];
        for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
            var tmLine = jobTaskWrapper.TMLines[i];
            if (tmLine.Selected == true) {
                if (tmLine.Invoiced__c == true) {
                    invoicedLines.push(tmLine);
                }
                else {
                    tmLines.push(jobTaskWrapper.TMLines[i]);
                }
            }
        }
        if (invoicedLines.length > 0) {
            this.showToast(component, "", "You cannot move T&M Line Numbers " + invoicedLines.join(', ') + " because they are invoiced.", "error", "dismissible");
            return;
        }

        if (tmLines.length > 0) {
            var jobTaskOptions = component.get("v.jobTaskOptions");
            var buttons = [];
            buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'OK', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "move", "callback": this.moveLinesCallback.bind(this, component, event, tmLines, jobTaskWrapper.JobTask) }});
            var params = { "jobTaskOptions": jobTaskOptions, "fromJobTask": jobTaskWrapper.JobTask };
            this.openModal(component, event, 'Move Lines', null, buttons, 'c:MoveJobTaskLinesDialog', params, 'small');
        }
        else {
            this.showToast(component, "Move Lines", "Please choose lines to move.", "error", "dismissible");
        }
    },
    moveLinesCallback : function(component, event, tmLines, fromJobTask, toJobTask) {
        this.closeModal(component, event);
        this.fireTMLinesMoveEvent(component, event, tmLines, fromJobTask, toJobTask);
    },
    confirmDeleteJobTask : function(component, event) {
        var buttons = [];
        buttons.push({ "label": 'OK', "variant": 'brand', "action": { "callback": this.confirmDeleteJobTaskCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Delete Task', 'Are you sure you want to delete this job task and the related T&M lines?', buttons, null, null, null);
    },
    confirmDeleteJobTaskCallback : function(component, event) {
        this.closeModal(component, event);
        this.fireJobTaskWrapperDeleteEvent(component, event);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    calculateFlatPays : function(component, event, resolve, reject) {
        var tm = component.get("v.tm");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var nextTMLineNo = component.get("v.nextTMLineNo");
        var mapMiscChargeLinesByResourceId = new Map();
        var miscChargeLines = [];
        for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
            var tmLine = jobTaskWrapper.TMLines[i];
            if (tmLine.Invoiced__c != true) {
                if (tmLine.Category__c == 'Labor') {
                    if (tmLine.Resource_Flat_Pays1__r && tmLine.Resource_Flat_Pays1__r.records) {
                        for (var j = 0; j < tmLine.Resource_Flat_Pays1__r.records.length; j++) {
                            var flatPayLine = tmLine.Resource_Flat_Pays1__r.records[j];
                            if (flatPayLine.Misc_Charge_Resource__r) {
                                var miscChargeLine;
                                if (mapMiscChargeLinesByResourceId.has(flatPayLine.Misc_Charge_Resource__c)) {
                                    miscChargeLine = mapMiscChargeLinesByResourceId.get(flatPayLine.Misc_Charge_Resource__c);
                                } else {
                                    miscChargeLine = {
                                        "Category__c": 'Misc. Charges And Taxes',
                                        "Line_No__c": nextTMLineNo,
                                        "TM__c": tm.Id,
                                        "TM_Job_Task__c": jobTaskWrapper.JobTask.Id,
                                        "TM_Job_Task__r": {
                                            "Id": jobTaskWrapper.JobTask.Id,
                                            "Line_No__c": jobTaskWrapper.JobTask.Line_No__c
                                        },
                                        "Resource__c": flatPayLine.Misc_Charge_Resource__c,
                                        "Resource__r": flatPayLine.Misc_Charge_Resource__r,
                                        "Description__c": flatPayLine.Misc_Charge_Resource__r.Description__c,
                                        "Unit_of_Measure__c": flatPayLine.Unit_of_Measure__c,
                                        "Unit_of_Measure__r": flatPayLine.Unit_of_Measure__r,
                                        "Quantity__c": 1,
                                        "Flat_Pay_Line__c": true
                                    };
                                    mapMiscChargeLinesByResourceId.set(miscChargeLine.Resource__c, miscChargeLine);
                                    nextTMLineNo++;
                                }
                            }
                        }
                    }
                } else if (tmLine.Category__c == 'Misc. Charges And Taxes' && tmLine.Flat_Pay_Line__c == true) {
                    miscChargeLines.push(tmLine); //save existing lines to an array.
                    jobTaskWrapper.TMLines.splice(i, 1);
                    i--;
                }
            }
        }

        //update the map
        for (var i = 0; i < miscChargeLines.length; i++) {
            var miscChargeLine = miscChargeLines[i];
            if (mapMiscChargeLinesByResourceId.has(miscChargeLine.Resource__c)) {
                var newMiscChargeLine = mapMiscChargeLinesByResourceId.get(miscChargeLine.Resource__c);
                newMiscChargeLine.Id = miscChargeLine.Id;
                newMiscChargeLine.Line_No__c = miscChargeLine.Line_No__c;
                newMiscChargeLine.Description__c = miscChargeLine.Description__c;
            }
        }

        //insert the updated lines to jobTaskWrapper
        for (let [key, value] of mapMiscChargeLinesByResourceId.entries()) {
            jobTaskWrapper.TMLines.push(value);
        }

        //update misc. charges section
        var sectionLines = jobTaskWrapper.TMLines.filter(function(tmLine) {
            return tmLine.Category__c == 'Misc. Charges And Taxes';
        });
        component.set("v.sectionLinesList[6]", sectionLines);

        if (resolve) {
            resolve();
        }
    },
    //ticket 19130 <<
    /*
    unlinkChildLines : function(component, event, tmLines) {
        var parentLineNos = [];
        var sectionIndexes = [];
        var sectionLinesList = component.get("v.sectionLinesList");
        for (var i = 0; i < tmLines.length; i++) {
            parentLineNos.push(tmLines[i].Line_No__c);
        }
        for (var i = 0; i < sectionLinesList.length; i++) {
            var sectionLines = sectionLinesList[i];
            for (var j = 0; j < sectionLines.length; j++) {
                var tmLine = sectionLines[j];
                if (tmLine.Parent_Line__r && parentLineNos.includes(tmLine.Parent_Line__r.Line_No__c)) {
                    tmLine.Parent_Line__r = null;
                    tmLine.Parent_Line__c = null;
                    if (!sectionIndexes.includes(i)) {
                        sectionIndexes.push(i);
                    }
                }
            }
        }

        this.refreshSections(component, sectionIndexes);
    },
    deleteChildLines : function(component, event, tmLine, resolve, reject) {
        var sectionIndexes = [];
        var sectionLinesList = component.get("v.sectionLinesList");
        for (var i = 0; i < sectionLinesList.length; i++) {
            var sectionLines = sectionLinesList[i];
            for (var j = sectionLines.length - 1; j >= 0; j--) {
                var childLine = sectionLines[j];
                if (childLine.Parent_Line__r && childLine.Parent_Line__r.Line_No__c == tmLine.Line_No__c) {
                    sectionLines.splice(j, 1);
                    if (!sectionIndexes.includes(i)) {
                        sectionIndexes.push(i);
                    }
                }
            }
        }
        this.refreshSections(component, sectionIndexes);
        this.updateJobTaskWrapperFromSections(component);
        if (resolve) {
            resolve();
        }
    },
    */
    //ticket 19130 >>
    validateResourceTypeOrResource : function(component, event, tmLine, resolve, reject) {
        var tm = component.get("v.tm");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var nextTMLineNo = component.get("v.nextTMLineNo");

        //ticket 19130 05.13.2023 <<
        //var params = { "JSONTM": JSON.stringify(tm), "JSONJobTask": JSON.stringify(jobTaskWrapper.JobTask), "JSONTMLine": JSON.stringify(tmLine), "nextTMLineNo": nextTMLineNo };
        var params = { "JSONTM": JSON.stringify(tm), "JSONJobTaskWrapper": JSON.stringify(jobTaskWrapper), "JSONTMLine": JSON.stringify(tmLine), "nextTMLineNo": nextTMLineNo };
        //ticket 19130 05.13.2023 >>
        this.callServerMethod(component, event, "c.validateResourceTypeOrResource", params, function(response) {
            //ticket 19130 05.03.2023 <<
            /*
            var newChildLines = JSON.parse(response);
            var childLineCount = 0;
            for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
                var childLine = jobTaskWrapper.TMLines[i];
                if (childLine.Parent_Line__r && childLine.Parent_Line__r.Line_No__c == tmLine.Line_No__c) {
                    childLineCount++;
                }
            }

            if (newChildLines.length == 0) {
                this.deleteChildLines(component, event, tmLine, null);
            }
            else if (childLineCount == 0) {
                var sectionIndexes = []; //track sections to refresh
                var sectionLinesList = component.get("v.sectionLinesList");
                if (newChildLines.length > 0) {
                    for (var i = 0; i < newChildLines.length; i++) {
                        var newChildLine = newChildLines[i];
                        switch (newChildLine.Category__c) {
                            case 'Labor':
                                sectionLinesList[0].push(newChildLine);
                                sectionIndexes.push(0);
                                break;
                            case 'Equipment':
                                sectionLinesList[1].push(newChildLine);
                                sectionIndexes.push(1);
                                break;
                            case 'Materials':
                                sectionLinesList[2].push(newChildLine);
                                sectionIndexes.push(2);
                                break;
                            case 'Subcontractors':
                                sectionLinesList[3].push(newChildLine);
                                sectionIndexes.push(3);
                                break;
                            case 'Waste Disposal':
                                sectionLinesList[4].push(newChildLine);
                                sectionIndexes.push(4);
                                break;
                            case 'Demurrage':
                                sectionLinesList[5].push(newChildLine);
                                sectionIndexes.push(5);
                                break;
                            case 'Misc. Charges And Taxes':
                                sectionLinesList[6].push(newChildLine);
                                sectionIndexes.push(6);
                                break;
                        }
                    }
                }
                this.refreshSections(component, sectionIndexes);
                this.updateJobTaskWrapperFromSections(component);
                if (resolve) {
                    resolve();
                }
            }*/
            tmLine = JSON.parse(response);
            if (tmLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r.records) {
                this.addChildLines(component, jobTaskWrapper, tmLine);
            }
            this.refreshSections(component, [0, 1, 2, 3, 4, 5, 6]);
            this.updateJobTaskWrapperFromSections(component);
            if (resolve) {
                resolve();
            }
            //ticket 19130 05.03.2023 >>
        });
    },
    refreshSections : function(component, sectionIndexes) {
        if (sectionIndexes.length > 0) {
            var sectionLinesList = component.get("v.sectionLinesList");
            for (var i = 0; i < sectionLinesList.length; i++) {
                if (sectionIndexes.includes(i)) {
                    component.set("v.sectionLinesList[" + i + "]", JSON.parse(JSON.stringify(sectionLinesList[i])));
                }
            }
/*
            var sections = component.find("section");
            for (var i = 0; i < sections.length; i++) {
                if (sectionIndexes.includes(i)) {
                    sections[i].refreshTable();
                }
            }*/
        }
        //this.combineTMLines(component);
    },
    fireTMLinesMoveEvent : function(component, event, tmLines, fromJobTask, toJobTask) {
        var tmLinesMoveEvent = component.getEvent("tmLinesMoveEvent");
        tmLinesMoveEvent.setParams({ "fromJobTask": fromJobTask, "toJobTask": toJobTask, "taskLines": tmLines });
        tmLinesMoveEvent.fire();
    },
    fireJobTaskWrapperDeleteEvent : function(component, event) {
        var jobTaskWrapperIndex = component.get("v.jobTaskWrapperIndex");
        var ondelete = component.getEvent("ondelete");
        ondelete.setParams({ "jobTaskWrapperIndex": jobTaskWrapperIndex });
        ondelete.fire();
    },
    //ticket 19130 <<
    /*
    fireJobTaskWrapperUpdateEvent : function(component, event) {
        var jobTaskWrapperIndex = component.get("v.jobTaskWrapperIndex");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var onchange = component.getEvent("onchange");
        onchange.setParams({ "jobTaskWrapperIndex": jobTaskWrapperIndex, "jobTaskWrapper": jobTaskWrapper });
        onchange.fire();
    },
    */
    fireJobTaskWrapperUpdateEvent : function(component, jobTaskWrapper) {
        var jobTaskWrapperIndex = component.get("v.jobTaskWrapperIndex");
        var onchange = component.getEvent("onchange");
        onchange.setParams({ "jobTaskWrapperIndex": jobTaskWrapperIndex, "jobTaskWrapper": jobTaskWrapper });
        onchange.fire();
    },
    //ticket 19130 >>
    calculateTMJobTask : function(component, event, jobTaskWrapper, callback) {
        var tm = component.get("v.tm");
        var nextTMLineNo = component.get("v.nextTMLineNo");

        var params = { "JSONTM": JSON.stringify(tm), "JSONJobTaskWrapper": JSON.stringify(jobTaskWrapper), "nextTMLineNo": nextTMLineNo };
        this.callServerMethod(component, event, "c.calculateTMJobTask", params, function(response) {
            var jobTaskWrapper = JSON.parse(response);
            component.set("v.jobTaskWrapper", jobTaskWrapper);

            this.groupTMLines(component, jobTaskWrapper);

            //ticket 19130 <<
            //this.fireJobTaskWrapperUpdateEvent(component, event);
            this.fireJobTaskWrapperUpdateEvent(component, jobTaskWrapper);
            //ticket 19130 >>

            if (callback) {
                callback();
            }
        })
    },
    //ticket 19130 05.03.2023 <<
    cleanUpRelations : function(component, jobTaskWrapper, resolve, reject) {
        this.cleanUpParentChildRelations(jobTaskWrapper);
        //refresh sections
        var sectionIndexes = [0, 1, 2, 3, 4, 5, 6]; //track sections to refresh
        this.refreshSections(component, sectionIndexes);
        this.updateJobTaskWrapperFromSections(component);

        if (resolve) {
            resolve();
        }
    },
    addChildLines : function(component, jobTaskWrapper, tmLine) {
        var mapTMinesByLineNo = new Map();
        for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
            var tmLine2 = jobTaskWrapper.TMLines[i];
            mapTMinesByLineNo.set(tmLine2.Line_No__c, tmLine2);

            if (jobTaskWrapper.TMLines[i].Line_No__c == tmLine.Line_No__c) {
                jobTaskWrapper.TMLines[i] = tmLine;
            }
        }
        tmLine.TM_Child_Lines__r.records.forEach(relation => {
            var childTMLine = relation.Child_Line__r;
            if (!mapTMinesByLineNo.has(childTMLine.Line_No__c)) {
                jobTaskWrapper.TMLines.push(childTMLine);
                mapTMinesByLineNo.set(childTMLine.Line_No__c, childTMLine);
            }
        });
        this.groupTMLines(component, jobTaskWrapper);

        /* obsolete
        if (childLines && childLines.length >= 0) {
            var lineIndex = -1;
            var mapChildResourceLinesByResourceId = new Map();
            for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
                var childLine = jobTaskWrapper.TMLines[i];
                if (childLine.Is_Child_Resource__c == true) {
                    var resourceId;
                    if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment' || childLine.Category__c == 'Bundled') {
                        resourceId = childLine.Resource_Type__c;
                    } else {
                        resourceId = childLine.Resource__c;
                    }
                    mapChildResourceLinesByResourceId.set(resourceId, childLine);
                }
                if (jobTaskWrapper.TMLines[i].Line_No__c == tmLine.Line_No__c) {
                    lineIndex = i;
                }
            }

            for (var i = 0; i < childLines.length; i++) {
                var childLine = childLines[i];
                var resourceId;
                if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment' || childLine.Category__c == 'Bundled') {
                    resourceId = childLine.Resource_Type__c;
                } else {
                    resourceId = childLine.Resource__c;
                }

                if (mapChildResourceLinesByResourceId.has(resourceId)) {
                    childLines[i] = mapChildResourceLinesByResourceId.get(resourceId);
                    childLines[i].Wizard_Question_Answered__c = false; //reset the child line wizard question flag to prompt wizard
                } else {
                    jobTaskWrapper.TMLines.push(childLine);
                }
            }


            //remove existing relationships if exist
            tmLine.TM_Child_Lines__r = {"records": []};
            for (var i = 0; i < childLines.length; i++) {
                var childLine = childLines[i];
                tmLine.TM_Child_Lines__r.records.push({
                    "Parent_Line__c": tmLine.Id,
                    "Parent_Line__r": {
                        "attributes": {"type": 'TM_Line__c'},
                        "Id": tmLine.Id,
                        "Line_No__c": tmLine.Line_No__c,
                        "Description__c": tmLine.Description__c,
                        "Category__c": tmLine.Category__c,
                        "Resource_Type__c": tmLine.Resource_Type__c,
                        "Resource_Type__r": tmLine.Resource_Type__r,
                        "Resource__c": tmLine.Resource__c,
                        "Resource__r": tmLine.Resource__r,
                    },
                    "Child_Line__c": childLine.Id,
                    "Child_Line__r": {
                        "attributes": {"type": 'TM_Line__c'},
                        "Id": childLine.Id,
                        "Line_No__c": childLine.Line_No__c,
                        "Description__c": childLine.Description__c,
                        "Category__c": childLine.Category__c,
                        "Resource_Type__c": childLine.Resource_Type__c,
                        "Resource_Type__r": childLine.Resource_Type__r,
                        "Resource__c": childLine.Resource__c,
                        "Resource__r": childLine.Resource__r,
                    }
                });
            }
            tmLine.TM_Child_Lines__r.totalSize = tmLine.TM_Child_Lines__r.records.length;
            tmLine.TM_Child_Lines__r.done = "true";
            jobTaskWrapper.TMLines[lineIndex] = tmLine;

            this.groupTMLines(component, jobTaskWrapper);
        }
        */
    }
    //ticket 19130 >>
});