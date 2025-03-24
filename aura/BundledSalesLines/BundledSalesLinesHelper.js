({
    setLinesVisibility : function(component, event) {
        //show/hide lines

        //job task <<
        /*
        var showBundledOnly = component.get("v.showBundledOnly");
        var parentSalesLine = component.get("v.parentSalesLine");
        var salesLines = component.get("v.salesLines");
        for (var i = 0; i < salesLines.length; i++) {
            var salesLine = salesLines[i];
            //clean up fields
            if (salesLine.Bill_as_Lump_Sum__c != true && salesLines.Bundle_Line__c != null) {
                salesLine.Bundle_Line__c = ''; //use blank instead of null to void the field gets dropped after passed to apex and returned
                salesLine.Bundle_Line__r = null;
            }

            salesLine.showLine = false;
            salesLine.Checked = false;
            if (salesLine.Category__c != 'Lump Sum' && salesLine.System_Calculated_Line__c != true) {
                if (salesLine.Bundle_Line__r != null && salesLine.Bundle_Line__r.Line_No__c == parentSalesLine.Line_No__c) {
                    salesLine.showLine = true;
                    salesLine.Checked = true;
                }

                if (showBundledOnly != true) {
                    if (salesLine.Bundle_Line__r == null) {
                        salesLine.showLine = true;
                    }
                }
            }
        }
        component.set("v.salesLines", salesLines);
        */
        var salesOrder = component.get("v.salesOrder");
        var showBundledOnly = component.get("v.showBundledOnly");
        var lumpSumLine = component.get("v.lumpSumLine");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        //contract specific resource <<
        /*
        var userInfoWrapper = component.get("v.userInfoWrapper");
        var defaultManifestFeeResourceId = userInfoWrapper.CompanySetup.Default_Manifest_Fee_Resource__c;
        */
        var setupData = component.get("v.setupData");
        var defaultManifestFeeResourceId = setupData.CompanySetup.Default_Manifest_Fee_Resource__c;
        //contract specific resource >>

        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            //clean up fields
            if (jobTaskWrapper.SalesLines[i].Bill_as_Lump_Sum__c != true && jobTaskWrapper.SalesLines[i].Bundle_Line__c != null) {
                jobTaskWrapper.SalesLines[i].Bundle_Line__c = ''; //use blank instead of null to void the field gets dropped after passed to apex and returned
                jobTaskWrapper.SalesLines[i].Bundle_Line__r = null;
            }

            jobTaskWrapper.SalesLines[i].showLine = false;
            jobTaskWrapper.SalesLines[i].Checked = false;
            //if (jobTaskWrapper.SalesLines[i].Category__c != 'Lump Sum' && jobTaskWrapper.SalesLines[i].System_Calculated_Line__c != true) {
            if ((jobTaskWrapper.SalesLines[i].Category__c != 'Bundled' && jobTaskWrapper.SalesLines[i].System_Calculated_Line__c != true) || jobTaskWrapper.SalesLines[i].Resource__c == defaultManifestFeeResourceId) {
                if (jobTaskWrapper.SalesLines[i].Bundle_Line__r != null) {
                    if (jobTaskWrapper.SalesLines[i].Bundle_Line__r.Line_No__c == lumpSumLine.Line_No__c) {
                        jobTaskWrapper.SalesLines[i].showLine = true;
                        jobTaskWrapper.SalesLines[i].Checked = true;
                    }
                }
                else {
                    if (showBundledOnly != true) {
                        jobTaskWrapper.SalesLines[i].showLine = true;
                    }
                }
            }

            //disable if document status is closed or quote is in pending approval status
            if (salesOrder.Document_Status__c == 'Closed' || salesOrder.Approval_Status__c == 'Pending_Approval' || salesOrder.Expired__c == true) {
                jobTaskWrapper.SalesLines[i].disabled = true;
            }
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);

        //job task >>
    },
    selectSalesLine : function(component, event, selectedLine) {
        //job task <<
        /*
        var salesOrder = component.get("v.salesOrder");
        var parentSalesLine = component.get("v.parentSalesLine");
        var salesLines = component.get("v.salesLines");
        for (var i = 0; i < salesLines.length; i++) {
            var salesLine = salesLines[i];
            if (salesLine.Line_No__c == selectedLine.Line_No__c) {
                //if (salesLine.Bill_as_Lump_Sum__c) {
                salesLine.Bill_as_Lump_Sum__c = salesLine.Checked;
                if (salesLine.Checked == true) {
                    salesLine.Bundle_Line__c = parentSalesLine.Id;
                    salesLine.Bundle_Line__r = { "Id": parentSalesLine.Id, "Name": parentSalesLine.Name, "Description__c": parentSalesLine.Description__c, "Line_No__c": parentSalesLine.Line_No__c };
                    salesLine.Bundle_Line_No__c = parentSalesLine.Line_No__c;
                    salesLine.Unit_Cost__c = 0;
                    salesLine.Unit_Price__c = 0;
                    salesLine.Line_Amount__c = 0;
                    salesLine.Line_Cost__c = 0;
                }
                else {
                    salesLine.Bundle_Line__c = '';  //use blank instead of null to void the field gets dropped after passed to apex and returned
                    salesLine.Bundle_Line__r = null;
                    salesLine.Unit_Cost__c = salesLine.xUnit_Cost__c;
                    salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
                    salesLine.Line_Amount__c = salesLine.xLine_Amount__c;
                    salesLine.Line_Cost__c = salesLine.xLine_Cost__c;
                }
                salesLine.Tax__c = 0;
                if (salesLine.Tax_Group__c == 'TX') {
                    salesLine.Tax__c = Math.round(salesLine.Line_Amount__c * salesLine.Tax_Pct__c ) / 100;
                }
                salesLine.Line_Amt_Incl_Tax__c = salesLine.Line_Amount__c + salesLine.Tax__c;
                break;
            }
        }
        component.set("v.salesLines", salesLines);
        var parentSalesLine = this.rollupLumpSumLine(parentSalesLine, salesLines); //call SalesOrderBase.rollupLumSumLine function
        component.set("v.parentSalesLine", parentSalesLine);

        this.setLinesVisibility(component, event);
        */
        var salesOrder = component.get("v.salesOrder");
        var lumpSumLine = component.get("v.lumpSumLine");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");

        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            var salesLine = jobTaskWrapper.SalesLines[i];
            if (salesLine.Line_No__c == selectedLine.Line_No__c) {
                //if (salesLine.Bill_as_Lump_Sum__c) {
                salesLine.Bill_as_Lump_Sum__c = salesLine.Checked;
                if (salesLine.Checked == true) {
                    salesLine.Bundle_Line__c = lumpSumLine.Id;
                    salesLine.Bundle_Line__r = { "Id": lumpSumLine.Id, "Name": lumpSumLine.Name, "Description__c": lumpSumLine.Description__c, "Line_No__c": lumpSumLine.Line_No__c };
                    salesLine.Bundle_Line_No__c = lumpSumLine.Line_No__c;
                    salesLine.Unit_Cost__c = 0;
                    salesLine.Unit_Price__c = 0;
                    salesLine.Line_Amount__c = 0;
                    salesLine.Line_Cost__c = 0;
                }
                else {
                    salesLine.Bundle_Line__c = '';  //use blank instead of null to void the field gets dropped after passed to apex and returned
                    salesLine.Bundle_Line__r = null;
                    salesLine.Unit_Cost__c = salesLine.xUnit_Cost__c;
                    salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
                    salesLine.Line_Amount__c = salesLine.xLine_Amount__c;
                    salesLine.Line_Cost__c = salesLine.xLine_Cost__c;
                }
                salesLine.Tax__c = 0;
                if (salesLine.Tax_Group__c == 'TX') {
                    salesLine.Tax__c = Math.round(salesLine.Line_Amount__c * salesLine.Tax_Pct__c ) / 100;
                }
                salesLine.Line_Amt_Incl_Tax__c = salesLine.Line_Amount__c + salesLine.Tax__c;
                break;
            }
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
        //bundle line pricing method <<
        //var lumpSumLine = this.rollupLumpSumLine(lumpSumLine, jobTaskWrapper.SalesLines); //call SalesOrderBase.rollupLumSumLine function
        var lumpSumLine = this.rollupLumpSumLine(lumpSumLine, jobTaskWrapper.SalesLines, true); //call SalesOrderBase.rollupLumSumLine function
        //bundle line pricing method <<

        component.set("v.lumpSumLine", lumpSumLine);
        this.setLinesVisibility(component, event);
        //job task >>
    }
})