public interface ISalesOrdersService {
    //job task <<
    //void calcEstimatedDateInfo(Sales_Order__c theSO, List<Sales_Line__c> theSLList, Integer duration);
    void calcEstimatedDateInfo(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers, Integer duration);
    //job task >>
    void updateSalesLinesForBillAsLumpSumAllAction(List<Sales_Line__c> theSLList);
    Sales_Order__c createNewSalesQuoteOrSalesOrder(String documentType, Id billToCustomerId, String serviceCenter, String contract, String quote);
    void updateSalesOrderBillingAndTax(Sales_Order__c theSO, Boolean isNewSO);
    //job task <<
    //String cloneSalesOrder(Set<Id> salesOrderIds, String documentType, String serviceCenter, String billToCustomer, Id billToParentId);
    String cloneSalesOrder(Set<Id> salesOrderIds, String documentType, String serviceCenter, String billToCustomer, Id billToParentId, String jobDescription, String poNumber);
    //job task >>
    String convertQuoteToOrder(Set<Id> salesOrderIds);
    void setSurchargePct(Sales_Order__c salesOrder);

    //ticket 19672 <<
    //void addRemoveSurchargeLine(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines);
    //void addRemoveManifestFeeLines(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines); //Ticket#15225
    //ticket 19672 >>

    //void createManifestFeeLines(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines); //Ticket#15225
    //deprecated <<
    //void prepareManifestFeeLines(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines, List<Sales_Line__c> wasteDisposalLines, Integer currentLineNo);
    //deprecated >>
    void updateSQWhenNewSOCreated(Id salesQuoteId);

    //aura <<
    //Decimal calcSurchargeAmount(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines);

    //ticket 19672 <<
    //void calcSurchargeAmount(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines);
    void calcSurchargeAmount(Sales_Order__c salesOrder, List<Sales_Order_Job_Task__c> jobTasks, List<Sales_Line__c> salesLines);
    void calcJobTaskAmountFields(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, List<Sales_Line__c> salesLines, Decimal taxPct);
    //ticket 19672 >>

    void updateTMAndSISuperUserChangeBTC(Sales_Order__c theSO);
    Integer updateTMPriceFromSO(Sales_Order__c theSO, List<TM__c> tms);
    //aura >>

    //job task <<
    void createSalesLinesFromJobTaskTemplateLines(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo, List<Job_Task_Template_Line__c> jobTaskTemplateLines);
    void cloneJobTask(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper fromJobTaskWrapper, ACVSalesOrderJobTaskWrapper newJobTaskWrapper, Integer nextSalesLineNo);
    //job task >>
}