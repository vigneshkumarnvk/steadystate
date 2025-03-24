({
    confirmMoveLines : function(component, event) {
        var worksheet = component.get("v.worksheet");
        var worksheetLines = [];
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = worksheet.WorksheetLines[i];
            if (worksheetLine.Selected == true) {
                worksheetLines.push(worksheetLine);
            }
        }
        
        if (worksheetLines.length > 0) {
            var jobTaskOptions = JSON.parse(JSON.stringify(component.get("v.jobTaskOptions"))); //make a copy
            
            //get the job tasks are on all selected worksheet lines
            var tmIds = [];
            for (var i = 0; i < worksheetLines.length; i++) {
                var worksheetLine = worksheetLines[i];
                if (!tmIds.includes(worksheetLine.TM__c)) {
                    tmIds.push(worksheetLine.TM__c);
                }
            }
            var setupData = component.get("v.setupData");
            var mapTMTasksByOrderTaskLineNoByTMId = setupData.TMTasksByOrderTaskLineNoByTMId;
            for (var i = 0; i < worksheetLines.length; i++) {
                var worksheetLine = worksheetLines[i];
                if (mapTMTasksByOrderTaskLineNoByTMId.has(worksheetLine.TM__c)) {
                    var mapTMTasksByOrderTaskLineNo = mapTMTasksByOrderTaskLineNoByTMId.get(worksheetLine.TM__c);
                    for (var j = 0; j < jobTaskOptions.length; j++) {
                        var jobTaskOption = jobTaskOptions[j];
                        if (!mapTMTasksByOrderTaskLineNo.has(jobTaskOption.value)) {
                            jobTaskOptions.splice(j, 1);
                            j--;
                        }
                    }
                }
            }
            
            if (jobTaskOptions.length == 1) {
                this.showToast(component, "", "Common job tasks are not found in the T&Ms of the selected lines.", "error", "dismissible");
                return;
            }
            
            var buttons = [];
            buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'OK', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "move", "callback": this.confirmMoveLinesCallback.bind(this, component, event, worksheetLines, worksheet.SalesOrderJobTask) }});
            var params = { "jobTaskOptions": jobTaskOptions, "fromJobTask": worksheet.SalesOrderJobTask };
            this.openModal(component, event, 'Move Lines', null, buttons, 'c:MoveJobTaskLinesDialog', params, 'small');
        }
        else {
            this.showToast(component, "", "Please select lines to move.", "error", "dismissible");
        }
    },
    confirmMoveLinesCallback : function(component, event, worksheetLines, fromJobTask, toJobTask) {
        this.closeModal(component, event);
        this.fireWorksheetLinesMoveEvent(component, event, worksheetLines, fromJobTask, toJobTask);
    },
    validateDeleteLines : function(component, rowIndexes) {
        var worksheet = component.get("v.worksheet");
        var childLines = [];
        var bundleLines = [];
        var systemLines = [];
        var undeletableLines = [];
        
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = worksheet.WorksheetLines[i];
            if (worksheetLine.Selected == true) {
                //ticket 19130 <<
                /*
                if (worksheetLine.Parent_Line__r != null) {
                    childLines.push(worksheetLine.Line_No__c);
                }
                */
                //ticket 19130 >>
                if (worksheetLine.Bundle_Line__r != null) {
                    bundleLines.push(worksheetLine.Line_No__c);
                }
                if (worksheetLine.System_Calculated_Line__c == true) {
                    systemLines.push(worksheetLine.Line_No__c);
                }
                if ((worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') && worksheetLine.Service_Center__r && worksheetLine.Service_Center__r.Temporary__c != true) {
                    undeletableLines.push(worksheetLine.Line_No__c);
                }
            }
        }
        
        var ok = true;
        if (childLines.length > 0) {
            this.showToast(component, "Delete Error", "You cannot delete lines (" + childLines.join(", ") + ") because they are linked to a parent line. Please delete the parent line first.", "error", "dismissible");
            ok = false;
        }
        if (bundleLines.length > 0) {
            this.showToast(component, "Delete Error", "You cannot delete bundled lines (" + bundleLines.join(", ") + "). Please unbundle lines first.", "error", "dismissible");
            ok = false;
        }
        if (systemLines.length > 0) {
            this.showToast(component, "Delete Error", "You cannot delete system calculated lines (" + systemLines.join(", ") + ").", "error", "dismissible");
            ok = false;
        }
        if (undeletableLines.length > 0) {
            this.showToast(component, "Delete Error", "You cannot delete none temporary labor/equipment line number(s) " + undeletableLines.join(", ") + ".", "error", "dismissible");
            ok = false;
        }
        return ok;
    },
    confirmDeleteLine : function(component, event, rowIndex) {
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'OK', "variant": 'brand', "action": { "callback": this.confirmDeleteLineCallback.bind(this, component, event, rowIndex) }});
        this.openModal(component, event, 'Delete Line', 'You are deleting the line. Are you sure you want to continue?', buttons, null, null, null);
    },
    confirmDeleteLineCallback : function(component, event, rowIndex) {
        this.closeModal(component, event);
        if (this.closeInlineEdit(component)) {
            var worksheet = component.get("v.worksheet");
            worksheet.WorksheetLines = this.deleteLines(component, worksheet.WorksheetLines, [parseInt(rowIndex)]);
            //component.set("v.worksheet", worksheet);
            component.set("v.worksheet.WorksheetLines", worksheet.WorksheetLines);
            this.setUnsavedChanges(component, event, true);
            this.calculateManifestFeeLines(component, event);
            this.fireWorksheetUpdateEvent(component, event);
        }
    },
    confirmDeleteLines : function(component, event, rowIndexes) {
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'OK', "variant": 'brand', "action": { "callback": this.confirmDeleteLinesCallback.bind(this, component, event, rowIndexes) }});
        this.openModal(component, event, 'Delete Lines', 'Are you sure you want to delete selected lines?', buttons, null, null, null);
    },
    confirmDeleteLinesCallback : function(component, event, rowIndexes) {
        this.closeModal(component, event);
        if (this.closeInlineEdit(component)) {
            var worksheet = component.get("v.worksheet");
            worksheet.WorksheetLines = this.deleteLines(component, worksheet.WorksheetLines, rowIndexes);
            //component.set("v.worksheet", worksheet);
            component.set("v.worksheet.WorksheetLines", worksheet.WorksheetLines);
            this.setUnsavedChanges(component, event, true);
            this.calculateManifestFeeLines(component, event);
            this.fireWorksheetUpdateEvent(component, event);
        }
    },
    deleteLines : function(component, worksheetLines, rowIndexes) {
        var worksheet = component.get("v.worksheet");
        for (var i = worksheetLines.length - 1; i >= 0; i--) {
            if (rowIndexes.includes(i)) {
                var worksheetLine = worksheetLines[i];
                if (worksheetLine.Category__c == 'Bundled') {
                    for (var j = 0; j < worksheetLines.length; j++) {
                        if (worksheetLines[j].Bundle_Line__r != null && worksheetLines[j].Bundle_Line__r.Line_No__c == worksheetLine.Line_No__c) {
                            worksheetLines[j].Bundle_Line__c = null;
                            worksheetLines[j].Bundle_Line__r = null;
                            worksheetLines[j].Bill_as_Lump_Sum__c = false;
                            if (worksheetLines[j].Non_Billable__c != true) {
                                worksheetLines[j].Unit_Price__c = worksheetLines[j].xUnit_Price__c;
                                //worksheetLines[j].Unit_Cost__c = worksheetLines[j].xUnit_Cost__c;
                                worksheetLines[j].Regular_Rate__c = worksheetLines[j].xRegular_Rate__c;
                                worksheetLines[j].Overtime_Rate__c = worksheetLines[j].xOvertime_Rate__c;
                                worksheetLines[j].Premium_Rate__c = worksheetLines[j].xPremium_Rate__c;
                            }
                            this.calculateLineTotals(worksheetLines[j]);
                        }
                    }
                }
                
                //ticket 19130 <<
                /*
                for (var j = 0; j < worksheetLines.length; j++) {
                    if (worksheetLines[j].Parent_Line__r != null && worksheetLines[j].Parent_Line__r.Line_No__c == worksheetLine.Line_No__c) {
                        worksheetLines[j].Parent_Line__c = null;
                        worksheetLines[j].Parent_Line__r = null;
                    }
                }
                */
                //ticket 19130 >>
                
                worksheet.DeletedWorksheetLines.push(worksheetLines[i]);
                worksheetLines.splice(i, 1);
                rowIndexes.splice(rowIndexes.indexOf(i), 1);
                i++;
            }
        }
        this.sortLines(worksheetLines);
        return JSON.parse(JSON.stringify(worksheetLines)); //return a copy to refresh the table
    },
    showLineCard : function(component, event, rowIndex, createNewBundleLine) {
        //close inline edit before showing
        this.closeInlineEdit(component);
        
        var salesOrderId = component.get("v.salesOrderId");
        var salesOrder = component.get("v.salesOrder");
        var setupData = component.get("v.setupData");
        var worksheet = component.get("v.worksheet");
        var nextWorksheetLineNo = component.get("v.nextWorksheetLineNo");
        var worksheetBundleLine = null;
        if (rowIndex >= 0) {
            worksheetBundleLine = worksheet.WorksheetLines[rowIndex];
        }
        
        //clear selected
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            worksheet.WorksheetLines[i].Selected = false;
        }
        this.refreshTable(component);
        
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.showLineCardCallback.bind(this, component, event) }});
        var params = { "salesOrderId": salesOrderId, "salesOrder": salesOrder, "worksheetBundleLine": worksheetBundleLine, "worksheet": worksheet, "nextWorksheetLineNo": nextWorksheetLineNo, "setupData": setupData, "createNewBundleLine": createNewBundleLine };
        this.openModal(component, event, 'Worksheet Bundle Line', null, buttons, 'c:BillingWorksheetLineCard', params, 'medium');
    },
    showLineCardCallback : function(component, event, worksheetLines) {
        this.closeModal(component, event);
        this.sortLines(worksheetLines);
        component.set("v.worksheet.WorksheetLines", worksheetLines);
        this.setUnsavedChanges(component, event, true);
        this.fireWorksheetUpdateEvent(component, event);
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    closeInlineEdit : function(component) {
        var datatable = component.find("datatable");
        return datatable.closeInlineEdit();
    },
    refreshTable : function(component) {
        var datatable = component.find("datatable");
        datatable.refreshTable();
    },
    getSelectedLines : function(component) {
        var rowIndexes = [];
        var worksheet = component.get("v.worksheet");
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            if (worksheet.WorksheetLines[i].Selected == true) {
                rowIndexes.push(i);
            }
        }
        return rowIndexes;
    },
    setUnsavedChanges : function(component, event, unsaved) {
        component.set("v.unsavedChanges", unsaved);
        this.fireUnsavedChangesEvent(component, event);
    },
    fireUnsavedChangesEvent : function(component, event) {
        var unsavedChangesEvent = component.getEvent("unsavedChangesEvent");
        unsavedChangesEvent.setParams({ "unsaved": component.get("v.unsavedChanges") });
        unsavedChangesEvent.fire();
    },
    fireWorksheetLinesMoveEvent : function(component, event, worksheetLines, fromJobTask, toJobTask) {
        var worksheetLinesMoveEvent = component.getEvent("worksheetLinesMoveEvent");
        worksheetLinesMoveEvent.setParams({ "fromJobTask": fromJobTask, "toJobTask": toJobTask, "taskLines": worksheetLines });
        worksheetLinesMoveEvent.fire();
    },
    fireWorksheetUpdateEvent : function(component, event, resolve) {
        //var index = component.get("v.index");
        console.log('fire workshhet update event');
        var index = component.get("v.worksheetIndex");
        var worksheet = component.get("v.worksheet");
        var worksheetUpdateEvent = component.getEvent("worksheetUpdateEvent");
        worksheetUpdateEvent.setParams({ "index": index, "worksheet": worksheet });
        worksheetUpdateEvent.fire();
        if (resolve) {
            resolve();
        }
    },
    calculateManifestFeeLines : function(component, event) {
        var worksheet = component.get("v.worksheet");
        var setupData = component.get("v.setupData");
        var salesOrderId = component.get("v.salesOrderId");
        
        var manifestFeeResource = setupData.CompanySetup.Default_Manifest_Fee_Resource__r;
        var mapManifestFeeLinesByTMId = new Map();
        var mapTMIdsByTaskId = new Map();
        
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = worksheet.WorksheetLines[i];
            if (worksheetLine.Category__c == 'Waste Disposal') {
                if (worksheetLine.System_Calculated_Line__c !== true) {
                    if (!mapTMIdsByTaskId.has(worksheetLine.TM__c)) {
                        mapTMIdsByTaskId.set(worksheetLine.TM_Job_Task__c, worksheetLine.TM__c);
                    }
                }
                else {
                    if (worksheetLine.Resource__c === manifestFeeResource.Id) {
                        mapManifestFeeLinesByTMId.set(worksheetLine.TM__c, worksheetLine);
                    }
                }
            }
        }
        
        var nextWorksheetLineNo = component.get("v.nextWorksheetLineNo");
        for (const [taskId, tmId] of mapTMIdsByTaskId.entries()) {
            if (mapManifestFeeLinesByTMId.has(tmId)) {
                mapTMIdsByTaskId.delete(tmId);
                mapManifestFeeLinesByTMId.delete(tmId);
                i--;
            }
        }
        
        var lineNosToDelete = [];
        for (const [key, worksheetLine] of mapManifestFeeLinesByTMId.entries()) {
            lineNosToDelete.push(worksheetLine.Line_No__c);
        }
        
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = worksheet.WorksheetLines[i];
            if (lineNosToDelete.includes(worksheetLine.Line_No__c)) {
                worksheet.DeletedWorksheetLines.push(worksheetLine);
                worksheet.WorksheetLines.splice(i, 1);
                i--;
            }
        }
        //this.sortLines(worksheet.WorksheetLines);
        //component.set("v.worksheet", worksheet);
        component.set("v.worksheet.WorksheetLines", worksheet.WorksheetLines);
        //ticket 19753 - next worksheet line no not updated after manifest fee line inserted
        //component.set("v.nextWorksheetLineNo", nextWorksheetLineNo);
        this.fireWorksheetUpdateEvent(component, event);
        //ticket 19753 >>
    },
    calculateManifestFeeLines2 : function (component, event){
        var worksheet = component.get("v.worksheet");
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheet": JSON.stringify(worksheet)};
        this.callServerMethod(component, event, "c.calculateManifestFeeLines", params, function (response) {
            worksheet = JSON.parse(response);
            //ticket 20475 << fixed TM lookup (TMNoOptions) blank issue after manifest line calculation
            //component.set("v.worksheet", worksheet);
            component.set("v.worksheet.WorksheetLines", worksheet.WorksheetLines);
            //ticket 20475 >>
            
            //ticket 19753 - next worksheet line no not updated after manifest fee line inserted
            this.fireWorksheetUpdateEvent(component, event);
            //ticket 19753 >>
        });
    },
    //ticket 19130 << temporary disabled, not needed for this phase
    /*
    calculatePresumptiveChildLines : function(component, event, worksheetLine, worksheetLineIndex, resolve, reject) {
        var salesOrderId = component.get("v.salesOrderId");
        var nextWorksheetLineNo = component.get("v.nextWorksheetLineNo");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetLine), "nextWorksheetLineNo": nextWorksheetLineNo };
        this.callServerMethod(component, event, "c.calculatePresumptiveChildLines", params, function(response) {
            var childLines = JSON.parse(response);
            if (childLines.length > 0) {
                var questionSets = [];
                var questionSet = { "templateLines": [] };
                for (var i = 0; i < childLines.length; i++) {
                    var childLine = childLines[i];
                    var question = {};
                    question.Line_No__c = childLine.Line_No__c;
                    question.Category__c = childLine.Category__c;
                    question.Resource_Type__c = childLine.Resource_Type__c;
                    question.Resource_Type__r = childLine.Resource_Type__r;
                    question.Resource__c = childLine.Resource__c;
                    question.Resource__r = childLine.Resource__r;
                    question.Description__c = childLine.Description__c;
                    question.Unit_of_Measure__c = childLine.Unit_of_Measure__c;
                    question.Unit_of_Measure__r = childLine.Unit_of_Measure__r;
                    question.Cost_Method__c = childLine.Cost_Method__c;
                    question.Unit_Weight_Vol__c = childLine.Unit_Weight_Vol__c;
                    question.Unit_Weight_Vol__r = childLine.Unit_Weight_Vol__r;
                    question.Container_Size__c = childLine.Container_Size__c;
                    question.Container_Size__r = childLine.Container_Size__r;
                    question.Question__c = 'Do you want to set quantity for the child resource ' + childLine.Description__c + '?';

                    question.Parent_Line__c = worksheetLine.Id;
                    question.Parent_Line__r = { "Id": worksheetLine.Id, "Line_No__c": worksheetLine.Line_No__c };

                    questionSet.templateLines.push(question);
                }
                questionSets.push(questionSet);
                var self = this;
                this.promptWizard(component, event, self, worksheetLine, worksheetLineIndex, questionSets, resolve);
            }
        })
    },
    promptWizard : function(component, event, helper, worksheetLine, worksheetLineIndex, questionSets, resolve) {
        var buttons = [];
        var params = {
            "questionSets": questionSets,
            "completeCallback": this.completeWizardCallback.bind(helper, component, event, worksheetLine, worksheetLineIndex, resolve),
            "cancelCallback": this.cancelCallback.bind(helper, component, event, resolve),
        };

        this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, "medium", null, null);
    },
    completeWizardCallback : function(component, event, worksheetLine, worksheetLineIndex, resolve, jobTaskQuestionSets) {
        this.closeModal(component, event);
        var salesOrderId = component.get("v.salesOrderId");
        var worksheet = component.get("v.worksheet");
        var worksheetLines = [];

        for (var i = 0; i < jobTaskQuestionSets.length; i++) {
            var jobTaskQuestionSet = jobTaskQuestionSets[i];
            for (var j = 0; j < jobTaskQuestionSet.templateLines.length; j++) {
                var templateLine = jobTaskQuestionSet.templateLines[j];

                if (templateLine.Quantity__c != null && templateLine.Quantity__c > 0) {
                    var childLine = {};
                    childLine.Line_No__c = templateLine.Line_No__c;
                    childLine.Sales_Order__c = salesOrderId;
                    childLine.Sales_Order_Job_Task__c = worksheet.SalesOrderJobTask.Id;
                    childLine.TM_Job_Task__c = worksheetLine.TM_Job_Task__c;
                    childLine.TM_Job_Task__r = worksheetLine.TM_Job_Task__r;
                    childLine.TM__c = worksheetLine.TM__c;
                    childLine.TM__r = worksheetLine.TM__r;
                    childLine.Category__c = templateLine.Category__c;
                    if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment') {
                        childLine.Service_Center__c = worksheetLine.Service_Center__c;
                        childLine.Service_Center__r = worksheetLine.Service_Center__r;
                    }
                    childLine.Parent_Line__c = worksheetLine.Id;
                    childLine.Parent_Line__r = { "Id": worksheetLine.Id, "Line_No__c": worksheetLine.Line_No__c};
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
                    childLine.Wizard_Question_Answered__c = true;
                    worksheetLines.push(childLine);
                }
            }
        }

        worksheet.WorksheetLines[worksheetLineIndex].Wizard_Question_Answered__c = true;
        if (worksheetLines.length > 0) {
            this.populateLinesInfo(component, event, worksheet, worksheetLines, resolve);
        }
        else {
            component.set("v.worksheet", worksheet);
            if (resolve) {
                resolve();
            }
        }
    },
    */
    //ticket 19130 >>
    populateLinesInfo : function(component, event, worksheet, worksheetLines, resolve) {
        if (worksheetLines.length > 0) {
            var salesOrderId = component.get("v.salesOrderId");
            var params = {"salesOrderId": salesOrderId, "JSONWorksheetLines": JSON.stringify(worksheetLines)};
            this.callServerMethod(component, event, "c.populateLinesInfo", params, function (response) {
                var worksheetLines2 = JSON.parse(response);
                //var worksheet = component.get("v.worksheet");
                for (var i = 0; i < worksheetLines2.length; i++) {
                    worksheet.WorksheetLines.push(worksheetLines2[i]);
                }
                component.set("v.worksheet", worksheet);
                if (resolve) {
                    resolve();
                }
            });
        }
        else {
            if (resolve) {
                resolve();
            }
        }
    },
    //Ticket#20496 >>
    calculateLaborHoursUsingWeeklyRule : function (component, event){
        var worksheet = component.get("v.worksheet");
        var worksheetLines = [];
        var updatedWorksheetLine = event.getParam("worksheetLine");
        var salesOrderId = component.get("v.salesOrderId");
        
        for(var i = 0; i < worksheet.WorksheetLines.length; i++){
            if(worksheet.WorksheetLines[i].Line_No__c == updatedWorksheetLine.Line_No__c){
                Object.assign(worksheet.WorksheetLines[i], updatedWorksheetLine);
            }
            worksheetLines.push(worksheet.WorksheetLines[i]);
        }
        
        var params = {"salesOrderId": salesOrderId, "JSONWorksheetLines": JSON.stringify(worksheetLines),"JSONUpdatedWorksheetLine": JSON.stringify(updatedWorksheetLine)};
        this.callServerMethod(component, event, "c.calculateLaborHoursUsingWeeklyRule", params, function (response){
            var worksheetLines2 = JSON.parse(response);
            worksheet.WorksheetLines = worksheetLines2;
            component.set("v.worksheet", worksheet);
        });
    },
    //Ticket#20496 <<
    cancelCallback : function(component, event, resolve) {
        this.closeModal(component, event);
        if (resolve) {
            resolve();
        }
    }
});