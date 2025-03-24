({
    doInit : function(component, event, helper) {
        //console.log('FlexDataTable: init');
        helper.initTemplate(component, event);
    },
    handleItemsChange : function(component, event, helper) {
        var collapsible = component.get("v.collapsible");
        var sorts = component.get("v.sorts");
        //console.log("FlexDataTable: items change. collapsible: " + collapsible + ', sorts: ' + sorts.length);
        if (collapsible == true || (sorts != null && sorts.length > 0)) {
            helper.calculateRowOrders(component, true);
            helper.updateHeaderCheckbox(component, event);
        }
    }, 
    handleCheckboxChange : function(component, event, helper) {
        var fieldName = event.getSource().get("v.value");
        var checked = event.getSource().get("v.checked");
        var items = component.get("v.items");
        for (var i = 0; i < items.length; i++) {
            items[i][fieldName] = checked;
        }
        component.set("v.items", items);

        var onSelectAll = component.getEvent("onSelectAll");
        onSelectAll.setParams({ "name": fieldName, "checked": checked });
        onSelectAll.fire();
    },
    handleRowAction : function(component, event, helper) {
        if (event.currentTarget && event.currentTarget.dataset) { //current target = row
            var rowIndex = event.currentTarget.dataset.rowIndex;
            //lookup item index

            var index;
            var collapsible = component.get("v.collapsible");
            var sorts = component.get("v.sorts");
            if (collapsible == true || (sorts != null && sorts.length > 0)) {
                var rowOrders = component.get("v.rowOrders");
                index = rowOrders[rowIndex];
            }
            else {
                index = rowIndex;
            }
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
            //console.log("Flex data table: action = " + action + ' ' + event.name);
            //console.log(name + ': index = ' + index + ' rowValue: '  + JSON.stringify(rowValue));

            var onrowaction = component.getEvent("onrowaction");
            onrowaction.setParams({ "action": action, "name": name, "rowIndex": index, "row": rowValue })
            onrowaction.fire();
        }
    },
    showHelpMessageIfInvalid : function(component, event) {
        var fields = [];
        var auraIds = component.get("v.auraIds");
        //console.log('auraIds: ' + JSON.stringify(auraIds));
        for (var i = 0; i < auraIds.length; i++) {
            var cmp = component.find(auraIds[i]);
            if (cmp) {
                fields.push(cmp);
            }
        }

        var allValid = fields.reduce(function (valid, field) {
            if (field) {
                if (Array.isArray(field)) {
                    for (var j = 0; j < field.length; j++) {
                        field[j].showHelpMessageIfInvalid();
                        //return valid && field[j].get("v.validity").valid;
                        if (field[j].get("v.validity")) {
                            valid = valid && field[j].get("v.validity").valid;
                        }
                    }
                    return valid;
                } else {
                    field.showHelpMessageIfInvalid();
                    return valid && field.get("v.validity").valid;
                }
            }
            return valid;
        }, true);

        component.set("v.validity", { valid: allValid });
        return allValid;
    },
    expand : function(component, event, helper) {
        event.stopPropagation();
        helper.collapse(component, event, false);
    },
    collapse : function(component, event, helper) {
        event.stopPropagation();
        helper.collapse(component, event, true);
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

            helper.calculateRowOrders(component, true)
        }
    }
    //ticket 20808 >>
})