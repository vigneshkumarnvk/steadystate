public with sharing class ACVSalesInvoiceLineController {


    @AuraEnabled
    public static String validateResourceType(String JSONSalesInvoice, String JSONJobTask, String JSONSalesInvoiceLine) {
        try {
            Sales_Invoice__c salesInvoice = JSONToSalesInvoice(JSONSalesInvoice);
            Sales_Invoice_Job_Task__c jobTask = JSONToJobTask(JSONJobTask);
            Sales_Invoice_Line__c salesInvoiceLine = JSONToSalesInvoiceLine(JSONSalesInvoiceLine);

            SalesInvoiceLinesService.initStaticVariables(salesInvoice, jobTask, salesInvoiceLine);
            SalesInvoiceLinesService.validateResourceType(salesInvoice, salesInvoiceLine);
            return JSON.serialize(salesInvoiceLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateResource(String JSONSalesInvoice, String JSONJobTask, String JSONSalesInvoiceLine) {
        try {
            Sales_Invoice__c salesInvoice = JSONToSalesInvoice(JSONSalesInvoice);
            Sales_Invoice_Job_Task__c jobTask = JSONToJobTask(JSONJobTask);
            Sales_Invoice_Line__c salesInvoiceLine = JSONToSalesInvoiceLine(JSONSalesInvoiceLine);

            SalesInvoiceLinesService.initStaticVariables(salesInvoice, jobTask, salesInvoiceLine);
            SalesInvoiceLinesService.validateResource(salesInvoice, salesInvoiceLine);

            return JSON.serialize(salesInvoiceLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String calculatePriceAndCost(String JSONSalesInvoice, String JSONJobTask, String JSONSalesInvoiceLine) {
        try {
            Sales_Invoice__c salesInvoice = JSONToSalesInvoice(JSONSalesInvoice);
            Sales_Invoice_Job_Task__c jobTask = JSONToJobTask(JSONJobTask);
            Sales_Invoice_Line__c salesInvoiceLine = JSONToSalesInvoiceLine(JSONSalesInvoiceLine);

            SalesInvoiceLinesService.initStaticVariables(salesInvoice, jobTask, salesInvoiceLine);
            SalesInvoiceLinesService.calculatePriceAndCost(salesInvoice, salesInvoiceLine); 
            return JSON.serialize(salesInvoiceLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String calculateTaxPct(String JSONSalesInvoice, String JSONJobTask, String JSONSalesInvoiceLine) {
        try {
            Sales_Invoice__c salesInvoice = JSONToSalesInvoice(JSONSalesInvoice);
            Sales_Invoice_Job_Task__c jobTask = JSONToJobTask(JSONJobTask);
            Sales_Invoice_Line__c salesInvoiceLine = JSONToSalesInvoiceLine(JSONSalesInvoiceLine);

            SalesInvoiceLinesService.initStaticVariables(salesInvoice, jobTask, salesInvoiceLine);
            SalesInvoiceLinesService.assignTaxPercent(salesInvoice, salesInvoiceLine);
            return JSON.serialize(salesInvoiceLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static Sales_Invoice__c JSONToSalesInvoice(String JSONSalesInvoice) {
        return (Sales_Invoice__c)JSON.deserialize(JSONSalesInvoice, Sales_Invoice__c.class);
    }

    private static Sales_Invoice_Job_Task__c JSONToJobTask(String JSONJobTask) {
        return (Sales_Invoice_Job_Task__c)JSON.deserialize(JSONJobTask, Sales_Invoice_Job_Task__c.class);
    }

    private static List<ACVSalesInvoiceJobTaskWrapper> JSONToJobTaskWrappers(String JSONJobTaskWrappers) {
        return (List<ACVSalesInvoiceJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesInvoiceJobTaskWrapper>.class);
    }

    private static ACVSalesInvoiceJobTaskWrapper JSONToJobTaskWrapper(String JSONJobTaskWrapper) {
        return (ACVSalesInvoiceJobTaskWrapper)JSON.deserialize(JSONJobTaskWrapper, ACVSalesInvoiceJobTaskWrapper.class);
    }

    private static Sales_Invoice_Line__c JSONToSalesInvoiceLine(String JSONSalesInvoiceLine) {
        return (Sales_Invoice_Line__c)JSON.deserialize(JSONSalesInvoiceLine, Sales_Invoice_Line__c.class);
    }
}