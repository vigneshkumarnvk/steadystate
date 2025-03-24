public with sharing class AdminSetupController {

    public AdminSetupController() {

    }

    public PageReference scheduleTMSignatureProcess() {
        try {
            String cron = '0 0 0/1 1/1 * ? *'; //hourly
            TMSignatureProcessSchedulable schedulable = new TMSignatureProcessSchedulable();
            String jobId = system.schedule('TMSignatureProcessSchedulable', cron, schedulable);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The apex class is scheduled successfully.'));
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference scheduleRollupCustomerRevenue() {
        try {
            String cron = '0 15 21 1/1 * ? *'; //daily at 21:15
            //RollupCustomerRevenueScheduable schedulable = new RollupCustomerRevenueScheduable();
            RollupCustomerRevenueSchedulable schedulable = new RollupCustomerRevenueSchedulable();
            String jobId = system.schedule('RollupCustomerRevenueScheduable', cron, schedulable);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The apex class is scheduled successfully.'));
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference scheduleRollupAR() {
        try {
            String cron = '0 0 22 1/1 * ? *'; //daily at 22:00
            RollupARScheduable schedulable = new RollupARScheduable();
            String jobId = system.schedule('RollupARScheduable', cron, schedulable);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The apex class is scheduled successfully.'));
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference scheduleCoupaSalesOrderLookupValue() {
        try {
            String cron = '0 0 0/1 1/1  ?'; //hourly
            CoupaSalesOrderLookupValueSchedule schedulable = new CoupaSalesOrderLookupValueSchedule();
            String jobId = system.schedule('CoupaSalesOrderLookupValueSchedule', cron, schedulable);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The apex class is scheduled successfully.'));
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference scheduleCoupaPurchOrderPull() {
        try {
            String cron = '0 0 0/1 1/1  ?'; //hourly
            CoupaPurchOrderPullSchedule schedulable = new CoupaPurchOrderPullSchedule();
            String jobId = system.schedule('CoupaPurchOrderPullSchedule', cron, schedulable);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The apex class is scheduled successfully.'));
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference scheduleCoupaEquipmentAssetLookupValue() {
        try {
            String cron = '0 0 0/1 1/1  ?'; //hourly
            CoupaEquipmentAssetLookupValueSchedule schedulable = new CoupaEquipmentAssetLookupValueSchedule();
            String jobId = system.schedule('CoupaEquipmentAssetLookupValueSchedule', cron, schedulable);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The apex class is scheduled successfully.'));
        }
        catch(exception ex) {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference scheduleKronosTimeClockBatch() {
        try{
            String cron = '0 0 2 1/1 * ? *'; //daily at 2:00
            KronosTimeClockSchedule schedulable = new KronosTimeClockSchedule();
            String jobId = System.schedule('KronosTimeClockSchedule', cron, schedulable);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The apex class is scheduled successfully.'));
        } catch (Exception ex){
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference scheduleKronosTimeClockBatchMonday() {
        try{
            String cron = '0 0 10 ? * MON'; //Monday at 10:00
            KronosTimeClockSchedule schedulable = new KronosTimeClockSchedule();
            String jobId = System.schedule('KronosTimeClockScheduleMonday', cron, schedulable);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The apex class is scheduled successfully.'));
        } catch (Exception ex){
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference executeKronosTimeClockBatch() {
        try{
            GenerateKronosTimeClockBatch kronosTimeClockBatch = new GenerateKronosTimeClockBatch();
            Database.executeBatch(kronosTimeClockBatch, 1);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Kronos Time Clock Batch is successfully executed'));
        } catch (Exception ex){
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public PageReference executeWorkOrderQuoteBatch() {
        try{
            CreateWorkOrderQuoteOpenSOBatch workOrderQuoteBatch = new CreateWorkOrderQuoteOpenSOBatch();
            Database.executeBatch(workOrderQuoteBatch, 10);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Work Order Quote Batch is successfully executed'));
        } catch (Exception ex){
            ApexPages.addMessages(ex);
        }
        return null;
    }

    
    public PageReference executeContractBillingProjectBatch() {
        try{
            CreateContractBillingProjectBatch contractBillingProjectBatch = new CreateContractBillingProjectBatch();
            Database.executeBatch(contractBillingProjectBatch, 10);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Contract Billing Project Batch is successfully executed'));
        } catch (Exception ex){
            ApexPages.addMessages(ex);
        }
        return null;
    }

}