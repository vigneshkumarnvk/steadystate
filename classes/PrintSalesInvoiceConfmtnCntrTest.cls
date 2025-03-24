@IsTest
public class PrintSalesInvoiceConfmtnCntrTest {
	
    @testSetup static void setup(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord; //needed for numbering series data

        Service_Center__c serviceCenter = TestDataUtil.ServiceCenterRecord;
        User testUser = TestDataUtil.UserRecord;
    }
    @IsTest
    static void testPrintNewSalesInvoice(){
        CompanyMgmt.byPassTrigger = true;
        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Order';
        salesOrder.Site_Name__c = 'MDN Test';
        salesOrder.Create_Site_Address__c = true;
        salesOrder.Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.subsidiarycompanyRecord.id;
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
        salesInvoice.Document_Status__c = 'Posted';
        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        salesInvoice.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
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
        salesInvoiceLine.TM_Line__c = TestDataUtil.TMLineLaborRecord.id;
        salesInvoiceLine.TM__c = TestDataUtil.TMRecord.id;
        insert salesInvoiceLine;
        Sales_Invoice_Job_Task__c JobTask = new Sales_Invoice_Job_Task__c();
        JobTask.Print_Order__c = 1.0;
        JobTask.Sales_Invoice__c= salesInvoice.id;
        insert JobTask;
        
        PageReference pref = Page.SalesInvoice;
        Test.setCurrentPage(pref);
        Test.startTest();
        //PrintSalesInvoiceConfirmationController printObj = new PrintSalesInvoiceConfirmationController();
        //printObj.PrintNewSalesInvoice();
        Sales_Invoice__c SalesInvoiceRecord = [SELECT Id FROM Sales_Invoice__c LIMIT 1];
        
        pref.getParameters().put('id', SalesInvoiceRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(SalesInvoiceRecord);
        PrintSalesInvoiceConfirmationController printController = new PrintSalesInvoiceConfirmationController(StdCon);
        printController.PrintNewSalesInvoice();
        String tile = printController.title;
        Test.stopTest();

    }
}