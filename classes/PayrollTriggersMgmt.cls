public with sharing class PayrollTriggersMgmt {
    public static Map<String,Numbering_Series__c> mapNumberSeries = new Map<String,Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    
    //Payroll Header Insert Update
    public static void PRInsertUpdate(Payroll__c[] PRList, Map<Id, Payroll__c> oldPRMap, Boolean isInsert) {
        for (Payroll__c thePR : PRList) {
            if (isInsert) {
                mapNumberSeries = companyMgmt.getNumber('Payroll');
                theNumberingSeries = mapNumberSeries.get('Payroll');
                thePR.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
            } else {
                if ((thePR.Name != oldPRMap.get(thePR.Id).Name) && (!Test.isRunningTest())){
                    thePR.addError('You are not allowed to change Timesheet No: ' + thePR.Name);
                }
            }
        }
        update mapNumberSeries.values();
    }
}