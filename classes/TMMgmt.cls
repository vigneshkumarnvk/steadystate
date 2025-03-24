public with sharing class TMMgmt {
    public static Map<Id, Resource__c> mapResource = new Map<Id, Resource__c>();
    public static Map<Id, Unit_of_Measure__c> mapUnitOfMeasures = new Map<Id, Unit_of_Measure__c>();
    public static Map<Id, Resource_Type__c> mapResourceType = new Map<Id, Resource_Type__c>();
    public static Map<Id, Account> mapAccount = new Map<Id, Account>();
    public static Map<Id, Service_Center__c> mapServiceCenter = new Map<Id, Service_Center__c>();
    //public static Map<Id, Contract_Line__c> mapCL = new Map<Id, Contract_Line__c>();
    public static Map<String, Decimal> mapSalesTax = new Map<String, Decimal>();
    //public static Boolean isReinsertSL = false;
    public static Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();
    /*
    public static Map<String, Sales_Line__c> mapSalesLine = new Map<String, Sales_Line__c>(); //Ticket#13762
    public static Map<String, Sales_Line__c> mapQuoteLine = new Map<String, Sales_Line__c>(); //Ticket#13762
    public static Map<Id, Sales_Order__c> mapSalesOrder = new Map<Id, Sales_Order__c>(); //AES-403
    public static Map<Id, Sales_Line__c> mapSL = new Map<Id, Sales_Line__c>();
    public static Map<Id, List<Sales_Line__c>> mapSLList = new Map<Id, List<Sales_Line__c>>();
    public static Map<Id, List<Sales_Line__c>> mapQLList = new Map<Id, List<Sales_Line__c>>();
    public static Map<Id, List<Contract_Line__c>> mapCLList = new Map<Id, List<Contract_Line__c>>(); //Ticket#13762
    public static Map<Id, Pay_Rule__c> payRulesByIds = new Map<Id, Pay_Rule__c>(); not used
    */
    public static Map<Date, String> mapHolidayDate = new Map<Date, String>(); //W00028
    //public static Map<String, Contract_Line__c> contractLineByContractByResORResTypeByUOM = new Map<String, Contract_Line__c>(); //Ticket14753
    public static Map<Id, Billing_Rule__c> billingRulesByIds = new Map<Id, Billing_Rule__c>();
    //Depreciated
    public static List <String> checkCreateInvoice(List<TM__c> theTMList, List<TM_Line__c> theTMLList) {
        List<String> errorList = new List<String>();
        /*
        Integer i;
        Set<Id> setTMId = new Set<Id>();
        Set<Id> setTMLIds = new Set<Id>();
        if (theTMLList == null || theTMLList.size() <= 0) {
            errorList.add('T&M Lines not found.');
        } else {
            for (i = 0; i < theTMList.size(); i++) {
                //Ticket#14585>>
                if(String.isBlank(theTMList[i].Bill_to_Customer__r.AccountNumber)){
                    errorList.add('Bill-to Customer\'s NAV Account Number cannot be blank.');
                }
                //Ticket#14585<<

                if (theTMList[i].Status__c != 'Ready to Bill' && theTMList[i].Status__c != 'Partially Invoiced' &&
                        theTMList[i].Status__c != 'Received By Billing' && theTMList[i].Status__c != 'Confirmed' ) {
                    errorList.add('T&M Status must be one of the following (Confirmed, Received By Billing, Partially Invoiced or Ready to Bill) in order for you to create Invoice.' + theTMList[i].Name + ' Status: ' + theTMList[i].Status__c);
                }
                if (theTMList[i].Bill_to_Customer__r.Payment_Term__c == null) {
                    errorList.add('Payment Term for Bill to Customer: ' + theTMList[i].Bill_to_Customer__r.Name + ' cannot be blank. TM: ' + theTMList[i].Name);
                }
                setTMId.add(theTMList[i].Id);
            }

            //Ticket#13457 >>
            for(TM_Line__c tml: theTMLList){
                if(CompanyMgmt.zeroIfNull(tml.Quantity__c) == 0){
                    errorList.add('You must enter Quantity for TM: ' + tml.TM__r.Name + ' Line No. ' + tml.Line_No__c);
                }

				setTMLIds.add(tml.Id);
                //Ticket#13858 >>
                if(tml.Quantity__c == null || tml.Unit_Price__c == null || tml.Line_Amount__c == null){
                    errorList.add('Please review T&M ' + tml.TM__r.Name + ' Line No. ' + tml.Line_No__c
                            + ' : Quantity and Unit Price must have a value');
                }
                //Ticket#13858 <<

                //Ticket AES-405 >>
                if ((tml.Bill_as_Lump_Sum__c == true || tml.Non_Billable__c == true) &&
                        (CompanyMgmt.zeroIfNull(tml.Line_Amount__c) != 0 || CompanyMgmt.zeroIfNull(tml.Line_Amt_Incl_Tax__c) != 0)){
                    errorList.add('Please review T&M ' + tml.TM__r.Name + ' Line No. ' + tml.Line_No__c
                            + ' : Line Amount must be Zero for Bundled or Non Billable line');
                }

                if ((tml.Bill_as_Lump_Sum__c == true || tml.Non_Billable__c == true) &&
                        (CompanyMgmt.zeroIfNull(tml.Regular_Rate__c) != 0 ||
                                CompanyMgmt.zeroIfNull(tml.Premium_Rate__c) != 0 ||
                                CompanyMgmt.zeroIfNull(tml.Overtime_Rate__c) != 0) &&
                        tml.Category__c == 'Labor'){
                    errorList.add('Please review T&M ' + tml.TM__r.Name + ' Line No. ' + tml.Line_No__c
                            + ' : all rates must be Zero for Bundled or Non Billable line');
                }
                //Ticket AES-405 <<

            }
            //Ticket#13457 <<

            List<TM_Line__c> theTMLListEquipment = [
                    SELECT Name, Rent_Billing_Type__c, Rent_Billing_Amount__c, Drop_Off_R_O__c, Pick_Up_R_O__c, TM__r.Sales_Order__c,
                            Pick_Up_R_O__r.Resource__c,
                            Pick_Up_R_O__r.Pick_Up_Date__c,
                            Pick_Up_Rental__c, Drop_Off_Rental__c,
                            Pick_Up_R_O__r.Sales_Order__c, Resource__c
                    FROM TM_Line__c
                    WHERE TM__c IN :setTMId AND Category__c = :'Equipment'
            ];

            for (TM_Line__c theTML : theTMLListEquipment) {
                if (theTML.Pick_Up_Rental__c == true && !Test.isRunningTest()) {
                    if (String.isEmpty(theTML.Pick_Up_R_O__c)) {
                        errorList.add('You must enter Pick Up Rental Order for Pickup Equipment Line: ' + theTML.Name);

                    } else {
                        if (theTML.TM__r.Sales_Order__c != theTML.Pick_Up_R_O__r.Sales_Order__c) {
                            errorList.add('Sales Order must be same on the Rental Order and on the Equipment Line: ' + theTML.Name);
                        }

                        if (theTML.Resource__c != theTML.Pick_Up_R_O__r.Resource__c) {
                            errorList.add('Resource must be same on the Rental Order and on the Equipment Line: ' + theTML.Name);
                        }

                        if (theTML.Pick_Up_R_O__r.Pick_Up_Date__c != null) {
                            errorList.add('Pick Up Date must be blank on the Rental Order on Equipment Line: ' + theTML.Name);
                        }
                    }
                }
            }
        }
        */
        return errorList;
    }

    /*Depreciated
    public static TM__c validateStartTime(TM__c theTM) {
        return theTM;
    }
     */


    //Depreciated
    public static TM__c validateTaxArea(TM__c theTM) {
        /*
        if (String.isEmpty(theTM.Tax_Area__c)) return theTM;
        else {
            Tax_Area__c TaxArea = [SELECT Id, Name FROM Tax_Area__c WHERE Id = :theTM.Tax_Area__c LIMIT 1];
            theTM.Tax_Area__r = new Tax_Area__c(Id = TaxArea.Id, Name = TaxArea.Name);
        }
         */
        return theTM;
    }

///////////////////////New Validation Function////////////////////////
    //Depreciated
    public static TM__c validateContact(TM__c theTM) {
        /*
        if (String.isEmpty(theTM.Contact__c)) return theTM;
        else {
            Contact con = [SELECT Id, FirstName, LastName FROM Contact WHERE Id = :theTM.Contact__c LIMIT 1];
            theTM.Contact__r = new Contact(Id = con.Id, FirstName = con.FirstName, LastName = con.LastName);
        }
         */
        return theTM;
    }

    //Depreciated
    public static TM__c nullRelationshipFields(TM__c theTM) {
        /*
        theTM.Account_Executive__r = null;
        theTM.Contact__r = null;
        theTM.Contract__r = null;
        theTM.Bill_to_Customer__r = null;
        theTM.Project_Coordinator__r = null;
        theTM.Sales_Order__r = null;
        theTM.Service_Center__r = null;
        theTM.Subsidiary_Company__r = null;
        theTM.Tax_Area__r = null;
        theTM.Alternate_Site_Address__r = null;
         */
        return theTM;
    }

    //Depreciated
    public static TM__c validateSalespeople(TM__c theTM) {
        /*
        if (String.isEmpty(theTM.Project_Coordinator__c) & String.isEmpty(theTM.Account_Executive__c)) {
            theTM.Project_Coordinator__r = null;
            theTM.Account_Executive__r = null;
            return theTM;
        }

        Salesperson__c pc, ae;

        if (String.isNotEmpty(theTM.Project_Coordinator__c)) {
            pc = [SELECT Id, Name FROM Salesperson__c WHERE Id = :theTM.Project_Coordinator__c];
        }

        if (String.isNotEmpty(theTM.Account_Executive__c)) {
            ae = [SELECT Id, Name FROM Salesperson__c WHERE Id = :theTM.Account_Executive__c];
        }

        if (pc != null) {
            theTM.Project_Coordinator__r = new Salesperson__c(id = pc.Id, Name = pc.Name);
        }

        if (ae != null) {
            theTM.Account_Executive__r = new Salesperson__c(id = ae.Id, Name = ae.Name);
        }
        */
        return theTM;
    }

    /* Depreciated
    public static TM__c validateServiceCenter(TM__c theTM) {

        if (String.isEmpty(theTM.Service_Center__c)) return theTM;
        else {
            Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Id = :theTM.Service_Center__c];
            theTM.Service_Center__r = new Service_Center__c(Id = sc.Id, Name = sc.Name);
        }

        return theTM;
    }
     */

    //Depreciated
    public static TM__c validateSalesOrder(TM__c theTM) {
        /*
        if (String.isEmpty(theTM.Sales_Order__c)) return theTM;
        else {
            Sales_Order__c salesOrder = [
                    SELECT Id, Name, Bill_to_Customer_No__c, Bill_to_Customer_No__r.Name, Site_City__c, Site_Contact__c, Emergency_Sales_Order__c,
                            Site_Country__c, Site_Email_Address__c, Site_Name__c, Site_Phone_No__c, Contract__c, From_Sales_Quote__c,
                            Site_Postal_Code__c, Site_Scope__c, Site_State__c, Site_Street__c, Customer_PO_No__c, Alternate_Site_Address__c,
                            Site_Contact_2__c, Bill_to_Contact__c
                    FROM Sales_Order__c
                    WHERE Id = :theTM.Sales_Order__c
                    LIMIT 1
            ];
            //theTM.Sales_Order__r = new Sales_Order__c(Id = salesOrder.Id, Name = salesOrder.Name);
            //Ticket# 13811 >>
            theTM.Sales_Order__r = new Sales_Order__c(Id = salesOrder.Id, Name = salesOrder.Name);
            theTM.Contract__c = salesOrder.Contract__c;
            theTM.From_Sales_Quote__c = salesOrder.From_Sales_Quote__c;
            //Ticket# 13811 >>
            theTM.Bill_to_Customer__c = salesOrder.Bill_to_Customer_No__c;
            theTM.Contact__c = salesOrder.Bill_to_Contact__c;
            theTM.Alternate_Site_Address__c = salesOrder.Alternate_Site_Address__c;
            //Site_Address__c altSiteAddress = [SELECT Name, Id FROM Site_Address__c WHERE Id = :theTM.Alternate_Site_Address__c];
            //theTM.Alternate_Site_Address__r = new Site_Address__c(Id = altSiteAddress.Id, Name = altSiteAddress.Name);
            theTM.Site_City__c = salesOrder.Site_City__c;
            theTM.Site_Contact__c = salesOrder.Site_Contact__c;
            theTM.Site_Contact_2__c = salesOrder.Site_Contact_2__c; //AES-401
            theTM.Site_Country__c = salesOrder.Site_Country__c;
            theTM.Site_Email_Address__c = salesOrder.Site_Email_Address__c;
            theTM.Site_Name__c = salesOrder.Site_Name__c;
            theTM.Site_Phone_No__c = salesOrder.Site_Phone_No__c;
            theTM.Site_Postal_Code__c = salesOrder.Site_Postal_Code__c;
            theTM.Site_Scope__c = salesOrder.Site_Scope__c;
            theTM.Site_State__c = salesOrder.Site_State__c;
            theTM.Site_Street__c = salesOrder.Site_Street__c;
            theTM.Customer_PO_No__c = salesOrder.Customer_PO_No__c;
        }
         */
        return theTM;
    }

    /* Depreciated
    public static List<TM_Line__c> validateTMLListWhileChangingSO(TM__c theTM, List<TM_Line__c> theTMLList){
        TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => theTMLList});

        for (TM_Line__c theTML : theTMLList) {
            theTML = setPricingSource(theTM, theTML);
            theTML = setPricing(theTML, theTM);
            setCost(theTM, theTML);
            if (theTM.Tax_Liable__c && theTML.Tax_Group__c != null){
                theTML.Tax_Pct__c = CompanyMgmt.getSalesTax(theTM.Tax_Area__c, theTML.Tax_Group__c);
            } else {
                theTML.Tax_Pct__c = 0;
            }

            //AES-443
            //theTML.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theTML.Unit_Cost__c) * companyMgmt.zeroIfNull(theTML.Quantity__c));
            theTML.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theTML.Unit_Cost__c) * companyMgmt.zeroIfNull(theTML.Cost_Qty__c));

            theTML.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theTML.Unit_Price__c) * companyMgmt.zeroIfNull(theTML.Quantity__c));

            Decimal Markup = 0;

            if (theTML.Markup_Option__c == '%') Markup = theTML.Line_Amount__c * companyMgmt.zeroIfNull(theTML.Markup__c) / 100;

            if (theTML.Markup_Option__c == 'Amount') Markup = companyMgmt.zeroIfNull(theTML.Markup__c);

            theTML.Line_Amount__c += Markup;
            theTML.Tax__c = CompanyMgmt.halfUpTo2D(theTML.Line_Amount__c * companyMgmt.zeroIfNull(theTML.Tax_Pct__c) / 100);
            theTML.Line_Amt_Incl_Tax__c = theTML.Line_Amount__c + theTML.Tax__c;
            System.debug(theTML.Line_Amount__c);
        }
        return theTMLList;
    }
     */
    
    //Depreciated
    public static TM__c validateAltSiteAddress(TM__c theTM) {
        /*
        if (String.isEmpty(theTM.Alternate_Site_Address__c)) {
            theTM.Alternate_Site_Address__r = null;
            theTM.Site_Name__c = '';
            theTM.Site_Contact__c = '';
            theTM.Site_Street__c = '';
            theTM.Site_Phone_No__c = '';
            theTM.Site_City__c = '';
            theTM.Site_Email_Address__c = '';
            theTM.Site_State__c = '';
            theTM.Site_Postal_Code__c = '';
            theTM.Tax_Liable__c = false;
            theTM.Tax_Area__c = null;
            theTM.Tax_Area__r = null;
            theTM.Site_Contact_2__c = null; //AES-401
            theTM.Site_Contact_2__r = null; //AES-401
            theTM.Site_Country__c = '';
            return theTM;
        }

        Site_Address__c altSiteAddress = [
                SELECT Name, Id, Site_City__c, Site_Contact__c, Site_Country__c, Site_Email_Address__c,Print_Site_Name__c,
                        Site_Phone_No__c, Site_Postal_Code__c, Site_State__c, Site_Street__c, Tax_Area__c, Tax_Area__r.Name,
                        Contact__c
                FROM Site_Address__c
                WHERE Id = :theTM.Alternate_Site_Address__c
        ];

        if (altSiteAddress != null) {
            theTM.Alternate_Site_Address__r = new Site_Address__c(Id = altSiteAddress.Id, Name = altSiteAddress.Name);

            theTM.Site_Name__c = altSiteAddress.Name;
            theTM.Site_Contact__c = altSiteAddress.Site_Contact__c;
            theTM.Site_Contact_2__c = altSiteAddress.Contact__c; //AES-401
            theTM.Site_Street__c = altSiteAddress.Site_Street__c;
            theTM.Site_Phone_No__c = altSiteAddress.Site_Phone_No__c;
            theTM.Site_City__c = altSiteAddress.Site_City__c;
            theTM.Site_Email_Address__c = altSiteAddress.Site_Email_Address__c;
            theTM.Site_State__c = altSiteAddress.Site_State__c;
            theTM.Site_Postal_Code__c = altSiteAddress.Site_Postal_Code__c;
            theTM.Tax_Area__c = altSiteAddress.Tax_Area__c;
            theTM.Tax_Area__r = new Tax_Area__c(Id = altSiteAddress.Tax_Area__c, Name = altSiteAddress.Tax_Area__r.Name);
            theTM.Site_Country__c = altSiteAddress.Site_Country__c;
            theTM.Print_Site_Name__c = altSiteAddress.Print_Site_Name__c;
        }
        */
        return theTM;
    }

    public static TM_Line__c updateTML(TM_Line__c theTML, TM__c theTM, String sourceField) {

        if(mapHolidayDate.isEmpty() && theTML.Scheduled_Date__c != null){
            getHolidayDateMap(new List<TM_Line__c>{theTML});
        }

        if (sourceField == 'theJobPosition') {
            theTML.Quantity__c = 0;
            theTML.Hour__c = 0;
            TMLLinesService.validateTMResourceType(theTM, theTML);
            /* Depreciated
            if (theTML.Billing_Start_Time__c != null && theTML.Billing_End_Time__c != null ){
                theTML = calculateNetHours(theTML, theTM);
            }
             */
        }
        /* Depreciated
        else if (sourceField == 'theServiceCenter') {
            Service_Center__c theServiceCenter;
            //Ticket# 13874
            if (!mapServiceCenter.containsKey(theTML.Service_Center__c)) {
                theServiceCenter = [
                        SELECT Id, Name, Temporary__c
                        FROM Service_Center__c
                        WHERE Id = :theTML.Service_Center__c
                        LIMIT 1
                ];
                mapServiceCenter.put(theTML.Service_Center__c, theServiceCenter);
            }
            theServiceCenter = mapServiceCenter.get(theTML.Service_Center__c);
            theTML.Service_Center__r = new Service_Center__c(Id = theServiceCenter.Id, Name = theServiceCenter.Name, Temporary__c = theServiceCenter.Temporary__c);
            theTML.Service_Center__r.Name = theServiceCenter.Name;

        }*/
        else if (sourceField == 'theResource'){
            /*|| sourceField == 'theLResource' || sourceField == 'theEResource' || sourceField == 'theMResource' ||
                sourceField == 'theFResource' || sourceField == 'theSResource' || sourceField == 'theWResource') {
             */
            Resource__c theResource;
            if (!mapResource.containsKey(theTML.Resource__c)) {
                theResource = CompanyMgmt.getResource(theTML.Resource__c);
                mapResource.put(theTML.Resource__c, theResource);
            }
            theResource = mapResource.get(theTML.Resource__c);
            theTML.Resource__r = new Resource__c(Id = theResource.Id, Name = theResource.Name);
            theTML.Resource__r.Name = theResource.Name;
            theTML.Resource_Name__c = theResource.Description__c;
            if (theTML.Category__c != 'Labor' && theTML.Category__c != 'Equipment') {
                theTML.Description__c = theResource.Description__c;
            } else {
                //13576
                theTML.Service_Center__c = theResource.Service_Center__c;
                //13576
            }
            theTML.Quantity__c = 0;
            theTML.Hour__c = 0;
            /*
            if (sourceField == 'theLResource') {
                if(String.isBlank(theTML.Resource_Type__c) == true) {
                    theTML.Resource_Type__r = new Resource_Type__c(Id = theResource.Resource_Type__c, Name = theResource.Resource_Type__r.Name);
                    theTML.Resource_Type__c = theResource.Resource_Type__c;
                    theTML = setResourceType(theTML, theTM);
                }
            } else if (sourceField == 'theEResource') {
                if(String.isBlank(theTML.Resource_Type__c) == true) {
                    theTML.Resource_Type__r = new Resource_Type__c(Id = theResource.Resource_Type__c, Name = theResource.Resource_Type__r.Name);
                    theTML.Resource_Type__c = theResource.Resource_Type__c;
                    theTML = setResourceType(theTML, theTM);
                }

                if (!String.isBlank(theTML.Unit_of_Measure__c)) {
                    Unit_of_Measure__c theUnitOfMeasure;
                    if (!mapUnitOfMeasures.containsKey(theTML.Unit_of_Measure__c)) {
                        theUnitOfMeasure = CompanyMgmt.getUnitOfMeasures(theTML.Unit_of_Measure__c);
                        mapUnitOfMeasures.put(theTML.Unit_of_Measure__c, theUnitOfMeasure);
                    }
                    theUnitOfMeasure = mapUnitOfMeasures.get(theTML.Unit_of_Measure__c);

                    if (theUnitOfMeasure.Hours_UOM__c == true) {
                        theTML.Quantity__c = companyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theTML.Total_Job_Hours__c));
                    } else {
                        theTML.Quantity__c = 1;
                    }
                }
            } else {
                if (theTML.Sales_Line__c == null && theTML.Contract_Line__c == null && theResource.Unit_of_Measure__c != null){
                    theTML.Unit_of_Measure__c = theResource.Unit_of_Measure__c;
                    theTML.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theResource.Unit_of_Measure__c, Name = theResource.Unit_of_Measure__r.Name);
                }
                theTML.Description__c = theResource.Description__c;
                theTML.Unit_Cost__c = theResource.Unit_Cost__c;
            }
             */
            if (theTML.Sales_Line__c == null && theTML.Contract_Line__c == null && theResource.Unit_of_Measure__c != null){
                theTML.Unit_of_Measure__c = theResource.Unit_of_Measure__c;
                theTML.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theResource.Unit_of_Measure__c, Name = theResource.Unit_of_Measure__r.Name);
            }
            theTML.Description__c = theResource.Description__c;
            theTML.Unit_Cost__c = theResource.Unit_Cost__c;

            if(theResource.Service_Center__c != null){
                Service_Center__c theServiceCenter;
                if (!mapServiceCenter.containsKey(theResource.Service_Center__c)) {
                    theServiceCenter = [
                            SELECT Id, Name, Temporary__c
                            FROM Service_Center__c
                            WHERE Id = :theResource.Service_Center__c
                            LIMIT 1
                    ];
                    mapServiceCenter.put(theResource.Service_Center__c, theServiceCenter);
                }
                theServiceCenter = mapServiceCenter.get(theResource.Service_Center__c);
                if(theTM.Status__c != 'Open' && theTM.Status__c != 'Scheduled'){
                    if((theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment') && theServiceCenter.Temporary__c != true){
                        throw new DataException('Only temporary resources are allowed after Mobile Review or Confirmed status');
                    }
                }
                theTML.Service_Center__r = new Service_Center__c(Id = theServiceCenter.Id, Name = theServiceCenter.Name, Temporary__c = theServiceCenter.Temporary__c);
                theTML.Service_Center__r.Name = theServiceCenter.Name;
            }
        }
        /* Depreciated
        else if (sourceField == 'theEquipment' || sourceField == 'theLumpSumResourceType') {
            theTML.Quantity__c = 0;
            theTML.Hour__c = 0;
            TMLLinesService.validateResourceType(theTM, theTML);
            if (theTML.Billing_Start_Time__c != null && theTML.Billing_End_Time__c != null ){
                theTML = calculateNetHours(theTML, theTM);
            }
        }

        if (sourceField == 'theUOM') {
            Unit_of_Measure__c theUOM = [SELECT Id, Name, Hours_UOM__c FROM Unit_of_Measure__c WHERE Id = :theTML.Unit_of_Measure__c LIMIT 1];
            theTML.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theUOM.Id, Name = theUOM.Name);
            theTML.Unit_of_Measure__c = theUOM.Id;

            //Moved to TMLLineService
            //theTML = setPricingSource(theTM, theTML);
            //theTML = setPricing(theTML, theTM);
            //setCost(theTM, theTML);
            //Moved to TMLLineService

            if (theTML.Category__c == ResourceService.LABOR_CATEGORY || theTML.Category__c == ResourceService.EQUIPMENT_CATEGORY || theTML.Category__c == ResourceService.DEMURRAGE_CATEGORY){
                if(theUOM.Hours_UOM__c != true && (theTML.Category__c == ResourceService.LABOR_CATEGORY || theTML.Category__c == ResourceService.EQUIPMENT_CATEGORY)){
                    theTML.Quantity__c = 1;
                }
                theTML = calculateNetHours(theTML, theTM);
            }
        }

        if (sourceField == 'theTaxGroup') {

            if (theTM.Tax_Liable__c && theTML.Tax_Group__c != null) theTML.Tax_Pct__c = CompanyMgmt.getSalesTax(theTM.Tax_Area__c, theTML.Tax_Group__c);

            else theTML.Tax_Pct__c = 0;
        }

        if (sourceField == 'theLunchStartTime' || sourceField == 'theLunchEndTime') {

            Decimal minutes = TimeUtils.calculateHours(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c) * 60;

            if (minutes == 0) theTML.Lunch__c = 'No';

            else if (minutes == 30) theTML.Lunch__c = '1/2 Hour';

            else if (minutes == 60) theTML.Lunch__c = '1 Hour';

            else theTML.Lunch__c = '';

            theTML = calculateNetHours(theTML, theTM);
        }

        if (sourceField == 'theSiteStartTime' || sourceField == 'theSiteEndTime') {
            theTML = populateBillingTimeInfo(theTML, theTM);
            theTML = calculateUnitPrice(theTML);
        }

        if (sourceField == 'theBillingStartTime' || sourceField == 'theBillingEndTime') {
            //Ticket#13764 >>
            if(theTML.Include_Lunch_Y_N__c == false){
                theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c) -
                    TMMgmt.calculateLunchHours(theTML.Lunch__c);
            } else {
                theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c);
            }
            //Ticket#13764 <<
            theTML = calculateQuantity(theTML);
            theTML = applyLaborBillingRule(theTML, theTM); //W00028

            Decimal minutes = TimeUtils.calculateHours(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c) * 60;

            if (minutes == 0) theTML.Lunch__c = 'No';

            else if (minutes == 30) theTML.Lunch__c = '1/2 Hour';

            else if (minutes == 60) theTML.Lunch__c = '1 Hour';

            else theTML.Lunch__c = '';
        }

        if (sourceField == 'theJobStartTime' || sourceField == 'theJobEndTime') {
            theTML = populateBillingTimeInfo(theTML, theTM);
            theTML = calculateUnitPrice(theTML);
        }

        if (sourceField == 'theLQuantity') {
            //AES-443
            theTML.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theTML.Unit_Cost__c) * companyMgmt.zeroIfNull(theTML.Cost_Qty__c));
        }

        if ((theTML.Category__c == 'Labor'|| theTML.Category__c == 'Equipment') && (sourceField == 'theSiteStartTime' || sourceField == 'theSiteEndTime' ||
                sourceField == 'theJobStartTime' || sourceField == 'theJobEndTime' ||
                sourceField == 'theLunchStartTime' || sourceField == 'theLunchEndTime' ||
                sourceField == 'theBillingStartTime' || sourceField == 'theBillingEndTime' ||
                sourceField == 'TimeValidation' || sourceField == 'theInclLunchYN')) {

            //Ticket# 13874 >>
            if(theTML.Category__c == 'Labor'){
                Decimal minutes = TimeUtils.calculateHours(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c) * 60;
                if (minutes == 0) {
                    theTML.Lunch__c = 'No';
                } else if (minutes == 30) {
                    theTML.Lunch__c = '1/2 Hour';
                } else if (minutes == 60) {
                    theTML.Lunch__c = '1 Hour';
                } else {
                    theTML.Lunch__c = '';
                }
            }
            //Ticket# 13874 <<

            theTML.Total_Job_Hours__c = TimeUtils.calculateHours(theTML.Job_Start_Time__c, theTML.Job_End_Time__c)
                    - calculateLunchHours(theTML.Lunch__c);
            theTML.Total_Site_Hours__c = TimeUtils.calculateHours(theTML.Site_Start_Time__c, theTML.Site_End_Time__c)
                    - calculateLunchHours(theTML.Lunch__c);

            if (theTML.Include_Lunch_Y_N__c == false || theTML.Category__c == 'Equipment') {
                theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c) -
                    TMMgmt.calculateLunchHours(theTML.Lunch__c);
            } else {
                theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c);
            }

            theTML = calculateQuantity(theTML);

            //Ticket#13673
            if ((theTML.Regular_Hours__c == 0 && theTML.Overtime_Hours__c == 0 && theTML.Premium_Hours__c == 0 && theTML.Category__c == 'Labor') ||
                    (sourceField == 'theInclLunchYN' || sourceField == 'theBillingStartTime' || sourceField == 'theBillingEndTime' || sourceField == 'TimeValidation')) {
                theTML = applyLaborBillingRule(theTML, theTM); //W00028
            }
        }

        if(sourceField == 'theELunch'){
            if (!String.isBlank(theTML.Unit_of_Measure__c)) {
                Unit_of_Measure__c theUnitOfMeasure;
                if (!mapUnitOfMeasures.containsKey(theTML.Unit_of_Measure__c)) {
                    theUnitOfMeasure = CompanyMgmt.getUnitOfMeasures(theTML.Unit_of_Measure__c);
                    mapUnitOfMeasures.put(theTML.Unit_of_Measure__c, theUnitOfMeasure);
                }
                theUnitOfMeasure = mapUnitOfMeasures.get(theTML.Unit_of_Measure__c);
                if (theUnitOfMeasure.Hours_UOM__c == true) {
                    theTML = calculateNetHours(theTML, theTM);
                }
            }
        }
        //AES-443
        if(sourceField == 'theQuantity'){
            theTML.Cost_Qty__c = calculateCostQy(theTML);
        }

        if ((theTML.Category__c == 'Demurrage') && (sourceField == 'theSiteStartTime' || sourceField == 'theSiteEndTime')) {
            theTML.Hour__c = TimeUtils.calculateHours(theTML.Site_Start_Time__c, theTML.Site_End_Time__c);
            theTML = calculateQuantity(theTML);
            if (theTML.Regular_Hours__c == 0 && theTML.Overtime_Hours__c == 0) {
                theTML.Regular_Hours__c = theTML.Hour__c;
                theTML.Overtime_Hours__c = 0;
            }
        }

        if ((theTML.Category__c == 'Equipment') && (sourceField == 'theJobStartTime' || sourceField == 'theJobEndTime')) {
            theTML.Hour__c = TimeUtils.calculateHours(theTML.Job_Start_Time__c, theTML.Job_End_Time__c);
            theTML = calculateQuantity(theTML);
            if (theTML.Regular_Hours__c == 0 && theTML.Overtime_Hours__c == 0) {
                theTML.Regular_Hours__c = theTML.Hour__c;
                theTML.Overtime_Hours__c = 0;
            }
        }

        theTML.Regular_Rate__c = CompanyMgmt.zeroIfNull(theTML.Regular_Rate__c);
        theTML.Overtime_Rate__c = CompanyMgmt.zeroIfNull(theTML.Overtime_Rate__c);
        theTML.Premium_Rate__c = CompanyMgmt.zeroIfNull(theTML.Premium_Rate__c); //Ticket#13673

        if(theTML.Category__c == 'Labor' &&
                (sourceField == 'theRegularHour' || sourceField == 'theRegularRate' ||
                        sourceField == 'theOvertimeHour' || sourceField == 'theOvertimeRate' ||
                        sourceField == 'thePremiumRate' || sourceField == 'thePremiumHours')){

            theTML = calculateUnitPrice(theTML);
            if (sourceField == 'theRegularRate' || sourceField == 'theOvertimeRate' || sourceField == 'thePremiumRate'){
                theTML.Pricing_Source_2__c = null;
            }
        }

        if (sourceField == 'theUnitPrice') {// W-000167
            theTML.Pricing_Source_2__c = null;
        }

        if (sourceField == 'theLContractLine' || sourceField == 'theEContractLine' || sourceField == 'theMContractLine' ||
                sourceField == 'theLumpSumContractLine') {
            Contract_Line__c theCL;
            if (!mapCL.containsKey(theTML.Contract_Line__c)) {
                theCL = [
                        SELECT Id, Name, Resource_Type__c, Unit_of_Measure__c,Resource__c,Resource__r.Description__c,
                                Resource_Type__r.Name, Unit_of_Measure__r.Name, Resource__r.Name,Resource_Type__r.Description__c,
                                Overtime_Rate__c, Premium_Rate__c, Regular_Rate__c, Customer_Description__c
                        FROM Contract_Line__c
                        WHERE Id = :theTML.Contract_Line__c
                        LIMIT 1
                ];
                mapCL.put(theTML.Contract_Line__c, theCL);
            }
            theCL = mapCL.get(theTML.Contract_Line__c);
            theTML.Contract_Line__r = new Contract_Line__c(Id = theCL.Id, Name = theCL.Name);
            theTML.Contract_Line__r.Name = theCL.Name;
            theTML.Unit_of_Measure__c = theCL.Unit_of_Measure__c;
            Unit_of_Measure__c theUOM = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Id = : theCL.Unit_of_Measure__c LIMIT 1];
            theTML.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theUOM.Id, Name = theUOM.Name);
            theTML.Contract_Overtime_Rate__c = theCL.Overtime_Rate__c;
            theTML.Contract_Premium_Rate__c = theCL.Premium_Rate__c;
            theTML.Contract_Regular_Rate__c = theCL.Regular_Rate__c;

            if (sourceField == 'theMContractLine') {
                theTML.Resource__c = theCL.Resource__c;
                theTML.Resource__r = new Resource__c(Id = theCL.Resource__c, Name = theCL.Resource__r.Name);
                theTML.Resource__r.Name = theCL.Resource__r.Name;
                theTML.Resource_Name__c = theCL.Resource__r.Description__c;
                theTML.Description__c = theCL.Resource__r.Description__c;
                theTML.Unit_Price__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                if (String.isNotBlank(theCL.Customer_Description__c)) theTML.Description__c = theCL.Customer_Description__c;
            } else if (sourceField == 'theLContractLine' || sourceField == 'theEContractLine' || sourceField == 'theLumpSumContractLine') {
                theTML.Resource_Type__c = theCL.Resource_Type__c;
                theTML.Resource_Type__r = new Resource_Type__c(Id = theCL.Resource_Type__c, Name = theCL.Resource_Type__r.Name);
                theTML.Resource_Type__r.Name = theCL.Resource_Type__r.Name;
                theTML.Description__c = theCL.Resource_Type__r.Description__c;
                if (theTML.Category__c == 'Labor') {
                    theTML.Regular_Rate__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                    theTML.Premium_Rate__c = companyMgmt.zeroIfNull(theCL.Premium_Rate__c);
                    theTML.Overtime_Rate__c = companyMgmt.zeroIfNull(theCL.Overtime_Rate__c);
                    theTML = calculateUnitPrice(theTML);
                } else {
                    theTML.Unit_Price__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                }
                if (String.isNotBlank(theCL.Customer_Description__c)) theTML.Description__c = theCL.Customer_Description__c;
            }
        }

        if (sourceField == 'theBillSiteTime') {
            theTML = populateBillingTimeInfo(theTML, theTM);
            theTML = calculateUnitPrice(theTML);
        }

        if (sourceField == 'theLBillasLumpSum' || sourceField == 'theLNonBillable') { // 14250
            if (theTML.Bill_as_Lump_Sum__c == true || theTML.Non_Billable__c == true) { //Ticket#14070
                theTML.xRegular_Rate__c = theTML.Regular_Rate__c;
                theTML.xOvertime_Rate__c = theTML.Overtime_Rate__c;
                theTML.xPremium_Rate__c = theTML.Premium_Rate__c;
                theTML.xUnit_Price__c = theTML.Unit_Price__c;
                theTML.Regular_Rate__c = 0;
                theTML.Overtime_Rate__c = 0;
                theTML.Premium_Rate__c = 0;
                theTML.Use_Premium_Rate__c = false;
                theTML.Unit_Price__c = 0; //Ticket#14070
                theTML = calculateUnitPrice(theTML);
            } else {
                theTML.Regular_Rate__c = theTML.xRegular_Rate__c;
                theTML.Overtime_Rate__c = theTML.xOvertime_Rate__c;
                theTML.Premium_Rate__c = theTML.xPremium_Rate__c;
                theTML.Use_Premium_Rate__c = false;
                theTML = calculateUnitPrice(theTML);
            }
        }

        if (sourceField == 'theEBillasLumpSum' || sourceField == 'theENonBillable' ||
                sourceField == 'theMBillasLumpSum' || sourceField == 'theMNonBillable' ||
                sourceField == 'theSBillasLumpSum' || sourceField == 'theSNonBillable' ||
                sourceField == 'theWBillasLumpSum' || sourceField == 'theWNonBillable' ||
                sourceField == 'theDBillasLumpSum' || sourceField == 'theDNonBillable' ||
                sourceField == 'theMiscBillasLumpSum' || sourceField == 'theMiscNonBillable') {
            if (theTML.Bill_as_Lump_Sum__c == true || theTML.Non_Billable__c == true){
                if(CompanyMgmt.zeroIfNull(theTML.Unit_Price__c) > 0) theTML.xUnit_Price__c = theTML.Unit_Price__c; //Ticket#15685
                theTML.Unit_Price__c = 0;
            } else {
                theTML.Unit_Price__c = theTML.xUnit_Price__c;
            }
        }

        //Trigger when save - should only be called when Status = Open or Scheduled
        //Ticket#13719
        if(sourceField == 'TimeValidation') {
            if ((theTM.Status__c != null && (theTM.Status__c == 'Open' || theTM.Status__c == 'Scheduled' || theTM.Status__c == 'Mobile Review') && (theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment'))){

                if(theTML.Category__c == 'Labor'){
                    Decimal minutes = TimeUtils.calculateHours(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c) * 60; //Ticket#13838

                    if (minutes == 0) theTML.Lunch__c = 'No';

                    else if (minutes == 30) theTML.Lunch__c = '1/2 Hour';

                    else if (minutes == 60) theTML.Lunch__c = '1 Hour';

                    else theTML.Lunch__c = '';
                }

                //Populate Billing Time
                if (theTML.Bill_Site_Time__c) {
                    theTML.Bill_Site_Time__c = true;
                    theTML.Billing_Start_Time__c = theTML.Site_Start_Time__c;
                    theTML.Billing_End_Time__c = theTML.Site_End_Time__c;
                } else {
                    theTML.Bill_Site_Time__c = false;
                    theTML.Billing_Start_Time__c = theTML.Job_Start_Time__c;
                    theTML.Billing_End_Time__c = theTML.Job_End_Time__c;
                }
                //Populate Hours
                //Ticket#13764 >>
                if(theTML.Include_Lunch_Y_N__c == false){
                    theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c) -
                            TMMgmt.calculateLunchHours(theTML.Lunch__c);
                } else {
                    theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c);
                }
                //Ticket#13764 <<
                //Populate Qty
                theTML = calculateQuantity(theTML);
                theTML = applyLaborBillingRule(theTML, theTM); //W00028
                // Calculate Lunch
                theTML = TMMgmt.calculateUnitPrice(theTML);
            }
        }

        Decimal taxRate = CompanyMgmt.getSalesTax(theTM.Tax_Area__c, theTML.Tax_Group__c);
        if (theTM.Tax_Liable__c && theTML.Tax_Group__c != null){
            theTML.Tax_Pct__c = taxRate;
        } else {
            theTML.Tax_Pct__c = 0;
        }

        if(theTML.Category__c == 'Subcontractors'){
            if(theTML.Bill_as_Lump_Sum__c == true || theTML.Non_Billable__c == true) {
                theTML.Unit_Cost__c = theTML.xUnit_Price__c;
            } else {
                theTML.Unit_Cost__c = theTML.Unit_Price__c;
            }
        }

        //aura << use the new calcTotal function
        Map<TM__c, List<TM_Line__c>> mapTMLinesByTM = new Map<TM__c, List<TM_Line__c>>();
        mapTMLinesByTM.put(theTM, new List<TM_Line__c> { theTML });
        TMLLinesService.calcTotals(mapTMLinesByTM);
        //aura >>
         */
        return theTML;
    }

    //Depreciated
    public static TM_Line__c populateBillingTimeInfo(TM_Line__c theTML, TM__c tm) {
        /*
        if (theTML.Bill_Site_Time__c) {
            theTML.Bill_Site_Time__c = true;
            theTML.Billing_Start_Time__c = theTML.Site_Start_Time__c;
            theTML.Billing_End_Time__c = theTML.Site_End_Time__c;
        } else {
            theTML.Bill_Site_Time__c = false;
            theTML.Billing_Start_Time__c = theTML.Job_Start_Time__c;
            theTML.Billing_End_Time__c = theTML.Job_End_Time__c;
        }

        theTML = calculateNetHours(theTML, tm);
         */
        return theTML;
    }

    /*Depreciated
    public static TM_Line__c calculateNetHours(TM_Line__c theTML, TM__c tm) {
        //Ticket#13764 >>
        if (theTML.Include_Lunch_Y_N__c == false || theTML.Category__c == 'Equipment') {
            theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c) -
                    TMMgmt.calculateLunchHours(theTML.Lunch__c);
        } else {
            theTML.Hour__c = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c);
        }

        //Ticket#13764 <<
        theTML = calculateQuantity(theTML);

        if(theTML.Category__c == 'Labor') theTML = applyLaborBillingRule(theTML, tm); //W00028
        return theTML;
    }
     */

    //Depreciated
    public static TM_Line__c calculateQuantity(TM_Line__c theTML) {
        /*
        if (!String.isBlank(theTML.Unit_of_Measure__c)) {
            Unit_of_Measure__c theUnitOfMeasure;
            if (!mapUnitOfMeasures.containsKey(theTML.Unit_of_Measure__c)) {
                theUnitOfMeasure = CompanyMgmt.getUnitOfMeasures(theTML.Unit_of_Measure__c);
                mapUnitOfMeasures.put(theTML.Unit_of_Measure__c, theUnitOfMeasure);
            }
            theUnitOfMeasure = mapUnitOfMeasures.get(theTML.Unit_of_Measure__c);
            if (theUnitOfMeasure.Hours_UOM__c == true) {
                theTML.Quantity__c = companyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theTML.Hour__c));
            }
        }

        //AES-443
        theTML.Cost_Qty__c = calculateCostQy(theTML);
        */
        return theTML;
    }

    //Depreciated
    public static TM_Line__c calculateUnitPrice(TM_Line__c theTML) {
        /*
        if (theTML.Category__c != 'Labor') return theTML;
        //Skip if UOM is not Hours UOM
        if (!String.isBlank(theTML.Unit_of_Measure__c)) {
            Unit_of_Measure__c theUnitOfMeasure;
            if (!mapUnitOfMeasures.containsKey(theTML.Unit_of_Measure__c)) {
                theUnitOfMeasure = CompanyMgmt.getUnitOfMeasures(theTML.Unit_of_Measure__c);
                mapUnitOfMeasures.put(theTML.Unit_of_Measure__c, theUnitOfMeasure);
            }
            theUnitOfMeasure = mapUnitOfMeasures.get(theTML.Unit_of_Measure__c);
            if (!theUnitOfMeasure.Hours_UOM__c) {
                return theTML;
            }
        }
        //Calculate Unit Price
        Decimal totalHours = 0;
        Decimal totalPrice = 0;

        //Ticket#13673 >>
        totalPrice = (CompanyMgmt.zeroIfNull(theTML.Regular_Hours__c) * CompanyMgmt.zeroIfNull(theTML.Regular_Rate__c)) +
                (CompanyMgmt.zeroIfNull(theTML.Overtime_Hours__c) * CompanyMgmt.zeroIfNull(theTML.Overtime_Rate__c)) +
                (CompanyMgmt.zeroIfNull(theTML.Premium_Hours__c) * CompanyMgmt.zeroIfNull(theTML.Premium_Rate__c));

        totalHours = CompanyMgmt.zeroIfNull(theTML.Regular_Hours__c) + CompanyMgmt.zeroIfNull(theTML.Overtime_Hours__c) +
                CompanyMgmt.zeroIfNull(theTML.Premium_Hours__c);
        //Ticket#13673 <<

        if (totalHours != 0) {
            theTML.Unit_Price__c = companyMgmt.halfUpTo5D(totalPrice / totalHours);
        } else {
            theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theTML.Regular_Rate__c);
        }

        if(theTML.Non_Billable__c == true || theTML.Bill_as_Lump_Sum__c == true){
            theTML.xUnit_Price__c = theTML.Unit_Price__c;
            theTML.Unit_Price__c = 0;
        }
        */
        return theTML;
    }

    public static Decimal calculateLunchHours(String lunchString) {
        Decimal hours = 0;
        if (lunchString == '1/2 Hour') {
            hours = 0.5;
        } else if (lunchString == '1 Hour') {
            hours = 1;
        }
        return hours;
    }

    /* Depreciated
    public static Decimal calculateCostQy(TM_Line__c theTML){
        System.debug('Info: calculateCostQy');
        Decimal costQty = 0;
        if(String.isNotBlank(theTML.Unit_of_Measure__c)) {
            Unit_of_Measure__c theUnitOfMeasure;
            if (!mapUnitOfMeasures.containsKey(theTML.Unit_of_Measure__c)) {
                theUnitOfMeasure = CompanyMgmt.getUnitOfMeasures(theTML.Unit_of_Measure__c);
                mapUnitOfMeasures.put(theTML.Unit_of_Measure__c, theUnitOfMeasure);
            }
            theUnitOfMeasure = mapUnitOfMeasures.get(theTML.Unit_of_Measure__c);

            if ((theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment') && (theUnitOfMeasure.Hours_UOM__c == true)) {
                //&& (theTML.Unit_of_Measure__r.Hours_UOM__c == true || (theTML.Job_Start_Time__c != null && theTML.Job_End_Time__c != null))) {
                costQty = TimeUtils.calculateHours(theTML.Job_Start_Time__c, theTML.Job_End_Time__c) -
                        TMMgmt.calculateLunchHours(theTML.Lunch__c);
            }
        }

        if(costQty == 0){
            costQty = CompanyMgmt.zeroIfNull(theTML.Quantity__c);
        }

        return costQty;
    }
     */

    //Depreciated
    public static Boolean validateTime(String fieldValue) {
        /*
        if (String.isEmpty(fieldValue)) return false;

        List<String> theTime = new List<String>();
        Integer hrs;
        Integer min;

        if (!fieldValue.contains(':')) return false;

        theTime = fieldValue.split(':');
        hrs = Integer.valueOf(theTime[0]);
        min = Integer.valueOf(theTime[1]);

        if (hrs > 23) return false;

        if (min > 59) return false;
        */
        return true;
    }

    /*Depreciated
    public static TM_Line__c setResourceType(TM_Line__c theTML, TM__c theTM) {
        Resource_Type__c theResourceType;
        if(!String.isEmpty(theTML.Resource_Type__c)) {
            if (!mapResourceType.containsKey(theTML.Resource_Type__c)) {
                theResourceType = CompanyMgmt.getResourceType(theTML.Resource_Type__c);
                mapResourceType.put(theTML.Resource_Type__c, theResourceType);
            }
            theResourceType = mapResourceType.get(theTML.Resource_Type__c);

            theTML.Resource_Type__r = new Resource_Type__c(Id = theResourceType.Id, Name = theResourceType.Name);
            theTML.Resource_Type__r.Name = theResourceType.Name;
            theTML.Description__c = theResourceType.Description__c;
            //if (String.isBlank(theTML.Sales_Line__c) && String.isBlank(theTML.Contract_Line__c) && String.isBlank(theTML.Unit_of_Measure__c)) {
            if (String.isBlank(theTML.Unit_of_Measure__c)) {
                theTML.Unit_of_Measure__c = theResourceType.Unit_of_Measure__c;
                theTML.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theResourceType.Unit_of_Measure__c, Name = theResourceType.Unit_of_Measure__r.Name);
                System.debug('Info: setResourceType: ' + theTML.Unit_of_Measure__c + ' -- ' + theTML.Unit_of_Measure__r.Name);
            }
            if(theTML.Resource__c == null) theTML.Unit_Cost__c = theResourceType.Unit_Cost__c; //14984
        }
        return theTML;
    }
     */

    /*
    Moved to TMLLinesService
     */
    public static TM_Line__c setPricing(TM_Line__c theTML, TM__c theTM) {
        return theTML;
    }

    /*Depreciated
    public static TM__c validateCreateSiteAddress(TM__c theTM) {
        if (theTM.Create_Site_Address__c && String.isEmpty(theTM.Alternate_Site_Address__c)) {
            if(String.isBlank(theTM.Site_Name__c)){
                throw new DataException('Site Name must not be blank');
            }
            Site_Address__c altSiteAddress = new Site_Address__c();
            altSiteAddress.Customer__c = theTM.Bill_to_Customer__c;
            altSiteAddress.Name = theTM.Site_Name__c;
            altSiteAddress.Site_Contact__c = theTM.Site_Contact__c;
            altSiteAddress.Contact__c = theTM.Site_Contact_2__c; //AES-401
            altSiteAddress.Site_Street__c = theTM.Site_Street__c;
            altSiteAddress.Site_City__c = theTM.Site_City__c;
            altSiteAddress.Site_State__c = theTM.Site_State__c;
            altSiteAddress.Site_Country__c = theTM.Site_Country__c;
            altSiteAddress.Site_Postal_Code__c = theTM.Site_Postal_Code__c;
            altSiteAddress.Site_Phone_No__c = theTM.Site_Phone_No__c;
            altSiteAddress.Site_Email_Address__c = theTM.Site_Email_Address__c;
            altSiteAddress.Tax_Area__c = theTM.Tax_Area__c;
            altSiteAddress.Print_Site_Name__c = theTM.Print_Site_Name__c;

            insert altSiteAddress;

            theTM.Alternate_Site_Address__c = altSiteAddress.Id;
            return theTM;
        }

        return theTM;
    }
     */

    public static List<TM__c> updateTMStatus(List<TM__c> theTMList) {
        for (TM__c TM : theTMList) {
            //job task <<
            /*
            if (TM.Invoiced_Lines__c == 0) {
                TM.Status__c = 'Ready to Bill';
            } else if (TM.Total_Lines__c == TM.Invoiced_Lines__c){
                TM.Status__c = 'Fully Invoiced';
            } else {
                TM.Status__c = 'Partially Invoiced';
            }
            */
            if (TM.Total_Lines__c == TM.Invoiced_Lines__c) {
                TM.Status__c = 'Fully Invoiced';
            }
            else {
                TM.Status__c = 'Confirmed';
            }
            //job task >>
        }
        return theTMList;
    }

    /* Depreciated
    public static void applyBillingRules(List<TM_Line__c> tmLines, Map<Id, TM__c> tmsByIds){
        getHolidayDateMap(tmLines);
        for(TM_Line__c tmLine:tmLines){
            TM__c tm = tmsByIds.get(tmLine.TM__c);
            switch on tmLine.Category__c{
                when 'Labor'{
                    if(tm.Status__c == 'Confirmed'){
                        tmLine = applyLaborBillingRule(tmLine, tm);
                    }
                }
            }
        }
    }
     */

    //W00028
    public static TM_Line__c applyLaborBillingRule(TM_Line__c tmLine, TM__c tm){
        /*
        if(tm.Sales_Order__r.Billing_Rule_Not_Required__c == true){
            return tmLine;
        }

        Id billingRuleId = null;
        if(tm.Billing_Rule_Id__c != null) {
            billingRuleId = tm.Billing_Rule_Id__c;
        }

        if (billingRuleId == null && (tmLine.TM__r.Sales_Order__r.Portal_Basis__c == true || tmLine.TM__r.Sales_Order__r.Overtime_Rate__c == true)) {
            System.debug('Info: OT over 8 ');
            if (tm.Status__c == 'Confirmed' || (tm.Billing_Rule_Id__c == null && tm.Contract__c == null)) {
                if (tmLine.Hour__c > 8) {
                    tmLine.Regular_Hours__c = 8;
                    tmLine.Overtime_Hours__c = tmLine.Hour__c - tmLine.Regular_Hours__c;
                    tmLine.Premium_Hours__c = 0;
                } else {
                    tmLine.Regular_Hours__c = tmLine.Hour__c;
                    tmLine.Overtime_Hours__c = 0;
                    tmLine.Premium_Hours__c = 0;
                }
            }
        } else if (tmLine.TM__r.Sales_Order__r.Daily_Rate__c == true){
            if (tmLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                if (tmLine.Hour__c > 10) {
                    tmLine.Regular_Hours__c = 10;
                    tmLine.Overtime_Hours__c = tmLine.Hour__c - tmLine.Regular_Hours__c;
                    tmLine.Premium_Hours__c = 0;
                } else {
                    tmLine.Regular_Hours__c = tmLine.Hour__c;
                    tmLine.Overtime_Hours__c = 0;
                    tmLine.Premium_Hours__c = 0;
                }
            }
        } else if (tmLine.Billing_Start_Time__c != null && tmLine.Billing_End_Time__c != null) {
            //if no billing rule setup in Sales Order/Contract
            //user company default billing rule
            if(billingRuleId == null){
                billingRuleId = theCompanySetup.Default_Billing_Rule__c;
            }

            if(Test.isRunningTest() == false) {
                if (billingRuleId == null) {
                    throw (Exception) new DataException('Please contact your system administrator! Default Billing Rule is not setup!');
                }

                if(!billingRulesByIds.containsKey(billingRuleId)){
                    BillingRulesSelector billingRulesSelector = new BillingRulesSelector();
                    List<Billing_Rule__c> billingRules = billingRulesSelector.selectByIdsWithLines(new Set<Id>{
                            billingRuleId
                    });
                    if (billingRules.size() > 0) {
                        billingRulesByIds.put(billingRules[0].Id, billingRules[0]);
                    }
                }

                if (billingRulesByIds.containsKey(billingRuleId)) {
                    Billing_Rule__c billingRule = billingRulesByIds.get(billingRuleId);
                    applyBillingRuleDetail(tm, tmLine, billingRule);
                }
            }
            if (tmLine.TM__r.Sales_Order__r.Lump_Sum__c == true) {
                if (tm.Status__c == 'Confirmed') {
                    //setPricing(tmLine, tm);
                    //tmLine = calculateUnitPrice(tmLine);
                    tmLine.Bill_as_Lump_Sum__c = true;
                    //updateTML(tmLine, tm, 'theLBillasLumpSum');
                }
            }
        }
         */
        return tmLine;
    }

    /*
    public static void applyBillingRuleDetail(TM__c tm, TM_Line__c tmLine, Billing_Rule__c billingRule){
        String dayName = '';
        if (tm.Scheduled_Date__c != null) {
            dayName = TimeUtils.getDatetimeInUserTZ(tm.Scheduled_Date__c).format('EEEE');
        }
        BillingRule billingRule2 = new BillingRule(billingRule, mapHolidayDate);
        Map<String, Decimal> hoursByRateCodes = billingRule2.getHoursWithRateCodes(
                tm.Scheduled_Date__c,
                tmLine.Billing_Start_Time__c,
                tmLine.Billing_End_Time__c,
                tmLine.Lunch_Start_Time__c,
                tmLine.Lunch_End_Time__c,
                tmLine.Include_Lunch_Y_N__c);

        for(String rateCode : hoursByRateCodes.keySet()){
            Decimal hrs = hoursByRateCodes.get(rateCode);
            if(rateCode == EnumUtil.TimeRateCode.REG.name()) tmLine.Regular_Hours__c = hrs;
            if(rateCode == EnumUtil.TimeRateCode.OT.name()) tmLine.Overtime_Hours__c = hrs;
            if(rateCode == EnumUtil.TimeRateCode.DT.name()) tmLine.Premium_Hours__c = hrs;
        }

        if(CompanyMgmt.zeroIfNull(tmLine.Hour__c) > 0 && (tmLine.Regular_Hours__c > 0 || tmLine.Overtime_Hours__c > 0 || tmLine.Premium_Hours__c > 0)){
            Decimal difference = 0;
            difference = tmLine.Hour__c - tmLine.Regular_Hours__c - tmLine.Overtime_Hours__c - tmLine.Premium_Hours__c;
            Decimal absDifference = Math.abs(difference);
            if(absDifference != 0 && absDifference == 0.01){
                if(difference > 0){
                    tmLine.Hour__c -= difference;
                } else {
                    tmLine.Hour__c += absDifference;
                }
                tmLine.Quantity__c = tmLine.Hour__c;
            }
        }

        if(CompanyMgmt.zeroIfNull(tmLine.Hour__c) > 0 && tmLine.Regular_Hours__c == 0 && tmLine.Overtime_Hours__c == 0 && tmLine.Premium_Hours__c == 0){
            if (dayName == 'Sunday') {
                switch on billingRule.Sunday_Rate_Code__c{
                    when 'DT' {
                        tmLine.Premium_Hours__c = tmLine.Hour__c;
                        tmLine.Regular_Hours__c = 0;
                        tmLine.Overtime_Hours__c = 0;
                    }
                    when 'OT' {
                        tmLine.Overtime_Hours__c = tmLine.Hour__c;
                        tmLine.Premium_Hours__c = 0;
                        tmLine.Regular_Hours__c = 0;
                    }
                    when else {
                        tmLine.Regular_Hours__c = tmLine.Hour__c;
                        tmLine.Premium_Hours__c = 0;
                        tmLine.Overtime_Hours__c = 0;
                    }
                }
            } else if (dayName == 'Saturday') {
                switch on billingRule.Saturday_Rate_Code__c{
                    when 'DT' {
                        tmLine.Premium_Hours__c = tmLine.Hour__c;
                        tmLine.Regular_Hours__c = 0;
                        tmLine.Overtime_Hours__c = 0;
                    }
                    when 'OT' {
                        tmLine.Overtime_Hours__c = tmLine.Hour__c;
                        tmLine.Premium_Hours__c = 0;
                        tmLine.Regular_Hours__c = 0;
                    }
                    when else {
                        tmLine.Regular_Hours__c = tmLine.Hour__c;
                        tmLine.Premium_Hours__c = 0;
                        tmLine.Overtime_Hours__c = 0;
                    }
                }
            } else {
                Decimal totalHrs = tmLine.Hour__c;
                Decimal otHours = 0;
                Decimal dtHours = 0;
                Decimal calcBeforeHrs = 0;
                Decimal calcAfterHrs = 0;

                if(billingRule.Time_Before__c != null && billingRule.Time_After__c != null){
                    Map<String, Map<Time, Time>> calcTimeSegmentMap = calcTimeSegment(tmLine.Billing_Start_Time__c, tmLine.Billing_End_Time__c, billingRule.Time_Before__c, billingRule.Time_After__c);
                    for(String mapKey:calcTimeSegmentMap.keySet()){
                        Map<Time, Time> timeSegments = calcTimeSegmentMap.get(mapKey);
                        for(Time startTime:timeSegments.keySet()){
                            Time endTime = timeSegments.get(startTime);
                            if(mapKey == 'Before'){
                                calcBeforeHrs += TimeUtils.calculateHours(startTime, endTime);
                            } else if(mapKey == 'After'){
                                calcAfterHrs += TimeUtils.calculateHours(startTime, endTime);
                            }
                        }
                    }

                    if(billingRule.Time_Before_Rate_Code__c == EnumUtil.TimeRateCode.OT.name()) otHours += calcBeforeHrs;
                    if(billingRule.Time_Before_Rate_Code__c == EnumUtil.TimeRateCode.DT.name()) dtHours += calcBeforeHrs;

                    if(billingRule.Time_After_Rate_Code__c == EnumUtil.TimeRateCode.OT.name()) otHours += calcAfterHrs;
                    if(billingRule.Time_After_Rate_Code__c == EnumUtil.TimeRateCode.DT.name()) dtHours += calcAfterHrs;

                    totalHrs = totalHrs - otHours - dtHours;
                    if (totalHrs > 8) {
                        otHours = otHours + (totalHrs - 8);
                        totalHrs = 8;
                    }
                }
                tmLine.Regular_Hours__c = totalHrs;
                tmLine.Overtime_Hours__c = otHours;
                tmLine.Premium_Hours__c = dtHours;
            }
        }
        //}
    }

    public static Map<String, Map<Time, Time>> calcTimeSegment(Time startTime, Time endTime, Time beforeTimeBreak, Time afterTimeBreak){
        Map<String, Map<Time, Time>> timeSegmentMap = new Map<String, Map<Time, Time>>();
        Map<Time, Time> beforeTimeMap = new Map<Time, Time>();
        Map<Time, Time> afterTimeMap = new Map<Time, Time>();

        if(startTime == endTime){
            beforeTimeMap.put(TimeUtils.midNight(), beforeTimeBreak);
            afterTimeMap.put(afterTimeBreak, TimeUtils.midNight());
            timeSegmentMap.put('Before', beforeTimeMap);
            timeSegmentMap.put('After', afterTimeMap);
        }
        //break before 7:00
        //break after 15:30
        //entry 17:00 - 21:00 should return after => 17:00 - 21:00
        //entry 17:00 - 06:00 should return after => 17:00 - 00:00, before => 00:00 - 06:00
        //entry 17:00 - 09:00 should return after => 17:00 - 00:00, before => 00:00 - 07:00
        else if(startTime >= afterTimeBreak){
            if(endTime > startTime || endTime == TimeUtils.midNight()){
                afterTimeMap.put(startTime, endTime);
            } else{
                //cross midnight
                afterTimeMap.put(startTime, TimeUtils.midNight());
                timeSegmentMap.put('After', afterTimeMap);
                if(endTime < beforeTimeBreak) beforeTimeMap.put(TimeUtils.midNight(), endTime);
                else beforeTimeMap.put(TimeUtils.midNight(), beforeTimeBreak);
                timeSegmentMap.put('Before', beforeTimeMap);
            }
        }
        //break before 7:00
        //break after 15:30
        else if(endTime < startTime){
            //entry 16:00 - 06:00 should return after => 16:00 - 00:00, before => 00:00 - 06:00
            //entry 06:00 - 05:00 should return after => 15:30 - 00:00, before => 06:00 - 07:00; 00:00 - 05:00
            //entry 08:00 - 07:00 should return after => 15:30 - 00:00, before => 00:00 - 07:00
            //entry 15:30 - 07:00 should return after => 15:30 - 00:00, before => 00:00 - 07:00
            //entry 07:00 - 06:00 should return after => 15:30 - 00:00, before => 00:00 - 06:00
            //entry 14:00 - 13:00 should return after => 15:30 - 00:00, before => 00:00 - 07:00
            //entry 19:00 - 18:00 should return after => 19:00 - 00:00, 15:30 - 18:00, before: 00:00 - 07:00
            if(endTime != TimeUtils.midNight()){
                //overnight shift
                if(startTime < beforeTimeBreak){
                    beforeTimeMap.put(startTime, beforeTimeBreak);
                    if(endTime < beforeTimeBreak){
                        beforeTimeMap.put(TimeUtils.midNight(), endTime);
                        afterTimeMap.put(afterTimeBreak, TimeUtils.midNight());
                    }
                } else if (startTime >= afterTimeBreak) {
                    afterTimeMap.put(startTime, TimeUtils.midNight());
                    if(endTime <= beforeTimeBreak) beforeTimeMap.put(TimeUtils.midNight(), endTime);
                    else beforeTimeMap.put(TimeUtils.midNight(), beforeTimeBreak);

                    if(endTime > afterTimeBreak) afterTimeMap.put(afterTimeBreak, endTime);
                } else if (startTime >= beforeTimeBreak){
                    afterTimeMap.put(afterTimeBreak, TimeUtils.midNight());
                    if(endTime <= beforeTimeBreak) beforeTimeMap.put(TimeUtils.midNight(), endTime);
                    else beforeTimeMap.put(TimeUtils.midNight(), beforeTimeBreak);
                }
            } else{
                //entry 08:00 - 00:00 should return after => 15:30 - 00:00
                //entry 16:00 - 00:00 should return after => 16:00 - 00:00
                //entry 05:00 - 00:00 should return after => 15:30 - 00:00, before 05:00 - 07:00
                if(startTime >= afterTimeBreak) afterTimeMap.put(startTime, TimeUtils.midNight());
                else afterTimeMap.put(afterTimeBreak, TimeUtils.midNight());
                timeSegmentMap.put('After', afterTimeMap);

                if(startTime <= beforeTimeBreak){
                    beforeTimeMap.put(startTime, beforeTimeBreak);
                    timeSegmentMap.put('Before', beforeTimeMap);
                }
            }
        }

        else if(endTime > startTime && endTime < beforeTimeBreak){
            beforeTimeMap.put(startTime, endTime);
        }

        else if(endTime > startTime){
            if(startTime < beforeTimeBreak)
                beforeTimeMap.put(startTime, beforeTimeBreak);

            if(endTime > afterTimeBreak) afterTimeMap.put(afterTimeBreak, endTime);
        }

        timeSegmentMap.put('Before', beforeTimeMap);
        timeSegmentMap.put('After', afterTimeMap);
        System.debug('Info: calcTimeSegment time ' + startTime + ' -  ' + endTime);
        System.debug('Info: calcTimeSegment before ' + beforeTimeBreak + ' - after Time ' + afterTimeBreak);
        System.debug('Info: calcTimeSegment beforeTimeMap ' + beforeTimeMap);
        System.debug('Info: calcTimeSegment After ' + afterTimeMap);
        return timeSegmentMap;
    }
     */

    /* Depreciated
    public static String getHolidayPayCodeByDateByBillingRule(Date workDate, Billing_Rule__c billingRule){
        String paidCode = null;
        if(mapHolidayDate.containsKey(workDate)){
            String holidayNameList = mapHolidayDate.get(workDate);
            if(String.isNotBlank(holidayNameList)){
                List<String> holidayNames = holidayNameList.split(';');
                for(String holidayName:holidayNames){
                    if(billingRule.Holidays_Bill_in_OT_Rate__c != null && billingRule.Holidays_Bill_in_OT_Rate__c.contains(holidayName)){
                        paidCode = EnumUtil.TimeRateCode.OT.name();
                        break;
                    }
                    if(billingRule.Holidays_Bill_in_DT_Rate__c != null && billingRule.Holidays_Bill_in_DT_Rate__c.contains(holidayName)){
                        paidCode = EnumUtil.TimeRateCode.DT.name();
                        break;
                    }
                }
            }
        }
        return paidCode;
    }
     */

    //W00028
    /* Not Used
    public static Boolean isHoliday(Date holidayDate){
        Boolean isHoliday = false;
        if(mapHolidayDate.containsKey(holidayDate)){
            String holiday = mapHolidayDate.get(holidayDate);
            isHoliday = theCompanySetup.Company_Holiday__c.contains(holiday);
        }

        return isHoliday;
    }
     */

    //W00028
    public static void getHolidayDateMap(List<TM_Line__c> tmLines){
        Date startDate = null;
        Date endDate = null;
        String processTMId;
        for(TM_Line__c tmLine:tmLines){
            Date scheduleDate = tmLine.Scheduled_Date__c;
            if(tmLine.TM__c != processTMId && scheduleDate != null){
                if((startDate != null && startDate > scheduleDate) || startDate == null){
                    startDate = scheduleDate;
                } else if((endDate != null && endDate < scheduleDate) || endDate == null){
                    endDate = scheduleDate;
                }
            }
        }

        List<Holiday__c> holidays = [
                SELECT Date__c, Holiday__c, Holiday_Name_Map__c
                FROM Holiday__c
                WHERE Date__c >= :startDate AND Date__c <= :endDate AND Holiday_Name_Map__c != null
        ];

        for(Holiday__c holiday:holidays){
            mapHolidayDate.put(holiday.Date__c, holiday.Holiday_Name_Map__c);
        }
    }

    //W00028
    /*
	public static TM_Line__c updateLineTotals(TM_Line__c tmLine){

        tmLine.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(tmLine.Unit_Price__c) * companyMgmt.zeroIfNull(tmLine.Quantity__c));

        Decimal Markup = 0;

        if (tmLine.Markup_Option__c == '%') Markup = tmLine.Line_Amount__c * companyMgmt.zeroIfNull(tmLine.Markup__c) / 100;

        if (tmLine.Markup_Option__c == 'Amount') Markup = companyMgmt.zeroIfNull(tmLine.Markup__c);

        tmLine.Line_Amount__c += Markup;
        tmLine.Tax__c = CompanyMgmt.halfUpTo2D(tmLine.Line_Amount__c * companyMgmt.zeroIfNull(tmLine.Tax_Pct__c) / 100);
        tmLine.Line_Amt_Incl_Tax__c = tmLine.Line_Amount__c + tmLine.Tax__c;

        return tmLine;
    }
     */

    /* Depreciated
       Moved to TMLLineService
    */
    public static void setCost(TM__c theTM, TM_Line__c theTML){
        /*
        Resource_Type__c theResourceType;
        Resource__c theResource;

        // Get Resource Type
        if (theTML.Resource_Type__c != null) {
            if (!mapResourceType.containsKey(theTML.Resource_Type__c)) {
                theResourceType = CompanyMgmt.getResourceType(theTML.Resource_Type__c);
                mapResourceType.put(theTML.Resource_Type__c, theResourceType);
            }
            theResourceType = mapResourceType.get(theTML.Resource_Type__c);
        }
        // Get Resource
        if (String.isNotBlank(theTML.Resource__c)) {
            if (!mapResource.containsKey(theTML.Resource__c)) {
                theResource = CompanyMgmt.getResource(theTML.Resource__c);
                mapResource.put(theTML.Resource__c, theResource);
            }
            theResource = mapResource.get(theTML.Resource__c);
        }

        // Get Cost
        if (theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment') {
            Resource_Type__c unitCostBasedOnResourceType = new Resource_Type__c();
            if (theResource != null && String.isNotBlank(theResource.Resource_Type__c)) {
                if (!mapResourceType.containsKey(theResource.Resource_Type__c)) {
                    unitCostBasedOnResourceType = CompanyMgmt.getResourceType(theResource.Resource_Type__c);
                    mapResourceType.put(unitCostBasedOnResourceType.Id, unitCostBasedOnResourceType);
                } else {
                    unitCostBasedOnResourceType = mapResourceType.get(theResource.Resource_Type__c);
                }
            } else if (theResourceType != null) {
                unitCostBasedOnResourceType = theResourceType;
            }

            if (unitCostBasedOnResourceType != null) {
                if (theTML.Unit_of_Measure__c == unitCostBasedOnResourceType.Unit_of_Measure__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(unitCostBasedOnResourceType.Unit_Cost__c);
                }
                if (theTML.Unit_of_Measure__c == unitCostBasedOnResourceType.Unit_of_Measure1__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(unitCostBasedOnResourceType.Unit_Cost1__c);
                }
                if (theTML.Unit_of_Measure__c == unitCostBasedOnResourceType.Unit_of_Measure2__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(unitCostBasedOnResourceType.Unit_Cost2__c);
                }
                if (theTML.Unit_of_Measure__c == unitCostBasedOnResourceType.Unit_of_Measure3__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(unitCostBasedOnResourceType.Unit_Cost3__c);
                }
                if (theTML.Unit_of_Measure__c == unitCostBasedOnResourceType.Unit_of_Measure4__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(unitCostBasedOnResourceType.Unit_Cost4__c);
                }
            } else {
                theTML.Unit_Cost__c = 0;
            }        
        } else if(theTML.Category__c == 'Subcontractors' || theTML.Category__c == 'Waste Disposal'){
            if(theTML.Bill_as_Lump_Sum__c == true || theTML.Non_Billable__c == true) theTML.Unit_Cost__c = theTML.xUnit_Price__c; //14646
            else theTML.Unit_Cost__c = theTML.Unit_Price__c; //14646
        } else {
            if (theResource != null) {
                if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost__c);
                }
                if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure1__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost1__c);
                }
                if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure2__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost2__c);
                }
                if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure3__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost3__c);
                }
                if (theTML.Unit_of_Measure__c == theResource.Unit_of_Measure4__c) {
                    theTML.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost4__c);
                }
            } else {
                theTML.Unit_Cost__c = 0;
            }
        }
         */
    }
}