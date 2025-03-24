@isTest
public class SalesOrderTest {
    
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data.
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        //Resource__c ResourceRecord = TestDataUtil.ResourceRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = :companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
        //Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
    }
    
    private static testMethod void Test_SalesOrderMgmt() {
        Test.startTest();
        Sales_Order__c theSO = TestDataUtil.SalesOrderRecord;
        SalesOrderMgmt.validateSalespeople(theSO);
        SalesOrderMgmt.validateSalespeople(TestDataUtil.SalesOrderRecordCSA);
        SalesOrderMgmt.validateContract(theSO);
        SalesOrderMgmt.validateContract(TestDataUtil.SalesOrderRecordCSA);
        SalesOrderMgmt.validateAltSiteAddress(theSO);
        SalesOrderMgmt.validateCreateSiteAddress(theSO);
        theSO.Alternate_Site_Address__c = TestDataUtil.SiteAddressRecord.Id;
        SalesOrderMgmt.validateContract(TestDataUtil.SalesOrderRecordCSA);
        SalesOrderMgmt.validateAltSiteAddress(TestDataUtil.SalesOrderRecordCSA);
        Sales_Order__c so2 = TestDataUtil.SalesOrderRecordCSA;
        so2.Site_Name__c = 'Test SIte Name xxxx';
        SalesOrderMgmt.validateCreateSiteAddress(so2);
        Sales_Line__c salesline = TestDataUtil.SalesLineRecord;
        SalesOrderMgmt.updateSL(salesline, theSO, 'theMaterial');
        SalesOrderMgmt.updateSL(salesline, theSO, 'theResource');
        SalesOrderMgmt.updateSL(salesline, theSO, 'theLResource');
        SalesOrderMgmt.updateSL(salesline, theSO, 'theEResource');
        salesline.Contract_Line__c = TestDataUtil.ContractLineRecord.id;
        salesline.Quantity__c = 1100;
        update salesline;
        SalesOrderMgmt.updateSL(salesline, theSO, 'theLContractLine');
        SalesOrderMgmt.setResourceType(salesline, theSO);
        SalesOrderMgmt.updateSL(salesline, theSO, 'theMContractLine');
        SalesOrderMgmt.updateSL(salesline, theSO, 'theTaxGroup');
        SalesOrderMgmt.updateSL(salesline, theSO, 'theResourceType');

        SalesOrderMgmt.nullRelationshipFields(theSO);
        SalesOrderMgmt.setPricing(salesline, theSO);
        salesline.Category__c = 'Equipment';
        salesline.Quantity__c = 1100;
        update salesline;
        SalesOrderMgmt.setPricing(salesline, theSO);
        salesline.Category__c = 'Labor';
        salesline.Quantity__c = 1100;
        update salesline;
        SalesOrderMgmt.setPricing(salesline, theSO);
        salesline.Category__c = 'Materials';
        salesLine.Resource_Type__c = null;
        salesline.Quantity__c = 1100;
        update salesline;
        Test.stopTest();
//        SalesOrderMgmt.setPricing(salesline, theSO);
//        SalesOrderMgmt.validateTaxArea(theSO);
//        theSO.Contract__c=TestDataUtil.ContractRecord.Id;
//        update theSO;
//        Contract_Line__c  ContractLineRecord = new Contract_Line__c (Name='Test ContractLine',Contract__c=theSO.Contract__c,Premium_Rate__c=10,Resource__c=TestDataUtil.ResourceRecord.Id,Resource_Type__c=TestDataUtil.ResourceTypeRecord.id,Unit_of_Measure__c=TestDataUtil.UnitMeasureRecord.id);
//        insert ContractLineRecord ;
    }


    private static testMethod void Test_SalesOrderController() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        Sales_Line__c SalesContractLineRecord = TestDataUtil.SalesContractLineRecord;
        
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        String title = inst_SOC.title;
        Boolean open = inst_SOC.Open;
//        Boolean completed = inst_SOC.Completed;
        boolean allowDataOverride = inst_SOC.allowDataOverride;
        boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
        inst_SOC.includeWeekend = True;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        Sales_Order__c SO = inst_SOC.salesOrder;
        //inst_SOC.updateReceiptDate();
        List<Sales_Line__c> SLList = inst_SOC.SLList;
        //Company_Setup__c CompanySetup = inst_SOC.CompanySetup;
        inst_SOC.validateSalesOrderType();
        inst_SOC.validateSalespeople();
        inst_SOC.validateContract();
        List<Sales_Line__c> SOListLaborLines = inst_SOC.SOListLaborLines;
        List<Sales_Line__c> SOListMaterialLines = inst_SOC.SOListMaterialLines;
        List<Sales_Line__c> SOListEquipmentLines = inst_SOC.SOListEquipmentLines;

        Test.startTest();

//        SalesOrderController.TMWrap r1=new SalesOrderController.TMWrap(Date.Today(),'test');
        inst_SOC.theTMWrapList = New List<SalesOrderController.TMWrap>();
