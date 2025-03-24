global class RollupCustomerRevenueScheduable implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new RollupCustomerRevenueBatchable(), 25);
    }
}