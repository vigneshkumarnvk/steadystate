({
    doInit : function(component, event, helper) {
        //ticket 20808 <<
        var sorts = component.get("v.sorts");
        if (sorts && Array.isArray(sorts)) {
            var items = component.get("v.items");
            helper.sort(items, sorts);
        }
        //ticket 20808 >>
        helper.initTemplate(component, event);
    },
    handleRowAction : function(component, event, helper) {
        if (event.currentTarget && event.currentTarget.dataset) { //current target = row
            var index = event.currentTarget.dataset.rowIndex;
            var name;
            if (event.target) {
                name = event.target.name;
            }

            var rowValue;
            var items = component.get("v.items");
            if (items && index >= 0 && index < items.length) {
                rowValue = items[index];
            }
            var action = event.type;
            var onRowAction = component.getEvent("onRowAction");
            onRowAction.setParams({ "action": action, "name": name, "rowIndex": index, "row": rowValue, target: event.target });
            onRowAction.fire();
        }
    },
    handleCheckboxChange : function(component, event, helper) {
        var columnIndex = parseInt(event.getSource().get("v.value"));
        var checked = event.getSource().get("v.checked");
        var columnHeaders = component.get("v.columnHeaders");
        var columnHeader = columnHeaders[columnIndex];
        var fieldName = columnHeader.selectAllCheckbox;
        var items = component.get("v.items");
        var trs = helper.findComponent(component, "tr");

        for (var i = 0; i < trs.length; i++) {
            var tr = trs[i].getElement();
            if (window.getComputedStyle(tr).display !== "none") { //only select visible lines
                items[i][fieldName] = checked;
            }
        }
        component.set("v.items", items);

        /*
        for (var i = 0; i < items.length; i++) {
            items[i][fieldName] = checked;
        }
        component.set("v.items", items);
        */

        var onSelectAll = component.getEvent("onSelectAll");
        onSelectAll.setParams({ "name": fieldName, "checked": checked });
        onSelectAll.fire();
    },
    filter : function(component, event, helper) {
        var columnIndex = event.getParam("columnIndex");
        var value = event.getParam("value");
        var columnHeaders = component.get("v.columnHeaders");
        columnHeaders[columnIndex].filterValue = value;
        component.set("v.columnHeaders[" + columnIndex + "].filterValue", value);
        helper.filter(component);
    },
    //ticket 20808 <<
    sortColumn : function(component, event, helper) {
        var index = event.getSource().get("v.value");
        var columnHeaders = component.get("v.columnHeaders");
        var columnHeader = columnHeaders[index];
        if (columnHeader.ascending == true) {
            columnHeader.ascending = false;
        }
        else {
            columnHeader.ascending = true;
        }
        component.set("v.columnHeaders[" + index + "]", columnHeader);

        var sorts = component.get("v.sorts");
        if (sorts) {
            for (var i = 0; i < sorts.length; i++) {
                if (sorts[i].fieldName == columnHeader.sortable) {
                    sorts[i].ascending = columnHeader.ascending;
                    break;
                }
            }
            var items = component.get("v.items");
            helper.sort(items, sorts);
            component.set("v.items", items);
        }
    }
    //ticket 20808 >>
})