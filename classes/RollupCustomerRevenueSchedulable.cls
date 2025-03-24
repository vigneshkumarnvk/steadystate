global class RollupCustomerRevenueSchedulable implements Schedulable {
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new RollupCustomerRevenueBatch(), 1000);
    }
}