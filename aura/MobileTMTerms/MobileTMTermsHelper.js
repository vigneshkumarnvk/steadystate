({
    getSalesOrder : function(component, event) {
        let salesOrderId = component.get("v.salesOrderId");
        let params = { "salesOrderId": salesOrderId }
        this.callServerMethod(component, event, "c.getSalesOrder", params, function(response) {
            component.set("v.salesOrder", JSON.parse(response));
        })
    }
});