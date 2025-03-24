@IsTest
private class ApprovalProcessTest {

    @testSetup static void setup(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord; //needed for numbering series data

        Service_Center__c serviceCenter = TestDataUtil.ServiceCenterRecord;
        User testUser = TestDataUtil.UserRecord;

        List<Approval_Tree__c> approvalTrees = new List<Approval_Tree__c>();

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SQ-01-1',
                Document_Type__c = 'Sales_Quote',
                Level__c = 1,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 45,
                Approver__c = testUser.Id));

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SQ-01-2',
                Document_Type__c = 'Sales_Quote',
                Level__c = 2,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 40,
                Approver__c = UserInfo.getUserId()));

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SQ-01-3',
                Document_Type__c = 'Sales_Quote',
                Level__c = 3,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 30,
                Approver__c = testUser.Id));

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SQ-01-4',
                Document_Type__c = 'Sales_Quote',
                Level__c = 4,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 15,
                Approver__c = testUser.Id));

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SO-01-1',
                Document_Type__c = 'Sales_Order',
                Level__c = 1,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 40,
                Approver__c = testUser.Id));

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SO-01-2',
                Document_Type__c = 'Sales_Order',
                Level__c = 2,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 30,
                Approver__c = testUser.Id));

        approvalTrees.add(new Approval_Tree__c(
                Name = 'SO-01-3',
                Document_Type__c = 'Sales_Order',
                Level__c = 3,
                Service_Center__c = serviceCenter.Id,
                Approval_Margin_Pct__c = 15,
                Approver__c = UserInfo.getUserId()));

        insert approvalTrees;
    }

    @IsTest
    static void testSalesOrderAutoApproved() {
        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Quote';
        salesOrder.Site_Name__c = 'MDN Test';
        salesOrder.Create_Site_Address__c = true;
        salesOrder.Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.subsidiarycompanyRecord.id;
        salesOrder.Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id;
        salesOrder.Total_Margin_Pct__c = 50;
        salesOrder.Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25);
        insert salesOrder;

        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Line_No__c = 1;
        salesLine.Category__c = 'Labor';
        salesLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.id;
        salesLine.Unit_of_Measure__c = TestDataUtil.HRUnitMeasureRecord.Id;
        salesLine.Description__c = 'Test item';
        salesLine.Quantity__c = 1;
        salesLine.UOM_Qty__c = 8;
        salesLine.Unit_Price__c = 50;
        salesLine.Unit_Cost__c = 25;
        salesLine.Regular_Rate__c = 50;
        salesLine.Overtime_Rate__c = 75;
        salesLine.Premium_Rate__c = 100;
        salesLine.Regular_Hours__c = 8;
        salesLine.Overtime_Hours__c= 0;
        salesLine.Premium_Hours__c = 0;
        salesLine.Regular_Day__c = 1;
        salesLine.Overtime_Day__c= 0;
        salesLine.Premium_Day__c = 0;
        salesLine.Number_of_Day__c = 1;

        insert salesLine;

        SalesRecordApprovalProcess salesRecordApprovalProcess = new SalesRecordApprovalProcess(salesOrder);
        salesRecordApprovalProcess.initialApprovalRequest = true;
        salesRecordApprovalProcess.submitApprovalRequest();
        salesRecordApprovalProcess.setApprovalStatusOnSave();

        ApprovalEmailContent approvalEmailContent = new ApprovalEmailContent(salesOrder.Id);
        ApprovalEmailContent.EmailContent emailContent = approvalEmailContent.emailContentWrapper;

        salesOrder.Total_Margin_Pct__c = 41;
        SalesRecordApprovalProcess salesRecordApprovalProcess2 = new SalesRecordApprovalProcess(salesOrder);
        salesRecordApprovalProcess2.setApprovalStatusOnSave();

        salesOrder.Total_Margin_Pct__c = 39;
        SalesRecordApprovalProcess salesRecordApprovalProcess3 = new SalesRecordApprovalProcess(salesOrder);
        salesRecordApprovalProcess3.setApprovalStatusOnSave();
    }

    @IsTest
    static void testSalesOrderApprovalProcess() {
        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Quote';
        salesOrder.Site_Name__c = 'MDN Test';
        salesOrder.Create_Site_Address__c = true;
        salesOrder.Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.subsidiarycompanyRecord.id;
        salesOrder.Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id;
        salesOrder.Total_Margin_Pct__c = 10;
        salesOrder.Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25);
        salesOrder.OwnerId = UserInfo.getUserId();
        insert salesOrder;

        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Line_No__c = 1;
        salesLine.Category__c = 'Labor';
        salesLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.id;
        salesLine.Unit_of_Measure__c = TestDataUtil.HRUnitMeasureRecord.Id;
        salesLine.Description__c = 'Test item';
        salesLine.Quantity__c = 1;
        salesLine.UOM_Qty__c = 8;
        salesLine.Unit_Price__c = 50;
        salesLine.Unit_Cost__c = 45;
        salesLine.Regular_Rate__c = 50;
        salesLine.Overtime_Rate__c = 75;
        salesLine.Premium_Rate__c = 100;
        salesLine.Regular_Hours__c = 8;
        salesLine.Overtime_Hours__c= 0;
        salesLine.Premium_Hours__c = 0;
        salesLine.Regular_Day__c = 1;
        salesLine.Overtime_Day__c= 0;
        salesLine.Premium_Day__c = 0;
        salesLine.Number_of_Day__c = 1;

        insert salesLine;

        SalesRecordApprovalProcess salesRecordApprovalProcess = new SalesRecordApprovalProcess(salesOrder);
        salesRecordApprovalProcess.initialApprovalRequest = true;
        //Submit record for approval
        salesRecordApprovalProcess.submitApprovalRequest();

        //reassign approval request
        salesRecordApprovalProcess.reassignApprovalRequest();

        //approve an approval request
        List<ProcessInstanceWorkitem> workItems = [
                SELECT Id, ProcessInstanceId
                FROM ProcessInstanceWorkitem
                WHERE ProcessInstance.TargetObjectId = :salesOrder.Id
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
        List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectByIdWithLinesAndProcessSteps(new Set<Id>{salesOrder.Id});
        Id processStepId = salesOrders[0].ProcessSteps[0].Id;

        List<ProcessInstanceHistory> processInstanceHistories = new List<ProcessInstanceHistory>();
        processInstanceHistories = ProcessInstanceStepController.getProcessInstanceHistories(processStepId);
        
        //retrieve approval comments
        ApprovalComment approvalComment = new ApprovalComment(salesOrder.Id);
        List<ApprovalComment.ApprovalCommentWrap> approvalCommentWraps = approvalComment.approvalCommensWraps;
    }

    @IsTest
    static void testSalesQuoteApprovalProcessMisc() {
        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Quote';
        salesOrder.Site_Name__c = 'MDN Test';
        salesOrder.Create_Site_Address__c = true;
        salesOrder.Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.subsidiarycompanyRecord.id;
        salesOrder.Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id;
        salesOrder.Total_Margin_Pct__c = 42;
        salesOrder.Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25);
        salesOrder.OwnerId = UserInfo.getUserId();
        insert salesOrder;

        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Line_No__c = 1;
        salesLine.Category__c = 'Labor';
        salesLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.id;
        salesLine.Unit_of_Measure__c = TestDataUtil.HRUnitMeasureRecord.Id;
        salesLine.Description__c = 'Test item';
        salesLine.Quantity__c = 1;
        salesLine.UOM_Qty__c = 8;
        salesLine.Unit_Price__c = 50;
        salesLine.Unit_Cost__c = 45;
        salesLine.Regular_Rate__c = 50;
        salesLine.Overtime_Rate__c = 75;
        salesLine.Premium_Rate__c = 100;
        salesLine.Regular_Hours__c = 8;
        salesLine.Overtime_Hours__c= 0;
        salesLine.Premium_Hours__c = 0;
        salesLine.Regular_Day__c = 1;
        salesLine.Overtime_Day__c= 0;
        salesLine.Premium_Day__c = 0;
        salesLine.Number_of_Day__c = 1;

        insert salesLine;

        SalesRecordApprovalProcess salesRecordApprovalProcess = new SalesRecordApprovalProcess(salesOrder);
        salesRecordApprovalProcess.initialApprovalRequest = true;
        //Submit record for approval
        salesRecordApprovalProcess.submitApprovalRequest();
    }

    @IsTest
    static void testSalesOrderApprovalProcessMisc() {
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
        salesOrder.Estimated_Job_Start_Date__c = Date.newInstance(2019,10,25);
        salesOrder.OwnerId = UserInfo.getUserId();
        insert salesOrder;

        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Line_No__c = 1;
        salesLine.Category__c = 'Labor';
        salesLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.id;
        salesLine.Unit_of_Measure__c = TestDataUtil.HRUnitMeasureRecord.Id;
        salesLine.Description__c = 'Test item';
        salesLine.Quantity__c = 1;
        salesLine.UOM_Qty__c = 8;
        salesLine.Unit_Price__c = 50;
        salesLine.Unit_Cost__c = 45;
        salesLine.Regular_Rate__c = 50;
        salesLine.Overtime_Rate__c = 75;
        salesLine.Premium_Rate__c = 100;
        salesLine.Regular_Hours__c = 8;
        salesLine.Overtime_Hours__c= 0;
        salesLine.Premium_Hours__c = 0;
        salesLine.Regular_Day__c = 1;
        salesLine.Overtime_Day__c= 0;
        salesLine.Premium_Day__c = 0;
        salesLine.Number_of_Day__c = 1;

        insert salesLine;

        SalesRecordApprovalProcess salesRecordApprovalProcess = new SalesRecordApprovalProcess(salesOrder);
        //Submit record for approval
        salesRecordApprovalProcess.submitApprovalRequest();
        //salesRecordApprovalProcess.sendApprovedNotification();
    }
}