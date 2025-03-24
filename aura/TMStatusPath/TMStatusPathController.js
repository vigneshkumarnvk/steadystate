({
    doInit : function(component, event, helper) {
        var stages = [];
        stages.push({ "label": 'Open', "value": 'Open' });
        stages.push({ "label": 'Scheduled', "value": 'Scheduled' });
        stages.push({ "label": 'Mobile Review', "value": 'Mobile Review' });
        stages.push({ "label": 'Confirmed', "value": 'Confirmed' });      
        stages.push({ "label": 'Sent to EQAI', "value": 'Sent to EQAI', "disableClick": true });
        stages.push({ "label": 'Fully Invoiced', "value": 'Fully Invoiced', "disableClick": true });
        stages.push({ "label": 'Void', "value": 'Void' }); 
        component.set("v.stages", stages);        
        helper.getTM(component, event);
    },
    handleStageChange : function(component, event, helper) {
        var tm = component.get("v.tm");
        var stages = component.get("v.stages");
        var stageValues = [];
        stages.forEach(function(stage) {
            stageValues.push(stage.value);
        });

        var newValue = event.getParam("value");
        var newValueIndex = stageValues.indexOf(newValue);
        var value = tm.Status__c;
        var valueIndex = stageValues.indexOf(value);
        valueIndex++;

        if (value == 'Scheduled' && tm.Mobile_TM__c != true) {
            valueIndex++;
        }

        if (newValue != 'Void') {
            if (newValueIndex > valueIndex) {
                component.set("v.tm.Status__c", value);
                var path = component.find("path");
                if (path) {
                    path.setStage(value);
                }
                helper.showToast(component, "Error", "Next valid status is " + stageValues[valueIndex], "error", "dismissible");
            }
            component.set("v.singleStage", false);
        }
        else {
            if (newValue != value) {
                component.set("v.singleStage", true);
            }
        }
    },
    handleStageComplete : function(component, event, helper) {
        var status = event.getParam("value");
        var xStatus = component.get("v.xStatus");

        if (status != xStatus) {
            if (status == 'Confirmed') {
                component.set("v.tm.Status__c", status);

                var tm = component.get("v.tm");
                var jobTaskWrappers = component.get("v.jobTaskWrappers");

                //validate lines <<

                var ok = true;
                for (var i = 0; i < jobTaskWrappers.length; i++) {
                    var jobTaskWrapper = jobTaskWrappers[i];
                    var laborLines = [];
                    var equipmentLines = [];
                    var materialLines = [];
                    var subcontractorLines = [];
                    var wasteDisposalLines = [];
                    var demurrageLines = [];
                    var miscChargeLines = [];
                    for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                        var tmLine = jobTaskWrapper.TMLines[j];
                        switch (tmLine.Category__c) {
                            case 'Labor':
                                laborLines.push(tmLine);
                                break;
                            case 'Equipment':
                                equipmentLines.push(tmLine);
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
                            case 'Demurrage':
                                demurrageLines.push(tmLine);
                                break;
                            case 'Misc. Charges And Taxes':
                                miscChargeLines.push(tmLine);
                                break;
                        }
                    }
                    ok = ok && helper.validateLaborLines(component, laborLines);
                    ok = ok && helper.validateEquipmentLines(component, equipmentLines);
                    ok = ok && helper.validateMaterialLines(component, materialLines);
                    ok = ok && helper.validateSubcontractorLines(component, subcontractorLines);
                    ok = ok && helper.validateWasteDisposalLines(component, wasteDisposalLines);
                    ok = ok && helper.validateDemurrageLines(component, demurrageLines);
                    ok = ok && helper.validateMiscChargeLines(component, miscChargeLines);
                }

                if (!ok) {
                    helper.showToast(component, "Validation Errors", "One or more T&M lines are missing required fields.", "error", "dismissible");
                    return;
                }
                //validate lines >>

                var prompt = true;
                var calls = [];
                if (prompt == true) {
                    calls.push(helper.promptWizard.bind(helper, component, event, jobTaskWrappers));
                }
                calls.push(helper.calculateTMJobTasks.bind(helper, component, event, tm, jobTaskWrappers));
                calls.push(helper.saveTM.bind(helper, component, event, tm, jobTaskWrappers, status));
                helper.makeStackedCalls(component, event, helper, calls);
            } else {
                component.set("v.tm.Status__c", status);
                helper.saveTMHeader(component, event);
            }
        }
    }
});