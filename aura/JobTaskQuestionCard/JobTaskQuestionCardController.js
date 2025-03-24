({
    doInit : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
    },
    validateQuantity : function(component, event, helper) {

    }, 
    validateUnitOfMeasure1 : function(component, event, helper) {
        var record = event.getParam("record"); //resource type
        var answerLine = component.get("v.templateLine.answerLine");
        if (record != null) {
            answerLine.Resource_Type_UOM__c = record.Id;
            answerLine.Resource_Type_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                answerLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
                answerLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
        }
        else {
            answerLine.Resource_Type_UOM__c = null;
            answerLine.Resource_Type_UOM__r = null;
            answerLine.Unit_of_Measure__c = null;
            answerLine.Unit_of_Measure__r = null;
        }
        component.set("v.templateLine.answerLine", answerLine);
    },
    validateUnitOfMeasure2 : function(component, event, helper) {
        var record = event.getParam("record"); //resource
        var answerLine = component.get("v.templateLine.answerLine");
        if (record != null) {
            answerLine.Resource_UOM__c = record.Id;
            answerLine.Resource_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                answerLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
                answerLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
        }
        else {
            answerLine.Resource_UOM__c = null;
            answerLine.Resource_UOM__r = null;
            answerLine.Unit_of_Measure__c = null;
            answerLine.Unit_of_Measure__r = null;
        }
        component.set("v.templateLine.answerLine", answerLine);
    },
    validateUnitOfMeasure3 : function(component, event, helper) {
        var record = event.getParam("record"); //resource uom
        var answerLine = component.get("v.templateLine.answerLine");
        if (record != null) {
            answerLine.Unit_of_Measure__c = record.Id;
        }
        else {
            answerLine.Unit_of_Measure__c = null;
        }
        component.set("v.templateLine.answerLine", answerLine);
    },
    validateCostMethod : function(component, event, helper) {
        var answerLine = component.get("v.templateLine.answerLine");
        answerLine.Container_Size__r = null;
        answerLine.Container_Size__c = null;
        answerLine.Unit_Weight_Vol__r = null;
        answerLine.Unit_Weight_Vol__c = null;
        component.set("v.templateLine.answerLine", answerLine);
    },
    handleUnitWeightVolumeChange1 : function(component, event, helper) {
        var answerLine = component.get("v.templateLine.answerLine");
        var record = event.getParam("record"); //resource uom
        if (record) {
            answerLine.Resource_UOM__c = record.Id;
            answerLine.Resource_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                answerLine.Unit_Weight_Vol__c = record.Unit_of_Measure__c;
                answerLine.Unit_Weight_Vol__r = record.Unit_of_Measure__r;
            }
        }
        else {
            answerLine.Resource_UOM__c = null;
            answerLine.Resource_UOM__r = null;
            answerLine.Unit_Weight_Vol__c = null;
            answerLine.Unit_Weight_Vol__r = null;
        }

        answerLine.Container_Size__c = null;
        answerLine.Container_Size__r = null;
        component.set("v.templateLine.answerLine", answerLine);
    },
    handleUnitWeightVolumeChange2 : function(component, event, helper) {
        var answerLine = component.get("v.templateLine.answerLine");
        var record = event.getParam("record"); //uom
        if (record) {
            answerLine.Unit_Weight_Vol__c = record.Id;
        }
        else {
            answerLine.Unit_Weight_Vol__c = null;
        }
        component.set("v.templateLine.answerLine", answerLine);
    },
    handleContainerSizeChange1 : function(component, event, helper) {
        var answerLine = component.get("v.templateLine.answerLine");
        var record = event.getParam("record"); //resource uom
        if (record) {
            answerLine.Container_Size__c = record.Unit_of_Measure__c;
            answerLine.Container_Size__r = record.Unit_of_Measure__r;
        }
        else {
            component.set("v.templateLine.answerLine.Container_Size__c", null);
            component.set("v.templateLine.answerLine.Container_Size__r", null);
        }
        component.set("v.templateLine.answerLine", answerLine);
    },
    handleContainerSizeChange2 : function(component, event, helper) {
        var answerLine = component.get("v.templateLine.answerLine");
        var record = event.getParam("record"); //resource uom
        if (record) {
            answerLine.Container_Size__c = record.Container_Size__c;
            answerLine.Container_Size__r = record.Container_Size__r;
        }
        else {
            answerLine.Container_Size__c = null;
            answerLine.Container_Size__r = null;
        }
        component.set("v.templateLine.answerLine", answerLine);
    },
    handleContainerSizeChange3 : function(component, event, helper) {
        var answerLine = component.get("v.templateLine.answerLine");
        var record = event.getParam("record"); //uom
        if (record) {
            answerLine.Container_Size__c = record.Id;
            answerLine.Container_Size__r = record;
        }
        else {
            answerLine.Container_Size__c = null;
            answerLine.Container_Size__r = null;
        }
        component.set("v.templateLine.answerLine", answerLine);
    },
    handleFacilityChange : function(component, event, helper) {
        var answerLine = component.get("v.templateLine.answerLine");
        var record = event.getParam("record");
        if (record) {
            answerLine.Facility__c = record.Id;
        }
        else {
            answerLine.Facility__c = null;
        }
        component.set("v.templateLine.answerLine", answerLine);
    },
    handleTemplateLineChange : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        if (templateLine != null) {
            helper.showFields(component);
        }
        //console.log("question card: " + JSON.stringify(templateLine))
    },
    clearErrors : function(component, event, helper) {
        helper.clearErrors(component, event);
    },
    validateFields : function(component, event, helper) {
        return helper.validateFields(component, event);
    }
});