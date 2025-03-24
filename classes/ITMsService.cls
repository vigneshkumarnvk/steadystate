public interface ITMsService {
    String createSalesInvoice(Id salesOrderId, Set<Id> TMIds, Set<Id> TMLIds, String invoiceNote);
    void addLinesToSalesInvoiceAsync(Id salesInvoice, Set<Id> TMLIds);
    void addSurchargeLineToSalesInvoiceAsync(Id salesInvoice);

    //job task <<
    ACVTMWrapper createTMFromSalesOrder(Id salesOrderId, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers);
    //ticket 19130 <<
    //List<ACVTMJobTaskWrapper> createTMJobTasksFromSalesOrder(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers, TM__c tm, Integer nextJobTaskLineNo, Integer nextTMLineNo);
    List<ACVTMJobTaskWrapper> createTMJobTasksFromSalesOrder(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers, TM__c tm, List<ACVTMJobTaskWrapper> tmJobTaskWrappers, Integer nextJobTaskLineNo, Integer nextTMLineNo);
    //ticket 19130 >>
    //ticket 19130 05.13.2023 <<
    void calculateChildResources(TM__c tm, List<ACVTMJobTaskWrapper> jobTaskWrappers);
    //ticket 19130 05.13.2023 >>

    void createTMLinesFromSalesOrder(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper, TM__c tm, ACVTMJobTaskWrapper tmJobTaskWrapper, Integer lastTMLineNo);
    //job task >>
}