/************************************************************************
 * OWner		Date			Task #			Description
 * Vennila		12/6/2023		63070			Blocked Credit Memo creation if Service Center EQAI Integration checkbox is checked.
 * Sathish		04/20/2024		79107			introduced new field and update close date while closing and reopening salesorder
 * Sathish		05/08/2024		87105			updated closed date when ingeration have been failed or not
 * Shahwaz      06/17/2024      87303           Reopen Sales Order and Billing Project - Tie to Service Center Checkbox
 * Shahwaz      10/21/2024      DE36096         SF-Remove ability for user to delete sales quotes/orders
 * Vennila      1/21/2024       TA500898        Block update to Job billing project call to EQAI on closing the sales order
 * Vignesh      03/02/2025      US141018       LOA Reminder if Quote/Order is Over $30,000
 * **********************************************************************/

global with sharing class SalesOrderController {
    private final ApexPages.StandardController theController;
    public Sales_Order__c theSO { get; set; }
    @TestVisible
    private List<Sales_Line__c> theSLList;
    public List<Sales_Line__c> theSOLineLaborList;
    public List<Sales_Line__c> theSOLineMaterialList;
    public List<Sales_Line__c> theSOListSubcontractors;
    public List<Sales_Line__c> theSOListWasteDisposal;
    public List<Sales_Line__c> theSOListMisc;
    public List<Sales_Line__c> theSOListLumpSum;

    public String orderId { get; set; }
    //private String newSOId;
    private String accountId;
    public static Company_Setup__c theCompanySetupValue;
    public Company_Setup__c theCompanySetup{
        get{
            if (theCompanySetupValue == null) {
                theCompanySetupValue = CompanyMgmt.getCompanySetup();
            }
            return theCompanySetupValue;
        }
    }

    //ticket 19895 <<
    public Boolean validForApproval { set; get; }
    //ticket 19895 >>

    public String startingDateValue { get; set; }
    public String endingDateValue { get; set; }
    public Boolean includeWeekend { get; set; }
    public Integer tmCount { get; set; }
    public List<TMWrap> theTMWrapList { get; set; }
    public Decimal maxDaysToCreateTM { get; set; }
    public Decimal maxTMCopiesPerDay { get; set; }
    public String selConvertTo { get; set; }

    public Decimal SLSubtotal { get; set; }
    public Decimal SLTaxTotal { get; set; }
    //public Decimal SLTotal { get; set; }
    //public Decimal SLProfitMargin { get; set; } //Ticket# AES-415
    //public Decimal SLTotalCost { get; set; }

    public Decimal SLSubtotalLabor { get; set; }
    public Decimal SLTaxTotalLabor { get; set; }
    //public Decimal SLTotalLabor { get; set; }
    //public Decimal SLProfitMarginLabor { get; set; } //Ticket# AES-415
    //public Decimal SLTotalCostLabor { get; set; }

    public Decimal SLSubtotalEquipment { get; set; }
    public Decimal SLTaxTotalEquipment { get; set; }
    //public Decimal SLTotalEquipment { get; set; }
    //public Decimal SLProfitMarginEquipment { get; set; } //Ticket# AES-415
    //public Decimal SLTotalCostEquipment { get; set; }

    public Decimal SLSubtotalMaterials { get; set; }
    public Decimal SLTaxTotalMaterials { get; set; }
    //public Decimal SLTotalMaterials { get; set; }
    //public Decimal SLProfitMarginMaterials { get; set; } //Ticket# AES-415
    //public Decimal SLTotalCostMaterials { get; set; }

    public Decimal SLSubtotalSubcontractors { get; set; }
    public Decimal SLTaxTotalSubcontractors { get; set; }
    public Decimal SLTotalSubcontractors { get; set; }
    public Decimal SLProfitMarginSubcontractors { get; set; } //Ticket# AES-415
    public Decimal SLTotalCostSubcontractors { get; set; }

    public Decimal SLSubtotalWasteDisposal { get; set; }
    public Decimal SLTaxTotalWasteDisposal { get; set; }
    //public Decimal SLTotalWasteDisposal { get; set; }
    //public Decimal SLProfitMarginWasteDisposal { get; set; } //Ticket# AES-415
    //public Decimal SLTotalCostWasteDisposal { get; set; }

    public Decimal SLSubtotalLumpSum { get; set; }
    public Decimal SLTaxTotalLumpSum { get; set; }
    //public Decimal SLTotalLumpSum { get; set; }
    //public Decimal SLProfitMarginLumpSum { get; set; } //Ticket# AES-415
    //public Decimal SLTotalCostLumpSum { get; set; }

    public Decimal SLSubtotalMisc { get; set; }
    public Decimal SLTaxTotalMisc { get; set; }
    //public Decimal SLTotalMisc { get; set; }
    //public Decimal SLProfitMarginMisc { get; set; } //Ticket# AES-415
    //public Decimal SLTotalCostMisc { get; set; }

    public Decimal SLSubtotalDemurrage { get; set; }
    public Decimal SLTaxTotalDemurrage { get; set; }
    public Decimal SLTotalDemurrage { get; set; }
    //public Decimal SLProfitMarginDemurrage { get; set; } //Ticket# AES-415
    //public Decimal SLTotalCostDemurrage { get; set; }

    public Decimal SurchargeAmount {get;set;} //Ticket# AES-416

    //public Tax_Area__c theTaxArea { get; set; }
    //public Contact theBTContact {get; set; } //Ticket# AES-401
    //public Contact theSiteContact {get; set;} //Ticket# AES-401
    public Contract theContract {get;set;} //Ticket# AES-440
    //public Sales_Order_Type__c theSalesOrderType{get;set;} // 14553
    public Boolean newSO {set;get;} // 14553
    public String addLineCategory { get; set; }
    public String orderBy;
    //public String orderBy_old;
    public String order;
    public String LaborAssumption { get; set; }

    //public String tmStartingDateValue { get; set; }
    //public String tmEndingDateValue { get; set; }
    //public List<TMCreateSIWrapper> theTMCreateSIWrapList { get; set; }
    public List<TM__c> theTMList{get;set;}
    public List<TM_Line__c> theAllTMLList { get; set; }
    //public List<TMSectionsWrapper> theTMSectionList { get; set; }
    //Map<String, TMSectionsWrapper> mapTMSectionWrapper;
    @TestVisible
    //private Map<Id, Sales_Invoice__c> mapTMSI;
    //private Sales_Invoice__c theSI;

    //public String fbURL { get; set; }
    //public String GoogleURL { get; set; }
    //public String TwitterURL { get; set; }
    //public String linkdURL { get; set; }
    public String companyLogoURL { get; set; }
    //public String saveType { get; set; }
    public String selPrintType { get; set; }
    public User theUser { get; set; } //Ticket# 13982
    public Id originBillToCustomer {get; set;} //Ticket# 13982
    private static Boolean isNullUOMQtyChecked = false;  //Ticket# 14296
    private static Boolean nullUOMQty = false;  //Ticket# 14296
    private static Boolean isSLQtyIsZeroChecked = false; //Ticket#14296
    private static Boolean SLQtyIsZero = false; //Ticket# 14296
    private Boolean EISurchargeLineFound = false; //14250
    private Boolean FuelSurchargeLineFound = false; // 14250
    //15189
    public String creditMemoNote {get; set;}
    public String selectedCrMemoReasonCode {get; set;}
    public Sales_Invoice__c appliedToInvoice {get; set;} //Ticket#19765
    public Boolean isUpdated {get; set;}
    public Boolean isWarning {get; set;}
    
    public List<SelectOption> getCrMemoReasonCodeOptions(){
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));
        Schema.DescribeFieldResult fieldResult = Sales_Invoice__c.Credit_Memo_Reason_Code__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for(Schema.PicklistEntry f:ple){
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }
    public Boolean printEstimatedDuration {get; set; } //Ticket#21772

    public SalesOrderController(ApexPages.StandardController controller) {
        theController = controller;
        orderId = ApexPages.currentPage().getParameters().get('id');
        printEstimatedDuration = true; //Ticket#21772
        Map<String, String> thePageParameters = ApexPages.currentPage().getParameters();
        for (String key : thePageParameters.keySet()) {
            if (key.contains('_lkid')) {
                accountId = thePageParameters.get(key);
            }
        }

        theContract = new Contract();

        newSO = false;
        selectSO();

        if(newSO == false){
            appliedToInvoice = new Sales_Invoice__c();
        }
        if (!String.isEmpty(theSO.Contract__c)) {
            theContract.Id = theSO.Contract__c;
            theContract = theSO.Contract__r;
        }

        selectSLList();

        /* Ticket#24559
        if (theSO.Portal_Basis__c) {LaborAssumption = 'PortalBasis';}
        else if (theSO.Overtime_Rate__c) {LaborAssumption = 'OvertimeRate';}
        else if (theSO.Daily_Rate__c) {LaborAssumption = 'DailyRate';}
        else if (theSO.Lump_Sum__c) {LaborAssumption = 'LumpSum';}
        else if (theSO.Portal_Basis_Adv__c) {LaborAssumption = 'PortalBasisAdv';} //Ticket# 14303

        for (Sales_Line__c theSL : theSLList) { // 14250
            if (theSL.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c){
                EISurchargeLineFound = true;
                FuelSurchargeLineFound = false;
                break;
            }
            if (theSL.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c){
                FuelSurchargeLineFound = true;
                EISurchargeLineFound = false;
                break;
            }
        }

        startingDateValue = Date.today().month() + '/' + Date.today().day() + '/' + Date.today().year();
        endingDateValue = startingDateValue;
        maxDaysToCreateTM = theCompanySetup.Max_Days_to_Create_T_M__c;
        maxTMCopiesPerDay = theCompanySetup.Max_T_M_Copies_Per_Day__c;
        tmCount = 1;
        includeWeekend = false;

        CalculateTotal();

        SurchargeAmount = CompanyMgmt.zeroIfNull(theSO.Surcharge_Amount__c); //Ticket# AES-416
         */

        /*
        if (CompanyMgmt.getVFPageName() == 'CreateSIFromSOConfirmation' || Test.isRunningTest()) {
            if (theSO.Document_Status__c != 'Open') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invoice can be created for Open Sales Orders only.'));
            } else {
                selectTmList();
                selectTmSections();
                //Need to select all TML first in order to calculate total lines and invoiced lines per category
                selectAllTML();
                //calculateLines();
            }
        }
         */

        /*
        if (CompanyMgmt.getVFPageName() == 'CreateSalesQuoteWord') {
            imageUrls();
        }
         */

        if (CompanyMgmt.getVFPageName() == 'CreateSalesQuotePDF') {
            ApexPages.currentPage().getHeaders().put('content-disposition', 'inline;filename='+ salesOrder.Name +'.pdf');
        }
        selectUser();

        //ticket 19895 <<
        this.validForApproval = true;

        if (theSO.Site_Street__c == null || theSO.Site_City__c == null || theSO.Site_State__c == null || theSO.Site_Postal_Code__c == null) {
            this.validForApproval = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Complete site address is required.'));
        }
        if (theSO.Tax_Area__c == null && theSO.Quote_Type__c != 'Rate_Sheet') {
            this.validForApproval = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Tax area is required.'));
        }
        
        // ticket 63070
       if(theSO.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == True && CompanyMgmt.getVFPageName() == 'CreateMiscCreditMemo')
        {
           // this.validForApproval = false;           
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Creating Misc. Credit Memos is disabled for this Service Center'));
        }
        //ticket 19895 >>

        //Ticket#20275 >>
        if (CompanyMgmt.getVFPageName() == 'SalesRecordApprovalConfirmation') {
            if (theSO.Expiration_Date__c < Date.today()) {
                this.validForApproval = false;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This Sales Quote is expired and can no longer be submitted for Approval. Please create a new Sales Quote.'));
            }

            //Ticket#21357 >>
            if(theSO.Quote_Contact__r.Blocked__c == true || theSO.Bill_to_Contact__r.Blocked__c == true || theSO.Site_Contact_2__r.Blocked__c == true){
                this.validForApproval = false;
            }
            //Ticket#21357 <<
        }
        //Ticket#20275 <<
        //Ticket#20275 <<        
        this.isWarning = theSO.Order_Total_Amount_Incl_Tax__c > 30000 ? true : false;        
    }
   
    public void setWarningResponse() { //US141018
        SalesOrderController newController = new SalesOrderController(theController); //Calling to validate again, if not validation not happens
        this.isWarning = false;    
    }

    public Boolean allowDataOverride { get {return CompanyMgmt.allowDataOverride();} }
    //Ticket# 13982
    private void selectUser() {
        theUser = new User();
        theUser = [SELECT Id, Name, Super_User__c FROM User WHERE Id = :UserInfo.getUserId()];
    }

    /*
     *  Ticket#20749 - add contract status field
     *  Ticket#21357 - add contact Blocked__c field
     */
    private void selectSO() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Order__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Bill_to_Contact__r.Salutation,Bill_to_Contact__r.Suffix, Bill_to_Contact__r.LastName, ' +
                'Bill_to_Contact__r.Title, Bill_to_Contact__r.Name, Bill_to_Contact__r.FirstName, Bill_to_Customer_No__r.Name, ' +
                'Bill_to_Customer_No__r.Credit_Hold__c, Sales_Order_Type__r.Name, Account_Executives__r.Name, ' +
                'Service_Center__r.Name, Project_Coordinator__r.Name,Contract__r.Name, Alternate_Site_Address__r.Name ';
        strQuery += ', Bill_to_Customer_No__r.Id, Bill_to_Customer_No__r.Service_Center__c, ' +
                'Bill_to_Customer_No__r.Subsidiary_Company__c, Bill_to_Customer_No__r.Tax_Area__c, ' +
                'Bill_to_Customer_No__r.Billing_Contact__c, Tax_Area__r.Name ';
        strQuery += ', Bill_to_Customer_No__r.BillingStreet , Bill_to_Customer_No__r.BillingCity, ' +
                'Bill_to_Customer_No__r.BillingState, Bill_to_Customer_No__r.BillingPostalCode, ' +
                'Bill_to_Customer_No__r.BillingCountry, Bill_to_Customer_No__r.Payment_Term__c, ' +
                'Bill_to_Customer_No__r.ParentId, Contract__r.ContractNumber ';
        strQuery += ', Sales_Order_Type__r.Description__c, Bill_to_Customer_No__r.AccountNumber, ' +
                'Bill_to_Customer_No__r.Emergency__c, From_Sales_Quote__r.Name, Site_Contact_2__r.Name, ' +
                'Site_Contact_2__r.FirstName, Site_Contact_2__r.LastName, Bill_to_Customer_No__r.RecordTypeId,' +
                'Contract__r.Billing_Rule__c, Contract__r.Billing_Rule__r.Name, Sales_Order_Type__r.Emergency_Response__c, Quote_Contact__r.Name, ' +
                'Quote_Contact__r.FirstName, Quote_Contact__r.LastName, Contract__r.Surcharge_Type__c, Contract__r.Surcharge_Pct__c, Rate_Sheet__r.Name, ' +
                'CreatedBy.Name, Service_Center__r.Blocked__c, Contract__r.Status';
        strQuery += ', Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c,Quote_Contact__r.Salutation, Quote_Contact__r.Title, Quote_Contact__r.Blocked__c, Bill_to_Contact__r.Blocked__c, Site_Contact_2__r.Blocked__c';
        strQuery += ' FROM Sales_Order__c WHERE Id =: orderId';
        theSO = Database.query(strQuery);
        originBillToCustomer = theSO.Bill_to_Customer_No__c;//Ticket# 13982
    }

    public String title {
        get {

            if (orderId == null) {
                return 'New Order';
            } else {
                return theSO.Document_Type__c;
            }
        }
    }

    public String titleInPrintConfirmation {
        get {

            if (orderId == null) {
                return '';
            } else {
                return theSO.Name;
            }
        }
    }

    public Boolean open {
        get {
            if (theSO.Document_Status__c == 'Open' && theSO.Approval_Status__c != EnumUtil.ApprovalStatus.PENDING_APPROVAL.name()){
                return true;
            } else{
                return false;
            }
        }
    }

    public Sales_Order__c salesOrder {
        get {
            return theSO;
        }
    }

    //Depreciated
    //moved to lighting
    public void validateSalesOrderType() {
        /*
        String salesOrderTypeId = ApexPages.currentPage().getParameters().get('salesOrderTypeId');
        //theSO = SalesOrderMgmt.validateSalesOrderType(theSO);
        if (!String.isEmpty(salesOrderTypeId)){
            List<Sales_Order_Type__c> sotTypes = [SELECT Id, Name, Emergency_Response__c FROM Sales_Order_Type__c WHERE Id = :salesOrderTypeId];
            if (sotTypes.size() > 0){
                Sales_Order_Type__c sot = sotTypes[0];
                theSO.Sales_Order_Type__c = sot.Id;
                theSO.Sales_Order_Type__r = sot;
                //theSalesOrderType = sot;
                theSO.Emergency_Sales_Order__c = sot.Emergency_Response__c;
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Sales Order Type does not exist!' + salesOrderTypeId));
            }
        }
         */
    }

    //Depreciated
    //moved to lighting
    public void validateSalespeople() {
        /*
        theSO = SalesOrderMgmt.validateSalespeople(theSO);
         */
    }

    //Depreciated
    //moved to lighting
    /*
    public void changeOwner(){
        String newOwnerId = ApexPages.currentPage().getParameters().get('newOwnerId');
        theSO.OwnerId = newOwnerId;
    }
     */

    //Depreciated
    //moved to lighting
    public void validateContract() { //AES-440
        /*
        String contractId = ApexPages.currentPage().getParameters().get('contractId');
        if (!String.isEmpty(contractId)){
            List<Contract> contracts = ContractsSelector.newInstance().selectById(new Set<Id>{contractId});
            if (contracts.size() > 0){
                theSO.Contract__c = contracts[0].Id;
                theSO.Contract__r = contracts[0];
                theContract = contracts[0];
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact does not exist!' + contractId));
            }
        } else {
            theSO.Contract__c = null;
            theSO.Contract__r = null;
            theSO.Surcharge_Pct__c = null;
        }

        SalesOrdersService.setSurchargePct(theSO);
        SalesLinesService.initStaticVariables(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => theSLList});
        for(Sales_Line__c salesLine : theSLList){
            SalesLinesService.calcUnitPrice(theSO, salesLine);
        }
        SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => theSLList});
         */
    }

    //moved to lighting
    /*
    public void validateRateSheet(){

        try{
            String rateSheetId = ApexPages.currentPage().getParameters().get('rateSheetId');
            if(String.isBlank(rateSheetId)){
                rateSheetId = null;
            }
            SalesOrdersService.validateRateSheet(theSO, theSLList, rateSheetId);
            //System.debug('Info: Rate Sheet after validate ' + theSO.Rate_Sheet__r);
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }
     */

    //moved to lighting
    public void validateBillToCustomer(){
        /*
        //Ticket#14549 >>
        if (originBillToCustomer != theSO.Bill_to_Customer_No__c && String.isNotBlank(theSO.Bill_to_Customer_No__c)){
            SalesOrdersService.updateSalesOrderBillingAndTax(theSO, newSO);
            theSO = SalesOrderMgmt.validateBillToCustomer(theSO);
            theSLList = SalesOrderMgmt.validateLines(theSLList, theSO);
            //Ticket# 14086 >>
            theSO.From_Sales_Quote__c = null;
            for (Sales_Line__c theSL : theSLList) {
                theSL.Quote_Line__c = null;
            }
            //Ticket# 14086 <<
            CalculateTotal();
        }
         */
    }

    //Depreciated
    public void validateQuoteDate(){
        /*
        theSO.Surcharge_Pct__c = null;
        SalesOrdersService.setSurchargePct(theSO);
        CalculateTotalOrder();
         */
    }

    //Depreciated
    public void validateSurchargeType(){
        /*
        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');
        if(newFieldValue != ''){
            theSO.Surcharge_Type__c = newFieldValue;
            theSO.Surcharge_Pct__c = null;
            SalesOrdersService.setSurchargePct(theSO);
            CalculateTotalOrder();
        }
         */
    }

    //Depreciated
    public void validateServiceCenter(){
        /*
        List<Service_Center__c> theSCList = ServiceCentersSelector.newInstance().selectById(new Set<Id>{theSO.Service_Center__c});
        if (theSCList.size() > 0){
            theSO.Subsidiary_Company__c = theSCList[0].Subsidiary_Company__c;
        }
         */
    }

    //Depreciated
    public void addDemurrageSurchargeLine (String surchargeType){
        /*
        CalculateTotal(); //msave removed resource_type__r causing fuel line calculation to $0.00
        Integer soLineListSize = theSLList.size();
        Decimal displayNo = 0;
        if (soLineListSize > 0 && theSLList[soLineListSize - 1].Line_No__c != null) displayNo = theSLList[soLineListSize - 1].Line_No__c;
        displayNo = displayNo + 1;
        Sales_Line__c surchargeLine = new Sales_Line__c();
        surchargeLine.Sales_Order__c = theSO.Id; //14553
        surchargeLine.Category__c = 'Misc. Charges And Taxes';
        surchargeLine.Line_No__c = displayNo;
        surchargeLine.Tax_Group__c = 'NT';
        if (surchargeType == 'Energy and Environmental Compliance Fee') {
            surchargeLine.Resource__c = theCompanySetup.Default_Energy_Insurance_Resource__c;
            surchargeLine.Resource__r = new Resource__c(Id = theCompanySetup.Default_Energy_Insurance_Resource__c, Name = theCompanySetup.Default_Energy_Insurance_Resource__r.Name);
            surchargeLine.Description__c = theCompanySetup.Default_Energy_Insurance_Resource__r.Description__c;
        } else if (surchargeType == 'Fuel Surcharge') {
            surchargeLine.Resource__c = theCompanySetup.Default_Fuel_Surcharge_Resource__c;
            surchargeLine.Resource__r = new Resource__c(Id = theCompanySetup.Default_Fuel_Surcharge_Resource__c, Name = theCompanySetup.Default_Fuel_Surcharge_Resource__r.Name);
            surchargeLine.Description__c = theCompanySetup.Default_Fuel_Surcharge_Resource__r.Description__c;
        }

        surchargeLine.Unit_of_Measure__c = CompanyMgmt.getResource(surchargeLine.Resource__c).Unit_of_Measure__c;
        surchargeLine.Quantity__c = 1;
        surchargeLine.Unit_Price__c = SurchargeAmount;
        surchargeLine.Line_Amount__c = SurchargeAmount;
        surchargeLine.Tax__c = 0.00;
        surchargeLine.Line_Amt_Incl_Tax__c = SurchargeAmount;
        surchargeLine.System_Calculated_Line__c = true;
        theSLList.add(surchargeLine);
         */
    }

    //Depreciated
    public void removeDemurrageSurchargeLine (List<Sales_Line__c> deleteList){
        /*
        for (Sales_Line__c theSL : theSLList) {
            if (theSL.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c ||
                    theSL.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c ) {
                deleteList.add(theSL);
            }
        }
         */
    }

    //Depreciated
    public void updateDemurrageSurchargeLine(){
        /*
        CalculateTotalOrder();
        for (Sales_Line__c theSL : theSLList) {
            if (theSL.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c ||
                    theSL.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c ) {
                theSL.Unit_Price__c = SurchargeAmount;
                theSL.Line_Amount__c = SurchargeAmount;
                theSL.Line_Amt_Incl_Tax__c = SurchargeAmount;
                break;
            }
        }
         */
    }

    //Depreciated
    public void validateAltSiteAddress() {
        //theSO = SalesOrderMgmt.validateAltSiteAddress(theSO);
    }

    //Depreciated
    public void validateCreateSiteAddress() {
        // should Create When Save SO
        //theSO = SalesOrderMgmt.validateCreateSiteAddress(theSO);
    }

    //Depreciated
    public void validateTaxLiable() {
        /*
        for (Sales_Line__c theSL : theSLList) {
            theSL.Tax_Group__c = theSO.Tax_Liable__c ? 'TX' : 'NT';
        }
        reInsertSL();
         */
    }

    //Depreciated
    //moved to lighting
    public void validateTaxArea() {
        /*
        //theSO = SalesOrderMgmt.validateTaxArea(theSO);
        //reInsertSL();

        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');

        if (!String.isEmpty(newFieldValue)) {
            //theSO.Tax_Area__c = newFieldValue;

            List<Tax_Area__c> TaxArea = [SELECT Id, Name FROM Tax_Area__c WHERE Id = :newFieldValue LIMIT 1];
            if (TaxArea.size() == 0) {
                TaxArea = [Select Id, Name from Tax_Area__c where Name = :newFieldValue Limit 1];
            }

            if (taxArea.size() > 0) {
                theSO.Tax_Area__c = TaxArea[0].Id;
                theSO.Tax_Area__r = new Tax_Area__c(Id = TaxArea[0].Id, Name = TaxArea[0].Name);
                reInsertSL();
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Tax Area does not exist! ' + newFieldValue));
            }
        }
         */
    }

    //Depreciated
    //moved to lightning
    public void validateContact(){
        /*
        String contactId = ApexPages.currentPage().getParameters().get('contactId');
        String fieldId = ApexPages.currentPage().getParameters().get('fieldId');
        if (!String.isEmpty(contactId)){
            //List<Contact> contacts = [SELECT Id, FirstName, LastName, Name, Mobile_Email__c, Email, Phone FROM Contact WHERE Id = :contactId];
            List<Contact> contacts = ContactsSelector.newInstance().selectContactsByIds(new Set<Id>{contactId});
            if (contacts.size() > 0) {
                Contact contact = contacts[0];
                if (fieldId == 'theBTContact') {
                    theSO.Bill_to_Contact__c = contact.Id;
                    theSO.Bill_to_Contact__r = contact;
                } else if (fieldId == 'theQuoteContact') {
                    theSO.Quote_Contact__c = contact.Id;
                    theSO.Quote_Contact__r = contact;
                } else {
                    theSO.Site_Contact_2__c = contact.Id;
                    theSO.Site_Contact_2__r = contact;
                    if(String.isNotBlank(contact.Phone)) theSO.Site_Phone_No__c = contact.Phone;
                    if(String.isNotBlank(contact.Email)) theSO.Site_Email_Address__c = contact.Email;
                    theSO.Mobile_Email__c = contact.Mobile_Email__c;
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact does not exist!' + contactId));
            }
        }
         */
    }

    //Depreciated
    //moved to lighting
    public void validateEstimateJob() { //W-000391
        /*
        List<Sales_Line__c> lines = new List<Sales_Line__c>(SOListLaborLines);
        lines.addAll(SOListEquipmentLines);
        theSO.Duration__c = CompanyMgmt.zeroIfNull(theSO.Duration__c) == 0 ? 1 : theSO.Duration__c.intValue();
        SalesOrdersService.calcEstimatedDateInfo(theSO, lines, theSO.Duration__c.intValue());
        for(Sales_Line__c line:lines){
            SalesLinesService.calcLaborUnitPrice(theSO, line);
        }
        SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{
                theSO => lines});
        //SalesOrdersService.updateSOWhenEstimateJobChanged(theSO, lines);
        CalculateTotal();
         */
    }

    //Ticket#21908 - add resource,resource type Blocked__c field
    private void selectSLList() {
        System.debug('Info: selectSLList >>');
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Unit_of_Measure__r.Name,Resource__r.Name, Sales_Order__r.Name, Resource_Type__r.Name, Resource__r.Unit_Cost__c, Resource_Type__r.Unit_Cost__c, Contract_Line__r.Name';
        strQuery += ', Resource_Type__r.Unit_of_Measure__c, Resource_Type__r.Unit_of_Measure1__c, Resource_Type__r.Unit_of_Measure2__c, Resource_Type__r.Unit_of_Measure3__c, Resource_Type__r.Unit_of_Measure4__c ';
        strQuery += ', Resource_Type__r.Fuel_Fired_Equipment__c, Sales_Order__r.Document_Type__c';
        strQuery += ', Resource__r.Unit_of_Measure__c, Resource__r.Unit_of_Measure1__c, Resource__r.Unit_of_Measure2__c, Resource__r.Unit_of_Measure3__c, Resource__r.Unit_of_Measure4__c ';
        strQuery += ', Sales_Line__c.Container_Size__r.Name, Sales_Line__c.Unit_Weight_Vol__r.Name, Facility__r.Name, Unit_of_Measure__r.Hours_UOM__c, Resource__r.EEC_Surcharge_Exempted__c, Resource_Type__r.EEC_Surcharge_Exempted__c';
        strQuery += ', Bundle_Line__r.Line_No__c, Resource__r.Tax_Group__c, Resource__r.Blocked__c, Resource_Type__r.Blocked__c';
        strQuery += ' FROM Sales_Line__c WHERE Sales_Order__c =: orderId ORDER BY Line_No__c';
        System.debug('Info: strQuery ' + strQuery);
        theSLList = Database.query(strQuery);
    }

    //Depreciated
    //moved to lightning
    public PageReference save() {
        /*
        try{
            msave();
            PageReference SalesOrderPage = new PageReference('/' + theSO.Id);
            SalesOrderPage.setRedirect(true);
            return SalesOrderPage;
        } catch (Exception e){
            System.debug('ERROR: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
         */
        return null;
    }

    //Depreciated
    //moved to lightning
    public PageReference quickSave() {
        /*
        try{
            msave();
            PageReference SalesOrderPage = new PageReference('/apex/SalesOrder?id=' + theSO.Id);
            SalesOrderPage.setRedirect(true);
            return SalesOrderPage;
        } catch (Exception e){
            System.debug('ERROR: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
         */
        return null;
    }

    //moved to lightning
    /*
    public PageReference billAsLumpSumAll() {
        SalesOrdersService.updateSalesLinesForBillAsLumpSumAllAction(theSLList);
        CalculateTotal();
        return null;
    }
     */

    public Boolean isSalesOrder {
        get {
            if (theSO.Document_Type__c == 'Sales Order') {
                return true;
            } else {
                return false;
            }
        }
    }

    public Company_Setup__c CompanySetup {
        get {
            return theCompanySetup;
        }
    }

    public List<Sales_Line__c> SOListLaborLines {
        get {
            theSOLineLaborList = new List<Sales_Line__c>();
            for (Sales_Line__c theSOL : theSLList) {
                if (theSOL.Category__c == 'Labor') {
                    theSOLineLaborList.add(theSOL);
                }
            }
            return theSOLineLaborList;
        }
        private set {
            theSOLineLaborList = value;
        }
    }

    public List<Sales_Line__c> SOListMaterialLines {
        get {
            theSOLineMaterialList = new List<Sales_Line__c>();
            for (Sales_Line__c theSOL : theSLList) {

                if (theSOL.Category__c == 'Materials') {
                    theSOLineMaterialList.add(theSOL);
                }

            }
            return theSOLineMaterialList;
        }
        private set {
            theSOLineMaterialList = value;
        }
    }

    public List<Sales_Line__c> SOListEquipmentLines {
        get {
            SOListEquipmentLines = new List<Sales_Line__c>();
            for (Sales_Line__c theSOL : theSLList) {
                if (theSOL.Category__c == 'Equipment') {
                    SOListEquipmentLines.add(theSOL);
                }
            }
            return SOListEquipmentLines;
        }
        private set {
            SOListEquipmentLines = value;
        }
    }

    public List<Sales_Line__c> SOListSubContractorLines {
        get {
            theSOListSubcontractors = new List<Sales_Line__c>();
            for (Sales_Line__c theSOL : theSLList) {
                if (theSOL.Category__c == 'Subcontractors') {
                    theSOListSubcontractors.add(theSOL);
                }
            }
            return theSOListSubcontractors;
        }
        private set {
            theSOListSubcontractors = value;
        }
    }

    public List<Sales_Line__c> SOListWasteDisposal {
        get {
            theSOListWasteDisposal = new List<Sales_Line__c>();
            for (Sales_Line__c theSOL : theSLList) {

                if (theSOL.Category__c == 'Waste Disposal') theSOListWasteDisposal.add(theSOL);

            }
            return theSOListWasteDisposal;
        }
        public set {
            theSOListWasteDisposal = value;
        }
    }

    public List<Sales_Line__c> SOListMisc {
        get {
            theSOListMisc = new List<Sales_Line__c>();
            for (Sales_Line__c theSOL : theSLList) {
                if (theSOL.Category__c == 'Misc. Charges And Taxes') theSOListMisc.add(theSOL);
            }
            return theSOListMisc;
        }
        private set {
            theSOListMisc = value;
        }
    }

    public List<Sales_Line__c> SOListLumpSum {
        get {
            theSOListLumpSum = new List<Sales_Line__c>();
            for (Sales_Line__c theSOL : theSLList) {
                if (theSOL.Category__c == 'Bundled') theSOListLumpSum.add(theSOL);
            }
            return theSOListLumpSum;
        }
        private set {
            theSOListLumpSum = value;
        }
    }

    //new Category added for case #13610
    public List<Sales_Line__c> SOListDemurrage {
        get {
            SOListDemurrage = new List<Sales_Line__c>();
            for (Sales_Line__c theSOL : theSLList) {
                if (theSOL.Category__c == 'Demurrage') SOListDemurrage.add(theSOL);
            }
            return SOListDemurrage;
        }
        private set {
            SOListDemurrage = value;
        }
    }

    //Sales order property give a select options to identify whcih PDF type they want
    //Ticket#27588 - Default type to 'Consolidated'
    public List<SelectOption> lstPrintType {
        get {
            if (lstPrintType == null) {
                lstPrintType = new List<SelectOption>();
                lstPrintType.add(new SelectOption('Consolidated', 'Consolidated'));
                lstPrintType.add(new SelectOption('Detail', 'Detail'));
            }
            return lstPrintType;
        }
        set;
    }

    // Ticket 14204
    /*
    public List<Sales_Line__c> SOListEquipmentLinesWithoutLumpSum{
        get {
            SOListEquipmentLinesWithoutLumpSum = new List<Sales_Line__c>();
            for (Sales_Line__c SL: SOListEquipmentLines) {
                if (SL.Bill_as_Lump_Sum__c != true && SL.Non_Billable__c != true) {
                    if(SL.Unit_of_Measure__c == theCompanySetup.Day_Unit_of_Measure__c){
                        SL.UOM_Qty__c = SL.Number_of_Day__c;
                    } else if (SL.Unit_of_Measure__r.Hours_UOM__c == true){
                        SL.UOM_Qty__c = SL.UOM_Qty__c * SL.Number_of_Day__c;
                    }
                    SOListEquipmentLinesWithoutLumpSum.add(SL);
                }
            }
            return SOListEquipmentLinesWithoutLumpSum;
        }
        set;
    }
    */

    /*
    public List<Sales_Line__c> SOListMaterialLinesWithoutLumpSum{

        get {
            SOListMaterialLinesWithoutLumpSum = new List<Sales_Line__c>();
            for (Sales_Line__c SL: SOListMaterialLines) {
                if (SL.Bill_as_Lump_Sum__c != true && SL.Non_Billable__c != true) {
                    SOListMaterialLinesWithoutLumpSum.add(SL);
                }
            }
            return SOListMaterialLinesWithoutLumpSum;
        }
        set;
    }
     */

    /*
    public List<Sales_Line__c> SOListSubContractorLinesWithoutLumpSum{
        get {
            SOListSubContractorLinesWithoutLumpSum = new List<Sales_Line__c>();
            for (Sales_Line__c SL: SOListSubContractorLines ) {
                if (SL.Bill_as_Lump_Sum__c != true && SL.Non_Billable__c != true) {
                    SOListSubContractorLinesWithoutLumpSum.add(SL);
                }
            }
            return SOListSubContractorLinesWithoutLumpSum;
        }
        set;

    }
     */

    /*
    public List<Sales_Line__c> SOListWasteDisposalWithoutLumpSum{

        get {
            SOListWasteDisposalWithoutLumpSum = new List<Sales_Line__c>();
            for (Sales_Line__c SL: SOListWasteDisposal) {
                if(CompanyMgmt.zeroIfNull(SL.Min_Sell_Qty__c) >  SL.Quantity__c) SL.Quantity__c = SL.Min_Sell_Qty__c;
                if (SL.Bill_as_Lump_Sum__c != true && SL.Non_Billable__c != true) {
                    SOListWasteDisposalWithoutLumpSum.add(SL);
                }
            }
            return SOListWasteDisposalWithoutLumpSum;
        }
        set;
    }

    /*
    public List<Sales_Line__c> SOListDemurrageWithoutLumpSum{
        get {
            SOListDemurrageWithoutLumpSum = new List<Sales_Line__c>();
            for (Sales_Line__c SL: SOListDemurrage) {
                if (SL.Bill_as_Lump_Sum__c != true && SL.Non_Billable__c != true) {
                    SOListDemurrageWithoutLumpSum.add(SL);
                }
            }
            return SOListDemurrageWithoutLumpSum;
        }
        set;
    }
     */

    /*
    public List<Sales_Line__c> SOListMiscWithoutLumpSum{
        get {
            SOListMiscWithoutLumpSum = new List<Sales_Line__c>();
            for (Sales_Line__c SL: SOListMisc) {
                //Ticket#14596
                if (SL.Bill_as_Lump_Sum__c != true && SL.Non_Billable__c != true &&
                        SL.Resource__c != theCompanySetup.Default_Fuel_Surcharge_Resource__c &&
                        SL.Resource__c != theCompanySetup.Default_Energy_Insurance_Resource__c) {
                    SOListMiscWithoutLumpSum.add(SL);
                }
            }
            return SOListMiscWithoutLumpSum;
        }
        set;
    }
     */

    public PageReference printQuotePDF() {

        if (String.isBlank(theSO.Site_Scope__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must enter Project Scope before you can print.'));
            return null;
        }
        if (String.isBlank(theSO.Surcharge_Type__c)) { //Ticket 14150
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must enter Surcharge Type before you can print.'));
            return null;
        }
        //Ticket#21772
        PageReference redirectPage = new PageReference('/apex/SalesQuotePDF?id=' + orderId + '&download=true&printType=' + selPrintType + '&printEstimatedDuration=' + printEstimatedDuration);
        redirectPage.setRedirect(true);
        return redirectPage;
    }

    //job task << for testing and comparing quote pdfs
    /*
    public PageReference printOldQuotePDF() {
        if (String.isBlank(theSO.Site_Scope__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must enter Project Scope before you can print.'));
            return null;
        }
        if (String.isBlank(theSO.Surcharge_Type__c)) { //Ticket 14150
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must enter Surcharge Type before you can print.'));
            return null;
        }

        PageReference redirectPage = new PageReference('/apex/CreateSalesQuotePDF?id=' + orderId + '&printType=' + selPrintType);
        redirectPage.setRedirect(true);
        return redirectPage;
    }
     */
    //job task >>

    //redirect to CreateSalesQuoteWordAdv page set parameter of print type detail or consolidate
    public PageReference printQuoteWord() {
        /*
        if (String.isBlank(theSO.Site_Scope__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must enter Project Scope before you can print.'));
            return null;
        }
        if (String.isBlank(theSO.Surcharge_Type__c)) { //Ticket 14150
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must enter Surcharge Type before you can print.'));
            return null;
        }
        PageReference redirectPage = new PageReference('/apex/CreateSalesQuoteWord?id=' + orderId + '&printType=' + selPrintType);
        redirectPage.setRedirect(true);
        return redirectPage;
         */
        return null;
    }

    //Depreciated
    public PageReference goToNewSO() {
        /*
        PageReference SOPage;
        if (newSOId != null) {
            SOPage = new PageReference('/' + newSOId);
        } else {
            SOPage = new PageReference('/' + theSO.Id);
        }
        SOPage.setRedirect(true);
        return SOPage;
         */
        return null;
    }

    public PageReference PrintConfirmation() {
        List<String> errorList = new List<String>();
        //errorList = SalesOrderMgmt.checkPrintConfirmation(theSO);

        if (errorList.size() > 0) {

            for (Integer i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, errorList[i]));
            }

            return null;
        } else {
            try {
                PageReference salesOrderPDFPage = new PageReference('/apex/SalesOrderPDF?Id=' + theSO.Id);
                salesOrderPDFPage.setRedirect(true);
                return salesOrderPDFPage;

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }
        }
    }

    public PageReference notValidatePrintConfirmation() {
        try {
            PageReference salesOrderPDFPage = new PageReference('/apex/SalesOrderPDF?Id=' + theSO.Id);
            salesOrderPDFPage.setRedirect(true);
            return salesOrderPDFPage;

        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
        }
    }

    //Depreciated
    public PageReference cancel() {
        /*
        if (newSO) return new PageReference('/' + theSO.Bill_to_Customer_No__c);
        return theController.cancel();
         */
        return null;
    }

    public String selectedPrintType {
        get {
            String printType = ApexPages.currentPage().getParameters().get('printType');

            return printType;
        }
        set;
    }

    public PageReference returnBack() {
        return theController.view();
    }

    //Depreciated
    /*
     *  moved to lightning
     */
    public PageReference insertLine() {
        /*
        Integer salesLineListSize = theSLList.size();
        String description = '';
        Id resource = null;
        Resource__c theResource;
        Unit_of_Measure__c theUnitOfMeasure;
        Decimal qty = 0;
        Integer LinesToInsert = Integer.valueof(theCompanySetup.Lines_to_Insert__c);
        //Integer LinesToInsert = 5;
        Decimal lineNo = 0;
        Decimal unitCost = 0;

        if (theSLList != null && theSLList.size() > 0) {
            if (theSLList[salesLineListSize - 1].Line_No__c != null) {
                lineNo = theSLList[salesLineListSize - 1].Line_No__c;
            }
        }

        String objectType = ApexPages.currentPage().getParameters().get('ObjectType');
        String lineCategory = ApexPages.currentPage().getParameters().get('LineCategory');

        if (lineCategory == 'Subcontractors') {
            resource = theCompanySetup.Default_Subcontractor_Resource__c;
            //description = theCompanySetup.Default_Subcontractor_Resource__r.Name;
            LinesToInsert = 5;
            qty = 1;
            unitCost = CompanyMgmt.zeroIfNull(theCompanySetup.Default_Subcontractor_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Lump Sum') {
            resource = theCompanySetup.Default_Lump_Sum_Resource__c;
            description = theCompanySetup.Default_Lump_Sum_Resource__r.Name;
            LinesToInsert = 5;
            unitCost = CompanyMgmt.zeroIfNull(theCompanySetup.Default_Lump_Sum_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Misc. Charges And Taxes') {
            //resource = theCompanySetup.Default_Misc_Charges_Taxes_Resource__c;
            LinesToInsert = 5;
            qty = 1;
            //unitCost = CompanyMgmt.zeroIfNull(theCompanySetup.Default_Misc_Charges_Taxes_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Demurrage') {
            description = '';
            LinesToInsert = 1;
        }

        if (Test.isRunningTest()) resource = TestDataUtil.ResourceRecord.Id;

        if (objectType == 'SalesLine') {
            if (LinesToInsert > 0) {
                for (Integer i = 0; i < LinesToInsert; i++) {
                    lineNo = lineNo + 1;
                    //if (lineCategory == 'Labor' && lineCategory != 'Equipment' && lineCategory != 'Materials' && lineCategory != 'Demurrage' && lineCategory != 'Waste Disposal') {
                    if (lineCategory == 'Subcontractors' || lineCategory == 'Lump Sum'){
                        theResource = [SELECT Id, Name, Unit_of_Measure__c FROM Resource__c WHERE Id = :resource LIMIT 1];
                        if (theResource.Unit_of_Measure__c != null) {
                            theUnitOfMeasure = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Id = :theResource.Unit_of_Measure__c LIMIT 1];
                            theSLList.add(new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo, Category__c = lineCategory,
                                    Resource__c = resource, Unit_of_Measure__c = theResource.Unit_of_Measure__c,
                                    Unit_of_Measure__r = new Unit_of_Measure__c(Id = theUnitOfMeasure.Id, Name = theUnitOfMeasure.Name),
                                    Description__c = description, Tax_Group__c = theSO.Tax_Liable__c ? 'TX' : 'NT', Quantity__c = qty,
                                    Regular_Rate__c = 0,
                                    Unit_Price__c = 0, Unit_Cost__c = unitCost, Line_Cost__c = CompanyMgmt.halfUpTo2D(qty * unitCost)));
                        } else {
                            theSLList.add(new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo, Category__c = lineCategory,
                                    Resource__c = resource, Unit_of_Measure__c = theResource.Unit_of_Measure__c,
                                    Description__c = description, Tax_Group__c = theSO.Tax_Liable__c ? 'TX' : 'NT', Quantity__c = qty,
                                    Unit_Price__c = 0, Unit_Cost__c = unitCost, Line_Cost__c = CompanyMgmt.halfUpTo2D(qty * unitCost)));
                        }
                    } else if ( (lineCategory == 'Labor' || lineCategory == 'Equipment') && (theSO.Estimated_Job_Start_Date__c != null && theSO.Duration__c != null)) {
                        theSLList.add(new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo, Category__c = lineCategory,
                                Resource__c = resource, Description__c = description, Tax_Group__c = theSO.Tax_Liable__c ? 'TX' : 'NT', Quantity__c = qty,
                                Unit_Price__c = 0, Unit_Cost__c = unitCost, Line_Cost__c = CompanyMgmt.halfUpTo2D(qty * unitCost), Number_of_Day__c = theSO.Duration__c));
                    } else {
                        theSLList.add(new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo, Category__c = lineCategory,
                                Resource__c = resource, Description__c = description, Tax_Group__c = theSO.Tax_Liable__c ? 'TX' : 'NT', Quantity__c = qty,
                                Unit_Price__c = 0, Unit_Cost__c = unitCost, Line_Cost__c = CompanyMgmt.halfUpTo2D(qty * unitCost)));

                    }
                }
            }
        }
         */
        return null;
    }

    /*
     *  moved to lightning
     */
    public PageReference deleteLine() {
        /*
        String objectType = ApexPages.currentPage().getParameters().get('objectType');
        String lineNo = ApexPages.currentPage().getParameters().get('lineNo');
        String lineType = ApexPages.currentPage().getParameters().get('lineType');

        if (lineNo == '') lineNo = '0';
        Boolean deleteManifestLine = false; // W-000237
        Boolean finishedNormalDelete = false;
        Decimal manifestLineNumber;
        if (theSO.Manifest_And_Profile__c && lineType == 'Waste Disposal') {
            // check if deleting empty waste line
            for (Integer i = 0; i < theSLList.size(); i++) {
                if (theSLList[i].Line_No__c == Decimal.valueOf(lineNo) && String.isNotEmpty(theSLList[i].Resource__c)){
                    deleteManifestLine = true; break;
                }
            }
            // find last system calculated line
            if (deleteManifestLine) {
                for (Integer i = SOListWasteDisposal.size() - 1 ; i >= 0 ; i--){
                    if (SOListWasteDisposal[i].System_Calculated_Line__c){
                        manifestLineNumber = SOListWasteDisposal[i].Line_No__c; break;
                    }
                }
            }
        }
        List<Integer> removeIndex = new List<Integer>();
        if (objectType == 'SalesLine') {
            for (Integer i = 0; i < theSLList.size(); i++) {
                if (CompanyMgmt.zeroIfNull(theSLList[i].Line_No__c) == Decimal.valueOf(lineNo) && theSLList[i].Category__c == lineType) {
                    //theSLList.remove(i);
                    removeIndex.add(i);
                    finishedNormalDelete = true;
                    if (!deleteManifestLine) break;
                }
                if (deleteManifestLine && theSLList[i].Line_No__c == manifestLineNumber){
                    //theSLList.remove(i);
                    removeIndex.add(i);
                    deleteManifestLine = false;
                    if (finishedNormalDelete) break;
                }
            }
            // when remove a element from list the index of that list will decrease 1
            for (Integer i = 0; i < removeIndex.size(); i++) {
                Integer indexAdjust = i == 0 ? 0 : 1;
                theSLList.remove(removeIndex[i] - indexAdjust);
            }
        }
         */
        return null;
    }

    /*
     *  moved to lightning
     */
    public PageReference validateField() {
        /*
        setFieldNameCategoryMap();
        String fieldName = ApexPages.currentPage().getParameters().get('fieldName');
        Integer i = Integer.valueOf(ApexPages.currentPage().getParameters().get('lineNo'));
        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');
        String Category = '';
        if(theSO.Estimated_Job_Start_Date__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Estimated Job Start Date field must not be blank'));
            return null;
        }
        if (fieldName == 'theJobPositionINPT') {
            if (String.isBlank(newFieldValue)) {
                SOListLaborLines[i].Resource_Type__c = null;
                SOListLaborLines[i].Resource_Type__r = null;
                SOListLaborLines[i].Description__c = '';
                Decimal lineNo = SOListLaborLines[i].Line_No__c;
                SOListLaborLines[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListLaborLines[i].Resource_Type__c = newFieldValue;
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }

                SOListLaborLines[i].Quantity__c = 0;
                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theResourceType');
                SalesOrdersService.calcEstimatedDateInfo(theSO, new List<Sales_Line__c>{SOListLaborLines[i]}, SOListLaborLines[i].Number_of_Day__c.intValue());
                SalesLinesService.validateResourceType(theSO, SOListLaborLines[i]);
                //SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListLaborLines[i]}});
            }
            Category = 'Labor';
        } else if (fieldName == 'theEquipmentINPT') {
            if (String.isBlank(newFieldValue)) {
                SOListEquipmentLines[i].Resource_Type__c = null;
                SOListEquipmentLines[i].Resource_Type__r = null;
                SOListEquipmentLines[i].Description__c = '';
                Decimal lineNo = SOListEquipmentLines[i].Line_No__c;
                SOListEquipmentLines[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListEquipmentLines[i].Resource_Type__c = newFieldValue;

                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }

                SOListEquipmentLines[i].Quantity__c = 0;
                SOListEquipmentLines[i] = SalesOrderMgmt.updateSL(SOListEquipmentLines[i], theSO, 'theResourceType');
                SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListEquipmentLines[i]}});
            }
            Category = 'Equipment';
        } else if (fieldName == 'theMaterialINPT') {
            if (String.isBlank(newFieldValue)) {
                SOListMaterialLines[i].Resource__c = null;
                SOListMaterialLines[i].Resource__r = null;
                SOListMaterialLines[i].Description__c = '';
                Decimal lineNo = SOListMaterialLines[i].Line_No__c;
                SOListMaterialLines[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListMaterialLines[i].Resource__c = newFieldValue;

                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }

                SOListMaterialLines[i].Quantity__c = 0;
                SOListMaterialLines[i] = SalesOrderMgmt.updateSL(SOListMaterialLines[i], theSO, 'theMResource');
                SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListMaterialLines[i]}});
            }
            Category = 'Materials';
        } else if (fieldName == 'theLLUOM') {
            if (String.isBlank(newFieldValue)) {
                SOListLaborLines[i].Unit_of_Measure__c = null;
                SOListLaborLines[i].Unit_of_Measure__r = null;
                SOListLaborLines[i].Resource_Type_UOM__c = null;
                SOListLaborLines[i].Resource_Type_UOM__r = null;
            } else {
                List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                        ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeIdByUOMId(SOListLaborLines[i].Resource_Type__c, newFieldValue);
                System.debug('Info# ResourceTypeUOMAssociation__c ' + resourceTypeUOMAssociations);
                if(resourceTypeUOMAssociations.size() > 0){
                    //SOListLaborLines[i].Unit_of_Measure__c = newFieldValue;
                    SOListLaborLines[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id=resourceTypeUOMAssociations[0].Unit_of_Measure__c, Name=resourceTypeUOMAssociations[0].Unit_of_Measure__r.Name);
                    SOListLaborLines[i].Unit_of_Measure__c = resourceTypeUOMAssociations[0].Unit_of_Measure__c;
                    SOListLaborLines[i].Resource_Type_UOM__c = resourceTypeUOMAssociations[0].Id;
                    SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListLaborLines[i]}});
                } else {
                    SOListLaborLines[i].Unit_of_Measure__c = null;
                    SOListLaborLines[i].Resource_Type_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            Category = 'Labor';
        } else if (fieldName == 'theMLUOM') {
            if (String.isBlank(newFieldValue)) {
                SOListMaterialLines[i].Unit_of_Measure__c = null;
                SOListMaterialLines[i].Unit_of_Measure__r = null;
                SOListMaterialLines[i].Resource_UOM__c = null;
                SOListMaterialLines[i].Resource_UOM__r = null;
            } else {
                List<ResourceUOMAssociation__c> resourceUOMAssociations =
                        ResourceUnitOfMeasuresSelector.newInstance().selectByResByUOM(SOListMaterialLines[i].Resource__c, newFieldValue);
                System.debug('Info# ResourceTypeUOMAssociation__c ' + resourceUOMAssociations);
                if(resourceUOMAssociations.size() > 0){
                    //SOListLaborLines[i].Unit_of_Measure__c = newFieldValue;
                    SOListMaterialLines[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id=resourceUOMAssociations[0].Unit_of_Measure__c, Name=resourceUOMAssociations[0].Unit_of_Measure__r.Name);
                    SOListMaterialLines[i].Unit_of_Measure__c = resourceUOMAssociations[0].Unit_of_Measure__c;
                    SOListMaterialLines[i].Resource_UOM__c = resourceUOMAssociations[0].Id;
                    SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListMaterialLines[i]}});
                } else {
                    SOListMaterialLines[i].Unit_of_Measure__c = null;
                    SOListMaterialLines[i].Resource_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            Category = 'Materials';
        } else if (fieldName == 'theELUOM') {
            if (String.isBlank(newFieldValue)) {
                SOListEquipmentLines[i].Unit_of_Measure__c = null;
                SOListEquipmentLines[i].Unit_of_Measure__r = null;
                SOListEquipmentLines[i].Resource_Type_UOM__c = null;
                SOListEquipmentLines[i].Resource_Type_UOM__r = null;
            } else {
                List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                        ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeIdByUOMId(SOListEquipmentLines[i].Resource_Type__c, newFieldValue);
                System.debug('Info# ResourceTypeUOMAssociation__c ' + resourceTypeUOMAssociations);
                if(resourceTypeUOMAssociations.size() > 0){
                    //SOListLaborLines[i].Unit_of_Measure__c = newFieldValue;
                    SOListEquipmentLines[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id=resourceTypeUOMAssociations[0].Unit_of_Measure__c,
                            Name=resourceTypeUOMAssociations[0].Unit_of_Measure__r.Name);
                    SOListEquipmentLines[i].Unit_of_Measure__c = resourceTypeUOMAssociations[0].Unit_of_Measure__c;
                    SOListEquipmentLines[i].Resource_Type_UOM__c = resourceTypeUOMAssociations[0].Id;
                    SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListEquipmentLines[i]}});
                } else {
                    SOListEquipmentLines[i].Unit_of_Measure__c = null;
                    SOListEquipmentLines[i].Resource_Type_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            Category = 'Equipment';
        } else if (fieldName == 'theLumpUOM') {
            if (String.isBlank(newFieldValue)) {
                theSOListLumpSum[i].Unit_of_Measure__c = null;
                theSOListLumpSum[i].Unit_of_Measure__r = null;
                theSOListLumpSum[i].Resource_Type_UOM__c = null;
                theSOListLumpSum[i].Resource_Type_UOM__r = null;
            } else {
                List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                        ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeIdByUOMId(theSOListLumpSum[i].Resource_Type__c, newFieldValue);
                System.debug('Info# ResourceTypeUOMAssociation__c ' + resourceTypeUOMAssociations);
                if(resourceTypeUOMAssociations.size() > 0){
                    //SOListLaborLines[i].Unit_of_Measure__c = newFieldValue;
                    theSOListLumpSum[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id=resourceTypeUOMAssociations[0].Unit_of_Measure__c,
                            Name=resourceTypeUOMAssociations[0].Unit_of_Measure__r.Name);
                    theSOListLumpSum[i].Unit_of_Measure__c = resourceTypeUOMAssociations[0].Unit_of_Measure__c;
                    theSOListLumpSum[i].Resource_Type_UOM__c = resourceTypeUOMAssociations[0].Id;
                    SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{theSOListLumpSum[i]}});
                } else {
                    theSOListLumpSum[i].Unit_of_Measure__c = null;
                    theSOListLumpSum[i].Resource_Type_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            Category = 'Lump Sum';
        } else if (fieldName == 'theMiscUOM') {
            if (String.isBlank(newFieldValue)) {
                SOListMisc[i].Unit_of_Measure__c = null;
                SOListMisc[i].Unit_of_Measure__r = null;
            } else {
                SOListMisc[i].Unit_of_Measure__c = newFieldValue;
                SOListMisc[i] = SalesOrderMgmt.updateSL(SOListMisc[i], theSO, 'theUOM');
            }
            Category = 'Misc. Charges And Taxes';
            // Ticket #13610
        } else if (fieldName == 'theMiscResource') { //Ticket#13810
            if (String.isBlank(newFieldValue)) {
                SOListMisc[i].Resource__c = null;
                SOListMisc[i].Resource__r = null;
                SOListMisc[i].Description__c = '';
                Decimal lineNo = SOListMisc[i].Line_No__c;
                SOListMisc[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListMisc[i].Resource__c = newFieldValue;

                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }

                SOListMisc[i].Quantity__c = 0;
                SOListMisc[i] = SalesOrderMgmt.updateSL(SOListMisc[i], theSO, 'theResource');
            }
            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theDUOM') {
            if (String.isBlank(newFieldValue)) {
                SOListDemurrage[i].Unit_of_Measure__c = null;
                SOListDemurrage[i].Unit_of_Measure__r = null;
                SOListDemurrage[i].Resource_UOM__c = null;
                SOListDemurrage[i].Resource_UOM__r = null;
            } else {
                List<ResourceUOMAssociation__c> resourceUOMAssociations =
                        ResourceUnitOfMeasuresSelector.newInstance().selectByResByUOM(SOListDemurrage[i].Resource__c, newFieldValue);
                if(resourceUOMAssociations.size() > 0){
                    SOListDemurrage[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id=resourceUOMAssociations[0].Unit_of_Measure__c, Name=resourceUOMAssociations[0].Unit_of_Measure__r.Name);
                    SOListDemurrage[i].Unit_of_Measure__c = resourceUOMAssociations[0].Unit_of_Measure__c;
                    SOListDemurrage[i].Resource_UOM__c = resourceUOMAssociations[0].Id;
                    SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListDemurrage[i]}});
                } else {
                    SOListDemurrage[i].Unit_of_Measure__c = null;
                    SOListDemurrage[i].Resource_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            Category = 'Demurrage';
        } else if (fieldName == 'theWUOM') {
            if (String.isBlank(newFieldValue)) {
                SOListWasteDisposal[i].Unit_of_Measure__c = null;
                SOListWasteDisposal[i].Unit_of_Measure__r = null;
                SOListWasteDisposal[i].Resource_UOM__c = null;
                SOListWasteDisposal[i].Resource_UOM__r = null;
            } else {
                List<ResourceUOMAssociation__c> resourceUOMAssociations =
                        ResourceUnitOfMeasuresSelector.newInstance().selectByResByUOM(SOListWasteDisposal[i].Resource__c, newFieldValue);
                if(resourceUOMAssociations.size() > 0){
                    SOListWasteDisposal[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id=resourceUOMAssociations[0].Unit_of_Measure__c, Name=resourceUOMAssociations[0].Unit_of_Measure__r.Name);
                    SOListWasteDisposal[i].Unit_of_Measure__c = resourceUOMAssociations[0].Unit_of_Measure__c;
                    SOListWasteDisposal[i].Resource_UOM__c = resourceUOMAssociations[0].Id;
                    SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListWasteDisposal[i]}});
                } else {
                    SOListWasteDisposal[i].Unit_of_Measure__c = null;
                    SOListWasteDisposal[i].Resource_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource.'));
                    return null;
                }
            }
            Category = 'Waste Disposal';
        } else if (fieldName == 'theSResource') {
            if (String.isBlank(newFieldValue)) {
                Decimal lineNo = SOListSubContractorLines[i].Line_No__c;
                SOListSubContractorLines[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListSubContractorLines[i].Resource__c = newFieldValue;
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }

                SOListSubContractorLines[i].Quantity__c = 0;
                SOListSubContractorLines[i] = SalesOrderMgmt.updateSL(SOListSubContractorLines[i], theSO, 'theSResource');
            }
            Category = 'Subcontractors';
        } else if (fieldName == 'theDResource') { //W-000021
            if (String.isBlank(newFieldValue)) {
                SOListDemurrage[i].Resource__c = null;
                SOListDemurrage[i].Resource__r = null;
                Decimal lineNo = SOListDemurrage[i].Line_No__c;
                SOListDemurrage[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListDemurrage[i].Resource__c = newFieldValue;
                    SOListDemurrage[i].Quantity__c = 1;
                    SOListDemurrage[i] = SalesOrderMgmt.updateSL(SOListDemurrage[i], theSO, 'theResource');
                    SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListDemurrage[i]}});
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Demurrage';
        }
        else if (fieldName == 'theWResource') { // Ticket# 14398
            if (String.isBlank(newFieldValue)) {
                SOListWasteDisposal[i].Resource__c = null;
                SOListWasteDisposal[i].Resource__r = null;
                Decimal lineNo = SOListWasteDisposal[i].Line_No__c;
                SOListWasteDisposal[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListWasteDisposal[i].Resource__c = newFieldValue;
                    SOListWasteDisposal[i] = SalesOrderMgmt.updateSL(SOListWasteDisposal[i], theSO, 'theResource');

                    if (theSO.Manifest_And_Profile__c) { // W-000237
                        SalesOrdersService.createManifestFeeLines(theSO, theSLList);
                    }

                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Waste Disposal';
        } else if (fieldName == 'theLContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                SOListLaborLines[i].Contract_Line__c = null;
                SOListLaborLines[i].Contract_Line__r = null;
                SOListLaborLines[i].Contract_Regular_Rate__c = 0;
                Decimal lineNo = SOListLaborLines[i].Line_No__c;
                SOListLaborLines[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListLaborLines[i].Contract_Line__c = newFieldValue;
                    SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theLContractLine');

                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Labor';
        } else if (fieldName == 'theEContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                SOListEquipmentLines[i].Contract_Line__c = null;
                SOListEquipmentLines[i].Contract_Line__r = null;
                SOListEquipmentLines[i].Contract_Regular_Rate__c = 0;
                Decimal lineNo = SOListEquipmentLines[i].Line_No__c;
                SOListEquipmentLines[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListEquipmentLines[i].Contract_Line__c = newFieldValue;
                    SOListEquipmentLines[i] = SalesOrderMgmt.updateSL(SOListEquipmentLines[i], theSO, 'theEContractLine');

                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Equipment';
        } else if (fieldName == 'theMContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                SOListMaterialLines[i].Contract_Line__c = null;
                SOListMaterialLines[i].Contract_Line__r = null;
                SOListMaterialLines[i].Contract_Regular_Rate__c = 0;
                Decimal lineNo = SOListMaterialLines[i].Line_No__c;
                SOListMaterialLines[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    SOListMaterialLines[i].Contract_Line__c = newFieldValue;
                    SOListMaterialLines[i] = SalesOrderMgmt.updateSL(SOListMaterialLines[i], theSO, 'theMContractLine');
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }

            }
            Category = 'Materials';
        } else if (fieldName == 'theLQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Quantity__c = 0;
                } else {
                    SOListLaborLines[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theQuantity');
                // W-000391
                SalesLinesService.calcLaborUnitPrice(theSO, SOListLaborLines[i]);
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListLaborLines[i]}});
                // W-000391

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theLUOMQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].UOM_Qty__c = 0;
                } else {
                    SOListLaborLines[i].UOM_Qty__c = decimal.valueOf(newFieldValue);
                    SOListLaborLines[i].Regular_Hours__c = decimal.valueOf(newFieldValue); //Ticket# 414
                }

                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theQuantity');
                // W-000391
                SalesLinesService.calcLaborUnitPrice(theSO, SOListLaborLines[i]);
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListLaborLines[i]}});
                // W-000391

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theEQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListEquipmentLines[i].Quantity__c = 0;
                } else {
                    SOListEquipmentLines[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                SOListEquipmentLines[i] = SalesOrderMgmt.updateSL(SOListEquipmentLines[i], theSO, 'theQuantity');
                // W-000391
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListEquipmentLines[i]}});

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theEUOMQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListEquipmentLines[i].UOM_Qty__c = 0;
                } else {
                    SOListEquipmentLines[i].UOM_Qty__c = decimal.valueOf(newFieldValue);
                }

                SOListEquipmentLines[i] = SalesOrderMgmt.updateSL(SOListEquipmentLines[i], theSO, 'theQuantity');

                // W-000391
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListEquipmentLines[i]}});

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theMQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListMaterialLines[i].Quantity__c = 0;
                } else {
                    SOListMaterialLines[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                SOListMaterialLines[i] = SalesOrderMgmt.updateSL(SOListMaterialLines[i], theSO, 'theQuantity');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Materials';
        } else if (fieldName == 'theMiscQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListMisc[i].Quantity__c = 0;
                } else {
                    SOListMisc[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                SOListMisc[i] = SalesOrderMgmt.updateSL(SOListMisc[i], theSO, 'theQuantity');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theWQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListWasteDisposal[i].Quantity__c = 0;
                } else {
                    SOListWasteDisposal[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{
                        theSO => new List<Sales_Line__c>{theSOListWasteDisposal[i]}});
                //SOListWasteDisposal[i] = SalesOrderMgmt.updateSL(SOListWasteDisposal[i], theSO, 'theQuantity');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theDQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListDemurrage[i].Quantity__c = 0;
                } else {
                    SOListDemurrage[i].Quantity__c = Decimal.valueOf(newFieldValue);
                }

                SOListDemurrage[i] = SalesOrderMgmt.updateSL(SOListDemurrage[i], theSO, 'theQuantity');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Demurrage';
        } else if (fieldName == 'theSQuantity') { //Ticket# 14037 AES-408
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListSubContractorLines[i].Quantity__c = 0;
                } else {
                    SOListSubContractorLines[i].Quantity__c = Decimal.valueOf(newFieldValue);
                }

                SOListSubContractorLines[i] = SalesOrderMgmt.updateSL(SOListSubContractorLines[i], theSO, 'theQuantity');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theSMarkup') { //Ticket# 14037 AES-408
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListSubContractorLines[i].Markup__c = 0;
                } else {
                    SOListSubContractorLines[i].Markup__c = Decimal.valueOf(newFieldValue);
                }

                SOListSubContractorLines[i] = SalesOrderMgmt.updateSL(SOListSubContractorLines[i], theSO, 'theMarkup');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theSMarkupOption') { //Ticket# 14037 AES-408
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListSubContractorLines[i].Markup_Option__c = '';
                } else {
                    SOListSubContractorLines[i].Markup_Option__c = newFieldValue;
                }

                SOListSubContractorLines[i] = SalesOrderMgmt.updateSL(SOListSubContractorLines[i], theSO, 'theMarkupOption');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theLTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Tax_Group__c = '';
                } else {
                    SOListLaborLines[i].Tax_Group__c = newFieldValue;
                }
                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theTaxGroup');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theETaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListEquipmentLines[i].Tax_Group__c = '';
                } else {
                    SOListEquipmentLines[i].Tax_Group__c = newFieldValue;
                }
                SOListEquipmentLines[i] = SalesOrderMgmt.updateSL(SOListEquipmentLines[i], theSO, 'theTaxGroup');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theMTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListMaterialLines[i].Tax_Group__c = '';
                } else {
                    SOListMaterialLines[i].Tax_Group__c = newFieldValue;
                }
                SOListMaterialLines[i] = SalesOrderMgmt.updateSL(SOListMaterialLines[i], theSO, 'theTaxGroup');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Materials';
        } else if (fieldName == 'theSTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSOListSubcontractors[i].Tax_Group__c = '';
                } else {
                    theSOListSubcontractors[i].Tax_Group__c = newFieldValue;
                }
                theSOListSubcontractors[i] = SalesOrderMgmt.updateSL(theSOListSubcontractors[i], theSO, 'theTaxGroup');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Subcontractors';
        } else if (fieldName == 'theMiscTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListMisc[i].Tax_Group__c = '';
                } else {
                    SOListMisc[i].Tax_Group__c = newFieldValue;
                }
                SOListMisc[i] = SalesOrderMgmt.updateSL(SOListMisc[i], theSO, 'theTaxGroup');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theLUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Unit_Price__c = 0;
                } else {
                    SOListLaborLines[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theUnitPrice');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theRegularRate') { //Ticket# AES-407
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Regular_Rate__c = 0;
                    SOListLaborLines[i].Overtime_Rate__c = 0;
                    SOListLaborLines[i].Premium_Rate__c = 0;

                } else {
                    SOListLaborLines[i].Regular_Rate__c = decimal.valueOf(newFieldValue);
                    SOListLaborLines[i].Overtime_Rate__c = decimal.valueOf(newFieldValue) * CompanySetup.T_M_Overtime_Multiplier__c;
                    SOListLaborLines[i].Premium_Rate__c = decimal.valueOf(newFieldValue) * CompanySetup.T_M_Premium_Multiplier__c;
                }
                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theRegularRate');
                SalesLinesService.calcLaborUnitPrice(theSO, theSOLineLaborList[i]);
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{
                        theSO => new List<Sales_Line__c>{theSOLineLaborList[i]}});


            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theOvertimeRate') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Overtime_Rate__c = 0;
                } else {
                    SOListLaborLines[i].Overtime_Rate__c = decimal.valueOf(newFieldValue);
                }
                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theOvertimeRate');
                SalesLinesService.calcLaborUnitPrice(theSO, theSOLineLaborList[i]);
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{
                        theSO => new List<Sales_Line__c>{theSOLineLaborList[i]}});

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'thePremiumRate') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Premium_Rate__c = 0;
                } else {
                    SOListLaborLines[i].Premium_Rate__c = decimal.valueOf(newFieldValue);
                }
                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'thePremiumRate');
                SalesLinesService.calcLaborUnitPrice(theSO, theSOLineLaborList[i]);
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{
                        theSO => new List<Sales_Line__c>{theSOLineLaborList[i]}});

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theRegularHours') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Regular_Hours__c = 0;
                } else {
                    SOListLaborLines[i].Regular_Hours__c = decimal.valueOf(newFieldValue);
                }
                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theRegularHours');

                SalesLinesService.calcLaborUnitPrice(theSO, theSOLineLaborList[i]);
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListLaborLines[i]}});
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theOvertimeHours') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Overtime_Hours__c = 0;
                } else {
                    SOListLaborLines[i].Overtime_Hours__c = decimal.valueOf(newFieldValue);
                }
                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theOvertimeHours');
                SalesLinesService.calcLaborUnitPrice(theSO, theSOLineLaborList[i]);
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListLaborLines[i]}});
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'thePremiumHours') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Premium_Hours__c = 0;
                } else {
                    SOListLaborLines[i].Premium_Hours__c = decimal.valueOf(newFieldValue);
                }
                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'thePremiumHours');
                SalesLinesService.calcLaborUnitPrice(theSO, theSOLineLaborList[i]);
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{SOListLaborLines[i]}});
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';   //Ticket# AES-407
        } else if (fieldName == 'theLBillasLumpSum') { //Ticket#14204 AES-431
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Bill_as_Lump_Sum__c = false;
                } else {
                    SOListLaborLines[i].Bill_as_Lump_Sum__c = Boolean.valueOf(newFieldValue);
                }

                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, 'theLBillasLumpSum');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theLNonBillable') { //Ticket#13673
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListLaborLines[i].Non_Billable__c = false;
                } else {
                    SOListLaborLines[i].Non_Billable__c = Boolean.valueOf(newFieldValue);
                }

                SOListLaborLines[i] = SalesOrderMgmt.updateSL(SOListLaborLines[i], theSO, fieldName);

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theEBillasLumpSum') { //Ticket#14204 AES-431
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListEquipmentLines[i].Bill_as_Lump_Sum__c = false;
                } else {
                    SOListEquipmentLines[i].Bill_as_Lump_Sum__c = Boolean.valueOf(newFieldValue);
                }

                SOListEquipmentLines[i] = SalesOrderMgmt.updateSL(SOListEquipmentLines[i], theSO, 'theEBillasLumpSum');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theENonBillable') { //Ticket#13673
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListEquipmentLines[i].Non_Billable__c = false;
                } else {
                    SOListEquipmentLines[i].Non_Billable__c = Boolean.valueOf(newFieldValue);
                }

                SOListEquipmentLines[i] = SalesOrderMgmt.updateSL(SOListEquipmentLines[i], theSO, fieldName);

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theMBillasLumpSum' || fieldName == 'theSBillasLumpSum' || fieldName == 'theWBillasLumpSum' ||
                fieldName == 'theDBillasLumpSum' || fieldName == 'theMiscBillasLumpSum') {
            try {

                Category = fieldNameCategoryMap.get(fieldName);
                Boolean isChecked = false;

                if (String.isNotBlank(newFieldValue)) {
                    // isChecked = true;  // 14522 This line doesn't make sense
                    isChecked = Boolean.valueOf(newFieldValue);
                }

                switch on Category {
                    when 'Subcontractors' {
                        theSOListSubcontractors[i].Bill_as_Lump_Sum__c = isChecked;
                        theSOListSubcontractors[i] = SalesOrderMgmt.updateSL(theSOListSubcontractors[i], theSO, fieldName);
                    }
                    when 'Waste Disposal' {
                        theSOListWasteDisposal[i].Bill_as_Lump_Sum__c = isChecked;
                        theSOListWasteDisposal[i] = SalesOrderMgmt.updateSL(theSOListWasteDisposal[i], theSO, fieldName);
                    }
                    when 'Demurrage' {
                        SOListDemurrage[i].Bill_as_Lump_Sum__c = isChecked;
                        SOListDemurrage[i] = SalesOrderMgmt.updateSL(SOListDemurrage[i], theSO, fieldName);
                    }
                    when 'Misc. Charges And Taxes' {
                        theSOListMisc[i].Bill_as_Lump_Sum__c = isChecked;
                        theSOListMisc[i] = SalesOrderMgmt.updateSL(theSOListMisc[i], theSO, fieldName);
                    }
                    when 'Materials' {
                        SOListMaterialLines[i].Bill_as_Lump_Sum__c = isChecked;
                        SOListMaterialLines[i] = SalesOrderMgmt.updateSL(SOListMaterialLines[i], theSO, fieldName);
                    }
                }

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

        } else if (fieldName == 'theMNonBillable' || fieldName == 'theSNonBillable' || fieldName == 'theWNonBillable' ||
                fieldName == 'theDNonBillable' || fieldName == 'theMiscNonBillable') {
            try {
                Category = fieldNameCategoryMap.get(fieldName);
                Boolean isChecked = false;

                if (String.isNotBlank(newFieldValue)) {
                    //isChecked = true; // 14522
                    isChecked = Boolean.valueOf(newFieldValue);
                }

                switch on Category {
                    when 'Subcontractors' {
                        theSOListSubcontractors[i].Non_Billable__c = isChecked;
                        theSOListSubcontractors[i] = SalesOrderMgmt.updateSL(theSOListSubcontractors[i], theSO, fieldName);
                    }
                    when 'Waste Disposal' {
                        theSOListWasteDisposal[i].Non_Billable__c = isChecked;
                        theSOListWasteDisposal[i] = SalesOrderMgmt.updateSL(theSOListWasteDisposal[i], theSO, fieldName);
                    }
                    when 'Demurrage' {
                        SOListDemurrage[i].Non_Billable__c = isChecked;
                        SOListDemurrage[i] = SalesOrderMgmt.updateSL(SOListDemurrage[i], theSO, fieldName);
                    }
                    when 'Misc. Charges And Taxes' {
                        theSOListMisc[i].Non_Billable__c = isChecked;
                        theSOListMisc[i] = SalesOrderMgmt.updateSL(theSOListMisc[i], theSO, fieldName);
                    }
                    when 'Materials' {
                        SOListMaterialLines[i].Non_Billable__c = isChecked;
                        SOListMaterialLines[i] = SalesOrderMgmt.updateSL(SOListMaterialLines[i], theSO, fieldName);
                    }
                }

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
        } else if (fieldName == 'theEUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListEquipmentLines[i].Unit_Price__c = 0;
                } else {
                    SOListEquipmentLines[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                SOListEquipmentLines[i] = SalesOrderMgmt.updateSL(SOListEquipmentLines[i], theSO, 'theUnitPrice');
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{
                        theSO => new List<Sales_Line__c>{SOListEquipmentLines[i]}});
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theMUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListMaterialLines[i].Unit_Price__c = 0;
                } else {
                    SOListMaterialLines[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                SOListMaterialLines[i] = SalesOrderMgmt.updateSL(SOListMaterialLines[i], theSO, 'theUnitPrice');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Materials';
        } else if (fieldName == 'theSUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSOListSubcontractors[i].Unit_Price__c = 0;
                } else {
                    theSOListSubcontractors[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSOListSubcontractors[i] = SalesOrderMgmt.updateSL(theSOListSubcontractors[i], theSO, 'theUnitPrice');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theWUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSOListWasteDisposal[i].Unit_Price__c = 0;
                } else {
                    theSOListWasteDisposal[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }

                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{
                        theSO => new List<Sales_Line__c>{theSOListWasteDisposal[i]}});

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theMiscUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSOListMisc[i].Unit_Price__c = 0;
                } else {
                    theSOListMisc[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSOListMisc[i] = SalesOrderMgmt.updateSL(theSOListMisc[i], theSO, 'theUnitPrice');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theDUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    SOListDemurrage[i].Unit_Price__c = 0;
                } else {
                    SOListDemurrage[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                SOListDemurrage[i] = SalesOrderMgmt.updateSL(SOListDemurrage[i], theSO, 'theUnitPrice');
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Demurrage';
        } else if (fieldName == 'theLumpSumResourceType') {
            if (String.isBlank(newFieldValue)) {
                theSOListLumpSum[i].Resource_Type__c = null;
                theSOListLumpSum[i].Resource_Type__r = null;
                theSOListLumpSum[i].Description__c = '';
                Decimal lineNo = theSOListLumpSum[i].Line_No__c;
                theSOListLumpSum[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    theSOListLumpSum[i].Resource_Type__c = newFieldValue;
                    theSOListLumpSum[i].Quantity__c = 0;
                    theSOListLumpSum[i] = SalesOrderMgmt.updateSL(theSOListLumpSum[i], theSO, 'theResourceType');
                    SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{theSO => new List<Sales_Line__c>{theSOListLumpSum[i]}});
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Lump Sum';
        } else if (fieldName == 'theLumpQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSOListLumpSum[i].Quantity__c = 0;
                } else {
                    theSOListLumpSum[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theSOListLumpSum[i] = SalesOrderMgmt.updateSL(theSOListLumpSum[i], theSO, 'theQuantity');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Lump Sum';
        } else if (fieldName == 'theLumpUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSOListLumpSum[i].Unit_Price__c = 0;
                } else {
                    theSOListLumpSum[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theSOListLumpSum[i] = SalesOrderMgmt.updateSL(theSOListLumpSum[i], theSO, 'theUnitPrice');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Lump Sum';
        } else if (fieldName == 'theLumpTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theSOListLumpSum[i].Tax_Group__c = '';
                } else {
                    theSOListLumpSum[i].Tax_Group__c = newFieldValue;
                }
                theSOListLumpSum[i] = SalesOrderMgmt.updateSL(theSOListLumpSum[i], theSO, 'theTaxGroup');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Lump Sum';
        } else if (fieldName == 'theLumpSumContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                theSOListLumpSum[i].Contract_Line__c = null;
                theSOListLumpSum[i].Contract_Line__r = null;
                theSOListLumpSum[i].Contract_Regular_Rate__c = 0;
                Decimal lineNo = theSOListLumpSum[i].Line_No__c;
                theSOListLumpSum[i] = new Sales_Line__c(Sales_Order__c = orderId, Line_No__c = lineNo);
            } else {
                try {
                    theSOListLumpSum[i].Contract_Line__c = newFieldValue;
                    theSOListLumpSum[i] = SalesOrderMgmt.updateSL(theSOListLumpSum[i], theSO, 'theLumpSumContractLine');
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Lump Sum';
        } else if (fieldName == 'theSCUnitCost'){ //Ticket#14646
            try{
                theSOListSubcontractors[i] = SalesOrderMgmt.updateSL(theSOListSubcontractors[i], theSO, 'UnitCost');
            } catch (Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            Category = 'Subcontractors';
        } else if (fieldName == 'theWContainerSize'){
            if(String.isBlank(newFieldValue)){
                theSOListWasteDisposal[i].Container_Size__c = null;
                theSOListWasteDisposal[i].Container_Size__r = null;
            } else {
                theSOListWasteDisposal[i].Container_Size__c = newFieldValue;
                List<Unit_of_Measure__c> uoms = UnitOfMeasuresSelector.newInstance().selectSObjectsById(new Set<Id>{newFieldValue});
                theSOListWasteDisposal[i].Container_Size__r = new Unit_of_Measure__c(Id = uoms[0].Id, Name = uoms[0].Name);
            }

            SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{
                    theSO => new List<Sales_Line__c>{theSOListWasteDisposal[i]}});


            Category = 'Waste Disposal';
        } else if (fieldName == 'theWUnitVol'){
            if(String.isBlank(newFieldValue)){
                theSOListWasteDisposal[i].Unit_Weight_Vol__c = null;
                theSOListWasteDisposal[i].Unit_Weight_Vol__r = null;
            } else {
                theSOListWasteDisposal[i].Unit_Weight_Vol__c = newFieldValue;
                List<Unit_of_Measure__c> uoms = UnitOfMeasuresSelector.newInstance().selectSObjectsById(new Set<Id>{newFieldValue});
                theSOListWasteDisposal[i].Unit_Weight_Vol__r = new Unit_of_Measure__c(Id = uoms[0].Id, Name = uoms[0].Name);
            }

            SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{
                    theSO => new List<Sales_Line__c>{theSOListWasteDisposal[i]}});


            Category = 'Waste Disposal';
        } else if (fieldName == 'theWCostMethod'){
            SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{
                    theSO => new List<Sales_Line__c>{theSOListWasteDisposal[i]}});

            Category = 'Waste Disposal';
        } else if (fieldName == 'theWFacility'){

            System.debug('Info: theWFacility ' + newFieldValue);
            if(String.isBlank(newFieldValue)){
                theSOListWasteDisposal[i].Facility__c = null;
                theSOListWasteDisposal[i].Facility__c = null;
            } else {
                theSOListWasteDisposal[i].Facility__c = newFieldValue;
                List<Facility__c> facilities = FacilitiesSelector.newInstance().selectById(new Set<Id>{newFieldValue});
                theSOListWasteDisposal[i].Facility__r = new Facility__c(Id = facilities[0].Id, Name = facilities[0].Name);
            }

            SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{
                    theSO => new List<Sales_Line__c>{theSOListWasteDisposal[i]}});

            Category = 'Waste Disposal';
        } else if (fieldName == 'theWUnitCost'){
            try {
                theSOListWasteDisposal[i] = SalesOrderMgmt.updateSL(theSOListWasteDisposal[i], theSO, 'UnitCost');
                theSOListWasteDisposal[i].Manually_Entered_Cost__c = true;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            Category = 'Waste Disposal';
        } else if (fieldName == 'laborDaysNeeded'){
            try{
                SalesOrdersService.calcEstimatedDateInfo(theSO, new List<Sales_Line__c>{theSOLineLaborList[i]}, Integer.valueOf(newFieldValue));
                SalesLinesService.calcLaborUnitPrice(theSO, theSOLineLaborList[i]);
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{
                        theSO => new List<Sales_Line__c>{theSOLineLaborList[i]}});
            } catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            Category = 'Labor';
        } else if (fieldName == 'equipmentDaysNeeded'){
            try{
                SalesLinesService.updateTotals(new Map<Sales_Order__c, List<Sales_Line__c>>{
                        theSO => new List<Sales_Line__c>{SOListEquipmentLines[i]}});
            } catch(Exception e){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            Category = 'Equipment';
        }

        if (Category == 'Labor') {
            CalculateTotalLabor();
            CalculateTotalOrder();
        }
        if (Category == 'Equipment') {
            CalculateTotalEquipment();
            CalculateTotalOrder();
        }
        if (Category == 'Materials') {
            CalculateTotalMaterials();
            CalculateTotalOrder();
        }
        if (Category == 'Subcontractors') {
            CalculateTotalSubcontractors();
            CalculateTotalOrder();
        }
        if (Category == 'Waste Disposal') {
            CalculateTotalWasteDisposal();
            CalculateTotalOrder();
        }
        if (Category == 'Lump Sum') {
            CalculateTotalLumpSum();
            CalculateTotalOrder();
        }
        if (Category == 'Misc. Charges And Taxes') {
            CalculateTotalMisc();
            CalculateTotalOrder();
        }
        if (Category == 'Demurrage') {
            CalculateTotalDemurrage();
            CalculateTotalOrder();
        }
        */
        return null;
    }

    //Not needed
    //Method to identify Actual row in main for specific Category
    public Integer getIndex(List<Sales_Line__c> SalesLineList, String Type, Integer Index) {
        Integer row = 0;
        /*
        Integer Arow = 0;
        for (Sales_Line__c SL : SalesLineList) {
            if (SL.Category__c == Type) {
                if (Arow == Index) Break;
                Arow++;
            }
            row++;
        }
         */
        return row;
    }

    //Depreciated
    public PageReference createTemporaryTmList() {
        /*
        Integer i = 0;
        Integer j = 0;
        Date startingDate = Date.parse(startingDateValue);
        Date endingDate = Date.parse(endingDateValue);
        String day;
        DateTime tmDate;
        theTMWrapList = new List<TMWrap>();

        Integer noOfDays = startingDate.daysBetween(endingDate);

        if (noOfDays > maxDaysToCreateTM) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Days between Starting Date and Ending Date cannot be more than ' + maxDaysToCreateTM + ' days.')); return null;
        }

        if (tmCount > maxTMCopiesPerDay) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No. of T&M Per Day cannot be more than ' + maxTMCopiesPerDay + ' days.')); return null;
        }

        //Ticket#13488 >>
        List<TM__c> existingTMs = [SELECT Id, Sales_Order__c FROM TM__c WHERE Sales_Order__c = :theSO.Id];
        Integer existingTMSize = existingTMs.size();
        //Ticket#13488 <<
        for (i = 1; i <= noOfDays + 1; i++) {
            tmDate = startingDate.addDays(i);
            tmDate = CompanyMgmt.convertLocalDatetime(tmDate);
            day = tmDate.format('EEEE');
            if ((day != 'Saturday' && day != 'Sunday' && !includeWeekend) || includeWeekend) {
                //Ticket#13488 >>
                existingTMSize += 1;
                //Ticket#13488 <<
                for (j = 1; j <= tmCount; j++) {
                    theTMWrapList.add(new TMWrap(
                            date.valueOf(tmDate),
                            'Day of Job ' + existingTMSize + ' ' + theSO.Bill_to_Customer_No__r.Name,
                            theSO.Site_Scope__c
                    ));
                }
            }
        }
        */
        return null;
    }

    //Depreciated
    public PageReference CreateTM() {
        /*
        List<TM__c> theTMList = new List<TM__c>();
        List<TM_Line__c> theTMLineList = new List<TM_Line__c>();
        TM__c theTM;
        TM_Line__c theTML;

        //Ticket# 13424 >>
        //Savepoint
        Savepoint sp = Database.setSavepoint();
        //Ticket# 13424 <<

        try {
            if(theSO.Service_Center__r.Blocked__c == true){
                throw new DataException('Service center ' + theSO.Service_Center__r.Name + ' is deactivated!');
            }

            List<TM__c> existingTMs = [SELECT Id, Sales_Order__c FROM TM__c WHERE Sales_Order__c = :theSO.Id];
            Integer existingTMSize = existingTMs.size();

            if (theSO.Bill_to_Customer_No__r.Emergency__c == true &&
                    String.isBlank(theSO.Bill_to_Customer_No__r.AccountNumber)) {
                if (Integer.valueOf(CompanyMgmt.zeroIfNull(theCompanySetup.Max_T_M_for_not_Approved_Customer__c))
                        < Integer.valueOf(existingTMSize + theTMWrapList.size())) {
                    throw new DataException('You have exceeded the number of Emergency T&Ms. This customer is not approved. Please contact Accounts Receivable');
                }
            }

            if (theSO.Bill_to_Customer_No__r.Emergency__c == false &&
                    String.isBlank(theSO.Bill_to_Customer_No__r.AccountNumber)) {
                throw new DataException('This customer is not approved. Please contact Accounts Receivable');
            }

            //Ticket#13807 AES-394<<
            for (Integer i = 0; i < theTMWrapList.size(); i++) {
                theTM = new TM__c();
                theTM.Bill_to_Customer__c = theSO.Bill_to_Customer_No__c;
                theTM.Contact__c = theSO.Bill_to_Contact__c;
                theTM.Site_Contact_2__c = theSO.Site_Contact_2__c; //AES-401,Ticket#14009
                theTM.Sales_Order__c = theSO.Id;
                theTM.Project_Coordinator__c = theSO.Project_Coordinator__c;
                theTM.Account_Executive__c = theSO.Account_Executives__c;
                theTM.Prevailing_Wage_Job__c = theSO.Prevailing_Wage_Job__c;
                theTM.Certified_PW_Job__c = theSO.Certified_PW_Job__c;
                theTM.Subsidiary_Company__c = theSO.Subsidiary_Company__c;
                theTM.Service_Center__c = theSO.Service_Center__c;
                theTM.Desired_Scheduled_Date__c = theTMWrapList[i].scheduledDate;
                theTM.Description__c = theTMWrapList[i].description;
                theTM.Contract__c = theSO.Contract__c;
                theTM.Customer_PO_No__c = theSO.Customer_PO_No__c;
                theTM.Status__c = 'Open';
                theTM.Alternate_Site_Address__c = theSO.Alternate_Site_Address__c;
                theTM.Site_Name__c = theSO.Site_Name__c;
                theTM.Site_Street__c = theSO.Site_Street__c;
                theTM.Site_City__c = theSO.Site_City__c;
                theTM.Site_State__c = theSO.Site_State__c;
                theTM.Site_Postal_Code__c = theSO.Site_Postal_Code__c;//Ticket#13730
                theTM.Site_Country__c = theSO.Site_Country__c;
                theTM.Site_Contact__c = theSO.Site_Contact__c;
                theTM.Site_Phone_No__c = theSO.Site_Phone_No__c;
                theTM.Site_Email_Address__c = theSO.Site_Email_Address__c;
                theTM.Tax_Liable__c = theSO.Tax_Liable__c;
                theTM.Tax_Area__c = theSO.Tax_Area__c;
                theTM.Site_Scope__c = theTMWrapList[i].siteScope;
                theTM.From_Sales_Quote__c = theSO.From_Sales_Quote__c;
                theTM.Print_Site_Name__c = theSO.Print_Site_Name__c;
                theTM.Billing_Instructions__c = theSO.Billing_Instructions__c;
                theTM.Internal_Comments__c = theSO.Internal_Comments__c; // 14554
                theTM.Customer_Billing_Instructions__c = theSO.Customer_Billing_Instructions__c;
                theTM.Sales_Order_Instructions__c = theSO.Sales_Order_Instructions__c;
                theTM.Rate_Sheet__c = theSO.Rate_Sheet__c;
                theTMList.add(theTM);
            }

            insert theTMList;

            if (theSLList != null && theSLList.size() > 0) {
                Set<Id> setResource = new Set<Id>();
                Set<Id> setResourceType = new Set<Id>();
                Set<Id> setCL = new Set<Id>();
                Set<Id> setUOM = new Set<Id>();
                Set<String> setTaxGroup = new Set<String>();
                List<Contract_Line__c> theCLList = new List<Contract_Line__c>();
                String theKey = '';

                for (Sales_Line__c SL : theSLList) {
                    if (SL.Resource__c != null) {
                        setResource.add(SL.Resource__c);
                    }

                    if (SL.Resource_Type__c != null) {
                        setResourceType.add(SL.Resource_Type__c);
                    }

                    if (SL.Contract_Line__c != null) {
                        setCL.add(SL.Contract_Line__c);
                    }

                    if (SL.Unit_of_Measure__c != null) {
                        setUOM.add(SL.Unit_of_Measure__c);
                    }
                    if (SL.Resource__c != null) {
                        setTaxGroup.add(SL.Resource__r.Tax_Group__c);
                    }
                }

                TMMgmt.mapResource = new Map<Id, Resource__c>([
                        SELECT Id, Name, Description__c, Resource_Type__c, Resource_Type__r.Name, Unit_of_Measure__c, Unit_of_Measure__r.Name, Silver_Rate__c, Silver_ER_Rate__c,
                                Gold_Rate__c, Gold_ER_Rate__c, Platinum_Rate__c, Platinum_ER_Rate__c,Unit_Cost__c
                        FROM Resource__c
                        WHERE Id IN :setResource
                ]);

                TMMgmt.mapResourceType = new Map<Id, Resource_Type__c>([
                        SELECT Id, Name, Description__c, Fleet_No_Required__c, Rental_Allowed__c, Unit_of_Measure__c, Unit_of_Measure__r.Name, Silver_ER_Rate__c,
                                Silver_Rate__c,Gold_ER_Rate__c,Gold_Rate__c, Platinum_ER_Rate__c, Platinum_Rate__c, Unit_Cost__c, Fuel_Fired_Equipment__c
                        FROM Resource_Type__c
                        WHERE Id IN :setResourceType
                ]);

                TMMgmt.mapCL = new Map<Id, Contract_Line__c>([
                        SELECT Id, Name, Resource_Type__c, Unit_of_Measure__c,Resource__c,Resource__r.Description__c,
                                Resource_Type__r.Name, Unit_of_Measure__r.Name, Resource__r.Name,Resource_Type__r.Description__c,
                                Overtime_Rate__c, Premium_Rate__c, Regular_Rate__c, Customer_Description__c
                        FROM Contract_Line__c
                        WHERE Id IN :setCL
                ]);
                theCLList = [
                        SELECT Id, Name, Contract__c, Resource_Type__c, Resource__c, Unit_of_Measure__c, Overtime_Rate__c, Regular_Rate__c, Customer_Description__c, Premium_Rate__c
                        FROM Contract_Line__c
                        WHERE Resource_Type__c IN :setResourceType AND Unit_of_Measure__c IN :setUOM
                        //LIMIT 1
                ];

                if (theCLList != null && theCLList.size() > 0) {
                    for (Contract_Line__c CL : theCLList) {
                        theKey = 'null' + ';' + CL.Resource_Type__c + ';' + CL.Unit_of_Measure__c;
                        TMMgmt.contractLineByContractByResORResTypeByUOM.put(theKey, CL);
                    }

                }
                // Put sales tax to map
                for (Tax_Detail__c theTaxDetail : [
                        SELECT Tax_Pct__c, Tax_Area__c, Tax_Group__c
                        FROM Tax_Detail__c
                        WHERE Tax_Area__c = :theSO.Tax_Area__r.Name AND Tax_Group__c IN :setTaxGroup
                ]) {

                    if (String.isEmpty(theTaxDetail.Tax_Area__c) || String.isEmpty(theTaxDetail.Tax_Group__c)) continue;

                    if (TMMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) == null)
                        TMMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, theTaxDetail.Tax_Pct__c); else
                            TMMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, TMMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) + theTaxDetail.Tax_Pct__c);
                }

                CompanyMgmt.mapSalesTax = TMMgmt.mapSalesTax;
                // Insert lines

                Integer LineNo = 0;
                for (TM__c TM : theTMList) {
                    for (Sales_Line__c theSL : theSLList) {
                        if ((theSL.Category__c == 'Labor' || theSL.Category__c == 'Equipment')) {
                            for (Integer i = 0; i < theSL.Quantity__c; i++) {
                                theTML = new TM_Line__c();
                                theTML.TM__c = TM.Id;
                                theTML.Category__c = theSL.Category__c;
                                theTML.Resource_Type__c = theSL.Resource_Type__c;
                                theTML.Service_Center__c = theTM.Service_Center__c;
                                theTML.Resource__c = theSL.Resource__c;
                                theTML.Unit_of_Measure__c = theSL.Unit_of_Measure__c;
                                theTML.Regular_Hours__c = 0;
                                theTML.Overtime_Hours__c = 0;
                                theTML.Premium_Hours__c = 0;
                                theTML.Contract_Line__c = theSL.Contract_Line__c;
                                theTML.Contract_Regular_Rate__c = theSL.Contract_Regular_Rate__c;
                                theTML.Contract_Premium_Rate__c = theSL.Contract_Premium_Rate__c;
                                theTML.Contract_Overtime_Rate__c = theSL.Contract_Overtime_Rate__c;
                                theTML.Unit_of_Measure__c = theSL.Unit_of_Measure__c;
                                if(theSL.Unit_of_Measure__r.Hours_UOM__c != true && theSL.Category__c == 'Labor') {
                                    theTML.Quantity__c = 1;
                                } //14984
                                // Need to use Billing Description from Sales Order
                                theTML.Description__c = theSL.Description__c;
                                theTML.Unit_Price__c = theSL.Unit_Price__c;
                                theTML.xUnit_Price__c = theSL.xUnit_Price__c;
                                //theTML.Regular_Rate__c = theSL.Unit_Price__c;
                                //aura <<
                                theTML.Bill_as_Lump_Sum__c = theSL.Bill_as_Lump_Sum__c;
                                theTML.Non_Billable__c = theSL.Non_Billable__c;
                                //aura >>
                                if(theSL.Category__c == 'Labor'){
                                    theTML.Regular_Rate__c = theSL.Regular_Rate__c;
                                    theTML.Overtime_Rate__c = theSL.Overtime_Rate__c;
                                    theTML.Premium_Rate__c = theSL.Premium_Rate__c;
                                    theTML.xRegular_Rate__c  = theSL.xRegular_Rate__c;
                                    theTML.xOvertime_Rate__c = theSL.xOvertime_Rate__c;
                                    theTML.xPremium_Rate__c = theSL.xPremium_Rate__c;
                                }
                                theTML.Tax_Group__c = 'TX';
                                theTML.Tax_Pct__c = theSL.Tax_Pct__c;
                                theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theSL.Unit_Cost__c);
                                theTML.Include_Lunch_Y_N__c = true; //Ticket#13764
                                theTML.Sales_Line__c = theSL.Id;
                                LineNo += 1;
                                theTML.Line_No__c = LineNo;
                                theTML.Pricing_Source_2__c = theSL.Pricing_Source_2__c; // W-000167
                                theTMLineList.add(theTML);
                            }
                        } else {
                            if (theSL.Category__c == 'Misc. Charges And Taxes' && // 14250
                                    (theSL.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c ||
                                            theSL.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c ||
                                            theSL.Resource__c == CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c)) {
                                continue;
                            }
                            if (theSO.Sales_Order_Type__r.Emergency_Response__c && theSL.Category__c == 'Misc. Charges And Taxes' && // 14937
                                    theSL.Resource__c == theCompanySetup.Default_Safety_Plan_Resource__c){
                                continue;
                            }
                            theTML = new TM_Line__c();
                            theTML.TM__c = TM.Id;
                            theTML.Category__c = theSL.Category__c;
                            theTML.Description__c = theSL.Description__c;
                            theTML.Resource_Type__c = theSL.Resource_Type__c;
                            theTML.Quantity__c = theSL.Quantity__c;
                            theTML.Resource__c = theSL.Resource__c;
                            theTML.Contract_Line__c = theSL.Contract_Line__c;
                            theTML.Contract_Regular_Rate__c = theSL.Contract_Regular_Rate__c;
                            theTML.Contract_Premium_Rate__c = theSL.Contract_Premium_Rate__c;
                            theTML.Contract_Overtime_Rate__c = theSL.Contract_Overtime_Rate__c;
                            theTML.Unit_Price__c = theSL.Unit_Price__c;
                            theTML.xUnit_Price__c = theSL.xUnit_Price__c;
                            //aura >>
                            theTML.Bill_as_Lump_Sum__c = theSL.Bill_as_Lump_Sum__c;
                            theTML.Non_Billable__c = theSL.Non_Billable__c;
                            //aura <<
                            theTML.Unit_of_Measure__c = theSL.Unit_of_Measure__c;
                            theTML.Tax_Group__c = 'TX';
                            theTML.Tax_Pct__c = theSL.Tax_Pct__c;
                            theTML.Tax__c = theSL.Tax__c;
                            theTML.Line_Amount__c = theSL.Line_Amount__c;
                            theTML.Line_Amt_Incl_Tax__c = theSL.Line_Amt_Incl_Tax__c;
                            if(theSL.Category__c == 'Lump Sum') {
                                theTML.Unit_Cost__c = 0;
                                theTML.Line_Cost__c = 0;
                            } else {
                                theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theSL.Unit_Cost__c);
                                theTML.Line_Cost__c = theTML.Unit_Cost__c * theTML.Quantity__c;
                            }
                            theTML.Sales_Line__c = theSL.Id;

                            //aura <<
                            theTML.Resource_UOM__c = theSL.Resource_UOM__c;
                            theTML.Resource_Type_UOM__c = theSL.Resource_Type_UOM__c;
                            theTML.Cost_Method__c = theSL.Cost_Method__c;
                            theTML.Unit_Weight_Vol__c = theSL.Unit_Weight_Vol__c;
                            theTML.Container_Size__c = theSL.Container_Size__c;
                            theTML.Facility__c = theSL.Facility__c;
                            theTML.Min_Sell_Qty__c = theSL.Min_Sell_Qty__c;
                            //aura >>

                            //W-000453 count vendor tax into price and cost calculation, assume vendor tax rate is the same of header tax rate.
                            Decimal taxRate = 0;
                            if(theTML.Tax_Pct__c == 0){
                                taxRate = CompanyMgmt.getSalesTax(theTM.Tax_Area__c, 'TX');
                            } else {
                                taxRate = 0;
                            }
                            theTML.Markup_Option__c = theSL.Markup_Option__c;
                            theTML.Markup__c = theSL.Markup__c;
                            LineNo += 1;
                            theTML.Line_No__c = LineNo;
                            theTML.Pricing_Source_2__c = theSL.Pricing_Source_2__c; // W-000167

                            if(theSL.Resource__c == theCompanySetup.Default_Manifest_Fee_Resource__c){
                                theTML.System_Calculated_Line__c = theSL.System_Calculated_Line__c;
                            }

                            theTMLineList.add(theTML);
                        }
                    }
                }
                insert theTMLineList;
            }
            if (theTMList.size() > 0) {
                PageReference TMPage = new PageReference('/' + theTMList[0].Id);
                TMPage.setRedirect(true);
                return TMPage;
            } else {
                PageReference SOPage = new PageReference('/' + theSO.Id);
                SOPage.setRedirect(true);
                return SOPage;
            }

        } catch (Exception e) {
            //Ticket# 13424 >>
            Database.rollback(sp);
            //Ticket# 13424 <<
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        */
        return null;
    }

    public List<TMWrap > TMWrapList {
        get {
            return theTMWrapList;
        }
        private set {
            theTMWrapList = value;
        }
    }

    public class TMWrap {
        public Date scheduledDate {
            get;
            set;
        }
        public String description {
            get;
            set;
        }
        public String siteScope {
            get;
            set;
        }
        public TMWrap(Date scheduledDate, String description, String siteScope) {
            this.scheduledDate = scheduledDate;
            this.description = description;
            this.siteScope = siteScope;
        }
    }

    //Depreciated
    public void validateCustomer() {
        /*
        String msg = 'Customer ' + salesOrder.Bill_to_Customer_No__r.Name + ' is on Credit Hold. Are you sure you want to continue?';
        if(salesOrder.Bill_to_Customer_No__r.Credit_Hold__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, msg));
        }*/
    }

    //Ticket# 14296
    public Boolean isNullUOMQty(){
        if (isNullUOMQtyChecked) return nullUOMQty;
        for (Sales_Line__c theSL : theSLList) {
            if ((theSL.Category__c == 'Labor' || theSL.Category__c == 'Equipment') && (theSL.UOM_Qty__c == null || theSL.UOM_Qty__c == 0)){
                nullUOMQty = true;
                break;
            }
        }
        isNullUOMQtyChecked = true;
        return nullUOMQty;
    }

    public Boolean isSLQtyIsZero () {
        if (isSLQtyIsZeroChecked) return SLQtyIsZero;
        for (Sales_Line__c theSL : theSLList) {
            if (theSL.Quantity__c == 0) {
                SLQtyIsZero = true;
                break;
            }
        }
        isSLQtyIsZeroChecked = true;
        return SLQtyIsZero;
    }

    //Ticket# 404 update if last condition >>
    public Boolean allowToCreateTM {
        get {
            // Ticket# 14296
            if (String.isBlank(theSO.CMR_Description__c) || theSO.Billing_Type__c == null
                    || theSO.Account_Executives__c == null || theSO.Document_Status__c == 'Closed' || theSO.Document_Type__c == 'Sales Quote' ||
                    theSO.Tax_Area__c == null || isNullUOMQty() || isSLQtyIsZero()
                    || theSO.Bill_to_Customer_No__r.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId()) {
                return false;
            } else {
                return true;
            }
        }
    }

    //Depreciated
    public List<String> getConvertMessages() {
        List<String> str = new List<String>();
        /*
        if (theSO.Document_Type__c == 'Sales Order') {
            str.add('ERROR! The sales document is a Sales Order already.');
        }
        //Ticket# AES-404
        if (theSO.Bill_to_Customer_No__r.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId()){
            str.add('ERROR! Cannot convert Quote to Sales Order because account is not approve yet!');
        }
        if (!theSO.Allow_Convert__c && theSO.Document_Type__c == 'Sales Quote'){
            str.add('ERROR! Cannot convert Quote to Sales Order because the Quote Type is One Time or the quote is expired!');
        }
         */
        return str;
    }

    //Depreciated
    public List<String> getMessages() {
        List<String> str = new List<String>();
        /*
        if (theSO.Document_Type__c == 'Sales Quote') {
            str.add('ERROR! You cannot create T&M from Sales Quote.');
        }
        if (theSO.Bill_to_Customer_No__r.Credit_Hold__c == true) {
            str.add('WARNING! Account is on Credit Hold. Are you sure to continue?');
        }
        if (String.isBlank(theSO.CMR_Description__c)) {
            str.add('ERROR! CMR Description cannot be blank.');
        }
        if (theSO.Billing_Type__c == null) {
            str.add('ERROR! Billing Type cannot be blank.');
        }
        if (theSO.Account_Executives__c == null) {
            str.add('ERROR! Account Executives cannot be blank.');
        }
        if (theSO.Document_Status__c == 'Closed') {
            str.add('ERROR! Sales Order is closed.');
        }
        if (theSO.Tax_Area__c == null) {
            str.add('ERROR! Tax Area cannot be blank.');
        }

        //Ticket# AES-404
        if (theSO.Bill_to_Customer_No__r.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId()){
            str.add('ERROR! Cannot convert Quote to Sales Order because account is not approve yet!');
        }

        //Ticket# 14296
        if (isNullUOMQty()) {
            str.add('ERROR! There is empty or zero UOM Qty sales line!');
        }

        if (isSLQtyIsZero()) {
            str.add('ERROR! There is zero qty sales line!');
        }
         */

        return str;
    }

    //Depreciated
    public PageReference CreateTMfromSO() {
        /* Depreciated
        TM__c theTM = new TM__c();
        List<TM_Line__c> theTMLineList = new List<TM_Line__c>();
        TM_Line__c theTML;
        //Savepoint
        Savepoint sp = Database.setSavepoint();
        try {
            if(theSO.Service_Center__r.Blocked__c == true){
                throw new DataException('Service center ' + theSO.Service_Center__r.Name + ' is deactivated!');
            }

            List<TM__c> existingTMs = [SELECT Id, Sales_Order__c FROM TM__c WHERE Sales_Order__c = :theSO.Id];
            Integer existingTMSize = existingTMs.size();
            if (theSO.Bill_to_Customer_No__r.Emergency__c == true &&
                    String.isBlank(theSO.Bill_to_Customer_No__r.AccountNumber)) {
                if (Integer.valueOf(CompanyMgmt.zeroIfNull(theCompanySetup.Max_T_M_for_not_Approved_Customer__c))
                        < (existingTMSize + 1)) {
                    throw new DataException('You have exceeded the number of Emergency T&Ms. This customer is not approved. Please contact Accounts Receivable');
                }
            }

            if (theSO.Bill_to_Customer_No__r.Emergency__c == false &&
                    String.isBlank(theSO.Bill_to_Customer_No__r.AccountNumber)) {
                throw new DataException('This customer is not approved. Please contact Accounts Receivable');
            }
            //Ticket#13807 AES-394 <<
            theTM.Bill_to_Customer__c = theSO.Bill_to_Customer_No__c;
            theTM.Contact__c = theSO.Bill_to_Contact__c;
            theTM.Site_Contact_2__c = theSO.Site_Contact_2__c; //AES-401,Ticket#14009
            theTM.Sales_Order__c = theSO.Id;
            theTM.Project_Coordinator__c = theSO.Project_Coordinator__c;
            theTM.Account_Executive__c = theSO.Account_Executives__c;
            theTM.Prevailing_Wage_Job__c = theSO.Prevailing_Wage_Job__c;
            theTM.Certified_PW_Job__c = theSO.Certified_PW_Job__c;
            theTM.Subsidiary_Company__c = theSO.Subsidiary_Company__c;
            theTM.Service_Center__c = theSO.Service_Center__c;
            theTM.Customer_PO_No__c = theSO.Customer_PO_No__c;

            //Ticket# 13488 >>
            theTM.Description__c = 'Day of Job ' + existingTMSize + 1 + ' ' + theSO.Bill_to_Customer_No__r.Name;
            theTM.Day_of_Job__c = existingTMSize + 1;
            //Ticket# 13488 <<

            theTM.Contract__c = theSO.Contract__c;
            theTM.Status__c = 'Open';
            theTM.Alternate_Site_Address__c = theSO.Alternate_Site_Address__c;
            theTM.Site_Name__c = theSO.Site_Name__c;
            theTM.Site_Street__c = theSO.Site_Street__c;
            theTM.Site_City__c = theSO.Site_City__c;
            theTM.Site_State__c = theSO.Site_State__c;
            theTM.Site_Postal_Code__c = theSO.Site_Postal_Code__c;//Ticket#13730
            theTM.Site_Country__c = theSO.Site_Country__c;
            theTM.Site_Contact__c = theSO.Site_Contact__c;
            theTM.Site_Phone_No__c = theSO.Site_Phone_No__c;
            theTM.Site_Email_Address__c = theSO.Site_Email_Address__c;
            theTM.Tax_Liable__c = theSO.Tax_Liable__c;
            theTM.Tax_Area__c = theSO.Tax_Area__c;
            theTM.Site_Scope__c = theSO.Site_Scope__c;
            theTM.From_Sales_Quote__c = theSO.From_Sales_Quote__c;
            theTM.Print_Site_Name__c = theSO.Print_Site_Name__c;
            theTM.Billing_Instructions__c = theSO.Billing_Instructions__c;
            theTM.Internal_Comments__c = theSO.Internal_Comments__c; //14554
            theTM.Customer_Billing_Instructions__c = theSO.Customer_Billing_Instructions__c;
            theTM.Sales_Order_Instructions__c = theSO.Sales_Order_Instructions__c;
            theTM.Mobile_Email__c = theSO.Mobile_Email__c; //Mobile T&M review status
            theTM.Rate_Sheet__c = theSO.Rate_Sheet__c;
            if (!Test.isRunningTest()) {
                insert theTM;
            }

            if (theSLList != null && theSLList.size() > 0) {
                Set<Id> setResource = new Set<Id>();
                Set<Id> setResourceType = new Set<Id>();
                Set<Id> setCL = new Set<Id>();
                Set<Id> setUOM = new Set<Id>();
                Set<String> setTaxGroup = new Set<String>();
                List<Contract_Line__c> theCLList = new List<Contract_Line__c>();
                String theKey = '';

                for (Sales_Line__c SL : theSLList) {
                    if (SL.Resource__c != null) {
                        setResource.add(SL.Resource__c);
                    }

                    if (SL.Resource_Type__c != null) {
                        setResourceType.add(SL.Resource_Type__c);
                    }

                    if (SL.Contract_Line__c != null) {
                        setCL.add(SL.Contract_Line__c);
                    }

                    if (SL.Unit_of_Measure__c != null) {
                        setUOM.add(SL.Unit_of_Measure__c);
                    }
                }

                TMMgmt.mapResource = new Map<Id, Resource__c>([
                        SELECT Id, Name, Description__c, Resource_Type__c, Resource_Type__r.Name, Unit_of_Measure__c, Silver_Rate__c, Silver_ER_Rate__c,
                                Gold_Rate__c, Gold_ER_Rate__c, Platinum_Rate__c, Platinum_ER_Rate__c,Unit_Cost__c, Tax_Group__c
                        FROM Resource__c
                        WHERE Id IN :setResource
                ]);

                for(Resource__c resource:TMMgmt.mapResource.values()){
                    if(resource.Tax_Group__c != null){
                        setTaxGroup.add(resource.Tax_Group__c);
                    }
                }

                TMMgmt.mapResourceType = new Map<Id, Resource_Type__c>([
                        SELECT Id, Name, Description__c, Fleet_No_Required__c, Rental_Allowed__c, Unit_of_Measure__c, Silver_ER_Rate__c,
                                Silver_Rate__c,Gold_ER_Rate__c,Gold_Rate__c, Platinum_ER_Rate__c, Platinum_Rate__c, Unit_Cost__c,
                                Unit_of_Measure1__c, Unit_of_Measure2__c, Unit_of_Measure3__c, Unit_of_Measure4__c, Unit_Of_Measure__r.Name, Fuel_Fired_Equipment__c
                        FROM Resource_Type__c
                        WHERE Id IN :setResourceType
                ]);

                TMMgmt.mapCL = new Map<Id, Contract_Line__c>([
                        SELECT Id, Name, Resource_Type__c, Unit_of_Measure__c,Resource__c,Resource__r.Description__c,
                                Resource_Type__r.Name, Unit_of_Measure__r.Name, Resource__r.Name,Resource_Type__r.Description__c,
                                Overtime_Rate__c, Premium_Rate__c, Regular_Rate__c, Customer_Description__c
                        FROM Contract_Line__c
                        WHERE Id IN :setCL
                ]);
                theCLList = [
                        SELECT Id, Name, Contract__c, Resource_Type__c, Resource__c, Unit_of_Measure__c, Overtime_Rate__c, Regular_Rate__c, Customer_Description__c, Premium_Rate__c
                        FROM Contract_Line__c
                        WHERE Resource_Type__c IN :setResourceType AND Unit_of_Measure__c IN :setUOM
                        //LIMIT 1
                ];

                if (theCLList != null && theCLList.size() > 0) {
                    for (Contract_Line__c CL : theCLList) {
                        theKey = 'null' + ';' + CL.Resource_Type__c + ';' + CL.Unit_of_Measure__c;
                        TMMgmt.contractLineByContractByResORResTypeByUOM.put(theKey, CL);
                    }

                }
                // Put sales tax to map
                if(setTaxGroup.size() > 0){
                    for (Tax_Detail__c theTaxDetail : [
                            SELECT Tax_Pct__c, Tax_Area__c, Tax_Group__c
                            FROM Tax_Detail__c
                            WHERE Tax_Area__c = :theSO.Tax_Area__r.Name AND Tax_Group__c IN :setTaxGroup
                    ]) {

                        if (String.isEmpty(theTaxDetail.Tax_Area__c) || String.isEmpty(theTaxDetail.Tax_Group__c)) continue;

                        if (TMMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) == null)
                            TMMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, theTaxDetail.Tax_Pct__c); else
                                TMMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, TMMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) + theTaxDetail.Tax_Pct__c);
                    }
                }

                CompanyMgmt.mapSalesTax = TMMgmt.mapSalesTax;
                // Insert lines
                Integer LineNo = 0;
                for (Sales_Line__c theSL : theSLList) {
                    if ((theSL.Category__c == 'Labor' || theSL.Category__c == 'Equipment')) {
                        for (Integer i = 0; i < theSL.Quantity__c; i++) {
                            theTML = new TM_Line__c();
                            theTML.TM__c = theTM.Id;
                            theTML.Category__c = theSL.Category__c;
                            theTML.Resource_Type__c = theSL.Resource_Type__c;
                            theTML.Service_Center__c = theTM.Service_Center__c;
                            theTML.Resource__c = theSL.Resource__c;
                            theTML.Regular_Hours__c = 0;
                            theTML.Overtime_Hours__c = 0;
                            theTML.Premium_Hours__c = 0;
                            //theTML.Quantity__c = theSL.Quantity__c;
                            theTML.Contract_Line__c = theSL.Contract_Line__c;
                            theTML.Contract_Regular_Rate__c = theSL.Contract_Regular_Rate__c;
                            theTML.Contract_Premium_Rate__c = theSL.Contract_Premium_Rate__c;
                            theTML.Contract_Overtime_Rate__c = theSL.Contract_Overtime_Rate__c;
                            theTML.Unit_of_Measure__c = theSL.Unit_of_Measure__c;
                            if(theSL.Unit_of_Measure__r.Hours_UOM__c != true && theSL.Category__c == 'Labor') theTML.Quantity__c = 1; //14984
                            // Need to use Billing Description from Sales Order
                            theTML.Description__c = theSL.Description__c;
                            theTML.Unit_Price__c = theSL.Unit_Price__c;
                            theTML.xUnit_Price__c = theSL.xUnit_Price__c;
                            //theTML.Regular_Rate__c = theSL.Unit_Price__c;
                            //aura >>
                            theTML.Bill_as_Lump_Sum__c = theSL.Bill_as_Lump_Sum__c;
                            theTML.Non_Billable__c = theSL.Non_Billable__c;
                            //aura <<
                            if(theSL.Category__c == 'Labor'){
                                theTML.Regular_Rate__c = theSL.Regular_Rate__c;
                                theTML.Overtime_Rate__c = theSL.Overtime_Rate__c;
                                theTML.Premium_Rate__c = theSL.Premium_Rate__c;
                                theTML.xRegular_Rate__c  = theSL.xRegular_Rate__c;
                                theTML.xOvertime_Rate__c = theSL.xOvertime_Rate__c;
                                theTML.xPremium_Rate__c = theSL.xPremium_Rate__c;
                            }
                            theTML.Tax_Group__c = 'TX';
                            theTML.Tax_Pct__c = theSL.Tax_Pct__c;
                            //theTML.Tax__c = theSL.Tax__c;
                            //theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theSL.Resource_Type__r.Unit_Cost__c);
                            theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theSL.Unit_Cost__c);
                            //theTML.Quote_Line__c = theSL.Quote_Line__c;
                            theTML.Sales_Line__c = theSL.Id;
                            theTML.Include_Lunch_Y_N__c = true; //Ticket#13764
                            LineNo += 1;
                            theTML.Line_No__c = LineNo;
                            theTML.Pricing_Source_2__c = theSL.Pricing_Source_2__c; // W-000167
                            theTMLineList.add(theTML);
                        }
                    } else {
                        if (theSL.Category__c == 'Misc. Charges And Taxes' && // 14250
                                (theSL.Resource__c == theCompanySetup.Default_Energy_Insurance_Resource__c ||
                                        theSL.Resource__c == theCompanySetup.Default_Fuel_Surcharge_Resource__c ||
                                        theSL.Resource__c == CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c)) {
                            continue;
                        }
                        if (theSO.Sales_Order_Type__r.Emergency_Response__c && theSL.Category__c == 'Misc. Charges And Taxes' && // 14937
                                theSL.Resource__c == theCompanySetup.Default_Safety_Plan_Resource__c ){
                            continue;
                        }
                        theTML = new TM_Line__c();
                        theTML.TM__c = theTM.Id;
                        theTML.Category__c = theSL.Category__c;
                        theTML.Description__c = theSL.Description__c;
                        theTML.Resource_Type__c = theSL.Resource_Type__c;
                        theTML.Quantity__c = CompanyMgmt.zeroIfNull(theSL.Quantity__c);
                        theTML.Resource__c = theSL.Resource__c;
                        theTML.Contract_Line__c = theSL.Contract_Line__c;
                        theTML.Contract_Regular_Rate__c = theSL.Contract_Regular_Rate__c;
                        theTML.Contract_Premium_Rate__c = theSL.Contract_Premium_Rate__c;
                        theTML.Contract_Overtime_Rate__c = theSL.Contract_Overtime_Rate__c;
                        theTML.Unit_Price__c = CompanyMgmt.zeroIfNull(theSL.Unit_Price__c);
                        theTML.xUnit_Price__c = theSL.xUnit_Price__c;
                        //theTML.Regular_Rate__c = theSL.Unit_Price__c;
                        //aura >>
                        theTML.Bill_as_Lump_Sum__c = theSL.Bill_as_Lump_Sum__c;
                        theTML.Non_Billable__c = theSL.Non_Billable__c;
                        //aura <<
                        theTML.Unit_of_Measure__c = theSL.Unit_of_Measure__c;
                        theTML.Tax_Group__c = 'TX';
                        theTML.Tax_Pct__c = theSL.Tax_Pct__c;
                        theTML.Tax__c = theSL.Tax__c;


                        //aura <<
                        theTML.Resource_UOM__c = theSL.Resource_UOM__c;
                        theTML.Resource_Type_UOM__c = theSL.Resource_Type_UOM__c;
                        theTML.Cost_Method__c = theSL.Cost_Method__c;
                        theTML.Unit_Weight_Vol__c = theSL.Unit_Weight_Vol__c;
                        theTML.Container_Size__c = theSL.Container_Size__c;
                        theTML.Facility__c = theSL.Facility__c;
                        theTML.Min_Sell_Qty__c = theSL.Min_Sell_Qty__c;
                        //aura >>

                        theTML.Line_Amount__c = theSL.Line_Amount__c;
                        theTML.Line_Amt_Incl_Tax__c = theSL.Line_Amt_Incl_Tax__c;
                        //theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theSL.Resource__r.Unit_Cost__c);

                        if(theSL.Category__c == 'Lump Sum'){
                            theTML.Unit_Cost__c = 0;
                            theTML.Line_Cost__c = 0;
                        } else {
                            theTML.Unit_Cost__c = CompanyMgmt.zeroIfNull(theSL.Unit_Cost__c);
                            theTML.Line_Cost__c = theTML.Unit_Cost__c * theTML.Quantity__c;
                        }

                        //W-000453 count vendor tax into price and cost calculation, assume vendor tax rate is the same of header tax rate.
                        Decimal taxRate = 0;
                        if(theTML.Tax_Pct__c == 0){
                            taxRate = CompanyMgmt.getSalesTax(theTM.Tax_Area__c, 'TX');
                        } else {
                            taxRate = 0;
                        }

                        theTML.Markup_Option__c = theSL.Markup_Option__c;
                        theTML.Markup__c = theSL.Markup__c;
                        //theTML.Quote_Line__c = theSL.Quote_Line__c;
                        theTML.Sales_Line__c = theSL.Id;
                        LineNo += 1;
                        theTML.Line_No__c = LineNo;
                        theTML.Pricing_Source_2__c = theSL.Pricing_Source_2__c; // W-000167

                        if(theSL.Resource__c == theCompanySetup.Default_Manifest_Fee_Resource__c){
                            theTML.System_Calculated_Line__c = theSL.System_Calculated_Line__c;
                        }

                        theTMLineList.add(theTML);
                    }
                }
                insert theTMLineList;
            }


            PageReference TMPage = new PageReference('/' + theTM.Id);
            TMPage.setRedirect(true);
            return TMPage;
        } catch (Exception e) {
            System.debug('Error# ' + e.getStackTraceString());
            //Ticket# 13424 >>
            Database.rollback(sp);
            //Ticket# 13424 <<
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
         */
        return null;
    }

    //Depreciated
    public PageReference CreateBlankTM() {
        /*
        TM__c theTM = new TM__c();

        //Savepoint
        Savepoint sp = Database.setSavepoint();

        try {
            if(theSO.Service_Center__r.Blocked__c == true){
                throw new DataException('Service center ' + theSO.Service_Center__r.Name + ' is deactivated!');
            }

            List<TM__c> existingTMs = [SELECT Id, Sales_Order__c FROM TM__c WHERE Sales_Order__c = :theSO.Id];
            Integer existingTMSize = existingTMs.size();

            if (theSO.Bill_to_Customer_No__r.Emergency__c == true &&
                    String.isBlank(theSO.Bill_to_Customer_No__r.AccountNumber)) {
                if (Integer.valueOf(CompanyMgmt.zeroIfNull(theCompanySetup.Max_T_M_for_not_Approved_Customer__c))
                        < Integer.valueOf(existingTMSize + 1)) {
                    throw new DataException('You have exceeded the number of Emergency T&Ms. This customer is not approved. Please contact Accounts Receivable');
                }
            }

            if (theSO.Bill_to_Customer_No__r.Emergency__c == false &&
                    String.isBlank(theSO.Bill_to_Customer_No__r.AccountNumber)) {
                throw new DataException('This customer is not approved. Please contact Accounts Receivable');
            }
            //Ticket#13807 AES-394 <<
            theTM.Bill_to_Customer__c = theSO.Bill_to_Customer_No__c;
            theTM.Contact__c = theSO.Bill_to_Contact__c;
            theTM.Site_Contact_2__c = theSO.Site_Contact_2__c; //AES-401,Ticket#14009
            theTM.Sales_Order__c = theSO.Id;
            theTM.Project_Coordinator__c = theSO.Project_Coordinator__c;
            theTM.Account_Executive__c = theSO.Account_Executives__c;
            theTM.Prevailing_Wage_Job__c = theSO.Prevailing_Wage_Job__c;
            theTM.Certified_PW_Job__c = theSO.Certified_PW_Job__c;
            theTM.Subsidiary_Company__c = theSO.Subsidiary_Company__c;
            theTM.Service_Center__c = theSO.Service_Center__c;
            theTM.Customer_PO_No__c = theSO.Customer_PO_No__c;
            theTM.Description__c = 'Day of Job ' + existingTMSize + 1 + ' ' + theSO.Bill_to_Customer_No__r.Name;
            theTM.Day_of_Job__c = existingTMSize + 1;
            theTM.Contract__c = theSO.Contract__c;
            theTM.Status__c = 'Open';
            theTM.Tax_Liable__c = theSO.Tax_Liable__c;
            theTM.Tax_Area__c = theSO.Tax_Area__c;
            theTM.From_Sales_Quote__c = theSO.From_Sales_Quote__c;
            theTM.Print_Site_Name__c = theSO.Print_Site_Name__c;
            theTM.Billing_Instructions__c = theSO.Billing_Instructions__c;
            theTM.Internal_Comments__c = theSO.Internal_Comments__c; // 14554
            theTM.Customer_Billing_Instructions__c = theSO.Customer_Billing_Instructions__c;
            theTM.Sales_Order_Instructions__c = theSO.Sales_Order_Instructions__c;
            theTM.Mobile_Email__c = theSO.Mobile_Email__c; //Mobile T&M review status
            theTM.Rate_Sheet__c = theSO.Rate_Sheet__c;
            if (!test.isrunningtest()) insert theTM;

            PageReference TMPage = new PageReference('/' + theTM.Id);
            TMPage.setRedirect(true);
            return TMPage;
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        */
        return null;
    }

    //Depreciated
    public PageReference cloneSO() {
        /*
        // Savepoint
        Savepoint sp = database.setSavePoint();

        Sales_Order__c theNewSO;
        try {
            theNewSO = theSO.clone(false);
            theNewSO = SalesOrderMgmt.nullRelationshipFields(theNewSO);
            theNewSO.Document_Status__c = 'Open';
            theNewSO.Name = null;
            theNewSO.NAV_Job_No__c = null;
            //integration.sync.flag <<
            theNewSO.Sync_d__c = false;
            //integration.sync.flag >>

            if (selConvertTo == 'Quote') {
                theNewSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();
                theNewSO.Document_Type__c = 'Sales Quote';
            } else if (selConvertTo == 'Order') {
                theNewSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId();
                theNewSO.Document_Type__c = 'Sales Order';
            }

            //Ticket#14389 >>
            theNewSO.Surcharge_Type__c = theSO.Surcharge_Type__c;
            theNewSO.Start_Date__c = null;
            theNewSO.End_Date__c = null;
            theNewSO.Surcharge_Amount__c = null;
            theNewSO.Surcharge_Pct__c = null;
            theNewSO.Quote_Date__c = null;
            //Ticket#14389 <<

            insert theNewSO;
            newSOId = theNewSO.Id;

            //******** To overcome soql limit on clone ***********
            Set<Id> setResource = new Set<Id>();
            Set<Id> setResourceType = new Set<Id>();
            Set<Id> setItemUOM = new Set<Id>();
            for (Sales_Line__c SL : theSLList) {

                if (SL.Resource__c != null) setResource.add(SL.Resource__c);

                if (SL.Resource_Type__c != null) setResourceType.add(SL.Resource_Type__c);

                if (SL.Unit_of_Measure__c != null) setItemUOM.add(SL.Unit_of_Measure__c);
            }

            SalesOrderMgmt.mapMaterial = new Map<Id, Resource__c>([
                    SELECT Id, Name, Description__c, Resource_Type__c, Resource_Type__r.Name, Unit_of_Measure__c, Unit_of_Measure1__c, Unit_of_Measure2__c, Unit_of_Measure3__c, Unit_of_Measure4__c,
                            Silver_ER_Rate__c, Silver_ER_Rate1__c, Silver_ER_Rate2__c, Silver_ER_Rate3__c, Silver_ER_Rate4__c,
                            Silver_Rate__c, Silver_Rate1__c, Silver_Rate2__c, Silver_Rate3__c, Silver_Rate4__c,
                            Gold_ER_Rate__c, Gold_ER_Rate1__c, Gold_ER_Rate2__c, Gold_ER_Rate3__c, Gold_ER_Rate4__c,
                            Gold_Rate__c, Gold_Rate1__c, Gold_Rate2__c, Gold_Rate3__c, Gold_Rate4__c,
                            Platinum_ER_Rate__c, Platinum_ER_Rate1__c, Platinum_ER_Rate2__c, Platinum_ER_Rate3__c, Platinum_ER_Rate4__c,
                            Platinum_Rate__c, Platinum_Rate1__c, Platinum_Rate2__c, Platinum_Rate3__c, Platinum_Rate4__c, Unit_Cost__c, Unit_of_Measure__r.Name,
                            Unit_Cost1__c, Unit_Cost2__c, Unit_Cost3__c, Unit_Cost4__c
                    FROM Resource__c
                    WHERE Id IN :setResource
            ]);

            SalesOrderMgmt.mapResourceType = new Map<Id, Resource_Type__c>([
                    SELECT Id, Name, Description__c, Fleet_No_Required__c, Rental_Allowed__c, Unit_of_Measure__c, Unit_of_Measure1__c, Unit_of_Measure2__c, Unit_of_Measure3__c, Unit_of_Measure4__c,
                            Silver_ER_Rate__c, Silver_ER_Rate1__c, Silver_ER_Rate2__c, Silver_ER_Rate3__c, Silver_ER_Rate4__c,
                            Silver_Rate__c, Silver_Rate1__c, Silver_Rate2__c, Silver_Rate3__c, Silver_Rate4__c,
                            Gold_ER_Rate__c, Gold_ER_Rate1__c, Gold_ER_Rate2__c, Gold_ER_Rate3__c, Gold_ER_Rate4__c,
                            Gold_Rate__c, Gold_Rate1__c, Gold_Rate2__c, Gold_Rate3__c, Gold_Rate4__c,
                            Platinum_ER_Rate__c, Platinum_ER_Rate1__c, Platinum_ER_Rate2__c, Platinum_ER_Rate3__c, Platinum_ER_Rate4__c,
                            Platinum_Rate__c, Platinum_Rate1__c, Platinum_Rate2__c, Platinum_Rate3__c, Platinum_Rate4__c, Unit_Cost__c, Unit_of_Measure__r.Name,
                            Unit_Cost1__c, Unit_Cost2__c, Unit_Cost3__c, Unit_Cost4__c, Fuel_Fired_Equipment__c
                    FROM Resource_Type__c
                    WHERE Id IN :setResourceType
            ]);

            SalesOrderMgmt.mapUOM = new Map<Id, Unit_of_Measure__c>([SELECT Id, Name, Hours_UOM__c FROM Unit_of_Measure__c WHERE Id IN :setItemUOM]);

            List<Sales_Line__c> theNewSLList = new List<Sales_Line__c>();

            for (Sales_Line__c SL : theSLList) {
                Sales_Line__c newSL = new Sales_Line__c();
                newSL = SL.Clone(false);

                newSL.Sales_Order__c = theNewSO.id;
                newSL.Line_No__c = SL.Line_No__c;
                newSL.Resource_Type__c = SL.Resource_Type__c;

                if (!String.isEmpty(newSL.Resource_Type__c)) newSL = SalesOrderMgmt.updateSL(newSL, theNewSO, 'theResourceType');

                newSL.Resource__c = SL.Resource__c;
                if (!String.isEmpty(newSL.Resource__c)) {
                    newSL = SalesOrderMgmt.updateSL(newSL, theNewSO, 'theResource');
                }
                newSL.Unit_of_Measure__c = SL.Unit_of_Measure__c;
                newSL = SalesOrderMgmt.updateSL(newSL, theNewSO, 'theUOM');
                newSL.Quantity__c = SL.Quantity__c;
                newSL.UOM_Qty__c = SL.UOM_Qty__c; //Ticket#14389
                newSL = SalesOrderMgmt.updateSL(newSL, theNewSO, 'theQuantity');
                newSL.Scheduled_Date__c = SL.Scheduled_Date__c;
                newSL.Description__c = SL.Description__c;
                newSL.Category__c = SL.Category__c;
                newSL.Unit_of_Measure__r = null;
                newSL.Resource_Type__r = null;
                newSL.Resource__r = null;
                theNewSLList.add(newSL);
            }

            insert theNewSLList;

            PageReference SOPage = new PageReference('/' + newSOId);
            SOPage.setRedirect(true);
            return SOPage;
        } catch (Exception e) {
            // Rollback
            Database.Rollback(sp);

            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + '---' + e.getStackTraceString()));
        }
         */
        return null;
    }

    public PageReference deleteSO() {
        // Savepoint
        Savepoint sp = database.setSavePoint();
        try {
            delete theSO;
            return new ApexPages.Action('{!List}').invoke();
        } catch (Exception e) {
            Database.rollback(sp);
            //DE36096
            String errorMessage = e.getMessage();
            if (errorMessage.contains('You do not have permissions to delete a Quote/Order. Please reach out to you Salesforce Administrator team.')) {
                errorMessage = 'You do not have permissions to delete a Quote/Order. Please reach out to you Salesforce Administrator team.';
            }            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            return null;
        }
        return null;
    }
    /*
      Depreciated -- 01/20/2021
      Ticket# 13375
     */
    public PageReference copyPWInfo() {
        /*
        Savepoint sp = Database.setSavepoint();
        try {
            List<TM__c> tmLst = [SELECT Id, Prevailing_Wage_Job__c, Certified_PW_Job__c FROM TM__c WHERE Sales_Order__c = :theSO.Id];
            for (TM__c tm : tmLst) {
                tm.Prevailing_Wage_Job__c = theSO.Prevailing_Wage_Job__c;
                tm.Certified_PW_Job__c = theSO.Certified_PW_Job__c;
            }
            update tmLst;

            PageReference SOPage = new PageReference('/' + theSO.Id);
            SOPage.setRedirect(true);
            return SOPage;
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
        }
         */
        return null;
    }

    public List<Sales_Line__c > SLList {
        get {
            return theSLList;
        }
    }

    public List<SelectOption> lstConvertTo {
        get {
            if (lstConvertTo == null) {
                lstConvertTo = new List<SelectOption>();
                lstConvertTo.add(new SelectOption('Quote', 'Quote'));
                lstConvertTo.add(new SelectOption('Order', 'Order'));
            }
            return lstConvertTo;
        }
        set;
    }

    /*02102023
    private void CalculateTotal() {

        CalculateTotalLabor();
        CalculateTotalEquipment();
        CalculateTotalMaterials();
        CalculateTotalSubcontractors();
        CalculateTotalWasteDisposal();
        CalculateTotalLumpSum();
        CalculateTotalMisc();
        CalculateTotalDemurrage();
        CalculateTotalOrder();
    }
     */

    /*02102023
    private void CalculateTotalLabor() {
        SLSubtotalLabor = 0.00;
        SLTaxTotalLabor = 0.00;
        SLTotalLabor = 0.00;
        //Ticket# AES-415
        SLProfitMarginLabor = 0.00;
        SLTotalCostLabor = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Line__c theSL : SOListLaborLines) {
            SLSubtotalLabor += CompanyMgmt.zeroIfNull(theSL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SLTaxTotalLabor += (CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SLTotalLabor += CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            //SLProfitMarginLabor += CompanyMgmt.zeroIfNull(theSL.Profit_Margin__c).setScale(2, RoundingMode.HALF_UP);
            SLTotalCostLabor += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSL.Bill_as_Lump_Sum__c && !theSL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if (SLSubtotalLabor != 0) {
            SLProfitMarginLabor = (1 - totalCostWithoutLumpSum / SLSubtotalLabor) * 100;
        }
    }
     */

    /*02102023
    private void CalculateTotalEquipment() {
        SLSubtotalEquipment = 0.00;
        SLTaxTotalEquipment = 0.00;
        SLTotalEquipment = 0.00;
        //Ticket# AES-415
        SLProfitMarginEquipment = 0.00;
        SLTotalCostEquipment = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Line__c theSL : SOListEquipmentLines) {
            SLSubtotalEquipment += CompanyMgmt.zeroIfNull(theSL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SLTaxTotalEquipment += (CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SLTotalEquipment += CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            //SLProfitMarginEquipment += CompanyMgmt.zeroIfNull(theSL.Profit_Margin__c).setScale(2, RoundingMode.HALF_UP);
            SLTotalCostEquipment += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSL.Bill_as_Lump_Sum__c && !theSL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if (SLSubtotalEquipment != 0) SLProfitMarginEquipment = (1 - totalCostWithoutLumpSum / SLSubtotalEquipment) * 100;
    }
     */

    /*02102023
    private void CalculateTotalMaterials() {
        SLSubtotalMaterials = 0.00;
        SLTaxTotalMaterials = 0.00;
        SLTotalMaterials = 0.00;
        //Ticket# AES-415
        SLProfitMarginMaterials = 0.00;
        SLTotalCostMaterials = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Line__c theSL : SOListMaterialLines) {
            SLSubtotalMaterials += CompanyMgmt.zeroIfNull(theSL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SLTaxTotalMaterials += (CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SLTotalMaterials += CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            //SLProfitMarginMaterials += CompanyMgmt.zeroIfNull(theSL.Profit_Margin__c).setScale(2, RoundingMode.HALF_UP);
            SLTotalCostMaterials += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSL.Bill_as_Lump_Sum__c && !theSL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if (SLSubtotalMaterials != 0) SLProfitMarginMaterials = (1 - totalCostWithoutLumpSum / SLSubtotalMaterials) * 100;
    }
     */

    /*02102023
    private void CalculateTotalSubcontractors() {
        SLSubtotalSubcontractors = 0.00;
        SLTaxTotalSubcontractors = 0.00;
        SLTotalSubcontractors = 0.00;
        //Ticket# AES-415
        SLProfitMarginSubcontractors = 0.00;
        SLTotalCostSubcontractors = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Line__c theSL : SOListSubContractorLines) {
            SLSubtotalSubcontractors += CompanyMgmt.zeroIfNull(theSL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SLTaxTotalSubcontractors += (CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SLTotalSubcontractors += CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            SLTotalCostSubcontractors += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSL.Bill_as_Lump_Sum__c && !theSL.Non_Billable__c) {
                totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            }
        }

        if (SLSubtotalSubcontractors != 0){
            //Ticket16082
            //Unit Cost = Unit Price therefore Total Cost = Total Revenue
            //SLSubtotalSubcontractors total revenue included markup
            if(totalCostWithoutLumpSum > 0){
                SLProfitMarginSubcontractors = CompanyMgmt.halfUpTo2D((SLSubtotalSubcontractors - totalCostWithoutLumpSum) / totalCostWithoutLumpSum * 100);
            } else {
                SLProfitMarginSubcontractors = 100;
            }
        }
    }
     */

    /*02102023
    private void CalculateTotalWasteDisposal() {
        SLSubtotalWasteDisposal = 0.00;
        SLTaxTotalWasteDisposal = 0.00;
        SLTotalWasteDisposal = 0.00;
        //Ticket# AES-415
        SLProfitMarginWasteDisposal = 0.00;
        SLTotalCostWasteDisposal = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Line__c theSL : SOListWasteDisposal) {
            SLSubtotalWasteDisposal += CompanyMgmt.zeroIfNull(theSL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SLTaxTotalWasteDisposal += (CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SLTotalWasteDisposal += CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            //SLProfitMarginWasteDisposal += CompanyMgmt.zeroIfNull(theSL.Profit_Margin__c).setScale(2, RoundingMode.HALF_UP);
            SLTotalCostWasteDisposal += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            if (!theSL.Bill_as_Lump_Sum__c && !theSL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if (SLSubtotalWasteDisposal != 0) SLProfitMarginWasteDisposal = (1 - totalCostWithoutLumpSum / SLSubtotalWasteDisposal) * 100;
    }
     */

    /*02102023
    private void CalculateTotalLumpSum() {

        SLSubtotalLumpSum = 0.00;
        SLTaxTotalLumpSum = 0.00;
        SLTotalLumpSum = 0.00;
        //Ticket# AES-415
        SLProfitMarginLumpSum = 0.00;
        SLTotalCostLumpSum = 0.00;
        for (Sales_Line__c theSL : SOListLumpSum) {
            SLSubtotalLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
            SLTaxTotalLumpSum += (CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
            SLTotalLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
            //SLProfitMarginLumpSum += CompanyMgmt.zeroIfNull(theSL.Profit_Margin__c).setScale(2, RoundingMode.HALF_UP);
            SLTotalCostLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
        }
        if (SLSubtotalLumpSum != 0) SLProfitMarginLumpSum = (1 - SLTotalCostLumpSum / SLSubtotalLumpSum) * 100;

    }
     */

    /*02102023
    private void CalculateTotalMisc() {
        SLSubtotalMisc = 0.00;
        SLTaxTotalMisc = 0.00;
        SLTotalMisc = 0.00;
        //Ticket# AES-415
        SLProfitMarginMisc = 0.00;
        SLTotalCostMisc = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Line__c theSL : SOListMisc) {
            //if(theSL.System_Calculated_Line__c != true){ //14520
            if(theSL.Resource__c != CompanySetup.Default_Fuel_Surcharge_Resource__c && theSL.Resource__c != CompanySetup.Default_Energy_Insurance_Resource__c){
                SLSubtotalMisc += CompanyMgmt.zeroIfNull(theSL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
                SLTaxTotalMisc += (CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
                SLTotalMisc += CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
                //SLProfitMarginMisc += CompanyMgmt.zeroIfNull(theSL.Profit_Margin__c).setScale(2, RoundingMode.HALF_UP);
                SLTotalCostMisc += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
                if (!theSL.Bill_as_Lump_Sum__c && !theSL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            }
        }
        if (SLSubtotalMisc != 0) SLProfitMarginMisc = (1 - totalCostWithoutLumpSum / SLSubtotalMisc) * 100;


    }
    */

    /*02102023
    private void CalculateTotalDemurrage() {
        SLSubtotalDemurrage = 0.00;
        SLTaxTotalDemurrage = 0.00;
        SLTotalDemurrage = 0.00;
        //Ticket# AES-415
        SLProfitMarginDemurrage = 0.00;
        SLTotalCostDemurrage = 0.00;
        Decimal totalCostWithoutLumpSum = 0.00;
        for (Sales_Line__c theSL : SOListDemurrage) {
            if(theSL.System_Calculated_Line__c != true){ //14520
                SLSubtotalDemurrage += CompanyMgmt.zeroIfNull(theSL.Line_Amount__c).setScale(2, RoundingMode.HALF_UP);
                SLTaxTotalDemurrage += (CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c) - CompanyMgmt.zeroIfNull(theSL.Line_Amount__c)).setScale(2, RoundingMode.HALF_UP);
                SLTotalDemurrage += CompanyMgmt.zeroIfNull(theSL.Line_Amt_Incl_Tax__c).setScale(2, RoundingMode.HALF_UP);
                //SLProfitMarginDemurrage += CompanyMgmt.zeroIfNull(theSL.Profit_Margin__c).setScale(2, RoundingMode.HALF_UP);
                SLTotalCostDemurrage += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
                if (!theSL.Bill_as_Lump_Sum__c && !theSL.Non_Billable__c ) totalCostWithoutLumpSum += CompanyMgmt.zeroIfNull(theSL.Line_Cost__c).setScale(2, RoundingMode.HALF_UP);
            }
        }
        if (SLSubtotalDemurrage != 0) SLProfitMarginDemurrage = (1 - totalCostWithoutLumpSum / SLSubtotalDemurrage) * 100;
    }
     */
    //87303
    public PageReference openSO() {
        if (theSO.Document_Status__c == 'Open') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Sales Order is open already.')); return null;
        } else {
            try {
                theSO.Document_Status__c = 'Open';
                theSO.Close_Date__c = null;
                update theSO;
               /* if(System.Label.Release_Flag =='true'){
                    if(theSO.JB_Sent_to_EQAI__c && theSO.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c){
                        String response = SFJobBillingProjectService.reOpenSalesOrderInfo(theSO.Id);
                        if(response == 'Integration Successful')
                        {
                            theSO.Document_Status__c = 'Open';
                            theSO.Close_Date__c = null;
                            update theSO;
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Status updated and Sent to EQAI successfully. Please click Return to Sales Order button to go back Sales Order'));
                            return null;
                        }
                        else
                        {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, response));return null;
                        }
                    }else{
                        theSO.Document_Status__c = 'Open';
                        theSO.Close_Date__c = null;
                        update theSO; 
                    }
                   
                }else{
                    theSO.Document_Status__c = 'Open';
                    theSO.Close_Date__c = null;
                    update theSO;
                }*/
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            return theController.view();
        }
    }

    public PageReference closeSO() {
        if (theSO.Document_Status__c == 'Closed') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Sales Order is Closed already.')); return null;

        } else {
            try {
                List<TM__c> theTMList = new List<TM__c>();
                theTMList = [SELECT Id, Name, Scheduled_Date__c FROM TM__c WHERE Sales_Order__c = :orderId AND Scheduled_Date__c != null ORDER BY Scheduled_Date__c ASC];
				theSO.Document_Status__c = 'Closed';
                theSO.Close_Date__c = system.Today();
                    
                if (theTMList != null && theTMList.size() > 0) {
                    theSO.Start_Date__c = theTMList[0].Scheduled_Date__c;
                    theSO.End_Date__c = theTMList[theTMList.size() - 1].Scheduled_Date__c;
                }
                update theSO; 
                
              /*  if(System.Label.Release_Flag =='true'){
                    if(theSO.JB_Sent_to_EQAI__c){
                        String response = SFJobBillingProjectService.updateCloseDateInSalesOrderInfo(theSO.Id); 
                        
                        System.debug('response====>'+response);
                        if(!response.Startswith('Update Succesful')){
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, response));return null;
                        }
                        else{
                            theSO.Document_Status__c = 'Closed';
                            theSO.Close_Date__c = system.Today();
                            update theSO; 
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Status updated and Closed Date Sent to EQAI successfully. Please click Return to Sales Order button to go back Sales Order'));
                            return null;
                        }
                    }else{
                        theSO.Document_Status__c = 'Closed';
                        theSO.Close_Date__c = system.Today();
                        update theSO; 
                    }
                    
                }else{
                    theSO.Document_Status__c = 'Closed';
                    theSO.Close_Date__c = system.Today();
                    update theSO; 
                }*/
                
 
                
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            return theController.view();
        }
    }

    public Map<String, Boolean> mapStandardAssumptions {
        get {
            return new Map<String, Boolean>{
                    'FreeAccess' => true,
                    'Pricing' => true,
                    'Expendables' => true
            };
        }
        set;
    }

    //Depreciated
    public List<SelectOption> getLaborAssumptionItems() {
        List<SelectOption> options = new List<SelectOption>();
        /*
        String portalBasis = 'All labor, vehicle and equipment charges are billed on a portal-to-portal basis,' +
                ' including time to analyze and off-load the waste at the disposal facility.' +
                ' Overtime rates will apply after eight hours.';

        String overtimeRate = 'All labor, vehicle and equipment charges are billed on a portal-to-portal basis.' +
                ' Overtime rates will apply after eight hours.';

        String DailyRate = 'All labor, vehicle and equipment charges are billed as a daily rate.' +
                ' This pricing is based on a 10 hour day, portal-to-portal.';

        String LumpSum = 'The labor, materials and equipment portion of this quote is lump sum; it is based on information ' +
                ' provided by you and/or gained at the site tour. Any conditions that differ may result in additional charges.';

        String portalBasisAdv = 'All labor, vehicle and equipment charges are billed on a portal-to-portal basis, including time to ' +
                'analyze and off-load the waste at the disposal facility. Overtime rates will apply for hours worked over 8 hours in a day, ' +
                'all hours before 7:00 am, after 3:30 pm, on weekdays and all day Saturday. Double time rates apply ' +
                'for hours worked on Sunday and Holidays.';

        options.add(new SelectOption('PortalBasis', portalBasis));
        options.add(new SelectOption('OvertimeRate', overtimeRate));
        options.add(new SelectOption('DailyRate', DailyRate));
        options.add(new SelectOption('LumpSum', LumpSum));
        options.add(new SelectOption('PortalBasisAdv', portalBasisAdv)); //Ticket# 14303
        */
        return options;
    }

    public PageReference CreateMiscCreditMemo() {
        if(String.isBlank(appliedToInvoice.Id)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select an applied-to invoice to continue!'));
            return null;
        }

        if (String.isEmpty(selectedCrMemoReasonCode)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a credit memo reason code to continue!'));
            return null;
        }

        if(String.isEmpty(creditMemoNote)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Credit Memo Note field must not be blank!'));
            return null;
        } else {
            String tempStr = creditMemoNote;
            tempStr = creditMemoNote.trim();
            if(tempStr.length() < 10){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Credit Memo Note field must be at least 10 characters long!'));
                return null;
            }
        }

        if (salesOrder.Document_Type__c == 'Sales Quote') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You cannot create Misc. Credit Memo from Sales Quote.'));
        } else {
            try {
                Sales_Invoice__c theSI = new Sales_Invoice__c();
                theSI.Bill_To_Customer__c = salesOrder.Bill_to_Customer_No__r.Id;
                theSI = SalesInvoiceMgmt.validateBillToCustomer(theSI);
                theSI.Document_Status__c = 'Open';
                theSI.Invoice_Date__c = Date.today();
                theSI = SalesInvoiceMgmt.nullRelationshipFields(theSI);
                theSI.Sales_Order__c = salesOrder.Id;
                theSI.Tax_Area__c = salesOrder.Tax_Area__c;
                theSI.Service_Center__c = salesOrder.Service_Center__c;
                theSI.Subsidiary_Company__c = salesOrder.Subsidiary_Company__c;
                theSI.Credit_Memo_Reason_Code__c = selectedCrMemoReasonCode;
                theSI.Internal_Comments__c = creditMemoNote;
                theSI.Reversed_from_SI__c = appliedToInvoice.Id;
                theSI.Credit_Memo__c = true;
                theSI.Misc_Invoice__c = true;
                //Ticket#18141
                if(theSI.Credit_Memo_Reason_Code__c == 'Customer is tax exempt'){
                    theSI.Tax_Liable__c = true;
                }
                //Ticket#18141
                insert theSI;

                //job task <<
                Sales_Invoice_Job_Task__c jobTask = new Sales_Invoice_Job_Task__c();
                jobTask.Sales_Invoice__c = theSI.Id;
                jobTask.Line_No__c = 1;
                jobTask.Name = 'Default';
                insert jobTask;
                //job task >>

                //Ticket#20111 >>
                if(theSI.Credit_Memo_Reason_Code__c == 'Customer is tax exempt') {
                    List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
                    List<ACVSalesInvoiceJobTaskWrapper> salesInvoiceJobTaskWrappers = new List<ACVSalesInvoiceJobTaskWrapper>();
                    ACVSalesInvoiceJobTaskWrapper salesInvoiceJobTaskWrapper = new ACVSalesInvoiceJobTaskWrapper();
                    salesInvoiceJobTaskWrapper.JobTask = jobTask;
                    salesInvoiceJobTaskWrapper.SalesInvoiceLines = salesInvoiceLines;
                    salesInvoiceJobTaskWrappers.add(salesInvoiceJobTaskWrapper);
                    SalesInvoicesService.reverseTaxAmount(appliedToInvoice, theSI, salesInvoiceJobTaskWrappers);
                    salesInvoiceLines = salesInvoiceJobTaskWrappers[0].SalesInvoiceLines;
                    if(salesInvoiceLines.size() > 0){
                        insert salesInvoiceLines;
                    }
                }
                //Ticket#20111 >>

                PageReference InvoicePage = new PageReference('/' + theSI.Id);
                InvoicePage.setRedirect(true);
                return InvoicePage;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        }
        return null;
    }

    //Depreciated
    public PageReference reInsertSL() {
        /*
        CompanyMgmt.systemCall = true;
        Savepoint sp = database.setSavePoint();
        try {
            Set<String> setTaxGroup = new Set<String>();
            Set<String> setItemDiscGrp = new Set<String>();
            for (Resource__c theResource : SalesOrderMgmt.mapResource.values()) {
                setTaxGroup.add(theResource.Tax_Group__c);
                setItemDiscGrp.add(theResource.Category__c);
            }
            for (Tax_Detail__c theTaxDetail : [
                    SELECT Tax_Pct__c, Tax_Area__c, Tax_Group__c
                    FROM Tax_Detail__c
                    WHERE Tax_Area__c = :theSO.Tax_Area__r.Name AND Tax_Group__c IN :setTaxGroup
            ]) {

                if (String.isEmpty(theTaxDetail.Tax_Area__c) || String.isEmpty(theTaxDetail.Tax_Group__c)) continue;

                if (SalesOrderMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) == null)
                    SalesOrderMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, theTaxDetail.Tax_Pct__c); else
                        SalesOrderMgmt.mapSalesTax.put(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c, SalesOrderMgmt.mapSalesTax.get(theTaxDetail.Tax_Area__c + ';' + theTaxDetail.Tax_Group__c) + theTaxDetail.Tax_Pct__c);
            }

            CompanyMgmt.mapSalesTax = SalesOrderMgmt.mapSalesTax;
            SalesOrderMgmt.isReinsertSL = true;
            // Assign those  SL which is exist in DB
            List<Sales_Line__c> theNewSLList = new List<Sales_Line__c>();
            // Assign those  SL which is not exist in DB

            for (Sales_Line__c SL : theSLList) {
                Sales_Line__c newSL = new Sales_Line__c();
                newSL = SL.clone(true);

                newSL = SalesOrderMgmt.updateSL(newSL, theSO, 'theTaxGroup');
                theNewSLList.add(newSL);
            }

            if (theSO.Id != null) {
                //clear __r values, value update should be based on __c values.
                theSO = SalesOrderMgmt.nullRelationshipFields(theSO);
                try {
                    upsert theSO;
                    update theNewSLList;
                } catch (Exception e) {
                    System.debug('Error: ' + e.getMessage());
                }
                selectSO();
            }

            theSLList.clear();
            theSLList.addAll(theNewSLList);
            CalculateTotal();
        } catch (Exception e) {
            // Rollback
            Database.Rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
         */
        return null;
    }

    /*
    private void setDefaultAssumptions() {
        theSO.Free_Access__c = true;
        theSO.Pricing__c = true;
        theSO.Expendables__c = true;
        theSO.Applicable_Taxes__c = true;
        theSO.Manifest_And_Profile__c = true;
        //W00028
        theSO.Portal_Basis__c = false;
        theSO.Portal_Basis_Adv__c = true;
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

        theSO.Any_Deviations__c = true;
        theSO.SHippable_Containers__c = true;
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
        LaborAssumption = 'PortalBasisAdv';
    }
     */

    //Depreciated
    public PageReference selectTmList() {
        /*
        TMCreateSIWrapper theTMWrap;
        Date tmStartDate;
        Date tmEndDate;
        List<TM__c> theTMList = new List<TM__c>();
        String readyToBill = 'Ready to Bill';
        String partiallyInvoiced = 'Partially Invoiced';

        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Project_Coordinator__r.Name, Bill_to_Customer__r.Payment_Term__c, Service_Center__r.Name, Sales_Order__r.Name, Contact__r.FirstName, Bill_To_Customer__r.Name';
        strQuery += ' FROM TM__c WHERE (Status__c =: readyToBill OR Status__c = :partiallyInvoiced) AND Sales_Order__c =:orderId ';

        if (!String.isEmpty(tmStartingDateValue)) {
            tmStartDate = Date.parse(tmStartingDateValue);
            strQuery += ' AND Scheduled_Date__c >=: tmStartDate ';
        }

        if (!String.isEmpty(tmEndingDateValue)) {
            tmEndDate = Date.parse(tmEndingDateValue);
            strQuery += ' AND Scheduled_Date__c <=: tmEndDate ';
        }

        strQuery += ' ORDER BY Scheduled_Date__c ASC ';
        theTMList = Database.query(strQuery);

        theTMCreateSIWrapList = new List<TMCreateSIWrapper>();

        if (theTMList != null && theTMList.size() > 0) {
            if (String.isEmpty(tmStartingDateValue)) {
                tmStartDate = theTMList[0].Scheduled_Date__c;
                tmStartingDateValue = tmStartDate.month() + '/' + tmStartDate.day() + '/' + tmStartDate.year();
            }

            if (String.isEmpty(tmEndingDateValue)) {
                tmEndDate = theTMList[theTMList.size() - 1].Scheduled_Date__c;
                tmEndingDateValue = tmEndDate.month() + '/' + tmEndDate.day() + '/' + tmEndDate.year();
            }

            for (Integer i = 0; i < theTMList.size(); i++) {
                theTMWrap = new TMCreateSIWrapper();
                theTMWrap.isSelected = true;
                theTMWrap.theTM = theTMList[i];
                theTMCreateSIWrapList.add(theTMWrap);
            }
        }
         */
        return null;
    }

    //Depreciated
    public void selectTmSections() {
        /*
        theTMSectionList = new List<TMSectionsWrapper>();
        mapTMSectionWrapper = new Map<string, TMSectionsWrapper>();
        mapTMSectionWrapper.put('Labor', new TMSectionsWrapper(true, 'Labor'));
        mapTMSectionWrapper.put('Equipment', new TMSectionsWrapper(true, 'Equipment'));
        mapTMSectionWrapper.put('Materials', new TMSectionsWrapper(true, 'Materials'));
        mapTMSectionWrapper.put('Subcontractors', new TMSectionsWrapper(true, 'Cost Plus Materials, Equipment and Services'));
        mapTMSectionWrapper.put('Waste Disposal', new TMSectionsWrapper(true, 'Waste Disposal'));
        mapTMSectionWrapper.put('Demurrage', new TMSectionsWrapper(true, 'Transportation, Demurrage and Fees'));
        mapTMSectionWrapper.put('Lump Sum', new TMSectionsWrapper(true, 'Lump Sum / Bundled'));
        mapTMSectionWrapper.put('Misc. Charges And Taxes', new TMSectionsWrapper(true, 'Miscellaneous Charges and Taxes'));
        theTMSectionList.addAll(mapTMSectionWrapper.values());
         */
    }

    //Depreciated
    /*
    public List<String> Categories {
        get {
            List<String> lstCategory = new List<String>();
            for (TMSectionsWrapper wrap : theTMSectionList) {
                if (wrap.isSelected) {
                    if (wrap.section == 'Labor') {
                        lstCategory.add('Labor');
                    }

                    if (wrap.section == 'Equipment') {
                        lstCategory.add('Equipment');
                    }

                    if (wrap.section == 'Materials') {
                        lstCategory.add('Materials');
                    }

                    if (wrap.section == 'Cost Plus Materials, Equipment and Services') {
                        lstCategory.add('Subcontractors');
                    }

                    if (wrap.section == 'Waste Disposal') {
                        lstCategory.add('Waste Disposal');
                    }

                    if (wrap.section == 'Transportation, Demurrage and Fees') {
                        lstCategory.add('Demurrage');
                    }

                    if (wrap.section == 'Lump Sum / Bundled') {
                        lstCategory.add('Lump Sum');
                    }

                    if (wrap.section == 'Miscellaneous Charges and Taxes') {
                        lstCategory.add('Misc. Charges And Taxes');
                    }
                }
            }

            return lstCategory;
        }
    }
     */

    //Depreciated
    /*
    public List<TM__c> selectedTMs {
        get {
            List<TM__c> TMList = new List<TM__c>();
            if (theTMCreateSIWrapList != null && theTMCreateSIWrapList.size() > 0) {
                for (TMCreateSIWrapper wrap : theTMCreateSIWrapList) {
                    if (wrap.isSelected) {
                        TMList.add(wrap.theTm);
                    }
                }
            }
            return TMList;
        }
    }
     */

    //Depreciated
    /*
    public PageReference createSI() {
        theSI = new Sales_Invoice__c();
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        Savepoint sp = database.setSavePoint();

        List<Sales_Invoice__c> lstSI = new List<Sales_Invoice__c>();
        lstSI = [SELECT Id, Name FROM Sales_Invoice__c WHERE Sales_Order__c = :orderId AND Document_Status__c = 'Open'];
        if (lstSI != null && lstSI.size() > 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are ' + lstSI.size() + ' open invoices exist for the sales order.'));
            return null;
        }
        try {
            if (Categories == null || Categories.size() <= 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select at least one section'));
                return null;
            }
            selectAllTML();

            boolean isInvoiced = true;

            if (theAllTMLList != null && theAllTMLList.size() > 0) {
                for (TM_Line__c theTML : theAllTMLList) {
                    if (!theTML.Invoiced__c) {
                        isInvoiced = false;
                        break;
                    }
                }

                if (!isInvoiced) {
                    insertSI();
                    theSILList = insertSIL();
                    if (theSILList != null && theSILList.size() > 0) {
                        insert theSILList;
                    }

                    //Update T&M
                    Set<Id> TMId = new Set<Id>();
                    for (TM__c theTM : selectedTMs) {
                        theTM.Sales_Invoice__c = theSI.Id;
                        TMId.add(theTM.Id);
                    }

                    theTMList = [SELECT Id, Name, Total_Lines__c, Invoiced_Lines__c, Status__c FROM TM__c WHERE Id IN:TMId];

                    theTMList = TMMgmt.updateTMStatus(theTMList);

                    update theTMList;

                    PageReference InvoicePage = new PageReference('/apex/SalesInvoice?id=' + theSI.Id);
                    InvoicePage.setRedirect(true);
                    return InvoicePage;
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select atleast one section'));
                    return null;
                }
            }
        } catch (Exception e) {
            Database.Rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no TML that are not invoiced yet.'));
            return null;
        }
        return null;
    }
     */

    //Depreciated
    @TestVisible
    public void selectAllTML() {
        /*
        theAllTMLList = new List<TM_Line__c>();
        Set<String> tmIds = new Set<String>();
        for (TM__c TM : selectedTMs) {
            if (!tmIds.contains(TM.Id)) {
                tmIds.add(TM.Id);
            }
        }

        if (!tmIds.isEmpty()) {
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM_Line__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ', TM__r.Scheduled_Date__c, TM__r.Name, Resource__r.Name, Resource__r.Description__c, Resource_Type__r.Name, Resource_Type__r.Fleet_No_Required__c,Service_Center__r.Equipment_Fleet_No_Not_Required__c ';
            strQuery += ' FROM TM_Line__c WHERE TM__c IN :tmIds AND Category__c IN: Categories AND Invoiced__c = false ORDER BY TM__c, Line_No__c';
            theAllTMLList = Database.query(strQuery);

            calculateLines();
        }
         */
    }

    /*
    //Depreciated
    @TestVisible
    private void calculateLines() {
        if (mapTMSectionWrapper != null) {
            theTMSectionList = new List<TMSectionsWrapper>();
            if (mapTMSectionWrapper.values() != null && mapTMSectionWrapper.values().size() > 0) {
                for (TMSectionsWrapper theWrap : mapTMSectionWrapper.values()) {
                    theWrap.totalLines = 0;
                    theWrap.invoicedLines = 0;
                }
            }

            String category = '';
            if (theAllTMLList != null && theAllTMLList.size() > 0) {
                for (TM_Line__c TML : theAllTMLList) {
                    category = TML.Category__c;
                    if (mapTMSectionWrapper.containsKey(category)) {
                        mapTMSectionWrapper.get(category).totalLines = mapTMSectionWrapper.get(category).totalLines + 1;
                        if (TML.Invoiced__c) {
                            mapTMSectionWrapper.get(category).invoicedLines = mapTMSectionWrapper.get(category).invoicedLines + 1;
                        }
                    }
                }
            }

            theTMSectionList.addAll(mapTMSectionWrapper.values());
        }
    }
     */

    //Depreciated
    /*
    @TestVisible
    private void insertSI() {
        //Sales_Invoice__c theSI = new Sales_Invoice__c();
        theSI.Bill_To_Customer__c = theSO.Bill_to_Customer_No__c;
        theSI = SalesInvoiceMgmt.validateBillToCustomer(theSI);
        theSI.Sales_Order__c = theSO.Id;
        theSI.Posting_Date__c = date.today();
        theSI.Account_Executive__c = theSO.Account_Executives__c;
        theSI.Customer_PO_No__c = theSO.Customer_PO_No__c;
        theSI.Service_Center__c = theSO.Service_Center__c;
        theSI.Subsidiary_Company__c = theSO.Subsidiary_Company__c;
        theSI.Document_Status__c = 'Open';
        theSI.Invoice_Date__c = date.Today();
        theSI.Contact__c = theSO.Bill_to_Contact__c;
        theSI.Bill_to_Customer__r = null;
        theSI.Contact__r = null;
        theSI.Tax_Area__r = null;
        theSI.Site_Name__c = theSO.Site_Name__c;
        theSI.Site_Street__c = theSO.Site_Street__c;
        theSI.Site_City__c = theSO.Site_City__c;
        theSI.Site_State__c = theSO.Site_State__c;
        theSI.Site_Postal_Code__c = theSO.Site_Postal_Code__c;
        theSI.Site_Country__c = theSO.Site_Country__c;
        theSI.Site_Contact__c = theSO.Site_Contact__c;
        theSI.Site_Phone_No__c = theSO.Site_Phone_No__c;
        theSI.Site_Email_Address__c = theSO.Site_Email_Address__c;
        theSI.Tax_Liable__c = theSO.Tax_Liable__c;
        theSI.Tax_Area__c = theSO.Tax_Area__c;
        theSI.Contract__c = theSO.Contract__c;
        insert theSI;
    }
     */

    //Depreciated
    public List<Sales_Invoice_Line__c> insertSIL() {
        Integer i;
        Decimal lineNo = 0;
        List<Sales_Invoice_Line__c> theNewSILList = new List<Sales_Invoice_Line__c>();
        /*
        Sales_Invoice_Line__c newSIL;
        if (theAllTMLList != null && theAllTMLList.size() > 0) {
            for (TM_Line__c theTML : theAllTMLList) {
                lineNo = lineNo + 1;
                newSIL = new Sales_Invoice_Line__c();
                newSIL.Sales_Invoice__c = theSI.Id;
                newSIL.Resource_Type__c = theTML.Resource_Type__c;
                newSIL.Resource__c = theTML.Resource__c;
                if ((!theTML.Resource_Type__r.Fleet_No_Required__c || theTML.Service_Center__r.Equipment_Fleet_No_Not_Required__c)
                        && (newSIL.Resource__c == null)) {
                    newSIL.Resource__c = theCompanySetup.Default_Equipment_Resource__c;
                }
                newSIL.Description__c = theTML.Description__c;
                newSIL.Category__c = theTML.Category__c;
                newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                newSIL.Line_No__c = lineNo;
                newSIL.Tax_Group__c = theTML.Tax_Group__c;
                newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                newSIL.Tax__c = theTML.Tax__c;
                //newSIL.Tax_Liable__c = theTML.Tax_Liable__c;
                newSIL.TM_Line__c = theTML.Id;
                newSIL.TM__c = theTML.TM__c;
                newSIL.Bill_as_Lump_Sum__c = theTML.Bill_as_Lump_Sum__c;
                newSIL.Non_Billable__c = theTML.Non_Billable__c; //Ticket#13673
                newSIL.BOL_Manifest__c = theTML.BOL_Manifest__c;
                newSIL.Scheduled_Date__c = theTML.TM__r.Scheduled_Date__c;
                if (theTML.Category__c != 'Labor') {
                    newSIL.Quantity__c = theTML.Quantity__c;
                    newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                    if (newSIL.Quantity__c != 0) {
                        newSIL.Unit_Price__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(theTML.Line_Amount__c) / newSIL.Quantity__c);
                    } else newSIL.Unit_Price__c = 0;

                    newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                    newSIL.Line_Cost__c = theTML.Line_Cost__c;
                    newSIL.Line_Amount__c = theTML.Line_Amount__c;
                    newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                    newSIL.Tax__c = theTML.Tax__c;
                    newSIL.Line_Amt_Incl_Tax__c = theTML.Line_Amt_Incl_Tax__c;

                    if (!string.isEmpty(saveType) && saveType == 'Lump Sum/Bundled') {
                        newSIL.Bill_as_Lump_Sum__c = true;
                        newSIL.Unit_Price__c = 0;
                        newSIL.Line_Amount__c = 0;
                        newSIL.Tax__c = 0;
                        newSIL.Line_Amt_Incl_Tax__c = 0;
                    }

                    if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                        theNewSILList.add(newSIL);
                    }

                } else {
                    //newSIL.Description__c = theTML.Resource_Type__r.Description__c;

                    if (theTML.Regular_Hours__c != null && theTML.Regular_Hours__c != 0) {
                        newSIL.Quantity__c = theTML.Regular_Hours__c;

                        if (theTML.Use_Premium_Rate__c) newSIL.Unit_Price__c = theTML.Premium_Rate__c;

                        else {
                            newSIL.Unit_Price__c = theTML.Regular_Rate__c;
                        }

                        newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                                CompanyMgmt.zeroIfNull(newSIL.Quantity__c));
                        newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * CompanyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                        newSIL.Line_Amt_Incl_Tax__c = newSIL.Line_Amount__c + newSIL.Tax__c;
                        newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                        newSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Cost__c) *
                                CompanyMgmt.zeroIfNull(newSIL.Quantity__c));
                        if (!string.isEmpty(saveType) && saveType == 'Lump Sum/Bundled') {
                            newSIL.Bill_as_Lump_Sum__c = true;
                            newSIL.Unit_Price__c = 0;
                            newSIL.Line_Amount__c = 0;
                            newSIL.Tax__c = 0;
                            newSIL.Line_Amt_Incl_Tax__c = 0;
                        }
                        if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                            theNewSILList.add(newSIL);
                        }
                    }

                    if (theTML.Overtime_Hours__c != null && theTML.Overtime_Hours__c != 0) {
                        lineNo = lineNo + 1;
                        newSIL = new Sales_Invoice_Line__c();
                        newSIL.Sales_Invoice__c = theSI.Id;
                        newSIL.Resource_Type__c = theTML.Resource_Type__c;
                        newSIL.Resource__c = theTML.Resource__c;
                        newSIL.Description__c = theTML.Description__c + '-OT';
                        newSIL.Category__c = theTML.Category__c;
                        newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                        newSIL.Line_No__c = lineNo;
                        newSIL.Tax_Group__c = theTML.Tax_Group__c;
                        newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                        newSIL.Tax__c = theTML.Tax__c;
                        //newSIL.Tax_Liable__c = theTML.Tax_Liable__c;
                        newSIL.TM_Line__c = theTML.Id;
                        newSIL.TM__c = theTML.TM__c;
                        newSIL.Scheduled_Date__c = theTML.TM__r.Scheduled_Date__c;
                        newSIL.Quantity__c = theTML.Overtime_Hours__c;
                        newSIL.Unit_Price__c = theTML.Overtime_Rate__c;
                        newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                                CompanyMgmt.zeroIfNull(newSIL.Quantity__c));
                        newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * CompanyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                        newSIL.Line_Amt_Incl_Tax__c = newSIL.Line_Amount__c + newSIL.Tax__c;
                        newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                        newSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(newSIL.Unit_Cost__c) *
                                CompanyMgmt.zeroIfNull(newSIL.Quantity__c));
                        if (!string.isEmpty(saveType) && saveType == 'Lump Sum/Bundled') {
                            newSIL.Bill_as_Lump_Sum__c = true;
                            newSIL.Unit_Price__c = 0;
                            newSIL.Line_Amount__c = 0;
                            newSIL.Tax__c = 0;
                            newSIL.Line_Amt_Incl_Tax__c = 0;
                        }
                        if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                            theNewSILList.add(newSIL);
                        }
                    }
                    //Ticket#13673 >>
                    if (theTML.Premium_Hours__c != null && theTML.Premium_Hours__c != 0) {
                        lineNo = lineNo + 1;
                        newSIL = new Sales_Invoice_Line__c();
                        newSIL.Sales_Invoice__c = theSI.Id;
                        newSIL.Resource__c = theTML.Resource__c;
                        newSIL.Resource_Type__c = theTML.Resource_Type__c;
                        newSIL.Description__c = theTML.Description__c + '-PREM';
                        newSIL.Category__c = theTML.Category__c;
                        newSIL.Unit_of_Measure__c = theTML.Unit_of_Measure__c;
                        newSIL.Line_No__c = lineNo;
                        newSIL.Tax_Group__c = theTML.Tax_Group__c;
                        newSIL.Tax_Pct__c = theTML.Tax_Pct__c;
                        newSIL.Tax__c = theTML.Tax__c;
                        newSIL.TM_Line__c = theTML.Id;
                        newSIL.TM__c = theTML.TM__c;
                        newSIL.Scheduled_Date__c = theTML.TM__r.Scheduled_Date__c;
                        newSIL.Quantity__c = theTML.Premium_Hours__c;
                        newSIL.Unit_Price__c = theTML.Premium_Rate__c;
                        newSIL.Line_Amount__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(newSIL.Unit_Price__c) *
                                companyMgmt.zeroIfNull(newSIL.Quantity__c));
                        newSIL.Tax__c = CompanyMgmt.halfUpTo2D(newSIL.Line_Amount__c * companyMgmt.zeroIfNull(newSIL.Tax_Pct__c) / 100);
                        newSIL.Line_Amt_Incl_Tax__c = newSIL.Line_Amount__c + newSIL.Tax__c;
                        newSIL.Unit_Cost__c = theTML.Unit_Cost__c;
                        newSIL.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(newSIL.Unit_Cost__c) *
                                companyMgmt.zeroIfNull(newSIL.Quantity__c));
                        if (newSIL.Quantity__c <> 0 || newSIL.Line_Amt_Incl_Tax__c <> 0) {
                            theNewSILList.add(newSIL);
                        }
                    }
                    //Ticket#13673 >>
                }
                //Update TML
                theTML.Invoiced__c = true;
            }
        }
        //To update Invoiced field
        upsert theAllTMLList;
        */
        return theNewSILList;
    }

    /*//Depreciated
    public class TMCreateSIWrapper {
        public Boolean isSelected {
            get;
            set;
        }

        public TM__c theTM {
            get;
            set;
        }
    }
     */

    /*
    public class TMSectionsWrapper {
        public Boolean isSelected {
            get;
            set;
        }

        public String section {
            get;
            set;
        }

        public Integer totalLines {
            get;
            set;
        }

        public Integer invoicedLines {
            get;
            set;
        }

        public TMSectionsWrapper(Boolean isSelected, String section) {
            this.isSelected = isSelected;
            this.section = section;
            this.totalLines = 0;
            this.invoicedLines = 0;
        }
    }
     */

    //Depreciated
    public void imageUrls() {
        /*
        string imgUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/servlet/servlet.ImageServer?id=';
        String orgId = UserInfo.getOrganizationId();
        string orgURL = '&oid=' + orgId;
        List<Document> documentList = [
                SELECT Name
                FROM Document
                WHERE
                        Name IN ('FB Image', 'Google Image', 'Linkd Image', 'Twitter Image', 'Company Logo')
        ];
        if (documentList != null && documentList.size() > 0) {
            for (Document doc : documentList) {
                if (doc.Name == 'FB Image') {
                    fbURL = imgUrl + doc.id + orgURL;
                }

                if (doc.Name == 'Google Image') {
                    GoogleURL = imgUrl + doc.id + orgURL;
                }

                if (doc.Name == 'Linkd Image') {
                    TwitterURL = imgUrl + doc.id + orgURL;
                }

                if (doc.Name == 'Twitter Image') {
                    linkdURL = imgUrl + doc.id + orgURL;
                }

                if (doc.Name == 'Company Logo') {
                    companyLogoURL = imgUrl + doc.id + orgURL;
                }
            }
        }
         */
    }

    //aura << move the functions to SalesOrderService
    /*
    //Ticket# 13982
    public void updateTMAndSISuperUserChangeBTC (){
        Set<Id> theSIIds = new Set<Id>();
        List<TM__c> theTMsToUpdate = new List<TM__c>();
        // Get Open Sales Invoice Ids and TMs related to each Sales Invoice
        List<Sales_Invoice__c> theSIs = [SELECT Id, Name, (SELECT Id, Name, Sales_Invoice__c,Total_Lines__c, Invoiced_Lines__c FROM T_Ms__r)
                                        FROM Sales_Invoice__c WHERE Sales_Order__c = :theSO.Id AND Document_Status__c <> 'Posted' AND Credit_Memo__c <> TRUE];
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
            theTM.Site_Contact_2__c = null; //AES-401,Ticket#14009
            theTM.From_Sales_Quote__c = null; //Ticket# 14086
            for(TM_Line__c theTML:theTM.TM_Lines__r){ //AES-426 #14086
                theTML.Contract_Line__c = null;
            }
        }
        //update theTMs;
        // Push price
        Integer counter = updateTMPriceFromSO(theTMs);

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
            //theTMList = TMMgmt.updateTMStatus(theTMList);
            for(TM__c theTM : theTMsToUpdate) {
                theTM.Sales_Invoice__c = null;
                theTM.Status__c = 'Ready to Bill';
            }
            update theTMsToUpdate;
        }
        delete theSIs;
    }

    // Ticket# 13982
    public Integer updateTMPriceFromSO (List<TM__c> tms) {
        fflib_SObjectUnitOfWork sow = new fflib_SObjectUnitOfWork(
                new Schema.SObjectType[]{
                        TM__c.SObjectType,
                        TM_Line__c.SObjectType
                }
        );

        Integer counter = 0;
        Map<TM__c, List<TM_Line__c>> tmLinesByTms = new Map<TM__c, List<TM_Line__c>>();
        for(TM__c tm:tms){
            System.debug('Info: ***tm.Bill_to_Customer__c: ' + tm.Bill_to_Customer__c);
            tm.Tax_Liable__c = theSO.Tax_Liable__c;
            tm.Contract__c = theSO.Contract__c;
            sow.registerDirty(tm);
            tmLinesByTms.put(tm, tm.TM_Lines__r);
        }

        TMLLinesService.initStaticVariables(tmLinesByTms);
        for(TM__c tm:tmLinesByTms.keySet()){
            for(TM_Line__c tmLine:tmLinesByTms.get(tm)){
                counter += 1;
                TMLLinesService.calcUnitPrice(tm, tmLine);
                TMLLinesService.calcUnitCost(tm, tmLine);
                if(tmLine.Category__c == 'Labor' && tmLine.Scheduled_Date__c  != null){
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
    */
    //aura >>

    //Ticket#18141
    public void validateAppliesToDoc(){
        try {
            String appliedToDocId = ApexPages.currentPage().getParameters().get('appliedToDocId');
            if (String.isNotBlank(appliedToDocId)) {
                List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{
                        appliedToDocId
                });
                if (salesInvoices.size() > 0) {
                    appliedToInvoice = salesInvoices[0];
                } else {
                    throw new DataException('Invalid applied-to invoice number selected!');
                }
            } else {
                appliedToInvoice = null;
            }
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    //job task
    public PageReference updateTMPrice() {
        Savepoint sp = Database.setSavePoint();
        try {
            Integer counter = BillingWorksheetService.calcWorksheetLinesPricing(theSO);
            isUpdated = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully updated ' + counter + ' Lines.'));
            return null;
        } catch (Exception e) {
            isUpdated = false;
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + e.getStackTraceString()));
            return null;
        }
        return theController.view();
    }

    /*
     *  Ticket#20749 - add sales order contract status for checking
     *  Ticket#21357 - add contact status checking
     */
    public PageReference saveAndSubmit() {
        Savepoint sp = Database.setSavepoint();
        try {
            if(theSO.Contract__c != null && theSO.Contract__r.Status != 'Activated'){
                throw new DataException('You cannot submit this document for approval because associated contract is not activated!');
            }

            if(theSO.Quote_Contact__r.Blocked__c == true){
                throw new DataException('You cannot submit this document for approval because quote contact has been blocked/inactive.');
            }

            if(theSO.Bill_to_Contact__r.Blocked__c == true){
                throw new DataException('You cannot submit this document for approval because bill-to contact has been blocked/inactive.');
            }

            if(theSO.Site_Contact_2__r.Blocked__c == true){
                throw new DataException('You cannot submit this document for approval because site contact has been blocked/inactive.');
            }
            //Ticket#25158 >>
            if(theSO.Estimated_Job_Start_Date__c == null){
                throw new DataException('You cannot submit this document for approval because "Estimated Job Start Date" field is blank.');
            }
            //Ticket#25158 <<

            //Ticket#21908 >>
            String lineNo = '';
            for(Sales_Line__c salesLine : theSLList){
                if(ResourceService.isCalcBaseOnResType(salesLine.Category__c) == true){
                    if (salesLine.Resource_Type__r != null && salesLine.Resource_Type__r.Blocked__c == true) {
                        lineNo = lineNo + salesLine.Line_No__c + ',';
                    }
                } else {
                    if (salesLine.Resource__r != null && salesLine.Resource__r.Blocked__c == true) {
                        lineNo = lineNo + salesLine.Line_No__c + ',';
                    }
                }
            }
            if(lineNo != ''){
                throw new DataException('Please remove following lines, Line No: ' + lineNo + ' before continuing, those lines contain blocked resource type/resource.');
            }
            //Ticket#21908 <<

            if(theSO.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name() && theSO.Document_Type__c != 'Sales Order'){
                this.submitRecordForApproval();
            }
            PageReference pageRef = new PageReference('/' + theSO.Id);
            return pageRef.setRedirect(true);
        }
        catch(Exception e) {
            Database.rollback(sp);
            System.debug('ERROR: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }

    Public void submitRecordForApproval() {
        SalesRecordApprovalProcess salesRecordAP = new SalesRecordApprovalProcess(theSO);
        salesRecordAP.initialApprovalRequest = true;
        salesRecordAP.submitApprovalRequest();
    }

    //Ticket#20749 - add sales order contract status for checking
    public Boolean isApproved{
        get {
            System.debug('theSO====>'+theSO.Approval_Status__c);
                System.debug('theSO====>'+theSO.Document_Type__c);
            if (theSO.Approval_Status__c != EnumUtil.ApprovalStatus.APPROVED.name() && theSO.Document_Type__c != 'Sales Order'){
                if(theSO.Contract__c != null && theSO.Contract__r.Status != 'Activated'){
                    return true;
                } else {
                    return false;
                }
            }
            return true;
        }
        set ;
    }
    
    // 63070, Block to create a credit memo
    public boolean isServCenterChecked{
        
        get {
            if (theSO.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == True)                
                return true;            
            else
                return false;
           
        }
        set ;
    }
    //DE36096
    public PageReference getValidation() {
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        if(profiles.size() > 0){
            if(profiles[0].Name == 'ACV Standard User'){
                String errorMessage = 'You do not have permissions to delete a Quote/Order. Please reach out to you Salesforce Administrator team.';          
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
            }
        }
        return null;
    }        
}