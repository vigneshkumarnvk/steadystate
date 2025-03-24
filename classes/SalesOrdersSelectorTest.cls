@IsTest
private class SalesOrdersSelectorTest {

    @IsTest
    private static void test() {

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


        Service_Center__c sc = new Service_Center__c(
                Name = '01',
                Description__c = 'SC01 Elizabeth, NJ Ops',
                Subsidiary_Company__c = subC.Id,
                //TM_No_Series__c = theNumberingSeries.Id,
                //Sales_Order_No_Series__c = theNumberingSeries.Id,
                //Sales_Order_No_Series__c = '',
                Max_No_of_Emergency_T_M__c = 2,
                Code__c = '01',
                City__c = 'Elizabeth',
                Street__c = '201 South First St.',
                Postal_Code__c = '07206',
                State__c = 'NJ',
                Country__c = 'US',
                Temporary__c = true

        );
        insert sc;
        Sales_Order_Type__c sot = new Sales_Order_Type__c(Description__c = 'test description');
        insert sot;
        Sales_Order__c theSO = new Sales_Order__c(
                Bill_to_Customer_No__c = account.Id,
                Payment_Term__c = pt.Id,
                Name = 'Test',
                Service_Center__c = sc.Id,
                Sales_Order_Type__c = sot.Id,
                Subsidiary_Company__c = subC.Id,
                Project_Coordinator__c = sp.Id,
                Surcharge_Type__c = 'N/A'
        );
        insert theSO;

        Sales_Line__c salesLine = new Sales_Line__c(
                Sales_Order__c = theSO.Id,
                Line_No__c = 1,
                Description__c = 'Test item',
                Quantity__c = 1100,
                UOM_Qty__c = 10,
                Regular_Hours__c = 4,
                Overtime_Hours__c= 3,
                Premium_Hours__c = 3,
                Regular_Day__c = 1,
                Overtime_Day__c= 1,
                Premium_Day__c = 1,
                Number_of_Day__c = 3,
                Category__c = 'Labor',
                Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id,
                Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id
        );
        insert salesLine;

        SalesOrdersSelector selector = new SalesOrdersSelector();
        selector.selectById(new Set<Id>{theSO.Id});
        selector.selectCreateInvoiceRequiredFieldsById(new Set<Id>{theSO.Id});
        selector.selectByIdWithLinesForClone(new Set<Id>{theSO.Id});
        selector.selectConvertRelatedFieldsById(new Set<Id>{theSO.Id});
        selector.selectTMsById(new Set<Id>{theSO.Id});
        selector.selectServiceCenterById(new Set<Id>{theSO.Id});
        selector.selectServiceCenterAndSubCompanyById(new Set<Id>{theSO.Id});
        selector.selectQuotesByBillToCustomer(account.Id);
        selector.selectConvertCountById(new Set<Id>{theSO.Id});
    }
}