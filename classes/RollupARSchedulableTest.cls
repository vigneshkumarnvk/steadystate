@isTest
private class RollupARSchedulableTest {
    private static testMethod void test() {
        Test.StartTest();
        String cron = '0 0 23 * * ?';
        System.schedule('Account Rollup AR Scheduled Job', cron, new RollupARScheduable());
        Test.stopTest();
    }
}