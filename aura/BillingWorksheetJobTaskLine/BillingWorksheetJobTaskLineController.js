({
    doInit : function(component, event, helper) {
        var salesOrderId = component.get("v.salesOrderId");
        var salesOrder = component.get("v.salesOrder");
        var advflag = component.get("v.salesOrder.Service_Center__r.Advanced_Disposal__c");
       // component.set("v.advDisposalFlag",advflag);
        console.log('init salesOrder:::::::::::::::'+JSON.stringify(salesOrder));
        var worksheet = component.get("v.worksheet");
        console.log('init worksheet:::::::::::::::'+JSON.stringify(worksheet));
        var setupData = component.get("v.setupData");
        console.log('advflag*****************'+advflag);
        var inlineEditComponentParams = {};
        inlineEditComponentParams.salesOrderId = salesOrderId;
        inlineEditComponentParams.salesOrder = salesOrder;
        inlineEditComponentParams.relatedInfos = worksheet.RelatedInfos;
        inlineEditComponentParams.setupData = setupData;
        //TM lookup <<
        //ticket 20170 <<
        //inlineEditComponentParams.TMNoOptions = component.get("v.worksheet.TMNoOptions");
        inlineEditComponentParams.TMNoOptions = component.getReference("v.worksheet.TMNoOptions");
        //ticket 20170 >>
        //TM lookup >>
        component.set("v.inlineEditComponentParams", inlineEditComponentParams);
        component.set("v.advDisposalFlag",advflag);
        // Fetch valid UOMs from the server
        var action = component.get("c.getValidUOMs");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var validUOMsMap = response.getReturnValue();
                component.set("v.validUOMsMap", validUOMsMap);
            } else {
                console.error('Failed to fetch valid UOMs: ' + state);
            }
        });
        $A.enqueueAction(action);
    },
    //ticket 20170 <<
    /*
    //TM lookup <<
    updateTMNoOptions : function(component, event, helper) {
        var inlineEditComponentParams = component.get("v.inlineEditComponentParams");
        inlineEditComponentParams.TMNoOptions = component.get("v.worksheet.TMNoOptions");

        var datatable = component.find("datatable");
        if (datatable) {
            datatable.set("v.inlineEditComponentParams.TMNoOptions", inlineEditComponentParams.TMNoOptions);
        }
    },
    //TM lookup >>
    */
    //ticket 20170 >>
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
        console.log('billing sheet line update');
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
            //ticket 19130 << parent child does not need to carry to billing worksheet anymore
            /*
            for (var i = 0; i < worksheet.WorksheetLines.length; i++) {

                if (worksheet.WorksheetLines[i].Parent_Line__r && worksheet.WorksheetLines[i].Parent_Line__r.Line_No__c == worksheetLine.Line_No__c) {
                    worksheet.WorksheetLines[i].TM__c = worksheetLine.TM__c;
                    worksheet.WorksheetLines[i].TM__r = worksheetLine.TM__r;
                    worksheet.WorksheetLines[i].Scheduled_Date__c = worksheetLine.Scheduled_Date__c;
                }
            }
            */
            //ticket 19130 >>
            component.set("v.worksheet", worksheet);
            //helper.refreshTable(component);
            helper.fireWorksheetUpdateEvent(component, event);
        }
        else if (causedByField === 'Resource__c'){
            if (worksheetLine && worksheet.WorksheetLines) {
                worksheet.WorksheetLines[worksheetLineIndex] = worksheetLine;
            }
            
            if(worksheetLine.Category__c === 'Waste Disposal') {
                helper.calculateManifestFeeLines2(component, event);
            }
        }
        //Ticket#20496
            else if (causedByField === 'calcLaborHoursUsingWeeklyRule'){
                helper.calculateLaborHoursUsingWeeklyRule(component, event);
            }
                else {
                    if (worksheetLine && worksheet.WorksheetLines) {
                        worksheet.WorksheetLines[worksheetLineIndex] = worksheetLine;
                    }
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
            //component.set("v.worksheet", worksheet);
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
    handleSelectAll : function(component, event, helper) {
        var name = event.getParam("name");
        if (name == 'To_Invoice__c' ) {
            helper.fireWorksheetUpdateEvent(component, event);
        }
    },
    addLine : function(component, event, helper) {
        if (helper.closeInlineEdit(component) == true) {
            var worksheet = component.get("v.worksheet");
            var salesOrder = component.get("v.salesOrder");
            var nextWorksheetLineNo = component.get("v.nextWorksheetLineNo");
            var worksheetLine = {};
            worksheetLine.Line_No__c = nextWorksheetLineNo;
            if (worksheet.RelatedInfos.length == 1) {
                var relatedInfo = worksheet.RelatedInfos[0];
                worksheetLine.TM__c = relatedInfo.TM.Id;
                worksheetLine.TM__r = relatedInfo.TM;
                //var jobTask = relatedInfo.TMJobTasks[0]; //there can only be one unique job task per TM
                var jobTask = relatedInfo.TMJobTask;
                worksheetLine.TM_Job_Task__c = jobTask.Id;
                worksheetLine.TM_Job_Task__r = jobTask;
                
            }
            worksheetLine.Sales_Order__c = worksheet.SalesOrderJobTask.Sales_Order__c;
            worksheetLine.Sales_Order__r = salesOrder; //Ticket#20286
            worksheetLine.Sales_Order_Job_Task__c = worksheet.SalesOrderJobTask.Id;
            worksheetLine.Sales_Order_Job_Task__r = { "Id": worksheet.SalesOrderJobTask.Id, "Line_No__c": worksheet.SalesOrderJobTask.Line_No__c };
            if(salesOrder.Tax_Liable__c === true){
                worksheetLine.Tax_Group__c = 'TX';
            } else {
                worksheetLine.Tax_Group__c = 'NT';
            }
            
            //ticket 20143 <<
            worksheetLine.Inserted_by_User__c = true;
            //ticket 20143 >>
            
            worksheet.WorksheetLines.push(worksheetLine);
            nextWorksheetLineNo++;
            //ticket 20143 << update line validation error on the screen
            //component.set("v.worksheet", worksheet);
            component.set("v.worksheet.WorksheetLines", worksheet.WorksheetLines);
            //ticket 20143 >>
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
        helper.showLineCard(component, event, rowIndex, false);
    },
    selectLines : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var checked = event.getParam("checked");
        var worksheetLines = component.get("v.worksheet.WorksheetLines");
        var worksheetLine = worksheetLines[rowIndex];
        console.log('desc>>>>',worksheetLine.Description__c);
        //console.log('length>>>',worksheetLine.Description__c.length());
        //fix to invoice <<
        //worksheetLine.Selected = checked;
        switch (name) {
            case 'Selected':
                worksheetLine.Selected = checked;
                break;
            case 'To_Invoice__c':
                worksheetLine.To_Invoice__c = checked;
                break;
        }
        //fix to invoice >>
        
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
        //ticket 19433 <<
        helper.fireWorksheetUpdateEvent(component, event);
        //ticket 19433 >>
    },
    /*  Ticket#19931
     *      - Job times is not required for Resource Type with Rental Resource Type checked.
     */
    validateLines : function(component, event, helper) {
        helper.closeInlineEdit(component);
        var worksheet = component.get("v.worksheet");
        
        var valid = true;
        var stingValue = JSON.stringify(worksheet.WorksheetLines);
        
        var params = { "workSheetLines": stingValue};
        var validUOMsMap = component.get("v.validUOMsMap");
        var errorMessages = [];
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
        
        //ticket 19433 <<
        var bundleLineNos = [];
        var worksheetLines=[];
        var bundledItems=[];
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = worksheet.WorksheetLines[i];
            //Prod Issue -July 03 Fix
            //debugger;
            
            worksheetLines.push(worksheetLine);
            if (worksheetLine.To_Invoice__c == true && worksheetLine.Bundle_Line__r) {
                bundleLineNos.push(worksheetLine.Bundle_Line__r.Line_No__c);
            }
            
        }
        //Prod Issue -July 03 Fix
        for (var i = 0; i < worksheetLines.length; i++) {
            if (worksheetLines[i].Category__c == 'Bundled') {
                bundledItems.push(worksheetLines[i].Line_No__c);
            }
        }
        
        var bundleLineNosToCheck = [];
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = worksheet.WorksheetLines[i];
            if (bundleLineNos.includes(worksheetLine.Line_No__c) && worksheetLine.To_Invoice__c != true) {
                bundleLineNosToCheck.push(worksheetLine.Line_No__c);
            }
            
            //ticket 20170 <<
            if (!worksheetLine.TM__c) {
                helper.showToast(component, "", "T&M # is required on all lines.", "error", "dismissible");
                return false;
            }
            //ticket 20170 >>
        }
        //Prod Issue -July 03 Fix        
        for (var i = 0; i < bundledItems.length; i++) {
            for (var j = 0; j < worksheetLines.length; j++) {
                
                if (worksheetLines[j].Bundle_Line__r && worksheetLines[j].Bundle_Line__r.Line_No__c == bundledItems[i]) {
                    bundledItems.splice(i, 1);
                    i--;
                }
                
            }
        }
        if(bundledItems.length > 0 ){
            helper.showToast(component, "", "You have created Bundle on Line Number(s) "+ bundledItems.join(',') + " Your Bundle line must include Child Line(s) to proceed.", "error", "dismissible");
            return false;
        }
        if (bundleLineNosToCheck.length > 0) {
            helper.showToast(component, "", "To Invoice of worksheet line(s) " + bundleLineNosToCheck.join(',') + " must be checked because child lines are checked to invoice.", "error", "dismissible");
            return false;
        }
        //ticket 19433 >>
        
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = worksheet.WorksheetLines[i];
            worksheetLine.errorText = null;
            
            var err = {};
            err.rowIndex = i;
            err.descriptions = [];
            
            //ticket 20170 <<
            if (worksheetLine.To_Invoice__c != true) continue;
            //ticket 20170 >>
            
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
                    if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                        if (parseFloat(worksheetLine.Hour__c) != parseFloat(worksheetLine.Regular_Hours__c) + parseFloat(worksheetLine.Overtime_Hours__c) + parseFloat(worksheetLine.Premium_Hours__c)) {
                            err.descriptions.push('Hours (' + parseFloat(worksheetLine.Hour__c) + ') does not equal REG+OT+DT (' + (parseFloat(worksheetLine.Regular_Hours__c) + parseFloat(worksheetLine.Overtime_Hours__c) + parseFloat(worksheetLine.Premium_Hours__c)) + ')');
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
                    if (!worksheetLine.Job_Start_Time__c) {
                        //ticket 19447 <<
                        //if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                        if (worksheetLine.Resource_Type__r && worksheetLine.Resource_Type__r.Fleet_No_Required__c == true  && worksheetLine.Resource_Type__r.Rental_Resource_Type__c != true) {
                            //ticket 19447 >>
                            err.descriptions.push('Job Start Time is required');
                        }
                    }
                    if (!worksheetLine.Job_End_Time__c) {
                        //ticket 19447 <<
                        //if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                        if (worksheetLine.Resource_Type__r && worksheetLine.Resource_Type__r.Fleet_No_Required__c == true && worksheetLine.Resource_Type__r.Rental_Resource_Type__c != true) {
                            //ticket 19447 >>
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
                    if (!worksheetLine.Markup__c){
                        err.descriptions.push('Markup is required');
                    }
                    if (!worksheetLine.Markup_Option__c){
                        err.descriptions.push('Markup Option is required');
                    }
                    break;
                case 'Waste Disposal':
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&M is required');
                    }
                    if (!worksheetLine.Resource__r) {
                        err.descriptions.push('Resource is required');
                    }
                    if(worksheetLine.TM__r.Service_Center__r != null && worksheetLine.TM__r.Service_Center__r.Advanced_Disposal__c == true){
                        if(worksheetLine.Category__c == 'Waste Disposal'){
                            if(!worksheetLine.Disposal_Billing_Method__c || worksheetLine.Disposal_Billing_Method__c == ''){
                                err.descriptions.push('Disposal Billing method is required');
                            }
                        }
                    }
                    /*Waste001
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
                     */
                    if (!worksheetLine.Unit_of_Measure__c && worksheetLine.Resource__r) {
                        err.descriptions.push('UOM is required');
                    }
                    
                    //ticket 19586 <<
                    if (worksheetLine.To_Invoice__c == true) {
                        //ticket 20143 <<
                        //if (worksheetLine.System_Calculated_Line__c != true && worksheetLine.Resource__r && worksheetLine.Resource__r.Name != 'WD' && worksheetLine.Resource__r.Name != 'Manifest Fee' && worksheetLine.Resource__r.Name != 'MA Transporter Fee') {
                        if (worksheetLine.System_Calculated_Line__c != true && worksheetLine.Resource__r && worksheetLine.Resource__r.Name != 'Manifest Fee' && worksheetLine.Resource__r.Name != 'MA Transporter Fee') {
                            //ticket 20143 >>
                            if (!worksheetLine.Facility__c) {
                                var facilityRequiredStartDate = new Date('2021-05-04T12:00:00.000Z');
                                if (!worksheetLine.CreatedDate || (worksheetLine.CreatedDate && new Date(worksheetLine.CreatedDate) >= facilityRequiredStartDate)) {
                                    err.descriptions.push('Facility is required');
                                }
                            }
                        }
                    }
                    //ticket 19586 >>
                    //US128849
                    if(worksheetLine.TM__r.Service_Center__c && worksheetLine.TM__r.Service_Center__r.Advanced_Disposal__c && (!worksheetLine.BOL_Manifest__c || !worksheetLine.Approval_Id__c)){
                        if(worksheetLine.Resource__r && worksheetLine.Resource__r.Name != 'Manifest Fee'){
                            err.descriptions.push('BOL Manifest or Profile Approval is required');
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
                    break;
                case 'Misc. Charges And Taxes':
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&M is required');
                    }
                    if (!worksheetLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    break;
                case 'Bundled':
                    if (!worksheetLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    
                    if (!worksheetLine.TM__c) {
                        err.descriptions.push('T&amp;M is required');
                    }
                    break;
            }
            
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
                   if(worksheetLine.Unit_Cost__c == 0 || !worksheetLine.Unit_Cost__c) {
                    	if(worksheetLine.Category__c == 'Waste Disposal' && worksheetLine.Disposal_Billing_Method__c == 'Indirect')
                    	{	
                        	err.descriptions.push('Unit Cost must not be zero.');
                    	}
                   	 else if (worksheetLine.Category__c != 'Waste Disposal') {
                        	err.descriptions.push('Unit Cost must not be zero.');
                    	}
                   }
                }
                
                if(!worksheetLine.Tax_Group__c || worksheetLine.Tax_Group__c === ''){
                    err.descriptions.push('Tax Group must not be blank');
                }
                if ((!worksheetLine.Quantity__c || worksheetLine.Quantity__c <= 0) /*&& worksheetLine.Resource__r.Allow_Negative_Quantity_Values__c == false*/) {
                    err.descriptions.push('Quantity is required.');
                }
                if (worksheetLine.Bill_as_Lump_Sum__c == true) {
                    if (worksheetLine.Category__c == 'Equipment' && worksheetLine.Resource_Type__r.Fuel_Fired_Equipment__c == true) {
                        if (!worksheetLine.xUnit_Price__c || worksheetLine.xUnit_Price__c == 0) {
                            err.descriptions.push('Unit price must not be zero.')
                        }
                        if (worksheetLine.Unit_Price__c && worksheetLine.Unit_Price__c != 0) {
                            err.descriptions.push('Bundled line unit price must be zero.')
                        }
                    }
                }
                else if (worksheetLine.Non_Billable__c != true) {
                    if (!worksheetLine.Unit_Price__c || worksheetLine.Unit_Price__c == 0) {
                        if(worksheetLine.Category__c == 'Waste Disposal' && worksheetLine.Disposal_Billing_Method__c == 'Indirect')
                        	err.descriptions.push('Unit price must not be zero.')
                        else if(worksheetLine.Category__c!= 'Waste Disposal')
                           err.descriptions.push('Unit price must not be zero.') 
                    }
                }
            }
            //bundled lines
            /*bundle not required on invoice
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
            //ticket 20170 <<
            //component.set("v.worksheet.WorksheetLines[" + i + "]", worksheetLine);
            //ticket 20170 >>
        }
        //ticket 20170 <<
        //helper.refreshTable(component);
        //ticket 20170 >>
        
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            var worksheetLine = worksheet.WorksheetLines[i];
            
            if (worksheetLine.To_Invoice__c === true && worksheetLine.Category__c === 'Waste Disposal' && worksheetLine.Resource__c !== 'Manifest Fee' && worksheetLine.Approval_Id__c !== undefined && worksheetLine.Approval_Id__c !== '') {
                var eqaiBillUnitCode = worksheetLine.EQAI_Bill_Unit_Code__c;
                if (eqaiBillUnitCode != null && validUOMsMap[eqaiBillUnitCode]) {
                    var validUOMs = validUOMsMap[eqaiBillUnitCode];
                    var selectedUOM = worksheetLine.Unit_of_Measure__r ? worksheetLine.Unit_of_Measure__r.Name : null;
                    
                    if (selectedUOM && !validUOMs.includes(selectedUOM)) {
                        console.debug('Error: Invalid UOM selected.');
                        var errorMessage = 'Line ' + worksheetLine.Line_No__c + ': The selected UOM "' + selectedUOM + '" does not match the selected profile approval. Based on the selected profile approval, please choose one of the following UOMs: ' + validUOMs.join(', ') + ' or review for a more appropriate profile approval.';
                        errorMessages.push(errorMessage); 
                        valid = false; 
                    }
                }
            }
        }
 
        if (errorMessages.length > 0) {
            var combinedErrorMessages = errorMessages.join(' ');
            helper.showToast(component, "Error", combinedErrorMessages, "error", "dismissible"); // Show all error messages
        }
        
        if (!valid && errorMessages.length === 0) {
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
    closeInlineEdit : function(component, event, helper) {
        helper.closeInlineEdit(component);
    }
});