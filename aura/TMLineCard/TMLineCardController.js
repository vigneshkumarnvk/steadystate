({
    //ticket 19130 <<
    doInit : function(component, event, helper) {
        helper.showFields(component);
        console.log(JSON.stringify(component.get("v.tmLine")));
    },
    addChildResource : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        if (!tmLine.TM_Child_Lines__r || !tmLine.TM_Child_Lines__r.records) {
            tmLine.TM_Child_Lines__r = { "records": [] };
        }
        tmLine.TM_Child_Lines__r.records.push({
            "Parent_Line__c": tmLine.Id,
            "Parent_Line__r": {
                "attributes": {"type": 'TM_Line__c'},
                "Id": tmLine.Id,
                "Line_No__c": tmLine.Line_No__c,
                "Category__c": tmLine.Category__c,
                "Resource_Type__c": tmLine.Resource_Type__c,
                "Resource_Type__r": tmLine.Resource_Type__r,
                "Resource__c": tmLine.Resource__c,
                "Resource__r": tmLine.Resource__r
            }
        });
        component.set("v.tmLine", tmLine);
    },
    removeParentChildRelation : function(component, event, helper) {
        var rowIndex = event.getSource().get("v.value");
        var tmLine = component.get("v.tmLine");
        if (tmLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r.records) {
            tmLine.TM_Child_Lines__r.records.splice(rowIndex, 1);
        }
        component.set("v.tmLine", tmLine);
    },
    handleRelationChange : function(component, event, helper) {
        var rowIndex = parseInt(event.getSource().get("v.label")); //use label to pass rowIndex
        var tmLine = component.get("v.tmLine");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        if (tmLine.TM_Child_Lines__r && tmLine.TM_Child_Lines__r.records) {
            var relation = tmLine.TM_Child_Lines__r.records[rowIndex];
            var childLineNo = relation.Child_Line__r.Line_No__c;
            for (var i = 0; i < jobTaskWrapper.TMLines.length; i++) {
                if (parseInt(jobTaskWrapper.TMLines[i].Line_No__c) == parseInt(childLineNo)) {
                    var childTMLine = jobTaskWrapper.TMLines[i];
                    relation.Child_Line__r.Id = childTMLine.Id;
                    relation.Child_Line__r.Category__c = childTMLine.Category__c;
                    relation.Child_Line__r.Resource_Type__c = childTMLine.Resource_Type__c;
                    relation.Child_Line__r.Resource_Type__r = childTMLine.Resource_Type__r;
                    relation.Child_Line__r.Resource__c = childTMLine.Resource__c;
                    relation.Child_Line__r.Resource__r = childTMLine.Resource__r;
                    relation.Child_Line__r.Description__c = childTMLine.Description__c;
                    relation.Child_Line__c = childTMLine.Id;
                    break;
                }
            }
        }
    },
    save : function(component, event, helper) {
        if (helper.validateFields(component, event)) {
            helper.saveTMLine(component, event);
        }
    }
    //ticket 19130 >>
    //temporary disable flat pay function
    /*
    addFlatPayLine : function(component, event, helper) {
        var tmLine = component.get("v.tmLine");
        if (tmLine.Resource_Flat_Pays1__r == null) {
            tmLine.Resource_Flat_Pays1__r = {"totalSize": 0, "done": true, "records": []};
        }

        var flatPayLine = {};
        flatPayLine.T_M__c = tmLine.TM__c;
        flatPayLine.T_M__r = tmLine.TM__r;
        flatPayLine.T_M_Line__c = tmLine.Id;
        flatPayLine.T_M_Line__r = { "Id": tmLine.Id, "Line_No__c": tmLine.Line_No__c };
        tmLine.Resource_Flat_Pays1__r.records.push(flatPayLine);
        tmLine.Resource_Flat_Pays1__r.totalSize = tmLine.Resource_Flat_Pays1__r.records.length;

        component.set("v.tmLine", tmLine);
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");
        var tmLine = component.get("v.tmLine");
        var flatPayLine = tmLine.Resource_Flat_Pays1__r.records[rowIndex];
        switch(name) {
            case 'delete':
                if (action == 'click') {
                    if (tmLine.Resource_Flat_Pays1__r != null && tmLine.Resource_Flat_Pays1__r.records.length > rowIndex) {
                        tmLine.Resource_Flat_Pays1__r.records.splice(rowIndex, 1);
                        tmLine.Resource_Flat_Pays1__r.totalSize = tmLine.Resource_Flat_Pays1__r.records.length;
                        component.set("v.tmLine", tmLine);
                    }
                }
                break;
            case 'rate-type':
                if (action == 'change') {
                    if (flatPayLine.Flat_Rate_Type__r != null) {
                        flatPayLine.Flat_Rate_Type__c = flatPayLine.Flat_Rate_Type__r.Id;
                        flatPayLine.Misc_Charge_Resource__r = flatPayLine.Flat_Rate_Type__r.Misc_Charge_Resource__r;
                        flatPayLine.Misc_Charge_Resource__c = flatPayLine.Flat_Rate_Type__r.Misc_Charge_Resource__c;
                        if (flatPayLine.Misc_Charge_Resource__r != null && flatPayLine.Misc_Charge_Resource__r.Unit_of_Measure__r != null) {
                            flatPayLine.Unit_of_Measure__c = flatPayLine.Misc_Charge_Resource__r.Unit_of_Measure__c;
                            flatPayLine.Unit_of_Measure__r = flatPayLine.Misc_Charge_Resource__r.Unit_of_Measure__r;
                        }
                        flatPayLine.Rate__c = flatPayLine.Flat_Rate_Type__r.Rate__c;
                    } else {
                        flatPayLine.Misc_Charge_Resource__r = null;
                        flatPayLine.Misc_Charge_Resource__c = null;
                        flatPayLine.Flat_Rate_Type__c = null;
                    }
                    component.set("v.tmLine.Resource_Flat_Pays1__r.records[" + rowIndex + "]", flatPayLine);
                }
                break;
            case 'misc-charge-resource':
                if (action == 'change') {
                    if (flatPayLine.Unit_of_Measure__r != null) {
                        flatPayLine.Misc_Charge_Resource__c = flatPayLine.Unit_of_Measure__r.Id;
                    } else {
                        flatPayLine.Misc_Charge_Resource__c = null;
                    }
                    component.set("v.tmLine.Resource_Flat_Pays1__r.records[" + rowIndex + "]", flatPayLine);
                }
                break;
        }
    },
    save : function(component, event, helper) {
        try {
            if (helper.validateFields(component, event)) {
                helper.save(component, event);
            }
        }
        catch(err) {
            helper.showToast(component, "Error", err.message, "error", "dismissible");
        }
    }
    */
    //temporary disable flat pay function

});