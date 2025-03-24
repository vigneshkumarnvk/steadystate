@isTest
public with sharing class AccountControllerTest {
    
    @testSetup static void SetupData() {
        //Setup Data//83014
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c testNumberSeriesRecord = TestDataUtil.NumberingSeriesRecord;
        User testUser = TestDataUtil.UserRecord;
        Account testAccRecord = TestDataUtil.AccountRecord;
        Account testAccRecord3 = TestDataUtil.customerAccountRecord;
        Subsidiary_Company__c testSubsidiaryCompRecord = TestDataUtil.SubsidiaryCompanyRecord;
        Service_Center__c testServiceCenRecord = TestDataUtil.ServiceCenterRecord;
        OrganizationConfigurations__c testOrgConfigRecord = TestDataUtil.OrganizationConfigurationsRecord;
        Salesperson__c testSalesperRecord = TestDataUtil.SalespersonRecord;
        if ([SELECT Id FROM Group WHERE Name = 'Data Admin'].size() == 0) {
        	Group testGroupRecord = TestDataUtil.GroupRecord;
        	GroupMember testGroupMemberRecord = TestDataUtil.GroupMemberRecord;
        }
        List<Accounting_Period__c> testAccountingPerRecords = TestDataUtil.AccountingPeriodRecords;
        Sales_Order_Type__c testSalesOrdtypeRecord = TestDataUtil.SalesOrdertypeRecord;
        List<Customer_Ledger_Entry__c> testCustomerLedgerEntryRecords = TestDataUtil.CustomerLedgerEntryRecords;
    }

    public static testMethod void test() {
		Account testAccRecord = [SELECT Id FROM Account WHERE Name LIKE :'%Cannon%' Limit 1];
        PageReference pageRef = Page.AccountConversion;
        ApexPages.StandardController sc = new ApexPages.standardController(testAccRecord);
        AccountController controller = new AccountController(sc);
                
        test.startTest();
        try {
            Test.setCurrentPage(pageRef);
            pageRef.getParameters().put('id', testAccRecord.id);
            testAccRecord.Type = 'Customer';
            controller.ConvertToCustomer();
            User theUser = [SELECT Id, FirstName, LastName, Phone, Service_Center__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            theUser.Service_Center__c='SC01 Elizabeth, NJ Ops';
            update theUser ;
            
        } catch (exception ex) {
        }
        
        Subsidiary_Company__c subsidiaryCompany = [SELECT Id FROM Subsidiary_Company__c Limit 1];
        Service_Center__c serviceCenter = [SELECT Id FROM Service_Center__c Limit 1];
        
        testAccRecord.Type = 'Account';
        testAccRecord.Subsidiary_Company__c = subsidiaryCompany.Id;
        testAccRecord.Service_Center__c = serviceCenter.Id;
        update testAccRecord;        
        sc = new ApexPages.standardController(testAccRecord);
        controller = new AccountController(sc);
        
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('id', testAccRecord.id);
        controller.ValidateServiceCenter();
        controller.SalesOrderTypeId =TestDataUtil.SalesOrdertypeRecord.id;
        controller.ownerId = UserInfo.getUserId();
        controller.CreateSO();

        controller.CreateSQ();       
        controller.CreateMiscCreditMemo();
        controller.SetSalesOrderType();
        controller.getMessages();
        System.debug('Info: ' + controller.getMessages());
        controller.returnBack();

        controller.getItems();
        controller.setSurchargeType('E&I Surcharge');
        test.stopTest();     
    }
    
    private static testMethod void testRollup() {
        Subsidiary_Company__c subsidiaryCompany = [Select Id From Subsidiary_Company__c Limit 1];
        Service_Center__c serviceCenter = [Select Id From Service_Center__c Limit 1];

        Accounting_Period__c testAccPer = [SELECT Id, Start_Date__c, End_Date__c FROM Accounting_Period__c LIMIT 1];
        testAccPer.Start_Date__c = System.today() -1;
        testAccPer.End_Date__c = System.today() +1;
        testAccPer.Fiscal_year__c = System.today().year();
        update testAccPer; 
        
        Salesperson__c testSalesperson = [SELECT Id, Name,Salesperson_Code__c, Status__c FROM Salesperson__c];
        testSalesperson.Name = 'Smith'; 
        testSalesperson.Salesperson_Code__c = 'S001'; 
        testSalesperson.Status__c='Active';
        update testSalesperson;
        
        List<Customer_Ledger_Entry__c> customerLedgerEntries = [SELECT Id, Due_Date__c, Posting_Date__c FROM Customer_Ledger_Entry__c];
        for(Customer_Ledger_Entry__c customerLedgerEntry : customerLedgerEntries) {
            customerLedgerEntry.Due_Date__c = System.today();
            customerLedgerEntry.Posting_Date__c = System.today();
        }
        update customerLedgerEntries;
        
        Test.startTest();        
        Database.executeBatch(new RollupCustomerARBatchable());  
        Database.executeBatch(new RollupCustomerRevenueBatchable());
        Database.executeBatch(new RollupCorporateARBatchable());
        Database.executeBatch(new RollupCustomerRevenueBatch());
        Test.stopTest();
    }

    static testMethod void testValidateField(){
		Subsidiary_Company__c subsidiaryCompany = [Select Id From Subsidiary_Company__c Limit 1];
        Service_Center__c serviceCenter = [Select Id From Service_Center__c Limit 1];
		Salesperson__c testSalesperson = [SELECT Id FROM Salesperson__c];
		Subsidiary_Company__c testComp = [SELECT Id FROM Subsidiary_Company__c];
        Sales_Order_Type__c testSalOrdType = [SELECT Id FROM Sales_Order_Type__c Limit 1];

        Account testAcc = [SELECT Id FROM Account WHERE Type = 'Customer' Limit 1];
        PageReference pref = Page.CreateSQFromAccountConfirmation;
        PageReference pageRef = Page.AccountConversion;

        ApexPages.StandardController sc = new ApexPages.standardController(testAcc);
        AccountController controller = new AccountController(sc);
        Test.startTest();

        Test.setCurrentPage(pref);
        pref.getParameters().put('id', testAcc.id);

        pref.getParameters().put('fieldName', 'targetNameWH');
        pref.getParameters().put('newFieldValue','awefawe');
        controller.validateField();
        pref.getParameters().put('fieldName', 'ja;efj');
        pref.getParameters().put('newFieldValue','awefawe');
        controller.validateField();
        pref.getParameters().put('fieldName', 'targetNameWH');
        pref.getParameters().put('newFieldValue',testSalOrdType.Id);
        controller.validateField();
        
        pref.getParameters().put('fieldName', 'targetOwner');
        pref.getParameters().put('newFieldValue', 'awefa');
        controller.validateField();

        Test.setCurrentPage(pageRef);
        pref.getParameters().put('id', testAcc.id);
        testAcc.Type = 'Customer';
        controller.ConvertToCustomer();
        Test.stopTest();

    }
    //test
}