({
    createSalesLinesFromTemplate : function(component, event) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        jobTaskWrapper.JobTask.Job_Task_Template__c = null;
        jobTaskWrapper.JobTask.Job_Task_Template__r = null;
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.createSalesLinesFromTemplateCallback.bind(this, component, event) }});
        var params = { "jobTask": jobTaskWrapper.JobTask, "mode": 'create-lines-from-template' };
        //ticket 19130 <<
        //this.openModal(component, event, 'Create Lines', null, buttons, 'c:JobTaskCard', params, 'medium');
        this.openModal(component, event, 'Create Lines', null, buttons, 'c:SelectJobTaskTemplateLines', params, 'medium');
        //ticket 19130 >>
    },
    /*
    createSalesLinesFromTemplateCallback : function(component, event, jobTask, templateLines) {
        try {
            var salesOrder = component.get("v.salesOrder");
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            var nextSalesLineNo = component.get("v.nextSalesLineNo");

            jobTaskWrapper.JobTask.Name = jobTask.Name;
            jobTaskWrapper.JobTask.Billing_Type__c = jobTask.Billing_Type__c;
            jobTaskWrapper.JobTask.Fixed_Price__c = jobTask.Fixed_Price__c;
            jobTaskWrapper.JobTask.Job_Task_Template__c = jobTask.Job_Task_Template__c;
            jobTaskWrapper.JobTask.Job_Task_Template__r = jobTask.Job_Task_Template__r;

            var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrapper": JSON.stringify(jobTaskWrapper), "JSONJobTaskTemplateLines": JSON.stringify(templateLines), "nextSalesLineNo": nextSalesLineNo };
            this.callServerMethod(component, event, "c.createSalesLinesFromJobTaskTemplateLines", params, function (response) {
                var jobTaskWrapper = JSON.parse(response);
                jobTaskWrapper.Collapsed = false; //default to expanded
                this.sortSalesLines(jobTaskWrapper.SalesLines);
                component.set("v.jobTaskWrapper", jobTaskWrapper);
                this.fireJobTaskWrapperUpdateEvent(component, event);
            });
        }
        finally {
            this.closeModal(component, event);
        }
    },
    */
    createSalesLinesFromTemplateCallback : function(component, event, jobTask, templateLines) {
        this.closeModal(component, event);
        /* disable wizard
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
                "completeCallback": this.completeWizardCallback.bind(this, component, event, jobTask, templateLines),
                "cancelCallback": this.insertSalesLinesFromSelectedTemplateLines.bind(this, component, event, jobTask, templateLines)
            };
            this.openModal(component, event, "Wizard", null, buttons, "c:Wizard", params, null, null);
        }
        else {
            this.insertSalesLinesFromSelectedTemplateLines(component, event, jobTask, templateLines);
        }
        */

        this.insertSalesLinesFromSelectedTemplateLines(component, event, jobTask, templateLines);
    },
    completeWizardCallback : function(component, event, jobTask, templateLines, jobTaskQuestionSets) {
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
        this.insertSalesLinesFromSelectedTemplateLines(component, event, jobTask, templateLines);
    },
    insertSalesLinesFromSelectedTemplateLines : function(component, event, jobTask, templateLines) {
        try {
            var salesOrder = component.get("v.salesOrder");
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            var nextSalesLineNo = component.get("v.nextSalesLineNo");

            jobTaskWrapper.JobTask.Name = jobTask.Name;
            jobTaskWrapper.JobTask.Billing_Type__c = jobTask.Billing_Type__c;
            jobTaskWrapper.JobTask.Fixed_Price__c = jobTask.Fixed_Price__c;
            jobTaskWrapper.JobTask.Job_Task_Template__c = jobTask.Job_Task_Template__c;
            jobTaskWrapper.JobTask.Job_Task_Template__r = jobTask.Job_Task_Template__r;
            var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrapper": JSON.stringify(jobTaskWrapper), "JSONJobTaskTemplateLines": JSON.stringify(templateLines), "nextSalesLineNo": nextSalesLineNo };
            this.callServerMethod(component, event, "c.createSalesLinesFromJobTaskTemplateLines", params, function (response) {
                var jobTaskWrapper = JSON.parse(response);
                jobTaskWrapper.Collapsed = false; //default to expanded
                this.sortSalesLines(jobTaskWrapper.SalesLines);
                //ticket 19130 <<
                this.cleanUpParentChildRelations(jobTaskWrapper);
                //ticket 19130 >>
                component.set("v.jobTaskWrapper", jobTaskWrapper);
                this.fireJobTaskWrapperUpdateEvent(component, event);
            });
        }
        finally {
            this.closeModal(component, event);
        }
    },
    editJobTask : function(component, event) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "save", "callback": this.editJobTaskCallback.bind(this, component, event) }});
        var params = { "jobTask": jobTaskWrapper.JobTask, "mode": 'edit-task' };
        //ticket 19130 <<
        //this.openModal(component, event, 'Edit Task', null, buttons, 'c:JobTaskCard', params, 'small');
        this.openModal(component, event, 'Edit Task', null, buttons, 'c:SelectJobTaskTemplateLines', params, 'small');
        //ticket 19130 >>
    },
    editJobTaskCallback : function(component, event, jobTask) {
        this.closeModal(component, event);
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        jobTaskWrapper.JobTask.Name = jobTask.Name;
        jobTaskWrapper.JobTask.Billing_Type__c = jobTask.Billing_Type__c;
        jobTaskWrapper.JobTask.Fixed_Price__c = jobTask.Fixed_Price__c;
        component.set("v.jobTaskWrapper", jobTaskWrapper);
    },
    fireCloneJobTaskEvent : function(component, event) {
        var jobTaskWrapperIndex = component.get("v.jobTaskWrapperIndex");
        var jobTaskWrapperCloneEvent = component.getEvent("jobTaskWrapperCloneEvent");
        jobTaskWrapperCloneEvent.setParams({ "jobTaskWrapperIndex": jobTaskWrapperIndex });
        jobTaskWrapperCloneEvent.fire();
    },
    fireDeleteJobTaskEvent : function(component, event) {
        var jobTaskWrapperIndex = component.get("v.jobTaskWrapperIndex");
        var jobTaskWrapperDeleteEvent = component.getEvent("jobTaskWrapperDeleteEvent");
        jobTaskWrapperDeleteEvent.setParams({ "jobTaskWrapperIndex": jobTaskWrapperIndex });
        jobTaskWrapperDeleteEvent.fire();
    },
    addSalesLine : function(component, event, jobTaskWrapper, linesAdded) {
        var salesOrder = component.get("v.salesOrder");
        //var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var jobTasks = component.get("v.jobTasks"); //for job task selection list
        var nextSalesLineNo = component.get("v.nextSalesLineNo");
        var defaultCategory = component.get("v.defaultCategory");
        //contract specific resource <<
        //var userInfoWrapper = component.get("v.userInfoWrapper");
        var setupData = component.get("v.setupData");
        //console.log(JSON.stringify(setupData))
        //contract specific resource >>
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTask": JSON.stringify(jobTaskWrapper.JobTask), "category": defaultCategory, "nextSalesLineNo": nextSalesLineNo };
        this.callServerMethod(component, event, "c.newSalesLine", params, function(salesLine) {
            nextSalesLineNo++;
            var defaultCategory = component.get("v.defaultCategory");
            //contract specific resource <<
            //var params = { "mode": 'add', "salesOrder": salesOrder, "jobTaskWrapper": jobTaskWrapper, "jobTasks": jobTasks, "salesLine": JSON.parse(salesLine), "userInfoWrapper": userInfoWrapper, "nextSalesLineNo": nextSalesLineNo, "linesAdded": linesAdded};
            var params = { "mode": 'add', "salesOrder": salesOrder, "jobTaskWrapper": jobTaskWrapper, "jobTasks": jobTasks, "salesLine": JSON.parse(salesLine), "setupData": setupData, "nextSalesLineNo": nextSalesLineNo, "linesAdded": linesAdded};
            //contract specific resource >>
            var buttons = [];
            buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": {"callback": this.cancelAddSalesLineCallback.bind(this, component, event, jobTaskWrapper, linesAdded) }});
            buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "saveSalesLine", "callback": this.addSalesLineCallback.bind(this, component, event, false) }});
            buttons.push({ "label": 'Save & New', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "saveSalesLine", "callback": this.addSalesLineCallback.bind(this, component, event, true) }});
            this.openModal(component, event, 'New Sales Line', null, buttons, 'c:SalesLineCard', params, 'large');
        });
    },
    addSalesLineCallback : function (component, event, doNewLine, jobTaskWrapper, linesAdded, category) {
        try {
            var nextSalesLineNo = component.get("v.nextSalesLineNo");
            for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                if (nextSalesLineNo < jobTaskWrapper.SalesLines[i].Line_No__c) {
                    nextSalesLineNo = jobTaskWrapper.SalesLines[i].Line_No__c;
                }
            }
            nextSalesLineNo++;
            component.set("v.nextSalesLineNo", nextSalesLineNo);
        } catch (error) {
            alert(error);
        } finally {
            if (doNewLine) {
                component.set("v.defaultCategory", category);
                this.closeModal(component, event);
                this.addSalesLine(component, event, jobTaskWrapper, linesAdded);
            } else {
                component.set("v.defaultCategory", null);
                this.calculateSalesOrderJobTask(component, event, jobTaskWrapper);
                this.closeModal(component, event);
            }
        }
    },
    cancelAddSalesLineCallback : function (component, event, jobTaskWrapper, linesAdded) {
        this.closeModal(component, event);
        if (linesAdded == true) { //check if there has been a data change. Cancel can happen after multiple creation of new lines
            this.calculateSalesOrderJobTask(component, event, jobTaskWrapper);
        }
    },
    editSalesLine : function (component, event, rowIndex) {
        try {
            var salesOrder = component.get("v.salesOrder");
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            var jobTasks = component.get("v.jobTasks"); //for job task selection list
            //contract specific resource <<
            //var userInfoWrapper = component.get("v.userInfoWrapper");
            var setupData = component.get("v.setupData");
            //contract specific resource >>
            var nextSalesLineNo = component.get("v.nextSalesLineNo");

            var salesLine = jobTaskWrapper.SalesLines[rowIndex];
            //contract specific resource <<
            //var params = { "mode": 'edit', "salesOrder": salesOrder, "jobTaskWrapper": jobTaskWrapper, "jobTasks": jobTasks, "salesLine": salesLine, "userInfoWrapper": userInfoWrapper };
            var params = { "mode": 'edit', "salesOrder": salesOrder, "jobTaskWrapper": jobTaskWrapper, "jobTasks": jobTasks, "salesLine": salesLine, "setupData": setupData, "nextSalesLineNo": nextSalesLineNo  };
            //contract specific resource >>

            var buttons = [];
            buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": {"callback": this.cancelCallback.bind(this, component, event) }});
            //job task <<
            //if (salesLine.System_Calculated_Line__c != true || salesLine.Category__c == 'Waste Disposal') {
            //ticket 19130 <<
            /*
            if ((salesLine.System_Calculated_Line__c != true
                        || salesLine.Category__c == 'Waste Disposal'
                        || salesLine.Parent_Line__r != null
                        || salesLine.Resource__c == setupData['CompanySetting'].Rinse_Out_Fee_Resource_Id__c)
                    && salesOrder.Document_Status__c != 'Closed' && salesOrder.Approval_Status__c != 'Pending_Approval' && salesOrder.Expired__c != true) {
             */
            if ((salesLine.System_Calculated_Line__c != true
                || salesLine.Category__c == 'Waste Disposal'
                || salesLine.Is_Child_Resource__c == true
                || salesLine.Resource__c == setupData['CompanySetting'].Rinse_Out_Fee_Resource_Id__c)
                && salesOrder.Document_Status__c != 'Closed' && salesOrder.Approval_Status__c != 'Pending_Approval' && salesOrder.Expired__c != true) {
                //ticket 19130 >>
                //job task >>
                buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "saveSalesLine", "callback": this.editSalesLineCallback.bind(this, component, event) }});
            }
            this.openModal(component, event, 'Edit Sales Line', null, buttons, 'c:SalesLineCard', params, 'large');
        } catch (error) {
            alert(error);
        }
    },
    editSalesLineCallback : function (component, event, jobTaskWrapper, salesLine) {
        try {
            var nextSalesLineNo = component.get("v.nextSalesLineNo");
            for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                if (nextSalesLineNo < jobTaskWrapper.SalesLines[i].Line_No__c) {
                    nextSalesLineNo = jobTaskWrapper.SalesLines[i].Line_No__c;
                }
            }
            nextSalesLineNo++;
            component.set("v.nextSalesLineNo", nextSalesLineNo);

            //roll up lump sum only when the child bundled lines are edited/deleted
            if (salesLine.Bundle_Line__r) {
                this.rollUpLumpSum(salesLine.Bundle_Line__r.Line_No__c, jobTaskWrapper);
            }
            this.calculateSalesOrderJobTask(component, event, jobTaskWrapper);
        } catch (error) {
            alert(error);
        } finally {
            this.closeModal(component, event);
        }
    },
    deleteSalesLine : function (component, event, rowIndex) {
        var buttons = [];
        buttons.push({ "label": 'OK', "variant": 'brand', "action": {"callback": this.deleteSalesLineCallback.bind(this, component, event, rowIndex) }});
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": {"callback": this.cancelCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Delete Sales Line', 'Are you sure you want to delete this sales line?', buttons, null, null, null);
    },
    deleteSalesLineCallback : function (component, event, rowIndex) {
        try {
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            this.deleteLines(jobTaskWrapper, [rowIndex]);
            this.calculateSalesOrderJobTask(component, event, jobTaskWrapper);
        } catch (error) {
            alert(error);
        } finally {
            this.closeModal(component, event);
        }
    },
    confirmDeleteSalesLines : function(component, event) {
        var rowIndexes = [];
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            if (jobTaskWrapper.SalesLines[i].Selected == true) {
                rowIndexes.push(i);
            }
        }

        if (rowIndexes.length > 0) {
            var buttons = [];
            buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'OK', "variant": 'brand', "action": { "callback": this.confirmDeleteSalesLinesCallback.bind(this, component, event, rowIndexes) }});
            this.openModal(component, event, 'Delete Lines', 'Are you sure you want to delete selected lines?', buttons, null, null, null);
        }
    },
    confirmDeleteSalesLinesCallback : function(component, event, rowIndexes) {
        this.closeModal(component, event);
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        this.deleteLines(jobTaskWrapper, rowIndexes);
        this.calculateSalesOrderJobTask(component, event, jobTaskWrapper);
    },
    deleteLines : function(jobTaskWrapper, rowIndexes) {
        rowIndexes.sort();
        for (var i = rowIndexes.length - 1; i >= 0; i--) {
            var rowIndex = rowIndexes[i];
            var targetSalesLine = jobTaskWrapper.SalesLines[rowIndex];

            jobTaskWrapper.SalesLines.forEach(function(salesLine) {
                if (targetSalesLine.Category__c == 'Bundled') {
                    if (salesLine.Bundle_Line__r != null && salesLine.Bundle_Line__r.Line_No__c == targetSalesLine.Line_No__c) {
                        salesLine.Bundle_Line__c = null;
                        salesLine.Bundle_Line__r = null;
                        salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
                        salesLine.Unit_Cost__c = salesLine.xUnit_Cost__c;
                        salesLine.Bill_as_Lump_Sum__c = false;
                    }
                }

                //ticket 19130 <<
                /*
                if (salesLine.Parent_Line__r && salesLine.Parent_Line__r.Line_No__c == targetSalesLine.Line_No__c) {
                    //remove linkage
                    salesLine.Parent_Line__c = null;
                    salesLine.Parent_Line__r = null;
                }
                */
                //ticket 19130 >>
            });

            jobTaskWrapper.SalesLines.splice(rowIndex, 1);

            //ticket 19130 <<
            this.cleanUpParentChildRelations(jobTaskWrapper);
            //ticket 19130 >>

            //roll up lump sum only when the child bundled lines are edited/deleted
            if (targetSalesLine.Bundle_Line__r) {
                this.rollUpLumpSum(targetSalesLine.Bundle_Line__r.Line_No__c, jobTaskWrapper);
            }
        }
    },
    cancelCallback : function (component, event) {
        this.closeModal(component, event);
    },
    calculateTax : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");

        if (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price' && salesOrder.Tax_Area__c != null && salesOrder.Tax_Liable__c == true && jobTaskWrapper.JobTask.Tax_Group__c == 'TX') {
            var params = {
                "JSONSalesOrder": JSON.stringify(salesOrder),
                "JSONJobTaskWrapper": JSON.stringify(jobTaskWrapper)
            };
            this.callServerMethod(component, event, "c.calculateTax", params, function (response) {
                var jobTaskWrapper2 = JSON.parse(response);
                component.set("v.jobTaskWrapper.JobTask", jobTaskWrapper2.JobTask);

                //ticket 19672 <<
                this.calculateTotals(component, event);
                //ticket 19672 >>
                this.fireJobTaskWrapperUpdateEvent(component, event);
            });
        }
        else {
            jobTaskWrapper.JobTask.Tax__c = 0;
            jobTaskWrapper.JobTask.Tax_Pct__c = 0;
            component.set("v.jobTaskWrapper.JobTask", jobTaskWrapper.JobTask);

            //ticket 19672 <<
            this.calculateTotals(component, event);
            //ticket 19672 >>

            this.fireJobTaskWrapperUpdateEvent(component, event);
        }
    },
    handleBillAsLumpSumChange : function (component, event, rowIndex) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesLine = jobTaskWrapper.SalesLines[rowIndex];
        if (salesLine.Bill_as_Lump_Sum__c != true && salesLine.Bundle_Line__r) {
            var lumpSumLineNo = salesLine.Bundle_Line__r.Line_No__c;

            salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
            salesLine.Unit_Cost__c = salesLine.xUnit_Cost__c;
            salesLine.Bundle_Line__c = null;
            salesLine.Bundle_Line__r = null;

            //before save calculation <<
            //this.calculateSalesLineAndJobTask(component, event, jobTaskWrapper, rowIndex, lumpSumLineNo);
            //before save calculation >>
        }
    },
    calculateSalesLineAndJobTask : function(component, event, jobTaskWrapper, rowIndex, lumpSumLineNo) {
        var salesOrder = component.get("v.salesOrder");
        var nextSalesLineNo = component.get("v.nextSalesLineNo");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrapper": JSON.stringify(jobTaskWrapper), "rowIndex": rowIndex, "nextSalesLineNo": nextSalesLineNo };
        this.callServerMethod(component, event, "c.calculateSalesOrderJobTask", params, function(response) {
            jobTaskWrapper = JSON.parse(response);
            if (lumpSumLineNo) {
                //roll up lump sum only when the child bundled lines are edited/deleted
                this.rollUpLumpSum(lumpSumLineNo, jobTaskWrapper);
            }
            this.sortSalesLines(jobTaskWrapper.SalesLines);
            component.set("v.jobTaskWrapper", jobTaskWrapper);
            this.fireJobTaskWrapperUpdateEvent(component, event);
        })
    },
    calculateSalesOrderJobTask : function(component, event, jobTaskWrapper) {
        var salesOrder = component.get("v.salesOrder");
        var nextSalesLineNo = component.get("v.nextSalesLineNo");
        var params = { "JSONSalesOrder": JSON.stringify(salesOrder), "JSONJobTaskWrapper": JSON.stringify(jobTaskWrapper), "nextSalesLineNo": nextSalesLineNo };
        this.callServerMethod(component, event, "c.calculateSalesOrderJobTask", params, function(response) {
            var jobTaskWrapper = JSON.parse(response);
            this.sortSalesLines(jobTaskWrapper.SalesLines);
            //ticket 19130 <<
            this.cleanUpParentChildRelations(jobTaskWrapper);
            //ticket 19130 >>
            component.set("v.jobTaskWrapper", jobTaskWrapper);
            this.fireJobTaskWrapperUpdateEvent(component, event);
        });
    },
    fireJobTaskWrapperUpdateEvent : function(component, event) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var jobTaskWrapperIndex = component.get('v.jobTaskWrapperIndex');
        var jobTaskWrapperUpdateEvent = component.getEvent("jobTaskWrapperUpdateEvent");
        jobTaskWrapperUpdateEvent.setParams({ "jobTaskWrapper": jobTaskWrapper, "jobTaskWrapperIndex": jobTaskWrapperIndex, "sourceComponent": 'SalesOrderJobTaskLine' });
        jobTaskWrapperUpdateEvent.fire();
    },
    calculateTotals : function(component, event) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var totalAmount = 0;
        var totalTax = 0;
        var totalAmountIncludingTax = 0;
        var totalCost = 0;

        if (jobTaskWrapper) {
            for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                var salesLine = jobTaskWrapper.SalesLines[i];

                var rollupAmount = true;
                var rollupCost = true;
                if (salesLine.Bill_as_Lump_Sum__c == true) {
                    rollupAmount = false;
                    rollupCost = false;
                } else if (salesLine.Non_Billable__c == true) {
                    rollupAmount = false;
                }

                if (rollupAmount || rollupCost) {
                    if (rollupAmount) {
                        totalAmount += salesLine.Line_Amount__c;
                        totalTax += salesLine.Tax__c;
                        totalAmountIncludingTax += salesLine.Line_Amt_Incl_Tax__c;
                    }
                    if (rollupCost) {
                        totalCost += salesLine.Line_Cost__c;
                    }
                }
            }
            component.set("v.jobTaskWrapper.JobTask.Rolled_Up_Sales_Lines_Amount__c", totalAmount);


            //ticket 19672 <<
            //overwrite total amount if the job task is fixed price
            if (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price') {
                totalAmount = 0;
                totalTax = 0;
                totalAmountIncludingTax = 0;
                if (jobTaskWrapper.JobTask.Fixed_Price__c) {
                    totalAmount = parseFloat(jobTaskWrapper.JobTask.Fixed_Price__c);
                }
                if (jobTaskWrapper.JobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge' && jobTaskWrapper.JobTask.Surcharge_Amount__c) {
                    totalAmount += parseFloat(jobTaskWrapper.JobTask.Surcharge_Amount__c);
                }
                if (jobTaskWrapper.JobTask.Tax__c) {
                    totalTax = parseFloat(jobTaskWrapper.JobTask.Tax__c);
                }
                totalAmountIncludingTax = totalAmount + totalTax;
            }
            //ticket 19672 >>
        }

        var totalProfit = 0;
        if (totalAmount != 0) {
            totalProfit = 1 - totalCost / totalAmount;
        }

        component.set("v.totalAmount", totalAmount);
        component.set("v.totalTax", totalTax);
        component.set("v.totalAmountIncludingTax", totalAmountIncludingTax);
        component.set("v.totalCost", totalCost);
        component.set("v.totalProfit", totalProfit);
    },
    //ticket 19130 <<
    resetWizardQuestionAnswered : function (component, jobTaskWrapper, salesLine) {
        //prompt question for all child resource when a parent resource is changed 05.09.23
        salesLine.Wizard_Question_Answered__c = false;
        if (salesLine.Sales_Child_Lines__r) {
            var childLineNos = [];
            for (var i = 0; i < salesLine.Sales_Child_Lines__r.records.length; i++) {
                childLineNos.push(salesLine.Sales_Child_Lines__r.records[i].Child_Line__r.Line_No__c);
            }
            if (childLineNos.length > 0) {
                for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                    if (childLineNos.includes(jobTaskWrapper.SalesLines[i].Line_No__c)) {
                        jobTaskWrapper.SalesLines[i].Wizard_Question_Answered__c = false;
                    }
                }
            }
        }
    }
    //ticket 19130 >>
})