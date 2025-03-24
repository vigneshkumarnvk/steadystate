global with sharing class SalesLinesService {
    global static Sales_Line__c newSalesLine(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, String category, Integer lineNo) {
        return service().newSalesLine(salesOrder, jobTask, category, lineNo);
    }

    global static Sales_Line__c validateCategory(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        Id salesLineId = salesLine.Id;
        salesLine = service().newSalesLine(salesOrder, salesLine.Sales_Order_Job_Task__r, salesLine.Category__c, salesLine.Line_No__c.intValue());
        salesLine.Id = salesLineId;
        return  salesLine;
    }

    global static void validateResourceType(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        service().assignDescription(salesOrder, salesLine);
        if (salesLine.Unit_of_Measure__c == null) {
            service().assignUnitOfMeasure(salesOrder, salesLine);
        }
        service().assignResourceTypeUOM(salesLine);
        if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
            salesLine.UOM_Qty__c = 0;
            if (salesLine.Unit_of_Measure__r != null) {
                if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                    if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                        salesLine.UOM_Qty__c = TimeUtils.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                    }
                }
            }
        }
        service().calcUnitPrice(salesOrder, salesLine);
        service().calcUnitCost(salesOrder, salesLine);
        service().assignTaxPercent(salesOrder, salesLine);
        service().calculateLineTotals(salesOrder, salesLine);
    }

    global static void validateResource(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        service().assignDescription(salesOrder, salesLine);
        if (salesLine.Unit_of_Measure__c == null) {
            service().assignUnitOfMeasure(salesOrder, salesLine);
        }
        service().assignResourceUOM(salesLine);
        service().calcUnitPrice(salesOrder, salesLine);
        service().calcUnitCost(salesOrder, salesLine);
        service().assignTaxPercent(salesOrder, salesLine);
        service().calculateLineTotals(salesOrder, salesLine);
    }

    global static void validateUnitOfMeasure(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        service().calcUnitPrice(salesOrder, salesLine);
        service().calcUnitCost(salesOrder, salesLine);
        service().assignTaxPercent(salesOrder, salesLine);
        if (salesLine.Category__c != 'Subcontractors') {
            service().assignDescription(salesOrder, salesLine);
        }
        service().calculateLineTotals(salesOrder, salesLine);
    }

    global static void assignDescription(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        service().assignDescription(salesOrder, salesLine);
    }

    global static void calculateLineTotals(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                service().calculateLineTotals(salesOrder, salesLine);
            }
        }
    }
    global static void calculateLineTotals(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper) {
        calculateLineTotals(salesOrder, new List<ACVSalesOrderJobTaskWrapper>{ jobTaskWrapper });
    }

    global static void calculateLineTotals(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        jobTaskWrapper.SalesLines.add(salesLine);
        calculateLineTotals(salesOrder, jobTaskWrapper);
    }

    global static void calculatePriceInfo(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                service().calcUnitPrice(salesOrder, salesLine);
                service().calcUnitCost(salesOrder, salesLine);
                service().assignTaxPercent(salesOrder, salesLine);
                service().assignDescription(salesOrder, salesLine);
                service().calculateLineTotals(salesOrder, salesLine);
            }
        }
    }

    global static void calculatePriceInfo(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper) {
        calculatePriceInfo(salesOrder, new List<ACVSalesOrderJobTaskWrapper>{ jobTaskWrapper });
    }

    global static void calculatePriceInfo(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        jobTaskWrapper.SalesLines.add(salesLine);
        calculatePriceInfo(salesOrder, jobTaskWrapper);
    }

    global static void explodeSalesLineDetails(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        if (containsCategory(jobTaskWrappers, new Set<String>{ 'Labor', 'Equipment' })) {
            service().explodeSalesLineDetails(salesOrder, jobTaskWrappers);
        }
    }
    global static void explodeSalesLineDetails(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper) {
        explodeSalesLineDetails(salesOrder, new List<ACVSalesOrderJobTaskWrapper>{ jobTaskWrapper });
    }
    global static Sales_Line__c explodeSalesLineDetails(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        jobTaskWrapper.SalesLines.add(salesLine);
        explodeSalesLineDetails(salesOrder, jobTaskWrapper);
        return jobTaskWrapper.SalesLines[0]; //sales line is initialized as a new object in explodeSalesLineDetails function.
    }
    //equipment schedule lines <<
    global static List<Sales_Line__c> explodeSalesLineDetails(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines) {
        ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        jobTaskWrapper.SalesLines = salesLines;
        explodeSalesLineDetails(salesOrder, jobTaskWrapper);
        return jobTaskWrapper.SalesLines;
    }
    //equipment schedule lines >>

    global static void recalculateSalesLineDetails(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers, Boolean recalculateHours) {
        if (containsCategory(jobTaskWrappers, new Set<String>{ 'Labor', 'Equipment'})) {
            service().recalculateSalesLineDetails(salesOrder, jobTaskWrappers, recalculateHours);
        }
    }
    global static void recalculateSalesLineDetails(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Boolean recalculateHours) {
        recalculateSalesLineDetails(salesOrder, new List<ACVSalesOrderJobTaskWrapper>{ jobTaskWrapper }, recalculateHours);
    }
    global static Sales_Line__c recalculateSalesLineDetails(Sales_Order__c salesOrder, Sales_Line__c salesLine, Boolean recalculateHours) {
        ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        jobTaskWrapper.SalesLines.add(salesLine);
        recalculateSalesLineDetails(salesOrder, jobTaskWrapper, recalculateHours);
        return jobTaskWrapper.SalesLines[0];
    }

    //recalculate lines on contract change 10.16.2020 <<
    global static void recalculateSalesLines(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        service().recalculateSalesLines(salesOrder, jobTaskWrappers);
    }

    //contract pricing fix 11.10.2020 <<
    global static void assignUnitOfMeasure(Sales_Line__c salesLine) {
        service().assignUnitOfMeasure(salesLine);
    }
    //contract pricing fix 11.10.2020 >>

    global static void calculateLumpSumLine(Sales_Line__c lumpSumLine, Sales_Order__c salesOrder, List<Sales_Line__c> salesLines, Boolean overwriteUnitPrice) {
        service().calculateLumpSumLine(lumpSumLine, salesOrder, salesLines, overwriteUnitPrice);
    }

    global static void initStaticVariables(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        service().initStaticVariables(salesOrder, jobTaskWrappers);
    }
    global static void initStaticVariables(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper) {
        initStaticVariables(salesOrder, new List<ACVSalesOrderJobTaskWrapper>{ jobTaskWrapper });
    }
    global static void initStaticVariables(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
        jobTaskWrapper.SalesLines.add(salesLine);
        initStaticVariables(salesOrder, new List<ACVSalesOrderJobTaskWrapper>{ jobTaskWrapper });
    }

    //ticket 19130 05.13.2023 <<
    /*
    global static List<Sales_Line__c> calculatePresumptiveChildLines(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, Sales_Line__c salesLine, Integer nextSalesLineNo) {
        return service().calculatePresumptiveChildLines(salesOrder, jobTask, salesLine, nextSalesLineNo);
    }
    */
    global static Sales_Line__c calculatePresumptiveChildLines(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Sales_Line__c salesLine, Integer nextSalesLineNo) {
        return service().calculatePresumptiveChildLines(salesOrder, jobTaskWrapper, salesLine, nextSalesLineNo);
    }
    //ticket 19130 05.13.2023 >>

    global static void calculateSurchargeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo) {
        service().calculateSurchargeLine(salesOrder, jobTaskWrapper, nextSalesLineNo);
    }

    global static void calculateManifestFeeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo) {
        service().calculateManifestFeeLine(salesOrder, jobTaskWrapper, nextSalesLineNo);
    }

    global static void calculateRinseOutFeeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo) {
        service().calculateRinseOutFeeLine(salesOrder, jobTaskWrapper, nextSalesLineNo);
    }

    global static void updateTotals(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers){
        service().updateTotals(salesOrder, jobTaskWrappers);
    }
    
    global static void assignResourceTypeUOM(Sales_Line__c salesLine) {
        service().assignResourceTypeUOM(salesLine);
    }

    global static void assignResourceUOM(Sales_Line__c salesLine) {
        service().assignResourceUOM(salesLine);
    }

    /*
        Ticket#17051 - remove service().initStaticVariables(new Map<Sales_Order__c, List<Sales_Line__c>>{ salesOrder => new List<Sales_Line__c>{ salesLine }});
                       it cause query 101 error
     */
    global static void calcUnitPrice(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        service().calcUnitPrice(salesOrder, salesLine);
    }

    //Ticket#19663
    global static void calcUnitCost(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                service().calcUnitCost(salesOrder, salesLine);
            }
        }
    }

    global static void calcUnitCost(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        service().calcUnitCost(salesOrder, salesLine);
    }

    global static void calcLaborUnitPrice(Sales_Order__c salesOrder, Sales_Line__c salesLine){
        service().calcLaborUnitPrice(salesOrder, salesLine);
    }

    private static ISalesLinesService service() {
        return (ISalesLinesService) Application.Service.newInstance(ISalesLinesService.class);
    }

    private static Boolean containsCategory(List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers, Set<String> categories) {
        Boolean contains = false;
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                if (categories.contains(salesLine.Category__c)) {
                    contains = true;
                    break;
                }
            }
        }
        return contains;
    }
}