trigger TimesheetLineTrigger on Timesheet_Line__c (before insert, before update, before delete) {
    if(Trigger.isBefore){
        if(Trigger.isDelete){
            TimesheetTriggerMgmt.TSLDelete(Trigger.old);
        } else {
            TimesheetTriggerMgmt.TSLInsertUpdate(Trigger.new);
        }
    }
}