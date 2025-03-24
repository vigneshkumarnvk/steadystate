({
    getSalesOrderJobTasks : function(component, event, salesOrderId) {
        var params = { "salesOrderId" : salesOrderId };
        this.callServerMethod(component, event, "c.getSalesOrderJobTasks", params, function(response) {
            var salesOrderWrapper = JSON.parse(response);
            //ticket 19674 <<
            //ticket 19852 <<
            var jobTaskWrappers = component.get("v.jobTaskWrappers");
            if (salesOrderWrapper.JobTasks.length < jobTaskWrappers.length) {
                this.showToast(component, "", "The selected sales order must have equal or more job tasks than the number of job tasks on this T&M.", "error", "dismissible");
                return;
            }
            //ticket 19852 >>
            //ticket 19674 >>
            component.set("v.salesOrder", salesOrderWrapper.SalesOrder);
            component.set("v.salesOrderJobTasks", salesOrderWrapper.JobTasks);
        })
    }
});