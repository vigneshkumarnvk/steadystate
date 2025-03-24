global with sharing class SalesInvoiceLinesService {
    private static ISalesInvoiceLinesService service() {
        return (ISalesInvoiceLinesService) Application.Service.newInstance(ISalesInvoiceLinesService.class);
    }

    global static void initStaticVariables(Sales_Invoice__c salesInvoice, List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers) {
        service().initStaticVariables(salesInvoice, jobTaskWrappers);
    }

    global static void initStaticVariables(Sales_Invoice__c salesInvoice, ACVSalesInvoiceJobTaskWrapper jobTaskWrapper) {
        List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers = new List<ACVSalesInvoiceJobTaskWrapper>{ jobTaskWrapper };
        service().initStaticVariables(salesInvoice, jobTaskWrappers);
    }

    global static void initStaticVariables(Sales_Invoice__c salesInvoice, Sales_Invoice_Job_Task__c jobTask, Sales_Invoice_Line__c salesInvoiceLine) {
        List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers = new List<ACVSalesInvoiceJobTaskWrapper>();
        ACVSalesInvoiceJobTaskWrapper jobTaskWrapper = new ACVSalesInvoiceJobTaskWrapper();
        jobTaskWrapper.JobTask = jobTask;
        jobTaskWrapper.SalesInvoiceLines.add(salesInvoiceLine);
        jobTaskWrappers.add(jobTaskWrapper);
        service().initStaticVariables(salesInvoice, jobTaskWrappers);
    }

    global static void validateResourceType(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine) {
        service().assignDescription(salesInvoiceLine);
        if (salesInvoiceLine.Unit_of_Measure__c == null) {
            service().assignUnitOfMeasure(salesInvoiceLine);
        }
        service().assignResourceTypeUOM(salesInvoiceLine);
        service().calcUnitCost(salesInvoice, salesInvoiceLine);
        service().assignTaxPercent(salesInvoice, salesInvoiceLine);
        service().calculateLineTotals(salesInvoice, salesInvoiceLine);
    }

    global static void validateResource(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine) {
        service().assignDescription(salesInvoiceLine);
        if (salesInvoiceLine.Unit_of_Measure__c == null) {
            service().assignUnitOfMeasure(salesInvoiceLine);
        }
        service().assignResourceUOM(salesInvoiceLine);
        service().calcUnitCost(salesInvoice, salesInvoiceLine);
        service().assignTaxPercent(salesInvoice, salesInvoiceLine);
        service().calculateLineTotals(salesInvoice, salesInvoiceLine);
    }

    global static void calculatePriceAndCost(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine) {
        service().calcUnitCost(salesInvoice, salesInvoiceLine);
        service().calculateLineTotals(salesInvoice, salesInvoiceLine);
    }

    global static void assignTaxPercent(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine) {
        service().assignTaxPercent(salesInvoice, salesInvoiceLine);
        service().calculateLineTotals(salesInvoice, salesInvoiceLine);
    }

    global static void calculateLineTotals(Sales_Invoice__c salesInvoice, List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers) {
        for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Invoice_Line__c salesInvoiceLine : jobTaskWrapper.SalesInvoiceLines) {
                service().calculateLineTotals(salesInvoice, salesInvoiceLine);
            }
        }
    }
}