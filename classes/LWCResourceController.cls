public with sharing class LWCResourceController {
    @AuraEnabled
    public static void processKronosTimePunch(String actionType, Id resourceId, Date startDate, Date endDate){
        //Resource__c resource = getResourceBy(resourceId);
        if(actionType == 'removeEntries'){
            deleteKronosEntries(resourceId, startDate, endDate);
        } else if (actionType == 'processEntries'){
            processKronosEntriesByResource(resourceId, startDate, endDate);
        }
    }

    /*
    @AuraEnabled(cacheable=true)
    public static Resource__c getResourceBy(Id resourceId){
        List<Resource__c> resources = ResourcesSelector.newInstance().selectById(new Set<Id>{resourceId});
        if (resources.size() > 0){
            return resources[0];
        } else {
            throw new DataException('Labor resource not found!');
        }
    }
     */

    private static void deleteKronosEntries(Id resourceId, Date startDate, Date endDate){
        if(endDate != null && endDate < startDate){
            throw new DataException('End Date cannot be earlier than the Start Date!');
        }

        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedEntries = [
                SELECT Id, Exported__c, Kronos_Action__c FROM Employee_Clocked_Time_for_Kronos__c WHERE Resource__c = :resourceId AND Work_Date__c >= :startDate AND Work_Date__c <= :endDate
                AND Kronos_Action__c != 'Delete'
        ];

        KronosTimeClockService.deleteKronosTimeClockEnties(employeeClockedEntries);
    }

    private static void processKronosEntriesByResource(Id resourceId, Date startDate, Date endDate){
        if(endDate != null && endDate < startDate){
            throw new DataException('End Date cannot be earlier than the Start Date!');
        }

        KronosTimeClockService.forceEntry = true;
        KronosTimeClockService.processEmployeeTimeDataByResource(resourceId, startDate, endDate);
    }
}