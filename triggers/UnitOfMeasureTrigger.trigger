trigger UnitOfMeasureTrigger on Unit_of_Measure__c (before insert, before update) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (Unit_of_Measure__c uom : Trigger.New) {
                uom.Name = uom.Name.toUpperCase();
            }
        }
    }
}