({
    initIterationTemplate : function(component, event) {
        var template = component.get("v.template");
        var indexVar = component.get("v.indexVar");
        var showRowNumbers = component.get("v.showRowNumbers");
        var parentLinkField = component.get("v.parentLinkField");
        var childLinkField = component.get("v.childLinkField");
        var collapsible = (parentLinkField && childLinkField);

        var columnHeaders = [];
        columnHeaders.push({label: "", headerStyle: "min-width:35px;max-width:35px;text-align:center;"});

        if (showRowNumbers) {
            columnHeaders.push({label: "Row", headerStyle: "min-width:60px;max-width:60px;text-align:center;"});
        }

        var template = component.get("v.template");
        if (template) {
            for (var i = 0; i < template.length; i++) {
                var columnElement = template[i];
                if (columnElement && columnElement.componentDef && columnElement.componentDef.descriptor == "markup://c:InlineEditColumnHeader") {
                    var columnHeader = {};
                    if (columnElement.attributes.values.id) {
                        columnHeader.id = columnElement.attributes.values.id.value;
                    }
                    if (columnElement.attributes.values.label) {
                        columnHeader.label = columnElement.attributes.values.label.value;
                    }
                    if (columnElement.attributes.values.headerStyle) {
                        columnHeader.headerStyle = columnElement.attributes.values.headerStyle.value;
                    }
                    if (columnElement.attributes.values.headerClass) {
                        columnHeader.headerClass = columnElement.attributes.values.headerClass.value;
                    }
                    if (columnElement.attributes.values.cellStyle) {
                        columnHeader.cellStyle = columnElement.attributes.values.cellStyle.value;
                    }
                    if (columnElement.attributes.values.cellClass) {
                        columnHeader.cellClass = columnElement.attributes.values.cellClass.value;
                    }
                    if (columnElement.attributes.values.selectAllCheckbox) {
                        columnHeader.selectAllCheckbox = columnElement.attributes.values.selectAllCheckbox.value;
                    }
                    if (columnElement.attributes.values.filterField) {
                        columnHeader.filterField = columnElement.attributes.values.filterField.value;
                    }
                    if (columnElement.attributes.values.filterFieldType) {
                        columnHeader.filterFieldType = columnElement.attributes.values.filterFieldType.value;
                    }
                    if (columnElement.attributes.values.filterFieldOptions) {
                        columnHeader.filterFieldOptions = columnElement.attributes.values.filterFieldOptions.value;
                    }
                    columnHeaders.push(columnHeader);
                }
            }
        }
        component.set("v.columnHeaders", columnHeaders);

        var tds = [];
        var inlineTds = [];

        tds.push(this.createCollapsibleComponentDef(component));
        inlineTds.push(this.createCloseButtonComponentDef(component));

        if (showRowNumbers) {
            tds.push(this.createRowNumberComponentDef(component));
            inlineTds.push(this.createRowNumberComponentDef(component));
        }

        tds.push(this.createRowComponentDef(component));
        inlineTds.push(this.createInlineEditComponentDef(component));

        var trComponentDef = this.createTrComponentDef(component, tds);
        var inlineTrComponentDef = this.createInlineTrComponent(component, inlineTds);

        var auraIfComponentDef = {
            "componentDef": {
                "descriptor": "markup://aura:if"
            },
            "attributes": {
                "values": {
                    "isTrue": {
                        "descriptor": "isTrue",
                        "value": {
                            "exprType": "FUNCTION",
                            "code": "function(cmp,fn) { "
                                + "var indexVar = cmp.get(\"v.indexVar\");"
                                + "var isInlineEditRow = fn.eq(parseInt(cmp.get(\"v.inlineEditRowIndex\")), parseInt(cmp.get(indexVar))); "
                                + "return isInlineEditRow; "
                                + "}",
                            "args": [
                                /*
                                {
                                    "exprType": "PROPERTY",
                                    "byValue": false,
                                    "path": indexVar
                                },*/
                                {
                                    "exprType": "PROPERTY",
                                    "byValue": false,
                                    "path": "v.inlineEditRowIndex"
                                }
                            ],
                            "byValue": false
                        }
                    },
                    "else": {
                        "descriptor": "else",
                        "value": [
                            trComponentDef
                        ]
                    },
                    "body": {
                        "descriptor": "body",
                        "value": [
                            inlineTrComponentDef
                        ]
                    }
                }
            }
        }
        //console.log(JSON.stringify(auraIfComponentDef));
        component.set("v.template", null);
        component.set("v.iterationTemplate", auraIfComponentDef);
    },
    buildParentChildRelationshipMap : function(component) {
        //console.log('--------------building parent-child relationship map----------------')
        var items = component.get("v.items");
        var xMapParentRowsByIndex = component.get("v.mapParentRowsByIndex");

        var mapCollapseStatesByKey = new Map();
        if (xMapParentRowsByIndex) {
            xMapParentRowsByIndex.forEach(function(parent, index) {
                mapCollapseStatesByKey.set(parent.rowKey, parent.collapsed);
                //console.log("parent line # " + parent.rowKey + ": collapsed = " + parent.collapsed);
            })
        }

        var mapParentRowsByIndex = new Map();
        var parentLinkField = component.get("v.parentLinkField");
        var childLinkField = component.get("v.childLinkField");
        if (items && parentLinkField && childLinkField) {
            var childFieldNames = childLinkField.split('.');

            var mapRowIndexesByKey = new Map();
            for (var i = 0; i < items.length; i++) {
                mapRowIndexesByKey.set(items[i][parentLinkField], i);
            }

            for (var i = 0; i < items.length; i++) {
                var item = items[i];

                var childLinkFieldValue = item[childFieldNames[0]];
                var j = 1;

                while (childLinkFieldValue && j < childFieldNames.length) {
                    childLinkFieldValue = childLinkFieldValue[childFieldNames[j]];
                    j++;
                }
                if (childLinkFieldValue) {
                    var parentRowIndex = mapRowIndexesByKey.get(childLinkFieldValue);
                    var children;
                    if (mapParentRowsByIndex.has(parentRowIndex)) {
                        var parent = mapParentRowsByIndex.get(parentRowIndex);
                        parent.old = false;
                        children = parent.children;
                    } else {
                        children = new Map();
                        //var parent = { "collapsed": false, "children": children, "old": false, "key": parentLinkFieldValue };
                        var parent = { "collapsed": true, "children": children, "rowKey": childLinkFieldValue }; //childLinkFieldValue = parent key
                        mapParentRowsByIndex.set(parentRowIndex, parent);
                    }
                    //children.set(i, item);
                    children.set(i, {});
                }
            }

            /*
            mapParentRowsByIndex.forEach(function(parent, key) {
                if (parent.old == true) {
                    mapParentRowsByIndex.delete(key);
                }
            });*/

            //copy collapsed state from previous screen
            if (mapCollapseStatesByKey) {
                mapParentRowsByIndex.forEach(function(parent, index) {
                    if (mapCollapseStatesByKey.has(parent.rowKey)) {
                        var collapsed = mapCollapseStatesByKey.get(parent.rowKey);
                        mapParentRowsByIndex.get(index).collapsed = collapsed;
                    }
                });
            }
        }

        component.set("v.mapParentRowsByIndex", mapParentRowsByIndex);
        //console.log("from builder parent-child relatioship");
        this.setRowsVisibility(component);
    },
    setRowsVisibility : function(component) {
        var items = component.get("v.items");
        var mapRowVisibleByIndex = new Map();

        if (items) {
            for (var i = 0; i < items.length; i++) {
                mapRowVisibleByIndex.set(i, true);
            }

            var mapParentRowsByIndex = component.get("v.mapParentRowsByIndex");
            if (mapParentRowsByIndex) {
                mapParentRowsByIndex.forEach(function (parent, parentRowIndex) {
                    parent.children.forEach(function (child, childRowIndex) {
                        var visible = mapRowVisibleByIndex.get(childRowIndex) && (!parent.collapsed);
                        mapRowVisibleByIndex.set(childRowIndex, visible);
                    });
                });
            }

            var mapFilterRowsByIndex = component.get("v.mapFilterRowsByIndex");
            if (mapFilterRowsByIndex) {
                mapFilterRowsByIndex.forEach(function (filterRow, rowIndex) {
                    var visible = mapRowVisibleByIndex.get(rowIndex) && (filterRow.visible);
                    mapRowVisibleByIndex.set(rowIndex, visible);
                });
            }
        }

        //console.log("mapRowVisibleByIndex");
        //mapRowVisibleByIndex.forEach(function(value, key) {
        //    console.log(key + " = " + mapRowVisibleByIndex.get(key));
        //})

        component.set("v.mapRowVisibleByIndex", mapRowVisibleByIndex);
    },
    toggleChildRowsVisibility : function(component, rowIndex, visible) {
        var mapParentRowsByIndex = component.get("v.mapParentRowsByIndex");
        if (mapParentRowsByIndex.has(rowIndex)) {
            var parent = mapParentRowsByIndex.get(rowIndex);
            parent.collapsed = visible;
        }
        component.set("v.mapParentRowsByIndex", mapParentRowsByIndex);
        this.setRowsVisibility(component);
    },
    openInlineEdit : function(component, rowIndex) {
        component.set("v.inlineEditRowIndex", rowIndex);

        var onInlineEditOpen = component.getEvent("onInlineEditOpen");
        var name = component.get("v.name");
        onInlineEditOpen.setParams({ "name": name, "rowIndex": rowIndex});
        onInlineEditOpen.fire();
    },
    closeInlineEdit : function(component, callback) {
        var closed = false;
        var inlineEditRowIndex = component.get("v.inlineEditRowIndex");
        if (inlineEditRowIndex >= 0) {
            var inlineEditValidationMethod = component.get("v.inlineEditValidationMethod");
            var inlineEditComponents = this.findComponent(component, "inline-edit-component");

            var valid = true;

            if (inlineEditComponents && inlineEditComponents[0]) {
                if (inlineEditValidationMethod) {
                    valid = inlineEditComponents[0][inlineEditValidationMethod]();
                }

                if (valid) {
                    component.set("v.inlineEditRowIndex", null);
                }
                closed = valid;

                if (closed == true) {
                    var varName = component.get("v.var");
                    var item = inlineEditComponents[0].get("v." + varName);

                    //update items
                    //var items = component.get("v.items");
                    //items[inlineEditRowIndex] = item;
                    //console.log('********** items[' + inlineEditRowIndex +']=' + items[inlineEditRowIndex].xLine_Amount__c);

                    var onInlineEditClose = component.getEvent("onInlineEditClose");
                    onInlineEditClose.setParams({"rowIndex": inlineEditRowIndex, "value": item, "callback": callback});
                    onInlineEditClose.fire();

                    if (callback) {
                        callback(inlineEditRowIndex, item);
                    }
                }
            }
            else {
                component.set("v.inlineEditRowIndex", null);
                closed = true;
            }
        }
        else {
            component.set("v.inlineEditRowIndex", null);
            closed = true;
        }
        return closed;
    },
    filter : function(component) {
        var items = component.get("v.items");
        var trs = this.findComponent(component, "tr");
        var columnHeaders = component.get("v.columnHeaders");
        var mapFilterRowsByIndex = new Map();
        var recordCount = 0;

        for (var i = 0; i < items.length; i++) {
            var visible = columnHeaders.reduce(function(show, columnHeader) {
                if (columnHeader.filterField && columnHeader.filterValue != null) {
                    var columnValue = items[i];
                    var fieldNames = columnHeader.filterField.split('.');
                    for (var j = 0; j < fieldNames.length; j++) {
                        if (columnValue != null) {
                            columnValue = columnValue[fieldNames[j]];
                        }
                        else {
                            break;
                        }
                    }
                    if (columnHeader.filterFieldType == 'date') {
                        show = show && columnValue != null && (Date.parse(columnValue) == Date.parse(columnHeader.filterValue));
                    }
                    else if (columnHeader.filterFieldType == 'option') {
                        var contains = false;
                        if (columnValue != null) {
                            var tokens = columnHeader.filterValue.split('|');
                            for (var k = 0; k < tokens.length; k++) {
                                contains = columnValue.toUpperCase().includes(tokens[k].toUpperCase());
                                if (contains == true) {
                                    break;
                                }
                            }
                        }
                        show = show && contains;
                    }
                    else {
                        show = show && columnValue != null && columnValue.toUpperCase().includes(columnHeader.filterValue.toUpperCase());
                    }
                }
                return show;
            }, true);
            mapFilterRowsByIndex.set(i, { "visible": visible });
        }
        component.set("v.mapFilterRowsByIndex", mapFilterRowsByIndex);
        this.setRowsVisibility(component);
    },
    clearAllFilters : function(component) {
        var columnHeaders = component.get("v.columnHeaders");
        for (var i = 0; i < columnHeaders.length; i++) {
            columnHeaders[i].filterValue = null;
        }
        component.set("v.columnHeaders", columnHeaders);

        var mapFilterRowsByIndex = component.get("v.mapFilterRowsByIndex");
        if (mapFilterRowsByIndex) {
            mapFilterRowsByIndex.forEach(function(filterRow, rowIndex) {
                filterRow.visible = true;
            });
        }
        component.set("v.mapFilterRowsByIndex", mapFilterRowsByIndex);
        this.setRowsVisibility(component);
    },
    refreshTable : function(component) {
        var items = component.get("v.items");
        var varName = component.get("v.var");
        var indexVar = component.get("v.indexVar");
        var mapRowComponentsByRowIndex = new Map();
        var rowComponents = this.findComponent(component, "row-component");
        var mapInlineComponentsByRowIndex = new Map();
        var inlineComponents = this.findComponent(component, "inline-edit-component");

        //row components
        if (rowComponents) {
            rowComponents.forEach(function(rowComponent) {
                if (rowComponent) {
                    var rowIndex = rowComponent.get("v." + indexVar);
                    mapRowComponentsByRowIndex.set(rowIndex, rowComponent);
                }
            });
        }

        for (var i = 0; i < items.length; i++) {
            if (mapRowComponentsByRowIndex.has(i)) {
                var rowComponent = mapRowComponentsByRowIndex.get(i);
                rowComponent.set("v." + varName, items[i]);
            }
        }

        //inline components
        if (inlineComponents) {
            inlineComponents.forEach(function(inlineComponent) {
                if (inlineComponent) {

                    var rowIndex = inlineComponent.get("v." + indexVar);
                    mapInlineComponentsByRowIndex.set(rowIndex, inlineComponent);
                }
            });
        }

        for (var i = 0; i < items.length; i++) {
            if (mapInlineComponentsByRowIndex.has(i)) {
                var inlineComponent = mapInlineComponentsByRowIndex.get(i);
                inlineComponent.set("v." + varName, items[i]);
            }
        }
    },
    findComponent : function(component, auraId) {
        var cmp = component.find(auraId);
        var cmps = [];
        if (Array.isArray(cmp)) {
            cmps = cmp;
        }
        else {
            cmps.push(cmp);
        }
        return cmps;
    },
    /*
    getTrsByRowIndex : function(component) {
        var mapTrsByRowIndex = new Map();
        var trs = this.findComponent(component, "tr");
        if (trs) {
            trs.forEach(function(tr) {
                var rowIndex = parseInt(tr.getElement().dataset.rowIndex);
                mapTrsByRowIndex.set(rowIndex, tr);
            });
        }
        return mapTrsByRowIndex;
    },*/
    createCollapsibleComponentDef : function(component) {
        var indexVar = component.get("v.indexVar");
        var varName = component.get("v.var");
        var collapseButtonComponentDef = {
            "componentDef": {
                "descriptor": "markup://lightning:buttonIcon"
            },
            "attributes": {
                "values": {
                    "value": {
                        "descriptor": "value",
                        "value": {
                            "exprType": "PROPERTY",
                            "byValue": false,
                            "path": indexVar
                        }
                    },
                    "variant": {
                        "descriptor": "variant",
                        "value": "bare"
                    },
                    "iconName": {
                        "descriptor": "iconName",
                        "value": "utility:add"
                    },
                    "class": {
                        "descriptor": "class",
                        "value": {
                            "exprType": "FUNCTION",
                            "code": "function(cmp, fn){" +
                                "var indexVar = cmp.get(\"v.indexVar\");" +
                                "var rowIndex = cmp.get(indexVar);" +
                                "var mapParentRowsByIndex = cmp.get(\"v.mapParentRowsByIndex\");" +
                                "if (mapParentRowsByIndex) {" +
                                "if (mapParentRowsByIndex.has(rowIndex)) {" +
                                "var parent = mapParentRowsByIndex.get(rowIndex);" +
                                "if (parent.collapsed == true) {" +
                                "return '';" +
                                "}" +
                                "else {" +
                                "return 'slds-hide';" +
                                "}" +
                                "}" +
                                "}" +
                                "}",
                            "args": [
                                {
                                    "exprType": "PROPERTY",
                                    "byValue": false,
                                    "path": "v.mapParentRowsByIndex"
                                }
                            ],
                            "byValue": false
                        }
                    },
                    "onclick": {
                        "descriptor": "onclick",
                        "value": {
                            "exprType": "PROPERTY",
                            "byValue": false,
                            "path": "c.collapse"
                        }
                    }
                }
            }
        };
        var expandButtonComponentDef = {
            "componentDef": {
                "descriptor": "markup://lightning:buttonIcon"
            },
            "attributes": {
                "values": {
                    "value": {
                        "descriptor": "value",
                        "value": {
                            "exprType": "PROPERTY",
                            "byValue": false,
                            "path": indexVar
                        }
                    },
                    "variant": {
                        "descriptor": "variant",
                        "value": "bare"
                    },
                    "iconName": {
                        "descriptor": "iconName",
                        "value": "utility:dash"
                    },
                    "class": {
                        "descriptor": "class",
                        "value": {
                            "exprType": "FUNCTION",
                            "code": "function(cmp, fn){" +
                                "var indexVar = cmp.get(\"v.indexVar\");" +
                                "var rowIndex = cmp.get(indexVar);" +
                                "var mapParentRowsByIndex = cmp.get(\"v.mapParentRowsByIndex\");" +
                                "if (mapParentRowsByIndex) {" +
                                "if (mapParentRowsByIndex.has(rowIndex)) {" +
                                "var parent = mapParentRowsByIndex.get(rowIndex);" +
                                "if (parent.collapsed == true) {" +
                                "return 'slds-hide';" +
                                "}" +
                                "else {" +
                                "return '';" +
                                "}" +
                                "}" +
                                "}" +
                                "}",
                            "args": [
                                {
                                    "exprType": "PROPERTY",
                                    "byValue": false,
                                    "path": "v.mapParentRowsByIndex"
                                }
                            ],
                            "byValue": false
                        }
                    },
                    "onclick": {
                        "descriptor": "onclick",
                        "value": {
                            "exprType": "PROPERTY",
                            "byValue": false,
                            "path": "c.expand"
                        }
                    }
                }
            }
        };

        var auraIfComponentDef = {
            "componentDef": {
                "descriptor": "markup://aura:if"
            },
            "attributes": {
                "values": {
                    "isTrue": {
                        "descriptor": "isTrue",
                        "value": {
                            "exprType": "FUNCTION",
                            "code": "function(cmp, fn){" +
                                "var indexVar = cmp.get(\"v.indexVar\");" +
                                "var rowIndex = cmp.get(indexVar);" +
                                "var mapParentRowsByIndex = cmp.get(\"v.mapParentRowsByIndex\");" +
                                "if (mapParentRowsByIndex) {" +
                                "if (mapParentRowsByIndex.has(rowIndex)) {" +
                                "return true;" +
                                "}" +
                                "}" +
                                "return false;" +
                                "}",
                            "args": [
                                {
                                    "exprType": "PROPERTY",
                                    "byValue": false,
                                    "path": "v.mapParentRowsByIndex"
                                }
                            ],
                            "byValue": false
                        }
                    },
                    "body": {
                        "descriptor": "body",
                        "value": [
                            collapseButtonComponentDef,
                            expandButtonComponentDef
                        ]
                    }
                }
            }
        };

        var collapsibleComponentDef = {
            "componentDef": {
                "descriptor": "markup://aura:html"
            },
            "attributes": {
                "values": {
                    "HTMLAttributes": {
                        "descriptor": "HTMLAttributes",
                        "value": {
                            "name": "collapsibleButton",
                            "style": "text-align:center;"
                        }
                    },
                    "tag": {
                        "descriptor": "tag",
                        "value": "td"
                    },
                    "body": {
                        "descriptor": "body",
                        "value": auraIfComponentDef
                    }
                }
            }
        }

        var fixedColumns = component.get("v.fixedColumns");
        if (fixedColumns > 0) {
            collapsibleComponentDef.attributes.values.HTMLAttributes.value.class = "fixed-column-0";
        }

        return collapsibleComponentDef;
    },
    createRowComponentDef : function(component) {
        var rowComponentName = component.get("v.rowComponentName");
        var varName = component.get("v.var");
        var indexVar = component.get("v.indexVar");
        var rowComponentMarkup = "markup://" + rowComponentName; //the component must be included in the parent page using <aura:dependency>

        var rowComponentDef = {
            "componentDef": {
                "descriptor": rowComponentMarkup
            },
            "localId": "row-component",
            "attributes": {
                "values": {
                }
            }
        };
        rowComponentDef.attributes.values[varName] = {
            "descriptor": varName,
            "value": {
                "exprType": "PROPERTY",
                "byValue": true,
                "path": varName
            }
        };
        rowComponentDef.attributes.values[indexVar] = {
            "descriptor": indexVar,
            "value": {
                "exprType": "PROPERTY",
                "byValue": false,
                "path": indexVar
            }
        };

        var rowComponentParams = component.get("v.rowComponentParams");
        if (rowComponentParams) {
            for (var name in rowComponentParams) {
                rowComponentDef.attributes.values[name] = {
                    "descriptor": "params",
                    "value": {
                        "exprType": "PROPERTY",
                        "byValue": false,
                        "path": "v.rowComponentParams." + name
                    }
                }
            };
        }
        return rowComponentDef;
    },
    createInlineEditComponentDef : function(component) {
        var varName = component.get("v.var");
        var indexVar = component.get("v.indexVar");
        var inlineEditComponentName = component.get("v.inlineEditComponentName");
        var inlineEditComponentMarkup = "markup://" + inlineEditComponentName;

        var inlineEditComponentDef  = {
            "componentDef": {
                "descriptor": inlineEditComponentMarkup
            },
            "localId": "inline-edit-component",
            "attributes": {
                "values": {
                }
            }
        };
        inlineEditComponentDef.attributes.values[varName] = {
            "descriptor": varName,
            "value": {
                "exprType": "PROPERTY",
                "byValue": true,
                "path": varName
            }
        };
        inlineEditComponentDef.attributes.values[indexVar] = {
            "descriptor": indexVar,
            "value": {
                "exprType": "PROPERTY",
                "byValue": false,
                "path": indexVar
            }
        };

        var inlineEditComponentParams = component.get("v.inlineEditComponentParams");
        if (inlineEditComponentParams) {
            for (var name in inlineEditComponentParams) {
                inlineEditComponentDef.attributes.values[name] = {
                    "descriptor": "params",
                    "value": {
                        "exprType": "PROPERTY",
                        "byValue": false,
                        "path": "v.inlineEditComponentParams." + name
                    }
                }
            }
        }

        return inlineEditComponentDef;
    },
    createRowNumberComponentDef : function(component) {
        var indexVar = component.get("v.indexVar");
        var showRowNumbers = component.get("v.showRowNumbers");

        var rowNumberComponentDef = {
            "componentDef": {
                "descriptor": "markup://aura:html"
            },
            "attributes": {
                "values": {
                    "HTMLAttributes": {
                        "descriptor": "HTMLAttributes",
                        "value": {
                            "name": "rowNumber",
                            "class": "slds-cell-wrap",
                            "style": "text-align: center;"
                        }
                    },
                    "tag": {
                        "descriptor": "tag",
                        "value": "td"
                    },
                    "body": {
                        "descriptor": "body",
                    }
                }
            }
        };
        var fixedColumns = component.get("v.fixedColumns");
        if (fixedColumns > 0) {
            rowNumberComponentDef.attributes.values.HTMLAttributes.value.class = "fixed-column-1";
        }

        rowNumberComponentDef.attributes.values.body.value = {
            "componentDef": {
                "descriptor": "markup://aura:expression"
            },
            "attributes": {
                "values": {
                    "value": {
                        "descriptor": "value",
                        "value": {
                            "exprType": "FUNCTION",
                            "code": "function(cmp,fn) { return fn.add(cmp.get(\"" + indexVar + "\"), 1);}",
                            "args": [
                                {
                                    "exprType": "PROPERTY",
                                    "byValue": false,
                                    "path": indexVar
                                }
                            ],
                            "byValue": false
                        }
                    }
                }
            }
        }
        return rowNumberComponentDef;
    },
    createCloseButtonComponentDef : function(component) {
        var indexVar = component.get("v.indexVar");

        var closeButtonComponentDef = {
            "componentDef": {
                "descriptor": "markup://aura:html"
            },
            "attributes": {
                "values": {
                    "HTMLAttributes": {
                        "descriptor": "HTMLAttributes",
                        "value": {
                            "class": "slds-cell-wrap",
                            "style": "text-align: center;"
                        }
                    },
                    "tag": {
                        "descriptor": "tag",
                        "value": "td"
                    },
                    "body": {
                        "descriptor": "body"
                    }
                }
            }
        };
        var fixedColumns = component.get("v.fixedColumns");
        if (fixedColumns > 0) {
            closeButtonComponentDef.attributes.values.HTMLAttributes.value.class += " fixed-column-0";
        }

        closeButtonComponentDef.attributes.values.body.value = {
            "componentDef": {
                "descriptor": "markup://lightning:buttonIcon"
            },
            "attributes": {
                "values": {
                    "value": {
                        "descriptor": "value",
                        "value": {
                            "exprType": "PROPERTY",
                            "byValue": false,
                            "path": indexVar
                        }
                    },
                    "variant": {
                        "descriptor": "variant",
                        "value": "bare"
                    },
                    "iconName": {
                        "descriptor": "iconName",
                        "value": "utility:close"
                    },
                    "alternativeText": {
                        "descriptor": "alternativeText",
                        "value": "Close inline edit"
                    },
                    "onclick": {
                        "descriptor": "onclick",
                        "value": {
                            "exprType": "PROPERTY",
                            "byValue": false,
                            "path": "c.closeInlineEdit"
                        }
                    }
                }
            }
        };
        return closeButtonComponentDef;
    },
    createTrComponentDef : function(component, tds) {
        var indexVar = component.get("v.indexVar");
        var trComponentDef = {
            "componentDef": {
                "descriptor": "markup://aura:html"
            },
            "localId": "tr",
            "attributes": {
                "values": {
                    "HTMLAttributes": {
                        "descriptor": "HTMLAttributes",
                        "value": {

                        }
                    },
                    "tag": {
                        "descriptor": "tag",
                        "value": "tr"
                    },
                    "body": {
                        "descriptor": "body",
                        "value": tds
                    }
                }
            }
        };

        trComponentDef.attributes.values.HTMLAttributes.value = {
            "class": {
                "exprType": "FUNCTION",
                "code": "function(cmp, fn) {" +
                    "var indexVar = cmp.get(\"v.indexVar\");" +
                    "var rowIndex = cmp.get(indexVar);" +
                    "var mapRowVisibleByIndex = cmp.get(\"v.mapRowVisibleByIndex\");" +
                    "if (mapRowVisibleByIndex) {" +
                    "if (mapRowVisibleByIndex.has(rowIndex)) {" +
                    "var visible = mapRowVisibleByIndex.get(rowIndex);" +
                    "if (visible != true) {" +
                    "return 'slds-hide';" +
                    "}" +
                    "else {" +
                    "return '';" +
                    "}" +
                    "}" +
                    "}" +
                    "}",
                "args": [
                    {
                        "exprType": "PROPERTY",
                        "byValue": false,
                        "path": "v.mapRowVisibleByIndex"
                    }
                ],
                "byValue": false
            },
            "onchange": {
                "exprType": "PROPERTY",
                "byValue": false,
                "path": "c.handleRowAction"
            },
            "onclick": {
                "exprType": "PROPERTY",
                "byValue": false,
                "path": "c.handleRowAction"
            }
        }
        trComponentDef.attributes.values.HTMLAttributes.value["data-row-index"] = {
            "exprType": "PROPERTY",
            "byValue": false,
            "path": indexVar
        };
        return trComponentDef;
    },
    createInlineTrComponent : function(component, tds) {
        var indexVar = component.get("v.indexVar");
        var trComponentDef = {
            "componentDef": {
                "descriptor": "markup://aura:html"
            },
            "localId": "tr",
            "attributes": {
                "values": {
                    "HTMLAttributes": {
                        "descriptor": "HTMLAttributes",
                        "value": {
                            "class": "inline-edit",
                        }
                    },
                    "tag": {
                        "descriptor": "tag",
                        "value": "tr"
                    },
                    "body": {
                        "descriptor": "body",
                        "value": tds
                    }
                }
            }
        };
        trComponentDef.attributes.values.HTMLAttributes.value["data-row-index"] = {
            "exprType": "PROPERTY",
            "byValue": false,
            "path": indexVar
        };
        return trComponentDef;
    },
    createTdComponentDef : function(component) {
        var td = {
            "componentDef": {
                "descriptor": "markup://aura:html"
            },
            "attributes": {
                "values": {
                    "tag": {
                        "descriptor": "tag",
                        "value": "td"
                    }
                }
            }
        };
        return td;
    },
    setFixedColumnHeaders : function(component, tr) {
        if (tr.getElement()) {
            var columnWidths = component.get("v.columnWidths");
            columnWidths
            if (columnWidths && columnWidths.length > 0) {
                var left = 0;
                for (var j = 0; j < tr.getElement().childNodes.length; j++) {
                    if (j < columnWidths.length) {
                        var td = tr.getElement().childNodes[j];
                        var style = tr.getElement().childNodes[j].style;
                        var width = columnWidths[j]
                        if (style) {
                            style.setProperty("top", "0px", "important");
                            style.setProperty("left", left + "px", "important");
                            style.setProperty("min-width", width + "px", "important");
                            style.setProperty("max-width", width + "px", "important");
                            style.setProperty("z-index", "1000", "important");
                            if (j == columnWidths.length - 1 || j == tr.getElement().childNodes.length - 1) {
                                //style.setProperty("border-right", "1px solid rgb(221, 219, 218)", "important");
                            }
                        } else {
                            style = "top:0px;left:" + left + "px;min-width:" + width + "px;max-width:" + width + "px;z-index:5;";
                            if (j == columnWidths.length - 1 || j == tr.getElement().childNodes.length - 1) {
                                style += 'border-right: 1px solid rgb(221, 219, 218);';
                            }
                            tr.getElement().childNodes[j].style = style;
                        }
                        left += width;
                        //console.log("left " + left);
                    } else {
                        break;
                    }
                }
            }
        }
    }
});