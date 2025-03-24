@isTest
public class VoidSalesInvoiceControllerTest {

    @testSetup
    static void setupTestData() {
       //Setup Data
        CompanyMgmt.byPassTrigger = true;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        Sales_Invoice__c SalesInvoiceRecord = TestDataUtil.SalesInvoiceRecord;
        Retainage_Ledger_Entry__c retainageLedgerEntryRecord = new Retainage_Ledger_Entry__c(Sales_Invoice__c = SalesInvoiceRecord.Id);
        List<Sales_Invoice_Line__c> testSalesInvoiceLineRecords = TestDataUtil.SalesInvoiceLineRecords;
        Sales_Order__c SalesOrderRecord = TestDataUtil.SalesOrderRecord;
        Sales_Order_Job_Task__c salesOrderJobTaskRecord = new Sales_Order_Job_Task__c(Sales_Order__c = SalesOrderRecord.ID,Task_No__c = 1,Billing_Type__c = 'T&M');
        insert salesOrderJobTaskRecord;
        Billing_Worksheet_Line__c worksheetline = new Billing_Worksheet_Line__c (Sales_Order__c = SalesOrderRecord.Id, Line_No__c = 1,Sales_Order_Job_Task__c=salesOrderJobTaskRecord.Id);
        insert worksheetline;
        testSalesInvoiceLineRecords[0].Billing_Worksheet_Line__c = worksheetline.Id;
        TM__c TMrec = TestDataUtil.TMRecord;
        TMrec.Status__c = 'Closed';
        update TMrec;
    }

    @isTest
    static void testVoidSalesInvoice() {
        // Fetch the sales invoice for testing
        Sales_Invoice__c salesInvoice = [SELECT Id, Name, Document_Status__c FROM Sales_Invoice__c LIMIT 1];
        CompanyMgmt.systemCall = true;
        Retainage_Ledger_Entry__c rleRecord = new Retainage_Ledger_Entry__c(Closed_By_Invoice_No__c = salesInvoice.Id,Closed_By_Invoice_Reversed_By__c=salesInvoice.ID);
        insert rleRecord;

        // Instantiate the controller with the test sales invoice
        ApexPages.StandardController stdController = new ApexPages.StandardController(salesInvoice);
        VoidSalesInvoiceController controller = new VoidSalesInvoiceController(stdController);

        // Test the initial state of the controller properties
        System.assertEquals('Open', controller.salesInvoice.Document_Status__c, 'Initial Document Status should be Open');
        System.assertEquals('Billing Package', controller.docType, 'DocType should be Billing Package');
        System.assertEquals(false, controller.posted, 'The posted property should return false');

        // Execute the voidSalesInvoice method
        Test.startTest();
        CompanyMgmt.systemCall = true;
        PageReference result = controller.voidSalesInvoice();
        Test.stopTest();

        Sales_Invoice__c updatedInvoice = [SELECT Document_Status__c, Name FROM Sales_Invoice__c WHERE Id = :salesInvoice.Id];
        List<TM_Line__c> tmLines = [SELECT Invoiced__c FROM TM_Line__c];
        for (TM_Line__c line : tmLines) {
            System.assertEquals(false, line.Invoiced__c, 'TM Line should no longer be marked as invoiced');
        }

        // Verify that an informational message was added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(3, messages.size(), '3 success messages should be present');
    }

    @isTest
    static void testVoidSalesInvoiceWithInvalidStatus() {
        // Create a sales invoice with a non-Open status
        Sales_Invoice__c salesInvoice = [SELECT ID FROM Sales_Invoice__c limit 1];
        salesInvoice.Document_Status__c = 'Posted';
        update salesInvoice;
        CompanyMgmt.systemCall = true;
        Retainage_Ledger_Entry__c rleRecord = new Retainage_Ledger_Entry__c(Closed_By_Invoice_No__c = salesInvoice.Id,Closed_By_Invoice_Reversed_By__c=salesInvoice.ID);
        insert rleRecord;

        // Instantiate the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(salesInvoice);
        VoidSalesInvoiceController controller = new VoidSalesInvoiceController(stdController);

        // Attempt to void the invoice
        Test.startTest();
        PageReference result = controller.voidSalesInvoice();
        Test.stopTest();

        // Verify that the invoice status did not change
        Sales_Invoice__c updatedInvoice = [SELECT Document_Status__c FROM Sales_Invoice__c WHERE Id = :salesInvoice.Id];
        System.assertEquals('Posted', updatedInvoice.Document_Status__c, 'The invoice status should remain Posted');

        // Verify that an error message was added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'One error message should be present');
        System.assert(messages[0].getSummary().contains('System can only void Open Billing Packages'), 'The error message should indicate invalid status');
    }
    @isTest
    static void testVoidCreditMemoWithReversedSI() {
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Contact__r.Blocked__c From Sales_Invoice__c Where Credit_Memo__c =: False Limit 1];
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id, Resource_Type__c From Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SalesInvoiceRecord.Id Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        Account AccountRecord = [Select Id From Account Limit 1];
        Salesperson__c SalespersonRecord = [Select Id From Salesperson__c Limit 1];
        Subsidiary_Company__c SubsidiaryCompanyRecord = [Select Id From Subsidiary_Company__c Limit 1];
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
        Payment_Term__c PaymentTermRecord = [Select Id From Payment_Term__c Limit 1];
        SalesInvoiceRecord.Posting_Date__c = Date.newInstance(2020, 1, 1);
        SalesInvoiceRecord.Tax_Area__c = TaxAreaRecord.id;
        Sales_Invoice__c reverseFromSI = new Sales_Invoice__c(
            Bill_to_Customer__c = AccountRecord.Id,
            Salesperson__c = SalespersonRecord.Id,
            Account_Executive__c = SalespersonRecord.Id,
            Subsidiary_Company__c = SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TaxAreaRecord.Id,
            Service_Center__c = ServiceCenterRecord.Id,
            Document_Status__c = 'Open',
            Sales_Order__c = SalesOrderRecord.Id,
            Payment_Term__c = PaymentTermRecord.Id,
            Posting_Date__c = Date.newInstance(2021, 1, 1),
            Retainage_Invoice__c = true
        );
        insert reverseFromSI;
        SalesInvoiceRecord.Reversed_from_SI__c = reverseFromSI.Id;
        SalesInvoiceRecord.Credit_Memo__c = TRUE;
        update SalesInvoiceRecord;
		
        CompanyMgmt.systemCall = true;
        Retainage_Ledger_Entry__c rleRecord = new Retainage_Ledger_Entry__c(Closed_By_Invoice_Reversed_By__c=SalesInvoiceRecord.ID);
        insert rleRecord;
        // Instantiate the controller
        ApexPages.StandardController stdController = new ApexPages.StandardController(SalesInvoiceRecord);
        VoidSalesInvoiceController controller = new VoidSalesInvoiceController(stdController);
		
        controller.getMessages();
        // Attempt to void the invoice
        Test.startTest();
        PageReference result = controller.voidSalesInvoice();
        Test.stopTest();

        // Verify that an error message was added
        List<ApexPages.Message> messages = ApexPages.getMessages();
        System.assertEquals(1, messages.size(), 'One error message should be present');
    }
}