({
    doInit : function(component, event, helper) {
        helper.getSalesOrder(component, event);
    },
    handleSalesOrderJobTaskChange : function(component, event, helper) {
        var record = event.getParam("record");
        if (record != null) {
            helper.getSalesOrder(component, event, record.Id);
        }
        else {
            component.set("v.salesOrderJobTaskWrapper", {});
        }
    },
    handleRowAction : function(component, event, helper) {

    },
    save : function(component, event, helper) {
        helper.save(component, event);
    }
});