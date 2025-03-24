({
    doInit : function(component, event, helper) {
        //ticket 19130 <<
        helper.initRelatedParentLines(component);
        //ticket 19130 >>
    },
    validateQuantity : function(component, event, helper) {
        //ticket 19130 <<
        var templateLine = component.get("v.templateLine");
        if (!templateLine.Quantity__c) {
            templateLine.answer = null;
        }
        component.set("v.templateLine", templateLine);
        //ticket 19130 >>
    },
    //ticket 19130 <<
    validateUOMQty : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        if (!templateLine.UOM_Qty__c) {
            templateLine.answer = null;
        }
        component.set("v.templateLine", templateLine);
    },
    //ticket 19130 >>
    /*
    validateUnitOfMeasure1 : function(component, event, helper) {
        var record = event.getParam("record"); //resource type
        var templateLine = component.get("v.templateLine");
        if (record != null) {
            templateLine.Resource_Type_UOM__c = record.Id;
            templateLine.Resource_Type_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                templateLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
                templateLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
        }
        else {
            templateLine.Resource_Type_UOM__c = null;
            templateLine.Resource_Type_UOM__r = null;
            templateLine.Unit_of_Measure__c = null;
            templateLine.Unit_of_Measure__r = null;
        }
        component.set("v.templateLine", templateLine);
    },
    validateUnitOfMeasure2 : function(component, event, helper) {
        var record = event.getParam("record"); //resource
        var templateLine = component.get("v.templateLine");
        if (record != null) {
            templateLine.Resource_UOM__c = record.Id;
            templateLine.Resource_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                templateLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
                templateLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
        }
        else {
            templateLine.Resource_UOM__c = null;
            templateLine.Resource_UOM__r = null;
            templateLine.Unit_of_Measure__c = null;
            templateLine.Unit_of_Measure__r = null;
        }
        component.set("v.templateLine", templateLine);
    },*/
    validateUnitOfMeasure3 : function(component, event, helper) {
        var record = event.getParam("record"); //resource uom
        var templateLine = component.get("v.templateLine");
        if (record != null) {
            templateLine.Unit_of_Measure__c = record.Id;
        }
        else {
            templateLine.Unit_of_Measure__c = null;
        }
        component.set("v.templateLine", templateLine);
    },
    validateCostMethod : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        templateLine.Container_Size__r = null;
        templateLine.Container_Size__c = null;
        templateLine.Unit_Weight_Vol__r = null;
        templateLine.Unit_Weight_Vol__c = null;
        component.set("v.templateLine", templateLine);
    },
    handleUnitWeightVolumeChange1 : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        var record = event.getParam("record"); //resource uom
        if (record) {
            templateLine.Resource_UOM__c = record.Id;
            templateLine.Resource_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                templateLine.Unit_Weight_Vol__c = record.Unit_of_Measure__c;
                templateLine.Unit_Weight_Vol__r = record.Unit_of_Measure__r;
            }
        }
        else {
            templateLine.Resource_UOM__c = null;
            templateLine.Resource_UOM__r = null;
            templateLine.Unit_Weight_Vol__c = null;
            templateLine.Unit_Weight_Vol__r = null;
        }

        templateLine.Container_Size__c = null;
        templateLine.Container_Size__r = null;
        component.set("v.templateLine", templateLine);
    },
    handleUnitWeightVolumeChange2 : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        var record = event.getParam("record"); //uom
        if (record) {
            templateLine.Unit_Weight_Vol__c = record.Id;
        }
        else {
            templateLine.Unit_Weight_Vol__c = null;
        }
        component.set("v.templateLine", templateLine);
    },
    handleContainerSizeChange1 : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        var record = event.getParam("record"); //resource uom
        if (record) {
            templateLine.Container_Size__c = record.Unit_of_Measure__c;
            templateLine.Container_Size__r = record.Unit_of_Measure__r;
        }
        else {
            component.set("v.templateLine.Container_Size__c", null);
            component.set("v.templateLine.Container_Size__r", null);
        }
        component.set("v.templateLine", templateLine);
    },
    handleContainerSizeChange2 : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        var record = event.getParam("record"); //resource uom
        if (record) {
            templateLine.Container_Size__c = record.Container_Size__c;
            templateLine.Container_Size__r = record.Container_Size__r;
        }
        else {
            templateLine.Container_Size__c = null;
            templateLine.Container_Size__r = null;
        }
        component.set("v.templateLine", templateLine);
    },
    handleContainerSizeChange3 : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        var record = event.getParam("record"); //uom
        if (record) {
            templateLine.Container_Size__c = record.Id;
            templateLine.Container_Size__r = record;
        }
        else {
            templateLine.Container_Size__c = null;
            templateLine.Container_Size__r = null;
        }
        component.set("v.templateLine", templateLine);
    },
    handleFacilityChange : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        var record = event.getParam("record");
        if (record) {
            templateLine.Facility__c = record.Id;
        }
        else {
            templateLine.Facility__c = null;
        }
        component.set("v.templateLine", templateLine);
    },
    handleTemplateLineChange : function(component, event, helper) {
        var templateLine = component.get("v.templateLine");
        if (templateLine != null) {
            helper.showFields(component);
            //ticket 19130 <<
            helper.initRelatedParentLines(component);
            //ticket 19130 >>
        }
        //console.log("question card: " + JSON.stringify(templateLine))
    },
    clearErrors : function(component, event, helper) {
        helper.clearErrors(component, event);
    },
    validateFields : function(component, event, helper) {
        //ticket 19130 <<
        //return helper.validateFields(component, event);
        var choice = event.getParams().arguments.YesOrNo;
        return helper.validateFields(component, event, choice);
        //ticket 19130 <<
    }
});