({
    doInit : function(component, event, helper) {
        var tm = component.get("v.tm");
        if (tm.Sales_Order__c) {
            helper.getSalesOrderJobTasks(component, event, tm.Sales_Order__c);
        }
    },
    handleSalesOrderChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            helper.getSalesOrderJobTasks(component, event, record.Id);
        }
        else {
            component.set("v.salesOrderJobTasks", []);
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                jobTaskWrappers[i].SalsOrderJobTask = null;
            }
        }
    },
    handleRowAction : function(component, event, helper) {

    },
    save : function(component, event, helper) {
        var callback = event.getParams().arguments.callback;
        if (callback) {
            var salesOrder = component.get("v.salesOrder");
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            var ok = true;
            var dup = [];
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                //ticket 19674 <<
                //var salesOrderJobTaskId = jobTaskWrappers[i].JobTask.Sales_Order_Job_Task__c;
                var salesOrderJobTaskId = jobTaskWrappers[i].NewSalesOrderJobTaskId;
                //ticket 19674 >>
                if (salesOrderJobTaskId) {
                    if (dup.includes(salesOrderJobTaskId)) {
                        helper.showToast(component, "", "You must not link more than 1 T&M job tasks to the same sales order job task.", "error", "dismissible");
                        ok = false;
                        break;
                    }
                    dup.push(salesOrderJobTaskId);
                }
                else {
                    helper.showToast(component, "", "You must map all T&M job tasks.", "error", "dismissible");
                    ok = false;
                    break;
                }
            }
            if (!ok) {
                return;
            }

            var salesOrderJobTasks = component.get("v.salesOrderJobTasks");
            var mapSalesOrderJobTaskById = new Map();
            salesOrderJobTasks.forEach(function(salesOrderJobTask) {
                mapSalesOrderJobTaskById.set(salesOrderJobTask.Id, salesOrderJobTask);
            });

            for (var i = 0; i < jobTaskWrappers.length; i++) {
                var jobTaskWrapper = jobTaskWrappers[i];
                //ticket 19674 <<
                //var salesOrderJobTask = mapSalesOrderJobTaskById.get(jobTaskWrapper.JobTask.Sales_Order_Job_Task__c);
                var salesOrderJobTask = mapSalesOrderJobTaskById.get(jobTaskWrapper.NewSalesOrderJobTaskId);
                //ticket 19674 >>
                jobTaskWrapper.JobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
                jobTaskWrapper.JobTask.Name = salesOrderJobTask.Name;
                jobTaskWrapper.JobTask.Task_No__c = salesOrderJobTask.Task_No__c;

                //ticket 19674 <<
                jobTaskWrapper.JobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
                jobTaskWrapper.JobTask.Fixed_Price__c = salesOrderJobTask.Fixed_Price__c;
                jobTaskWrapper.JobTask.Tax_Group__c = salesOrderJobTask.Tax_Group__c;
                for (var j = 0; j < jobTaskWrapper.TMLines.length; j++) {
                    var tmLine = jobTaskWrapper.TMLines[j];
                    tmLine.Sales_Line__c = null;
                    tmLine.Sales_Line__r = null;
                    tmLine.Quote_Line__c = null;
                    tmLine.Sales_Line__r = null;
                    tmLine.Contract_Line__c = null;
                    tmLine.Contract_Line__r = null;
                    //ticket 19130 <<
                    /*
                    tmLine.Sales_Parent_Line__c = null;
                    tmLine.Sales_Parent_Line__r = null;
                    */
                    //ticket 19130 >>
                    tmLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                    tmLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                }
                //ticket 19674 >>
            }

            var tm = component.get("v.tm");
            tm.Sales_Order__c = salesOrder.Id;
            //ticket 19674 <<
            //var params = { "JSONTM": JSON.stringify(tm) };
            var params = { "JSONTM": JSON.stringify(tm), "JSONJobTaskWrappers": JSON.stringify(jobTaskWrappers) };
            //ticket 19674 >>
            helper.callServerMethod(component, event, "c.validateSalesOrder", params, function(response) {
                //ticket 19674 <<
                /*
                tm = JSON.parse(response);
                callback(tm, jobTaskWrappers);
                */
                var tmWrapper = JSON.parse(response);
                callback(tmWrapper.TM, tmWrapper.JobTaskWrappers);
                //ticket 19674 >>
            });
        }
    }
});