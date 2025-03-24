({
	//job task <<
	/*
	doInit : function(component, event, helper) {

	},
    doNewSalesLine : function(component, event, helper) {
        helper.newSalesLine(component, event, null);
    },
    */
    //job task >>
    /*
    handleMenuSelect : function(component, event, helper) {
        var value = event.getParam("value");
        switch(value) {
            case 'create-task':
                helper.createJobTask(component, event);
                break;
        }
    },*/
    addJobTask : function(component, event, helper) {
        helper.addJobTask(component, event);
    },
    //job task <<
    /*
	handleRowAction : function(component, event, helper) {
		var name = event.getParam("name");
		var rowIndex = event.getParam("rowIndex");
		var salesLines = component.get("v.salesLines");
		var action = event.getParam("action");
		if (salesLines && salesLines.length > rowIndex) {

            switch (name) {
                case 'edit':
                    if (action == 'click') {
                    	helper.editSalesLine(component, event, rowIndex);
                    }
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
            }
        }
    },
    */
    //job task >>
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
    handleJobTaskWrapperUpdateEvent : function(component, event, helper) {
        var jobTaskWrapperIndex = event.getParam("jobTaskWrapperIndex");
        var jobTaskWrapper = event.getParam("jobTaskWrapper");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");

        jobTaskWrappers[jobTaskWrapperIndex] = jobTaskWrapper;
        helper.handleSalesLinesChange(component, jobTaskWrappers);
    },
    handleJobTaskWrapperCloneEvent : function(component, event, helper) {
        var jobTaskWrapperIndex = event.getParam("jobTaskWrapperIndex");
        helper.cloneJobTask(component, event, jobTaskWrapperIndex);
    },
    handleJobTaskWrapperDeleteEvent : function(component, event, helper) {
        var jobTaskWrapperIndex = event.getParam("jobTaskWrapperIndex");
        helper.confirmDeleteJobTask(component, event, jobTaskWrapperIndex);
    },
    //job task >>
    validateFields : function(component, event, helper) {
        var jobTaskLines = [];
        var comps = component.find("job-task-line");
        if (Array.isArray(comps)) {
            jobTaskLines = comps;
        } else {
            jobTaskLines.push(comps);
        }

        var ok = jobTaskLines.reduce(function (valid, comp) {
            if (comp) {
                valid = valid && comp.validateFields();
            }
            return valid;
        }, true);
        return ok;
    },
    handleJobTaskWrappersChange : function(component, event, helper) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        helper.handleSalesLinesChange(component, jobTaskWrappers);
    }
})