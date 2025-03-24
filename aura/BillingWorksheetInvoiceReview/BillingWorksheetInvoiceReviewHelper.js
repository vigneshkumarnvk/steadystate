({
    getSalesOrder: function (component, event) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = {"salesOrderId": salesOrderId};
        this.callServerMethod(component, event, "c.getSalesOrder", params, function (response) {
            var salesOrder = JSON.parse(response);
            component.set("v.salesOrder", salesOrder);
        });
    },
    getWorksheets: function (component, event) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = {"salesOrderId": salesOrderId, "queryFewerFields": true };
        this.callServerMethod(component, event, "c.getUnbilledTasks", params, function (response) {
            var worksheets = JSON.parse(response);
            component.set("v.worksheets", worksheets);
        });
    },
    selectWorksheet: function (component, event, worksheetIndex, salesOrderJobTaskId) {
        var salesOrderId = component.get("v.salesOrderId");
        var salesOrder = component.get("v.salesOrder");
        var params = { "salesOrderId": salesOrderId, "salesOrderJobTaskId": salesOrderJobTaskId, "queryFewerFields": true };
        this.callServerMethod(component, event, "c.getWorksheet", params, function (response) {
            var newWorksheet = JSON.parse(response);
            var totalLineCount = newWorksheet.WorksheetLines.length;
            for (var i = 0; i < newWorksheet.WorksheetLines.length; i++) {
                if (newWorksheet.WorksheetLines[i].To_Invoice__c != true) {
                    newWorksheet.WorksheetLines.splice(i, 1);
                    i--;
                }
            }
            
            if (totalLineCount > 0 && newWorksheet.WorksheetLines.length == 0) {
                if(salesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c){
                    this.showToast(component, "", "To Billing Package lines are not found for this job task.", "info", "dismissible");
                }else{
                    this.showToast(component, "", "To invoice lines are not found for this job task.", "info", "dismissible");
                }
            }
            
            this.splitLaborLines(newWorksheet.WorksheetLines);
            this.sortLines(newWorksheet.WorksheetLines);
            var activeWorksheets = component.get("v.activeWorksheets");
            activeWorksheets.push(newWorksheet);
            component.set("v.activeWorksheets", activeWorksheets);
            
            var worksheets = component.get("v.worksheets");
            var worksheet = worksheets[worksheetIndex];
            for (var i = 0; i < worksheet.RelatedInfos.length; i++) {
                worksheet.RelatedInfos[i].TM.Selected = true;
            }
            component.set("v.worksheets", worksheets);
            
            var activeWorksheetIndex = activeWorksheets.length - 1;
            component.set("v.selectedTabId", 'tab' + activeWorksheetIndex); //activate the tab
        });
    },
    deselectWorksheet : function(component, event, worksheetIndex) {
        var worksheets = component.get("v.worksheets");
        var worksheet = worksheets[worksheetIndex];
        var activeWorksheets = component.get("v.activeWorksheets");
        
        for (var i = 0; i < activeWorksheets.length; i++) {
            if (activeWorksheets[i].SalesOrderJobTask.Id == worksheet.SalesOrderJobTask.Id) {
                activeWorksheets.splice(i, 1);
                break;
            }
        }
        component.set("v.activeWorksheets", activeWorksheets);
        
        for (var i = 0; i < worksheet.RelatedInfos.length; i++) {
            worksheet.RelatedInfos[i].TM.Selected = false;
        }
        component.set("v.worksheets", worksheets);
        
        if (worksheetIndex >= activeWorksheets.length) {
            component.set("v.selectedTabId", "tab0")
        }
    },
    selectTM : function(component, event, worksheetIndex, salesOrderJobTaskId, tmId) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "salesOrderJobTaskId": salesOrderJobTaskId, "tmId": tmId, "queryFewerFields": true };
        this.callServerMethod(component, event, "c.getWorksheetLines", params, function(response) {
            var newWorksheet = JSON.parse(response);
            
            var totalLineCount = newWorksheet.WorksheetLines.length;
            for (var i = 0; i < newWorksheet.WorksheetLines.length; i++) {
                if (newWorksheet.WorksheetLines[i].To_Invoice__c != true) {
                    newWorksheet.WorksheetLines.splice(i, 1);
                    i--;
                }
            }
            
            if (totalLineCount > 0 && newWorksheet.WorksheetLines.length == 0) {
                this.showToast(component, "", "To invoice lines are not found for this T&M.", "info", "dismissible");
            }
            
            var activeWorksheets = component.get("v.activeWorksheets");
            var activeWorksheetIndex = -1;
            for (var i = 0; i < activeWorksheets.length; i++) {
                var activeWorksheet = activeWorksheets[i];
                if (activeWorksheet.SalesOrderJobTask.Id == salesOrderJobTaskId) {
                    activeWorksheetIndex = i;
                    break;
                }
            }
            
            //ticket 20830 <<
            /*
            //check to make sure bundle line exists in worksheet if T&M lines of selected T&M are bundled
            var worksheetLineIds = [];
            if (activeWorksheetIndex >= 0) {
                var activeWorksheet = activeWorksheets[activeWorksheetIndex];
                for (var i = 0; i < activeWorksheet.WorksheetLines.length; i++) {
                    var worksheetLine = activeWorksheet.WorksheetLines[i];
                    if (worksheetLine.Id) {
                        worksheetLineIds.push(worksheetLine.Id);
                    }
                }
            }
            var mapBundleLinesById = new Map();
            for (var i = 0; i < newWorksheet.WorksheetLines.length; i++) {
                var worksheetLine = newWorksheet.WorksheetLines[i];
                if (worksheetLine.Bundle_Line__r) {
                    if (!worksheetLineIds.includes(worksheetLine.Bundle_Line__c) && !mapBundleLinesById.has(worksheetLine.Bundle_Line__c) && worksheetLine.Bundle_Line__r.TM__c != tmId) {
                        mapBundleLinesById.set(worksheetLine.Bundle_Line__c, worksheetLine.Bundle_Line__r);
                    }
                }
            }

            if (parseInt(mapBundleLinesById.size) > 0) {
                //check if bundle line is already included in the worksheet
                var tmNos = [];
                for (const [key, bundleLine] of mapBundleLinesById.entries()) {
                    if (worksheetLineIds)
                        tmNos.push(bundleLine.TM__r.Name);
                }

                var worksheets = component.get("v.worksheets");
                var worksheet = worksheets[worksheetIndex];
                for (var i = 0; i < worksheet.RelatedInfos.length; i++) {
                    if (worksheet.RelatedInfos[i].TM.Id == tmId) {
                        worksheet.RelatedInfos[i].TM.Selected = false;
                    }
                }
                component.set("v.worksheets[" + worksheetIndex + "]", worksheet);
                this.showToast(component, "", "The selected T&M contains lines bundled by another T&M. Please select T&M " + tmNos.join(',') + " first.", "error", "dismissible")
                return;
            }
            */
            //ticket 20830 >>
            
            var activeWorksheet = null;
            if (activeWorksheetIndex == -1) {
                activeWorksheet = newWorksheet;
                activeWorksheetIndex = activeWorksheets.length;
                var worksheets = component.get("v.worksheets");
                worksheets[worksheetIndex].Selected = true;
                component.set("v.worksheets", worksheets);
            }
            else {
                var activeWorksheet = activeWorksheets[activeWorksheetIndex];
                var mapWorksheetLinesByLineNo = new Map();
                for (var i = 0; i < activeWorksheet.WorksheetLines.length; i++) {
                    var activeWorksheetLine = activeWorksheet.WorksheetLines[i];
                    mapWorksheetLinesByLineNo.set(activeWorksheetLine.Line_No__c, activeWorksheetLine);
                }
                
                for (var i = 0; i < newWorksheet.WorksheetLines.length; i++) {
                    var newWorksheetLine = newWorksheet.WorksheetLines[i];
                    if (mapWorksheetLinesByLineNo.has(newWorksheetLine.Line_No__c)) {
                        this.showToast(component, "", "Worksheet line " + newWorksheetLine.Line_No__c + " already exists in the worksheet.");
                        return;
                    }
                }
                
                for (var i = 0; i < newWorksheet.WorksheetLines.length; i++) {
                    activeWorksheet.WorksheetLines.push(newWorksheet.WorksheetLines[i]);
                }
            }
            
            //ticket 20830 <<
            //check selected TMs
            var tmIds = [];
            for (var i = 0; i < activeWorksheet.WorksheetLines.length; i++) {
                tmIds.push(activeWorksheet.WorksheetLines[i].TM__c);
            }
            
            var worksheets = component.get("v.worksheets");
            var worksheet = worksheets[worksheetIndex];
            for (var i = 0; i < worksheet.RelatedInfos.length; i++) {
                if (tmIds.includes(worksheet.RelatedInfos[i].TM.Id)) {
                    worksheet.RelatedInfos[i].TM.Selected = true;
                }
            }
            component.set("v.worksheets[" + worksheetIndex + "]", worksheet);
            //ticket 20830 >>
            
            this.splitLaborLines(activeWorksheet.WorksheetLines);
            this.sortLines(activeWorksheet.WorksheetLines);
            activeWorksheets[activeWorksheetIndex] = activeWorksheet;
            component.set("v.activeWorksheets", activeWorksheets);
            component.set("v.selectedTabId", 'tab' + activeWorksheetIndex); //activate the tab
        })
    },
    deselectTM : function(component, event, worksheetIndex, salesOrderJobTaskId, tmId) {
        var worksheets = component.get("v.worksheets");
        var worksheet = worksheets[worksheetIndex];
        var activeWorksheets = component.get("v.activeWorksheets");
        
        var ok = true;
        for (var i = 0; i < activeWorksheets.length; i++) {
            var activeWorksheet = activeWorksheets[i];
            if (activeWorksheet.SalesOrderJobTask.Id == worksheet.SalesOrderJobTask.Id) {
                //check for bundled lines
                var bundleLineNos = [];
                var lineNos = [];
                for (var j = 0; j < activeWorksheet.WorksheetLines.length; j++) {
                    var worksheetLine = activeWorksheet.WorksheetLines[j];
                    if (worksheetLine.TM__c != tmId) {
                        if (worksheetLine.Bundle_Line__r) {
                            if (!bundleLineNos.includes(worksheetLine.Bundle_Line__r.Line_No__c)) {
                                bundleLineNos.push(worksheetLine.Bundle_Line__r.Line_No__c);
                            }
                        }
                    } else {
                        lineNos.push(worksheetLine.Line_No__c)
                    }
                }
                
                if (bundleLineNos.length > 0) {
                    for (var j = 0; j < lineNos.length; j++) {
                        if (bundleLineNos.includes(lineNos[j])) {
                            for (var k = 0; k < worksheet.RelatedInfos.length; k++) {
                                if (worksheet.RelatedInfos[k].TM.Id == tmId) {
                                    worksheet.RelatedInfos[k].TM.Selected = true;
                                    component.set("v.worksheets[" + worksheetIndex + "]", worksheet);
                                    break;
                                }
                            }
                            
                            this.showToast(component, "", "This T&M bundles other T&Ms lines. You must remove the bundled T&M from the worksheet first.", "error", "dismissible");
                            ok = false;
                        }
                    }
                }
                break;
            }
        }
        
        if (ok == true) {
            for (var i = 0; i < activeWorksheets.length; i++) {
                var activeWorksheet = activeWorksheets[i];
                if (activeWorksheet.SalesOrderJobTask.Id == worksheet.SalesOrderJobTask.Id) {
                    
                    for (var j = 0; j < activeWorksheet.WorksheetLines.length; j++) {
                        if (activeWorksheet.WorksheetLines[j].TM__c == tmId) {
                            activeWorksheet.WorksheetLines.splice(j, 1);
                            j--;
                        }
                    }
                    if (activeWorksheet.WorksheetLines.length > 0) {
                        component.set("v.activeWorksheets[" + i + "]", activeWorksheet);
                    } else {
                        activeWorksheets.splice(i, 1);
                        worksheet.Selected = false;
                        component.set("v.worksheets", worksheets);
                        component.set("v.activeWorksheets", activeWorksheets);
                        component.set("v.selectedTabId", 'tab0');
                    }
                    break;
                }
            }
        }
    },
    calculateProfitAndMargin : function(component) {
        var profitMargin = component.find("profit-margin");
        if (profitMargin) {
            profitMargin.refresh();
        }
    },
    confirmCreateInvoice: function (component, event) {
       
        var activeWorksheets = component.get("v.activeWorksheets");
        var amount = 0;
        var lineCount = 0;
        var salesOrder = component.get("v.salesOrder");
        for (var i = 0; i < activeWorksheets.length; i++) {
            var activeWorksheet = activeWorksheets[i];
            
            if (activeWorksheet.SalesOrderJobTask.Billing_Type__c == 'Fixed Price') {
                amount += (activeWorksheet.SalesOrderJobTask.Amount_To_Bill__c);
            }
            
            for (var j = 0; j < activeWorksheet.WorksheetLines.length; j++) {
                var worksheetLine = activeWorksheet.WorksheetLines[j];
                if (worksheetLine.To_Invoice__c == true) {
                    if (activeWorksheet.SalesOrderJobTask.Billing_Type__c != 'Fixed Price') {
                        amount += (worksheetLine.Line_Amount__c ? worksheetLine.Line_Amount__c : 0);
                    }
                    
                    lineCount++;
                }
            }
        }
        if (lineCount == 0) {
            this.showToast(component, "Error", "There is no lines to invoice.", "error", "dismissible");
            return;
        }
        
        var buttons = [];
        buttons.push({
            "label": 'Cancel',
            "variant": 'neutral',
            "action": {"callback": this.cancelCallback.bind(this, component, event)}
        });
        buttons.push({
            "label": 'Create',
            "variant": 'brand',
            "action": {"callback": this.confirmCreateInvoiceCallback.bind(this, component, event)}
        });
        const isIncludeSO = salesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c;
       
        const modalTitle = isIncludeSO ? 'Create EQAI Billing Package' : 'Create Invoice';
        const modalMessage = `You are about to create ${isIncludeSO ? 'a EQAI billing package' : 'an invoice'} of amount $${amount.toFixed(2)}. Do you want to continue?`;
        this.openModal(component, event, modalTitle, modalMessage, buttons, null, null, null, null, null, "300px");
    },
    confirmCreateInvoiceCallback: function (component, event) {
        this.closeModal(component, event);
        
        var activeWorksheets = component.get("v.activeWorksheets");
        var salesOrderId = component.get("v.salesOrderId");
        var salesOrderJobTaskIds = [];
        var worksheetLineIds = [];
        for (var i = 0; i < activeWorksheets.length; i++) {
            var activeWorksheet = activeWorksheets[i];
            salesOrderJobTaskIds.push(activeWorksheet.SalesOrderJobTask.Id);
            for (var j = 0; j < activeWorksheet.WorksheetLines.length; j++) {
                worksheetLineIds.push(activeWorksheet.WorksheetLines[j].Id);
            }
        }
        
        var params = {"salesOrderId": salesOrderId, "JSONSalesOrderJobTaskIds": JSON.stringify(salesOrderJobTaskIds), "JSONWorksheetLineIds": JSON.stringify(worksheetLineIds)};
        this.callServerMethod(component, event, "c.createSalesInvoiceFromWorksheetLines", params, function (response) {
            var salesInvoiceId = response;
            this.navigateToSObject(component, event, salesInvoiceId);
        });
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    validateInvoice : function(component, event) {
        var ok = true;
        var jobTaskLines = [];
        var jobTaskLine = component.find("active-worksheet");
        if (Array.isArray(jobTaskLine)) {
            jobTaskLines = jobTaskLine;
        }
        else {
            if (jobTaskLine) {
                jobTaskLines.push(jobTaskLine);
            }
        }
        
        if (jobTaskLines.length == 0) {
            this.showToast(component, "", "Please choose at lease one job task to invoice.");
            ok = false;
        }
        
        for (var i = 0; i < jobTaskLines.length; i++) {
            var ok2 = jobTaskLines[0].validateWorksheet();
            ok = ok && ok2;
        }
        return ok;
    },
    splitLaborLines : function(worksheetLines) {
        var laborLines = [];
        for (var i = 0; i < worksheetLines.length; i++ ) {
            var worksheetLine = worksheetLines[i];
            var splitLines = [];
            if (worksheetLine.Category__c == 'Labor' && worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                if (worksheetLine.Regular_Hours__c && worksheetLine.Regular_Hours__c > 0) {
                    var laborLine = JSON.parse(JSON.stringify(worksheetLine));
                    laborLine.RateCode = 'REG';
                    laborLine.Unit_Price__c = laborLine.Regular_Rate__c;
                    laborLine.Quantity__c = laborLine.Regular_Hours__c;
                    laborLine.Hour__c = laborLine.Regular_Hours__c;
                    laborLine.Overtime_Hours__c = 0;
                    laborLine.Premium_Hours__c = 0;
                    this.calculateLineTotals(laborLine);
                    laborLines.push(laborLine);
                    splitLines.push(laborLine);
                }
                if (worksheetLine.Overtime_Hours__c && worksheetLine.Overtime_Hours__c > 0) {
                    var laborLine = JSON.parse(JSON.stringify(worksheetLine));
                    laborLine.RateCode = 'OT';
                    laborLine.Unit_Price__c = laborLine.Overtime_Rate__c;
                    laborLine.Quantity__c = laborLine.Overtime_Hours__c;
                    laborLine.Hour__c = laborLine.Overtime_Hours__c;
                    laborLine.Regular_Hours__c = 0;
                    laborLine.Premium_Hours__c = 0;
                    this.calculateLineTotals(laborLine);
                    laborLines.push(laborLine);
                    splitLines.push(laborLine);
                }
                if (worksheetLine.Premium_Hours__c && worksheetLine.Premium_Hours__c > 0) {
                    var laborLine = JSON.parse(JSON.stringify(worksheetLine));
                    laborLine.RateCode = 'OT';
                    laborLine.Unit_Price__c = laborLine.Premium_Rate__c;
                    laborLine.Quantity__c = laborLine.Premium_Hours__c;
                    laborLine.Hour__c = laborLine.Premium_Hours__c;
                    laborLine.Regular_Hours__c = 0;
                    laborLine.Overtime_Hours__c = 0;
                    laborLine.Description__c += '-DT';
                    this.calculateLineTotals(laborLine);
                    laborLines.push(laborLine);
                    splitLines.push(laborLine);
                }
                
                //profit & margin: use the first line to store total line cost of the labor line.
                for (var j = 0; j < splitLines.length; j++) {
                    if (j == 0) {
                        splitLines[j].Cost_Qty__c = worksheetLine.Cost_Qty__c;
                        splitLines[j].Line_Cost__c = worksheetLine.Line_Cost__c;
                    }
                    else {
                        splitLines[j].Cost_Qty__c = 0;
                        splitLines[j].Line_Cost__c = 0;
                    }
                    splitLines[j].xLine_Cost__c = splitLines[j].Line_Cost__c;
                }
                
                worksheetLines.splice(i, 1);
                i--;
            }
        }
        
        for (var i = 0; i < laborLines.length; i++) {
            worksheetLines.push(laborLines[i]);
        }
    }
    
});