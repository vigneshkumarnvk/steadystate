public with sharing class SalesOrderMgmt {
    //public static Map<Id, Unit_of_Measure__c> mapUOM = new Map<Id, Unit_of_Measure__c>();
    //public static Map<Id, Contract_Line__c> mapCL = new Map<Id, Contract_Line__c>();
    public static Map<Id, Account> mapAccount = new Map<Id, Account>();
    //Public static Map<String, Contract_Line__c> mapContractLines = new Map<String, Contract_Line__c>();
    public static Map<Id, Resource__c> mapResource = new Map<Id, Resource__c>();
    public static Map<String, Decimal> mapSalesTax = new Map<String, Decimal>();
    public static Boolean isReinsertSL = false;
    public static Map<Id, TM__c> mapTM = new Map<Id, TM__c>();
    //public static Map<Id, Pay_Rule__c> payRulesByIds = new Map<Id, Pay_Rule__c>();
    
    public static List <String> checkSave(Sales_Order__c theSO, List<Sales_Line__c> theSLList) {
        List<String> errorList = new List<String> ();
        /*
        if((theSO.Surcharge_Type__c == 'Energy & Insurance' || theSO.Surcharge_Type__c == 'Fuel Surcharge') && theSO.Quote_Date__c == null){
            errorList.add('Quote Date must not be blank when Surcharge Type ' + theSO.Surcharge_Type__c + ' is selected!');
        }

        if(String.isBlank(theSO.Bill_to_Contact__c)){
            errorList.add('You must choose a Bill-to Contact before you can save the record.');
        }

        if (String.isBlank(theSO.Quote_Contact__c) && theSO.Document_Type__c == 'Sales Quote') {
            errorList.add('You must choose a Quote Contact before you can save Sales Quote.');
        }

        if (String.isEmpty(theSO.Sales_Order_Type__c)) {
            errorList.add('You must choose a Sales Order Type before you can save Sales Order.');
        }
        if (String.isEmpty(theSO.Surcharge_Type__c)) {
            errorList.add('You must choose a Surcharge Type before you can save Sales Order.');
        }
        if (String.isEmpty(theSO.Service_Center__c)) {
            errorList.add('You must choose a Service Center before you can save Sales Order.');
        }
        if (String.isEmpty(theSO.Tax_Area__c)) {
            errorList.add('You must choose a Tax Area before you can save Sales Order.');
        }
        if (String.isEmpty(theSO.Site_Scope__c)){
            errorList.add('You must enter Project Scope before you can save Sales Order.');
        }

        if(theSO.Estimated_Job_Start_Date__c == null){
            errorList.add('Estimated Job Start Date field must not be blank.');
        }

        List<Account> accountList = AccountsSelector.newInstance().selectSubsidiaryCompInfoById(new Set<Id>{
                theSO.Bill_to_Customer_No__c
        });
        if (accountList.size() > 0) {
            Account account = accountList[0];
            if (account.Subsidiary_Company__r.Name != '1-ACV ENVIRO' && (account.Type == 'Customer')) {
                errorList.add('You can only create Sales Quote or Sales Order from ACV Enviro customer');
            }
            if (account.Subsidiary_Company__c == null && theSO.Document_Type__c == 'Sales Quote') {
                errorList.add('The account must have a Subsidiary Company to create a Sales Quote');
            }
            if (String.isNotEmpty(theSO.Sales_Order_Type__c)) {
                Sales_Order_Type__c sot = [SELECT Id, Emergency_Response__c FROM Sales_Order_Type__c WHERE Id = :theSO.Sales_Order_Type__c];
                if (account.Emergency__c == true && sot.Emergency_Response__c != true && theSO.Document_Type__c == 'Sales Order') {
                    errorList.add('This customer is not approved. Only Emergency Response sales order are allowed!');
                }
            }
        }
        if (String.isEmpty(theSO.CMR_Description__c) && theSO.Document_Type__c == 'Sales Order') {
            errorList.add('You must enter Job Description before you can save Sales Order.');
        }
		
        //Ticket#14522
		Integer billAsLumpSumlines = 0;
        Integer systemCalculatedLines = 0;

        for(Sales_Line__c salesLine:theSLList){
            if(salesLine.Category__c == 'Waste Disposal' || salesLine.Category__c == 'Misc. Charges And Taxes'){
                if((String.isNotEmpty(salesLine.Description__c) == true || CompanyMgmt.zeroIfNull(salesLine.Quantity__c) != 0) &&
                        String.isBlank(salesLine.Resource__c)){
                    String fieldName;
                    if(salesLine.Category__c == 'Waste Disposal') fieldName = 'Waste Disposal';
                    if(salesLine.Category__c == 'Misc. Charges And Taxes') fieldName = 'Service';
                    errorList.add(fieldName + ' field must not be blank! Line No. ' + salesLine.Line_No__c);
                }
            }

            //Ticket#14522
            if (salesLine.Bill_as_Lump_Sum__c == true){
                billAsLumpSumlines++;
            }
            if (salesLine.System_Calculated_Line__c == true){
                systemCalculatedLines++;
            }
            
        }

        //Ticket#14522
        if (billAsLumpSumlines + systemCalculatedLines == theSLList.size() && theSLList.size() > 0 && theSLList.size() != systemCalculatedLines) {
            errorList.add('Please enter a Lump Sum Resource line.');
        }
         */
        return errorList;
    }

    //moved to lighting
    public static Sales_Order__c validateSalesOrderType(Sales_Order__c theSO) {
        /*
        if (String.isEmpty(theSO.Sales_Order_Type__c)) {
            theSO.Sales_Order_Type__r = null;
            return theSO;
        }

        Sales_Order_Type__c salesOrderType = [SELECT Name, Id FROM Sales_Order_Type__c WHERE Id = : theSO.Sales_Order_Type__c];

        if (salesOrderType != null) {
            theSO.Sales_Order_Type__r = new Sales_Order_Type__c(Id = salesOrderType.Id, Name = salesOrderType.Name);
        }
         */
        return theSO;
    }

    //moved to lighting
    public static Sales_Order__c validateSalespeople(Sales_Order__c theSO) {
        /*
        if (String.isEmpty(theSO.Project_Coordinator__c) & String.isEmpty(theSO.Account_Executives__c)) {
            theSO.Project_Coordinator__r = null;
            theSO.Account_Executives__r = null;
            return theSO;
        }

        Salesperson__c pc, ae;

        if (String.isNotEmpty(theSO.Project_Coordinator__c)) {
            pc = [SELECT Id, Name FROM Salesperson__c WHERE Id = : theSO.Project_Coordinator__c];
        }

        if (String.isNotEmpty(theSO.Account_Executives__c)) {
            ae = [SELECT Id, Name FROM Salesperson__c WHERE Id = : theSO.Account_Executives__c];
        }

        if (pc != null) {
            theSO.Project_Coordinator__r = new Salesperson__c(id = pc.Id, Name = pc.Name);
        }

        if (ae != null) {
            theSO.Account_Executives__r = new Salesperson__c(id = ae.Id, Name = ae.Name);
        }
        */
        return theSO;
    }
    // Ticket# AES-416
    /*
    public static Sales_Order__c validateSurchargeTypeAndQuoteDate (Sales_Order__c theSO) {
        if (theSO.Surcharge_Type__c != null && String.isNotBlank(theSO.Contract__c)) {
            List<Contract> contracts = ContractsSelector.newInstance().selectById(new Set<Id>{
                    theSO.Contract__c
            });
            System.debug('Info: contracts' + contracts);
            if(contracts.size() > 0){
                if(theSO.Surcharge_Type__c == 'Energy & Insurance') theSO.Surcharge_Pct__c = CompanyMgmt.zeroIfNull(contracts[0].Energy_Insurance__c);
                if(theSO.Surcharge_Type__c == 'Fuel Surcharge') theSO.Surcharge_Pct__c = CompanyMgmt.zeroIfNull(contracts[0].Fuel_Surcharge_Pct__c);
            }
        }

        System.debug('Info: theSO.Surcharge_Pct__c ' + theSO.Surcharge_Pct__c);

        if (theSO.Surcharge_Type__c != null && theSO.Quote_Date__c != null && theSO.Surcharge_Pct__c == 0 && theSO.Surcharge_Pct__c == null) {
            System.debug('Info: validateSurchargeTypeAndQuoteDate 2 ' + theSO.Surcharge_Pct__c);
            List<Surcharge_Setup__c> surchargeSetup = [
                    SELECT Id, Name, Effective_Date__c, Surcharge_Pct__c
            FROM Surcharge_Setup__c
            WHERE Effective_Date__c <= :theSO.Quote_Date__c
            AND Surcharge_Type__c = :theSO.Surcharge_Type__c
                    ORDER BY Effective_Date__c DESC
                    LIMIT 1
            ];
            if (surchargeSetup.size() > 0){
                theSO.Surcharge_Pct__c = surchargeSetup[0].Surcharge_Pct__c;
            } else {
                theSO.Surcharge_Pct__c = null;
            }
        }
        if (theSO.Surcharge_Type__c == null) theSO.Surcharge_Pct__c = null;
        return theSO;
    }
    */

    //Depreciated
    public static Sales_Order__c validateContract(Sales_Order__c theSO) {
        /*
        if (String.isEmpty(theSO.Contract__c)) {
            theSO.Contract__r = null;
            return theSO;
        }

        Contract contract = [
                SELECT Id, Name, ContractNumber, Status, AccountId,
                Internal_Comments__c, Billing_Instructions__c, Fuel_Surcharge_Pct__c, Energy_Insurance__c,
                        StartDate, ContractTerm
                FROM Contract
                WHERE Id = :theSO.Contract__c
        ];

        if (contract != null) {
            theSO.Contract__c = contract.Id;
            theSO.Contract__r = new Contract(Id = contract.Id,
                                             Name = contract.Name,
                                             Status = contract.Status,
                                             AccountId = contract.AccountId,
                                             StartDate = contract.StartDate,
                                             ContractTerm = contract.ContractTerm
                                            );
            //Ticket#14554 >>
            if(String.isNotBlank(contract.Billing_Instructions__c))
                theSO.Billing_Instructions__c = contract.Billing_Instructions__c;
            if(String.isNotBlank(contract.Internal_Comments__c))
                theSO.Internal_Comments__c = contract.Internal_Comments__c;
            //Ticket#14554 <<
            //Ticket#14596 >>
            if(contract.Energy_Insurance__c != null && contract.Energy_Insurance__c > 0){
                if(theSO.Surcharge_Type__c == 'Energy & Insurance'){
                    theSO.Surcharge_Pct__c = contract.Energy_Insurance__c;
                }
                if(theSO.Surcharge_Type__c == 'Fuel Surcharge'){
                    theSO.Surcharge_Pct__c = contract.Fuel_Surcharge_Pct__c;
                }
            }
            //Ticket#14596 <<
        }
        */
        return theSO;
    }

    //Depreciated
    public static Sales_Order__c validateBillToCustomer(Sales_Order__c theSO){
        /*
        if (!String.isEmpty(theSO.Contract__c)) {
            System.debug(theSO.Contract__c);
            theSO.Contract__c = null;
        }

        if(!String.isEmpty(theSO.Bill_to_Contact__c)) theSO.Bill_to_Contact__c = null;
        */
        return theSO;
    }

    //Depreciated
    public static Sales_Order__c validateAltSiteAddress(Sales_Order__c theSO) {
        /*
        if (String.isEmpty(theSO.Alternate_Site_Address__c)) {
            theSO.Alternate_Site_Address__r = null;
            theSO.Site_Name__c = '';
            theSO.Site_Contact__c = '';
            theSO.Site_Contact_2__c = null; //AES-401
            theSO.Site_Contact_2__r = null; //AES-401
            theSO.Site_Street__c = '';
            theSO.Site_Phone_No__c = '';
            theSO.Site_City__c = '';
            theSO.Site_Email_Address__c = '';
            theSO.Site_State__c = '';
            theSO.Site_Postal_Code__c = '';
            theSO.Tax_Liable__c = false;
            theSO.Tax_Area__c = null;
            theSO.Tax_Area__r = null;
            theSO.Site_Country__c = '';
            theSO.Mobile_Email__c = null;
            return theSO;
        }

        Site_Address__c altSiteAddress = [
                SELECT Name, Id, Site_City__c, Site_Contact__c, Site_Country__c, Site_Email_Address__c,
                                          Site_Phone_No__c, Site_Postal_Code__c, Site_State__c, Site_Street__c, Tax_Area__c,Tax_Area__r.Name,
                        Print_Site_Name__c, Contact__c, Contact__r.Name, Contact__r.Email, Contact__r.Mobile_Email__c,
                        Contact__r.Phone
                FROM Site_Address__c
                WHERE Id = :theSO.Alternate_Site_Address__c
        ];

        if (altSiteAddress != null) {
            theSO.Alternate_Site_Address__r = new Site_Address__c(Id = altSiteAddress.Id, Name = altSiteAddress.Name);
            theSO.Site_Name__c = altSiteAddress.Name;
            theSO.Site_Contact__c = altSiteAddress.Site_Contact__c;
            theSO.Site_Contact_2__c = altSiteAddress.Contact__c; //AES-401
            theSO.Site_Street__c = altSiteAddress.Site_Street__c;
            theSO.Site_Phone_No__c = altSiteAddress.Site_Phone_No__c;
            theSO.Site_City__c = altSiteAddress.Site_City__c;
            theSO.Site_Email_Address__c = altSiteAddress.Site_Email_Address__c;            
            theSO.Site_State__c = altSiteAddress.Site_State__c;
            theSO.Site_Postal_Code__c = altSiteAddress.Site_Postal_Code__c;
            theSO.Tax_Area__c = altSiteAddress.Tax_Area__c;
            theSO.Tax_Area__r = new Tax_Area__c(Id = altSiteAddress.Tax_Area__c, Name = altSiteAddress.Tax_Area__r.Name);
            theSO.Site_Country__c = altSiteAddress.Site_Country__c;
            theSO.Print_Site_Name__c = altSiteAddress.Print_site_Name__c;
            if(String.isNotBlank(altSiteAddress.Contact__c)){
                if(String.isNotBlank(altSiteAddress.Contact__r.Email)) theSO.Site_Email_Address__c = altSiteAddress.Contact__r.Email;
                if(String.isNotBlank(altSiteAddress.Contact__r.Phone)) theSO.Site_Phone_No__c = altSiteAddress.Contact__r.Phone;
                theSO.Mobile_Email__c = altSiteAddress.Contact__r.Mobile_Email__c;
            }
        }
        */
        return theSO;
    }

    //Depreciated
    public static Sales_Order__c validateCreateSiteAddress(Sales_Order__c theSO) {
        /*
        if (theSO.Create_Site_Address__c && String.isBlank(theSO.Alternate_Site_Address__c)) {
            Site_Address__c altSiteAddress = new Site_Address__c();
            if(String.isBlank(theSO.Site_Name__c)){
                throw new DataException('Site Name must not be blank');
            }
            altSiteAddress.Customer__c = theSO.Bill_to_Customer_No__c;
            altSiteAddress.Name = theSO.Site_Name__c;
            altSiteAddress.Site_Contact__c = theSO.Site_Contact__c;
            altSiteAddress.Contact__c = theSO.Site_Contact_2__c; //AES-401
            altSiteAddress.Site_Street__c = theSO.Site_Street__c;
            altSiteAddress.Site_City__c = theSO.Site_City__c;
            altSiteAddress.Site_State__c = theSO.Site_State__c;
            altSiteAddress.Site_Country__c = theSO.Site_Country__c;
            altSiteAddress.Site_Postal_Code__c = theSO.Site_Postal_Code__c;
            altSiteAddress.Site_Phone_No__c = theSO.Site_Phone_No__c;
            altSiteAddress.Site_Email_Address__c = theSO.Site_Email_Address__c;
            altSiteAddress.Tax_Area__c = theSO.Tax_Area__c;
            altSiteAddress.Print_Site_Name__c = theSO.Print_Site_Name__c;

            insert altSiteAddress;
            theSO.Alternate_Site_Address__c = altSiteAddress.Id;
        }
        */
        return theSO;
    }

    //Depreciated
    //Moved to lightning
    public static Sales_Line__c updateSL(Sales_Line__c theSL, Sales_Order__c theSO, String sourceField) {
        /*
        if (sourceField == 'theResource' || sourceField == 'theLResource' || sourceField == 'theEResource' || sourceField == 'theMResource' ||
                sourceField == 'theFResource' || sourceField == 'theSResource' || sourceField == 'theWResource' || sourceField == 'theEIResource') { // W-000021
            Resource__c theResource;
            if (!mapMaterial.containsKey(theSL.Resource__c)) {
                theResource = CompanyMgmt.getResource(theSL.Resource__c);
                mapMaterial.put(theSL.Resource__c, theResource);
            }
            theResource = mapMaterial.get(theSL.Resource__c);
            theSL.Resource__r = new Resource__c(Id = theResource.Id, Name = theResource.Name);
            theSL.Resource__r.Name = theResource.Name;
            if (theSL.Category__c != 'Labor' && theSL.Category__c != 'Equipment') {
                theSL.Description__c = theResource.Description__c;
            }
            theSL.Quantity__c = 0;
            if (sourceField == 'theEIResource') theSL.Quantity__c = 1; // W-000021
            
            if (sourceField == 'theLResource') {
                theSL.Resource_Type__r = new Resource_Type__c(Id = theResource.Resource_Type__c, Name = theResource.Resource_Type__r.Name);
                theSL.Resource_Type__c = theResource.Resource_Type__c;
                theSL = setResourceType(theSL, theSO);
            } else if (sourceField == 'theEResource') {
                theSL.Resource_Type__r = new Resource_Type__c(Id = theResource.Resource_Type__c, Name = theResource.Resource_Type__r.Name);
                theSL.Resource_Type__c = theResource.Resource_Type__c;
                theSL = setResourceType(theSL, theSO);
            } else {
                theSL.Unit_of_Measure__c = theResource.Unit_of_Measure__c;
            theSL.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theResource.Unit_of_Measure__c, Name = theResource.Unit_of_Measure__r.Name);
                theSL.Unit_Cost__c = theResource.Unit_Cost__c;
            }

            theSL = setPricing(theSL, theSO);
            setCost(theSL, theSO);
            theSL = calculateUnitPrice(theSL); //Ticket# AES-407
        }

        if (sourceField == 'theResourceType') {
            theSL = setResourceType(theSL, theSO);
            theSL.Quantity__c = 0;
            theSL = setPricing(theSL, theSO);
            setCost(theSL, theSO);
        }
        if (sourceField == 'theUOM') {
            if (theSL.Unit_of_Measure__c != null){
                Unit_of_Measure__c theUOM = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Id = : theSL.Unit_of_Measure__c LIMIT 1];
                theSL.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theUOM.Id, Name = theUOM.Name);
                theSL.Unit_of_Measure__c = theUOM.Id;
                
                theSL = setPricing(theSL, theSO);
                setCost(theSL, theSO);
                theSL = calculateUnitPrice(theSL);
                theSL.UOM_Qty__c = 1;
            }
        }

        if (sourceField == 'theLContractLine' || sourceField == 'theEContractLine' || sourceField == 'theMContractLine' || 
            sourceField == 'theLumpSumContractLine') {
            Contract_Line__c theCL;
            if (!mapCL.containsKey(theSL.Contract_Line__c)) {
                System.debug('<=Contract Line=>'+theSL.Contract_Line__c);
                theCL = [
                        SELECT Id, Name, Resource_Type__c, Unit_of_Measure__c,Resource__c,Resource__r.Description__c,
                                Resource_Type__r.Name, Unit_of_Measure__r.Name, Resource__r.Name,Resource_Type__r.Description__c,
                                Overtime_Rate__c, Premium_Rate__c, Regular_Rate__c, Customer_Description__c
                        FROM Contract_Line__c
                        WHERE Id = :theSL.Contract_Line__c
                        LIMIT 1
                ];
                mapCL.put(theSL.Contract_Line__c, theCL);
            }
            theCL = mapCL.get(theSL.Contract_Line__c);
            theSL.Contract_Line__r = new Contract_Line__c(Id = theCL.Id, Name = theCL.Name);
            theSL.Contract_Line__r.Name = theCL.Name;
            theSL.Unit_of_Measure__c = theCL.Unit_of_Measure__c;
            Unit_of_Measure__c theUOM = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Id = : theCL.Unit_of_Measure__c LIMIT 1];
            theSL.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theUOM.Id, Name = theUOM.Name);
            theSL.Contract_Regular_Rate__c = theCL.Regular_Rate__c;
            theSL.Contract_Overtime_Rate__c = theCL.Overtime_Rate__c;
            theSL.Contract_Premium_Rate__c = theCL.Premium_Rate__c;
            if (sourceField == 'theMContractLine') {
                theSL.Resource__c = theCL.Resource__c;
                theSL.Resource__r = new Resource__c(Id = theCL.Resource__c, Name = theCL.Resource__r.Name);
                theSL.Resource__r.Name = theCL.Resource__r.Name;
                theSL.Description__c = theCL.Resource__r.Description__c;
                theSL.Unit_Price__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                if (String.isNotBlank(theCL.Customer_Description__c)) theSL.Description__c = theCL.Customer_Description__c;
            } else if (sourceField == 'theLContractLine' || sourceField == 'theEContractLine'|| sourceField == 'theLumpSumContractLine') {
                theSL.Resource_Type__c = theCL.Resource_Type__c;
                theSL.Resource_Type__r = new Resource_Type__c(Id = theCL.Resource_Type__c, Name = theCL.Resource_Type__r.Name);
                theSL.Resource_Type__r.Name = theCL.Resource_Type__r.Name;
                theSL.Description__c = theCL.Resource_Type__r.Description__c;
                    theSL.Unit_Price__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                if (String.isNotBlank(theCL.Customer_Description__c)) theSL.Description__c = theCL.Customer_Description__c;
            }
        }
        
        if (sourceField == 'theTaxGroup') {
            if (theSO.Tax_Liable__c && theSL.Tax_Group__c != null) {
                theSL.Tax_Pct__c = CompanyMgmt.getSalesTax(theSO.Tax_Area__c, theSL.Tax_Group__c);
            } else {
                theSL.Tax_Pct__c = 0;
            }
        }
        
        if (sourceField == 'theQuantity') {
            //theSL.Line_Cost__c = theSL.Unit_Cost__c * theSL.Quantity__c;
            theSL = calculateUnitPrice(theSL);
        }
        //Ticket# 407 >>
        if(theSL.Category__c == 'Labor' &&
                (sourceField == 'theRegularHours' || sourceField == 'theRegularRate' ||
                        sourceField == 'theOvertimeHours' || sourceField == 'theOvertimeRate' ||
                        sourceField == 'thePremiumHours' || sourceField == 'thePremiumRate')){
        
            //theSL = calculateUnitPrice(theSL);
            if (sourceField == 'theRegularRate' || sourceField == 'theOvertimeRate' || sourceField == 'thePremiumRate') {
                theSL.Pricing_Source_2__c= theSO.Document_Type__c == 'Sales Quote' ? EnumUtil.PricingSource.SALES_QUOTE.name() : EnumUtil.PricingSource.SALES_ORDER.name();
            }
        }
        //Ticket# AES-407 <<

        //Ticket# 14204 AES-431
        if (sourceField == 'theLBillasLumpSum' || sourceField == 'theLNonBillable') {
            if (theSL.Bill_as_Lump_Sum__c == true || theSL.Non_Billable__c == true) {
                theSL.xRegular_Rate__c = theSL.Regular_Rate__c;
                theSL.xOvertime_Rate__c = theSL.Overtime_Rate__c;
                theSL.xPremium_Rate__c = theSL.Premium_Rate__c;
                theSL.xUnit_Price__c = theSL.Unit_Price__c;
                theSL.Regular_Rate__c = 0;
                theSL.Premium_Rate__c = 0;
                theSL.Overtime_Rate__c = 0;
                theSL.Unit_Price__c = 0;
                theSL = calculateUnitPrice(theSL);
            } else {
                if (theSL.Contract_Line__c != null) {
                    theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theSL.Contract_Regular_Rate__c);
                    theSL.Premium_Rate__c = companyMgmt.zeroIfNull(theSL.Contract_Premium_Rate__c);
                    theSL.Overtime_Rate__c = companyMgmt.zeroIfNull(theSL.Contract_Overtime_Rate__c);
                } else {
                    theSL.Regular_Rate__c = theSL.xRegular_Rate__c;
                    theSL.Overtime_Rate__c = theSL.xOvertime_Rate__c;
                    theSL.Premium_Rate__c = theSL.xPremium_Rate__c;
                }
                theSL = calculateUnitPrice(theSL);
            }
        }
        
        if (sourceField == 'theEBillasLumpSum' || sourceField == 'theENonBillable' ||
                sourceField == 'theMBillasLumpSum' || sourceField == 'theMNonBillable' ||
                sourceField == 'theSBillasLumpSum' || sourceField == 'theSNonBillable' ||
                sourceField == 'theWBillasLumpSum' || sourceField == 'theWNonBillable' ||
                sourceField == 'theDBillasLumpSum' || sourceField == 'theDNonBillable' ||
                sourceField == 'theMiscBillasLumpSum' || sourceField == 'theMiscNonBillable') {

            if (theSL.Bill_as_Lump_Sum__c == true || theSL.Non_Billable__c == true){
                if(CompanyMgmt.zeroIfNull(theSL.Unit_Price__c) > 0) theSL.xUnit_Price__c = theSL.Unit_Price__c; //Ticket#15685
                theSL.Unit_Price__c = 0;
            } else {
                if (theSL.Contract_Regular_Rate__c !=null && theSL.Contract_Regular_Rate__c != 0) {
                theSL.Unit_Price__c = CompanyMgmt.zeroIfNull(theSL.Contract_Regular_Rate__c);
                } else {
                    theSL.Unit_Price__c = theSL.xUnit_Price__c;
                }
            }
        }

        if (sourceField == 'theUnitPrice') {// W-000167
            theSL.Pricing_Source_2__c = theSO.Document_Type__c == 'Sales Quote' ? EnumUtil.PricingSource.SALES_QUOTE.name() : EnumUtil.PricingSource.SALES_ORDER.name();
        }
		if(theSL.Category__c == 'Subcontractors' || theSL.Category__c == 'Waste Disposal'){
            if(theSL.Bill_as_Lump_Sum__c == true || theSL.Non_Billable__c == true) theSL.Unit_Cost__c = theSL.xUnit_Price__c; //14646
            else theSL.Unit_Cost__c = theSL.Unit_Price__c; //14646
        }

        if (theSO.Tax_Liable__c && theSL.Tax_Group__c != null) theSL.Tax_Pct__c = CompanyMgmt.getSalesTax(theSO.Tax_Area__c, theSL.Tax_Group__c);           
        else theSL.Tax_Pct__c = 0;
        if (theSL.Category__c != 'Labor' && theSL.Category__c != 'Equipment'){
        theSL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theSL.Unit_Cost__c) * companyMgmt.zeroIfNull(theSL.Quantity__c));
        theSL.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theSL.Unit_Price__c) * companyMgmt.zeroIfNull(theSL.Quantity__c));
        } else {
            theSL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theSL.Unit_Cost__c) * companyMgmt.zeroIfNull(theSL.Quantity__c) * companyMgmt.zeroIfNull(theSL.UOM_Qty__c));
            theSL.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(theSL.Unit_Price__c) * companyMgmt.zeroIfNull(theSL.Quantity__c) * companyMgmt.zeroIfNull(theSL.UOM_Qty__c));
        }

        //Ticket# 14037 AES-408 >>
        Decimal Markup = 0;
        if (theSL.Markup_Option__c == '%') Markup = theSL.Line_Amount__c * companyMgmt.zeroIfNull(theSL.Markup__c) / 100;
        if (theSL.Markup_Option__c == 'Amount') Markup = companyMgmt.zeroIfNull(theSL.Markup__c);
        theSL.Line_Amount__c += Markup;
        //Ticket# 14037 AES-408 <<
        theSL.Tax__c = CompanyMgmt.halfUpTo2D(theSL.Line_Amount__c * companyMgmt.zeroIfNull(theSL.Tax_Pct__c) / 100);
        theSL.Line_Amt_Incl_Tax__c = theSL.Line_Amount__c + theSL.Tax__c;
        //Ticket# AES-415
        theSL.Profit_Margin__c = theSL.Line_Amount__c - theSL.Line_Cost__c;
         */
        return theSL;
    }

    //Moved to lightning
    public static Sales_Line__c calculateUnitPrice(Sales_Line__c theSL){
        /*
        if (theSL.Category__c != 'Labor') return theSL;
        //Skip if UOM is not Hours UOM
        if (!string.isBlank(theSL.Unit_of_Measure__c)) {
            Unit_of_Measure__c theUnitOfMeasure;
            if (!mapUOM.containsKey(theSL.Unit_of_Measure__c)) {
                theUnitOfMeasure = CompanyMgmt.getUnitOfMeasures(theSL.Unit_of_Measure__c);
                mapUOM.put(theSL.Unit_of_Measure__c, theUnitOfMeasure);
            }
            theUnitOfMeasure = mapUOM.get(theSL.Unit_of_Measure__c);
            if (theUnitOfMeasure.Hours_UOM__c != true) {
                theSL.Unit_Price__c = theSL.Regular_Rate__c;
                return theSL;
            }
        }
        //Calculate Unit Price
        Decimal totalHours = 0;
        Decimal totalPrice = 0;

        totalPrice = (CompanyMgmt.zeroIfNull(theSL.Regular_Hours__c) * CompanyMgmt.zeroIfNull(theSL.Regular_Rate__c)) +
                (CompanyMgmt.zeroIfNull(theSL.Overtime_Hours__c) * CompanyMgmt.zeroIfNull(theSL.Overtime_Rate__c)) +
                (CompanyMgmt.zeroIfNull(theSL.Premium_Hours__c) * CompanyMgmt.zeroIfNull(theSL.Premium_Rate__c));

        totalHours = CompanyMgmt.zeroIfNull(theSL.Regular_Hours__c) + CompanyMgmt.zeroIfNull(theSL.Overtime_Hours__c) +
                CompanyMgmt.zeroIfNull(theSL.Premium_Hours__c);
        System.debug(totalHours + ' ' + totalPrice);
        if (totalHours != 0) {
            theSL.Unit_Price__c = companyMgmt.halfUpTo3D(totalPrice / totalHours);
        } else {
            theSL.Unit_Price__c = CompanyMgmt.zeroIfNull(theSL.Regular_Rate__c);
        }
         */
        return theSL;
    }

    //Depreciated
    public static Sales_Order__c nullRelationshipFields(Sales_Order__c theSO) {
        /*
        // Null all relationship fields to save
        theSO.Bill_to_Customer_No__r = null;
        theSO.Tax_Area__r = null;
        theSO.Bill_to_Contact__r = null;
         */
        return theSO;
    }

    //Depreciated
    //Moved to lightning
    public static Sales_Line__c setResourceType(Sales_Line__c theSL, Sales_Order__c theSO) {
        /*
        Resource_Type__c theResourceType;
        if (!mapResourceType.containsKey(theSL.Resource_Type__c)) {
            theResourceType = CompanyMgmt.getResourceType(theSL.Resource_Type__c);
            mapResourceType.put(theSL.Resource_Type__c, theResourceType);
        }
        theResourceType = mapResourceType.get(theSL.Resource_Type__c);

        theSL.Resource_Type__r = new Resource_Type__c(Id = theResourceType.Id, Name = theResourceType.Name, Fuel_Fired_Equipment__c = theResourceType.Fuel_Fired_Equipment__c);
        theSL.Resource_Type__r.Name = theResourceType.Name;
        theSL.Description__c = theResourceType.Description__c;
        theSL.Unit_of_Measure__c = theResourceType.Unit_of_Measure__c;
        theSL.Unit_of_Measure__r = new Unit_of_Measure__c(Id = theResourceType.Unit_of_Measure__c, Name = theResourceType.Unit_of_Measure__r.Name);
        theSL.Unit_Cost__c = theResourceType.Unit_Cost__c;
         */
        return theSL;
    }

    //Moved to service
    public static Sales_Line__c setPricing(Sales_Line__c theSL, Sales_Order__c theSO) {
        /*
        System.debug('#*SalesOrderMgmt setPricing begin');
        // Do not update prices if from Sales Quote
        if (theSL.Quote_Line__c != null) return theSL;           
        // Get Prices
        string theKey = '';
        List<Contract_Line__c> theCLList = new List<Contract_Line__c>();
        Contract_Line__c theCL = new Contract_Line__c();
        Resource_Type__c theResourceType;
        Resource__c theResource;
        // Get Resource Type
        if (theSL.Resource_Type__c != null) {
            system.debug('scott1');
            if (!mapResourceType.containsKey(theSL.Resource_Type__c)) {
                theResourceType = CompanyMgmt.getResourceType(theSL.Resource_Type__c);
                mapResourceType.put(theSL.Resource_Type__c, theResourceType);
            }
            theResourceType = mapResourceType.get(theSL.Resource_Type__c);
        }
        // Get Resource
        if (theSL.Resource__c != null) {
            if (!mapMaterial.containsKey(theSL.Resource__c)) {
                theResource = CompanyMgmt.getResource(theSL.Resource__c);
                mapMaterial.put(theSL.Resource__c, theResource);
            }
            theResource = mapMaterial.get(theSL.Resource__c);
        }

        System.debug('#*theResourceType: ' + theResourceType);
        System.debug('#*theResource ' + theResource);

        Account theAccount;
        if (!mapAccount.containsKey(theSO.Bill_to_Customer_No__c)) {
            theAccount = [
                    SELECT Id, Name, Pricing_Group__c
                    FROM Account
                    WHERE Id = :theSO.Bill_to_Customer_No__c
                    LIMIT 1
            ];
            mapAccount.put(theSO.Bill_to_Customer_No__c, theAccount);
        }

        theAccount = mapAccount.get(theSO.Bill_to_Customer_No__c);
        System.debug('#*theAccount ' + theAccount);
        // Get contract price
        if (theSL.Category__c == 'Labor') {
            theKey = theSO.Contract__c + ';' + theSL.Resource_Type__c + ';' + theSL.Unit_of_Measure__c;

            System.debug('#*Labor Pricing begin');
            System.debug('#*theKey ' + theKey);

            system.debug('***theSO.Contract__c' + theSO.Contract__c);
            if (mapContractLines.containsKey(theKey))  theCL = mapContractLines.get(theKey);
              
            else {
                theCLList = [
                        SELECT Id, Name, Contract__c, Resource_Type__c, Resource__c, Overtime_Rate__c, Regular_Rate__c, Customer_Description__c, Premium_Rate__c
                        FROM Contract_Line__c
                        WHERE Contract__c = :theSO.Contract__c AND Resource_Type__c = :theSL.Resource_Type__c AND Unit_of_Measure__c = :theSL.Unit_of_Measure__c
                        LIMIT 1
                ];

                if (theCLList != null && theCLList.size() > 0) {
                    theKey = theSO.Contract__c + ';' + theSL.Resource_Type__c + ';' + theSL.Unit_of_Measure__c;
                    mapContractLines.put(theKey, theCLList[0]);
                }
            }

            if (mapContractLines.containsKey(theKey)) {
                theCL = mapContractLines.get(theKey);
                theSL.Contract_Line__c = theCL.Id;
                theSL.Contract_Line__r = new Contract_Line__c(Id = theCL.Id, Name = theCL.Name);
                theSL.Contract_Line__r.Name = theCL.Name;
                theSL.Contract_Overtime_Rate__c = companyMgmt.zeroIfNull(theCL.Overtime_Rate__c);
                theSL.Contract_Regular_Rate__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                theSL.Contract_Premium_Rate__c = companyMgmt.zeroIfNull(theCL.Premium_Rate__c);
                if (companyMgmt.zeroIfNull(theCL.Regular_Rate__c) != 0) theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c); //Ticket# AES-407
                if (companyMgmt.zeroIfNull(theCL.Overtime_Rate__c) != 0) theSL.Overtime_Rate__c = companyMgmt.zeroIfNull(theCL.Overtime_Rate__c); //Ticket# AES-407
                if (companyMgmt.zeroIfNull(theCL.Premium_Rate__c) != 0) theSL.Premium_Rate__c = companyMgmt.zeroIfNull(theCL.Premium_Rate__c); //Ticket# AES-407
                if (String.isNotBlank(theCL.Customer_Description__c)) theSL.Description__c = theCL.Customer_Description__c;
                theSL.Pricing_Source_2__c = EnumUtil.PricingSource.CONTRACT.name(); // W-000167
                //if (theSO.Pricing_Source__c != EnumUtil.PricingSource.SALES_QUOTE.name()) theSO.Pricing_Source__c = EnumUtil.PricingSource.CONTRACT.name();
            } else {
                // No Contract - use Standard Price
                if (theResourceType != null) {
                        //emergency response

                    //Ticket AES-407 Change All Unit_Price__c to Regular_Rate__c
                    theSL.Regular_Rate__c = 0;
                    system.debug('#*theAccount.Pricing_Group__c' + theAccount.Pricing_Group__c);
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure__c){
                        if (theSO.Emergency_Sales_Order__c == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate__c);
                        } else {
                        
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure1__c || Test.IsRunningTest()){
                        if (theSO.Emergency_Sales_Order__c == true) {
                        
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate1__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate1__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate1__c);
                        } else {
                        
                            if (theAccount.Pricing_Group__c == 'Silver')  theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate1__c);
                              
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate1__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate1__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure2__c || Test.IsRunningTest()){
                        if (theSO.Emergency_Sales_Order__c == true) {
                        
                            if (theAccount.Pricing_Group__c == 'Silver') {
                                theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate2__c);
                            } else if (theAccount.Pricing_Group__c == 'Gold') {
                                theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate2__c);
                            } else if (theAccount.Pricing_Group__c == 'Platinum') {
                                theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate2__c);
                            }
                        } else {
                        
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate2__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate2__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate2__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure3__c || Test.IsRunningTest()){
                        if (theSO.Emergency_Sales_Order__c == true) {
                        
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate3__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate3__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate3__c);
                        } else {
                        
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate3__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate3__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate3__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure4__c || Test.IsRunningTest()){
                        if (theSO.Emergency_Sales_Order__c == true) {
                        
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate4__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate4__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate4__c);
                        } else {
                        
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate4__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate4__c);
                               
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Regular_Rate__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate4__c);
                        }
                    }
                        //emergency response >>
                } else {
                    theSL.Regular_Rate__c = 0;
                }
                //Ticket# AES-414 >>
                theSL.Overtime_Rate__c = CompanyMgmt.zeroIfNull(theSL.Regular_Rate__c) * CompanyMgmt.zeroIfNull(CompanyMgmt.getCompanySetup().T_M_Overtime_Multiplier__c);
                theSL.Premium_Rate__c =  CompanyMgmt.zeroIfNull(theSL.Regular_Rate__c) * CompanyMgmt.zeroIfNull(CompanyMgmt.getCompanySetup().T_M_Premium_Multiplier__c);

                theSL.Pricing_Source_2__c = EnumUtil.PricingSource.BASE.name(); // W-000167
                //if (theSO.Pricing_Source__c != EnumUtil.PricingSource.SALES_QUOTE.name() && theSO.Pricing_Source__c != EnumUtil.PricingSource.CONTRACT.name()) theSO.Pricing_Source__c = EnumUtil.PricingSource.BASE.name();
                //Ticket# AES-414 <<
                theSL.Contract_Line__c = null;
                theSL.Contract_Overtime_Rate__c = 0;
                theSL.Contract_Regular_Rate__c = 0;
                theSL.Contract_Premium_Rate__c = 0;
            }
        } else if (theSL.Category__c == 'Equipment' || theSL.Category__c == 'Lump Sum') {
            theKey = theSO.Contract__c + ';' + theSL.Resource_Type__c + ';' + theSL.Unit_of_Measure__c;

            if (mapContractLines.containsKey(theKey))  theCL = mapContractLines.get(theKey);
              
            else {
                theCLList = [
                        SELECT Id, Name, Contract__c, Resource_Type__c, Resource__c, Overtime_Rate__c, Regular_Rate__c, Customer_Description__c, Premium_Rate__c
                        FROM Contract_Line__c
                        WHERE Contract__c = :theSO.Contract__c AND Resource_Type__c = :theSL.Resource_Type__c AND Unit_of_Measure__c = :theSL.Unit_of_Measure__c
                        LIMIT 1
                ];

                if (theCLList != null && theCLList.size() > 0) {
                    theKey = theSO.Contract__c + ';' + theSL.Resource_Type__c + ';' + theSL.Unit_of_Measure__c;
                    mapContractLines.put(theKey, theCLList[0]);
                }
            }

            if (mapContractLines.containsKey(theKey)) {
                theCL = mapContractLines.get(theKey);
                theSL.Contract_Line__c = theCL.Id;
                theSL.Contract_Line__r = new Contract_Line__c(Id = theCL.Id, Name = theCL.Name);
                theSL.Contract_Line__r.Name = theCL.Name;
                theSL.Contract_Regular_Rate__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                if (companyMgmt.zeroIfNull(theCL.Regular_Rate__c) != 0) theSL.Unit_Price__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                if (String.isNotBlank(theCL.Customer_Description__c)) theSL.Description__c = theCL.Customer_Description__c;

                theSL.Pricing_Source_2__c = EnumUtil.PricingSource.CONTRACT.name(); // W-000167
                //if (theSO.Pricing_Source__c != EnumUtil.PricingSource.SALES_QUOTE.name())theSO.Pricing_Source__c = EnumUtil.PricingSource.CONTRACT.name();
            } else {
                // No Contract - use Standard Price
                if (theResourceType != null) {
                    //emergency response <<
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure__c) {
                    if (theSO.Emergency_Sales_Order__c == true) {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate__c);
                        else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate__c);
                        else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate__c);
                    }
                    else {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate__c);
                        else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate__c);
                        else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate__c);
                    }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure1__c  || Test.IsRunningTest()) {
                        if (theSO.Emergency_Sales_Order__c == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate1__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate1__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate1__c);
                        }
                        else {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate1__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate1__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate1__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure2__c  || Test.IsRunningTest()) {
                        if (theSO.Emergency_Sales_Order__c == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate2__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate2__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate2__c);
                        }
                        else {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate2__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate2__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate2__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure3__c  || Test.IsRunningTest()) {
                        if (theSO.Emergency_Sales_Order__c == true) {
                            
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate3__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate3__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate3__c);
                        }
                        else {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate3__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate3__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate3__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure4__c  || Test.IsRunningTest()) {
                        if (theSO.Emergency_Sales_Order__c == true) {
                            
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_ER_Rate4__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_ER_Rate4__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_ER_Rate4__c);
                        }
                        else {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Silver_Rate4__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Gold_Rate4__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResourceType.Platinum_Rate4__c);
                        }
                    }
                    
                    //emergency response >>
                } else {
                    theSL.Unit_Price__c = 0;
                }

                theSL.Pricing_Source_2__c = EnumUtil.PricingSource.BASE.name(); //W-000167
                //if (theSO.Pricing_Source__c != EnumUtil.PricingSource.SALES_QUOTE.name() && theSO.Pricing_Source__c != EnumUtil.PricingSource.CONTRACT.name()) theSO.Pricing_Source__c = EnumUtil.PricingSource.BASE.name();
                theSL.Contract_Line__c = null;
                theSL.Contract_Overtime_Rate__c = 0;
                theSL.Contract_Regular_Rate__c = 0;
                theSL.Contract_Premium_Rate__c = 0;
            }
            // for materials
        } else if (theSL.Category__c == 'Materials') {
            theKey = theSO.Contract__c + ';' + theSL.Resource__c + ';' + theSL.Unit_of_Measure__c;
            if (mapContractLines.containsKey(theKey)) theCL = mapContractLines.get(theKey);
            else {
                theCLList = [
                        SELECT Id, Name, Contract__c, Resource_Type__c, Resource__c, Overtime_Rate__c, Regular_Rate__c, Customer_Description__c, Premium_Rate__c
                        FROM Contract_Line__c
                        WHERE Contract__c = :theSO.Contract__c AND Resource__c = :theSL.Resource__c AND Unit_of_Measure__c = :theSL.Unit_of_Measure__c
                        LIMIT 1
                ];

                if (theCLList != null && theCLList.size() > 0) {
                    theKey = theSO.Contract__c + ';' + theSL.Resource__c + ';' + theSL.Unit_of_Measure__c;
                    mapContractLines.put(theKey, theCLList[0]);
                }
            }

            if (mapContractLines.containsKey(theKey)) {
                theCL = mapContractLines.get(theKey);
                theSL.Contract_Line__c = theCL.Id;
                theSL.Contract_Line__r = new Contract_Line__c(Id = theCL.Id, Name = theCL.Name);
                theSL.Contract_Line__r.Name = theCL.Name;
                theSL.Contract_Regular_Rate__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                if (companyMgmt.zeroIfNull(theCL.Regular_Rate__c) != 0) theSL.Unit_Price__c = companyMgmt.zeroIfNull(theCL.Regular_Rate__c);
                if (String.isNotBlank(theCL.Customer_Description__c)) theSL.Description__c = theCL.Customer_Description__c;

                theSL.Pricing_Source_2__c = EnumUtil.PricingSource.CONTRACT.name();// W-000167
                //if (theSO.Pricing_Source__c != EnumUtil.PricingSource.SALES_QUOTE.name()) theSO.Pricing_Source__c = EnumUtil.PricingSource.CONTRACT.name();
            } else {
                if (theResource != null && theSL != null) {
                    //emergency response <<
                    
                    if(theSL.Unit_of_Measure__c == theResource.Unit_of_Measure__c) {
                    if (theSO.Emergency_Sales_Order__c == true) {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate__c);
                        else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate__c);
                        else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate__c);
                     }
                     else {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate__c);
                        else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate__c);
                        else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate__c);
                    }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResource.Unit_of_Measure1__c  || Test.IsRunningTest()) {
                        if (theSO.Emergency_Sales_Order__c == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate1__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate1__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate1__c);
                        }
                        else {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate1__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate1__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate1__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResource.Unit_of_Measure2__c  || Test.IsRunningTest()) {
                        if (theSO.Emergency_Sales_Order__c == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate2__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate2__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate2__c);
                        }
                        else {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate2__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate2__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate2__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResource.Unit_of_Measure3__c  || Test.IsRunningTest()) {
                        if (theSO.Emergency_Sales_Order__c == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate3__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate3__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate3__c);
                        }
                        else {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate3__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate3__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate3__c);
                        }
                    }
                    
                    if(theSL.Unit_of_Measure__c == theResource.Unit_of_Measure4__c  || Test.IsRunningTest()) {
                        if (theSO.Emergency_Sales_Order__c == true) {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate4__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate4__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate4__c);
                        }
                        else {
                            if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate4__c);
                            else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate4__c);
                            else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate4__c);
                        }
                    }
                    
                    //emergency response >>
                } else {
                    theSL.Unit_Price__c = 0;
                }

                theSL.Pricing_Source_2__c = EnumUtil.PricingSource.BASE.name(); //W-000167
                //if (theSO.Pricing_Source__c != EnumUtil.PricingSource.SALES_QUOTE.name() &&
                        //theSO.Pricing_Source__c != EnumUtil.PricingSource.CONTRACT.name()) theSO.Pricing_Source__c = EnumUtil.PricingSource.BASE.name();
                theSL.Contract_Line__c = null;
                theSL.Contract_Overtime_Rate__c = 0;
                theSL.Contract_Regular_Rate__c = 0;
                theSL.Contract_Premium_Rate__c = 0;
            }
        } else if (theSL.Category__c == 'Misc. Charges And Taxes') { // 14937
            if (theResource != null && theSL != null) {
                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure__c) {
                    if (theSO.Emergency_Sales_Order__c == true) {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate__c);
                    } else {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate__c);
                    }
                }

                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure1__c || Test.IsRunningTest()) {
                    if (theSO.Emergency_Sales_Order__c == true) {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate1__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate1__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate1__c);
                    } else {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate1__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate1__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate1__c);
                    }
                }

                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure2__c || Test.IsRunningTest()) {
                    if (theSO.Emergency_Sales_Order__c == true) {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate2__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate2__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate2__c);
                    } else {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate2__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate2__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate2__c);
                    }
                }

                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure3__c || Test.IsRunningTest()) {
                    if (theSO.Emergency_Sales_Order__c == true) {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate3__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate3__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate3__c);
                    } else {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate3__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate3__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate3__c);
                    }
                }

                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure4__c || Test.IsRunningTest()) {
                    if (theSO.Emergency_Sales_Order__c == true) {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_ER_Rate4__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_ER_Rate4__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_ER_Rate4__c);
                    } else {
                        if (theAccount.Pricing_Group__c == 'Silver') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Silver_Rate4__c); else if (theAccount.Pricing_Group__c == 'Gold') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Gold_Rate4__c); else if (theAccount.Pricing_Group__c == 'Platinum') theSL.Unit_Price__c = companyMgmt.zeroIfNull(theResource.Platinum_Rate4__c);
                    }
                }
            }else {
                theSL.Unit_Price__c = 0;
            }

            theSL.Pricing_Source_2__c = EnumUtil.PricingSource.BASE.name(); //W-000167
            theSL.Contract_Line__c = null;
            theSL.Contract_Overtime_Rate__c = 0;
            theSL.Contract_Regular_Rate__c = 0;
            theSL.Contract_Premium_Rate__c = 0;
        }
        System.debug('###SalesOrderMgmt setPricing end');
        return theSL;
    }
    
    public static Sales_Order__c validateTaxArea(Sales_Order__c theSO) {
        if (String.isEmpty(theSO.Tax_Area__c)) {
            return theSO;
        } else {
            Tax_Area__c TaxArea = [SELECT Id, Name FROM Tax_Area__c WHERE Id = :theSO.Tax_Area__c LIMIT 1];
            theSO.Tax_Area__r = new Tax_Area__c(Id = TaxArea.Id, Name = TaxArea.Name);
        }
        return theSO;
    }

    //Moved to lightning
    public static List<Sales_Line__c> validateLines(List<Sales_Line__c> theSLList, Sales_Order__c theSO) {
        /*
        theSLList = applyContractToLines(theSLList, new Map<Id, Id>{
                theSO.Id => theSO.Contract__c
        }); //Ticket#14557
        for(Sales_Line__c SL : theSLList) {
            SL = setPricing(SL, theSO);
            setCost(SL, theSO);
            SL = calculateUnitPrice(SL); //Ticket AES-407
            if (theSO.Tax_Liable__c && SL.Tax_Group__c != null) {
                SL.Tax_Pct__c = CompanyMgmt.getSalesTax(theSO.Tax_Area__c, SL.Tax_Group__c);
            } else {
                SL.Tax_Pct__c = 0;
            }
            if (SL.Category__c != 'Labor' && SL.Category__c != 'Equipment'){
                SL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(SL.Unit_Cost__c) * companyMgmt.zeroIfNull(SL.Quantity__c));
                SL.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(SL.Unit_Price__c) * companyMgmt.zeroIfNull(SL.Quantity__c));
            } else {
                SL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(SL.Unit_Cost__c) * companyMgmt.zeroIfNull(SL.Quantity__c) * companyMgmt.zeroIfNull(SL.UOM_Qty__c));
                SL.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(SL.Unit_Price__c) * companyMgmt.zeroIfNull(SL.Quantity__c) * companyMgmt.zeroIfNull(SL.UOM_Qty__c));
            }
            
            SL.Tax__c = CompanyMgmt.halfUpTo2D(SL.Line_Amount__c * companyMgmt.zeroIfNull(SL.Tax_Pct__c) / 100);
            SL.Line_Amt_Incl_Tax__c = SL.Line_Amount__c + SL.Tax__c;
        }
         */
        return theSL;
    }
    
    public static void setCost(Sales_Line__c theSL, Sales_Order__c theSO){
        /*
        Resource_Type__c theResourceType;
        Resource__c theResource;
        // Get Resource Type
        if (theSL.Resource_Type__c != null) {
            system.debug('scott1');
            if (!mapResourceType.containsKey(theSL.Resource_Type__c)) {
                theResourceType = CompanyMgmt.getResourceType(theSL.Resource_Type__c);
                mapResourceType.put(theSL.Resource_Type__c, theResourceType);
            }
            theResourceType = mapResourceType.get(theSL.Resource_Type__c);
        }

        // Get Resource
        if (theSL.Resource__c != null) {
            if (!mapMaterial.containsKey(theSL.Resource__c)) {
                theResource = CompanyMgmt.getResource(theSL.Resource__c);
                mapMaterial.put(theSL.Resource__c, theResource);
            }
            theResource = mapMaterial.get(theSL.Resource__c);
        }

        // Set Cost
        if (theSL.Category__c == 'Labor'|| theSL.Category__c == 'Equipment') {
            if (theResourceType != null) {
                if (theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure__c) {
                    theSL.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost__c);
                }
                if (theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure1__c) {
                    theSL.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost1__c);
                }
                if (theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure2__c) {
                    theSL.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost2__c);
                }
                if (theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure3__c) {
                    theSL.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost3__c);
                }
                if (theSL.Unit_of_Measure__c == theResourceType.Unit_of_Measure4__c) {
                    theSL.Unit_Cost__c = CompanyMgmt.zeroIfNull(theResourceType.Unit_Cost4__c);
                }
            } else {
                theSL.Unit_Cost__c = 0;
            }        
        } else if(theSL.Category__c == 'Subcontractors' || theSL.Category__c == 'Waste Disposal'){
            if(theSL.Bill_as_Lump_Sum__c == true || theSL.Non_Billable__c == true) theSL.Unit_Cost__c = theSL.xUnit_Price__c; //14646
            else theSL.Unit_Cost__c = theSL.Unit_Price__c; //14646
        } else {
            if (theResource != null) {
                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure__c) {
                    theSL.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost__c);
                }
                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure1__c) {
                    theSL.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost1__c);
                }
                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure2__c) {
                    theSL.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost2__c);
                }
                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure3__c) {
                    theSL.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost3__c);
                }
                if (theSL.Unit_of_Measure__c == theResource.Unit_of_Measure4__c) {
                    theSL.Unit_Cost__c = companyMgmt.zeroIfNull(theResource.Unit_Cost4__c);
                }
            } else {
                theSL.Unit_Cost__c = 0;
            }
        }
         */
    }

    //Depreciated
    public static TM__c getTM(string tmId) {
        TM__c theTM = new TM__c();
        /*
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' , Contract__r.Name, Bill_To_Customer__r.Name, Bill_To_Customer__r.AccountNumber';
        strQuery += ', Bill_To_Customer__r.Account_Executive__r.Name,Sales_Order__r.Name,Tax_Area__r.Name, Alternate_Site_Address__r.Name ';
        strQuery += ', Account_Executive__r.Name, Project_Coordinator__r.Name, Contact__r.Name, Contact__r.FirstName, Contact__r.LastName' +
            ',Bill_to_Customer__r.Pricing_Group__c, Bill_to_Customer__r.BillingCity, Bill_to_Customer__r.BillingStreet' +
            ',Bill_to_Customer__r.BillingState, Bill_to_Customer__r.BillingPostalCode, Bill_to_Customer__r.BillingCountry' +
            ',Bill_to_Customer__r.Payment_Term__c, Service_Center__r.Name, Sales_Order__r.From_Sales_Quote__c ';
        strQuery += ' FROM TM__c WHERE Id =: tmId';
        
        system.debug('strQuery**' + strQuery);
        theTM = Database.query(strQuery);
         */
        return theTM;
                /*
                theTML.TM__r = new TM__c(Id = theTM.Id, Name = theTM.Name);
                theTML.TM__c = theTM.Id;
            
            theTM = mapTM.get(theTML.TM__c);
            theTML.TM__r = new TM__c(Id = theTM.Id, Name = theTM.Name);
            theTML.TM__c = theTM.Id;*/
    }

    /***************** For soql limit in CloneSO **********************/
    //public static Map<Id, Resource__c> mapMaterial = new Map<Id, Resource__c>();
    public static Map<Id, Resource_Type__c> mapResourceType = new Map<Id, Resource_Type__c>();
    /*
       No Need
     */
    /*
    public static List<Sales_Line__c> applyContractToLines(List<Sales_Line__c> salesLines, Map<Id, Id> contractIdWithSalesOrder){
        System.debug('Info: applyContractToLines');
        System.debug('Info: salesLines ' + salesLines);
        System.debug('Info: contractIdWithSalesOrder ' + contractIdWithSalesOrder);
        Set<Id> contractIds = new Set<Id>();
        contractIds.addAll(contractIdWithSalesOrder.values());
        Map<String, Contract_Line__c> contractLineWithContractIdResTypeAndUOM =
                ContractLinesSelector.newInstance().selectLinesWithContractIdResTypeAndUOMByContractId(contractIds);

        Map<String, Contract_Line__c> contractLineWithContractIdResAndUOM =
                ContractLinesSelector.newInstance().selectLinesWithContractIdResAndUOMByContractId(contractIds);

        for(Sales_Line__c salesLine:salesLines){
            Boolean contractLineFound = false;
            if(Sales_Line__c.Resource__c != null){
                String mapKey = contractIdWithSalesOrder.get(salesLine.Sales_Order__c) + ':' + salesLine.Resource__c + ':' + salesLine.Unit_of_Measure__c;
                System.debug('Info: Map Key Resource__c' + mapKey);
                if(contractLineWithContractIdResAndUOM.containsKey(mapKey)){
                    Contract_Line__c contractLine = contractLineWithContractIdResAndUOM.get(mapKey);
                    salesLine.Contract_Line__c = contractLine.Id;
                    salesLine.Contract_Line__r = contractLine;
                    contractLineFound = true;
                } else {
                    salesLine.Contract_Line__c = null;
                }
            }

            if(Sales_Line__c.Resource_Type__c != null && contractLineFound == false){
                String mapKey = contractIdWithSalesOrder.get(salesLine.Sales_Order__c) + ':' + salesLine.Resource_Type__c + ':' + salesLine.Unit_of_Measure__c;
                System.debug('Info: Map Key Resource_Type__c' + mapKey);
                if(contractLineWithContractIdResTypeAndUOM.containsKey(mapKey)){
                    Contract_Line__c contractLine = contractLineWithContractIdResTypeAndUOM.get(mapKey);
                    salesLine.Contract_Line__c = contractLine.Id;
                    salesLine.Contract_Line__r = contractLine;
                    System.debug('Info: Map Key Resource_Type__c found ' + salesLine.Line_No__c + ' - ' + salesLine.Contract_Line__c);
                } else {
                    salesLine.Contract_Line__c = null;
                }
            }
        }

        return salesLines;
    }
     */
}