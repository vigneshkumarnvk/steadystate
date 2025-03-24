public class SalesOrder_BeforeInsertTriggerHandler extends TriggerHandlerBase {
    public override void mainEntry() {
    System.debug('SalesOrder_BeforeInsertTriggerHandler >> mainEntry()');

        List<Sales_Order__c> SOList = (List<Sales_Order__c>) Trigger.new;
        Map<Id, Sales_Order__c> oldValues = (Map<Id, Sales_Order__c>) Trigger.oldMap;
        Boolean isInsert = Trigger.isInsert;

        SalesOrderTriggersMgt.SOInsertUpdate(SOList, oldValues, isInsert);
    }
}