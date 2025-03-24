({
    recalculateAllLines : function(jobTaskWrappers) {
        this.rollupLines(jobTaskWrappers);
    },
    rollupLines : function(jobTaskWrappers) {
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTaskWrapper = jobTaskWrappers[i];
            //ticket 19535 <<
            /*
            var salesLines = jobTaskWrapper.SalesLines;

            jobTaskWrapper.totalAmount = 0;
            jobTaskWrapper.totalCost = 0;
            for (var j = 0; j < salesLines.length; j++) {
                var salesLine = salesLines[j];

                if (salesLine.Quantity__c == null) {
                    salesLine.Quantity__c = 0;
                }

                if (salesLine.Category__c == 'Lump Sum') {
                    salesLine = this.rollupLumpSumLine(salesLine, salesLines);
                }

                if (salesLine.Bill_as_Lump_Sum__c != true) {
                    if (salesLine.Non_Billable__c != true) {
                        jobTaskWrapper.totalAmount += salesLine.Line_Amount__c;
                    }
                    jobTaskWrapper.totalCost += salesLine.Line_Cost__c;
                }
            }
            */
            this.rollupJobTaskWrapperLines(jobTaskWrapper);
            //ticket 19535 >>
        }
    },
    //ticket 19535 <<
    rollupJobTaskWrapperLines : function(jobTaskWrapper) {
        var salesLines = jobTaskWrapper.SalesLines;

        jobTaskWrapper.totalAmount = 0;
        jobTaskWrapper.totalCost = 0;
        for (var j = 0; j < salesLines.length; j++) {
            var salesLine = salesLines[j];

            if (salesLine.Quantity__c == null) {
                salesLine.Quantity__c = 0;
            }

            if (salesLine.Category__c == 'Bundled') {
                salesLine = this.rollupLumpSumLine(salesLine, salesLines);
            }

            if (salesLine.Bill_as_Lump_Sum__c != true) {
                if (salesLine.Non_Billable__c != true) {
                    jobTaskWrapper.totalAmount += salesLine.Line_Amount__c;
                }
                jobTaskWrapper.totalCost += salesLine.Line_Cost__c;
            }
        }
    },
    //ticket 19535 >>
    sortSalesLines : function(salesLines) {
        let sorts = [
            { fieldName: 'Category__c', ascending: true, custom: ['Labor', 'Equipment', 'Materials', 'Subcontractors', 'Waste Disposal', 'Misc. Charges And Taxes', 'Demurrage', 'Bundled']},
            { fieldName: 'Line_No__c', ascending: true, custom: null },
        ];
        this.sortLines(salesLines, sorts);
        this.hierarchySort(salesLines);
    },
    sortLines : function(objList, sorts) {
        objList.sort(function(a, b) {
            return sort(a, b, sorts, 0);
        });

        function sort(a, b, sorts, sortIndex) {
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
                    order = sort(a, b, sorts, sortIndex);
                }
            }

            if (ascending != true) {
                order = order * -1;
            }
            return order;
        };
    },
    hierarchySort : function(salesLines) {
        var mapChildLinesByParentLineNo = new Map();
        for (var i = 0; i < salesLines.length; i++) {
            var salesLine = salesLines[i];
            if (salesLine.Bundle_Line__r != null) {
                var parentLineNo = salesLine.Bundle_Line__r.Line_No__c;
                var children;
                if (mapChildLinesByParentLineNo.has(parentLineNo)) {
                    children = mapChildLinesByParentLineNo.get(parentLineNo);
                }
                else {
                    var children = [];
                    mapChildLinesByParentLineNo.set(parentLineNo, children);
                }
                children.push(salesLine);
            }
        }

        var salesLines2 = [];
        for (var i = 0; i < salesLines.length; i++) {
            var salesLine = salesLines[i];

            if (!salesLine.Bundle_Line__r) {
                salesLines2.push(salesLine);
                //push child lines
                if (mapChildLinesByParentLineNo.has(salesLine.Line_No__c)) {
                    var children = mapChildLinesByParentLineNo.get(salesLine.Line_No__c);
                    children.forEach(function(child) {
                        salesLines2.push(child);
                    })
                }
            }
        }

        //assign the ordered list back to salesLines
        for (var i = 0; i < salesLines.length; i++) {
            salesLines[i] = salesLines2[i];
        }
    },
    validateSalesOrderType : function(component, event) {
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");

        if (salesOrder.Id == null) { //wipe out lines if new order
            jobTaskWrappers = [];
        }

        if (record != null) {
            salesOrder.Sales_Order_Type__c = record.Id;
            salesOrder.Sales_Order_Type__r = record;
            salesOrder.Emergency_Sales_Order__c = record.Emergency_Response__c;
            salesOrder.Rate_Sheet__c = record.Rate_Sheet__c;
            salesOrder.Rate_Sheet__r = record.Rate_Sheet__r;
            //component.set("v.salesOrder", salesOrder);
            /* 09.15.2020 - per ACV meeting, disable this automation
            //bring in lines from associated job task template
            if (salesOrder.Id == null) { //only allow templates when creating new order
                var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
                this.callServerMethod(component, event, "c.validateSalesOrderType", params, function (response) {
                    if (response != null) {
                        var salesOrderWrapper = JSON.parse(response);
                        for (var i = 0; i < salesOrderWrapper.JobTaskWrappers.length; i++) {
                            this.sortSalesLines(salesOrderWrapper.JobTaskWrappers[i].SalesLines);
                        }
                        component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
                        component.set("v.jobTaskWrappers", salesOrderWrapper.JobTaskWrappers);
                    }
                });
            }*/
        }
        else {
            salesOrder.Sales_Order_Type__c = null;
            salesOrder.Sales_Order_Type__r = null;
            salesOrder.Emergency_Sales_Order__c = false;
            salesOrder.Rate_Sheet__c = null;
            salesOrder.Rate_Sheet__r = null;
            //component.set("v.salesOrder", salesOrder);
            //component.set("v.jobTaskWrappers", jobTaskWrappers);
        }

        //Ticket#19820 >>
        if (salesOrder.Id != null) {
            var params = {
                "JSONSalesOrder": JSON.stringify(salesOrder),
                "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers)
            };
            this.callServerMethod(component, event, "c.validateSalesOrderType", params, function (response) {
                if (response != null) {
                    var salesOrderWrapper = JSON.parse(response);
                    for (var i = 0; i < salesOrderWrapper.JobTaskWrappers.length; i++) {
                        this.rollupAllLumpSumLines(salesOrderWrapper.JobTaskWrappers[i].SalesLines, true);
                        this.sortSalesLines(salesOrderWrapper.JobTaskWrappers[i].SalesLines);
                    }

                    component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
                    component.set("v.jobTaskWrappers", salesOrderWrapper.JobTaskWrappers);
                }
            });
        }
        //Ticket#19820 >>
    },
    validateContract : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.validateContract", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);

            //recalculate lines on contract change 10.16.2020 <<
            for (var i = 0; i < salesOrderWrapper.JobTaskWrappers.length; i++) {
                this.rollupAllLumpSumLines(salesOrderWrapper.JobTaskWrappers[i].SalesLines, true);
            }
            //recalculate lines on contract change 10.16.2020 <<

            component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
            component.set("v.jobTaskWrappers", salesOrderWrapper.JobTaskWrappers);
        })
    },
    validatePayRule : function(component, event) {
        var record = event.getParam("record");
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        if (record) {
            salesOrder.Pay_Rule__c = record.Id;
            salesOrder.Prevailing_Wage_Job__c = true;
            //component.set("v.salesOrder.Pay_Rule__c", record.Id);
            //component.set("v.salesOrder.Prevailing_Wage_Job__c", true);
        }
        else {
            salesOrder.Pay_Rule__c = null;
            //component.set("v.salesOrder.Pay_Rule__c", null);
        }
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.validatePayRule", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);
            salesOrder = salesOrderWrapper.SalesOrder
            jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
            component.set("v.salesOrder", component.get("v.salesOrder")); //update the field on the sales order information tab
            component.set("v.jobTaskWrappers", jobTaskWrappers);
        });
    },
    promptWizard : function(component, event, jobTaskWrappers, resolve, reject) {
        var salesOrder = component.get("v.salesOrder");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };

        this.callServerMethod(component, event, "c.prepareWizardQuestions", params, function (response) {
            var mapQuestionsByIndex = JSON.parse(response);
            var jobTaskQuestionSets = [];
            if (Object.keys(mapQuestionsByIndex).length > 0) {
                for (var jobTaskWrapperIndex in mapQuestionsByIndex) {
                    var questions = mapQuestionsByIndex[jobTaskWrapperIndex];
                    var jobTaskWrapper = jobTaskWrappers[jobTaskWrapperIndex];
                    var jobTaskTemplate = {
                        "jobTaskWrapperIndex": jobTaskWrapperIndex,
                        "title": 'Task ' + jobTaskWrapper.JobTask.Task_No__c + ' - ' + jobTaskWrapper.JobTask.Name,
                        "templateLines": questions
                    };
                    jobTaskQuestionSets.push(jobTaskTemplate);
                }
            }

            if (jobTaskQuestionSets.length > 0) {
                var buttons = [];
                //ticket 19130 <<
                /*
                var params = {
                    "questionSets": jobTaskQuestionSets,
                    "contractId": salesOrder.Contract__c,
                    "completeCallback": this.completeWizardCallback.bind(this, component, event, resolve),
                    "cancelCallback": this.cancelCallback.bind(this, component, event),
                    "resolve": resolve
                };
                */
                var params = {
                    "sourceObjectType": 'SalesOrder',
                    "questionSets": jobTaskQuestionSets,
                    "contractId": salesOrder.Contract__c,
                    "completeCallback": this.completeWizardCallback.bind(this, component, event, resolve),
                    "cancelCallback": this.cancelCallback.bind(this, component, event),
                    "resolve": resolve
                };
                //ticket 19130 >>
                //ticket 19130 <<
                //this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, "small", null, null);
                this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, "small-high", null, null);
                //ticket 19130 >>
            }
            else {
                resolve();
            }
        }, function(error) {
            this.showToast(component, "Error", error, "error", "dismissible");
            if (reject) {
                reject(error);
            }
        });
    },
    completeWizardCallback : function(component, event, resolve, jobTaskQuestionSets) {
        this.closeModal(component, event);

        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");


        //ticket 19130 <<
        /*
        var tempJobTaskWrappers = []; //store child lines for price recalculation
        for (var i = 0; i < jobTaskQuestionSets.length; i++) {
            var jobTaskQuestionSet = jobTaskQuestionSets[i];
            var mapTemplateLinesByIndex = new Map();
            for (var j = 0; j < jobTaskQuestionSet.templateLines.length; j++) {
                var templateLine = jobTaskQuestionSet.templateLines[j];
                mapTemplateLinesByIndex.set(templateLine.Line_No__c, templateLine);
            }

            var mapSalesLinesByLineNo = new Map();
            var parentLineNos = [];
            var jobTaskWrapper = jobTaskWrappers[jobTaskQuestionSet.jobTaskWrapperIndex];
            var tempJobTaskWrapper = { "JobTask": jobTaskWrapper.JobTask, "SalesLines": [] };
            tempJobTaskWrappers.push(tempJobTaskWrapper);
            for (var j = 0; j < jobTaskWrapper.SalesLines.length; j++) {
                var salesLine = jobTaskWrapper.SalesLines[j];
                if (mapTemplateLinesByIndex.has(salesLine.Line_No__c)) {
                    var templateLine = mapTemplateLinesByIndex.get(salesLine.Line_No__c);
                    if (templateLine.Quantity__c) {
                        salesLine.Quantity__c = templateLine.Quantity__c;
                        salesLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        salesLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                        salesLine.Contract_Line__c = null; //null for pricing recalculation
                        salesLine.Contract_Line__r = null;
                    }
                    salesLine.Wizard_Question_Answered__c = true;
                    parentLineNos.push(salesLine.Parent_Line__r.Line_No__c);
                    mapTemplateLinesByIndex.delete(salesLine.Line_No__c);

                    tempJobTaskWrapper.SalesLines.push(salesLine);
                }
                mapSalesLinesByLineNo.set(salesLine.Line_No__c, salesLine);
            }

            //insert new child lines
            if (mapTemplateLinesByIndex.size > 0) {
                for (const [key, templateLine] of mapTemplateLinesByIndex.entries()) {
                    var parentLine = mapSalesLinesByLineNo.get(templateLine.Parent_Line__r.Line_No__c);
                    parentLineNos.push(parentLine.Line_No__c);
                    if (templateLine.Quantity__c != null && templateLine.Quantity__c > 0) {
                        var childLine = {};
                        childLine.Line_No__c = templateLine.Line_No__c;
                        childLine.Sales_Order_Job_Task__c = jobTaskWrapper.JobTask.Id;
                        childLine.Sales_Order_Job_Task__r = jobTaskWrapper.JobTask;
                        childLine.Sales_Order__c = salesOrder.Id;
                        childLine.Sales_Order__r = { "Id": salesOrder.Id, "Name": salesOrder.Name };
                        childLine.Category__c = templateLine.Category__c;
                        if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment') {
                            childLine.Service_Center__c = parentLine.Service_Center__c;
                            childLine.Service_Center__r = parentLine.Service_Center__r;
                        }
                        childLine.Parent_Line__c = parentLine.Id;
                        childLine.Parent_Line__r = { "Id": parentLine.Id, "Line_No__c": parentLine.Line_No__c};
                        childLine.Resource_Type__c = templateLine.Resource_Type__c;
                        childLine.Resource_Type__r = templateLine.Resource_Type__r;
                        childLine.Resource__c = templateLine.Resource__c;
                        childLine.Resource__r = templateLine.Resource__r;
                        if (templateLine.Resource_Type__r) {
                            childLine.Description__c = templateLine.Description__c;
                            if (childLine.Resource__r) {
                                childLine.Resource_Name__c = templateLine.Resource__r.Name;
                            }
                        }
                        else {
                            childLine.Description__c = templateLine.Description__c;
                        }
                        childLine.Quantity__c = templateLine.Quantity__c;
                        childLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        childLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                        childLine.Cost_Method__c = templateLine.Cost_Method__c;
                        childLine.Container_Size__c = templateLine.Container_Size__c;
                        childLine.Container_Size__r = templateLine.Container_Size__r;
                        childLine.Unit_Weight_Vol__c = templateLine.Unit_Weight_Vol__c;
                        childLine.Unit_Weight_Vol__r = templateLine.Unit_Weight_Vol__r;
                        childLine.Resource_Type_UOM__c = templateLine.Resource_Type_UOM__c;
                        childLine.Resource_Type_UOM__r = templateLine.Resource_Type_UOM__r;
                        childLine.Resource_UOM__c = templateLine.Resource_UOM__c;
                        childLine.Resource_UOM__r = templateLine.Resource_UOM__r;
                        childLine.Unit_Price__c = templateLine.Unit_Price__c;
                        childLine.xUnit_Price__c = templateLine.xUnit_Price__c;
                        childLine.Unit_Cost__c = templateLine.Unit_Cost__c;
                        childLine.xUnit_Cost__c = templateLine.xUnit_Cost__c;
                        childLine.Tax_Group__c = templateLine.Tax_Group__c;
                        childLine.Tax_Pct__c = templateLine.Tax_Pct__c;
                        childLine.Tax__c = templateLine.Tax__c;
                        childLine.Regular_Rate__c = templateLine.Regular_Rate__c;
                        childLine.Overtime_Rate__c = templateLine.Overtime_Rate__c;
                        childLine.Premium_Rate__c = templateLine.Premium_Rate__c;
                        childLine.xRegular_Rate__c = templateLine.xRegular_Rate__c;
                        childLine.xOvertime_Rate__c = templateLine.xOvertime_Rate__c;
                        childLine.xPremium_Rate__c = templateLine.xPremium_Rate__c;
                        childLine.Pricing_Source_2__c = templateLine.Pricing_Source_2__c;
                        childLine.Line_Amount__c = templateLine.Line_Amount__c;
                        childLine.xLine_Amount__c = templateLine.xLine_Amount__c;
                        childLine.Line_Amt_Incl_Tax__c = templateLine.Line_Amt_Incl_Tax__c;
                        childLine.Line_Cost__c = templateLine.Line_Cost__c;
                        childLine.xLine_Cost__c = templateLine.xLine_Cost__c;
                        //childLine.Contract_Line__c = templateLine.Contract_Line__c;//null for pricing recalculation
                        //childLine.Contract_Line__r = templateLine.Contract_Line__r;
                        childLine.Number_of_Day__c = templateLine.Number_of_Day__c;

                        childLine.Wizard_Question_Answered__c = true;
                        jobTaskWrapper.SalesLines.push(childLine);
                        tempJobTaskWrapper.SalesLines.push(childLine);
                    }
                }
            }

            //update parent lines
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                for (var j = 0; j < jobTaskWrapper.SalesLines.length; j++) {
                    var salesLine = jobTaskWrapper.SalesLines[j];
                    if (parentLineNos.includes(salesLine.Line_No__c)) {
                        salesLine.Wizard_Question_Answered__c = true;
                    }
                }
            }
        }
        */

        var newSalesLinesJobTaskWrappers = []; //store child lines for price recalculation
        for (var i = 0; i < jobTaskQuestionSets.length; i++) {
            var jobTaskQuestionSet = jobTaskQuestionSets[i];
            var mapSalesLinesByLineNo = new Map();
            var mapParentChildRelationsByKey = new Map();
            var mapParentLinesByChildLineNo = new Map();
            var jobTaskWrapper = jobTaskWrappers[jobTaskQuestionSet.jobTaskWrapperIndex];

            var newSalesLinesJobTaskWrapper = { "JobTask": jobTaskWrapper.JobTask, "SalesLines": [] };
            newSalesLinesJobTaskWrappers.push(newSalesLinesJobTaskWrapper);
            
            for (var j = 0; j < jobTaskWrapper.SalesLines.length; j++) {
                var salesLine = jobTaskWrapper.SalesLines[j];
                salesLine.Wizard_Question_Answered__c = true;
                mapSalesLinesByLineNo.set(salesLine.Line_No__c, salesLine);
            }

            for (var j = 0; j < jobTaskWrapper.SalesLines.length; j++) {
                var salesLine = jobTaskWrapper.SalesLines[j];
                if (salesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r.records) {
                    for (var k = 0; k < salesLine.Sales_Child_Lines__r.records.length; k++) {
                        var relation = salesLine.Sales_Child_Lines__r.records[k];
                        var key = relation.Parent_Line__r.Line_No__c + ';' + relation.Child_Line__r.Line_No__c;
                        mapParentChildRelationsByKey.set(key, relation);
                        var parentLines;
                        if (mapParentLinesByChildLineNo.has(relation.Child_Line__r.Line_No__c)) {
                            parentLines = mapParentLinesByChildLineNo.get(relation.Child_Line__r.Line_No__c);
                        }
                        else {
                            parentLines = [];
                            mapParentLinesByChildLineNo.set(relation.Child_Line__r.Line_No__c, parentLines);
                        }
                        parentLines.push(mapSalesLinesByLineNo.get(relation.Parent_Line__r.Line_No__c));
                    }
                }
            }

            for (var j = 0; j < jobTaskQuestionSet.templateLines.length; j++) {
                var templateLine = jobTaskQuestionSet.templateLines[j];
                if (templateLine.Quantity__c && templateLine.Quantity__c > 0) {
                    var childLine;
                    if (mapSalesLinesByLineNo.has(templateLine.Line_No__c)) {
                        childLine = mapSalesLinesByLineNo.get(templateLine.Line_No__c);
                        childLine.Quantity__c = templateLine.Quantity__c;
                        if (templateLine.Category__c == 'Labor' || (templateLine.Category__c == 'Equipment')) {
                            childLine.UOM_Qty__c = templateLine.UOM_Qty__c;
                            if (childLine.Sales_Line_Details__r && childLine.Sales_Line_Details__r.records) {
                                for (var k = 0; k < childLine.Sales_Line_Details__r.records.length; k++) {
                                    childLine.Sales_Line_Details__r.records[k].UOM_Qty__c = childLine.UOM_Qty__c;
                                }
                            }
                        }
                        childLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        childLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                    }
                    else {
                        childLine = {};
                        childLine.Line_No__c = templateLine.Line_No__c;
                        childLine.Sales_Order_Job_Task__c = jobTaskWrapper.JobTask.Id;
                        childLine.Sales_Order_Job_Task__r = jobTaskWrapper.JobTask;
                        childLine.Sales_Order__c = salesOrder.Id;
                        childLine.Sales_Order__r = {"Id": salesOrder.Id, "Name": salesOrder.Name};
                        childLine.Category__c = templateLine.Category__c;
                        /*if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment') {
                            childLine.Service_Center__c = salesOrder.Service_Center__c;
                            childLine.Service_Center__r = salesOrder.Service_Center__r;
                        }*/
                        childLine.Resource_Type__c = templateLine.Resource_Type__c;
                        childLine.Resource_Type__r = templateLine.Resource_Type__r;
                        childLine.Resource__c = templateLine.Resource__c;
                        childLine.Resource__r = templateLine.Resource__r;
                        if (templateLine.Resource_Type__r) {
                            childLine.Description__c = templateLine.Description__c;
                            if (childLine.Resource__r) {
                                childLine.Resource_Name__c = templateLine.Resource__r.Name;
                            }
                        } else {
                            childLine.Description__c = templateLine.Description__c;
                        }
                        childLine.Quantity__c = templateLine.Quantity__c;
                        if (templateLine.Category__c == 'Labor' || (templateLine.Category__c == 'Equipment')) {
                            childLine.UOM_Qty__c = templateLine.UOM_Qty__c;
                            if (childLine.Sales_Line_Details__r && childLine.Sales_Line_Details__r.records) {
                                for (var k = 0; k < childLine.Sales_Line_Details__r.records.length; k++) {
                                    childLine.Sales_Line_Details__r.records[k].UOM_Qty__c = childLine.UOM_Qty__c;
                                }
                            }
                        }
                        childLine.Unit_of_Measure__c = templateLine.Unit_of_Measure__c;
                        childLine.Unit_of_Measure__r = templateLine.Unit_of_Measure__r;
                        childLine.Cost_Method__c = null;
                        childLine.Container_Size__c = null;
                        childLine.Container_Size__r = null;
                        childLine.Unit_Weight_Vol__c = null;
                        childLine.Unit_Weight_Vol__r = null;

                        childLine.Wizard_Question_Answered__c = true;
                        childLine.Is_Child_Resource__c = true;
                        jobTaskWrapper.SalesLines.push(childLine);

                        //add to calculate price
                        newSalesLinesJobTaskWrapper.SalesLines.push(childLine);

                        mapSalesLinesByLineNo.set(childLine.Line_No__c, childLine);
                    }

                    //handle new relationship
                    if (templateLine.Parent_Lines__r && templateLine.Parent_Lines__r.records) {
                        for (var k = 0; k < templateLine.Parent_Lines__r.records.length; k++) {
                            var relation = templateLine.Parent_Lines__r.records[k];
                            if (!mapSalesLinesByLineNo.has(relation.Parent_Line__r.Line_No__c)) alert("Parent line #" + relation.Parent_Line__r.Line_No__c + ' is not found.');
                            if (!mapSalesLinesByLineNo.has(relation.Child_Line__r.Line_No__c)) alert("Child line #" + relation.Child_Line__r.Line_No__c + ' is not found.');
                            var parentLine = mapSalesLinesByLineNo.get(relation.Parent_Line__r.Line_No__c);
                            var childLine = mapSalesLinesByLineNo.get(relation.Child_Line__r.Line_No__c);
                            var key = parentLine.Line_No__c + ';' + childLine.Line_No__c;
                            if (!mapParentChildRelationsByKey.has(key)) {
                                if (!parentLine.Sales_Child_Lines__r || !parentLine.Sales_Child_Lines__r.records) {
                                    parentLine.Sales_Child_Lines__r = {"records": []};
                                }
                                var relation2 = {};
                                relation2.Parent_Line__c = parentLine.Id;
                                relation2.Parent_Line__r = {"Id": parentLine.Id, "Line_No__c": parentLine.Line_No__c};
                                relation2.Child_Line__c = childLine.Id;
                                relation2.Child_Line__r = {
                                    "Id": childLine.Id,
                                    "Line_No__c": childLine.Line_No__c
                                };

                                parentLine.Sales_Child_Lines__r.records.push(relation2);
                                parentLine.Sales_Child_Lines__r.totalSize = parentLine.Sales_Child_Lines__r.records.length;
                                parentLine.Sales_Child_Lines__r.done = "true";
                                mapSalesLinesByLineNo.set(parentLine.Line_No__c, parentLine);
                            }
                        }
                    }
                }
                else {
                    /* system should not delete the child line * email 10/25 <<
                    if (mapSalesLinesByLineNo.has(templateLine.Line_No__c)) {
                        mapSalesLinesByLineNo.delete(templateLine.Line_No__c);
                        for (var k = 0; k < jobTaskWrapper.SalesLines.length; k++) {
                            if (jobTaskWrapper.SalesLines[k].Line_No__c == templateLine.Line_No__c) {
                                jobTaskWrapper.SalesLines.splice(k, 1);
                                break;
                            }
                        }

                        if (mapParentLinesByChildLineNo.has(templateLine.Line_No__c)) {
                            for (var k = 0; k < mapParentLinesByChildLineNo.get(templateLine.Line_No__c); k++) {
                                var parentLine = mapParentLinesByChildLineNo.get(templateLine.Line_No__c);
                                for (var l = 0; l < parentLine.Sales_Child_Lines__r.records.length; l++) {
                                    if (parentLine.Sales_Child_Lines__r.records[l].Child_Line__r.Line_No__c == templateLine.Line_No__c) {
                                        parentLine.Sales_Child_Lines__r.records.splice(l, 1);
                                        l--;
                                    }
                                }
                            }
                        }
                    }
                    system should not delete the child line * email 10/25 >>
                    */
                }
            }
        }
        //ticket 19130 >>

        //ticket 19130 <<
        //var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(tempJobTaskWrappers) };
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(newSalesLinesJobTaskWrappers) };
        //ticket 19130 >>
        this.callServerMethod(component, event, "c.calculatePriceInfo", params, function(response) {
            var jobTaskWrappers2 = JSON.parse(response);
            var mapSalesLinesByLineNo = new Map();
            for (var i = 0; i < jobTaskWrappers2.length; i++) {
                var jobTaskWrapper2 = jobTaskWrappers2[i];
                for (var j = 0; j < jobTaskWrapper2.SalesLines.length; j++) {
                    var salesLine = jobTaskWrapper2.SalesLines[j];
                    mapSalesLinesByLineNo.set(salesLine.Line_No__c, salesLine);
                }
            }

            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                for (var j = 0; j < jobTaskWrapper.SalesLines.length; j++) {
                    var salesLine = jobTaskWrapper.SalesLines[j];
                    if (mapSalesLinesByLineNo.has(salesLine.Line_No__c)) {
                        jobTaskWrapper.SalesLines[j] = mapSalesLinesByLineNo.get(salesLine.Line_No__c);
                    }
                }
            }
            resolve(); //recalculate lines
        });
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
        this.showToast(component, "Wizard", "Wizard cancelled.", "warning", "dismissible");
    },
    calculateAndSaveSalesOrder : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        this.calculateSalesOrder(component, event, salesOrder, jobTaskWrappers, false, this.validateSalesOrder.bind(this, component, event));
    },
    validateJobTasks : function(component, event) {
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var errors = [];

        //check for duplicated task no.
        var taskNos = [];
        var dupTaskNos = [];
        var missingTaskNos = [];
        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTaskWrapper = jobTaskWrappers[i];
            if (!jobTaskWrapper.JobTask.Task_No__c) {
                missingTaskNos.push(jobTaskWrapper.JobTask.Task_No__c);
            }
            var taskNo = parseInt(jobTaskWrapper.JobTask.Task_No__c);
            if (taskNos.includes(taskNo)) {
                dupTaskNos.push(taskNo);
            }
            else {
                taskNos.push(taskNo);
            }
        }

        if (dupTaskNos.length > 0) {
            errors.push('Duplicate Task Number(s) ' + dupTaskNos.join(', ') + ' are found.');
        }
        if (missingTaskNos.length > 0) {
            errors.push('Task Number is required for Job Task(s) ' + missingTaskNos.join(', ') + '.');
        }

        for (var i = 0; i < errors.length; i++) {
            this.showToast(component, 'Validation Error', errors[i], 'error', 'dismissible');
        }
        return (errors.length == 0);
    },
    validateSalesOrder : function(component, event, salesOrder, jobTaskWrappers, resolve, reject) {
            //remove lines with 0 quantity
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var linesDeleted = [];
                var jobTaskWrapper = jobTaskWrappers[i];

                //remove none child lines with zero qty
                for (var j = jobTaskWrapper.SalesLines.length - 1; j >= 0; j--) {
                    var salesLine = jobTaskWrapper.SalesLines[j];
                    //ticket 19130 <<
                    //if (!salesLine.Parent_Line__r && (!salesLine.Quantity__c || salesLine.Quantity__c == 0) && salesLine.System_Calculated_Line__c != true) {
                    if (salesLine.Is_Child_Resource__c != true && (!salesLine.Quantity__c || salesLine.Quantity__c == 0) && salesLine.System_Calculated_Line__c != true) {
                        //ticket 19130 >>
                        jobTaskWrapper.SalesLines.splice(j, 1);
                        linesDeleted.push(salesLine.Line_No__c);
                    }
                }

                //remove child lines that have zero qty and don't have a parent
                //ticket 19130 <<
                /*
                for (var j = jobTaskWrapper.SalesLines.length - 1; j >= 0; j--) {
                    var salesLine = jobTaskWrapper.SalesLines[j];
                    if (salesLine.Parent_Line__r) {
                        if (linesDeleted.includes(salesLine.Parent_Line__r.Line_No__c)) {
                            salesLine.Parent_Line__c = null;
                            salesLine.Parent_Line__r = null;
                        }
                    }
                    if (!salesLine.Parent_Line__r && (!salesLine.Quantity__c || salesLine.Quantity__c == 0) && salesLine.System_Calculated_Line__c != true) {
                        jobTaskWrapper.SalesLines.splice(j, 1);
                        linesDeleted.push(salesLine.Line_No__c);
                    }
                }

	            if (linesDeleted.length > 0) {
	                this.rollupAllLumpSumLines(jobTaskWrapper.SalesLines, true);
	            }
                */
                var childSalesLineNos = [];
                for (var j = 0; j < jobTaskWrapper.SalesLines.length; j++) {
                    var salesLine = jobTaskWrapper.SalesLines[j];
                    if (salesLine.Is_Child_Resource__c != true && salesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r.records) {
                        for (var k = 0; k < salesLine.Sales_Child_Lines__r.records.length; k++) {
                            childSalesLineNos.push(parseInt(salesLine.Sales_Child_Lines__r.records[k].Line_No__c));
                        }
                    }
                }
                var childLinesDeleted = false;
                for (var j = jobTaskWrapper.SalesLines.length - 1; j >= 0; j--) {
                    var salesLine = jobTaskWrapper.SalesLines[j];
                    if (salesLine.Is_Child_Resource__c == true && !childSalesLineNos.includes(parseInt(salesLine.Line_No__c)) && (!salesLine.Quantity__c || salesLine.Quantity__c == 0)) {
                        jobTaskWrapper.SalesLines.splice(j, 1);
                        childLinesDeleted = true;
                    }
                }

                this.cleanUpParentChildRelations(jobTaskWrapper);
                if (childLinesDeleted) {
                    this.rollupAllLumpSumLines(jobTaskWrapper.SalesLines, true);
                }
                //ticket 19130 >>
            }

            var errors = [];
            var unbundledLines = [];
            var zeroQuantityLines = [];
            var lumpSumLines = [];

            var zeroUOMQtyLines = [];
            var zeroDaysNeededLines = [];
            var zeroUnitCostLines = [];

            //ticket 19586 <<
            var missingFacilityLines = [];
            //ticket 19586 >>

            var salesLines = [];
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                for (var j = 0; j < jobTaskWrapper.SalesLines.length; j++) {
                    var salesLine = jobTaskWrapper.SalesLines[j];
                    salesLines.push(salesLine);
                }
            }

            for (var i = 0; i < salesLines.length; i++) {
                if (salesLines[i].Category__c == 'Bundled') {
                    lumpSumLines.push(salesLines[i].Line_No__c);
                }
            }
            for (var i = 0; i < lumpSumLines.length; i++) {
                for (var j = 0; j < salesLines.length; j++) {
                    if (salesLines[j].Bill_as_Lump_Sum__c == true) {
                        if (salesLines[j].Bundle_Line__r && salesLines[j].Bundle_Line__r.Line_No__c == lumpSumLines[i]) {
                            lumpSumLines.splice(i, 1);
                            i--;
                        }
                    }
                }
            }

            if (lumpSumLines.length > 0) {
                errors.push('You have created lump lines (line numbers ' + lumpSumLines.join(', ') + ') with no bundled lines . You must bundle up the Bundled lines to proceed.')
            }

            for (var i = 0; i < salesLines.length; i++) {
                var salesLine = salesLines[i];
                if (salesLine.Bill_as_Lump_Sum__c == true && salesLine.Bundle_Line__r == null) {
                    unbundledLines.push(salesLine.Line_No__c);
                }

                //ticket 19130 <<
                //if ((!salesLine.Quantity__c || salesLine.Quantity__c == 0) && !salesLine.Parent_Line__r) { //don't count child resource lines
                if ((!salesLine.Quantity__c || salesLine.Quantity__c == 0) && salesLine.Is_Child_Resource__c != true) { //don't count child resource lines
                    //ticket 19130 >>
                    zeroQuantityLines.push(salesLine.Line_No__c);
                }

                //job task <<
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                    //ticket 19130 <<
                    //if ((!salesLine.UOM_Qty__c || salesLine.UOM_Qty__c == 0) && !salesLine.Parent_Line__r) {
                    if ((!salesLine.UOM_Qty__c || salesLine.UOM_Qty__c == 0) && salesLine.Is_Child_Resource__c != true) {
                        //ticket 19130 >>
	                    zeroUOMQtyLines.push(salesLine.Line_No__c);
	                }
	            }

	            if (salesLine.Category__c == 'Materials' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Labor') {
	                if (!salesLine.Number_of_Day__c || salesLine.Number_of_Day__c == 0) {
	                    zeroDaysNeededLines.push(salesLine.Line_No__c);


	                }
	            }

	            if (salesLine.Category__c == 'Waste Disposal') {
	                if (salesLine.Bill_as_Lump_Sum__c == true || salesLine.Non_Billable__c == true) {
	                    if (!salesLine.xUnit_Cost__c || salesLine.xUnit_Cost__c == 0) {
	                        zeroUnitCostLines.push(salesLine.Line_No__c);



	                    }
	                } else {
	                    if (!salesLine.Unit_Cost__c || salesLine.Unit_Cost__c == 0) {
	                        zeroUnitCostLines.push(salesLine.Line_No__c);


	                    }
	                }

	                //ticket 19586 <<
	                if (salesLine.System_Calculated_Line__c != true) {
	                    if (!salesLine.Facility__c) {
	                        var facilityRequiredStartDate = new Date('2021-05-04T12:00:00.000Z');
	                        if (!salesLine.CreatedDate || (salesLine.CreatedDate && new Date(salesLine.CreatedDate) >= facilityRequiredStartDate)) {
	                            missingFacilityLines.push(salesLine.Line_No__c);












	                        }
	                    }

	                }
	                //ticket 19586 >>
	            }
	        }
	        if (unbundledLines.length > 0) {
	            errors.push('You have selected "Bundled" on Sales Line Number(s) ' + unbundledLines.join(', ') + '. You must create the Bundled line to proceed.');
	        }





	        if (zeroQuantityLines.length > 0) {
	            errors.push('You must enter "Quantity" on Sales Line Number(s) ' + zeroQuantityLines.join(', ') + '.');
	        }

	        if (zeroUOMQtyLines.length > 0) {
	            errors.push('You must enter "UOM Qty" on Sales Line Number(s) ' + zeroUOMQtyLines.join(', ') + '.');
	        }


	        if (zeroDaysNeededLines.length > 0) {
	            errors.push('You must enter "Days Needed" on Sales Line Number(s) ' + zeroDaysNeededLines.join(', ') + '.');
	        }

	        if (zeroUnitCostLines.length > 0) {
	            errors.push('You must enter "Unit Cost" on Sales Line Number(s) ' + zeroUnitCostLines.join(', ') + '.');
	        }



	        //ticket 19586 <<
	        if (missingFacilityLines.length > 0) {
	            errors.push('You must enter "Facility" on Sales Line Number(s) ' + missingFacilityLines.join(', ') + '.');
	        }
	        //ticket 19586 >>

	        if (jobTaskWrappers.length == 0) {
	            errors.push('You must create at least one job to save.');
	        }






	        if (salesOrder.Document_Type__c == 'Sales Quote') {



	            for (var i = 0; i < jobTaskWrappers.length; i++) {
	                var jobTaskWrapper = jobTaskWrappers[i];
	                if (jobTaskWrapper.SalesLines.length == 0) {
	                    errors.push('Job task ' + jobTaskWrapper.JobTask.Name + ' must contain at least one sales line.');






	                }
	            }
	        }

	        //check for duplicated task no.
	        var taskNos = [];
	        var dupTaskNos = [];
	        var missingTaskNos = [];
	        for (var i = 0; i < jobTaskWrappers.length; i++) {
	            var jobTaskWrapper = jobTaskWrappers[i];
	            if (!jobTaskWrapper.JobTask.Task_No__c) {
	                missingTaskNos.push(jobTaskWrapper.JobTask.Task_No__c);
	            }
	            var taskNo = parseInt(jobTaskWrapper.JobTask.Task_No__c);
	            if (taskNos.includes(taskNo)) {
	                dupTaskNos.push(taskNo);
	            }
	            else {
	                taskNos.push(taskNo);

	            }
	        }

	        if (dupTaskNos.length > 0) {
	            errors.push('Duplicate Task Number(s) ' + dupTaskNos.join(', ') + ' are found.');
	        }
	        if (missingTaskNos.length > 0) {
	            errors.push('Task Number is required for Job Task(s) ' + missingTaskNos.join(', ') + '.');
	        }

	        for (var i = 0; i < errors.length; i++) {
	            this.showToast(component, 'Validation Error', errors[i], 'error', 'dismissible');
	        }

	        //return (errors.length == 0);
	        component.set("v.jobTaskWrappers", jobTaskWrappers);

	        if (errors.length == 0) {
	            if (resolve) {
	                resolve();
	            }
	            else {
	                return true;
	            }
	        }
	        else {
	            if (reject) {
	                reject();
	            }
	            else {
	                return false;
	            }
	        }
    },
    saveSalesOrder : function(component, event) {
        //job task <<
        /*
        var salesOrder = component.get("v.salesOrder");
        var salesLines = component.get("v.salesLines");

        if (this.validateSalesOrderBeforeSave(component, salesOrder, salesLines)) {
            var JSONSalesOrder = this.serializeObject(salesOrder);
            var JSONSalesLines = this.serializeObject(salesLines, 'Sales_Line_Details__r');
            var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLines": JSONSalesLines };
            this.callServerMethod(component, event, "c.saveSalesOrder", params, function(response) {
                //fix.null.fields <<
                //this.navigateToSObject(component, event, response.SalesOrder.Id);
                var salesOrder = JSON.parse(response.JSONSalesOrder);
                this.navigateToSObject(component, event, salesOrder.Id);
                //fix.null.fields >>
                //
                $A.get('e.force:refreshView').fire();
            });
        }
        */
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var params = {
            "JSONSalesOrder": JSON.stringify(salesOrder),
            "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers)
        };
        //<<US141018
        var skipWaring = true;
        var isshowWarning = component.get("v.showWarning");
		if (salesOrder.Document_Type__c == 'Sales Order' && isshowWarning == false) {
            var orderTotAmtInclTax = 0;
            for(var i = 0; i < jobTaskWrappers.length; i++) {
                orderTotAmtInclTax += jobTaskWrappers[i].JobTask.Total_Amount_Incl_Tax__c;
            }
            if (orderTotAmtInclTax > 30000) {
                component.set("v.callQuoteOrderLOAReminder", true);
                skipWaring = false;
            }
        } 
        
        if (isshowWarning || salesOrder.Document_Type__c != 'Sales Order' || skipWaring) { //US141018>>
            this.callServerMethod(component, event, "c.saveSalesOrder", params, function (response) {
                var salesOrderWrapper = JSON.parse(response);
                this.navigateToSObject(component, event, salesOrderWrapper.SalesOrder.Id);
                $A.get('e.force:refreshView').fire();
            }, function(error) {
                this.showToast(component, "Error", error, "error", "dismissible");
            });
        }
        //job task >>
    },
    calculateSalesOrder : function(component, event, salesOrder, jobTaskWrappers, calcSurchargePct, resolve, reject) {
        this.recalculateAllLines(jobTaskWrappers);
        var nextSalesLineNo = component.get("v.nextSalesLineNo");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers), "calcSurchargePct": calcSurchargePct, "nextSalesLineNo": nextSalesLineNo };
        this.callServerMethod(component, event, "c.calculateSalesOrder", params, function(response) {
            //Ticket#21908 >>
            var salesOrderWrapper = JSON.parse(response);
            var jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
            //Ticket#21908 <<
            this.recalculateAllLines(jobTaskWrappers);
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                this.rollupAllLumpSumLines(jobTaskWrappers[i].SalesLines, false)
            }
            component.set("v.salesOrder", salesOrderWrapper.SalesOrder); //Ticket#21908
            component.set("v.jobTaskWrappers", jobTaskWrappers);

            //before-save calculation <<
            component.set("v.unsavedChanges", false);
            //before-save calculation >>

            if (resolve) {
                resolve(jobTaskWrappers);
            }
        }, function(error) {
            this.showToast(component, "Error", error, "error", "dismissible");
            if (reject) {
                reject()
            }
        });
    },
    recalculateSalesLineDetails : function(component, event, recalculateHours) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        if (jobTaskWrappers.length > 0) {
            var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers), "recalculateHours": recalculateHours };
            this.callServerMethod(component, event, "c.recalculateSalesLineDetails", params, function (response) {
                var jobTaskWrappers = JSON.parse(response);
                this.recalculateAllLines(jobTaskWrappers);
                component.set("v.jobTaskWrappers", jobTaskWrappers);
            });
        }
    },
    handleAssumptionChange : function(component, event, recalculateHours) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        if (jobTaskWrappers.length > 0) {
            this.recalculateSalesLineDetails(component, event, recalculateHours);
        } else {
            var params = { "JSONSalesOrder": JSON.stringify(salesOrder)};
            this.callServerMethod(component, event, "c.validateAssumptionChange", params, function (response) {
                var salesOrderWrapper = JSON.parse(response);
                component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
            });
        }
    },
    updateSalesLines : function(salesLine, salesLines) {
        if(salesLine != null) {
            for (var i = 0; i < salesLines.length; i++) {
                if (salesLine.Line_No__c == salesLines[i].Line_No__c) {
                    salesLines[i] = salesLine;
                    break;
                }
            }
        }
        this.sortSalesLines(salesLines);
        return salesLines;
    },
    getLumpSumLine : function(salesLine, salesLines) {
        var lumpSumLine = null;
        if (salesLine.Bundle_Line__r != null) {
            for (var i = 0; i < salesLines.length; i++) {
                if (salesLine.Bundle_Line__r.Line_No__c == salesLines[i].Line_No__c) {
                    lumpSumLine = salesLines[i];
                    break;
                }
            }
        }
        return lumpSumLine;
    },
    rollupAllLumpSumLines : function(salesLines, recalculateUnitPrice) {
        for (var i = 0; i < salesLines.length; i++) {
            if (salesLines[i].Category__c == 'Bundled') {
                salesLines[i] = this.rollupLumpSumLine(salesLines[i], salesLines, recalculateUnitPrice);
                this.updateSalesLines(salesLines[i], salesLines);
            }
        }
    },
    rollUpLumpSum : function(lumpSumLineNo, jobTaskWrapper) {
        var lumpSumLine = this.getLumSumLineByLineNo(jobTaskWrapper, lumpSumLineNo);
        if (lumpSumLine) {
            this.rollupLumpSumLine(lumpSumLine, jobTaskWrapper.SalesLines);
        }
    },
    getLumSumLineByLineNo : function(jobTaskWrapper, lumpSumLineNo) {
        var lumpSumLine = null;
        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            if (jobTaskWrapper.SalesLines[i].Line_No__c == lumpSumLineNo) {
                lumpSumLine = jobTaskWrapper.SalesLines[i];
                break;
            }
        }
        return lumpSumLine;
    },
    //bundle line pricing method <<
    rollupLumpSumLine : function(lumpSumLine, salesLines, recalculateUnitPrice) {
        //bundle line pricing method >>
        var bundledLines = [];
        if (salesLines && salesLines.length > 0) {
            for (var i = 0; i < salesLines.length; i++) {
                var salesLine = salesLines[i];
                if (salesLine.Category__c != 'Bundled' && salesLine.Bill_as_Lump_Sum__c == true && salesLine.Bundle_Line__r != null && salesLine.Bundle_Line__r.Line_No__c == lumpSumLine.Line_No__c) {
                    bundledLines.push(salesLine);
                }
            }
        }

        if (lumpSumLine.Quantity__c == null) {
            lumpSumLine.Quantity__c = 0;
        }

        var lumpSumAmount = 0;
        var lumpSumCost = 0;
        if (bundledLines.length > 0) {
            for (var i = 0; i < bundledLines.length; i++) {
                var bundledLine = bundledLines[i];
                //non-billable <<
                //lumpSumAmount += bundledLine.xLine_Amount__c;
                if (bundledLine.Non_Billable__c != true) {
                    lumpSumAmount += bundledLine.xLine_Amount__c;
                }
                //non-billable >>
                lumpSumCost += bundledLine.xLine_Cost__c;
            }
            //bundle line pricing method <<
            /*
            if (lumpSumLine.Contract_Line__c != null) {
                lumpSumLine.Unit_Price__c = lumpSumLine.xUnit_Price__c;
            } else {
                if (lumpSumLine.Rolled_up_Unit_Price__c > lumpSumLine.Unit_Price__c) {
                    lumpSumLine.Unit_Price__c = lumpSumLine.Rolled_up_Unit_Price__c;
                }
            }

            lumpSumLine.Unit_Cost__c = lumpSumCost;
            */
            var unitPrice = 0;
            var unitCost = 0;
            if (lumpSumLine.Bundle_Pricing_Method__c == 'Per Unit') {
                if (lumpSumLine.Quantity__c > 0) {
                    unitPrice = Math.round(lumpSumAmount / lumpSumLine.Quantity__c * 100) / 100;
                    unitCost = Math.round(lumpSumCost / lumpSumLine.Quantity__c * 100) / 100;
                }
            }
            else {
                unitPrice = lumpSumAmount;
                unitCost = lumpSumCost;
            }
            if (lumpSumLine.Contract_Line__c != null) {
                unitPrice = lumpSumLine.xUnit_Price__c;
            }

            lumpSumLine.Rolled_up_Unit_Price__c = lumpSumAmount;
            if (recalculateUnitPrice == true) {
                lumpSumLine.Unit_Price__c = unitPrice;
            }
            lumpSumLine.Unit_Cost__c = unitCost;

            //bundle line pricing method >>

            //Ticket 17605 << per Stephen's email, the total rolled up cost should be the unit cost of the lump sum line
            /*
            //Temporary fix << 4.13.2020 for Quote-AS100610 (a0u1V00004fJV7BQAW), per ticket 17201. This needs to be revisited for amount-based or unit-based calcuation.
            //other than the basis issue, after rolling up line cost, and change quantity the line cost will behave like a unit cost.
            //but if then a line is added/removed from the bundle, the roll up cost will divide the quantity, such the unit cost become the rollup cost  divided by the quantity
            //if (lumpSumLine.Quantity__c != 0) {
            if (lumpSumLine.Quantity__c != 0 && lumpSumLine.Sales_Order__c != 'a0u1V00004fJV7BQAW') {
            //Temporary fix >>
                lumpSumLine.Unit_Cost__c = Math.round(lumpSumCost / lumpSumLine.Quantity__c * 100) / 100.0
            }
            */

            //Ticket 17605 >>
        } else {
            lumpSumLine.Rolled_up_Unit_Price__c = 0;
            lumpSumLine.Unit_Price__c = lumpSumLine.xUnit_Price__c;
            lumpSumLine.Unit_Cost__c = lumpSumLine.xUnit_Cost__c;
        }

        lumpSumLine.Line_Amount__c = Math.round(lumpSumLine.Unit_Price__c * lumpSumLine.Quantity__c * 100) / 100.0;
        lumpSumLine.Tax__c = 0;
        if (lumpSumLine.Tax_Group__c == 'TX') {
            lumpSumLine.Tax__c = Math.round(lumpSumLine.Line_Amount__c * lumpSumLine.Tax_Pct__c ) / 100.0;
        }
        lumpSumLine.Line_Amt_Incl_Tax__c = lumpSumLine.Line_Amount__c + lumpSumLine.Tax__c;

        lumpSumLine.Line_Cost__c = Math.round(lumpSumLine.Unit_Cost__c * lumpSumLine.Quantity__c * 100) / 100.0;

        //bundle line pricing method <<
        lumpSumLine.Profit_Margin__c = lumpSumLine.Line_Amount__c - lumpSumLine.Line_Cost__c;
        //bundle line pricing method >>

        return lumpSumLine;
    },
    calculateHours : function (startTime, endTime) {
        var hours;
        if (startTime != null && endTime != null) {
            //fix.null.fields <<
            /*
            if (startTime == endTime) {
                hours = 24;
            } else {
                hours = (endTime - startTime) / 36e5;
            }
            */
            var startTimeValue = this.timeToInteger(startTime);
            var endTimeValue = this.timeToInteger(endTime);
            if (startTimeValue == endTimeValue) {
                hours = 24;
            } else {
                hours = (endTimeValue - startTimeValue) / 36e5;
            }
            //fix.null.fields >>
        }
        else {
            hours = 0;
        }

        if (hours < 0) {
            hours += 24;
        }

        return hours;
    },
    //fix.null.fields <<
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
    },
    //fix.null.fields >>
    serializeObject : function(obj, relationship) {
        if (!obj) {
            throw 'Unable to serialize an undefined object.';
        }

        var JSONObj = JSON.stringify(obj);
        var clone = JSON.parse(JSONObj);

        if (relationship != null) {
            var relations = [];
            if (Array.isArray(relationship)) {
                relations = relationship;
            }
            else {
                relations.push(relationship);
            }

            if (Array.isArray(clone)) {
                for (var i = 0; i < relations.length; i++) {
                    for (var j = 0; j < clone.length; j++) {
                        if (clone[j].hasOwnProperty(relations[i])) {
                            var arr = clone[j][relations[i]];
                            if (!arr.hasOwnProperty('records')) {
                                var arr2 = arr;
                                arr = { totalSize: arr2.length, done: true, records: arr2 };
                            }
                            clone[j][relations[i]] = arr;
                        }
                    }
                }
            }
            else {
                for (var i = 0; i < relations.length; i++) {
                    if (clone.hasOwnProperty(relations[i])) {
                        var arr = clone[relations[i]];
                        if (!arr.hasOwnProperty('records')) {
                            var arr2 = arr;
                            arr = { totalSize: arr2.length, done: true, records: arr2 };
                        }
                        clone[relations[i]] = arr;
                    }
                }
            }
        }
        return JSON.stringify(clone);
    },
    validateFromSalesQuote : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
        this.callServerMethod(component, event, "c.validateFromSalesQuote", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);
            for (var i = 0; i < salesOrderWrapper.JobTaskWrappers.length; i++) {
                this.rollupAllLumpSumLines(salesOrderWrapper.JobTaskWrappers[i].SalesLines, true);
            }
            component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
            component.set("v.jobTaskWrappers", salesOrderWrapper.JobTaskWrappers);
        })
    },
    //job task <<
    addJobTask : function(component, event, defaultJobTaskTemplate) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrappers = component.get("v.jobTaskWrappers");
        var nextJobTaskLineNo = component.get("v.nextJobTaskLineNo");
        var taxGroup = (salesOrder.Tax_Liable__c == true ? 'TX' : 'NT');
        var nextTaskNo = 0;

        for (var i = 0; i < jobTaskWrappers.length; i++) {
            var jobTaskWrapper = jobTaskWrappers[i];
            if (jobTaskWrapper.JobTask.Task_No__c && jobTaskWrapper.JobTask.Task_No__c > nextTaskNo) {
                nextTaskNo = jobTaskWrapper.JobTask.Task_No__c;
            }
        }
        nextTaskNo++;


        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.addJobTaskCallback.bind(this, component, event) }});
        var jobTask = { "Line_No__c": nextJobTaskLineNo, "Task_No__c": nextTaskNo, "Pct_To_Bill__c": 0, "Pct_Billed__c": 0, "Tax_Group__c": taxGroup};
        var params = { "jobTask": jobTask, "mode": 'create-task-from-template', "defaultJobTaskTemplate": defaultJobTaskTemplate,"salesOrder":salesOrder };

        //ticket 19130 <<
        //this.openModal(component, event, 'New Job Task', null, buttons, 'c:JobTaskCard', params, 'medium');
        this.openModal(component, event, 'New Job Task', null, buttons, 'c:SelectJobTaskTemplateLines', params, 'medium');
        //ticket 19130 >>
    },
    addJobTaskCallback : function(component, event, jobTask, templateLines) {
        this.closeModal(component, event);

        /* disabled wizard
        var jobTaskTemplate = {"jobTaskWrapperIndex": 0, "title": jobTask.Name, "templateLines": []}; //use index 0
        for (var i = 0; i < templateLines.length; i++) {
            var templateLine = JSON.parse(JSON.stringify(templateLines[i]));
            if (templateLine.Parent_Line__r && templateLine.Parent_Line__r.Line_No__c && (!templateLine.Quantity__c || templateLine.Quantity__c == 0)) {
                templateLine.Parent_Line__r = null;
                templateLine.Parent_Line__c = null;
                jobTaskTemplate.templateLines.push(templateLine);
            }
        }
        if (jobTaskTemplate.templateLines.length > 0) {
            var jobTaskQuestionSets = [jobTaskTemplate];
            var buttons = [];
            var params = {
                "questionSets": jobTaskQuestionSets,
                "completeCallback": this.completeWizardCallback2.bind(this, component, event, jobTask, templateLines),
                "cancelCallback": this.createJobTask.bind(this, component, event, jobTask, templateLines)
            };
            this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, null, null);
        }
        else {
            this.createJobTask(component, event, jobTask, templateLines);
        }*/
        this.createJobTask(component, event, jobTask, templateLines);
    },
    /*disable wizard
    completeWizardCallback2 : function(component, event, jobTask, templateLines, jobTaskQuestionSets) {
        this.closeModal(component, event);
        var mapTemplateLinesByLineNo = new Map();
        var jobTaskQuestionSet = jobTaskQuestionSets[0];
        for (var i = 0; i < jobTaskQuestionSet.templateLines.length; i++) {
            var templateLine = jobTaskQuestionSet.templateLines[i];
            mapTemplateLinesByLineNo.set(templateLine.Line_No__c, templateLine);
        }
        for (var i = 0; i < templateLines.length; i++) {
            if (mapTemplateLinesByLineNo.has(templateLines[i].Line_No__c)) {
                var templateLine = mapTemplateLinesByLineNo.get(templateLines[i].Line_No__c);
                if (templateLine.Quantity__c) {
                    templateLines[i].Quantity__c = templateLine.Quantity__c;
                }
            }
        }
        this.createJobTask(component, event, jobTask, templateLines);
    },*/
    createJobTask : function(component, event, jobTask, templateLines) {
        this.closeModal(component, event);

        var salesOrder = component.get("v.salesOrder");
        var nextSalesLineNo = component.get("v.nextSalesLineNo");
        var jobTaskWrapper = { "JobTask": jobTask, "SalesLines": [] };
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrapper": JSON.stringify(jobTaskWrapper), "JSONJobTaskTemplateLines": JSON.stringify(templateLines), "nextSalesLineNo": nextSalesLineNo };
        this.callServerMethod(component, event, "c.createSalesLinesFromJobTaskTemplateLines", params, function (response) {
            var jobTaskWrapper = JSON.parse(response);

            /*
            for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                var salesLine = jobTaskWrapper.SalesLines[i];
                if (salesLine.Parent_Line__r) {
                    salesLine.Wizard_Question_Answered__c = true;
                }
            }*/

            jobTaskWrapper.Collapsed = false; //default to expanded
            this.sortSalesLines(jobTaskWrapper.SalesLines);
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            jobTaskWrappers.push(jobTaskWrapper);
            this.recalculateAllLines(jobTaskWrappers);
            component.set("v.jobTaskWrappers", jobTaskWrappers);

            var cmp = component.getConcreteComponent();
            cmp.set("v.selectedTabId", 'tab' + (jobTaskWrappers.length - 1));
        });
    },
    //job task >>
    //ticket 19535 << move from SaleLinecard.cmp
    calculateSalesLine : function(component, event, resolve, reject) {
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        this.callServerMethod(component, event, "c.calculateSalesLine", params, function(response) {
            var salesLine2 = JSON.parse(response);
            if (salesLine2.Category__c == 'Bundled') {
                this.recalculateLumpSumLine(component, event, salesLine2);
            }
            component.set("v.salesLine", salesLine2);
            if (resolve) {
                resolve();
            }
        })
    },
    //ticket 19535 >>
    //ticket 19130 <<
    cleanUpParentChildRelations : function(jobTaskWrapper) {
        var lineNos = [];
        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            lineNos.push(parseInt(jobTaskWrapper.SalesLines[i].Line_No__c));
        }
        var childLineNos = [];
        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            var salesLine = jobTaskWrapper.SalesLines[i];
            if (salesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r.records) {
                for (var j = 0; j < salesLine.Sales_Child_Lines__r.records.length; j++) {
                    var relation = salesLine.Sales_Child_Lines__r.records[j];
                    if (relation.Child_Line__r) {
                        var childLineNo = parseInt(relation.Child_Line__r.Line_No__c);
                        if (!lineNos.includes(childLineNo)) { //child resource line is deleted
                            salesLine.Sales_Child_Lines__r.records.splice(j, 1);
                            j--;
                        }
                        else {
                            if (!childLineNos.includes(childLineNo)) {
                                childLineNos.push(childLineNo);
                            }
                        }
                    }
                }
                salesLine.Sales_Child_Lines__r.totalSize = salesLine.Sales_Child_Lines__r.records.length;
                salesLine.Sales_Child_Lines__r.done = "true";
            }
        }

        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            var salesLine = jobTaskWrapper.SalesLines[i];
            salesLine.Dereferenced_Child_Resource__c = false;
            if (childLineNos.includes(parseInt(salesLine.Line_No__c))) {
                salesLine.Is_Child_Resource__c = true;
            } else if (salesLine.Is_Child_Resource__c == true) {
                salesLine.Dereferenced_Child_Resource__c = true;
            }
        }
    }
    //ticket 19130 >>
})