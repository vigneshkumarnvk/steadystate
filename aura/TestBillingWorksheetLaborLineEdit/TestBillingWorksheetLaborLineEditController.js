({
    doInit : function(component, event, helper) {
        helper.showFields(component);

        var unitCostField = { "visible": false, "disabled": true };
        var worksheetLine = component.get("v.worksheetLine");
        /*
        if (worksheetLine.Category__c == 'Waste Disposal' && worksheetLine.System_Calculated_Line__c != true) {
            if (worksheetLine.Bill_as_Lump_Sum__c == true || worksheetLine.Non_Billable__c == true) {
                if (worksheetLine.xUnit_Cost__c == null || worksheetLine.xUnit_Cost__c == 0) {
                    unitCostField.disabled = false;
                }
            }
            else {
                if (worksheetLine.Unit_Cost__c == null || worksheetLine.Unit_Cost__c == 0) {
                    unitCostField.disabled = false;
                }
            }
        }*/
        if (worksheetLine.Category__c == 'Waste Disposal' && worksheetLine.System_Calculated_Line__c != true) {
            if (worksheetLine.Unit_Cost__c == null || worksheetLine.Unit_Cost__c == 0) {
                unitCostField.disabled = false;
            }
        }
        component.set("v.unitCostField", unitCostField);
    },
    handleWorksheetLineChange : function(component, event, helper) {
        //helper.showFields(component);
        //helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleTMChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var relatedInfos = component.get("v.relatedInfos");
        var salesOrderJobTask = component.get("v.salesOrderJobTask");
        if (!worksheetLine.TM__c) {
            worksheetLine.TM__c = null;
            worksheetLine.TM__r = null;
            worksheetLine.TM_Job_Task__c = null;
            worksheetLine.TM_Job_Task__r = null;
            if (worksheetLine.Category__c == 'Labor') {
                helper.calculateBillingHours(component, event, worksheetLine, true);
            }
            else {
                component.set("v.worksheetLine", worksheetLine);
                helper.fireWorksheetLineUpdateEvent(component, event, "TM__c");
            }
        }
        else {
            for (var i = 0; i < relatedInfos.length; i++) {
                var relatedInfo = relatedInfos[i];
                if (relatedInfo.TM.Id == worksheetLine.TM__c) {
                    worksheetLine.TM__r = {
                        "Id": relatedInfo.TM.Id,
                        "Name": relatedInfo.TM.Name,
                        "Scheduled_Date__c": relatedInfo.TM.Scheduled_Date__c
                    };
                    var jobTask = relatedInfo.TMJobTasks[0]; //there should be at least one job task per TM
                    worksheetLine.TM_Job_Task__c = jobTask.Id;
                    worksheetLine.TM_Job_Task__r = jobTask;
                    break;
                }
            }
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event, "TM__c");
        }
    },
    handleCategoryChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var newWorksheetLine = {};
        newWorksheetLine.Id = worksheetLine.Id;
        newWorksheetLine.Line_No__c = worksheetLine.Line_No__c;
        newWorksheetLine.Category__c = worksheetLine.Category__c;
        newWorksheetLine.TM_Job_Task__c = worksheetLine.TM_Job_Task__c;
        newWorksheetLine.TM_Job_Task__r = worksheetLine.TM_Job_Task__r;
        newWorksheetLine.TM__c = worksheetLine.TM__c;
        newWorksheetLine.TM__r = worksheetLine.TM__r;
        newWorksheetLine.Sales_Order__c = worksheetLine.Sales_Order__c;
        newWorksheetLine.Sales_Order_Job_Task__c = worksheetLine.Sales_Order_Job_Task__c;
        newWorksheetLine.Resource_Type__c = null;
        newWorksheetLine.Resource_Type__r = null;
        newWorksheetLine.Resource__c = null;
        newWorksheetLine.Resource__r = null;
        newWorksheetLine.Description__c = null;
        newWorksheetLine.Unit_of_Measure__c = null;
        newWorksheetLine.Unit_of_Measure__r = null;
        newWorksheetLine.Contract_Line__c = null;
        newWorksheetLine.Contract_Line__r = null;
        newWorksheetLine.Unit_Price__c = 0;
        newWorksheetLine.Quantity__c = 0;
        newWorksheetLine.Line_Amount__c = 0;
        newWorksheetLine.Line_Amt_Incl_Tax__c = 0;
        newWorksheetLine.Unit_Cost__c = 0;
        newWorksheetLine.Line_Cost__c = 0;
        newWorksheetLine.Tax__c = 0;
        newWorksheetLine.Tax_Pct__c = 0;
        newWorksheetLine.Pricing_Source_2__c = null;
        newWorksheetLine.Job_Start_Time__c = null;
        newWorksheetLine.Job_End_Time__c =  null;
        newWorksheetLine.Site_Start_Time__c = null;
        newWorksheetLine.Site_End_Time__c = null;
        newWorksheetLine.Lunch_Start_Time__c = null;
        newWorksheetLine.Lunch_End_Time__c = null;
        newWorksheetLine.Include_Lunch_Y_N__c = false;
        newWorksheetLine.Total_Job_Hours__c = null;
        newWorksheetLine.Total_Site_Hours__c = null;
        newWorksheetLine.Billing_Start_Time__c = null;
        newWorksheetLine.Billing_End_Time__c = null;
        newWorksheetLine.Hour__c = 0;
        newWorksheetLine.Bill_as_Lump_Sum__c = false;
        newWorksheetLine.Non_Billable__c = false;
        newWorksheetLine.Cost_Method__c = null;
        newWorksheetLine.Container_Size__c = null;
        newWorksheetLine.Container_Size__r = null;
        newWorksheetLine.Unit_Weight_Vol__c = null;
        newWorksheetLine.Unit_Weight_Vol__r = null;
        newWorksheetLine.BOL_Manifest__c = null;
        newWorksheetLine.Facility__c = null;
        newWorksheetLine.Facility__r = null;
        newWorksheetLine.Parent_Line__c = null;
        newWorksheetLine.Parent_Line__r = null;
        newWorksheetLine.Bundle_Line__c = null;
        newWorksheetLine.Bundle_Line__r = null;

        Object.assign(worksheetLine, newWorksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.showFields(component);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleServiceCenterChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record != null) {
            worksheetLine.Service_Center__c = record.Id;
        }
        else {
            worksheetLine.Service_Center__c = null;
        }
        component.set("v.worksheetLine", worksheetLine);
        helper.showFields(component);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleResourceTypeChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {
            worksheetLine.Resource_Type__c = record.Id;
            worksheetLine.Description__c = record.Name;
            //worksheetLine.Resource__c = null;
            //worksheetLine.Resource__r = null;
            //worksheetLine.Resource_Name__c = null;
            if (record.Unit_of_Measure__r != null) {
                worksheetLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
                worksheetLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
            worksheetLine.Wizard_Question_Answered__c = false;
            helper.validateResourceType(component, event, worksheetLine);
        }
        else {
            worksheetLine.Resource_Type__c = null;
            worksheetLine.Description__c = null;
            //worksheetLine.Resource__c = null;
            //worksheetLine.Resource__r = null;
            //worksheetLine.Resource_Name__c = null;
            worksheetLine.Unit_of_Measure__c = null;
            worksheetLine.Unit_of_Measure__r = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event, "Resource_Type__c");
        }
    },
    handleResourceChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");

        worksheetLine.Cost_Method__c = null;
        worksheetLine.Unit_Weight_Vol__c = null;
        worksheetLine.Unit_Weight_Vol__r = null;
        worksheetLine.Container_Size__c = null;
        worksheetLine.Container_Size__r = null;
        if (record) {
            worksheetLine.Resource__c = record.Id;
            if (worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') {
                worksheetLine.Resource_Name__c = record.Description__c;
                if (record.Service_Center__c != null) {
                    worksheetLine.Service_Center__c = record.Service_Center__c;
                    worksheetLine.Service_Center__r = record.Service_Center__r;
                }
            }
            else {
                worksheetLine.Description__c = record.Description__c;
                worksheetLine.Service_Center__c = null;
                worksheetLine.Service_Center__r = null;
            }

            if (record.Unit_of_Measure__c) {
                worksheetLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
                worksheetLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
            worksheetLine.Wizard_Question_Answered__c = false;
            helper.validateResource(component, event, worksheetLine);
        }
        else {
            worksheetLine.Resource__c = null;
            worksheetLine.Resource_Name__c = null;
            worksheetLine.Description__c = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event, 'Resource__c');
        }
    },
    handleTaxGroupChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        helper.validateTaxGroup(component, event, worksheetLine);
    },
    handleUnitOfMeasureChange1 : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {
            worksheetLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            worksheetLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            helper.calculatePriceAndCost(component, event, worksheetLine);
        }
        else {
            worksheetLine.Unit_of_Measure__c = null;
            worksheetLine.Unit_of_Measure__r = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleUnitOfMeasureChange3 : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {
            worksheetLine.Unit_of_Measure__c = record.Id;
            worksheetLine.Unit_of_Measure__r = record;
            helper.calculatePriceAndCost(component, event, worksheetLine);
        }
        else {
            worksheetLine.Unit_of_Measure__c = null;
            worksheetLine.Unit_of_Measure__r = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleBillSiteTimeChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        if (worksheetLine.Bill_Site_Time__c == true) {
            worksheetLine.Billing_Start_Time__c = worksheetLine.Site_Start_Time__c;
            worksheetLine.Billing_End_Time__c = worksheetLine.Site_End_Time__c;
        }
        else {
            worksheetLine.Billing_Start_Time__c = worksheetLine.Job_Start_Time__c;
            worksheetLine.Billing_End_Time__c = worksheetLine.Job_End_Time__c;
        }

        if ((worksheetLine.Billing_Start_Time__c && worksheetLine.Billing_End_Time__c) || (!worksheetLine.Billing_Start_Time__c && !worksheetLine.Billing_End_Time__c)) {
            helper.calculateBillingHours(component, event, worksheetLine, true);
        }
        else {
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleBillingTimeChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        if ((worksheetLine.Billing_Start_Time__c && worksheetLine.Billing_End_Time__c) || (!worksheetLine.Billing_Start_Time__c && !worksheetLine.Billing_End_Time__c)) {
            helper.calculateBillingHours(component, event, worksheetLine, true);
        }
        else {
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleLunchTimeChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        //both empty or both not empty + start < end
        if ((worksheetLine.Lunch_Start_Time__c && worksheetLine.Lunch_End_Time__c) || (!worksheetLine.Lunch_Start_Time__c && !worksheetLine.Lunch_End_Time__c)) {
            worksheetLine.Total_Job_Hours__c = helper.calculateJobHours(worksheetLine);
            worksheetLine.Total_Site_Hours__c = helper.calculateSiteHours(worksheetLine);
            helper.calculateBillingHours(component, event, worksheetLine, (worksheetLine.Include_Lunch_Y_N__c != true));
        }
        else {
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleJobTimeChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        if ((worksheetLine.Job_Start_Time__c && worksheetLine.Job_End_Time__c) || (!worksheetLine.Job_Start_Time__c && !worksheetLine.Job_End_Time__c)) {
            worksheetLine.Total_Job_Hours__c = helper.calculateJobHours(worksheetLine);
            if (worksheetLine.Bill_Site_Time__c != true) {
                worksheetLine.Billing_Start_Time__c = worksheetLine.Job_Start_Time__c;
                worksheetLine.Billing_End_Time__c = worksheetLine.Job_End_Time__c;
            }
            component.set("v.worksheetLine", worksheetLine);
            helper.calculateBillingHours(component, event, worksheetLine, (worksheetLine.Bill_Site_Time__c != true));
        }
        else {
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleSiteTimeChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        if ((worksheetLine.Site_Start_Time__c && worksheetLine.Site_End_Time__c) || (!worksheetLine.Site_Start_Time__c && !worksheetLine.Site_End_Time__c)) {
            worksheetLine.Total_Site_Hours__c = helper.calculateSiteHours(worksheetLine);
            if (worksheetLine.Bill_Site_Time__c == true) {
                worksheetLine.Billing_Start_Time__c = worksheetLine.Site_Start_Time__c;
                worksheetLine.Billing_End_Time__c = worksheetLine.Site_End_Time__c;
            }
            component.set("v.worksheetLine", worksheetLine);
            helper.calculateBillingHours(component, event, worksheetLine, (worksheetLine.Bill_Site_Time__c == true));
        }
        else {
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleUnitPriceChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.xUnit_Price__c = worksheetLine.Unit_Price__c;
        worksheetLine.Pricing_Source_2__c = null;
        if (worksheetLine.Category__c == 'Subcontractors') {
            worksheetLine.Unit_Cost__c = worksheetLine.Unit_Price__c;
            worksheetLine.xUnit_Cost__c = worksheetLine.Unit_Price__c;
        }

        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handlexUnitPriceChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        if (worksheetLine.Category__c == 'Subcontractors') {
            worksheetLine.xUnit_Cost__c = worksheetLine.xUnit_Price__c;
        }
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleUnitCostChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.xUnit_Cost__c = worksheetLine.Unit_Cost__c;
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handlexUnitCostChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleMarkupChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleMarkupOptionChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleRegularRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        worksheetLine.xRegular_Rate__c = worksheetLine.Regular_Rate__c;
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handlexRegularRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleOvertimeRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        worksheetLine.xOvertime_Rate__c = worksheetLine.Overtime_Rate__c;
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handlexOvertimeRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
    },
    handleDoubleTimeRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        worksheetLine.xPremium_Rate__c = worksheetLine.Premium_Rate__c;
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handlexDoubleTimeRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleQuantityChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleNonBillableChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        if (worksheetLine.Non_Billable__c != true) {
            worksheetLine.Unit_Price__c = worksheetLine.xUnit_Price__c;
            //worksheetLine.Unit_Cost__c = worksheetLine.xUnit_Cost__c;
            worksheetLine.Regular_Rate__c = worksheetLine.xRegular_Rate__c;
            worksheetLine.Overtime_Rate__c = worksheetLine.xOvertime_Rate__c;
            worksheetLine.Premium_Rate__c = worksheetLine.xPremium_Rate__c;
        }
        else {
            worksheetLine.Unit_Price__c = 0;
            worksheetLine.Regular_Rate__c = 0;
            worksheetLine.Overtime_Rate__c = 0;
            worksheetLine.Overtime_Rate__c = 0;

        }
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleBillAsLumpSumChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        if (worksheetLine.Bill_as_Lump_Sum__c != true) {
            //don't unlink Bundle_Line__r yet, handle this in inlineEditClose event to recalculate the lump sum rollup
            worksheetLine.Unit_Price__c = worksheetLine.xUnit_Price__c;
            //worksheetLine.Unit_Cost__c = worksheetLine.xUnit_Cost__c;
            worksheetLine.Regular_Rate__c = worksheetLine.xRegular_Rate__c;
            worksheetLine.Overtime_Rate__c = worksheetLine.xOvertime_Rate__c;
            worksheetLine.Premium_Rate__c = worksheetLine.xPremium_Rate__c;
        }
        else {
            worksheetLine.Regular_Rate__c = 0;
            worksheetLine.Overtime_Rate__c = 0;
            worksheetLine.Overtime_Rate__c = 0;
            worksheetLine.Unit_Price__c = 0;
        }
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleCostMethodChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Resource_UOM__c = null;
        worksheetLine.Resource_UOM__r = null;
        worksheetLine.Unit_Weight_Vol__c = null;
        worksheetLine.Unit_Weight_Vol__r = null;
        worksheetLine.Container_Size__c = null;
        worksheetLine.Container_Size__r = null;
        component.set("v.worksheetLine", worksheetLine);
        helper.showFields(component);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleUnitWeightVolumeChange1 : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {
            worksheetLine.Resource_UOM__c = record.Id;
            worksheetLine.Resource_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                worksheetLine.Unit_Weight_Vol__c = record.Unit_of_Measure__c;
                worksheetLine.Unit_Weight_Vol__r = record.Unit_of_Measure__r;
            }
            worksheetLine.Container_Size__c = null;
            worksheetLine.Container_Size__r = null;
            helper.calculatePriceAndCost(component, event, worksheetLine);
        }
        else {
            worksheetLine.Resource_UOM__c = null;
            worksheetLine.Resource_UOM__r = null;
            worksheetLine.Unit_Weight_Vol__c = null;
            worksheetLine.Unit_Weight_Vol__r = null;
            worksheetLine.Container_Size__c = null;
            worksheetLine.Container_Size__r = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleUnitWeightVolumeChange2 : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {
            worksheetLine.Unit_Weight_Vol__c = record.Unit_of_Measure__c;
            helper.calculatePriceAndCost(component, event, worksheetLine);
        }
        else {
            worksheetLine.Unit_Weight_Vol__c  = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleContainerSizeChange1 : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {
            worksheetLine.Container_Size__c = record.Unit_of_Measure__c;
            worksheetLine.Container_Size__r = record.Unit_of_Measure__r;
            helper.calculatePriceAndCost(component, event, worksheetLine);
        }
        else {
            worksheetLine.Container_Size__c  = null;
            worksheetLine.Container_Size__r  = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleContainerSizeChange3 : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {
            worksheetLine.Container_Size__c = record.Container_Size__c;
            var containerSize = { "Id": record.Container_Size__c, "Name": record.Container_Size__r.Name };
            worksheetLine.Container_Size__r = containerSize;
            helper.calculatePriceAndCost(component, event, worksheetLine);
        }
        else {
            worksheetLine.Container_Size__c  = null;
            worksheetLine.Container_Size__r  = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleContainerSizeChange2 : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {
            worksheetLine.Container_Size__c = record.Id;
            worksheetLine.Container_Size__r = record;
            helper.calculatePriceAndCost(component, event, worksheetLine);
        }
        else {
            worksheetLine.Container_Size__c  = null;
            worksheetLine.Container_Size__r  = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    handleFacilityChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {
            worksheetLine.Facility__c = record.Id;
            worksheetLine.Facility__r = record;
            helper.calculatePriceAndCost(component, event, worksheetLine);
        }
        else {
            worksheetLine.Facility__c  = null;
            worksheetLine.Facility__r  = null;
            component.set("v.worksheetLine", worksheetLine);
            helper.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    viewLine : function(component, event, helper) {
        helper.fireWorksheetLineViewEvent(component, event);
    },
    validateFields : function(component, event, helper) {
        var fields = [];
        var worksheetLine = component.get("v.worksheetLine");
        if (!worksheetLine.TM__c) fields.push('T&M No.');
        if (!worksheetLine.Category__c) fields.push('Category');
        if (worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') {
            if (!worksheetLine.Resource_Type__c) fields.push('Resource Type');
            if (!worksheetLine.Service_Center__c) fields.push('Service Center');
        }
        else {
            if (!worksheetLine.Quantity__c) fields.push('Quantity');
            if (worksheetLine.Category__c == 'Subcontractors') {
                if (!worksheetLine.Resource__c) fields.push('Resource');
            }
        }
        if (!worksheetLine.Description__c) fields.push('Billing Description');

        if (fields.length > 0) {
            helper.showToast(component, "Validation Errors", "You must complete the required fields: " + fields.join(', ') + '.', "error", "dismissible");
            return false;
        }
        return true;
    }
});