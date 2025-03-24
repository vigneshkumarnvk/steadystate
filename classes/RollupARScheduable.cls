global class RollupARScheduable implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new RollupCustomerARBatchable(), 25);
    }
}