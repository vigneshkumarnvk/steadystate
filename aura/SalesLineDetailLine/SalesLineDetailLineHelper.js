({
    recalculateDetailLine : function(component, event) {
       //fire event
        var calculateSalesLineEvent = component.getEvent("calculateSalesLineEvent");
        calculateSalesLineEvent.fire();
    },
    calculateUOMQty : function(component, event) {
        var salesLineDetail = component.get("v.salesLineDetail");
        if (salesLineDetail.Start_Time__c != null && salesLineDetail.End_Time__c != null) {
            var hours = this.calculateHours(salesLineDetail.Start_Time__c, salesLineDetail.End_Time__c);
            component.set("v.salesLineDetail.UOM_Qty__c", hours);
        }
        this.recalculateDetailLine(component, event);
    },
    copyTimes : function (component, event){
        var rowIndex = component.get("v.rowIndex");
        var copyTimesEvent = component.getEvent("salesDetailLineCopyTimeEvent");
        copyTimesEvent.setParam("lineIndex", rowIndex);
        copyTimesEvent.fire();
    }
});