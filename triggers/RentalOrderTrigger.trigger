trigger RentalOrderTrigger on Rental_Order__c (before insert, before update) {
	if(Trigger.isInsert || Trigger.isUpdate){
        List<Rental_Order__c> ROList = Trigger.new;
        RentalOrderTriggersMgmt.ROInsertUpdate(ROList, trigger.oldMap, trigger.isInsert);
    }
}