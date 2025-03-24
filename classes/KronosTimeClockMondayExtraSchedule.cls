global class KronosTimeClockMondayExtraSchedule implements Schedulable {
    global void execute(SchedulableContext sc){
        GenerateKronosTimeClockBatchMondayExtra kronosTimeClockBatch = new GenerateKronosTimeClockBatchMondayExtra();
        Database.executeBatch(kronosTimeClockBatch, 1);
    }
}