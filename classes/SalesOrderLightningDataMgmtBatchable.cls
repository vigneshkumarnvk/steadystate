public with sharing class SalesOrderLightningDataMgmtBatchable implements Database.Batchable<Id> {

    public List<Id> start(Database.BatchableContext bc) {
        /*
        List<Id> salesOrderIds = new List<Id>();
        for (Sales_Order__c salesOrder : [SELECT Id FROM Sales_Order__c WHERE Converted_To_Lightning__c <> TRUE ORDER BY CreatedDate]) {
            salesOrderIds.add(salesOrder.Id);
        }    
        return salesOrderIds;
        */
        return null;
    }

    public void execute(Database.BatchableContext BC, List<Id> salesOrderIds) {
        /*
        try {
            List<ACVSalesOrderWrapper> salesOrderWrappers = SalesOrderLightningDataManagement.getSalesOrders(new Set<Id>(salesOrderIds));    
            SalesOrderLightningDataManagement.MakeSalesOrderLightningCompatible(salesOrderWrappers);
        }
        catch(exception ex) {
            System.abortJob(bc.GetJobId());
            throw ex;
        }
        */
    }
    
    public void finish(Database.BatchableContext bc) {

    }
}