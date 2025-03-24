@isTest
private class AdminSetupControllerTest {
    private static testMethod void testScheduleTMSignatureProcess() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.scheduleTMSignatureProcess();
        } catch (exception ex) {

        }
    }

    private static testMethod void testScheduleRollupCustomerRevenue() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.scheduleRollupCustomerRevenue();
        } catch (exception ex) {

        }
    }

    private static testMethod void testScheduleRollupAR() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.scheduleRollupAR();
        } catch (exception ex) {

        }
    }

    private static testMethod void testScheduleCoupaSalesOrderLookupValue() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.scheduleCoupaSalesOrderLookupValue();
        } catch (exception ex) {

        }
    }

    private static testMethod void testScheduleCoupaPurchOrderPull() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.scheduleCoupaPurchOrderPull();
        } catch (exception ex) {

        }
    }

    private static testMethod void testScheduleCoupaEquipmentAssetLookupValue() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.scheduleCoupaEquipmentAssetLookupValue();
        }
        catch(exception ex) {

        }
    }

    private static testMethod void scheduleKronosTimeClockBatch() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.scheduleKronosTimeClockBatch();
        }
        catch(exception ex) {

        }
    }

    private static testMethod void scheduleKronosTimeClockBatchMonday() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.scheduleKronosTimeClockBatchMonday();
        }
        catch(exception ex) {

        }
    }

    private static testMethod void executeKronosTimeClockBatch() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.executeKronosTimeClockBatch();
        }
        catch(exception ex) {

        }
    }

    private static testMethod void executeWorkOrderQuoteBatch() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.executeWorkOrderQuoteBatch();
        }
        catch(exception ex) {

        }
    }

    private static testMethod void executeContractBillingProjectBatch() {
        try {
            AdminSetupController adminSetupController = new AdminSetupController();
            adminSetupController.executeContractBillingProjectBatch();
        }
        catch(exception ex) {

        }
    }
}