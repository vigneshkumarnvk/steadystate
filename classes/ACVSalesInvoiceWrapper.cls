public with sharing class ACVSalesInvoiceWrapper {
    @AuraEnabled
    public Sales_Invoice__c SalesInvoice { set; get; }

    @AuraEnabled
    public List<ACVSalesInvoiceJobTaskWrapper> JobTaskWrappers { set; get; }


    public ACVSalesInvoiceWrapper(Sales_Invoice__c salesInvoice, List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers) {
        this.SalesInvoice = salesInvoice;
        this.JobTaskWrappers = jobTaskWrappers;
    }

    public ACVSalesInvoiceWrapper(Sales_Invoice__c invoice, List<Sales_Invoice_Job_Task__c> jobTasks, List<Sales_Invoice_Line__c> invoiceLines) {
        this.SalesInvoice = invoice;
        this.JobTaskWrappers = new List<ACVSalesInvoiceJobTaskWrapper>();
        Map<Integer, ACVSalesInvoiceJobTaskWrapper> mapInvoiceJobTaskWrappersByJobTask = new Map<Integer, ACVSalesInvoiceJobTaskWrapper>();

        for (Sales_Invoice_Job_Task__c jobTask : jobTasks) {
            Integer jobTaskLineNo = jobTask.Line_No__c.intValue();
            ACVSalesInvoiceJobTaskWrapper jobTaskWrapper = new ACVSalesInvoiceJobTaskWrapper();
            jobTaskWrapper.JobTask = jobTask;
            jobTaskWrapper.SalesInvoiceLines = new List<Sales_Invoice_Line__c>();
            mapInvoiceJobTaskWrappersByJobTask.put(jobTaskLineNo, jobTaskWrapper);
        }

        for (Sales_Invoice_Line__c invoiceLine : invoiceLines) {
            Integer jobTaskLineNo = 0;
            if (invoiceLine.Sales_Invoice_Job_Task__r != null && invoiceLine.Sales_Invoice_Job_Task__r.Line_No__c != null) {
                jobTaskLineNo = invoiceLine.Sales_Invoice_Job_Task__r.Line_No__c.intValue();
            }

            ACVSalesInvoiceJobTaskWrapper jobTaskWrapper;
            if (mapInvoiceJobTaskWrappersByJobTask.containsKey(jobTaskLineNo)) {
                jobTaskWrapper = mapInvoiceJobTaskWrappersByJobTask.get(jobTaskLineNo);
            }
            else {
                //handle sales lines without a job task -- old invoices
                jobTaskWrapper = new ACVSalesInvoiceJobTaskWrapper();
                jobTaskWrapper.JobTask = new Sales_Invoice_Job_Task__c(Line_No__c = jobTaskLineNo, Name = 'Unassigned T&M Lines');
                jobTaskWrapper.SalesInvoiceLines = new List<Sales_Invoice_Line__c>();
                mapInvoiceJobTaskWrappersByJobTask.put(jobTaskWrapper.JobTask.Line_No__c.intValue(), jobTaskWrapper);
            }

            invoiceLine.Sales_Invoice_Job_Task__c = jobTaskWrapper.JobTask.Id;
            invoiceLine.Sales_Invoice_Job_Task__r = jobTaskWrapper.JobTask;
            jobTaskWrapper.SalesInvoiceLines.add(invoiceLine);
        }

        this.JobTaskWrappers = mapInvoiceJobTaskWrappersByJobTask.values();
    }

    public List<Sales_Invoice_Job_Task__c> getJobTasks() {
        List<Sales_Invoice_Job_Task__c> salesInvoiceJobTasks = new List<Sales_Invoice_Job_Task__c>();
        for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : this.JobTaskWrappers) {
            salesInvoiceJobTasks.add(jobTaskWrapper.JobTask);
        }
        return salesInvoiceJobTasks;
    }

    public List<Sales_Invoice_Line__c> getTMLines() {
        List<Sales_Invoice_Line__c> invoiceLines = new List<Sales_Invoice_Line__c>();
        for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : this.JobTaskWrappers) {
            for (Sales_Invoice_Line__c invoiceLine : jobTaskWrapper.SalesInvoiceLines) {
                invoiceLines.add(invoiceLine);
            }
        }
        return invoiceLines;
    }
}