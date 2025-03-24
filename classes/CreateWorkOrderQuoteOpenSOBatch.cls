/******************************************************************************************************
* Class Name: CreateWorkOrderQuoteOpenSOBatch
* Description: This batch class query's all Sales Orders that are 'Open' and 'Submitted to Eqai' is false utilizes the MakeCalloutsQueueable class to 
               perform asynchronous callout for each sales order to the Work Order Quote EQAI integration.
* ***************************************************************************************************
* Owner		        Task #			Date		Description
* Andrew Simons         76914                   2/21            Batch class created to send open sales order AND not submitted to eqai to create work order quote
* ******************************************************************************************************/


global class CreateWorkOrderQuoteOpenSOBatch implements Database.Batchable<SObject>, Database.Stateful {

    private List<String> salesOrderIds;
    Integer queryLimit;
    String queryFilter;

    global CreateWorkOrderQuoteOpenSOBatch() {
        // Query for the custom metadata record
        BatchSettings__mdt workOrderQuoteQuerySize = [SELECT MasterLabel, Value__c FROM BatchSettings__mdt WHERE MasterLabel ='WorkOrderQuoteQuerySize' LIMIT 1];
        BatchSettings__mdt workOrderQuoteQueryFilter = [SELECT MasterLabel, Query_Filter__c FROM BatchSettings__mdt WHERE MasterLabel ='workOrderQuoteQueryFilter' LIMIT 1];
        // Retrieve the value from the custom metadata record
        queryLimit = Integer.valueOf(workOrderQuoteQuerySize.Value__c);
        queryFilter = String.valueOf(workOrderQuoteQueryFilter.Query_Filter__c);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query Open sales orders
        String query = 'SELECT Id FROM Sales_Order__c WHERE ' + queryFilter + ' LIMIT :queryLimit';
        return Database.getQueryLocator(query);
    }
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Process records in batches based on the specified batch size - 10
        salesOrderIds = new List<String>();
        List<Sales_Order__c> salesOrders = (List<Sales_Order__c>) scope;

        for (Sales_Order__c salesOrder : salesOrders) {
            salesOrderIds.add(salesOrder.Id);
        }

        // Enqueue a Queueable job for each sales order id list to make the callout asynchronously
        if (!salesOrderIds.isEmpty()) {
            System.enqueueJob(new MakeCalloutsQueueable(salesOrderIds, 0));
            System.debug('Enqueued Queueable job for callouts.');
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: Add any additional processing after batch completion
        System.debug('finished...');
    }

}