@IsTest
private class SalesOrderController2Test {
    /*
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;

    @IsTest
    private static void testControllerBehavior() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        Id salesOrderId = fflib_IDGenerator.generate(Sales_Order__c.SObjectType);
        Sales_Order__c theSO = new Sales_Order__c(Id = salesOrderId, Name = 'Test');
        Company_Setup__c theCompanySetup = new Company_Setup__c(
                Id = fflib_IDGenerator.generate(Company_Setup__c.SObjectType),
                Review_Invoice_All_No_of_Records__c = 10
        );
        List<TM_Line__c> theTMLList = new List<TM_Line__c>{
                new TM_Line__c(
                        Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                        Line_No__c = 1
                ),
                new TM_Line__c(
                        Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                        Line_No__c = 2
                )
        };
        List<TM__c> theTMList = new List<TM__c>{
                new TM__c(
                        Id = fflib_IDGenerator.generate(TM__c.SObjectType),
                        Scheduled_Date__c = Date.today()
                ),
                new TM__c(
                        Id = fflib_IDGenerator.generate(TM__c.SObjectType)
                )
        };
        PageReference pf = Page.ReviewTMAll;
        Test.setCurrentPage(pf); //
        SalesOrderController2.theCompanySetupValue = theCompanySetup;
        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        SalesOrderController2 controller = new SalesOrderController2(standardController);
        Boolean bool = controller.allowDataOverride;
        pf.getParameters().put('id', theSO.Id);
        try {
            controller = new SalesOrderController2(standardController);
        } catch (Exception e){

        }
        String str = controller.title;
        Boolean bool2 = controller.open;
        Sales_Order__c salesOrder = controller.salesOrder;
        controller.cancel();
        controller.returnBack();
        controller.selFilterField = 'TM__r.Scheduled_Date__c';
        controller.filterInput = String.valueOf(Date.today().format());
        controller.selFilterOp = 'equals';
        controller.filterReviewTMSection();
        controller.selFilterOp = 'contains';
        controller.filterReviewTMSection();
        controller.selFilterOp = 'not contains';
        controller.filterReviewTMSection();
        controller.selFilterOp = 'greater than or equal';
        controller.filterReviewTMSection();
        controller.selFilterOp = 'less than or equal';
        controller.orderBy = 'Name';
        controller.order = 'ASC';
        controller.filterReviewTMSection();
        controller.selFilterField = 'TM__r.Name';
        controller.selFilterOp = 'equals';
        controller.filterReviewTMSection();
        controller.selFilterOp = 'contains';
        controller.filterReviewTMSection();
        controller.selFilterOp = 'not contains';
        controller.filterReviewTMSection();
        controller.selFilterOp = 'greater than or equal';
        controller.filterReviewTMSection();
        controller.selFilterOp = 'less than or equal';
        controller.order = 'DESC';
        controller.filterReviewTMSection();
        controller.theTMList = theTMList;
        try {
            controller.stdCon = new ApexPages.StandardSetController(theTMLList);
            controller.pageSize = 1;
            System.currentPageReference().getParameters().put('objectType', 'TMLine');
            controller.deleteTMLine();
        } catch (Exception e) {

        }
        controller.loadData(theTMLList);
        controller.createTMMaps();
        controller.saveTM();
        controller.quickSaveTM();
        controller.msaveSection();
        controller.saveSection();
        controller.quickSaveSection();
        controller.initalizeReviewTMSection();
        controller.goToReviewAddTMLine();
        controller.goToReviewTMSection();
        controller.addLine();
        controller.addLineOnLoad('TMLine', '');
        controller.addLineOnLoad('TMLine', 'Waste Disposal');
        controller.addLineOnLoad('TMLine', 'Lump Sum');
        controller.addLineOnLoad('TMLine', 'Misc. Charges And Taxes');
        controller.addLineOnLoad('TMLine', 'Subcontractors');
        controller.addLineOnLoad('TMLine', 'Demurrage');
        controller.addLineOnLoad('TMLine', 'Labor');
        System.currentPageReference().getParameters().put('ObjectType','TMLine');
        System.currentPageReference().getParameters().put('LineCategory','Waste Disposal');
        controller.addLine();
        System.currentPageReference().getParameters().put('LineCategory','Lump Sum');
        controller.addLine();
        System.currentPageReference().getParameters().put('LineCategory','Misc. Charges And Taxes');
        controller.addLine();
        System.currentPageReference().getParameters().put('LineCategory','Subcontractors');
        controller.addLine();
        System.currentPageReference().getParameters().put('LineCategory','Demurrage');
        controller.addLine();
        System.currentPageReference().getParameters().put('LineCategory','Labor');
        controller.addLine();
        controller.cancelAddTMline();
        controller.cancelTMSection();
        controller.setOrderBy();
        List<SelectOption> selectOptions = controller.lstFilterOperator;
        List<SelectOption> selectOptions2 = controller.lstFilterField;
        Boolean bool3 = controller.hasNext;
        Boolean bool4 = controller.hasPrevious;
        Integer i = controller.pageNumber;
        controller.first();
        controller.last();
        controller.previous();
        controller.next();
        controller.theTMLListSection = theTMLList;
        String str2 = controller.paginationStat;
        Boolean bool5 = controller.hasRecords;
        Integer i2 = controller.TMLLinesSectionIncludeAll;
        String str3 = controller.selectedTMId;
    }

    @IsTest
    private static void testControllerBehaviorContinue() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();

        Id salesOrderId = fflib_IDGenerator.generate(Sales_Order__c.SObjectType);
        Sales_Order__c theSO = new Sales_Order__c(Id = salesOrderId, Name = 'Test');
        Company_Setup__c theCompanySetup = new Company_Setup__c(
                Id = fflib_IDGenerator.generate(Company_Setup__c.SObjectType),
                Review_Invoice_All_No_of_Records__c = 10
        );
        TM__c theTM = new TM__c(Id = fflib_IDGenerator.generate(TM__c.SObjectType));
        List<TM__c> theTMList = new List<TM__c>{theTM};
        List<TM_Line__c> theTMLList = new List<TM_Line__c>{
                new TM_Line__c(
                        Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                        Line_No__c = 1,
                        TM__c = theTM.Id,
                        Category__c = 'Labor',
                        To_Invoice__c = true
                ),
                new TM_Line__c(
                        Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                        Line_No__c = 2,
                        TM__c = theTM.Id
                )
        };
        PageReference pf = Page.ReviewTMAll;
        Test.setCurrentPage(pf); //
        SalesOrderController2.theCompanySetupValue = theCompanySetup;
        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        SalesOrderController2 controller = new SalesOrderController2(standardController);
        controller.theTMLList = theTMLList;
        controller.theTMList = theTMList;
        System.currentPageReference().getParameters().put('objectType', 'TMLine');
        controller.copyTime();
        theTMLList[0].Job_Start_Time__c = Time.newInstance(1,0,0,0);
        controller.copyTime();
        theTMLList[0].Job_End_Time__c = Time.newInstance(2,0,0,0);
        System.currentPageReference().getParameters().put('timeType', 'BillingTime');
        controller.copyTime();
        theTMLList[0].Billing_Start_Time__c = Time.newInstance(1,0,0,0);
        controller.copyTime();
        theTMLList[0].Billing_End_Time__c = Time.newInstance(2,0,0,0);
        controller.copyTime();
        System.currentPageReference().getParameters().put('timeType', '');
        theTMLList[0].Category__c = 'Labor';
        controller.copyTime();
        theTMLList[0].Site_Start_Time__c = Time.newInstance(1,0,0,0);
        controller.copyTime();
        theTMLList[0].Site_End_Time__c = Time.newInstance(2,0,0,0);
        controller.copyTime();
        theTMLList[0].Lunch_Start_Time__c = Time.newInstance(1,30,0,0);
        controller.copyTime();
        theTMLList[0].Lunch_End_Time__c = Time.newInstance(1,33,0,0);
        controller.copyTime();
        System.currentPageReference().getParameters().put('tmId', theTM.Id);
        System.currentPageReference().getParameters().put('displayId', '1');
        controller.copyTime();
        System.currentPageReference().getParameters().put('timeType', 'BillingTime');
        controller.copyTime();
        controller.stdCon = new ApexPages.StandardSetController(theTMLList);
        controller.invoiceAll();
        controller.invoiceNone();
        controller.lumpSumAll();
        controller.lumpSumNone();
        controller.nonBillableAll();
        controller.nonBillableNone();
        controller.blankRefresh();
        controller.createSIFromReviewTMs();
    }

    @IsTest
    private static void testControllerBehavoirKeepGoing(){

        Company_Setup__c companySetup = new Company_Setup__c(
                //Name = userinfo.getOrganizationname(),
                Name = 'Default',
                //Days_to_Receive__c = 7,
                //Days_to_Ship__c = 2,
                Lines_to_Insert__c = 5,
                //Lot_Days_to_Expire__c = 365,
                //Payment_Term__c = PaymentTermRecord.Id,
                //Warehouse__c = WarehouseRecord.Id,
                //Currency__c = CurrencyRecord.Id,
                Allow_Posting_From__c = Date.newInstance(2015, 1, 1),
                Allow_Posting_To__c = Date.newInstance(2019, 1, 1)
                //Account_AP__c = GLAccountRecord.Id,
                //Account_AR__c = GLAccountRecord.Id,
                //Account_Capacity_Expense__c = GLAccountRecord.Id,
                //Account_Capacity_Variance__c = GLAccountRecord.Id,
                //Account_COGS__c = GLAccountRecord.Id,
                //Account_Finished_Good_Inventory__c = GLAccountRecord.Id,
                //Account_Inventory_Adjustment__c = GLAccountRecord.Id,
                //Account_Material_Variance__c = GLAccountRecord.Id,
                //Account_Purchase_Price_Variance__c = GLAccountRecord.Id,
                //Account_Sales__c = GLAccountRecord.Id,
                //Account_WIP_Inventory__c = GLAccountRecord.Id,
                //Account_Sales_Tax_Payable__c = GLAccountRecord.Id,
                //Account_Raw_Material_Inventory__c = GLAccountRecord.Id,
                //Account_Purchase__c = GLAccountRecord.Id,
                //Account_Sales_Discount__c = GLAccountRecord.Id,
                //Fiscal_Year_Type__c = '445',
                //Fiscal_Year_Start_Month__c = 'April',
                //Fiscal_Start_Date__c = Date.ValueOf('2017-09-01')
        );
        insert companySetup;
        Id salesOrderId = fflib_IDGenerator.generate(Sales_Order__c.SObjectType);
        Sales_Order__c theSO = new Sales_Order__c(Id = salesOrderId, Name = 'Test');
        Company_Setup__c theCompanySetup = new Company_Setup__c(
                Id = fflib_IDGenerator.generate(Company_Setup__c.SObjectType),
                Review_Invoice_All_No_of_Records__c = 10
        );
        TM__c theTM = new TM__c(Id = fflib_IDGenerator.generate(TM__c.SObjectType));
        List<TM__c> theTMList = new List<TM__c>{theTM};
        List<TM_Line__c> theTMLList = new List<TM_Line__c>{
                new TM_Line__c(
                        Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                        Line_No__c = 1,
                        TM__c = theTM.Id,
                        Category__c = 'Labor',
                        To_Invoice__c = true,
                        Invoiced__c = false
                ),
                new TM_Line__c(
                        Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                        Line_No__c = 2,
                        TM__c = theTM.Id,
                        To_Invoice__c = true,
                        Invoiced__c = false
                )
        };
        PageReference pf = Page.ReviewTMAll;
        Test.setCurrentPage(pf); //
        SalesOrderController2.theCompanySetupValue = theCompanySetup;
        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        SalesOrderController2 controller = new SalesOrderController2(standardController);
        controller.theTMLList = theTMLList;
        controller.theTMList = theTMList;
        controller.CalculateSectionTotals();
        String twoHundredAndFiftyOne;
        for (Integer i = 0; i < 200; i++) {
            twoHundredAndFiftyOne += '' + i;
        }
        controller.invoiceNote =  twoHundredAndFiftyOne;
        controller.createSIFromReviewTMs();
        controller.invoiceNote = null;
        controller.createSIFromReviewTMs();
    }
    
    @IsTest
    private static void testValidateTMField() {
        Sales_Order__c theSO = new Sales_Order__c();
        initTestObjects(theSO);
        TM__c TMRecord = [SELECT Id,Status__c, Sales_Order__c, From_Sales_Quote__c, Contract__c, Bill_to_Customer__c, Tax_Liable__c, Tax_Area__c FROM TM__c LIMIT 1];
        List<TM_Line__c> theTMLList = [SELECT Id, Name FROM TM_Line__c WHERE TM__c = :TMRecord.Id];
        Resource_Type__c ResourceTypeRecord = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Resource__c ResourceRecord = [SELECT Id FROM Resource__c LIMIT 1];
        Unit_of_Measure__c UnitMeasureRecord = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Service_Center__c ServiceCenterRecord = [SELECT Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c FROM Service_Center__c LIMIT 1];
        Test.startTest();
        PageReference pref = Page.ReviewTMAll;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', theSO.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(theSO);

        SalesOrderController2 controller = new SalesOrderController2(StdCon);
        controller.mapTM.put(TMRecord.Id,TMRecord);

        controller.theTMLListLabor = [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, TM__c,Unit_Price__c
                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c FROM TM_Line__c
                WHERE Category__c =: 'Labor'];


        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theServiceCenter');
        pref.getParameters().put('newFieldValue', ServiceCenterRecord.Id);
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        controller.validateTMField();


        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theJobPosition');
        pref.getParameters().put('newFieldValue', ResourceTypeRecord.Id );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLUOM');
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theRegularHour');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theRegularRate');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '10' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theOvertimeRate');
        pref.getParameters().put('newFieldValue', null );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'thePremiumRate');
        pref.getParameters().put('newFieldValue', null );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'abc');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theTaxGroup');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLBillasLumpSum');
        pref.getParameters().put('newFieldValue', 'false' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '123' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLNonBillable');
        pref.getParameters().put('newFieldValue', 'false' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '123' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLUnitPrice');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLQuantity');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLToInvoice');
        pref.getParameters().put('newFieldValue', 'true' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLUOM');
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.theTMLListLabor[0].Resource_Type__c = null;
        controller.validateTMField();

        Test.stopTest();
    }

    @IsTest
    private static void testValidateTMFieldLaborTimes() {
        Sales_Order__c theSO = new Sales_Order__c();
        initTestObjects(theSO);
        TM__c TMRecord = [SELECT Id,Status__c, Sales_Order__c, From_Sales_Quote__c, Contract__c, Bill_to_Customer__c, Tax_Liable__c FROM TM__c LIMIT 1];
        List<TM_Line__c> theTMLList = [SELECT Id, Name FROM TM_Line__c WHERE TM__c = :TMRecord.Id];
        Resource_Type__c ResourceTypeRecord = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Resource__c ResourceRecord = [SELECT Id FROM Resource__c LIMIT 1];
        Unit_of_Measure__c UnitMeasureRecord = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Service_Center__c ServiceCenterRecord = [SELECT Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c FROM Service_Center__c LIMIT 1];
        Test.startTest();
        PageReference pref = Page.ReviewTMAll;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', theSO.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(theSO);

        SalesOrderController2 controller = new SalesOrderController2(StdCon);
        controller.mapTM.put(TMRecord.Id,TMRecord);

        controller.theTMLListLabor = [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, TM__c,Unit_Price__c
                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c
        FROM TM_Line__c WHERE Category__c =: 'Labor'];


        pref.getParameters().put('lineNo', '0');

        pref.getParameters().put('fieldName', 'theLunchStartTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLunchStartTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLunchStartTime');
        pref.getParameters().put('newFieldValue', '1002' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'null' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLunchEndTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLunchEndTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLunchEndTime');
        pref.getParameters().put('newFieldValue', '1002' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theBillingStartTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theBillingStartTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theBillingStartTime');
        pref.getParameters().put('newFieldValue', '1002' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theBillingEndTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theBillingEndTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theBillingEndTime');
        pref.getParameters().put('newFieldValue', '1002' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theJobStartTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theJobEndTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theJobStartTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theJobStartTime');
        pref.getParameters().put('newFieldValue', '1002' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSiteStartTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSiteEndTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSiteStartTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSiteStartTime');
        pref.getParameters().put('newFieldValue', '1002' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLContractLine');
        pref.getParameters().put('newFieldValue', Null );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLContractLine');
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theUsePremiumRate');
        pref.getParameters().put('newFieldValue', null );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'abc');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theBillSiteTime');
        pref.getParameters().put('newFieldValue', null );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLunch');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', null );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theOvertimeHour');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'thePremiumHours');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'thePremiumRate');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theOvertimeRate');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();
        Test.stopTest();
    }
    
    private static void initTestObjects(Sales_Order__c theSO){
        CompanyMgmt.byPassTrigger = true;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        //TM
        TM__c TMRecord = TestDataUtil.TMRecord;
        //TM Line

        TM_Line__c TMLineLaborRecord = TestDataUtil.TMLineLaborRecord;
        TM_Line__c TMLineEquipmentRecord = TestDataUtil.TMLineEquipmentRecord;
        TM_Line__c TMLineMaterialRecord = TestDataUtil.TMLineMaterialRecord ;
        TM_Line__c TMLineSubcontractorsRecord = TestDataUtil.TMLineSubcontractorsRecord ;
        TM_Line__c TMLineWasteDisposalRecord = TestDataUtil.TMLineWasteDisposalRecord ;
        TM_Line__c TMLineDemurrageRecord = TestDataUtil.TMLineDemurrageRecord;
        TM_Line__c TMLineLumpSumRecord = TestDataUtil.TMLineLumpSumRecord ;
        TM_Line__c TMLineMiscRecord = TestDataUtil.TMLineMisChargeRecord ;
        //Others
        Resource__c eqRes = TestDataUtil.ResourceEquipmentRecord;
        Resource_Type__c ResourceTypeRecord = TestDataUtil.ResourceTypeRecord;
        Service_Center__c sc = TestDataUtil.ServiceCenterRecord;
        Tax_Area__c TaxAreaRecord = TestDataUtil.TaxAreaRecord;
        Tax_Jurisdiction__c taxJurisdiction = TestDataUtil.TaxJurisdictionRecord;
        Tax_Detail__c taxDetail = TestDataUtil.TaxDetailRecord;
        Unit_of_Measure__c uom = TestDataUtil.UnitMeasureRecord;
        Resource__c transRes = TestDataUtil.ResourceTransportationRecord;
        Contract_Line__c ContractLineRecord = TestDataUtil.ContractLineRecord;
        Site_Address__c SiteAddressRecord = TestDataUtil.SiteAddressRecord;
        Contract  ContractRecord = TestDataUtil.ContractRecord;
        theSO = TestDataUtil.SalesOrderRecord;
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        Sales_Line__c SalesEquipmentLineRecord = TestDataUtil.SalesEquipmentLineRecord;
        Sales_Line__c SalesWasteLineRecord = TestDataUtil.SalesWasteLineRecord;
        List<Company_Setup__c> theCSList = [SELECT Id FROM Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
        CompanyMgmt.byPassTrigger = false;
    }
    @IsTest
    private static void Test_validateTMFields2() {
        Sales_Order__c theSO = new Sales_Order__c();
        initTestObjects(theSO);
        TM__c TMRecord = [SELECT Id,Status__c, Sales_Order__c, From_Sales_Quote__c, Contract__c, Bill_to_Customer__c, Tax_Liable__c, Tax_Area__c FROM TM__c LIMIT 1];
        TM_Line__c TMLineRecord = [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, TM__c,Unit_Price__c
                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c FROM TM_Line__c
                WHERE Category__c =: 'Equipment'];

        Resource_Type__c ResourceTypeRecord = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Resource__c ResourceRecord = [SELECT Id FROM Resource__c LIMIT 1];
        Unit_of_Measure__c UnitMeasureRecord = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Service_Center__c ServiceCenterRecord = [SELECT Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c FROM Service_Center__c LIMIT 1];
        Test.startTest();
        PageReference pref = Page.ReviewTMAll;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', theSO.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(theSO);

        SalesOrderController2 controller = new SalesOrderController2(StdCon);
        controller.mapTM.put(TMRecord.Id,TMRecord);
        

        controller.theTMLListEquipment = new List<TM_Line__c>{TMLineRecord};


        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theEquipment');
        pref.getParameters().put('newFieldValue', ResourceTypeRecord.Id );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theEServiceCenter');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', ServiceCenterRecord.Id );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theEResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        controller.validateTMField();


        pref.getParameters().put('fieldName', 'theESiteStartTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.theTMLListEquipment[0].Category__c = 'Equipment';
        controller.theTMLListEquipment[0].Regular_Hours__c = 0;
        controller.theTMLListEquipment[0].Overtime_Hours__c = 0;
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theESiteEndTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1002' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theEUOM');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.validateTMField();


        pref.getParameters().put('fieldName', 'theEBillingStartTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('fieldName', 'theEBillingEndTime');
        pref.getParameters().put('newFieldValue', '05:00' );
        controller.theTMLListEquipment[0].Include_Lunch_Y_N__c = true;
        controller.validateTMField();
        controller.theTMLListEquipment[0].Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        controller.theTMLListEquipment[0].Lunch_End_Time__c = Time.newInstance(12,30,0,0);
        controller.validateTMField();
        controller.theTMLListEquipment[0].Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        controller.theTMLListEquipment[0].Lunch_End_Time__c = Time.newInstance(13,0,0,0);
        controller.validateTMField();
        controller.theTMLListEquipment[0].Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        controller.theTMLListEquipment[0].Lunch_End_Time__c = Time.newInstance(13,30,0,0);
        controller.validateTMField();


        pref.getParameters().put('fieldName', 'theEBillasLumpSum');
        pref.getParameters().put('newFieldValue', null );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theEQuantity');
        pref.getParameters().put('newFieldValue', null );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theEUnitPrice');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theETaxGroup');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theEContractLine');
        pref.getParameters().put('newFieldValue', null );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();
        pref.getParameters().put('fieldName', 'theENonBillable');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'false');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theEToInvoice');
        pref.getParameters().put('newFieldValue', 'true' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theEUOM');
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.theTMLListEquipment[0].Resource_Type__c = null;
        controller.validateTMField();
        Test.stopTest();
    }
    @IsTest
    private static void testValidateTMFields3() {
        Sales_Order__c theSO = new Sales_Order__c();
        initTestObjects(theSO);
        TM__c TMRecord = [SELECT Id,Status__c, Sales_Order__c, From_Sales_Quote__c, Contract__c, Bill_to_Customer__c, Tax_Liable__c,Tax_Area__c FROM TM__c LIMIT 1];
        Resource_Type__c ResourceTypeRecord = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Resource__c ResourceRecord = [SELECT Id FROM Resource__c LIMIT 1];
        Unit_of_Measure__c UnitMeasureRecord = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Service_Center__c ServiceCenterRecord = [SELECT Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c FROM Service_Center__c LIMIT 1];
        Test.startTest();
        PageReference pref = Page.ReviewTMAll;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', theSO.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(theSO);

        SalesOrderController2 controller = new SalesOrderController2(StdCon);
        controller.mapTM.put(TMRecord.Id,TMRecord);

        Unit_of_Measure__c uom = UnitMeasureRecord;
        TM_Line__c TMLineMaterialRecord =   [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, TM__c,Unit_Price__c
                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c
        FROM TM_Line__c WHERE Category__c =: 'Materials'];


        controller.theTMLListMaterials = new List<TM_Line__c>();
        controller.theTMLListMaterials.add(TMLineMaterialRecord);

        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theMResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMQuantity');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMUOM');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.validateTMField();
        controller.theTMLListMaterials[0].resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMBillasLumpSum');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMNonBillable');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMContractLine');
        pref.getParameters().put('newFieldValue', Null );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMToInvoice');
        pref.getParameters().put('newFieldValue', 'true' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        Test.stopTest();
    }
    
    @IsTest
    private static void testValidaeTMField4(){
        Sales_Order__c theSO = new Sales_Order__c();
        initTestObjects(theSO);
        TM__c TMRecord = [SELECT Id,Status__c, Sales_Order__c, From_Sales_Quote__c, Contract__c, Bill_to_Customer__c, Tax_Liable__c, Tax_Area__c FROM TM__c LIMIT 1];
        Resource_Type__c ResourceTypeRecord = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Resource__c ResourceRecord = [SELECT Id FROM Resource__c LIMIT 1];
        Unit_of_Measure__c UnitMeasureRecord = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Service_Center__c ServiceCenterRecord = [SELECT Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c FROM Service_Center__c LIMIT 1];
        Test.startTest();
        PageReference pref = Page.ReviewTMAll;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', theSO.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(theSO);

        SalesOrderController2 controller = new SalesOrderController2(StdCon);
        controller.mapTM.put(TMRecord.Id,TMRecord);

        Unit_of_Measure__c uom = UnitMeasureRecord;

        controller.theTMLListSubcontractors =  [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, TM__c,Unit_Price__c
                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c,
                Cost_Method__c,Min_Sell_Qty__c,Container_Size__c,Unit_Weight_Vol__c,Facility__c,
                Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c FROM TM_Line__c
                WHERE Category__c =: 'Subcontractors'];

        controller.theTMLListWasteDisposal =  [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, TM__c,Unit_Price__c
                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c,
                Cost_Method__c,Min_Sell_Qty__c,Container_Size__c,Unit_Weight_Vol__c,Facility__c
                FROM TM_Line__c
                WHERE Category__c =: 'Waste Disposal'];

        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theSResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSQuantity');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSUOM');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSUnitPrice');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSMarkup');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSMarkupOption');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSTaxGroup');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSToInvoice');
        pref.getParameters().put('newFieldValue', 'true' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();


        pref.getParameters().put('fieldName', 'theWResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theWQuantity');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theWUOM');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theWUnitPrice');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theWMarkupOption');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'ABC' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theWMarkup');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theWTaxGroup');
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theWToInvoice');
        pref.getParameters().put('newFieldValue', 'true' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theWUOM');
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.theTMLListWasteDisposal[0].Resource__c = TestDataUtil.ResourceWasteDisposalRecord.Id;
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theSUOM');
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.theTMLListSubcontractors[0].Resource__c = TestDataUtil.ResourceSubcontractorRecord.Id;
        controller.validateTMField();

        Test.stopTest();
    }
    
    @IsTest
    private static void testValidateTMField5() {
        Sales_Order__c theSO = new Sales_Order__c();
        initTestObjects(theSO);
        TM__c TMRecord = [SELECT Id,Status__c, Sales_Order__c, From_Sales_Quote__c, Contract__c,Sales_Order__r.Billing_Rule_Not_Required__c,
                Bill_to_Customer__c, Tax_Liable__c, Name, Scheduled_Date__c, Billing_Rule_Id__c, Tax_Area__c FROM TM__c LIMIT 1];
        Resource_Type__c ResourceTypeRecord = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Resource__c ResourceTransportationRecord = [SELECT Id FROM Resource__c WHERE Name =: 'TRAN2' LIMIT 1];
        Unit_of_Measure__c UnitMeasureRecord = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Service_Center__c ServiceCenterRecord = [SELECT Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c FROM Service_Center__c LIMIT 1];
        Test.startTest();
        PageReference pref = Page.ReviewTMAll;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', theSO.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(theSO);

        SalesOrderController2 controller = new SalesOrderController2(StdCon);
        controller.mapTM.put(TMRecord.Id,TMRecord);

        Unit_of_Measure__c uom = UnitMeasureRecord;

        List<TM_Line__c> testTMLList = [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, TM__c,Regular_Hours__c, Overtime_Hours__c, Premium_Hours__c, Unit_of_Measure__c, Hour__c,Billing_End_Time__c,
                Billing_Start_Time__c,Unit_Price__c ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c,
                Cost_Method__c,Min_Sell_Qty__c,Container_Size__c,Unit_Weight_Vol__c,Facility__c,
                Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c FROM TM_Line__c];
        controller.theTMLListDemurrage = testTMLList;
        controller.theTMLList = testTMLList;
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theDResource');
        pref.getParameters().put('newFieldValue', ResourceTransportationRecord.Id );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'Invalid');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue',TestDataUtil.ResourceRecord.Id);
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        //companySetup.Default_Transportation_Resource__c = TestDataUtil.ResourceRecord.Id;
        update companySetup;
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theDSiteStartTime');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theDSiteEndTime');
        pref.getParameters().put('newFieldValue', '1:2' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1002' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theDQuantity');
        pref.getParameters().put('newFieldValue', null );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theDUOM');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.ID );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theDUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theDTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theDToInvoice');
        pref.getParameters().put('newFieldValue', 'true' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theDUOM');
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.ID );
        controller.theTMLListDemurrage[0].Resource__c = TestDataUtil.ResourceDemurrageRecord.Id;
        controller.validateTMField();
        controller.theTMLListDemurrage[0].Resource__c = null;
        controller.validateTMField();
        Test.stopTest();
    }
    
    @IsTest
    private static void testValidateTMFieldLumpSumSection(){
        Sales_Order__c theSO = new Sales_Order__c();
        initTestObjects(theSO);
        TM__c TMRecord = [SELECT Id,Status__c, Sales_Order__c, From_Sales_Quote__c, Contract__c, Bill_to_Customer__c, Tax_Liable__c,Tax_Area__c FROM TM__c LIMIT 1];
        Resource_Type__c ResourceTypeRecord = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Unit_of_Measure__c UnitMeasureRecord = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Service_Center__c ServiceCenterRecord = [SELECT Id,Name,Max_No_of_Emergency_T_M__c,Subsidiary_Company__c FROM Service_Center__c LIMIT 1];
        PageReference pref = Page.ReviewTMAll;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', theSO.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(theSO);

        SalesOrderController2 controller = new SalesOrderController2(StdCon);
        controller.mapTM.put(TMRecord.Id,TMRecord);

        Unit_of_Measure__c uom = UnitMeasureRecord;
        List<TM_Line__c> testTMLList = [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, TM__c,Unit_Price__c
                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Tax_Group__c, Cost_Qty__c, Tax_Pct__c, Line_Cost__c FROM TM_Line__c];
        controller.theTMLListLumpSum = testTMLList;
        Test.startTest();
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theLumpSumResourceType');
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', ResourceTypeRecord.Id);
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', 'abc');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLumpQuantity');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLumpUOM');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLumpUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLumpSumContractLine');
        pref.getParameters().put('newFieldValue', '');
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '7777');
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLumpTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLumpToInvoice');
        pref.getParameters().put('newFieldValue', 'true' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theLumpUOM');
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.theTMLListLumpSum[0].Resource__c = TestDataUtil.ResourceLumpSumRecord.Id;
        controller.validateTMField();
        Test.stopTest();
    }
    
    @IsTest
    private static void testValidateTMFieldMiscSection(){
        Sales_Order__c theSO = new Sales_Order__c();
        initTestObjects(theSO);
        TM__c TMRecord = [SELECT Id,Status__c, Sales_Order__c, From_Sales_Quote__c, Contract__c, Bill_to_Customer__c,
                Tax_Liable__c, Name, Scheduled_Date__c, Billing_Rule_Id__c,Tax_Area__c, Sales_Order__r.Billing_Rule_Not_Required__c FROM TM__c LIMIT 1];
        Unit_of_Measure__c UnitMeasureRecord = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        PageReference pref = Page.ReviewTMAll;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', theSO.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(theSO);

        SalesOrderController2 controller = new SalesOrderController2(StdCon);
        controller.mapTM.put(TMRecord.Id,TMRecord);

        Unit_of_Measure__c uom = UnitMeasureRecord;
        List<TM_Line__c> testTMLList = [SELECT Id,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c
                ,Site_End_Time__c,Lunch_Start_Time__c,Lunch_End_Time__c, TM__c,Regular_Hours__c, Overtime_Hours__c, Premium_Hours__c, Unit_of_Measure__c, Hour__c,Billing_End_Time__c, Billing_Start_Time__c,Unit_Price__c
                ,Unit_Cost__c, Markup_Option__c, Markup__c, Tax__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Tax_Group__c, Cost_Qty__c,
                Cost_Method__c,Min_Sell_Qty__c,Container_Size__c,Unit_Weight_Vol__c,Facility__c,
                Tax_Pct__c, Line_Cost__c FROM TM_Line__c];
        controller.theTMLListMisc = testTMLList;
        Test.startTest();
        pref.getParameters().put('lineNo', '0');

        pref.getParameters().put('fieldName', 'theMiscQuantity');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMiscUOM');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', UnitMeasureRecord.Id );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMiscUnitPrice');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMiscTaxGroup');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();

        pref.getParameters().put('fieldName', 'theMiscResource');
        pref.getParameters().put('newFieldValue', '' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', '1' );
        controller.validateTMField();
        pref.getParameters().put('newFieldValue', fflib_IDGenerator.generate(Resource__c.SObjectType));
        controller.validateTMField();

        Test.stopTest();
    }
     */
}