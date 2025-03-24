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

                if (!tmLine.Resource_Type__c) {
                    err.descriptions.push('Equipment Type is required.');
                }
                if (!tmLine.Resource__c && tmLine.Resource_Type__r && tmLine.Resource_Type__r.Fleet_No_Required__c == true && tmLine.Service_Center__r && tmLine.Service_Center__r.Equipment_Fleet_No_Not_Required__c != true) {
                    err.descriptions.push('Equipment is required.');
                }

                if (!tmLine.Service_Center__c) {
                    err.descriptions.push('Service Center is required');
                }

                if (tmLine.Resource_Type__r && tmLine.Resource_Type__r.Fleet_No_Required__c == true) {
                    if (!tmLine.Job_Start_Time__c) {
                        err.descriptions.push('Job Start Time is required');
                    }
                    if (!tmLine.Job_End_Time__c) {
                        err.descriptions.push('Job End Time is required');
                    }
                }

                if (!tmLine.Quantity__c || tmLine.Quantity__c == 0) {
                    err.descriptions.push('Quantity is required.');
                }
                //ticket 19447 <<
                else if (tmLine.Resource_Type__r && tmLine.Resource_Type__r.Fleet_No_Required__c == true && tmLine.Unit_of_Measure__r && tmLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                    if (parseFloat(tmLine.Total_Job_Hours__c) - this.calculateLunchHours(tmLine) != parseFloat(tmLine.Quantity__c)) {
                        err.descriptions.push('Quantity must equal to Job Hours.');
                    }
                }
                //ticket 19447 >>

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
            valid = this.validateEquipmentLines(component, tmLines);
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
    //move to TMLinesBase <<
});