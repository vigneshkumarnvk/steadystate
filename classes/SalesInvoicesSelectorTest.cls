@IsTest
private class SalesInvoicesSelectorTest {

    @IsTest
    private static void test(){
        Company_Setup__c companySetup = new Company_Setup__c(
                Name = 'Default',
                Lines_to_Insert__c = 5,
                Allow_Posting_From__c = Date.newInstance(2015, 1, 1),
                Allow_Posting_To__c = Date.newInstance(2019, 1, 1)
        );
        insert companySetup;

        Numbering_Series__c theNS;
        List<Numbering_Series__c> theNSList = new List<Numbering_Series__c>();

        theNS = new Numbering_Series__c();
        theNS.Name = 'JOB01';
        theNS.Prefix__c = 'NJ';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);
        theNS = new Numbering_Series__c();

        theNS.Name = 'Sales Invoice';
        theNS.Prefix__c = 'SI';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);
        insert theNSList;

        Payment_Term__c pt = new Payment_Term__c(
                Name = '14 DAYS',
                Discount_Pct__c = 0,
                Discount_Date_Calculation__c = 0,
                Due_Date_Calculation__c = 0
        );
        insert pt;
        GL_Account__c glAccount = new GL_Account__c(
                Name = 'GLAccountRecordTest',
                Description__c = 'Test GL Account'
        );
        insert glAccount;
        Tax_Area__c ta = new Tax_Area__c(
                Name = 'NJ',
                Sales_Tax_Account__c = glAccount.Id
        );
        insert ta;
        Salesperson__c sp = new Salesperson__c(
                Name = 'London Postmaster',
                Account_Executive__c = true,
                First_Name__c = 'firstname',
                Last_Name__c = 'lastname',
                Status__c = 'Active',
                Salesperson_Code__c = '88766543fhjk',
                User__c = UserInfo.getUserId()
        );
        insert sp;
        Subsidiary_Company__c subC = new Subsidiary_Company__c(
                Name = '1-REPUBLIC SERVICES',
                Display_Name__c = 'SO'
        );
        insert subC;
        Account account = new Account();
        account.Name = 'Cannon Group';
        account.AccountNumber = '01-00000001';
        account.Payment_Term__c = pt.Id;
        account.Tax_Area__c = ta.Id;
        account.BillingStreet = 'test Street';
        account.BillingCity = 'test City';
        account.BillingState = 'Colorado';
        account.BillingStateCode = 'CO';
        account.BillingCountryCode = 'US';
        account.BillingPostalCode = 'test postalcode';
        account.Customer_Type__c = 'UTILITIES';
        account.Account_Executive__c = sp.Id;
        account.Salesperson__c = sp.Id;
        account.Subsidiary_Company__c = subC.Id;
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert account;


        Service_Center__c sc = new Service_Center__c(
                Name = '01',
                Description__c = 'SC01 Elizabeth, NJ Ops',
                Subsidiary_Company__c = subC.Id,
                TM_No_Series__c = theNSList[0].Id,
                //Sales_Order_No_Series__c = theNumberingSeries.Id,
                //Sales_Order_No_Series__c = '',
                Max_No_of_Emergency_T_M__c = 2,
                Code__c = '01',
                City__c = 'Elizabeth',
                Street__c = '201 South First St.',
                Postal_Code__c = '07206',
                State__c = 'NJ',
                Country__c = 'US',
                Temporary__c = true

        );
        insert sc;

        Sales_Order_Type__c sot = new Sales_Order_Type__c(Description__c = 'test description');
        insert sot;
        Sales_Order__c theSO = new Sales_Order__c(
                Bill_to_Customer_No__c = account.Id,
                Payment_Term__c = pt.Id,
                Name = 'Test',
                Service_Center__c = sc.Id,
                Sales_Order_Type__c = sot.Id,
                Subsidiary_Company__c = subC.Id,
                Project_Coordinator__c = sp.Id,
                Surcharge_Type__c = 'N/A'
        );
        insert theSO;

        TM__c theTM = new TM__c(
                Bill_to_Customer__c = account.Id,
                Project_Coordinator__c = sp.Id,
                Account_Executive__c = sp.Id,
                Prevailing_Wage_Job__c = true,
                Certified_PW_Job__c = true,
                Service_Center__c = sc.Id,
                Subsidiary_Company__c = subC.Id,
                Tax_Area__c = ta.Id,
                Sales_Order__c = theSO.Id,
                Scheduled_Date__c = Date.today().addDays(-7),
                Status__c = 'Open'
        );
        insert theTM;
        Sales_Invoice__c theSI = new Sales_Invoice__c(
                Bill_to_Customer__c = account.Id,
                Salesperson__c = sp.Id,
                Account_Executive__c = sp.Id,
                Subsidiary_Company__c = subC.Id,
                Tax_Area__c = ta.Id,
                Service_Center__c = sc.Id,
                Document_Status__c = 'Open',
                Sales_Order__c = theSO.Id,
                Payment_Term__c = pt.Id
        );
        insert theSI;

        SalesInvoicesSelector selector = new SalesInvoicesSelector();
        selector.selectById(new Set<Id>{theSI.Id});
        selector.selectByIdWithSILines(new Set<Id>{theSI.Id});
        selector.selectPOBySalesOrderId(new Set<Id>{theSI.Id});
        selector.selectLineCountById(new Set<Id>{theSI.Id});
    }

    @IsTest
    private static void testSalseInvoiceSelector(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord; //needed for numbering series data
        CompanyMgmt.byPassTrigger = true;
        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Order';
        salesOrder.Site_Name__c = 'MDN Test';
        salesOrder.Create_Site_Address__c = true;
        salesOrder.Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.Id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.Id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesOrder.Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id;
        salesOrder.Total_Margin_Pct__c = 10;
        salesOrder.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        salesOrder.Approved__c = true;
        salesOrder.Approved_Profit_Margin__c = 40;
        salesOrder.Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25);
        salesOrder.OwnerId = UserInfo.getUserId();
        insert salesOrder;

        Sales_Invoice__c salesInvoice = new Sales_Invoice__c();
        salesInvoice.Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id;
        salesInvoice.Salesperson__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Account_Executive__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesInvoice.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        salesInvoice.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesInvoice.Document_Status__c = 'Open';
        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        salesInvoice.Approval_Status__c = EnumUtil.ApprovalStatus.DRAFT.name();
        salesInvoice.OwnerId = UserInfo.getUserId();
        insert salesInvoice;

        Sales_Invoice_Line__c salesInvoiceLine = new Sales_Invoice_Line__c();
        salesInvoiceLine.Sales_Invoice__c = salesInvoice.Id;
        salesInvoiceLine.Resource__c = TestDataUtil.ResourceRecord.Id;
        salesInvoiceLine.Category__c = 'Labor';
        salesInvoiceLine.Description__c = 'Test';
        salesInvoiceLine.Line_No__c = 1;
        salesInvoiceLine.Quantity__c = 1;
        salesInvoiceLine.Unit_Price__c = 100;
        salesInvoiceLine.Line_Amount__c = 100;
        salesInvoiceLine.Unit_Cost__c = 90;
        salesInvoiceLine.Line_Cost__c = 90;
        salesInvoiceLine.Line_Amt_Incl_Tax__c = 100;
        salesInvoiceLine.Tax__c = 0;
        salesInvoiceLine.Tax_Group__c = 'NT';
        salesInvoiceLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        salesInvoiceLine.TM_Line__c = TestDataUtil.TMLineLaborRecord.Id;
        salesInvoiceLine.TM__c = TestDataUtil.TMRecord.Id;
        insert salesInvoiceLine;

        Sales_Invoice__c creditMemoWorkSheet = new Sales_Invoice__c();
        creditMemoWorkSheet.Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id;
        creditMemoWorkSheet.Salesperson__c = TestDataUtil.SalespersonRecord.Id;
        creditMemoWorkSheet.Account_Executive__c = TestDataUtil.SalespersonRecord.Id;
        creditMemoWorkSheet.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        creditMemoWorkSheet.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        creditMemoWorkSheet.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        creditMemoWorkSheet.Document_Status__c = 'Open';
        creditMemoWorkSheet.Worksheet__c = true;
        creditMemoWorkSheet.Sales_Order__c = salesOrder.Id;
        creditMemoWorkSheet.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        creditMemoWorkSheet.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        creditMemoWorkSheet.OwnerId = UserInfo.getUserId();
        insert creditMemoWorkSheet;

        Sales_Invoice_Line__c workSheetLine = new Sales_Invoice_Line__c();
        workSheetLine.Sales_Invoice__c = creditMemoWorkSheet.Id;
        workSheetLine.Resource__c = TestDataUtil.ResourceRecord.Id;
        workSheetLine.Category__c = 'Labor';
        workSheetLine.Description__c = 'Test';
        workSheetLine.Line_No__c = 1;
        workSheetLine.Quantity__c = 1;
        workSheetLine.Unit_Price__c = 95;
        workSheetLine.Line_Amount__c = 95;
        workSheetLine.Unit_Cost__c = 90;
        workSheetLine.Line_Cost__c = 90;
        workSheetLine.Line_Amt_Incl_Tax__c = 95;
        workSheetLine.Tax__c = 0;
        workSheetLine.Tax_Group__c = 'NT';
        workSheetLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        workSheetLine.TM_Line__c = TestDataUtil.TMLineLaborRecord.Id;
        workSheetLine.TM__c = TestDataUtil.TMRecord.Id;
        insert workSheetLine;

        Test.startTest();
        List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{salesInvoice.Id});
        salesInvoices = SalesInvoicesSelector.newInstance().selectLineCountById(new Set<Id>{salesInvoice.Id});
        salesInvoices = SalesInvoicesSelector.newInstance().selectByIdWithSILinesForReverse(new Set<Id>{salesInvoice.Id});
        salesInvoices = SalesInvoicesSelector.newInstance().selectPOBySalesOrderId(new Set<Id>{salesOrder.Id});
        salesInvoices = SalesInvoicesSelector.newInstance().selectByIdWithLinesAndProcessSteps(new Set<Id>{salesInvoice.Id});
        List<Sales_Invoice__c> creditMemoWorkheets = SalesInvoicesSelector.newInstance().selectOpenCreditMemoWorksheetWithLines(creditMemoWorkSheet.Id);
        creditMemoWorkheets = SalesInvoicesSelector.newInstance().selectCreditMemoWorksheetsWithChangedLines(creditMemoWorkSheet.Id);

        List<Sales_Invoice_Line__c> salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByIds(new Set<Id>{salesInvoiceLine.Id});
        salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(salesInvoice.Id);
        salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectPostedInvoiceLinesByTMLineIds(new Set<Id>{TestDataUtil.TMLineLaborRecord.Id});
        salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectApprovedCreditMemoWorksheetByTMLineIds(new Set<Id>{TestDataUtil.TMLineLaborRecord.Id});

        Test.stopTest();

    }
}