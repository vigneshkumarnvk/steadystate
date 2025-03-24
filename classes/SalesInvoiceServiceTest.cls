@IsTest
private class SalesInvoiceServiceTest {
    @IsTest
    private static void testSalesInvoiceService(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;  //needed for numbering series data. 
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
        salesOrder.EqaiGeneratorId__c = 343003;
        insert salesOrder;
        Service_Center__c sc = new Service_Center__c();
        sc.id = TestDataUtil.ServiceCenterRecord.Id;
        sc.Name = '64';
        sc.Include_SO_in_EQAI_Invoice_Integration__c = True;
        update sc;
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c();
        salesInvoice.Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id;
        salesInvoice.Salesperson__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Account_Executive__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesInvoice.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        salesInvoice.Service_Center__c = sc.Id;
        salesInvoice.Document_Status__c = 'Open';
        salesInvoice.Approval_Status__c = 'Approved';
        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        salesInvoice.OwnerId = UserInfo.getUserId();
        salesInvoice.Contract__c = TestDataUtil.ContractRecord.Id;
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
        Test.setMock(HttpCalloutMock.class, new workOrderQuoteServiceMockHttpGenerator());
        Sales_Invoice__c creditMemo = SalesInvoicesService.createCreditMemo(salesInvoice, creditMemoWorkSheet.Id);
        SendEQAIBillingPackageCtrl.sendSalesInvoiceToEQAI(salesInvoice.id);
        SendEQAIBillingPackageCtrl.getSalesInvoice(salesInvoice.id);

        SalesInvoiceWorkOrderService.workOrderDetailInfo(salesInvoice.id,73,93,'123');
        salesInvoice.Document_Status__c = 'Sent to EQAI';
        update salesInvoice; 
        SendEQAIBillingPackageCtrl.sendSalesInvoiceToEQAI(salesInvoice.id);
        Map<Id, String> parentInvWithNextRevNumber = SalesInvoicesService.getParentInvIdWithNextReversionInvNum(new Set<Id>{TestDataUtil.TMRecord.Id}, new Set<Id>{TestDataUtil.TMLineLaborRecord.Id});
        Test.stopTest();
        //test 
    }
    
    @IsTest
    private static void testSalesLinesService(){
        NewTestData.createTestData();
        Test.startTest();
        Id salesInvoiceId = NewTestData.mapSalesInvoicesByName.get('INVOICE01').Id;
        List<Sales_Invoice_Job_Task__c> salesInvoiceJobTasks = SalesInvoiceJobTasksSelector.newInstance().selectBySalesInvoiceId(new Set<Id>{salesInvoiceId});
        List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectById(new Set<Id>{salesInvoiceId});
        List<Sales_Invoice_Line__c> salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(salesInvoiceId);
        SalesInvoiceLinesService.initStaticVariables(salesInvoices[0], salesInvoiceJobTasks[0], salesInvoiceLines[0]);
        
        ACVSalesInvoiceJobTaskWrapper jobTaskWrapper = new ACVSalesInvoiceJobTaskWrapper();
        jobTaskWrapper.JobTask = salesInvoiceJobTasks[0];
        jobTaskWrapper.SalesInvoiceLines = salesInvoiceLines;
        
        List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers = new List<ACVSalesInvoiceJobTaskWrapper>();
        jobTaskWrappers.add(jobTaskWrapper);
        SalesInvoiceLinesService.initStaticVariables(salesInvoices[0], jobTaskWrappers);
        
        for(Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
            SalesInvoiceLinesService.validateResourceType(salesInvoices[0], salesInvoiceLine);
            SalesInvoiceLinesService.validateResource(salesInvoices[0], salesInvoiceLine);
            SalesInvoiceLinesService.calculatePriceAndCost(salesInvoices[0], salesInvoiceLine);
            SalesInvoiceLinesService.assignTaxPercent(salesInvoices[0], salesInvoiceLine);
        }
        SalesInvoiceLinesService.calculateLineTotals(salesInvoices[0], jobTaskWrappers);
        SendEQAIBillingPackageCtrl.sendSalesInvoiceToEQAI(salesInvoices[0].id);
        SalesInvoiceWorkOrderService.workOrderHeaderInfo(salesInvoices[0].id);
        Test.stopTest();
    }
    @IsTest
    private static void testSalesLinesServiceException(){
        Test.startTest();
        SendEQAIBillingPackageCtrl.splitSuccessMessage('Error: Integration failed due to the following reason;Project code:MD109395 already exists in workorderquoteheader table;');
        Test.stopTest();
        //System.assertEquals(true,errorlogs.size()>0);
    }
    
