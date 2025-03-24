@IsTest
private class InvoiceApprovalTest {
    @testSetup static void setup(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord; //needed for numbering series data

        Service_Center__c serviceCenter = TestDataUtil.ServiceCenterRecord;
        User testUser = TestDataUtil.UserRecord;

        List<Approval_Tree__c> approvalTrees = new List<Approval_Tree__c>();

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SI-01-1',
                Document_Type__c = 'Sales_Invoice',
                Level__c = 1,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 40,
                Approver__c = testUser.Id));

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SI-01-2',
                Document_Type__c = 'Sales_Invoice',
                Level__c = 2,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 30,
                Approver__c = UserInfo.getUserId()));

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SI-01-3',
                Document_Type__c = 'Sales_Invoice',
                Level__c = 3,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 15,
                Approver__c = testUser.Id));

        insert approvalTrees;
    }

    @IsTest
    static void testInvoiceApproval() {
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
        salesInvoiceLine.TM_Line__c = TestDataUtil.TMLineLaborRecord.id;
        salesInvoiceLine.TM__c = TestDataUtil.TMRecord.id;
        insert salesInvoiceLine;

        Test.startTest();
        SalesInvoicesService.submitForApproval(salesInvoice.Id, true);

        //approve an approval request
        List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstanceId
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :salesInvoice.Id
        ];
        List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
        for(ProcessInstanceWorkitem workItem : workItems){
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setWorkitemId(workItem.Id);
            //Valid values are: Approve, Reject, or Reassign.
            req.setAction('Approve');
            req.setComments('Approve');
            requests.add(req);
        }
        Approval.ProcessResult[] processResults = Approval.process(requests);
        List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectByIdWithLinesAndProcessSteps(new Set<Id>{salesInvoice.Id});
        Id processStepId = salesInvoices[0].ProcessSteps[0].Id;

        List<ProcessInstanceHistory> processInstanceHistories = new List<ProcessInstanceHistory>();
        processInstanceHistories = ProcessInstanceStepController.getProcessInstanceHistories(processStepId);

        //retrieve approval comments
        ApprovalComment approvalComment = new ApprovalComment(salesInvoice.Id);
        List<ApprovalComment.ApprovalCommentWrap> approvalCommentWraps = approvalComment.approvalCommensWraps;

        ApprovalEmailContent approvalEmailContent = new ApprovalEmailContent(salesInvoice.Id);
        ApprovalEmailContent.EmailContent emailContent = approvalEmailContent.emailContentWrapper;

        salesInvoiceLine.Unit_Cost__c = 50;
        salesInvoiceLine.Line_Cost__c = 50;
        update salesInvoiceLine;
        SalesInvoicesService.submitForApproval(salesInvoice.Id);
        Test.stopTest();
    }

    @IsTest
    static void testCreditMemoWorksheetApproval() {
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
        workSheetLine.TM_Line__c = TestDataUtil.TMLineLaborRecord.id;
        workSheetLine.TM__c = TestDataUtil.TMRecord.id;
        insert workSheetLine;

        Test.startTest();
        try{
            SalesInvoicesService.submitForApproval(creditMemoWorkSheet.Id);
            //approve an approval request
            List<ProcessInstanceWorkitem> workItems = [
                    SELECT Id, ProcessInstanceId
                    FROM ProcessInstanceWorkitem
                    WHERE ProcessInstance.TargetObjectId = :creditMemoWorkSheet.Id
            ];
            List<Approval.ProcessWorkitemRequest> requests = new List<Approval.ProcessWorkitemRequest>();
            for(ProcessInstanceWorkitem workItem : workItems){
                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                req.setWorkitemId(workItem.Id);
                //Valid values are: Approve, Reject, or Reassign.
                req.setAction('Approve');
                req.setComments('Approve');
                requests.add(req);
            }
            Approval.ProcessResult[] processResults = Approval.process(requests);

            ApprovalEmailContent approvalEmailContent = new ApprovalEmailContent(creditMemoWorkSheet.Id);
            ApprovalEmailContent.EmailContent emailContent = approvalEmailContent.emailContentWrapper;
        } catch (Exception e){

        }
        Test.stopTest();
    }
    //test
}