({
    doInit : function(component, event, helper) {
        helper.showFields(component);
    },
    validateCategory : function(component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        var lineNo = jobTaskTemplateLine.Line_No__c;
        var category = jobTaskTemplateLine.Category__c;
        jobTaskTemplateLine = { "Line_No__c": lineNo, "Category__c": category };
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    validateResourceType : function(component, event, helper) {
        var record = event.getParam("record");

        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        if (record != null) {
            jobTaskTemplateLine.Resource_Type__c = record.Id;
            jobTaskTemplateLine.Description__c = record.Description__c;
            if (record.Unit_of_Measure__r != null) {
                jobTaskTemplateLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
                jobTaskTemplateLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            }
        }
        else {
            jobTaskTemplateLine.Resource_Type__c = null;
            jobTaskTemplateLine.Description__c = null;
            jobTaskTemplateLine.Unit_of_Measure__c = null;
            jobTaskTemplateLine.Unit_of_Measure__r = null;
        }
        jobTaskTemplateLine.Resource_Type_UOM__r = null;
        jobTaskTemplateLine.Resource_Type_UOM__c = null;
        jobTaskTemplateLine.Cost_Method__c = null;
        jobTaskTemplateLine.Unit_Weight_Vol__r = null;
        jobTaskTemplateLine.Unit_Weight_Vol__c = null;
        jobTaskTemplateLine.Container_Size__r = null;
        jobTaskTemplateLine.Container_Size__c = null;

        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    validateResource : function(component, event, helper) {
        var record = event.getParam("record");

        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        if (record != null) {
            jobTaskTemplateLine.Resource__c = record.Id;
            jobTaskTemplateLine.Description__c = record.Description__c;
            if (record.Unit_of_Measure__r) {
                jobTaskTemplateLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
                jobTaskTemplateLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            }
        }
        else {
            jobTaskTemplateLine.Resource__c = null;
            jobTaskTemplateLine.Description__c = null;
            jobTaskTemplateLine.Unit_of_Measure__c = null;
            jobTaskTemplateLine.Unit_of_Measure__r = null;
        }
        jobTaskTemplateLine.Resource_UOM__c = null;
        jobTaskTemplateLine.Resource_UOM__r = null;
        jobTaskTemplateLine.Cost_Method__c = null;
        jobTaskTemplateLine.Unit_Weight_Vol__r = null;
        jobTaskTemplateLine.Unit_Weight_Vol__c = null;
        jobTaskTemplateLine.Container_Size__r = null;
        jobTaskTemplateLine.Container_Size__c = null;

        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    validateUnitOfMeasure1 : function(component, event, helper) {
        var record = event.getParam("record"); //resource type
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        if (record != null) {
            jobTaskTemplateLine.Resource_Type_UOM__c = record.Id;
            jobTaskTemplateLine.Resource_Type_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                jobTaskTemplateLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
                jobTaskTemplateLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
        }
        else {
            jobTaskTemplateLine.Resource_Type_UOM__c = null;
            jobTaskTemplateLine.Resource_Type_UOM__r = null;
            jobTaskTemplateLine.Unit_of_Measure__c = null;
            jobTaskTemplateLine.Unit_of_Measure__r = null;
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    validateUnitOfMeasure2 : function(component, event, helper) {
        var record = event.getParam("record"); //resource
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        if (record != null) {
            jobTaskTemplateLine.Resource_UOM__c = record.Id;
            jobTaskTemplateLine.Resource_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                jobTaskTemplateLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
                jobTaskTemplateLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
        }
        else {
            jobTaskTemplateLine.Resource_UOM__c = null;
            jobTaskTemplateLine.Resource_UOM__r = null;
            jobTaskTemplateLine.Unit_of_Measure__c = null;
            jobTaskTemplateLine.Unit_of_Measure__r = null;
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    validateUnitOfMeasure3 : function(component, event, helper) {
        var record = event.getParam("record"); //resource uom
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        if (record != null) {
            jobTaskTemplateLine.Unit_of_Measure__c = record.Id;
        }
        else {
            jobTaskTemplateLine.Unit_of_Measure__c = null;
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    validateCostMethod : function(component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        jobTaskTemplateLine.Container_Size__r = null;
        jobTaskTemplateLine.Container_Size__c = null;
        jobTaskTemplateLine.Unit_Weight_Vol__r = null;
        jobTaskTemplateLine.Unit_Weight_Vol__c = null;
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    handleUnitWeightVolumeChange1 : function(component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        var record = event.getParam("record"); //resource uom
        if (record) {
            jobTaskTemplateLine.Resource_UOM__c = record.Id;
            jobTaskTemplateLine.Resource_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                jobTaskTemplateLine.Unit_Weight_Vol__c = record.Unit_of_Measure__c;
                jobTaskTemplateLine.Unit_Weight_Vol__r = record.Unit_of_Measure__r;
            }
        }
        else {
            jobTaskTemplateLine.Resource_UOM__c = null;
            jobTaskTemplateLine.Resource_UOM__r = null;
            jobTaskTemplateLine.Unit_Weight_Vol__c = null;
            jobTaskTemplateLine.Unit_Weight_Vol__r = null;
        }

        jobTaskTemplateLine.Container_Size__c = null;
        jobTaskTemplateLine.Container_Size__r = null;
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    handleUnitWeightVolumeChange2 : function(component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        var record = event.getParam("record"); //uom
        if (record) {
            jobTaskTemplateLine.Unit_Weight_Vol__c = record.Id;
        }
        else {
            jobTaskTemplateLine.Unit_Weight_Vol__c = null;
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    handleContainerSizeChange1 : function(component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        var record = event.getParam("record"); //resource uom
        if (record) {
            jobTaskTemplateLine.Container_Size__c = record.Unit_of_Measure__c;
            jobTaskTemplateLine.Container_Size__r = record.Unit_of_Measure__r;
        }
        else {
            component.set("v.jobTaskTemplateLine.Container_Size__c", null);
            component.set("v.jobTaskTemplateLine.Container_Size__r", null);
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    handleContainerSizeChange2 : function(component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        var record = event.getParam("record"); //resource uom
        if (record) {
            jobTaskTemplateLine.Container_Size__c = record.Container_Size__c;
            jobTaskTemplateLine.Container_Size__r = record.Container_Size__r;
        }
        else {
            jobTaskTemplateLine.Container_Size__c = null;
            jobTaskTemplateLine.Container_Size__r = null;
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    handleContainerSizeChange3 : function(component, event, helper) {
        var jobTaskTemplateLine = component.get("v.jobTaskTemplateLine");
        var record = event.getParam("record"); //uom
        if (record) {
            jobTaskTemplateLine.Container_Size__c = record.Id;
            jobTaskTemplateLine.Container_Size__r = record;
        }
        else {
            jobTaskTemplateLine.Container_Size__c = null;
            jobTaskTemplateLine.Container_Size__r = null;
        }
        component.set("v.jobTaskTemplateLine", jobTaskTemplateLine);
    },
    handleJobTaskTemplateLineChange : function(component, event, helper) {
        helper.showFields(component);
    },
    saveTemplateLine : function(component, event, helper) {
        if (helper.validateFields(component)) {
            helper.saveTemplateLine(component, event);
        }
    }
});