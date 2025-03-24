({
    afterRender : function(component, helper) {
        this.superAfterRender();
        var collapsible = component.get("v.collapsible");
        var sorts = component.get("v.sorts");
        if (collapsible == true || (sorts != null && sorts.length > 0)) {
            //console.log("FlexDataTable: afterRender");
            helper.calculateRowOrders(component, true);
        }
    }
});