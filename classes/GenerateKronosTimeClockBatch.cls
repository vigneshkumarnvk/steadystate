public with sharing class GenerateKronosTimeClockBatch implements Database.Batchable<Service_Center__c> {
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
            KronosTimeClockService.processEmployeeTimeDataByServiceCenter(serviceCenter.Id, null, runDate);
        }
    }

    public void finish(Database.BatchableContext bc){
        //Ticket#24469 >>
        KronosTimeClockEntriesSortingBatch sortingBatch = new KronosTimeClockEntriesSortingBatch(false);
        //KronosTimeClockEntriesSortingBatch sortingBatch = new KronosTimeClockEntriesSortingBatch();
        //Ticket#24469 <<
        Database.executeBatch(sortingBatch, 3000);
    }
}