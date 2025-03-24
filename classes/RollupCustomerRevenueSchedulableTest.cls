@isTest
private class RollupCustomerRevenueSchedulableTest {
    private static testMethod void test() {
        Test.StartTest();
        String cron = '0 0 23 * * ?';
        System.schedule('Account Rollup AR Scheduled Job', cron, new RollupCustomerRevenueScheduable());
        System.schedule('Account Customer Rev Rollup Job', cron, new RollupCustomerRevenueSchedulable());
        Test.stopTest();
    }
}