({
    validateWorksheet : function(component, event, helper) {
        var worksheet = component.get("v.worksheet");
        var salesOrder = component.get("v.salesOrder");
        var invoiceLineCount = 0;
        for (var i = 0; i < worksheet.WorksheetLines.length; i++) {
            if (worksheet.WorksheetLines[i].To_Invoice__c == true) {
                invoiceLineCount++;
            }
        }
        
        if (invoiceLineCount == 0) {
            if(salesOrder.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c){
                helper.showToast(component, "Error", 'There are no lines checked To Billing Package in job task ' + worksheet.SalesOrderJobTask.Name, "error", "dismissible");
                return false;      
            }else{
                helper.showToast(component, "Error", 'There are no lines to invoice in job task ' + worksheet.SalesOrderJobTask.Name, "error", "dismissible");
                return false;
            }
            
        }
        if (worksheet.SalesOrderJobTask.Billing_Type__c == 'Fixed Price') {
            if (!worksheet.SalesOrderJobTask.Pct_To_Bill__c) {
                helper.showToast(component, "", "% To Billing is required for fixed price job task.", "error", "dismissible");
                return false;
            }
            
        }
        return true;
    },
});