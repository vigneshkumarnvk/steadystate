({
    rollupBundle : function(lumpSumLine, worksheetLines, recalculateUnitPrice) {
        var rolledUpBundlePrice = 0;
        //var rolledUpBundleCost = 0;
        if (!lumpSumLine.Unit_Price__c) {
            lumpSumLine.Unit_Price__c = 0;
        }

        for (var i = 0; i < worksheetLines.length; i++) {
            var worksheetLine = worksheetLines[i];
            if (worksheetLine.Bundle_Line__r && worksheetLine.Bundle_Line__r.Line_No__c == lumpSumLine.Line_No__c) {
                //console.log('Line #' + worksheetLine.Line_No__c + ': ' + worksheetLine.xLine_Amount__c);
                rolledUpBundlePrice += (worksheetLine.xLine_Amount__c ? worksheetLine.xLine_Amount__c : 0);
                //rolledUpBundleCost += (worksheetLine.xLine_Cost__c ? worksheetLine.xLine_Cost__c : 0);
            }
        };

        /*
        if (lumpSumLine.Unit_Price__c < rolledUpBundlePrice) {
            lumpSumLine.Unit_Price__c = rolledUpBundlePrice;
        }
        lumpSumLine.Rolled_up_Unit_Price__c = rolledUpBundlePrice;
        //lumpSumLine.Unit_Cost__c = rolledUpBundleCost;
        */
        var unitPrice = 0;
        if (lumpSumLine.Bundle_Pricing_Method__c == 'Per Unit') {
            if (lumpSumLine.Quantity__c && lumpSumLine.Quantity__c > 0) {
                unitPrice = Math.round(rolledUpBundlePrice / lumpSumLine.Quantity__c * 100) / 100;
            }
            else {
                unitPrice = rolledUpBundlePrice;
            }
        }
        else {
            unitPrice = rolledUpBundlePrice;
        }

        lumpSumLine.Rolled_up_Unit_Price__c = rolledUpBundlePrice;
        //don't overwrite unit price
        /*
        if (recalculateUnitPrice == true) {
            lumpSumLine.Unit_Price__c = unitPrice;
        }
        */

        this.calculateLineTotals(lumpSumLine);
    },
    calculateLineTotals : function(worksheetLine) { //this function also appears in BillingWorksheetLineBase
        var unitPrice = 0;
        var regulateRate = 0;
        var overtimeRate = 0;
        var doubleTimeRate = 0;
        var regularHours = (worksheetLine.Regular_Hours__c ? parseFloat(worksheetLine.Regular_Hours__c) : 0);
        var overtimeHours = (worksheetLine.Overtime_Hours__c ? parseFloat(worksheetLine.Overtime_Hours__c) : 0);
        var doubleTimeHours = (worksheetLine.Premium_Hours__c ? parseFloat(worksheetLine.Premium_Hours__c) : 0);
        var unitCost = 0;
        var qty = (worksheetLine.Quantity__c ? parseFloat(worksheetLine.Quantity__c) : 0);
        var minSellQty = (worksheetLine.Min_Sell_Qty__c ? parseFloat(worksheetLine.Min_Sell_Qty__c) : 0);
        //var markup = (worksheetLine.Markup__c ? parseFloat(worksheetLine.Markup__c) : 0);  //Ticket#19964
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
        //console.log(worksheetLine.Category__c + ' ' + unitPrice);
        var lineAmount = 0;
        if (worksheetLine.Category__c == 'Labor') {
            if(worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                lineAmount = Math.round(regulateRate * regularHours * 100) / 100
                    + Math.round(overtimeRate * overtimeHours * 100) / 100
                    + Math.round(doubleTimeRate * doubleTimeHours * 100) / 100;
            } else {
                lineAmount = Math.round(regulateRate * qty * 100) / 100;
            }
        }
        else {
            lineAmount = Math.round(unitPrice * qty * 100) / 100;
            if (worksheetLine.Category__c == 'Waste Disposal' && minSellQty > qty) {
                lineAmount = Math.round(unitPrice * minSellQty * 100) / 100;
            }
            /*  //Ticket#19964
            if (worksheetLine.Category__c != 'Subcontractors') {
                if (worksheetLine.Markup_Option__c == '%') {
                    //lineAmount += lineAmount * markup / 100;
                    lineAmount = lineAmount + Math.round(lineAmount * markup) / 100;
                } else if (worksheetLine.Markup_Option__c == 'Amount') {
                    lineAmount += markup;
                }
            }
             */
        }
        var lineCost = Math.round(unitCost * costQty * 100) / 100;
        console.log('bw linecost' +linecost);
        worksheetLine.Cost_Qty__c = costQty;
        worksheetLine.Line_Amount__c = lineAmount;
        //ticket 21055 <<
        //worksheetLine.Tax__c = Math.round(lineAmount * worksheetLine.Tax_Pct__c) / 100;
        worksheetLine.Tax__c = Math.round(lineAmount * (worksheetLine.Tax_Pct__c ? worksheetLine.Tax_Pct__c : 0)) / 100;
        console.log('bw tax' +worksheetLine.Tax__c);
        //ticket 21055 >>
        worksheetLine.Line_Amt_Incl_Tax__c = worksheetLine.Line_Amount__c + worksheetLine.Tax__c;
        console.log('bw line amt incl tax: '+worksheetLine.Line_Amt_Incl_Tax__c);
        worksheetLine.Line_Cost__c = lineCost;

        worksheetLine.xLine_Amount__c = worksheetLine.Line_Amount__c;
        worksheetLine.xLine_Cost__c = worksheetLine.Line_Cost__c;

        if (worksheetLine.Bill_as_Lump_Sum__c == true || worksheetLine.Non_Billable__c == true) {
            worksheetLine.Line_Amount__c = 0;
            worksheetLine.Tax__c = 0;
            worksheetLine.Line_Amt_Incl_Tax__c = 0;
            //worksheetLine.Line_Cost__c = 0;
        }
    },
    sortLines : function(worksheetLines) {
        //add ScheduleDate for sorting
        for (var i = 0; i < worksheetLines.length; i++) {
            worksheetLines[i].ScheduledDate = null;
            worksheetLines[i].TMNo = null;
            if (worksheetLines[i].TM__r && worksheetLines[i].TM__r.Scheduled_Date__c) {
                worksheetLines[i].ScheduledDate = worksheetLines[i].TM__r.Scheduled_Date__c;
                worksheetLines[i].TMNo = worksheetLines[i].TM__r.Name;
            }
        }
        let sorts = [
            { fieldName: 'ScheduledDate', ascending: true },
            { fieldName: 'TMNo', ascending: true },
            { fieldName: 'Category__c', ascending: true, custom: ['Labor', 'Equipment', 'Materials', 'Subcontractors', 'Waste Disposal', 'Misc. Charges And Taxes', 'Demurrage', 'Bundled']},
            { fieldName: 'System_Calculated_Line__c', ascending: true, custom: null },
        ];
        this.sortList(worksheetLines, sorts);
        this.hierarchySort(worksheetLines);
    },
    hierarchySort : function(worksheetLines) {
        var mapChildLinesByParentLineNo = new Map();
        for (var i = 0; i < worksheetLines.length; i++) {
            var worksheetLine = worksheetLines[i];
            if (worksheetLine.Bundle_Line__r != null) {
                var parentLineNo = worksheetLine.Bundle_Line__r.Line_No__c;
                var children;
                if (mapChildLinesByParentLineNo.has(parentLineNo)) {
                    children = mapChildLinesByParentLineNo.get(parentLineNo);
                }
                else {
                    var children = [];
                    mapChildLinesByParentLineNo.set(parentLineNo, children);
                }
                children.push(worksheetLine);
            }
        }

        var worksheetLines2 = [];
        for (var i = 0; i < worksheetLines.length; i++) {
            var worksheetLine = worksheetLines[i];
            if (worksheetLine.Bundle_Line__r == null) {
                worksheetLines2.push(worksheetLine);
                if (mapChildLinesByParentLineNo.has(worksheetLine.Line_No__c)) {
                    var children = mapChildLinesByParentLineNo.get(worksheetLine.Line_No__c);
                    children.forEach(function(child) {
                        worksheetLines2.push(child);
                    });
                }
            }
        }

        //assign the ordered list back to worksheetLines2
        for (var i = 0; i < worksheetLines.length; i++) {
            worksheetLines[i] = worksheetLines2[i];
        }
    },
    sortList : function(objList, sorts) {
        objList.sort(function(a, b) {
            return customSort(a, b, sorts, 0);
        });

        function customSort(a, b, sorts, sortIndex) {
            var fieldName = sorts[sortIndex].fieldName;
            var custom = sorts[sortIndex].custom;
            var ascending = sorts[sortIndex].ascending;

            var val1;
            var val2;
            if (custom != null) {
                val1 = custom.indexOf(a[fieldName]);
                val2 = custom.indexOf(b[fieldName]);
            }
            else {
                val1 = a[fieldName];
                val2 = b[fieldName];
            }

            var order = 0;
            if (val1 > val2) {
                order = 1;
            } else if (val1 < val2) {
                order = -1;
            }
            else {
                if (sortIndex < sorts.length - 1) {
                    sortIndex++;
                    order = customSort(a, b, sorts, sortIndex);
                }
            }

            if (ascending != true) {
                order = order * -1;
            }
            return order;
        };
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