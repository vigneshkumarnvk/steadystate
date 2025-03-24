trigger CompanySetupTrigger on Company_Setup__c (before update,before insert,before delete) {
    if ((trigger.isUpdate || trigger.isInsert) && trigger.isBefore) {
        CompanyTriggerMgmt.CSInsertUpdate(Trigger.new,Trigger.isInsert,Trigger.OldMap);
    }
    if (trigger.isDelete && trigger.isBefore)   {
        CompanyTriggerMgmt.CSDelete(Trigger.old);
    }
}