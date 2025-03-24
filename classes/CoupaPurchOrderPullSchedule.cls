global class CoupaPurchOrderPullSchedule implements Schedulable, Database.AllowsCallouts {
    global void execute(SchedulableContext sc){
        CoupaIntegrationService.getPurchaseOrder();
    }
}