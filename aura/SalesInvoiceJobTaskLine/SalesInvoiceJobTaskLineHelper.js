({
    newSalesInvoiceLine : function(component) {
        var salesInvoice = component.get("v.salesInvoice");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var setupData = component.get("v.setupData");
        var nextInvoiceLineNo = component.get("v.nextInvoiceLineNo");

        var salesInvoiceLine = { };
        var resource;
        switch (salesInvoiceLine.Category__c) {
            case 'Waste Disposal':
                resource = setupData.CompanySetup.Default_Waste_Disposal_Resource__r;
                break;
            case 'Bundled':
                resource = setupData.CompanySetup.Default_Lump_Sum_Resource__r;
                break;
            case 'Misc. Charges And Taxes':
                resource = setupData.CompanySetup.Default_Misc_Charges_Taxes_Resource__r;
                break;
            case 'Subcontractors':
                resource = setupData.CompanySetup.Default_Subcontractor_Resource__r;
                break;
            default:
                resource = null;
        }
        if (resource) {
            salesInvoiceLine.Resource__c = resource.Id;
            salesInvoiceLine.Resource__r = resource;
            salesInvoiceLine.Description__c = resource.Name;
            salesInvoiceLine.Unit_of_Measure__c = resource.Unit_of_Measure__c;
            salesInvoiceLine.Unit_of_Measure__r = resource.Unit_of_Measure__r;
            salesInvoiceLine.Unit_Cost__c = resource.Unit_Cost__c;
        }

        salesInvoiceLine.Sales_Invoice__c = salesInvoice.Id;
        salesInvoiceLine.Sales_Invoice__r = salesInvoice;
        salesInvoiceLine.Sales_Invoice_Job_Task__c = jobTaskWrapper.JobTask.Id;
        salesInvoiceLine.Line_No__c = nextInvoiceLineNo;
        salesInvoiceLine.Service_Center__c = salesInvoice.Service_Center__c;
        salesInvoiceLine.Service_Center__r = salesInvoice.Service_Center__r;
        salesInvoiceLine.Quantity__c = null;
        salesInvoiceLine.Unit_Price__c = null;
        salesInvoiceLine.Tax_Group__c = 'TX';
        salesInvoiceLine.Cost_Method__c = null;
        salesInvoiceLine.Unit_Weight_Vol__c = null;
        salesInvoiceLine.Unit_Weight_Vol__r = null;
        salesInvoiceLine.Container_Size__c = null;
        salesInvoiceLine.Container_Size__r = null;
        salesInvoiceLine.Facility__c = null;
        salesInvoiceLine.Facility__r = null;
        salesInvoiceLine.BOL_Manifest__c = null;

        nextInvoiceLineNo++;
        component.set("v.nextInvoiceLineNo", nextInvoiceLineNo);

        return salesInvoiceLine;
    },
    openInlineEdit : function(component, rowIndex, resolve, reject) {
        var datatable = component.find("datatable");
        datatable.openInlineEdit(rowIndex);
        if (resolve) {
            resolve();
        }
    },
    closeInlineEdit : function(component, resolve, reject) {
        this.calculateJobTotals(component);
        if (resolve) {
            resolve();
        }
    },
    refreshTable : function(component, event) {
        var datatable = component.find("datatable");
        datatable.refreshTable();
    },
    calculateJobTotals : function(component) {
        this.calculateTotals(component);
        this.fireSalesInvoiceLinesChangedEvent(component);
    },
    fireSalesInvoiceLinesChangedEvent : function(component) {
        var salesInvoiceLinesChangedEvent = component.getEvent("salesInvoiceLinesChangedEvent");
        salesInvoiceLinesChangedEvent.fire();
    },
    calculateTotals : function(component) {
        var total = 0;
        var totalInclTax = 0;
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        if (jobTaskWrapper) {
            jobTaskWrapper.SalesInvoiceLines.forEach(function (salesInvoiceLine) {
                total += (salesInvoiceLine.Line_Amount__c ? salesInvoiceLine.Line_Amount__c : 0);
                totalInclTax += (salesInvoiceLine.Line_Amt_Incl_Tax__c ? salesInvoiceLine.Line_Amt_Incl_Tax__c : 0);
            });
            component.set("v.total", total);
            component.set("v.totalInclTax", totalInclTax);
        }
    }
});