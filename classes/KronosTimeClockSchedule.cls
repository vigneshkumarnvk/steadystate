global class KronosTimeClockSchedule implements Schedulable {
    global void execute(SchedulableContext sc){
        GenerateKronosTimeClockBatch kronosTimeClockBatch = new GenerateKronosTimeClockBatch();
        Database.executeBatch(kronosTimeClockBatch, 1);
    }
}