({
    doInit : function(component, event, helper) {
        var flatPay = {};
        component.set("v.flatPay", flatPay);
    },
    handleFlatRateTypeChange : function(component, event, helper) {
        var flatPay = component.get("v.flatPay");
        var record = event.getParam("record");
        if (record != null) {
            flatPay.Flat_Rate_Type__c = record.Id;
            flatPay.Misc_Charge_Resource__r = record.Misc_Charge_Resource__r;
            flatPay.Misc_Charge_Resource__c = record.Misc_Charge_Resource__c;
            if (record.Misc_Charge_Resource__r != null && record.Misc_Charge_Resource__r.Unit_of_Measure__r != null) {
                flatPay.Unit_of_Measure__c = record.Misc_Charge_Resource__r.Unit_of_Measure__c;
                flatPay.Unit_of_Measure__r = record.Misc_Charge_Resource__r.Unit_of_Measure__r;
            }
            flatPay.Rate__c = record.Rate__c;
        }
        else {
            flatPay.Misc_Charge_Resource__r = null;
            flatPay.Misc_Charge_Resource__c = null;
            flatPay.Flat_Rate_Type__c = null;
        }
        component.set("v.flatPay", flatPay);
    },
    handleMiscChargeResourceChange : function(component, event, helper) {
        var flatPay = component.get("v.flatPay");
        var record = event.getParam("record");
        if (record != null) {
            flatPay.Misc_Charge_Resource__c = record.Id;
        }
        else {
            flatPay.Misc_Charge_Resource__c = null;
        }
        component.set("v.flatPay", flatPay);
    },
    create : function(component, event, helper) {
        if (helper.validateFields(component, event)) {
            helper.create(component, event);
        }
    }
});