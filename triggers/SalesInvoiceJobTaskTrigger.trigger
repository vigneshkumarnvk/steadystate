trigger SalesInvoiceJobTaskTrigger on Sales_Invoice_Job_Task__c (after insert, after update, after delete) {
    if (CompanyMgmt.byPassTrigger == true) return;
    
    if (Trigger.isAfter) {
        Set<Id> salesOrderJobTaskIds = new Set<Id>();
        if (Trigger.isUpdate || Trigger.isInsert) {
            for (Sales_Invoice_Job_Task__c jobTask : Trigger.new) {
                if (jobTask.Sales_Order_Job_Task__c != null) {
                    salesOrderJobTaskIds.add(jobTask.Sales_Order_Job_Task__c);
                }
            }
        }
        else if (Trigger.isDelete) {
            for (Sales_Invoice_Job_Task__c jobTask : Trigger.old) {
                if (jobTask.Sales_Order_Job_Task__c != null) {
                    salesOrderJobTaskIds.add(jobTask.Sales_Order_Job_Task__c);
                }
            }
        }

        Map<Id, Sales_Order_Job_Task__c> mapSalesOrderJobTasksById = new Map<Id, Sales_Order_Job_Task__c>();
        for (Sales_Invoice_Job_Task__c salesInvoiceJobTask : [SELECT Billing_Pct__c, Sales_Invoice__r.Credit_Memo__c, Sales_Order_Job_Task__c, Voided__c FROM Sales_Invoice_Job_Task__c WHERE Sales_Order_Job_Task__c IN : salesOrderJobTaskIds]) {
            Sales_Order_Job_Task__c salesOrderJobTask;
            if (mapSalesOrderJobTasksById.containsKey(salesInvoiceJobTask.Sales_Order_Job_Task__c)) {
                salesOrderJobTask = mapSalesOrderJobTasksById.get(salesInvoiceJobTask.Sales_Order_Job_Task__c);
            }
            else {
                salesOrderJobTask = new Sales_Order_Job_Task__c(Id = salesInvoiceJobTask.Sales_Order_Job_Task__c);
                salesOrderJobTask.Pct_Billed__c = 0;
                mapSalesOrderJobTasksById.put(salesOrderJobTask.Id, salesOrderJobTask);
            }

            if (salesInvoiceJobTask.Voided__c != true) {
                if (salesInvoiceJobTask.Sales_Invoice__r.Credit_Memo__c != true) {
                    salesOrderJobTask.Pct_Billed__c += (salesInvoiceJobTask.Billing_Pct__c == null ? 0 : salesInvoiceJobTask.Billing_Pct__c);
                } else {
                    salesOrderJobTask.Pct_Billed__c -= (salesInvoiceJobTask.Billing_Pct__c == null ? 0 : salesInvoiceJobTask.Billing_Pct__c);
                }
            }

            if (salesOrderJobTask.Pct_Billed__c < 0) {
                salesOrderJobTask.Pct_Billed__c = 0;
            }
        }
        if (mapSalesOrderJobTasksById.size() > 0) {
            CompanyMgmt.byPassTrigger = true;
            update mapSalesOrderJobTasksById.values();
            CompanyMgmt.byPassTrigger = false;
        }

    }
}