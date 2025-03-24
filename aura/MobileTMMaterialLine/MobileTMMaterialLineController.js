({
    doInit : function(component, event, helper) {
    },
    handleResourceChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");

        var record = event.getParam("record");
        if (record) {
            tmLine.Resource__c = record.Id;
            tmLine.Description__c = record.Description__c;
            tmLine.Unit_of_Measure__c = record.Unit_of_Measure__c;
            tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
        }
        else {
            tmLine.Resource__c = null;
            tmLine.Description__c = null;
        }

        //Ticket#19594 >>
        tmLine.Contract_Line__c = null;
        tmLine.Quote_Line__c = null;
        tmLine.Sales_Line__c = null;
        //Ticket#19594 <<

        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    handleUnitOfMeasureChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        var record = event.getParam("record");
        if (record != null) {
            //tmLine.Unit_of_Measure__c = record.Id;
            tmLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            tmLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
        }
        else {
            tmLine.Unit_of_Measure__c = null;
        }

        //Ticket#19594 >>
        tmLine.Contract_Line__c = null;
        tmLine.Quote_Line__c = null;
        tmLine.Sales_Line__c = null;
        //Ticket#19594 <<

        component.set("v.tmLine", tmLine);
        helper.fireTMLineUpdateEvent(component, event);
    },
    doDelete : function(component, event, helper) {
        helper.fireTMLineDeleteEvent(component, event);
    }
})