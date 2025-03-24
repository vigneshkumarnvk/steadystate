({
    getBundleLines : function(component, event) {
        var salesOrderJobTaskId = component.get("v.salesOrderJobTaskId");
        var params = { "salesOrderJobTaskId": salesOrderJobTaskId };
        this.callServerMethod(component, event, "c.getBundleLines", params, function(response) {
            var bundleLines = JSON.parse(response);
            component.set("v.bundleLines", bundleLines);
        });
    }
});