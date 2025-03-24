trigger GLBatchTrigger on GL_Batch__c(before insert, before update, before delete) {
    if (Trigger.isInsert) {
        List<GL_Batch__c> GLBList = Trigger.new;
        //GLTriggersMgmt.GLB_I_U_Trigger(GLBList,Trigger.isInsert);
    } else if (Trigger.isDelete) {
        CompanyTriggerMgmt.GLB_D(Trigger.old);
    } else if (Trigger.isUpdate){
        List<GL_Batch__c> glBatcheLst = Trigger.new;
        for(GL_Batch__c glBatch:glBatcheLst){
            if(glBatch.Closed__c == true && glBatch.Total_Amount__c == 0 && Trigger.oldMap.get(glBatch.Id).Closed__c == false)
                glBatch.Description__c = 'Total ' + glBatch.No_of_Lines__c + ' records. Closed at ' + System.now();
        }
    }
}