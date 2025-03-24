({
    fireWorksheetLineViewEvent : function(component, event) {
        var rowIndex = component.get("v.index");
        var worksheetLineViewEvent = component.getEvent("worksheetLineViewEvent");
        worksheetLineViewEvent.setParams({ "rowIndex": rowIndex });
        worksheetLineViewEvent.fire();
    },
    validateResourceType : function(component, event, worksheetLine) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetLine) };
        this.callServerMethod(component, event, "c.validateResourceType", params, function(response) {
            //component.set("v.worksheetLine", JSON.parse(response));
            Object.assign(worksheetLine, JSON.parse(response));
            //ticket 19725 <<
            this.calculateBillingHours(component, event, worksheetLine, true);
            //ticket 19725 >>
            component.set("v.worksheetLine", worksheetLine);
            this.fireWorksheetLineUpdateEvent(component, event, 'Resource_Type__c');
        });
    },
    validateResource : function(component, event, worksheetLine) {
        var salesOrderId = component.get("v.salesOrderId");
        //ticket 20143 <<
        //var unitCostField = component.get("v.unitCostField");
        //ticket 20143 >>
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetLine) };
        this.callServerMethod(component, event, "c.validateResource", params, function(response) {
            Object.assign(worksheetLine, JSON.parse(response));
            if (worksheetLine.Category__c === 'Waste Disposal' && worksheetLine.System_Calculated_Line__c !== true) {
                //ticket 19873 <<
                /*
                if (worksheetLine.Unit_Cost__c == null || worksheetLine.Unit_Cost__c === 0) {
                    unitCostField.disabled = false;
                }
                */
                //ticket 20143 <<
                /*                
                if ((worksheetLine.Resource__r && (worksheetLine.Resource__r.Name == 'WD' || worksheetLine.Resource__r.Name == 'Manifest Fee')) || !worksheetLine.Costing_Source__c || (worksheetLine.Costing_Source__c && worksheetLine.Costing_Source__c.includes('Order-') != true)) {
                    unitCostField.disabled = false;
                }
                */
                //ticket 20143 >>
                //ticket 19873 <<
            } else {
                //ticket 20143 <<
                /*
                if(worksheetLine.Resource__r && worksheetLine.Resource__r.Allow_Manual_Unit_Cost_Adjustment__c === true){
                    unitCostField.disabled = false;
                }

                if(worksheetLine.Category__c == 'Subcontractors'){
                    unitCostField.disabled = false;
                }
                */
                //ticket 20143 >>
            }

            //ticket 20143 <<
            //component.set("v.unitCostField", unitCostField);
            //ticket 20143 >>
            component.set("v.worksheetLine", worksheetLine);
            this.fireWorksheetLineUpdateEvent(component, event, 'Resource__c');
        });
    },
    validateContractLine : function(component, event, worksheetLine) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetLine) };
        this.callServerMethod(component, event, "c.validateContractLine", params, function(response) {
            Object.assign(worksheetLine, JSON.parse(response));
            component.set("v.worksheetLine", worksheetLine);
            this.fireWorksheetLineUpdateEvent(component, event);
        });
    },
    calculatePriceAndCost : function(component, event, worksheetLine) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetLine) };
        this.callServerMethod(component, event, "c.calculatePriceAndCost", params, function(response) {
            Object.assign(worksheetLine, JSON.parse(response));
            this.calculateBillingHours(component, event, worksheetLine, true);
            component.set("v.worksheetLine", worksheetLine);
            this.fireWorksheetLineUpdateEvent(component, event);
        });
    },
    validateTaxGroup : function(component, event, worksheetLine) {
        var salesOrderId = component.get("v.salesOrderId");
        if (worksheetLine.Tax_Group__c == 'TX') {
            var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetLine) };
            this.callServerMethod(component, event, "c.validateTaxGroup", params, function (response) {
                Object.assign(worksheetLine, JSON.parse(response));
                component.set("v.worksheetLine", worksheetLine);
                this.fireWorksheetLineUpdateEvent(component, event);
            });
        }
        else {
            worksheetLine.Tax_Pct__c = 0;
            this.calculateLineTotals(worksheetLine);
            component.set("v.worksheetLine", worksheetLine);
            this.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    calculateLaborHours : function(component, event, worksheetLine) {
        var salesOrderId = component.get("v.salesOrderId");
        var params = { "salesOrderId": salesOrderId, "JSONWorksheetLine": JSON.stringify(worksheetLine) };
        this.callServerMethod(component, event, "c.calculateLaborHours", params, function(response) {
            Object.assign(worksheetLine, JSON.parse(response));
            //ticket 19725 <<
            if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                worksheetLine.Quantity__c = worksheetLine.Hour__c;
            }
            else {
                worksheetLine.Quantity__c = 1;
            }
            //ticket 19725 >>
            component.set("v.worksheetLine", worksheetLine);
            this.fireWorksheetLineUpdateEvent(component, event);
        });
    },
    //Ticket#20496 >>
    calculateLaborHoursUsingWeeklyRule : function(component, event, worksheetLine) {
        this.fireWorksheetLineUpdateEvent(component, event, 'calcLaborHoursUsingWeeklyRule');
    },
    //Ticket#20496 <<
    calculateBillingHours : function(component, event, worksheetLine, calcLaborHours) {
        var billingHours = this.calculateHours(worksheetLine.Billing_Start_Time__c, worksheetLine.Billing_End_Time__c);
        var lunchHours = 0;
        if (worksheetLine.Category__c == 'Labor' && worksheetLine.Include_Lunch_Y_N__c != true) {
            lunchHours = this.calculateHours(worksheetLine.Lunch_Start_Time__c, worksheetLine.Lunch_End_Time__c);
        }
        worksheetLine.Hour__c = (billingHours - lunchHours);

        if (worksheetLine.Category__c == 'Labor' && calcLaborHours == true) {
            /*
            if (worksheetLine.Billing_Start_Time__c && worksheetLine.Billing_End_Time__c) {
                this.calculateLaborHours(component, event, worksheetLine);
            }
            */
            worksheetLine.Quantity__c = 1;
            if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                if (worksheetLine.Billing_Start_Time__c && worksheetLine.Billing_End_Time__c) {
                    //Ticket#20496
                    var salesOrder = component.get("v.salesOrder");
                    if((salesOrder.Billing_Rule__r != null && salesOrder.Billing_Rule__r.Enable_Weekly_Total_Calculation__c === true) ||
                        salesOrder.Contract__r != null && salesOrder.Contract__r.Billing_Rule__r != null && salesOrder.Contract__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c === true)
                    {
                        this.calculateLaborHoursUsingWeeklyRule(component, event, worksheetLine);
                    } else {
                        this.calculateLaborHours(component, event, worksheetLine);
                    }
                    //this.calculateLaborHours(component, event, worksheetLine);
                    //Ticket#20496
                }
            }
        }
        else if (worksheetLine.Category__c == 'Equipment') {
            if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                worksheetLine.Quantity__c = worksheetLine.Hour__c;
            }
            else {
                worksheetLine.Quantity__c = 1;
            }
            this.calculateLineTotals(worksheetLine);
            component.set("v.worksheetLine", worksheetLine);
            this.fireWorksheetLineUpdateEvent(component, event);
        }
        else {
            this.calculateLineTotals(worksheetLine);
            component.set("v.worksheetLine", worksheetLine);
            this.fireWorksheetLineUpdateEvent(component, event);
        }
    },
    setWorksheetLine : function(component, event, worksheetLine) {
        component.set("v.worksheetLine", worksheetLine);
    },
    calculateJobHours : function(worksheetLine) {
        var jobHours = this.calculateHours(worksheetLine.Job_Start_Time__c, worksheetLine.Job_End_Time__c);
        var lunchHours = 0;
        if (worksheetLine.Category__c == 'Labor') {
            lunchHours = this.calculateHours(worksheetLine.Lunch_Start_Time__c, worksheetLine.Lunch_End_Time__c);
        }
        return jobHours - lunchHours;
    },
    calculateSiteHours : function(worksheetLine) {
        var siteHours = this.calculateHours(worksheetLine.Site_Start_Time__c, worksheetLine.Site_End_Time__c);
        var lunchHours = 0;
        if (worksheetLine.Category__c == 'Labor') {
            lunchHours = this.calculateHours(worksheetLine.Lunch_Start_Time__c, worksheetLine.Lunch_End_Time__c);
        }
        return siteHours - lunchHours;
    },
    calculateHours : function (startTime, endTime) {
        var hours;
        if (startTime != null && endTime != null) {
            var startTimeValue = this.timeToInteger(startTime);
            var endTimeValue = this.timeToInteger(endTime);
            if (startTimeValue == endTimeValue) {
                hours = 24;
            } else {
                hours = (endTimeValue - startTimeValue) / 36e5;
            }
        }
        else {
            hours = 0;
        }

        if (hours < 0) {
            hours += 24;
        }

        return hours;
    },
    timeToInteger : function(timeString) {
        var timeValue = null;
        if (timeString) {
            var arr = timeString.split(':');
            var h = arr[0];
            var m = arr[1];
            var s = arr[2];
            timeValue = (h * 60 * 60 + m * 60 + parseInt(s)) * 1000;
        }
        return timeValue;
    },
    showFields : function(component) {
        var salesOrder = component.get("v.salesOrder");
        console.log('Worksheet line Service Center'+ JSON.stringify(salesOrder));
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
        fields.regularRate = { "visible": false, "disabled": true };
        fields.overtimeRate = { "visible": false, "disabled": true };
        fields.doubleTimeRate = { "visible": false, "disabled": true };
        fields.regularHours = { "visible": false, "disabled": true };
        fields.overtimeHours = { "visible": false, "disabled": true };
        fields.doubleTimeHours = { "visible": false, "disabled": true };
        fields.quantity = { "visible": false, "disabled": true };
        fields.billAsLumpSum = { "visible": false, "disabled": true };
        fields.quantity = { "visible": false, "disabled": true };
        fields.billSiteTime = { "visible": false, "disabled": true };
        fields.includeLunchYN = { "visible": false, "disabled": true };
        fields.billingStartTime = { "visible": false, "disabled": true };
        fields.billingEndTime = { "visible": false, "disabled": true };
        fields.hours = { "visible": false, "disabled": true };
        fields.jobStartTime = { "visible": false, "disabled": true };
        fields.siteStartTime = { "visible": false, "disabled": true };
        fields.siteEndTime = { "visible": false, "disabled": true };
        fields.jobEndTime = { "visible": false, "disabled": true };
        fields.lunchStartTime = { "visible": false, "disabled": true };
        fields.lunchEndTime = { "visible": false, "disabled": true };
        fields.jobHours = { "visible": false, "disabled": true };
        fields.siteHours = { "visible": false, "disabled": true };
        fields.costMethod = { "visible": false, "disabled": true };
        fields.unitWeightVolume = { "visible": false, "disabled": true };
        fields.containerSize = { "visible": false, "disabled": true };
        fields.facility = { "visible": false, "disabled": true };
        fields.BOLManifest = { "visible": false, "disabled": true };
        fields.profileApproval = { "visible": false, "disabled": true };
        fields.billingMethod = { "visible": false, "disabled": true };
        fields.markupOption = { "visible": false, "disabled": true };
        fields.markup = { "visible": false, "disabled": true };

        //ticket 20143 <<
        fields.unitCost = { "visible": false, "disabled": true };
        //ticket 20143 >>

        var worksheetLine = component.get("v.worksheetLine");

        fields.select.visible = true;
        fields.select.disabled = false;
        fields.view.visible = true;
        fields.view.disabled = (worksheetLine.Category__c != 'Labor');


        fields.category.visible = true;
        fields.category.disabled = false;
        /*
        if (worksheetLine.TM_Line__c != null || worksheetLine.System_Calculated_Line__c == true || worksheetLine.Flat_Pay_Line__c == true) {
            fields.tm.disabled = true;
            fields.category.disabled = true;
        }
        */
        if (worksheetLine.TM_Line__c != null || worksheetLine.System_Calculated_Line__c == true || worksheetLine.Flat_Pay_Line__c == true) {
            fields.tm.disabled = true;
        }
        if (worksheetLine.TM_Line__c != null || worksheetLine.System_Calculated_Line__c == true || worksheetLine.Flat_Pay_Line__c == true || worksheetLine.Category__c == 'Bundled') {
            fields.category.disabled = true;
        }
        
      
        console.log('salesOrder.Service_Center__r+++++++++++'+salesOrder.Service_Center__r.Advanced_Disposal__c);
        
        if(salesOrder.Service_Center__r != null && salesOrder.Service_Center__r.Advanced_Disposal__c==true)
           {
               console.log('(worksheetLine.Category__c');
            if(worksheetLine.Category__c != 'Waste Disposal') {
                 console.log('worksheetLine.Category__c1');
                    fields.billingMethod.visible = true;
                    fields.billingMethod.disabled = true;
                    fields.profileApproval.visible = true;
                    fields.profileApproval.disabled = true;
                	fields.facility.disabled = true;
                	fields.BOLManifest.disabled = true;
            }
            /*else{
                fields.billingMethod.visible =false;
                fields.profileApproval.visible = false;
        	}*/
        
       }
        else{
            console.log('Else block');
            fields.billingMethod.visible =false;
            fields.profileApproval.visible = false;
        }
        switch(worksheetLine.Category__c) {
            case 'Labor':
                fields.serviceCenter.visible = true;
                if (!worksheetLine.Service_Center__r || worksheetLine.Service_Center__r.Temporary__c == true) {
                    fields.serviceCenter.disabled = false;
                    fields.delete.visible = true;
                    fields.delete.disabled = false;
                    fields.tm.visible = true;
                    fields.tm.disabled = false;
                }
                fields.resourceType.visible = true;
                fields.resourceType.disabled = false;
                fields.resource.visible = true;
                fields.resourceName.visible = true;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                if (!worksheetLine.Service_Center__r || (worksheetLine.Service_Center__r && worksheetLine.Service_Center__r.Temporary__c == true)) {
                    fields.resource.disabled = false;
                    fields.resourceName.disabled = false;
                }

                fields.regularRate.visible = true;
                fields.regularRate.disabled = true;
                fields.overtimeRate.visible = true;
                fields.overtimeRate.disabled = true;
                fields.doubleTimeRate.visible = true;
                fields.doubleTimeRate.disabled = true;

                if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                    fields.regularHours.visible = true;
                    fields.overtimeHours.visible = true;
                    fields.doubleTimeHours.visible = true;
                    if (salesOrder.Billing_Rule_Not_Required__c == true) {
                        fields.regularHours.disabled = false;
                        fields.overtimeHours.disabled = false;
                        fields.doubleTimeHours.disabled = false;
                    }
                }

                if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                    fields.quantity.visible = true;
                    fields.quantity.disabled = false;
                }
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.billSiteTime.visible = true;
                fields.billSiteTime.disabled = false;
                fields.includeLunchYN.visible = true;
                fields.includeLunchYN.disabled = false;
                fields.billingStartTime.visible = true;
                fields.billingStartTime.disabled = false;
                fields.billingEndTime.visible = true;
                fields.billingEndTime.disabled = false;
                fields.hours.visible = true;

                if (worksheetLine.Service_Center__r && worksheetLine.Service_Center__r.Temporary__c != true) {
                    fields.jobStartTime.visible = true;
                    fields.jobStartTime.disabled = true;
                    fields.siteStartTime.visible = true;
                    fields.siteStartTime.disabled = true;
                    fields.siteEndTime.visible = true;
                    fields.siteEndTime.disabled = true;
                    fields.jobEndTime.visible = true;
                    fields.jobEndTime.disabled = true;
                    fields.lunchStartTime.visible = true;
                    fields.lunchStartTime.disabled = true;
                    fields.lunchEndTime.visible = true;
                    fields.lunchEndTime.disabled = true;
                }
                else {
                    fields.jobStartTime.visible = true;
                    fields.jobStartTime.disabled = false;
                    fields.siteStartTime.visible = true;
                    fields.siteStartTime.disabled = false;
                    fields.siteEndTime.visible = true;
                    fields.siteEndTime.disabled = false;
                    fields.jobEndTime.visible = true;
                    fields.jobEndTime.disabled = false;
                    fields.lunchStartTime.visible = true;
                    fields.lunchStartTime.disabled = false;
                    fields.lunchEndTime.visible = true;
                    fields.lunchEndTime.disabled = false;
                }
                fields.jobHours.visible = true;
                fields.jobHours.disabled = true;
                fields.siteHours.visible = true;
                fields.siteHours.disabled = true;
                fields.facility.visible = true;
                fields.facility.disabled = true;
                fields.BOLManifest.visible = true;
                fields.BOLManifest.disabled = true;
                break;
            case 'Equipment':
                fields.serviceCenter.visible = true;
                if (!worksheetLine.Service_Center__r || worksheetLine.Service_Center__r.Temporary__c == true) {
                    fields.serviceCenter.disabled = false;
                    fields.delete.visible = true;
                    fields.delete.disabled = false;
                    fields.tm.visible = true;
                    fields.tm.disabled = false;
                }

                fields.resourceType.visible = true;
                fields.resourceType.disabled = false;
                fields.resource.visible = true;
                fields.resourceName.visible = true;
                fields.resourceName.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                if (!worksheetLine.Service_Center__r  || (worksheetLine.Service_Center__r && worksheetLine.Service_Center__r.Temporary__c == true)) {
                    fields.resource.disabled = false;
                    fields.resourceName.disabled = false;
                }
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                //if (worksheetLine.Unit_of_Measure__r && worksheetLine.Unit_of_Measure__r.Hours_UOM__c != true) {
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                //}

                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.billingStartTime.visible = true;
                fields.billingStartTime.disabled = true;
                fields.billingEndTime.visible = true;
                fields.billingEndTime.disabled = true;
                fields.hours.visible = true;
                if (worksheetLine.Service_Center__r && worksheetLine.Service_Center__r.Temporary__c != true) {
                    fields.jobStartTime.visible = true;
                    fields.jobStartTime.disabled = true;
                    fields.jobEndTime.visible = true;
                    fields.jobEndTime.disabled = true;
                }
                else {
                    fields.jobStartTime.visible = true;
                    fields.jobStartTime.disabled = false;
                    fields.jobEndTime.visible = true;
                    fields.jobEndTime.disabled = false;
                }
                fields.jobHours.visible = true;
                fields.jobHours.disabled = true;  
                fields.facility.visible = true;
                fields.facility.disabled = true;
                fields.BOLManifest.visible = true;
                fields.BOLManifest.disabled = true;
                break;
            case 'Materials':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                fields.tm.visible = true;
                fields.tm.disabled = false;
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
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                 fields.facility.visible = true;
                fields.facility.disabled = true;
                fields.BOLManifest.visible = true;
                fields.BOLManifest.disabled = true;
                break;
            case 'Subcontractors':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                fields.tm.visible = true;
                fields.tm.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = true; //Ticket#19964
               
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                fields.markupOption.visible = true;
                fields.markupOption.disabled = false;
                fields.markup.visible = true;
                fields.markup.disabled = false;

                //ticket 20143 <<
                fields.unitCost.disabled = false;
                fields.facility.visible = true;
                fields.facility.disabled = true;
                fields.BOLManifest.visible = true;
                fields.BOLManifest.disabled = true;
                //ticket 20143 >>
               
                break;
            case 'Waste Disposal':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                fields.tm.visible = true;
                fields.tm.disabled = false;
                fields.resource.visible = true;
                fields.resource.disabled = false;
                fields.description.visible = true;
                fields.description.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;
                
                if (worksheetLine.Resource__r != null && worksheetLine.Resource__r.Name != 'WD' && worksheetLine.Resource__r.Name != 'Manifest Fee' && worksheetLine.Resource__r.Name != 'MA Transporter Fee' && (worksheetLine.Resource__r.Has_Container__c == true || worksheetLine.Resource__r.Has_Weight_Volume__c == true)) {
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

                //Waste001
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;

                fields.facility.visible = true;
                fields.facility.disabled = false;
                fields.facility.required = true
                fields.BOLManifest.visible = true;
               fields.BOLManifest.disabled = false;
                //fields.profileApproval.disabled = false;
                /*if(worksheetLine.TM__r.Service_Center__r != null && worksheetLine.TM__r.Service_Center__r.Advanced_Disposal__c==true && worksheetLine.Resource__r.Name != 'Manifest Fee'){
                    fields.billingMethod.visible = true;
                    fields.billingMethod.disabled = false;
                    fields.profileApproval.visible = true;
                    fields.profileApproval.disabled = false;
                   
                }
                else{
                    fields.billingMethod.visible =false;
                    //fields.billingMethod.disabled = false;
                    fields.profileApproval.visible = false;
                }
                if(worksheetLine.Resource__r && worksheetLine.Resource__r.Name == 'Manifest Fee' &&  worksheetLine.TM__r.Service_Center__r.Advanced_Disposal__c==true ){
                  //  fields.BOLManifest.visible = true;
                //	fields.BOLManifest.disabled = true;
                    //fields.facility.visible = true;
                    //fields.facility.disabled = true;
                    fields.profileApproval.visible = false;
                    fields.profileApproval.disabled = true;
                    fields.billingMethod.visible = false;
                    fields.billingMethod.disabled = true;
                }
                if(worksheetLine.Resource__r && worksheetLine.Resource__r.Name == 'Manifest Fee' && worksheetLine.TM__r.Service_Center__r.Advanced_Disposal__c==false ){
                    fields.BOLManifest.visible = true;                	
                    fields.facility.visible = true;                   
                    fields.profileApproval.visible = false;                    
                    fields.billingMethod.visible = false;
                   
                }*/
                //if(worksheetLine.TM__r.Service_Center__r != null && worksheetLine.TM__r.Service_Center__r.Advanced_Disposal__c==true){
                if(salesOrder.Service_Center__r != null && salesOrder.Service_Center__r.Advanced_Disposal__c==true){
                    if(worksheetLine.Resource__r && worksheetLine.Resource__r.Name == 'Manifest Fee'){
                        fields.billingMethod.visible = true;
                        fields.billingMethod.disabled = false;
                        fields.profileApproval.visible = true;
                        fields.profileApproval.disabled = true;
                        fields.facility.disabled = true;
                        fields.BOLManifest.disabled = true;
                    }
                    else{
                       fields.billingMethod.visible = true;
                        fields.billingMethod.disabled = false;
                        fields.profileApproval.visible = true;
                        fields.profileApproval.disabled = false; 
                        
                    }
                }
                else{
                    if(worksheetLine.Resource__r && worksheetLine.Resource__r.Name == 'Manifest Fee'){
                        fields.billingMethod.visible = false;
                        fields.profileApproval.visible = false;
                        fields.facility.disabled = true;
                        fields.BOLManifest.disabled = true;
                    }
                    else{
                       	fields.billingMethod.visible = false;
                        fields.profileApproval.visible = false;
                    }
                }
                
                //ticket 20143 <<
                if (worksheetLine.System_Calculated_Line__c != true) {
                    fields.unitCost.disabled = false;
                    /*if ((worksheetLine.Resource__r && (worksheetLine.Resource__r.Name == 'WD' || worksheetLine.Resource__r.Name == 'Manifest Fee')) || !worksheetLine.Costing_Source__c || (worksheetLine.Costing_Source__c && worksheetLine.Costing_Source__c.includes('Order-') != true)) {
                        fields.unitCost.disabled = false;
                    }*/
                }
                //ticket 20143 >>
                break;
            case 'Demurrage':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                fields.tm.visible = true;
                fields.tm.disabled = false;
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
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;               
                break;
            case 'Misc. Charges And Taxes':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                fields.tm.visible = true;
                fields.tm.disabled = false;
                if (worksheetLine.System_Calculated_Line__c == true || worksheetLine.Flat_Pay_Line__c == true) {
                    fields.resource.visible = true;
                    fields.resource.disabled = true;
                    fields.description.visible = true;
                    fields.description.disabled = true;
                }
                else {
                    fields.resource.visible = true;
                    fields.resource.disabled = false;
                    fields.description.visible = true;
                    fields.description.disabled = false;
                }
                fields.unitOfMeasure.visible = true;
                fields.unitOfMeasure.disabled = false;
                fields.unitPrice.visible = true;
                fields.unitPrice.disabled = false;
                fields.quantity.visible = true;
                fields.quantity.disabled = false;
                fields.billAsLumpSum.visible = true;
                fields.billAsLumpSum.disabled = false;               
                break;
            case 'Bundled':
                fields.delete.visible = true;
                fields.delete.disabled = false;
                fields.tm.visible = true;
                fields.tm.disabled = false;
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
                break;
            default:
                fields.delete.visible = true;
                fields.delete.disabled = false;
                fields.tm.visible = true;
                fields.tm.disabled = false;
                break;
        }

        //ticket 20143 <<
        if(worksheetLine.Resource__r && worksheetLine.Resource__r.Allow_Manual_Unit_Cost_Adjustment__c === true){
            fields.unitCost.disabled = false;
        }
        //ticket 20143 >>

        //ticket 19571 <<
        //ticket 19130 <<
        /*
        if (worksheetLine.Parent_Line__r != null || worksheetLine.System_Calculated_Line__c == true || worksheetLine.Bundle_Line__r != null) {
            fields.delete.disabled = true;
            fields.tm.disabled = true;
        }
        */
        if (worksheetLine.System_Calculated_Line__c == true || worksheetLine.Bundle_Line__r != null) {
            fields.delete.disabled = true;
            fields.tm.disabled = true;
        }
        //ticket 19130 >>

        if (worksheetLine.TM_Line__c != null || worksheetLine.System_Calculated_Line__c == true || worksheetLine.Flat_Pay_Line__c == true) {
            fields.tm.disabled = true;
        }
        //ticket 19571 >>

        component.set("v.fields", fields);
    },
    getValidUOMs: function(component, billUnitCode, callback) {
      
        var action = component.get("c.getValidBillUnitCode");  // Apex method to fetch UOMs
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

   

});