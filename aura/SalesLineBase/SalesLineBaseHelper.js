({
    fireSalesLineUpdateEvent : function(component, field) {
        var rowIndex = component.get("v.index");
        var salesLine = component.get("v.salesLine");
        var salesLineUpdateEvent = component.getEvent("salesLineUpdateEvent");
        salesLineUpdateEvent.setParams({ "rowIndex": rowIndex, "field": field, "salesLine": salesLine });
        salesLineUpdateEvent.fire();
    },
    fireSalesLineDeleteEvent : function(component) {
        var rowIndex = component.get("v.index");
        var salesLineDeleteEvent = component.getEvent("salesLineDeleteEvent");
        salesLineDeleteEvent.setParams({ "rowIndex": rowIndex });
        salesLineDeleteEvent.fire();
    },
    fireSalesLineViewEvent : function(component) {
        var rowIndex = component.get("v.index");
        var salesLineViewEvent = component.getEvent("salesLineViewEvent");
        salesLineViewEvent.setParams({ "rowIndex": rowIndex });
        salesLineViewEvent.fire();
    }
});