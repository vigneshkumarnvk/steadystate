({
    //ticket 19130 <<
    handleLineSelect : function(component, event, helper) {
        helper.fireSalesLineUpdateEvent(component);
    },
    //ticket 19130 >>
    deleteSalesLine : function(component, event, helper) {
        helper.fireSalesLineDeleteEvent(component);
    },
    viewSalesLine : function(component, event, helper) {
        helper.fireSalesLineViewEvent(component);
    },
    //ticket 19130 <<
    handleIsChildResourceChange : function(component, event, helper) {
        helper.fireSalesLineUpdateEvent(component);
    },
    //ticket 19130 >>
    //ticket 19535 <<
    handleBillAsLumpSumChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        if (salesLine.Bill_as_Lump_Sum__c == true) {
            salesLine.Unit_Price__c = 0;
            salesLine.Unit_Cost__c = 0;
        }
        else {
            salesLine.Unit_Cost__c = salesLine.xUnit_Cost__c;
            salesLine.Bundle_Line__c = null;
            salesLine.Bundle_Line__r = null;
        }
        if (salesLine.Non_Billable__c != true && salesLine.Bill_as_Lump_Sum__c != true) {
            salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
        }
        component.set("v.salesLine", salesLine);

        var calls = [];
        calls.push(helper.calculateSalesLine.bind(helper, component, event));
        calls.push(helper.fireSalesLineUpdateEvent.bind(helper, component, 'Bill_as_Lump_Sum__c'));
        helper.makeStackedCalls(component, event, helper, calls);

    },
    handleNonBillableChange : function(component, event, helper) {
        var salesLine = component.get("v.salesLine");
        if (salesLine.Non_Billable__c == true) {
            salesLine.Unit_Price__c = 0;
        }
        if (salesLine.Non_Billable__c != true && salesLine.Bill_as_Lump_Sum__c != true) {
            salesLine.Unit_Price__c = salesLine.xUnit_Price__c;
        }
        component.set("v.salesLine", salesLine);

        var calls = [];
        calls.push(helper.calculateSalesLine.bind(helper, component, event));
        calls.push(helper.fireSalesLineUpdateEvent.bind(helper, component, 'Non_Billable__c'));
        helper.makeStackedCalls(component, event, helper, calls);
    }
    //ticket 19535 >>
});