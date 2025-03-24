@IsTest
private class AccountsSelectorTest {

    @IsTest
    private static void test(){
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
        Salesperson__c sp = new Salesperson__c(
                Name = 'London Postmaster',
                Account_Executive__c = true,
                First_Name__c = 'firstname',
                Last_Name__c = 'lastname',
                Status__c = 'Active',
                Salesperson_Code__c = '88766543fhjk',
                User__c = UserInfo.getUserId()
        );
        insert sp;
        Subsidiary_Company__c subC = new Subsidiary_Company__c(
                Name = '1-REPUBLIC SERVICES',
                Display_Name__c = 'SO'
        );
        insert subC;
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
        account.Subsidiary_Company__c = subC.Id;
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        insert account;

        AccountsSelector selector = new AccountsSelector();
        selector.selectBillingInstructionsById(new Set<Id>{account.Id});
    }

}