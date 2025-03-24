({
    doInit : function(component, event, helper) {
        var pageRef = component.get("v.pageReference");
        var salesOrderId = pageRef.state.c__id;
        component.set("v.salesOrderId", salesOrderId);
        helper.getSalesOrder(component, event);
        helper.getWorksheets(component, event);
        component.set("v.activeWorksheets", []);
        document.title = "T&Ms Billing";
    },
    handlePageChange : function(component, event, helper) {
        var pageRef = component.get("v.pageReference");
        var salesOrderId = pageRef.state.c__id;
        component.set("v.salesOrderId", salesOrderId);
        helper.getSalesOrder(component, event);
        helper.getWorksheets(component, event);
        component.set("v.activeWorksheets", []);
    },
    handleWorksheetsChange : function(component, event, helper) {
        helper.calculateProfitAndMargin(component);
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var rowIndex = event.getParam("rowIndex");
        var action = event.getParam("action");

        switch (name) {
            case 'jobTaskCheckBox':
                if (action == 'change') {
                    var worksheets = component.get("v.worksheets");
                    var worksheet = worksheets[rowIndex];
                    var salesOrderJobTaskId = worksheet.SalesOrderJobTask.Id;
                    if (worksheet.Selected == true) {
                        helper.selectWorksheet(component, event, rowIndex, salesOrderJobTaskId);
                    } else {
                        helper.deselectWorksheet(component, event, rowIndex, salesOrderJobTaskId);
                    }
                }
                break;
            case 'tmCheckbox':
                if (action == 'change') {
                    var target = event.getParam("target");
                    if (target) {
                        var tmIndex = target.dataset.tmIndex;
                        var salesOrderJobTaskId = target.dataset.orderTaskId;
                        var tmId = target.dataset.tmId;

                        var worksheets = component.get("v.worksheets");
                        var worksheet = worksheets[rowIndex];
                        var relatedInfo = worksheet.RelatedInfos[tmIndex];
                        if (relatedInfo.TM.Selected == true) {
                            helper.selectTM(component, event, rowIndex, salesOrderJobTaskId, tmId);
                        }
                        else {
                            helper.deselectTM(component, event, rowIndex, salesOrderJobTaskId, tmId);
                        }
                    }
                }
                break;
        }
    },
    createInvoice : function(component, event, helper) {
        
       if (helper.validateInvoice(component, event)) {
            helper.confirmCreateInvoice(component, event);
       }
    },
    navigateToBillingWorksheet : function(component, event, helper) {
        var salesOrderId = component.get("v.salesOrderId");
        var url = '/lightning/cmp/c__BillingWorksheet?c__id=' + salesOrderId;
        helper.navigateToUrl(component, event, url);
    }
});