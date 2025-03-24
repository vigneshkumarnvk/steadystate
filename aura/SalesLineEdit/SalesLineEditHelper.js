({
    validateNumberOfDays : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesLine = component.get("v.salesLine");

        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        this.callServerMethod(component, event, "c.validateNumberOfDays", params, function(response) {
            salesLine = JSON.parse(response);
            component.set("v.salesLine", salesLine);

            //update the jobTaskWrapper with the updated sales line
            this.updateSalesLines(salesLine, jobTaskWrapper.SalesLines);

            if (salesLine.Bundle_Line__r) {
                this.rollUpLumpSum(salesLine.Bundle_Line__r.Line_No__c, jobTaskWrapper);
                this.fireJobTaskWrapperUpdateEvent(component, jobTaskWrapper);
            }
            this.fireSalesLineUpdateEvent(component, 'Number_of_Days__c');
        })
    },
    validateUnitOfMeasure : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesLine = component.get("v.salesLine");

        //fix 04.20.21 <<
        if (salesLine.Sales_Line_Details__r) {
            if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                if (salesLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                    salesLine.UOM_Qty__c = 1;

                    for (var i = 0; i < salesLine.Sales_Line_Details__r.records.length; i++) {
                        salesLine.Sales_Line_Details__r.records[i].Start_Time__c = null;
                        salesLine.Sales_Line_Details__r.records[i].End_Time__c = null;
                        salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                        salesLine.Sales_Line_Details__r.records[i].Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                        salesLine.Sales_Line_Details__r.records[i].UOM_Qty__c = salesLine.UOM_Qty__c;
                    }
                } else {
                    var salesOrder = component.get("v.salesOrder");
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
        //fix 04.20.21 >>
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        this.callServerMethod(component, event, "c.validateUnitOfMeasure", params, function(response) {
            salesLine = JSON.parse(response);
            component.set("v.salesLine", salesLine);

            //update the jobTaskWrapper with the updated sales line
            this.updateSalesLines(salesLine, jobTaskWrapper.SalesLines);

            if (salesLine.Bundle_Line__r) {
                this.rollUpLumpSum(salesLine.Bundle_Line__r.Line_No__c, jobTaskWrapper);
                this.fireJobTaskWrapperUpdateEvent(component, jobTaskWrapper);
            }
        })
    },
    fireJobTaskWrapperUpdateEvent : function(component, jobTaskWrapper) {
        var jobTaskWrapperIndex = component.get("v.jobTaskWrapperIndex");
        var jobTaskWrapperUpdateEvent = component.getEvent("jobTaskWrapperUpdateEvent");
        jobTaskWrapperUpdateEvent.setParams({ "jobTaskWrapper": jobTaskWrapper, "jobTaskWrapperIndex": jobTaskWrapperIndex });
        jobTaskWrapperUpdateEvent.fire();
    }
});