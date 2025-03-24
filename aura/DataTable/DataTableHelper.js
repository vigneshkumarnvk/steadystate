({
    initTemplate : function(component, event, rowIndex) {
        var columnHeaders = [];
        var columns = [];
        var varName = component.get("v.var");
        var indexVar = component.get("v.indexVar");
        var template = component.get("v.template");
        var showRowNumbers = component.get("v.showRowNumbers");
        var dataRowAttributes = {};
        var rootAuraIfComponentDef;

        if (template) {
            if (showRowNumbers == true) {
                columnHeaders.push({ label: "Row", headerStyle: "width:25px; text-align:center;" });
                columns.push(this.createRowNumberComponentDef(component));
            }
            var templateComponents;
            if (template[0].componentDef.descriptor == "markup://aura:if") {
                rootAuraIfComponentDef = template[0];
                templateComponents = template[0].attributes.values.body.value;
            }
            else {
                templateComponents = template;
            }

            if (templateComponents && templateComponents.length > 0) {
                for (var i = 0; i < templateComponents.length; i++) {
                    var templateComponent = templateComponents[i];
                    if (templateComponent.componentDef) {
                        if (templateComponent.componentDef.descriptor == "markup://c:DataRow") {
                            dataRowAttributes = templateComponent.attributes.values;
                            //component.set("v.dataRowAttributes", dataRowAttributes);
                        } else if (templateComponent.componentDef.descriptor == "markup://c:DataColumn") {
                            var columnHeader = {};
                            if (templateComponent.attributes.values.id) {
                                columnHeader.id = templateComponent.attributes.values.id.value;
                            }
                            if (templateComponent.attributes.values.label) {
                                columnHeader.label = templateComponent.attributes.values.label.value;
                            }
                            if (templateComponent.attributes.values.headerStyle) {
                                columnHeader.headerStyle = templateComponent.attributes.values.headerStyle.value;
                            }
                            if (templateComponent.attributes.values.headerClass) {
                                columnHeader.headerClass = templateComponent.attributes.values.headerClass.value;
                            }
                            if (templateComponent.attributes.values.cellStyle) {
                                columnHeader.cellStyle = templateComponent.attributes.values.cellStyle.value;
                            }
                            if (templateComponent.attributes.values.cellClass) {
                                columnHeader.cellClass = templateComponent.attributes.values.cellClass.value;
                            }
                            if (templateComponent.attributes.values.selectAllCheckbox) {
                                columnHeader.selectAllCheckbox = templateComponent.attributes.values.selectAllCheckbox.value;
                            }
                            if (templateComponent.attributes.values.filterField) {
                                columnHeader.filterField = templateComponent.attributes.values.filterField.value;
                            }
                            if (templateComponent.attributes.values.filterFieldType) {
                                columnHeader.filterFieldType = templateComponent.attributes.values.filterFieldType.value;
                            }

                            //ticket 20808 <<
                            if (templateComponent.attributes.values.sortable) {
                                columnHeader.sortable = templateComponent.attributes.values.sortable.value;
                                columnHeader.ascending = true;
                            }
                            //ticket 20808 >>
                            columnHeaders.push(columnHeader);

                            if (templateComponent.attributes.values.body && templateComponent.attributes.values.body.value) {
                                var containedComponents = templateComponent.attributes.values.body.value;

                                var tdComponentDef = {
                                    "componentDef": {
                                        "descriptor": "markup://aura:html"
                                    },
                                    "attributes": {
                                        "values": {
                                            "HTMLAttributes": {
                                                "descriptor": "HTMLAttributes",
                                                "value": {
                                                    "class": (templateComponent.attributes.values.cellClass ? templateComponent.attributes.values.cellClass.value : ""),
                                                    "style": (templateComponent.attributes.values.cellStyle ? templateComponent.attributes.values.cellStyle.value : "")
                                                }
                                            },
                                            "tag": {
                                                "descriptor": "tag",
                                                "value": "td"
                                            },
                                            "body": {
                                                "descriptor": "body",
                                                "value": containedComponents
                                            }
                                        },
                                    }
                                };
                                columns.push(tdComponentDef);
                            }
                        }
                    }
                }
            }

            var prefilters = component.get("v.prefilters");
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
                                "class": (dataRowAttributes.class ? dataRowAttributes.class.value : ''),
                                "style": {
                                    "exprType": "FUNCTION",
                                    "code": "function(cmp, fn) {" +
                                        "var styles = [];" +
                                        "var items = cmp.get(\"v.items\");" +
                                        "var indexVar = cmp.get(\"v.indexVar\");" +
                                        "var rowIndex = cmp.get(indexVar);" +
                                        "var " + varName + " = items[rowIndex];" +
                                        "var mapFilterRowsByIndex = cmp.get(\"v.mapFilterRowsByIndex\");" +
                                        "if (mapFilterRowsByIndex) {" +
                                        "if (mapFilterRowsByIndex.has(rowIndex)) {" +
                                        "var visible = mapFilterRowsByIndex.get(rowIndex).visible;" +
                                        "if (visible != true) {" +
                                        "styles.push('display:none');" +
                                        "}" +
                                        "}" +
                                        "}" +
                                        "if (styles.length == 0 && " + prefilters + ") {" +
                                        "if (" + prefilters +") {" +
                                        "if (!styles.includes('display:none')) {"+
                                        "styles.push('display:none');" +
                                        "}" +
                                        "}" +
                                        "}" +
                                        "return styles.join(';');" +
                                        "}",
                                    "args": [
                                        {
                                            "exprType": "PROPERTY",
                                            "byValue": false,
                                            "path": "v.mapFilterRowsByIndex"
                                        },
                                        {
                                            "exprType": "PROPERTY",
                                            "byValue": false,
                                            "path": varName
                                        }
                                    ],
                                    "byValue": false
                                },

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
            trComponentDef.attributes.values.HTMLAttributes.value.onchange = {
                "exprType": "PROPERTY",
                "byValue": false,
                "path": "c.handleRowAction"
            };
            trComponentDef.attributes.values.HTMLAttributes.value.onclick = {
                "exprType": "PROPERTY",
                "byValue": false,
                "path": "c.handleRowAction"
            };
            trComponentDef.attributes.values.HTMLAttributes.value["data-row-index"] = {
                "exprType": "PROPERTY",
                "byValue": false,
                "path": indexVar
            };

            if (rootAuraIfComponentDef) {
                rootAuraIfComponentDef.attributes.values.body.value = [ trComponentDef ];
            }
            else {
                rootAuraIfComponentDef = trComponentDef;
            }

            component.set("v.columnHeaders", columnHeaders);
            component.set("v.template", rootAuraIfComponentDef);
        }
    },
    /*
    filter : function(component, index) {
        var items = component.get("v.items");
        var trs = this.findComponent(component, "tr");
        var columnHeaders = component.get("v.columnHeaders");

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
                    show = show && (columnValue != null && columnValue.toUpperCase().includes(columnHeader.filterValue.toUpperCase()));
                }
                return show;
            }, true);

            if (visible == true) {
                $A.util.removeClass(trs[i], 'slds-hide');
            }
            else {
                $A.util.addClass(trs[i], 'slds-hide');
            }
        }
    },*/
    filter : function(component, event) {
        var items = component.get("v.items");
        var trs = this.findComponent(component, "tr");
        var columnHeaders = component.get("v.columnHeaders");
        var mapFilterRowsByIndex = new Map();

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
                    else {
                        show = show && columnValue != null && columnValue.toUpperCase().includes(columnHeader.filterValue.toUpperCase());
                    }
                }
                return show;
            }, true);
            mapFilterRowsByIndex.set(i, { "visible": visible });
        }
        component.set("v.mapFilterRowsByIndex", mapFilterRowsByIndex);
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
    createRowNumberComponentDef : function(component) {
        var indexVar = component.get("v.indexVar");
        var rowNumberComponentDef = {
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
                        "descriptor": "body",
                        "value": {
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
                    }
                },
            }
        }
        return rowNumberComponentDef;
    },
    //ticket 20808 <<
    sort : function(objList, sorts) {
        function sort(a, b, sorts, sortIndex) {
            if (!sorts || !sorts[sortIndex]) return 0;

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
            return order;
        };

        objList.sort(function(a, b) {
            return sort(a, b, sorts, 0);
        });
    }
    //ticket 20808 >>
});