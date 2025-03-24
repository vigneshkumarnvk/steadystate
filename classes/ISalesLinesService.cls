public interface ISalesLinesService {
    //aura <<
    //job task <<
    //void assignDescription(Sales_Line__c salesLine);
    void assignDescription(Sales_Order__c salesOrder, Sales_Line__c salesLine);
    //job task >>
    void assignUnitOfMeasure(Sales_Line__c salesLine);
    void assignUnitOfMeasure(Sales_Order__c salesOrder, Sales_Line__c salesLine);
    void assignTaxPercent(Sales_Order__c salesOrder, Sales_Line__c salesLine);
    void calculateLineTotals(Sales_Order__c salesOrder, Sales_Line__c salesLine);
    //job task <<
    //Sales_Line__c newSalesLine(Sales_Order__c salesOrder, String category, Integer lineNo);
    //void explodeSalesLineDetails(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines);
    //void recalculateSalesLineDetails(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines, Boolean calculateHours);
    //void initStaticVariables(Map<Sales_Order__c, List<Sales_Line__c>> salesLinesByOrders);
    void initStaticVariables(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers);
    Sales_Line__c newSalesLine(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, String category, Integer nextSalesLineNo);
    void explodeSalesLineDetails(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers);
    void recalculateSalesLineDetails(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers, Boolean recalculateHours);

    //ticket 19130 05.13.2023 <<
    //List<Sales_Line__c> calculatePresumptiveChildLines(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, Sales_Line__c parentLine, Integer nextSalesLineNo);
    Sales_Line__c calculatePresumptiveChildLines(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Sales_Line__c parentLine, Integer nextSalesLineNo);
    //ticket 19130 05.13.2023 >>

    //calculate lines on contract change 10.16.2020 <<
    void recalculateSalesLines(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers); 
    void calculateLumpSumLine(Sales_Line__c lumpSumLine, Sales_Order__c salesOrder, List<Sales_Line__c> salesLines, Boolean overwriteUnitPrice);
    //calculate lines on contract change 10.16.2020 >>
    //job task >>
    //aura >>
    void assignResourceTypeUOM(Sales_Line__c salesLine);
    void assignResourceUOM(Sales_Line__c salesLine);
    void calcUnitPrice(Sales_Order__c salesOrder, Sales_Line__c salesLine);
    void calcUnitCost(Sales_Order__c salesOrder, Sales_Line__c salesLine);

    //job task <<
    //void updateTotals(Map<Sales_Order__c, List<Sales_Line__c>> salesLinesByOrders);
    //void populateLinesInfo(Map<Sales_Order__c, List<Sales_Line__c>> salesLinesByOrders);
    void updateTotals(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers);
    //job task >>
    void calcLaborUnitPrice(Sales_Order__c salesOrder, Sales_Line__c salesLine);

    //job task <<
    void calculateSurchargeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo);
    void calculateManifestFeeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo);
    void calculateRinseOutFeeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo);
    //job task >>
}