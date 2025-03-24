@IsTest
private class SalesOrdersServiceTest {
    @IsTest
    private static void testUpdateSalesLinesForBillAsLumpSumAllAction(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ISalesLines domainMock = new Mocks.SalesLines(mocks);
        ISalesOrdersSelector selectorMock= new Mocks.SalesOrdersSelector(mocks);
        
        // Given
        mocks.startStubbing();
        Sales_Order__c theSO = new Sales_Order__c(
            Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType)
        );
        Sales_Line__c salesLine1 = new Sales_Line__c(
            Id = fflib_IDGenerator.generate(Sales_Line__c.SObjectType),
            Sales_Order__c = theSO.Id
        );
        Sales_Line__c salesLine2 = new Sales_Line__c(
            Id = fflib_IDGenerator.generate(Sales_Line__c.SObjectType),
            Sales_Order__c = theSO.Id
        );
        List<Sales_Line__c> theSLList = new List<Sales_Line__c>{salesLine1, salesLine2};
            mocks.when(domainMock.sObjectType()).thenReturn(Sales_Line__c.SObjectType);
        mocks.when(selectorMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorMock.selectById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.stopStubbing();
        Application.Domain.setMock(domainMock);
        Application.Selector.setMock(selectorMock);
        
        // When
        SalesOrdersService.updateSalesLinesForBillAsLumpSumAllAction(theSLList);
        
    }
    
    /*
@IsTest
private static void testCloneSalesOrder() {
// Create mocks
fflib_ApexMocks mocks = new fflib_ApexMocks();
fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
ISalesOrdersSelector selectorMock= new Mocks.SalesOrdersSelector(mocks);

// Given
mocks.startStubbing();
Account billToCust = TestDataUtil.customerAccountRecord;
Id theSOId = fflib_IDGenerator.generate(Sales_Order__c.SObjectType);
Id theSLId = fflib_IDGenerator.generate(Sales_Line__c.SObjectType);

String jsonStr = '{"Id" : "' + theSOId + '", "Approval_Status__c" : "Approved", "Sales_Lines__r" : {"totalSize" : 1, "done" : true, "records" : [{"Id" : "'+  theSLId +'", "Sales_Order__c" : "'+ theSOId +'"}]}}';
Sales_Order__c theSO  = (Sales_Order__c) JSON.deserialize(jsonStr, Sales_Order__c.class);
mocks.when(selectorMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
mocks.when(selectorMock.selectByIdWithLinesForClone(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
mocks.stopStubbing();
Application.UnitOfWork.setMock(uowMock);
Application.Selector.setMock(selectorMock);

// When
SalesOrdersService.cloneSalesOrder(new Set<Id>{theSO.Id}, 'Quote', fflib_IDGenerator.generate(Service_Center__c.SObjectType), billToCust.Id, billToCust.Id);
SalesOrdersService.cloneSalesOrder(new Set<Id>{theSO.Id}, 'Order', fflib_IDGenerator.generate(Service_Center__c.SObjectType), billToCust.Id, billToCust.Id);
}
*/
    
    @IsTest
    private static void testCloneSalesQuote() {
        // Create mocks
        /*
Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
Subsidiary_Company__c theSubsidiaryCompany = TestDataUtil.SubsidiaryCompanyRecord;
Service_Center__c theServiceCenter = TestDataUtil.ServiceCenterRecord;
Sales_Order__c theSO  = TestDataUtil.SalesOrderRecord;
SalesOrdersService.cloneSalesOrder(new Set<Id>{theSO.Id}, 'Quote', theServiceCenter.Id, theSO.Bill_to_Customer_No__c, theSO.Bill_to_Customer_No__c, 'job description', 'ABC12123');
SalesOrdersService.cloneSalesOrder(new Set<Id>{theSO.Id}, 'Order', theServiceCenter.Id, theSO.Bill_to_Customer_No__c, theSO.Bill_to_Customer_No__c, 'job description','ABV123123');
*/
        NewTestData.createTestData();
        
        Test.startTest();
        Account customer = NewTestData.mapAccountWrappersByName.get('Customer 2').Account;
        Service_Center__c theServiceCenter = TestDataUtil.ServiceCenterRecord;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SQ1');
        salesOrder.Contract__c = null;
        salesOrder.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        CompanyMgmt.byPassTrigger = true;
        update salesOrder;
        SalesOrdersService.cloneSalesOrder(new Set<Id>{salesOrder.Id}, 'Quote', theServiceCenter.Id, customer.Id, customer.Id, 'job description', '12123');
        Test.stopTest();
    }
    @IsTest
    private static void testCloneSalesOrder() {
        NewTestData.createTestData();
        
        Test.startTest();
        Service_Center__c theServiceCenter = TestDataUtil.ServiceCenterRecord;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        salesOrder.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        CompanyMgmt.byPassTrigger = true;
        update salesOrder;
        try{
            SalesOrdersService.cloneSalesOrder(new Set<Id>{salesOrder.Id}, 'Order', theServiceCenter.Id, salesOrder.Bill_to_Customer_No__c, salesOrder.Bill_to_Customer_No__c, 'job description','123123');   
        }
        catch(Exception ex){}
        Test.stopTest();
    }
    
    
    @IsTest
    private static void testCreateNewSalesQuoteOrSalesOrderWithSalesOrderParam(){
        NewTestData.createTestData();
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IContractsSelector selectorContractMock = new Mocks.ContractsSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);
        
