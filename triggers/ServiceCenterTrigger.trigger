trigger ServiceCenterTrigger on Service_Center__c (before insert, before update) {
    if (Trigger.isBefore) {
        for (Service_Center__c sc : Trigger.New) {
            if (sc.Code__c != null) {
                sc.Code__c = sc.Code__c.toUpperCase();
            }
        }
    }
}