trigger WeekNumberTrigger on Week_Number__c (before insert, before update) {
    if(Trigger.isInsert || Trigger.isUpdate){
        List<Week_Number__c> WNList = Trigger.new;
        WeekNumberTriggersMgt.WNInsertUpdate(WNList, Trigger.oldMap, Trigger.isInsert);
    }
}