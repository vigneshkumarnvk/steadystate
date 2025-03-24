({
    doInit : function(component, event, helper) {
    }, 
    handleResourceTypeChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        if (record) {
            tmLine.Resource_Type__c = record.Id;
            tmLine.Description__c = record.Description__c;
            if (record.Unit_of_Measure__r != null) {
                tmLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
                tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            }
            //helper.validateResourceType(component, event, tmLine);
            helper.calculateSiteHours(component, tmLine);
            helper.calculateJobHours(component, tmLine);
            helper.calculateQuantity(component, tmLine);
        }
        else {
            tmLine.Resource_Type__c = null;
            tmLine.Description__c = null;
            tmLine.Unit_of_Measure__c = null;
            tmLine.Unit_of_Measure__r = null;
        }

        //Ticket#19594 >>
        tmLine.Contract_Line__c = null;
        tmLine.Quote_Line__c = null;
        tmLine.Sales_Line__c = null;
        //Ticket#19594 <<

        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleServiceCenterChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        if (record) {
            tmLine.Service_Center__c = record.Id;
        }
        else {
            tmLine.Service_Center__c = null;
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleResourceChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");

        var record = event.getParam("record");
        if (record) {
            tmLine.Resource__c = record.Id;
            tmLine.Resource_Name__c = record.Description__c;
            tmLine.Service_Center__c = record.Service_Center__c;
            tmLine.Service_Center__r = record.Service_Center__r;
            //if (!record.Unit_of_Measure__c) {
            //    tmLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
            //    tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            //}
            if (!tmLine.Resource_Type__r && record.Resource_Type__r) {
                tmLine.Resource_Type__c = record.Resource_Type__c;
                tmLine.Resource_Type__r = record.Resource_Type__r;
                tmLine.Description__c = record.Resource_Type__r.Description__c;
                if (!tmLine.Unit_of_Measure__r && record.Resource_Type__r.Unit_of_Measure__r) {
                    tmLine.Unit_of_Measure__c = record.Resource_Type__r.Unit_of_Measure__c;
                    tmLine.Unit_of_Measure__r = record.Resource_Type__r.Unit_of_Measure__r;
                }
            }
            helper.calculateSiteHours(component, tmLine);
            helper.calculateJobHours(component, tmLine);
            helper.calculateQuantity(component, tmLine);
            //Ticket#20410 >>
            helper.validateResource(component, event, tmLine);
            //Ticket#20410 >>
        }
        else {
            tmLine.Resource__c = null;
            tmLine.Resource_Name__c = null;
            //Ticket#20410 >>
            component.set("v.tmLine", tmLine);
            helper.fireTMLineUpdateEvent(component, event);
            //Ticket#20410 >>
        }
        //Ticket#20410 >>
        /*
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
         */
        //Ticket#20410 >>
    },
    handleJobStartTimeChange : function(component, event, helper) {
        //helper.calculateJobHours(component, event);
        var tmLine = component.get("v.tmLine");
        helper.calculateJobHours(component, tmLine);
        helper.calculateQuantity(component, tmLine);
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleJobEndTimeFocus : function(component, event, helper) {
        if (!component.get("v.tmLine.Job_End_Time__c")) {
            component.set("v.tmLine.Job_End_Time__c", component.get("v.tmLine.Site_End_Time__c"));
            setTimeout(
                $A.getCallback(function() {
                    component.set("v.tmLine.Job_End_Time__c", null);
                }
            ), 1);
        }
    },
    handleJobEndTimeChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        helper.calculateJobHours(component, tmLine);
        helper.calculateQuantity(component, tmLine);
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleSiteStartTimeFocus : function(component, event, helper) {
        if (!component.get("v.tmLine.Site_Start_Time__c")) {
            component.set("v.tmLine.Site_Start_Time__c", component.get("v.tmLine.Job_Start_Time__c"));
            setTimeout(
                $A.getCallback(function() {
                        component.set("v.tmLine.Site_Start_Time__c", null);
                    }
                ), 1);
        }
    },
    handleSiteStartTimeChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        helper.calculateSiteHours(component, tmLine);
        helper.calculateQuantity(component, tmLine);
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleSiteEndTimeFocus : function(component, event, helper) {
        if (!component.get("v.tmLine.Site_End_Time__c")) {
            component.set("v.tmLine.Site_End_Time__c", component.get("v.tmLine.Site_Start_Time__c"));
            setTimeout(
                $A.getCallback(function() {
                        component.set("v.tmLine.Site_End_Time__c", null);
                    }
                ), 1);
        }
    },
    handleSiteEndTimeChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        helper.calculateSiteHours(component, tmLine);
        helper.calculateQuantity(component, tmLine);
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleLunchStartTimeFocus : function(component, event, helper) {
        if (!component.get("v.tmLine.Lunch_Start_Time__c")) {
            component.set("v.tmLine.Lunch_Start_Time__c", '12:00:00.000Z');
            setTimeout(
                $A.getCallback(function() {
                        component.set("v.tmLine.Lunch_Start_Time__c", null);
                    }
                ), 1);
        }
    },
    handleLunchStartTimeChange : function(component, event, helper) {
        //helper.calculateSiteHours(component, event);
        //helper.calculateJobHours(component, event);
        var tmLine = component.get("v.tmLine");
        helper.calculateQuantity(component, tmLine);
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleLunchEndTimeFocus : function(component, event, helper) {
        if (!component.get("v.tmLine.Lunch_End_Time__c")) {
            component.set("v.tmLine.Lunch_End_Time__c", component.get("v.tmLine.Lunch_Start_Time__c"));
            setTimeout(
                $A.getCallback(function() {
                        component.set("v.tmLine.Lunch_End_Time__c", null);
                    }
                ), 1);
        }
    },
    handleLunchEndTimeChange : function(component, event, helper) {
        //helper.calculateSiteHours(component, event);
        //helper.calculateJobHours(component, event);
        var tmLine = component.get("v.tmLine");
        helper.calculateQuantity(component, tmLine);
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleServiceCenterChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        if (record) {
            tmLine.Service_Center__c = record.Id;

            if (tmLine.Category__c === 'Equipment') {
                helper.calculateFleetNotRequired(tmLine);
            }
        }
        else {
            tmLine.Service_Center__c = null;
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);
    },
    handleUnitOfMeasure1Change : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        if (record) {
            tmLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            helper.calculateSiteHours(component, tmLine);
            helper.calculateJobHours(component, tmLine);
            helper.calculateQuantity(component, tmLine);
        }
        else {
            tmLine.Unit_of_Measure__c = null;
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);
    },
    handleUnitOfMeasureChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        if (record) {
            tmLine.Unit_of_Measure__c = record.Id;
            helper.calculateSiteHours(component, tmLine);
            helper.calculateJobHours(component, tmLine);
            helper.calculateQuantity(component, tmLine);
        }
        else {
            tmLine.Unit_of_Measure__c = null;
        }
        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component);
    },
    doDelete : function(component, event, helper) {
        helper.fireTMLineDeleteEvent(component, event);
    },
    doCopyTime : function(component, event, helper) {
        var rowIndex = component.get("v.rowIndex")
        var copyTimeEvent = component.getEvent("copyTimeEvent");
        copyTimeEvent.setParams({ "rowIndex": rowIndex });
        copyTimeEvent.fire();
    }
})