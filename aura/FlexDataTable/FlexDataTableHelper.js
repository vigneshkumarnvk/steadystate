({
    calculateRowOrders : function(component, initValueProvider) {
        var items = component.get("v.items");
        if (!items) {
            return;
        }

        var sorts = component.get("v.sorts");
        if (sorts != null && sorts.length > 0) {
            this.sort(items, sorts);
        } 

        //var rowOrders = new Map();
        var rowOrders = component.get("v.rowOrders");
        var collapsible = component.get("v.collapsible");
        var keyName = component.get("v.keyName");
        var linkedToKeyName = component.get("v.linkedToKeyName");
        //if (collapsible == true) {
        if (keyName && linkedToKeyName) {
            var collapsed = component.get("v.collapsed");
            var nested = component.get("v.nested");
            if (!nested) {
                nested = {};
            }

            for (var index in nested) {
                if (nested.hasOwnProperty(index)) {
                    nested[index].processed = false;
                    //console.log("set nested[" + index + "].processed=false")
                    if (nested[index].hasChildren) {
                        for (var i = 0; i < nested[index].children.length; i++) {
                            nested[index].children[i].processed = false;
                        }
                    }
                }
            }

            if (items) {
                //console.log('items length = ' + items.length);
                //calculate parent and child
                for (var i = 0; i < items.length; i++) {
                    var keyValue = this.getKeyValue(items[i], keyName);
                    var linkedToKeyValue = this.getKeyValue(items[i], linkedToKeyName);
                    if (!linkedToKeyValue) { //parent record
                        var rowInfo = null;
                        for (var index in nested) {
                            if (nested.hasOwnProperty(index)) {
                                if (nested[index][keyName] == keyValue) {
                                    rowInfo = JSON.parse(JSON.stringify(nested[index])); //copy nested[index] to avoid rowInfo referencing to nested[index]
                                    break;
                                }
                            }
                        }

                        if (rowInfo == null) { //not found
                            rowInfo = {};
                            rowInfo[keyName] = keyValue; //row.Line_No__c = line #
                            rowInfo.collapsed = collapsed;  //parent flag
                            rowInfo.show = true; //control show/hide of the record, = true for parent record
                        }

                        rowInfo.itemIndex = i;
                        rowInfo.processed = true;
                        rowInfo.hasChildren = false; //default to fault, turn on when children are found
                        rowInfo.children = []; //reset children
                        for (var j = 0; j < items.length; j++) {
                            //calculate related key value
                            linkedToKeyValue = this.getKeyValue(items[j], linkedToKeyName);

                            if (linkedToKeyValue != null && linkedToKeyValue == rowInfo[keyName]) {
                                //calculate child key value
                                var childKeyValue = this.getKeyValue(items[j], keyName);

                                var childRowInfo = {};
                                childRowInfo[keyName] = childKeyValue;
                                childRowInfo.itemIndex = j;
                                childRowInfo.show = !collapsed;
                                childRowInfo.collapsed = null; //don't apply to child rows
                                childRowInfo.processed = true;

                                rowInfo.hasChildren = true;
                                rowInfo.children.push(childRowInfo);
                            }
                        }
                        nested[i] = rowInfo;
                        //console.log("update nested[" + i + "].processed = true ");
                    }
                }
            }


            for (var index in nested) {
                if (nested.hasOwnProperty(index)) {
                    //console.log("nested[" + index + "].processed=" + nested[index].processed)
                    if (nested[index].processed != true) {
                        delete nested[index];
                        //console.log('delete nest ' + index);
                    }
                    else if (nested[index].hasChildren == true) {
                        for (var i = 0; i < nested[index].children.length; i++) {
                            if (nested[index].children[i].processed != true) {
                                delete nested[index].children[i];
                                //console.log('delete nest ' + index);
                            }
                        }
                    }
                }
            }
            component.set("v.nested", nested);

            for (var index in nested) {
                if (nested.hasOwnProperty(index)) {
                    //console.log("nested[" + index + "]")
                }
            }

            var orderIndex = 0;
            //var rows = {};
            var rows = component.get("v.rows");
            if (!rows) {
                rows = {};
            }

            for (var index in nested) {
                //console.log("nested " + index)
                if (nested.hasOwnProperty(index)) {
                    var row = nested[index];
                    rowOrders[orderIndex] = row.itemIndex;
                    //console.log("rowOrderIndex = " + orderIndex);
                    orderIndex++;
                    rows[row[keyName]] = { "show": true, "hasChildren": row.hasChildren, "collapsed": row.collapsed };
                    if (row.hasChildren) {
                        for (var i = 0; i < row.children.length; i++) {
                            row.children[i].show = !row.collapsed;
                            rowOrders[orderIndex] = row.children[i].itemIndex;
                            //console.log("rowOrderIndex* = " + orderIndex);
                            orderIndex++;
                            rows[row.children[i][keyName]] = { "show": row.children[i].show };
                        }
                    }
                }
            }

            //clean up rowOrders old elements
            var rowOrdersCount = 0;
            for (var index in rowOrders) {
                rowOrdersCount++;
            }
            for (var i = orderIndex; i < rowOrdersCount; i++) {
                delete rowOrders[i];
            }

            component.set("v.rows", rows);
            component.set("v.rowOrders", rowOrders);
            /*
            for (const [key, value] of Object.entries(rowOrders)) {
                console.log(key, value, items[value][keyName]);
            }*/
        }
        else {
            //var rowOrders = {};
            //ticket 19130 <<
            for (var key in rowOrders) {
                delete rowOrders[key];
            }
            //ticket 19130 >>
            var items = component.get("v.items");
            for (var i = 0; i < items.length; i++) {
                rowOrders[i] = i;
            }
            component.set("v.rowOrders", rowOrders);
        }


        //compare the copy of items with the items
        var xItems = component.get("v.xItems");
        //ticket 19130 <<
        //var fields = ['Selected'];
        var fields = [];
        //ticket 19130 >>
        var changed = false;
        if (xItems && xItems.length == items.length) {
            for (var i = 0; i < items.length; i++) {
                var item = items[i];
                var xItem = xItems[i];
                for (var key in item) {
                    if (item.hasOwnProperty(key)) {
                        if (JSON.stringify(item[key]) != JSON.stringify(xItem[key])) {
                            if (fields.includes(key)) {
                            } else {
                                changed = true;
                                break;
                            }
                        }
                    }
                }
            }
        }
        else {
            changed = true;
        }
        component.set("v.xItems", JSON.parse(JSON.stringify(items)));

        changed = true;
        if (initValueProvider == true && changed == true) {
            component.set("v.valueProviderAdded", false);
            component.addValueProvider(
                "flexDataTable",
                {
                    get: function (key) {
                        var items = component.get("v.items");
                        return Object.keys(rowOrders).map(key => items[rowOrders[key]]);
                    }
                }
            );

            /*
            //add the javascript provider to the window
            Object.defineProperty(window, "my", {
                writable: true,
                value: rowOrders
            });
            */

            var param1 = component.get("v.param1");
            if (param1) {
                component.addValueProvider("param1",
                    {
                        get: function (key) {
                            return param1;
                        }
                    }
                );
            }

            component.set("v.valueProviderAdded", true);
        }
    },
    updateHeaderCheckbox : function(component, event) {
        var items = component.get("v.items");
        if (items && items.length > 0) {
            var columnHeaders = component.get("v.columnHeaders");
            for (var i = 0; i < columnHeaders.length; i++) {
                if (columnHeaders[i].checkbox != null) {
                    var checkboxes = component.find("header-checkbox");
                    var checkbox;
                    if ($A.util.isArray(checkboxes)) {
                        for (var k = 0; k < checkboxes.length; k++) {
                            if (checkboxes[k].get("v.value") == columnHeaders[i].checkbox) {
                                checkbox = checkboxes[k];
                                break;
                            }
                        }
                    }
                    else {
                        checkbox = checkboxes;
                    }

                    var allChecked = true;
                    for (var j = 0; j < items.length; j++) {
                        if (items[j][columnHeaders[i].checkbox] != true) {
                            allChecked = false;
                            break;
                        }
                    }
                    checkbox.set("v.checked", allChecked);
                }
            }
        }
    },
    getKeyValue : function(obj, keyName) {
        var fieldNames = keyName.split(".");
        var keyValue = obj;
        for (var f = 0; f < fieldNames.length; f++) {
            keyValue = keyValue[fieldNames[f]];
            if (keyValue == null) {
                break;
            }
        }
        return keyValue;
    },
    initTemplate : function(component, event) {
        var columnHeaders = [];
        var columns = [];
        var auraIds = [];
        var path = component.get("v.var");
        var indexVar = component.get("v.indexVar");
        var template = component.get("v.template");
        var rowAttributes;
        var collapsible = component.get("v.collapsible");
        var collapseButtonPosition = component.get("v.collapseButtonPosition");

        if (template) {
            var collapsibleColumnHeader;
            var collapsibleColumn;
            if (collapsible) {
                collapsibleColumnHeader = { label: "", style: "width:15px;" };
                var buttons = {
                    "componentDef": {
                        "descriptor": "markup://aura:html"
                    },
                    "attributes": {
                        "values": {
                            "HTMLAttributes": {
                                "descriptor": "HTMLAttributes",
                                "value": {
                                }
                            },
                            "tag": {
                                "descriptor": "tag",
                                "value": "span"
                            },
                            "body": {
                                "descriptor": "body",
                                "value": [
                                    {
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
                                                            "var keyName = cmp.get(\"v.keyName\");" +
                                                            "var fieldNames = keyName.split('.');" +
                                                            "var itemName = cmp.get(\"v.var\");" +
                                                            "if (cmp.get(itemName) != null) {" +
                                                            "var keyValue = cmp.get(itemName);" +
                                                            "for (var i = 0; i < fieldNames.length; i++) {" +
                                                            "keyValue = keyValue[fieldNames[i]];" +
                                                            "if (keyValue == null) {" +
                                                            "break;" +
                                                            "}" +
                                                            "}" +
                                                            "var rows = cmp.get(\"v.rows\");" +
                                                            "if (rows) {" +
                                                            "var row = rows[keyValue];" +
                                                            "if (row) {" +
                                                            "return (row.hasChildren && !row.collapsed);" +
                                                            "}" +
                                                            "}" +
                                                            "}" +
                                                            "return false;" +
                                                            "}",
                                                        "args": [
                                                            {
                                                                "exprType": "PROPERTY",
                                                                "byValue": false,
                                                                "path": "item"
                                                            },
                                                            {
                                                                "exprType": "PROPERTY",
                                                                "byValue": false,
                                                                "path": "v.rows"
                                                            }
                                                        ],
                                                        "byValue": false
                                                    }
                                                },
                                                "body": {
                                                    "descriptor": "body",
                                                    "value": [
                                                        {
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
                                                                            "target": null,
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
                                                        }
                                                    ]
                                                }
                                            }
                                        }
                                    },
                                    {
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
                                                            "var keyName = cmp.get(\"v.keyName\");" +
                                                            "var fieldNames = keyName.split('.');" +
                                                            "var itemName = cmp.get(\"v.var\");" +
                                                            "if (cmp.get(itemName) != null) {" +
                                                            "var keyValue = cmp.get(itemName);" +
                                                            "for (var i = 0; i < fieldNames.length; i++) {" +
                                                            "keyValue = keyValue[fieldNames[i]];" +
                                                            "if (keyValue == null) {" +
                                                            "break;" +
                                                            "}" +
                                                            "}" +
                                                            "var rows = cmp.get(\"v.rows\");" +
                                                            "if (rows) {" +
                                                            "var row = rows[keyValue];" +
                                                            "if (row) {" +
                                                            "return (row.hasChildren && row.collapsed);" +
                                                            "}" +
                                                            "}" +
                                                            "}" +
                                                            "return false;" +
                                                            "}",
                                                        "args": [
                                                            {
                                                                "exprType": "PROPERTY",
                                                                "byValue": false,
                                                                "path": "item"
                                                            },
                                                            {
                                                                "exprType": "PROPERTY",
                                                                "byValue": false,
                                                                "path": "v.rows"
                                                            }
                                                        ],
                                                        "byValue": false
                                                    }
                                                },
                                                "body": {
                                                    "descriptor": "body",
                                                    "value": [
                                                        {

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
                                                                            "target": null,
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
                                                        }
                                                    ]
                                                }
                                            }
                                        }
                                    }
                                ]
                            }
                        }
                    }
                }

                var td = {
                    "componentDef": {
                        "descriptor": "markup://aura:html"
                    },
                    "attributes": {
                        "values": {
                            "HTMLAttributes": {
                                "descriptor": "HTMLAttributes",
                                "value": {
                                    "style": "text-align:center;width:15px;"
                                }
                            },
                            "tag": {
                                "descriptor": "tag",
                                "value": "td"
                            },
                            "body": {
                                "descriptor": "body",
                                "value": buttons
                            }
                        }
                    }
                }

                collapsibleColumn = td;

                if (collapseButtonPosition == 'left') {
                    columnHeaders.push(collapsibleColumnHeader);
                    columns.push(collapsibleColumn)
                }
            }

            //validate allowed elements in the template
            var childElementName;
            var flexDataTableRowCount = 0;
            for (var i = 0; i < template.length; i++) {
                var element = template[i];
                if (element.componentDef.descriptor == "markup://aura:if") {
                    if (template.length > 1) {
                        throw 'There should only be one ' + element.componentDef.descriptor + ' in the datatable template.';
                    }
                    childElementName = element.componentDef.descriptor;
                }
                else if (element.componentDef.descriptor == "markup://c:FlexDataTableRow") {
                    flexDataTableRowCount++;
                    childElementName = element.componentDef.descriptor;
                }
                else if (element.componentDef.descriptor == "markup://c:FlexDataTableColumn") {
                    childElementName = element.componentDef.descriptor;
                }
                else {
                    throw element.componentDef.descriptor + ' is not a valid child element of the flex data table.';
                }
            }

            if (flexDataTableRowCount > 1) {
                throw 'Only one ' + element.componentDef.descriptor + ' should be defined in the flex data table.';
            }

            var rootAuraIf;
            var dataTableColumns;
            if (childElementName == "markup://aura:if") {
                rootAuraIf = template[0].attributes.values.isTrue;
                dataTableColumns = template[0].attributes.values.body.value;
            }
            else if (childElementName == "markup://c:FlexDataTableColumn") {
                dataTableColumns = template;
            }

            if (dataTableColumns && dataTableColumns.length > 0) {
                for (var i = 0; i < dataTableColumns.length; i++) {
                    var dataTableColumn = dataTableColumns[i];
                    //console.log('**** ' + JSON.stringify(dataTableColumn));
                    if (dataTableColumn.componentDef) {
                        if (dataTableColumn.componentDef.descriptor == "markup://c:FlexDataTableRow") {
                            rowAttributes = dataTableColumn.attributes.values;
                        } else if (dataTableColumn.componentDef.descriptor == "markup://c:FlexDataTableColumn") {
                            //column headers
                            var columnHeader = {};
                            if (dataTableColumn.attributes.values.id) {
                                columnHeader.id = dataTableColumn.attributes.values.id.value;
                            }
                            if (dataTableColumn.attributes.values.label) {
                                columnHeader.label = dataTableColumn.attributes.values.label.value;
                            }
                            if (dataTableColumn.attributes.values.style) {
                                columnHeader.style = dataTableColumn.attributes.values.style.value;
                            }
                            if (dataTableColumn.attributes.values.class) {
                                columnHeader.class = dataTableColumn.attributes.values.class.value;
                            }
                            if (dataTableColumn.attributes.values.checkbox) {
                                columnHeader.checkbox = dataTableColumn.attributes.values.checkbox.value;
                            }
                            //ticket 20808 <<
                            if (dataTableColumn.attributes.values.sortable) {
                                columnHeader.sortable = dataTableColumn.attributes.values.sortable.value;
                                columnHeader.ascending = true;
                            }
                            //ticket 20808 >>
                            columnHeaders.push(columnHeader);

                            //column values
                            if (dataTableColumn.attributes.values.body && dataTableColumn.attributes.values.body.value) {
                                var containedComponents = dataTableColumn.attributes.values.body.value;
                                for (var j = 0; j < containedComponents.length; j++) {
                                    containedComponents[j] = this.addSpanTag(containedComponents[j]); //wrap up the child components with a span tag using the element name so the element name bubbles up to the tr element
                                }

                                //console.log('*** ' + JSON.stringify(dataTableColumn));
                                //this.calculateRequiredFields(dataTableColumn, auraIds);
                                //console.log('*** ' + JSON.stringify(auraIds));

                                //create td to hold the components
                                var td = {
                                    "componentDef": {
                                        "descriptor": "markup://aura:html"
                                    },
                                    "attributes": {
                                        "values": {
                                            "HTMLAttributes": {
                                                "descriptor": "HTMLAttributes",
                                                "value": {
                                                    "role": "gridcell",
                                                    "class": "slds-cell-wrap"
                                                }
                                            },
                                            "tag": {
                                                "descriptor": "tag",
                                                "value": "td"
                                            },
                                            "body": {
                                                "descriptor": "body",
                                                "value": containedComponents //containedComponents
                                            }
                                        },
                                    }
                                };

                                columns.push(td);
                            }
                        }
                    }
                }
            }

            //add expand/collapse button
            if (collapsible == true) {
                if (collapseButtonPosition == 'right') {
                    columnHeaders.push(collapsibleColumnHeader);
                    columns.push(collapsibleColumn);
                }
            }

            var rowClass;
            var rowStyle;
            if (rowAttributes) {
                if (rowAttributes.class) {
                    rowClass = rowAttributes.class;
                }
                if (rowAttributes.style) {
                    rowStyle = rowAttributes.style;
                }
            }

            var tr = {
                "componentDef": {
                    "descriptor": "markup://aura:html"
                },
                "attributes": {
                    "values": {
                        "HTMLAttributes": {
                            "descriptor": "HTMLAttributes",
                            "value": {
                                //"name": "TR" + indexVar,
                                "class": (rowClass ? rowClass.value : null),
                                "style": (rowStyle ? rowStyle.value : null)
                            }
                        },
                        "tag": {
                            "descriptor": "tag",
                            "value": "tr"
                        },
                        "body": {
                            "descriptor": "body",
                            "value": columns
                        }
                    }
                }
            };

            tr.attributes.values.HTMLAttributes.value.onchange = {
                "exprType": "PROPERTY",
                "byValue": false,
                "target": null,
                "path": "c.handleRowAction"
            };
            tr.attributes.values.HTMLAttributes.value.onclick = {
                "exprType": "PROPERTY",
                "byValue": false,
                "target": null,
                "path": "c.handleRowAction"
            };

            tr.attributes.values.HTMLAttributes.value.onfocusin = {
                "exprType": "PROPERTY",
                "byValue": false,
                "target": null,
                "path": "c.handleRowAction"
            };
            tr.attributes.values.HTMLAttributes.value.onfocusout = {
                "exprType": "PROPERTY",
                "byValue": false,
                "target": null,
                "path": "c.handleRowAction"
            };

            tr.attributes.values.HTMLAttributes.value["data-row-index"] = {
                "exprType": "PROPERTY",
                "byValue": false,
                "target": null,
                "path": indexVar
            };

            var auraIfHideRow;
            if (collapsible == true) {
                auraIfHideRow = {
                    "componentDef": {
                        "descriptor": "markup://aura:if"
                    },
                    "attributes": {
                        "values": {
                            "isTrue": {
                                "descriptor": "isTrue",
                                "value": {
                                    "exprType": "FUNCTION",
                                    "code": "function(cmp, fn){ " +
                                        "var keyName = cmp.get(\"v.keyName\");" +
                                        "var fieldNames = keyName.split('.');" +
                                        "var itemName = cmp.get(\"v.var\");" +
                                        "if (cmp.get(itemName) != null) {" +
                                        "var keyValue = cmp.get(itemName);" +
                                        "for (var i = 0; i < fieldNames.length; i++) {" +
                                        "keyValue = keyValue[fieldNames[i]];" +
                                        "if (keyValue == null) {" +
                                        "break;" +
                                        "}" +
                                        "}" +
                                        "var rows = cmp.get(\"v.rows\");" +
                                        "if (rows) {" +
                                        "var row = rows[keyValue];" +
                                        "if (row) {" +
                                        "return (row.show);" +
                                        "}" +
                                        "}" +
                                        "}" +
                                        "return true;}",
                                    "args": [
                                        {
                                            "exprType": "PROPERTY",
                                            "byValue": false,
                                            "path": "item"
                                        },
                                        {
                                            "exprType": "PROPERTY",
                                            "byValue": false,
                                            "path": "v.rows" //include v.rows so changes are fired
                                        },
                                    ],
                                    "byValue": false
                                }
                            },
                            "body": {
                                "descriptor": "body",
                                "value": tr
                            }
                        }
                    }
                }
            }
            else {
                auraIfHideRow = tr; //replace with tr
            }

            var componentDef;
            if (rootAuraIf != null) {
                componentDef = {
                    "componentDef": {
                        "descriptor": "markup://aura:if"
                    },
                    "attributes": {
                        "values": {
                            "isTrue": rootAuraIf,
                            "body": {
                                "descriptor": "body",
                                "value": auraIfHideRow
                            }
                        }
                    },
                }
            }
            else {
                componentDef = auraIfHideRow;
            }

            //console.log(JSON.stringify(componentDef));
            component.set("v.auraIds", auraIds);
            component.set("v.columnHeaders", columnHeaders);
            component.set("v.template", componentDef);
        }
    },
    addSpanTag : function(element) {
        var elementName;
        if (Array.isArray(element)) {
            for (var i = 0; i < element.length; i++) {
                element[i] = this.addSpanTag(element[i]);
                //console.log('** array 1');
            }
        }
        else {
            if (element.attributes && element.attributes.values) {
                if (element.attributes.values && element.attributes.values.body) {
                    var childElement = element.attributes.values.body.value;
                    if (Array.isArray(childElement)) {
                        childElement = this.addSpanTag(childElement);
                        //console.log('** array 2');
                    }
                }
                else if (element.attributes.values.name) {
                    //var JSONElement = JSON.stringify(element);
                    var span = {
                        "componentDef": {
                            "descriptor": "markup://aura:html"
                        },
                        "attributes": {
                            "values": {
                                "HTMLAttributes": {
                                    "descriptor": 'HTMLAttributes',
                                    "value": {
                                        "name": element.attributes.values.name.value
                                    }
                                },
                                "tag": {
                                    "descriptor": 'tag',
                                    "value": 'span'
                                },
                                "body": {
                                    "descriptor": 'body',
                                    "value": element//JSON.parse(JSONElement)
                                }
                            },
                        }
                    };
                    element = span;
                }
            }
        }
        return element;
    },
    collapse : function(component, event, collapse) {
        var rowIndex = event.getSource().get("v.value");
        var rowOrders = component.get("v.rowOrders");
        var itemIndex = rowOrders[rowIndex];

        var nested = component.get("v.nested");
        for (var index in nested) {
            if (nested.hasOwnProperty(index)) {
                if (nested[index].itemIndex == itemIndex) {
                    nested[index].collapsed = !nested[index].collapsed;
                    break;
                }
            }
        }

        component.set("v.nested", nested);
        this.calculateRowOrders(component, false); //no need to initiate the value provider again, as the rows orders don't change on collapsing
    },
    /*
    calculateRequiredFields : function(component, auraIds) {
        //console.log('*** component ' + component.componentDef.descriptor);
        //console.log('*** ' + JSON.stringify(component));
        if (component && component.attributes && component.attributes.values) {
            //console.log('-- ' + JSON.stringify(component.attributes.values.required.value == true));
            if (component && component.localId && component.attributes && component.attributes.values && component.attributes.values.required &&  component.attributes.values.required.value == true) {
                //console.log('** auraId = ' + component.localId);
                auraIds.push(component.localId); //localId = aura:id
            }

            //has child components
            if (component.attributes.values.body && component.attributes.values.body.value){
                var childComponents = component.attributes.values.body.value;
                if (Array.isArray(childComponents)) {
                    for (var i = 0; i < childComponents.length; i++) {
                        //console.log('***  child component ' + childComponents[i].componentDef.descriptor);
                        this.calculateRequiredFields(childComponents[i], auraIds);
                    }
                }
                else {
                    this.calculateRequiredFields(childComponents, auraIds);
                }
            }
        }

        return auraIds;
    },*/
    sort : function(objList, sorts) {
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
            //ticket 20808 <<
            /*
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
            */

            if (val1 === val2) {
                if (sortIndex < sorts.length - 1) {
                    sortIndex++;
                    order = sort(a, b, sorts, sortIndex);
                }
            }
            else if (val1 === null) {
                order = 1;
            }
            else if (val2 == null) {
                order = -1;
            }
            else if (ascending == true) {
                order = (val1 < val2 ? -1 : 1);
            }
            else {
                order = (val1 < val2 ? 1 : -1);
            }
            //ticket 20808 >>

            return order;
        };

        objList.sort(function(a, b) {
            return sort(a, b, sorts, 0);
        });
    }
});