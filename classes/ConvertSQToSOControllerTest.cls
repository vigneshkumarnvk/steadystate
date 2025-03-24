@IsTest
private class ConvertSQToSOControllerTest {
    
    @IsTest
    private static void test(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        
        mocks.startStubbing();
        Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL');
        Insert acc;
        Sales_Order__c theSO = new Sales_Order__c(
            Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
            Document_Type__c = 'Sales Order',Bill_to_Customer_No__c = acc.Id,Customer_PO_No__c ='a23453'
        );
        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSOMock.selectConvertRelatedFieldsById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(serviceSOMock.convertQuoteToOrder(new Set<Id>{theSO.Id})).thenReturn(theSO.Id);
        mocks.stopStubbing();
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        //test
        CovertSalesQuoteToSalesOrderController controller = new CovertSalesQuoteToSalesOrderController(standardController);
        Test.setMock(HttpCalloutMock.class, new workOrderQuoteServiceTest());
        controller.convertQuoteToOrder();
        controller.getConvertMessages();
        Boolean bool = controller.allowConvertToOrder;
    }
    
    @IsTest
    private static void testExceptionAndErrors(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Mocks.SalesOrdersService serviceSOMock = new Mocks.SalesOrdersService(mocks);
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        
        mocks.startStubbing();
        Id soId= fflib_IDGenerator.generate(Sales_Order__c.SObjectType);
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='Subsidiary Company1');
        insert subsidiaryCompany;
        Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id);
        insert serviceCenter;
        Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
        insert salesPerson;
        Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id);
        insert acc;
        String prospectId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
        String jsonStr = '{ "Id" : "' + soId + '" , "Bill_to_Customer_No__r" : {"RecordTYpeId" : "' + prospectId + '","id":"'+ acc.id +'"}, "Allow_Convert__c" : false, "Document_Type__c" : "Sales Quote", "Customer_PO_No__c":"a1234","Blocked__c": true}';
        Sales_Order__c theSO = (Sales_Order__c) JSON.deserialize(jsonStr, Sales_Order__c.class);
        theSO.Bill_to_Customer_No__c = acc.id;
        
        ApexPages.StandardController standardController = new ApexPages.StandardController(theSO);
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorSOMock.selectConvertRelatedFieldsById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        //mocks.when(serviceSOMock.convertQuoteToOrder(new Set<Id>{theSO.Id})).thenThrow(new MyException('heh'));
        mocks.stopStubbing();
        Application.Service.setMock(ISalesOrdersService.class, serviceSOMock);
        Application.Selector.setMock(selectorSOMock);
        
        CovertSalesQuoteToSalesOrderController controller = new CovertSalesQuoteToSalesOrderController(standardController);
        Test.setMock(HttpCalloutMock.class, new workOrderQuoteServiceTest());
        controller.convertQuoteToOrder();
        controller.getConvertMessages();
    }
    
    
    @isTest
    static void testPerformWorkOrderQuoteHeaderInfoCallout() {
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='Subsidiary Company1');
        insert subsidiaryCompany;
        Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id);
        insert serviceCenter;
        Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
        insert salesPerson;
        Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id);
        insert acc;
        
        Sales_Order__c salesQuote = new Sales_Order__c(Name='Test1');
        salesQuote.Subsidiary_Company__c = subsidiaryCompany.id;
        salesQuote.Bill_to_Customer_No__c = acc.id;
        salesQuote.Project_Coordinator__c = salesPerson.id;
        salesQuote.Service_Center__c = serviceCenter.id;
        salesQuote.Surcharge_Type__c = 'EEC Fee';
        salesQuote.Customer_PO_No__c = '123456';
        insert salesQuote;
        
        Test.startTest();
        CovertSalesQuoteToSalesOrderController.performWorkOrderQuoteHeaderInfoCallout(salesQuote.id);
        Test.stopTest();
    }
    
    @isTest
    static void testConvertQuoteToOrder() {
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='Subsidiary Company1');
        insert subsidiaryCompany;
        Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id);
        insert serviceCenter;
        Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
        insert salesPerson;
        Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id);
        insert acc;
        
        Sales_Order__c salesQuote = new Sales_Order__c(Name='Quote-Test1');
        salesQuote.Subsidiary_Company__c = subsidiaryCompany.id;
        salesQuote.Bill_to_Customer_No__c = acc.id;
        salesQuote.Project_Coordinator__c = salesPerson.id;
        salesQuote.Service_Center__c = serviceCenter.id;
        salesQuote.Surcharge_Type__c = 'EEC Fee';
        salesQuote.Customer_PO_No__c = '123421321';
        insert salesQuote;
        
        ApexPages.StandardController standardController = new ApexPages.StandardController(salesQuote);
        CovertSalesQuoteToSalesOrderController controller = new CovertSalesQuoteToSalesOrderController(standardController);
        
        Test.startTest();
        controller.convertQuoteToOrder();
        Test.stopTest();
    }
    
    @IsTest
    private static void testWithEmergencySO(){
        
        Subsidiary_Company__c subsidiaryCompany = new Subsidiary_Company__c(Name='Subsidiary Company1');
        insert subsidiaryCompany;
        Service_Center__c serviceCenter = new Service_Center__c(Name='12', Code__c='12345', Subsidiary_Company__c=subsidiaryCompany.id,Include_SO_in_EQAI_Invoice_Integration__c =true);
        insert serviceCenter;
        Salesperson__c salesPerson = new SalesPerson__c(Name='Salesperson1', Salesperson_Code__c='1', Status__c='Active');
        insert salesPerson;
        Account acc = new Account(name ='Test Account',PO_Number_Type__c ='NUMERICAL', AccountNumber='123dfsa', Subsidiary_Company__c=subsidiaryCompany.id,Emergency__c = true);
        insert acc;
        
        Sales_Order__c salesQuote = new Sales_Order__c(Name='Quote-Test1');
        salesQuote.Subsidiary_Company__c = subsidiaryCompany.id;
        salesQuote.Bill_to_Customer_No__c = acc.id;
        salesQuote.Project_Coordinator__c = salesPerson.id;
        salesQuote.Service_Center__c = serviceCenter.id;
        salesQuote.Surcharge_Type__c = 'EEC Fee';
        salesQuote.Customer_PO_No__c = '123421321';
        insert salesQuote;
        system.debug('salesQuote'+salesQuote);
        
        ApexPages.StandardController standardController = new ApexPages.StandardController(salesQuote);
        CovertSalesQuoteToSalesOrderController controller = new CovertSalesQuoteToSalesOrderController(standardController);
        
        Test.startTest();
        controller.convertQuoteToOrder();
        salesQuote.Is_New_D365_Project__c = false;
        update salesQuote;
        acc.Sage_Customer_No__c = '12345';
        update acc;
        controller.convertQuoteToOrder();
        controller.getConvertMessages();
        Test.stopTest();
    }
    //test1
    
    class MyException extends Exception{}
}