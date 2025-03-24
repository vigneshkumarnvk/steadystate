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
                    err.descriptions.push('Resource is required.');
                }
                if (!tmLine.Quantity__c || tmLine.Quantity__c == 0) {
                    err.descriptions.push('Quantity is required.');
                }
                if (!tmLine.Unit_of_Measure__c) {
                    err.descriptions.push('UOM is required');
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
            valid = this.validateDemurrageLines(component, tmLines);
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