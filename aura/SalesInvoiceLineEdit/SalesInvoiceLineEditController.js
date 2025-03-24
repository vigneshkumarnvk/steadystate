({
    doInit : function(component, event, helper) {
        helper.showFields(component);
    },
    handleCategoryChange : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var newSalesInvoiceLine = {};
        newSalesInvoiceLine.Id = salesInvoiceLine.Id;
        newSalesInvoiceLine.Line_No__c = salesInvoiceLine.Line_No__c;
        newSalesInvoiceLine.Sales_Invoice__c = salesInvoiceLine.Sales_Invoice__c;
        newSalesInvoiceLine.Sales_Invoice_Job_Task__c = salesInvoiceLine.Sales_Invoice_Job_Task__c;
        newSalesInvoiceLine.Category__c = salesInvoiceLine.Category__c;
        Object.assign(salesInvoiceLine, newSalesInvoiceLine);
        helper.showFields(component);
    },
    handleResourceTypeChange : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        salesInvoiceLine.Resource_Type__c = null;
        salesInvoiceLine.Resource__c = null;
        salesInvoiceLine.Resource__r = null;
        salesInvoiceLine.Description__c = null;
        salesInvoiceLine.Unit_of_Measure__c = null;
        salesInvoiceLine.Unit_of_Measure__r = null;
        salesInvoiceLine.Quantity__c = null;

        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Resource_Type__c = record.Id;
            component.set("v.salesInvoiceLine", salesInvoiceLine);
            helper.validateResourceType(component, event, salesInvoiceLine);
        }
        else {
            component.set("v.salesInvoiceLine", salesInvoiceLine);
            helper.showFields(component);
        }
    },
    handleResourceChange : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        salesInvoiceLine.Resource__c = null;
        salesInvoiceLine.Cost_Method__c = null;
        salesInvoiceLine.Unit_Weight_Vol__c = null;
        salesInvoiceLine.Unit_Weight_Vol__r = null;
        salesInvoiceLine.Container_Size__c = null;
        salesInvoiceLine.Container_Size__r = null;

        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Resource__c = record.Id;
            helper.validateResource(component, event, salesInvoiceLine);
        }
        else {
            salesInvoiceLine.Description__c = null;
        }

        component.set("v.salesInvoiceLine", salesInvoiceLine);
        helper.showFields(component);
    },
    handleTaxGroupChange : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        helper.calculateTaxPct(component, event, salesInvoiceLine);
    },
    handleUnitOfMeasureChange1 : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Unit_of_Measure__c = record.Unit_of_Measure__r.Id;
            salesInvoiceLine.Unit_of_Measure__r = record.Unit_of_Measure__r;
            helper.calculatePriceAndCost(component, event, salesInvoiceLine);
        }
        else {
            salesInvoiceLine.Unit_of_Measure__c = null;
            salesInvoiceLine.Unit_of_Measure__r = null;
        }
        component.set("v.salesInvoiceLine", salesInvoiceLine);
        helper.showFields(component);
    },
    handleUnitOfMeasureChange3 : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Unit_of_Measure__c = record.Id;
            salesInvoiceLine.Unit_of_Measure__r = record;
            helper.calculatePriceAndCost(component, event, salesInvoiceLine);
        }
        else {
            salesInvoiceLine.Unit_of_Measure__c = null;
            salesInvoiceLine.Unit_of_Measure__r = null;
        }
        component.set("v.salesInvoiceLine", salesInvoiceLine);
        helper.showFields(component);
    },
    handleUnitPriceChange : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        if (salesInvoiceLine.Category__c == 'Subcontractors') {
            salesInvoiceLine.Unit_Cost__c = salesInvoiceLine.Unit_Price__c;
        }
        salesInvoiceLine.xUnit_Price__c = salesInvoiceLine.Unit_Price__c;
        helper.calculateLineTotals(component, salesInvoiceLine);
        component.set("v.salesInvoiceLine", salesInvoiceLine);
    },
    /*  Ticket#19931
     *    - Job times is not required for Resource Type with Rental Resource Type checked.
     */
    handleQuantityChange : function(component, event, helper) {
        var salesInvoice = component.get("v.salesInvoice");
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        if (salesInvoiceLine.Category__c == 'Labor' || (salesInvoiceLine.Resource_Type__r && salesInvoiceLine.Resource_Type__r.Fleet_No_Required__c == true && salesInvoiceLine.Resource_Type__r.Rental_Resource_Type__c != true)) {
            salesInvoiceLine.Cost_Qty__c = salesInvoiceLine.Quantity__c;
        }
        helper.calculateLineTotals(component, salesInvoiceLine);
        component.set("v.salesInvoiceLine", salesInvoiceLine);
    },
    handleNonBillableChange : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        if (salesInvoiceLine.Bill_as_Lump_Sum__c == true || salesInvoiceLine.Non_Billable__c == true) {
            salesInvoiceLine.Unit_Price__c = 0;
        }
        else {
            salesInvoiceLine.Unit_Price__c = salesInvoiceLine.xUnit_Price__c;
        }
        helper.calculateLineTotals(component, salesInvoiceLine);
        component.set("v.salesInvoiceLine", salesInvoiceLine);
    },
    handleBillAsLumpSumChange : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        if (salesInvoiceLine.Bill_as_Lump_Sum__c == true || salesInvoiceLine.Non_Billable__c == true) {
            salesInvoiceLine.Unit_Price__c = 0;
        }
        else {
            salesInvoiceLine.Unit_Price__c = salesInvoiceLine.xUnit_Price__c;
        }
        helper.calculateLineTotals(component, salesInvoiceLine);
        component.set("v.salesInvoiceLine", salesInvoiceLine);
    },
    handleCostMethodChange : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        salesInvoiceLine.Resource_UOM__c = null;
        salesInvoiceLine.Resource_UOM__r = null;
        salesInvoiceLine.Unit_Weight_Vol__c = null;
        salesInvoiceLine.Unit_Weight_Vol__r = null;
        salesInvoiceLine.Container_Size__c = null;
        salesInvoiceLine.Container_Size__r = null;
        component.set("v.salesInvoiceLine", salesInvoiceLine);
        helper.showFields(component);
    },
    handleUnitWeightVolumeChange1 : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Resource_UOM__c = record.Id;
            salesInvoiceLine.Resource_UOM__r = record;
            if (record.Unit_of_Measure__r != null) {
                salesInvoiceLine.Unit_Weight_Vol__c = record.Unit_of_Measure__c;
                salesInvoiceLine.Unit_Weight_Vol__r = record.Unit_of_Measure__r;
            }
            salesInvoiceLine.Container_Size__c = null;
            salesInvoiceLine.Container_Size__r = null;
            helper.calculatePriceAndCost(component, event, salesInvoiceLine);
        }
        else {
            salesInvoiceLine.Resource_UOM__c = null;
            salesInvoiceLine.Resource_UOM__r = null;
            salesInvoiceLine.Unit_Weight_Vol__c = null;
            salesInvoiceLine.Unit_Weight_Vol__r = null;
            salesInvoiceLine.Container_Size__c = null;
            salesInvoiceLine.Container_Size__r = null;
            component.set("v.salesInvoiceLine", salesInvoiceLine);
        }
        helper.showFields(component);
    },
    handleUnitWeightVolumeChange2 : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Unit_Weight_Vol__c = record.Unit_of_Measure__c;
            helper.calculatePriceAndCost(component, event, salesInvoiceLine);
        }
        else {
            salesInvoiceLine.Unit_Weight_Vol__c  = null;
            component.set("v.salesInvoiceLine", salesInvoiceLine);
        }
        helper.showFields(component);
    },
    handleContainerSizeChange1 : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Container_Size__c = record.Unit_of_Measure__c;
            salesInvoiceLine.Container_Size__r = record.Unit_of_Measure__r;
            helper.calculatePriceAndCost(component, event, salesInvoiceLine);
        }
        else {
            salesInvoiceLine.Container_Size__c  = null;
            salesInvoiceLine.Container_Size__r  = null;
            component.set("v.salesInvoiceLine", salesInvoiceLine);
        }
    },
    handleContainerSizeChange3 : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Container_Size__c = record.Container_Size__c;
            var containerSize = { "Id": record.Container_Size__c, "Name": record.Container_Size__r.Name };
            salesInvoiceLine.Container_Size__r = containerSize;
            helper.calculatePriceAndCost(component, event, salesInvoiceLine);
        }
        else {
            salesInvoiceLine.Container_Size__c  = null;
            salesInvoiceLine.Container_Size__r  = null;
            component.set("v.salesInvoiceLine", salesInvoiceLine);
        }
    },
    handleContainerSizeChange2 : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Container_Size__c = record.Id;
            salesInvoiceLine.Container_Size__r = record;
            helper.calculatePriceAndCost(component, event, salesInvoiceLine);
        }
        else {
            salesInvoiceLine.Container_Size__c  = null;
            salesInvoiceLine.Container_Size__r  = null;
            component.set("v.salesInvoiceLine", salesInvoiceLine);
        }
    },
    handleFacilityChange : function(component, event, helper) {
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var record = event.getParam("record");
        if (record) {
            salesInvoiceLine.Facility__c = record.Id;
            salesInvoiceLine.Facility__r = record;
            helper.calculatePriceAndCost(component, event, salesInvoiceLine);
        }
        else {
            salesInvoiceLine.Facility__c  = null;
            salesInvoiceLine.Facility__r  = null;
            component.set("v.salesInvoiceLine", salesInvoiceLine);
        }
    },
    validateFields : function(component, event, helper) {
        var fields = [];
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        if (!salesInvoiceLine.TM__c) fields.push('T&M No.');
        if (!salesInvoiceLine.Category__c) fields.push('Category');
        if (salesInvoiceLine.Category__c == 'Labor' || salesInvoiceLine.Category__c == 'Equipment') {
            if (!salesInvoiceLine.Resource_Type__c) fields.push('Resource Type');
            if (!salesInvoiceLine.Service_Center__c) fields.push('Service Center');
        }
        else {
            if (!salesInvoiceLine.Quantity__c) fields.push('Quantity');
            if (salesInvoiceLine.Category__c == 'Subcontractors') {
                if (!salesInvoiceLine.Resource__c) fields.push('Resource');
            }
        }
        if (!salesInvoiceLine.Description__c) fields.push('Billing Description');

        if (fields.length > 0) {
            helper.showToast(component, "Validation Errors", "You must complete the required fields: " + fields.join(', ') + '.', "error", "dismissible");
            return false;
        }
        return true;
    }
});