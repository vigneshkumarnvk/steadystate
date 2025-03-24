@IsTest
private class CloneSalesOrderControllerTest {

    @IsTest
    private static void testCloneSO(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);
        IUsersSelector selectorUserMock = new Mocks.UsersSelector(mocks);

        // Given taskf
        mocks.startStubbing();
        Service_Center__c theSC = new Service_Center__c(
                Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
                Name = '01',
            	Description__c = 'Test',
            	Prevent_New_and_Cloned_Sales_Orders__c = false
        );
        Subsidiary_Company__c subCom = new Subsidiary_Company__c(
                Id = fflib_IDGenerator.generate(Subsidiary_Company__c.SObjectType),
                Name= '1-ACV'
        );
        Account billToCust = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Name = 'CON EDISON',
            	Type = 'Prospect'
        );
        Sales_Order__c theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Service_Center__c = theSC.Id,
                Subsidiary_Company__c = subCom.Id,
                Bill_to_Customer_No__c = billToCust.Id,
            	CMR_Description__c = 'Test'
        );
        User usertest = new User(
                Id = fflib_IDGenerator.generate(User.SObjectType),
                Service_Center__c = theSC.Name
        );

        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorUserMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(selectorSOMock.selectServiceCenterAndSubCompanyById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorSCMock.selectAll()).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCust.Id})).thenReturn(new List<Account>{billToCust});
        mocks.when(selectorUserMock.selectById(new Set<Id>{Id.valueOf(UserInfo.getUserId())})).thenReturn(new List<User>{usertest});
        mocks.when(selectorSCMock.selectByName(usertest.Service_Center__c)).thenReturn(new List<Service_Center__c>{theSC});
        mocks.stopStubbing();
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);
        Application.Selector.setMock(selectorUserMock);

        // When
        CloneSalesOrderController controller = new CloneSalesOrderController(standardController);
        List<SelectOption> selectOptions = controller.lstConvertTo;
        //String sc = controller.selServiceCenter;;
        controller.selConvertTo = 'Order';
        controller.poNumber = 'TestPO';
        controller.selectedServiceCenterId = theSC.Id;
        controller.cloneSO();

    }

    @IsTest
    private static void testCloneSOWithException(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);
        IUsersSelector selectorUserMock = new Mocks.UsersSelector(mocks);


        // Given
        mocks.startStubbing();
        Service_Center__c theSC = new Service_Center__c(
                Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
                Name = '01'
        );
        Subsidiary_Company__c subCom = new Subsidiary_Company__c(
                Id = fflib_IDGenerator.generate(Subsidiary_Company__c.SObjectType),
                Name= '1-ACV'
        );
        Account billToCust = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Name = 'CON EDISON'
        );
        Sales_Order__c theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Service_Center__c = theSC.Id,
                Subsidiary_Company__c = subCom.Id,
                Bill_to_Customer_No__c = billToCust.Id
        );
        User usertest = new User(
                Id = fflib_IDGenerator.generate(User.SObjectType),
                Service_Center__c = theSC.Name
        );

        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorUserMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(selectorSOMock.selectServiceCenterAndSubCompanyById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorSCMock.selectAll()).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCust.Id})).thenReturn(new List<Account>{billToCust});
        mocks.when(selectorUserMock.selectById(new Set<Id>{Id.valueOf(UserInfo.getUserId())})).thenReturn(new List<User>{usertest});
        mocks.when(selectorSCMock.selectByName(usertest.Service_Center__c)).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(serviceSOMock.cloneSalesOrder(new Set<Id>{ theSO.Id},'Order', theSC.Id, billToCust.Id, billToCust.Id, 'job description','ACV12343')).thenThrow(new MyException('lala'));
        mocks.stopStubbing();
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);
        Application.Selector.setMock(selectorUserMock);

        // When
        CloneSalesOrderController controller = new CloneSalesOrderController(standardController);
        controller.selConvertTo = 'Order';
        
        controller.cloneSO();

    }

    @IsTest
    private static void testValidateBillToCust(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);

        // Given
        mocks.startStubbing();
        Service_Center__c theSC = new Service_Center__c(
                Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
                Name = '01'
        );
        Subsidiary_Company__c subCom = new Subsidiary_Company__c(
                Id = fflib_IDGenerator.generate(Subsidiary_Company__c.SObjectType),
                Name= '1-ACV'
        );
        Account billToCust = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Name = 'CON EDISON',
            	Type = 'Prospect'
        );
        Sales_Order__c theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Service_Center__c = theSC.Id,
                Subsidiary_Company__c = subCom.Id,
                Bill_to_Customer_No__c = billToCust.Id
        );

        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorSOMock.selectServiceCenterAndSubCompanyById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorSCMock.selectAll()).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCust.Id})).thenReturn(new List<Account>{billToCust});

        mocks.stopStubbing();
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);

        CloneSalesOrderController controller = new CloneSalesOrderController(standardController);
        System.currentPageReference().getParameters().put('billToCustId', billToCust.Id);
        controller.validateBillToCust();
    }
    @IsTest
    private static void testValidateBillToCustWithNullBillToCust(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);

        // Given
        mocks.startStubbing();
        Service_Center__c theSC = new Service_Center__c(
                Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
                Name = '01'
        );
        Subsidiary_Company__c subCom = new Subsidiary_Company__c(
                Id = fflib_IDGenerator.generate(Subsidiary_Company__c.SObjectType),
                Name= '1-ACV',
            QtC_Enabled__c = true
        );
        Account billToCust = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Name = 'CON EDISON',
            	Type = 'Prospect'
        );
        Sales_Order__c theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Service_Center__c = theSC.Id,
                Subsidiary_Company__c = subCom.Id,
                Bill_to_Customer_No__c = billToCust.Id
        );

        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorSOMock.selectServiceCenterAndSubCompanyById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorSCMock.selectAll()).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCust.Id})).thenReturnMulti(new List<List<Account>>{new List<Account>{billToCust}, new List<Account>()});

        mocks.stopStubbing();
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);

        CloneSalesOrderController controller = new CloneSalesOrderController(standardController);
        //System.currentPageReference().getParameters().put('billToCustId', billToCust.Id);
        controller.validateBillToCust();
    }
    
	 @IsTest
    private static void testValidateBillToCustwithParam(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);

        // Given
        mocks.startStubbing();
        Service_Center__c theSC = new Service_Center__c(
                Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
                Name = '01'
        );
        Subsidiary_Company__c subCom = new Subsidiary_Company__c(
                Id = fflib_IDGenerator.generate(Subsidiary_Company__c.SObjectType),
                Name= '1-ACV'
        );
        Contact contact = new Contact(
            Id = fflib_IDGenerator.generate(Contact.SObjectType),
            Contact_Type__c = 'Billing',
            Blocked__c = False
        );
        Account billToCust = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Name = 'CON EDISON',
            	Type = 'Customer',
            Customer_Status__c = 'Active',
            BillingStreet = 'Test Street',
            BillingCity = 'Test City',
            BillingStateCode = 'Test State',
             BillingPostalCode = '85249',
            Billing_Contact__c = contact.Id
        );
        Sales_Order__c theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Service_Center__c = theSC.Id,
                Subsidiary_Company__c = subCom.Id,
                Bill_to_Customer_No__c = billToCust.Id
        );

        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorSOMock.selectServiceCenterAndSubCompanyById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorSCMock.selectAll()).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCust.Id})).thenReturn(new List<Account>{billToCust});

        mocks.stopStubbing();
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);

        CloneSalesOrderController controller = new CloneSalesOrderController(standardController);
        System.currentPageReference().getParameters().put('billToCustId', billToCust.Id);
        controller.validateBillToCust();
        CloneSalesOrderController.validateBillToCust(billToCust.Id);
    }
    @IsTest
    private static void testCloneSOwithParam(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);

        // Given
        mocks.startStubbing();
        Service_Center__c theSC = new Service_Center__c(
                Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
                Name = '01',
            Prevent_New_and_Cloned_Sales_Orders__c = false
        );
        Subsidiary_Company__c subCom = new Subsidiary_Company__c(
                Id = fflib_IDGenerator.generate(Subsidiary_Company__c.SObjectType),
                Name= '1-ACV',QtC_Enabled__c = True
        );
        Contact contact = new Contact(
            Id = fflib_IDGenerator.generate(Contact.SObjectType),
            Contact_Type__c = 'Billing',
            Blocked__c = False
        );
        Account billToCust = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Name = 'CON EDISON',
            	Type = 'Customer'
        );
        Sales_Order__c theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Service_Center__c = theSC.Id,
                Subsidiary_Company__c = subCom.Id,
                Bill_to_Customer_No__c = billToCust.Id
        );

        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorSOMock.selectServiceCenterAndSubCompanyById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorSCMock.selectAll()).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCust.Id})).thenReturn(new List<Account>{billToCust});
		mocks.stopStubbing();
        
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);
		CloneSalesOrderController controller = new CloneSalesOrderController(standardController);
        System.currentPageReference().getParameters().put('billToCustId', billToCust.Id);
        System.currentPageReference().getParameters().put('selectedSCId', theSC.Id);
        
        controller.populatedSelectedServiceCenterId();
        //controller.selServiceCenter();
        CloneSalesOrderController.cloneSalesOrder( theSO.Id,'Order', theSC.Id, billToCust.Id, billToCust.Id, 'job description','ACV12343');
        
    }
    
    @IsTest
    private static void testselServiceCenter(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);
        IUsersSelector selectorUserMock = new Mocks.UsersSelector(mocks);

        // Given
        mocks.startStubbing();
        Service_Center__c theSC = new Service_Center__c(
                Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
                Name = '01',
            	Description__c = 'Test',
            	Prevent_New_and_Cloned_Sales_Orders__c = false
        );
        Subsidiary_Company__c subCom = new Subsidiary_Company__c(
                Id = fflib_IDGenerator.generate(Subsidiary_Company__c.SObjectType),
                Name= '1-ACV'
        );
        Account billToCust = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Name = 'CON EDISON',
            	Type = 'Prospect'
        );
        Sales_Order__c theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Service_Center__c = theSC.Id,
                Subsidiary_Company__c = subCom.Id,
                Bill_to_Customer_No__c = billToCust.Id,
            	CMR_Description__c = 'Test'
        );
        User usertest = new User(
                Id = fflib_IDGenerator.generate(User.SObjectType),
                Service_Center__c = theSC.Name
        );

        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorUserMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(selectorSOMock.selectServiceCenterAndSubCompanyById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorSCMock.selectAll()).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCust.Id})).thenReturn(new List<Account>{billToCust});
        mocks.when(selectorUserMock.selectById(new Set<Id>{Id.valueOf(UserInfo.getUserId())})).thenReturn(new List<User>{usertest});
        mocks.when(selectorSCMock.selectByName(usertest.Service_Center__c)).thenReturn(new List<Service_Center__c>{theSC});
        mocks.stopStubbing();
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);
        Application.Selector.setMock(selectorUserMock);

        // When
        CloneSalesOrderController controller = new CloneSalesOrderController(standardController);
        List<SelectOption> selectOptions = controller.lstConvertTo;
        
        controller.selConvertTo = 'Quote';
        controller.poNumber = 'TestPO';
        System.currentPageReference().getParameters().put('poNumber', 'PO1234');
        controller.cloneSO();
        String sc = controller.selServiceCenter;

    }
    
    @IsTest
    private static void testgetData(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        IServiceCentersSelector selectorSCMock = new Mocks.ServiceCentersSelector(mocks);
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);
        IUsersSelector selectorUserMock = new Mocks.UsersSelector(mocks);

        // Given
        mocks.startStubbing();
        Service_Center__c theSC = new Service_Center__c(
                Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
                Name = '01',
            	Description__c = 'Test',
            	Prevent_New_and_Cloned_Sales_Orders__c = false
        );
        Subsidiary_Company__c subCom = new Subsidiary_Company__c(
                Id = fflib_IDGenerator.generate(Subsidiary_Company__c.SObjectType),
                Name= '1-ACV'
        );
        Account billToCust = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Name = 'CON EDISON',
            	Type = 'Prospect'
        );
        Sales_Order__c theSO = new Sales_Order__c(
                //Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Service_Center__c = theSC.Id,
                Subsidiary_Company__c = subCom.Id,
                Bill_to_Customer_No__c = billToCust.Id,
            	CMR_Description__c = 'Test'
        );
    // insert theSO;
        
        NewTestData.createTestData();
        //Test.startTest();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        
        User usertest = new User(
                Id = fflib_IDGenerator.generate(User.SObjectType),
                Service_Center__c = theSC.Name
        );

        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSCMock.sObjectType()).thenReturn(Service_Center__c.SObjectType);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorUserMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(selectorSOMock.selectServiceCenterAndSubCompanyById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorSCMock.selectAll()).thenReturn(new List<Service_Center__c>{theSC});
        mocks.when(selectorAccountMock.selectById(new Set<Id>{billToCust.Id})).thenReturn(new List<Account>{billToCust});
        mocks.when(selectorUserMock.selectById(new Set<Id>{Id.valueOf(UserInfo.getUserId())})).thenReturn(new List<User>{usertest});
        mocks.when(selectorSCMock.selectByName(usertest.Service_Center__c)).thenReturn(new List<Service_Center__c>{theSC});
        mocks.stopStubbing();
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        Application.Selector.setMock(selectorSCMock);
        Application.Selector.setMock(selectorAccountMock);
        Application.Selector.setMock(selectorUserMock);

        // When
        CloneSalesOrderController controller = new CloneSalesOrderController(standardController);
        List<SelectOption> selectOptions = controller.lstConvertTo;
        //String sc = controller.selServiceCenter;
        CloneSalesOrderController.getData(salesOrder.Id);

    }

    private class MyException extends Exception {
    }
    //test1
}