({
    handleSelectChange : function (component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        if (jobTaskTemplateLine.Selected != true) {
            jobTaskTemplateLine.Quantity__c = null;
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    handleQuantityChange : function (component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        if (jobTaskTemplateLine.Quantity__c != null && jobTaskTemplateLine.Quantity__c >= 0) {
            jobTaskTemplateLine.Selected = true;
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    handleClearQuantity : function (component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        if (jobTaskTemplateLine.Quantity__c) {
            jobTaskTemplateLine.Quantity__c = null;
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    }
});