    @IsTest
    private static void testSalesInvoiceService1(){
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
        salesOrder.EqaiGeneratorId__c = 343003;
        salesOrder.Name = 'test A while back I needed to count the amount of';
        insert salesOrder;
        
        
        Service_Center__c sc = new Service_Center__c();
        sc.id = TestDataUtil.ServiceCenterRecord.Id;
        sc.Name = '64';
        sc.Include_SO_in_EQAI_Invoice_Integration__c = True;
        sc.Advanced_Disposal__c = true;
        update sc;
        
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c();
        salesInvoice.Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id;
        salesInvoice.Salesperson__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Account_Executive__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesInvoice.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        salesInvoice.Service_Center__c = sc.Id;
        salesInvoice.Document_Status__c = 'Open';
        salesInvoice.Approval_Status__c = 'Approved';
        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        salesInvoice.OwnerId = UserInfo.getUserId();
        salesInvoice.Contract__c = TestDataUtil.ContractRecord.Id;
        insert salesInvoice;
        //test
        // Test.startTest();
        // Test.setMock(HttpCalloutMock.class, new MockHttpBillingJobResponseGenerator());
        // SendEQAIBillingPackageCtrl.updateDocumentTypeID(salesInvoice.id,salesOrder.Id); 
        // salesInvoice.Document_Status__c = 'Sent to EQAI';
        // update salesInvoice; 
        // Test.stopTest();
    }
    
    @IsTest
    private static void testSalesInvoiceService12(){
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
        salesOrder.EqaiGeneratorId__c = 343003;
        salesOrder.Site_Address_Changed__c = true;
        insert salesOrder;
        
        
        Service_Center__c sc = new Service_Center__c();
        sc.id = TestDataUtil.ServiceCenterRecord.Id;
        sc.Name = '64';
        sc.Include_SO_in_EQAI_Invoice_Integration__c = True;
        update sc;
        
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c();
        salesInvoice.Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id;
        salesInvoice.Salesperson__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Account_Executive__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesInvoice.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        salesInvoice.Service_Center__c = sc.Id;
        salesInvoice.Document_Status__c = 'Open';
        salesInvoice.Approval_Status__c = 'Approved';
        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        salesInvoice.OwnerId = UserInfo.getUserId();
        salesInvoice.Contract__c = TestDataUtil.ContractRecord.Id;
        insert salesInvoice;
        
        Test.startTest();
        SendEQAIBillingPackageCtrl.updateStatusInSalesOrder(salesInvoice.id); 
        Test.stopTest();
    }
    @IsTest
    private static void testSalesLinesService2(){
 
        //update salesInvoice.
        Test.startTest();
        try{
            SendEQAIBillingPackageCtrl.sendSalesInvoiceToEQAI('a1UW40000001SjpMAE');
            
        }catch(Exception e){
            
        }
        Test.stopTest();
    }
    
    
    @isTest
    private static void testSalesInvoiceService3() {
        // Setup data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        CompanyMgmt.byPassTrigger = true;
        Sales_Order__c salesOrder = new Sales_Order__c(
            Surcharge_Type__c = 'N/A',
            Document_Type__c = 'Sales Order',
            Site_Name__c = 'MDN Test',
            Create_Site_Address__c = true,
            Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Total_Margin_Pct__c = 10,
            Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name(),
            Approved__c = true,
            Approved_Profit_Margin__c = 40,
            Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25),
            OwnerId = UserInfo.getUserId(),
            EqaiGeneratorId__c = 343003,
            D365_Project_ID__c ='232323',
            Disposal_Billing_Method__c ='Direct'
            
        );
        insert salesOrder;
        Service_Center__c sc = new Service_Center__c(
            id = TestDataUtil.ServiceCenterRecord.Id,
            Name = '64',
            Include_SO_in_EQAI_Invoice_Integration__c = True
        );
        update sc;
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c(
            Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id,
            Salesperson__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Service_Center__c = sc.Id,
            Document_Status__c = 'Open',
            Approval_Status__c = 'Approved',
            Sales_Order__c = salesOrder.Id,
            Payment_Term__c = TestDataUtil.PaymentTermRecord.Id,
            OwnerId = UserInfo.getUserId(),
            Contract__c = TestDataUtil.ContractRecord.Id
        );
        insert salesInvoice;
        
