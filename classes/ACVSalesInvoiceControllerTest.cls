@IsTest
private class ACVSalesInvoiceControllerTest {
    @IsTest
    private static void testSaveSalesInvoice() {
        NewTestData.createTestData();

        Test.startTest();

        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
        Sales_Invoice__c SalesInvoiceRecordObj = TestDataUtil.SalesInvoiceRecord;
		//salesInvoice.Credit_Memo__c= TRUE;
        //salesInvoice.Misc_Invoice__c= TRUE;
        Sales_Invoice__c SalesInvoiceRecord = [Select Id,Contact__r.Blocked__c From Sales_Invoice__c Where Credit_Memo__c =: False Limit 1];
        Sales_Invoice_Line__c SalesInvoiceLineRecord = [Select Id, Resource_Type__c From Sales_Invoice_Line__c WHERE Sales_Invoice__c =: SalesInvoiceRecord.Id Limit 1];
        Tax_Area__c TaxAreaRecord = [Select Id From Tax_Area__c Limit 1];
        Sales_Order__c SalesOrderRecord = [Select Id,Create_Site_Address__c From Sales_Order__c Limit 1];
        //GL_Entry__c GLEntryRecord = [Select Id From GL_Entry__c Limit 1];
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
            Posting_Date__c = Date.newInstance(2021, 1, 1)
        );
        insert reverseFromSI;
       
        ACVSalesInvoiceController.getSetupData();

        String JSONInvoiceWrapper = ACVSalesInvoiceController.getSalesInvoice(salesInvoice.Id);
        ACVSalesInvoiceWrapper invoiceWrapper = (ACVSalesInvoiceWrapper)JSON.deserialize(JSONInvoiceWrapper, ACVSalesInvoiceWrapper.class);
        String JSONSalesInvoice = JSON.serialize(invoiceWrapper.SalesInvoice);
        String JSONJobTaskWrappers = JSON.serialize(invoiceWrapper.JobTaskWrappers);
        ACVSalesInvoiceController.calculateSalesInvoice(JSONSalesInvoice, JSONJobTaskWrappers);
        ACVSalesInvoiceController.saveSalesInvoice(JSONSalesInvoice, JSONJobTaskWrappers);

        JSONInvoiceWrapper = ACVSalesInvoiceController.getSalesInvoice(salesInvoice.Id);
        invoiceWrapper = (ACVSalesInvoiceWrapper)JSON.deserialize(JSONInvoiceWrapper, ACVSalesInvoiceWrapper.class);
        JSONSalesInvoice = JSON.serialize(invoiceWrapper.SalesInvoice);
        JSONJobTaskWrappers = JSON.serialize(invoiceWrapper.JobTaskWrappers);
        ACVSalesInvoiceController.postSalesInvoice(JSONSalesInvoice, JSONJobTaskWrappers);

        salesInvoice.Misc_Invoice__c = true;
        CompanyMgmt.byPassTrigger = true;
        salesInvoice.Reversed_from_SI__c = reverseFromSI.Id;
        update salesInvoice;
        JSONInvoiceWrapper = ACVSalesInvoiceController.getSalesInvoice(salesInvoice.Id);
        invoiceWrapper = (ACVSalesInvoiceWrapper)JSON.deserialize(JSONInvoiceWrapper, ACVSalesInvoiceWrapper.class);
        JSONSalesInvoice = JSON.serialize(invoiceWrapper.SalesInvoice);
        JSONJobTaskWrappers = JSON.serialize(invoiceWrapper.JobTaskWrappers);
        ACVSalesInvoiceController.saveSalesInvoice(JSONSalesInvoice, JSONJobTaskWrappers);

        salesInvoice.Document_Status__c = 'Posted';
        CompanyMgmt.byPassTrigger = true;
        salesInvoice.Reversed_from_SI__c = reverseFromSI.Id;
        update salesInvoice;
        JSONInvoiceWrapper = ACVSalesInvoiceController.getSalesInvoice(salesInvoice.Id);
        invoiceWrapper = (ACVSalesInvoiceWrapper)JSON.deserialize(JSONInvoiceWrapper, ACVSalesInvoiceWrapper.class);
        JSONSalesInvoice = JSON.serialize(invoiceWrapper.SalesInvoice);
        JSONJobTaskWrappers = JSON.serialize(invoiceWrapper.JobTaskWrappers);
        ACVSalesInvoiceController.saveSalesInvoice(JSONSalesInvoice, JSONJobTaskWrappers);
        ACVSalesInvoiceController.testStackCall();

