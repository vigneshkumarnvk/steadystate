({
    doInit : function(component, event, helper) {

    },
    handleNumberOfDaysChange : function(component, event, helper) {
        //helper.calculateSalesLine(component, event);
        var salesLine = component.get("v.salesLine");
        var numberOfDays = salesLine.Number_of_Day__c;
        var maxNumberOfDays = component.get("v.salesOrder.Duration__c");

        if (numberOfDays) {
            var valid = true;
            var message = '';
            if (numberOfDays > maxNumberOfDays) {
                valid = false;
                message = 'Days Needed must not exceed the duration (' + maxNumberOfDays + ' days) specified on the sales quote/order.';
                var fieldDaysNeeded = component.find("days-needed");
                if (fieldDaysNeeded) {
                    fieldDaysNeeded.rollbackValue();
                }
            } else if (numberOfDays == 0) {
                valid = false;
                message = 'Days Needed must be greater than zero.';
                var fieldDaysNeeded = component.find("days-needed");
                if (fieldDaysNeeded) {
                    fieldDaysNeeded.rollbackValue();
                }
            }
            if (valid) {
                //before-save calculation <<
                //helper.validateNumberOfDays(component, event);
                //equipment schedule lines <<
                //if (salesLine.Category__c == 'Labor') {
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                //equipment schedule lines >>
                    helper.validateNumberOfDays(component, event);
                }
                else {
                    helper.fireSalesLineUpdateEvent(component, 'Number_of_Days__c');
                }
                //before-save calculation >>
            } else {
                helper.showToast(component, "Error", message, "error", "dismissible");
            }
        }
    },
    handleQuantityChange : function(component, event, helper) {
        helper.fireSalesLineUpdateEvent(component, 'Quantity__c');
    },
    handleUOMQtyChange : function(component, event, helper) {
        helper.fireSalesLineUpdateEvent(component, 'UOM_Qty__c');
    },
    //ticket 19535 << move to SalesLineBase.cmp
    /*
    handleBillAsLumpSumChange : function(component, event, helper) {
        helper.fireSalesLineUpdateEvent(component, 'Bill_as_Lump_Sum__c');
    },
    */
    //ticket 19535 >>
    handleUnitOfMeasureChange1 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            var salesLine = component.get("v.salesLine");
            salesLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            salesLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            //equipment schedule lines <<
            //if (salesLine.Category__c == 'Labor') {
            if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
            //equipment schedule lines >>
                if (salesLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                    salesLine.UOM_Qty__c = 1;
                    if (salesLine.Sales_Line_Details__r) {
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                            salesLine.Sales_Line_Details__r.records[i].Start_Time__c = null;
                            salesLine.Sales_Line_Details__r.records[i].End_Time__c = null;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                            salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                        }
                    }
                }
                else {
                    var salesOrder = component.get("v.salesOrder");
                    if (salesLine.Sales_Line_Details__r) {
                        for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                            salesLine.Sales_Line_Details__r.records[i].Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                            salesLine.Sales_Line_Details__r.records[i].End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                            salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                            salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                        }
                    }
                }
            }
            component.set("v.salesLine", salesLine);
            helper.validateUnitOfMeasure(component, event);
        }
        else {
            component.set("v.salesLine.Unit_of_Measure__c", null);
        }
        component.set("v.salesLine.UOM_Qty__c", null);
    },
    handleUnitOfMeasureChange2 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesLine.Unit_of_Measure__c", record.Unit_of_Measure__r.Id);
            component.set("v.salesLine.Unit_of_Measure__r", record.Unit_of_Measure__r);
            component.set("v.salesLine.Facility__c", record.Facility__c);
            component.set("v.salesLine.Facility__r", record.Facility__r);
            helper.validateUnitOfMeasure(component, event);
        }
        else {
            component.set("v.salesLine.Unit_of_Measure__c", null);
        }
        component.set("v.salesLine.UOM_Qty__c", null);
    },
    handleUnitOfMeasureChange3 : function(component, event, helper) {
        var record = event.getParam("record");
        if (record) {
            component.set("v.salesLine.Unit_of_Measure__c", record.Id);
            component.set("v.salesLine.Unit_of_Measure__r", record);
            helper.validateUnitOfMeasure(component, event);
        }
        else {
            component.set("v.salesLine.Unit_of_Measure__c", null);
        }
        component.set("v.salesLine.UOM_Qty__c", null);
    },
});