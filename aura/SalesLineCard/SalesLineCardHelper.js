({
    validateCategory : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        ///job task <<
        //var JSONSalesOrder = this.serializeObject(salesOrder);
        //var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        //job task >>
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        this.callServerMethod(component, event, "c.validateCategory", params, function(salesLine) {
            //fix.null.fields <<
            //component.set("v.salesLine", salesLine);
            component.set("v.salesLine", JSON.parse(salesLine));
            //fix.null.fields >>
            this.showFields(component, event);
        })
    },
    validateResourceType : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        //job task <<
        //var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var nextSalesLineNo = component.get("v.nextSalesLineNo");

        //ticket 19130 05.13.2023 <<
        //var params = { "JSONSalesOrder": JSONSalesOrder, "JSONJobTask": JSON.stringify(jobTaskWrapper.JobTask), "JSONSalesLine": JSONSalesLine, "nextSalesLineNo": nextSalesLineNo };
        var JSONJobTaskWrapper = JSON.stringify(jobTaskWrapper);
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONJobTaskWrapper": JSONJobTaskWrapper,  "JSONSalesLine": JSONSalesLine, "nextSalesLineNo": nextSalesLineNo };
        //ticket 19130 05.13.2023 >>
        //job task >>

        //ticket 19130 05.13.2023 << - validateResourceType is called correctly, JSONJobTaskWrapper is not passed to the function somehow and the function name is validateResourceType
        //this.callServerMethod(component, event, "c.validateResourceType", params, function(response) {
        this.callServerMethod(component, event, "c.validateResourceType", params, function(response) {
        //ticket 19130 05.13.2023 >>
            //fix.null.fields <<
            //component.set("v.salesLine", response);
            salesLine = JSON.parse(response);
            //job task <<

            //ticket 19130 05.03.2023 <<
            /*
            this.deletePresumptiveChildLines(jobTaskWrapper, salesLine);
            if (salesLine.Child_Lines__r && salesLine.Child_Lines__r.records) {
                jobTaskWrapper.SalesLines = jobTaskWrapper.SalesLines.concat(salesLine.Child_Lines__r.records);
                delete salesLine.Child_Lines__r;
            }
            */
            if (salesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r.records) {
                this.addChildLines(component, jobTaskWrapper, salesLine);
            }
            //ticket 19130 05.03.2023 >>
            //job task >>

            component.set("v.salesLine", salesLine);
            //fix.null.fields >>

            //recalculate rollup if the resource is changed
            if (salesLine.Bundle_Line__r) {
                this.rollUpLumpSum(salesLine.Bundle_Line__r.Line_No__c, jobTaskWrapper);
            }

            this.showFields(component, event);
        })
    },
    validateResource : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        console.log('uom cleared...'+JSONSalesLine.UnitOfMeasureCleared__c);
        //job task <<
        //var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };

        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var nextSalesLineNo = component.get("v.nextSalesLineNo");
        //ticket 19130 05.13.2023 <<
        //var params = { "JSONSalesOrder": JSONSalesOrder, "JSONJobTask": JSON.stringify(jobTaskWrapper.JobTask), "JSONSalesLine": JSONSalesLine, "nextSalesLineNo": nextSalesLineNo };
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONJobTaskWrapper": JSON.stringify(jobTaskWrapper), "JSONSalesLine": JSONSalesLine, "nextSalesLineNo": nextSalesLineNo };
        //ticket 19130 05.13.2023 >>
        //job task >>

        //ticket 19130 05.13.2023 <<
        //this.callServerMethod(component, event, "c.validateResource", params, function(response) {
        this.callServerMethod(component, event, "c.validateResource", params, function(response) {
        //ticket 19130 05.13.2023 >>
            //fix.null.fields <<
            //component.set("v.salesLine", response);
            var salesLine = JSON.parse(response);
            //fix.null.fields >>

            //ticket 19130 05.13.2023 <<
            /*
            //job task <<
            this.deletePresumptiveChildLines(jobTaskWrapper, salesLine);
            if (salesLine.Child_Lines__r && salesLine.Child_Lines__r.records) {
                jobTaskWrapper.SalesLines = jobTaskWrapper.SalesLines.concat(salesLine.Child_Lines__r.records);
                delete salesLine.Child_Lines__r;
            }
            //job task >>
            */
            if (salesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r.records) {
                this.addChildLines(component, jobTaskWrapper, salesLine);
            }
            //ticket 19130 05.13.2023 >>

            component.set("v.salesLine", salesLine);
            this.showFields(component, event);
        })
    },
    validateUnitOfMeasure : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesLine = component.get("v.salesLine");
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        this.callServerMethod(component, event, "c.validateUnitOfMeasure", params, function(response) {
            //fix.null.fields <<
            //component.set("v.salesLine", response);
            salesLine = JSON.parse(response);
            component.set("v.salesLine", salesLine);
            //fix.null.fields >>

            //rollup lump sum
            if (salesLine.Bundle_Line__r) {
                this.rollUpLumpSum(salesLine.Bundle_Line__r.Line_No__c, jobTaskWrapper);
            }
        })
    },
    validateNumberOfDays : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        this.callServerMethod(component, event, "c.validateNumberOfDays", params, function(response) {
            //fix.null.fields <<
            //component.set("v.salesLine", response);
            component.set("v.salesLine", JSON.parse(response));
            //fix.null.fields >>
        })
    },
    calculatePriceAndCost : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        this.callServerMethod(component, event, "c.validateUnitOfMeasure", params, function(response) {
            //fix.null.fields <<
            //component.set("v.salesLine", response);
            component.set("v.salesLine", JSON.parse(response));
            //fix.null.fields >>
            this.showFields(component, event);
        })
    },
    //ticket 19535 << move to SalesOrderBase.cmp
    /*
    calculateSalesLine : function(component, event) {
        var salesOrder = component.get("v.salesOrder");
        var salesLine = component.get("v.salesLine");
        var JSONSalesOrder = this.serializeObject(salesOrder);
        var JSONSalesLine = this.serializeObject(salesLine, 'Sales_Line_Details__r');
        var params = { "JSONSalesOrder": JSONSalesOrder, "JSONSalesLine": JSONSalesLine };
        this.callServerMethod(component, event, "c.calculateSalesLine", params, function(response) {
            //fix.null.fields <<
            //component.set("v.salesLine", response);

            //bundle line pricing method <<
            //component.set("v.salesLine", JSON.parse(response));
            var salesLine2 = JSON.parse(response);
            if (salesLine2.Category__c == 'Lump Sum') {
                this.recalculateLumpSumLine(component, event, salesLine2);
            }
            component.set("v.salesLine", salesLine2);
            //bundle line pricing method >>
            //fix.null.fields >>
        })
    },
    */
    //ticket 19535 >>
    //job task <<
    //ticket 19130 <<
    /*
    deletePresumptiveChildLines : function(jobTaskWrapper, parentLine) {
        for (var i = jobTaskWrapper.SalesLines.length - 1; i >= 0; i--) {
            var salesLine = jobTaskWrapper.SalesLines[i];
            if (salesLine.Parent_Line__r && salesLine.Parent_Line__r.Line_No__c == parentLine.Line_No__c) {
                jobTaskWrapper.SalesLines.splice(i, 1);
            }
        }
    },
    */
    //ticket 19130 >>
    //job task >>
    //bundle line pricing method <<
    //recalculateLumpSumLine : function(component, event, salesLine) {
    recalculateLumpSumLine : function(component, event, salesLine, recalculateUnitPrice) {
        //bundle line pricing method >>
        //recalculate rollup if the resource is changed
        /*
        var salesLine = component.get("v.salesLine");
        if (salesLine.Category__c == 'Lump Sum') {
            var salesLines = component.get("v.salesLines");
            this.rollupLumpSumLine(salesLine, salesLines);
            component.set("v.salesLine", salesLine);
        }
        */
        var lumpSumLine = null;
        //job task <<
        //var salesLines = component.get("v.salesLines");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesLines = jobTaskWrapper.SalesLines;
        //job task >>

        if (salesLine.Category__c == 'Bundled') {
            lumpSumLine = salesLine;
        }
        else if (salesLine.Bill_as_Lump_Sum__c == true && salesLine.Bundle_Line__r != null && salesLine.Bundle_Line__r.Line_No__c != null) {
            //ticket 19535 <<
            //lumpSumLine = this.findLumpSumLine(salesLine, salesLines);
            lumpSumLine = this.getLumpSumLine(salesLine, salesLines);
            //ticket 19535 >>
        }

        if (lumpSumLine != null) {
            //bundle line pricing method <<
            /*
            lumpSumLine = this.rollupLumpSumLine(lumpSumLine, salesLines);
            salesLines = this.updateSalesLines(lumpSumLine, salesLines);
            */
            lumpSumLine = this.rollupLumpSumLine(lumpSumLine, salesLines, recalculateUnitPrice);
            //bundle line pricing method >>
            //job task <<
            //component.set("v.salesLines", salesLines);
            jobTaskWrapper.SalesLines = salesLines;
            component.set("v.jobTaskWrapper", jobTaskWrapper);
            //job task >>
        }
    },
    saveSalesLine : function(component, event) {
        if (this.validateFields(component, event) == true) {
            var salesLine = component.get("v.salesLine");
            
            //salesLine.isManualEdit = true;
            //component.set("v.salesLine",salesLine);
            console.log('saveSalesLines::::::::::::::::::::'+JSON.stringify(salesLine));
            //bundle line pricing method <<
            /*
            if (salesLine.Category__c == 'Lump Sum' && salesLine.Unit_Price__c && salesLine.Rolled_up_Unit_Price__c && salesLine.Unit_Price__c < salesLine.Rolled_up_Unit_Price__c) {
                this.confirmBundledPrice(component, event);
            }
            else {
                this.saveSalesLineCallback(component, event);
            }*/
            var confirmPrice = false;
            if (salesLine.Category__c == 'Bundled' && salesLine.Unit_Price__c && salesLine.Rolled_up_Unit_Price__c) {
                if (salesLine.Bundle_Pricing_Method__c == 'Per Unit') {
                    if (salesLine.Quantity__c && salesLine.Unit_Price__c < Math.round(salesLine.Rolled_up_Unit_Price__c / salesLine.Quantity__c * 100) / 100) {
                        confirmPrice = true;
                    }
                }
                else {
                    if (salesLine.Unit_Price__c < salesLine.Rolled_up_Unit_Price__c) {
                        confirmPrice = true;
                    }
                }
            }

            if (confirmPrice) {
                this.confirmBundledPrice(component, event);
            }
            else {
                this.saveSalesLineCallback(component, event);
            }
            //bundle line pricing method >>
        }
    },
    confirmBundledPrice : function(component, event, callback) {
        var buttons = [];
        buttons.push({
            "label": 'No',
            "variant": 'neutral',
            "action": {"callback": this.cancelCallback.bind(this, component, event)}
        });
        buttons.push({
            "label": 'Yes',
            "variant": 'brand',
            "action": {"callback": this.confirmBundledPriceCallback.bind(this, component, event)}
        });
        //bundle line pricing method <<
        //this.openModal(component, event, "Bundled Price Confirmation", 'The bundled price is less than the rolled up price. Are you sure?', buttons, null, null, null);
        var salesLine = component.get("v.salesLine");
        var message;
        if (salesLine.Bundle_Pricing_Method__c == 'Per Unit') {
            message = 'The bundled Unit Price is less than the rolled-up unit price. Are you sure?';
        }
        else {
            message = 'The bundled Total Price is less than the rolled-up total price. Are you sure?';
        }
        this.openModal(component, event, "Bundled Price Confirmation", message, buttons, null, null, null);
        //bundle line pricing method >>
    },
    confirmBundledPriceCallback : function(component, event) {
        this.closeModal(component, event);
        this.saveSalesLineCallback(component, event);
    },
    saveSalesLineCallback : function(component, event) {
        var salesLine = component.get("v.salesLine");
        //job task <<
        //var salesLines = component.get("v.salesLines"); //sales lines may contain bundle information
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        console.log('inside jobTaskWrapper callback::::::::::::::'+JSON.stringify(jobTaskWrapper));
        console.log('inside salesLine callback::::::::::::::'+JSON.stringify(salesLine));
        //add or update the sales line
        var salesLineIndex = -1;
        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            if (jobTaskWrapper.SalesLines[i].Line_No__c ==  salesLine.Line_No__c) {
                salesLineIndex = i;
            }
            //clear the select flag on the sales line
            jobTaskWrapper.SalesLines[i].selected;
        }

        if (salesLineIndex >= 0) {
            //ticket 19130 <<
            //check if the relationship has changed, if yes, prompt the wizard
            let xSalesLine = jobTaskWrapper.SalesLines[salesLineIndex];

            if (!xSalesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r) {
                salesLine.Wizard_Question_Answered__c = false;
            }
            else if (xSalesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r) {
                let xChildLineNos = [];
                let childLineNos = [];
                for (var i = 0; i < xSalesLine.Sales_Child_Lines__r.records.length; i++) {
                    xChildLineNos.push(parseInt(xSalesLine.Sales_Child_Lines__r.records[i].Child_Line__r.Line_No__c));
                }
                for (var i = 0; i < salesLine.Sales_Child_Lines__r.records.length; i++) {
                    childLineNos.push(parseInt(salesLine.Sales_Child_Lines__r.records[i].Child_Line__r.Line_No__c));
                }

                for (var i = 0; i < xChildLineNos.length; i++) {
                    let lineNo = xChildLineNos[i];
                    let index = childLineNos.indexOf(lineNo);
                    if (index >= 0) {
                        xChildLineNos.splice(i, 1);
                        i--;
                        childLineNos.splice(index, 1);
                    }
                }
                salesLine.Wizard_Question_Answered__c = !(xChildLineNos.length > 0 || childLineNos.length > 0);

                //set child lines question answered to false
                var childLineNosToUpdate = [...xChildLineNos, ...childLineNos];
                childLineNosToUpdate.forEach(childLineNo => {
                    for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                        if (jobTaskWrapper.SalesLines[i].Line_No__c == childLineNo) {
                            jobTaskWrapper.SalesLines[i].Wizard_Question_Answered__c = false;
                        }
                    }
                });
            }

            //prompt question for all child resource when the parent resource is changed 05.09.23
            if (xSalesLine.Quantity__c != salesLine.Quantity__c || xSalesLine.UOM_Qty__c != salesLine.UOM_Qty__c || xSalesLine.Number_of_Day__c != salesLine.Number_of_Day__c) {
                salesLine.Wizard_Question_Answered__c =  false;
                var childLineNos = [];
                if (salesLine.Sales_Child_Lines__r) {
                    for (var i = 0; i < salesLine.Sales_Child_Lines__r.records.length; i++) {
                        childLineNos.push(salesLine.Sales_Child_Lines__r.records[i].Child_Line__r.Line_No__c);
                    }
                    if (childLineNos.length > 0) {
                        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                            if (childLineNos.includes(jobTaskWrapper.SalesLines[i].Line_No__c)) {
                                jobTaskWrapper.SalesLines[i].Wizard_Question_Answered__c = false;
                            }
                        }
                    }
                }
            }
            //ticket 19130 >>

            jobTaskWrapper.SalesLines[salesLineIndex] = salesLine;
        }
        else {
            jobTaskWrapper.SalesLines.push(salesLine);
        }
        //job task >>

        var actionParams = event.getParams().arguments;
        if (actionParams.callback) { //pass the sales line the callback function
            //clear the select flag from the sales lines
            //job task <<
            /*
            for (var i = 0; i < salesLines.length; i++) {
                delete salesLines[i].selected;
            }
            actionParams.callback(salesLine, salesLines);
            */
            var mode = component.get("v.mode");
            if (mode == 'add') {
                var linesAdded = component.get("v.linesAdded");
                actionParams.callback(jobTaskWrapper, linesAdded, salesLine.Category__c);
            }
            else {
                actionParams.callback(jobTaskWrapper, salesLine);
            }
            //job task >>
        }
    },
     fireTMLineUpdateEvent : function(component, causedByField) {
        var rowIndex = component.get("v.index");
        var tmLine = component.get("v.salesLine");
        var tmLineUpdateEvent = component.getEvent("tmLineUpdateEvent");
        tmLineUpdateEvent.setParams({ "rowIndex": rowIndex, "tmLine": tmLine, "causedByField": causedByField });
        tmLineUpdateEvent.fire();
    },
    showFields : function(component, event) {
        var fields = {};
        fields.Category = { "id": 'category', "show": false, "required": false, "disabled": true };
        fields.ResourceType = { "id": 'resource-type', "show": false, "required": false, "disabled": true };
        fields.Resource = { "id": 'resource', "show": false, "required": false, "disabled": true };
        fields.DaysNeeded = { "id": 'days-needed', "show": false, "required": false, "disabled": true };
        fields.Quantity = { "id": 'quantity', "show": false, "required": false, "disabled": true };
        fields.Description = { "id": 'description', "show": false, "required": false, "disabled": true };
        fields.UOMQty = { "id": 'uom-qty', "show": false, "required": false, "disabled": true };
        fields.UnitOfMeasure = { "id": 'unit-of-measure', "show": false, "required": false, "disabled": true };
        fields.RegularRate = { "id": 'regular-rate', "show": false, "required": false, "disabled": true };
        fields.OvertimeRate = { "id": 'overtime-rate', "show": false, "required": false, "disabled": true };
        fields.DoubleTimeRate = { "id": 'double-time-rate', "show": false, "required": false, "disabled": true };
        fields.UnitPrice = { "id": 'unit-price', "show": false, "required": false, "disabled": true };
        fields.LaborUnitPrice = { "id": 'labor-unit-price', "show": false, "required": false, "disabled": true };
        fields.TotalLaborHours = { "id": 'total-labor-hour', "show": false, "required": false, "disabled": true };
        fields.RolledUpUnitPrice = { "id": 'rolled-up-unit-price', "show": false, "required": false, "disabled": true };
        fields.PricingSource = { "id": 'pricing-source', "show": false, "required": false, "disabled": true };
        fields.MarkupOption = { "id": 'makrup-option', "show": false, "required": false, "disabled": true };
        fields.Markup = { "id": 'markup', "show": false, "required": false, "disabled": true };
        fields.ContractLine = { "id": 'contract-line', "show": false, "required": false, "disabled": true };
        fields.ContractRegularRate = { "id": 'contract-regular-rate', "show": false, "required": false, "disabled": true };
        fields.RegularHours = { "id": 'regular-hours', "show": false, "required": false, "disabled": true };
        fields.OvertimeHours = { "id": 'overtime-hours', "show": false, "required": false, "disabled": true };
        fields.DoubleTimeHours = { "id": 'double-time-hours', "show": false, "required": false, "disabled": true };
        fields.CostMethod = { "id": 'cost-method', "show": false, "required": false, "disabled": true };
        fields.UnitWeightVolume = { "id": 'unit-weight-volume', "show": false, "required": false, "disabled": true };
        fields.ContainerSize = { "id": 'container-size', "show": false, "required": false, "disabled": true };
        fields.Facility = { "id": 'facility', "show": false, "required": false, "disabled": true };
        fields.MinSellQty = { "id": 'min-sell-qty', "show": false, "required": false, "disabled": true };
        fields.BillAsLumpSum = { "id": 'bill-as-lump-sum', "show": false, "required": false, "disabled": true };
        fields.NonBillable = { "id": 'non-billable', "show": false, "required": false, "disabled": true };
        fields.TaxGroup = { "id": 'tax-group', "show": false, "required": false, "disabled": true};
        fields.LineAmount = { "id": 'line-amount', "show": false, "required": false, "disabled": true };
        fields.Tax = { "id": 'tax', "show": false, "required": false, "disabled": true };
        fields.LineAmountIncludingTax = { "id": 'line-amount-including-tax', "show": false, "required": false, "disabled": true };
        fields.UnitCost = { "id": 'unit-cost', "show": false, "required": false, "disabled": true };
        fields.LineCost = { "id": 'line-cost', "show": false, "required": false, "disabled": true };
        //bundle line pricing method <<
        fields.BundlePricingMethod = { "id": 'bundle-pricing-method', "show": false, "required": false, "disabled": true };
        //bundle line pricing method >>
        //job task <<
        fields.ParentLine = { "id": 'parent-line', "show": false, "required": false, "disabled": true };
        //job task >>
        //ticket 19130 <<
        fields.ChildResource = {"id": 'child-resource', "show": false, "required": false, "disabled": true };
        //ticket 19130 >>
        var salesLine = component.get("v.salesLine");

        switch (salesLine.Category__c) {
            case 'Labor':
                fields.Category.show = true;
                fields.Category.required = true;
                fields.Category.disabled = false;
                fields.ResourceType.show = true;
                fields.ResourceType.required = true;
                fields.ResourceType.disabled = false;
                fields.DaysNeeded.show = true;
                fields.DaysNeeded.required = true;
                fields.DaysNeeded.disabled = false;
                fields.Quantity.show = true;
                fields.Quantity.required = true;
                fields.Quantity.disabled = false;
                fields.Description.show = true;
                fields.Description.disabled = false;
                fields.UOMQty.show = true;
                fields.UOMQty.required = true;
                fields.UOMQty.disabled = false;
                fields.UnitOfMeasure.show = true;
                fields.UnitOfMeasure.required = true;
                fields.UnitOfMeasure.disabled = false;
                fields.RegularRate.show = true;
                fields.RegularRate.disabled = false;
                fields.OvertimeRate.show = true;
                fields.OvertimeRate.disabled = false;
                fields.DoubleTimeRate.show = true;
                fields.DoubleTimeRate.disabled = false;
                fields.PricingSource.show = true;
                fields.ContractLine.show = true;
                fields.ContractRegularRate.show = true;
                fields.LaborUnitPrice.show = true;
                fields.TotalLaborHours.show = true;
                fields.RegularHours.show = true;
                fields.OvertimeHours.show = true;
                fields.DoubleTimeHours.show = true;
                fields.BillAsLumpSum.show = true;
                fields.BillAsLumpSum.disabled = false;
                fields.NonBillable.show = true;
                fields.NonBillable.disabled = false;
                fields.TaxGroup.show = true;
                fields.TaxGroup.disabled = false;
                fields.LineAmount.show = true;
                fields.Tax.show = true;
                fields.LineAmountIncludingTax.show = true;
                //fields.UnitCost.show = true; //Ticket#22710
                fields.LineCost.show = true;
                break;
            case 'Equipment':
                fields.Category.show = true;
                fields.Category.required = true;
                fields.Category.disabled = false;
                fields.ResourceType.show = true;
                fields.ResourceType.required = true;
                fields.ResourceType.disabled = false;
                fields.DaysNeeded.show = true;
                fields.DaysNeeded.required = true;
                fields.DaysNeeded.disabled = false;
                fields.Quantity.show = true;
                fields.Quantity.required = true;
                fields.Quantity.disabled = false;
                fields.Description.show = true;
                fields.Description.disabled = false;
                fields.UOMQty.show = true;
                fields.UOMQty.required = true;
                fields.UOMQty.disabled = false;
                fields.UnitOfMeasure.show = true;
                fields.UnitOfMeasure.required = true;
                fields.UnitOfMeasure.disabled = false;
                fields.UnitPrice.show = true;
                fields.UnitPrice.disabled = false;
                fields.PricingSource.show = true;
                fields.ContractLine.show = true;
                fields.ContractRegularRate.show = true;
                fields.BillAsLumpSum.show = true;
                fields.BillAsLumpSum.disabled = false;
                fields.NonBillable.show = true;
                fields.NonBillable.disabled = false;
                fields.TaxGroup.show = true;
                fields.TaxGroup.disabled = false;
                fields.LineAmount.show = true;
                fields.Tax.show = true;
                fields.LineAmountIncludingTax.show = true;
                fields.UnitCost.show = true;
                fields.LineCost.show = true;
                break;
            case 'Materials':
                fields.Category.show = true;
                fields.Category.required = true;
                fields.Category.disabled = false;
                fields.Resource.show = true;
                fields.Resource.required = true;
                fields.Resource.disabled = false;
                fields.DaysNeeded.show = true;
                fields.DaysNeeded.required = true;
                fields.DaysNeeded.disabled = false;
                fields.Quantity.show = true;
                fields.Quantity.required = true;
                fields.Quantity.disabled = false;
                fields.Description.show = true;
                fields.Description.disabled = false;
                fields.UnitOfMeasure.show = true;
                fields.UnitOfMeasure.required = true;
                fields.UnitOfMeasure.disabled = false;
                fields.UnitPrice.show = true;
                fields.UnitPrice.disabled = false;
                fields.PricingSource.show = true;
                fields.ContractLine.show = true;
                fields.ContractRegularRate.show = true;
                fields.BillAsLumpSum.show = true;
                fields.BillAsLumpSum.disabled = false;
                fields.NonBillable.show = true;
                fields.NonBillable.disabled = false;
                fields.TaxGroup.show = true;
                fields.TaxGroup.disabled = false;
                fields.LineAmount.show = true;
                fields.Tax.show = true;
                fields.LineAmountIncludingTax.show = true;
                fields.UnitCost.show = true;
                fields.LineCost.show = true;
                break;
            case 'Subcontractors':
                fields.Category.show = true;
                fields.Category.required = true;
                fields.Category.disabled = false;
                fields.Quantity.show = true;
                fields.Quantity.required = true;
                fields.Quantity.disabled = false;
                fields.Description.show = true;
                fields.Description.required = true;
                fields.Description.disabled = false;
                fields.UnitOfMeasure.show = true;
                fields.UnitOfMeasure.required = true;
                fields.UnitOfMeasure.disabled = false;
                fields.UnitPrice.show = true;
                fields.UnitPrice.disabled = true; //Ticket#19664
                fields.PricingSource.show = true;
                fields.MarkupOption.show = true;
                fields.MarkupOption.disabled = false;
                fields.Markup.show = true;
                fields.Markup.disabled = false;
                fields.BillAsLumpSum.show = true;
                fields.BillAsLumpSum.disabled = false;
                fields.NonBillable.show = true;
                fields.NonBillable.disabled = false;
                fields.TaxGroup.show = true;
                fields.TaxGroup.disabled = false;
                fields.LineAmount.show = true;
                fields.Tax.show = true;
                fields.LineAmountIncludingTax.show = true;
                fields.UnitCost.show = true;
                fields.UnitCost.required = true; //Ticket#19664
                fields.UnitCost.disabled = false;
                fields.LineCost.show = true;
                break;
            case 'Waste Disposal':
                if (salesLine.System_Calculated_Line__c != true) {
                    fields.Category.show = true;
                    fields.Category.required = true;
                    fields.Category.disabled = false;
                    fields.Resource.show = true;
                    fields.Resource.required = true;
                    fields.Resource.disabled = false;
                    fields.Quantity.show = true;
                    fields.Quantity.required = true;
                    fields.Quantity.disabled = false;
                    fields.Description.show = true;
                    fields.Description.disabled = false;

                    fields.UnitPrice.show = true;
                    fields.UnitPrice.disabled = false;
                    fields.UnitPrice.required = true;

                    //cost method <<
                    //(is new or is created before the cutover date) and the resource has container or weight/volume
                    var dt = new Date('2020-04-08T12:00:00.000Z'); //cut over date
                    if (salesLine.Resource__r != null && salesLine.Resource__r.Name != 'WD' && salesLine.Resource__r.Name != 'MA Transporter Fee' && ((salesLine.CreatedDate && new Date(salesLine.CreatedDate) >= dt) || salesLine.CreatedDate == null) && (salesLine.Resource__c && (salesLine.Resource__r.Has_Container__c == true || salesLine.Resource__r.Has_Weight_Volume__c == true))) {
                        fields.UnitOfMeasure.show = true;
                        fields.UnitOfMeasure.disabled = false;
                        fields.MinSellQty.show = true;
                        fields.MinSellQty.disabled = false;
                    }
                    else {
                        //fields.CostMethod.show = false;
                        //fields.CostMethod.required = false;
                        //fields.CostMethod.disabled = true;
                        fields.UnitOfMeasure.show = true;
                        fields.UnitOfMeasure.disabled = false;
                        //fields.ContainerSize.show = false;
                        //fields.ContainerSize.disabled = true;
                        //fields.ContainerSize.required = false;
                        //fields.UnitWeightVolume.show = false;
                        //fields.UnitWeightVolume.disabled = false;
                        //fields.UnitWeightVolume.required = false;
                        fields.MinSellQty.show = false;
                        fields.MinSellQty.disabled = true;
                    }
                    //cost method >>

                    fields.Facility.show = true;
                    fields.Facility.disabled = false;

                    fields.PricingSource.show = true;
                    fields.ContractLine.show = true;
                    fields.ContractRegularRate.show = true;
                    fields.BillAsLumpSum.show = true;
                    fields.BillAsLumpSum.disabled = false;
                    fields.NonBillable.show = true;
                    fields.NonBillable.disabled = false;
                    fields.TaxGroup.show = true;
                    fields.TaxGroup.disabled = false;
                    fields.LineAmount.show = true;
                    fields.Tax.show = true;
                    fields.LineAmountIncludingTax.show = true;
                    fields.UnitCost.show = true;
                    fields.UnitCost.required = true;
                    fields.UnitCost.disabled = false;
                    fields.LineCost.show = true;

                    if(salesLine.Resource__r != null && salesLine.Resource__r.Name === 'Manifest Fee') {
                            fields.UnitCost.disabled = true;
                    }
                }
                else { //manifest line
                    fields.Category.show = true;
                    fields.Category.required = true;
                    fields.Category.show = true;
                    fields.Category.required = true;
                    fields.Resource.show = true;
                    fields.Resource.required = true;
                    fields.Quantity.show = true;
                    fields.Quantity.required = true;
                    fields.Quantity.disabled = false;
                    fields.Description.show = true;
                    fields.UnitOfMeasure.show = true;
                    fields.UnitOfMeasure.required = true;
                    fields.UnitPrice.show = true;
                    fields.TaxGroup.show = true;
                    fields.TaxGroup.disabled = false;
                    fields.LineAmount.show = true;
                    fields.Tax.show = true;
                    fields.LineAmountIncludingTax.show = true;
                    fields.UnitCost.show = true;
                    fields.LineCost.show = true;
                }
                break;
            case 'Misc. Charges And Taxes':

                if(salesLine.Resource__r != null && salesLine.Resource__r.Allow_Manual_Unit_Cost_Adjustment__c == true){
                    fields.UnitCost.disabled = false;
                }

                if((salesLine.Resource__r == null) || (salesLine.Resource__r != null && salesLine.System_Calculated_Line__c != true)) {
                    fields.Category.show = true;
                    fields.Category.required = true;
                    fields.Category.disabled = false;
                    fields.Resource.show = true;
                    fields.Resource.required = true;
                    fields.Resource.disabled = false;
                    fields.Quantity.show = true;
                    fields.Quantity.required = true;
                    fields.Quantity.disabled = false;
                    fields.Description.show = true;
                    fields.Description.disabled = false;
                    fields.UnitOfMeasure.show = true;
                    fields.UnitOfMeasure.required = true;
                    fields.UnitOfMeasure.disabled = false;
                    fields.UnitPrice.show = true;
                    fields.UnitPrice.disabled = false;
                    fields.PricingSource.show = true;
                    fields.BillAsLumpSum.show = true;
                    fields.BillAsLumpSum.disabled = false;
                    fields.NonBillable.show = true;
                    fields.NonBillable.disabled = false;
                    fields.ContractLine.show = true;
                    fields.ContractRegularRate.show = true;
                    fields.TaxGroup.show = true;
                    fields.TaxGroup.disabled = false;
                    fields.LineAmount.show = true;
                    fields.Tax.show = true;
                    fields.LineAmountIncludingTax.show = true;
                    fields.UnitCost.show = true;
                    fields.LineCost.show = true;
                }
                else {
                    fields.Category.show = true;
                    fields.Category.required = true;
                    fields.Category.disabled = true;
                    fields.Resource.show = true;
                    fields.Resource.required = true;
                    fields.Resource.disabled = true;
                    fields.Quantity.show = true;
                    fields.Quantity.required = true;
                    fields.Quantity.disabled = false;
                    fields.Description.show = true;
                    fields.Description.disabled = true;
                    fields.UnitOfMeasure.show = true;
                    fields.UnitOfMeasure.required = true;
                    fields.UnitOfMeasure.disabled = true;
                    fields.UnitPrice.show = true;
                    fields.UnitPrice.disabled = true;
                    fields.PricingSource.show = true;
                    fields.BillAsLumpSum.show = true;
                    fields.BillAsLumpSum.disabled = true;
                    fields.NonBillable.show = true;
                    fields.NonBillable.disabled = true;
                    fields.ContractLine.show = true;
                    fields.ContractRegularRate.show = true;
                    fields.TaxGroup.show = true;
                    fields.TaxGroup.disabled = false;
                    fields.LineAmount.show = true;
                    fields.Tax.show = true;
                    fields.LineAmountIncludingTax.show = true;
                    fields.UnitCost.show = true;
                    fields.LineCost.show = true;
                }
                break;
            case 'Bundled':
                fields.Category.show = true;
                fields.Category.required = true;
                fields.Category.disabled = false;
                fields.ResourceType.show = true;
                fields.ResourceType.required = true;
                fields.ResourceType.disabled = false;
                fields.Quantity.show = true;
                fields.Quantity.required = true;
                fields.Quantity.disabled = false;
                fields.Description.show = true;
                fields.Description.disabled = false;
                fields.UnitOfMeasure.show = true;
                fields.UnitOfMeasure.required = true;
                fields.UnitOfMeasure.disabled = false;
                fields.UnitPrice.show = true;
                fields.UnitPrice.disabled = false;
                fields.RolledUpUnitPrice.show = true;
                fields.PricingSource.show = true;
                fields.ContractLine.show = true;
                fields.ContractRegularRate.show = true;
                fields.TaxGroup.show = true;
                fields.TaxGroup.disabled = false;
                fields.LineAmount.show = true;
                fields.Tax.show = true;
                fields.LineAmountIncludingTax.show = true;
                fields.UnitCost.show = true;
                fields.LineCost.show = true;
                //bundle line pricing method <<
                fields.BundlePricingMethod.show = true;
                fields.BundlePricingMethod.required = true;
                fields.BundlePricingMethod.disabled = false;
                //bundle line pricing method >>
                break;
            case 'Demurrage':
                fields.Category.show = true;
                fields.Category.required = true;
                fields.Category.disabled = false;
                fields.Resource.show = true;
                fields.Resource.required = true;
                fields.Resource.disabled = false;
                fields.Quantity.show = true;
                fields.Quantity.required = true;
                fields.Quantity.disabled = false;
                fields.Description.show = true;
                fields.Description.disabled = false;
                fields.UnitOfMeasure.show = true;
                fields.UnitOfMeasure.required = true;
                fields.UnitOfMeasure.disabled = false;
                fields.UnitPrice.show = true;
                fields.UnitPrice.disabled = false;
                fields.PricingSource.show = true;
                fields.BillAsLumpSum.show = true;
                fields.BillAsLumpSum.disabled = false;
                fields.NonBillable.show = true;
                fields.NonBillable.disabled = false;
                fields.ContractLine.show = true;
                fields.ContractRegularRate.show = true;
                fields.TaxGroup.show = true;
                fields.TaxGroup.disabled = false;
                fields.LineAmount.show = true;
                fields.Tax.show = true;
                fields.LineAmountIncludingTax.show = true;
                fields.UnitCost.show = true;
                fields.LineCost.show = true;
                break;
            default:
                fields.Category.show = true;
                fields.Category.required = true;
                fields.Category.disabled = false;
                break;
        }

        //job task <<
        if (salesLine.Category__c != null) {
            //ticket 19130 <<
            //if (salesLine.Parent_Line__r != null) {
            if (salesLine.Is_Child_Resource__c == true) {
            //ticket 19130 >>
                fields.Category.disabled = true;
                fields.ResourceType.disabled = true;
                fields.Resource.disabled = true;
                fields.UnitOfMeasure.disabled = true;
            }

            //ticket 19130 <<
            /*
            var showParentLineField = true;
            var jobTaskWrapper = component.get("v.jobTaskWrapper");
            for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
                var salesLine2 = jobTaskWrapper.SalesLines[i];
                if (salesLine2.Parent_Line__r != null && salesLine2.Parent_Line__r.Line_No__c == salesLine.Line_No__c) {
                    showParentLineField = false;
                    break;
                }
            }
            fields.ParentLine.show = showParentLineField;
            fields.ParentLine.disabled = !showParentLineField;
            */
            //ticket 19130 >>
        }
        //job task >>

        //ticket 19130 <<
        fields.ChildResource.disabled = false;
        //ticket 19130 >>
        component.set("v.xFields", fields);
    },
    validateFields : function(component, event, helper) {
        var fieldsToValidate = new Array();
        var salesLine = component.get("v.salesLine");
        var salesOrder = component.get("v.salesOrder");

        var fields = component.get("v.xFields");

        Object.keys(fields).forEach(function(key,index) {
            var field = fields[key];
            if (field.id != null && field.required == true) {
                fieldsToValidate.push(component.find(field.id));
            }
        });

        /* not needed, validatin is done based on the required flag
        //conditionally required fields
        switch (salesLine.Category__c) {
            case 'Waste Disposal':
                if (salesLine.Cost_Method__c == 'Unit_Weight_Vol') {
                    if (salesLine.Unit_Weight_Vol__c != null) {
                        fieldsToValidate.push(component.find("unit-weight-volume"));
                    }
                }
                else if (salesLine.Cost_Method__c == 'Container'){
                    fieldsToValidate.push(component.find("container-size"));
                }

                fieldsToValidate.push(component.find("unit-cost"));
                break;
        }
        */
        var ok = fieldsToValidate.reduce(function(valid, inputField) {

            if (Array.isArray(inputField)) {
                for (var i = 0; i < inputField.length; i++) {
                    inputField[i].showHelpMessageIfInvalid();
                    //job task <<
                    //return valid && inputField[i].get("v.validity").valid;
                    valid = valid && inputField[i].get("v.validity").valid;
                    //job task >>
                }
                //job task <<
                return valid;
                //job task >>
            }
            else {
                inputField.showHelpMessageIfInvalid();
                valid = valid && inputField.get("v.validity").valid
                return valid;
            }

        }, true);

        //ticket 19130 <<
        if (salesLine.Sales_Child_Lines__r && salesLine.Sales_Child_Lines__r.records) {
            var childLineNos = [];
            var dups = [];
            for (var i = 0; i < salesLine.Sales_Child_Lines__r.records.length; i++) {
                var relation = salesLine.Sales_Child_Lines__r.records[i];
                if (relation.Child_Line__r && relation.Child_Line__r.Line_No__c) {
                    if (!childLineNos.includes(parseInt(relation.Child_Line__r.Line_No__c))) {
                        childLineNos.push(parseInt(relation.Child_Line__r.Line_No__c));
                    }
                    else {
                        dups.push(relation.Child_Line__r.Description__c);
                        ok = false;
                    }
                }
                else {
                    salesLine.Sales_Child_Lines__r.records.splice(i, 1);
                    i--;
                }
            }
            if (dups.length > 0) {
                this.showToast(component, "", "Duplicated child resources are entered: " + dups.join(", ") + ".", "error", "dismissible");
            }
        }
        //ticket 19130 >>

        return ok;
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    normalizeNumber : function(number) {
        if (isNaN(number)) {
            number = 0;
        }
        return number;
    },
    //ticket 19130 <<
    addChildLines : function(component, jobTaskWrapper, salesLine) {
        var mapSalesLinesByLineNo = new Map();
        for (var i = 0; i < jobTaskWrapper.SalesLines.length; i++) {
            var salesLine2 = jobTaskWrapper.SalesLines[i];
            mapSalesLinesByLineNo.set(salesLine2.Line_No__c, salesLine2);
        }

        salesLine.Sales_Child_Lines__r.records.forEach(relation => {
            var childSalesLine = relation.Child_Line__r;
            if (!mapSalesLinesByLineNo.has(childSalesLine.Line_No__c)) {
                jobTaskWrapper.SalesLines.push(childSalesLine);
                mapSalesLinesByLineNo.set(childSalesLine.Line_No__c, childSalesLine);
            }
        });

        /*
        for (var i = 0; i < childLines.length; i++) {
            var childLine = childLines[i];
            var resourceId;
            if (childLine.Category__c == 'Labor' || childLine.Category__c == 'Equipment' || childLine.Category__c == 'Bundled') {
                resourceId = childLine.Resource_Type__c;
            } else {
                resourceId = childLine.Resource__c;
            }

            if (mapChildResourceLinesByResourceId.has(resourceId)) {
                childLines[i] = mapChildResourceLinesByResourceId.get(resourceId);
                childLines[i].Wizard_Question_Answered__c = false; //reset the child line wizard question flag to prompt wizard
            } else {
                jobTaskWrapper.SalesLines.push(childLine);
            }
        }

        /*
        //remove existing relationships if exist
        salesLine.Sales_Child_Lines__r = { "records": [] };
        for (var i = 0; i < childLines.length; i++) {
            var childLine = childLines[i];
            salesLine.Sales_Child_Lines__r.records.push({
                "Parent_Line__c": salesLine.Id,
                "Parent_Line__r": {
                    "attributes": {"type": 'Sales_Line__c'},
                    "Id": salesLine.Id,
                    "Line_No__c": salesLine.Line_No__c,
                    "Description__c": salesLine.Description__c,
                    "Category__c": salesLine.Category__c,
                    "Resource_Type__c": salesLine.Resource_Type__c,
                    "Resource_Type__r": salesLine.Resource_Type__r,
                    "Resource__c": salesLine.Resource__c,
                    "Resource__r": salesLine.Resource__r
                },
                "Child_Line__c": childLine.Id,
                "Child_Line__r": {
                    "attributes": {"type": 'Sales_Line__c'},
                    "Id": childLine.Id,
                    "Line_No__c": childLine.Line_No__c,
                    "Description__c": childLine.Description__c,
                    "Category__c": childLine.Category__c,
                    "Resource_Type__c": childLine.Resource_Type__c,
                    "Resource_Type__r": childLine.Resource_Type__r,
                    "Resource__c": childLine.Resource__c,
                    "Resource__r": childLine.Resource__r
                }
            });
        }
        salesLine.Sales_Child_Lines__r.totalSize = salesLine.Sales_Child_Lines__r.records.length;
        salesLine.Sales_Child_Lines__r.done = "true";
        */
    },
    getValidUOMs: function(component, billUnitCode, callback) {
    var action = component.get("c.getValidUOMs");  // Apex method to fetch UOMs
    action.setParams({ billUnitCode: billUnitCode });

    action.setCallback(this, function(response) {
        var state = response.getState();
        if (state === "SUCCESS") {
            var uomList = response.getReturnValue();
            callback(uomList);  // Return the valid UOM list to the callback
        } else {
            console.error("Error fetching valid UOMs:", response.getError());
            callback([]);  // Fallback to empty list in case of error
        }
    });

    $A.enqueueAction(action);  // Enqueue the action
}


})