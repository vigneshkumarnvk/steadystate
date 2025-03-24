@IsTest
private class TMLinesSelectorTest {

    @IsTest
    private static void test(){
        Company_Setup__c companySetup = new Company_Setup__c(

                Name = 'Default',
                Lines_to_Insert__c = 5,
                Allow_Posting_From__c = Date.newInstance(2015, 1, 1),
                Allow_Posting_To__c = Date.newInstance(2019, 1, 1)
        );
        insert companySetup;

        Numbering_Series__c theNS;
        List<Numbering_Series__c> theNSList = new List<Numbering_Series__c>();

        theNS = new Numbering_Series__c();
        theNS.Name = 'JOB01';
        theNS.Prefix__c = 'NJ';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'PO Temp Number';
        theNS.Prefix__c = 'PO';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Purchase Order';
        theNS.Prefix__c = 'PO';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Purchase Receipt';
        theNS.Prefix__c = 'PR';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Return Purchase Order';
        theNS.Prefix__c = 'PRO';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Sales Invoice';
        theNS.Prefix__c = 'SI';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Credit Memo';
        theNS.Prefix__c = 'CR';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Sales Order';
        theNS.Prefix__c = 'SO';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'SC01 TM No.';
        theNS.Prefix__c = 'TMEL';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'T&M';
        theNS.Prefix__c = 'TM';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Timesheet';
        theNS.Prefix__c = 'T';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Payroll';
        theNS.Prefix__c = 'P';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Contract Line';
        theNS.Prefix__c = 'CL';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Rental Order';
        theNS.Prefix__c = 'RO';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        theNS = new Numbering_Series__c();
        theNS.Name = 'Contract Line';
        theNS.Prefix__c = 'CL';
        theNS.Separator__c = '-';
        theNS.Last_Number_Used__c = 1000000;
        theNSList.add(theNS);

        insert theNSList;

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
                TM_No_Series__c = theNSList[0].Id,
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

        TM__c theTM = new TM__c(
                Bill_to_Customer__c = account.Id,
                Project_Coordinator__c = sp.Id,
                Account_Executive__c = sp.Id,
                Prevailing_Wage_Job__c = true,
                Certified_PW_Job__c = true,
                Service_Center__c = sc.Id,
                Subsidiary_Company__c = subC.Id,
                Tax_Area__c = ta.Id,
                Sales_Order__c = theSO.Id,
                Scheduled_Date__c = Date.today().addDays(-7),
                Status__c = 'Open'
        );
        insert theTM;

        Unit_of_Measure__c uom = new Unit_of_Measure__c( Name = 'Day',  Description__c = 'Area' );
        insert uom;

        Resource_Type__c rt = new Resource_Type__c(
                Name = 'Field Tech',
                Description__c = 'Field Tech',
                Category__c = 'Labor',
                Unit_of_Measure__c = uom.id
        );
        insert rt;

        Resource__c r = new Resource__c(
                Name = 'TR7',
                Fleet_Number__c = 'TR7',
                Status__c = 'Active',
                Plate_Number__c = 'TDF19P',
                Plate_State__c = 'NJ',
                Make__c = 'Car Mate',
                //Ticket 13360 >>
                //Vehicle_Year__c = 2000,
                //Ticket 13360 <<
                VIN__c = '5A3U616D1YL005502',
                Country__c = 'US',
                Subsidiary_Company__c = subC.Id,
                Service_Center__c = sc.Id,
                Rent_Company__c = 'CVI',
                Resource_Type__c = rt.Id,
                Category__c = 'Labor',
                Unit_of_Measure__c = uom.id,
                Employee_Type__c = 'Employee' ,
                Non_Payroll_Labor_Resource__c = false
        );
        insert r;

        TM_Line__c theTML = new TM_Line__c(
                Line_No__c = 1,
                Description__c = 'Test item',
                Quantity__c = 1650,
                Category__c = 'Labor',
                TM__c = theTM.Id,
                Resource_Type__c = rt.Id,
                Service_Center__c = sc.Id,
                Resource__c = r.Id,
                Total_Site_Hours__c = 1650,
                Regular_Hours__c = 550,
                Regular_Rate__c = 1,
                Overtime_Rate__c = 1,
                Overtime_Hours__c = 550,
                Premium_Hours__c = 550,
                Premium_Rate__c = 1,
                Unit_Price__c = 1,
                Hour__c = 1650,
                Tax_Group__c = 'TX',
                Unit_of_Measure__c = uom.Id, //Added to add missing field
                Job_Start_Time__c = System.now().addHours(-8).time(),
                Job_End_Time__c = System.now().time()
        );
        insert theTML;
        Test.startTest();
        TMLinesSelector selector = new TMLinesSelector();
        selector.selectSObjectsById(new Set<Id>{theTML.Id});
        selector.selectTMLMapWithResourceTypeAndResourceById(new Set<Id>{theTML.Id});
        selector.selectTMLMapWithUnitOfMeasureById(new Set<Id>{theTML.Id});
        selector.selectInterCompanyLineByScheduledDateRange(Date.today(), Date.today());
        selector.selectSafetyPlanLineByTMId(new Set<Id>{theTML.Id}, r.Id);
        selector.selectCreateInvoiceRequiredFieldsById(new Set<Id>{theTML.Id});
        selector.selectAwayServiceCenterLinesByScheduledDateServiceCenterAndCategory(Date.today(), sc.Name, 'Labor');
        selector.selectByTmId(new Set<Id>{theTM.Id});
        selector.selectByTmId(new Set<Id>{theTM.Id}, null);
        selector.selectWithFlatPaysByTmId(new Set<Id>{theTM.Id}, null);
        selector.selectTMLinesByCategory(theTM.Id, sc.Id, 'Labor');
        List<TM_Line__c> tmLines = TMLinesSelector.newInstance().selectByIds(new Set<Id>{theTML.Id});

        Test.stopTest();
    }
}