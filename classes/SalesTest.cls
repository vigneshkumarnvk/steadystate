@isTest
public class SalesTest {
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = :companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }
    
    private static testMethod void Test_SalesInvoiceController() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref); 
		CompanyMgmt.byPassTrigger = true;
        List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
        Sales_Invoice_Line__C SalesInvoiceLineRecord1 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Equipment',
            Description__c = 'Test user',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord1;
        salesInvoiceLines.add(SalesInvoiceLineRecord1);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord2 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Bundled',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord2;
        salesInvoiceLines.add(SalesInvoiceLineRecord2);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord3 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Materials',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord3;
        salesInvoiceLines.add(SalesInvoiceLineRecord3);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord4 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Subcontractors',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord4;
        salesInvoiceLines.add(SalesInvoiceLineRecord4);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord5 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Waste Disposal',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord5;
        salesInvoiceLines.add(SalesInvoiceLineRecord5);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord6 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Demurrage',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord6;
        salesInvoiceLines.add(SalesInvoiceLineRecord6);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord7 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Misc. Charges And Taxes',
            Description__c = 'Test1',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id,
            Resource_Type__c = TestDataUtil.ResourceTypeRecord.id
        );
        //insert SalesInvoiceLineRecord7;
        salesInvoiceLines.add(SalesInvoiceLineRecord7);
        
        insert salesInvoiceLines;
        
        test.startTest();
        
        //pref.getParameters().put('id', TestDataUtil.SalesInvoiceRecord.Id);
        pref.getParameters().put('id', TestDataUtil.SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesInvoiceRecord);
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = TestDataUtil.SalesInvoiceLineRecord;
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
        inst_SIC.validateBillToCustomer();
        inst_SIC.validateTaxArea();
        inst_SIC.validateTaxLiable();
        inst_SIC.validateContact();
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
        
        inst_SIC.PrintSalesInvoice();
        inst_SIC.save();
        inst_SIC.quickSave();
        inst_SIC.save();
        inst_SIC.cloneSalesInvoice();
        inst_SIC.cancel();
        inst_SIC.returnBack();
        inst_SIC.deleteSalesInvoice();
        SalesInvoiceTriggersMgmt.updateTMInvoiceRelations(salesInvoiceLines);
        
        /* scott temp soql 101 error
pref.getParameters().put('objectType', 'SalesInvoiceLine');
inst_SIC.insertLine();
pref.getParameters().put('lineNo', '0');
pref.getParameters().put('fieldName', 'theQuantity');
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();
//inst_SIC.validateField1();
pref.getParameters().put('newFieldValue', 'TEST');
//inst_SIC.validateField1();
pref.getParameters().put('fieldName', 'theResource');
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
//inst_SIC.validateField1();
pref.getParameters().put('fieldName', 'theTaxGroup');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Tax_Group__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', 'TEST');
inst_SIC.validateField();
//inst_SIC.validateField1();
pref.getParameters().put('fieldName', 'theUnitPrice');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
//inst_SIC.validateField1();
pref.getParameters().put('fieldName', 'theJobPosition');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('lineNo', '0');
pref.getParameters().put('fieldName', 'theEquipment');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMiscResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMiscResourceType');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theLResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theEResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theSResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theWResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theDResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theLUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theEUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theSUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theWUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theDUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theLumpUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theLumpSumResourceType');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMiscUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
try {
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
} catch (Exception e) {

}

List<Sales_Invoice_Line__c> theSILLines = new List<Sales_Invoice_Line__c>();
theSILLines.add(SalesInvoiceLineRecord);
SalesInvoiceController.WrapSILByCategory cmp = new SalesInvoiceController.WrapSILByCategory();
cmp.Category = 'Labor';
cmp.theSILLines = theSILLines;
List<Sales_Invoice_Line__c> theSILList = New List<Sales_Invoice_Line__c>();
theSILList.add(TestDataUtil.SalesInvoiceLineRecord);
inst_SIC.theSILList = theSILList;
inst_SIC.reverseSalesInvoice();
List<SalesInvoiceController.WrapSILByCategory> WrapSIL = inst_SIC.WrapSIL;
List<SalesInvoiceController.WrapSILByCategory> WrapSILByCategoryAndDate = New List<SalesInvoiceController.WrapSILByCategory>();
WrapSILByCategoryAndDate = inst_SIC.WrapSILByCategoryAndDate;
pref.getParameters().put('displayId', '');
*/
        /*101 sql error


inst_SIC.deleteLine();
inst_SIC.deleteSalesInvoice();

inst_SIC.lstInvoiceType = Null;
List<SelectOption> lstLogo2 = inst_SIC.lstLogo;


pref.getParameters().remove('id');
StdCon = new ApexPages.StandardController(new Sales_Invoice__c());
inst_SIC = new SalesInvoiceController(StdCon);
inst_SIC.postSI();
inst_SIC.unpostSI();
inst_SIC.validateInvoiceDate();
inst_SIC.validatePaymentTerm() ;
Boolean posted = inst_SIC.posted;
PageReference pageref = Page.SalesInvoice;
///////////////////////////////////////

Sales_Invoice_Line__c SILineRecord = TestDataUtil.SalesInvoiceLineRecord;
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
pref.getParameters().put('id', TestDataUtil.SalesInvoiceRecord.Id);
StdCon = new ApexPages.StandardController(TestDataUtil.SalesInvoiceRecord);
inst_SIC = new SalesInvoiceController(StdCon);

inst_SIC.updatePostedSI();
*/
        Test.stopTest();
        
    }
    
    private static testMethod void Test_SalesInvoiceController1() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        CompanyMgmt.byPassTrigger = true;
        List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
        Sales_Invoice_Line__C SalesInvoiceLineRecord1 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Equipment',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord1;
        salesInvoiceLines.add(SalesInvoiceLineRecord1);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord2 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Bundled',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord2;
        salesInvoiceLines.add(SalesInvoiceLineRecord2);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord3 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Materials',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord3;
        salesInvoiceLines.add(SalesInvoiceLineRecord3);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord4 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Subcontractors',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord4;
        salesInvoiceLines.add(SalesInvoiceLineRecord4);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord5 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Waste Disposal',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord5;
        salesInvoiceLines.add(SalesInvoiceLineRecord5);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord6 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Demurrage',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord6;
        salesInvoiceLines.add(SalesInvoiceLineRecord6);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord7 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Misc. Charges And Taxes',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id,
            Resource_Type__c = TestDataUtil.ResourceTypeRecord.id
        );
        //insert SalesInvoiceLineRecord7;
        salesInvoiceLines.add(SalesInvoiceLineRecord7);
        
        insert salesInvoiceLines;
        
        test.startTest();
        
        
        pref.getParameters().put('id', TestDataUtil.SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesInvoiceRecord);
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = TestDataUtil.SalesInvoiceLineRecord;
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);
        
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
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', 'TEST');
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theUnitPrice');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theJobPosition');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theEquipment');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theMResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscResourceType');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theLResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theEResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theSResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theWResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theDResource');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', '1');
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theLUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theMUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theEUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theSUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        //pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        //inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theWUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        //pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        //inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theDUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theLumpUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theLumpSumResourceType');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscUOM');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        try {
            pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
            inst_SIC.validateField();
        } catch (Exception e) {
            
        }
        
        List<Sales_Invoice_Line__c> theSILLines = new List<Sales_Invoice_Line__c>();
        theSILLines.add(SalesInvoiceLineRecord);
        SalesInvoiceController.WrapSILByCategory cmp = new SalesInvoiceController.WrapSILByCategory();
        cmp.Category = 'Labor';
        cmp.theSILLines = theSILLines;
        List<Sales_Invoice_Line__c> theSILList = New List<Sales_Invoice_Line__c>();
        theSILList.add(TestDataUtil.SalesInvoiceLineRecord);
        inst_SIC.theSILList = theSILList;
        inst_SIC.reverseSalesInvoice();
        List<SalesInvoiceController.WrapSILByCategory> WrapSIL = inst_SIC.WrapSIL;
        List<SalesInvoiceController.WrapSILByCategory> WrapSILByCategoryAndDate = New List<SalesInvoiceController.WrapSILByCategory>();
        WrapSILByCategoryAndDate = inst_SIC.WrapSILByCategoryAndDate;
        pref.getParameters().put('displayId', '');    
    }
    
    private static testMethod void Test_SalesInvoiceController2() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        CompanyMgmt.byPassTrigger = true;
        List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
        Sales_Invoice_Line__C SalesInvoiceLineRecord1 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Equipment',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord1;
        salesInvoiceLines.add(SalesInvoiceLineRecord1);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord2 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Bundled',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord2;
        salesInvoiceLines.add(SalesInvoiceLineRecord2);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord3 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Materials',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord3;
        salesInvoiceLines.add(SalesInvoiceLineRecord3);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord4 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Subcontractors',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord4;
        salesInvoiceLines.add(SalesInvoiceLineRecord4);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord5 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Waste Disposal',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord5;
        salesInvoiceLines.add(SalesInvoiceLineRecord5);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord6 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Demurrage',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        //insert SalesInvoiceLineRecord6;
        salesInvoiceLines.add(SalesInvoiceLineRecord6);
        
        Sales_Invoice_Line__C SalesInvoiceLineRecord7 = new Sales_Invoice_Line__c(
            Sales_Invoice__c = TestDataUtil.SalesInvoiceRecord.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Misc. Charges And Taxes',
            Description__c = 'Test',
            Line_No__c = 5,
            Quantity__c = 5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineLaborRecord.id,
            TM__c = TestDataUtil.TMRecord.id,
            Resource_Type__c = TestDataUtil.ResourceTypeRecord.id
        );
        //insert SalesInvoiceLineRecord7;
        salesInvoiceLines.add(SalesInvoiceLineRecord7);
        
        insert salesInvoiceLines;
        
        test.startTest();
        
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesInvoiceRecord);
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = TestDataUtil.SalesInvoiceLineRecord;
        
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
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        pref.getParameters().put('fieldName', 'theTaxGroup');
        pref.getParameters().put('newFieldValue', '');
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Tax_Group__c);
        inst_SIC.validateField();
        pref.getParameters().put('newFieldValue', 'TEST');
        inst_SIC.validateField();
        //inst_SIC.validateField1();
        /*
pref.getParameters().put('fieldName', 'theUnitPrice');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
//inst_SIC.validateField1();
pref.getParameters().put('fieldName', 'theJobPosition');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('lineNo', '0');
pref.getParameters().put('fieldName', 'theEquipment');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMiscResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMiscResourceType');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theLResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theEResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theSResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theWResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theDResource');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', '1');
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theLUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theEUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theSUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theWUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theDUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theLumpUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theLumpSumResourceType');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
inst_SIC.validateField();

pref.getParameters().put('fieldName', 'theMiscUOM');
pref.getParameters().put('newFieldValue', '');
inst_SIC.validateField();
try {
pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Unit_of_Measure__c);
inst_SIC.validateField();
} catch (Exception e) {

}
*/
        
        inst_SIC.deleteLine();
        inst_SIC.deleteSalesInvoice();
        
        inst_SIC.lstInvoiceType = Null;
        List<SelectOption> lstLogo2 = inst_SIC.lstLogo;
        
        pref.getParameters().remove('id');
        StdCon = new ApexPages.StandardController(new Sales_Invoice__c());
        inst_SIC = new SalesInvoiceController(StdCon);
        inst_SIC.postSI();
        inst_SIC.unpostSI();
        inst_SIC.validateInvoiceDate();
        inst_SIC.validatePaymentTerm() ;
        Boolean posted = inst_SIC.posted;
        PageReference pageref = Page.SalesInvoice;
        ///////////////////////////////////////
        Sales_Invoice_Line__c SILineRecord = TestDataUtil.SalesInvoiceLineRecord;
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
        pref.getParameters().put('id', TestDataUtil.SalesInvoiceRecord.Id);
        StdCon = new ApexPages.StandardController(TestDataUtil.SalesInvoiceRecord);
        inst_SIC = new SalesInvoiceController(StdCon);
        
        inst_SIC.updatePostedSI();
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesInvoiceControllerAddLine() {
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        
        test.startTest();
        
        //pref.getParameters().put('id', TestDataUtil.SalesInvoiceRecord.Id);
        pref.getParameters().put('id', TestDataUtil.SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesInvoiceRecord);
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = TestDataUtil.SalesInvoiceLineRecord;
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);
        
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
    
    private static testMethod void Test_SalesInvoiceControllerAddLine2() {
        PageReference pref = Page.SalesInvoice;
        CompanyMgmt.byPassTrigger = true;
        Test.setCurrentPage(pref);
        
        test.startTest();
        
        //pref.getParameters().put('id', TestDataUtil.SalesInvoiceRecord.Id);
        pref.getParameters().put('id', TestDataUtil.SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesInvoiceRecord);
        
        Sales_Invoice_Line__c SalesInvoiceLineRecord = TestDataUtil.SalesInvoiceLineRecord;
        SalesInvoiceController inst_SIC = new SalesInvoiceController(StdCon);
        
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
    
    private static testMethod void Test_SalesInvoiceMgmt() {
        Test.startTest();
        GL_Entry__c GLEntryRecord = TestDataUtil.GLEntryRecord;
        Tax_Jurisdiction__c taxJurisdiction = TestDataUtil.TaxJurisdictionRecord;
        Tax_Detail__c taxDetail = TestDataUtil.TaxDetailRecord;
        Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceRecord;
        SalesInvoiceRecord.Posting_Date__c = Date.today();
        SalesInvoiceRecord.Tax_Area__c = TestDataUtil.TaxAreaRecord.id;
        update SalesInvoiceRecord;
        Sales_Order__c SO = SalesOrderMgmt.validateCreateSiteAddress(TestDataUtil.SalesOrderRecord);
        SalesInvoiceMgmt.unpostCheck(SalesInvoiceRecord);
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        CompanyMgmt.byPassTrigger = true;
        theSILList.add(TestDataUtil.SalesInvoiceLineRecord);
        
        
        
        SalesInvoiceRecord.Document_Status__c = 'Posted';
        SalesInvoiceRecord.Posting_Date__c = Date.today().addDays(-5);
        SalesInvoiceRecord.New_Posting_Date__c = Date.today();
        update SalesInvoiceRecord;
        
        SalesInvoiceMgmt.postSI(theSILList, SalesInvoiceRecord);
        SalesInvoiceMgmt.updateGL(GLEntryRecord, SalesInvoiceRecord, False);
        SalesInvoiceMgmt.unpostSI(SalesInvoiceRecord);
        //  CompanyMgmt.byPassTrigger = false;
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesInvoiceMgmt2() {
        GL_Entry__c GLEntryRecord = TestDataUtil.GLEntryRecord;
        Tax_Jurisdiction__c taxJurisdiction = TestDataUtil.TaxJurisdictionRecord;
        Tax_Detail__c taxDetail = TestDataUtil.TaxDetailRecord;
        Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceRecord;
        SalesInvoiceRecord.Posting_Date__c = Date.newInstance(2020, 1, 1);
        SalesInvoiceRecord.Tax_Area__c = TestDataUtil.TaxAreaRecord.id;
        
        Sales_Invoice__c reverseFromSI = new Sales_Invoice__c(
            Bill_to_Customer__c = TestDataUtil.AccountRecord.Id,
            Salesperson__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Document_Status__c = 'Open',
            Sales_Order__c = TestDataUtil.SalesOrderRecord.Id,
            Payment_Term__c = TestDataUtil.PaymentTermRecord.Id,
            Posting_Date__c = Date.newInstance(2021, 1, 1)
        );
        insert reverseFromSI;
        SalesInvoiceRecord.Reversed_from_SI__c = reverseFromSI.Id;
        update SalesInvoiceRecord;
        Account acc = TestDataUtil.AccountRecord;
        acc.Inter_co_Account__c = true;
        update acc;
        SalesInvoiceRecord.Bill_To_Customer__r = acc;
        Test.startTest();
        List<Sales_Invoice_Line__c> theSILList = new List<Sales_Invoice_Line__c>();
        theSILList.add(TestDataUtil.SalesInvoiceLineRecord);
        SalesInvoiceMgmt.checkPost(TestDataUtil.SalesInvoiceRecord);
        SalesInvoiceRecord.Credit_Memo__c = true;
        SalesInvoiceMgmt.checkPost(TestDataUtil.SalesInvoiceRecord);
        Test.stopTest();
        
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
        salesline.Quantity__c = 1100;
        salesline.Resource_Type__c = null;
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
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Resource_Type__c);
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
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Resource_Type__c);
        inst_SOC.validateField();
        
        pref.getParameters().put('fieldName', 'theSResource');
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceRecord.Id);
        inst_SOC.validateField();
        
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesOrderController2a() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
		CompanyMgmt.byPassTrigger = true;
        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        
        
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
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
        inst_SOC.validateSalesOrderType();
        inst_SOC.validateSalespeople();
        inst_SOC.validateContract();
        List<Sales_Line__c> SOListLaborLines = inst_SOC.SOListLaborLines;
        List<Sales_Line__c> SOListMaterialLines = inst_SOC.SOListMaterialLines;
        List<Sales_Line__c> SOListEquipmentLines = inst_SOC.SOListEquipmentLines;
        String[] messagesWS = inst_SOC.getMessages();
        
        Test.startTest();
        
        inst_SOC.PrintConfirmation();
        inst_SOC.notValidatePrintConfirmation();
        
        inst_SOC.save();
        inst_SOC.quickSave();
        inst_SOC.LaborAssumption = 'OvertimeRate';
        inst_SOC.quickSave();
        inst_SOC.LaborAssumption = 'DailyRate';
        inst_SOC.quickSave();
        inst_SOC.LaborAssumption = 'LumpSum';
        inst_SOC.quickSave();
        inst_SOC.createTemporaryTmList();
        inst_SOC.getConvertMessages();
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
        //inst_SOC.CreateMiscCreditMemo();
        inst_SOC.CreateBlankTM();
        //inst_SOC.selectTmSections();
        
        //inst_SOC.tmStartingDateValue = '02/16/2018';
        //inst_SOC.tmEndingDateValue = '02/17/2018';
        inst_SOC.theSO = TestDataUtil.SalesOrderRecord;
        //inst_SOC.selectTmList();
        //List<String> strings = inst_SOC.Categories;
        //List<TM__c> tms = inst_SOC.selectedTMs;
        //inst_SOC.createSI();
        //inst_SOC.selectAllTML();
        
        List<TM_Line__c> ltmLines = new List<TM_Line__c>();
        ltmLines.add(TestDataUtil.TMLineDemurrageRecord);
        //ltmLines.add(TestDataUtil.TMLineEquipmentRecord);
        ltmLines.add(TestDataUtil.TMLineLaborRecord);
        List<Sales_Invoice_Line__c> insertSIL = inst_SOC.insertSIL();
        inst_SOC.reInsertSL();
        inst_SOC.updateTMPrice();
        /*
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
//inst_SOC.theSO = SO;
*/
        Test.stopTest();
    }
    
    /*
private static testMethod void Test_SalesOrderController5() {

CompanyMgmt.byPassLineTrigger = true;
CompanyMgmt.byPassTrigger = true;
PageReference pref = Page.SalesOrder;
Test.setCurrentPage(pref);

pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
SalesOrderController inst_SOC = new SalesOrderController(StdCon);
String str = inst_SOC.addLineCategory;
Sales_Order__c SO = inst_SOC.salesOrder;
inst_SOC.includeWeekend = True;
inst_SOC.tmCount = 5;
inst_SOC.startingDateValue = '01/01/2018';
Test.startTest();
inst_SOC.createTemporaryTmList();
inst_SOC.CreateTM();
inst_SOC.validateCreateSiteAddress();
List<SalesOrderController.TMWrap> theTMWrapLis = new List<SalesOrderController.TMWrap>();
Boolean isSalesOrder = inst_SOC.isSalesOrder;
SO.Document_Type__c = 'Sales Quote';
List<Sales_Line__c> SOListSubContractorLines = inst_SOC.SOListSubContractorLines;
List<Sales_Line__c> SOListWasteDisposal = inst_SOC.SOListWasteDisposal;
List<SelectOption> lstConvertTo = inst_SOC.lstConvertTo;
//List<SelectOption> LAItems = inst_SOC.getLaborAssumptionItems();
//Map<String, Boolean> mapStandardAssumptions = inst_SOC.mapStandardAssumptions;
Test.stopTest();
}
*/
    
    private static testMethod void Test_SalesOrderController6() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        
        
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        String str = inst_SOC.addLineCategory;
        Sales_Order__c SO = inst_SOC.salesOrder;
        inst_SOC.includeWeekend = True;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        Test.startTest();
        inst_SOC.openSO();
        inst_SOC.validateTaxLiable();
        inst_SOC.validateTaxArea();
        inst_SOC.copyPWInfo();
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesOrderController7() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        
        
        Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        String str = inst_SOC.addLineCategory;
        Sales_Order__c SO = inst_SOC.salesOrder;
        inst_SOC.includeWeekend = true;
        inst_SOC.tmCount = 5;
        inst_SOC.startingDateValue = '01/01/2018';
        Test.startTest();
        //inst_SOC.convertQuoteToOrder();
        inst_SOC.closeSO();
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesOrderController8() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        
        Test.startTest();
        
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
        
        Test.stopTest();
    }
    
    private static testMethod void Test_SalesOrderController9() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        CompanyMgmt.byPassTrigger = true;
        
        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        
        //Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        //String title = inst_SOC.title;
        //Boolean open = inst_SOC.Open;
        
        //boolean allowDataOverride = inst_SOC.allowDataOverride;
        //boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
        //inst_SOC.includeWeekend = True;
        //inst_SOC.tmCount = 5;
        //inst_SOC.startingDateValue = '01/01/2018';
        Sales_Order__c SO = inst_SOC.salesOrder;
        
        //List<Sales_Line__c> SLList = inst_SOC.SLList;
        
        /*
inst_SOC.validateSalesOrderType();
inst_SOC.validateSalespeople();
inst_SOC.validateContract();
*/
        
        //List<Sales_Line__c> SOListLaborLines = New List<Sales_Line__c>();
        //List<Sales_Line__c> SOListMaterialLines = New List<Sales_Line__c>();
        //List<Sales_Line__c> SOListEquipmentLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListEquipLines = New List<Sales_Line__c>();
        List<Sales_Line__c> SOListLumpSumLines = New List<Sales_Line__c>();
        //List<Sales_Line__c> SOListWasteDisposalLines = New List<Sales_Line__c>();
        
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
        
        pref.getParameters().put('fieldName', 'theLUnitPrice');
        pref.getParameters().put('newFieldValue', '5');
        inst_SOC.validateField();
        
        pref.getParameters().put('fieldName', 'theLUnitPrice');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();
        
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
        
        pref.getParameters().put('fieldName', 'theEquipmentINPT');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();
        
        pref.getParameters().put('fieldName', 'theMaterialINPT');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();
        
        pref.getParameters().put('fieldName', 'theSResource');
        pref.getParameters().put('newFieldValue', '');
        //inst_SOC.validateField();
        
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
    
    private static testMethod void Test_SalesOrderControllerMiscResourceValidation() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        
        List<Sales_Line__c> miscLines = New List<Sales_Line__c>();
        
        miscLines.add(TestDataUtil.SalesMiscLineRecord);
        inst_SOC.theSLList = miscLines;
        
        Test.startTest();
        
        pref.getParameters().put('lineNo', '0');
        
        pref.getParameters().put('fieldName', 'theMiscQuantity');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscTaxGroup');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscUnitPrice');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscUOM');
        pref.getParameters().put('newFieldValue', Null);
        inst_SOC.validateField();
        
        pref.getParameters().put('fieldName', 'theMiscUOM');
        pref.getParameters().put('newFieldValue', TestDataUtil.UnitMeasureRecord.id);
        inst_SOC.validateField();
        
        Test.stopTest();
        
    }
    
    private static testMethod void Test_SalesOrderControllerLumpSumValidation() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        
        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        
        SalesOrderController inst_SOC = new SalesOrderController(StdCon);
        
        List<Sales_Line__c> lumpSumLines = new List<Sales_Line__c>();
        lumpSumLines.add(TestDataUtil.SalesLumpSumLineRecord);
        
        inst_SOC.theSLList = lumpSumLines;
        inst_SOC.theSOListLumpSum = lumpSumLines;
        Test.startTest();
        
        pref.getParameters().put('lineNo', '0');
        
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
        
        Test.stopTest();
        
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
            Subsidiary__c = '1-ACV ENVIRO',
            Status = 'Draft'
        );
        insert ContractRecord ;
        ContractRecord.Status = 'Activated';
        update ContractRecord;
        CompanyMgmt.byPassTrigger = false;
        
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
            Subsidiary__c = '1-ACV ENVIRO',
            Status = 'Draft'
        );
        insert ContractRecord ;
        
        ContractRecord.Status = 'Activated';
        update ContractRecord;
		CompanyMgmt.byPassTrigger = false;

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
            Subsidiary__c = '1-ACV ENVIRO',
            Status = 'Draft'
        );
        
        insert ContractRecord ;
        ContractRecord.Status = 'Activated';
        update ContractRecord;
        CompanyMgmt.byPassTrigger = false;
        
        
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
    private static testMethod void testMethodWhenIncludeSOTrue() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Service_Center__c serviceCenterRecord = TestDataUtil.ServiceCenterRecord;
        serviceCenterRecord.Include_SO_in_EQAI_Invoice_Integration__c = true;
        update serviceCenterRecord;
        Sales_Order__c createSalesOrderRecord = TestDataUtil.SalesOrderRecord;
        pref.getParameters().put('id', createSalesOrderRecord.Id);
        Test.startTest();
        ApexPages.StandardController StdCon = new ApexPages.StandardController(createSalesOrderRecord);
        SalesOrderController salesOrderRecord = new SalesOrderController(StdCon);
        Boolean isChecked = salesOrderRecord.isServCenterChecked ;
        Test.stopTest();
        
    }
    private static testMethod void testMethodForCategory() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Sales_Order__c createSalesOrderRecord = TestDataUtil.SalesOrderRecord;
        pref.getParameters().put('id', createSalesOrderRecord.Id);
        Test.startTest();
        ApexPages.StandardController StdCon = new ApexPages.StandardController(createSalesOrderRecord);
        SalesOrderController salesOrderRecord = new SalesOrderController(StdCon);
        Boolean isChecked = salesOrderRecord.isServCenterChecked ;
        List<Sales_Line__c>  miscList = salesOrderRecord.SOListMisc;
        miscList.add(TestDataUtil.SalesMiscLineRecord);
        List<Sales_Line__c>  lumpSumList = salesOrderRecord.SOListLumpSum;
        lumpSumList.add(TestDataUtil.SalesLumpSumLineRecord);
        Test.stopTest();
    }
    
    private static testMethod void testMethodForApproval() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Contract createContractRecord = TestDataUtil.ContractRecord;
        Sales_Order__c createSalesOrderRecord = TestDataUtil.SalesOrderRecord;
        
        //update TestDataUtil.SalesOrderRecord;
        pref.getParameters().put('id', createSalesOrderRecord.Id);
        pref.getParameters().put('appliedToDocId', createSalesOrderRecord.Id);
        
        Test.startTest();
        ApexPages.StandardController StdCon = new ApexPages.StandardController(createSalesOrderRecord);
        SalesOrderController salesOrderRecord = new SalesOrderController(StdCon);
        salesOrderRecord.theSO.Contract__c= createContractRecord.Id;
        salesOrderRecord.theSO.Document_Type__c = 'Sales Quote';
        salesOrderRecord.validateAppliesToDoc();
        salesOrderRecord.saveAndSubmit();
        Test.stopTest();
        
    }
    
    private static testMethod void testMethodForApproval1() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Contract createContractRecord = TestDataUtil.ContractRecord;
        Sales_Order__c createSalesOrderRecord = TestDataUtil.SalesOrderRecord;
        
        //update TestDataUtil.SalesOrderRecord;
        pref.getParameters().put('id', createSalesOrderRecord.Id);
        
        Test.startTest();
        ApexPages.StandardController StdCon = new ApexPages.StandardController(createSalesOrderRecord);
        SalesOrderController salesOrderRecord = new SalesOrderController(StdCon);
        salesOrderRecord.theSO.Approval_Status__c= 'Draft';
        salesOrderRecord.theSO.Document_Type__c = 'Sales Quote';
        Boolean isAppor = salesOrderRecord.isApproved;
        salesOrderRecord.isNullUOMQty();
        salesOrderRecord.isSLQtyIsZero();
        Test.stopTest();
        
    }
    
    private static testMethod void testMethodForApproval3() {
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Contract createContractRecord = TestDataUtil.ContractRecord;   
        Contact createContactReecord = TestDataUtil.Contact2Record;
        createContactReecord.Blocked__c = True;
        Sales_Order__c createSalesOrderRecord = TestDataUtil.SalesOrderRecord;
        
        //update TestDataUtil.SalesOrderRecord;
        pref.getParameters().put('id', createSalesOrderRecord.Id);
        pref.getParameters().put('appliedToDocId', createSalesOrderRecord.Id);
        
        Test.startTest();
        ApexPages.StandardController StdCon = new ApexPages.StandardController(createSalesOrderRecord);
        SalesOrderController salesOrderRecord = new SalesOrderController(StdCon);
        salesOrderRecord.theSO.Contract__c= createContractRecord.Id;
        salesOrderRecord.theSO.Document_Type__c = 'Sales Quote';
        salesOrderRecord.theSO.Quote_Contact__c = createContactReecord.Id;
        salesOrderRecord.validateAppliesToDoc();
        salesOrderRecord.saveAndSubmit();
        
        //TMWrap test method
        Date testDate = Date.today();
        String testDescription = 'Test Description';
        String testSiteScope = 'Test Site Scope'; 
        
        SalesOrderController.TMWrap testTMWrap = new SalesOrderController.TMWrap(testDate,testDescription,testSiteScope);
        
        Test.stopTest();
        
    }
    
    private static testMethod void testGetterSetter(){
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        Sales_Order__c createSalesOrderRecord = TestDataUtil.SalesOrderRecord;
        //update TestDataUtil.SalesOrderRecord;
        pref.getParameters().put('id', createSalesOrderRecord.Id);
        
        Test.startTest();
        ApexPages.StandardController StdCon = new ApexPages.StandardController(createSalesOrderRecord);
        SalesOrderController salesOrderRecord = new SalesOrderController(StdCon);
        salesOrderRecord.endingDateValue = 'testDate';
        salesOrderRecord.includeWeekend = false;
        salesOrderRecord.selConvertTo = 'testConvert1';
        salesOrderRecord.maxTMCopiesPerDay = 1.0;
        salesOrderRecord.maxDaysToCreateTM = 14.0;
        salesOrderRecord.SLSubtotal = 13.0;
        salesOrderRecord.SLTaxTotal =7; 
        salesOrderRecord.SLTaxTotalWasteDisposal = 1.0;
        salesOrderRecord.SLSubtotalWasteDisposal = 0.0;
        salesOrderRecord.SLTotalCostSubcontractors = 0.0;
        salesOrderRecord.tmCount = 1;
        Test.stopTest();
    } 
    private static testMethod void Test_saveAndSubmit() {
		
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref); 
		CompanyMgmt.byPassTrigger = true;
        Contract ContractRecord = new Contract (
                Name = 'Test ContractRecord1',
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

    static testMethod void testGetCrMemoReasonCodeOptions(){
        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);

        pref.getParameters().put('id', TestDataUtil.SalesOrderRecord.Id);
        ApexPages.StandardController standardController = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);
        SalesOrderController salesOrderController = new SalesOrderController(standardController);
        List<SelectOption> options = salesOrderController.getCrMemoReasonCodeOptions();
        salesOrderController.creditMemoNote = 'Note';
    }
    private static testMethod void Test_SalesOrderController10() {

        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        CompanyMgmt.byPassTrigger = true;

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

        private static testMethod void Test_SalesOrderController11() {

        PageReference pref = Page.SalesOrder;
        Test.setCurrentPage(pref);
        CompanyMgmt.byPassTrigger = true;

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
        inst_SOC.SLSubtotalLabor = 9.0;
        inst_SOC.SLTaxTotalLabor = 9.0;
        inst_SOC.SLSubtotalEquipment = 9.0;
        inst_SOC.SLTaxTotalEquipment = 9.0;
            
            inst_SOC.SLSubtotalMaterials = 9.0;
            inst_SOC.SLTaxTotalMaterials = 9.0;
            
            inst_SOC.SLSubtotalSubcontractors = 9.0;
            inst_SOC.SLTaxTotalSubcontractors = 9.0;
            inst_SOC.SLTotalSubcontractors = 9.0;
            inst_SOC.SLProfitMarginSubcontractors = 9.0;
            inst_SOC.SLSubtotalLumpSum = 9.0;
            inst_SOC.SLTaxTotalLumpSum = 9.0;
            inst_SOC.SLSubtotalMisc = 9.0;
            inst_SOC.SLTaxTotalMisc = 9.0;
            inst_SOC.SLSubtotalDemurrage = 9.0;
            inst_SOC.SLTaxTotalDemurrage = 9.0;
            inst_SOC.SLTotalDemurrage = 9.0;
            inst_SOC.SurchargeAmount = 9.0;
            inst_SOC.theTMList = new List<TM__c>{new TM__c()};
                inst_SOC.theAllTMLList =new List<TM_Line__c>{new TM_Line__c()};
inst_SOC.validateBillToCustomer();
    inst_SOC.validateQuoteDate();
    inst_SOC.validateSurchargeType();
    inst_SOC.validateServiceCenter();
    inst_SOC.addDemurrageSurchargeLine('Test');
            inst_SOC.updateDemurrageSurchargeLine();
            inst_SOC.validateContact();
            inst_SOC.validateEstimateJob();
            inst_SOC.removeDemurrageSurchargeLine(new List<Sales_Line__c>{new Sales_Line__c()});
    }
    //test123
}