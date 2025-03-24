/*************************************************************************************************
* Name         :  SalesOrdersServiceImpl
* Description  :  Service used by Quote/Order and related pages on Sales Order
*
* Test classes
* SalesOrdersServiceTest
* ACVSalesOrderControllerTest
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      03-20-2024             81966: Salesforce Billing Package Should Not Be Sent to EQAI Work Order Without D365 Project ID on Sales Order in Salesforce
* Andrew Simons             05-13-2024             87270: Sent_to_EQAI_Date__c set to null when quote is cloned
* Prabhu Rathakrishnan      09/09/2024             US121824: Salesforce - Billing Project lookup on Sales Order
* Pavithra P                10-16-2024             US124701: [Continued] [Continued] [Continued] [Unplanned] - Update - Salesforce Assign Multiple Salespeople to an Account and Sales Orders
* Prabhu Rathakrishnan      10/13/2024             US127188 - Salesforce - Modifications to allow ESIC Surcharge Type
* Prabhu Rathakrishnan      11/18/2024             TA476466 - Case 121441 - Blocked Pay Rule allowed to be used.
  Shahwaz Khan              01/10/2042             US136059 - Salesforce - Remove values stored in Disposal fields (Disposal billing method, Profile approval) when cloning sales quotes/orders from advanced disposal SC to non advanced disposal SC
* Andrew Simons             01/22/2025             US137003 - SF - Force Generator Lookup on Site Information tab of Sales Quote/Order for Advanced Disposal Service Centers 
* Yuvraj Ganesan			02/17/2025             DE37804 - Check Contract Surcharge type and set Surcharge Type as 'N/A'
* Yuvraj Ganesan			03/17/2025			   DE38307 - Salesforce EEC Fee Line Incorrectly Allowed to be Marked as Non-Billable
  *************************************************************************************************/
