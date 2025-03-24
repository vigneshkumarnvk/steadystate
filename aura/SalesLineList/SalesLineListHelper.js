({
    cloneJobTask : function(component, event, jobTaskWrapperIndex) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var jobTaskWrapper = jobTaskWrappers[jobTaskWrapperIndex];

        var nextTaskNo = 0;
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            if (nextTaskNo < jobTaskWrappers[i].JobTask.Task_No__c) {
                nextTaskNo = jobTaskWrappers[i].JobTask.Task_No__c;
            }
        }
        nextTaskNo++;

        var nextJobTaskLineNo = component.get("v.nextJobTaskLineNo");
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.cloneJobTaskCallback.bind(this, component, event, jobTaskWrapperIndex) }});
        var jobTask = { Line_No__c: nextJobTaskLineNo, Name: jobTaskWrapper.JobTask.Name, "Task_No__c": nextTaskNo, Billing_Type__c: jobTaskWrapper.JobTask.Billing_Type__c };
        var newJobTaskWrapper = { "JobTask": jobTask }
        var params = { "jobTask": jobTask, "mode": 'clone-task' };
        //ticket 19130 <<
        //this.openModal(component, event, 'Clone Job Task', null, buttons, 'c:JobTaskCard', params, 'medium');
        this.openModal(component, event, 'Clone Job Task', null, buttons, 'c:SelectJobTaskTemplateLines', params, 'medium');
        //ticket 19130 >>
    },
    cloneJobTaskCallback : function(component, event, jobTaskWrapperIndex, jobTask) {
        this.closeModal(component, event);
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var nextSalesLineNo = component.get("v.nextSalesLineNo");

        var fromJobTaskWrapper = jobTaskWrappers[jobTaskWrapperIndex];
        var newJobTaskWrapper = { "JobTask": jobTask, "SalesLines": [] }
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONFromJobTaskWrapper": JSON.stringify(fromJobTaskWrapper), "JSONNewJobTaskWrapper": JSON.stringify(newJobTaskWrapper), "nextSalesLineNo": nextSalesLineNo };
        this.callServerMethod(component, event, "c.cloneJobTask", params, function(response) {
            var jobTaskWrapper = JSON.parse(response);
            this.sortSalesLines(jobTaskWrapper.SalesLines);
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            jobTaskWrappers.push(jobTaskWrapper);
            component.set("v.jobTaskWrappers", jobTaskWrappers);
        })
    },
    confirmDeleteJobTask : function(component, event, jobTaskWrapperIndex) {
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'OK', "variant": 'brand', "action": { "callback": this.confirmDeleteJobTaskCallback.bind(this, component, event, jobTaskWrapperIndex) }});
        this.openModal(component, event, 'Delete Task', 'Are you sure you want to delete this job task and the related sales lines?', buttons, null, null, null);
    },
    confirmDeleteJobTaskCallback : function(component, event, jobTaskWrapperIndex) {
        this.closeModal(component, event);
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        jobTaskWrappers.splice(jobTaskWrapperIndex, 1);
        component.set("v.jobTaskWrappers", []);
        component.set("v.jobTaskWrappers", jobTaskWrappers);
        if (jobTaskWrapperIndex >= jobTaskWrappers.length) {
            component.set("v.selectedTabId", "tab0");
        }
    },
    cancelCallback : function (component, event) {
        this.closeModal(component, event);
    },
    handleSalesLinesChange : function(component, jobTaskWrappers) {
        var lineTotals = [];
        var items = new Map();
        var nextJobTaskLineNo = 0;
        var nextSalesLineNo = 0;
        var jobTasks = [];
        //var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var showActualTotals = false;
        var salesOrder = component.get("v.salesOrder"); //Ticket#24560

        if (jobTaskWrappers) {
            var totalAmount = 0;
            var totalTax = 0;
            var totalAmountIncludingTax = 0;
            var totalCost = 0;
            var totalOverheadBurden = 0; //Ticket#25132

            var actualTotalAmount = 0;
            var actualTotalTax = 0;
            var actualTotalAmountIncludingTax = 0;

            for (var i = 0 ; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];

                jobTasks.push(jobTaskWrapper.JobTask); //update the select list on the sales line card

                //calculate next job task line number
                if (jobTaskWrapper.JobTask.Line_No__c > nextJobTaskLineNo) {
                    nextJobTaskLineNo = jobTaskWrapper.JobTask.Line_No__c;
                }

                var amount = 0;
                var tax = 0;
                var amountIncludingTax = 0;
                var cost = 0;
                var operatingCost = 0; //Ticket#24560
                if (jobTaskWrapper.SalesLines != null) {
                    for (var j = 0; j < jobTaskWrapper.SalesLines.length; j++) {
                        var salesLine = jobTaskWrapper.SalesLines[j];

                        ////calculate next sales line number
                        if (salesLine.Line_No__c > nextSalesLineNo) {
                            nextSalesLineNo = salesLine.Line_No__c;
                        }

                        var rollupAmount = true;
                        var rollupCost = true;
                        if (salesLine.Bill_as_Lump_Sum__c == true) {
                            rollupAmount = false;
                            rollupCost = false;
                        } else if (salesLine.Non_Billable__c == true) {
                            rollupAmount = false;
                        }

                        if (rollupAmount || rollupCost) {
                            //roll up totals by category
                            var item;
                            var category = salesLine.Category__c;
                            //change category description
                            if (category == 'Demurrage') {
                                category = 'Transportation, Demurrage and Fees';
                            } else if (category == 'Subcontractors') {
                                category = 'Cost Plus Materials, Equipment and Services';
                            }
                            else if (category == 'Bundled') {
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

                            if (rollupAmount) {
                                item.LineAmount += salesLine.Line_Amount__c;
                                item.Tax += salesLine.Tax__c;
                                item.LineAmountIncludingTax += salesLine.Line_Amt_Incl_Tax__c;

                                /*
                                totalAmount += salesLine.Line_Amount__c;
                                totalTax += salesLine.Tax__c;
                                totalAmountIncludingTax += salesLine.Line_Amt_Incl_Tax__c;
                                */
                                amount += salesLine.Line_Amount__c;
                                tax += salesLine.Tax__c;
                                amountIncludingTax += salesLine.Line_Amt_Incl_Tax__c;
                            }
                            if (rollupCost) {
                                item.LineCost += salesLine.Line_Cost__c;
                                cost += salesLine.Line_Cost__c;
                            }
                        }
                    }
                }

                //Ticket#24560 >>
                var operatingExpensePct = (salesOrder.Operating_Expense_Cost_Pct__c ? parseFloat(salesOrder.Operating_Expense_Cost_Pct__c) : 0);
                operatingCost = Math.round(amount * operatingExpensePct) / 100;
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
                
                totalAmount += amount;
                totalTax += tax;
                totalAmountIncludingTax += amountIncludingTax;
                totalCost += cost;
                totalCost += operatingCost; //Ticket#24560
                totalOverheadBurden += operatingCost; //Ticket#25132

                if (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price') {
                    var actualAmount = (jobTaskWrapper.JobTask.Fixed_Price__c ? parseFloat(jobTaskWrapper.JobTask.Fixed_Price__c) : 0);
                    var taxPct = 0;
                    if (jobTaskWrapper.JobTask.Tax_Group__c == 'TX') {
                        taxPct = (jobTaskWrapper.JobTask.Tax_Pct__c ? parseFloat(jobTaskWrapper.JobTask.Tax_Pct__c) : 0);
                    }

                    //ticket 19672 <<
                    if (jobTaskWrapper.JobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge') {
                        actualAmount += (jobTaskWrapper.JobTask.Surcharge_Amount__c ? parseFloat(jobTaskWrapper.JobTask.Surcharge_Amount__c) : 0);
                    }
                    //ticket 19672 >>
                    actualTotalAmount += actualAmount;
                    actualTotalTax += Math.round(actualAmount * taxPct) / 100;
                    showActualTotals = true;
                }
                else {
                    actualTotalAmount += amount;
                    actualTotalTax += tax;
                }
            }
            actualTotalAmountIncludingTax = actualTotalAmount + actualTotalTax;

            component.set("v.jobTasks", jobTasks); //job task drop down for sales line card

            //grand totals
            //Ticket#25132 >>
            if(totalOverheadBurden > 0){
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
            if (showActualTotals) {
                var item = {
                    "Category": "Suggested Totals",
                    "LineAmount": totalAmount,
                    "Tax": totalTax,
                    "LineAmountIncludingTax": totalAmountIncludingTax,
                    "LineCost": totalCost,
                    "class": 'total-bold '
                };
                items.set("Grand Total", item);

                item = {
                    "Category": "Fixed Price Totals",
                    "LineAmount": actualTotalAmount,
                    "Tax": actualTotalTax,
                    "LineAmountIncludingTax": actualTotalAmountIncludingTax,
                    "LineCost": totalCost,
                    "class": 'total-bold '
                };
                items.set("Actual Total", item);
            }
            else {
                var item = {
                    "Category": "Totals",
                    "LineAmount": totalAmount,
                    "Tax": totalTax,
                    "LineAmountIncludingTax": totalAmountIncludingTax,
                    "LineCost": totalCost,
                    "class": 'total-bold '
                };
                items.set("Grand Total", item);
            }

            var orderProfit = 0;
            if (actualTotalAmount != 0) {
                //orderProfit = 100 - Math.round(totalCost / totalAmount * 100 * 100) / 100;
                let margin = 1 - totalCost / actualTotalAmount;
                orderProfit = Math.round(margin * 100 * 100 + Number.EPSILON) / 100;
            }
            component.set("v.salesOrder.Total_Margin_Pct__c", orderProfit);

            for (const [key, item] of items.entries()) {
                item.ProfitMargin = 0;
                if (item.LineAmount != 0) {
                    item.ProfitMargin = (1 - item.LineCost / item.LineAmount);
                }
                lineTotals.push(item);
            }
        }
        component.set("v.nextJobTaskLineNo", nextJobTaskLineNo + 1);
        component.set("v.nextSalesLineNo", Math.ceil(nextSalesLineNo) + 1);
        component.set("v.lineTotals", lineTotals);
    }
    //job task >>
})