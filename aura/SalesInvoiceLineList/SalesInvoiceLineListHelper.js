({
    handleSalesInvoiceLinesChanged : function(component) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var salesInvoice = component.get("v.salesInvoice"); //Ticket#24560
        var lineTotals = [];
        var items = new Map();

        if (jobTaskWrappers) {
            var totalAmount = 0;
            var totalTax = 0;
            var totalAmountIncludingTax = 0;
            var totalCost = 0;
            var totalOverheadBurden = 0; //Ticket#25132

            for (var i = 0 ; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                var jobTaskTotalAmount = 0; //Ticket#24560

                if (jobTaskWrapper.SalesInvoiceLines != null) {
                    for (var j = 0; j < jobTaskWrapper.SalesInvoiceLines.length; j++) {
                        var salesInvoiceLine = jobTaskWrapper.SalesInvoiceLines[j];
                        var rollupAmount = true;
                        var rollupCost = true;
                        if (salesInvoiceLine.Bill_as_Lump_Sum__c == true) {
                            rollupAmount = false;
                        } else if (salesInvoiceLine.Non_Billable__c == true) {
                            rollupAmount = false;
                        }

                        if (rollupAmount || rollupCost) {
                            //roll up totals by category
                            var item;
                            var category = salesInvoiceLine.Category__c;
                            //change category description
                            if (category == 'Demurrage') {
                                category = 'Transportation, Demurrage and Fees';
                            }
                            else if (category == 'Subcontractors') {
                                category = 'Cost Plus Materials, Equipment and Services';
                            }
                            else if (category == 'Bundled') {
                                category = 'Bundled';
                            }

                            if (category) {
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
                                    item.LineAmount += salesInvoiceLine.Line_Amount__c;
                                    item.Tax += salesInvoiceLine.Tax__c;
                                    item.LineAmountIncludingTax += salesInvoiceLine.Line_Amt_Incl_Tax__c;

                                    totalAmount += salesInvoiceLine.Line_Amount__c;
                                    jobTaskTotalAmount += salesInvoiceLine.Line_Amount__c; //Ticket#24560
                                    totalTax += salesInvoiceLine.Tax__c == null? 0:salesInvoiceLine.Tax__c;
                                   //	totalTax += salesInvoiceLine.Tax__c;
                                    totalAmountIncludingTax += salesInvoiceLine.Line_Amt_Incl_Tax__c;
                                }
                                item.LineCost += salesInvoiceLine.Line_Cost__c;
                                totalCost += salesInvoiceLine.Line_Cost__c;
                            }
                        }
                    }
                }

                //Ticket#24560 >>
                var operatingExpensePct = (salesInvoice.Operating_Expense_Cost_Pct__c ? parseFloat(salesInvoice.Operating_Expense_Cost_Pct__c) : 0);
                var operatingCost = Math.round(jobTaskTotalAmount * operatingExpensePct) / 100;
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
                    totalCost += operatingCost;
                }
                 */
                //Ticket#24560 <<
                totalOverheadBurden += operatingCost; //Ticket#25132
            }

            //grand totals
            if(totalOverheadBurden > 0){
                item = {
                    "Category": "Overhead Burden",
                    "LineAmount": 0,
                    "Tax": 0,
                    "LineAmountIncludingTax": 0,
                    "LineCost": totalOverheadBurden
                }
                items.set("Overhead Burden", item);
                totalCost += totalOverheadBurden;
            }

            var item = {
                "Category": "Totals",
                "LineAmount": totalAmount,
                "Tax": totalTax,
                "LineAmountIncludingTax": totalAmountIncludingTax,
                "LineCost": totalCost
            };
            items.set("Grand Total", item);

            var profit = 0;
            if (totalAmount != 0) {
                //orderProfit = 100 - Math.round(totalCost / totalAmount * 100 * 100) / 100;
                let margin = 1 - totalCost / totalAmount;
                profit = Math.round(margin * 100 * 100 + Number.EPSILON) / 100;
            }

            for (const [key, item] of items.entries()) {
                item.ProfitMargin = 0;
                if (item.LineAmount != 0) {
                    item.ProfitMargin = (1 - item.LineCost / item.LineAmount);
                }
                lineTotals.push(item);
            }
        }
        
        component.set("v.lineTotals", lineTotals);
    }
});