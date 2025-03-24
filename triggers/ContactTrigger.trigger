trigger ContactTrigger on Contact (after insert, after update, before update,before insert) {
    if (CompanyMgmt.byPassTrigger == true) return;
   If(Trigger.isAfter)
   {
       if(Trigger.isInsert)
       {
           ContactTriggerhandler.onAfterInsert(Trigger.new);
       }
       if(Trigger.isUpdate)
       {
           ContactTriggerhandler.onAfterUpdate(Trigger.new, Trigger.oldMap);
       }
   }
   if(Trigger.isBefore)
   {
       if(Trigger.isUpdate)
       {
           ContactTriggerhandler.onBeforeUpdate(Trigger.new, Trigger.oldMap);
       }
       if(Trigger.isInsert){
           ContactTriggerhandler.onBeforeInsert(Trigger.new);
       }

   }
   
}