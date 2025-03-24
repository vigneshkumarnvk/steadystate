({
    getSalesOrder : function(component, event, jobTaskId) {
        var salesOrderId = component.get("v.salesOrderId");
        var salesOrderJobTaskId = component.get("v.salesOrderJobTaskId");
        var params = { "salesOrderId": salesOrderId, "salesOrderJobTaskId": salesOrderJobTaskId };
        this.callServerMethod(component, event, "c.getSalesOrder", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);
            var jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
            for (var i = 0; i < jobTaskWrappers.length; i++) {
                jobTaskWrappers[i].Collapsed = true; //default to collapsed
                for (var j = 0; j < jobTaskWrappers[i].SalesLines.length; j++) {
                    var salesLine = jobTaskWrappers[i].SalesLines[j];
                    if (salesLine.System_Calculated_Line__c == true) {
                        jobTaskWrappers[i].SalesLines.splice(j, 1);
                        j--;
                    }
                    //ticket 19130 <<
                    /*
                    else if (salesLine.Parent_Line__r && (!salesLine.Quantity__c || salesLine.Quantity__c == 0)) {
                        jobTaskWrappers[i].SalesLines.splice(j, 1);
                        j--;
                    }
                    */
                    else if (salesLine.Is_Child_Resource__c == true && (!salesLine.Quantity__c || salesLine.Quantity__c == 0)) {
                        jobTaskWrappers[i].SalesLines.splice(j, 1);
                        j--;
                    }
                    //ticket 19130 >>
                }
            }
            component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
            component.set("v.salesOrderJobTaskWrappers", jobTaskWrappers);
        })
    },
    save : function(component, event) {
        var salesOrderJobTaskWrappers = JSON.parse(JSON.stringify(component.get("v.salesOrderJobTaskWrappers"))); //make a copy
        for (var i = 0; i < salesOrderJobTaskWrappers.length; i++) {
            var salesOrderJobTaskWrapper = salesOrderJobTaskWrappers[i];
            for (var j = 0; j < salesOrderJobTaskWrapper.SalesLines.length; j++) {
                if (salesOrderJobTaskWrapper.SalesLines[j].Selected != true) {
                    salesOrderJobTaskWrapper.SalesLines.splice(j, 1);
                    j--;
                }
            }
            if (salesOrderJobTaskWrapper.SalesLines.length == 0 && salesOrderJobTaskWrapper.Selected != true) {
                salesOrderJobTaskWrappers.splice(i, 1);
                i--;
            }
        }

        if (salesOrderJobTaskWrappers.length > 0) {
            var actionParams = event.getParams().arguments;
            if (actionParams.callback) {
                actionParams.callback(salesOrderJobTaskWrappers);
            }
        } else {
            this.showToast(component, "Error", "You must choose a job task to import.", "error", "dismissible");
        }
    }
});