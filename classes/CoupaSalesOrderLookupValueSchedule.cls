global class CoupaSalesOrderLookupValueSchedule implements Schedulable {
    global void execute(SchedulableContext sc){
        CoupaSalesOrderSyncBatch coupaSalesOrderSyncBatch = new CoupaSalesOrderSyncBatch();
        Database.executeBatch(coupaSalesOrderSyncBatch, 5);
    }
}