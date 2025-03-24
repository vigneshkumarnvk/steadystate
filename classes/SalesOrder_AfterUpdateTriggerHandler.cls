public class SalesOrder_AfterUpdateTriggerHandler extends TriggerHandlerBase{
    public override void mainEntry(){ 
        System.debug('SalesOrder_AfterUpdateTriggerHandler >> mainEntry()');
         if(CompanyMgmt.byPassTrigger != true){
            fflib_SObjectDomain.triggerHandler(SalesOrders.class);
         }
    }
}