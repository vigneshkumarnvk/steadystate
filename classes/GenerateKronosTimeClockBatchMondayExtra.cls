public with sharing class GenerateKronosTimeClockBatchMondayExtra implements Database.Batchable<Service_Center__c> {
    public List<Service_Center__c> start(Database.BatchableContext bc){
        List<Service_Center__c> serviceCenters = [
                SELECT Id
                FROM Service_Center__c];
        return serviceCenters;
    }

    public void execute(Database.BatchableContext bc, List<Service_Center__c> serviceCenters){
        for(Service_Center__c serviceCenter : serviceCenters){
            //System.debug('Info: serviceCenter ' + serviceCenter.Name);
            Date runDate = Date.today();
            if(runDate < KronosTimeClockService.KRONOSCUTOFFDATE){
                runDate = KronosTimeClockService.KRONOSCUTOFFDATE;
            }
            KronosTimeClockService.mondayExtraRun = true;
            KronosTimeClockService.processEmployeeTimeDataByServiceCenter(serviceCenter.Id, null, runDate);
        }
    }

    public void finish(Database.BatchableContext bc){
        KronosTimeClockEntriesSortingBatch sortingBatch = new KronosTimeClockEntriesSortingBatch(true);
        Database.executeBatch(sortingBatch, 3000);
    }
}