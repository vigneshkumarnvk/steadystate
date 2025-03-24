trigger SalesLineTrigger on Sales_Line__c (before insert, before update, before delete) {
    SalesOrderTriggersMgt.SLInsertUpdate(Trigger.new, Trigger.oldMap);
}