({
    loadTM : function(component, event, helper) {
        var params = event.getParams().arguments;
        component.set("v.tmId", params.tmId);
        component.set("v.pageName", params.pageName);
        helper.GetData(component, event);
    },
    navigate : function(component, event, helper) {
        helper.confirmNavigate(component, event);
    },
})