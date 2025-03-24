({
    doInit : function(component, event, helper) {
        var salesInvoice = component.get("v.salesInvoice");
        var setupData = component.get("v.setupData");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var jobTaskWrapperIndex = component.get("v.jobTaskWrapperIndex");
        var inlineEditComponentParams = { "salesInvoice": salesInvoice, "jobTaskWrapper": jobTaskWrapper, "jobTaskWrapperIndex": jobTaskWrapperIndex, "setupData": setupData};
        component.set("v.inlineEditComponentParams", inlineEditComponentParams);
        
        helper.calculateTotals(component);
    },
    addLine : function(component, event, helper) {
        var jobTaskWrapper = component.get("v.jobTaskWrapper");
        var salesInvoiceLine = helper.newSalesInvoiceLine(component);
        jobTaskWrapper.SalesInvoiceLines.push(salesInvoiceLine);
        component.set("v.jobTaskWrapper", jobTaskWrapper);
        var rowIndex = jobTaskWrapper.SalesInvoiceLines.length - 1;

        var calls = [];
        calls.push(helper.closeInlineEdit.bind(helper, component));
        calls.push(helper.openInlineEdit.bind(helper, component, rowIndex));
        helper.makeStackedCalls(component, event, helper, calls);
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var action = event.getParam("action");
        var rowIndex = event.getParam("rowIndex");
        switch(name) {
            case 'delete':
                break;
        }
    },
    handleInlineEditClose : function(component, event, helper) {
        helper.closeInlineEdit(component);
    },
    handleSalesInvoiceLineUpdate : function(component, event, helper) {
        helper.calculateJobTotals(component);
    },
    handleSalesInvoiceLineDelete : function(component, event, helper) {
        var salesInvoiceLine = event.getParam("salesInvoiceLine");
        var jobTaskWrapper = component.get("v.jobTaskWrapper");

        for (var i = 0; i < jobTaskWrapper.SalesInvoiceLines.length; i++) {
            if (jobTaskWrapper.SalesInvoiceLines[i].Line_No__c == salesInvoiceLine.Line_No__c) {
                jobTaskWrapper.SalesInvoiceLines.splice(i, 1);
                break;
            }
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
        helper.calculateJobTotals(component);
    },
    handleJobTaskWrapperChange : function(component, event, helper) {
        helper.calculateJobTotals(component);
    },
    validateLines : function(component, event, helper) {
        helper.closeInlineEdit(component);

        var valid = true;
        var jobTaskWrapper = component.get("v.jobTaskWrapper");

        for (var i = 0; i < jobTaskWrapper.SalesInvoiceLines.length; i++) {
            var salesInvoiceLine = jobTaskWrapper.SalesInvoiceLines[i];
            salesInvoiceLine.errorText = null;

            var err = {};
            err.rowIndex = i;
            err.descriptions = [];

            if (!salesInvoiceLine.Category__c) {
                err.descriptions.push('Category is required');
            }

            switch (salesInvoiceLine.Category__c) {
                case 'Labor':
                case 'Bundled':
                    if (!salesInvoiceLine.Resource_Type__c) {
                        err.descriptions.push('Resource Type is required');
                    }
                    if (!salesInvoiceLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (!salesInvoiceLine.Quantity__c) {
                        err.descriptions.push('Quantity is required');
                    }
                    break;
                case 'Equipment':
                    if (!salesInvoiceLine.Resource_Type__c) {
                        err.descriptions.push('Resource Type is required');
                    }
                    if (!salesInvoiceLine.Resource__c && salesInvoiceLine.Resource_Type__r.Fleet_No_Required__c == true) {
                        err.descriptions.push('Resource is required');
                    }
                    if (!salesInvoiceLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (!salesInvoiceLine.Quantity__c) {
                        err.descriptions.push('Quantity is required');
                    }
                    break;
                case 'Materials':
                case 'Demurrage':
                case 'Misc. Charges And Taxes':
                    if (!salesInvoiceLine.Resource__c) {
                        err.descriptions.push('Resource is required')
                    }
                    if (!salesInvoiceLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (!salesInvoiceLine.Quantity__c) {
                        err.descriptions.push('Quantity is required');
                    }
                    break;
                case 'Subcontractors':
                    if (!salesInvoiceLine.Description__c) {
                        err.descriptions.push('Description is required');
                    }
                    if (!salesInvoiceLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }
                    if (!salesInvoiceLine.Quantity__c) {
                        err.descriptions.push('Quantity is required');
                    }
                    break;
                case 'Waste Disposal':
                    if (!salesInvoiceLine.Resource__r) {
                        err.descriptions.push('Resource is required');
                    }

                    /*Waste001
                    if (salesInvoiceLine.Resource__r && salesInvoiceLine.Resource__r.Name != 'WD' && salesInvoiceLine.Resource__r.Name != 'MA Transporter Fee' && salesInvoiceLine.Resource__r.Name != 'Manifest Fee' && (salesInvoiceLine.Resource__r.Has_Container__c == true || salesInvoiceLine.Resource__r.Has_Weight_Volume__c == true)) {
                        if (!salesInvoiceLine.Cost_Method__c && salesInvoiceLine.System_Calculated_Line__c != true) {
                            err.descriptions.push('Cost Method is required.');
                        } else if (salesInvoiceLine.Cost_Method__c == 'Unit_Weight_Vol' && !salesInvoiceLine.Unit_Weight_Vol__c) {
                            err.descriptions.push('Unit Weight/Volume is required');
                        } else if (salesInvoiceLine.Cost_Method__c == 'Container' && !salesInvoiceLine.Container_Size__c) {
                            err.descriptions.push('Container is required');
                        }
                    }
                    if (!salesInvoiceLine.Unit_of_Measure__c) {
                        if (salesInvoiceLine.Resource__r && (salesInvoiceLine.Resource__r.Name == 'WD' || salesInvoiceLine.Resource__r.Name == 'MA Transporter Fee' || salesInvoiceLine.Resource__r.Name == 'Manifest Fee' || (salesInvoiceLine.Resource__r.Has_Container__c != true && salesInvoiceLine.Resource__r.Has_Weight_Volume__c != true))) {
                            err.descriptions.push('UOM is required');
                        }
                    }
                     */

                    if (!salesInvoiceLine.Unit_of_Measure__c) {
                        err.descriptions.push('UOM is required');
                    }

                    if (!salesInvoiceLine.Quantity__c) {
                        err.descriptions.push('Quantity is required');
                    }
                    break;
            }

            if (err.descriptions.length > 0) {
                salesInvoiceLine.errorText = '';
                for (var j = 0; j < err.descriptions.length; j++) {
                    salesInvoiceLine.errorText += (j + 1) + ') ' + err.descriptions[j] + ' ';
                }
                valid = false;
            }
        }
        component.set("v.jobTaskWrapper", jobTaskWrapper);
        helper.refreshTable(component);

        /*
        if (!valid) {
            helper.showToast(component, "Validation Errors", "You must resolve all validation errors to continue.", "error", "pester");
        }*/

        return valid;
    }
});