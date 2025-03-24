({
    doInit : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var jobTaskWrapperIndex = component.get("v.jobTaskWrapperIndex");
        var setupData = component.get("v.setupData");
        var inlineEditComponentParams = { "salesOrder": salesOrder, "jobTaskWrapper": jobTaskWrapper, "jobTaskWrapperIndex": jobTaskWrapperIndex, "setupData": setupData };
        var rowComponentParams = { "salesOrder": salesOrder, "jobTaskWrapper": jobTaskWrapper, "jobTaskWrapperIndex": jobTaskWrapperIndex, "setupData": setupData };
        component.set("v.rowComponentParams", rowComponentParams);
        component.set("v.inlineEditComponentParams", inlineEditComponentParams);
        helper.calculateTotals(component, event);
    },
    doNewSalesLine : function(component, event, helper) {
        var datatable = component.find("datatable");
        if (datatable) {
            datatable.closeInlineEdit();
        }

        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        helper.addSalesLine(component, event, jobTaskWrapper, false);
    },
    handleMenuSelect : function(component, event, helper) {
        var selectedMenuItemValue = event.getParam("value");
        switch(selectedMenuItemValue) {
            case 'create-lines-from-template':
                helper.createSalesLinesFromTemplate(component, event);
                break;
            case 'edit-job-task':
                helper.editJobTask(component, event);
                break;
            case 'clone-job-task':
                helper.fireCloneJobTaskEvent(component, event);
                break;
            case 'delete-job-task':
                helper.fireDeleteJobTaskEvent(component, event);
                break;
            case 'delete-lines':
                helper.confirmDeleteSalesLines(component, event);
                break;
        }
    },
    //job task <<
    /*
    collapseJobTask : function(component, event, helper) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        jobTaskWrapper.Collapsed = !jobTaskWrapper.Collapsed;
        component.set("v.jobTaskWrapper", jobTaskWrapper);
    },*/
    //job task >>
    handleRowAction : function(component, event, helper) {
        /*
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        var salesLines = component.get("v.jobTaskWrapper.SalesLines");
        if (salesLines && salesLines.length > rowIndex) {
            switch (name) {
                case 'edit':
                    if (action == 'click') {
                        helper.editSalesLine(component, event, rowIndex);
                    }
                    break;
                    break;
                case 'delete':
                    if (action == 'click') {
                        helper.deleteSalesLine(component, event, rowIndex);
                    }
                    break;
                case 'billAsLumpSum':
                    if (action == 'change') {
                        helper.handleBillAsLumpSumChange(component, event, rowIndex);
                    }
                    break;
                case 'quantity':
                    if (action == 'focusout') {
                        var rowValue = event.getParam("row");
                        var salesLine = salesLines[rowIndex];
                        helper.calculateLineTotals(component, event, rowIndex);
                    }
                    break;
                case 'uomQty':
                    if (action == 'focusout') {
                        helper.calculateLineTotals(component, event, rowIndex);
                    }
                    break;
            }
        }
        */
    },
    handleSalesLineUpdateEvent : function(component, event, helper) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var rowIndex = event.getParam("rowIndex");
        var field = event.getParam("field");
        switch(field) {
            case 'Bill_as_Lump_Sum__c':
                helper.handleBillAsLumpSumChange(component, event, rowIndex);
                var salesLine = event.getParam("salesLine");
                if (salesLine) {
                    Object.assign(jobTaskWrapper.SalesLines[rowIndex], salesLine);
                    //ticket 19535 <<
                    helper.rollupJobTaskWrapperLines(jobTaskWrapper);
                    //ticket 19535 >>
                }
                helper.fireJobTaskWrapperUpdateEvent(component, event);
                break;
            //ticket 19535 <<
            case 'Non_Billable__c':
                var salesLine = event.getParam("salesLine");
                if (salesLine) {
                    Object.assign(jobTaskWrapper.SalesLines[rowIndex], salesLine);
                    helper.rollupJobTaskWrapperLines(jobTaskWrapper);
                }
                helper.fireJobTaskWrapperUpdateEvent(component, event);
                break;
            //ticket 19535 >>
            case 'Quantity__c':
                var salesLine = jobTaskWrapper.SalesLines[rowIndex];
                var lumpSumLineNo;
                if (salesLine.Bundle_Line__r) {
                    lumpSumLineNo = salesLine.Bundle_Line__r.Line_No__c;
                }
                //equipment schedule lines <<
                //if (salesLine.Category__c == 'Labor') {
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                //equipment schedule lines >>
                    if (salesLine.Sales_Line_Details__r && salesLine.Sales_Line_Details__r.records) {
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                            salesLine.Sales_Line_Details__r.records[i].Quantity__c = salesLine.Quantity__c;
                        }
                    }
                }
                //ticket 19130 <<
                helper.resetWizardQuestionAnswered(component, jobTaskWrapper, salesLine);
                //ticket 19130 >>

                //before save calculation <<
                //fix 04.20.21 <<
                helper.calculateSalesLineAndJobTask(component, event, jobTaskWrapper, rowIndex, lumpSumLineNo);
                //fix 04.20.21 >>
                component.set("v.unsavedChanges", true);
                //before save calculation >>
                var salesLine = event.getParam("salesLine");
                if (salesLine) {
                    Object.assign(jobTaskWrapper.SalesLines[rowIndex], salesLine);
                }
                helper.fireJobTaskWrapperUpdateEvent(component, event);
                break;
            case 'UOM_Qty__c':
                var salesLine = jobTaskWrapper.SalesLines[rowIndex];
                var lumpSumLineNo;
                if (salesLine.Bundle_Line__r) {
                    lumpSumLineNo = salesLine.Bundle_Line__r.Line_No__c;
                }
                //equipment schedule lines <<
                //if (salesLine.Category__c == 'Labor') {
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                //equipment schedule lines >>
                    if (salesLine.Sales_Line_Details__r && salesLine.Sales_Line_Details__r.records) {
                        var hours = helper.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                            if (salesLine.Unit_of_Measure__r == null || salesLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                                salesLine.Sales_Line_Details__r.records[i].Start_Time__c = null;
                                salesLine.Sales_Line_Details__r.records[i].End_Time__c = null;
                            } else {
                                var lineHours = helper.calculateHours(salesLine.Sales_Line_Details__r.records[i].Start_Time__c, salesLine.Sales_Line_Details__r.records[i].End_Time__c);
                                if (salesLine.UOM_Qty__c == lineHours) {
                                    //don't overwrite the start/end time
                                }
                                else if (salesLine.UOM_Qty__c == hours) {
                                    salesLine.Sales_Line_Details__r.records[i].Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                                    salesLine.Sales_Line_Details__r.records[i].End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                                }
                                else {
                                    salesLine.Sales_Line_Details__r.records[i].Start_Time__c = null;
                                    salesLine.Sales_Line_Details__r.records[i].End_Time__c = null;
                                }
                            }
                            salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                        }
                    }
                }

                //ticket 19130 <<
                helper.resetWizardQuestionAnswered(component, jobTaskWrapper, salesLine);
                //ticket 19130 >>

                //before save calculation <<
                //fix 04.20.21 <<
                helper.calculateSalesLineAndJobTask(component, event, jobTaskWrapper, rowIndex, lumpSumLineNo);
                //fix 04.20.21 >>
                component.set("v.unsavedChanges", true);
                //before save calculation >>
                var salesLine = event.getParam("salesLine");
                if (salesLine) {
                    Object.assign(jobTaskWrapper.SalesLines[rowIndex], salesLine);
                }
                helper.fireJobTaskWrapperUpdateEvent(component, event);
                break;
            case 'Number_of_Days__c':
                //before save calculation <<
                component.set("v.unsavedChanges", true);
                //before save calculation >>
                var salesLine = event.getParam("salesLine");
                if (salesLine) {
                    //ticket 19130 <<
                    helper.resetWizardQuestionAnswered(component, jobTaskWrapper, salesLine);
                    //ticket 19130 >>
                    Object.assign(jobTaskWrapper.SalesLines[rowIndex], salesLine);
                }
                helper.fireJobTaskWrapperUpdateEvent(component, event);
                break;
        }
    },
    handleSalesLineViewEvent : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        helper.editSalesLine(component, event, rowIndex);
    },
    handleSalesLineDeleteEvent : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        helper.deleteSalesLine(component, event, rowIndex);
    },
    //job task <<
    /*
    handleSalesLinesChange : function(component, event, helper) {
        var totalLines = [];
        var items = new Map();
        var maxLineNo = 0;
        var salesLines = component.get("v.salesLines");
        if (salesLines) {

            var totalAmount = 0;
            var totalTax = 0;
            var totalAmountIncludingTax = 0;
            var totalCost = 0;

            for (var i = 0 ; i < salesLines.length; i++) {
                var salesLine = salesLines[i];

                //find last sales line no.
                    if (salesLine.Line_No__c > maxLineNo) {
                        maxLineNo = salesLine.Line_No__c;
                    }

                var rollupAmount = true;
                var rollupCost = true;
                if (salesLine.Bill_as_Lump_Sum__c == true) {
                    rollupAmount = false;
                    rollupCost = false;
                }
                else if (salesLine.Non_Billable__c == true) {
                    rollupAmount = false;
                }

                if (rollupAmount || rollupCost) {

                    //roll up totals by category
                    var item;
                    var category = salesLine.Category__c;
                    if (category == 'Demurrage') {
                        category = 'Transportation, Demurrage and Fees';
                    } else if (category == 'Subcontractors') {
                        category = 'Cost Plus Materials, Equipment and Services';
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
                        item.LineAmount += salesLine.Line_Amount__c;
                        item.Tax += salesLine.Tax__c;
                        item.LineAmountIncludingTax += salesLine.Line_Amt_Incl_Tax__c;

                        totalAmount += salesLine.Line_Amount__c;
                        totalTax += salesLine.Tax__c;
                        totalAmountIncludingTax += salesLine.Line_Amt_Incl_Tax__c;
                    }
                    if (rollupCost) {
                        item.LineCost += salesLine.Line_Cost__c;

                        totalCost += salesLine.Line_Cost__c;
                    }
                }
            }

            //grand totals
            var item = { "Category": "Totals", "LineAmount": totalAmount, "Tax": totalTax, "LineAmountIncludingTax": totalAmountIncludingTax, "LineCost": totalCost };
            items.set("Grand Total", item);

            var orderProfit = 0;
            if (totalAmount != 0) {
                orderProfit = 100 - Math.round(totalCost / totalAmount * 100 * 100) / 100;
            }
            component.set("v.salesOrder.Total_Margin_Pct__c", orderProfit);

            for (const [key, item] of items.entries()) {
                item.ProfitMargin = 0;
                if (item.LineAmount != 0) {
                    item.ProfitMargin = (1 - item.LineCost / item.LineAmount);
                }
                totalLines.push(item);
            };
        }

        component.set("v.nextSalesLineNo", Math.ceil(maxLineNo) + 1);
        component.set("v.totalLines", totalLines);
    },
    */
    handleJobTaskWrapperChange : function(component, event, helper) {
        helper.calculateTotals(component, event);
    },
    //job task >>
    handleBillingTypeChange : function(component, event, helper) {
        /*
        var jobTask = component.get("v.jobTaskWrapper.JobTask");
        if (jobTask && jobTask.Billing_Type__c != 'Fixed Price') {
            jobTask.Fixed_Price__c = null;
            jobTask.Tax__c = null;
            jobTask.Tax_Pct__c = null;
        }
        component.set("v.jobTaskWrapper.JobTask", jobTask);
        */
        var jobTaskWrapper = component.get("v.jobTaskWrapper");

        if (jobTaskWrapper.JobTask && jobTaskWrapper.JobTask.Billing_Type__c != 'Fixed Price') {
            jobTaskWrapper.JobTask.Fixed_Price__c = null;
            jobTaskWrapper.JobTask.Tax__c = null;
            jobTaskWrapper.JobTask.Tax_Pct__c = null;
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
        helper.fireJobTaskWrapperUpdateEvent(component, event);
    },
    //ticket 19672 <<
    handleFixedPriceSurchargeOptionChange : function(component, event, helper) {
        helper.calculateTax(component, event);
    },
    //ticket 19672 >>
    handleTaxGroupChange : function(component, event, helper) {
        helper.calculateTax(component, event);
    },
    handleFixedPriceChange : function(component, event, helper) {
        //ticket 19672 <<
        //helper.calculateTax(component, event);
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        helper.calculateSalesOrderJobTask(component, event, jobTaskWrapper);
        //ticket 19672 >>
    },
    handleAssumptionChange : function(component, event, helper) {
        helper.fireJobTaskWrapperUpdateEvent(component, event);
    },
    validateFields : function(component, event, helper) {
        return true;
    },
    handleInlineEditClose : function(component, event, helper) {

    },
    handleJobTaskWrapperUpdateEvent : function(component, event, helper) {
        var newJobTaskWrapper = event.getParam("jobTaskWrapper");
        var componentSource = event.getParam("sourceComponent");
        if (componentSource != 'SalesOrderJobTaskLine') { //avoid listen to event fired by SalesOrderJobTaskLine component itselft
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            component.set("v.jobTaskWrapper", newJobTaskWrapper);
        }
    },
    validateFields : function(component, event, helper) {
        var jobTask = component.get("v.jobTaskWrapper.JobTask");
        var fields = [];
        fields.push(component.find("task-no"));
        fields.push(component.find("billing-type"));
        fields.push(component.find("description"));
        if (jobTask.Billing_Type__c == 'Fixed Price') {
            fields.push(component.find("fixed-price"));
            fields.push(component.find("tax-group"));
            //ticket 19672 <<
            fields.push(component.find("surcharge-option"));
            //ticket 19672 >>
        }
        var ok = fields.reduce(function(valid, inputField) {
            if (inputField) {
                inputField.showHelpMessageIfInvalid();
            }
            return valid && inputField.get("v.validity").valid;
        }, true);

        return ok;
    }
})