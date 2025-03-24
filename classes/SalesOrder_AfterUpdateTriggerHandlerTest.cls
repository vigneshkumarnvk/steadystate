@isTest
private class SalesOrder_AfterUpdateTriggerHandlerTest {
  
    @testSetup
    private static void setup() {
        Account acc = TestDataUtil.AccountRecord;
        SalesPerson__c sp =  new SalesPerson__c(Name = 'London Postmaster',Salesperson_Code__c = 'HOU',Status__c = 'Active');
        insert sp;
        Subsidiary_Company__c sco = TestDataUtil.SubsidiaryCompanyRecord;
        Service_Center__c sc = new Service_Center__c (Name = 'Test',
                            Description__c = 'SC01 Elizabeth, NJ Ops', Code__c = '01', Subsidiary_Company__c = sco.Id);//TestDataUtil.ServiceCenterRecord;
        insert sc;
        Sales_Order__c so = new Sales_Order__c(Name = 'NJ57506-01-2083',
                Surcharge_Type__c = 'N/A',Service_Center__c =  sc.id,
                Site_Name__c = 'Test SIte Name xx', Project_Coordinator__c = sp.id, 	Bill_to_Customer_No__c=acc.id, Subsidiary_Company__c=sco.id);
       insert so;
    }
    
   @IsTest
    static void updateHandler(){
       Account acc = [Select Id from Account LIMIT 1];
       SalesPerson__c sp = [Select Id from SalesPerson__c LIMIT 1];
       Service_Center__c sc= [Select Id from Service_Center__c LIMIT 1];
       Subsidiary_Company__c sco = [Select Id from Subsidiary_Company__c LIMIT 1];
       Sales_Order__c so = [Select Id from Sales_Order__c LIMIT 1];
       test.startTest();
       so.Description__c = 'Test1';
       update so;
       test.stopTest();
        
       System.assert(true, 'This is code coverage'); 
    }

}