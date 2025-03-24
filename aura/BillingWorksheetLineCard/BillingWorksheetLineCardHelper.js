({
    getBundleLines : function(component, event) {
        var worksheet = component.get("v.worksheet");
        var params = { "salesOrderJobTaskId": worksheet.SalesOrderJobTask.Id };
        this.callServerMethod(component, event, "c.getBundleLines", params, function(response) {
            var salesLines = JSON.parse(response);
            component.set("v.bundleLines", salesLines);
        });
    },
    createNewWorksheetBundleLine : function(component, event) {
        var salesOrderId = component.get("v.salesOrderId");
        var worksheet = component.get("v.worksheet");
        var nextWorksheetLineNo = component.get("v.nextWorksheetLineNo");

        var worksheetBundleLine = {};
        worksheetBundleLine.Line_No__c = nextWorksheetLineNo;
        worksheetBundleLine.Category__c = 'Bundled';
        worksheetBundleLine.Sales_Order_Job_Task__c = worksheet.SalesOrderJobTask.Id;
        worksheetBundleLine.Sales_Order_Job_Task__r = worksheet.SalesOrderJobTask;
        worksheetBundleLine.Sales_Order__c = salesOrderId;
        worksheetBundleLine.Sales_Order__r = { "Id": salesOrderId };

        if (worksheet.RelatedInfos && worksheet.RelatedInfos.length == 1) {
            var relatedInfo = worksheet.RelatedInfos[0];
            worksheetBundleLine.TM__r = {
                "Id": relatedInfo.TM.Id,
                "Name": relatedInfo.TM.Name,
                "Scheduled_Date__c": relatedInfo.TM.Scheduled_Date__c
            };
            //var jobTask = relatedInfo.TMJobTasks[0]; //there should be at least one job task per TM
            var jobTask = relatedInfo.TMJobTask;
            worksheetBundleLine.TM_Job_Task__c = jobTask.Id;
            worksheetBundleLine.TM_Job_Task__r = jobTask;
        }
        component.set("v.worksheetBundleLine", worksheetBundleLine);
        this.displayBundledLines(component, worksheetBundleLine);
    },
    createWorksheetBundleLine : function(component, event, salesBundleLine) {
        var worksheet = component.get("v.worksheet");
        var nextWorksheetLineNo = component.get("v.nextWorksheetLineNo");

        var worksheetBundleLine = {};
        worksheetBundleLine.Line_No__c = nextWorksheetLineNo;
        worksheetBundleLine.Category__c = salesBundleLine.Category__c;
        worksheetBundleLine.Resource_Type__c = salesBundleLine.Resource_Type__c;
        worksheetBundleLine.Resource_Type__r = salesBundleLine.Resource_Type__r;
        worksheetBundleLine.Resource_Type_UOM__c = salesBundleLine.Resource_Type_UOM__c;
        worksheetBundleLine.Resource_Type_UOM__r = salesBundleLine.Resource_Type_UOM__r;
        worksheetBundleLine.Unit_of_Measure__c = salesBundleLine.Unit_of_Measure__c;
        worksheetBundleLine.Unit_of_Measure__r = salesBundleLine.Unit_of_Measure__r;
        worksheetBundleLine.Description__c = salesBundleLine.Description__c;
        worksheetBundleLine.Quantity__c = salesBundleLine.Quantity__c;
        worksheetBundleLine.Unit_Price__c = salesBundleLine.Unit_Price__c;
        worksheetBundleLine.xUnit_Price__c = salesBundleLine.xUnit_Price__c;
        worksheetBundleLine.Bundle_Pricing_Method__c = salesBundleLine.Bundle_Pricing_Method__c;
        worksheetBundleLine.Unit_Cost__c = 0;
        worksheetBundleLine.xUnit_Cost__c = 0;
        worksheetBundleLine.Line_Amount__c = salesBundleLine.Line_Amount__c;
        worksheetBundleLine.Line_Amt_Incl_Tax__c = salesBundleLine.Line_Amt_Incl_Tax__c;
        worksheetBundleLine.xLine_Amount__c = salesBundleLine.xLine_Amount__c;
        worksheetBundleLine.Line_Cost__c = 0;
        worksheetBundleLine.xLine_Cost__c = 0;
        worksheetBundleLine.Tax_Group__c = salesBundleLine.Tax_Group__c;
        worksheetBundleLine.Tax_Pct__c = salesBundleLine.Tax_Pct__c;
        worksheetBundleLine.Tax__c = salesBundleLine.Tax__c;
        worksheetBundleLine.Sales_Line__c = salesBundleLine.Id;
        worksheetBundleLine.Quote_Line__c = salesBundleLine.Quote_Line__c;
        worksheetBundleLine.Contract_Line__c = salesBundleLine.Contract_Line__c;
        worksheetBundleLine.Contract_Line__r = salesBundleLine.Contract_Line__r;
        worksheetBundleLine.Pricing_Source_2__c = salesBundleLine.Pricing_Source_2__c;
        worksheetBundleLine.Sales_Order_Job_Task__c = salesBundleLine.Sales_Order_Job_Task__c;
        worksheetBundleLine.Sales_Order_Job_Task__r = salesBundleLine.Sales_Order_Job_Task__r;
        worksheetBundleLine.Sales_Order__c = salesBundleLine.Sales_Order__c;
        worksheetBundleLine.Sales_Order__r = salesBundleLine.Sales_Order__r;
        worksheetBundleLine.Sales_Bundle_Line__c = salesBundleLine.Id;

        if (worksheet.RelatedInfos && worksheet.RelatedInfos.length == 1) {
            var relatedInfo = worksheet.RelatedInfos[0];
            worksheetBundleLine.TM__r = {
                "Id": relatedInfo.TM.Id,
                "Name": relatedInfo.TM.Name,
                "Scheduled_Date__c": relatedInfo.TM.Scheduled_Date__c
            };
            //var jobTask = relatedInfo.TMJobTasks[0]; //there should be at least one job task per TM
            var jobTask = relatedInfo.TMJobTask;
            worksheetBundleLine.TM_Job_Task__c = jobTask.Id;
            worksheetBundleLine.TM_Job_Task__r = jobTask;
        }
        component.set("v.worksheetBundleLine", worksheetBundleLine);
        this.displayBundledLines(component, worksheetBundleLine);
    },
    validateResourceType : function(component, event, worksheetBundleLine) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetBundleLine) };
        this.callServerMethod(component, event, "c.validateResourceType", params, function(response) {
            var worksheetLine = JSON.parse(response);
            this.calculateLineTotals(worksheetLine);
            component.set("v.worksheetBundleLine", worksheetLine);
        });
    },
    validateResource : function(component, event, worksheetBundleLine) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetBundleLine) };
        this.callServerMethod(component, event, "c.validateResource", params, function(response) {
            var worksheetLine = JSON.parse(response);
            this.calculateLineTotals(worksheetLine);
            component.set("v.worksheetBundleLine", worksheetLine);
        });
    },
    calculatePriceAndCost : function(component, event, worksheetBundleLine) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetBundleLine) };
        this.callServerMethod(component, event, "c.calculatePriceAndCost", params, function(response) {
            var worksheetLine = JSON.parse(response);
            this.calculateLineTotals(worksheetLine);
            component.set("v.worksheetBundleLine", worksheetLine);
        });
    },
    validateTaxGroup : function(component, event, worksheetBundleLine) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetBundleLine) };
        this.callServerMethod(component, event, "c.validateTaxGroup", params, function(response) {
            var worksheetBundleLine = JSON.parse(response);
            this.calculateLineTotals(worksheetBundleLine);
            component.set("v.worksheetBundleLine", worksheetBundleLine);
        });
    },
    displayBundledLines : function(component, worksheetBundleLine) {
        var worksheet = component.get("v.worksheet");
        var worksheetLines = [];
        var showBundledLinesOnly = false;
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = JSON.parse(JSON.stringify(worksheet.WorksheetLines[i]));
            if (worksheetLine.Bundle_Line__r && worksheetLine.Bundle_Line__r.Line_No__c == worksheetBundleLine.Line_No__c) {
                worksheetLine.Selected = true;
                worksheetLines.push(worksheetLine);
                showBundledLinesOnly = true;
            } else if (!worksheetLine.Bundle_Line__r) { //don't allow bundle lines that are bundled already by another bundle line
                worksheetLines.push(worksheetLine);
            }
        }
        component.set("v.showBundledLinesOnly", showBundledLinesOnly);
        component.set("v.worksheetLines", worksheetLines);
        this.setLinesVisibility(component, worksheetLines);
    },
    setLinesVisibility : function(component, worksheetLines) {
        var showBundledLinesOnly = component.get("v.showBundledLinesOnly");
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        var setupData = component.get("v.setupData");
        var defaultManifestFeeResourceId = setupData.CompanySetup.Default_Manifest_Fee_Resource__c;

        for (var i = 0; i < worksheetLines.length; i++) {
            var worksheetLine = worksheetLines[i];
            worksheetLine.visible = false;

            if ((worksheetLine.Category__c != 'Bundled' && worksheetLine.System_Calculated_Line__c != true) || worksheetLine.Resource__c == defaultManifestFeeResourceId) {
                if (worksheetLine.Bundle_Line__r && worksheetLine.Bundle_Line__r.Line_No__c == worksheetBundleLine.Line_No__c) {
                    worksheetLine.visible = true;
                }

                if (!showBundledLinesOnly) {
                    if (!worksheetLine.Bundle_Line__r) { //lines not bundled
                        worksheetLine.visible = true;
                    }
                }
            }
        }
    },
    handleLineSelect : function(component, rowIndex) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        var worksheetLines = component.get("v.worksheetLines");
        var worksheetLine = worksheetLines[rowIndex];

        this.updateWorksheetLine(component, worksheetLine);
        component.set("v.worksheetLines[" + rowIndex + "]", worksheetLine);

        this.rollupBundle(worksheetBundleLine, worksheetLines, true);
        component.set("v.worksheetBundleLine", worksheetBundleLine);

        this.setLinesVisibility(component, worksheetLines);
        component.set("v.worksheetLines", worksheetLines);
    },
    handleSelectAll : function(component, event) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        var worksheetLines = component.get("v.worksheetLines");
        for (var i = 0; i < worksheetLines.length; i++) {
            var worksheetLine = worksheetLines[i];
            this.updateWorksheetLine(component, worksheetLine); //calculate line totals
        };
        this.rollupBundle(worksheetBundleLine, worksheetLines, true); //roll up
        component.set("v.worksheetBundleLine", worksheetBundleLine);

        this.setLinesVisibility(component, worksheetLines);
        component.set("v.worksheetLines", worksheetLines);
    },
    updateWorksheetLine : function(component, worksheetLine) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        if (worksheetLine.Selected == true) {
            worksheetLine.Bill_as_Lump_Sum__c = true;
            //worksheetLine.Unit_Cost__c = 0;
            worksheetLine.Unit_Price__c = 0;
            worksheetLine.Line_Amount__c = 0;
            //worksheetLine.Line_Cost__c = 0;
            worksheetLine.Bundle_Line__c = worksheetBundleLine.Id;
            worksheetLine.Bundle_Line__r = { "Id": worksheetBundleLine.Id, "Name": worksheetBundleLine.Name, "Line_No__c": worksheetBundleLine.Line_No__c };
        }
        else {
            worksheetLine.Bill_as_Lump_Sum__c = false;
            //worksheetLine.Unit_Cost__c = worksheetLine.xUnit_Cost__c;
            worksheetLine.Unit_Price__c = worksheetLine.xUnit_Price__c;
            worksheetLine.Line_Amount__c = worksheetLine.xLine_Amount__c;
            //worksheetLine.Line_Cost__c = worksheetLine.xLine_Cost__c;
            worksheetLine.Bundle_Line__c = null;
            worksheetLine.Bundle_Line__r = null;
        }
        this.calculateLineTotals(worksheetLine);
    },
    validate : function(component) {
        var worksheetBundleLine = component.get("v.worksheetBundleLine");
        if (worksheetBundleLine == null) {
            return false;
        }

        var fields = [];
        fields.push(component.find("resource-type"));
        fields.push(component.find("description"));
        fields.push(component.find("tm"));
        fields.push(component.find("quantity"));
        fields.push(component.find("unit-price"));
        fields.push(component.find("unit-of-measure"));
        //fields.push(component.find("bundle-pricing-method"));
        fields.push(component.find("tax-group"));
        var ok = fields.reduce(function(valid, field) {
            if (Array.isArray(field)) {
                for (var i = 0; i < field.length; i++) {
                    field[i].showHelpMessageIfInvalid();
                    valid = valid && field[i].get("v.validity").valid;
                }
                return valid;
            }
            else {
                field.showHelpMessageIfInvalid();
                valid = valid && field.get("v.validity").valid
                return valid;
            }
        }, true);

        if (ok == true) {
            if (worksheetBundleLine.Unit_Price__c == 0) {
                this.showToast(component, "", "Unit price must not be zero.", "error", "dismissible");
                ok = false;
            }
        }
        return ok;
    },
    showSpinner : function(component) {
        setTimeout(function() {
            var spinner = component.find("loading-spinner");
            $A.util.removeClass(spinner, 'slds-hide');
        }, 1);
    },
    hideSpinner : function(component) {
        setTimeout(function() {
            var spinner = component.find("loading-spinner");
            $A.util.addClass(spinner, 'slds-hide');
        }, 1);
    },
})