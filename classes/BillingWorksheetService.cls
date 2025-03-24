global with sharing class BillingWorksheetService {

    private static IBillingWorksheetService service() {
        return (IBillingWorksheetService) Application.Service.newInstance(IBillingWorksheetService.class);
    }

    global static void initStaticVariables(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers) {
        service().initStaticVariables(salesOrderId, worksheetWrappers);
    }

    global static void initStaticVariables(Id salesOrderId, BillingWorksheetWrapper worksheetWrapper) {
        initStaticVariables(salesOrderId, new List<BillingWorksheetWrapper>{
                worksheetWrapper
        });
    }

    global static void initStaticVariables(Id salesOrderId, List<Billing_Worksheet_Line__c> worksheetLines) {
        BillingWorksheetWrapper worksheetWrapper = new BillingWorksheetWrapper();
        worksheetWrapper.WorksheetLines = worksheetLines;
        initStaticVariables(salesOrderId, new List<BillingWorksheetWrapper>{
                worksheetWrapper
        });
    }

    //Ticket#19663
    global static void initStaticVariables(Id salesOrderId, List<Billing_Worksheet_Line__c> worksheetLines, Id payRuleId, Boolean isPayRuleCostUpdateCall){
        BillingWorksheetWrapper worksheetWrapper = new BillingWorksheetWrapper();
        worksheetWrapper.WorksheetLines = worksheetLines;
        worksheetWrapper.PayRuleId = payRuleId;
        worksheetWrapper.IsPayRuleCostUpdateCall = isPayRuleCostUpdateCall;
        initStaticVariables(salesOrderId, new List<BillingWorksheetWrapper>{
                worksheetWrapper
        });
    }

    global static void populateLinesInfo(Id salesOrderId, List<Billing_Worksheet_Line__c> worksheetLines) {
        service().calculateLaborHours(salesOrderId, worksheetLines);
        for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
            service().calcUnitPrice(salesOrderId, worksheetLine);
            service().calcUnitCost(salesOrderId, worksheetLine);
            service().assignTaxPercent(salesOrderId, worksheetLine);
            //service().assignDescription(salesOrderId, worksheetLine);
            service().calculateLineTotals(worksheetLine, true);
        }
        //DE37077
        service().populateWasteDisposalLineInfo(worksheetLines);
    }

    //ticket 19130 << temporary disable, not needed for this phase
    /*
    global static List<Billing_Worksheet_Line__c> calculatePresumptiveChildLines(Billing_Worksheet_Line__c worksheetLine, Integer nextWorksheetLineNo) {
        return service().calculatePresumptiveChildLines(worksheetLine, nextWorksheetLineNo);
    }
    */

    //global static Sales_Invoice__c createSalesInvoice(Id salesOrderId, List<Billing_Worksheet_Line__c> worksheetLines) {
    global static Sales_Invoice__c createSalesInvoice(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers) {
        initStaticVariables(salesOrderId, worksheetWrappers);
        service().validateSalesInvoice(salesOrderId, worksheetWrappers);
        return service().createSalesInvoice(salesOrderId, worksheetWrappers);
    }

    global static void validateResourceType(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        service().assignResourceTypeUOM(worksheetLine);
        service().calcUnitPrice(salesOrderId, worksheetLine);
        service().calcUnitCost(salesOrderId, worksheetLine);
        service().assignTaxPercent(salesOrderId, worksheetLine);
        service().assignDescription(salesOrderId, worksheetLine);
        service().calculateLineTotals(worksheetLine, true);
    }

    global static void validateResource(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        service().assignResourceUOM(worksheetLine);
        service().calcUnitPrice(salesOrderId, worksheetLine);
        service().calcUnitCost(salesOrderId, worksheetLine);
        service().assignTaxPercent(salesOrderId, worksheetLine);
        service().assignDescription(salesOrderId, worksheetLine);
        service().calculateLineTotals(worksheetLine, true);
    }

    global static void validateContractLine(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine){
        service().validateContractLine(salesOrderId, worksheetLine);
        service().assignTaxPercent(salesOrderId, worksheetLine);
        service().assignDescription(salesOrderId, worksheetLine);
        service().calculateLineTotals(worksheetLine, true);
    }

    /*
    global static void calculatePriceAndCost(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        service().calcUnitPrice(salesOrderId, worksheetLine);
        service().calcUnitCost(salesOrderId, worksheetLine);
        //service().assignTaxPercent(salesOrderId, worksheetLine);
        service().calculateLineTotals(worksheetLine);
    }*/

    global static void calculatePriceAndCost(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        service().calcUnitPrice(salesOrderId, worksheetLine);
        service().calcUnitCost(salesOrderId, worksheetLine);
        service().assignTaxPercent(salesOrderId, worksheetLine);
        // service().assignDescription(salesOrderId, worksheetLine);
        service().calculateLineTotals(worksheetLine, true);
    }

    global static void calculatePriceAndCost(Id salesOrderId, List<BillingWorksheetWrapper> worksheets) {
        for (BillingWorksheetWrapper worksheet : worksheets) {
            for (Billing_Worksheet_Line__c worksheetLine : worksheet.WorksheetLines) {
                service().calcUnitPrice(salesOrderId, worksheetLine);
                service().calcUnitCost(salesOrderId, worksheetLine);
                service().assignTaxPercent(salesOrderId, worksheetLine);
                service().assignDescription(salesOrderId, worksheetLine);
                service().calculateLineTotals(worksheetLine, true);
            }
        }
    }

    global static void assignTaxPercent(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        service().assignTaxPercent(salesOrderId, worksheetLine);
        service().calculateLineTotals(worksheetLine, true);
    }

    /*
        Ticket#19500
        Update Billing Worksheet Line tax info when Sales Order tax info changed.
    */
    global static void calculateLineTax(List<Sales_Order__c> salesOrders){
        Map<Id, Sales_Order__c> salesOrderbyIds = new Map<Id, Sales_Order__c>(salesOrders);
        List<Billing_Worksheet_Line__c> billingWorksheetLines = BillingWorksheetLinesSelector.newInstance().selectOpenLinesBySalesOrderId(salesOrderbyIds.keySet());
        for(Billing_Worksheet_Line__c billingWorksheetLine:billingWorksheetLines) {
            Sales_Order__c salesOrder = salesOrderbyIds.get(billingWorksheetLine.Sales_Order__c);
            if (salesOrder.Tax_Liable__c && billingWorksheetLine.Tax_Group__c != null) {
                billingWorksheetLine.Tax_Pct__c = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, billingWorksheetLine.Tax_Group__c);
            } else {
                billingWorksheetLine.Tax_Pct__c = 0;
            }
            service().calculateLineTotals(billingWorksheetLine, false);
        }
        CompanyMgmt.systemCall = true;
        update billingWorksheetLines;
    }

    /*
        Ticket#19820
        Update Billing Worksheet Line Unit Price and Total when Sales Order Type changed.
     */
    global static void validateSalesOrderType(Sales_Order__c salesOrder){
        List<Billing_Worksheet_Line__c> billingWorksheetLines = BillingWorksheetLinesSelector.newInstance().selectOpenLinesBySalesOrderId(new Set<Id>{salesOrder.Id});
        initStaticVariables(salesOrder.Id, billingWorksheetLines);
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            service().calcUnitPrice(salesOrder.Id, billingWorksheetLine);
            service().calculateLineTotals(billingWorksheetLine, false);
        }
        CompanyMgmt.systemCall = true;
        update billingWorksheetLines;
    }

    global static void calculateLaborHours(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        List<Billing_Worksheet_Line__c> worksheetLines = new List<Billing_Worksheet_Line__c>{ worksheetLine };
        service().calculateLaborHours(salesOrderId, worksheetLines);
        worksheetLine = worksheetLines[0];
        service().calculateLineTotals(worksheetLine, true);
    }

    //Ticket#20496 >>
    global static void calculateLaborHours(Id salesOrderId, List<Billing_Worksheet_Line__c> billingWorksheetLines){
        initStaticVariables(salesOrderId, billingWorksheetLines);
        service().calculateLaborHours(salesOrderId, billingWorksheetLines);
    }

    global static void calculateLaborHours(Id salesOrderId, List<Billing_Worksheet_Line__c> billingWorksheetLines, Billing_Worksheet_Line__c updatedWorksheetLine){
        initStaticVariables(salesOrderId, billingWorksheetLines);
        service().calculateLaborHours(salesOrderId, billingWorksheetLines, updatedWorksheetLine);
    }
    //Ticket#20496 <<

    global static void calculateUnitCost(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine, Boolean initStaticVariable){
        if(initStaticVariable == true){
            initStaticVariables(salesOrderId, new List<Billing_Worksheet_Line__c>{worksheetLine});
        }
        service().calcUnitCost(salesOrderId, worksheetLine);
    }

    //Ticket#19663 >>
    global static void calculateUnitCost(Id salesOrderId, List<Billing_Worksheet_Line__c> billingWorksheetLines, Boolean initStaticVariable, Id payRuleId, Boolean isPayRuleCostUpdateCall){
        if(initStaticVariable == true){
            initStaticVariables(salesOrderId, billingWorksheetLines, payRuleId, isPayRuleCostUpdateCall);
        }
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            service().calcUnitCost(salesOrderId, billingWorksheetLine);
            calculateLineTotals(billingWorksheetLine, false);
        }
    }

    global static void calculateLineTotals(Billing_Worksheet_Line__c worksheetLine) {
        service().calculateLineTotals(worksheetLine, true);
    }

    //Ticket#19663 >>
    global static void calculateLineTotals(Billing_Worksheet_Line__c worksheetLine, Boolean reCalCostQty) {
        service().calculateLineTotals(worksheetLine, reCalCostQty);
    }

    global static void rollupBundledLines(List<Billing_Worksheet_Line__c> worksheetLines) {
        Map<Integer, Billing_Worksheet_Line__c> mapLumpSumLinesByLineNo = new Map<Integer, Billing_Worksheet_Line__c>();
        Map<Integer, List<Billing_Worksheet_Line__c>> mapBundledLinesByParentLineNo = new Map<Integer, List<Billing_Worksheet_Line__c>>();
        for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
            if (worksheetLine.Category__c == 'Bundled') {
                mapLumpSumLinesByLineNo.put(worksheetLine.Line_No__c.intValue(), worksheetLine);
            }

            if (worksheetLine.Bundle_Line__r != null) {
                Integer parentLineNo = worksheetLine.Bundle_Line__r.Line_No__c.intValue();
                List<Billing_Worksheet_Line__c> bundledLines;
                if (mapBundledLinesByParentLineNo.containsKey(parentLineNo)) {
                    bundledLines = mapBundledLinesByParentLineNo.get(parentLineNo);
                } else {
                    bundledLines = new List<Billing_Worksheet_Line__c>();
                    mapBundledLinesByParentLineNo.put(parentLineNo, bundledLines);
                }
                bundledLines.add(worksheetLine);
            }
        }

        for (Integer parentLineNo : mapBundledLinesByParentLineNo.keySet()) {
            Decimal rollupAmount = 0;
            List<Billing_Worksheet_Line__c> bundledWorksheetLines = mapBundledLinesByParentLineNo.get(parentLineNo);
            for (Billing_Worksheet_Line__c worksheetLine : bundledWorksheetLines) {
                rollupAmount += (worksheetLine.xLine_Amount__c != null ? worksheetLine.xLine_Amount__c : 0);
            }

            if (mapLumpSumLinesByLineNo.containsKey(parentLineNo)) {
                Billing_Worksheet_Line__c lumpSumLine = mapLumpSumLinesByLineNo.get(parentLineNo);
                lumpSumLine.Rolled_up_Unit_Price__c = rollupAmount;
                service().calculateLineTotals(lumpSumLine, true);
            }
        }
    }

    global static Integer calcWorksheetLinesPricing(Sales_Order__c salesOrder){
        Integer recordCount = 0;
        List<TM__c> tms = TMsSelector.newInstance().selectOpenTMsBySalesOrderIdWithLines(salesOrder.Id);
        if(tms.size() > 0) {
            BillingWorksheetWrapper billingWorksheetWrapper = new BillingWorksheetWrapper();
            List<BillingWorksheetWrapper.RelatedInfo> relatedInfos = new List<BillingWorksheetWrapper.RelatedInfo>();
            //Ticket#24525
            Map<TM__c, List<TM_Line__c>> tmLinesByTMs = new Map<TM__c, List<TM_Line__c>>();
            Map<Id, TM__c> tmsByIds = new Map<Id, TM__c>();
            for (TM__c tm : tms) {
                //tm.Contract__c = salesOrder.Contract__c; //Ticket#24525
                tm.From_Sales_Quote__c = salesOrder.From_Sales_Quote__c;
                BillingWorksheetWrapper.RelatedInfo relatedInfo = new BillingWorksheetWrapper.RelatedInfo();
                relatedInfo.TM = tm;
                relatedInfos.add(relatedInfo);

                //Ticket#24525 >>
                //if(tm.Contract__c != salesOrder.Contract__c){
                tm.Contract__c = salesOrder.Contract__c;
                tmsByIds.put(tm.Id, tm);
                tmLinesByTMs.put(tm, tm.TM_Lines__r);
                //System.debug('Info: TMs with different contract: ' + tm.Name + ' -- ' + tm.Contract__c + ' SO contract: ' + salesOrder.Contract__c);
                //}
                //Ticket#24525 <<
            }
            List<Billing_Worksheet_Line__c> billingWorksheetLines = BillingWorksheetLinesSelector.newInstance().selectOpenLinesBySalesOrderId(new Set<Id>{salesOrder.Id});
            if(billingWorksheetLines.size() > 0) {
                billingWorksheetWrapper.relatedInfos = relatedInfos;
                billingWorksheetWrapper.WorksheetLines = billingWorksheetLines;
                service().initStaticVariables(salesOrder.Id, new List<BillingWorksheetWrapper>{
                        billingWorksheetWrapper
                });

                service().calculateLaborHours(salesOrder.Id, billingWorksheetLines);
                for (Billing_Worksheet_Line__c worksheetLine : billingWorksheetLines) {
                    worksheetLine.Contract_Line__c = null;
                    worksheetLine.Sales_Line__c = null;
                    service().calcUnitPrice(salesOrder.Id, worksheetLine);
                    service().calcUnitCost(salesOrder.Id, worksheetLine);
                    service().assignTaxPercent(salesOrder.Id, worksheetLine);
                    service().assignDescription(salesOrder.Id, worksheetLine); //Ticket#24525
                    service().calculateLineTotals(worksheetLine, true); 
                }
            }

            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            
            update tms;
            //Ticket#24525 >>
            if(tmsByIds.size() > 0){
                List<TM_Line__c> tmLinesToUpdate = new List<TM_Line__c>();
                TMLLinesService.initStaticVariables(tmLinesByTMs);
                for(TM__c tm : tmLinesByTMs.keySet()){
                    for(TM_Line__c tmLine : tmLinesByTMs.get(tm)){
                        tmLine.Sales_Line__c = null; //Ticket#24869 force system to re-calculate sales line.
                        tmLine.Contract_Line__c = null; //Ticket#24869 force system to re-calculate contract line.
                        TMLLinesService.validateUnitOfMeasure(tm, tmLine, false);
                        tmLinesToUpdate.add(tmLine);
                    }
                }
                if(tmLinesToUpdate.size() > 0) {
                    recordCount += tmLinesToUpdate.size();                    
                    update tmLinesToUpdate;
                    CompanyMgmt.byPassLineTrigger = false;
                    CompanyMgmt.byPassTrigger = false;
                }
            }
            //Ticket#24525 <<

            if (billingWorksheetLines.size() > 0) {
                CompanyMgmt.systemCall = true;
                recordCount += billingWorksheetLines.size();
                update billingWorksheetLines;
            }
        }
        return recordCount;
    }

    /*
     *  Ticket#24817
     */
    global static void reopenKronosProcessedTMLinesByIds(Set<Id> tmLinesIds){
        List<TM_Line__c> tmLines = [SELECT Id, Kronos_Integration_Note__c, KronosTimeEntriesProcessed__c
        FROM TM_Line__c
        WHERE Id IN :tmLinesIds AND Category__c = :ResourceService.LABOR_CATEGORY AND KronosTimeEntriesProcessed__c = TRUE];
        for(TM_Line__c tmLine : tmLines){
            tmLine.KronosTimeEntriesProcessed__c = false;
            tmLine.Kronos_Integration_Note__c = System.today() + ' TM line reopen, due to resource type change in billing worksheet';
        }

        if(tmLines.size() > 0){
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            update tmLines;
            CompanyMgmt.byPassTrigger = false;
            CompanyMgmt.byPassLineTrigger = false;
        }
    }

}