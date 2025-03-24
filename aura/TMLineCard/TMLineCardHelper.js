({
    //ticket 19130 <<
    showFields : function(component) {
        var tm = component.get("v.tm");
        var tmLine = component.get("v.tmLine");
        var fields = {};
        fields.ChildResource = { "id": 'child-resource', "show": false, "required": false, "disabled": true };

        if ((tm.Status__c == 'Open' || tm.Status__c == 'Scheduled' || tm.Status__c == 'Mobile Review' || tm.Status__c == 'Confirmed') && (tmLine.Resource__c || tmLine.Resource_Type__c)) {
            fields.ChildResource.show = true;
            fields.ChildResource.required = true;
            fields.ChildResource.disabled = false;
        }
        component.set("v.xFields", fields);
    },
    validateFields : function(component, event) {
        var ok = true;
        var tmLine = component.get("v.tmLine");
        var childLines = [];
        var dups = [];
        if (tmLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r.records) {
            for (var i = 0; i < tmLine.TM_Child_Lines__r.records.length; i++) {
                var relation = tmLine.TM_Child_Lines__r.records[i];
                if (!relation.Child_Line__r || !relation.Child_Line__r.Line_No__c) {
                    tmLine.TM_Child_Lines__r.records.splice(i, 1);
                    i--;
                }
                else {
                    if (!childLines.includes(parseInt(relation.Child_Line__r.Line_No__c))) {
                        childLines.push(parseInt(relation.Child_Line__r.Line_No__c));
                    }
                    else {
                        dups.push('"' + relation.Child_Line__r.Description__c + '"');
                        ok = false;
                    }
                }
            }
        }

        if (dups.length > 0) {
            this.showToast(component, "", "Duplicated child resources are entered: " + dups.join(",") + ". Please remove.", "error", "dismissible");
        }

        return ok;
    },
    saveTMLine : function(component, event) {
        var tmLine = component.get("v.tmLine");
        var actionParams = event.getParams().arguments;
        if (actionParams.callback) {
            actionParams.callback(tmLine);
        }
    },
    //ticket 19130 >>
    //temporary disable flat pay function
    /*
    save : function(component, event) {
        var tmLine = component.get("v.tmLine");
        var actionParams = event.getParams().arguments;
        if (actionParams.callback) {
            actionParams.callback(tmLine);
        }
    },
    validateFields : function(component, event) {
        var tmLine = component.get("v.tmLine");
        if (tmLine.Resource_Flat_Pays1__r != null && tmLine.Resource_Flat_Pays1__r.records != null) {
            var flatRateTypeIds = [];
            for (var i = 0; i < tmLine.Resource_Flat_Pays1__r.records.length; i++) {
                var flatPayLine = tmLine.Resource_Flat_Pays1__r.records[i];
                if (flatPayLine.Flat_Rate_Type__c == null) {
                    throw Error('Line #' + i + ': flat rate type is required.');
                }
                if (flatPayLine.Rate__c == null || flatPayLine.Rate__c == 0) {
                    throw Error('Line #' + i + ': rate is required.');
                }

                if (flatRateTypeIds.includes(flatPayLine.Flat_Rate_Type__c)) {
                    throw Error('Line #' + i + ': duplicated flat pay lines (flat pay type: ' + flatPayLine.Flat_Rate_Type__r.Name + ').');
                }
                flatRateTypeIds.push(flatPayLine.Flat_Rate_Type__c);
            };
        }
        return true;
    }
    */
    //temporary disable flat pay function
});