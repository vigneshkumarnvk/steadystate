@IsTest
public with sharing class SalesInvoiceTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        CompanyMgmt.byPassTrigger = true;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        //GL_Account__c GLAccountRecord = TestDataUtil.GLAccountRecord;
        Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceRecord;
        List<Sales_Invoice_Line__c> testSalesInvoiceLineRecords = TestDataUtil.SalesInvoiceLineRecords;
        Resource__c ResourceRecord = TestDataUtil.ResourceRecord;
        GL_Entry__c GLEntryRecord = TestDataUtil.GLEntryRecord;
        Tax_Jurisdiction__c taxJurisdiction = TestDataUtil.TaxJurisdictionRecord;
        Tax_Detail__c taxDetail = TestDataUtil.TaxDetailRecord;
        Tax_Area__c taxArea = TestDataUtil.TaxAreaRecord;
        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        Account AccountRecord = TestDataUtil.AccountRecord;
        SalesPerson__c SalespersonRecord = TestDataUtil.SalespersonRecord;
        Subsidiary_Company__c SubsidiaryCompanyRecord = TestDataUtil.SubsidiaryCompanyRecord;
        Service_Center__c ServiceCenterRecord = TestDataUtil.ServiceCenterRecord;
        Payment_Term__c PaymentTermRecord = TestDataUtil.PaymentTermRecord;
        //Sales_Invoice__c SalesInvoiceCMRecord = TestDataUtil.SalesInvoiceCMRecord;
        //Sales_Invoice_Line__c SalesInvoiceLineCMRecord = TestDataUtil.SalesInvoiceLineCMRecord;
        
//        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = :companySetup.Id];
//        System.assertEquals(theCSList.size(), 1);
    }

    @IsTest
    private static void Test_SalesInvoiceController() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        Test.startTest();
        Sales_Invoice__c SalesInvoiceRecord = [SELECT Id FROM Sales_Invoice__c LIMIT 1];
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);


        Boolean allowDataOverride = inst_SIC.allowDataOverride;
        String title = inst_SIC.title;
        String docType = inst_SIC.docType;
        Sales_Invoice__c SI = inst_SIC.SI;
        Company_Setup__c CompanySetup = inst_SIC.CompanySetup;
