@isTest
private class SalesBudgetControllerTest {
    static testMethod void test() {
        Test.startTest();

        Salesperson__c sp = new Salesperson__c(Name = 'Smith', Salesperson_Code__c = 'S0001', Account_Executive__c = true, Status__c='Active');
        insert sp;

        Subsidiary_Company__c company = new Subsidiary_Company__c(Name = 'ACV');
        insert company;
                        
        Account customer = new Account(Name = 'Test', AccountNumber = '00-1001706', Type = 'Customer', BillingStreet = '123 ABC Ave', BillingCity = 'New York', BillingStateCode = 'NY', BillingPostalCode = '12345', BillingCountryCode = 'US', Customer_Type__c = 'OTHER', Account_Executive__c = sp.Id, Salesperson__c = sp.Id, Subsidiary_Company__c = company.Id);
        insert customer;
  
        List<Sales_Budget__c> buds = new List<Sales_budget__c>();
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(buds);
        SalesBudgetController controller = new SalesBudgetController(sc);
        Test.setCurrentPage(Page.SalesBudgetImport);
        controller.Year = '2018';
        String csv = 'Customer,Account Executive,Salesperson,Sales Budget 1,Sales Budget 2,Sales Budget 3,Sales Budget 4,Sales Budget 5,Sales Budget 6,Sales Budget 7,Sales Budget 8,Sales Budget 9,Sales Budget 10,Sales Budget 11,Sales Budget 12\n' +
                     '00-1001706,TBD (Clayton),TBD,0.00,"2,518.75","31,525.36",0.00,0.00,0.00,0.00,"1,094.65",0.00,714.30,"6,344.86",0.00';
        controller.data = Blob.valueOf(csv);
        try {
            controller.Import();
        }
        catch(exception ex) {
        }

        csv = 'Customer,Account Executive,Salesperson,Sales Budget 1,Sales Budget 2,Sales Budget 3,Sales Budget 4,Sales Budget 5,Sales Budget 6,Sales Budget 7,Sales Budget 8,Sales Budget 9,Sales Budget 10,Sales Budget 11,Sales Budget 12\n' +
                     'XXXXXXXXXX,TBD (Clayton),TBD,0.00,"2,518.75","31,525.36",0.00,0.00,0.00,0.00,"1,094.65",0.00,714.30,"6,344.86",0.00';
        controller.data = Blob.valueOf(csv);
        try {
            controller.Import();
        }
        catch(exception ex) {
        }
                             
        Test.stopTest();
    }
}