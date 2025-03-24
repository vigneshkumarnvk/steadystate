({
    calculateProfitMargin : function(component) {
        var worksheets = component.get("v.worksheets");
        var lineTotals = [];
        var items = new Map();
        var showInvoiceTotals = false;
        if (worksheets) {
            var actualTotalAmount = 0;
            var actualTotalTax = 0;
            var actualTotalAmountInclTax = 0;
            var actualTotalCost = 0;

            var invoiceTotalAmount = 0;
            var invoiceTotalTax = 0;
            var invoiceTotalAmountInclTax = 0;
            var totalOverheadBurden = 0; //Ticket#25132

            for (var i = 0 ; i < worksheets.length; i++) {
                var worksheet = worksheets[i];

                var worksheetAmount = 0;
                var worksheetTax = 0;
                var worksheetAmountInclTax = 0;
                var worksheetCost = 0;

                if (worksheet.WorksheetLines != null) {
                    for (var j = 0; j < worksheet.WorksheetLines.length; j++) {
                        var worksheetLine = worksheet.WorksheetLines[j];
                        if (worksheetLine.To_Invoice__c == true) {
                            var rollupAmount = true;
                            var rollupCost = true;
                            if (worksheetLine.Bill_as_Lump_Sum__c == true) {
                                rollupAmount = false;
                                //rollupCost = false;
                            } else if (worksheetLine.Non_Billable__c == true) {
                                rollupAmount = false;
                            }

                            if (rollupAmount || rollupCost) {
                                //roll up totals by category
                                var item;
                                var category = worksheetLine.Category__c;
                                console.log('category >> '+category);
                                //change category description
                                if (category == 'Demurrage') {
                                    category = 'Transportation, Demurrage and Fees';
                                } else if (category == 'Subcontractors') {
                                    category = 'Cost Plus Materials, Equipment and Services';                                    
                                } else if (category == 'Bundled') {
                                    category = 'Bundled';
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
								console.log('rollupAmount >> '+rollupAmount);
                                if (rollupAmount) {
                                    console.log('line amount >> '+worksheetLine.Line_Amount__c);
                                    console.log('line cost >> '+worksheetLine.Line_Cost__c);
                                    item.LineAmount += worksheetLine.Line_Amount__c;
                                    item.Tax += worksheetLine.Tax__c;
                                    item.LineAmountIncludingTax += worksheetLine.Line_Amt_Incl_Tax__c;

                                    worksheetAmount += worksheetLine.Line_Amount__c;
                                    worksheetTax += +worksheetLine.Tax__c;
                                    worksheetAmountInclTax += worksheetLine.Line_Amt_Incl_Tax__c;
                                }
                               
                                if (rollupCost) {
                                    console.log('worksheetLine.Line_Cost__c',worksheetLine.Line_Cost__c);
                                    item.LineCost += worksheetLine.Line_Cost__c;

                                    worksheetCost += worksheetLine.Line_Cost__c;
                                }
                            }
                        }
                    }

                    //Ticket#24560 >>
                    var operatingExpensePct = (worksheet.SalesOrderJobTask.Sales_Order__r.Operating_Expense_Cost_Pct__c ? parseFloat(worksheet.SalesOrderJobTask.Sales_Order__r.Operating_Expense_Cost_Pct__c) : 0);
                    //console.log('operatingExpensePct: ' + operatingExpensePct);
                    //console.log('worksheet.SalesOrderJobTask.Sales_Order__r.Operating_Expense_Cost_Pct__c: ' + worksheet.SalesOrderJobTask.Sales_Order__r.Operating_Expense_Cost_Pct__c);
                    var operatingCost = Math.round(worksheetAmount * operatingExpensePct) / 100;
                    /*Ticket#25132
                    if(operatingCost > 0){
                        item = {
                            "Category": "Overhead Burden",
                            "LineAmount": 0,
                            "Tax": 0,
                            "LineAmountIncludingTax": 0,
                            "LineCost": operatingCost
                        }
                        items.set("Overhead Burden", item);
                    }
                     */
                    //Ticket#24560 <<
                }

                actualTotalAmount += worksheetAmount;
                actualTotalTax += worksheetTax;
                actualTotalAmountInclTax += worksheetAmountInclTax;
                actualTotalCost += worksheetCost;
                totalOverheadBurden += operatingCost; //Ticket#25132
				console.log('actualTotalCost >> '+actualTotalCost);
                
                if (worksheet.SalesOrderJobTask.Billing_Type__c == 'Fixed Price') {
                    var invoiceAmount = (worksheet.SalesOrderJobTask.Amount_To_Bill__c ? worksheet.SalesOrderJobTask.Amount_To_Bill__c : 0);
                    var taxPct = 0;
                    if (worksheet.SalesOrderJobTask.Tax_Group__c == 'TX') {
                        taxPct = (worksheet.SalesOrderJobTask.Tax_Pct__c ? worksheet.SalesOrderJobTask.Tax_Pct__c : 0);
                    }
                    invoiceTotalAmount += invoiceAmount;
                    invoiceTotalTax += Math.round(invoiceAmount * taxPct) / 100;
                    showInvoiceTotals = true;
                }
                else {
                    invoiceTotalAmount += worksheetAmount;
                    invoiceTotalTax += worksheetTax;
                }
                invoiceTotalAmountInclTax += invoiceTotalAmount + invoiceTotalTax;
                console.log('invoiceTotalAmountInclTax',invoiceTotalAmountInclTax)
            }

            //Ticket#25132 >>
            if(totalOverheadBurden > 0){
                 console.log('totalOverheadBurden >> '+worksheetLine);
                item = {
                    "Category": "Overhead Burden",
                    "LineAmount": 0,
                    "Tax": 0,
                    "LineAmountIncludingTax": 0,
                    "LineCost": totalOverheadBurden
                }
                items.set("Overhead Burden", item);
            }
            //Ticket#25132 <<

            //invoice totals
            if (showInvoiceTotals) {
                console.log('showInvoiceTotals >> '+worksheetLine);
                var item = {
                    "Category": "Suggested Totals",
                    "LineAmount": actualTotalAmount,
                    "Tax": actualTotalTax,
                    "LineAmountIncludingTax": actualTotalAmountInclTax,
                    "LineCost": actualTotalCost,
                    "class": 'total-bold '
                };
                items.set("Suggested Totals", item);

                item = {
                    "Category": "Fixed Price Totals",
                    "LineAmount": invoiceTotalAmount,
                    "Tax": invoiceTotalTax,
                    "LineAmountIncludingTax": invoiceTotalAmountInclTax,
                    "LineCost": actualTotalCost,
                    "class": 'total-bold '
                };
                items.set("Fixed Price Total", item);
            }
            else {
                console.log('else >> '+actualTotalAmountInclTax);
                var item = {
                    "Category": "Totals",
                    "LineAmount": actualTotalAmount,
                    "Tax": actualTotalTax,
                    "LineAmountIncludingTax": actualTotalAmountInclTax,
                    "LineCost": actualTotalCost,
                    "class": 'total-bold '
                };
                items.set("Totals", item);
            }

            for (const [key, item] of items.entries()) {
                console.log('item >> '+item);
                item.ProfitMargin = 0;
                if (item.LineAmount != 0) {
                    console.log('item.LineCost',item.LineCost)
                    item.ProfitMargin = (1 - item.LineCost / item.LineAmount);
                }
                if (!item.class) {
                    item.class = '';
                }
                item.class += 'slds-cell-wrap';
                lineTotals.push(item);
            }
        }
                console.log('lineTotals',lineTotals)
        component.set("v.lineTotals", lineTotals);
    },
});