/*
* Class Name: SFJobBillingProjectService
* Created By  : Shahwaz Khan 

* Modification Log :
* Developer                 Date                   Description
--------------------------------------------------------------------------------------------------------------               
Shahwaz Khan                09/04/2024              80447 - Job Level Billing Project
													Fixed Argument Issue
													Fixed 88134
*************************************************************************************************************/
@IsTest
public class SFJobBillingProjectServiceTest {
    
    @IsTest
    private static void testSalesInvoiceService(){
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
        salesOrder.Internal_Comments__c = 'Test the internal comment in the job billing project json . Please enforce the user to create the job billing project Json with internal comment section Test the internal comment in the job billing project json . Please enforce the user to create the job billing project json with internal comment section ';
        Contact billingContact = new Contact(AccountId = TestDataUtil.customerAccountRecord.Id, LastName = 'MDN', Email = 'example@example.com', Contact_Type__c = 'Billing');
        insert billingContact;
        salesOrder.Bill_to_Contact__c = billingContact.Id;        
        insert salesOrder;
        
        TestDataUtil.customerAccountRecord.Invoice_Submission_Channels__c = 'EMAIL';
        update TestDataUtil.customerAccountRecord;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpBillingJobResponseGenerator());
        SFJobBillingProjectService.reOpenSalesOrderInfo(salesOrder.Id);
        SFJobBillingProjectService.updateCloseDateInSalesOrderInfo(salesOrder.Id);
        SalesOrders obj=New SalesOrders(New List<Sales_Order__c>{salesOrder});
        obj.checkBeforeConvert();
        Test.stopTest();
    }
}