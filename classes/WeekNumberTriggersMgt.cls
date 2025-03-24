public with sharing class WeekNumberTriggersMgt {
    
    
    public static void WNInsertUpdate(List<Week_Number__c> WNList, Map<Id, Week_Number__c> oldWNMap, Boolean isInsert){
        Map<String, Week_Number__c> WNNameMap = new Map<String, Week_Number__c>();
        // Check duplicate
        for (Week_Number__c theWN : WNList) {
            if (isInsert || (theWN.Name != oldWNMap.get(theWN.Id).Name)) {
                if (WNNameMap.containsKey(theWN.Name)) {
                    theWN.Name.adderror('Same year, Same week number are not allowed. Week Number: ' + theWN.Name);
                } else {
                    WNNameMap.put(theWN.Name.toUpperCase(), theWN);
                }
            }
        }
    }
}