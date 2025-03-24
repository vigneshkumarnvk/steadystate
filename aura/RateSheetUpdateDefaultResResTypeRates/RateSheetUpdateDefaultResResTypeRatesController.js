({
    doInit : function (component, event, helper) {
        var pageRef = component.get("v.pageReference");
        var rateSheetId = pageRef.state.c__id;
        component.set("v.rateSheetId", rateSheetId);
        helper.promptQuestion(component, event);
    },
});