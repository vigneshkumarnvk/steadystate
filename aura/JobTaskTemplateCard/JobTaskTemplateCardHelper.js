({
    getJobTaskTemplate : function(component, event) {
        var recordId = component.get("v.recordId");
        if (recordId != null) {
            var params = { "jobTaskTemplateId": recordId };
            this.callServerMethod(component, event, "c.getJobTaskTemplate", params, function(response) {
                var jobTaskTemplateWrapper = JSON.parse(response);
                var jobTaskTemplate = jobTaskTemplateWrapper.JobTaskTemplate;
                var jobTaskTemplateLines = jobTaskTemplateWrapper.JobTaskTemplateLines;
                component.set("v.jobTaskTemplate", jobTaskTemplate);
                component.set("v.jobTaskTemplateLines", jobTaskTemplateLines);
            })
        }
        else {
            component.set("v.jobTaskTemplate", {});
            component.set("v.jobTaskTemplateLines", []);
        }
    },
    validate : function(component, event) {
        var ok = true;
        var jobTaskTemplate = component.get("v.jobTaskTemplate");
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
        for (var i = 0; i < jobTaskTemplateLines.length; i++) {
            var jobTaskTemplateLine = jobTaskTemplateLines[i];
            if (jobTaskTemplateLine.Category__c == '' && jobTaskTemplateLine.Resource__c == null && jobTaskTemplateLine.Resource_Type__c == null) {
                //do nothing, will remove
            }
            else {
                if (jobTaskTemplate.Type__c == 'Wizard') {
                    if (!jobTaskTemplateLine.Question__c) {
                        this.showToast(component, "Error", "You must set up questions on all lines.", "error", "dismissible");
                        ok = false;
                        break;
                    }
                }
            }
        }
        return ok;
    },
    saveJobTaskTemplate : function(component, event) {
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
        for (var i = 0; i < jobTaskTemplateLines.length; i++) {
            if (jobTaskTemplateLines[i].Category__c == '' && jobTaskTemplateLines[i].Resource__c == null && jobTaskTemplateLines[i].Resource_Type__c == null) {
                jobTaskTemplateLines.splice(i, 1);
                i--;
            }
        }
        component.set("v.jobTaskTemplateLines", jobTaskTemplateLines);

        if (this.validateFields(component, event)) {
            var jobTaskTemplate = component.get("v.jobTaskTemplate");

            var JSONJobTaskTemplate = JSON.stringify(jobTaskTemplate);
            var JSONJobTaskTemplateLines = JSON.stringify(jobTaskTemplateLines);
            //console.log('JSONJobTaskTemplateLines: ' + JSONJobTaskTemplateLines);
            var params = { JSONJobTaskTemplate: JSONJobTaskTemplate,  JSONJobTaskTemplateLines: JSONJobTaskTemplateLines};

            this.callServerMethod(component, event, "c.saveJobTaskTemplate", params, function(dataTemplateId) {
                this.navigateToSObject(component, event, dataTemplateId);
            })
        }
    },
    addTemplateLine : function(component, event, category) {
        var jobTaskTemplate = component.get("v.jobTaskTemplate");
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
        var nextTemplateLineNo = component.get("v.nextTemplateLineNo");
        var jobTaskTemplateLine = { "Category__c": category, "Line_No__c": nextTemplateLineNo };
        nextTemplateLineNo++;

        var params = { "jobTaskTemplate": jobTaskTemplate, "jobTaskTemplateLines": jobTaskTemplateLines, "jobTaskTemplateLine": jobTaskTemplateLine, "nextTemplateLineNo": nextTemplateLineNo };
        var buttons = [];
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "saveTemplateLine", "callback": this.addTemplateLineCallback.bind(this, component, event, false) }});
        buttons.push({ "label": 'Save & New', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "saveTemplateLine", "callback": this.addTemplateLineCallback.bind(this, component, event, true) }});
        this.openModal(component, event, 'New Job Task Template Line', null, buttons, 'c:JobTaskTemplateLineCard', params, 'small');
    },
    addTemplateLineCallback : function(component, event, doNewLine, jobTaskTemplateLines, defaultCategory) {
        try {
            component.set("v.jobTaskTemplateLines", jobTaskTemplateLines);
        }
        catch(error) {
            alert(error);
        }
        finally{
            if (doNewLine) {
                this.closeModal(component, event);
                this.addTemplateLine(component, event, defaultCategory);
            }
            else {
                this.closeModal(component, event);
            }
        }
    },
    cancelCallback : function(component, event) {
        this.closeModal(component, event);
    },
    editTemplateLine : function(component, event, rowIndex) {
        try {
            var jobTaskTemplate = component.get("v.jobTaskTemplate");
            var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
            var nextTemplateLineNo = component.get("v.nextTemplateLineNo");
            var jobTaskTemplateLine = jobTaskTemplateLines[rowIndex];
            var params = { "jobTaskTemplate": jobTaskTemplate, "jobTaskTemplateLines": jobTaskTemplateLines, "jobTaskTemplateLine": jobTaskTemplateLine, "nextTemplateLineNo": nextTemplateLineNo };
            var buttons = [];
            buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
            buttons.push({ "label": 'Save', "variant": 'brand', "action": { "scope": 'COMPONENT', "method": "saveTemplateLine", "callback": this.editTemplateLineCallback.bind(this, component, event) }});
            this.openModal(component, event, 'Edit Task Template Line', null, buttons, 'c:JobTaskTemplateLineCard', params, 'small');
        }
        catch(error) {
            alert(error);
        }
    },
    editTemplateLineCallback : function(component, event, jobTaskTemplateLines) {
        try {
            component.set("v.jobTaskTemplateLines", jobTaskTemplateLines);
        }
        catch(error) {
            alert(error);
        }
        finally {
            this.closeModal(component, event);
        }
    },
    deleteTemplateLine : function(component, event, rowIndex) {
        var buttons = [];
        buttons.push({ "label": 'OK', "variant": 'brand', "action": { "callback": this.deleteTemplateLineCallback.bind(this, component, event, rowIndex) }});
        buttons.push({ "label": 'Cancel', "variant": 'neutral', "action": { "callback": this.cancelCallback.bind(this, component, event) }});
        this.openModal(component, event, 'Delete Task Template Line', 'Are you sure you want to delete this template line?', buttons, null, null, null);
    },
    deleteTemplateLineCallback : function(component, event, rowIndex) {
        try {
            var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
            jobTaskTemplateLines.splice(rowIndex, 1);
            component.set("v.jobTaskTemplateLines", jobTaskTemplateLines);
        }
        catch(error) {
            alert(error);
        }
        finally {
            this.closeModal(component, event);
        }
    },
    validateFields : function(component, event) {
        var fields = [];
        fields.push(component.find("name"));

        var allValid = fields.reduce(function(valid, field) {
            if (field) {
                if (Array.isArray(field)) {
                    for (var i = 0; i < field.length; i++) {
                        field[i].showHelpMessageIfInvalid();
                        valid = valid && field[i].get("v.validity").valid;
                    }
                    return valid;
                } else {
                    field.showHelpMessageIfInvalid();
                    return valid && field.get("v.validity").valid;
                }
            }
            return valid;
        }, true);

        return allValid;
    },
    sortTemplateLines : function(component) {
        var jobTaskTemplateLines = component.get("v.jobTaskTemplateLines");
        jobTaskTemplateLines.sort(function(a, b) {
            var sorts = ['Labor', 'Equipment', 'Materials', 'Subcontractors', 'Waste Disposal', 'Misc. Charges And Taxes', 'Demurrage', 'Bundled'];
            var val1 = sorts.indexOf(a.Category__c);
            var val2 = sorts.indexOf(b.Category__c);
            var order = 0;
            if (val1 > val2) {
                order = 1;
            }
            else if (val1 < val2) {
                order = -1;
            }
            else {
                if (a.Line_No__c > b.Line_No__c) {
                    order = 1;
                }
                else if (a.Line_No__c < b.Line_No__c) {
                    order = -1;
                }
            }
            return order;
        });
        component.set("v.jobTaskTemplateLines", jobTaskTemplateLines);
    }
});