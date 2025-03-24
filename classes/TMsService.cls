global with sharing class TMsService {
    //ticket 19916 <<
    global static Boolean ByPassCreatingBillingWorksheetLines;
    //ticket 19916 >>

    global static final String OPEN_STATUS = 'Open';
    global static final String SCHEDULED_STATUS = 'Scheduled';
    global static final String MOBILE_REVIEW_STATUS = 'Mobile Review';
    global static final String CONFIRMED_STATUS = 'Confirmed';
    /* Depreciated
    global static final String RECEIVED_BY_BILLING_STATUS = 'Received By Billing';
    global static final String READY_TO_BILL_STATUS = 'Ready to Bill';
    global static final String PARTIALLY_INVOICED_STATUS = 'Partially Invoiced';
     */
    global static final String FULLY_INVOICED_STATUS = 'Fully Invoiced';
    global static final String VOID_STATUS = 'Void';
    global static final String CLOSED_STATUS = 'Closed';
    global static Boolean PMReviewSetNullByTMLineUpdated = false; //Ticket#21817

    global static String createSalesInvoice(Id salesOrderId, Set<Id> TMIds, Set<Id> TMLids, String invoiceNote){
        return service().createSalesInvoice(salesOrderId, TMIds, TMLids, invoiceNote);
    }

    global static void addLinesToSalesInvoiceAsync(Id salesInvoice, Set<Id> TMLids){
        service().addLinesToSalesInvoiceAsync(salesInvoice, TMLids);
    }

    global static void addSurchargeLineToSalesInvoiceAsync(Id salesInvoice){
        service().addSurchargeLineToSalesInvoiceAsync(salesInvoice);
    }

    //Sales Order Route
    global static void updateTMDataWhenSalesOrderIsUpdated(List<Sales_Order__c> salesOrders){
        Map<Id, Sales_Order__c> salesOrdersByIds = new Map<Id, Sales_Order__c>(salesOrders);
        List<TM__c> tms = TMsSelector.newInstance().selectTMsBySalesOrderIds(salesOrdersByIds.keySet());
        for(TM__c tm : tms){
            tm.Prevailing_Wage_Job__c = salesOrdersByIds.get(tm.Sales_Order__c).Prevailing_Wage_Job__c;
        }

        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        update tms;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;
    }

    global static void validateRateSheet(TM__c tm, List<TM_Line__c> tmLines, Id rateSheetId){
        /*
        if(String.isNotBlank(rateSheetId)){
            List<Rate_Sheet__c> rateSheets = [SELECT Id, Name FROM Rate_Sheet__c WHERE Id = :rateSheetId];
            if(rateSheets.size() > 0){
                tm.Rate_Sheet__c = rateSheets[0].Id;
                tm.Rate_Sheet__r = rateSheets[0];
            } else {
                throw new DataException('Rate Sheet is not found with rate sheet id: ' + rateSheetId);
            }
        } else {
            tm.Rate_Sheet__c = null;
            tm.Rate_Sheet__r = null;
        }
        TMLLinesService.initStaticVariables(new Map<TM__c, List<TM_Line__c>>{tm => tmLines});
        for(TM_Line__c tmLine : tmLines){
            TMLLinesService.calcUnitPrice(tm, tmLine);
            TMLLinesService.calcUnitCost(tm, tmLine);
        }
        TMLLinesService.calcTotals(new Map<TM__c, List<TM_Line__c>>{tm => tmLines});
        System.debug('Info: Rate Sheet Info ' + tm.Rate_Sheet__r);
         */
    }

    global static void calcRinseOutFeeLine(TM__c tm, List<TM_Line__c> tmLines){
        /*
        Boolean addRinseOutLine = tm.Sales_Order__r.Charge_Rinse_Out_Fee__c;
        if(addRinseOutLine == true){
            upsertRinseOutFeeLine(tm, tmLines);
        } else {
            removeRinseOutFeeLine(tmLines);
        }
         */
    }

    global static ACVTMWrapper createTMFromSalesOrder(Id salesOrderId, List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers) {
        return service().createTMFromSalesOrder(salesOrderId, salesOrderJobTaskWrappers);
    }

    //ticket 19130 <<
    /*
    global static List<ACVTMJobTaskWrapper> createTMJobTasksFromSalesOrder(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers, TM__c tm, Integer lastJobTaskLineNo, Integer lastTMLineNo) {
        return service().createTMJobTasksFromSalesOrder(salesOrder, salesOrderJobTaskWrappers, tm, lastJobTaskLineNo, lastTMLineNo);
    }
    */
    global static List<ACVTMJobTaskWrapper> createTMJobTasksFromSalesOrder(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers, TM__c tm, List<ACVTMJobTaskWrapper> tmJobTaskWrappers, Integer lastJobTaskLineNo, Integer lastTMLineNo) {
        return service().createTMJobTasksFromSalesOrder(salesOrder, salesOrderJobTaskWrappers, tm, tmJobTaskWrappers, lastJobTaskLineNo, lastTMLineNo);
    }
    //ticket 19130 >>


    global static void createTMLinesFromSalesOrder(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper, TM__c tm, ACVTMJobTaskWrapper tmJobTaskWrapper, Integer lastTMLineNo) {
        service().createTMLinesFromSalesOrder(salesOrder, salesOrderJobTaskWrapper, tm, tmJobTaskWrapper, lastTMLineNo);
    }

    //ticket 19130 05.13.2023 <<
    global static void calculateChildResources(TM__c tm, List<ACVTMJobTaskWrapper> jobTaskWrappers) {
        service().calculateChildResources(tm, jobTaskWrappers);
    }
    //ticket 19130 05.13.2023 >>

    public static void createBillingWorksheetLines(Set<TM__c> tms) {
        CompanyMgmt.systemCall = true;
        Set<Id> tmIds = new Set<Id>();
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> salesLineIds = new Set<Id>();
        Set<Id> salesOrderJobTaskIds = new Set<Id>();
        Map<Id, Integer> mapNextLineNosBySalesOrderId = new Map<Id, Integer>();
        //Ticket#20496 >>
        Date earliestDate = null;
        Date latestDate = null;
        for (TM__c tm : tms) {
            tmIds.add(tm.Id);
            if (tm.Sales_Order__c != null) {
                salesOrderIds.add(tm.Sales_Order__c);
            }
            mapNextLineNosBySalesOrderId.put(tm.Sales_Order__c, 1);

            if(earliestDate == null && latestDate == null){
                earliestDate = tm.Scheduled_Date__c;
                latestDate = tm.Scheduled_Date__c;
            } else {
                if (tm.Scheduled_Date__c < earliestDate){
                    earliestDate = tm.Scheduled_Date__c;
                }
                if (tm.Scheduled_Date__c > latestDate){
                    latestDate = tm.Scheduled_Date__c;
                }
            }
        }

        Map<Date, Week_Number__c> weekNumberByStartingDate = new Map<Date, Week_Number__c>();
        if(earliestDate != null && latestDate != null){
            String earliestYearStr = String.valueOf(earliestDate.year());
            String latestYearStr = String.valueOf(latestDate.year());
            for(Week_Number__c weekNumber : [SELECT Id, Week_No__c, Week_Start_Date__c, Week_End_Date__c, Year__c, Name FROM Week_Number__c WHERE Year__c = :earliestYearStr OR Year__c = :latestYearStr]){
                weekNumberByStartingDate.put(weekNumber.Week_Start_Date__c, weekNumber);
            }
        }
        //Ticket#20496 <<

        if (salesOrderIds.size() == 0) {
            throw new DataException('TM must be associated with a sales order.');
        }

        Sales_Order__c salesOrder = SalesOrdersSelector.newInstance().selectById(salesOrderIds)[0];
        List<Sales_Line__c> salesLineList = [SELECT Id, Tax_Group__c,Tax_Pct__c FROM Sales_Line__c WHERE Sales_Order__c = :salesOrder.Id 
                                             AND System_Calculated_Line__c  = True AND Category__c = 'Waste Disposal' AND Description__c = 'Manifest Fee'];

        List<TM_Line__c> tmLines = TMLinesSelector.newInstance().selectWithFlatPaysByTmId(tmIds, new List<String>{ 'Invoiced__c != TRUE' });
        if (tmLines.size() == 0) { //nothing to create
            return;
        }

        Map<Id, TM_Line__c> mapTMLinesByTMId = new Map<Id, TM_Line__c>();
        for (TM_Line__c tmLine : tmLines) {
            mapTMLinesByTMId.put(tmLine.Id, tmLine);
            //Ticket#25514 >>
            if(String.isNotBlank(tmLine.Quote_Line__c)){
                if(tmLine.Quote_Line__r.Sales_Order__c != salesOrder.From_Sales_Quote__c){
                    tmLine.Quote_Line__c = null;
                }
            }
            if(String.isNotBlank(tmLine.Sales_Line__c)){
                if(tmLine.Sales_Line__r.Sales_Order__c != salesOrder.Id){
                    tmLine.Sales_Line__c = null;
                }
            }
            if(String.isNotBlank(tmLine.Contract_Line__c)){
                if(tmLine.Contract_Line__r.Contract__c != salesOrder.Contract__c){
                    tmLine.Contract_Line__c = null;
                }
            }
            //Ticket#25514 <<
            if(tmLine.Category__c == ResourceService.LABOR_CATEGORY || tmLine.Category__c == ResourceService.EQUIPMENT_CATEGORY || tmLine.Category__c == ResourceService.LUMP_SUM_CATEGORY){
                if(String.isNotBlank(tmLine.Quote_Line__c)){
                    if(tmLine.Quote_Line__r.Resource_Type__c != tmLine.Resource_Type__c){
                        tmLine.Quote_Line__c = null;
                    }
                }
                if(String.isNotBlank(tmLine.Sales_Line__c)){
                    if(tmLine.Sales_Line__r.Resource_Type__c != tmLine.Resource_Type__c){
                        tmLine.Sales_Line__c = null;
                    }
                }
            } else {
                if(String.isNotBlank(tmLine.Quote_Line__c)){
                    if(tmLine.Quote_Line__r.Resource__c != tmLine.Resource__c){
                        tmLine.Quote_Line__c = null;
                    }
                }
                if(String.isNotBlank(tmLine.Sales_Line__c)){
                    if(tmLine.Sales_Line__r.Resource__c != tmLine.Resource__c){
                        tmLine.Sales_Line__c = null;
                    }
                }
            }
            salesOrderJobTaskIds.add(tmLine.TM_Job_Task__r.Sales_Order_Job_Task__c);
            salesLineIds.add(tmLine.Sales_Line__c);
        }

        Map<Id, Sales_Line__c> mapSalesLinesById = new Map<Id, Sales_Line__c>();
        for (Sales_Line__c salesLine : SalesLinesSelector.newInstance().selectLinesById(salesLineIds)) {
            mapSalesLinesById.put(salesLine.Id, salesLine);
        }

        //get the last billing worksheet line no by sales order
        for (AggregateResult result : [SELECT Sales_Order__c, MAX(Line_No__c) LastLineNo FROM Billing_Worksheet_Line__c WHERE Sales_Order__c IN :mapNextLineNosBySalesOrderId.keySet() GROUP BY Sales_Order__c]) {
            Id salesOrderId = (Id)result.get('Sales_Order__c');
            if (mapNextLineNosBySalesOrderId.containsKey(salesOrderId)) {
                mapNextLineNosBySalesOrderId.put(salesOrderId, ((Decimal)result.get('LastLineNo')).intValue() + 1);
            }
        }

        Map<Id, Billing_Worksheet_Line__c> mapWorksheetLinesByTMLineId = new Map<Id, Billing_Worksheet_Line__c>();
        Map<Id, Billing_Worksheet_Line__c> mapLumpSumWorksheetLinesBySalesLineId = new Map<Id, Billing_Worksheet_Line__c>();
        //select the worksheet lines linked to the TMs and also all none-invoiced lump sum lines on the worksheet that were created previously.

        List<Billing_Worksheet_Line__c> worksheetLines = BillingWorksheetLinesSelector.newInstance().selectOpenLinesByTMIds(tmIds);
        for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
            if (worksheetLine.TM_Line__c != null) {
                if (mapTMLinesByTMId.containsKey(worksheetLine.TM_Line__c)) {
                    if (worksheetLine.Invoiced__c != true) { //only work with none invoiced lines
                        mapWorksheetLinesByTMLineId.put(worksheetLine.TM_Line__c, worksheetLine);
                    }
                }
            }
            else if (worksheetLine.Category__c == 'Bundled'){
                mapLumpSumWorksheetLinesBySalesLineId.put(worksheetLine.Sales_Line__c, worksheetLine);
            }
        }

        Set<Id> salesBundleLineIds = new Set<Id>();
        Map<Integer, Billing_Worksheet_Line__c> mapMiscChargeLinesByLineNo = new Map<Integer, Billing_Worksheet_Line__c>();
        for (TM_Line__c tmLine : tmLines) {
            //Ticket#24285 >>
            if(tmLine.Category__c == ResourceService.LABOR_CATEGORY && tmLine.Quantity__c == 0
                    && tmLine.Job_Start_Time__c == tmLine.Site_Start_Time__c && tmLine.Site_Start_Time__c == tmLine.Site_End_Time__c && tmLine.Site_End_Time__c == tmLine.Job_End_Time__c
                    && tmLine.Lunch_Start_Time__c == null && tmLine.Lunch_End_Time__c == null){
                continue;
            }
            //Ticket#24285 <<        
            if (!mapWorksheetLinesByTMLineId.containsKey(tmLine.Id)) {
                Sales_Line__c salesLine = null;
                if (tmLine.Sales_Line__c != null) {
                    salesLine = mapSalesLinesById.get(tmLine.Sales_Line__c);
                }

                Integer lineNo = mapNextLineNosBySalesOrderId.get(tmLine.TM__r.Sales_Order__c);
                mapNextLineNosBySalesOrderId.put(tmLine.TM__r.Sales_Order__c, lineNo + 1);

                Billing_Worksheet_Line__c worksheetLine;
                worksheetLine = new Billing_Worksheet_Line__c();
                worksheetLine.Line_No__c = lineNo;
                worksheetLine.TM__c = tmLine.TM__c;
                worksheetLine.TM__r = tmLine.TM__r;
                //Ticket#20496 >>
                if(tmLine.TM__r.Scheduled_Date__c != null) {
                    Date tempDate = tmLine.TM__r.Scheduled_Date__c;
                    if(TimeUtils.getWeekdayName(tmLine.TM__r.Scheduled_Date__c) == 'Sunday'){
                        tempDate = tempDate.addDays(-1);
                    }
                    Date acvStartOfWeek = tempDate.toStartOfWeek().addDays(1);
                    if(weekNumberByStartingDate.containsKey(acvStartOfWeek)){
                        worksheetLine.Week_Number__c = weekNumberByStartingDate.get(acvStartOfWeek).Id;
                    }
                }
                //Ticket#20496 >>
                worksheetLine.Category__c = tmLine.Category__c;
                worksheetLine.TM_Line__c = tmLine.Id;
                worksheetLine.TM_Line__r = new TM_Line__c(Id = tmLine.Id, Line_No__c = tmLine.Line_No__c);
                worksheetLine.TM_Job_Task__c = tmLine.TM_Job_Task__c;
                worksheetLine.Service_Center__c = tmLine.Service_Center__c;
                worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
                worksheetLine.Resource__c = tmLine.Resource__c;
                worksheetLine.Resource__r = tmLine.Resource__r;
                worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
                worksheetLine.Description__c = tmLine.Description__c;
                worksheetLine.Quantity__c = tmLine.Quantity__c;
                worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
                worksheetLine.Unit_of_Measure__r = tmLine.Unit_of_Measure__r;

                /*Waste001
                worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
                worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
                worksheetLine.Container_Size__c = tmLine.Container_Size__c;
                 */
                worksheetLine.Cost_Method__c = null;
                worksheetLine.Unit_Weight_Vol__c = null;
                worksheetLine.Container_Size__c = null;

                worksheetLine.Facility__c = tmLine.Facility__c;
                worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
                //ticket US128542
                worksheetLine.Approval_Id__c = tmLine.Approval_Id__c;
                worksheetLine.Profile_Id__c = tmLine.Profile_Id__c;
                //US129137
                worksheetLine.EQAI_Bill_Unit_Code__c = tmLine.EQAI_Bill_Unit_Code__c;
                worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
                worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
                worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
                worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
                worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
                worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
                worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
                worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
                //ticket 19130 <<
                /*
                worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
                worksheetLine.TM_Parent_Line__r = tmLine.Parent_Line__r;
                */
                //ticket 19130 >>
                worksheetLine.Sales_Order_Job_Task__c = tmLine.TM_Job_Task__r.Sales_Order_Job_Task__c;
                worksheetLine.Sales_Order__c = tmLine.TM__r.Sales_Order__c;
                worksheetLine.Regular_Hours__c = 0;
                worksheetLine.Overtime_Hours__c = 0;
                worksheetLine.Premium_Hours__c = 0;
                worksheetLine.Wizard_Question_Answered__c = tmLine.Wizard_Question_Answered__c;
                //non-billable flag from TM line <<
                worksheetLine.Non_Billable__c = tmLine.Non_Billable__c;
                //non-billable flag from TM line >>

                if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment') {
                    worksheetLine.Job_Start_Time__c = tmLine.Job_Start_Time__c;
                    worksheetLine.Job_End_Time__c = tmLine.Job_End_Time__c;
                    worksheetLine.Total_Job_Hours__c = tmLine.Total_Job_Hours__c;

                    if (tmLine.Category__c == 'Labor') {
                        worksheetLine.Include_Lunch_Y_N__c = true;
                        worksheetLine.Bill_Site_Time__c = false;
                        worksheetLine.Site_Start_Time__c = tmLine.Site_Start_Time__c;
                        worksheetLine.Site_End_Time__c = tmLine.Site_End_Time__c;
                        worksheetLine.Lunch_Start_Time__c = tmLine.Lunch_Start_Time__c;
                        worksheetLine.Lunch_End_Time__c = tmLine.Lunch_End_Time__c;
                        worksheetLine.Total_Site_Hours__c = tmLine.Total_Site_Hours__c;
                        worksheetLine.Travel_Hours__c = tmLine.Travel_Hours__c; //PW Job Travel Cost
                        worksheetLine.Cost_Qty__c = CompanyMgmt.zeroIfNull(tmLine.Total_Job_Hours__c) - TimeUtils.calculateHours(worksheetLine.Lunch_Start_Time__c, worksheetLine.Lunch_End_Time__c);
                    }
                    worksheetLine.Billing_Start_Time__c = worksheetLine.Job_Start_Time__c;
                    worksheetLine.Billing_End_Time__c = worksheetLine.Job_End_Time__c;
                    worksheetLine.Hour__c = TimeUtils.calculateHours(worksheetLine.Billing_Start_Time__c, worksheetLine.Billing_End_Time__c);
                }
                /* Ticket#19964
                else if (tmLine.Category__c == 'Subcontractors') {
                    Decimal unitPrice = 0;
                    if (tmLine.Unit_Cost__c != null) {
                        unitPrice = tmLine.Unit_Price__c;
                    } else if (salesLine != null) {
                        unitPrice = salesLine.Unit_Price__c;
                    }
                    if (worksheetLine.Bill_as_Lump_Sum__c != true && worksheetLine.Non_Billable__c != true) {
                        worksheetLine.Unit_Price__c = unitPrice;
                        worksheetLine.Unit_Cost__c = unitPrice;
                    }
                    worksheetLine.xUnit_Price__c = unitPrice;
                    worksheetLine.xUnit_Cost__c = unitPrice;
                }
                 */
                else if (tmLine.Category__c == ResourceService.LUMP_SUM_CATEGORY){
                    //For existing lump sum line in scheduled T&M
                    worksheetLine.Unit_Price__c = tmLine.Unit_Price__c;
                }

                if (salesLine != null) {
                    if (worksheetLine.Category__c != 'Subcontractors') {
                        worksheetLine.Contract_Regular_Rate__c = salesLine.Contract_Regular_Rate__c;
                        worksheetLine.Contract_Overtime_Rate__c = salesLine.Contract_Overtime_Rate__c;
                        worksheetLine.Contract_Premium_Rate__c = salesLine.Contract_Premium_Rate__c;
                        worksheetLine.Unit_Price__c = salesLine.Unit_Price__c;
                        worksheetLine.xUnit_Price__c = salesLine.xUnit_Price__c;
                        worksheetLine.Unit_Cost__c = salesLine.Unit_Cost__c;
                        worksheetLine.xUnit_Cost__c = salesLine.xUnit_Cost__c;
                        worksheetLine.Regular_Rate__c = salesLine.Regular_Rate__c;
                        worksheetLine.Overtime_Rate__c = salesLine.Overtime_Rate__c;
                        worksheetLine.Premium_Rate__c = salesLine.Premium_Rate__c;
                        worksheetLine.xRegular_Rate__c = salesLine.xRegular_Rate__c;
                        worksheetLine.xOvertime_Rate__c = salesLine.xOvertime_Rate__c;
                        worksheetLine.xPremium_Rate__c = salesLine.xPremium_Rate__c;
                    }
                    worksheetLine.Tax_Group__c = salesLine.Tax_Group__c;
                    worksheetLine.Tax_Pct__c = salesLine.Tax_Pct__c;
                    //ticket 19698 <<
                    //worksheetLine.Bill_as_Lump_Sum__c = salesLine.Bill_as_Lump_Sum__c;
                    //ticket 19698 >>
                    //non-billable flag from TM line <<
                    //worksheetLine.Non_Billable__c = salesLine.Non_Billable__c;
                    //non-billable flag from TM line >>
                    worksheetLine.Pricing_Source_2__c = salesLine.Pricing_Source_2__c;
                    worksheetLine.Min_Sell_Qty__c = salesLine.Min_Sell_Qty__c;
                    worksheetLine.Markup_Option__c = salesLine.Markup_Option__c;
                    worksheetLine.Markup__c = salesLine.Markup__c;
                } else {
                    if(salesOrder.Tax_Liable__c == True)
                    	worksheetLine.Tax_Group__c = 'TX';
                    else
                        worksheetLine.Tax_Group__c = 'NT';
                }
                
                if(worksheetLine.System_Calculated_Line__c == True && worksheetLine.Description__c == 'Manifest Fee' && !salesLineList.isEmpty())
                {
                    worksheetLine.Tax_Group__c = salesLineList[0].Tax_Group__c;
                    worksheetLine.Sales_Line__c = salesLineList[0].Id;
                    worksheetLine.Tax_Pct__c = salesLineList[0].Tax_Pct__c;
                }
                
               
				
                //calculate cost qty
                //worksheetLine.Cost_Qty__c = BillingWorksheetService.calculateCostQty(worksheetLine);
                mapWorksheetLinesByTMLineId.put(tmLine.Id, worksheetLine);

                if (tmLine.TM_Job_Task__r.Sales_Order_Job_Task__r.Billing_Type__c == 'Fixed Price') {
                    if (tmLine.Sales_Bundle_Line__c != null) {
                        salesBundleLineIds.add(tmLine.Sales_Bundle_Line__c);
                    }
                }

                //flat pay misc charge lines
                if (tmLine.Category__c == 'Misc. Charges And Taxes' && tmLine.Flat_Pay_Line__c == true) {
                    mapMiscChargeLinesByLineNo.put(worksheetLine.Line_No__c.intValue(), worksheetLine);
                }
            }
        }

        List<Billing_Worksheet_Line__c> worksheetLinesToUpsert = new List<Billing_Worksheet_Line__c>();

        //only submit none system lines for price, cost calculation
        for (Id tmlId : mapWorksheetLinesByTMLineId.keySet()) {
            Billing_Worksheet_Line__c worksheetLine = mapWorksheetLinesByTMLineId.get(tmlId);
            System.debug('worksheetLine >>>'+ worksheetLine.Category__c+'Price >>' + worksheetLine.Unit_Price__c);
        
            worksheetLinesToUpsert.add(worksheetLine);
        }
		        
        //calculate pricing, cost, labor hours, totals, etc.
        BillingWorksheetService.initStaticVariables(salesOrder.Id, worksheetLinesToUpsert);
        BillingWorksheetService.populateLinesInfo(salesOrder.Id, worksheetLinesToUpsert);
        //handle flat pay lines


        if (mapMiscChargeLinesByLineNo.size() > 0) {
            Map<Id, Decimal> mapFlatPayAmountByResourceId = new Map<Id, Decimal>();
            for (Billing_Worksheet_Line__c worksheetLine : mapMiscChargeLinesByLineNo.values()) {
                mapFlatPayAmountByResourceId.put(worksheetLine.Resource__c, 0);
                Decimal unitPrice = 0;
                for (TM_Line__c tmLine : tmLines) {
                    if (tmLine.Category__c == 'Labor') {
                        if (tmLine.Resource_Flat_Pays1__r != null && tmLine.Resource_Flat_Pays1__r.size() > 0) {
                            for (Resource_Flat_Pay__c flatPay : tmLine.Resource_Flat_Pays1__r) {
                                if (flatPay.Misc_Charge_Resource__c == worksheetLine.Resource__c) {
                                    unitPrice += CompanyMgmt.zeroIfNull(flatPay.Rate__c);
                                }
                            }
                        }
                    }
                }

                worksheetLine.Unit_Price__c = unitPrice;
                worksheetLine.xUnit_Price__c = worksheetLine.Unit_Price__c;
                worksheetLine.Unit_Cost__c = unitPrice;
                worksheetLine.xUnit_Cost__c = worksheetLine.Unit_Cost__c;
                System.debug('worksheetLine >>>'+ worksheetLine.Category__c+'Price >>' + worksheetLine.Unit_Price__c);
                BillingWorksheetService.calculateLineTotals(worksheetLine);
                System.debug('worksheetLine After Calc>>>'+ worksheetLine.Category__c+'Price >>' + worksheetLine.Unit_Price__c);
                
            }
        }

        List<Integer> tmLineNos = new List<Integer>();
        for (Billing_Worksheet_Line__c worksheetLine : worksheetLinesToUpsert) {
            //Ticket#20496 >>
            if(worksheetLine.TM__c != null && worksheetLine.Week_Number__c == null){
                Date tempDate = worksheetLine.TM__r.Scheduled_Date__c;
                if(TimeUtils.getWeekdayName(worksheetLine.TM__r.Scheduled_Date__c) == 'Sunday'){
                    tempDate = tempDate.addDays(-1);
                }
                Date acvStartOfWeek = tempDate.toStartOfWeek().addDays(1);
                if(weekNumberByStartingDate.containsKey(acvStartOfWeek)){
                    worksheetLine.Week_Number__c = weekNumberByStartingDate.get(acvStartOfWeek).Id;
                }
            }
            //Ticket#20496 <<
            Boolean allowZeroUnitCost = false;
            if (worksheetLine.Resource__r != null) {
                allowZeroUnitCost = worksheetLine.Resource__r.Allow_Zero_Unit_Cost_at_TM_Confirmation__c;
            }
            if (allowZeroUnitCost != true) {
                if (worksheetLine.Category__c != 'Waste Disposal' && worksheetLine.Category__c != 'Subcontractors' &&
                        worksheetLine.Category__c != ResourceService.MISC_CHARGES_AND_TAX_CATEGORY &&
                        worksheetLine.Category__c != ResourceService.LUMP_SUM_CATEGORY &&
                        worksheetLine.System_Calculated_Line__c != true)
                {
                    if (!worksheetLine.Bill_as_Lump_Sum__c == true && worksheetLine.Non_Billable__c != true) {
                        if (worksheetLine.Unit_Cost__c == 0 || worksheetLine.Unit_Cost__c == null) {
                            tmLineNos.add(worksheetLine.TM_Line__r.Line_No__c.intValue());
                        }
                    } else {
                        if (worksheetLine.xUnit_Cost__c == 0 || worksheetLine.xUnit_Cost__c == null) {
                            tmLineNos.add(worksheetLine.TM_Line__r.Line_No__c.intValue());
                        }
                    }
                }
            }
        }
        if (tmLineNos.size() > 0) {
            throw new DataException('Unit cost of T&M lines ' + String.join(tmLineNos, ', ') + ' must not be zero.');
        }


        CompanyMgmt.byPassTrigger = true;
        upsert worksheetLinesToUpsert;
        CompanyMgmt.byPassTrigger = false;

        List<Billing_Worksheet_Line__c> worksheetLinesToUpdate = new List<Billing_Worksheet_Line__c>();
        for (Billing_Worksheet_Line__c worksheetLine : worksheetLinesToUpsert) {
            Boolean addLineToUpdate = false;
            if (worksheetLine.Bundle_Line__c == null && worksheetLine.Sales_Bundle_Line__c != null) {
                if (mapLumpSumWorksheetLinesBySalesLineId.containsKey(worksheetLine.Sales_Bundle_Line__c)) {
                    worksheetLine.Bundle_Line__c = mapLumpSumWorksheetLinesBySalesLineId.get(worksheetLine.Sales_Bundle_Line__c).Id;
                    addLineToUpdate = true;
                }
            }

            //ticket 19130 <<
            /*
            if (worksheetLine.TM_Parent_Line__c != null) {
                if (mapWorksheetLinesByTMLineId.containsKey(worksheetLine.TM_Parent_Line__c)) {
                    worksheetLine.Parent_Line__c = mapWorksheetLinesByTMLineId.get(worksheetLine.TM_Parent_Line__c).Id;
                    addLineToUpdate = true;
                }
            }
            */
            //ticket 19130 >>

            if (addLineToUpdate) {
                worksheetLinesToUpdate.add(worksheetLine);
            }
        }

        if (worksheetLinesToUpdate.size() > 0) {
            CompanyMgmt.byPassTrigger = true;
            update worksheetLinesToUpdate;
            CompanyMgmt.byPassTrigger = false;
        }

        //link the tm lines with the worksheet lines
        List<TM_Line__c> tmLinesToUpdate = new List<TM_Line__c>();
        for (Id tmLineId : mapWorksheetLinesByTMLineId.keySet()) {
            Billing_Worksheet_Line__c worksheetLine = mapWorksheetLinesByTMLineId.get(tmLineId);
            TM_Line__c tmLine = new TM_Line__c();
            tmLine.Id = tmLineId;
            tmLine.Billing_Worksheet_Line__c = worksheetLine.Id;
            //Ticket#19917 >>
            if(String.isBlank(tmLine.Contract_Line__c) && String.isNotBlank(worksheetLine.Contract_Line__c)) {
                tmLine.Contract_Line__c = worksheetLine.Contract_Line__c;
            }
            //Ticket#19917 >>
            tmLinesToUpdate.add(tmLine);
        }

        CompanyMgmt.byPassLineTrigger = true;
        update tmLinesToUpdate;
        CompanyMgmt.byPassLineTrigger = false;

        /* comment out - this code is not needed when T&M is confirmed
        //read all none invoiced lines and rollup lump sum
        List<Billing_Worksheet_Line__c> allWorksheetLines = BillingWorksheetLinesSelector.newInstance().selectBySalesOrderJobTaskId(salesOrderJobTaskIds, new List<String>{ 'Invoiced__c != TRUE' });
        BillingWorksheetService.rollupBundledLines(allWorksheetLines);
        CompanyMgmt.byPassTrigger = true;
        update allWorksheetLines;
        CompanyMgmt.byPassTrigger = false;
        */
    }

    public static void deleteBillingWorksheetLines(Set<TM__c> tms) {
        CompanyMgmt.systemCall = true;
        /*if(Test.isRunningTest())
            return;*/
        Set<Id> tmIds = new Set<Id>();
        //Set<Id> salesOrderIds = new Set<Id>(); //not used
        for (TM__c tm : tms) {
            tmIds.add(tm.Id);
            //salesOrderIds.add(tm.Sales_Order__c); //not used
        }

        //Map<Id, Billing_Worksheet_Line__c> mapLumpSumWorksheetLinesByIds = new Map<Id, Billing_Worksheet_Line__c>(); //not used
        List<Billing_Worksheet_Line__c> worksheetLinesToDelete = new List<Billing_Worksheet_Line__c>();

        //Ticket#20496 add Billing Rules field to selector
        List<Billing_Worksheet_Line__c> worksheetLines = [SELECT Id, Line_No__c, TM__c, TM__r.Status__c, TM__r.Name, Invoiced__c, Category__c,
                Resource__c, Sales_Order__c, Week_Number__c,
                Sales_Order__r.Billing_Rule__c, Sales_Order__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c,
                Sales_Order__r.Contract__c, Sales_Order__r.Contract__r.Billing_Rule__c,
                Sales_Order__r.Contract__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c,
                Sales_Order__r.Service_Center__c, Sales_Order__r.Service_Center__r.Billing_Rule__c,
                Sales_Order__r.Service_Center__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c,
                Sales_Order__r.Subsidiary_Company__c, Sales_Order__r.Subsidiary_Company__r.Billing_Rule__c,
                Sales_Order__r.Subsidiary_Company__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c
        FROM Billing_Worksheet_Line__c
        WHERE TM__c IN :tmIds];
        //Ticket#20496 >>
        Id salesOrderId = null;
        Id billingRuleId = null;
        Set<Id> weekNumberIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        Set<Id> deletedWorksheetIds = new Set<Id>();
        Boolean weeklyTotalCalculationEnabled = false;
        //Ticket#20496 <<

        //System.debug('Info: Start for loop');
        for (Integer i = 0; i < worksheetLines.size(); i++) {
            Billing_Worksheet_Line__c worksheetLine = worksheetLines[i];
            if (worksheetLine.TM__r.Status__c == 'Void' && worksheetLine.Invoiced__c == true) {
                throw new DataException('You cannot void T&M ' + worksheetLine.TM__r.Name + ' because one ore more lines are invoiced.');
            }
            else {
                if (worksheetLine.Invoiced__c != true) {
                    worksheetLinesToDelete.add(worksheetLine);
                    /*
                    System.debug('Info: ********Line No: ' + worksheetLine.Line_No__c);
                    System.debug('Info: worksheetLine.Sales_Order__c ' + worksheetLine.Sales_Order__c);
                    System.debug('Info: worksheetLine.Sales_Order__r.Contract__c ' + worksheetLine.Sales_Order__r.Contract__c);
                    System.debug('Info: worksheetLine.Sales_Order__r.Contract__r.Billing_Rule__c ' + worksheetLine.Sales_Order__r.Contract__r.Billing_Rule__c);
                    System.debug('Info: worksheetLine.Sales_Order__r.Contract__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c ' + worksheetLine.Sales_Order__r.Contract__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c);
                    System.debug('Info: --------------------------');
                    System.debug('Info: worksheetLine.Sales_Order__c ' + worksheetLine.Sales_Order__c);
                    System.debug('Info: worksheetLine.Sales_Order__r.Billing_Rule__c ' + worksheetLine.Sales_Order__r.Billing_Rule__c);
                    System.debug('Info: worksheetLine.Sales_Order__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c ' + worksheetLine.Sales_Order__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c);
                     */
                    //Ticket#20496 >>
                    if (worksheetLine.Sales_Order__c != null &&
                            worksheetLine.Sales_Order__r.Contract__c != null &&
                            worksheetLine.Sales_Order__r.Contract__r.Billing_Rule__c != null &&
                            worksheetLine.Sales_Order__r.Contract__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c == true)
                    {
                        weeklyTotalCalculationEnabled = true;
                    } else if (worksheetLine.Sales_Order__c != null &&
                            worksheetLine.Sales_Order__r.Billing_Rule__c != null &&
                            worksheetLine.Sales_Order__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c == true)
                    {
                        weeklyTotalCalculationEnabled = true;
                    }

                    if(weeklyTotalCalculationEnabled == true && worksheetLine.Category__c == ResourceService.LABOR_CATEGORY){
                        salesOrderId = worksheetLine.Sales_Order__c;
                        resourceIds.add(worksheetLine.Resource__c);
                        weekNumberIds.add(worksheetLine.Week_Number__c);
                        deletedWorksheetIds.add(worksheetLine.Id);
                    }
                    //Ticket#20496 <<
                    worksheetLines.remove(i);
                    i--;
                }
            }
        }
        //System.debug('Info: End for loop');
        //System.debug('Info: weeklyTotalCalculationEnabled ' + weeklyTotalCalculationEnabled);

        if (worksheetLinesToDelete.size() > 0) {
            CompanyMgmt.byPassTrigger = true;
            delete worksheetLinesToDelete;
            CompanyMgmt.byPassTrigger = false;

            //Ticket#20496 >>
            //System.debug('Info: deletedWorksheetIds ' + deletedWorksheetIds);
            if(weeklyTotalCalculationEnabled == true && deletedWorksheetIds.size() > 0){
                List<Billing_Worksheet_Line__c> billingWorksheetLines = [SELECT Id, Line_No__c, Category__c, Resource__c,
                        Week_Number__c, Hour__c, Regular_Hours__c, Include_Lunch_Y_N__c, Lunch_Start_Time__c,
                        Lunch_End_Time__c, TM__r.T_M_Scheduled_Day__c, TM__r.Scheduled_Date__c, Invoiced__c,
                        Billing_Start_Time__c, Billing_End_Time__c, Quantity__c, Unit_of_Measure__c, Regular_Rate__c,
                        Overtime_Rate__c, Premium_Rate__c, Unit_Price__c, Unit_Cost__c, Tax_Pct__c, TM__c, Resource_Type__c,
                        Sales_Order__c, Unit_of_Measure__r.Hours_UOM__c,TM__r.Name, Overtime_Hours__c, Premium_Hours__c,
                        Min_Sell_Qty__c,Markup__c,Cost_Qty__c,Bill_as_Lump_Sum__c,Non_Billable__c, xUnit_Price__c, xUnit_Cost__c,
                        xRegular_Rate__c, xOvertime_Rate__c, xPremium_Rate__c, Markup_Option__c, Line_Amount__c, Tax__c,
                        Line_Amt_Incl_Tax__c, Line_Cost__c, xLine_Amount__c, xLine_Cost__c
                FROM Billing_Worksheet_Line__c
                WHERE Sales_Order__r.Billing_Rule__c = :billingRuleId AND Category__c = 'Labor' AND Resource__c IN :resourceIds AND Week_Number__c IN :weekNumberIds
                AND Id NOT IN :deletedWorksheetIds AND Invoiced__c = FALSE
                ORDER BY TM__r.Scheduled_Date__c ASC];
                BillingWorksheetService.calculateLaborHours(salesOrderId, billingWorksheetLines);
                /*
                for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
                    System.debug('Info: billingWorksheetLine ' + billingWorksheetLine.Line_No__c + ' -- ' + billingWorksheetLine.TM__r.Scheduled_Date__c + ' --- ' + billingWorksheetLine.Regular_Hours__c + ' -- ' + billingWorksheetLine.Overtime_Hours__c);
                }
                 */
                update billingWorksheetLines;
            }
            //Ticket#20496 <<
        }
    }

    public static List<TM__c> cloneAndSchedule(List<TM__c> selectedTMs, String scheduleDate){
        Savepoint sp = Database.setSavepoint();
        try {
            //Prepare TM Id set for bulk query
            Set<Id> tmIds = new Set<Id>();
            Set<Id> salesOrderIds = new Set<Id>(); //Ticket#19849

            String[] dateArray = new String[3];
            String scheduleDateStr = scheduleDate;
            if(scheduleDate.contains('/')) {
                dateArray = scheduleDate.split('/', 3);
                scheduleDateStr = dateArray[2] + '-' + dateArray[0] + '-' + dateArray[1];
            }

            Date scheduledDate = Date.valueOf(scheduleDateStr);

            for (TM__c tm : selectedTMs) {
                if(tm.Contact__r.Blocked__c == true){
                    throw new DataException('T&M cannot be cloned because linked Bill-to Contact is blocked');
                }

                if(tm.Site_Contact_2__r.Blocked__c == true){
                    throw new DataException('T&M cannot be cloned because linked Site Contact is blocked');
                }

                tmIds.add(tm.Id);
                salesOrderIds.add(tm.Sales_Order__c);
            }

            /*
            //Ticket#19849 >>
            List<Sales_Order__c> salesOrders = [SELECT Id, Name, Document_Status__c FROM Sales_Order__c WHERE Id IN :salesOrderIds AND Document_Status__c = 'Closed'];
            if(salesOrders.size() > 0){
                String errorMsg = 'T&M cannot be cloned because linked sales orders is closed. Sales Order No.: ';
                for(Sales_Order__c salesOrder : salesOrders){
                    errorMsg = errorMsg + salesOrder.Name + ', ';
                }
                errorMsg = errorMsg.removeEnd(', ');
                throw new DataException(errorMsg);
            }
            //Ticket#19849 >>
             */

            Map<Id, Sales_Order__c> salesOrdersByIds = new Map<Id, Sales_Order__c>(); //Ticket#24525

            //Ticket#27427 - allow user to prevent new T&M creation from service center. 
            List<Sales_Order__c> salesOrders = [SELECT Id, Name, Document_Status__c, Bill_to_Customer_No__r.Emergency__c,
                Bill_to_Customer_No__r.AccountNumber, Contract__c, Contract__r.Status, Contract__r.EndDate,
                Service_Center__r.Prevent_TM_Creation__c, Service_Center__r.Name
                FROM Sales_Order__c
                WHERE Id IN :salesOrderIds];

            for(Sales_Order__c salesOrder : salesOrders){
                salesOrdersByIds.put(salesOrder.Id, salesOrder); //Ticket#24525
                if(salesOrder.Document_Status__c == 'Closed'){
                    throw new DataException('T&M cannot be cloned because linked sales orders is closed. Sales Order No.: ' + salesOrder.Name);
                }

                if (salesOrder.Contract__c != null) {
                    if (salesOrder.Contract__r.Status != 'Activated') {
                        throw new DataException('Contract associated with sales order is not activated.');
                    }

                    if (scheduledDate > salesOrder.Contract__r.EndDate) {
                        throw new DataException('Contract expired on ' + salesOrder.Contract__r.EndDate);
                    }
                }
                if(salesOrder.Service_Center__r.Prevent_TM_Creation__c == true){
                    throw new DataException('T&M Creation is not permitted for this Service Center. SC: ' + salesOrder.Service_Center__r.Name);
                }
            }

            //Clone and schedule T&M
            Map<Id, TM__c> mapNewTMsByOldTMId = new Map<Id, TM__c>();
            Set<Id> oldTMIdWithContractBeenChanged = new Set<Id>(); //Ticket#24525
            for (TM__c tm : selectedTMs) {
                TM__c newTM = tm.clone(false, true, false, false);
                newTM.Name = null;
                newTM.Scheduled_Date__c = scheduledDate;
                newTM.Status__c = 'Scheduled';
                newTM.Ready_to_Close__c = false;
                newTM.Sales_Invoice__c = null;
                newTM.Confirmed_Date__c = null;
                newTM.Confirmed_by__c = null;
                newTM.Mobile_TM__c = false;
                newTM.Job_Complete__c = false;
                newTM.Mobile_First_Save_At__c = null;
                newTM.Old_Id__c = tm.Id;
                newTM.Project_Manager_Reviewed__c = false;
                newTM.Reviewed_At_Status__c = null;
                newTM.Reviewed_Date__c = null;
                newTM.Reviewed_By__c = null;
                newTM.Rate_Sheet__c = null; //Ticket#25287

                //field TM PDF <<
                newTM.Mobile_TM__c = false;
                newTM.Accept_Terms_and_Conditions__c = false;
                newTM.Field_TM_PDF_Sent__c = false;
                newTM.Field_TM_PDF_Saved__c = false;
                newTM.Customer_Comments__c = null;
                newTM.Customer_Not_Available__c = false;
                //field TM PDF >>

                //Ticket#24525 >>
                mapNewTMsByOldTMId.put(tm.Id, newTM);
                Id salesOrderContractId = salesOrdersByIds.get(tm.Sales_Order__c).Contract__c;
                if(salesOrderContractId != tm.Contract__c){
                    oldTMIdWithContractBeenChanged.add(tm.Id);
                    newTM.Contract__c = salesOrderContractId;
                }
                //Ticket#24525 <<
            }
            //CompanyMgmt.byPassTrigger = true;
            insert mapNewTMsByOldTMId.values();
            //CompanyMgmt.byPassTrigger = false;

            //Ticket#24525 >>
            Set<Id> newTMIdWithContractBeenChanged = new Set<Id>();
            for(Id oldTMId : oldTMIdWithContractBeenChanged){
                newTMIdWithContractBeenChanged.add(mapNewTMsByOldTMId.get(oldTMId).Id);
            }
            //Ticket#24525 <<

            //insert job task
            List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
            Map<Id, Map<Integer, TM_Job_Task__c>> mapNewJobTasksByLineNoByOldTMId = new Map<Id, Map<Integer, TM_Job_Task__c>>();
            for (TM_Job_Task__c jobTask : TMJobTasksSelector.newInstance().selectByTMId(tmIds)) {
                TM__c newTM = mapNewTMsByOldTMId.get(jobTask.TM__c);
                TM_Job_Task__c newJobTask = jobTask.clone(false, true, false, false);
                newJobTask.TM__c = newTM.Id;
                newJobTask.TM__r = new TM__c(Id = newTM.Id);
                jobTasks.add(newJobTask);

                Map<Integer, TM_Job_Task__c> mapNewJobTasksByLineNo;
                if (mapNewJobTasksByLineNoByOldTMId.containsKey(jobTask.TM__c)) {
                    mapNewJobTasksByLineNo = mapNewJobTasksByLineNoByOldTMId.get(jobTask.TM__c);
                }
                else {
                    mapNewJobTasksByLineNo = new Map<Integer, TM_Job_Task__c>();
                    mapNewJobTasksByLineNoByOldTMId.put(jobTask.TM__c, mapNewJobTasksByLineNo);
                }
                mapNewJobTasksByLineNo.put(jobTask.Line_No__c.intValue(), newJobTask);
            }
            //CompanyMgmt.byPassTrigger = true;
            insert jobTasks;
            //CompanyMgmt.byPassTrigger = false;

            //tm lines
            Map<Id, Map<Integer, TM_Line__c>> mapNewTMLinesByLineNoByTMId = new Map<Id, Map<Integer, TM_Line__c>>();
            //ticket 19130 <<
            Map<Id, Map<Integer, TM_Line__c>> mapOldTMLinesByLineNoByNewTMId = new Map<Id, Map<Integer, TM_Line__c>>();
            List<TM_Line__c> newTMLines = new List<TM_Line__c>();
            //ticket 19130 >>

            //duplicated safety plan lines issue <<
            //for (TM_Line__c tmLine : TMLinesSelector.newInstance().selectByTmId(tmIds, null)) {
            List<String> filters = new List<String>();
            filters.add('System_Calculated_Line__c<>TRUE');
            filters.add('Category__c != \'Bundled\''); //Ticket#23789
            for (TM_Line__c tmLine : TMLinesSelector.newInstance().selectByTmId(tmIds, filters)) {
                //duplicated safety plan lines issue >>

                //ticket 19861 <<
                if (tmLine.Resource_Type__r != null && tmLine.Resource_Type__r.Blocked__c == true) {
                    throw new DataException('You cannot clone ' + tmLine.TM__r.Name + ' because resource type "' + tmLine.Resource_Type__r.Name + '" is blocked.');
                }
                if (tmLine.Resource__r != null && tmLine.Resource__r.Blocked__c == true) {
                    throw new DataException('You cannot clone ' + tmLine.TM__r.Name + ' because resource "' + tmLine.Resource__r.Name + '" is blocked.');
                }
                //ticket 19861 >>

                TM__c newTM = mapNewTMsByOldTMId.get(tmLine.TM__c);
                TM_Job_Task__c newJobTask = mapNewJobTasksByLineNoByOldTMId.get(tmLine.TM__c).get(tmLine.TM_Job_Task__r.Line_No__c.intValue());

                Map<Integer, TM_Line__c> mapNewTMLinesByLineNo;
                if (mapNewTMLinesByLineNoByTMId.containsKey(newTM.Id)) {
                    mapNewTMLinesByLineNo = mapNewTMLinesByLineNoByTMId.get(newTM.Id);
                }
                else {
                    mapNewTMLinesByLineNo = new Map<Integer, TM_Line__c>();
                    mapNewTMLinesByLineNoByTMId.put(newTM.Id, mapNewTMLinesByLineNo);
                }

                //ticket 19130 <<
                Map<Integer, TM_Line__c> mapOldTMLinesByLineNo;
                if (mapOldTMLinesByLineNoByNewTMId.containsKey(newTM.Id)) {
                    mapOldTMLinesByLineNo = mapOldTMLinesByLineNoByNewTMId.get(newTM.Id);
                }
                else {
                    mapOldTMLinesByLineNo = new Map<Integer, TM_Line__c>();
                    mapOldTMLinesByLineNoByNewTMId.put(newTM.Id, mapOldTMLinesByLineNo);
                }
                mapOldTMLinesByLineNo.put(tmLine.Line_No__c.intValue(), tmLine);
                //ticket 19130 >>

                TM_Line__c newTMLine = tmLine.clone(false, true, false, false);
                newTMLine.TM__c = newTM.Id;
                newTMLine.TM_Job_Task__c = newJobTask.Id;
                newTMLine.Category__c = tmLine.Category__c;
                newTMLine.Tax_Group__c = tmLine.Tax_Group__c;
                newTMLine.Resource_Type__c = tmLine.Resource_Type__c;
                newTMLine.Resource__c = tmLine.Resource__c;
                newTMLine.Resource_Name__c = tmLine.Resource_Name__c;
                newTMLine.Description__c = tmLine.Description__c;
                newTMLine.Service_Center__c = tmLine.Service_Center__c;
                newTMLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
                newTMLine.Line_No__c = tmLine.Line_No__c;
                newTMLine.Contract_Line__c = tmLine.Contract_Line__c;
                //Ticket#24525 >>
                if(newTMIdWithContractBeenChanged.contains(newTM.Id)){
                    newTMLine.Contract_Line__c = null;
                }
                //Ticket#24525 <<
                if (tmLine.Category__c != 'Labor' && tmLine.Category__c != 'Equipment') {
                    newTMLine.Quantity__c = tmLine.Quantity__c;
                } else {
                    newTMLine.Quantity__c = 0;
                    newTMLine.Regular_Hours__c = null;
                    newTMLine.Overtime_Hours__c = null;
                    newTMLine.Premium_Hours__c = null;
                    newTMLine.Cost_Qty__c = 0;
                }
                newTMLine.Job_Start_Time__c = null;
                newTMLine.Job_End_Time__c = null;
                newTMLine.Site_Start_Time__c = null;
                newTMLine.Site_End_Time__c = null;
                newTMLine.Total_Job_Hours__c = 0;
                newTMLine.Total_Site_Hours__c = 0;
                newTMLine.Billing_End_Time__c = null;
                newTMLine.Billing_Start_Time__c = null;
                newTMLine.Hour__c = 0;
                newTMLine.Lunch_End_Time__c = null;
                newTMLine.Lunch_Start_Time__c = null;
                newTMLine.Lunch__c = null;
                newTMLine.Sales_Line__c = tmLine.Sales_Line__c;
                newTMLine.Regular_Rate__c = tmLine.Regular_Rate__c;
                newTMLine.Premium_Rate__c = tmLine.Premium_Rate__c;
                newTMLine.Overtime_Rate__c = tmLine.Overtime_Rate__c;
                newTMLine.Markup_Option__c = tmLine.Markup_Option__c;
                newTMLine.Markup__c = tmLine.Markup__c;
                newTMLine.Invoiced__c = false;
                newTMLine.Billing_Worksheet_Line__c = null;
                newTMLine.KronosTimeEntriesProcessed__c = false;
                newTMLine.Kronos_Integration_Note__c = null;
                if (newTMLine.Category__c == 'Labor') {
                    newTMLine.Unit_Price__c = tmLine.Regular_Rate__c;
                } else {
                    newTMLine.Unit_Price__c = tmLine.Unit_Price__c;
                }

                //ticket 19130 <<
                newTMLine.Parent_Line__c = null;
                newTMLine.Is_Child_Resource__c = tmLine.Is_Child_Resource__c;
                newTMLine.Dereferenced_Child_Resource__c = tmLine.Dereferenced_Child_Resource__c;
                newTMLine.Wizard_Question_Answered__c = false;
                newTMLines.add(newTMLine);
                //ticket 19130 >>

                mapNewTMLinesByLineNo.put(newTMLine.Line_No__c.intValue(), newTMLine);
            }

            //ticket 19130 <<
            insert newTMLines;

            List<TM_Line__c> newTMLinesToUpdate = new List<TM_Line__c>();
            List<TM_Parent_Child_Relation__c> relationsToInsert = new List<TM_Parent_Child_Relation__c>();
            for (Id tmId : mapOldTMLinesByLineNoByNewTMId.keySet()) {
                Map<Integer, TM_Line__c> mapOldTMLinesByLineNo = mapOldTMLinesByLineNoByNewTMId.get(tmId);
                Map<Integer, TM_Line__c> mapNewTMLinesByLineNo = mapNewTMLinesByLineNoByTMId.get(tmId);
                for (TM_Line__c oldTMLine : mapOldTMLinesByLineNo.values()) {
                    TM_Line__c newTmLine = mapNewTMLinesByLineNo.get(oldTMLine.Line_No__c.intValue());
                    Boolean updateLine = false;
                    if (oldTMLine.Bundle_Line__r != null) {
                        Integer bundleLineNo = oldTMLine.Bundle_Line__r.Line_No__c.intValue();
                        newTMLine.Bundle_Line__c = mapNewTMLinesByLineNo.get(bundleLineNo).Id;
                        updateLine = true;
                    }

                    if (oldTMLine.Linked_Line__r != null) {
                        Integer linkedLineNo = oldTMLine.Linked_Line__r.Line_No__c.intValue();
                        newTMLine.Linked_Line__c = mapNewTMLinesByLineNo.get(linkedLineNo).Id;
                        updateLine = true;
                    }

                    if (updateLine) {
                        newTMLinesToUpdate.add(newTMLine);
                    }

                    if (oldTMLine.TM_Child_Lines__r != null) {
                        for (TM_Parent_Child_Relation__c xRelation : oldTMLine.TM_Child_Lines__r) {
                            TM_Parent_Child_Relation__c relation = new TM_Parent_Child_Relation__c();
                            TM_Line__c newChildTMLine = mapNewTMLinesByLineNo.get(xRelation.Child_Line__r.Line_No__c.intValue());
                            relation.Parent_Line__c = newTMLine.Id;
                            relation.Child_Line__c = newChildTMLine.Id;
                            relationsToInsert.add(relation);
                        }
                    }
                }
            }
            update newTMLinesToUpdate;
            insert relationsToInsert;
            //ticket 19130 >>

            //ticket 19130 <<
            /*
            //insert bundle line first
            List<TM_Line__c> bundleLinesToInsert = new List<TM_Line__c>();
            for (Map<Integer, TM_Line__c> mapNewTMLinesByLineNo : mapNewTMLinesByLineNoByTMId.values()) {
                Set<Integer> bundleLineNos = new Set<Integer>();
                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (tmLine.Bundle_Line__r != null) {
                        bundleLineNos.add(tmLine.Bundle_Line__r.Line_No__c.intValue());
                    }
                }

                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (bundleLineNos.contains(tmLine.Line_No__c.intValue())) {
                        bundleLinesToInsert.add(tmLine);
                    }
                }
            }
            if (bundleLinesToInsert.size() > 0) {
                //CompanyMgmt.byPassTrigger = true;
                //CompanyMgmt.byPassLineTrigger = true;
                upsert bundleLinesToInsert;
                //CompanyMgmt.byPassTrigger = false;
                //CompanyMgmt.byPassLineTrigger = false;
            }

            //insert parent lines next
            List<TM_Line__c> parentLinesToInsert = new List<TM_Line__c>();
            for (Map<Integer, TM_Line__c> mapNewTMLinesByLineNo : mapNewTMLinesByLineNoByTMId.values()) {
                Set<Integer> parentLineNos = new Set<Integer>();
                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (tmLine.Parent_Line__r != null) {
                        parentLineNos.add(tmLine.Parent_Line__r.Line_No__c.intValue());
                    }
                }

                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (parentLineNos.contains(tmLine.Line_No__c.intValue())) {
                        parentLinesToInsert.add(tmLine);
                    }
                }
            }
            if (parentLinesToInsert.size() > 0) {
                //CompanyMgmt.byPassTrigger = true;
                //CompanyMgmt.byPassLineTrigger = true;
                upsert parentLinesToInsert;
                //CompanyMgmt.byPassTrigger = false;
                //CompanyMgmt.byPassLineTrigger = false;
            }

            //insert linked lines next
            List<TM_Line__c> linkedLinesToInsert = new List<TM_Line__c>();
            for (Map<Integer, TM_Line__c> mapNewTMLinesByLineNo : mapNewTMLinesByLineNoByTMId.values()) {
                Set<Integer> linkedLineNos = new Set<Integer>();
                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (tmLine.Linked_Line__r != null) {
                        linkedLineNos.add(tmLine.Linked_Line__r.Line_No__c.intValue());
                    }
                }

                for (TM_Line__c tmLine : mapNewTMLinesByLineNo.values()) {
                    if (linkedLineNos.contains(tmLine.Line_No__c.intValue())) {
                        linkedLinesToInsert.add(tmLine);
                    }
                }
            }
            if (linkedLinesToInsert.size() > 0) {
                ///CompanyMgmt.byPassTrigger = true;
                //CompanyMgmt.byPassLineTrigger = true;
                upsert linkedLinesToInsert;
                //CompanyMgmt.byPassTrigger = false;
                //CompanyMgmt.byPassLineTrigger = false;
            }

            //update bundled, child and linked lines
            //List<TM_Line__c> tmLines = new List<TM_Line__c>();
            for (Id tmId : mapNewTMLinesByLineNoByTMId.keySet()) {
                Map<Integer, TM_Line__c> mapNewTMLinesByLineNo = mapNewTMLinesByLineNoByTMId.get(tmId);
                for (Integer lineNo : mapNewTMLinesByLineNo.keySet()) {
                    TM_Line__c tmLine = mapNewTMLinesByLineNo.get(lineNo);

                    if (tmLine.Bundle_Line__r != null) {
                        TM_Line__c bundleLine = mapNewTMLinesByLineNo.get(tmLine.Bundle_Line__r.Line_No__c.intValue());
                        tmLine.Bundle_Line__c = bundleLine.Id;
                        tmLine.Bundle_Line__r = new TM_Line__c(Id = bundleLine.Id, Line_No__c = bundleLine.Line_No__c);
                    }
                    if (tmLine.Parent_Line__r != null) {
                        TM_Line__c parentLine = mapNewTMLinesByLineNo.get(tmLine.Parent_Line__r.Line_No__c.intValue());
                        tmLine.Parent_Line__c = parentLine.Id;
                        tmLine.Parent_Line__r = new TM_Line__c(Id = parentLine.Id, Line_No__c = parentLine.Line_No__c);
                    }
                    if (tmLine.Linked_Line__r != null) {
                        TM_Line__c linkedLine = mapNewTMLinesByLineNo.get(tmLine.Linked_Line__r.Line_No__c.intValue());
                        tmLine.Linked_Line__c = linkedLine.Id;
                        tmLine.Linked_Line__r = new TM_Line__c(Id = linkedLine.Id, Line_No__c = linkedLine.Line_No__c);
                    }
                    //tmLines.add(tmLine);
                }
            }
            */
            //ticket 19130 >>

            //duplicated safety plan lines issue <<
            Map<TM__c, List<TM_Line__c>> mapTMLinesByTM = new Map<TM__c, List<TM_Line__c>>();
            Map<TM__c, List<ACVTMJobTaskWrapper>> mapJobTaskWrappersByTM = new Map<TM__c, List<ACVTMJobTaskWrapper>>();
            Map<Id, Integer> mapNextTMLineNosByTMId = new Map<Id, Integer>();
            Map<Id, TM__c> newTmsByIds = new Map<Id, TM__c>(); //Ticket#24525
            for (Id oldTMId : mapNewTMsByOldTMId.keySet()) {
                TM__c newTM = mapNewTMsByOldTMId.get(oldTMId);
                List<TM_Job_Task__c> newTMJobTasks = mapNewJobTasksByLineNoByOldTMId.get(oldTMId).values();

                //ticket 19130 <<
                /*
                List<TM_Line__c> newTMLines = mapNewTMLinesByLineNoByTMId.get(newTM.Id).values();
                newTmsByIds.put(newTM.Id, newTM); //Ticket#24525
                mapTMLinesByTM.put(newTM, newTMLines);
                ACVTMWrapper tmWrapper = new ACVTMWrapper(newTM, newTMJobTasks, newTMLines);
                mapJobTaskWrappersByTM.put(tmWrapper.TM, tmWrapper.JobTaskWrappers);
                */
                Map<Integer, TM_Line__c> mapNewTMLinesByLineNo = mapNewTMLinesByLineNoByTMId.get(newTM.Id);
                newTmsByIds.put(newTM.Id, newTM); //Ticket#24525
                mapTMLinesByTM.put(newTM, mapNewTMLinesByLineNo.values());
                ACVTMWrapper tmWrapper = new ACVTMWrapper(newTM, newTMJobTasks, mapNewTMLinesByLineNo.values());
                mapJobTaskWrappersByTM.put(tmWrapper.TM, tmWrapper.JobTaskWrappers);
                //ticket 19130 >>



                Integer nextTMLineNo = 0;
                for (TM_Line__c newTmLine : newTMLines) {
                    if (nextTMLineNo < newTMLine.Line_No__c.intValue()) {
                        nextTMLineNo = newTmLine.Line_No__c.intValue();
                    }
                }
                nextTMLineNo++;
                mapNextTMLineNosByTMId.put(newTM.Id, nextTMLineNo);
            }

            TMLLinesService.initStaticVariables(mapTMLinesByTM);

            //Ticket#24525 >>
            for(Id newTMId : newTMIdWithContractBeenChanged){
                TM__c newTM = newTmsByIds.get(newTMId);
                for(TM_Line__c tmLine : mapTMLinesByTM.get(newTM)){
                    TMLLinesService.validateUnitOfMeasure(newTM, tmLine, false);
                }
            }
            //Ticket#24525 <<

            List<TM_Line__c> tmLines = new List<TM_Line__c>();
            for (TM__c newTM : mapJobTaskWrappersByTM.keySet()) {
                Integer nextTMLineNo = mapNextTMLineNosByTMId.get(newTM.Id);
                List<ACVTMJobTaskWrapper> jobTaskWrappers = mapJobTaskWrappersByTM.get(newTM);

                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    Integer lineCount = jobTaskWrapper.TMLines.size();
                    TMLLinesService.createSafetyPlanLine(newTM, jobTaskWrapper, nextTMLineNo);
                    if (jobTaskWrapper.TMLines.size() > lineCount) {
                        nextTMLineNo++;
                        break;
                    }
                }

                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    Integer lineCount = jobTaskWrapper.TMLines.size();
                    TMLLinesService.calculateManifestFeeLine(newTM, jobTaskWrapper, nextTMLineNo);
                    if (jobTaskWrapper.TMLines.size() > lineCount) {
                        nextTMLineNo++;
                    }
                }

                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    Integer lineCount = jobTaskWrapper.TMLines.size();
                    TMLLinesService.calculateRinseOutFeeLine(newTM, jobTaskWrapper, nextTMLineNo);
                    if (jobTaskWrapper.TMLines.size() > lineCount) {
                        nextTMLineNo++;
                    }
                }

                //insert tm line to tmLines list
                for (ACVTMJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                        tmLines.add(tmLine);
                    }
                }
            }
            //duplicated safety plan lines issue >>

            upsert tmLines;
            return mapNewTMsByOldTMId.values();
        }
        catch(Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            Database.rollback(sp);
            throw ex;
        }
    }

    //Ticket#23028
    public static void updateExistingBillingWorksheetLines(Map<Id, TM_Line__c> tmLinesByIds){
        Set<Id> billWorksheetLineIds = new Set<Id>();
        for(TM_Line__c tmLine : tmLinesByIds.values()){
            if(tmLine.Category__c != ResourceService.LABOR_CATEGORY && String.isNotBlank(tmLine.Billing_Worksheet_Line__c)){
                billWorksheetLineIds.add(tmLine.Billing_Worksheet_Line__c);
            }
        }
        if(billWorksheetLineIds.size() == 0){
            return;
        }

        List<Billing_Worksheet_Line__c> billingWorksheetLines = BillingWorksheetLinesSelector.newInstance().selectById(billWorksheetLineIds);
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            TM_Line__c tmLine = tmLinesByIds.get(billingWorksheetLine.TM_Line__c);
            billingWorksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
            billingWorksheetLine.Resource__c = tmLine.Resource__c;
            billingWorksheetLine.Service_Center__c = tmLine.Service_Center__c;
            billingWorksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
            billingWorksheetLine.Quantity__c = tmLine.Quantity__c;
            billingWorksheetLine.Description__c = tmLine.Description__c;
            billingWorksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
            billingWorksheetLine.Facility__c = tmLine.Facility__c;
            billingWorksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
            //US128542
            billingWorksheetLine.Approval_Id__c = tmLine.Approval_Id__c;
            billingWorksheetLine.Profile_Id__c = tmLine.Profile_Id__c;
            //US129137
            billingWorksheetLine.EQAI_Bill_Unit_Code__c = tmLine.EQAI_Bill_Unit_Code__c;
            billingWorksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
            billingWorksheetLine.Fleet_No__c = tmLine.Fleet_No__c;
            billingWorksheetLine.Wizard_Question_Answered__c = tmLine.Wizard_Question_Answered__c;
            billingWorksheetLine.Non_Billable__c = tmLine.Non_Billable__c;
            if(billingWorksheetLine.Category__c == ResourceService.EQUIPMENT_CATEGORY){
                billingWorksheetLine.Job_Start_Time__c = tmLine.Job_Start_Time__c;
                billingWorksheetLine.Job_End_Time__c = tmLine.Job_End_Time__c;
                billingWorksheetLine.Total_Job_Hours__c = tmLine.Total_Job_Hours__c;
                billingWorksheetLine.Billing_Start_Time__c = billingWorksheetLine.Job_Start_Time__c;
                billingWorksheetLine.Billing_End_Time__c = billingWorksheetLine.Job_End_Time__c;
                billingWorksheetLine.Hour__c = TimeUtils.calculateHours(billingWorksheetLine.Billing_Start_Time__c, billingWorksheetLine.Billing_End_Time__c);
            }
        }
        BillingWorksheetService.initStaticVariables(billingWorksheetLines[0].Sales_Order__c, billingWorksheetLines);
        //Ticket#23234 >>
        //BillingWorksheetService.populateLinesInfo(billingWorksheetLines[0].Sales_Order__c, billingWorksheetLines);
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            BillingWorksheetService.calculatePriceAndCost(billingWorksheetLines[0].Sales_Order__c, billingWorksheetLine);
        }
        //Ticket#23234 <<
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        update billingWorksheetLines;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;
    }

    private static ITMsService service(){
        return (ITMsService) Application.Service.newInstance(ITMsService.class);
    }
}