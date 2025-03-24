({
    doInit : function(component, event, helper) {
        var salesOrderId = component.get("v.salesOrderId");
        var worksheet = component.get("v.worksheet");
        var inlineEditComponentParams = {};
        inlineEditComponentParams.salesOrderId = salesOrderId;
        //inlineEditComponentParams.relatedInfos = worksheet.RelatedInfos;
        component.set("v.inlineEditComponentParams", inlineEditComponentParams);
    },
    handleRowAction : function(component, event, helper) {
        var name = event.getParam("name");
        var action = event.getParam("action");
        var rowIndex = event.getParam("rowIndex");
        switch(name) {
            case 'delete':
                var rowIndex = event.getParam("rowIndex");
                helper.confirmDeleteLine(component, event, rowIndex);
                break;
            case 'view':
                var rowIndex = event.getParam("rowIndex");
                helper.showLineCard(component, event, rowIndex);
                break;
        }
    },
    handleInlineEditClose : function(component, event, helper) {
        var rowIndex = event.getParam("rowIndex");
        var worksheetLines = component.get("v.worksheetLines");
        var worksheetLine = worksheetLines[rowIndex];
        var lumpSumLineNo;
        if (worksheetLine.Bundle_Line__r) {
            lumpSumLineNo = worksheetLine.Bundle_Line__r.Line_No__c;
            if (worksheetLine.Bill_as_Lump_Sum__c != true) {
                worksheetLine.Bundle_Line__c = null;
                worksheetLine.Bundle_Line__r = null;
            }
        }

        if (lumpSumLineNo) {
            var lumpSumRowIndex = -1;
            for (var i = 0; i < worksheetLines.length; i++) {
                if (worksheetLines[i].Line_No__c == lumpSumLineNo) {
                    lumpSumLine = worksheetLines[i];
                    lumpSumRowIndex = i;
                    break;
                }
            }

            if (lumpSumRowIndex >= 0) {
                var lumpSumLine = worksheetLines[lumpSumRowIndex];
                helper.rollupBundle(lumpSumLine, worksheetLines, false);
                component.set("v.worksheetLines[" + lumpSumRowIndex + "]", lumpSumLine);
                helper.refreshTable(component);
            }
        }
    },
});