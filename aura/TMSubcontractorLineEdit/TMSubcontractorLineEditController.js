({
    handleUnitPriceChange : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        /*
        var unitCost = tmLine.Unit_Cost__c;
        tmLine.Unit_Price__c = unitCost;
        tmLine.xUnit_Price__c = unitCost;
        if (tmLine.Bill_as_Lump_Sum__c == true || tmLine.Non_Billable__c == true) {
            tmLine.Unit_Price__c = 0;
        }
        */
        tmLine.xUnit_Price__c = tmLine.Unit_Price__c;
        tmLine.Unit_Cost__c = tmLine.Unit_Price__c;
        tmLine.xUnit_Cost__c = tmLine.Unit_Cost__c;
        component.set("v.tmLine", tmLine);
    }
});