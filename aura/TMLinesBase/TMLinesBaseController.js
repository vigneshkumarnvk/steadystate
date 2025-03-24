({
    doInit : function(component, event, helper) {
        var tm = component.get("v.tm");

        //ticket 19130 <<
        /*
        var jobTaskOptions = component.get("v.jobTaskOptions");
        var jobTask = component.get("v.jobTask");
        var laborLines = component.get("v.laborLines"); //for equipment operator in the equipment section
        var inlineEditComponentParams = { "tm": tm, "jobTask": jobTask, "laborLines": laborLines, "jobTaskOptions": jobTaskOptions }; //laborLines for equipment operators
        var rowComponentParams = { "tm": tm, "jobTask": jobTask };
        */
        var jobTaskWrapper = component.getReference("v.jobTaskWrapper");
        var laborLines = component.get("v.laborLines"); //for equipment operator in the equipment section
        var inlineEditComponentParams = { "tm": tm, "jobTaskWrapper": jobTaskWrapper, "laborLines": laborLines }; //laborLines for equipment operators
        var rowComponentParams = { "tm": tm, "jobTaskWrapper": jobTaskWrapper };
        //ticket 19130 >>

        component.set("v.inlineEditComponentParams", inlineEditComponentParams);
        component.set("v.rowComponentParams", rowComponentParams);
    },
    viewLine : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        helper.viewLine(component, event, rowIndex);
    },
    addLine : function(component, event, helper) {
        //helper.addLine(component, event);
        var calls = [];
        calls.push(helper.addLine.bind(helper, component, event));
        calls.push(helper.activateInlineEdit.bind(helper, component, event));
        calls.push(helper.fireTMLinesChangedEvent.bind(helper, component));
        helper.makeStackedCalls(component, event, helper, calls);
    },
    copyTime : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        helper.confirmCopyTime(component, event, rowIndex);
    },
    deleteLines : function(component, event, helper) {
        var rowIndexes = helper.getSelectedLines(component);
        if (rowIndexes.length > 0) {
            if (helper.validateDeleteLines(component, rowIndexes) == true) {
                helper.confirmDeleteLines(component, event, rowIndexes);
            }
        }
    },
    handleRowAction : function(component, event, helper) {

    },
    isInlineEditMode : function(component, event, helper) {
        var datatable = component.getConcreteComponent().find("datatable");
        if (datatable) {
            return datatable.isInlineEditMode();
        }
        return true;
    },
    validateLines : function(component, event, helper) {
        //ticket 19130 <<
        //helper.cleanUpChildResourceLines(component);
        //ticket 19130 >>
        return helper.validateLines(component);
    },
    closeInlineEdit : function(component, event, helper) {
        var callback = event.getParams().arguments.callback;
        helper.closeInlineEdit(component, callback);
    },
    //this function is called by datatable onInlineEditClose event
    handleInlineEditClose : function(component, event, helper) {
        var callback = event.getParam("callback");
        var tmLines = component.get("v.tmLines");
        //var actions = [];
        //actions.push('calculateLines');
        //helper.fireTMCalculateLinesEvent(component, actions, tmLines, callback);
        helper.fireTMLinesChangedEvent(component, callback);
    },
    refreshTable : function(component) {
        var datatable = component.find("datatable");
        datatable.refreshTable();
    },
    handleTMLineDeleteEvent : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        var rowIndexes = [ rowIndex ];
        if (helper.validateDeleteLines(component, rowIndexes) == true) {
            helper.confirmDeleteLines(component, event, rowIndexes);
        }
    },
    handleTMLineUpdateEvent : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        var tmLine = event.getParam("tmLine");
        var causedByField = event.getParam("causedByField");
        var tmLines = component.get("v.tmLines");
        tmLines[rowIndex] = tmLine;
        helper.fireTMLinesChangedEvent(component, rowIndex, causedByField);
    }
});