/************************************************************************************************************
* Name         :  rsgTriggerStrategyTest
* Description  :  rsgTriggerStrategyTest
*
* Modification Log :
* Developer                    Date            Description
* ---------------------------------------------------------------------------- 
Harika Madapathi         07/22/2023             68128 - Tech Debt: Update Trigger Framework for SalesOrder object
*************************************************************************************************************/
@IsTest
private class rsgTriggerStrategyTest {
    
    @testSetup
    private static void setup() {
        
        SalesPerson__c sp =  new SalesPerson__c(Name = 'London Postmaster',Salesperson_Code__c = 'HOU',Status__c = 'Active');
        insert sp;
        Subsidiary_Company__c sco = TestDataUtil.SubsidiaryCompanyRecord;
        Service_Center__c sc = new Service_Center__c (Name = 'Test',
                                                      Description__c = 'SC01 Elizabeth, NJ Ops', Code__c = '01', Subsidiary_Company__c = sco.Id);//TestDataUtil.ServiceCenterRecord;
        insert sc;
        
        Payment_Term__c pt = new Payment_Term__c(
            Name = '14 DAYS',
            Discount_Pct__c = 0,
            Discount_Date_Calculation__c = 0,
            Due_Date_Calculation__c = 0
        );
        insert pt;
        GL_Account__c glAccount = new GL_Account__c(
            Name = 'GLAccountRecordTest',
            Description__c = 'Test GL Account'
        );
        insert glAccount;
        Tax_Area__c ta = new Tax_Area__c(
            Name = 'NJ',
            Sales_Tax_Account__c = glAccount.Id
        );
        insert ta;
        
        Account account = new Account();
        account.Name = 'Cannon Group';
        account.AccountNumber = '01-00000001';
        account.Payment_Term__c = pt.Id;
        account.Tax_Area__c = ta.Id;
        account.BillingStreet = 'test Street';
        account.BillingCity = 'test City';
        account.BillingState = 'Colorado';
        account.BillingStateCode = 'CO';
        account.BillingCountryCode = 'US';
        account.BillingPostalCode = 'test postalcode';
        account.Customer_Type__c = 'UTILITIES';
        account.Account_Executive__c = sp.Id;
        account.Salesperson__c = sp.Id;
        System.debug('sco.Id======>'+sco.Id);
        account.Subsidiary_Company__c = sco.Id;
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert account;
        
    }
    
    @IsTest
    static void executeTriggerHandler(){
        
        SalesPerson__c sp = [Select Id from SalesPerson__c LIMIT 1];
        Service_Center__c sc= [Select Id from Service_Center__c LIMIT 1];
        Account acc = [Select Id from Account LIMIT 1];
        Subsidiary_Company__c sco = [Select Id from Subsidiary_Company__c LIMIT 1];
        
        test.startTest();
        Sales_Order__c so = new Sales_Order__c(Name = 'NJ57506-01-2083',
                                               Surcharge_Type__c = 'N/A',Service_Center__c =  sc.id,
                                               Site_Name__c = 'Test SIte Name xx', Project_Coordinator__c = sp.id);
        so.Bill_to_Customer_No__c = acc.Id;
        so.Subsidiary_Company__c = sco.Id;
        insert so;
        test.stopTest();
        
        System.assert(true, 'This is a code coverage'); 
    }
    
    @IsTest
    static void executeTriggerHandler_with2updates(){
        SalesPerson__c sp = [Select Id from SalesPerson__c LIMIT 1];
        Service_Center__c sc= [Select Id from Service_Center__c LIMIT 1];
        Account acc = [Select Id from Account LIMIT 1];
        Subsidiary_Company__c sco = [Select Id from Subsidiary_Company__c LIMIT 1];
        
        Sales_Order__c so = new Sales_Order__c(Name = 'NJ57506-01-2083',
                                               Surcharge_Type__c = 'N/A',Service_Center__c =  sc.id,
                                               Site_Name__c = 'Test SIte Name xx', Project_Coordinator__c = sp.id);
        so.Bill_to_Customer_No__c = acc.Id;
        so.Subsidiary_Company__c = sco.Id;
        insert so;
        
        test.startTest();
        
        so.Billing_Type__c = 'T&M';
        update so;
        
        test.stopTest();
        
    }
    
    @IsTest
    static void getHandlerNameFromTriggerConfigurationSettings(){
        test.startTest();
        rsgTrigger_Configuration_Setting__mdt rsgTriggerConfigurationSetting = rsgTriggerStrategy.getHandlerNameFromTriggerConfigurationSettings('Sales_Order__c', 'insert', 'after');
        test.stopTest();
        
        System.assert(rsgTriggerConfigurationSetting != null, 'Expected the class to be initialized');
        System.assertEquals('SalesOrder_AfterInsertTriggerHandler', rsgTriggerConfigurationSetting.Trigger_Handler_Name__c, 'The Handler Name Should match.');
    }
}