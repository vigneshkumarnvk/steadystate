trigger GLTrigger on GL_Entry__c (before insert, before update, before delete) {
    if (trigger.isDelete) {
        List<GL_Entry__c> GLList = Trigger.old;
        CompanyTriggerMgmt.GL_D_Trigger(GLList);
    } else if (Trigger.isAfter){
        List<GL_Entry__c> GLList = Trigger.new;
        CompanyTriggerMgmt.GL_I_U_Trigger(GLList);
    }
}