public with sharing class SalesOrdersServiceImpl implements ISalesOrdersService{

    //job task <<
    /* move to SalesLinesService
    public static Map<Id, Resource_Type__c> mapResourceTypesById = new Map<Id, Resource_Type__c>();
    public static Map<Id, Resource__c> mapResourcesById = new Map<Id, Resource__c>();
     */
    //job task >>

    public static Company_Setup__c theCompanySetupValue;

    private Company_Setup__c theCompanySetup {
        get{
            if (theCompanySetupValue == null) {
                theCompanySetupValue = CompanyMgmt.getCompanySetup();
            }
            return theCompanySetupValue;
        }
    }

    //job task <<
    /* moved to
    public void initStaticVariables(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        //init resource and resource type maps
        Set<Id> resourceTypeIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();

        //add surcharge resources and manifest resource
        resourceIds.add(theCompanySetup.Default_Energy_Insurance_Resource__c);
        resourceIds.add(theCompanySetup.Default_Fuel_Surcharge_Resource__c);
        resourceIds.add(theCompanySetup.Default_Manifest_Fee_Resource__c);
        resourceIds.add(CompanySettingUtil.acvSetting.Default_Retainage_Resource_Id__c);

        mapResourceTypesById = ResourceTypesSelector.newInstance().getResourceTypesByIdsMap(resourceTypeIds);
        mapResourcesById = ResourcesSelector.newInstance().getResourcesByIdsMapByResIds(resourceIds);
    }*/
    //job task >>

    public void updateSalesLinesForBillAsLumpSumAllAction(List<Sales_Line__c> theSLList) {
        ISalesLines salesLinesDomain = SalesLines.newInstance(theSLList);
        prepareSalesLinesDomainMap(theSLList);
        salesLinesDomain.updateSalesLinesForBillAsLumpSumAllAction();
    }

    public void prepareSalesLinesDomainMap(List<Sales_Line__c> theSLList) {
        Set<Id> salesOrderIdSet = new Set<Id>();
        for (Sales_Line__c theSL : theSLList){
            salesOrderIdSet.add(theSL.Sales_Order__c);
        }
        SalesLines.mapSalesOrders.putAll(SalesOrdersSelector.newInstance().selectById(salesOrderIdSet));
    }

    /*
        Ticket#18267 Allow block service center
     */
    public Sales_Order__c createNewSalesQuoteOrSalesOrder(String documentType, Id billToCustomerId, String serviceCenter, String contract, String quote) {
        //Ticket#27427 >>
        List<User_Service_Center__c> userServiceCenters = [SELECT Id, Service_Center__r.Prevent_New_and_Cloned_Sales_Orders__c, Service_Center__r.Name FROM User_Service_Center__c WHERE User__c = :UserInfo.getUserId()];
        if(userServiceCenters.size() == 1 && userServiceCenters[0].Service_Center__r.Prevent_New_and_Cloned_Sales_Orders__c == true && documentType == 'Sales Order'){
            throw new DataException('Service Center ' + userServiceCenters[0].Service_Center__r.Name + ' is prevented from creating new Sales Orders.');
        }
        //Ticket#27427 <<
        Sales_Order__c theSO = new Sales_Order__c();

        theSO.OwnerId = UserInfo.getUserId();
        List<Service_Center__c> theSCList = ServiceCentersSelector.newInstance().selectByName(serviceCenter);
        if (theSCList.size() > 0) {
            Service_Center__c theSC= theSCList[0];
            if(theSC.Blocked__c == true){
                theSO.Service_Center__c = null;
            } else {
                theSO.Service_Center__c = theSC.Id;
            }

            theSO.Subsidiary_Company__c = theSC.Subsidiary_Company__c;
            theSO.Service_Center__r = theSC;
            theSO.Subsidiary_Company__r = theSC.Subsidiary_Company__r;
        }
        theSO.Document_Type__c = documentType;
        if (theSO.Document_Type__c == 'Sales Order'){
            theSO.Quote_Date__c = Date.today();
            theSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId();
            theSO.From_Sales_Quote__c = quote;
        } else {
            theSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();
            theSO.Quote_Date__c = Date.today();
            theSO.Quote_Type__c = EnumUtil.QuoteType.ONE_TIME.name();
            theSO.Quote_Status__c = EnumUtil.QuoteStatus.PENDING.name();
        }

        theSO.Prevailing_Wage_Job__c = true;

        theSO.Duration__c = 1;
        if (theSO.Document_Type__c == 'Sales Order') {
            theSO.Manifest_And_Profile__c = true; //per Jay
        }

        if (String.isNotEmpty(contract)) {
            List<Contract> contracts = ContractsSelector.newInstance().selectByIdWithBillingRule(new Set<Id>{contract});
            if (contracts.size() > 0 ){
                Contract theContract = contracts[0];
                theSO.Contract__c = theContract.Id;
                theSO.Contract__r = theContract;
                theSO.Billing_Rule__c = theContract.Billing_Rule__c;
                theSO.Billing_Rule__r = theContract.Billing_Rule__r; 
                //copy surcharge setup from contract to sales order/quote #15605
                if(String.isNotBlank(theContract.Surcharge_Type__c)){
                    theSO.Surcharge_Type__c = theContract.Surcharge_Type__c;
                    theSO.Surcharge_Pct__c = CompanyMgmt.zeroIfNull(theContract.Surcharge_Pct__c);
                }
            }
        }

        /*
        else if (theSO.Service_Center__c != null){ //Ticket#21540
            theSO.Billing_Rule__c = theSCList[0].Billing_Rule__c;
            theSO.Billing_Rule__r = theSCList[0].Billing_Rule__r;
            if(String.isNotBlank(theSCList[0].Surcharge_Type__c)){
                theSO.Surcharge_Type__c = theSCList[0].Surcharge_Type__c;
                theSO.Surcharge_Pct__c = CompanyMgmt.zeroIfNull(theSCList[0].Surcharge_Pct__c);
            }
        }
         */

        //Ticket21540 >>
        /*
        else {
            theSO.Surcharge_Type__c = 'Energy & Insurance';
            setSurchargePct(theSO);
        }
         */

        //default surcharge type to Energy and Insurance #15605
        if(String.isBlank(theSO.Surcharge_Type__c)){
            theSO.Surcharge_Type__c = 'EEC Fee';
            setSurchargePct(theSO);
        }

        if(theSO.Billing_Rule__c == null && theSO.Subsidiary_Company__r.Billing_Rule__c != null){
            theSO.Billing_Rule__c = theSO.Subsidiary_Company__r.Billing_Rule__c;
            theSO.Billing_Rule__r = theSO.Subsidiary_Company__r.Billing_Rule__r;
        }
        //Ticket21540 <<

        List<Account> accounts = AccountsSelector.newInstance().selectById(new Set<Id>{billToCustomerId});
        theSO.Bill_to_Customer_No__c = billToCustomerId;
        theSO.Bill_to_Customer_No__r = accounts[0];
        theSO.Document_Status__c = 'Open';
        theSO.Portal_Basis__c = false;

        //Ticket#24559 >>
        //theSO.Portal_Basis_Adv__c = true;
        theSO.Portal_Basis_Adv__c = false;
        theSO.Default_Billing_Rule_2023__c = true;
        //Ticket#24559 <<

        //Ticket#24650 >>
        if (theSO.Billing_Rule__c == null) {
            Billing_Rule__c billingRule = BillingRuleService.getBillingRuleIdForSalesOrderAssumption(theSO);
            theSO.Billing_Rule__r = billingRule;
            theSO.Billing_Rule__c = billingRule.Id;
        }
        //Ticket#24650 <<

        updateSalesOrderBillingAndTax(theSO, true);

        //ticket 19895 <<
        theSO.Tax_Area__c = accounts[0].Tax_Area__c;
        theSO.Tax_Area__r = accounts[0].Tax_Area__r;

        if (theSO.Bill_to_Customer_No__r.Service_Center__r.Advanced_Disposal__c == false) { //US137003
            theSO.Site_Street__c = accounts[0].BillingStreet;
            theSO.Site_City__c = accounts[0].BillingCity;
            theSO.Site_State__c = accounts[0].BillingStateCode;
            theSO.Site_Postal_Code__c = accounts[0].BillingPostalCode;
            theSO.Site_Country__c = accounts[0].BillingCountryCode;
            theSO.Site_Phone_No__c = accounts[0].Phone;
        }
        //ticket 19895 >>

        //aura <<
        //terms and conditions
        if (theSO.Document_Type__c == 'Sales Quote') {
            theSO.Any_Deviations__c = true;
            theSO.Shippable_Containers__c = true;
            theSO.First_Hour_Of_Loading__c = true;
            theSO.Overtime_Rate_Description__c = true;
            theSO.Rate_Time_Definitions__c = true;
            theSO.Charges_For_Labor__c = true;
            theSO.Waste_Disposal_And_Ancillary__c = true;
            theSO.Characterization_Of_Waste__c = true;
            theSO.Generate_Before_Final__c = true;
            theSO.Lab_Packs_Rate__c = true;
            theSO.Cylinders_Require_Evaluation__c = true;
            theSO.Manifest_And_Profile__c = true;
            theSO.Net_Due_Day__c = true;
            theSO.Applicable_Taxes_Quote__c = true;
            theSO.Client_Is_Responsible__c = true;
            theSO.In_The_Event__c = true;
            theSO.Quote_Valid_30__c = true;
            theSO.Unless_Superseded__c = true;
			theSO.Term_Conditions_Opt20__c = true;
        }
        //aura >>

        //set default assumptions
        theSO.Free_Access__c = true;
        theSO.Pricing__c = true;
        theSO.Expendables__c = true;
        theSO.Applicable_Taxes__c = true;
        theSO.Manifest_And_Profile__c = true;
        theSO.Portal_Basis__c = false;
        //Ticket#24559 >>
        //theSO.Portal_Basis_Adv__c = true;
        theSO.Portal_Basis_Adv__c = false;
        theSO.Default_Billing_Rule_2023__c = true;
        //Ticket#24559 <<
        theSO.Overtime_Rate__c = false;
        theSO.Daily_Rate__c = false;
        theSO.Lump_Sum__c = false;

        theSO.Minimum_Disposal_Fee__c = true;
        theSO.Disposal_Pricing__c = true;
        theSO.First_Hour_Of_Loading__c = true;
        theSO.Invoice_Of_Work__c = true;
        theSO.Minimum_Disposal_Charge__c = true;
        theSO.Maximum_Weight__c = true;
        theSO.Off_Specification__c = true;
        theSO.Overtime_Rate__c = false;
        theSO.Daily_Rate__c = false;
        theSO.Lump_Sum__c = false;
        //set default assumptions

        return theSO;
    }

    public void updateSalesOrderBillingAndTax(Sales_Order__c theSO, Boolean isNewSO) {
        Account billToCust = AccountsSelector.newInstance().selectById(new Set<Id>{theSO.Bill_to_Customer_No__c})[0];
        theSO.Street__c = billToCust.BillingStreet;
        theSO.City__c = billToCust.BillingCity;
        theSO.State__c = billToCust.BillingStateCode;
        theSO.Postal_Code__c = billToCust.BillingPostalCode;
        //ticket 33537
        theSO.Country__c = billToCust.BillingCountryCode;
        if(billToCust.BillingCountryCode != null && billToCust.BillingCountryCode == 'CA') {
            theSO.Country__c = 'CAN';
        }
        theSO.Fax_No__c = billToCust.Fax;
        theSO.Phone_No__c = billToCust.Phone;
        theSO.Phone_Ext__c = billToCust.Phone_Ext__c;
        //ticket 19895 <<
        /*
        theSO.Tax_Area__c = billToCust.Tax_Area__c;
        theSO.Tax_Area__r = billToCust.Tax_Area__r;
        */
        theSO.Tax_Area__c = null;
        theSO.Tax_Area__r = null;
        theSO.Site_Name__c = null;
        theSO.Site_Street__c = null;
        theSO.Site_City__c = null;
        theSO.Site_State__c = null;
        theSO.Site_Postal_Code__c = null;
        theSO.Site_Country__c = null;
        theSO.Site_Phone_No__c = null;
        //ticket 19895 >>

        if(billToCust.Inter_co_Account__c != true){
            theSO.Tax_Liable__c = true;
        } else {
            theSO.Tax_Liable__c = false;
            theSO.Inter_Company_Job__c = true;
        }

        /*
         *  Ticket#21211 add Inter_co_Account__c to Customer initiation
         *  Ticket#20977 - add Subsidiary_Company__r for new new order\quote creation
         *  Task#81352   - Shahwaz Khan (Added by) : Add Additional Options to Sales Order Type Field line 280,281
         */
        theSO.Bill_to_Customer_No__r = new Account(Id = billToCust.Id,
                                                   Name = billToCust.Name,
                                                   ParentId = billToCust.ParentId,
                                                   Subsidiary_Company__c = billToCust.Subsidiary_Company__c,
                                                   Subsidiary_Company__r = billToCust.Subsidiary_Company__r,
                                                   AccountNumber = billToCust.AccountNumber,
                                                   PO_Number_Type__c = billToCust.PO_Number_Type__c,
                                                   Inter_co_Account__c = billToCust.Inter_co_Account__c,
                                                   Service_Center__c = billToCust.Service_Center__c,   
                                                   Service_Center__r = billToCust.Service_Center__r, 
                                                   Sage_Customer_No__c = billToCust.Sage_Customer_No__c);  //Task#78375 Task#78376

        if (isNewSO){
            List<Contact> billingContacts = ContactsSelector.newInstance().selectBillingContactsByAccount(new Set<Id>{billToCust.Id});

            if(billingContacts.size() == 1){
                theSO.Bill_to_Contact__c = billingContacts[0].Id;
                theSO.Bill_to_Contact__r = billingContacts[0];
            }
            if (theSO.Document_Type__c == 'Sales Quote') { //W-000392
                List<Contact> quoteContacts = ContactsSelector.newInstance().selectQuoteContactsByAccount(new Set<Id>{billToCust.Id});
                if (quoteContacts.size() == 1){
                    theSO.Quote_Contact__c = quoteContacts[0].Id;
                    theSO.Quote_Contact__r = quoteContacts[0];
                }
            }

            //ticket 19895 <<
            //theSO.Tax_Area__r = billToCust.Tax_Area__r;
            //ticket 19895 >>

            //theSO.Account_Executives__c = billToCust.Account_Executive__c;
            //theSO.Account_Executives__r = billTocust.Account_Executive__r;
            //US124701 - To make Account Executive as null
           // theSO.Account_Executives__c = billToCust.Account_Executive__c;
           // theSO.Account_Executives__r = billTocust.Account_Executive__r;
            /* Ticket#19752 - blank out when create new SQ/SO
            theSO.Project_Coordinator__c = billToCust.Salesperson__c;
            theSO.Project_Coordinator__r = billToCust.Salesperson__r;
             */

            theSO.Billing_Instructions__c = billToCust.Billing_Instructions__c;
            theSO.Customer_Billing_Instructions__c = AccountsService.generateCustomerBillingInstructions(billToCust);
            theSO.Internal_Comments__c = billToCust.Internal_Comments__c;
            theSO.Tax_Liable__c = billToCust.Tax_Liable__c;

            if ((String.isEmpty(theSO.Billing_Instructions__c) || String.isEmpty(theSO.Internal_Comments__c)) && String.isNotEmpty(billToCust.ParentId)) {
                List<Account> accounts = AccountsSelector.newInstance().selectBillingInstructionsById(new Set<Id>{billToCust.ParentId});
                if (accounts.size() > 0) {
                    Account corporateAccount = accounts[0];
                    if (String.isNotEmpty(corporateAccount.Billing_Instructions__c) && String.isEmpty(theSO.Billing_Instructions__c)) {
                        theSO.Billing_Instructions__c = corporateAccount.Billing_Instructions__c;
                    }
                    if (String.isNotEmpty(corporateAccount.Internal_Comments__c) && String.isEmpty(theSO.Internal_Comments__c)) {
                        theSO.Internal_Comments__c = corporateAccount.Internal_Comments__c;
                    }
                }
            }

            if (billToCust.Type == 'Prospect') {
                theSO.Payment_Term__c = theCompanySetup.Quote_Default_Payment_Term__c;
                theSO.Payment_Term__r = theCompanySetup.Quote_Default_Payment_Term__r;
            } else if (billToCust.Type == 'Customer') {
                theSO.Payment_Term__c = billToCust.Payment_Term__c;
                theSO.Payment_Term__r = billToCust.Payment_Term__r;
            }

            //ticket 19895 <<
            /*
            theSO.Site_Street__c = billToCust.BillingStreet;
            theSO.Site_City__c = billToCust.BillingCity;
            theSO.Site_State__c = billToCust.BillingStateCode;
            theSO.Site_Postal_Code__c = billToCust.BillingPostalCode;
            theSO.Site_Country__c = billToCust.BillingCountryCode;
            theSO.Site_Phone_No__c = billToCust.Phone;
            */
            //ticket 19895 >>
        } else {
            //Ticket#23456 >>
            theSO.Surcharge_Type__c = 'EEC Fee';
            setSurchargePct(theSO);
            if(theSO.Subsidiary_Company__r.Billing_Rule__c != null){
                theSO.Billing_Rule__c = theSO.Subsidiary_Company__r.Billing_Rule__c;
                theSO.Billing_Rule__r = theSO.Subsidiary_Company__r.Billing_Rule__r;
            } else {
                theSO.Billing_Rule__c = theCompanySetup.Default_Billing_Rule__c;
                theSO.Billing_Rule__r = theCompanySetup.Default_Billing_Rule__r;
            }
            //Ticket#24559 >>
            //theSO.Portal_Basis_Adv__c = true;
            theSO.Portal_Basis_Adv__c = false;
            theSO.Default_Billing_Rule_2023__c = true;
            //Ticket#24559 <<

            theSO.Portal_Basis__c = false;
            theSO.Overtime_Rate__c = false;
            theSO.Daily_Rate__c = false;
            theSO.Lump_Sum__c = false;
            //Ticket#23456 <<
        }
    }

    public void setSurchargePct(Sales_Order__c salesOrder) {
        Boolean surchargeFound = false;
        if (salesOrder.Contract__c != null) {
            List<Contract> contracts = ContractsSelector.newInstance().selectById(new Set<Id>{
                    salesOrder.Contract__c
            });
            if(contracts != null && contracts.size() > 0) {
                if (contracts[0].Surcharge_Type__c != null && contracts[0].Surcharge_Type__c != 'N/A') {
                    if(salesOrder.Surcharge_Type__c != null){
                        if(salesOrder.Surcharge_Type__c.equals( contracts[0].Surcharge_Type__c)){
                    		salesOrder.Surcharge_Type__c = contracts[0].Surcharge_Type__c;        
                        }
                        else{
                            salesOrder.Surcharge_Pct__c = null;
                        }
                    }
                    
                    if (salesOrder.Surcharge_Type__c == 'N/A') {
                        salesOrder.Surcharge_Pct__c = null;
                    } else {
                        if (contracts[0].Surcharge_Pct__c != null) {
                            if(salesOrder.Surcharge_Type__c.equals( contracts[0].Surcharge_Type__c)){
                                salesOrder.Surcharge_Pct__c = contracts[0].Surcharge_Pct__c;
                                surchargeFound = true;
                            }
                            else{
                                salesOrder.Surcharge_Pct__c = null;
                            }
                        }
                    }
                }
            }
        }

        //Ticket#21540 >>
        /*
        if(surchargeFound == false && salesOrder.Service_Center__c != null){
            List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectById(new Set<Id>{salesOrder.Service_Center__c});
            if(serviceCenters[0].Surcharge_Type__c != null){
                salesOrder.Surcharge_Type__c = serviceCenters[0].Surcharge_Type__c;
                if(salesOrder.Surcharge_Type__c == 'N/A'){
                    salesOrder.Surcharge_Pct__c = null;
                } else {
                    if(serviceCenters[0].Surcharge_Pct__c != null){
                        salesOrder.Surcharge_Pct__c = serviceCenters[0].Surcharge_Pct__c;
                        surchargeFound = true;
                    }
                }
            }
        }
         */
        //Ticket#21540 <<
		system.debug('salesOrder.Surcharge_Type__c********************'+salesOrder.Surcharge_Type__c);
        system.debug('salesOrder.surchargeFound********************'+surchargeFound);
        //system.debug('salesOrder.Surcharge_Pct__c********************'+salesOrder.Surcharge_Pct__c);surchargeFound
        if ((salesOrder.Surcharge_Type__c == 'EEC Fee' || salesOrder.Surcharge_Type__c == 'Fuel Surcharge' || salesOrder.Surcharge_Type__c == 'ESIC') && salesOrder.Quote_Date__c != null && surchargeFound == false) {
            //Ticket#21540 >>
            List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectById(new Set<Id>{salesOrder.Service_Center__c});
            if(serviceCenters != null && serviceCenters.size() > 0) {
                if (salesOrder.Surcharge_Type__c == 'EEC Fee' && CompanyMgmt.zeroIfNull(serviceCenters[0].Energy_Environmental_Compliance_Pct__c) > 0) {
                    salesOrder.Surcharge_Pct__c = serviceCenters[0].Energy_Environmental_Compliance_Pct__c;
                    surchargeFound = true;
                }

                if (salesOrder.Surcharge_Type__c == 'Fuel Surcharge' && CompanyMgmt.zeroIfNull(serviceCenters[0].Fuel_Surcharge_Pct__c) > 0) {
                    salesOrder.Surcharge_Pct__c = serviceCenters[0].Fuel_Surcharge_Pct__c;
                    surchargeFound = true;
                }
                
                if(salesOrder.Surcharge_Type__c == 'ESIC' && CompanyMgmt.zeroIfNull(serviceCenters[0].ESIC_Surcharge_Cost_Pct__c) > 0){
                    salesOrder.Surcharge_Pct__c = serviceCenters[0].ESIC_Surcharge_Cost_Pct__c ;
                    surchargeFound = true;
                }
            }
			system.debug('surchargeFound**************************'+surchargeFound);
            if(surchargeFound == false) {
                //Surcharge_Setup__c surchargeSetup = SurchargeSetupsSelector.newInstance().selectByTypeAndEffectiveDate(salesOrder.Quote_Date__c, salesOrder.Surcharge_Type__c);
                Surcharge_Setup__c surchargeSetup = SurchargeSetupsSelector.newInstance().selectByTypeAndEffectiveDate(salesOrder.Quote_Date__c, salesOrder.Surcharge_Type__c, salesOrder.Subsidiary_Company__c);
                //Ticket#21540 <<
                if (surchargeSetup != null) {
                    system.debug('inside if before setting value fomr surcharge setup'+surchargeSetup.Surcharge_Pct__c);
                    salesOrder.Surcharge_Pct__c = surchargeSetup.Surcharge_Pct__c;
                } else {
                    salesOrder.Surcharge_Pct__c = null;
                }
            }
        }

        if (salesOrder.Surcharge_Type__c == null || salesOrder.Surcharge_Type__c == 'N/A') {
            salesOrder.Surcharge_Pct__c = null;
        }
    }

    //ticket 19672 << -- surcharge needs to be per job task
    /*
    public void calcSurchargeAmount(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines){
        Decimal surchargeAmt = 0;
        if(salesOrder.Surcharge_Type__c != null){
            Decimal subTotalForSurchargeCalculation = 0;
            subTotalForSurchargeCalculation = calcTotalForSurchargeCalculation(salesOrder.Surcharge_Type__c, salesLines);
            surchargeAmt = CompanyMgmt.halfUpTo2D(subTotalForSurchargeCalculation * CompanyMgmt.zeroIfNull(salesOrder.Surcharge_Pct__c) / 100);
        }

        salesOrder.Surcharge_Amount__c = surchargeAmt;
    }

    public void addRemoveSurchargeLine(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines) {
        //add/update/remove surcharge lines
        if (salesOrder.Surcharge_Type__c == 'Energy & Insurance' || salesOrder.Surcharge_Type__c == 'Fuel Surcharge') {
            this.addSurchargeLine(salesOrder, salesLines);
        }
        else {
            this.removeSurchargeLine(salesOrder, salesLines);
        }
    }

    private void addSurchargeLine(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines) {
        if (salesLines.size() == 0) {
            return;
        }

        Boolean surchargeLineFound = false;
        for (Sales_Line__c salesLine : salesLines) {
            if (salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true &&
                    (salesLine.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c || salesLine.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c)) {
                salesLine.Unit_Price__c = salesOrder.Surcharge_Amount__c;
                salesLine.Line_Amount__c = salesOrder.Surcharge_Amount__c;
                salesLine.Line_Amt_Incl_Tax__c = salesOrder.Surcharge_Amount__c;

                if(salesOrder.Surcharge_Type__c == 'Energy & Insurance' && salesLine.Resource__c != theCompanySetup.Default_Energy_Insurance_Resource__c){
                    salesLine.Resource__c = theCompanySetup.Default_Energy_Insurance_Resource__c;
                    salesLine.Resource__r = theCompanySetup.Default_Energy_Insurance_Resource__r;
                    salesLine.Description__c = theCompanySetup.Default_Energy_Insurance_Resource__r.Description__c;
                }

                if(salesOrder.Surcharge_Type__c == 'Fuel Surcharge' && salesLine.Resource__c != theCompanySetup.Default_Fuel_Surcharge_Resource__c){
                    salesLine.Resource__c = theCompanySetup.Default_Fuel_Surcharge_Resource__c;
                    salesLine.Resource__r = theCompanySetup.Default_Fuel_Surcharge_Resource__r;
                    salesLine.Description__c = theCompanySetup.Default_Fuel_Surcharge_Resource__r.Description__c;
                }

                surchargeLineFound = true;
            }
        }

        if (!surchargeLineFound) {
            //get the last line no
            Integer lineNo = 0;
            for (Sales_Line__c salesLine : salesLines) {
                if (lineNo < salesLine.Line_No__c.intValue()) {
                    lineNo = salesLine.Line_No__c.intValue();
                }
            }
            lineNo++;

            Sales_Line__c surchargeLine = new Sales_Line__c(Category__c = 'Misc. Charges And Taxes', Line_No__c = lineNo, Sales_Order__c = salesOrder.Id);
            if (salesOrder.Surcharge_Type__c == 'Energy & Insurance') {
                surchargeLine.Resource__c = theCompanySetup.Default_Energy_Insurance_Resource__c;
                surchargeLine.Resource__r = theCompanySetup.Default_Energy_Insurance_Resource__r;
                surchargeLine.Description__c = theCompanySetup.Default_Energy_Insurance_Resource__r.Description__c;
                surchargeLine.Unit_of_Measure__c = theCompanySetup.Default_Energy_Insurance_Resource__r.Unit_of_Measure__c;
                surchargeLine.Unit_of_Measure__r = theCompanySetup.Default_Energy_Insurance_Resource__r.Unit_of_Measure__r;
            } else {
                surchargeLine.Resource__c = theCompanySetup.Default_Fuel_Surcharge_Resource__c;
                surchargeLine.Resource__r = theCompanySetup.Default_Fuel_Surcharge_Resource__r;
                surchargeLine.Description__c = theCompanySetup.Default_Fuel_Surcharge_Resource__r.Description__c;
                surchargeLine.Unit_of_Measure__c = theCompanySetup.Default_Fuel_Surcharge_Resource__r.Unit_of_Measure__c;
                surchargeLine.Unit_of_Measure__r = theCompanySetup.Default_Fuel_Surcharge_Resource__r.Unit_of_Measure__r;
            }
            surchargeLine.Quantity__c = 1;
            surchargeLine.Unit_Price__c = salesOrder.Surcharge_Amount__c;
            surchargeLine.Tax_Group__c = 'NT';
            surchargeLine.Tax_Pct__c = 0;
            surchargeLine.Tax__c = 0;
            surchargeLine.Line_Amount__c = salesOrder.Surcharge_Amount__c;
            surchargeLine.Line_Amt_Incl_Tax__c = salesOrder.Surcharge_Amount__c;
            surchargeLine.System_Calculated_Line__c = true;

            //SalesLinesService.initStaticVariables(new Map<Sales_Order__c, List<Sales_Line__c>> {salesOrder => new List<Sales_Line__c>{ surchargeLine }});
            //SalesLinesService.calcUnitCost(salesOrder, surchargeLine);
            //surchargeLine.Line_Cost__c = CompanyMgmt.halfUpTo2D(surchargeLine.Unit_Cost__c * surchargeLine.Quantity__c);

            salesLines.add(surchargeLine);
        }
    }

    private void removeSurchargeLine(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines) {
        for (Integer i = 0 ; i < salesLines.size(); i++) {
            Sales_Line__c salesLine = salesLines[i];
            if (salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true &&
                    (salesLine.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c || salesLine.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c)) {
                salesLines.remove(i);
                i--;
            }
        }
    }
    */
    public void calcSurchargeAmount(Sales_Order__c salesOrder, List<Sales_Order_Job_Task__c> jobTasks, List<Sales_Line__c> salesLines) {
        Integer nextSalesLineNo = 0;
        for (Sales_Line__c salesLine : salesLines) {
            if (salesLine.Line_No__c.intValue() > nextSalesLineNo) {
                nextSalesLineNo = salesLine.Line_No__c.intValue();
            }
        }
        nextSalesLineNo++;

        ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTasks, salesLines);
        Decimal surchargeAmt = 0;
        Boolean hasLines = false;
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : salesOrderWrapper.JobTaskWrappers) {
            SalesLinesService.calculateSurchargeLine(salesOrder, jobTaskWrapper, nextSalesLineNo);
            nextSalesLineNo++;
            if(salesOrder.Surcharge_Type__c != null) {
                surchargeAmt += (jobTaskWrapper.JobTask.Surcharge_Amount__c != null ? jobTaskWrapper.JobTask.Surcharge_Amount__c : 0);
            }

            if (jobTaskWrapper.SalesLines.size() > 0) {
                hasLines = true;
            }
        }
        salesOrder.Surcharge_Amount__c = surchargeAmt;
        if (hasLines == true) { //handle old sales order data, in case jobTaskWrapper.SalesLines return null and then all lines will be deleted by ContractUtil.cls
            jobTasks.clear();
            jobTasks.addAll(salesOrderWrapper.getJobTasks());
            salesLines.clear();
            salesLines.addAll(salesOrderWrapper.SalesLines);
        }
    }
    //ticket 19672 >>

    /*
     *  Ticket#17068 Remove active contracts checking when clone.
     */
    //job task <<
    /*
    public String cloneSalesOrder(Set<Id> salesOrderIds, String documentType, String serviceCenter, Id billToCustomer, Id billToParentId) {
        Savepoint sp = Database.setSavepoint();

        try {
            List<Sales_Order__c> salesOrderList = SalesOrdersSelector.newInstance().selectByIdWithLinesForClone(salesOrderIds);
            List<Sales_Line__c> salesLineList = SalesLinesSelector.newInstance().selectLinesWithDetailsBySalesOrderId(salesOrderIds);

            ISalesOrders salesOrderDomain = SalesOrders.newInstance(salesOrderList);
            salesOrderDomain.initStaticVariables();
            salesOrderDomain.checkBeforeClone(billToCustomer, documentType);

            if (salesOrderList.size() == 0) {
                return null;
            }

            Sales_Order__c theSO = salesOrderList[0];
            Sales_Order__c theNewSO = theSO.clone(false, true);

            theNewSO.Name = null;
            theNewSO.Document_Status__c = 'Open';
            theNewSO.NAV_Job_No__c = null;
            theNewSO.Sync_d__c = false;
            if (documentType == 'Quote') {
                theNewSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();
                theNewSO.Document_Type__c = 'Sales Quote';
                if (String.isNotEmpty(theSO.From_Sales_Quote__c)) {
                    theNewSO.From_Sales_Quote__c = null;
                }
            } else if (documentType == 'Order') {
                theNewSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId();
                theNewSO.Document_Type__c = 'Sales Order';
                if (billToCustomer != theSO.Bill_to_Customer_No__c) {
                    theNewSO.From_Sales_Quote__c = null;
                }
            }
            theNewSO.Service_Center__c = serviceCenter;
            theNewSO.Start_Date__c = null;
            theNewSO.End_Date__c = null;
            theNewSO.Quote_Date__c = Date.today();
            theNewSO.Surcharge_Pct__c = null;
            theNewSO.Surcharge_Amount__c = null;

            //reset approval process related fields
            theNewSO.Approval_Status__c = 'Draft';
            theNewSO.Approved_Profit_Margin__c = null;
            theNewSO.Approved_Level__c = null;
            theNewSO.Approved_Amount__c = null;
            theNewSO.Pending_Approval_From__c = null;
            theNewSO.Pending_Approval_Level__c = null;
            theNewSO.Approval_Step_Completed__c = false;
            theNewSO.Approved__c = false;

            //03.01.2020 <<
            theNewSO.Billing_Rule_Not_Required__c = false;
            //03.01.2020 >>

            if (billToCustomer != theSO.Bill_to_Customer_No__c) {
                theNewSO.Bill_to_Customer_No__c = billToCustomer;
                theNewSO.Bill_to_Contact__c = null;
                theNewSO.Customer_PO_No__c = null;
                theNewSO.Contract__c = null;
                theNewSO.Alternate_Site_Address__c = null;
                theNewSO.Site_Name__c = null;
                theNewSO.Site_Contact__c = null;
                theNewSO.Site_Contact_2__c = null;
                theNewSO.Site_Phone_No__c = null;
                theNewSO.Site_Email_Address__c = null;
                theNewSO.Alternate_Site_Address__c = null;
                theNewSO.Site_City__c = null;
                theNewSO.Site_State__c = null;
                theNewSO.Site_Postal_Code__c = null;
                theNewSO.Print_Site_Name__c = false;
                theNewSO.Create_Site_Address__c = false;
                updateSalesOrderBillingAndTax(theNewSO, true);
            }
            setSurchargePct(theNewSO);
            insert theNewSO;

            //sales lines
            Map<Integer, Sales_Line__c> mapSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
            for (Sales_Line__c theSL : theSO.Sales_Lines__r) {
                mapSalesLinesByLineNo.put(theSL.Line_No__c.intValue(), theSL);
            }

            List<Sales_Line__c> theNewSLList = new List<Sales_Line__c>();
            Map<Integer, Sales_Line__c> mapNewSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
            if (theSO.Sales_Lines__r != null) {
                for (Sales_Line__c theSL : theSO.Sales_Lines__r) {
                    Sales_Line__c newSL = theSL.clone(false, true);

                    newSL.Sales_Order__c = theNewSO.Id;

                    if (documentType == 'Quote') {
                        newSL.Quote_Line__c = null;
                    }
                    if (billToCustomer != theSO.Bill_to_Customer_No__c) {
                        newSL.Quote_Line__c = null;
                        newSL.Contract_Line__c = null;
                        newSL.Pricing_Source_2__c = null;
                    }

                    newSL.Bundle_Line__c = null;
                    newSL.Bundle_Line__r = null;

                    theNewSLList.add(newSL);
                    mapNewSalesLinesByLineNo.put(newSL.Line_No__c.intValue(), newSL);
                }
            }

            if (theNewSLList.size() > 0){
                insert theNewSLList;
            }

            if (theSO.Sales_Lines__r != null) {
                for (Integer i = 0; i < theSO.Sales_Lines__r.size(); i++) {
                    Sales_Line__c theSL = theSO.Sales_Lines__r[i];
                    if (theSL.Bundle_Line__r != null) {
                        Integer salesLineLineNo = theSL.Line_No__c.intValue();
                        Integer bundleLineLineNo = theSL.Bundle_Line__r.Line_No__c.intValue();
                        if (mapNewSalesLinesByLineNo.containsKey(salesLineLineNo)) {
                            Sales_Line__c newSL = mapNewSalesLinesByLineNo.get(salesLineLineNo);
                            Sales_Line__c newBundleLine = mapNewSalesLinesByLineNo.get(bundleLineLineNo);
                            newSL.Bundle_Line__c = newBundleLine.Id;
                        }
                    }
                }
            }
            upsert theNewSLList;

            List<Sales_Order__c> sos = SalesOrdersSelector.newInstance().selectByIdWithLinesForClone(new Set<Id>{ theNewSO.Id });
            theNewSO = sos[0];

            calcSurchargeAmount(theNewSO, theNewSLList);
            addRemoveSurchargeLine(theNewSO, theNewSLList);

            update theNewSO;


            //sales line details
            Map<Integer, Sales_Line__c> mapSalesLinesWithDetailByLineNo = new Map<Integer, Sales_Line__c>();
            for (Sales_Line__c salesLine : salesLineList) {
                mapSalesLinesWithDetailByLineNo.put(salesLine.Line_No__c.intValue(), salesLine);
            }

            List<Sales_Line_Detail__c> newSLDetailList = new List<Sales_Line_Detail__c>();
            for (Sales_Line__c newSL : theNewSLList) {
                if (mapSalesLinesWithDetailByLineNo.containsKey(newSL.Line_No__c.intValue())) {
                    Sales_Line__c salesLine = mapSalesLinesWithDetailByLineNo.get(newSL.Line_No__c.intValue());
                    if (salesLine.Sales_Line_Details__r != null) {
                        for (Sales_Line_Detail__c theSLDetail : salesLine.Sales_Line_Details__r) {
                            Sales_Line_Detail__c newSLDetail = theSLDetail.clone(false, true);
                            newSLDetail.Sales_Line__c = newSL.Id;
                            newSLDetailList.add(newSLDetail);
                        }
                    }
                }
            }
            if (newSLDetailList.size() > 0) {
                insert newSLDetailList;
            }

            return theNewSO.Id;
        }
        catch(Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    */

    public String cloneSalesOrder(Set<Id> salesOrderIds, String documentType, String serviceCenter, Id billToCustomer, Id billToParentId, String jobDescription, String poNumber) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Sales_Order__c> salesOrderList = SalesOrdersSelector.newInstance().selectByIdWithLinesForClone(salesOrderIds);
            List<Sales_Order_Job_Task__c> jobTaskList = SalesOrderJobTasksSelector.newInstance().selectBySalesOrderId(salesOrderIds);
            List<Sales_Line__c> salesLineList = SalesLinesSelector.newInstance().selectLinesWithDetailsBySalesOrderId(salesOrderIds);

            ISalesOrders salesOrderDomain = SalesOrders.newInstance(salesOrderList);
            salesOrderDomain.initStaticVariables();
            salesOrderDomain.checkBeforeClone(billToCustomer, documentType);

            if (salesOrderList.size() == 0) {
                return null;
            }

            Sales_Order__c theSO = salesOrderList[0];
            Sales_Order__c theNewSO = theSO.clone(false, true);

            theNewSO.Is_New_D365_Project__c = false;
            theNewSO.D365_Project_ID__c = null;
            theNewSO.Name = null;
            theNewSO.Document_Status__c = 'Open';
            theNewSO.NAV_Job_No__c = null;
            theNewSO.Sync_d__c = false;
            theNewSO.ClonedFromRecordId__c = theSO.Id;
            theNewSO.Convert_Count__c = 0; //Ticket#20149
            theNewSO.Blocked__c = false; //Ticket#21908
            theNewSO.SO_sent_to_EQAI__c = false; //Ticket 77002
            theNewSO.SO_Submitted_to_EQAI__c = false;
            theNewSO.Sent_to_EQAI_Date__c = null; //Ticket#87270
            theNewSO.Disposal_Billing_Method__c = null; // US136059 
            if (documentType == 'Quote') {
                theNewSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();
                theNewSO.Document_Type__c = 'Sales Quote';
                theNewSO.Customer_PO_No__c = null; // Ticket 78897
                if (String.isNotEmpty(theSO.From_Sales_Quote__c)) {
                    theNewSO.From_Sales_Quote__c = null;
                }
            } else if (documentType == 'Order') {
                theNewSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId();
                theNewSO.Document_Type__c = 'Sales Order';
                if (billToCustomer != theSO.Bill_to_Customer_No__c || serviceCenter != theSO.Service_Center__c) {
                    theNewSO.From_Sales_Quote__c = null;
                }
                List<Account> billToCustomers = AccountsSelector.newInstance().selectById(new Set<Id>{ billToCustomer });
                 AccountsService.validatePONumberFormat(billToCustomers[0], poNumber);
                theNewSO.Customer_PO_No__c = poNumber;
            }
            if(theSO.Pay_Rule__c != null){
                if(theSO.Pay_Rule__r.Blocked__c)
                    theNewSO.Pay_Rule__c = null;
            }
            theNewSO.CMR_Description__c = jobDescription;
            theNewSO.Service_Center__c = serviceCenter;
            theNewSO.Start_Date__c = null;
            theNewSO.End_Date__c = null;
            theNewSO.Quote_Date__c = System.today();
            //Ticket#21908 >>
            //theNewSO.Quote_Date__c = null;
            theNewSO.Estimated_Job_Start_Date__c = null;
            theNewSO.Estimated_Job_End_Date__c = null;
            //theNewSO.Duration__c = null; Ticket#24326
            theNewSO.Quote_Status__c = EnumUtil.QuoteStatus.PENDING.name();
            //Ticket#21908 <<
            theNewSO.Surcharge_Pct__c = null;
            theNewSO.Surcharge_Amount__c = null;

            //reset approval process related fields
            theNewSO.Approval_Status__c = 'Draft';
            theNewSO.Approved_Profit_Margin__c = null;
            theNewSO.Approved_Level__c = null;
            theNewSO.Approved_Amount__c = null;
            theNewSO.Pending_Approval_From__c = null;
            theNewSO.Pending_Approval_Level__c = null;
            theNewSO.Approval_Step_Completed__c = false;
            theNewSO.Approved__c = false;

            theNewSO.Billing_Rule_Not_Required__c = false;
            theNewSO.Rate_Sheet__c = null; //Ticket#25378

            /* Ticket#24326
            theNewSO.Tax_Area__c = null;
            theNewSO.Tax_Area__r = null;
             */
			
            theNewSO.D365_Project_ID__c = null;//81966
            
            theNewSO.Name_of_Worker_Responsible__c = null; //78236
            theNewSO.Worker_Responsible__c = null; //78236

            if (billToCustomer != theSO.Bill_to_Customer_No__c) {

                theNewSO.Bill_to_Customer_No__c = billToCustomer;
                theNewSO.Bill_to_Contact__c = null;
                theNewSO.Customer_PO_No__c = null;
                theNewSO.Contract__c = null;
                theNewSO.Alternate_Site_Address__c = null;
                theNewSO.Site_Name__c = null;
                theNewSO.Site_Street__c = null;
                theNewSO.Site_City__c = null;
                theNewSO.Site_State__c = null;
                theNewSO.Site_Postal_Code__c = null;
                theNewSO.Site_Country__c = null;
                theNewSO.Site_Phone_No__c = null;
                theNewSO.Site_Email_Address__c = null;
                theNewSO.Site_Contact_2__c = null;
                theNewSO.Print_Site_Name__c = false;
                theNewSO.Create_Site_Address__c = false;
                theNewSO.Quote_Contact__c = null;
                theNewSO.Opportunity__c = null;
                theNewSO.Pay_Rule__c = null;
                theNewSO.Prevailing_Wage_Job__c = false;
                //Ticket#24326 >>
                theNewSO.Tax_Area__c = null;
                theNewSO.Tax_Area__r = null;
                //Ticket#24326 <<
                updateSalesOrderBillingAndTax(theNewSO, true);
            } else {
                if (theNewSO.Document_Type__c == 'Sales Quote' && theNewSO.Quote_Contact__c == null) {
                    List<Contact> quoteContacts = ContactsSelector.newInstance().selectQuoteContactsByAccount(new Set<Id>{ billToCustomer });
                    if (quoteContacts.size() == 1){
                        theNewSO.Quote_Contact__c = quoteContacts[0].Id;
                        theNewSO.Quote_Contact__r = quoteContacts[0];
                    }
                }
            }
            theNewSO.Account_Executives__c = null;
            //DE37804 - Check Contract Surcharge type and set Surcharge Type as 'N/A'
            if(theNewSO.Contract__c != null){
                List<Contract> contracts = ContractsSelector.newInstance().selectById(new Set<Id>{ theNewSO.Contract__c });
                if (contracts.size() > 0) {
                    Contract contract = contracts[0];
                    theNewSO.Surcharge_Type__c = contract.Surcharge_Type__c;
                    if(contract.Surcharge_Type__c != null && contract.Surcharge_Type__c == 'N/A'){
                        theNewSO.Surcharge_Type__c = 'N/A';
                        theNewSO.Surcharge_Pct__c = null;
                    } else {
                        theNewSO.Surcharge_Pct__c = (contract.Surcharge_Pct__c != null) ? contract.Surcharge_Pct__c : null;
                    }
                }
            } else {
                theNewSO.Surcharge_Type__c = 'EEC Fee'; //Ticket#21836
            }
            //Ticket#24559 >>
            if(theSO.Portal_Basis_Adv__c == true){
                theNewSO.Portal_Basis_Adv__c = false;
                theNewSO.Default_Billing_Rule_2023__c = true;
                theNewSO.Default_Billing_Rule_To_Display__c = null;
                theNewSO.Billing_Rule__c = theCompanySetup.Default_Billing_Rule__c;
            }
            //Ticket#24559 <<
            setSurchargePct(theNewSO);
            insert theNewSO;

            Map<Integer, Sales_Order_Job_Task__c> mapJobTasksByLineNo = new Map<Integer, Sales_Order_Job_Task__c>();
            for (Sales_Order_Job_Task__c jobTask : jobTaskList) {
                Sales_Order_Job_Task__c newJobTask = new Sales_Order_Job_Task__c();
                newJobTask.Name = jobTask.Name;
                newJobTask.Sales_Order__c = theNewSO.Id;
                newJobTask.Job_Task_Template__c = jobTask.Job_Task_Template__c;
                newJobTask.Line_No__c = jobTask.Line_No__c;
                newJobTask.Task_No__c = jobTask.Task_No__c;
                newJobTask.Billing_Type__c = jobTask.Billing_Type__c;
                newJobTask.Custom_Assumption1__c = jobTask.Custom_Assumption1__c;
                newJobTask.Custom_Assumption2__c = jobTask.Custom_Assumption2__c;
                newJobTask.Custom_Assumption3__c = jobTask.Custom_Assumption3__c;
                newJobTask.Custom_Assumption4__c = jobTask.Custom_Assumption4__c;
                newJobTask.Custom_Assumption5__c = jobTask.Custom_Assumption5__c;
                newJobTask.Custom_Assumption6__c = jobTask.Custom_Assumption6__c;
                newJobTask.Custom_Assumption7__c = jobTask.Custom_Assumption7__c;
                newJobTask.Custom_Assumption8__c = jobTask.Custom_Assumption8__c;
                newJobTask.Custom_Assumption9__c = jobTask.Custom_Assumption9__c;
                newJobTask.Custom_Assumption10__c = jobTask.Custom_Assumption10__c;
                newJobTask.Fixed_Price__c = jobTask.Fixed_Price__c;
                newJobTask.Rolled_Up_Sales_Lines_Amount__c = jobTask.Rolled_Up_Sales_Lines_Amount__c;
                newJobTask.Surcharge_Amount__c = jobTask.Surcharge_Amount__c;
                newJobTask.Tax_Group__c = jobTask.Tax_Group__c;
                newJobTask.Tax_Pct__c = jobTask.Tax_Pct__c;
                newJobTask.Tax__c = jobTask.Tax__c;
                newJobTask.Total_Amount__c = jobTask.Total_Amount__c;
                newJobTask.Total_Amount_Incl_Tax__c = jobTask.Total_Amount_Incl_Tax__c;
                //ticket 19672 <<
                newJobTask.Fixed_Price_Surcharge_Option__c = jobtask.Fixed_Price_Surcharge_Option__c;
                //ticket 19672 >>
                mapJobTasksByLineNo.put(newJobTask.Line_No__c.intValue(), newJobTask);
            }
            insert mapJobTasksByLineNo.values();

            //sales lines
            //Map<Integer, Sales_Line__c> mapSalesLinesByLineNo = new Map<Integer, Sales_Line__c>(); not used
            Map<Integer, Sales_Line__c> mapNewSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
            //if (theSO.Sales_Lines__r != null) {
                //for (Sales_Line__c theSL : theSO.Sales_Lines__r) {
                    //mapSalesLinesByLineNo.put(theSL.Line_No__c.intValue(), theSL);
                for (Sales_Line__c theSL : salesLineList) {
                    //Ticket#21836 >>
                    if(theSL.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c){
                        continue;
                    }
                    //Ticket#21836 <<
                    Sales_Line__c newSL = theSL.clone(false, true);

                    newSL.Sales_Order__c = theNewSO.Id;

                    // US136059 >> start
                    newSL.Profile_Id__c = null;
                    newSL.Approval_Id__c = null;
                    newSL.EQAI_UOM__c = null;
                    newSL.Disposal_Billing_Method__c = null;
                    if(newSL.Category__c == 'Waste Disposal')
                    {
                        if(newSL.Contract_Line__c !=null && String.isNotBlank(newSL.Contract_Line__r.Customer_Description__c)){                        
                            newSL.Description__c = newSL.Contract_Line__r.Customer_Description__c;
                        }
                        else if(newSL.Resource__c !=null && String.isNotBlank(newSL.Resource__r.Description__c)){
                            newSL.Description__c = newSL.Resource__r.Description__c;                     
                        }
                      if(newSL.System_Calculated_Line__c == false)  
                      newSL.Unit_of_Measure__c = null;
                    }
                    //US136059 >> end
                    //DE38307 - Disable non billable checkbox
                    if(newSL.Category__c == 'Misc. Charges And Taxes' && (newSL.Description__c == 'EEC Fee' || newSL.Description__c == 'ESIC' || newSL.Description__c == 'Fuel Surcharge') ){
                        newSL.Non_Billable__c = false;
                    }
                    if (documentType == 'Quote') {
                        newSL.Quote_Line__c = null;
                    }
                    if (billToCustomer != theSO.Bill_to_Customer_No__c) {
                        newSL.Quote_Line__c = null;
                        newSL.Contract_Line__c = null;
                        newSL.Pricing_Source_2__c = null;
                    }

                    //quote line linkage fix <<
                    if (theNewSO.Document_Type__c == 'Sales Quote') {
                        newSL.Quote_Line__c = null;
                    }
                    //quote line linkage fix >>

                    newSL.Bundle_Line__c = null;
                    newSL.Bundle_Line__r = null;
                    //ticket 19130 <<
                    /*
                    newSL.Parent_Line__c = null;
                    newSL.Parent_Line__r = null;
                    */
                    newSL.Wizard_Question_Answered__c = false;
                    //ticket 19130 >>
                    //Ticket#23484
                    //Make sure Markup and Markup Option fields were blank out for other categories except subcontractors
                    if(newSL.Category__c != ResourceService.SUBCONTRACTORS_CATEGORY){
                        newSL.Markup__c = null;
                        newSL.Markup_Option__c = null;
                    }

                    Sales_Order_Job_Task__c jobTask = mapJobTasksByLineNo.get(newSL.Sales_Order_Job_Task__r.Line_No__c.intValue());
                    newSL.Sales_Order_Job_Task__c = jobTask.Id;

                    mapNewSalesLinesByLineNo.put(newSL.Line_No__c.intValue(), newSL);
                }
            //}
            CompanyMgmt.byPassTrigger = true;  //bypass qty check in SalesOrderTriggersMgt.  Check is performed at the next step, update
            insert mapNewSalesLinesByLineNo.values();
            CompanyMgmt.byPassTrigger = false;

            //if (theSO.Sales_Lines__r != null) {
                //for (Integer i = 0; i < theSO.Sales_Lines__r.size(); i++) {
                    //Sales_Line__c theSL = theSO.Sales_Lines__r[i];
                for (Integer i = 0; i < salesLineList.size(); i++) {
                    Sales_Line__c theSL = salesLineList[i];
                    Integer salesLineLineNo = theSL.Line_No__c.intValue();
                    if (theSL.Bundle_Line__r != null) {
                        Integer bundleLineNo = theSL.Bundle_Line__r.Line_No__c.intValue();
                        if (mapNewSalesLinesByLineNo.containsKey(salesLineLineNo)) {
                            Sales_Line__c newSL = mapNewSalesLinesByLineNo.get(salesLineLineNo);
                            Sales_Line__c newBundleLine = mapNewSalesLinesByLineNo.get(bundleLineNo);
                            newSL.Bundle_Line__c = newBundleLine.Id;
                        }
                    }

                    //ticket 19130 <<
                    /*
                    if (theSL.Parent_Line__r != null) {
                        Integer parentLineNo = theSL.Parent_Line__r.Line_No__c.intValue();
                        if (mapNewSalesLinesByLineNo.containsKey(salesLineLineNo)) {
                            Sales_Line__c newSL = mapNewSalesLinesByLineNo.get(salesLineLineNo);
                            Sales_Line__c newParentLine = mapNewSalesLinesByLineNo.get(parentLineNo);
                            newSL.Parent_Line__c = newParentLine.Id;
                        }
                    }
                    */
                    //ticket 19130 >>
                }
            //}
            update mapNewSalesLinesByLineNo.values();

            //sales line details
            Map<Integer, Sales_Line__c> mapSalesLinesWithDetailByLineNo = new Map<Integer, Sales_Line__c>();
            for (Sales_Line__c salesLine : salesLineList) {
                //ticket 19861 <<
                /* Ticket#21908 >>
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Bundled') {
                    if (salesLine.Resource_Type__r != null && salesLine.Resource_Type__r.Blocked__c == true) {
                        throw new DataException('You cannot clone this quote/order because resource type "' + salesLine.Resource_Type__r.Name + '" has been blocked.');
                    }
                }
                else if (salesLine.Category__c == 'Materials' || salesLine.Category__c == 'Waste Disposal' || salesLine.Category__c == 'Demurrage' || salesLine.Category__c == 'Misc. Taxes And Charges') {
                    if (salesLine.Resource__r != null && salesLine.Resource__r.Blocked__c == true) {
                        throw new DataException('You cannot clone this quote/order because resource "' + salesLine.Resource__r.Name + '" has been blocked.');
                    }
                }
                Ticket#21908 << */
                //ticket 19861 >>
                mapSalesLinesWithDetailByLineNo.put(salesLine.Line_No__c.intValue(), salesLine);
            }

            //ticket 19130 <<
            List<Sales_Parent_Child_Relation__c> relationsToInsert = new List<Sales_Parent_Child_Relation__c>();
            //ticket 19130 >>

            List<Sales_Line_Detail__c> newSLDetailList = new List<Sales_Line_Detail__c>();
            for (Sales_Line__c newSL : mapNewSalesLinesByLineNo.values()) {
                if (mapSalesLinesWithDetailByLineNo.containsKey(newSL.Line_No__c.intValue())) {
                    Sales_Line__c salesLine = mapSalesLinesWithDetailByLineNo.get(newSL.Line_No__c.intValue());

                    //ticket 19130 <<
                    if (salesLine.Sales_Child_Lines__r != null) {
                        for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                            Sales_Parent_Child_Relation__c relationToInsert = new Sales_Parent_Child_Relation__c();
                            relationToInsert.Parent_Line__c = newSL.Id;
                            relationToInsert.Child_Line__c = mapNewSalesLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue()).Id;
                            relationsToInsert.add(relationToInsert);
                        }
                    }
                    //ticket 19130 >>

                    if (salesLine.Sales_Line_Details__r != null) {
                        for (Sales_Line_Detail__c theSLDetail : salesLine.Sales_Line_Details__r) {
                            Sales_Line_Detail__c newSLDetail = theSLDetail.clone(false, true);
                            newSLDetail.Sales_Line__c = newSL.Id;
                            newSLDetailList.add(newSLDetail);
                        }
                    }
                }
            }
            //ticket 19130 <<
            insert relationsToInsert;
            //ticket 19130 >>

            if (newSLDetailList.size() > 0) {
                insert newSLDetailList;
            }

            List<Sales_Order__c> sos = SalesOrdersSelector.newInstance().selectByIdWithLinesForClone(new Set<Id>{ theNewSO.Id });
            theNewSO = sos[0];

            //ticket 19672 <<
            /*
            calcSurchargeAmount(theNewSO, mapNewSalesLinesByLineNo.values());
            addRemoveSurchargeLine(theNewSO, mapNewSalesLinesByLineNo.values());
            */
            if(mapNewSalesLinesByLineNo.values().size() > 0) {
                SalesLinesService.initStaticVariables(theNewSO, mapNewSalesLinesByLineNo.values()[0]); //Ticket#21836
            } else {
                SalesLinesService.initStaticVariables(theNewSO, new Sales_Line__c()); //Ticket#21836
            }
            calcSurchargeAmount(theNewSO, mapJobTasksByLineNo.values(), mapNewSalesLinesByLineNo.values());
            //ticket 19672 >>


            Decimal taxPct = 0;
            if (theNewSO.Tax_Area__c != null && theNewSO.Tax_Liable__c == true) {
                taxPct = CompanyMgmt.getSalesTax(theNewSO.Tax_Area__c, 'TX');
            }

            //ticket 19672 <<
            /*
            for (Sales_Order_Job_Task__c jobTask : mapJobTasksByLineNo.values()) {
                if (jobtask.Billing_Type__c == 'Fixed Price') {
                    jobtask.Total_Amount__c = CompanyMgmt.zeroIfNull(jobtask.Fixed_Price__c);
                    jobtask.Total_Amount_Incl_Tax__c = jobtask.Total_Amount__c;
                    jobtask.Tax_Pct__c = taxPct;
                    jobtask.Tax__c = 0;
                    if (jobtask.Tax_Group__c == 'TX') {
                        jobtask.Tax__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(jobtask.Fixed_Price__c) * jobtask.Tax_Pct__c / 100);
                        jobtask.Total_Amount_Incl_Tax__c = jobtask.Total_Amount__c + jobtask.Tax__c;
                    }
                }
                else {
                    jobtask.Total_Amount__c = 0;
                    jobtask.Total_Amount_Incl_Tax__c = 0;
                    jobtask.Tax__c = 0;
                    for(Sales_Line__c salesLine : mapNewSalesLinesByLineNo.values()) {
                        if (salesLine.Sales_Order_Job_Task__c == jobTask.Id) {
                            jobtask.Total_Amount__c = CompanyMgmt.zeroIfNull(jobtask.Total_Amount__c) + CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                            jobtask.Total_Amount_Incl_Tax__c = CompanyMgmt.zeroIfNull(jobtask.Total_Amount_Incl_Tax__c) + CompanyMgmt.zeroIfNull(salesLine.Line_Amt_Incl_Tax__c);
                            jobtask.Tax__c = CompanyMgmt.zeroIfNull(jobtask.Tax__c) + CompanyMgmt.zeroIfNull(salesLine.Tax__c);
                        }
                    }
                }
            }
            */

            //SalesLinesService.recalculateSalesLines(theNewSO, )
            Map<Id, Sales_Line__c> newSalesLinesByIds = new Map<Id, Sales_Line__c>();
            newSalesLinesByIds.putAll(SalesLinesSelector.newInstance().selectLinesWithDetailsBySalesOrderId(new Set<Id>{theNewSO.Id})); //Ticket#20212
            Map<Id, List<Sales_Line__c>> mapSalesLinesByJobTaskId = new Map<Id, List<Sales_Line__c>>();
            for (Sales_Line__c salesLine : mapNewSalesLinesByLineNo.values()) {
                Decimal newSurchargeAmt = salesLine.Line_Amount__c; //Ticket#24948
                salesLine = newSalesLinesByIds.get(salesLine.Id); //Ticket#20212
                //Ticket#24948 >>
                if(salesLine.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c || salesLine.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c){
                    salesLine.Unit_Price__c = newSurchargeAmt;
                    salesLine.Line_Amount__c = newSurchargeAmt;
                    salesLine.Line_Amt_Incl_Tax__c = newSurchargeAmt;
                }
                //Ticket#24948 <<
                salesLine.Tax_Pct__c = taxPct;
                SalesLinesService.calculateLineTotals(theNewSO, salesLine); //calculate sales tax
                List<Sales_Line__c> salesLines2;
                if (mapSalesLinesByJobTaskId.containsKey(salesLine.Sales_Order_Job_Task__c)) {
                    salesLines2 = mapSalesLinesByJobTaskId.get(salesLine.Sales_Order_Job_Task__c);
                }
                else {
                    salesLines2 = new List<Sales_Line__c>();
                    mapSalesLinesByJobTaskId.put(salesLine.Sales_Order_Job_Task__c, salesLines2);
                }
                salesLines2.add(salesLine);
                mapNewSalesLinesByLineNo.put(salesLine.Line_No__c.intValue(), salesLine);  //Ticket#20212
            }

            /*
             *  Ticket#20497 - recalculate unit cost when clone
             */
            List<ACVSalesOrderJobTaskWrapper> salesOrderJobTaskWrappers = new List<ACVSalesOrderJobTaskWrapper>();
            for(Sales_Order_Job_Task__c salesOrderJobTask : mapJobTasksByLineNo.values()){
                if(mapSalesLinesByJobTaskId.containsKey(salesOrderJobTask.Id)){
                    ACVSalesOrderJobTaskWrapper salesOrderJobTaskWrapper = new ACVSalesOrderJobTaskWrapper(salesOrderJobTask, mapSalesLinesByJobTaskId.get(salesOrderJobTask.Id));
                    salesOrderJobTaskWrappers.add(salesOrderJobTaskWrapper);
                }
            }

            if(salesOrderJobTaskWrappers.size() > 0){
                SalesLinesService.initStaticVariables(theNewSO, salesOrderJobTaskWrappers);
                SalesLinesService.calcUnitCost(theNewSO, salesOrderJobTaskWrappers);
                SalesLinesService.calculateLineTotals(theNewSO, salesOrderJobTaskWrappers);
            }

            for (Sales_Order_Job_Task__c jobTask : mapJobTasksByLineNo.values()) {
                if (jobTask.Billing_Type__c == 'Fixed Price') {
                    jobTask.Tax_Pct__c = taxPct;
                }
                List<Sales_Line__c> salesLines2 = mapSalesLinesByJobTaskId.get(jobTask.Id);
                this.calcJobTaskAmountFields(theNewSO, jobTask, salesLines2, taxPct);
            }
            //ticket 19672 >>

            //Ticket#24326 Calculate total profit margin>>
            Decimal orderTotalAmt = 0;
            Decimal orderTotalCost = 0;
            for(Sales_Order_Job_Task__c jobTask : mapJobTasksByLineNo.values()) {
                orderTotalAmt = orderTotalAmt + CompanyMgmt.zeroIfNull(jobTask.Total_Amount__c);
            }
            for(Sales_Line__c salesLine : mapNewSalesLinesByLineNo.values()){
                orderTotalCost = orderTotalCost + CompanyMgmt.zeroIfNull(salesLine.Line_Cost__c);
            }
            if(orderTotalAmt > 0) {
                theNewSO.Total_Margin_Pct__c = ((orderTotalAmt - orderTotalCost) / orderTotalAmt) * 100;
            }
            //Ticket#24326 <<
            //Ticket#25132 >>
            SalesOrdersService.setOperatingExpense(theNewSO);
            //Ticket#25132 <<            
            update theNewSO;
            update mapJobTasksByLineNo.values();
            update mapNewSalesLinesByLineNo.values();

            return theNewSO.Id;
        }
        catch(Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    //job task >>

    //ticket 19672 <<
    public void calcJobTaskAmountFields(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, List<Sales_Line__c> salesLines, Decimal taxPct) {
        if (jobtask.Billing_Type__c == 'Fixed Price') {
            jobtask.Total_Amount__c = CompanyMgmt.zeroIfNull(jobtask.Fixed_Price__c);
            //ticket 19672 <<
            if (jobtask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge') {
                jobtask.Total_Amount__c += CompanyMgmt.zeroIfNull(jobtask.Surcharge_Amount__c);
            }
            //ticket 19672 >>
            jobtask.Total_Amount_Incl_Tax__c = jobtask.Total_Amount__c;
            jobtask.Tax_Pct__c = taxPct;
            jobtask.Tax__c = 0;
            if (jobtask.Tax_Group__c == 'TX') {
                //ticket 19672 <<
                //jobtask.Tax__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(jobtask.Fixed_Price__c) * jobtask.Tax_Pct__c / 100);
                jobtask.Tax__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(jobtask.Total_Amount__c) * jobtask.Tax_Pct__c / 100);
                //ticket 19672 >>
                jobtask.Total_Amount_Incl_Tax__c = jobtask.Total_Amount__c + jobtask.Tax__c;
            }
        }
        else {
            jobtask.Total_Amount__c = 0;
            jobtask.Total_Amount_Incl_Tax__c = 0;
            jobtask.Tax__c = 0;
            if(salesLines != null) {
                for (Sales_Line__c salesLine : salesLines) {
                    if (salesLine.Sales_Order_Job_Task__c != jobTask.Id) {
                        throw new DataException('Sales line #' + salesLine.Line_No__c + ' is expected to have sales order job task id ' + jobTask.Id);
                    }
                    jobtask.Total_Amount__c = CompanyMgmt.zeroIfNull(jobtask.Total_Amount__c) + CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                    jobtask.Total_Amount_Incl_Tax__c = CompanyMgmt.zeroIfNull(jobtask.Total_Amount_Incl_Tax__c) + CompanyMgmt.zeroIfNull(salesLine.Line_Amt_Incl_Tax__c);
                    jobtask.Tax__c = CompanyMgmt.zeroIfNull(jobtask.Tax__c) + CompanyMgmt.zeroIfNull(salesLine.Tax__c);
                }
            }
        }
    }
    //ticket 19672 >>

    //aura >>

    //aura <<
    /*
    public String convertQuoteToOrder(Set<Id> salesOrderIds) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        List<Sales_Order__c> salesOrderList = SalesOrdersSelector.newInstance().selectByIdWithLinesForClone(salesOrderIds);
        if (salesOrderList.size() == 0) return null;


        //W-000405 >>
        ISalesOrders salesOrderDomain = SalesOrders.newInstance(salesOrderList);
        salesOrderDomain.initStaticVariables();
        salesOrderDomain.checkBeforeConvert();
        //W-000405 <<

        Sales_Order__c theSO = salesOrderList[0];
        Sales_Order__c theNewSO = theSO.clone(false);
        List<Sales_Line__c> theNewSLList = theSO.Sales_Lines__r;

        theNewSO.From_Sales_Quote__c = theSO.Id;
        theNewSO.Document_Type__c = 'Sales Order';
        theNewSO.Name = null;
        theNewSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId();
        theNewSO.Estimated_Revenue__c = CompanyMgmt.zeroIfNull(theSO.Total_Amount__c) - CompanyMgmt.zeroIfNull(theSO.Surcharge_Amount__c);

        uow.registerNew(theNewSO);
        if (theSO.Convert_Count__c == null){
            theSO.Convert_Count__c = 1;
        } else {
            theSO.Convert_Count__c++;
        }

        if(theSO.Quote_Status__c == EnumUtil.QuoteStatus.PENDING.name()) theSO.Quote_Status__c = EnumUtil.QuoteStatus.WON.name();

        uow.registerDirty(theSO);
        if (theNewSLList.size() > 0){
            for (Sales_Line__c theSL : theNewSLList) {
                Sales_Line__c newSL = new Sales_Line__c();
                newSL = theSL.clone(false);
                newSL.Quote_Line__c = theSL.Id;
                if (newSL.System_Calculated_Line__c) {
                    newSL.Pricing_Source_2__c = null;
                }
                uow.registerNew(newSL, Sales_Line__c.Sales_Order__c, theNewSO);
            }
        }
        uow.commitWork();
        return theNewSO.Id;
    }
    */
    public String convertQuoteToOrder(Set<Id> salesOrderIds) {
        Savepoint sp = Database.setSavepoint();

        try {
            List<Sales_Order__c> salesOrderList = SalesOrdersSelector.newInstance().selectByIdWithLinesForClone(salesOrderIds);
            //job task <<
            List<Sales_Order_Job_Task__c> jobTasks = SalesOrderJobTasksSelector.newInstance().selectBySalesOrderId(salesOrderIds);
            //job task >>
            List<Sales_Line__c> salesLineList = SalesLinesSelector.newInstance().selectLinesWithDetailsBySalesOrderId(salesOrderIds);
            if (salesOrderList.size() == 0) return null;

            //W-000405 >>
            ISalesOrders salesOrderDomain = SalesOrders.newInstance(salesOrderList);
            salesOrderDomain.initStaticVariables();
            salesOrderDomain.checkBeforeConvert();
            //W-000405 <<

            Sales_Order__c theSO = salesOrderList[0];
			//03.10.20 << make order description required
            //billing type <<
            /*
            if (theSO.Order_Description__c == null) {
                throw new DataException('You must fill out the order description before converting this quote to order.');
            }
            */
            //billing type >>
            //03.10.20 >> make order description required

            Sales_Order__c theNewSO = theSO.clone(false, true);
			theNewSO.From_Sales_Quote__c = theSO.Id;
            theNewSO.Document_Type__c = 'Sales Order';
            theNewSO.SO_Submitted_to_EQAI__c = true;
            theNewSO.EQAI_Billing_Project_Id__c = theSO.EQAI_Billing_Project_Id__c;
            theNewSO.Name = null;
            theNewSO.Is_New_D365_Project__c = theSO.Is_New_D365_Project__c;
            theNewSO.D365_Project_ID__c = theSO.D365_Project_ID__c; 
            theNewSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId();
            theNewSO.Estimated_Revenue__c = CompanyMgmt.zeroIfNull(theSO.Total_Amount__c) - CompanyMgmt.zeroIfNull(theSO.Surcharge_Amount__c);
			if(theSO.Pay_Rule__c != null){
                if(theSO.Pay_Rule__r.Blocked__c)
                    theNewSO.Pay_Rule__c = null;
            }
            insert theNewSO;

            if (theSO.Convert_Count__c == null) {  
                theSO.Convert_Count__c = 1;
            } else {
                theSO.Convert_Count__c++;
            }

            if (theSO.Quote_Status__c == EnumUtil.QuoteStatus.PENDING.name()) {
                theSO.Quote_Status__c = EnumUtil.QuoteStatus.WON.name();
            }
            update theSO;

            //job task <<
            Map<Integer, Sales_Order_Job_Task__c> mapJobTasksByLineNo = new Map<Integer, Sales_Order_Job_Task__c>();
            for (Sales_Order_Job_Task__c jobTask : jobTasks) {
                Sales_Order_Job_Task__c newJobTask = jobTask.clone(false, true);
                newJobTask.Sales_Order__c = theNewSO.Id;
                mapJobTasksByLineNo.put(newJobTask.Line_No__c.intValue(), newJobTask);
            }
            insert mapJobTasksByLineNo.values();
            //job task >>

            //sales lines
            //Map<Integer, Sales_Line__c> mapSalesLinesByLineNo = new Map<Integer, Sales_Line__c>(); not used
            List<Sales_Line__c> theNewSLList = new List<Sales_Line__c>();
            Map<Integer, Sales_Line__c> mapNewSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
            //if (theSO.Sales_Lines__r != null) {
            //for (Sales_Line__c theSL : theSO.Sales_Lines__r) {
            for (Sales_Line__c theSL : salesLineList) {
                //mapSalesLinesByLineNo.put(theSL.Line_No__c.intValue(), theSL);
                Sales_Line__c newSL = theSL.clone(false, true);
                newSL.Sales_Order__c = theNewSO.Id;
                newSL.Quote_Line__c = theSL.Id;
                if (newSL.System_Calculated_Line__c) {
                    newSL.Pricing_Source_2__c = null;
                }

                newSL.Bundle_Line__c = null;
                newSL.Bundle_Line__r = null;

                //job task <<
                //ticket 19130 <<
                /*
                newSL.Parent_Line__c = null;
                newSL.Parent_Line__r = null;
                */
                //ticket 19130 >>
                if (mapJobTasksByLineNo.containsKey(newSL.Sales_Order_Job_Task__r.Line_No__c.intValue())) {
                    Sales_Order_Job_Task__c jobTask = mapJobTasksByLineNo.get(newSL.Sales_Order_Job_Task__r.Line_No__c.intValue());
                    newSL.Sales_Order_Job_Task__c = jobTask.Id;
                }
                //job task >>

                theNewSLList.add(newSL);
                mapNewSalesLinesByLineNo.put(newSL.Line_No__c.intValue(), newSL);
            }
            //}

            if (theNewSLList.size() > 0){
                CompanyMgmt.byPassTrigger = true; //bypass qty check in SalesOrderTriggersMgt.  Check is performed at the next step, update
                insert theNewSLList;
                CompanyMgmt.byPassTrigger = false;
            }

            //handle bundle lines
            //if (theSO.Sales_Lines__r != null) {
            //for (Integer i = 0; i < theSO.Sales_Lines__r.size(); i++) {
                //Sales_Line__c theSL = theSO.Sales_Lines__r[i];
            for (Integer i = 0; i < salesLineList.size(); i++) {
                Sales_Line__c theSL = salesLineList[i];
                if (theSL.Bundle_Line__r != null) {
                    Integer salesLineLineNo = theSL.Line_No__c.intValue();
                    Integer bundleLineLineNo = theSL.Bundle_Line__r.Line_No__c.intValue();
                    if (mapNewSalesLinesByLineNo.containsKey(salesLineLineNo)) {
                        Sales_Line__c newSL = mapNewSalesLinesByLineNo.get(salesLineLineNo);
                        Sales_Line__c newBundleLine = mapNewSalesLinesByLineNo.get(bundleLineLineNo);
                        newSL.Bundle_Line__c = newBundleLine.Id;
                    }
                }
                //ticket 19130 <<
                /*
                //job task << parent-child resource lines
                if (theSL.Parent_Line__r != null) {
                    Integer salesLineNo = theSL.Line_No__c.intValue();
                    Integer parentLineNo = theSL.Parent_Line__r.Line_No__c.intValue();
                    if (mapNewSalesLinesByLineNo.containsKey(salesLineNo)) {
                        Sales_Line__c newSL = mapNewSalesLinesByLineNo.get(salesLineNo);
                        Sales_Line__c parentLine = mapNewSalesLinesByLineNo.get(parentLineNo);
                        newSL.Parent_Line__c = parentLine.Id;
                    }
                }
                //job task >>
                */
                //ticket 19130 >>
            }
            //}
            upsert theNewSLList;

            //sales line details
            Map<Integer, Sales_Line__c> mapSalesLinesWithDetailByLineNo = new Map<Integer, Sales_Line__c>();
            for (Sales_Line__c salesLine : salesLineList) {
                mapSalesLinesWithDetailByLineNo.put(salesLine.Line_No__c.intValue(), salesLine);
            }

            //ticket 19130 <<
            List<Sales_Parent_Child_Relation__c> relationsToInsert = new List<Sales_Parent_Child_Relation__c>();
            //ticket 19130 >>

            List<Sales_Line_Detail__c> newSLDetailList = new List<Sales_Line_Detail__c>();
            for (Sales_Line__c newSL : theNewSLList) {
                if (mapSalesLinesWithDetailByLineNo.containsKey(newSL.Line_No__c.intValue())) {
                    Sales_Line__c salesLine = mapSalesLinesWithDetailByLineNo.get(newSL.Line_No__c.intValue());

                    //ticket 19130 <<
                    if (salesLine.Sales_Child_Lines__r != null) {
                        for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                            Sales_Parent_Child_Relation__c relationToInsert = new Sales_Parent_Child_Relation__c();
                            relationToInsert.Parent_Line__c = newSL.Id;
                            relationToInsert.Child_Line__c = mapNewSalesLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue()).Id;
                            relationsToInsert.add(relationToInsert);
                        }
                    }
                    //ticket 19130 >>

                    if (salesLine.Sales_Line_Details__r != null) {
                        for (Sales_Line_Detail__c theSLDetail : salesLine.Sales_Line_Details__r) {
                            Sales_Line_Detail__c newSLDetail = theSLDetail.clone(false, true);
                            newSLDetail.Sales_Line__c = newSL.Id;
                            newSLDetailList.add(newSLDetail);
                        }
                    }
                }
            }

            //ticket 19130 <<
            insert relationsToInsert;
            //ticket 19130 >>

            if (newSLDetailList.size() > 0) {
                insert newSLDetailList;
            }

            return theNewSO.Id;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    //aura >>

    //ticket 19672 <<
    /*
    public void addRemoveManifestFeeLines(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines){
        Boolean addManifestFeeLine = salesOrder.Manifest_And_Profile__c;
        Integer wasteDisposalLineCount = 0;
        for(Sales_Line__c salesLine :salesLines) {
            if (salesLine.Category__c == 'Waste Disposal' && salesLine.Resource__c != null && salesLine.System_Calculated_Line__c == false) {
                wasteDisposalLineCount += 1;
            }
        }
        if (addManifestFeeLine && wasteDisposalLineCount > 0) {
            this.addManifestFeeLines(salesOrder, salesLines);
        }
        else {
            this.removeManifestFeeLines(salesOrder, salesLines);
        }
    }

    private void addManifestFeeLines(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines) {
        Integer sysCalcManifestLineCount = 0;
        Integer totalWasteDisposalLineCount = 0;
        List<Decimal> lineNos = new List<Decimal>();

        for(Sales_Line__c salesLine :salesLines){
            if(salesLine.Category__c == 'Waste Disposal' && salesLine.System_Calculated_Line__c == true &&
                    salesLine.Resource__c == theCompanySetup.Default_Manifest_Fee_Resource__c) {
                sysCalcManifestLineCount += 1;
            }

            if(salesLine.Category__c == 'Waste Disposal' && salesLine.Resource__c != null && salesLine.System_Calculated_Line__c == false){
                totalWasteDisposalLineCount +=1;
                lineNos.add(salesLine.Line_No__c);
            }
        }
        if (sysCalcManifestLineCount == 0 && totalWasteDisposalLineCount > 0) {
            Decimal lastLineNo = getLastLineNumber(salesLines);
            salesLines.add(createManifestFeeLine(lastLineNo + 1, true, salesOrder.Id, salesOrder.Tax_Liable__c, salesOrder.Tax_Area__c));
        }
    }

    private void removeManifestFeeLines(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines) {
        for (Integer i = 0; i < salesLines.size(); i++) {
            if(salesLines[i].Category__c == 'Waste Disposal' && salesLines[i].System_Calculated_Line__c == true &&
                    salesLines[i].Resource__c == theCompanySetup.Default_Manifest_Fee_Resource__c) {
                salesLines.remove(i);
                i--;
            }
        }
    }
    */
    //ticket 19672 >>
    //deprecated <<
    /*
    public void prepareManifestFeeLines(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines, List<Sales_Line__c> wasteDisposalLines, Integer currentLineNo){
        Integer systemLineCount = 0;
        Integer lineCount = 0;
        for (Sales_Line__c theSL : wasteDisposalLines) {
            if(theSL.System_Calculated_Line__c) {
                systemLineCount++;
                lineCount++;
                continue;
            }
            if (String.isNotEmpty(theSL.Resource__c)){
                lineCount++;
            }
        }
        if (Math.mod(lineCount, 2) == 0) return;
        Boolean isFirst = Math.mod(systemLineCount + 1, 4) == 1 ? true : false;
        Decimal lineNumber = 0;
        Integer lineSize = salesLines.size();
        Boolean lineCreated = false;
        if (lineSize > 0 && salesLines[lineSize - 1].Line_No__c != null) lineNumber = salesLines[lineSize - 1].Line_No__c + 1;
        if (currentLineNo + 1 < wasteDisposalLines.size()) {
            for (Integer j = currentLineNo + 1; j < wasteDisposalLines.size() && !lineCreated; j++) { // Break double loop
                if (String.isEmpty(wasteDisposalLines[j].Resource__c)) {
                    lineNumber = wasteDisposalLines[j].Line_No__c;
                    for (Integer k = 0; k < salesLines.size(); k++ ) {
                        if(salesLines[k].Line_No__c == lineNumber) {
                            salesLines[k] = createManifestFeeLine(lineNumber, isFirst, salesOrder.Id, salesOrder.Tax_Liable__c, salesOrder.Tax_Area__c);
                            lineCreated = true;
                            break;
                        }
                    }
                }
            }
        }
        if (!lineCreated) salesLines.add(createManifestFeeLine(lineNumber, isFirst, salesOrder.Id, salesOrder.Tax_Liable__c, salesOrder.Tax_Area__c));
    }
    */
    //deprecated >>

    private Sales_Line__c createManifestFeeLine(Decimal lineNumber, Boolean isFirst, Id salesOrderId, Boolean taxLiable, String taxArea) {
        Sales_Line__c newLine = new Sales_Line__c();
        newLine.Sales_Order__c = salesOrderId;
        newLine.Category__c = 'Waste Disposal';
        newLine.Line_No__c = lineNumber;
        newLine.Tax_Group__c = 'TX';
        List<Resource__c> resources = ResourcesSelector.newInstance().selectById(new Set<Id>{theCompanySetup.Default_Manifest_Fee_Resource__c});
        Resource__c theResource = resources[0];
        newLine.Resource__c = theResource.Id;
        newLine.Resource__r = theResource;
        newLine.Description__c = theResource.Description__c;
        newLine.Unit_of_Measure__c = theResource.Unit_of_Measure__c;
        //aura <<
        //newLine.Quantity__c = 1;
        newLine.Unit_of_Measure__r = theResource.Unit_of_Measure__r;
        newLine.Quantity__c = 0;
        //aura >>
        newLine.Unit_Price__c = isFirst ? 25 : 5;
        newLine.Unit_Cost__c = newLine.Unit_Price__c;
        newLine.Line_Amount__c = newLine.Unit_Price__c;
        newLine.Line_Cost__c = newLine.Line_Amount__c;
        if (taxLiable) newLine.Tax_Pct__c = CompanyMgmt.getSalesTax(taxArea, newLine.Tax_Group__c); else newLine.Tax_Pct__c = 0;
        newLine.Tax__c = CompanyMgmt.halfUpTo2D(newLine.Line_Amount__c * companyMgmt.zeroIfNull(newLine.Tax_Pct__c) / 100);
        newLine.Line_Amt_Incl_Tax__c = newLine.Line_Amount__c + newLine.Tax__c;
        newLine.System_Calculated_Line__c = true;
        return newLine;
    }

    public void updateSQWhenNewSOCreated(Id salesQuoteId) {
        fflib_ISObjectUnitOfWork uow = Application.UnitOfWork.newInstance();
        ISalesOrders domainSO = SalesOrders.newInstance(SalesOrdersSelector.newInstance().selectConvertCountById(new Set<Id>{salesQuoteId}));
        domainSO.updateConvertCountAndQuoteStatus(uow);
        uow.commitWork();
    }

    public Decimal getLastLineNumber(List<Sales_Line__c> salesLines){
        Decimal largestLineNo = 0;
        for(Sales_Line__c salesLine:salesLines) {
            //aura <<
            //if(largestLineNo < salesLine.Line_No__c) largestLineNo = salesLine.Line_No__c;
            if (largestLineNo < salesLine.Line_No__c) {
                largestLineNo = salesLine.Line_No__c;
            }
            //aur >>
        }
        return largestLineNo;
    }

    //W-000391
    //job task <<
    /*
    public void calcEstimatedDateInfo(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines, Integer duration){
        if (salesOrder.Estimated_Job_Start_Date__c != null && salesOrder.Duration__c != null) {
            if (salesOrder.Duration__c <= 0) {
                throw new DataException('Duration must be bigger than zero. Pleas enter valid duration value');
            }

            Date startDate = salesOrder.Estimated_Job_Start_Date__c;
            Boolean includeWeekend = salesOrder.Include_Weekend__c;
            Boolean includeHoliday = salesOrder.Include_Holiday__c;
            Date endDate;

            Integer otPayDays = 0;
            Integer dtPayDays = 0;
            Integer regPayDays = 0;

            Id billingRuleId = salesOrder.Contract__r.Billing_Rule__c != null ? salesOrder.Contract__r.Billing_Rule__c : theCompanySetup.Default_Billing_Rule__c;
            BillingRule billingRule = new BillingRule(billingRuleId);

            WorkDays workDays = new WorkDays(startDate, duration, billingRule, includeWeekend, includeHoliday);
            endDate = workDays.calcEndDate();
            salesOrder.Estimated_Job_End_Date__c = endDate;
            Map<Date, String> payCodeByDates = workDays.calcWorkDatesWithRateCode();
            for(Date workDate:payCodeByDates.keySet()){
                String payCode = payCodeByDates.get(workDate);
                if(payCode == EnumUtil.TimeRateCode.REG.name()) regPayDays += 1;
                else if(payCode == EnumUtil.TimeRateCode.OT.name()) otPayDays += 1;
                else if(payCode == EnumUtil.TimeRateCode.DT.name()) dtPayDays += 1;
            }

            for (Sales_Line__c line : salesLines) {
                if (line.Category__c == 'Labor') {
                    line.Regular_Day__c = regPayDays;
                    line.Overtime_Day__c = otPayDays;
                    line.Premium_Day__c = dtPayDays;
                }
                line.Number_of_Day__c = duration;
            }
        }

        if(salesOrder.Estimated_Job_Start_Date__c != null) assignRateSheet(salesOrder);
    }
    */
    /*
     *   Ticket#24326
     *      when pass in duration is set to 0 - mean line's day needed does not need to be recalculate
     *      if pass in duration is not equals to 0 then system will recalculate all line duration using header duration value
     */
    public void calcEstimatedDateInfo(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers, Integer duration){
        if (salesOrder.Estimated_Job_Start_Date__c != null && salesOrder.Duration__c != null) {
            if (salesOrder.Duration__c <= 0) {
                throw new DataException('Duration must be greater than zero. Please enter valid duration.');
            }

            Date startDate = salesOrder.Estimated_Job_Start_Date__c;
            Boolean includeWeekend = salesOrder.Include_Weekend__c;
            Boolean includeHoliday = salesOrder.Include_Holiday__c;
            Date endDate;

            Integer otPayDays = 0;
            Integer dtPayDays = 0;
            Integer regPayDays = 0;

            //Ticket#21540 >>
            Id billingRuleId = null;
            if(salesOrder.Contract__r.Billing_Rule__c != null){
                billingRuleId = salesOrder.Contract__r.Billing_Rule__c;
            } else if (salesOrder.Service_Center__r.Billing_Rule__c != null){
                billingRuleId = salesOrder.Service_Center__r.Billing_Rule__c;
            } else if (salesOrder.Subsidiary_Company__r.Billing_Rule__c != null){
                billingRuleId = salesOrder.Subsidiary_Company__r.Billing_Rule__c;
            } else {
                billingRuleId = theCompanySetup.Default_Billing_Rule__c;
            }
            //if(salesOrder.Contract__r.Billing_Rule__c != null ? salesOrder.Contract__r.Billing_Rule__c : theCompanySetup.Default_Billing_Rule__c);
            //Ticket#21540 <<
            BillingRule billingRule = new BillingRule(billingRuleId);

            Integer tempDuration = duration;
            if(duration == 0){
                tempDuration = salesOrder.Duration__c.intValue();
            }
            WorkDays workDays = new WorkDays(startDate, tempDuration, billingRule, includeWeekend, includeHoliday);
            endDate = workDays.calcEndDate();
            salesOrder.Estimated_Job_End_Date__c = endDate;
            if(duration > 0) {
                Map<Date, String> payCodeByDates = workDays.calcWorkDatesWithRateCode();
                for(Date workDate:payCodeByDates.keySet()){
                    String payCode = payCodeByDates.get(workDate);
                    if(payCode == EnumUtil.TimeRateCode.REG.name()) regPayDays += 1;
                    else if(payCode == EnumUtil.TimeRateCode.OT.name()) otPayDays += 1;
                    else if(payCode == EnumUtil.TimeRateCode.DT.name()) dtPayDays += 1;
                }
    
                for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                        if (salesLine.Category__c == 'Labor') {
                            salesLine.Regular_Day__c = regPayDays;
                            salesLine.Overtime_Day__c = otPayDays;
                            salesLine.Premium_Day__c = dtPayDays;
                        }
                        if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Materials') {
                            salesLine.Number_of_Day__c = duration;
                        }
                    }
                }
            }
        }

        if(salesOrder.Estimated_Job_Start_Date__c != null) {
            assignRateSheet(salesOrder);
        }
    }
    //job task >>

    public void assignRateSheet(Sales_Order__c salesOrder){
        if(salesOrder.Estimated_Job_Start_Date__c != null && salesOrder.Rate_Sheet__c == null){
            Id companyPriceListId;
            Id scPriceListId;
            Set<Id> priceListIds = new Set<Id>();
            if(theCompanySetup.Price_List__c != null){
                companyPriceListId = theCompanySetup.Price_List__c;
                priceListIds.add(companyPriceListId);
            }

            if(salesOrder.Service_Center__c != null){
                List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectById(new Set<Id>{salesOrder.Service_Center__c});
                if(serviceCenters.size() > 0){
                    scPriceListId = serviceCenters[0].Price_List__c;
                    priceListIds.add(scPriceListId);
                }
            }

            if(priceListIds.size() > 0){
                Boolean rateSheetFound = false;
                Map<Id, Id> activeRateSheetsByPriceListIds =
                        PriceListSelector.newInstance().getActiveRateSheetIdByPricesListIdsAndWorkDate(priceListIds, salesOrder.Estimated_Job_Start_Date__c);

                if(activeRateSheetsByPriceListIds.containsKey(scPriceListId)){
                    salesOrder.Rate_Sheet__c = activeRateSheetsByPriceListIds.get(scPriceListId);
                    rateSheetFound = true;
                }

                if(rateSheetFound == false && activeRateSheetsByPriceListIds.containsKey(companyPriceListId)){
                    salesOrder.Rate_Sheet__c = activeRateSheetsByPriceListIds.get(companyPriceListId);
                    rateSheetFound = true;
                }
            }
        }
    }

    //ticket 19672 <<
    /*
    public Decimal calcTotalForSurchargeCalculation(String surchargeType, List<Sales_Line__c> salesLines){
        if (salesLines == null) return 0;

        Decimal subTotal = 0;
        Set<Id> resIds = new Set<Id>();
        Set<Id> resTypeIds = new Set<Id>();
        for(Sales_Line__c salesLine : salesLines){
            if(salesLine.Resource_Type__c != null) resTypeIds.add(salesLine.Resource_Type__c);
            if(salesLine.Resource__c != null) resIds.add(salesLine.Resource__c);
        }

        Map<Id, Resource_Type__c> resourceTypesByIds = ResourceTypesSelector.newInstance().getResourceTypesByIdsMap(resTypeIds);
        Map<Id, Resource__c> resourcesByIds = ResourcesSelector.newInstance().getResourcesByIdsMapByResIds(resIds);

        switch on surchargeType{
            when 'Energy & Insurance'{
                for(Sales_Line__c salesLine : salesLines) {
                    Boolean eiExempted = false;
                    if (salesLine.Resource_Type__c != null && resourceTypesByIds.containsKey(salesLine.Resource_Type__c)) {
                        Resource_Type__c resourceType = resourceTypesByIds.get(salesLine.Resource_Type__c);
                        eiExempted = resourceType.E_I_Surcharge_Exempted__c;
                    }
                    if (salesLine.Resource__c != null && eiExempted != true && resourcesByIds.containsKey(salesLine.Resource__c)) {
                        Resource__c resource = resourcesByIds.get(salesLine.Resource__c);
                        eiExempted = resource.E_I_Surcharge_Exempted__c;
                    }

                    if (salesLine.Resource__c != theCompanySetup.Default_Energy_Insurance_Resource__c &&
                            salesLine.Resource__c != theCompanySetup.Default_Fuel_Surcharge_Resource__c &&
                            eiExempted != true) {

                        subTotal += CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                    }
                }
            }
            when 'Fuel Surcharge'{
                for(Sales_Line__c salesLine : salesLines){
                    if(salesLine.Category__c == 'Equipment' && salesLine.Resource_Type__c != null &&
                            resourceTypesByIds.containsKey(salesLine.Resource_Type__c)){
                        Resource_Type__c resourceType = resourceTypesByIds.get(salesLine.Resource_Type__c);
                        if(resourceType.Fuel_Fired_Equipment__c == true){
                            subTotal += CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                            if(salesLine.Bill_as_Lump_Sum__c == true || salesLine.Non_Billable__c == true){
                                //Ticket#18396 >>
                                subTotal += CompanyMgmt.zeroIfNull(salesLine.xLine_Amount__c);
                                //Ticket#18396 <<
                            }
                        }
                    }
                }
            }
        }
        return CompanyMgmt.halfUpTo2D(subTotal);
    }
    */
    //ticket 19672 >>

    //aura <<
    //Ticket# 13982
    public void updateTMAndSISuperUserChangeBTC(Sales_Order__c theSO) {
        Set<Id> theSIIds = new Set<Id>();
        List<TM__c> theTMsToUpdate = new List<TM__c>();

        // Get Open Sales Invoice Ids and TMs related to each Sales Invoice
        List<Sales_Invoice__c> theSIs = [SELECT Id, Name, (SELECT Id, Name, Sales_Invoice__c,Total_Lines__c, Invoiced_Lines__c FROM T_Ms__r)
        FROM Sales_Invoice__c WHERE Sales_Order__c = :theSO.Id AND Document_Status__c <> 'Posted' AND Document_Status__c <> 'Void' AND Credit_Memo__c <> TRUE];
        if (theSIs.size() > 0) {
            for (Sales_Invoice__c theSI : theSIs){
                theSIIds.add(theSI.Id);
                theTMsToUpdate.addAll(theSI.T_Ms__r);
            }
        }

        // Get TMs without SI generated and TMs with Open SI generated
        List<TM__c> theTMs = TMsSelector.newInstance().selectOpenTMsBySalesOrderIdAndInvoiceIdWithLines(theSO.Id, theSIIds);
        // Update theTMs BTC, Contract__c and From_Sales_Quote__c
        for (TM__c theTM : theTMs) {
            theTM.Bill_to_Customer__c = theSO.Bill_to_Customer_No__c;
            theTM.Contract__c = null;
            theTM.Contact__c = null;
            //resolve site address error <<
            theTM.Alternate_Site_Address__c = null;
            //resolve site address error >>
            theTM.Site_Contact_2__c = null; //AES-401,Ticket#14009
            theTM.From_Sales_Quote__c = null; //Ticket# 14086
            for(TM_Line__c theTML:theTM.TM_Lines__r){ //AES-426 #14086
                theTML.Contract_Line__c = null;
            }
        }

        // Push price
        Integer counter = updateTMPriceFromSO(theSO, theTMs);

        // Delete Open Sales Invoice and Bring all related TMs back to "Ready to Bill"
        Set<Id> theTMsToUpdateIds = new Set<Id>();
        for (TM__c theTM : theTMsToUpdate) {
            theTMsToUpdateIds.add(theTM.Id);
        }
        List<TM_Line__c> theTMLList = [SELECT Id, Name, Invoiced__c FROM TM_Line__c WHERE TM__c in :theTMsToUpdateIds];
        if (theTMLList != null && theTMLList.size() > 0){
            for (TM_Line__c TML : theTMLList) {
                TML.Invoiced__c = false;
            }
            upsert theTMLList;
        }
        if (theTMsToUpdate != null && theTMsToUpdate.size() > 0) {
            for(TM__c theTM : theTMsToUpdate) {
                theTM.Sales_Invoice__c = null;
                theTM.Status__c = 'Ready to Bill';
            }
            update theTMsToUpdate;
        }
        delete theSIs;
    }

    // Ticket# 13982
    public Integer updateTMPriceFromSO (Sales_Order__c theSO, List<TM__c> tms) {
        fflib_SObjectUnitOfWork sow = new fflib_SObjectUnitOfWork(
                new Schema.SObjectType[]{
                        TM__c.SObjectType,
                        TM_Line__c.SObjectType
                }
        );

        Integer counter = 0;
        Map<TM__c, List<TM_Line__c>> tmLinesByTms = new Map<TM__c, List<TM_Line__c>>();
        for (TM__c tm : tms) {
            tm.Tax_Liable__c = theSO.Tax_Liable__c;
            tm.Contract__c = theSO.Contract__c;
            sow.registerDirty(tm);
            tmLinesByTms.put(tm, tm.TM_Lines__r);
        }

        TMLLinesService.initStaticVariables(tmLinesByTms);
        for (TM__c tm : tmLinesByTms.keySet()) {
            for (TM_Line__c tmLine : tmLinesByTms.get(tm)) {
                counter += 1;
                TMLLinesService.calcUnitPrice(tm, tmLine);
                TMLLinesService.calcUnitCost(tm, tmLine);
                if (tmLine.Category__c == 'Labor' && tmLine.Scheduled_Date__c != null) {
                    tmLine = TMMgmt.applyLaborBillingRule(tmLine, tm);
                }
                sow.registerDirty(tmLine);
            }
        }
        TMLLinesService.calcTotals(tmLinesByTms);

        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.massCreateInvoice = true;
        sow.commitWork();
        return counter;
    }
    //aura >>

    //job task <<
    //ticket 19130 <<
    /*
    public void createSalesLinesFromJobTaskTemplateLines(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo, List<Job_Task_Template_Line__c> jobTaskTemplateLines) {
        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
        if (jobTaskTemplateLines != null) {
            Map<Id, Sales_Line__c> mapSalesLinesByTemplateLineId = new Map<Id, Sales_Line__c>();
            //parent lines
            for (Job_Task_Template_Line__c jobTaskTemplateLine : jobTaskTemplateLines) {
                if (jobTaskTemplateLine.Parent_Line__c == null) {
                    Sales_Line__c salesLine = this.createSalesLineFromJobTaskTemplateLine(salesOrder, jobTaskWrapper.JobTask, nextSalesLineNo, jobTaskTemplateLine, null);
                    salesLines.add(salesLine);
                    nextSalesLineNo++;

                    mapSalesLinesByTemplateLineId.put(jobTaskTemplateLine.Id, salesLine);
                }
            }

            //child lines
            for (Job_Task_Template_Line__c jobTaskTemplateLine : jobTaskTemplateLines) {
                if (jobTaskTemplateLine.Parent_Line__c != null) {
                    Integer parentSalesLineNo = null;
                    if (mapSalesLinesByTemplateLineId.containsKey(jobTaskTemplateLine.Parent_Line__c)) {
                        parentSalesLineNo = mapSalesLinesByTemplateLineId.get(jobTaskTemplateLine.Parent_Line__c).Line_No__c.intValue();
                    }
                    Sales_Line__c salesLine = this.createSalesLineFromJobTaskTemplateLine(salesOrder, jobTaskWrapper.JobTask, nextSalesLineNo, jobTaskTemplateLine, parentSalesLineNo);
                    salesLines.add(salesLine);
                    nextSalesLineNo++;
                }
            }
        }
        jobTaskWrapper.SalesLines.addAll(salesLines);
    }
    */

    private String getSalesLineItemUOMKey(Sales_Line__c salesLine) {
        String key;
        if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Bundled') {
            key = salesLine.Resource_Type__c + ';' + salesLine.Unit_of_Measure__c;
        }
        else {
            key = salesLine.Resource__c + ';' + salesLine.Unit_of_Measure__c;
        }
        return key;
    }
    public void createSalesLinesFromJobTaskTemplateLines(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo, List<Job_Task_Template_Line__c> jobTaskTemplateLines) {
        if (jobTaskTemplateLines != null) {


            //ticket 19130 05.13.2023 <<
            /*
            //convert the template lines to sales lines
            List<Sales_Line__c> newSalesLines = new List<Sales_Line__c>();
            Map<String, Sales_Line__c> mapNewSalesLinesByKey = new Map<String, Sales_Line__c>();
            for (Job_Task_Template_Line__c jobTaskTemplateLine : jobTaskTemplateLines) {
                Sales_Line__c salesLine = this.createSalesLineFromJobTaskTemplateLine(salesOrder, jobTaskWrapper.JobTask, nextSalesLineNo, jobTaskTemplateLine, null);
                nextSalesLineNo++;

                //add the template child lines to the child lines map
                String key = this.getSalesLineItemUOMKey(salesLine);
                mapNewSalesLinesByKey.put(key, salesLine);
                newSalesLines.add(salesLine);
            }

            //add to the tempJobTaskWrapper for presumptive child query
            ACVSalesOrderJobTaskWrapper tempJobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
            tempJobTaskWrapper.JobTask = jobTaskWrapper.JobTask;
            tempJobTaskWrapper.SalesLines.addAll(newSalesLines);
            SalesLinesService.initStaticVariables(salesOrder, tempJobTaskWrapper); //query presumptive child resources

            //build a map for the existing resources on the jobTaskWrapper
            Map<String, Sales_Line__c> mapJobTaskWrapperSalesLinesByKey = new Map<String, Sales_Line__c>();
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                String key = this.getSalesLineItemUOMKey(salesLine);
                mapJobTaskWrapperSalesLinesByKey.put(key, salesLine);
            }

            //get the presumptive child resources and replace them with the existing the child resources on the jobTaskWrapper if exist
            Set<Integer> linesInserted = new Set<Integer>();
            for (Integer i = 0; i < newSalesLines.size(); i++) {
                Sales_Line__c newSalesLine = newSalesLines[i];
                List<Sales_Line__c> childLines = SalesLinesService.calculatePresumptiveChildLines(salesOrder, jobTaskWrapper.JobTask, newSalesLine, nextSalesLineNo);

                if (childLines.size() > 0) {
                    linesInserted.add(newSalesLine.Line_No__c.intValue());

                    List<Sales_Parent_Child_Relation__c> relations = new List<Sales_Parent_Child_Relation__c>();
                    for (Integer j = 0; j < childLines.size(); j++) {
                        String key = this.getSalesLineItemUOMKey(childLines[j]);
                        Sales_Line__c childLine;
                        if (mapJobTaskWrapperSalesLinesByKey.containsKey(key)) {
                            childLine = mapJobTaskWrapperSalesLinesByKey.get(key); //use the existing line from the jobTaskWrapper
                            childLine.Is_Child_Resource__c = true;

                            //do not insert the line from the newSalesLines later as it's a child resource
                            if (mapNewSalesLinesByKey.containsKey(key)) {
                                linesInserted.add(mapNewSalesLinesByKey.get(key).Line_No__c.intValue());
                            }

                        } else if (mapNewSalesLinesByKey.containsKey(key)) {
                            childLine = mapNewSalesLinesByKey.get(key); //use the resource from the template line
                            linesInserted.add(childLine.Line_No__c.intValue()); //record child lines to remove from the newSalesLines
                            if (!mapJobTaskWrapperSalesLinesByKey.containsKey(key)) {
                                jobTaskWrapper.SalesLines.add(childLine);
                                mapJobTaskWrapperSalesLinesByKey.put(key, childLine);
                                nextSalesLineNo++;
                            }
                        }
                        else {
                            childLine = childLines[j];
                            if (!mapJobTaskWrapperSalesLinesByKey.containsKey(key)) {
                                jobTaskWrapper.SalesLines.add(childLine); //add the new child resource
                                mapJobTaskWrapperSalesLinesByKey.put(key, childLine);
                                nextSalesLineNo++;
                            }
                        }

                        //create relationship
                        Sales_Parent_Child_Relation__c relation = new Sales_Parent_Child_Relation__c();
                        relation.Parent_Line__c = newSalesLine.Id;
                        relation.Parent_Line__r = new Sales_Line__c(Id = newSalesLine.Id, Line_No__c = newSalesLine.Line_No__c, Description__c = newSalesLine.Description__c, Category__c = newSalesLine.Category__c, Resource_Type__c = newSalesLine.Resource_Type__c, Resource_Type__r = newSalesLine.Resource_Type__r, Resource__c = newSalesLine.Resource__c, Resource__r = newSalesLine.Resource__r);
                        relation.Child_Line__c = childLine.Id;
                        relation.Child_Line__r = new Sales_Line__c(Id = childLine.Id, Line_No__c = childLine.Line_No__c,  Description__c = childLine.Description__c, Category__c = childLine.Category__c, Resource_Type__c = childLine.Resource_Type__c, Resource_Type__r = childLine.Resource_Type__r, Resource__c = childLine.Resource__c, Resource__r = childLine.Resource__r);
                        relations.add(relation);
                    }
                    newSalesLine = (Sales_Line__c)JSONUtils.attachListToParent(newSalesLine, relations, 'Sales_Child_Lines__r');
                    jobTaskWrapper.SalesLines.add(newSalesLine); //parent line insert always
                }
            }

            //insert remaining lines
            for (Integer i = 0; i < newSalesLines.size(); i++) {
                Sales_Line__c newSalesLine = newSalesLines[i];
                if (!linesInserted.contains(newSalesLine.Line_No__c.intValue())) {
                    String key = this.getSalesLineItemUOMKey(newSalesLine);
                    //check if the resource is a child resource on the jobTaskTaskWrapper, only insert if it's not a child resource
                    if (mapJobTaskWrapperSalesLinesByKey.containsKey(key)) {
                        if (!mapJobTaskWrapperSalesLinesByKey.get(key).Is_Child_Resource__c) {
                            jobTaskWrapper.SalesLines.add(newSalesLine);
                        }
                    }
                    else {
                        jobTaskWrapper.SalesLines.add(newSalesLine);
                    }
                }
            }
            */

            for (Job_Task_Template_Line__c jobTaskTemplateLine : jobTaskTemplateLines) {
                Sales_Line__c salesLine = this.createSalesLineFromJobTaskTemplateLine(salesOrder, jobTaskWrapper.JobTask, nextSalesLineNo, jobTaskTemplateLine, null);
                jobTaskWrapper.SalesLines.add(salesLine);
                nextSalesLineNo++;
            }
            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrapper); //query presumptive child resources
            for (Integer i = 0; i < jobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c salesLine = jobTaskWrapper.SalesLines[i];
                if (salesLine.Wizard_Question_Answered__c == true) continue;

                salesLine = SalesLinesService.calculatePresumptiveChildLines(salesOrder, jobTaskWrapper, salesLine, nextSalesLineNo);
                jobTaskWrapper.SalesLines[i] = salesLine;
                nextSalesLineNo = jobTaskWrapper.NextSalesLineNo;
            }
            //ticket 19130 05.13.2023 >>
        }
    }
    //ticket 19130 >>

    private Sales_Line__c createSalesLineFromJobTaskTemplateLine(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, Integer nextSalesLineNo, Job_Task_Template_Line__c jobTaskTemplateLine, Integer parentLineNo) {
        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Sales_Order_Job_Task__c = jobTask.Id;
        salesLine.Sales_Order_Job_Task__r = new Sales_Order_Job_Task__c(Line_No__c = jobTask.Line_No__c);
        salesLine.Line_No__c = nextSalesLineNo;
        salesLine.Category__c = jobTaskTemplateLine.Category__c;
        salesLine.Resource_Type__c = jobTaskTemplateLine.Resource_Type__c;
        salesLine.Resource_Type__r = jobTaskTemplateLine.Resource_Type__r;
        salesLine.Resource__c = jobTaskTemplateLine.Resource__c;
        salesLine.Resource__r = jobTaskTemplateLine.Resource__r;
        salesLine.Description__c = jobTaskTemplateLine.Description__c;
        salesLine.Resource_Type_UOM__c = jobTaskTemplateLine.Resource_Type_UOM__c;
        salesLine.Resource_Type_UOM__r = jobTaskTemplateLine.Resource_Type_UOM__r;
        salesLine.Resource_UOM__c = jobTaskTemplateLine.Resource_UOM__c;
        salesLine.Resource_UOM__r = jobTaskTemplateLine.Resource_UOM__r;
        salesLine.Unit_of_Measure__c = jobTaskTemplateLine.Unit_of_Measure__c;
        salesLine.Unit_of_Measure__r = jobTaskTemplateLine.Unit_of_Measure__r;
        //ticket 19130 <<
        if (jobTaskTemplateLine.Quantity__c == null) {
            jobTaskTemplateLine.Quantity__c = 0;
        }
        //ticket 19130 >>
        salesLine.Quantity__c = jobTaskTemplateLine.Quantity__c;
        if (jobTaskTemplateLine.Category__c == 'Labor' || jobTaskTemplateLine.Category__c == 'Equipment') {
            salesLine.Number_of_Day__c = salesOrder.Duration__c;
            salesLine.UOM_Qty__c = 0;
        }
        /*Waste001
        salesLine.Cost_Method__c = jobTaskTemplateLine.Cost_Method__c;
        salesLine.Unit_Weight_Vol__c = jobTaskTemplateLine.Unit_Weight_Vol__c;
        salesLine.Unit_Weight_Vol__r = jobTaskTemplateLine.Unit_Weight_Vol__r;
        salesLine.Container_Size__c = jobTaskTemplateLine.Container_Size__c;
        salesLine.Container_Size__r = jobTaskTemplateLine.Container_Size__r;
         */
        salesLine.Cost_Method__c = null;
        salesLine.Unit_Weight_Vol__c = null;
        salesLine.Container_Size__c = null;

        salesLine.Number_of_Day__c = salesOrder.Duration__c;
        salesLine.Tax_Group__c = 'TX';

        if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
            if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                    salesLine.UOM_Qty__c = TimeUtils.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                }
            }
            else {
                salesLine.UOM_Qty__c = 1;
            }
        }

        //ticket 19130 <<
        /*
        if (parentLineNo != null) {
            salesLine.Parent_Line__r = new Sales_Line__c(Line_No__c = parentLineNo);
        }
        */
        salesLine.Is_Child_Resource__c = jobTaskTemplateLine.Is_Child_Resource__c;
        //ticket 19130 >>
        return  salesLine;
    }

    public void cloneJobTask(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper fromJobTaskWrapper, ACVSalesOrderJobTaskWrapper newJobTaskWrapper, Integer nextSalesLineNo) {
        //ticket 19130 <<
        //List<Sales_Line__c> newSalesLines = new List<Sales_Line__c>();
        Map<Integer, Sales_Line__c> mapNewSalesLinesByOldLineNo = new Map<Integer, Sales_Line__c>();
        //ticket 19130 >>    

        if (fromJobTaskWrapper.SalesLines != null) {
            Map<Integer, Integer> mapBoundLines = new Map<Integer, Integer>();
            Map<Integer, Integer> mapParentLines = new Map<Integer, Integer>();

            for (Integer i = 0;  i < fromJobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c salesLine = fromJobTaskWrapper.SalesLines[i];

                Sales_Line__c newSalesLine = salesLine.clone(false, true);
                newSalesLine.Id = null;
                newSalesLine.Line_No__c = nextSalesLineNo;
                newSalesLine.Sales_Order_Job_Task__c = newJobTaskWrapper.JobTask.Id;
                newSalesLine.Sales_Order_Job_Task__r = newJobTaskWrapper.JobTask;
                if (newSalesLine.Sales_Line_Details__r != null) {
                    for (Sales_Line_Detail__c salesLineDetail : newSalesLine.Sales_Line_Details__r) {
                        salesLineDetail.Id = null; //preserveId = false only works for the parent record
                        salesLineDetail.Sales_Line__c = null;
                    }
                }
                
                //ticket 19130 <<
                //newSalesLines.add(newSalesLine);
                mapNewSalesLinesByOldLineNo.put(salesLine.Line_No__c.intValue(), newSalesLine);
                //ticket 19130 >>
                
                nextSalesLineNo++;

                //handle bundled lines
                mapBoundLines.put(salesLine.Line_No__c.intValue(), newSalesLine.Line_No__c.intValue());
                //handle child resource lines
                mapParentLines.put(salesLine.Line_No__c.intValue(), newSalesLine.Line_No__c.intValue());
            }

            //handle bundled lines
            //ticket 19130 <<
            //for (Sales_Line__c newSalesLine : newSalesLines) {
            for (Sales_Line__c newSalesLine : mapNewSalesLinesByOldLineNo.values()) {
            //ticket 19130 >>
                //newSalesLine still holds the original bundle line info
                if (newSalesLine.Bundle_Line__r != null) {
                    Integer newBundleLineNo = mapBoundLines.get(newSalesLine.Bundle_Line__r.Line_No__c.intValue());
                    //link the new sales line to the new bundle line
                    newSalesLine.Bundle_Line__c = null;
                    newSalesLine.Bundle_Line__r = new Sales_Line__c(Line_No__c = newBundleLineNo);
                }
            }

            //ticket 19130 <<
            /*
            //handle child resource lines
            for (Sales_Line__c newSalesLine : newSalesLines) {
                //newSalesLine still holds the original parent line info
                if (newSalesLine.Parent_Line__r != null) {
                    Integer newParentLineNo = mapParentLines.get(newSalesLine.Parent_Line__r.Line_No__c.intValue());
                    newSalesLine.Parent_Line__c = null;
                    newSalesLine.Parent_Line__r = new Sales_Line__c(Line_No__c = newParentLineNo);
                }
            }
            */
            for (Integer i = 0;  i < fromJobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c fromSalesLine = fromJobTaskWrapper.SalesLines[i];
                if (fromSalesLine.Sales_Child_Lines__r != null) {
                    Sales_Line__c newParentLine = mapNewSalesLinesByOldLineNo.get(fromSalesLine.Line_No__c.intValue());
                    List<Sales_Parent_Child_Relation__c> relationsToInsert = new List<Sales_Parent_Child_Relation__c>();
                    for (Integer j = 0; j < fromSalesLine.Sales_Child_Lines__r.size(); j++) {
                        Sales_Parent_Child_Relation__c relation = fromSalesLine.Sales_Child_Lines__r[j];
                        Sales_Line__c newChildLine = mapNewSalesLinesByOldLineNo.get(relation.Child_Line__r.Line_No__c.intValue());
                        Sales_Parent_Child_Relation__c relationToInsert = new Sales_Parent_Child_Relation__c();
                        relationToInsert.Parent_Line__r = new Sales_Line__c(Line_No__c = newParentLine.Line_No__c, Description__c = newParentLine.Description__c, Category__c = newParentLine.Category__c, Resource_Type__c = newParentLine.Resource_Type__c, Resource_Type__r = newParentLine.Resource_Type__r, Resource__c = newParentLine.Resource__c, Resource__r = newParentLine.Resource__r);
                        relationToInsert.Child_Line__r = new Sales_Line__c(Line_No__c = newChildLine.Line_No__c, Description__c = newChildLine.Description__c, Category__c = newChildLine.Category__c, Resource_Type__c = newChildLine.Resource_Type__c, Resource_Type__r = newChildLine.Resource_Type__r, Resource__c = newChildLine.Resource__c, Resource__r = newChildLine.Resource__r);
                        relationsToInsert.add(relationToInsert);
                    }
                    mapNewSalesLinesByOldLineNo.put(fromSalesLine.Line_No__c.intValue(), (Sales_Line__c)JSONUtils.attachListToParent(newParentLine, relationsToInsert, 'Sales_Child_Lines__r'));
                }
            }
            //ticket 19130 >>
        }
        //ticket 19130 <<
        //newJobTaskWrapper.SalesLines = newSalesLines;
        newJobTaskWrapper.SalesLines = mapNewSalesLinesByOldLineNo.values();
        //ticket 19130 >>
    }
    //job task >>
}