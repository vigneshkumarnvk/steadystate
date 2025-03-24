public class TMLines extends fflib_SObjectDomain implements ITMLines {

    public static Map<Id, Resource_Type__c> mapResourceTypes = new Map<Id, Resource_Type__c>();
    public static Map<Id, Resource__c> mapResources = new Map<Id, Resource__c>();
    public static Map<Id, Unit_of_Measure__c> mapUnitOfMeasures = new Map<Id, Unit_of_Measure__c>();
    public static Map<Id, Sales_Line__c> mapSalesLines = new Map<Id, Sales_Line__c>();
    public static Map<Id, Contract_Line__c> mapContractLines = new Map<Id, Contract_Line__c>();
    public static Map<Id, Account> mapAccounts = new Map<Id, Account>();
    public static Map<Id, Sales_Order__c> mapSalesOrders = new Map<Id, Sales_Order__c>();
    public static Company_Setup__c theCompanySetupValue;

    public static ITMLines newInstance(List<TM_Line__c> sObjectList) {
        return (ITMLines) Application.Domain.newInstance(sObjectList);
    }

    public TMLines(List<TM_Line__c> sObjectList) {
        super(sObjectList);
    }

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> sObjectList) {
            return new TMLines(sObjectList);
        }
    }

    public Company_Setup__c theCompanySetup {
        get {
            if (theCompanySetupValue == null) {
                theCompanySetupValue = CompanyMgmt.getCompanySetup();
            }
            return theCompanySetupValue;
        }
        set;
    }

    public void updateTMLinesWhenResourceTypeChanged() {
        updateResourceType();
        /* Kevin: should not reset quantity, the code caused input quantity to change to zero
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            theTML.Quantity__c = 0;
            theTML.Hour__c = 0;
        }
        */
        updateTMLLunch();
        updateTMLHour();
        updateTMLThreeHours();
        updateTMLQuantity();
        updateTMLCostQty();
        /** NOTICE: the order to update pricing should be backwards compare to TMMgmt.
         *  Because each line apply its own pricing rule
         *  The order is tier -> contract -> Sales line or quote. Each step override previous price.
         */
        updatePricingBaseOnStandard();
        updatePricingBaseOnContractValue();
        updatePricingBaseOnSalesLineValue();
    }

    public void updateTMLinesWhenUnitOfMeasureChanged(){
        updatePricingBaseOnStandard();
        updatePricingBaseOnContractValue();
        updatePricingBaseOnSalesLineValue();
    }

    public void updateTMLinesRestOfFields() {
        updateTMLTotalJobHours();
        updateTMLTotalSiteHours();
        updateTMLBillingStartEndTimeWhenBillSiteTime();
        updateTMLLunch();
        updateTMLHour();
        updateTMLThreeHours();
        updateTMLQuantity();
        updateTMLBillAsLumpSumAndNonbillable();
        updateTMLUnitPrice();
        updateTMLUnitCost();
        updateTMLCostQty();
        updateTMLTaxPct();
        updateTMLTotal();
    }

    public void updateTMLBillAsLumpSumAndNonbillable(){
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if (theTML.Category__c == 'Labor'){
                if (theTML.Bill_as_Lump_Sum__c == true || theTML.Non_Billable__c == true) {
                    theTML.Regular_Rate__c = 0;
                    theTML.Premium_Rate__c = 0;
                    theTML.Overtime_Rate__c = 0;
                    theTML.Use_Premium_Rate__c = false;
                    theTML.Unit_Price__c = 0;
                }
            } else {
                if (theTML.Bill_as_Lump_Sum__c == true || theTML.Non_Billable__c == true) {
                    theTML.Unit_Price__c = 0;
                }
            }
        }
    }

    public void updateTMLUnitPrice(){
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if (theTML.Category__c != 'Labor') continue;
            //Skip if UOM is not Hours UOM
            //scott 020919 there is a potential issue here - old UOM may not be hours
            //if (theTML.Unit_of_Measure__r.Hours_UOM__c != true) continue;
            //fix.001 << handle null UOM
            if (mapUnitOfMeasures.containsKey(theTML.Unit_of_Measure__c)) {
            //fix.001 >>
                if (mapUnitOfMeasures.get(theTML.Unit_of_Measure__c).Hours_UOM__c != true) continue;
                //Calculate Unit Price
                Decimal totalHours = 0;
                Decimal totalPrice = 0;
    
                totalPrice = (CompanyMgmt.zeroIfNull(theTML.Regular_Hours__c) * CompanyMgmt.zeroIfNull(theTML.Regular_Rate__c)) +
                        (CompanyMgmt.zeroIfNull(theTML.Overtime_Hours__c) * CompanyMgmt.zeroIfNull(theTML.Overtime_Rate__c)) +
                        (CompanyMgmt.zeroIfNull(theTML.Premium_Hours__c) * CompanyMgmt.zeroIfNull(theTML.Premium_Rate__c));
    
                totalHours = CompanyMgmt.zeroIfNull(theTML.Regular_Hours__c) + CompanyMgmt.zeroIfNull(theTML.Overtime_Hours__c) +
                        CompanyMgmt.zeroIfNull(theTML.Premium_Hours__c);
    
                if (totalHours != 0) {
                    theTML.Unit_Price__c = CompanyMgmt.halfUpTo5D(totalPrice / totalHours);
                } else {
                    theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theTML.Regular_Rate__c);
                }
            }
        }
    }

    public void updateTMLTaxPct() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if (theTML.TM__r.Tax_Liable__c && theTML.Tax_Group__c != null) {
                theTML.Tax_Pct__c = CompanyMgmt.getSalesTax(theTML.TM__r.Tax_Area__c, theTML.Tax_Group__c);
            } else {
                theTML.Tax_Pct__c = 0;
            }
        }
    }

    public void updateTMLTotal() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            theTML.Line_Cost__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theTML.Unit_Cost__c) * CompanyMgmt.zeroIfNull(theTML.Cost_Qty__c));
            theTML.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theTML.Unit_Price__c) * CompanyMgmt.zeroIfNull(theTML.Quantity__c));
            Decimal Markup = 0;
            if(theTML.Category__c != ResourceService.SUBCONTRACTORS_CATEGORY) {
                if (theTML.Markup_Option__c == '%') Markup = theTML.Line_Amount__c * CompanyMgmt.zeroIfNull(theTML.Markup__c) / 100;
                if (theTML.Markup_Option__c == 'Amount') Markup = CompanyMgmt.zeroIfNull(theTML.Markup__c);
            }
            theTML.Line_Amount__c += Markup;
            theTML.Tax__c = CompanyMgmt.halfUpTo2D(theTML.Line_Amount__c * CompanyMgmt.zeroIfNull(theTML.Tax_Pct__c) / 100);
            theTML.Line_Amt_Incl_Tax__c = theTML.Line_Amount__c + theTML.Tax__c;
        }
    }

    public void updateResourceType() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            Resource_Type__c theResourceType;
            if (String.isNotEmpty(theTML.Resource_Type__c)) {
                if (!mapResourceTypes.containsKey(theTML.Resource_Type__c)) {
                    theResourceType = CompanyMgmt.getResourceType(theTML.Resource_Type__c);
                    mapResourceTypes.put(theTML.Resource_Type__c, theResourceType);
                }
                theResourceType = mapResourceTypes.get(theTML.Resource_Type__c);
                theTML.Description__c = theResourceType.Description__c;
                if (theTML.Sales_Line__c == null && theTML.Contract_Line__c == null && theTML.Unit_of_Measure__c == null) {
                    theTML.Unit_of_Measure__c = theResourceType.Unit_of_Measure__c;
                    theTML.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theResourceType.Unit_of_Measure__c, Name = theResourceType.Unit_of_Measure__r.Name);
                }
                theTML.Unit_Cost__c = theResourceType.Unit_Cost__c;
            }
        }
    }

    public void updatePricingBaseOnContractValue() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if (String.isNotEmpty(theTML.Contract_Line__c)) {
                Contract_Line__c theCL;
                theCL = mapContractLines.get(theTML.Contract_Line__c);
                if (theTML.Category__c == 'Labor') {
                    theTML.Contract_Regular_Rate__c = CompanyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                    theTML.Contract_Overtime_Rate__c = CompanyMgmt.zeroIfNull(theCL.Overtime_Rate__c);
                    theTML.Contract_Premium_Rate__c = CompanyMgmt.zeroIfNull(theCL.Premium_Rate__c);
                    if (CompanyMgmt.zeroIfNull(theCL.Regular_Rate__c) != 0) theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                    if (CompanyMgmt.zeroIfNull(theCL.Premium_Rate__c) != 0) theTML.Premium_Rate__c = CompanyMgmt.zeroIfNull(theCL.Premium_Rate__c);
                    if (CompanyMgmt.zeroIfNull(theCL.Overtime_Rate__c) != 0) theTML.Overtime_Rate__c = CompanyMgmt.zeroIfNull(theCL.Overtime_Rate__c);
                    theTML.Use_Premium_Rate__c = false;
                } else if (theTML.Category__c == 'Equipment' || theTML.Category__c == 'Bundled') {
                    theTML.Contract_Regular_Rate__c = CompanyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                    if (CompanyMgmt.zeroIfNull(theCL.Regular_Rate__c) != 0) theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                } else if (theTML.Category__c == 'Materials') {
                    theTML.Contract_Regular_Rate__c = CompanyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                    theTML.Contract_Premium_Rate__c = CompanyMgmt.zeroIfNull(theCL.Premium_Rate__c);
                    if (CompanyMgmt.zeroIfNull(theCL.Regular_Rate__c) != 0) theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                }
                if (String.isNotBlank(theCL.Customer_Description__c)) theTML.Description__c = theCL.Customer_Description__c;
            }
        }
    }

    public void updatePricingBaseOnSalesLineValue() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if (String.isNotEmpty(theTML.Sales_Line__c)) {
                Sales_Line__c salesLine;
                salesLine = mapSalesLines.get(theTML.Sales_Line__c);
                if (theTML.Unit_of_Measure__c == salesLine.Unit_of_Measure__c) {
                    theTML.Description__c = salesLine.Description__c;
                    if (CompanyMgmt.zeroIfNull(salesLine.Unit_Price__c) != 0) {
                        theTML.Unit_Price__c = salesLine.Unit_Price__c;
                        theTML.Regular_Rate__c = salesLine.Regular_Rate__c;
                        theTML.Overtime_Rate__c = salesLine.Overtime_Rate__c;
                        theTML.Premium_Rate__c = salesLine.Premium_Rate__c;

                    }
                }
            }
        }
    }

    public void updateTMLUnitCost() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if (theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment') {
                if (theTML.Resource_Type__c != null){
                    Resource_Type__c theResourceType = mapResourceTypes.get(theTML.Resource_Type__c);
                    theTML.Unit_Cost__c = 0;
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost__c);
                    }

                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure1__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost1__c);
                    }
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure2__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost2__c);
                    }
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure3__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost3__c);
                    }
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure4__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost4__c);
                    }
                }
            } else {
                if (theTML.Resource__c != null){
                    Resource__c theResource = mapResources.get(theTML.Resource__c);
                    theTML.Unit_Cost__c = 0;
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResource.Unit_Cost__c);
                    }
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure1__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResource.Unit_Cost1__c);
                    }
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure2__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResource.Unit_Cost2__c);
                    }
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure3__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResource.Unit_Cost3__c);
                    }
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure4__c) {
                        theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResource.Unit_Cost4__c);
                    }
                }
            }
        }
    }

    public void updateTMLLunch() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if(theTML.Category__c == 'Labor'){
                theTML.Lunch__c = TimeUtils.generateLunchHourString(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c);
                /*
                Decimal minutes = TimeUtils.calculateHours(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c) * 60;
                if (minutes == 0) theTML.Lunch__c = 'No';
                else if (minutes == 30) theTML.Lunch__c = '1/2 Hour';
                else if (minutes == 60) theTML.Lunch__c = '1 Hour';
                else theTML.Lunch__c = '';
                 */
            }
        }
    }

    public void updateTMLHour() {
        //labor-equipment linkage <<
        Map<Id, List<TM_Line__c>> mapLinkedLines = new Map<Id, List<TM_Line__c>>();
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if (theTML.Category__c == 'Equipment' && theTML.Linked_Line__c != null) {
                List<TM_Line__c> linkedLines;
                if (mapLinkedLines.containsKey(theTML.Linked_Line__c)) {
                    linkedLines = mapLinkedLines.get(theTML.Linked_Line__c);
                }
                else {
                    linkedLines = new List<TM_Line__c>();
                    mapLinkedLines.put(theTML.Linked_Line__c, linkedLines);
                }
                linkedLines.add(theTML);                     
                mapLinkedLines.put(theTML.Linked_Line__c, linkedLines);
            }
        }
        //labor-equipment linkage >>  
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            //fix.001 <<
            /*
            //Decimal minutes = TimeUtils.calculateHours(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c) * 60;
            if (theTML.Include_Lunch_Y_N__c == false || theTML.Category__c == 'Equipment') {
                //theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c) - minutes.divide(60, 1);
                theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c) - calculateLunchHours(theTML.Lunch__c);
            } else {
                theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c);
            }
            */
            if (theTML.Category__c == 'Labor') {
                /*
                Decimal minutes = TimeUtils.calculateHours(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c) * 60; 
                theTML.Lunch__c = null;
                if (minutes == 0) {
                    theTML.Lunch__c = 'No';
                } else if (minutes == 30) {
                    theTML.Lunch__c = '1/2 Hour';
                } else if (minutes == 60) {
                    theTML.Lunch__c = '1 Hour';
                }
                 */
                theTML.Lunch__c = TimeUtils.generateLunchHourString(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c);
                
                if (theTML.Bill_Site_Time__c == true) {
                    theTML.Bill_Site_Time__c = true;
                    theTML.Billing_Start_Time__c = theTML.Site_Start_Time__c;
                    theTML.Billing_End_Time__c = theTML.Site_End_Time__c;
                } else {
                    theTML.Bill_Site_Time__c = false;
                    if(theTML.Billing_Start_Time__c == null) theTML.Billing_Start_Time__c = theTML.Job_Start_Time__c;
                    if(theTML.Billing_End_Time__c == null) theTML.Billing_End_Time__c = theTML.Job_End_Time__c;
                }
                
                if(theTML.Include_Lunch_Y_N__c == false){

                    theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c) - TimeUtils.convertLunchHourStringToDecimal(theTML.Lunch__c); //TMMgmt.calculateLunchHours(theTML.Lunch__c);
                } else {
                    theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c);
                }
                
                //labor-equipment linkage << //update equiment lines
                if (mapLinkedLines.containsKey(theTML.Id)) {
                    List<TM_Line__c> linkedLines = mapLinkedLines.get(theTML.Id);
                    for (TM_Line__c linkedLine : linkedLines) {
                        linkedLine.Job_Start_Time__c = theTML.Job_Start_Time__c;
                        linkedLine.Job_ENd_Time__c = theTML.Job_End_Time__c;
                        linkedLine.Site_Start_Time__c = theTML.Site_Start_Time__c;
                        linkedLine.Site_End_Time__c = theTML.Site_End_Time__c;
                        linkedLine.Billing_Start_Time__c = null;
                        linkedLine.Billing_End_Time__c = null;
                    }
                }
            }
        }
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {        

        //labor-equipment linkage  >>    
            //labor-equipment linkage  <<  calcualte labor hours first so that equipment lines will have correct hours from the labor lines if linked      
            //else if (theTML.Category__c == 'Equipment') {                
            if (theTML.Category__c == 'Equipment') {            
            //labor-equipment linkage  >>            
                if (theTML.Bill_Site_Time__c == true) {
                    theTML.Bill_Site_Time__c = true;
                    theTML.Billing_Start_Time__c = theTML.Site_Start_Time__c;
                    theTML.Billing_End_Time__c = theTML.Site_End_Time__c;
                } else {
                    theTML.Bill_Site_Time__c = false;
                    if(theTML.Billing_Start_Time__c == null) theTML.Billing_Start_Time__c = theTML.Job_Start_Time__c;
                    if(theTML.Billing_End_Time__c == null) theTML.Billing_End_Time__c = theTML.Job_End_Time__c;
                }
                
                if(theTML.Include_Lunch_Y_N__c == false){
                    theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c) - TimeUtils.convertLunchHourStringToDecimal(theTML.Lunch__c); //TMMgmt.calculateLunchHours(theTML.Lunch__c);
                } else {
                    theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c);
                }
            }
            else if (theTML.Category__c == 'Demurrage') {
                theTML.Hour__c = TimeUtils.calculateHours(theTML.Site_Start_Time__c, theTML.Site_End_Time__c);
            }
            //fix.001 >>
        }
    }

    public void updateTMLBillingStartEndTimeWhenBillSiteTime() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if (theTML.Bill_Site_Time__c == true) {
                theTML.Bill_Site_Time__c = true;
                theTML.Billing_Start_Time__c = theTML.Site_Start_Time__c;
                theTML.Billing_End_Time__c = theTML.Site_End_Time__c;
            } else {
                theTML.Bill_Site_Time__c = false;
                if(theTML.Billing_Start_Time__c == null) theTML.Billing_Start_Time__c = theTML.Job_Start_Time__c;
                if(theTML.Billing_End_Time__c == null) theTML.Billing_End_Time__c = theTML.Job_End_Time__c;
            }
        }
    }

    public void updateTMLTotalJobHours() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            theTML.Total_Job_Hours__c = TimeUtils.calculateHours(theTML.Job_Start_Time__c, theTML.Job_End_Time__c)
                    - calculateLunchHours(theTML.Lunch__c);
        }
    }

    public void updateTMLTotalSiteHours() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            theTML.Total_Site_Hours__c = TimeUtils.calculateHours(theTML.Site_Start_Time__c, theTML.Site_End_Time__c)
                    - calculateLunchHours(theTML.Lunch__c);
        }
    }

    public void updateTMLThreeHours() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            if (CompanyMgmt.zeroIfNull(theTML.Hour__c) > 0) {
                Decimal totalHrs = theTML.Hour__c;
                if (totalHrs > 8 && theTML.Category__c == 'Labor') {
                    theTML.Regular_Hours__c = 8;
                    theTML.Overtime_Hours__c = totalHrs - theTML.Regular_Hours__c;
                    theTML.Premium_Hours__c = 0;
                } else {
                    theTML.Regular_Hours__c = totalHrs;
                    theTML.Overtime_Hours__c = 0;
                    theTML.Premium_Hours__c = 0;
                }
            }
        }
    }

    public void updateTMLQuantity() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            //fix.001 <<
            /*
            if (theTML.Category__c == 'Labor'){
                if (String.isNotEmpty(theTML.Unit_of_Measure__c)) {
                    if (theTML.Unit_of_Measure__r.Hours_UOM__c == true) {
                        theTML.Quantity__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theTML.Hour__c));
                    } else {
                        theTML.Quantity__c = 1;
                    }
                } else {
                    theTML.Quantity__c = 1;
                }
            }
            */
            if (!string.isBlank(theTML.Unit_of_Measure__c)) {
                if (theTML.Unit_of_Measure__r.Hours_UOM__c == true && (theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment')) {
                    theTML.Quantity__c = companyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theTML.Hour__c));
                }
            }
            //fix.001 >>
        }
    }

    public void updateTMLCostQty() {
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            Decimal costQty = 0;
            if ((theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment') && theTML.Unit_of_Measure__r.Hours_UOM__c == true) {
                costQty = TimeUtils.calculateHours(theTML.Job_Start_Time__c, theTML.Job_End_Time__c) -
                        TimeUtils.convertLunchHourStringToDecimal(theTML.Lunch__c);  //calculateLunchHours(theTML.Lunch__c);
            }
            if (costQty == 0) {
                costQty = CompanyMgmt.zeroIfNull(theTML.Quantity__c);
            }
            theTML.Cost_Qty__c = costQty;
        }
    }

    public Decimal calculateLunchHours(String lunchString) {
        Decimal hours = 0;
        if (lunchString == '1/2 Hour') hours = 0.5; else if (lunchString == '1 Hour') hours = 1;
        return hours;
    }

    public void updatePricingBaseOnStandard() {
        /*
        for (TM_Line__c theTML : (List<TM_Line__c>) Records) {
            //fix.001 << choose quote or sales order
            //Sales_Order__c theSO = mapSalesOrders.get(theTML.TM__r.Sales_Order__c);
            Id salesOrderId;
            if (theTML.TM__r.Sales_Order__c != null) {
                salesOrderId = theTML.TM__r.Sales_Order__c;
            }
            else {
                salesOrderId = theTML.TM__r.From_Sales_Quote__c;
            }
            Sales_Order__c theSO = mapSalesOrders.get(salesOrderId);
            //fix.001 >>            
            
            Boolean isSalesOrderER = theSO.Emergency_Sales_Order__c;
            Account theAccount = mapAccounts.get(theTML.TM__r.Bill_to_Customer__c);
            if (theTML.Category__c == 'Labor') {
                theTML.Regular_Rate__c = 0;
                if (mapResourceTypes.containsKey(theTML.Resource_Type__c)) {
                    Resource_Type__c theResourceType = mapResourceTypes.get(theTML.Resource_Type__c);
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure__c) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure1__c) {
                        if (isSalesOrderER == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate1__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate1__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate1__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate1__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate1__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate1__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure2__c) {
                        if (isSalesOrderER == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate2__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate2__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate2__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate2__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate2__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate2__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure3__c) {
                        if (isSalesOrderER == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate3__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate3__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate3__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate3__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate3__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate3__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure4__c) {
                        if (isSalesOrderER == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate4__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate4__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate4__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate4__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate4__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate4__c);
                        }
                    }
                    theTML.Overtime_Rate__c = CompanyMgmt.zeroIfNull(theTML.Regular_Rate__c) * CompanyMgmt.zeroIfNull(theCompanySetup.T_M_Overtime_Multiplier__c);
                    theTML.Premium_Rate__c = CompanyMgmt.zeroIfNull(theTML.Regular_Rate__c) * CompanyMgmt.zeroIfNull(theCompanySetup.T_M_Premium_Multiplier__c);
                    theTML.Use_Premium_Rate__c = false;
                    theTML.Unit_Price__c = theTML.Regular_Rate__c;
    
                    if (theTML.Contract_Line__c == null) {
                        theTML.Contract_Overtime_Rate__c = 0;
                        theTML.Contract_Regular_Rate__c = 0;
                        theTML.Contract_Premium_Rate__c = 0;
                    }
                }
            } else if (theTML.Category__c == 'Equipment' || theTML.Category__c == 'Lump Sum') {
                theTML.Unit_Price__c = 0;
                if (mapResourceTypes.containsKey(theTML.Resource_Type__c)) {            
                    Resource_Type__c theResourceType = mapResourceTypes.get(theTML.Resource_Type__c);
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure1__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate1__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate1__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate1__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate1__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate1__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate1__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure2__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate2__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate2__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate2__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate2__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate2__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate2__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure3__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate3__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate3__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate3__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate3__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate3__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate3__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResourceType.Unit_of_Measure4__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate4__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate4__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate4__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Silver_Rate4__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Gold_Rate4__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResourceType.Platinum_Rate4__c);
                        }
                    }
                    if (theTML.Contract_Line__c == null) {
                        theTML.Contract_Overtime_Rate__c = 0;
                        theTML.Contract_Regular_Rate__c = 0;
                        theTML.Contract_Premium_Rate__c = 0;
                    }
                }
            } else if (theTML.Category__c == 'Materials') {
                theTML.Unit_Price__c = 0;
                if (mapResources.containsKey(theTML.Resource__c)) {
                    Resource__c theResource = mapResources.get(theTML.Resource__c);
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_ER_Rate__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_ER_Rate__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_ER_Rate__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_Rate__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_Rate__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_Rate__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure1__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_ER_Rate1__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_ER_Rate1__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_ER_Rate1__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_Rate1__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_Rate1__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_Rate1__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure2__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_ER_Rate2__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_ER_Rate2__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_ER_Rate2__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_Rate2__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_Rate2__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_Rate2__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure3__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_ER_Rate3__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_ER_Rate3__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_ER_Rate3__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_Rate3__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_Rate3__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_Rate3__c);
                        }
                    }
    
                    if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure4__c) {
                        //if (theTM.Emergency_TM__c == true) {
                        if (isSalesOrderER == true) { //AES-403
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_ER_Rate4__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_ER_Rate4__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_ER_Rate4__c);
                        } else {
                            if (theAccount.Pricing_Group__c == 'Silver') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Silver_Rate4__c); else if (theAccount.Pricing_Group__c == 'Gold') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Gold_Rate4__c); else if (theAccount.Pricing_Group__c == 'Platinum') theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theResource.Platinum_Rate4__c);
                        }
                    }
                    if (theTML.Contract_Line__c == null) {
                        theTML.Contract_Overtime_Rate__c = 0;
                        theTML.Contract_Regular_Rate__c = 0;
                        theTML.Contract_Premium_Rate__c = 0;
                    }
                }
            }
            //fix.001 <<
            else {
                theTML.Unit_Price__c = 0;
            }
            //fix.001 >>
        }
         */
    }
}