public class CoupaSalesOrderSyncBatch implements Database.Batchable<Sales_Order__c>, Database.AllowsCallouts{
    public List<Sales_Order__c> start(Database.BatchableContext bc) {
        List<Sales_Order__c> salesOrders = [
                SELECT Id, Name, Document_Status__c, Synced_with_Coupa__c, Coupa_Lookup_Value_Id__c
                FROM Sales_Order__c
                WHERE Synced_with_Coupa__c != TRUE AND Document_Type__c = 'Sales Order' AND Document_Status__c = 'Open'
        ];
        return salesOrders;
    }

    public void execute(Database.BatchableContext BC, List<Sales_Order__c> salesOrders){
        List<Sales_Order__c> salesOrdersToUpdate = new List<Sales_Order__c>();
        Integration_Setting__mdt coupaSetting = IntegrationSettingUtil.coupaSetting;
        for (Sales_Order__c salesOrder : salesOrders) {
            if (salesOrder.Document_Status__c == 'Closed' && salesOrder.Coupa_Lookup_Value_Id__c == null) {
                salesOrder.Synced_with_Coupa__c = true;
                salesOrdersToUpdate.add(salesOrder);
            } else {
                String method = 'POST';
                String recordId = '';
                if (salesOrder.Coupa_Lookup_Value_Id__c != null) {
                    method = 'PUT';
                    recordId = salesOrder.Coupa_Lookup_Value_Id__c;
                } else {
                    Integer coupaId = CoupaIntegrationService.getLookupValueByName(salesOrder.Name, coupaSetting.Coupa_Sales_Order_Lookup_Id__c);
                    if (coupaId != null) {
                        salesOrder.Coupa_Lookup_Value_Id__c = String.valueOf(coupaId);
                        recordId = salesOrder.Coupa_Lookup_Value_Id__c;
                        method = 'PUT';
                    }
                }

                Boolean isActive = salesOrder.Document_Status__c != 'Closed';
                HttpResponse res = CoupaIntegrationService.syncLookupValue(method, 'Sales Order', recordId, salesOrder.Name, isActive);

                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    if (res.getStatusCode() == 201 && String.isNotBlank(res.getBody())) {
                        CoupaIntegrationService.LookupValue lookupValue = (CoupaIntegrationService.LookupValue) JSON.deserialize(res.getBody(), CoupaIntegrationService.LookupValue.class);
                        salesOrder.Coupa_Lookup_Value_Id__c = String.valueOf(lookupValue.id);
                    }
                    salesOrder.Synced_with_Coupa__c = true;
                    salesOrdersToUpdate.add(salesOrder);
                }
            }
        }

        if(salesOrdersToUpdate.size() > 0){
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            update salesOrdersToUpdate;
        }

    }

    public void finish(Database.BatchableContext BC){

    }
}