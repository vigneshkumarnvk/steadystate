public with sharing class LWCTMController {

    @AuraEnabled
    public static Id cloneAndScheduleTM(Id tmId, String scheduledDate){
        try{
            List<TM__c> tms = TMsSelector.newInstance().selectByIds(new Set<Id>{tmId});
            List<TM__c> newTMs = TMsService.cloneAndSchedule(tms, scheduledDate);
            return newTMs[0].Id;
        } catch (Exception ex){
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
}