//        Boolean postedWS = inst_SIC.posted;
        String[] messagesWS = inst_SIC.getMessages();
        inst_SIC.selLogo = 'Test';
        inst_SIC.TMNames = 'Test';
        List<Sales_Invoice_Line__c> SILList = inst_SIC.SILList;
        inst_SIC.validateBillToCustomer();
        inst_SIC.validateTaxArea();
        inst_SIC.validateTaxLiable();
        inst_SIC.validateContact();
        //inst_SIC.reverseSalesInvoice();
        inst_SIC.lstInvoiceType = null;
        List<SelectOption> lstLogoVal = inst_SIC.lstLogo;
        List<SelectOption> lstPrintCopy = inst_SIC.lstPrintCopy;
        List<SelectOption> lstInvoiceType = inst_SIC.lstInvoiceType;
        lstInvoiceType = null;
        List<SelectOption> lstLogo = inst_SIC.lstLogo;
        pref.getParameters().put('PrintCopy', 'None');
        //List<String> copiesToPrint = inst_SIC.copiesToPrint;
        String selectedInvoicetype = inst_SIC.selectedInvoicetype;
        Boolean containsLumSumCategory = inst_SIC.containsLumSumCategory;

        inst_SIC.PrintSalesInvoice();
        inst_SIC.save();
        inst_SIC.quickSave();
        inst_SIC.save();
        inst_SIC.cloneSalesInvoice();
        inst_SIC.cancel();
        inst_SIC.returnBack();
        inst_SIC.deleteSalesInvoice();
        inst_SIC.quickSaveForLinePaginationPage();

        Test.stopTest();

    }

    @IsTest
    private static void Test_SalesInvoiceController1() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        //Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceCMRecord;
        //Sales_Invoice_Line__c SalesInvoiceLineRecordList = TestDataUtil.SalesInvoiceLineCMRecord;

        Sales_Invoice__c SalesInvoiceRecord = [SELECT Id,Credit_Memo__c FROM Sales_Invoice__c Limit 1];
        Resource__c ResourceRecord = [SELECT Id,Name,Tax_Group__c,Unit_of_Measure__c FROM Resource__c Limit 1];
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id,Resource_Type__c,Resource__r.Name From Sales_Invoice_Line__c Limit 1];
        List<Sales_Invoice_Line__c> SalesInvoiceLineRecordList = [Select Id,Resource_Type__c From Sales_Invoice_Line__c Where Sales_Invoice__c =: SalesInvoiceRecord.Id];
        test.startTest();
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);

        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);
        inst_SIC.theSILListLabor = SalesInvoiceLineRecordList;
        pref.getParameters().put('objectType', 'SalesInvoiceLine');
        //inst_SIC.insertLine();
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theQuantity');
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theJobPosition');
        pref.getParameters().put('newFieldValue', ' ');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();

        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theEquipment');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theMResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theMiscResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theMiscResourceType');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theLResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theEResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theSResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theWResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theDResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theLUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theMUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theEUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theSUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        //pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        //inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theWUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        //pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        //inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theDUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theLumpUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theLumpSumResourceType');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();

        pref.getParameters().put('fieldName', 'theMiscUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        try {
            pref.getParameters().put('newFieldValue', ResourceRecord.Unit_of_Measure__c);
            inst_SIC.validateField();
        } catch (Exception e) {

        }
        
        inst_SIC.postSI();
        inst_SIC.unpostSI();
        //SalesInvoiceRecord.Credit_Memo__c = False;
        //update SalesInvoiceRecord;
        List<Sales_Invoice_Line__c> theSILLines = new List<Sales_Invoice_Line__c>();
        theSILLines.add(SalesInvoiceLineRecord);
        SalesInvoiceController.WrapSILByCategory cmp = new SalesInvoiceController.WrapSILByCategory();
        cmp.Category = 'Labor';
        cmp.theSILLines = theSILLines;
        List<Sales_Invoice_Line__c> theSILList = New List<Sales_Invoice_Line__c>();
        theSILList.add(SalesInvoiceLineRecord);
        inst_SIC.theSILList = theSILList;
        //inst_SIC.reverseSalesInvoice();
        List<SalesInvoiceController.WrapSILByCategory> WrapSIL = inst_SIC.WrapSIL;
        List<SalesInvoiceController.WrapSILByCategory> WrapSILByCategory = inst_SIC.WrapSILByCategory;
        List<SalesInvoiceController.WrapSILByCategory> WrapSILByCategoryAndDate = New List<SalesInvoiceController.WrapSILByCategory>();
        WrapSILByCategoryAndDate = inst_SIC.WrapSILByCategoryAndDate;
        pref.getParameters().put('displayId', '');
        Test.stopTest();
    }

    @IsTest
    private static void Test_SalesInvoiceController2() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);

        //Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceCMRecord;
        //Sales_Invoice_Line__c SalesInvoiceLineRecord = TestDataUtil.SalesInvoiceLineCMRecord;
        Resource__c ResourceRecord = [SELECT Id,Unit_of_Measure__c,Tax_Group__c FROM Resource__c Limit 1];

        Sales_Invoice__c SalesInvoiceRecord = [SELECT Id,Credit_Memo__c FROM Sales_Invoice__c Limit 1];
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id,Sales_Invoice__c From Sales_Invoice_Line__c Limit 1];

        test.startTest();
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);
        boolean allowDataOverride = inst_SIC.allowDataOverride;
        String title = inst_SIC.title;
        String docType = inst_SIC.docType;
        Sales_Invoice__c SI = inst_SIC.SI;
        Company_Setup__c CompanySetup = inst_SIC.CompanySetup;
