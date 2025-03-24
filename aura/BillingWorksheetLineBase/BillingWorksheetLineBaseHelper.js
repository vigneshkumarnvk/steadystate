({
    fireWorksheetLineUpdateEvent : function(component, event, causedByField) {
        var rowIndex = component.get("v.index");
        var worksheetLine = component.get("v.worksheetLine");
        var worksheetLineUpdateEvent = component.getEvent("worksheetLineUpdateEvent");
        worksheetLineUpdateEvent.setParams({ "rowIndex": rowIndex, "worksheetLine": worksheetLine, "causedByField": causedByField });
        worksheetLineUpdateEvent.fire();
    },
    fireWorksheetLineDeleteEvent : function(component, event) {
        var rowIndex = component.get("v.index");
        var worksheetLineDeleteEvent = component.getEvent("worksheetLineDeleteEvent");
        worksheetLineDeleteEvent.setParams({ "rowIndex": rowIndex });
        worksheetLineDeleteEvent.fire();
    },
    fireWorksheetLineViewEvent : function(component, event) {
        var rowIndex = component.get("v.index");
        var worksheetLineViewEvent = component.getEvent("worksheetLineViewEvent");
        worksheetLineViewEvent.setParams({ "rowIndex": rowIndex });
        worksheetLineViewEvent.fire();
    },
    fireWorksheetLineSelectEvent : function(component, event, name) {
        var rowIndex = component.get("v.index");
        var worksheetLine = component.get("v.worksheetLine");
        var worksheetLineSelectEvent = component.getEvent("worksheetLineSelectEvent");
        //fix to invoice commented1 <<
        //worksheetLineSelectEvent.setParams({ "name": name, "rowIndex": rowIndex, "checked":  worksheetLine.Selected });
        var checked = false;
        switch (name) {
            case 'Selected':
                checked = worksheetLine.Selected;
                break;
            case 'To_Invoice__c':
                checked = worksheetLine.To_Invoice__c;
                break;
        }
        worksheetLineSelectEvent.setParams({ "name": name, "rowIndex": rowIndex, "checked": checked });
        //fix to invoice >>
        worksheetLineSelectEvent.fire();
    },
    calculateLineTotals : function(worksheetLine) { //this function also appears in BillingWorksheetBase
        console.log('calculate line totals on worksheet base');
        var unitPrice = 0;
        var regulateRate = 0;
        var overtimeRate = 0;
        var doubleTimeRate = 0;
        var regularHours = (worksheetLine.Regular_Hours__c ? parseFloat(worksheetLine.Regular_Hours__c) : 0);
        console.log(regularHours);
        var overtimeHours = (worksheetLine.Overtime_Hours__c ? parseFloat(worksheetLine.Overtime_Hours__c) : 0);
        var doubleTimeHours = (worksheetLine.Premium_Hours__c ? parseFloat(worksheetLine.Premium_Hours__c) : 0);
        var unitCost = 0;
      
        var qty = (worksheetLine.Quantity__c ? parseFloat(worksheetLine.Quantity__c) : 0);
        var minSellQty = (worksheetLine.Min_Sell_Qty__c ? parseFloat(worksheetLine.Min_Sell_Qty__c) : 0);
        //var markup = (worksheetLine.Markup__c ? parseFloat(worksheetLine.Markup__c) : 0); //Ticket#19964
        //Ticket#23071 >>
        var regularUnitCost = (worksheetLine.Regular_Unit_Cost__c ? parseFloat(worksheetLine.Regular_Unit_Cost__c) : 0);
        var otUnitCost = (worksheetLine.Overtime_Unit_Cost__c ? parseFloat(worksheetLine.Overtime_Unit_Cost__c) : 0);
        var dtUnitCost = (worksheetLine.Double_Time_Unit_Cost__c ? parseFloat(worksheetLine.Double_Time_Unit_Cost__c) : 0);
        //Ticket#23071 <<
        var costQty = 0;
        var totalJobHours = (worksheetLine.Total_Job_Hours__c ? parseFloat(worksheetLine.Total_Job_Hours__c) : 0);

        if ((worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') && (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true)) {
            //costQty = (worksheetLine.Hour__c ? parseFloat(worksheetLine.Hour__c) : 0);
            var lunchHours = this.calculateLunchHours(worksheetLine);
            costQty = totalJobHours - lunchHours;
        } else {
            costQty = (worksheetLine.Quantity__c ? parseFloat(worksheetLine.Quantity__c) : 0);
        }

        //console.log('Cost Qty.: ' + costQty);
        /*
        if(costQty == 0){
            costQty = (worksheetLine.Quantity__c ? parseFloat(worksheetLine.Quantity__c) : 0);
        }
         */

        if (worksheetLine.Bill_as_Lump_Sum__c != true && worksheetLine.Non_Billable__c != true) {
            unitPrice = (worksheetLine.Unit_Price__c ? parseFloat(worksheetLine.Unit_Price__c) : 0);
            
            //unitCost = (worksheetLine.Unit_Cost__c ? worksheetLine.Unit_Cost__c : 0);
            regulateRate = (worksheetLine.Regular_Rate__c ? parseFloat(worksheetLine.Regular_Rate__c) : 0);
            overtimeRate = (worksheetLine.Overtime_Rate__c ? parseFloat(worksheetLine.Overtime_Rate__c) : 0);
            doubleTimeRate = (worksheetLine.Premium_Rate__c ? parseFloat(worksheetLine.Premium_Rate__c) : 0);
        }
        else {
            unitPrice = (worksheetLine.xUnit_Price__c ? parseFloat(worksheetLine.xUnit_Price__c) : 0);
            //unitCost = worksheetLine.xUnit_Cost__c;
            
            regulateRate = (worksheetLine.xRegular_Rate__c ? parseFloat(worksheetLine.xRegular_Rate__c) : 0);
            overtimeRate = (worksheetLine.xOvertime_Rate__c ? parseFloat(worksheetLine.xOvertime_Rate__c) : 0);
            doubleTimeRate = (worksheetLine.xPremium_Rate__c ? parseFloat(worksheetLine.xPremium_Rate__c) : 0);
        }
         unitCost = (worksheetLine.Unit_Cost__c ? parseFloat(worksheetLine.Unit_Cost__c) : 0);
        //Ticket#23071 >>
        if ((worksheetLine.Category__c == 'Labor') && (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true)) {
            var totalCost = Math.round(regularHours * regularUnitCost * 100) / 100
                + Math.round(overtimeHours * otUnitCost * 100) / 100
                + Math.round(doubleTimeHours * dtUnitCost * 100) / 100;
            var totalHours = regularHours + overtimeHours + doubleTimeHours;
            if(totalHours > 0 && totalCost > 0){
                unitCost = totalCost / totalHours;
                worksheetLine.Unit_Cost__c = unitCost * 100 / 100;
            }
        }
        //Ticket#23071 <<
        var lineAmount = 0;
        if (worksheetLine.Category__c == 'Labor') {
            if(worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                lineAmount = Math.round(regulateRate * regularHours * 100) / 100
                    + Math.round(overtimeRate * overtimeHours * 100) / 100
                    + Math.round(doubleTimeRate * doubleTimeHours * 100) / 100;
            } else {
                lineAmount = Math.round((regulateRate * qty * 100).toFixed(2)) / 100;
            }
        }
        else {
            lineAmount = Math.round((unitPrice * qty * 100).toFixed(2)) / 100;
            if (worksheetLine.Category__c == 'Waste Disposal' && minSellQty > qty) {
                lineAmount = Math.round(unitPrice * minSellQty * 100) / 100;
            }
            /* //Ticket#19964
            else if (worksheetLine.Category__c != 'Subcontractors') {
                if (worksheetLine.Markup_Option__c == '%') {
                    lineAmount = lineAmount + Math.round(lineAmount * markup) / 100;
                } else if (worksheetLine.Markup_Option__c == 'Amount') {
                    lineAmount += markup;
                }
            }
             */
        }

        var lineCost = Math.round(unitCost * costQty * 100) / 100;
        worksheetLine.Line_Amount__c = lineAmount;
        worksheetLine.Tax__c = Math.round(lineAmount * worksheetLine.Tax_Pct__c) / 100;
        worksheetLine.Line_Amt_Incl_Tax__c = Math.round((worksheetLine.Line_Amount__c + worksheetLine.Tax__c) * 100) / 100;
        worksheetLine.Line_Cost__c = lineCost;
        worksheetLine.Cost_Qty__c = costQty;
        worksheetLine.xLine_Amount__c = worksheetLine.Line_Amount__c;
        worksheetLine.xLine_Cost__c = worksheetLine.Line_Cost__c;

        if (worksheetLine.Bill_as_Lump_Sum__c == true || worksheetLine.Non_Billable__c == true) {
            worksheetLine.Line_Amount__c = 0;
            worksheetLine.Tax__c = 0;
            worksheetLine.Line_Amt_Incl_Tax__c = 0;
            //worksheetLine.Line_Cost__c = 0;
        }
       
    },
    calculateLunchHours : function(worksheetLine) {
        return this.calculateHours(worksheetLine.Lunch_Start_Time__c, worksheetLine.Lunch_End_Time__c);
    },
    calculateHours : function(startTime, endTime) {
        var hours = 0;
        if (startTime != null && endTime != null) {
            var startTimeValue = this.timeToInteger(startTime);
            var endTimeValue = this.timeToInteger(endTime);
            if (startTimeValue == endTimeValue) {
                hours = 24;
            } else {
                hours = (endTimeValue - startTimeValue) / 36e5;
                hours = Math.round(hours * 100) / 100;
            }
        }

        if (hours < 0) {
            hours += 24;
        }

        return hours;
    },
    timeToInteger : function(timeString) {
        var timeValue = null;
        if (timeString) {
            var arr = timeString.split(':');
            var h = arr[0];
            var m = arr[1];
            var s = arr[2];
            timeValue = (h * 60 * 60 + m * 60 + parseInt(s)) * 1000;
        }
        return timeValue;
    }
});