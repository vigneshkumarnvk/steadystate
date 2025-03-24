({
    doInit : function(component, event, helper) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        helper.groupTMLines(component, jobTaskWrapper);
    },
    handleMenuSelect : function(component, event, helper) {
        var value = event.getParam("value"); //from menuItem
        switch(value) {
            case 'create-lines-from-template':
                helper.createTMLinesFromTemplate(component, event);
                break;
            case 'import-lines-from-sales-order':
                helper.createTMLinesFromSalesOrder(component, event);
                break;
            /*
            case 'edit-task':
                helper.editJobTask(component, event);
                break;*/
            case 'delete-task':
                helper.confirmDeleteJobTask(component, event);
                break;
        }
    },
    moveLines : function(component, event, helper) {
        helper.confirmMoveLines(component, event);
    },
    calculateLines : function(component, event, helper) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        helper.calculateTMJobTask(component, event, jobTaskWrapper);
    },
    handleTMLinesChangeEvent : function(component, event, helper) {
        //this function is called whenever a section's tmLines are updated (add, delete, modify)
        var category = event.getParam("category");
        var tmLines = event.getParam("tmLines");
        var causedByField = event.getParam("causedByField");
        var causedByRowIndex = event.getParam("causedByRowIndex");
        //ticket 19130 <<
        /*
        var sectionIndex = -1;
        switch(category) {
            case 'Labor':
                sectionIndex = 0;
                break;
            case 'Equipment':
                sectionIndex = 1;
                break;
            case 'Materials':
                sectionIndex = 2;
                break;
            case 'Subcontractors':
                sectionIndex = 3;
                break;
            case 'Waste Disposal':
                sectionIndex = 4;
                break;
            case 'Demurrage':
                sectionIndex = 5;
                break;
            case 'Misc. Charges And Taxes':
                sectionIndex = 6;
                break;
        }
        */
        var sectionIndex = [ 'Labor', 'Equipment', 'Materials', 'Subcontractors', 'Waste Disposal', 'Demurrage', 'Misc. Charges And Taxes' ].indexOf(category);

        //ticket 19130 >>
        if (sectionIndex >= 0) {
            var sectionLines = component.get("v.sectionLinesList[" + sectionIndex + "]");
            //Object.assign(sectionLines, tmLines);
            component.set("v.sectionLinesList[" + sectionIndex + "]", tmLines);

            //handle deleted lines
            var tmLineNos = [];
            var deletedTMLines = [];
            //ticket 19130 <<
            //var parentLineNos = [];
            //ticket 19130 >>
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            tmLines.forEach(function(tmLine) {
                tmLineNos.push(tmLine.Line_No__c);
            });
            for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
                var tmLine = jobTaskWrapper.TMLines[i];
                if (tmLine.Category__c == category) {
                    if (!tmLineNos.includes(tmLine.Line_No__c)) { //line has been deleted
                        deletedTMLines.push(tmLine);
                    }

                    //remove all lines from the category
                    jobTaskWrapper.TMLines.splice(i, 1);
                    i--;
                }
            }

            //ticket 19130 << this is handled by cleanUpRelations()
            /*
            //unlink child lines from the deleted lines
            if (deletedTMLines.length > 0) {
                if (tmLine.Parent_Line__r) {
                    parentLineNos.push(tmLine.Parent_Line__r.Line_No__c);
                }
                helper.unlinkChildLines(component, event, deletedTMLines);
            }


            //reactivate the wizard if all child lines are deleted, Wizard_Question_Answered__c = false
            for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
                var tmLine = jobTaskWrapper.TMLines[i];
                if (tmLine.Parent_Line__r) {
                    var index = parentLineNos.indexOf(tmLine.Parent_Line__r.Line_No__c);
                    if (index > 0) {
                        parentLineNos.splice(index, 1);
                    }
                }
            }

            for ( var i = 0; i < parentLineNos.length; i++) {
                for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
                    var tmLine = jobTaskWrapper.TMLines[i];
                    if (parentLineNos.includes(tmLine.Line_No__c)) {
                        tmLine.Wizard_Question_Answered__c = false;
                        break;
                    }
                }
            }
            */
            //ticket 19130 >>

            //re-insert the updated lines
            for (var i = 0; i < tmLines.length; i++) {
                jobTaskWrapper.TMLines.push(tmLines[i]);
            }

            //update equipment hours by equipment operator <<
            var tm = component.get("v.tm");
            if (category == 'Labor' && (tm.Status__c == 'Open' || tm.Status__c == 'Scheduled' || tm.Status__c == 'Mobile Review')) {
                var equipmentLines = [];
                var mapLaborLinesByLineNo = new Map();
                for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
                    var tmLine = jobTaskWrapper.TMLines[i];
                    if (tmLine.Category__c == 'Equipment') {
                        equipmentLines.push(tmLine);
                    }
                    else if (tmLine.Category__c == 'Labor') {
                        mapLaborLinesByLineNo.set(tmLine.Line_No__c, tmLine);
                    }
                }

                if (equipmentLines.length > 0) {
                    var equipmentLinesChanged = false;
                    for (var i = 0; i < equipmentLines.length; i++) {
                        var equipmentLine = equipmentLines[i];
                        if (equipmentLine.Invoiced__c != true && equipmentLine.Linked_Line__r) {
                            if (mapLaborLinesByLineNo.has(equipmentLine.Linked_Line__r.Line_No__c)) {
                                var laborLine = mapLaborLinesByLineNo.get(equipmentLine.Linked_Line__r.Line_No__c);
                                if (laborLine.Job_Start_Time__c && laborLine.Job_End_Time__c
                                    && (laborLine.Job_Start_Time__c != equipmentLine.Job_Start_Time__c || laborLine.Job_End_Time__c != equipmentLine.Job_End_Time__c)) {
                                    equipmentLine.Job_Start_Time__c = laborLine.Job_Start_Time__c;
                                    equipmentLine.Job_End_Time__c = laborLine.Job_End_Time__c;
                                    equipmentLine.Total_Job_Hours__c = laborLine.Total_Job_Hours__c;
                                    if (equipmentLine.Unit_of_Measure__r && equipmentLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                                        equipmentLine.Quantity__c = equipmentLine.Total_Job_Hours__c;
                                    } else {
                                        equipmentLine.Quantity__c = 1;
                                    }
                                    equipmentLinesChanged = true;
                                }
                            }
                        }
                    }
                    if (equipmentLinesChanged) {
                        var equipmentSectionLinesList = component.get("v.sectionLinesList[1]");
                        Object.assign(equipmentSectionLinesList, equipmentLines);
                        helper.refreshSections(component, [1]);
                    }
                }
            }

            //update equipment hours by equipment operator >>
            var calls = [];
            //ticket 19130 <<
            /*
            if (causedByField == 'Resource_Type__c' || causedByField == 'Resource__c') {
                var tmLine = tmLines[causedByRowIndex];
            */
            var tmLine = tmLines[causedByRowIndex];
            if ((causedByField == 'Resource_Type__c' || causedByField == 'Resource__c') && tmLine.Wizard_Question_Answered__c != true) {
            //ticket 19130 >>
                calls.push(helper.validateResourceTypeOrResource.bind(helper, component, event, tmLine));
            }

            if (causedByField == 'Flat_Pay_Lines__r') {
                calls.push(helper.calculateFlatPays.bind(helper, component, event));
            }

            //ticket 19130 <<
            //calls.push(helper.fireJobTaskWrapperUpdateEvent.bind(helper, component, event));
            calls.push(helper.cleanUpRelations.bind(helper, component, jobTaskWrapper));
            calls.push(helper.fireJobTaskWrapperUpdateEvent.bind(helper, component, jobTaskWrapper));
            //ticket 19130 >>

            helper.makeStackedCalls(component, event, helper, calls);
            //fire event to notify TMLineList that jobTaskWrapper has changed

            //helper.makeStackedCalls(component, event, helper, calls);
        }
    },
    //this function makes sure only one active inline edit row in all sections
    handleInlineEditOpen : function(component, event, helper) {
        var sectionName = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");

        //helper.combineTMLines(component);
        var sections = component.find("section");
        for (var i = 0; i < sections.length; i++) {
            var section = sections[i];
            if (section.get("v.category") != sectionName) {
                //console.log('close ' + section.get("v.category"))
                section.closeInlineEdit();
            }
        }
    },
    groupTMLines : function(component, event, helper) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        helper.groupTMLines(component, jobTaskWrapper);
    },
    /*
    combineTMLines : function(component, event, helper) {
        helper.combineTMLines(component);
    },*/
    isInlineEditMode : function(component, event, helper) {
        var inlineEditMode = false;
        var sections = component.find("section");
        for (var i = 0; i < sections.length; i++) {
            inlineEditMode = sections[i].isInlineEditMode();
            if (inlineEditMode) {
                break;
            }
        }
        return inlineEditMode;
    },
    closeInlineEdit : function(component, event, helper) {
        var sections = component.find("section");
        for (var i = 0; i < sections.length; i++) {
            sections[i].closeInlineEdit();
        }
    },
    validate : function(component, event, helper) {
        var status = event.getParams().arguments.status;

        if (status == 'Confirmed') {
            var sectionIndexes = [];
            var ok = true;
            var sections = component.find("section");
            for (var i = 0; i < sections.length; i++) {
                sectionIndexes.push(i);
                var valid = sections[i].validateLines();
                ok = ok && valid;
            }
            return ok;
            //this.refreshSections(component, sectionIndexes);
        }

        return true;
    },
    calculateFlatPays : function(component, event, helper) {
        helper.calculateFlatPays(component, event);
    }
});