//        inst_SOC.theTMWrapList.add(r1);
        inst_SOC.CreateTM();
        inst_SOC.CreateTMfromSO();
        inst_SOC.CloneSO();
        inst_SOC.goToNewSO();
        inst_SOC.cancel();
        inst_SOC.returnBack();
        inst_SOC.validateAltSiteAddress();

        Test.stopTest();

    }

    private static testMethod void Test_SalesOrderController2() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
		     CompanyMgmt.byPassTrigger = true;

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        Resource__c ResourceRecord = [SELECT Id,Name,Tax_Group__c,Unit_of_Measure__c,Resource_Type__c FROM Resource__c Limit 1];
        String title = inst_SOC.title;
        Boolean open = inst_SOC.Open;
        boolean allowDataOverride = inst_SOC.allowDataOverride;
        boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
        inst_SOC.includeWeekend = True;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        Sales_Order__c SO = inst_SOC.salesOrder;
        List<Sales_Line__c> SLList = inst_SOC.SLList;
        inst_SOC.validateSalesOrderType();
        inst_SOC.validateSalespeople();
        inst_SOC.validateContract();

        List<Sales_Line__c> SOListLaborLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListMaterialLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListEquipmentLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListEquipLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListLumpSumLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListWasteDisposalLines = New List<Sales_Line__c>();

        SOListEquipLines.add(TestDataUtil.SalesEquipmentLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesMaterialLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesMiscLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesLumpSumLineRecord);
        SOListLumpSumLines.add(TestDataUtil.SalesLumpSumLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesWasteLineRecord);

        inst_SOC.theSLList = SOListEquipLines;
        inst_SOC.theSOListLumpSum = SOListLumpSumLines;
        Test.startTest();

        inst_SOC.createTemporaryTmList();

        pref.getParameters().put('objectType', 'SalesLine');
        inst_SOC.insertLine();

        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theQuantity');
        pref.getParameters().put('newFieldValue', '1');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theJobPositionINPT');
        pref.getParameters().put('newFieldValue', '2');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theEquipmentINPT');
        pref.getParameters().put('newFieldValue', '3');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theEquipmentINPT');
        pref.getParameters().put('newFieldValue', ResourceRecord.Resource_Type__c);
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theMaterialINPT');
        pref.getParameters().put('newFieldValue', '4');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theMaterialINPT');
        pref.getParameters().put('newFieldValue', TestDataUtil.SalesMaterialLineRecord.Resource__c);
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theLLUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theJobPositionINPT');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theJobPositionINPT');
        pref.getParameters().put('newFieldValue', 'test');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theJobPositionINPT');
        pref.getParameters().put('newFieldValue', ResourceRecord.Resource_Type__c);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theSResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SOC.validateField();


        Test.stopTest();

    }


    private static testMethod void Test_SalesOrderController2b() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
		     CompanyMgmt.byPassTrigger = true;

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        Resource__c ResourceRecord = [SELECT Id,Name,Tax_Group__c,Unit_of_Measure__c,Resource_Type__c FROM Resource__c Limit 1];
        String title = inst_SOC.title;
        Boolean open = inst_SOC.Open;
        boolean allowDataOverride = inst_SOC.allowDataOverride;
        boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
        inst_SOC.includeWeekend = True;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        Sales_Order__c SO = inst_SOC.salesOrder;
        //inst_SOC.updateReceiptDate();
        List<Sales_Line__c> SLList = inst_SOC.SLList;
        //Company_Setup__c CompanySetup = inst_SOC.CompanySetup;
        inst_SOC.validateSalesOrderType();
        inst_SOC.validateSalespeople();
        inst_SOC.validateContract();

        List<Sales_Line__c> SOListLaborLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListMaterialLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListEquipmentLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListEquipLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListLumpSumLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListWasteDisposalLines = New List<Sales_Line__c>();

        SOListEquipLines.add(TestDataUtil.SalesEquipmentLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesMaterialLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesMiscLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesLumpSumLineRecord);
        SOListLumpSumLines.add(TestDataUtil.SalesLumpSumLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesWasteLineRecord);

        inst_SOC.theSLList = SOListEquipLines;
        inst_SOC.theSOListLumpSum = SOListLumpSumLines;
        Test.startTest();

        inst_SOC.createTemporaryTmList();

        pref.getParameters().put('objectType', 'SalesLine');
        inst_SOC.insertLine();

        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theQuantity');
        pref.getParameters().put('newFieldValue', '1');
        inst_SOC.validateField();
        
        pref.getParameters().put('fieldName', 'theLContractLine');
        pref.getParameters().put('newFieldValue', TestDataUtil.ContractLineRecord.Id);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLContractLine');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMContractLine');
        pref.getParameters().put('newFieldValue', TestDataUtil.ContractLineRecord.Id);
        inst_SOC.validateField();
        pref.getParameters().put('newFieldValue', 'abc');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLQuantity');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLQuantity');
        pref.getParameters().put('newFieldValue', '5');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theEQuantity');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theEQuantity');
        pref.getParameters().put('newFieldValue', '5');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMQuantity');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMQuantity');
        pref.getParameters().put('newFieldValue', '5');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLTaxGroup');
        pref.getParameters().put('newFieldValue', 'tst');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLTaxGroup');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theETaxGroup');
        pref.getParameters().put('newFieldValue', 'tst');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theETaxGroup');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMTaxGroup');
        pref.getParameters().put('newFieldValue', 'tst');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMTaxGroup');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        Test.stopTest();

    }
    
    private static testMethod void Test_SalesOrderController3() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);

        
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        /*
        Contract_Line__c ContractLineRecord = TestDataUtil.ContractLineRecord;
        TM__c TMRecord = TestDataUtil.TMRecord;
        TM_Line__c TMLineRecord = TestDataUtil.TMLineLaborRecord;
        //TM_Line__c TMLineRecord2 = TestDataUtil.TMLineDemurrageRecord;
        TM_Line__c TMLineRecord3 = TestDataUtil.TMLineSubcontractorsRecord;
        //TM_Line__c TMLineRecord4 = TestDataUtil.TMLineMisChargeRecord;
        TM_Line__c TMLineRecord5 = TestDataUtil.TMLineLumpSumRecord;  
        TM_Line__c TMLineRecord6 = TestDataUtil.TMLineWasteDisposalRecord;
        TM_Line__c TMLineRecord7 = TestDataUtil.TMLineMaterialRecord;
        //TM_Line__c TMLineRecord8 = TestDataUtil.TMLineEquipmentRecord;
        Tax_Area__c TaxAreaRecord = TestDataUtil.TaxAreaRecord;
         */

        Test.startTest();

        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        String title = inst_SOC.title;
        Boolean open = inst_SOC.Open;
        boolean allowDataOverride = inst_SOC.allowDataOverride;
        boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
        inst_SOC.includeWeekend = True;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        Sales_Order__c SO = inst_SOC.salesOrder;
        List<Sales_Line__c> SLList = inst_SOC.SLList;
        Company_Setup__c CompanySetup = inst_SOC.CompanySetup;

        /*
        inst_SOC.validateSalesOrderType();
        inst_SOC.validateSalespeople();
        inst_SOC.validateContract();
         */
        List<Sales_Line__c> SOListLaborLines = inst_SOC.SOListLaborLines;
        List<Sales_Line__c> SOListMaterialLines = inst_SOC.SOListMaterialLines;
        List<Sales_Line__c> SOListEquipmentLines = inst_SOC.SOListEquipmentLines;
        String[] messagesWS = inst_SOC.getMessages();



        //inst_SOC.PrintConfirmation();
        //inst_SOC.notValidatePrintConfirmation();

        /*
        inst_SOC.save();
        inst_SOC.quickSave();
        inst_SOC.LaborAssumption = 'OvertimeRate';
        inst_SOC.quickSave();
        inst_SOC.LaborAssumption = 'DailyRate';
        inst_SOC.quickSave();
        inst_SOC.LaborAssumption = 'LumpSum';
        inst_SOC.quickSave();
         */
        ///////////////////////////
        Test.stopTest();

    }

    private static testMethod void Test_SalesOrderController3Extend() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        Contract_Line__c ContractLineRecord = TestDataUtil.ContractLineRecord;
        /*
        TM__c TMRecord = TestDataUtil.TMRecord;
        TM_Line__c TMLineRecord = TestDataUtil.TMLineLaborRecord;
        //TM_Line__c TMLineRecord2 = TestDataUtil.TMLineDemurrageRecord;
        TM_Line__c TMLineRecord3 = TestDataUtil.TMLineSubcontractorsRecord;
        //TM_Line__c TMLineRecord4 = TestDataUtil.TMLineMisChargeRecord;
        TM_Line__c TMLineRecord5 = TestDataUtil.TMLineLumpSumRecord;
        TM_Line__c TMLineRecord6 = TestDataUtil.TMLineWasteDisposalRecord;
        TM_Line__c TMLineRecord7 = TestDataUtil.TMLineMaterialRecord;
        //TM_Line__c TMLineRecord8 = TestDataUtil.TMLineEquipmentRecord;
         */
        Tax_Area__c TaxAreaRecord = TestDataUtil.TaxAreaRecord;
        Test.startTest();
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        String title = inst_SOC.title;
        Boolean open = inst_SOC.Open;
        boolean allowDataOverride = inst_SOC.allowDataOverride;
        boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
        inst_SOC.includeWeekend = True;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        Sales_Order__c SO = inst_SOC.salesOrder;
        List<Sales_Line__c> SLList = inst_SOC.SLList;
        Company_Setup__c CompanySetup = inst_SOC.CompanySetup;

        /*
        inst_SOC.createTemporaryTmList();
        inst_SOC.getConvertMessages();
         */
        ///////////////////////////
        Test.stopTest();

    }

    private static testMethod void Test_SalesOrderController4() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        String title = inst_SOC.title;
        Boolean open = inst_SOC.open;
        Boolean allowDataOverride = inst_SOC.allowDataOverride;
        Boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
        inst_SOC.includeWeekend = true;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        Sales_Order__c SO = inst_SOC.salesOrder;
        List<Sales_Line__c> SLList = inst_SOC.SLList;
        List<Sales_Line__c> SOListLaborLines = inst_SOC.SOListLaborLines;
        List<Sales_Line__c> SOListMaterialLines = inst_SOC.SOListMaterialLines;
        List<Sales_Line__c> SOListEquipmentLines = inst_SOC.SOListEquipmentLines;
        String companyLogoURL = inst_SOC.companyLogoURL;

        Test.startTest();

        inst_SOC.theTMWrapList = new List<SalesOrderController.TMWrap>();
        inst_SOC.CreateTM();
        List<Sales_Line__c> theSLList = new List<Sales_Line__c>();
        theSLList.add(TestDataUtil.SalesLineRecord);
        theSLList.add(TestDataUtil.SalesContractLineRecord);
        
        inst_SOC.CreateTMfromSO();
        inst_SOC.getIndex(theSLList, 'type', 0);

        pref.getParameters().put('LineCategory', 'Waste Disposal');
        pref.getParameters().put('ObjectType', 'SalesLine');
        inst_SOC.insertLine();
        pref.getParameters().put('LineCategory', 'Subcontractors');
        inst_SOC.insertLine();
        pref.getParameters().put('LineCategory', 'Bundled');
        inst_SOC.insertLine();
        pref.getParameters().put('LineCategory', 'Misc. Charges And Taxes');
        inst_SOC.insertLine();
        pref.getParameters().put('LineCategory', 'Labor');
        inst_SOC.insertLine();
        inst_SOC.CreateBlankTM();

        inst_SOC.theSO = TestDataUtil.SalesOrderRecord;

        List<TM_Line__c> ltmLines = [Select Id From TM_Line__c];

        ltmLines.add(TestDataUtil.TMLineLaborRecord);
        List<Sales_Invoice_Line__c> insertSIL = inst_SOC.insertSIL();
        inst_SOC.reInsertSL();
        inst_SOC.updateTMPrice();
        Document DocRecord = TestDataUtil.DocumentRecord;
        inst_SOC.imageUrls();
        DocRecord.Name = 'Google Image';
        update DocRecord;
        inst_SOC.imageUrls();
        DocRecord.Name = 'Linkd Image';
        update DocRecord;
        inst_SOC.imageUrls();
        DocRecord.Name = 'Twitter Image';
        update DocRecord;
        inst_SOC.imageUrls();
        DocRecord.Name = 'Company Logo';
        update DocRecord;
        inst_SOC.imageUrls();

        List<SelectOption> getLaborAssumptionItems = inst_SOC.getLaborAssumptionItems();

        Test.stopTest();
    }

    private static testMethod void Test_SalesOrderController5() {
		     CompanyMgmt.byPassTrigger = true;

        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        
		SalesOrderRecord.Site_Scope__c = 'Test Site scope';
        SalesOrderRecord.Surcharge_Type__c = 'Fuel Surcharge';
        update SalesOrderRecord;        
ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        Sales_Line__c SalesLineRecord2 = TestDataUtil.SalesDemurrageLineRecord;
        Sales_Line__c SalesLineRecord3 = TestDataUtil.SalesContractLineRecord;
        Sales_Line__c SalesLineRecord4 = TestDataUtil.SalesWasteLineRecord;
        List<Sales_Line__c> theSLList = [Select Id from Sales_Line__c]; 
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        String str = inst_SOC.addLineCategory;
        String titleInPrintConf = inst_SOC.titleInPrintConfirmation;
        //inst_SOC.changeOwner();
        List<SelectOption> lstPrintType = inst_SOC.lstPrintType;
        //List<Sales_Line__c> soLineListForConsolidated = inst_SOC.soLineListForConsolidated;
        inst_SOC.printQuotePDF();
        inst_SOC.printQuoteWord();
        String selectedPrintType = inst_SOC.selectedPrintType;
        //inst_SOC.theSOListDemurrage = theSLList;
        pref.getParameters().put('objectType', 'SalesLine');
        inst_SOC.insertLine();
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theDUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theDUOM');
        pref.getParameters().put('newFieldValue', TestDataUtil.UnitMeasureRecord.Id);
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theDResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theDQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theDQuantity');
        pref.getParameters().put('newFieldValue', '1');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theDUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theDUnitPrice');
        pref.getParameters().put('newFieldValue', '1');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theWQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theWQuantity');
        pref.getParameters().put('newFieldValue', '1');
        inst_SOC.validateField();
        Map<String, Boolean> mapStandardAssumptions = inst_SOC.mapStandardAssumptions;

    }

    private static testMethod void Test_SalesOrderController6() {

        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        Contract_Line__c ContractLineRecord = TestDataUtil.ContractLineRecord;
        /*
        TM__c TMRecord = TestDataUtil.TMRecord;
        TM_Line__c TMLineRecord = TestDataUtil.TMLineLaborRecord;
        //TM_Line__c TMLineRecord2 = TestDataUtil.TMLineDemurrageRecord;
        TM_Line__c TMLineRecord3 = TestDataUtil.TMLineSubcontractorsRecord;
        //TM_Line__c TMLineRecord4 = TestDataUtil.TMLineMisChargeRecord;
        TM_Line__c TMLineRecord5 = TestDataUtil.TMLineLumpSumRecord;
        TM_Line__c TMLineRecord6 = TestDataUtil.TMLineWasteDisposalRecord;
        TM_Line__c TMLineRecord7 = TestDataUtil.TMLineMaterialRecord;
        //TM_Line__c TMLineRecord8 = TestDataUtil.TMLineEquipmentRecord;
         */
        Tax_Area__c TaxAreaRecord = TestDataUtil.TaxAreaRecord;
        Test.startTest();
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        Sales_Order__c SO = inst_SOC.salesOrder;


        inst_SOC.createTemporaryTmList();
        inst_SOC.CreateTM();
        inst_SOC.validateCreateSiteAddress();
        List<SalesOrderController.TMWrap> theTMWrapLis = new List<SalesOrderController.TMWrap>();
        Boolean isSalesOrder = inst_SOC.isSalesOrder;
        SO.Document_Type__c = 'Sales Quote';
        //inst_SOC.convertQuoteToOrder();
        List<Sales_Line__c> SOListSubContractorLines = inst_SOC.SOListSubContractorLines;
        List<Sales_Line__c> SOListWasteDisposal = inst_SOC.SOListWasteDisposal;
        List<SelectOption> lstConvertTo = inst_SOC.lstConvertTo;
        //List<SelectOption> LAItems = inst_SOC.getLaborAssumptionItems();
        //Map<String, Boolean> mapStandardAssumptions = inst_SOC.mapStandardAssumptions;
        inst_SOC.closeSO();
        inst_SOC.openSO();
        //inst_SOC.validateTaxLiable();
        Tax_Detail__c taxDetail = TestDataUtil.TaxDetailRecord;
        Tax_Area__c taxArea = TestDataUtil.TaxAreaRecord;
        pref.getParameters().put('newFieldValue', taxArea.Id);
        inst_SOC.validateTaxArea();
        inst_SOC.copyPWInfo();
        Test.stopTest();
    }

    private static testMethod void Test_SalesOrderController6ext() {

        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        Contract_Line__c ContractLineRecord = TestDataUtil.ContractLineRecord;
        /*
        TM__c TMRecord = TestDataUtil.TMRecord;
        TM_Line__c TMLineRecord = TestDataUtil.TMLineLaborRecord;
        //TM_Line__c TMLineRecord2 = TestDataUtil.TMLineDemurrageRecord;
        TM_Line__c TMLineRecord3 = TestDataUtil.TMLineSubcontractorsRecord;
        //TM_Line__c TMLineRecord4 = TestDataUtil.TMLineMisChargeRecord;
        TM_Line__c TMLineRecord5 = TestDataUtil.TMLineLumpSumRecord;
        TM_Line__c TMLineRecord6 = TestDataUtil.TMLineWasteDisposalRecord;
        TM_Line__c TMLineRecord7 = TestDataUtil.TMLineMaterialRecord;
        //TM_Line__c TMLineRecord8 = TestDataUtil.TMLineEquipmentRecord;
        Tax_Area__c TaxAreaRecord = TestDataUtil.TaxAreaRecord;
         */

        Test.startTest();
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        Sales_Order__c SO = inst_SOC.salesOrder;


        inst_SOC.createTemporaryTmList();
        inst_SOC.CreateTM();
        inst_SOC.validateCreateSiteAddress();
        List<SalesOrderController.TMWrap> theTMWrapLis = new List<SalesOrderController.TMWrap>();
        Boolean isSalesOrder = inst_SOC.isSalesOrder;
        SO.Document_Type__c = 'Sales Quote';
        //inst_SOC.convertQuoteToOrder();
        List<Sales_Line__c> SOListSubContractorLines = inst_SOC.SOListSubContractorLines;
        List<Sales_Line__c> SOListWasteDisposal = inst_SOC.SOListWasteDisposal;
        List<SelectOption> lstConvertTo = inst_SOC.lstConvertTo;
        //List<SelectOption> LAItems = inst_SOC.getLaborAssumptionItems();
        //Map<String, Boolean> mapStandardAssumptions = inst_SOC.mapStandardAssumptions;
        inst_SOC.closeSO();
        inst_SOC.openSO();
        inst_SOC.validateTaxLiable();
        //Tax_Detail__c taxDetail = TestDataUtil.TaxDetailRecord;
        //Tax_Area__c taxArea = TestDataUtil.TaxAreaRecord;
        //pref.getParameters().put('newFieldValue', taxArea.Id);
        //inst_SOC.validateTaxArea();
        //inst_SOC.copyPWInfo();

        Test.stopTest();
    }

    private static testMethod void Test_SalesOrderController7() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        inst_SOC.startingDateValue = '01/01/2018';
        Sales_Order__c SO = inst_SOC.salesOrder;
        List<Sales_Line__c> SLList = inst_SOC.SLList;
        List<Sales_Line__c> SOListLaborLines = inst_SOC.SOListLaborLines;

        Test.startTest();

        inst_SOC.theTMWrapList = new List<SalesOrderController.TMWrap>();
        inst_SOC.CreateTM();
        List<Sales_Line__c> theSLList = new List<Sales_Line__c>();
        theSLList.add(TestDataUtil.SalesLineRecord);
        theSLList.add(TestDataUtil.SalesContractLineRecord);

        inst_SOC.theSO = TestDataUtil.SalesOrderRecord;

        List<TM_Line__c> ltmLines = [Select Id From TM_Line__c];

        ltmLines.add(TestDataUtil.TMLineLaborRecord);
        /*
        List<TM__c> tms = inst_SOC.selectedTMs;
        inst_SOC.CreateMiscCreditMemo();
        inst_SOC.theSO.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        SalesOrderController.TMCreateSIWrapper testWrap = new SalesOrderController.TMCreateSIWrapper();
        testWrap.isSelected = true;
        testWrap.theTM = TestDataUtil.TMRecord;
        inst_SOC.theTMCreateSIWrapList.add(testWrap);
        inst_SOC.selectAllTML();
        inst_SOC.createSI();
        inst_SOC.calculatelines();
         */

        Test.stopTest();
    }

    private static testMethod void Test_SalesOrderController8() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
		     CompanyMgmt.byPassTrigger = true;

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        Resource__c ResourceRecord = [SELECT Id,Name,Tax_Group__c,Unit_of_Measure__c,Resource_Type__c FROM Resource__c Limit 1];
        String title = inst_SOC.title;
        Boolean open = inst_SOC.Open;
        boolean allowDataOverride = inst_SOC.allowDataOverride;
        boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
        inst_SOC.includeWeekend = True;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        Sales_Order__c SO = inst_SOC.salesOrder;
        List<Sales_Line__c> SLList = inst_SOC.SLList;
        inst_SOC.validateSalesOrderType();
        inst_SOC.validateSalespeople();
        inst_SOC.validateContract();

        List<Sales_Line__c> SOListLaborLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListMaterialLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListEquipmentLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListEquipLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListLumpSumLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListWasteDisposalLines = New List<Sales_Line__c>();

        SOListEquipLines.add(TestDataUtil.SalesEquipmentLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesMaterialLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesMiscLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesLumpSumLineRecord);
        SOListLumpSumLines.add(TestDataUtil.SalesLumpSumLineRecord);
        SOListEquipLines.add(TestDataUtil.SalesWasteLineRecord);

        inst_SOC.theSLList = SOListEquipLines;
        inst_SOC.theSOListLumpSum = SOListLumpSumLines;
        Test.startTest();

        inst_SOC.createTemporaryTmList();
        pref.getParameters().put('objectType', 'SalesLine');
        inst_SOC.insertLine();
        pref.getParameters().put('lineNo', '0');

        pref.getParameters().put('fieldName', 'theEUnitPrice');
        pref.getParameters().put('newFieldValue', '5');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theEUnitPrice');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMUnitPrice');
        pref.getParameters().put('newFieldValue', '5');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theSUnitPrice');
        pref.getParameters().put('newFieldValue', '5');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theWUnitPrice');
        pref.getParameters().put('newFieldValue', '5');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMUnitPrice');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theSUnitPrice');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theWUnitPrice');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theEContractLine');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theEContractLine');
        pref.getParameters().put('newFieldValue', '8888');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMContractLine');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMiscQuantity');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theEquipmentINPT');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMaterialINPT');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theSResource');
        pref.getParameters().put('newFieldValue', '');
        //inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMiscTaxGroup');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMiscUnitPrice');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpSumResourceType');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpSumResourceType');
        pref.getParameters().put('newFieldValue', '123');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpQuantity');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpQuantity');
        pref.getParameters().put('newFieldValue', '123');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpQuantity');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpQuantity');
        pref.getParameters().put('newFieldValue', '123');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpUnitPrice');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpUnitPrice');
        pref.getParameters().put('newFieldValue', '123');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpTaxGroup');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpTaxGroup');
        pref.getParameters().put('newFieldValue', '123');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpSumContractLine');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpSumContractLine');
        pref.getParameters().put('newFieldValue', '123');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLLUOM');
        pref.getParameters().put('newFieldValue', TestDataUtil.UnitMeasureRecord.id);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpSumContractLine');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpSumContractLine');
        pref.getParameters().put('newFieldValue', '123');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMLUOM');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMLUOM');
        pref.getParameters().put('newFieldValue', TestDataUtil.UnitMeasureRecord.id);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theELUOM');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theELUOM');
        pref.getParameters().put('newFieldValue', TestDataUtil.UnitMeasureRecord.id);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpUOM');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLumpUOM');
        pref.getParameters().put('newFieldValue', TestDataUtil.UnitMeasureRecord.id);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMiscUOM');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theMiscUOM');
        pref.getParameters().put('newFieldValue', TestDataUtil.UnitMeasureRecord.id);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theWUOM');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theWUOM');
        pref.getParameters().put('newFieldValue', TestDataUtil.UnitMeasureRecord.id);
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theEUOMQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SOC.validateField();

        pref.getParameters().put('fieldName', 'theLUOMQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SOC.validateField();
        pref.getParameters().put('newFieldValue', 'abc');
        inst_SOC.validateField();

        inst_SOC.deleteLine();
        inst_SOC.deleteSO();
        inst_SOC.validateAltSiteAddress();

        List<SalesOrderController.TMWrap > TMWrapList = inst_SOC.TMWrapList;
        inst_SOC.validateCustomer();
        pref.getParameters().remove('id');
        StdCon = new ApexPages.StandardController(new Sales_Order__c());
        PageReference pageref = Page.SalesOrder;

        Test.stopTest();

    }

    private static testMethod void Test_SalesOrderController9() {
		     CompanyMgmt.byPassTrigger = true;

        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        Sales_Line__c SalesLineRecord2 = TestDataUtil.SalesDemurrageLineRecord;
        Sales_Line__c SalesLineRecord3 = TestDataUtil.SalesContractLineRecord;
        Sales_Line__c SalesLineRecord4 = TestDataUtil.SalesWasteLineRecord;
        List<Sales_Line__c> theSLList = [Select Id from Sales_Line__c];
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        String str = inst_SOC.addLineCategory;
        String titleInPrintConf = inst_SOC.titleInPrintConfirmation;
        //inst_SOC.changeOwner();
        List<SelectOption> lstPrintType = inst_SOC.lstPrintType;
        //List<Sales_Line__c> soLineListForConsolidated = inst_SOC.soLineListForConsolidated;
        inst_SOC.printQuotePDF();
        inst_SOC.printQuoteWord();
        String selectedPrintType = inst_SOC.selectedPrintType;
        //inst_SOC.theSOListDemurrage = theSLList;
        pref.getParameters().put('objectType', 'SalesLine');
        inst_SOC.insertLine();
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theDResource');
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SOC.validateField();
        pref.getParameters().put('fieldName', 'theSResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SOC.validateField();
    }

    private static testMethod void Test_PaginationBase() {
        PaginationBase pg = new PaginationBase();
        pg.fetchStdSetRecords();
        Boolean hasNext = pg.hasNext;
        Boolean hasPrevious = pg.hasPrevious ;
        Integer pageNumber = pg.pageNumber;
        pg.first();
        pg.last() ;
        pg.next() ;
        String paginationStat = pg.paginationStat;
        Boolean hasRecords = pg.hasRecords;
        String sortBy = pg.sortBy;
        String sortDirection = pg.sortDirection;
    }

    private static testMethod void Test_SalesOrderTriggersMgt() {
        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        List<Sales_Order__c>SalesOrderList = new List<Sales_Order__c>();
        SalesOrderList.add(SalesOrderRecord);
        Map<Id, Sales_Order__c>SalesOrderMap = new Map<Id, Sales_Order__c>();
        SalesOrderMap.put(SalesOrderRecord.Id, SalesOrderRecord);
        SalesOrderTriggersMgt.SOInsertUpdate(SalesOrderList, SalesOrderMap, True);
        Sales_Order__c theSO = TestDataUtil.SalesOrderRecordCSA;
        System.debug('<==theSO==>' + theSO.Alternate_Site_Address__c);
        SalesOrderMgmt.validateAltSiteAddress(TestDataUtil.SalesOrderRecordCSA);
    }

    private static testMethod void Test_SalesInvoiceEmailing() {
        Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceRecord;
        SalesInvoiceRecord.Contact__c = TestDataUtil.Contact2Record.id;
        update SalesInvoiceRecord;
        Test.setCurrentPageReference(new PageReference('Page.EmailSalesInvoicePreview'));
        System.currentPageReference().getParameters().put('Id', SalesInvoiceRecord.id);
        ApexPages.StandardController sc = new ApexPages.StandardController(SalesInvoiceRecord);
        SalesInvoiceEmailing RO = new SalesInvoiceEmailing(sc);
        String title = RO.title;
        RO.EmailSI();
        RO.returnBack();
        List<SelectOption> lstInvoiceType = RO.lstInvoiceType;
    }

    private static testMethod void Test_WeekNumberController() {
        Week_Number__c WeekNumberRecord = TestDataUtil.WeekNumberRecord ;
        WeekNumberController wn = new WeekNumberController();
        wn.Year = Date.today().year();
        wn.CreateWeekNumbers();
        wn.returnBack();
    }

    private static testMethod void Test_SalesOrderMgmt2() {
		     CompanyMgmt.byPassTrigger = true;

        Contract ContractRecord = new Contract (
                Name = 'Test ContractRecord',
                AccountId = TestDataUtil.customerAccountRecord.id,
                StartDate = Date.today().addDays(-200),
                Subsidiary__c = '1-REPUBLIC SERVICES',
                Status = 'Draft'

        );
        insert ContractRecord ;
        ContractRecord.Status = 'Activated';
        update ContractRecord;
        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        SalesOrderRecord.Alternate_Site_Address__c = TestDataUtil.SiteAddressRecord.Id;
        SalesOrderRecord.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        SalesOrderRecord.Contract__c = ContractRecord.Id;
        update SalesOrderRecord;
        SalesOrderMgmt.validateAltSiteAddress(SalesOrderRecord);
        //SalesOrderMgmt.validateTaxArea(SalesOrderRecord);
        Unit_of_Measure__c UnitMeasureRecord = TestDataUtil.UnitMeasureRecord;
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
        update SalesLineRecord;

        Contract_Line__c ContractLineRecord = new Contract_Line__c (
                Name = 'Test ContractLine',
                Contract__c = SalesOrderRecord.Contract__c,
                Premium_Rate__c = 10,
//          Resource__c=SalesLineRecord.Resource__c,
                Resource_Type__c = SalesLineRecord.Resource_Type__c,
                Unit_of_Measure__c = UnitMeasureRecord.Id
        );
        insert ContractLineRecord;


        SalesOrderMgmt.setPricing(SalesLineRecord, SalesOrderRecord);
    }

    private static testMethod void Test_SalesOrderMgmt3() {
        		     CompanyMgmt.byPassTrigger = true;

        Contract ContractRecord = new Contract (
                Name = 'Test ContractRecord',
                AccountId = TestDataUtil.customerAccountRecord.id,
                StartDate = Date.Today().AddDays(-200),
                Subsidiary__c = '1-REPUBLIC SERVICES',
                Status = 'Draft'
        );
        insert ContractRecord ;
        ContractRecord.Status = 'Activated';
        update ContractRecord;
        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        SalesOrderRecord.Alternate_Site_Address__c = TestDataUtil.SiteAddressRecord.Id;
        SalesOrderRecord.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        SalesOrderRecord.Contract__c = ContractRecord.Id;
        update SalesOrderRecord;
        Unit_of_Measure__c UnitMeasureRecord = TestDataUtil.UnitMeasureRecord;
        Sales_Line__c SalesEquipmentLineRecord = TestDataUtil.SalesEquipmentLineRecord ;
        SalesEquipmentLineRecord .Unit_of_Measure__c = UnitMeasureRecord.Id;
        update SalesEquipmentLineRecord ;
        Contract_Line__c ContractLineRecord = new Contract_Line__c (
                Name = 'Test ContractLine',
                Contract__c = SalesOrderRecord.Contract__c,
                Premium_Rate__c = 10,
                Resource_Type__c = SalesEquipmentLineRecord .Resource_Type__c,
                Unit_of_Measure__c = UnitMeasureRecord.Id
        );
        insert ContractLineRecord;

        SalesOrderMgmt.setPricing(SalesEquipmentLineRecord, SalesOrderRecord);

    }

    private static testMethod void Test_SalesOrderMgmt4() {
		     CompanyMgmt.byPassTrigger = true;

        Contract ContractRecord = new Contract (
                Name = 'Test ContractRecord',
                AccountId = TestDataUtil.customerAccountRecord.id,
                StartDate = Date.Today().AddDays(-200),
                Subsidiary__c = '1-REPUBLIC SERVICES',
                Status = 'Draft'
        );
        insert ContractRecord ;
        ContractRecord.Status = 'Activated';
        update ContractRecord;

        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        SalesOrderRecord.Alternate_Site_Address__c = TestDataUtil.SiteAddressRecord.Id;
        SalesOrderRecord.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        SalesOrderRecord.Contract__c = ContractRecord.Id;
        update SalesOrderRecord;

        Unit_of_Measure__c UnitMeasureRecord = TestDataUtil.UnitMeasureRecord;
        Sales_Line__c SalesMaterialLineRecord = TestDataUtil.SalesMaterialLineRecord ;
        SalesMaterialLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
        update SalesMaterialLineRecord ;
        Contract_Line__c ContractLineRecord = new Contract_Line__c (
                Name = 'Test ContractLine',
                Contract__c = SalesOrderRecord.Contract__c,
                Premium_Rate__c = 10,
                Resource_Type__c = SalesMaterialLineRecord.Resource_Type__c,
                Unit_of_Measure__c = UnitMeasureRecord.Id
        );
        insert ContractLineRecord;

        SalesOrderMgmt.setPricing(SalesMaterialLineRecord, SalesOrderRecord);
        SalesOrderRecord.Emergency_Sales_Order__c = true ;
        Account a = [SELECT Id, Name, Pricing_Group__c FROM Account WHERE Id = :SalesOrderRecord.Bill_to_Customer_No__c LIMIT 1];
        a.Pricing_Group__c = 'Gold';
        SalesOrderMgmt.mapAccount.put(SalesOrderRecord.Bill_to_Customer_No__c, a);
        SalesOrderMgmt.setPricing(SalesMaterialLineRecord, SalesOrderRecord);
        a = [SELECT Id, Name, Pricing_Group__c FROM Account WHERE Id = :SalesOrderRecord.Bill_to_Customer_No__c LIMIT 1];
        a.Pricing_Group__c = 'Platinum';
        SalesOrderMgmt.mapAccount.put(SalesOrderRecord.Bill_to_Customer_No__c, a);
        SalesOrderMgmt.setPricing(SalesMaterialLineRecord, SalesOrderRecord);

    }

    /*
    static testMethod void Test_SalesOrderMgmt5 (){
        Sales_Order__c theSO = TestDataUtil.SalesOrderRecord;
        Sales_Line__c theSL = TestDataUtil.SalesLineRecord;
        theSO.Emergency_Sales_Order__c = true;
        theSL.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        SalesOrderMgmt.setPricing(theSL, theSO);
        Account account = SalesOrderMgmt.mapAccount.get(theSO.Bill_to_Customer_No__c);
        account.Pricing_Group__c = 'Gold';
        SalesOrderMgmt.setPricing(theSL, theSO);
        account.Pricing_Group__c = 'Platinum';
        SalesOrderMgmt.setPricing(theSL, theSO);
        theSO.Emergency_Sales_Order__c = false;
        SalesOrderMgmt.setPricing(theSL, theSO);
    }
     */

    static testMethod void testGetCrMemoReasonCodeOptions(){
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController standardController = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        SalesOrderController salesOrderController = new SalesOrderController(standardController);
        List<SelectOption> options = salesOrderController.getCrMemoReasonCodeOptions();
        salesOrderController.creditMemoNote = 'Note';
    }

    static testMethod void testContractValidation(){
        Account customer = TestDataUtil.customerAccountRecord;
        Contract contract = TestDataUtil.ContractRecordCustomer;
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        pref.getParameters().put('contractId', contract.Id);
        ApexPages.StandardController standardController = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        SalesOrderController salesOrderController = new SalesOrderController(standardController);
        salesOrderController.validateContract();
        pref.getParameters().put('contractId', '');

        salesOrderController.validateBillToCustomer();
        salesOrderController.validateServiceCenter();
    }

    static testMethod void testChangeBillToCustomer(){
        Account customer = TestDataUtil.customerAccountRecord2;
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecord;
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', salesOrder.Id);
        ApexPages.StandardController standardController = new ApexPages.StandardController(salesOrder);
        SalesOrderController salesOrderController = new SalesOrderController(standardController);
        salesOrderController.originBillToCustomer = salesOrder.Bill_to_Customer_No__c;
        salesOrder.Bill_to_Customer_No__c = customer.Id;
        salesOrderController.theSO = salesOrder;
        salesOrderController.validateBillToCustomer();


        Contact contact = TestDataUtil.Contact2Record;
        pref.getParameters().put('contactId', contact.Id);
        pref.getParameters().put('fieldId', '');
        salesOrderController.validateContact();

    }

    static testMethod void testSurcharge(){
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecord;
        salesOrder.Surcharge_Pct__c = 10;
        salesOrder.Quote_Date__c = Date.today();
        pref.getParameters().put('id', salesOrder.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(salesOrder);

        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        inst_SOC.theSO = salesOrder;

        /*
        Resource__c ResourceRecord = [SELECT Id,Name,Tax_Group__c,Unit_of_Measure__c,Resource_Type__c FROM Resource__c Limit 1];
        String title = inst_SOC.title;
        Boolean open = inst_SOC.Open;
        boolean allowDataOverride = inst_SOC.allowDataOverride;
        boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
        */

        inst_SOC.includeWeekend = True;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        //Sales_Order__c SO = inst_SOC.salesOrder;

        List<Sales_Line__c> salesLines = New List<Sales_Line__c>();

        salesLines.add(TestDataUtil.SalesEquipmentLineRecord);
        salesLines.add(TestDataUtil.SalesLineRecord);

        inst_SOC.theSLList = salesLines;

        Test.startTest();
        List<Surcharge_Setup__c> surchargeSetups = new List<Surcharge_Setup__c>();
        Surcharge_Setup__c surchargeSetup = new Surcharge_Setup__c(
                Name = 'EI',
                Surcharge_Type__c = 'Energy and Environmental Compliance Fee',
                Surcharge_Pct__c = 10,
                Effective_Date__c = Date.today());
        surchargeSetups.add(surchargeSetup);

        surchargeSetup = new Surcharge_Setup__c(
                Name = 'FS',
                Surcharge_Type__c = 'Fuel Surcharge',
                Surcharge_Pct__c = 20,
                Effective_Date__c = Date.today());

        surchargeSetups.add(surchargeSetup);
        insert surchargeSetups;

        pref.getParameters().put('newFieldValue', 'N/A');
        inst_SOC.validateSurchargeType();
        pref.getParameters().put('newFieldValue', 'Energy and Environmental Compliance Fee');
        inst_SOC.validateSurchargeType();
        pref.getParameters().put('newFieldValue', 'Fuel Surcharge');
        inst_SOC.validateSurchargeType();
        inst_SOC.addDemurrageSurchargeLine('Energy and Environmental Compliance Fee');
        inst_SOC.addDemurrageSurchargeLine('Fuel Surcharge');
        inst_SOC.SurchargeAmount = 1000;
        inst_SOC.updateDemurrageSurchargeLine();
        List<Sales_Line__c> deleteList = new List<Sales_Line__c>();
        inst_SOC.removeDemurrageSurchargeLine(deleteList);
        //String surchargeStr = inst_SOC.surchargeOnPDF;
        inst_SOC.validateQuoteDate();
        Test.stopTest();
    }

    //deprecated <<
    /*
    static testMethod void testPDFPrint(){
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecord;
        salesOrder.Surcharge_Pct__c = 10;
        salesOrder.Quote_Date__c = Date.today();
        pref.getParameters().put('id', salesOrder.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(salesOrder);

        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        SalesOrderController salesOrderController = new SalesOrderController(StdCon);
        salesOrderController.laborPDFWrap pdfwrap = new salesOrderController.laborPDFWrap('Labor 1', 'Labor 2', 1, 1, 'HR', 2.23,2.55,false);

        List<Sales_Line__c> salesLines = New List<Sales_Line__c>();

        Sales_Line__c laborLine = TestDataUtil.SalesLineRecord;
        Sales_Line__c equipmentLine = TestDataUtil.SalesEquipmentLineRecord;
        Sales_Line__c materLine = TestDataUtil.SalesMaterialLineRecord;
        Sales_Line__c subcontractLine = TestDataUtil.SalesContractLineRecord;
        Sales_Line__c wasteLine = TestDataUtil.SalesWasteLineRecord;
        Sales_Line__c lumpSumLine = TestDataUtil.SalesLumpSumLineRecord;
        Sales_Line__c miscline = TestDataUtil.SalesMiscLineRecord;
        Sales_Line__c demurrageLine = TestDataUtil.SalesDemurrageLineRecord;

        salesLines.add(laborLine);
        salesLines.add(equipmentLine);
        salesLines.add(materLine);
        salesLines.add(subcontractLine);
        salesLines.add(wasteLine);
        salesLines.add(lumpSumLine);
        salesLines.add(miscline);
        salesLines.add(demurrageLine);

        inst_SOC.theSLList = salesLines;

        List<Sales_Line__c> laborLines = inst_SOC.SOListLaborLines;
        List<Sales_Line__c> equipmentLines = inst_SOC.SOListEquipmentLines;
        List<Sales_Line__c> subcontractorLines = inst_SOC.SOListSubContractorLines;
        List<Sales_Line__c> wasteLines = inst_SOC.SOListWasteDisposal;
        List<Sales_Line__c> miscLines = inst_SOC.SOListMisc;
        List<Sales_Line__c> lumpSumLines = inst_SOC.SOListLumpSum;
        List<Sales_Line__c> demurrageLines = inst_SOC.SOListDemurrage;
        List<Sales_Line__c> materialLines = inst_SOC.SOListMaterialLines;

        List<Sales_Line__c> pdfEquipmentLines = inst_SOC.SOListEquipmentLinesWithoutLumpSum;
        List<Sales_Line__c> pdfMaterialLines = inst_SOC.SOListMaterialLinesWithoutLumpSum;
        List<Sales_Line__c> pdfSubContractLines = inst_SOC.SOListSubContractorLinesWithoutLumpSum;
        List<Sales_Line__c> pdfWDLines = inst_SOC.SOListWasteDisposalWithoutLumpSum;
        List<Sales_Line__c> pdfDemurrageLines = inst_SOC.SOListDemurrageWithoutLumpSum;
        List<Sales_Line__c> pdfMiscLines = inst_SOC.SOListMiscWithoutLumpSum;

        Decimal laborTotal = inst_SOC.laborSubtotalforPDF;
        List<salesOrderController.laborPDFWrap> laborPDFWraps = inst_SOC.soLineListForLaborPDF;
        List<salesOrderController.laborPDFWrap> laborPDFWraps2 = inst_SOC.laborPDFWrapsConsolidate;
        List<Sales_Line__c> wordDocLines = inst_SOC.soLineListForConsolidated;
    }
    */
    //deprecated >>

    /*
    static testMethod void testCreateNewSO(){
        Account billToCust = TestDataUtil.customerAccountRecord;
        Service_Center__c serviceCenter = TestDataUtil.ServiceCenterRecord;
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        pref.getParameters().put('documentType', 'Sales Quote');
        pref.getParameters().put('billToCustomer', billToCust.Id);
        pref.getParameters().put('serviceCenter', serviceCenter.Id);
        pref.getParameters().put('contract', '');
        pref.getParameters().put('quote', '');

        Sales_Order__c salesOrder = new Sales_Order__c();
        ApexPages.StandardController StdCon = new ApexPages.StandardController(salesOrder);
        SalesOrderController salesOrderController = new SalesOrderController(StdCon);
    }
     */

    static testMethod  void testValidateEstimatedJob(){
        Billing_Rule__c br = new Billing_Rule__c(
                Name = 'test',
                Holidays_Bill_in_DT_Rate__c = 'Christmas Day Company',
                Holidays_Bill_in_OT_Rate__c = 'Thanksgiving',
                Sunday_Rate_Code__c = EnumUtil.TimeRateCode.DT.name(),
                Saturday_Rate_Code__c = EnumUtil.TimeRateCode.OT.name()
        );
        insert br;

        List<Billing_Rule_Line__c> billingRuleLines = new List<Billing_Rule_Line__c>();

        Billing_Rule_Line__c billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,30,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.Hours_After_Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Tuesday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Friday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Hours_After_Number_of_Hours__c = 3;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'DT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Day_Based';
        billingRuleLine.Day__c = 'Saturday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        if(billingRuleLines.size() > 0){
            insert billingRuleLines;
        }

        Company_Setup__c companySetup = [SELECT Id, Default_Billing_Rule__c FROM Company_Setup__c LIMIT 1];
        companySetup.Default_Billing_Rule__c = br.Id;
        update companySetup;

        Test.startTest();
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecord;
        salesOrder.Surcharge_Pct__c = 10;
        salesOrder.Quote_Date__c = Date.today();
        salesOrder.Estimated_Job_Start_Date__c = Date.today();
        salesOrder.Estimated_Job_End_Date__c = Date.today();
        salesOrder.Include_Holiday__c = true;
        salesOrder.Include_Weekend__c = true;
        salesOrder.Duration__c = 1;
        pref.getParameters().put('id', salesOrder.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(salesOrder);

        SalesOrderController inst_SOC = new SalesOrderController(StdCon);

        List<Sales_Line__c> salesLines = New List<Sales_Line__c>();

        Sales_Line__c laborLine = TestDataUtil.SalesLineRecord;
        Sales_Line__c equipmentLine = TestDataUtil.SalesEquipmentLineRecord;

        salesLines.add(laborLine);
        salesLines.add(equipmentLine);

        inst_SOC.theSLList = salesLines;

        List<Sales_Line__c> laborLines = inst_SOC.SOListLaborLines;
        List<Sales_Line__c> equipmentLines = inst_SOC.SOListEquipmentLines;
        inst_SOC.validateEstimateJob();
        Test.stopTest();
    }

private static testMethod void Test_saveAndSubmit() {
		     CompanyMgmt.byPassTrigger = true;
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Contract ContractRecord = new Contract (
                Name = 'Test ContractRecord',
                AccountId = TestDataUtil.customerAccountRecord.id,
                StartDate = Date.today().addDays(-200),
                Subsidiary__c = '1-REPUBLIC SERVICES',
                Status = 'Draft'

        );
        insert ContractRecord ;
        
        ContractRecord.Status = 'Activated';
        update ContractRecord;
        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        SalesOrderRecord.Alternate_Site_Address__c = TestDataUtil.SiteAddressRecord.Id;
        SalesOrderRecord.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        SalesOrderRecord.Contract__c = ContractRecord.Id;
        SalesOrderRecord.Document_Type__c = 'Sales Order';
        update SalesOrderRecord;
        //SalesOrderMgmt.validateAltSiteAddress(SalesOrderRecord);
        //SalesOrderMgmt.validateTaxArea(SalesOrderRecord);
        //saveAndSubmit
        Unit_of_Measure__c UnitMeasureRecord = TestDataUtil.UnitMeasureRecord;
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesLineRecord.Unit_of_Measure__c = UnitMeasureRecord.Id;
        update SalesLineRecord;

        Contract_Line__c ContractLineRecord = new Contract_Line__c (
                Name = 'Test ContractLine',
                Contract__c = SalesOrderRecord.Contract__c,
                Premium_Rate__c = 10,
//          Resource__c=SalesLineRecord.Resource__c,
                Resource_Type__c = SalesLineRecord.Resource_Type__c,
                Unit_of_Measure__c = UnitMeasureRecord.Id
        );
        insert ContractLineRecord;
        
        Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceRecord;
        SalesInvoiceRecord.Contact__c = TestDataUtil.Contact2Record.id;
        SalesInvoiceRecord.Credit_Memo_Reason_Code__c = 'Customer is tax exempt';
        update SalesInvoiceRecord;
        
        pref.getParameters().put('id', SalesOrderRecord.Id);
ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesOrderRecord);

        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
		inst_SOC.saveAndSubmit();
		boolean isApproved = inst_SOC.isApproved;
        boolean isServCenterChecked = inst_SOC.isServCenterChecked;
        
        
        List<Sales_Line__c> SOListMisc = inst_SOC.SOListMisc;
        List<Sales_Line__c> SOListLumpSum = inst_SOC.SOListLumpSum;
        List<Sales_Line__c> SOListDemurrage = inst_SOC.SOListDemurrage;
        //inst_SOC.submitRecordForApproval();
        
        pref.getParameters().put('appliedToDocId', SalesInvoiceRecord.Id);
        inst_SOC.validateAppliesToDoc();
        
        Sales_Order__c SalesOrderRecord1 = TestDataUtil.SalesOrderRecord;
        SalesOrderRecord1.Alternate_Site_Address__c = TestDataUtil.SiteAddressRecord.Id;
        SalesOrderRecord1.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        SalesOrderRecord1.Contract__c = ContractRecord.Id;
        
        SalesOrderRecord1.Document_Type__c = 'Sales Order';
        update SalesOrderRecord1;
        inst_SOC.selectedCrMemoReasonCode = 'Test Code';
        inst_SOC.creditMemoNote = 'Customer is tax exempt';
        inst_SOC.CreateMiscCreditMemo();
        inst_SOC.PrintConfirmation();
        inst_SOC.notValidatePrintConfirmation();
	inst_SOC.isNullUOMQty();
        inst_SOC.isSLQtyIsZero();
        //SalesOrderMgmt.setPricing(SalesLineRecord, SalesOrderRecord);
    }

    //test
}