({
    doInit : function(component, event, helper) {
        /*
        //tableClasses and tableStyles
        var horizontalScroll = component.get("v.horizontalScroll");
        var verticalScroll = component.get("v.verticalScroll");
        var fixedColumns = component.get("v.fixedColumns");
        var fixedHeaders = component.get("v.fixedHeaders");
        var height = component.get("v.height");
        var showRowNumbers = component.get("v.showRowNumbers");
        var parentLinkField = component.get("v.parentLinkField");
        var childLinkField = component.get("v.childLinkField");

        if (showRowNumbers == true) {
            fixedColumns++;
        }
        if (parentLinkField && childLinkField) {
            fixedColumns++;
        }
        component.set("v.fixedColumns", fixedColumns);

        var classes = [];
        var styles = [];
        if (horizontalScroll == true) {
            classes.push('horizontal-scroll');
            if (fixedColumns > 0) classes.push('fixed-column');
        }
        if (verticalScroll == true) {
            classes.push('vertical-scroll');
            if (fixedHeaders == true) classes.push('fixed-header');
            styles.push("max-height: " + height);
        }

        if (classes.length > 0) {
            component.set("v.tableClass", classes.join(' '));
        }
        if (styles.length > 0) {
            component.set("v.tableStyle", styles.join(' '));
        }

        helper.initIterationTemplate(component, event);
        helper.buildParentChildRelationshipMap(component);
        */
        component.set("v.savedTemplate", component.get("v.template"));
        helper.buildTable(component, event);
    },
    handleItemsChange : function(component, event, helper) {
        helper.buildParentChildRelationshipMap(component);
    },
    handleRowAction : function(component, event, helper) {
        var disabled = component.get("v.disabled");
        if (disabled == true) {
            return;
        }

        if (event.currentTarget && event.currentTarget.dataset) { //current target = row
            var rowIndex = event.currentTarget.dataset.rowIndex;

            var name;
            if (event.target) {
                name = event.target.name;
            }

            var rowValue;
            var items = component.get("v.items");
            if (items && rowIndex >= 0 && rowIndex < items.length) {
                rowValue = items[rowIndex];
            }
            var action = event.type;

            if (action == 'click') {
                var inlineComponentName = component.get("v.inlineEditComponentName");
                if (inlineComponentName != null) {
                    var noneInlineFields = component.get("v.noneInlineFields");
                    if (!noneInlineFields) {
                        noneInlineFields = [];
                    }
                    noneInlineFields.push('rowNumber');
                    noneInlineFields.push('collapsibleButton');
                    if (!noneInlineFields.includes(name)) {
                        var inlineEditRowIndex = component.get("v.inlineEditRowIndex");
                        //if (inlineEditRowIndex != rowIndex) {
                        if (inlineEditRowIndex >= 0) {
                            if (helper.closeInlineEdit(component) == true) {
                                helper.openInlineEdit(component, rowIndex);
                            }
                        } else {
                            helper.openInlineEdit(component, rowIndex);
                        }
                        //}
                    }
                }
            }

            var onRowAction = component.getEvent("onRowAction");
            onRowAction.setParams({ "action": action, "name": name, "rowIndex": rowIndex, "row": rowValue });
            onRowAction.fire();
        }
    },
    handleCheckboxChange : function(component, event, helper) {
        var columnIndex = parseInt(event.getSource().get("v.value"));
        var checked = event.getSource().get("v.checked");
        var items = component.get("v.items");
        var varName = component.get("v.var");
        var indexVar = component.get("v.indexVar");
        var rowComponents = helper.findComponent(component, "row-component");
        var mapRowComponentsByRowIndex = new Map();
        var columnHeaders = component.get("v.columnHeaders");
        var fieldName = columnHeaders[columnIndex].selectAllCheckbox;

        if (rowComponents) {
            rowComponents.forEach(function(rowComponent) {
                if (rowComponent) {
                    var rowIndex = rowComponent.get("v." + indexVar);
                    mapRowComponentsByRowIndex.set(rowIndex, rowComponent);
                }
            });
        }
        var inlineEditComponent = component.find("inline-edit-component");

        //select by filtered <<
        var mapFilterRowsByIndex = component.get("v.mapFilterRowsByIndex");
        //select by filtered >>
        for (var i = 0; i < items.length; i++) {
            var visible = true;
            if (mapFilterRowsByIndex != null && mapFilterRowsByIndex.has(i)) {
                visible = mapFilterRowsByIndex.get(i).visible;
            }

            if (visible == true) {
                items[i][fieldName] = checked;
                /*
                if (mapRowComponentsByRowIndex.has(i)) {
                    var rowComponent = mapRowComponentsByRowIndex.get(i);
                    rowComponent.set("v." + varName, items[i]);
                    //var checkbox = rowComponent.find(fieldName); //field name = aura:id
                }

                if (inlineEditComponent) {
                    if (Array.isArray(inlineEditComponent)) {
                        inlineEditComponent = inlineEditComponent[0];
                    }
                    var rowIndex = inlineEditComponent.get("v." + indexVar);
                    if (rowIndex == i) {
                        inlineEditComponent.set("v." + varName, items[i]);
                    }
                }*/
            }
        }
        //component.set("v.items", items);

        helper.buildTable(component, event);
        component.set("v.columnHeaders[" + columnIndex + "].checked", checked);

        var onSelectAll = component.getEvent("onSelectAll");
        onSelectAll.setParams({ "name": fieldName, "checked": checked });
        onSelectAll.fire();
    },
    isInlineEditMode : function(component, event, helper) {
        return (component.get("v.inlineEditRowIndex") != null);
    },
    openInlineEdit : function(component, event, helper) {
        var rowIndex = event.getParams().arguments.rowIndex;
        var inlineEditRowIndex = component.get("v.inlineEditRowIndex");
        if (inlineEditRowIndex >= 0) {
            helper.closeInlineEdit(component);
        }
        helper.openInlineEdit(component, rowIndex);
    },
    closeInlineEdit : function(component, event, helper) {
        var callback = null;
        if (event.getParams().arguments) {
            callback = event.getParams().arguments.callback;
        }
        return helper.closeInlineEdit(component, callback);
    },
    scrollToBottom : function(component, event, helper) {
        var container = document.getElementById("scrollable-container");
        container.scrollTop = container.scrollHeight;
    },
    filter : function(component, event, helper) {
        helper.closeInlineEdit(component);

        var columnIndex = event.getParam("columnIndex");
        var value = event.getParam("value");
        var action = event.getParam("action");

        var columnHeaders = component.get("v.columnHeaders");
        columnHeaders[columnIndex].filterValue = value;
        columnHeaders[columnIndex].action = action;
        component.set("v.columnHeaders[" + columnIndex + "].filterValue", value);
        helper.filter(component);

        //ticket 20318 <<
        helper.setRowsVisibility(component);
        //ticket 20318 >>

        //component.set("v.columnHeaders[" + columnIndex + "].checked", false); //clear the header checkbox as the filter changed

        //clear header checkboxes as filter has changed
        var cmps = [];
        var checkboxes = component.find("header-checkbox");
        if (Array.isArray(checkboxes)) {
            cmps = checkboxes;
        }
        else {
            cmps.push(checkboxes);
        }
        for (var i = 0; i < cmps.length; i++) {
            cmps[i].set("v.checked", false);
        }
    },
    clearAllFilters : function(component, event, helper) {
        helper.clearAllFilters(component);
    },
    refreshTable : function(component, event, helper) {
        helper.refreshTable(component);
    },
    collapse : function(component, event, helper) {
        event.stopPropagation();
        var rowIndex = event.getSource().get("v.value");
        helper.toggleChildRowsVisibility(component, rowIndex, false);
    },
    expand : function(component, event, helper) {
        event.stopPropagation();
        var rowIndex = event.getSource().get("v.value");
        helper.toggleChildRowsVisibility(component, rowIndex, true);
    }
});