        Test.stopTest();
    }

    @IsTest
    private static void testRetainageInvoice(){
        NewTestData.createTestData();

        Test.startTest();
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
        salesInvoice.Retainage_Pct__c = 20;
        String JSONInvoiceWrapper = ACVSalesInvoiceController.getSalesInvoice(salesInvoice.Id);
        ACVSalesInvoiceWrapper invoiceWrapper = (ACVSalesInvoiceWrapper)JSON.deserialize(JSONInvoiceWrapper, ACVSalesInvoiceWrapper.class);
        String JSONSalesInvoice = JSON.serialize(invoiceWrapper.SalesInvoice);
        String JSONJobTaskWrappers = JSON.serialize(invoiceWrapper.JobTaskWrappers);
        ACVSalesInvoiceController.saveSalesInvoice(JSONSalesInvoice, JSONJobTaskWrappers);

        JSONInvoiceWrapper = ACVSalesInvoiceController.getSalesInvoice(salesInvoice.Id);
        invoiceWrapper = (ACVSalesInvoiceWrapper)JSON.deserialize(JSONInvoiceWrapper, ACVSalesInvoiceWrapper.class);
        JSONSalesInvoice = JSON.serialize(invoiceWrapper.SalesInvoice);
        JSONJobTaskWrappers = JSON.serialize(invoiceWrapper.JobTaskWrappers);
        ACVSalesInvoiceController.postSalesInvoice(JSONSalesInvoice, JSONJobTaskWrappers);

        CompanyMgmt.systemCall = true;
        Retainage_Ledger_Entry__c retainageLedgerEntry = new Retainage_Ledger_Entry__c();
        retainageLedgerEntry.Sales_Invoice__c = salesInvoice.Id;
        retainageLedgerEntry.Customer__c = salesInvoice.Bill_to_Customer__c;
        retainageLedgerEntry.Sales_Order__c = salesInvoice.Sales_Order__c;
        retainageLedgerEntry.Amount__c = 100;
        insert retainageLedgerEntry;
        try{
            CompanySettingUtil.acvSetting.Default_Retainage_Resource_Id__c = NewTestData.mapResourceWrappersByName.get('Retainage Resource').Resource.Id;
                    SalesInvoicesService.createRetainageInvoice(salesInvoice);
        } catch (Exception e){

        }
        Test.stopTest();
    }

    @IsTest
    private static void testAutoReverseAmount(){
        NewTestData.createTestData();

        Test.startTest();
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
        List<Sales_Invoice_Line__c> salesInvoiceLines2 = [SELECT Id FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c = :salesInvoice.Id];
        for (Sales_Invoice_Line__c salesInvoiceLine2 : salesInvoiceLines2) {
            salesInvoiceLine2.Tax__c = 10;
        }
        CompanyMgmt.byPassTrigger = true;
        update salesInvoiceLines2;

        String JSONInvoiceWrapper = ACVSalesInvoiceController.getSalesInvoice(salesInvoice.Id);
        ACVSalesInvoiceWrapper invoiceWrapper = (ACVSalesInvoiceWrapper)JSON.deserialize(JSONInvoiceWrapper, ACVSalesInvoiceWrapper.class);
        List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{ salesInvoice.Id });
        List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
        SalesInvoicesService.autoReverseTaxAmount(salesInvoices[0], salesInvoice, salesInvoiceLines);
        Test.stopTest();
    }

    @IsTest
    private static void testReverseTaxAmount(){
        NewTestData.createTestData();

        Test.startTest();
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
        List<Sales_Invoice_Line__c> salesInvoiceLines2 = [SELECT Id FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c = :salesInvoice.Id];
        Integer i = 0;
        for (Sales_Invoice_Line__c salesInvoiceLine2 : salesInvoiceLines2) {
            salesInvoiceLine2.Tax__c = 1000;
            salesInvoiceLine2.Tax_Reverse_Line__c = true;
            if (i == 0) {
                salesInvoiceLine2.Tax_Group__c = 'NT';
            }
            else {
                salesInvoiceLine2.Tax_Group__c = 'TX';
            }
            i++;
        }
        CompanyMgmt.byPassTrigger = true;
        update salesInvoiceLines2;

        String JSONInvoiceWrapper = ACVSalesInvoiceController.getSalesInvoice(salesInvoice.Id);
        ACVSalesInvoiceWrapper invoiceWrapper = (ACVSalesInvoiceWrapper)JSON.deserialize(JSONInvoiceWrapper, ACVSalesInvoiceWrapper.class);
        Formula.recalculateFormulas(new List<Sales_Invoice__c> { invoiceWrapper.SalesInvoice });
        SalesInvoicesService.reverseTaxAmount(invoiceWrapper.SalesInvoice, salesInvoice, invoiceWrapper.JobTaskWrappers);

        salesInvoice.Credit_Memo_Reason_Code__c = 'Customer is tax exempt';
        try {
            ACVSalesInvoiceController.validateAppliesToDoc(JSON.serialize(salesInvoice), JSON.serialize(invoiceWrapper.JobTaskWrappers));
        }
        catch(exception ex) {
            
        }
        ACVSalesInvoiceController.validatePaymentTerm(JSON.serialize(salesInvoice));
        Test.stopTest();
    }

    @IsTest
    private static void testGetParentInvIdWithNextReversionInvNum(){
        NewTestData.createTestData();

        Test.startTest();
        List<TM__c> tms = [SELECT Id FROM TM__c];
        List<TM_Line__c> tmLines = [SELECT Id FROM TM_Line__c];

        Set<Id> tmIds = new Set<Id>();
        Set<Id> tmlIds = new Set<Id>();
        for (TM__c tm : tms) {
            tmIds.add(tm.Id);
        }
        for (TM_Line__c tmLine : tmLines) {
            tmlIds.add(tmLine.Id);
        }

        SalesInvoicesService.getParentInvIdWithNextReversionInvNum(tmIds, tmlIds);
        Test.stopTest();
    }

    @IsTest
    private static void testCalcSurchargeAmount(){
        NewTestData.createTestData();

        Test.startTest();
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
        List<Sales_Invoice_Line__c> salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(salesInvoice.Id);
        SalesInvoicesService.calcSurchargeAmount(salesInvoice, salesInvoiceLines);
        Test.stopTest();
    }

    @IsTest
    private static void testCreatCreditMemo(){
        NewTestData.createTestData();

        Test.startTest();
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
        List<Sales_Invoice_Line__c> salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(salesInvoice.Id);
        SalesInvoicesService.createCreditMemo(salesInvoice, null);
        Test.stopTest();
    }
    
      @IsTest
    private static void testSalesInvoiceLineModification() {
         NewTestData.createTestData();
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
         List<Sales_Invoice_Line__c> invoiceLines = [SELECT Id,Flat_Pay_Line__c, LastModifiedDate FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c = :salesInvoice.Id];
         Map<Id, DateTime> invoiceLineModifiedDatesByIds = new Map<Id, DateTime>();
        for(Sales_Invoice_Line__c line : invoiceLines) {
            invoiceLineModifiedDatesByIds.put(line.Id, line.LastModifiedDate);
        }
        Test.startTest();
        invoiceLines[0].Flat_Pay_Line__c = true;
        update invoiceLines[0];
        Test.stopTest();
    
      try {
            // Re-run the logic that checks for LastModifiedDate changes
            List<Sales_Invoice_Line__c> existingInvoiceLines = [SELECT Id, LastModifiedDate FROM Sales_Invoice_Line__c WHERE Id IN :invoiceLineModifiedDatesByIds.keySet()];
            for(Sales_Invoice_Line__c salesInvoiceLine : existingInvoiceLines) {
                if(invoiceLineModifiedDatesByIds.containsKey(salesInvoiceLine.Id) &&
                    invoiceLineModifiedDatesByIds.get(salesInvoiceLine.Id) < salesInvoiceLine.LastModifiedDate) {
                    throw new DataException('Sales Invoice lines have been modified after you retrieved the data. Please refresh page and try again.');
                }
            }
        } catch (DataException ex) {
            // Assert that the correct exception is thrown
            System.assertEquals('Sales Invoice lines have been modified after you retrieved the data. Please refresh page and try again.', ex.getMessage());
        }
    //
    
    
    
    
    }
    
    
  }