({
    createFlatPay : function(component, event) {
        var selectedLaborLines = [];
        var tmLines = component.get("v.tmLines");
        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            if (tmLine.Selected == true) {
                if (tmLine.Invoiced__c === true) {
                    this.showToast(component, "Error", "Line " + tmLine.Line_No__c + " has been invoiced. You cannot create flat pay.", "error", "dismissible");
                    return;
                }
                selectedLaborLines.push(tmLine);
            }
        }

        if (selectedLaborLines.length > 0) {
            var buttons = [];
            buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'Create', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "create", "callback": this.createFlatPayCallback.bind(this, component, event, selectedLaborLines) }});
            var params = { "laborLines": selectedLaborLines };
            this.openModal(component, event, 'Create Flat Pay', null, buttons, 'c:TMFlatPayCard', params, 'small-high');
        }
        else {
            this.showToast(component, "Error", "You must choose at least one line to create flat pay.", "error", "dismissible");
        }
    },
    createFlatPayCallback : function(component, event, selectedLaborLines, flatPay) {
        this.closeModal(component, event);
        this.closeInlineEdit(component);

        var tm = component.get("v.tm");
        var mapNewFlatPaysByTMLineNo = new Map();
        var mapFlatPayTypeIdsByTMLineNo = new Map();

        for (var i = 0; i < selectedLaborLines.length; i++) {
            var tmLine = selectedLaborLines[i];
            if (tmLine.Resource_Flat_Pays1__r && tmLine.Resource_Flat_Pays1__r.records) {
                var flatPayTypeIds = [];
                mapFlatPayTypeIdsByTMLineNo.set(tmLine.Line_No__c, flatPayTypeIds);
                for (var j = 0; j < tmLine.Resource_Flat_Pays1__r.records.length; j++) {
                    flatPayTypeIds.push(tmLine.Resource_Flat_Pays1__r.records[j].Flat_Rate_Type__c);
                }
            }
        }
        
        //create flat pay for the selected labor lines
        for (var i = 0; i < selectedLaborLines.length; i++) {
            var tmLine = selectedLaborLines[i];

            //check for existing flat pay types
            var flatPayExists = false;
            if (mapFlatPayTypeIdsByTMLineNo.has(tmLine.Line_No__c)) {
                var flatPayTypeIds = mapFlatPayTypeIdsByTMLineNo.get(tmLine.Line_No__c);
                if (flatPayTypeIds.includes(flatPay.Flat_Rate_Type__c)) {
                    flatPayExists = true;
                }
            }

            if (!flatPayExists) {
                var resourceFlatPay = {};
                resourceFlatPay.Flat_Rate_Type__c = flatPay.Flat_Rate_Type__c;

                resourceFlatPay.Flat_Rate_Type__r = flatPay.Flat_Rate_Type__r;
                resourceFlatPay.Misc_Charge_Resource__c = flatPay.Misc_Charge_Resource__c;
                resourceFlatPay.Misc_Charge_Resource__r = flatPay.Misc_Charge_Resource__r;
                if (flatPay.Misc_Charge_Resource__r != null) {
                    resourceFlatPay.Unit_of_Measure__c = flatPay.Misc_Charge_Resource__r.Unit_of_Measure__c;
                    resourceFlatPay.Unit_of_Measure__r = flatPay.Misc_Charge_Resource__r.Unit_of_Measure__r;
                }
                resourceFlatPay.Rate__c = flatPay.Rate__c;
                resourceFlatPay.T_M__c = tm.Id;
                resourceFlatPay.T_M_Line__c = tmLine.Id;
                resourceFlatPay.T_M_Line__r = {Id: tmLine.Id, "Line_No__c": tmLine.Line_No__c};
                mapNewFlatPaysByTMLineNo.set(tmLine.Line_No__c, resourceFlatPay);
            }
        }

        var tmLines = component.get("v.tmLines");
        for (var i = 0; i < tmLines.length; i++) {
            var tmLine = tmLines[i];
            if (mapNewFlatPaysByTMLineNo.has(tmLine.Line_No__c)) {
                if (!tmLine.Resource_Flat_Pays1__r) {
                    tmLine.Resource_Flat_Pays1__r = {"totalSize": 0, "done": true, "records": []};
                }
                tmLine.Resource_Flat_Pays1__r.records.push(mapNewFlatPaysByTMLineNo.get(tmLine.Line_No__c));
                tmLine.Resource_Flat_Pays1__r.totalSize = tmLines[i].Resource_Flat_Pays1__r.records.length; //update total records
            }
            tmLine.Selected = false;
        }
        component.set("v.tmLines", tmLines);

        //update the TMLaborLine view
        //this.refreshTable(component);

        this.fireTMLinesChangedEvent(component, null, 'Flat_Pay_Lines__r');
    },
    validateLines : function(component) {
        var valid = true;
        var hasError = false;
        var tmLines = component.get("v.tmLines");
        try {
            //move to TMLinesBase <<
            /*
            for (var i = 0; i < tmLines.length; i++) {
                var tmLine = tmLines[i];
                tmLine.errorText = null;

                var err = {"descriptions": []};
                if (!tmLine.Resource_Type__c) {
                    err.descriptions.push('Resource Type is required.');
                }
                if (!tmLine.Resource__c) {
                    err.descriptions.push('Resource is required.');
                }
                if (!tmLine.Service_Center__c) {
                    err.descriptions.push('Service Center is required.');
                }

                if (!tmLine.Unit_of_Measure__c) {
                    err.descriptions.push('UOM is required.');
                }

                if (!tmLine.Job_Start_Time__c) {
                    err.descriptions.push('Job Start Time is required.');
                }
                if (!tmLine.Site_Start_Time__c) {
                    err.descriptions.push('Site Start Time is required.');
                }
                if (!tmLine.Site_End_Time__c) {
                    err.descriptions.push('Site End Time is required.');
                }
                if (!tmLine.Job_End_Time__c) {
                    err.descriptions.push('Job End Time is required.');
                }

                if ((!tmLine.Quantity__c || tmLine.Quantity__c == 0) && !tmLine.Parent_Line__r) {
                    err.descriptions.push('Quantity is required.');
                }
                //ticket 19447 <<
                else if (tmLine.Unit_of_Measure__r && tmLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                    if (parseFloat(tmLine.Total_Job_Hours__c) - this.calculateLunchHours(tmLine) != parseFloat(tmLine.Quantity__c)) {
                        err.descriptions.push('Quantity must equal to Job Hours.');
                    }
                }
                //ticket 19447 >>

                //check duplicated flat pay lines
                if (tmLine.Resource_Flat_Pays1__r != null && tmLine.Resource_Flat_Pays1__r.records != null) {
                    var flatRateTypeIds = [];
                    for (var j = 0; j < tmLine.Resource_Flat_Pays1__r.records.length; j++) {
                        var flatRateTypeId = tmLine.Resource_Flat_Pays1__r.records[j].Flat_Rate_Type__c;
                        if (flatRateTypeIds.includes(flatRateTypeId)) {
                            err.descriptions.push('Duplicated flat pay type ' + tmLine.Resource_Flat_Pays1__r.records[i].Flat_Rate_Type__r.Name);
                            break;
                        }
                        flatRateTypeIds.push(flatRateTypeId);
                    }
                }

                if (err.descriptions.length > 0) {
                    tmLine.errorText = '';
                    for (var j = 0; j < err.descriptions.length; j++) {
                        tmLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                    }
                    //component.set("v.tmLines[" + i + "]", tmLine);
                    valid = false;
                }
                //else if (tmLine.errorText) {
                //    tmLine.errorText = null;
                //component.set("v.tmLines[" + i + "]", tmLine);
                //}
                component.set("v.tmLines[" + i + "]", tmLine);
            }
            */
            for (var i = 0; i < tmLines.length; i++) {
                if (tmLines[i].errorText) {
                    hasError = true;
                    break;
                }
            }
            valid = this.validateLaborLines(component, tmLines);
            //move to TMLinesBase >>
        }
        catch(err) {
            alert(err);
        }

        if (!valid || hasError) {
            var datatable = component.find("datatable");
            datatable.refreshTable(); //need to refresh table because items are passed to the line component as value
        }

        return valid;
    },
    //move to TMLinesBase <<
    /*
    //ticket 19447 <<
    calculateLunchHours : function(tmLine) {
        return this.calculateHours(tmLine.Lunch_Start_Time__c, tmLine.Lunch_End_Time__c);
    }
    //ticket 19447 >>
    */
    //move to TMLinesBase >>
});