        Sales_Invoice_Line__c salesInvoiceLineRecord = new Sales_Invoice_Line__c(
            Sales_Invoice__c = salesInvoice.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Waste Disposal',
            Description__c = '100 characters is between 14 words and 25 words with spaces included in the character count.If spac',
            Line_No__c = 5,
            Quantity__c = -5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineWasteDisposalRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        insert salesInvoiceLineRecord;
        
        Test.startTest();
        Boolean wasteDisposal = SalesInvoiceWorkOrderService.containsWasteDisposalInvoiceLine(salesInvoice.id);
       	Boolean isWasteDisposal = SendEQAIBillingPackageCtrl.containsWasteDisposalInvoiceLine(salesInvoice.id);
        Test.setMock(HttpCalloutMock.class, new MockHttpBillingJobResponseGenerator());
        SendEQAIBillingPackageCtrl.sendSalesInvoiceToEQAI(salesInvoice.id);
        salesInvoice.Document_Status__c = 'Sent to EQAI';
        update salesInvoice;
        SalesInvoiceWorkOrderService.createCaseWithParentId(salesInvoice.Id,'Error','check','Request');
        Test.stopTest();
    }
    //test
    @isTest
    static void testSendSalesInvoiceToEQAIWithValidationError() {
        // Setup test data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        CompanyMgmt.byPassTrigger = true;
        Sales_Order__c salesOrder = new Sales_Order__c(
            Surcharge_Type__c = 'N/A',
            Document_Type__c = 'Sales Order',
            Site_Name__c = 'MDN Test',
            Create_Site_Address__c = true,
            Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Total_Margin_Pct__c = 10,
            Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name(),
            Approved__c = true,
            Approved_Profit_Margin__c = 40,
            Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25),
            OwnerId = UserInfo.getUserId(),
            EqaiGeneratorId__c = 343003,
            D365_Project_ID__c ='232323',
            Disposal_Billing_Method__c ='Direct'
        );
        insert salesOrder;
        Service_Center__c sc = new Service_Center__c(
            id = TestDataUtil.ServiceCenterRecord.Id,
            Name = '64',
            Include_SO_in_EQAI_Invoice_Integration__c = True
            );
        update sc;
        
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c(
            Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id,
            Salesperson__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Service_Center__c = sc.Id,
            Document_Status__c = 'Open',
            Approval_Status__c = 'Approved',
            Sales_Order__c = salesOrder.Id,
            Payment_Term__c = TestDataUtil.PaymentTermRecord.Id,
            OwnerId = UserInfo.getUserId(),
            Contract__c = TestDataUtil.ContractRecord.Id
        );
        insert salesInvoice;
        TM_Line__c testTMLine = TestDataUtil.TMLineWasteDisposalRecord;
        TM__c testTM = TestDataUtil.TMRecord;
        Test.startTest();
        try {
            SendEQAIBillingPackageCtrl.updateDocumentTypeID(salesInvoice.Id, null); 
            System.assert(false, 'Expected an AuraHandledException to be thrown');
        } catch (AuraHandledException ex) {
            System.assert(ex.getMessage().contains('Script-thrown exception'), 
                          'Expected exception message for failed update not found: ' + ex.getMessage());
        } catch (Exception e) {
            System.assert(false, 'Unexpected exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    @isTest
    private static void testSalesInvoiceService4() {
        // Setup data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        CompanyMgmt.byPassTrigger = true;
        Sales_Order__c salesOrder = new Sales_Order__c(
            Surcharge_Type__c = 'N/A',
            Document_Type__c = 'Sales Order',
            Site_Name__c = 'MDN Test',
            Create_Site_Address__c = true,
            Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Total_Margin_Pct__c = 10,
            Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name(),
            Approved__c = true,
            Approved_Profit_Margin__c = 40,
            Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25),
            OwnerId = UserInfo.getUserId(),
            EqaiGeneratorId__c = 343003,
            D365_Project_ID__c ='232323',
            Disposal_Billing_Method__c ='InDirect'
        );
        insert salesOrder;
        Service_Center__c sc = new Service_Center__c(
            id = TestDataUtil.ServiceCenterRecord.Id,
            Name = '64',
            Include_SO_in_EQAI_Invoice_Integration__c = True,
            Advanced_Disposal__c = True
        );
        update sc;
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c(
            Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id,
            Salesperson__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Service_Center__c = sc.Id,
            Document_Status__c = 'Open',
            Approval_Status__c = 'Approved',
            Sales_Order__c = salesOrder.Id,
            Payment_Term__c = TestDataUtil.PaymentTermRecord.Id,
            OwnerId = UserInfo.getUserId(),
            Contract__c = TestDataUtil.ContractRecord.Id
        );
        insert salesInvoice;
        
        Sales_Invoice_Line__c salesInvoiceLineRecord = new Sales_Invoice_Line__c(
            Sales_Invoice__c = salesInvoice.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Waste Disposal',
            Description__c = 'Manifest Fee',
            Line_No__c = 5,
            Quantity__c = -5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineWasteDisposalRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        insert salesInvoiceLineRecord;
        Test.startTest();
        Boolean wasteDisposal = SalesInvoiceWorkOrderService.containsWasteDisposalInvoiceLine(salesInvoice.id);
        Test.setMock(HttpCalloutMock.class, new MockHttpBillingJobResponseGenerator());
        SendEQAIBillingPackageCtrl.sendSalesInvoiceToEQAI(salesInvoice.id);
        salesInvoice.Document_Status__c = 'Sent to EQAI';
        update salesInvoice;
        SalesInvoiceWorkOrderService.createCaseWithParentId(salesInvoice.Id,'Error','check','Request');
        Test.stopTest();
    }
     @isTest
    private static void testSingleJSON() {
        // Setup data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        CompanyMgmt.byPassTrigger = true;
        Sales_Order__c salesOrder = new Sales_Order__c(
            Surcharge_Type__c = 'N/A',
            Document_Type__c = 'Sales Order',
            Site_Name__c = 'MDN Test',
            Create_Site_Address__c = true,
            Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Total_Margin_Pct__c = 10,
            Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name(),
            Approved__c = true,
            Approved_Profit_Margin__c = 40,
            Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25),
            OwnerId = UserInfo.getUserId(),
            EqaiGeneratorId__c = 343003,
            D365_Project_ID__c ='232323',
            Disposal_Billing_Method__c ='Direct'
        );
        insert salesOrder;
        Service_Center__c sc = new Service_Center__c(
            id = TestDataUtil.ServiceCenterRecord.Id,
            Name = '64',
            Include_SO_in_EQAI_Invoice_Integration__c = True,
            Advanced_Disposal__c = True
        );
        update sc;
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c(
            Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id,
            Salesperson__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Service_Center__c = sc.Id,
            Document_Status__c = 'Open',
            Approval_Status__c = 'Approved',
            Sales_Order__c = salesOrder.Id,
            Payment_Term__c = TestDataUtil.PaymentTermRecord.Id,
            OwnerId = UserInfo.getUserId(),
            Contract__c = TestDataUtil.ContractRecord.Id
        );
        insert salesInvoice;
        
        Sales_Invoice_Line__c salesInvoiceLineRecord = new Sales_Invoice_Line__c(
            Sales_Invoice__c = salesInvoice.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Waste Disposal',
            Description__c = '100 character is between 14 words and 25 words with spaces included in the character count. If spac',
            Line_No__c = 5,
            Quantity__c = -5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineWasteDisposalRecord.id,
            TM__c = TestDataUtil.TMRecord.id,
            BOL_Manifest__c = 'AB123456789'
        );
        insert salesInvoiceLineRecord;
        
        Test.startTest();
        Boolean wasteDisposal = SalesInvoiceWorkOrderService.containsWasteDisposalInvoiceLine(salesInvoice.id);
       	
        Test.setMock(HttpCalloutMock.class, new BillingPkgSingleJSONMockResponse());
        SendEQAIBillingPackageCtrl.sendSalesInvoiceToEQAI(salesInvoice.id);
        salesInvoice.Document_Status__c = 'Sent to EQAI';
        update salesInvoice;
        
        Test.stopTest();
    }
    @IsTest
    private static void testAccountService(){
        Account customerAccount = TestDataUtil.customerAccountRecord;
        customerAccount.PO_Number_Type__c = AccountsService.PO_FORMAT_ALPHANUMERICAL;
        customerAccount.Invoice_Backup_Documents__c = AccountsService.INVOICE_BACKUP_TYPE_INVOICE;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_AP;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_EXECUTIVE;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_PURCHASE;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_QUOTE;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_SALES;
        customerAccount.Invoice_Email_Contact_Types__c = AccountsService.INVOICE_EMAIL_CONTACT_TYPE_SITE;
        customerAccount.Invoice_Submission_Channels__c = AccountsService.INVOICE_SUBMISSION_CHANNEL_EMAIL;
        update customerAccount;

        String poNumber = 'ABC1234';
        try{
            SendEQAIBillingPackageCtrl.validatePONumber(customerAccount.id, poNumber);
        } catch (Exception e){

        }
    }
    @IsTest
    private static void testSalesInvoiceServiceWD(){
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
        salesOrder.EqaiGeneratorId__c = 343003;
        salesOrder.Site_Address_Changed__c = true;
        insert salesOrder;
        
        
        Service_Center__c sc = new Service_Center__c();
        sc.id = TestDataUtil.ServiceCenterRecord.Id;
        sc.Name = '64';
        sc.Include_SO_in_EQAI_Invoice_Integration__c = True;
        sc.Advanced_Disposal__c = True;
        update sc;
        
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c();
        salesInvoice.Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id;
        salesInvoice.Salesperson__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Account_Executive__c = TestDataUtil.SalespersonRecord.Id;
        salesInvoice.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesInvoice.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        salesInvoice.Service_Center__c = sc.Id;
        salesInvoice.Document_Status__c = 'Open';
        salesInvoice.Approval_Status__c = 'Approved';
        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Payment_Term__c = TestDataUtil.PaymentTermRecord.Id;
        salesInvoice.OwnerId = UserInfo.getUserId();
        salesInvoice.Contract__c = TestDataUtil.ContractRecord.Id;
        insert salesInvoice;
        
        Sales_Invoice_Line__c salesInvoiceLineRecord = new Sales_Invoice_Line__c(
            Sales_Invoice__c = salesInvoice.Id,
            Resource__c = TestDataUtil.ResourceRecord.Id,
            Category__c = 'Waste Disposal',
            Description__c = '100 characters is between 14 words and 25 words with spaces included in the character count. If spac',
            Line_No__c = 5,
            Quantity__c = -5,
            Unit_Price__c = 2,
            Line_Amount__c = 0,
            Line_Amt_Incl_Tax__c = 0,
            Tax__c = 0,
            Tax_Group__c = 'NT',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            TM_Line__c = TestDataUtil.TMLineWasteDisposalRecord.id,
            TM__c = TestDataUtil.TMRecord.id
        );
        insert salesInvoiceLineRecord;
        
        Test.startTest();
        SendEQAIBillingPackageCtrl.updateStatusInSalesOrder(salesInvoice.id); 
        Test.stopTest();
    }
    //test
}