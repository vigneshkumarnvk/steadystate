public class TMs extends fflib_SObjectDomain implements ITMs{

    public static Company_Setup__c theCompanySetupValue;

    /*
    private Company_Setup__c theCompanySetup{
        get{
            if (theCompanySetupValue == null){
                theCompanySetupValue = CompanyMgmt.getCompanySetup();
            }
            return theCompanySetupValue;
        }
    }
     */

    public static ITMs newInstance(List<TM__c> sObjectList) {
        return (ITMs) Application.Domain.newInstance(sObjectList);
    }

    public TMs(List<TM__c> sObjectList) {
        super(sObjectList);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new TMs(sObjectList);
        }
    }

    // DML on child line should be placed in after trigger otherwise SELF_REFERENCE error
    public override void onAfterUpdate(Map<Id, SObject> oldMap) {
        //job task <<
        /* move to TM Creation routine
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        List<TM__c> checkList = new List<TM__c>();
        for (TM__c theTM : (List<TM__c>) Records) {
            if (theTM.Status__c == 'Received By Billing' && ((TM__c)oldMap.get(theTM.Id)).Status__c == 'Confirmed'){
                checkList.add(theTM);
            }
        }
        Map<Id, Id> tempMap = new Map<Id,Id>();
        if (checkList.size() > 0) {
            tempMap = checkWhetherToCreateSafetyPlanLine(checkList);
        }
        if (tempMap.size() > 0) createSafetyPlanLineToFirstTM(tempMap, uow);

        // handle confirmed status
        if(Records.size() == 1){
            TM__c tm = (TM__c) Records[0];
            TM__c oldTM = (TM__c)oldMap.get(tm.Id);
            if(tm.Status__c == 'Confirmed' && (oldTM.Status__c == 'Scheduled' || oldTM.Status__c == 'Mobile Review')){
                List<TM_Line__c> tmLines = new List<TM_Line__c>();
                tmLines = [
                        SELECT Id, Name, Resource__c, TM__r.Scheduled_Date__c, TM__c, TM__r.Name, Category__c, Line_No__c, Job_Start_Time__c,
                                Job_End_Time__c, Site_Start_Time__c, Site_End_Time__c, Pick_Up_Rental__c,Resource_Type__r.Fleet_No_Required__c,
                                Service_Center__r.Equipment_Fleet_No_Not_Required__c, Quantity__c, Unit_Price__c, Line_Amount__c, Service_Center__c,
                                Resource__r.Non_Payroll_Labor_Resource__c,Resource_Name__c,To_Invoice__c, Invoiced__c,
                                Bill_as_Lump_Sum__c, Non_Billable__c, Line_Amt_Incl_Tax__c, TM__r.Sales_Order__r.Portal_Basis__c,
                                TM__r.Sales_Order__r.Portal_Basis_Adv__c, TM__r.Sales_Order__r.Overtime_Rate__c,
                                TM__r.Sales_Order__r.Lump_Sum__c, TM__r.Sales_Order__r.Daily_Rate__c,Billing_Start_Time__c,
                                Billing_End_Time__c, Resource__r.Status__c, Resource__r.Out_of_Service_Date__c, Resource__r.Name,
                                Unit_of_Measure__c,Regular_Rate__c,Premium_Rate__c, Overtime_Rate__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                                Cost_Method__c, Facility__c, Container_Size__c, Min_Sell_Qty__c, Unit_Weight_Vol__c,
                                Markup__c, Cost_Qty__c, Tax_Group__c, Tax_Pct__c, Line_Cost__c, Markup_Option__c, Tax__c,
                                Regular_Hours__c, Overtime_Hours__c, Premium_Hours__c, Pricing_Source_2__c, Contract_Line__c
                        FROM TM_Line__c
                        WHERE TM__c = :tm.Id];
                TMLLinesService.initStaticVariables(new Map<TM__c, List<TM_Line__c>>{tm => tmLines});
                for(TM_Line__c tmLine : tmLines){
                    TMLLinesService.calcUnitPrice(tm, tmLine);
                    TMLLinesService.calcUnitCost(tm, tmLine);
                }
                TMLLinesService.calcTotals(new Map<TM__c, List<TM_Line__c>>{tm => tmLines});
                uow.registerDirty(tmLines);
            }
        }

        // Last line, this should be execute at the end of method
        if (!System.Test.isRunningTest()) uow.commitWork();
        */
        //job task >>
    }

    //job task << move to TMsServiceImpl
    /*
    public Map<Id, Id> checkWhetherToCreateSafetyPlanLine(List<TM__c> theTMList) {
        Map<Id, Id> returnMap = new Map<Id, Id>();
        Set<Id> salesOrderIdWithDefaultSaftyResId = new Set<Id>();
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> tmIds = new Set<Id>();
        for (TM__c theTM : theTMList){
            salesOrderIds.add(theTM.Sales_Order__c);
            tmIds.add(theTM.Id);
        }

        List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectTMsById(salesOrderIds);
        for(Sales_Order__c salesOrder:salesOrders){
            for(TM__c tm:salesOrder.Service_Orders__r){
                tmIds.add(tm.Id);
            }
        }

        List<TM_Line__c> tmls = TMLinesSelector.newInstance().selectSafetyPlanLineByTMId(tmIds, theCompanySetup.Default_Safety_Plan_Resource__c);
        for (TM_Line__c theTML : tmls) {
            salesOrderIdWithDefaultSaftyResId.add(theTML.TM__r.Sales_Order__c);
        }

        Map<Id, Sales_Order__c> salesOrderMap = new Map<Id, Sales_Order__c>(salesOrders);
        for (TM__c theTM : theTMList) {

            if (salesOrderMap.containsKey(theTM.Sales_Order__c)){

                Sales_Order__c theSO = salesOrderMap.get(theTM.Sales_Order__c);
                System.debug('Info: theSO.Service_Orders__r ' + theSO.Service_Orders__r);
                if (!theSO.Sales_Order_Type__r.Emergency_Response__c){
                    continue;
                }

                List<TM__c> tms = theSO.Service_Orders__r;
                if (tms[0].Id != theTM.Id){
                    continue;
                }

                if(!salesOrderIdWithDefaultSaftyResId.contains(theTM.Sales_Order__c)){
                    returnMap.put(theTM.Id, theTM.Sales_Order__c);
                }
            }
        }
        return returnMap;
    }

    public void createSafetyPlanLineToFirstTM(Map<Id, Id> tmIdToSOId, fflib_ISObjectUnitOfWork uow) {
        List<Resource__c> resources = ResourcesSelector.newInstance().selectById(new Set<Id>{theCompanySetup.Default_Safety_Plan_Resource__c});
        Resource__c theResource = resources[0];
        List<TM__c> theTMList = TMsSelector.newInstance().selectTMLineNOById(tmIdToSOId.keySet());
        Map<Id, Decimal> tmIdToLineNO = new Map<Id, Decimal>();
        for (TM__c theTM : theTMList){
            List<TM_Line__c> theTMLList = theTM.TM_Lines__r;
            if(theTMLList.size() == 0) {
                tmIdToLineNO.put(theTM.Id, 1); continue;
            }
            tmIdToLineNO.put(theTM.Id, theTMLList[0].Line_No__c + 1);
        }
        // Get Sales Order safety plan line price
        Set<Id> salesOrderIdSet = new Set<Id>();
        for (Id id : tmIdToSOId.values()){
            salesOrderIdSet.add(id);
        }
        Map<Id, Decimal> soIdToLineUnitPrice = new Map<Id, Decimal>();
        List<Sales_Line__c> theSLList = SalesLinesSelector.newInstance().selectSafetyPlanLineBySalesOrderId(salesOrderIdSet, theCompanySetup.Default_Safety_Plan_Resource__c);
        if (theSLList.size() > 0) {
            for (Sales_Line__c theSL : theSLList) {
                soIdToLineUnitPrice.put(theSL.Sales_Order__c, theSL.Unit_Price__c);
            }
        }
        System.debug(soIdToLineUnitPrice);
        for (Id id : tmIdToSOId.keySet()){
            TM_Line__c newLine = new TM_Line__c();
            newLine.TM__c = id;
            newLine.Category__c = 'Misc. Charges And Taxes';
            newLine.Line_No__c = tmIdToLineNO.get(id);
            newLine.Tax_Group__c = 'NT';
            newLine.Resource__c = theResource.Id;
            newLine.Description__c = theResource.Description__c;
            newLine.Unit_of_Measure__c = theResource.Unit_of_Measure__c;
            newLine.Quantity__c = 1;
            newLine.Unit_Price__c = soIdToLineUnitPrice.containsKey(tmIdToSOId.get(id)) ? soIdToLineUnitPrice.get(tmIdToSOId.get(id)) : theResource.Silver_Rate__c;
            newLine.Line_Amount__c = newLine.Unit_Price__c;
            newLine.Tax__c = 0.00;
            newLine.Line_Amt_Incl_Tax__c = newLine.Unit_Price__c;
            newLine.System_Calculated_Line__c = true;
            uow.registerNew(newLine);
        }
    }
    */

    public void updateCustomerPONumber(Map<Id, String> poToUpdateBySOIds, fflib_ISObjectUnitOfWork uow) {
        for (TM__c theTM : (List<TM__c>) Records) {
            theTM.Customer_PO_No__c = poToUpdateBySOIds.get(theTM.Sales_Order__c);
            uow.registerDirty(theTM);
        }
    }
}