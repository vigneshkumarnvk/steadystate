({
    doInit : function(component, event, helper) {
      
        helper.showFields(component);
        var worksheetLine = component.get("v.worksheetLine");
        // Fetch valid UOMs based on the Bill Unit Code
        
         helper.getValidUOMs(component, worksheetLine.EQAI_Bill_Unit_Code__c, function(uomList) {
                console.log('uomList+++++++++++++++++', uomList); 
                if (uomList.length === 1) {
                    console.log('Single UOM:', uomList[0]);                   
                    component.set("v.uomItems", "'" + uomList[0] + "'");  
                   
                } else if (uomList.length > 1) {
                    let formattedValue = uomList.map(uom => "'" + uom + "'").join(",");
                    component.set("v.uomItems", formattedValue); 
                    console.log("Multiple UOMs available:", formattedValue);
                }
            });
		
        //ticket 20143 << move to the showFields function
        return; // need to rollback 20143 changes below when deploy to production!!!
        //ticket 20143 >>

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
        if (worksheetLine.Category__c == 'Subcontractors'){
            unitCostField.disabled = false;
        } else if (worksheetLine.Category__c == 'Waste Disposal' && worksheetLine.System_Calculated_Line__c != true) {
            //ticket 19873 <<
            /*
            if (worksheetLine.Unit_Cost__c == null || worksheetLine.Unit_Cost__c == 0) {
                unitCostField.disabled = false;
            }
            */
            //ticket 20143 <<
            /*
            if (!worksheetLine.Costing_Source__c || (worksheetLine.Costing_Source__c && worksheetLine.Costing_Source__c.includes('Order-') != true)) {
                unitCostField.disabled = false;
            }
            */
            if ((worksheetLine.Resource__r && (worksheetLine.Resource__r.Name == 'WD' || worksheetLine.Resource__r.Name == 'Manifest Fee')) || !worksheetLine.Costing_Source__c || (worksheetLine.Costing_Source__c && worksheetLine.Costing_Source__c.includes('Order-') != true)) {
                unitCostField.disabled = false;
            }
            //ticket 20143 >>
            //ticket 19873 >>
        } else {
            if(worksheetLine.Resource__r && worksheetLine.Resource__r.Allow_Manual_Unit_Cost_Adjustment__c === true){
                unitCostField.disabled = false;
            }
        }
       
        
        component.set("v.unitCostField", unitCostField);
      
        
    },
    handleWorksheetLineChange : function(component, event, helper) {
        helper.showFields(component);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleTMChange : function(component, event, helper) {
        //TM lookup <<
        /*
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
                    //var jobTask = relatedInfo.TMJobTasks[0]; //there should be at least one job task per TM
                    var jobTask = relatedInfo.TMJobTask;
                    worksheetLine.TM_Job_Task__c = jobTask.Id;
                    worksheetLine.TM_Job_Task__r = jobTask;
                    break;
                }
            }
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event, "TM__c");
        }
        */
        var record = event.getParam("record");
        var worksheetLine = component.get("v.worksheetLine");
        if (record) {
            worksheetLine.TM__c = record.Id;
            worksheetLine.TM__r = {
                "Id": record.Id,
                "Name": record.Name,
                "Scheduled_Date__c": record.Scheduled_Date__c,
            };
            worksheetLine.TM_Job_Task__c = record.TM_Job_Task__c;
            worksheetLine.TM_Job_Task__r = record.TM_Job_Task__r;
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event, "TM__c");
        }
        else {
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
        //TM lookup >>
    },
    handleCategoryChange : function(component, event, helper) {
        var setupData = component.get("v.setupData");

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
        newWorksheetLine.Disposal_Billing_Method__c = null;
        newWorksheetLine.Approval_Id__c = null;
        //ticket 19130 <<
        /*
        newWorksheetLine.Parent_Line__c = null;
        newWorksheetLine.Parent_Line__r = null;
        */
        //ticket 19130 >>
        newWorksheetLine.Bundle_Line__c = null;
        newWorksheetLine.Bundle_Line__r = null;

        newWorksheetLine.Service_Center__c = null;
        newWorksheetLine.Service_Center__r = null;
        newWorksheetLine.Quote_Line__c = null;
        newWorksheetLine.Sales_Line__c = null;
        if (newWorksheetLine.Category__c == 'Labor' || newWorksheetLine.Category__c == 'Equipment') {
            if (setupData.TempServiceCenter) {
                newWorksheetLine.Service_Center__c = setupData.TempServiceCenter.Id;
                newWorksheetLine.Service_Center__r = setupData.TempServiceCenter;
            }
        }

        Object.assign(worksheetLine, newWorksheetLine);

        //ticket 20143 << move to the showFields function
        /*
        if(worksheetLine.Category__c == 'Subcontractors'){
            component.set("v.unitCostField", false);
        }
        */
        //ticket 20143 >>
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

        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;

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
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        //worksheetLine.Facility__c = null;
        //worksheetLine.Facility__r = null;
        //US137007
        //worksheetLine.Profile_Id__c = null;
        //worksheetLine.Approval_Id__c = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
		worksheetLine.Unit_of_Measure__c = null;
        worksheetLine.Unit_of_Measure__r = null;
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
                if(worksheetLine.Profile_Id__c == null){
                    worksheetLine.Description__c = record.Description__c;
                }
                worksheetLine.Service_Center__c = null;
                worksheetLine.Service_Center__r = null;
            }

            if (record.Unit_of_Measure__c && record.Approval_id__c == null) {
                worksheetLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
                worksheetLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
            worksheetLine.Wizard_Question_Answered__c = false;
            helper.validateResource(component, event, worksheetLine);
        }
        else {
            worksheetLine.Resource__c = null;
            worksheetLine.Resource_Name__c = null;
            if(worksheetLine.Profile_Id__c == null){
                worksheetLine.Description__c = null;
            }
            component.set("v.worksheetLine", worksheetLine);
            helper.showFields(component);
            helper.fireWorksheetLineUpdateEvent(component, event, 'Resource__c');
        }
    },
    handleTaxGroupChange : function(component, event, helper) {
        console.log('********a***********');
        var worksheetLine = component.get("v.worksheetLine");
        helper.validateTaxGroup(component, event, worksheetLine);
    },
    handleUnitOfMeasureChange1 : function(component, event, helper) {
        var record = event.getParam("record");
        var worksheetLine = component.get("v.worksheetLine");        
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
       
        if (record) {
          
            worksheetLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
            worksheetLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            //alert(worksheetLine.Unit_of_Measure__c);
            //ticket 19819 <<
            if ((worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') && worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                worksheetLine.Quantity__c = 1;
            }
            //ticket 19819 >>
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
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
        if (record) {
            worksheetLine.Unit_of_Measure__c = record.Id;
            worksheetLine.Unit_of_Measure__r = record;
            //ticket 19819 <<
            if ((worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') && worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                worksheetLine.Quantity__c = 1;
            }
            //ticket 19819 >>
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
        var unitPrice = worksheetLine.Unit_Price__c;
        var xunitPrice = worksheetLine.xUnit_Price__c;
        component.set("v.prvUnitPrice",unitPrice);
        component.set("v.prvxUnitPrice",xunitPrice);
        //Ticket#20286 >>
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Quote_Line__r = null;
        worksheetLine.Sales_Line__c = null;
        worksheetLine.Sales_Line__r = null;
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;     
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
		//Ticket#20286 <<
    },
    handlexUnitPriceChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        if (worksheetLine.Category__c == 'Subcontractors') {
            worksheetLine.Unit_Cost__c = worksheetLine.xUnit_Price__c;
            worksheetLine.xUnit_Cost__c = worksheetLine.xUnit_Price__c;
        }
        var unitPrice = worksheetLine.Unit_Price__c;
        var xunitPrice = worksheetLine.xUnit_Price__c;
        component.set("v.prvUnitPrice",unitPrice);
        component.set("v.prvxUnitPrice",xunitPrice);
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleUnitCostChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.xUnit_Cost__c = worksheetLine.Unit_Cost__c;

        if(worksheetLine.Category__c === 'Subcontractors') {
            console.log('inside subcontractors');
            var markup = (worksheetLine.Markup__c ? parseFloat(worksheetLine.Markup__c) : 0);
            var unitCost = (worksheetLine.Unit_Cost__c ? parseFloat(worksheetLine.Unit_Cost__c) : 0);
            if (worksheetLine.Bill_as_Lump_Sum__c === true) {
                unitCost = (worksheetLine.xUnit_Cost__c ? parseFloat(worksheetLine.xUnit_Cost__c) : 0);
            }
            var unitPrice = unitCost;
            console.log('unitPrice',unitPrice);
            if (worksheetLine.Markup_Option__c === '%') {
                console.log('worksheetLine.Markup_Option__c',worksheetLine.Markup_Option__c);
                unitPrice = unitCost + Math.round(unitCost * markup) / 100;
                console.log('unitPrice after calculating',unitPrice);
            } else if (worksheetLine.Markup_Option__c === 'Amount') {
                unitPrice = unitCost + markup;
            }
            if (worksheetLine.Bill_as_Lump_Sum__c === true) {
                worksheetLine.xUnit_Price__c = unitPrice;
            } else {
                worksheetLine.Unit_Price__c = unitPrice;
                //ticket 20799 <<
                worksheetLine.xUnit_Price__c = unitPrice;
                //ticket 20799>>
            }
            worksheetLine.Costing_Source__c = null;
            worksheetLine.Pricing_Source_2__c = null;
            worksheetLine.Sales_Line__c = null;
            worksheetLine.Quote_Line__c = null;
        }

        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handlexUnitCostChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");

        if(worksheetLine.Category__c === 'Subcontractors') {
            var markup = (worksheetLine.Markup__c ? parseFloat(worksheetLine.Markup__c) : 0);
            var unitCost = (worksheetLine.Unit_Cost__c ? parseFloat(worksheetLine.Unit_Cost__c) : 0);
            if (worksheetLine.Bill_as_Lump_Sum__c === true) {
                unitCost = (worksheetLine.xUnit_Cost__c ? parseFloat(worksheetLine.xUnit_Cost__c) : 0);
            }
           // unitCost = (worksheetLine.Unit_Cost__c ? parseFloat(worksheetLine.Unit_Cost__c) : 0);
            var unitPrice = unitCost;
            if (worksheetLine.Markup_Option__c === '%') {
                unitPrice = unitCost + Math.round(unitCost * markup) / 100;
            } else if (worksheetLine.Markup_Option__c === 'Amount') {
                unitPrice = unitCost + markup;
            }
            if (worksheetLine.Bill_as_Lump_Sum__c === true) {
                worksheetLine.xUnit_Price__c = unitPrice;
            } else {
                worksheetLine.Unit_Price__c = unitPrice;
                //ticket 20799 <<
                worksheetLine.xUnit_Price__c = unitPrice;
                //ticket 20799>>
            }

            worksheetLine.Costing_Source__c = null;
            worksheetLine.Pricing_Source_2__c = null;
            worksheetLine.Sales_Line__c = null;
            worksheetLine.Quote_Line__c = null;
        }

        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleMarkupChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        console.log('handle markup change');
        if(worksheetLine.Category__c === 'Subcontractors') {
            var markup = (worksheetLine.Markup__c ? parseFloat(worksheetLine.Markup__c) : 0);
            var unitCost = (worksheetLine.Unit_Cost__c ? parseFloat(worksheetLine.Unit_Cost__c) : 0);
            
            if (worksheetLine.Bill_as_Lump_Sum__c === true) {
                unitCost = (worksheetLine.xUnit_Cost__c ? parseFloat(worksheetLine.xUnit_Cost__c) : 0);
                
            }
            //unitCost = (worksheetLine.Unit_Cost__c ? parseFloat(worksheetLine.Unit_Cost__c) : 0);
            var unitPrice = unitCost;
            if (worksheetLine.Markup_Option__c === '%') {
                 console.log('Markup %');
                unitPrice = unitCost + Math.round(unitCost * markup) / 100;
            } else if (worksheetLine.Markup_Option__c === 'Amount') {
                console.log('Markup amount');
                unitPrice = unitCost + markup;
              
            }
            if (worksheetLine.Bill_as_Lump_Sum__c === true) {
                worksheetLine.xUnit_Price__c = unitPrice;
            } else {
                worksheetLine.Unit_Price__c = unitPrice;
                //ticket 20799 <<
                worksheetLine.xUnit_Price__c = unitPrice;
                //ticket 20799>>
            }

            worksheetLine.Costing_Source__c = null;
            worksheetLine.Pricing_Source_2__c = null;
            worksheetLine.Sales_Line__c = null;
            worksheetLine.Quote_Line__c = null;
        }
        
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleMarkupOptionChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        console.log('handle markup option');
        if(worksheetLine.Category__c === 'Subcontractors') {
            var markup = (worksheetLine.Markup__c ? parseFloat(worksheetLine.Markup__c) : 0);
            var unitCost = (worksheetLine.Unit_Cost__c ? parseFloat(worksheetLine.Unit_Cost__c) : 0);
            if (worksheetLine.Bill_as_Lump_Sum__c === true) {
                unitCost = (worksheetLine.xUnit_Cost__c ? parseFloat(worksheetLine.xUnit_Cost__c) : 0);
            }
          //  var unitCost = (worksheetLine.Unit_Cost__c ? parseFloat(worksheetLine.Unit_Cost__c) : 0);
            var unitPrice = unitCost;
            if (worksheetLine.Markup_Option__c === '%') {
                console.log('handle markup %');
                unitPrice = unitCost + Math.round(unitCost * markup) / 100;
                console.log('handle markup %'+unitPrice);
            } else if (worksheetLine.Markup_Option__c === 'Amount') {
                console.log('handle markup amount');
                unitPrice = unitCost + markup;
                console.log('handle markup amount'+unitPrice);
            }
            if (worksheetLine.Bill_as_Lump_Sum__c === true) {
                worksheetLine.xUnit_Price__c = unitPrice;
            } else {
                worksheetLine.Unit_Price__c = unitPrice;
                //ticket 20799 <<
                worksheetLine.xUnit_Price__c = unitPrice;
                //ticket 20799>>
            }

            worksheetLine.Costing_Source__c = null;
            worksheetLine.Pricing_Source_2__c = null;
            worksheetLine.Sales_Line__c = null;
            worksheetLine.Quote_Line__c = null;
        }

        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleRegularRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        worksheetLine.xRegular_Rate__c = worksheetLine.Regular_Rate__c;
        //ticket 20281 <<
        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c != true) {
            worksheetLine.Unit_Price__c = worksheetLine.Regular_Rate__c;
            worksheetLine.xUnit_Price__c = worksheetLine.Regular_Rate__c;
        }
        //ticket 20281 >>
        //Ticket#20286 >>
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Quote_Line__r = null;
        worksheetLine.Sales_Line__c = null;
        worksheetLine.Sales_Line__r = null;
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;        
        //Ticket#20286 <<
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handlexRegularRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        //ticket 20281 <<
        worksheetLine.Regular_Rate__c = worksheetLine.xRegular_Rate__c;
        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c != true) {
            worksheetLine.xUnit_Price__c = worksheetLine.xRegular_Rate__c;
        }
        //ticket 20281 >>
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleOvertimeRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        worksheetLine.xOvertime_Rate__c = worksheetLine.Overtime_Rate__c;
        //Ticket#20286 >>
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Quote_Line__r = null;
        worksheetLine.Sales_Line__c = null;
        worksheetLine.Sales_Line__r = null;
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;        
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handlexOvertimeRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        //ticket 20281 <<
        worksheetLine.Overtime_Rate__c = worksheetLine.xOvertime_Rate__c;
        //ticket 20281 >>
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
    },
    handleDoubleTimeRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        worksheetLine.xPremium_Rate__c = worksheetLine.Premium_Rate__c;
        //Ticket#20286 >>
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Quote_Line__r = null;
        worksheetLine.Sales_Line__c = null;
        worksheetLine.Sales_Line__r = null;
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;        
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handlexDoubleTimeRateChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        worksheetLine.Pricing_Source_2__c = null;
        //ticket 20281 <<
        worksheetLine.Premium_Rate__c = worksheetLine.xPremium_Rate__c;
        //ticket 20281 >>
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleRegularHoursChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleOvertimeHoursChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        helper.calculateLineTotals(worksheetLine);
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleDoubleTimeHoursChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
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
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
        component.set("v.worksheetLine", worksheetLine);
        helper.showFields(component);
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
    handleUnitWeightVolumeChange1 : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
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
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
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
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
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
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
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
        worksheetLine.Contract_Line__c = null;
        worksheetLine.Contract_Line__r = null;
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
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
        //Ticket#24917 >>
        //worksheetLine.Contract_Line__c = null;
        //worksheetLine.Contract_Line__r = null;
        //Ticket#24917 <<
        worksheetLine.Quote_Line__c = null;
        worksheetLine.Sales_Line__c = null;
        worksheetLine.Unit_of_Measure__c = null;
        worksheetLine.Unit_of_Measure__r = null;
        worksheetLine.Approval_Id__c = null;
       
        if (record) {
            worksheetLine.Facility__c = record.Id;
            worksheetLine.Facility__r = record;
            helper.calculatePriceAndCost(component, event, worksheetLine);
        }
        else {
            worksheetLine.Facility__c  = null;
            worksheetLine.Facility__r  = null;
            //ticket 20143 <<
            /*
            component.set("v.worksheetLine", worksheetLine);
            helper.fireWorksheetLineUpdateEvent(component, event);
            */
            helper.calculatePriceAndCost(component, event, worksheetLine);
            //ticket 20143 >>
        }
    },
    //Ticket#19511
    handleContractLineChange : function(component, event, helper) {
        var worksheetLine = component.get("v.worksheetLine");
        var record = event.getParam("record");
        if (record) {

            worksheetLine.Contract_Line__c = record.Id;
            if(worksheetLine.Approval_Id__c == null)
            {
               worksheetLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
               worksheetLine.Unit_of_Measure__r = record.Unit_of_Measure__r; 
            }
            

            worksheetLine.Unit_Price__c = record.Regular_Rate__c;
            worksheetLine.xUnit_Price__c = worksheetLine.Unit_Price__c;
            worksheetLine.Contract_Regular_Rate__c = record.Regular_Rate__c;
            worksheetLine.Contract_Overtime_Rate__c = record.Overtime_Rate__c;
            worksheetLine.Contract_Premium_Rate__c = record.Premium_Rate__c;

            worksheetLine.Regular_Rate__c = record.Regular_Rate__c;
            worksheetLine.Overtime_Rate__c = record.Overtime_Rate__c;
            worksheetLine.Premium_Rate__c = record.Premium_Rate__c;

            worksheetLine.xRegular_Rate__c = worksheetLine.Regular_Rate__c;
            worksheetLine.xOvertime_Rate__c = worksheetLine.Overtime_Rate__c;
            worksheetLine.xPremium_Rate__c = worksheetLine.Premium_Rate__c;

            /* this will be set by server call
            if (record.Customer_Description__c != null) {
                worksheetLine.Description__c = record.Customer_Description__c;
            }
             */

            //Ticket#19445
            if(worksheetLine.Category__c === 'Waste Disposal'){
                worksheetLine.Facility__c = record.Facility__c;
                worksheetLine.Facility__r = record.Facility__r;
            }
        }
        else {
            worksheetLine.Contract_Line__c = null;
            worksheetLine.Unit_Price__c = worksheetLine.xUnit_Price__c;
            worksheetLine.Regular_Rate__c = worksheetLine.xRegular_Rate__c;
            worksheetLine.Overtime_Rate__c = worksheetLine.xOvertime_Rate__c;
            worksheetLine.Premium_Rate__c = worksheetLine.xPremium_Rate__c;
        }

        component.set("v.worksheetLine", worksheetLine);
        helper.validateContractLine(component, event, worksheetLine);
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
    },
    handleApprovalChange : function(component, event, helper) {
        var record = event.getParam("record");
        var worksheetLine = component.get("v.worksheetLine");
        if (record) {
            worksheetLine.Profile_Id__c  = record.ProfileID;
            worksheetLine.Approval_Id__c = record.Approval;
            worksheetLine.Description__c = record.Description;
            worksheetLine.EQAI_Bill_Unit_Code__c = record.UOM;
            worksheetLine.Unit_of_Measure__c = null;
            worksheetLine.Unit_of_Measure__r = null;//US129137
         	helper.getValidUOMs(component, record.UOM, function(uomList) {
                if (uomList.length === 1) {
                    console.log('Single UOM:', uomList[0]);                   
                    component.set("v.uomItems", "'" + uomList[0] + "'");  
                   
                } else if (uomList.length > 1) {
                    let formattedValue = uomList.map(uom => "'" + uom + "'").join(",");
                    component.set("v.uomItems", formattedValue); 
                    console.log("Multiple UOMs available:", formattedValue);
                }
            });
        } else {
            worksheetLine.Profile_Id__c  = null;
            worksheetLine.Approval_Id__c = null;
            worksheetLine.Description__c = null; 
            worksheetLine.EQAI_Bill_Unit_Code__c = null;
            worksheetLine.Unit_of_Measure__c = null;
            worksheetLine.Unit_of_Measure__r = null;//US129137
            console.log('worksheetLine.EQAI_Bill_Unit_Code__c',worksheetLine.EQAI_Bill_Unit_Code__c)
        }
        component.set("v.worksheetLine", worksheetLine);
        helper.fireWorksheetLineUpdateEvent(component, event);

    },
    handleBillingMethodChange : function(component, event, helper) {
      
        var worksheetLine = component.get("v.worksheetLine");
        var unitPrice;
        var xunitPrice;
        unitPrice = worksheetLine.Unit_Price__c;
        xunitPrice = worksheetLine.xUnit_Price__c;
        if(worksheetLine.Disposal_Billing_Method__c == 'Direct')
        {
           
            if(unitPrice != null && unitPrice!=0)
                component.set("v.prvUnitPrice", unitPrice); 
            if(xunitPrice != null && xunitPrice!=0)
                component.set("v.prvxUnitPrice", xunitPrice);
            component.set("v.worksheetLine.Unit_Price__c", 0);
            component.set("v.worksheetLine.xUnit_Price__c", 0);
        }
        else
        {
            let prvUnitPrice = component.get("v.prvUnitPrice");
            let prvxUnitPrice = component.get("v.prvxUnitPrice");
            if(prvUnitPrice!=null && prvUnitPrice!=0 )              
                component.set("v.worksheetLine.Unit_Price__c", prvUnitPrice); 
            else if(unitPrice != null && unitPrice!=0)
                component.set("v.worksheetLine.Unit_Price__c", unitPrice); 
            if(prvxUnitPrice!=null && prvxUnitPrice!=0 )              
                component.set("v.worksheetLine.xUnit_Price__c", prvxUnitPrice); 
            else if(xunitPrice != null && xunitPrice!=0)
                component.set("v.worksheetLine.xUnit_Price__c", prvxUnitPrice); 
        }
       
        helper.fireWorksheetLineUpdateEvent(component, event);
    },
   

});