//        Boolean postedWS = inst_SIC.posted;
        String[] messagesWS = inst_SIC.getMessages();
        inst_SIC.selLogo = 'Test';
        inst_SIC.TMNames = 'Test';
        List<Sales_Invoice_Line__c> SILList = inst_SIC.SILList;
        //inst_SIC.reverseSalesInvoice();
        inst_SIC.lstInvoiceType = Null;
        List<SelectOption> lstLogoVal = inst_SIC.lstLogo;
        List<SelectOption> lstPrintCopy = inst_SIC.lstPrintCopy;
        List<SelectOption> lstInvoiceType = inst_SIC.lstInvoiceType;
        lstInvoiceType = null;
        List<SelectOption> lstLogo = inst_SIC.lstLogo;
        pref.getParameters().put('PrintCopy', 'None');
        //List<String> copiesToPrint = inst_SIC.copiesToPrint;
        String selectedInvoicetype = inst_SIC.selectedInvoicetype;
        Boolean containsLumSumCategory = inst_SIC.containsLumSumCategory;

        pref.getParameters().put('objectType', 'SalesInvoiceLine');
        //inst_SIC.insertLine();
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theQuantity');
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('newFieldValue', 'TEST');
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theResource');
        pref.getParameters().put('newFieldValue', ResourceRecord.Id);
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', 'TEST');
        inst_SIC.validateField();

        inst_SIC.deleteLine();
        inst_SIC.deleteSalesInvoice();

        inst_SIC.lstInvoiceType = Null;
        List<SelectOption> lstLogo2 = inst_SIC.lstLogo;

        pref.getParameters().remove('id');
        StdCon = new ApexPages.StandardController(new Sales_Invoice__c());
        inst_SIC = new SalesInvoiceController(StdCon);
        //inst_SIC.postSI();
        //inst_SIC.unpostSI();
        inst_SIC.validateInvoiceDate();
        inst_SIC.validatePaymentTerm() ;
        Boolean posted = inst_SIC.posted;
        PageReference pageref = Page.SalesInvoice;
        ///////////////////////////////////////
        Sales_Invoice_Line__c SILineRecord = SalesInvoiceLineRecord;
        SILineRecord.Category__c = Null;
        SILineRecord.Resource__c = Null;
        SILineRecord.Quantity__c = 0;
        SILineRecord.Rental_Order__c = Null;
        SILineRecord.TM_Line__c = Null;
        SILineRecord.Tax_Group__c = Null;
        List<Sales_Invoice_Line__c> SILList2 = New List<Sales_Invoice_Line__c>();
        SILList2.add(SILineRecord);
        SalesInvoiceTriggersMgmt.SILInsertUpdate(SILList2);


        TestDataUtil.ServiceCenterRecord.Override_Remittance_on_Invoice__c = true;
        update TestDataUtil.ServiceCenterRecord;
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        StdCon = new ApexPages.StandardController(SalesInvoiceRecord);
        inst_SIC = new SalesInvoiceController(StdCon);

        inst_SIC.updatePostedSI();
        Test.stopTest();
    }

    @IsTest
    private static void Test_SalesInvoiceController3() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        CompanyMgmt.byPassTrigger = true;
        //Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceCMRecord;
        //Sales_Invoice_Line__c SalesInvoiceLineRecord = TestDataUtil.SalesInvoiceLineCMRecord;
        Account billTo = [SELECT Id FROM Account LIMIT 1];
        Salesperson__c sp = [SELECT Id FROM Salesperson__c LIMIT 1];
        Subsidiary_Company__c subCom = [SELECT Id FROM Subsidiary_Company__c LIMIT 1];
        Tax_Area__c taxArea = [SELECT Id FROM Tax_Area__c LIMIT 1];
        Service_Center__c sc = [SELECT Id FROM Service_Center__c LIMIT 1];
        Sales_Order__c salesOrder = [SELECT Id FROM Sales_Order__c LIMIT 1];
        Payment_Term__c paymentTerm = [SELECT Id FROM Payment_Term__c LIMIT 1];
        TM__c tm = [SELECT Id FROM TM__c LIMIT 1];
        TM_Line__c tmLine = [SELECT Id FROM TM_Line__c LIMIT 1];
        Unit_of_Measure__c uom = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Resource__c ResourceRecord = [SELECT Id,Tax_Group__c,Unit_of_Measure__c FROM Resource__c Limit 1];

        Sales_Invoice__c SalesInvoiceRecord = new Sales_Invoice__c(
                Bill_to_Customer__c = billTo.Id,
                Salesperson__c = sp.Id,
                Account_Executive__c = sp.Id,
                Subsidiary_Company__c = subCom.Id,
                Tax_Area__c = taxArea.Id,
                Service_Center__c = sc.Id,
                Document_Status__c = 'Open',
                Sales_Order__c = salesOrder.Id,
                Payment_Term__c = paymentTerm.Id,
                Credit_Memo__c = true
        );

        insert SalesInvoiceRecord;

        Sales_Invoice_Line__c SalesInvoiceLineRecord = new Sales_Invoice_Line__c(
                Sales_Invoice__c = SalesInvoiceRecord.Id,
                Resource__c = ResourceRecord.Id,
                Category__c = 'Labor',
                Description__c = 'Test',
                Line_No__c = 5,
                Quantity__c = -5,
                Unit_Price__c = 2,
                Line_Amount__c = 0,
                Line_Amt_Incl_Tax__c = 0,
                Tax__c = 0,
                Tax_Group__c = 'NT',
                Unit_of_Measure__c = uom.Id,
                TM_Line__c = tmLine.id,
                TM__c = tm.id
        );

        insert SalesInvoiceLineRecord;

        //Sales_Invoice__c SalesInvoiceRecord = [SELECT Id,Credit_Memo__c,Posting_Date__c,Tax_Area__c FROM Sales_Invoice__c Where Credit_Memo__c = True Limit 1];
        //Sales_Invoice_Line__c SalesInvoiceLineRecord = [SELECT Id FROM Sales_Invoice_Line__c Where Sales_Invoice__c =: SalesInvoiceRecord.Id];

        Test.startTest();
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);
        inst_SIC.theSI = SalesInvoiceRecord;
        inst_SIC.postSI();
        inst_SIC.unpostSI();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Waste Disposal');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Waste Disposal');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Bundled');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Misc. Charges And Taxes');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Labor');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Subcontractors');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Demurrage');
        inst_SIC.addLine();

      
        Test.stopTest();
    }

    @IsTest
    private static void Test_SalesInvoiceController4() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        CompanyMgmt.byPassTrigger = true;
        //Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceCMRecord;
        //Sales_Invoice_Line__c SalesInvoiceLineRecord = TestDataUtil.SalesInvoiceLineCMRecord;
        Account billTo = [SELECT Id FROM Account LIMIT 1];
        Salesperson__c sp = [SELECT Id FROM Salesperson__c LIMIT 1];
        Subsidiary_Company__c subCom = [SELECT Id FROM Subsidiary_Company__c LIMIT 1];
        Tax_Area__c taxArea = [SELECT Id FROM Tax_Area__c LIMIT 1];
        Service_Center__c sc = [SELECT Id FROM Service_Center__c LIMIT 1];
        Sales_Order__c salesOrder = [SELECT Id FROM Sales_Order__c LIMIT 1];
        Payment_Term__c paymentTerm = [SELECT Id FROM Payment_Term__c LIMIT 1];
        TM__c tm = [SELECT Id FROM TM__c LIMIT 1];
        TM_Line__c tmLine = [SELECT Id FROM TM_Line__c LIMIT 1];
        Unit_of_Measure__c uom = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Resource__c ResourceRecord = [SELECT Id,Tax_Group__c,Unit_of_Measure__c FROM Resource__c Limit 1];

        Sales_Invoice__c SalesInvoiceRecord = new Sales_Invoice__c(
                Bill_to_Customer__c = billTo.Id,
                Salesperson__c = sp.Id,
                Account_Executive__c = sp.Id,
                Subsidiary_Company__c = subCom.Id,
                Tax_Area__c = taxArea.Id,
                Service_Center__c = sc.Id,
                Document_Status__c = 'Open',
                Sales_Order__c = salesOrder.Id,
                Payment_Term__c = paymentTerm.Id,
                Credit_Memo__c = true
        );

        insert SalesInvoiceRecord;

        Sales_Invoice_Line__c SalesInvoiceLineRecord = new Sales_Invoice_Line__c(
                Sales_Invoice__c = SalesInvoiceRecord.Id,
                Resource__c = ResourceRecord.Id,
                Category__c = 'Labor',
                Description__c = 'Test',
                Line_No__c = 5,
                Quantity__c = -5,
                Unit_Price__c = 2,
                Line_Amount__c = 0,
                Line_Amt_Incl_Tax__c = 0,
                Tax__c = 0,
                Tax_Group__c = 'NT',
                Unit_of_Measure__c = uom.Id,
                TM_Line__c = tmLine.id,
                TM__c = tm.id
        );

        insert SalesInvoiceLineRecord;

        //Sales_Invoice__c SalesInvoiceRecord = [SELECT Id,Credit_Memo__c,Posting_Date__c,Tax_Area__c FROM Sales_Invoice__c Where Credit_Memo__c = True Limit 1];
        //Sales_Invoice_Line__c SalesInvoiceLineRecord = [SELECT Id FROM Sales_Invoice_Line__c Where Sales_Invoice__c =: SalesInvoiceRecord.Id];

        Test.startTest();
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);
        inst_SIC.theSI = SalesInvoiceRecord;

        List<Sales_Invoice_Line__c> sils = [SELECT Id FROM Sales_Invoice_Line__c];

        inst_SIC.theSILList = sils;
        inst_SIC.theSILListLabor = sils;
        inst_SIC.theSILListEquipment = sils;
        inst_SIC.theSILListMaterials = sils;
        inst_SIC.theSILListMisc = sils;
        inst_SIC.theSILListSubcontractors = sils;
        inst_SIC.theSILListWasteDisposal = sils;
        inst_SIC.theSILListDemurrage = sils;
        inst_SIC.theSILListLumpSum = sils;
        inst_SIC.theSILListMisc = sils;
        pref.getParameters().put('objectType', 'SalesInvoiceLine');
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theLBillasLumpSum');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', 'False');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theLQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theMUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theMTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theEQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theEBillasLumpSum');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', 'False');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theEUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theETaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theSQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theSUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theSTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theWQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theWUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theWTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theDQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theDUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theDTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theLumpQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theLumpUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theDTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theLumpQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theLumpUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theLumpTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theMiscQuantity');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theMiscUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theMiscTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theLContractLine');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theEContractLine');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theLumpSumContractLine');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('fieldName', 'theMContractLine');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        Test.stopTest();
    }


    @IsTest
    private static void Test_SalesInvoiceControllerAddLine() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        test.startTest();
        Sales_Invoice__c SalesInvoiceRecord = [SELECT Id,Credit_Memo__c,Posting_Date__c,Tax_Area__c FROM Sales_Invoice__c Where Credit_Memo__c = False Limit 1];
        
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);

        inst_SIC.postSI();
        inst_SIC.unpostSI();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Waste Disposal');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Waste Disposal');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Bundled');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Misc. Charges And Taxes');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Labor');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Subcontractors');
        inst_SIC.addLine();
        pref.getParameters().put('ObjectType', 'SILine');
        pref.getParameters().put('LineCategory', 'Demurrage');
        inst_SIC.addLine();

        List<Object> WrapSILForLumpFormat = inst_SIC.WrapSILForLumpFormat;

        List<Sales_Invoice_Line__c> sils = [SELECT Id FROM Sales_Invoice_Line__c];
        for (Sales_Invoice_Line__c sil : sils) {
            sil.Scheduled_Date__c = Date.today();
        }
        update sils;

        inst_SIC.voidSalesInvoice();
        inst_SIC.organizeData();

        Test.stopTest();
    }

    @IsTest
    private static void testReverseSI() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        //Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceCMRecord;
        //Sales_Invoice_Line__c SalesInvoiceLineRecordList = TestDataUtil.SalesInvoiceLineCMRecord;
        Sales_Invoice__c testInvoiceRecord = [SELECT Id FROM Sales_Invoice__c LIMIT 1];
        String SIId = testInvoiceRecord.Id;
        Sales_Invoice__c SalesInvoiceRecord = new Sales_Invoice__c();
        List<Sales_Invoice_Line__c> SalesInvoiceLineRecordList = new List<Sales_Invoice_Line__c>();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Invoice__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        //Ticket#21211
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Bill_To_Customer__r.Name,Tax_Area__r.Name,Contact__r.Name,Account_Executive__r.Name,Salesperson__r.Name,Sales_Order__r.Name';
        strQuery += ',Payment_Term__r.Name, Bill_to_Customer__r.AccountNumber, Service_Center__r.Remittance_Name__c, Service_Center__r.Remittance_Address_1__c ';
        strQuery += ',Service_Center__r.Remittance_Address_2__c, Service_Center__r.Remittance_Phone__c, Service_Center__r.EFT_To_Bank_Name__c ';
        strQuery += ',Service_Center__r.EFT_Address_1__c, Service_Center__r.EFT_Address_2__c, Service_Center__r.Checking_Account_1__c, Service_Center__r.Checking_Account_2__c  ';
        strQuery += ',Contract__r.Override_Remittance_on_Invoice__c, Contract__r.Remittance_Name__c, Contract__r.Remittance_Address_1__c, Contract__r.Remittance_Address_2__c ';
        strQuery += ',Contract__r.EFT_To_Bank_Name__c, Contract__r.EFT_Address_1__c, Contract__r.EFT_Address_2__c, Contract__r.Checking_Account_1__c ';
        strQuery += ',Contract__r.Checking_Account_2__c, Contract__r.Remittance_Phone__c, Contract__r.Logo__c ';
        strQuery += ',Service_Center__r.Override_Remittance_on_Invoice__c, Service_Center__r.Logo__c, Tax_Area__r.Sales_Tax_Account__c, Sales_Order__r.CMR_Description__c ';
        strQuery += ',Bill_to_Customer__r.Inter_co_Account__c,Bill_to_Customer__r.Inter_co_Revenue_Account__c, Bill_to_Customer__r.Inter_co_AR_Account__c,Reversed_from_SI__r.Name,' +
                'Service_Center__r.Name, Site_Contact_2__r.Name, Bill_to_Customer__r.InterCo__c ';
        strQuery += ' FROM Sales_Invoice__c WHERE Id =: SIId';
        SalesInvoiceRecord = Database.query(strQuery);

        Map<String, Schema.SObjectField> fields2 = Schema.SObjectType.Sales_Invoice_Line__c.fields.getMap();
        List<String> lstFields2 = new List<String>();
        for (Schema.SObjectField field : fields2.values()) {
            lstFields2.add(field.getDescribe().getName());
        }
        String strQuery2 = 'SELECT ' + String.join(lstFields2, ',');
        strQuery2 += ',Unit_of_Measure__r.Name,Sales_Invoice__r.Bill_to_Customer__c,Resource__r.Name, TM__r.Name, Resource_Type__r.Name, Contract_Line__r.Name, Contract_Line__r.Regular_Rate__c,' +
                'Service_Center__r.Name, Resource_Type__r.Fuel_Fired_Equipment__c';
        strQuery2 += ' FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SIId ORDER BY Line_No__c';
        SalesInvoiceLineRecordList = Database.query(strQuery2);

        Test.startTest();
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);

        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);
        inst_SIC.theSILListLabor = SalesInvoiceLineRecordList;
        inst_SIC.reverseSalesInvoice();
        SalesInvoiceRecord.Credit_Memo_Reason_Code__c = 'Customer is tax exempt';
        inst_SIC.theSI = SalesInvoiceRecord;
        inst_SIC.theSILList = SalesInvoiceLineRecordList;
        inst_SIC.reverseSalesInvoice();

        SalesInvoiceRecord.Credit_Memo_Reason_Code__c = 'Pricing error';
        inst_SIC.theSI = SalesInvoiceRecord;
        inst_SIC.creditMemoNote = '12313123';
        inst_SIC.reverseSalesInvoice();
        inst_SIC.creditMemoNote = '1234567890';
        inst_SIC.reverseSalesInvoice();
        
        List<Sales_invoice__c> invoiceList = new List<Sales_invoice__c>();
        invoiceList.add(SalesInvoiceRecord);
        SalesInvoiceTriggersMgmt.updateTMInvoiceRelations(SalesInvoiceLineRecordList);
        SalesInvoiceTriggersMgmt.SIDelete(invoiceList);
        Test.stopTest();
    }

    @IsTest
    private static void testSurcharge(){
        Test.startTest();
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        Sales_Invoice__c testInvoiceRecord = [SELECT Id FROM Sales_Invoice__c LIMIT 1];
        String recordId = testInvoiceRecord.Id;
        pref.getParameters().put('id', recordId);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(testInvoiceRecord);
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);

        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Sales_Invoice__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Sales_Invoice__c WHERE Id =: recordId';
        testInvoiceRecord = Database.query(strQuery);
        testInvoiceRecord.Surcharge_Type__c = 'EEC Fee';
        testInvoiceRecord.Surcharge_Pct__c = 10;
        inst_SIC.theSI = testInvoiceRecord;
        inst_SIC.addDemurrageSurchargeLine('EEC Fee');
        inst_SIC.msave();
        testInvoiceRecord.Surcharge_Type__c = 'Fuel Surcharge';
        inst_SIC.theSI = testInvoiceRecord;
        inst_SIC.addDemurrageSurchargeLine('Fuel Surcharge');
        inst_SIC.updateDemurrageSurchargeLine();
        List<Sales_Invoice_Line__c> deletedLines = new List<Sales_Invoice_Line__c>();
        inst_SIC.removeDemurrageSurchargeLine(deletedLines);
        inst_SIC.msave();
        Test.stopTest();
    }
}