        mocks.startStubbing();
        String documentType = 'Sales Order';
        String billToCustomer = fflib_IDGenerator.generate(Account.SObjectType);
        Account parentAcct = new Account(
            Id = fflib_IDGenerator.generate(Account.SObjectType),
            Billing_Instructions__c = 'Test',
            Internal_Comments__c = 'test'
        );
        Account acct = new Account(
            Id = billToCustomer,
            Type = 'Prospect',
            ParentId = parentAcct.Id
        );
        String serviceCenter = '01';
        Service_Center__c theSC = new Service_Center__c(
            Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
            Name = serviceCenter
        );
        String contrac = fflib_IDGenerator.generate(Contract.SObjectType);
        Contract contra = new Contract(
            Id = contrac
        );
        String quote = fflib_IDGenerator.generate(Account.SObjectType);
        Company_Setup__c theCompanySetup = new Company_Setup__c(
            Quote_Default_Payment_Term__c = fflib_IDGenerator.generate(Payment_Term__c.SObjectType)
        );
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorContractMock.sObjectType()).thenReturn(Contract.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorSCMock.selectByName('01')).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorContractMock.selectByIdWithBillingRule(new Set<Id>{contrac})).thenReturn(new List<Contract>{contra});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCustomer})).thenReturn(new List<Account>{acct});
        mocks.when(selectorAccountMock.selectBillingInstructionsById(new Set<Id>{acct.ParentId})).thenReturn(new List<Account>{parentAcct});
        mocks.stopStubbing();
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);
        Application.Selector.setMock(selectorContractMock);
        
        SalesOrdersServiceImpl.theCompanySetupValue = theCompanySetup;
        SalesOrdersService.createNewSalesQuoteOrSalesOrder(documentType, billToCustomer, serviceCenter, contrac, quote);
        
    }
    @IsTest
    private static void testCreateNewSalesQuoteOrSalesOrderWithSalesQuoteParam(){
        NewTestData.createTestData();
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IContractsSelector selectorContractMock = new Mocks.ContractsSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);
        
        mocks.startStubbing();
        String documentType = 'Sales Quote';
        String billToCustomer = fflib_IDGenerator.generate(Account.SObjectType);
        Account parentAcct = new Account(
            Id = fflib_IDGenerator.generate(Account.SObjectType),
            Billing_Instructions__c = 'Test',
            Internal_Comments__c = 'test'
        );
        Account acct = new Account(
            Id = billToCustomer,
            Type = 'Customer',
            ParentId = parentAcct.Id,
            Inter_co_Account__c = true
        );
        
        String serviceCenter = '01';
        Service_Center__c theSC = new Service_Center__c(
            Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
            Name = serviceCenter
        );
        String contrac = fflib_IDGenerator.generate(Contract.SObjectType);
        Contract contra = new Contract(
            Id = contrac
        );
        String quote = fflib_IDGenerator.generate(Account.SObjectType);
        Company_Setup__c theCompanySetup = new Company_Setup__c(
            Quote_Default_Payment_Term__c = fflib_IDGenerator.generate(Payment_Term__c.SObjectType)
        );
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorContractMock.sObjectType()).thenReturn(Contract.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorSCMock.selectByName('01')).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorContractMock.selectByIdWithBillingRule(new Set<Id>{contrac})).thenReturn(new List<Contract>{contra});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCustomer})).thenReturn(new List<Account>{acct});
        mocks.when(selectorAccountMock.selectBillingInstructionsById(new Set<Id>{acct.ParentId})).thenReturn(new List<Account>{parentAcct});
        mocks.stopStubbing();
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);
        Application.Selector.setMock(selectorContractMock);
        
        SalesOrdersServiceImpl.theCompanySetupValue = theCompanySetup;
        SalesOrdersService.createNewSalesQuoteOrSalesOrder(documentType, billToCustomer, serviceCenter, contrac, quote);
    }
    
    @IsTest
    private static void testSetSurchargePct() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IContractsSelector selectorContractMock = new Mocks.ContractsSelector(mocks);
        
        mocks.startStubbing();
        Contract contra = new Contract(
            Id = fflib_IDGenerator.generate(Contract.SObjectType)
        );
        Sales_Order__c theSO = new Sales_Order__c(
            Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
            Contract__c = contra.Id,
            Surcharge_Type__c = 'EEC Fee'
        );
        mocks.when(selectorContractMock.sObjectType()).thenReturn(Contract.SObjectType);
        mocks.when(selectorContractMock.selectById(new Set<Id>{contra.Id})).thenReturn(new List<Contract>{contra});
        mocks.stopStubbing();
        Application.Selector.setMock(selectorContractMock);
        
        SalesOrdersService.setSurchargePct(theSO);
    }
    
    @IsTest
    private static void testConvertQuoteToOrder(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ISalesOrdersSelector selectorMock= new Mocks.SalesOrdersSelector(mocks);
    }
    
    @IsTest
    private static void testSalesOrderService(){
        NewTestData.createTestData();
        Test.startTest();
        Id salesOrderId = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01).Id;
        SalesOrdersService.addManifestLineToRelatedRecords(new Set<Id>{salesOrderId});
        //SalesOrdersService.deleteManifestLineFromRelatedRecords(new Set<Id>{salesOrderId});
        
        Sales_Order__c salesOrder = SalesOrdersSelector.newInstance().selectById(new Set<Id>{salesOrderId})[0];
        SalesOrdersService.validatePayRule(salesOrder);
        Id salesQuoteId = NewTestData.mapSalesOrdersByName.get('SQ1').Id;
        SalesOrdersService.updateSQWhenNewSOCreated(salesQuoteId);
        Test.stopTest();
    }
    
    @IsTest
    private static void testdeleteManifestLineFromRelatedRecords(){
        NewTestData.createTestData();
        Test.startTest();
        Id salesOrderId = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01).Id;
        //SalesOrdersService.addManifestLineToRelatedRecords(new Set<Id>{salesOrderId});
        SalesOrdersService.deleteManifestLineFromRelatedRecords(new Set<Id>{salesOrderId});
        SalesOrdersService.reopenKronosProcessedTMLinesBySalesOrderId(salesOrderId);
        Test.stopTest();
    }
    
    // @IsTest
    // private static void testIsValidCustomer() {
    //     NewTestData.createTestData();
        
    //     Test.startTest();
    //     Account customer = NewTestData.mapAccountWrappersByName.get('Customer 2').Account;
    //     customer.Type = 'Prospect';
    //     customer.Customer_Status__c = 'Active';
    //     customer.BillingStreet = 'Test Street';
    //     customer.BillingCity = 'Test City';
    //     customer.BillingStateCode ='AZ';
    //     customer.BillingPostalCode ='85244';
    //     update customer;
    //     Service_Center__c theServiceCenter = TestDataUtil.ServiceCenterRecord;
    //     Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SQ1');
    //     salesOrder.Contract__c = null;
    //     salesOrder.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
    //     List<Contact> contacts = new List<Contact>();
        
    //     Contact customerContact = new Contact();
    //     customerContact.AccountId = customer.Id;
    //     customerContact.Account = customer;
    //     customerContact.FirstName = 'John';
    //     customerContact.LastName = 'Smith';
    //     customerContact.MailingStreet = '123 ABC Ave' + '\n' + 'Suite 123';
    //     customerContact.MailingStateCode = 'NY';
    //     customerContact.MailingState = 'New York';
    //     customerContact.MailingCity = 'New York';
    //     customerContact.MailingCountry = 'United States';
    //     customerContact.MailingCountryCode = 'US';
    //     customerContact.MailingPostalCode = '10002';
    //     customerContact.Contact_Type__c = 'Site;Quote;Billing;Purchase;Executive;Sales';
    //     contacts.add(customerContact);
        
    //     insert contacts;
        
    //     CompanyMgmt.byPassTrigger = true;
    //     update salesOrder;
    //     SalesOrdersService.isValidCustomer(customer.Id);
    //     Test.stopTest();
    // }
    private static testMethod void testValidateRateSheet() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        Rate_Sheet__c objRate = New Rate_Sheet__c();
        objRate.Name = 'test';
        insert objRate; 
        Test.startTest();
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
        SalesOrdersService.validateRateSheet(salesOrder,jobTaskWrappers,objRate.Id);
        SalesOrdersService.cloneJobTask(salesOrder,jobTaskWrappers[0],jobTaskWrappers[0],1);
        Test.stopTest();  
    }
    //test1
}