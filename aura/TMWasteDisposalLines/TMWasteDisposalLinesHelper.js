({
    validateLines : function(component) {
        var valid = true;
        var hasError = false;
        var tmLines = component.get("v.tmLines");
        try {
            //move to TMLinesBase <<
            /*
            for (var i = 0; i < tmLines.length; i++) {
                var tmLine = tmLines[i];
                var err = {"descriptions": []};

                if (!tmLine.Resource__c) {
                    err.descriptions.push('Waste Disposal is required.');
                }
                if (!tmLine.Quantity__c || tmLine.Quantity__c == 0) {
                    err.descriptions.push('Quantity is required.');
                }

                if (tmLine.Resource__r == null || tmLine.Resource__r.Name == 'WD' || (tmLine.Resource__r.Has_Container__c != true && tmLine.Resource__r.Has_Weight_Volume__c != true)) {
                    if (!tmLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                } else {
                    if (tmLine.System_Calculated_Line__c != true) {
                        if (!tmLine.Cost_Method__c) {
                            err.descriptions.push('Cost Method is required');
                        }
                        if (!tmLine.Facility__c) {
                            err.descriptions.push('Facility is required.');
                        }
                    }
                }

                if (err.descriptions.length > 0) {
                    tmLine.errorText = '';
                    for (var j = 0; j < err.descriptions.length; j++) {
                        tmLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                    }
                    component.set("v.tmLines[" + i + "]", tmLine);
                    valid = false;
                } else if (tmLine.errorText) {
                    tmLine.errorText = null;
                    component.set("v.tmLines[" + i + "]", tmLine);
                }
            }
            */
            for (var i = 0; i < tmLines.length; i++) {
                if (tmLines[i].errorText) {
                    hasError = true;
                    break;
                }
            }
            valid = this.validateWasteDisposalLines(component, tmLines);
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

});