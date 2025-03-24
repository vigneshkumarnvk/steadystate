({
    doInit : function(component, event, helper) {
        var worksheet = component.get("v.worksheet");
        var createNewBundleLine = component.get("v.createNewBundleLine");

        if (createNewBundleLine == true) {
            helper.getBundleLines(component, event);
        }
        else {
            var worksheetBundleLine = component.get("v.worksheetBundleLine");
            helper.displayBundledLines(component, worksheetBundleLine);
        }
    },
    addNewBundleLine : function(component, event, helper) {
        helper.createNewWorksheetBundleLine(component, event);
    },
    handleResourceTypeChange : function(component, event, helper) {
        var record = event.getParam("record");
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        if (record) {
            worksheetBundleLine.Resource_Type__c = record.Id;
            worksheetBundleLine.Description__c = record.Description__c;
            if (record.Unit_of_Measure__r) {
                worksheetBundleLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
                worksheetBundleLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
            helper.validateResourceType(component, event, worksheetBundleLine);
        }
        else {
            worksheetBundleLine.Resource_Type__c = null;
            worksheetBundleLine.Description__c = null;
        }
        component.set("v.worksheetBundleLine", worksheetBundleLine);
    },
    handleBundlePricingMethodChange : function(component, event, helper) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        var worksheetLines = component.get("v.worksheetLines");
        if (worksheetBundleLine.Bundle_Pricing_Method__c == 'Per Total') {
            worksheetBundleLine.Quantity__c = 1;
        }
        helper.rollupBundle(worksheetBundleLine, worksheetLines, true);
        if (worksheetBundleLine.Bundle_Pricing_Method__c == 'Per Unit') {
            worksheetBundleLine.Quantity__c = null;
        }
        component.set("v.worksheetBundleLine", worksheetBundleLine);
    },
    handleBundleLineRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        var value = event.getParam("value");
        switch(name) {
            case 'select':
                if (action == 'change') {
                    var bundleLines = component.get("v.bundleLines");
                    var bundleLine = bundleLines[rowIndex];
                    if (bundleLine) {
                        if (bundleLine.Selected == true) {
                            helper.createWorksheetBundleLine(component, event, bundleLine);
                        }
                        else {
                            component.set("v.worksheetBundleLine", null);
                            component.set("v.")
                        }
                    }
                }
                break;
        }
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        switch(name) {
            case 'select':
                if (action == 'change') {
                    helper.handleLineSelect(component, rowIndex);
                }
                break;
        }
    },
    handleSelectAll : function(component, event, helper) {
        helper.handleSelectAll(component, event);
    },
    /*
    handleResourceTypeChange : function(component, event, helper) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        var record = event.getParam("record");
        worksheetBundleLine.Contract_Line__c = null;
        worksheetBundleLine.Contract_Line__r = null;
        if (record) {
            worksheetBundleLine.Resource_Type__c = record.Id;
            worksheetBundleLine.Description__c = record.Description__c;
            worksheetBundleLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
            worksheetBundleLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            helper.validateResourceType(component, event, worksheetBundleLine);
        }
        else {
            worksheetBundleLine.Resource_Type__c = null;
            worksheetBundleLine.Description__c = null;
            worksheetBundleLine.Unit_of_Measure__c = null;
            worksheetBundleLine.Unit_of_Measure__r = null;
            component.set("v.worksheetBundleLine", worksheetBundleLine);
        }
    },
    handleContractLineChange : function(component, event, helper) {
        var record = event.getParam("record");
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        if (record) {
            worksheetBundleLine.Contract_Line__c = record.Id;

            worksheetBundleLine.Resource_Type__c = record.Resource_Type__c;
            worksheetBundleLine.Resource_Type__r = record.Resource_Type__r;
            worksheetBundleLine.Resource__c = record.Resource__c;
            worksheetBundleLine.Resource__r = record.Resource__r;
            worksheetBundleLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
            worksheetBundleLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            worksheetBundleLine.Unit_Price__c = record.Regular_Rate__c;
            worksheetBundleLine.xUnit_Price__c = salesLine.Unit_Price__c;
            worksheetBundleLine.Contract_Regular_Rate__c = record.Regular_Rate__c;
            worksheetBundleLine.Contract_Overtime_Rate__c = record.Overtime_Rate__c;
            worksheetBundleLine.Contract_Premium_Rate__c = record.Premium_Rate__c;
            if (record.Customer_Description__c != null) {
                worksheetBundleLine.Description__c = record.Customer_Description__c;
            }
        }
        else {
            worksheetBundleLine.Contract_Line__c = null;
            worksheetBundleLine.Resource_Type__c = null;
            worksheetBundleLine.Resource_Type__r = null;
            worksheetBundleLine.Resource__c = null;
            worksheetBundleLine.Resource__r = null;
            worksheetBundleLine.Unit_of_Measure__c = null;
            worksheetBundleLine.Unit_of_Measure__r = null;
            worksheetBundleLine.Unit_Price__c = worksheetBundleLine.xUnit_Price__c;
            worksheetBundleLine.Contract_Regular_Rate__c = worksheetBundleLine.xRegular_Rate__c;
            worksheetBundleLine.Contract_Overtime_Rate__c = worksheetBundleLine.xOvertime_Rate__c;
            worksheetBundleLine.Contract_Premium_Rate__c = worksheetBundleLine.xPremium_Rate__c;
        }
        helper.validateResourceType(component, event, worksheetBundleLine);
    },*/
    handleTaxGroupChange : function(component, event, helper) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        if (worksheetBundleLine.Tax_Group__c == 'TX') {
            helper.validateTaxGroup(component, event, worksheetBundleLine);
        }
        else {
            worksheetBundleLine.Tax_Pct__c = null;
            helper.calculateLineTotals(worksheetBundleLine);
            component.set("v.worksheetBundleLine", worksheetBundleLine);
        }
    },
    handleQuantityChange : function(component, event, helper) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        var worksheetLines = component.get("v.worksheetLines");
        helper.rollupBundle(worksheetBundleLine, worksheetLines, true);
        component.set("v.worksheetBundleLine", worksheetBundleLine);
        helper.calculateLineTotals(worksheetBundleLine);
        component.set("v.worksheetBundleLine", worksheetBundleLine);
    },
    handleUnitOfMeasureChange1 : function(component, event, helper) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        var record = event.getParam("record");
        if (record) {
            worksheetBundleLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            worksheetBundleLine.Unit_of_Measure__c = record.Unit_of_Measure__r;
            //worksheetBundleLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            //helper.validateUnitOfMeasure(component, event, worksheetBundleLine);
        }
        else {
            worksheetBundleLine.Unit_of_Measure__c = null;
        }
        component.set("v.worksheetBundleLine", worksheetBundleLine);
    },
    handleUnitOfMeasureChange2 : function(component, event, helper) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        var record = event.getParam("record");
        if (record) {
            worksheetBundleLine.Unit_of_Measure__c = record.Id;
            //helper.validateUnitOfMeasure(component, event, worksheetBundleLine);
        }
        else {
            worksheetBundleLine.Unit_of_Measure__c = null;
        }
        component.set("v.worksheetBundleLine", worksheetBundleLine);
    },
    handleTMChange : function(component, event, helper) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        var relatedInfos = component.get("v.worksheet.RelatedInfos");
        if (!worksheetBundleLine.TM__c) {
            worksheetBundleLine.TM__c = null;
            worksheetBundleLine.TM__r = null;
            worksheetBundleLine.TM_Job_Task__c = null;
            worksheetBundleLine.TM_Job_Task__r = null;
        }
        else {
            for (var i = 0; i < relatedInfos.length; i++) {
                var relatedInfo = relatedInfos[i];
                if (relatedInfo.TM.Id == worksheetBundleLine.TM__c) {
                    worksheetBundleLine.TM__r = {
                        "Id": relatedInfo.TM.Id,
                        "Name": relatedInfo.TM.Name,
                        "Scheduled_Date__c": relatedInfo.TM.Scheduled_Date__c
                    };
                    var jobTask = relatedInfo.TMJobTasks[0]; //there should be at least one job task per TM
                    worksheetBundleLine.TM_Job_Task__c = jobTask.Id;
                    worksheetBundleLine.TM_Job_Task__r = jobTask;
                    break;
                }
            }
        }
        component.set("v.worksheetBundleLine", worksheetBundleLine);
    },
    handleUnitPriceChange : function(component, event, helper) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        helper.calculateLineTotals(worksheetBundleLine);
        component.set("v.worksheetBundleLine", worksheetBundleLine);
    },
    save : function(component, event, helper) {
        if (helper.validate(component)) {
            var callbackFunction = event.getParams().arguments.callbackFunction;
            if (callbackFunction) {
                var worksheet = component.get("v.worksheet");
                var worksheetLines = component.get("v.worksheetLines");
                var createNewBundleLine = component.get("v.createNewBundleLine");
                var worksheetBundleLine = component.get("v.worksheetBundleLine");
                if (createNewBundleLine == true) {
                    worksheet.WorksheetLines.push(worksheetBundleLine);
                }
                else {
                    for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
                        var worksheetLine = worksheet.WorksheetLines[i];
                        if (worksheetLine.Category__c == 'Bundled' && worksheetLine.Line_No__c == worksheetBundleLine.Line_No__c) {
                            Object.assign(worksheetLine, worksheetBundleLine);
                            break;
                        }
                    }
                }

                var mapWorksheetLinesByLineNo = new Map();
                worksheetLines.forEach(function (worksheetLine) {
                    mapWorksheetLinesByLineNo.set(worksheetLine.Line_No__c, worksheetLine);
                });

                for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
                    var worksheetLine = worksheet.WorksheetLines[i];
                    if (worksheetLine.Category__c != 'Bundled') {
                        if (mapWorksheetLinesByLineNo.has(worksheetLine.Line_No__c)) {
                            var worksheetLine2 = mapWorksheetLinesByLineNo.get(worksheetLine.Line_No__c);
                            worksheetLine.Bill_as_Lump_Sum__c = worksheetLine2.Bill_as_Lump_Sum__c;
                            worksheetLine.Bundle_Line__c = worksheetLine2.Bundle_Line__c;
                            worksheetLine.Bundle_Line__r = worksheetLine2.Bundle_Line__r;
                            worksheetLine.Unit_Price__c = worksheetLine2.Unit_Price__c;
                        }
                        worksheetLine.Selected = false; //clear flag
                        worksheetLine.visible = true;
                        helper.calculateLineTotals(worksheetLine);
                    }
                }
                //callbackFunction(worksheet.WorksheetLines);
                callbackFunction(worksheetBundleLine);
            }
        }
    },
    refreshView : function(component, event, helper) {
        var worksheetLines = component.get("v.worksheetLines");
        helper.setLinesVisibility(component, worksheetLines);
        component.set("v.worksheetLines", worksheetLines);
    },
})