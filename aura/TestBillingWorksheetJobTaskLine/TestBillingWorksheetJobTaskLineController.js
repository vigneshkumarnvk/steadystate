({
    doInit : function(component, event, helper) {
        var salesOrderId = component.get("v.salesOrderId");
        var worksheet = component.get("v.worksheet");

        var inlineEditComponentParams = {};
        inlineEditComponentParams.salesOrderId = salesOrderId;
        inlineEditComponentParams.relatedInfos = worksheet.RelatedInfos;
        component.set("v.inlineEditComponentParams", inlineEditComponentParams);
    },
    handlePctToBillChange : function(component, event, helper) {
        var worksheet = component.get("v.worksheet");
        if (!worksheet.SalesOrderJobTask.Pct_To_Bill__c) {
            worksheet.SalesOrderJobTask.Pct_To_Bill__c = 0;
        }
        if (!worksheet.SalesOrderJobTask.Pct_Billed__c) {
            worksheet.SalesOrderJobTask.Pct_Billed__c = 0;
        }

        var maxPctToBill = 100 - worksheet.SalesOrderJobTask.Pct_Billed__c;
        if (worksheet.SalesOrderJobTask.Pct_To_Bill__c > maxPctToBill) {
            worksheet.SalesOrderJobTask.Pct_To_Bill__c = 0;
            worksheet.SalesOrderJobTask.Amount_To_Bill__c = 0;
            helper.showToast(component, 'Error', 'You cannot bill more than ' + maxPctToBill + '%.', 'error', 'dismissible');
        }
        else {
            worksheet.SalesOrderJobTask.Amount_To_Bill__c = Math.round(worksheet.SalesOrderJobTask.Fixed_Price__c * worksheet.SalesOrderJobTask.Pct_To_Bill__c) / 100;
        }
        component.set("v.worksheet.SalesOrderJobTask", worksheet.SalesOrderJobTask);
        helper.fireWorksheetUpdateEvent(component, event);
    },
    handleWorksheetLineUpdateChange : function(component, event, helper) {
        helper.setUnsavedChanges(component, event, true);

        //pop up child resource wizard if the causedByField is resource type/resource
        var worksheet = component.get("v.worksheet");
        var causedByField = event.getParam("causedByField");
        var worksheetLine = event.getParam("worksheetLine");
        var worksheetLineIndex = event.getParam("rowIndex");

        /* move to save event
        if (causedByField == 'Resource_Type__c') {
            if (worksheetLine.Resource_Type__c) {
                var calls = [];
                if (worksheetLine.Wizard_Question_Answered__c != true) {
                    calls.push(helper.calculatePresumptiveChildLines.bind(helper, component, event, worksheetLine, worksheetLineIndex));
                }
                calls.push(helper.fireWorksheetUpdateEvent.bind(helper, component, event));
                helper.makeStackedCalls(component, event, helper, calls);
            } else {
                for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
                    if (worksheet.WorksheetLines[i].Parent_Line__r && worksheet.WorksheetLines[i].Parent_Line__r.Line_No__c == worksheetLine.Line_No__c) {
                        worksheet.WorksheetLines[i].Parent_Line__c = null;
                        worksheet.WorksheetLines[i].Parent_Line__r = null;
                    }
                }
                component.set("v.worksheet", worksheet);
                helper.refreshTable(component);
                helper.fireWorksheetUpdateEvent(component, event);
            }
        }
        else if (causedByField == 'Resource__c') {
            if (worksheetLine.Resource__c) {
                var calls = [];
                if (worksheetLine.Wizard_Question_Answered__c != true) {
                    calls.push(helper.calculatePresumptiveChildLines.bind(helper, component, event, worksheetLine, worksheetLineIndex));
                }
                calls.push(helper.fireWorksheetUpdateEvent.bind(helper, component, event));
                helper.makeStackedCalls(component, event, helper, calls);
            }
            else {
                for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
                    if (worksheet.WorksheetLines[i].Parent_Line__r && worksheet.WorksheetLines[i].Parent_Line__r.Line_No__c == worksheetLine.Line_No__c) {
                        worksheet.WorksheetLines[i].Parent_Line__c = null;
                        worksheet.WorksheetLines[i].Parent_Line__r = null;
                    }
                }
                component.set("v.worksheet", worksheet);
                helper.refreshTable(component);
                helper.fireWorksheetUpdateEvent(component, event);
            }
        }
        else*/
        if (causedByField == 'TM__c') {
            for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
                if (worksheet.WorksheetLines[i].Parent_Line__r && worksheet.WorksheetLines[i].Parent_Line__r.Line_No__c == worksheetLine.Line_No__c) {
                    worksheet.WorksheetLines[i].TM__c = worksheetLine.TM__c;
                    worksheet.WorksheetLines[i].TM__r = worksheetLine.TM__r;
                    worksheet.WorksheetLines[i].Scheduled_Date__c = worksheetLine.Scheduled_Date__c;
                }
            }
            component.set("v.worksheet", worksheet);
            //helper.refreshTable(component);
            helper.fireWorksheetUpdateEvent(component, event);
        }
        else {
            helper.fireWorksheetUpdateEvent(component, event);
        }
    },
    changeLineStatus : function(component, event, helper) {
        var status = event.currentTarget.dataset.value;
        var worksheet = component.get("v.worksheet");
        var lineCount = 0;
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            if (worksheet.WorksheetLines[i].Selected == true) {
                worksheet.WorksheetLines[i].Status__c = status;
                lineCount++;
            }
        }
        if (lineCount > 0) {
            component.set("v.worksheet", worksheet);
            helper.refreshTable(component);
            helper.fireWorksheetUpdateEvent(component, event);
        }
        else {
            helper.showToast(component, "", "Please select lines to update status.", "error", "dismissible");
        }
    },
    handleMenuSelect : function(component, event, helper) {
        var menuItem = event.getParam("value");
        switch(menuItem) {
            case 'move-lines':
                helper.confirmMoveLines(component, event);
                break;
            /*
            case 'clear-table-filters':
                var datatable = component.find("datatable");
                if (datatable) {
                    datatable.clearAllFilters();
                }
                break;
            */
            case 'delete-lines':
                var rowIndexes = helper.getSelectedLines(component);
                if (rowIndexes.length > 0) {
                    if (helper.validateDeleteLines(component, rowIndexes) == true) {
                        helper.confirmDeleteLines(component, event, rowIndexes);
                    }
                }
                break;
            case 'sort-table-rows':
                if (helper.closeInlineEdit(component)) { //must close inline edit before sort
                    var worksheet = component.get("v.worksheet");
                    helper.sortLines(worksheet.WorksheetLines);
                    component.set("v.worksheet", worksheet);
                }
                break;
        }
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var action = event.getParam("action");
        var rowIndex = event.getParam("rowIndex");
        switch(name) {
            case 'delete':
                var rowIndex = event.getParam("rowIndex");
                helper.confirmDeleteLine(component, event, rowIndex);
                break;
            case 'view':
                var rowIndex = event.getParam("rowIndex");
                helper.showLineCard(component, event, rowIndex);
                break;
        }
    },
    addLine : function(component, event, helper) {
        if (helper.closeInlineEdit(component) == true) {
            var worksheet = component.get("v.worksheet");
            var nextWorksheetLineNo = component.get("v.nextWorksheetLineNo");
            var worksheetLine = {};
            worksheetLine.Line_No__c = nextWorksheetLineNo;
            if (worksheet.RelatedInfos.length == 1) {
                var relatedInfo = worksheet.RelatedInfos[0];
                worksheetLine.TM__c = relatedInfo.TM.Id;
                worksheetLine.TM__r = relatedInfo.TM;
                var jobTask = relatedInfo.TMJobTasks[0]; //there can only be one unique job task per TM
                worksheetLine.TM_Job_Task__c = jobTask.Id;
                worksheetLine.TM_Job_Task__r = jobTask;

            }
            worksheetLine.Sales_Order__c = worksheet.SalesOrderJobTask.Sales_Order__c;
            worksheetLine.Sales_Order_Job_Task__c = worksheet.SalesOrderJobTask.Id;
            worksheetLine.Sales_Order_Job_Task__r = { "Id": worksheet.SalesOrderJobTask.Id, "Line_No__c": worksheet.SalesOrderJobTask.Line_No__c };
            worksheetLine.Tax_Group__c = 'TX';
            worksheet.WorksheetLines.push(worksheetLine);
            nextWorksheetLineNo++;
            component.set("v.worksheet", worksheet);
            component.set("v.nextWorksheetLineNo", nextWorksheetLineNo);

            if (worksheet.WorksheetLines.length > 0) {
                setTimeout(function () {
                    var datatable = component.find("datatable");
                    datatable.openInlineEdit(worksheet.WorksheetLines.length - 1);
                    datatable.scrollToBottom();
                }, 1);
            }
        }
    },
    getBundleLine : function(component, event, helper) {
        helper.showLineCard(component, event, null, true)
    },
    deleteLine : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        helper.confirmDeleteLine(component, event, rowIndex)
    },
    viewLine : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        helper.showLineCard(component, event, rowIndex, false)
    },
    selectLines : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var worksheetLines = component.get("v.worksheet.WorksheetLines");
        var worksheetLine = worksheetLines[rowIndex];
        var lineCount = 0;
        for (var i = 0; i < worksheetLines.length; i++) {
            if (worksheetLines[i].Bundle_Line__r != null && worksheetLines[i].Bundle_Line__r.Line_No__c == worksheetLine.Line_No__c) {
                switch (name) {
                    case 'Selected':
                        worksheetLines[i].Selected = worksheetLine.Selected;
                        break;
                    case 'To_Invoice__c':
                        worksheetLines[i].To_Invoice__c = worksheetLine.To_Invoice__c;
                        break;
                }
                lineCount++;
            }
        }
        if (lineCount > 0) {
            helper.refreshTable(component);
        }
    },
    validateLines : function(component, event, helper) {
        helper.closeInlineEdit(component);

        var valid = true;
        var worksheet = component.get("v.worksheet");
        var invoice = event.getParams().arguments.invoice;

        if (invoice == true) {
            if (worksheet.SalesOrderJobTask.Billing_Type__c == 'Fixed Price') {
                var invoiceLineCount = 0;
                for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
                    if (worksheet.WorksheetLines[i].To_Invoice__c == true) {
                        invoiceLineCount++;
                    }
                }
                if (invoiceLineCount > 0 && !worksheet.SalesOrderJobTask.Pct_To_Bill__c) {
                    helper.showToast(component, "Error", "% To Billing is required.", "error", "dismissible");
                    return false;
                }
            }
        }

        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = worksheet.WorksheetLines[i];

            worksheetLine.errorText = null;

            var err = {};
            err.rowIndex = i;
            err.descriptions = [];

            if (!worksheetLine.Category__c) {
                err.descriptions.push('Category is required');
            }

            switch (worksheetLine.Category__c) {
                case 'Labor':
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&M is required');
                    }
                    if (!worksheetLine.Service_Center__c) {
                        err.descriptions.push('Service Center is required');
                    }
                    if (!worksheetLine.Resource_Type__c) {
                        err.descriptions.push('Resource Type is required');
                    }
                    if (!worksheetLine.Resource__c) {
                        err.descriptions.push('Resource is required');
                    }
                    if (!worksheetLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (worksheetLine.To_Invoice__c == true && (!worksheetLine.Quantity__c || worksheetLine.Quantity__c <= 0)) {
                        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                            err.descriptions.push('Quantity is required');
                        }
                    }
                    if (!worksheetLine.Job_Start_Time__c) {
                        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            err.descriptions.push('Job Start Time is required');
                        }
                    }
                    if (!worksheetLine.Site_Start_Time__c) {
                        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            err.descriptions.push('Site Start Time is required');
                        }
                    }
                    if (!worksheetLine.Site_End_Time__c) {
                        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            err.descriptions.push('Site End Time is required');
                        }
                    }
                    if (!worksheetLine.Job_End_Time__c) {
                        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            err.descriptions.push('Job End Time is required');
                        }
                    }
                    break;
                case 'Equipment':
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&M is required');
                    }
                    if (!worksheetLine.Service_Center__c) {
                        err.descriptions.push('Service Center is required');
                    }
                    if (!worksheetLine.Resource_Type__c) {
                        err.descriptions.push('Resource Type is required');
                    }
                    if (!worksheetLine.Resource__c && worksheetLine.Resource_Type__r && worksheetLine.Resource_Type__r.Fleet_No_Required__c == true && worksheetLine.Service_Center__r && worksheetLine.Service_Center__r.Equipment_Fleet_No_Not_Required__c != true) {
                        err.descriptions.push('Resource is required');
                    }
                    if (!worksheetLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required')
                    }
                    if (worksheetLine.To_Invoice__c == true && (!worksheetLine.Quantity__c || worksheetLine.Quantity__c <= 0)) {
                        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                            err.descriptions.push('Quantity is required');
                        }
                    }
                    if (!worksheetLine.Job_Start_Time__c) {
                        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            err.descriptions.push('Job Start Time is required');
                        }
                    }
                    if (!worksheetLine.Job_End_Time__c) {
                        if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            err.descriptions.push('Job End Time is required');
                        }
                    }
                    break;
                case 'Materials':
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&M is required');
                    }
                    if (!worksheetLine.Resource__c) {
                        err.descriptions.push('Resource is required')
                    }
                    if (!worksheetLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (worksheetLine.To_Invoice__c == true && (!worksheetLine.Quantity__c || worksheetLine.Quantity__c <= 0)) {
                        err.descriptions.push('Quantity is required');
                    }
                    break;
                case 'Subcontractors':
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&M is required');
                    }
                    if (!worksheetLine.Description__c) {
                        err.descriptions.push('Billing Description is required');
                    }
                    if (!worksheetLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (worksheetLine.To_Invoice__c == true && (!worksheetLine.Quantity__c || worksheetLine.Quantity__c <= 0)) {
                        err.descriptions.push('Quantity is required');
                    }
                    break;
                case 'Waste Disposal':
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&M is required');
                    }
                    if (!worksheetLine.Resource__r) {
                        err.descriptions.push('Resource is required');
                    }
                    if (worksheetLine.Resource__r && worksheetLine.Resource__r.Name != 'WD' && worksheetLine.Resource__r.Name != 'Manifest Fee' && worksheetLine.Resource__r.Name != 'MA Transporter Fee' && (worksheetLine.Resource__r.Has_Container__c == true || worksheetLine.Resource__r.Has_Weight_Volume__c == true)) {
                        if (!worksheetLine.Cost_Method__c && worksheetLine.System_Calculated_Line__c != true) {
                            err.descriptions.push('Cost Method is required.');
                        } else if (worksheetLine.Cost_Method__c == 'Unit_Weight_Vol' && !worksheetLine.Unit_Weight_Vol__c) {
                            err.descriptions.push('Unit Weight/Volume is required');
                        } else if (worksheetLine.Cost_Method__c == 'Container' && !worksheetLine.Container_Size__c) {
                            err.descriptions.push('Container is required');
                        }
                    }
                    if (!worksheetLine.Unit_of_Measure__c) {
                        if (worksheetLine.Resource__r && (worksheetLine.Resource__r.Name == 'WD' || worksheetLine.Resource__r.Name == 'Manifest Fee' || worksheetLine.Resource__r.Name == 'MA Transporter Fee' || (worksheetLine.Resource__r.Has_Container__c != true && worksheetLine.Resource__r.Has_Weight_Volume__c != true))) {
                            err.descriptions.push('UOM is required');
                        }
                    }
                    if (worksheetLine.To_Invoice__c == true && (!worksheetLine.Quantity__c || worksheetLine.Quantity__c <= 0)) {
                        err.descriptions.push('Quantity is required');
                    }
                    if (worksheetLine.To_Invoice__c == true && worksheetLine.Bill_as_Lump_Sum__c != true && worksheetLine.NonBillable != true) {
                        if (!worksheetLine.Unit_Cost__c || worksheetLine.Unit_Cost__c <= 0) {
                            err.descriptions.push('Unit cost is required');
                        }
                    }
                    break;
                case 'Demurrage':
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&M is required');
                    }
                    if (!worksheetLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (worksheetLine.To_Invoice__c == true && (!worksheetLine.Quantity__c || worksheetLine.Quantity__c <= 0)) {
                        err.descriptions.push('Quantity is required');
                    }
                    break;
                case 'Misc. Charges And Taxes':
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&M is required');
                    }
                    if (!worksheetLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (worksheetLine.To_Invoice__c == true && (!worksheetLine.Quantity__c || worksheetLine.Quantity__c <= 0)) {
                        err.descriptions.push('Quantity is required');
                    }
                    break;
                case 'Bundled':
                    if (!worksheetLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (worksheetLine.To_Invoice__c == true && (!worksheetLine.Quantity__c || worksheetLine.Quantity__c <= 0)) {
                        err.descriptions.push('Quantity is required');
                    }
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&amp;M is required');
                    }
                    break;
            }

            if (invoice == true) {
                if (worksheetLine.To_Invoice__c == true) {
                    /*
                    if (worksheetLine.Bill_as_Lump_Sum__c == true || worksheetLine.Non_Billable__c == true) {
                        if (worksheetLine.xUnit_Cost__c == 0 || worksheetLine.xUnit_Cost__c == null) {
                            err.descriptions.push('Unit Cost must not be zero.');
                        }
                    } else {
                        if (worksheetLine.Unit_Cost__c == 0 || worksheetLine.Unit_Cost__c == null) {
                            err.descriptions.push('Unit Cost must not be zero.');
                        }
                    }*/
                    if (worksheetLine.Category__c != 'Bundled' && worksheetLine.Category__c != 'Demurrage' && worksheetLine.Category__c != 'Misc. Charges And Taxes') {
                        if (worksheetLine.Unit_Cost__c == 0 || !worksheetLine.Unit_Cost__c) {
                            err.descriptions.push('Unit Cost must not be zero.');
                        }
                    }
                }
            }
            //bundled lines
            /*bundle not required on inovice
            if (worksheetLine.To_Invoice__c == true && worksheetLine.Bill_as_Lump_Sum__c == true && !worksheetLine.Bundle_Line__r) {
                err.descriptions.push('This line must be bundled because Bill as Lump Sum is checked.');
            }
            */

            if (err.descriptions.length > 0) {
                worksheetLine.errorText = '<ol class="slds-list_ordered">';

                for (var j = 0; j < err.descriptions.length; j++) {
                    worksheetLine.errorText += '<li>' + err.descriptions[j] + '</li>';
                }
                worksheetLine.errorText += '</ol>'
                valid = false;
            }
            component.set("v.worksheet.WorksheetLines[" + i + "]", worksheetLine);
        }
        helper.refreshTable(component);

        if (!valid) {
            helper.showToast(component, "Validation Errors", "You must resolve all validation errors to continue.", "error", "pester");
        }

        return valid;
    },
    handleInlineEditClose : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        var worksheetLines = component.get("v.worksheet.WorksheetLines");
        var worksheetLine = worksheetLines[rowIndex];
        var lumpSumLineNo;
        if (worksheetLine.Bundle_Line__r) {
            lumpSumLineNo = worksheetLine.Bundle_Line__r.Line_No__c;
            if (worksheetLine.Bill_as_Lump_Sum__c != true) {
                worksheetLine.Bundle_Line__c = null;
                worksheetLine.Bundle_Line__r = null;
            }
        }

        if (lumpSumLineNo) {
            var lumpSumRowIndex = -1;
            for (var i = 0; i < worksheetLines.length; i++) {
                if (worksheetLines[i].Line_No__c == lumpSumLineNo) {
                    lumpSumLine = worksheetLines[i];
                    lumpSumRowIndex = i;
                    break;
                }
            }

            if (lumpSumRowIndex >= 0) {
                var lumpSumLine = worksheetLines[lumpSumRowIndex];
                helper.rollupBundle(lumpSumLine, worksheetLines, false);
                component.set("v.worksheet.WorksheetLines[" + lumpSumRowIndex + "]", lumpSumLine);
                helper.refreshTable(component);
            }
        }
    },
    openEditDialog : function(component, event, helper) {
        var rowIndex = parseInt(event.getSource().get("v.value"));
        helper.showLineCard2(component, event, rowIndex);

    }
});