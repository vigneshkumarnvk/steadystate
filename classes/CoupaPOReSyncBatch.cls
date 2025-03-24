public with sharing class CoupaPOReSyncBatch implements Database.Batchable<Purchase_Order__c>, Database.AllowsCallouts{
    public List<Purchase_Order__c> start(Database.BatchableContext bc) {
        List<Purchase_Order__c> purchaseOrders = [
                SELECT Id, Name, Coupa_ReSync__c, Coupa_Id__c
                FROM Purchase_Order__c
                WHERE Coupa_Id__c != NULL AND Coupa_ReSync__c = FALSE
        ];
        return purchaseOrders;
    }

    public void execute(Database.BatchableContext BC, List<Purchase_Order__c> purchaseOrders){
        List<Purchase_Order__c> purchaseOrdersToUpdates = new List<Purchase_Order__c>();
        for (Purchase_Order__c purchaseOrder : purchaseOrders) {
            CoupaIntegrationService.getPurchaseOrderByPONumber(purchaseOrder.Name);
            purchaseOrder.Coupa_ReSync__c = true;
            purchaseOrdersToUpdates.add(purchaseOrder);
        }

        if(purchaseOrdersToUpdates.size() > 0){
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            update purchaseOrdersToUpdates;
        }
    }

    public void finish(Database.BatchableContext BC){

    }
}