({
    handleWasteDisposalUnitOfMeasureChange : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");
        if (record) {

            /*Waste001
            tmLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
             */
            tmLine.Unit_of_Measure__c = record.Id;
            tmLine.Unit_of_Measure__r = record;
            //ticket 22167 <<
            tmLine.Contract_Line__c = null;
            //ticket 22167 >>
            //ticket 22134 <<
            //helper.validateUnitOfMeasure(component, event);
            var calls = [];
            calls.push(helper.validateUnitOfMeasure.bind(helper, component, event));
            calls.push(helper.fireTMLineUpdateEvent.bind(helper, component));
            helper.makeStackedCalls(component, event, helper, calls);
           
          
            //ticket 22134 >>
        } else {
            tmLine.Unit_of_Measure__c = null;
            tmLine.Unit_of_Measure__r = null;
            component.set("v.tmLine", tmLine);
        }

    },
    handleUnitWeightVolume1Change : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");
        if (record) {
            tmLine.Unit_Weight_Vol__r = record.Unit_of_Measure__r;
            tmLine.Unit_Weight_Vol__c = record.Unit_of_Measure__r.Id;
        } else {
            tmLine.Unit_Weight_Vol__r = null;
            tmLine.Unit_Weight_Vol__c = null;
        }
        component.set("v.tmLines", tmLine);
    },
    handleUnitWeightVolume2Change : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");
        if (record) {
            tmLine.Unit_Weight_Vol__c = record.Id;
        } else {
            tmLine.Unit_Weight_Vol__c = null;
        }
        component.set("v.tmLine", tmLine);
    },
    handleContainerSize1Change : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");
        if (record) {
            tmLine.Container_Size__r = record.Unit_of_Measure__r;
            tmLine.Container_Size__c = record.Unit_of_Measure__c;
        } else {
            tmLine.Container_Size__r = null;
            tmLine.Container_Size__c = null;
        }
        component.set("v.tmLine", tmLine);
    },
    handleContainerSize3Change : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");
        if (record) {
            tmLine.Container_Size__c = record.Id;
        } else {
            tmLine.Container_Size__c = null;
        }
        component.set("v.tmLine", tmLine);
    },
    handleBOLManifestChange : function(component, event, helper) {
        console.log('handle bol manifest change');
        helper.fireTMLineUpdateEvent(component);
    },
        handleFacilityChange : function(component, event, helper) {
        var record = event.getParam("record");
        var tmLine = component.get("v.tmLine");
        if (record) {
            tmLine.Facility__c = record.Id;
            tmLine.Profile_Id__c = null;
            tmLine.Approval_Id__c = null;
            tmLine.Unit_of_Measure__c = null;
             tmLine.Unit_of_Measure__r = null;
            //ticket 22134 <<
            //helper.validateUnitOfMeasure(component, event);
            var calls = [];
            calls.push(helper.validateUnitOfMeasure.bind(helper, component, event));
            calls.push(helper.fireTMLineUpdateEvent.bind(helper, component));
            helper.makeStackedCalls(component, event, helper, calls);
            //ticket 22134 >>
        } else {
            tmLine.Facility__c = null;
            tmLine.Profile_Id__c = null;
            tmLine.Approval_Id__c = null;
            tmLine.EQAI_Bill_Unit_Code__c = null;
            tmLine.Unit_of_Measure__c = null;
            tmLine.Unit_of_Measure__r = null;
            component.set("v.tmLine", tmLine);
        }
    }
});