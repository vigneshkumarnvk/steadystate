({
    getTemplateLines : function(component, event, jobTaskTemplateId) {
        if (jobTaskTemplateId != null) {
            var params = { "jobTaskTemplateId": jobTaskTemplateId };
            this.callServerMethod(component, event, "c.getJobTaskTemplateLines", params, function(response) {
                var jobTaskTemplateLines = JSON.parse(response);
                for (var i = 0; i < jobTaskTemplateLines.length; i++) {
                    jobTaskTemplateLines[i].Selected = true;
                }

                let sorts = [
                    { fieldName: 'Category__c', ascending: true, custom: ['Labor', 'Equipment', 'Materials', 'Subcontractors', 'Waste Disposal', 'Misc. Charges And Taxes', 'Demurrage', 'Bundled']},
                    { fieldName: 'Line_No__c', ascending: true, custom: null },
                ];
                this.sortLines(jobTaskTemplateLines, sorts);

                component.set("v.selectAll", true);
                component.set("v.jobTaskTemplateLines", jobTaskTemplateLines);
            })
        }
    },
    save : function(component, event) {
        var jobTask = component.get("v.jobTask");
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
        for (var i = 0; i < jobTaskTemplateLines.length; i++) {
            if (jobTaskTemplateLines[i].Selected != true) {
                jobTaskTemplateLines.splice(i, 1);
                i--;
            }
        }
        var actionParams = event.getParams().arguments;
        if (actionParams.callback) {
            actionParams.callback(jobTask, jobTaskTemplateLines);
        }
    },
    validateFields : function(component, event) {
        var fields = [];
        if (component.find("name")) {
            fields.push(component.find("name"));
        }

        var mode = component.get("v.mode");
        if (mode == 'create-task-from-template') {
            if (component.find("billing-type")) {
                fields.push(component.find("billing-type"));
            }
        }

        /*
        var jobTask = component.get("v.jobTask");
        if (jobTask.Billing_Type__c == 'Fixed Price') {
            fields.push(component.find("fixed-price"));
        }
        */

        var ok = fields.reduce(function(valid, field) {
            if (Array.isArray(field)) {
                for (var i = 0; i < field.length; i++) {
                    field[i].showHelpMessageIfInvalid();
                    valid = valid && field[i].get("v.validity").valid;
                }
                return valid;
            }
            else {
                field.showHelpMessageIfInvalid();
                return valid && field.get("v.validity").valid;
            }

        }, true);

        var lineNumbers = [];
        var resourceNames = [];
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
        for (var i = 0; i < jobTaskTemplateLines.length; i++) {
            var jobTaskTemplateLine = jobTaskTemplateLines[i];
            if (jobTaskTemplateLine.Selected != true && jobTaskTemplateLine.Quantity__c) {
                lineNumbers.push(jobTaskTemplateLine.Line_No__c);
                if (jobTaskTemplateLine.Category__c == 'Labor' || jobTaskTemplateLine.Category__c == 'Equipment' || jobTaskTemplateLine.Category__c == 'Bundled') {
                    resourceNames.push(jobTaskTemplateLine.Resource_Type__r.Name);
                }
                else {
                    resourceNames.push(jobTaskTemplateLine.Resource__r.Name);
                }
            }
        }
        if (ok != true) {
            this.showToast(component, "Error", "Please complete all required fields.", "error", "dismissible");
        }
        else if (lineNumbers.length > 0) {
            ok = false;
            this.showToast(component, "", "You've entered quantity for " + resourceNames.join(', ') + ', but did not select the line. Please select the line or remove the quantity.', "error", "dismissible");
        }


        return ok;
    },
    sortLines : function(objList, sorts) {
        objList.sort(function(a, b) {
            return sort(a, b, sorts, 0);
        });

        function sort(a, b, sorts, sortIndex) {
            var fieldName = sorts[sortIndex].fieldName;
            var custom = sorts[sortIndex].custom;
            var ascending = sorts[sortIndex].ascending;

            var val1;
            var val2;
            if (custom != null) {
                val1 = custom.indexOf(a[fieldName]);
                val2 = custom.indexOf(b[fieldName]);
            }
            else {
                val1 = a[fieldName];
                val2 = b[fieldName];
            }

            var order = 0;
            if (val1 > val2) {
                order = 1;
            } else if (val1 < val2) {
                order = -1;
            }
            else {
                if (sortIndex < sorts.length - 1) {
                    sortIndex++;
                    order = sort(a, b, sorts, sortIndex);
                }
            }

            if (ascending != true) {
                order = order * -1;
            }
            return order;
        };
    },
});