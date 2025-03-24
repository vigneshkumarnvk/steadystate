trigger GLAccountTrigger on GL_Account__c (before insert, before update, before delete) {
    if (Trigger.isDelete) {
        CompanyTriggerMgmt.GLA_D(Trigger.Old);
    }
}