({
    clearErrors : function(component, event) {
        component.set('v.isVisible', false);
        component.set('v.isVisible', true);
    },
    //ticket 19130 <<
    //validateFields : function(component, event) {
    validateFields : function(component, event, choice) {
    //ticket 19130 >>

        //ticket 19130 <<
        var ok = true;
        var quantityField = component.find("quantity");
        if (quantityField) {
            quantityField.setCustomValidity("");
            quantityField.reportValidity();
            if (choice == 'Yes') {
                if (quantityField.get("v.value") <= 0) {
                    quantityField.setCustomValidity("Quantity must be greater than zero.");
                    quantityField.reportValidity();
                    ok = false;
                }
            }
            else {
                if (quantityField.get("v.value") < 0) {
                    quantityField.setCustomValidity("Quantity must be greater than or equal to zero.");
                    quantityField.reportValidity();
                    ok = false;
                }
            }
        }
        if (!ok) return;

        var uomQtyField = component.find("uom-qty");
        if (uomQtyField) {
            uomQtyField.setCustomValidity("");
            uomQtyField.reportValidity();
            if (choice == 'Yes') {
                if (uomQtyField.get("v.value") <= 0) {
                    uomQtyField.setCustomValidity("Quantity must be greater than zero.");
                    uomQtyField.reportValidity();
                    ok = false;
                }
            }
            else {
                if (uomQtyField.get("v.value") < 0) {
                    uomQtyField.setCustomValidity("UOM Qty must be greater than or equal to zero.");
                    uomQtyField.reportValidity();
                    ok = false;
                }
            }
        }
        if (!ok) return;
        //ticket 19130 >>

        var fieldComponents = new Array();
        var fields = component.get("v.xFields");
        Object.keys(fields).forEach(function(key, index) {
            var field = fields[key];
            if (field["id"] != null && field["required"] == true) {
                fieldComponents.push(component.find(field["id"]));
            }
        });

        var allValid = fieldComponents.reduce(function(valid, element) {
            if (element) {
                if (Array.isArray(element)) {
                    for (var i = 0; i < element.length; i++) {
                        element[i].showHelpMessageIfInvalid();
                        if (element[i]) {
                            valid = valid && element[i].get("v.validity").valid;
                        }
                    }
                    return valid;
                } else {
                    element.showHelpMessageIfInvalid();
                    if (element) {
                        valid = valid && element.get("v.validity").valid;
                    }
                    return  valid;
                }
            }
            return valid;
        }, true);

        return allValid;
    },
    showFields : function(component) {
        var xFields = {};

        xFields.Category = { "id": 'category', "show": false, "required": false, "disabled": true };
        xFields.ResourceType = { "id": 'resource-type', "show": false, "required": false, "disabled": true };
        xFields.Resource = { "id": 'resource', "show": false, "required": false, "disabled": true };
        xFields.Description = { "id": 'description', "show": false, "required": false, "disabled": true };
        xFields.UnitOfMeasure = { "id": 'unit-of-measure', "show": false, "required": false, "disabled": true };
        xFields.Quantity = { "id": 'quantity', "show": false, "required": false, "disabled": true };
        //ticket 19130 <<
        xFields.UOMQty = { "id": 'uom-qty', "show": false, "required": false, "disabled": true };
        //ticket 19130 >>
        xFields.CostMethod = { "id": 'cost-method', "show": false, "required": false, "disabled": true };
        xFields.UnitWeightVolume = { "id": 'unit-weight-volume', "show": false, "required": false, "disabled": true };
        xFields.ContainerSize = { "id": 'container-size', "show": false, "required": false, "disabled": true };

        var templateLine = component.get("v.templateLine");
        switch (templateLine.Category__c) {
            case 'Labor':
                xFields.Category.show = true;
                xFields.Category.required = true;
                xFields.Category.disabled = false;
                xFields.ResourceType.show = true;
                xFields.ResourceType.required = true;
                xFields.ResourceType.disabled = false;
                xFields.Description.show = true;
                xFields.Description.disabled = false;
                xFields.UnitOfMeasure.show = true;
                xFields.UnitOfMeasure.required = true;
                xFields.UnitOfMeasure.disabled = false;
                xFields.Quantity.show = true;
                xFields.Quantity.required = true;
                xFields.Quantity.disabled = false;
                //ticket 19130 <<
                if (component.get("v.sourceObjectType") == 'SalesOrder') {
                    xFields.UOMQty.show = true;
                    xFields.UOMQty.required = true;
                    xFields.UOMQty.disabled = false;
                }
                //ticket 19130 <<
                break;
            case 'Equipment':
                xFields.Category.show = true;
                xFields.Category.required = true;
                xFields.Category.disabled = false;
                xFields.ResourceType.show = true;
                xFields.ResourceType.required = true;
                xFields.ResourceType.disabled = false;
                xFields.Description.show = true;
                xFields.Description.disabled = false;
                xFields.UnitOfMeasure.show = true;
                xFields.UnitOfMeasure.required = true;
                xFields.UnitOfMeasure.disabled = false;
                xFields.Quantity.show = true;
                xFields.Quantity.required = true;
                xFields.Quantity.disabled = false;
                //ticket 19130 <<
                if (component.get("v.sourceObjectType") == 'SalesOrder') {
                    xFields.UOMQty.show = true;
                    xFields.UOMQty.required = true;
                    xFields.UOMQty.disabled = false;
                }
                //ticket 19130 <<
                break;
            case 'Materials':
                xFields.Category.show = true;
                xFields.Category.required = true;
                xFields.Category.disabled = false;
                xFields.Resource.show = true;
                xFields.Resource.required = true;
                xFields.Resource.disabled = false;
                xFields.Description.show = true;
                xFields.Description.disabled = false;
                xFields.UnitOfMeasure.show = true;
                xFields.UnitOfMeasure.required = true;
                xFields.UnitOfMeasure.disabled = false;
                xFields.Quantity.show = true;
                xFields.Quantity.required = true;
                xFields.Quantity.disabled = false;
                break;
            case 'Subcontractors':
                xFields.Category.show = true;
                xFields.Category.required = true;
                xFields.Category.disabled = false;
                xFields.Description.show = true;
                xFields.Description.required = true;
                xFields.Description.disabled = false;
                xFields.UnitOfMeasure.show = true;
                xFields.UnitOfMeasure.required = true;
                xFields.UnitOfMeasure.disabled = false;
                xFields.Quantity.show = true;
                xFields.Quantity.required = true;
                xFields.Quantity.disabled = false;
                break;
            case 'Waste Disposal':
                xFields.Category.show = true;
                xFields.Category.required = true;
                xFields.Category.disabled = false;
                xFields.Resource.show = true;
                xFields.Resource.required = true;
                xFields.Resource.disabled = false;
                xFields.Description.show = true;
                xFields.Description.disabled = false;
                xFields.Quantity.show = true;
                xFields.Quantity.required = true;
                xFields.Quantity.disabled = false;

                /*Waste001
                if (templateLine.Resource__r != null && templateLine.Resource__r.Name != 'WD'
                    && (templateLine.Resource__r.Has_Container__c == true || templateLine.Resource__r.Has_Weight_Volume__c == true)) {
                    xFields.CostMethod.show = true;
                    xFields.CostMethod.required = true;
                    xFields.CostMethod.disabled = false;
                    xFields.UnitOfMeasure.show = false;
                    xFields.UnitOfMeasure.disabled = true;
                    xFields.ContainerSize.show = true;
                    xFields.ContainerSize.disabled = false;
                    xFields.UnitWeightVolume.show = true;
                    xFields.UnitWeightVolume.disabled = false;
                    if (templateLine.Cost_Method__c == 'Container') {
                        xFields.ContainerSize.required = true;
                    }
                    else if (templateLine.Cost_Method__c == 'Unit_Weight_Vol') {
                        xFields.UnitWeightVolume.required = true;
                    }
                }
                else {
                    xFields.CostMethod.show = false;
                    xFields.CostMethod.required = false;
                    xFields.CostMethod.disabled = true;
                    xFields.UnitOfMeasure.show = true;
                    xFields.UnitOfMeasure.required = true;
                    xFields.UnitOfMeasure.disabled = false;
                    xFields.ContainerSize.show = false;
                    xFields.ContainerSize.disabled = true;
                    xFields.ContainerSize.required = false;
                    xFields.UnitWeightVolume.show = false;
                    xFields.UnitWeightVolume.disabled = false;
                    xFields.UnitWeightVolume.required = false;
                }
                 */
                xFields.UnitOfMeasure.show = true;
                xFields.UnitOfMeasure.required = true;
                xFields.UnitOfMeasure.disabled = false;
                break;
            case 'Misc. Charges And Taxes':
                xFields.Category.show = true;
                xFields.Category.required = true;
                xFields.Category.disabled = false;
                xFields.Resource.show = true;
                xFields.Resource.required = true;
                xFields.Resource.disabled = false;
                xFields.Description.show = true;
                xFields.Description.disabled = false;
                xFields.UnitOfMeasure.show = true;
                xFields.UnitOfMeasure.required = true;
                xFields.UnitOfMeasure.disabled = false;
                xFields.Quantity.show = true;
                xFields.Quantity.required = true;
                xFields.Quantity.disabled = false;
                break;
            case 'Bundled':
                xFields.Category.show = true;
                xFields.Category.required = true;
                xFields.Category.disabled = false;
                xFields.ResourceType.show = true;
                xFields.ResourceType.required = true;
                xFields.ResourceType.disabled = false;
                xFields.Description.show = true;
                xFields.Description.disabled = false;
                xFields.UnitOfMeasure.show = true;
                xFields.UnitOfMeasure.required = true;
                xFields.UnitOfMeasure.disabled = false;
                xFields.Quantity.show = true;
                xFields.Quantity.disabled = false;
                break;
            case 'Demurrage':
                xFields.Category.show = true;
                xFields.Category.required = true;
                xFields.Category.disabled = false;
                xFields.Resource.show = true;
                xFields.Resource.required = true;
                xFields.Resource.disabled = false;
                xFields.Description.show = true;
                xFields.Description.disabled = false;
                xFields.UnitOfMeasure.show = true;
                xFields.UnitOfMeasure.required = true;
                xFields.UnitOfMeasure.disabled = false;
                xFields.Quantity.show = true;
                xFields.Quantity.required = true;
                xFields.Quantity.disabled = false;
                break;
            default:
                xFields.Category.show = true;
                xFields.Category.required = true;
                xFields.Category.disabled = false;
                break;
        }
        component.set("v.xFields", xFields);
    },

    //ticket 19130 <<
    initRelatedParentLines : function (component) {
        var sourceObjectType = component.get("v.sourceObjectType");
        var templateLine = component.get("v.templateLine");
        var relations = [];
        var others = [];
        if (templateLine.Parent_Lines__r && templateLine.Parent_Lines__r.records) {
            if (sourceObjectType == 'SalesOrder') {
                var mapParentLinesByResourceType = new Map();
                for (var i = 0; i < templateLine.Parent_Lines__r.records.length; i++) {
                    var relation = templateLine.Parent_Lines__r.records[i];

                    var relation2;

                    if (!mapParentLinesByResourceType.has(relation.Parent_Line__r.Resource_Type__c)) {
                        relation2 = JSON.parse(JSON.stringify(relation));
                        mapParentLinesByResourceType.set(relation.Parent_Line__r.Resource_Type__c, relation2);
                    } else {
                        relation2 = mapParentLinesByResourceType.get(relation.Parent_Line__r.Resource_Type__c);
                        relation2.Parent_Line__r.Quantity__c += relation.Parent_Line__r.Quantity__c;
                    }
                }
                relations = Array.from(mapParentLinesByResourceType.values());
            }
            else if (sourceObjectType == 'TM') {
                //show labor and equipment count, instead of quantity
                var mapParentLinesByResourceType = new Map();
                for (var i = 0; i < templateLine.Parent_Lines__r.records.length; i++) {
                    var relation = templateLine.Parent_Lines__r.records[i];
                    if (relation.Parent_Line__r.Category__c == 'Labor' || relation.Parent_Line__r.Category__c == 'Equipment') {
                        var relation2;
                        if (!mapParentLinesByResourceType.has(relation.Parent_Line__r.Resource_Type__c)) {
                            relation2 = JSON.parse(JSON.stringify(relation));
                            if (relation.Parent_Line__r.Quantity__c > 0) {
                                relation2.Parent_Line__r.Quantity__c = 1;
                            }
                            mapParentLinesByResourceType.set(relation.Parent_Line__r.Resource_Type__c, relation2);
                        } else {
                            relation2 = mapParentLinesByResourceType.get(relation.Parent_Line__r.Resource_Type__c);
                            if (relation.Parent_Line__r.Quantity__c > 0) {
                                relation2.Parent_Line__r.Quantity__c++;
                            }
                        }
                    }
                    else {
                        others.push(relation);
                    }
                }
                relations = Array.from(mapParentLinesByResourceType.values());
                relations = relations.concat(others);
            }
            else {
                relations = templateLine.Parent_Lines__r.records;
            }
        }
        component.set("v.relations", relations);
        this.showFields(component);

        if (relations) {
            var summaryLine = {};
            summaryLine.Quantity = 0;
            for (var i = 0; i < relations.length; i++) {
                summaryLine.Quantity += parseFloat(relations[i].Parent_Line__r.Quantity__c);
            }
            component.set("v.summaryLine", summaryLine);
        }
    }
    //ticket 19130 >>

});