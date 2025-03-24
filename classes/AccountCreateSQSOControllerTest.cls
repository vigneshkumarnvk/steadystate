@IsTest
private class AccountCreateSQSOControllerTest {

    @IsTest
    private static void test(){
        //Create Mock
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        IAccountsSelector selectorAccountMock = new Mocks.AccountsSelector(mocks);
        IContractsSelector selectorContractMock = new Mocks.ContractsSelector(mocks);
        IUsersSelector selectorUserMock = new Mocks.UsersSelector(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);

        mocks.startStubbing();
        Account parentAcct = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType)
        );
        Account acct = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                ParentId = parentAcct.Id
        );

        Id contractId = fflib_IDGenerator.generate(Contract.SObjectType);
        String jsonStr = '{"Id" : "' + contractId + '", "Name" : "Test Contract", "ContractNumber" : "998"}';
        Contract contra = (Contract) JSON.deserialize(jsonStr, Contract.class);
        User u = new User(
                Service_Center__c = fflib_IDGenerator.generate(Service_Center__c.SObjectType)
        );
        Sales_Order__c  theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Name = 'test sales order'
        );
        ApexPages.StandardController standardController = new ApexPages.StandardController(acct);
        mocks.when(selectorAccountMock.sObjectType()).thenReturn(Account.SObjectType);
        mocks.when(selectorContractMock.sObjectType()).thenReturn(Contract.SObjectType);
        mocks.when(selectorUserMock.sObjectType()).thenReturn(User.SObjectType);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorAccountMock.selectParentAccountById(new Set<Id>{acct.Id})).thenReturn(new List<Account>{acct});
        mocks.when(selectorContractMock.selectByAccountId(new Set<Id>{acct.Id, parentAcct.Id})).thenReturnMulti(new List<List<Contract>>{new List<Contract>{contra}, new List<Contract>()});
        mocks.when(selectorSOMock.selectQuotesByBillToCustomer(acct.Id)).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorUserMock.selectById(new Set<Id>{UserInfo.getUserId()})).thenReturn(new List<User>{u});
        mocks.stopStubbing();
        Application.Selector.setMock(selectorAccountMock);
        Application.Selector.setMock(selectorContractMock);
        Application.Selector.setMock(selectorUserMock);
        Application.Selector.setMock(selectorSOMock);

        AccountCreateSalesQuoteOrOrderController controller = new AccountCreateSalesQuoteOrOrderController(standardController);
        controller.checkAccountContractBeforeRenderPage();
        AccountCreateSalesQuoteOrOrderController controller2 = new AccountCreateSalesQuoteOrOrderController(standardController);
        controller2.checkAccountContractBeforeRenderPage();
    }

}