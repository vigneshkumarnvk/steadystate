({
    validateResourceType : function(component, event) {
        var salesInvoice = component.get("v.salesInvoice");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var params = { "JSONSalesInvoice": JSON.stringify(salesInvoice), "JSONJobTask": JSON.stringify(jobTaskWrapper.JobTask), "JSONSalesInvoiceLine": JSON.stringify(salesInvoiceLine) };
        this.callServerMethod(component, event, "c.validateResourceType", params, function(response) {
            Object.assign(salesInvoiceLine, JSON.parse(response));
            component.set("v.salesInvoiceLine", salesInvoiceLine);
            this.calculateLineTotals(component, salesInvoiceLine);
            this.showFields(component);
        });
    },
    validateResource : function(component, event) {
        var salesInvoice = component.get("v.salesInvoice");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var params = { "JSONSalesInvoice": JSON.stringify(salesInvoice), "JSONJobTask": JSON.stringify(jobTaskWrapper.JobTask), "JSONSalesInvoiceLine": JSON.stringify(salesInvoiceLine) };
        this.callServerMethod(component, event, "c.validateResource", params, function(response) {
            Object.assign(salesInvoiceLine, JSON.parse(response));
            component.set("v.salesInvoiceLine", salesInvoiceLine);
            this.calculateLineTotals(component, salesInvoiceLine);
        });
    },
    calculateTaxPct : function(component, event, salesInvoiceLine) {
        if (salesInvoiceLine.Tax_Group__c == 'TX') {
            var salesInvoice = component.get("v.salesInvoice");
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            var salesInvoiceLine = component.get("v.salesInvoiceLine");
            var params = { "JSONSalesInvoice": JSON.stringify(salesInvoice), "JSONJobTask": JSON.stringify(jobTaskWrapper.JobTask), "JSONSalesInvoiceLine": JSON.stringify(salesInvoiceLine) };
            this.callServerMethod(component, event, "c.calculateTaxPct", params, function (response) {
                Object.assign(salesInvoiceLine, JSON.parse(response));
                component.set("v.salesInvoiceLine", salesInvoiceLine);
                this.calculateLineTotals(component, salesInvoiceLine);
            });
        }
        else {
            salesInvoiceLine.Tax_Pct__c = 0;
            this.calculateLineTotals(component, salesInvoiceLine);
            component.set("v.salesInvoiceLine", salesInvoiceLine);
        }
    },
    calculatePriceAndCost : function(component, event) {
        var salesInvoice = component.get("v.salesInvoice");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesInvoiceLine = component.get("v.salesInvoiceLine");
        var params = { "JSONSalesInvoice": JSON.stringify(salesInvoice), "JSONJobTask": JSON.stringify(jobTaskWrapper.JobTask), "JSONSalesInvoiceLine": JSON.stringify(salesInvoiceLine) };
        this.callServerMethod(component, event, "c.calculatePriceAndCost", params, function (response) {
            Object.assign(salesInvoiceLine, JSON.parse(response));
            component.set("v.salesInvoiceLine", salesInvoiceLine);
            this.calculateLineTotals(component, salesInvoiceLine);
        });
    },
    /*  Ticket#19931
     *    - Job times is not required for Resource Type with Rental Resource Type checked.
     */
    calculateLineTotals : function(component, salesInvoiceLine) {
        var qty = (salesInvoiceLine.Quantity__c ? salesInvoiceLine.Quantity__c : 0);
        var costQty = (salesInvoiceLine.Cost_Qty__c ? salesInvoiceLine.Cost_Qty__c : 0);
        var unitCost = (salesInvoiceLine.Unit_Cost__c ? salesInvoiceLine.Unit_Cost__c : 0);
        var unitPrice = (salesInvoiceLine.Unit_Price__c ? salesInvoiceLine.Unit_Price__c : 0);
        var taxPct = (salesInvoiceLine.Tax_Pct__c ? salesInvoiceLine.Tax_Pct__c : 0);

        salesInvoiceLine.Line_Amount__c = Math.round(qty * unitPrice * 100) / 100;
        salesInvoiceLine.Tax__c = salesInvoiceLine.Line_Amount__c * taxPct / 100;
        salesInvoiceLine.Line_Amt_Incl_Tax__c = salesInvoiceLine.Line_Amount__c + salesInvoiceLine.Tax__c;

        if (salesInvoiceLine.Category__c == 'Labor' || (salesInvoiceLine.Resource_Type__r && salesInvoiceLine.Resource_Type__r.Fleet_No_Required__c == true && salesInvoiceLine.Resource_Type__r.Rental_Resource_Type__c != true)) {
            salesInvoiceLine.Line_Cost__c = Math.round(costQty * unitCost * 100) / 100;
        }
        else {
            salesInvoiceLine.Line_Cost__c = Math.round(qty * unitCost * 100) / 100;
        }

        this.fireSalesInvoiceLineUpdateEvent(component);
    },
    fireSalesInvoiceLineUpdateEvent : function(component, salesInvoiceLine) {
        var params = { "salesInvoiceLine": salesInvoiceLine };
        var salesInvoiceLineUpdateEvent = component.getEvent("salesInvoiceLineUpdateEvent");
        salesInvoiceLineUpdateEvent.setParams(params);
        salesInvoiceLineUpdateEvent.fire();
    },
    showFields : function(component) {
        var fields = {};
        fields.select = { "visible": false, "disabled": true };
        fields.delete = { "visible": false, "disabled": true };
        fields.view = { "visible": false, "disabled": true };
        fields.tm = { "visible": false, "disabled": true };
        fields.category = { "visible": false, "disabled": true };
        fields.serviceCenter = { "visible": false, "disabled": true };
        fields.resourceType = { "visible": false, "disabled": true };
        fields.resource = { "visible": false, "disabled": true };
        fields.resourceName ={ "visible": false, "disabled": true };
        fields.description = { "visible": false, "disabled": true };
        fields.unitOfMeasure = { "visible": false, "disabled": true };
        fields.unitPrice = { "visible": false, "disabled": true };
        fields.quantity = { "visible": false, "disabled": true };
        fields.billAsLumpSum = { "visible": false, "disabled": true };
        fields.nonBillable = { "visible": false, "disabled": true };
        fields.quantity = { "visible": false, "disabled": true };
        fields.taxGroup = { "visible": false, "disabled": true };
        fields.costMethod = { "visible": false, "disabled": true };
        fields.unitWeightVolume = { "visible": false, "disabled": true };
        fields.containerSize = { "visible": false, "disabled": true };
        fields.facility = { "visible": false, "disabled": true };
        fields.BOLManifest = { "visible": false, "disabled": true };

        var salesInvoiceLine = component.get("v.salesInvoiceLine");

        fields.category.visible = true;
        fields.category.disabled = false;
        fields.delete.visible = true;
        fields.delete.disabled = false;

        switch(salesInvoiceLine.Category__c) {
            case 'Labor':
                fields.serviceCenter.visible = true;
                fields.serviceCenter.disabled = false;
                fields.resourceType.visible = true;
                fields.resourceType.disabled = false;
                fields.resource.visible = true;
                fields.resource.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.taxGroup.visible = true;
                fields.taxGroup.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.nonBillable.visible = true;
                fields.nonBillable.disabled = false;
                break;
            case 'Equipment':
                fields.serviceCenter.visible = true;
                fields.serviceCenter.disabled = false;
                fields.resourceType.visible = true;
                fields.resourceType.disabled = false;
                fields.resource.visible = true;
                fields.resource.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.taxGroup.visible = true;
                fields.taxGroup.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.nonBillable.visible = true;
                fields.nonBillable.disabled = false;
                break;
            case 'Materials':
                fields.resource.visible = true;
                fields.resource.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.taxGroup.visible = true;
                fields.taxGroup.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.nonBillable.visible = true;
                fields.nonBillable.disabled = false;
                break;
            case 'Subcontractors':
                fields.tm.visible = true;
                fields.tm.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.taxGroup.visible = true;
                fields.taxGroup.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.nonBillable.visible = true;
                fields.nonBillable.disabled = false;
                break;
            case 'Waste Disposal':
                fields.resource.visible = true;
                fields.resource.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.taxGroup.visible = true;
                fields.taxGroup.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.nonBillable.visible = true;
                fields.nonBillable.disabled = false;

                if (salesInvoiceLine.Resource__r != null && salesInvoiceLine.Resource__r.Name != 'WD' && (salesInvoiceLine.Resource__r.Has_Container__c == true || salesInvoiceLine.Resource__r.Has_Weight_Volume__c == true)) {
                    fields.costMethod.visible = true;
                    fields.costMethod.disabled = false;
                    fields.unitWeightVolume.visible = true;
                    fields.unitWeightVolume.disabled = false;
                    fields.containerSize.visible = true;
                    fields.containerSize.disabled = false;
                }
                else {
                    fields.unitOfMeasure.visible = true;
                    fields.unitOfMeasure.disabled = false;
                }
                fields.facility.visible = true;
                fields.facility.disabled = false;
                fields.BOLManifest.visible = true;
                fields.BOLManifest.disabled = false;
                break;
            case 'Demurrage':
                fields.resource.visible = true;
                fields.resource.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.taxGroup.visible = true;
                fields.taxGroup.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.nonBillable.visible = true;
                fields.nonBillable.disabled = false;
                break;
            case 'Misc. Charges And Taxes':
                fields.resource.visible = true;
                fields.resource.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.taxGroup.visible = true;
                fields.taxGroup.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.nonBillable.visible = true;
                fields.nonBillable.disabled = false;
                break;
            case 'Bundled':
                fields.resourceType.visible = true;
                fields.resourceType.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.taxGroup.visible = true;
                fields.taxGroup.disabled = false;
                break;
            default:
                break;
        }

        component.set("v.fields", fields);
    },
});