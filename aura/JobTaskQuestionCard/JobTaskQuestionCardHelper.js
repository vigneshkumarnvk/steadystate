({
    clearErrors : function(component, event) {
        component.set("v.templateLine.answerLine.Quantity__c", null);
        component.set('v.isVisible', false);
        component.set('v.isVisible', true);
    }, 
    validateFields : function(component, event) {
        var fieldComponents = new Array();
        var fields = component.get("v.xFields");
        Object.keys(fields).forEach(function(key, index) {
            var field = fields[key];
            if (field.id != null && field.required == true) {
                fieldComponents.push(component.find(field.id));
            }
        });

        var allValid = fieldComponents.reduce(function(valid, field) {
            if (field) {
                if (Array.isArray(field)) {
                    for (var i = 0; i < field.length; i++) {
                        field[i].showHelpMessageIfInvalid();
                        if (field[i]) {
                            valid = valid && field[i].get("v.validity").valid;
                        }
                    }
                    return valid;
                } else {
                    field.showHelpMessageIfInvalid();
                    if (field) {
                        valid = valid && field.get("v.validity").valid;
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
    }
});