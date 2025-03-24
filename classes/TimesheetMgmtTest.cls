@isTest
public class TimesheetMgmtTest {
    /*
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    public static Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
    */
    @testSetup static void SetupData() {
        //Setup Data
        /*
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
        */

        Numbering_Series__c theNS = new Numbering_Series__c();
        List<Numbering_Series__c> theNSList = new List<Numbering_Series__c>();
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

        insert theNSList;

        Subsidiary_Company__c subsidiaryCompany =
                new Subsidiary_Company__c(
            Name = '1-REPUBLIC SERVICES',
            Display_Name__c = 'REPUBLIC SERVICES'
        );
        insert subsidiaryCompany;


        Salesperson__c salesperson = new Salesperson__c(
            Name = 'SP01',
            Account_Executive__c = true,
            First_Name__c = 'firstname',
            Last_Name__c = 'lastname',
            Status__c = 'Active',
            Salesperson_Code__c = '88766543fhjk',
            User__c = UserInfo.getUserId()
        );
        insert salesperson;

        Unit_of_Measure__c unitOfMeasure = new Unit_of_Measure__c(
            Name = 'HR',
            Hours_UOM__c = true,
            Description__c = 'Hour');
        insert unitOfMeasure;

        Resource_Type__c resourceType = new Resource_Type__c(
            Name = 'Field Technician',
            Description__c = 'Field Technician',
            Category__c = 'Labor',
            Unit_of_Measure__c = unitOfMeasure.Id
        );
        insert resourceType;

        Resource_Type__c equipmentResourceType = new Resource_Type__c(
                Name = 'Bobcat',
                Description__c = 'Bobcat',
                Category__c = 'Equipment',
                Unit_of_Measure__c = unitOfMeasure.Id
        );
        insert equipmentResourceType;

        List<Off_Type__c> offTypes = new List<Off_Type__c>();
        Off_Type__c offType = new Off_Type__c (
                Name = 'Shop Time',
                Equipment__c = false,
                Map_to_Time_Type__c = 'Shop Time'
        );
        offTypes.add(offType);

        offType = new Off_Type__c (
                Name = 'Holiday',
                Equipment__c = false,
                Map_to_Time_Type__c = 'Other'
        );
        offTypes.add(offType);

        insert offTypes;

        Payment_Term__c paymentTerm = new Payment_Term__c(
            Name = '30 DAYS',
            Discount_Pct__c = 0,
            Discount_Date_Calculation__c = 0,
            Due_Date_Calculation__c = 0
        );
        insert paymentTerm;

        GL_Account__c glAccount = new GL_Account__c(
            Name = 'Test'
        );
        insert glAccount;

        Tax_Area__c taxArea = new Tax_Area__c(
            Name = 'NJ',
            Sales_Tax_Account__c = glAccount.Id
        );
        insert taxArea;

        Account acc = new Account(
            Name = 'Test',
            Payment_Term__c = paymentTerm.Id,
            Tax_Area__c = taxArea.Id,
            AccountNumber = '01-00000001',
            BillingStreet = 'test Street',
            BillingCity = 'test City',
            BillingState = 'Colorado',
            BillingStateCode = 'CO',
            BillingCountryCode = 'US',
            BillingPostalCode = 'test postalcode',
            Customer_Type__c = 'UTILITIES',
            Account_Executive__c = salesperson.Id,
            Salesperson__c = salesperson.Id,
            Subsidiary_Company__c = subsidiaryCompany.Id,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId()
        );
        insert acc;


        Numbering_Series__c tmNumberingSeries = [SELECT Id FROM Numbering_Series__c WHERE Name = 'SC01 TM No.'];
        Numbering_Series__c soNumberingSeries = [SELECT Id FROM Numbering_Series__c WHERE Name = 'Sales Order'];
        Service_Center__c serviceCenter = /*[SELECT Id FROM Service_Center__c WHERE Name = '01' LIMIT 1];*/

                new Service_Center__c(
            Name = '01',
            Subsidiary_Company__c = subsidiaryCompany.Id,
            Description__c = 'SC01 Elizabeth, NJ Ops',
            TM_No_Series__c = tmNumberingSeries.Id,
            Sales_Order_No_Series__c = soNumberingSeries.Id,
            Max_No_of_Emergency_T_M__c = 2,
            Code__c = '01',
            City__c = 'Elizabeth',
            Street__c = '201 South First St.',
            Postal_Code__c = '07206',
            State__c = 'NJ',
            Country__c = 'US'
        );
        upsert serviceCenter;

        Sales_Order_Type__c salesOrderType = new Sales_Order_Type__c(Description__c = 'test description');
        insert salesOrderType;

        Sales_Order__c salesOrder = new Sales_Order__c(
            Name = 'NJ57506-01-2080',
            Bill_to_Customer_No__c = acc.Id,
            Service_Center__c = serviceCenter.Id,
            Sales_Order_Type__c = salesOrderType.Id,
            Subsidiary_Company__c = subsidiaryCompany.Id,
            Project_Coordinator__c = salesperson.Id,
            Surcharge_Type__c = 'N/A'
        );
        insert salesOrder;

        List<Pay_Rule__c> payRuleLst = new List<Pay_Rule__c>();
        Pay_Rule__c unionPayRule = new Pay_Rule__c(
                Name = 'Union',
                Type__c = 'Union',
                Pay_Holiday__c = true,
                Work_Before_and_After_Holiday_to_Qualify__c = true,
                Work_x_Out_y_Days_to_Qualify__c = '3|5',
                Enable_Dispatch_from_Home_Pay__c = true
                );

        payRuleLst.add(unionPayRule);
        insert payRuleLst;

        Pay_Rule_Line__c prLine = new Pay_Rule_Line__c(
                Pay_Rule__c = unionPayRule.Id,
                Resource_Type__c = resourceType.Id,
                Eligible_Holidays__c = 'New Year\'s Day Actual',
                Holiday_with_Double_Time_Pay__c = 'New Year\'s Day Actual',
                Overtime_Rate_Multiple__c = 1.5,
                Double_Time_Rate_Multiple__c = 2,
                Daily_OT_After_Num_of_Hours__c = 8,
                Time_After_Pay_Code__c = 'O/T',
                Time_Before_Pay_Code__c = 'O/T',
                Sunday_Pay_Code__c = 'DBT',
                Saturday_Pay_Code__c = 'O/T',
                Before_Time__c = Time.newInstance(7,0,0,0),
                After_Time__c = Time.newInstance(16,0,0,0),
                Rate__c = 100);
        insert prLine;

        Pay_Rule__c payRule = new Pay_Rule__c();
        payRule.Name = 'PWRule';
        payRule.Type__c = 'Prevailing Wage';
        payRule.Pay_Holiday__c = true;
        payRule.Pay_Travel_Time__c = true;
        insert payRule;

        List<Pay_Rule_Line__c> payRuleLines = new List<Pay_Rule_Line__c>();
        Pay_Rule_Line__c payRuleLine = new Pay_Rule_Line__c();
        payRuleLine.Pay_Rule__c = payRule.Id;
        payRuleLine.Resource_Type__c = resourceType.Id;
        payRuleLine.Rate__c = 32;
        payRuleLine.Daily_OT_After_Num_of_Hours__c = 8;
        payRuleLine.Overtime_Rate_Multiple__c = 1.5;
        payRuleLine.Double_Time_Rate_Multiple__c = 2;
        payRuleLine.Sunday_Pay_Code__c = 'O/T';
        payRuleLine.Holidays_with_Overtime_Pay__c = 'New Year\'s Day Actual';
        payRuleLine.Eligible_Holidays__c = 'New Year\'s Day Actual';
        payRuleLine.Fringe__c = 22;
        payRuleLine.OT_Fringe_Amount__c = 22;
        payRuleLine.DT_Fringe_Amount__c = 22;
        payRuleLine.Peak_Season_Start__c = Date.newInstance(2020,4,1);
        payRuleLine.Peak_Season_End__c = Date.newInstance(2020,7,31);
        payRuleLines.add(payRuleLine);
        insert payRuleLines;

        Pay_Rule_Holiday__c prHoliday = new Pay_Rule_Holiday__c(
                Name = 'New Year',
                Pay_Rule__c = unionPayRule.Id,
                Holiday__c = 'New Year\'s Day Actual',
                Date__c = Date.valueOf('2018-01-02'),
                Pay_Code__c = 'DBT');

        insert prHoliday;

        Resource__c laborResource = new Resource__c(
            RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Labor').getRecordTypeId(),
            Name = 'FT',
            Status__c = 'Active',
            Start_Date__c = Date.valueOf('2010-01-01'),
            Subsidiary_Company__c = subsidiaryCompany.Id,
            Service_Center__c = serviceCenter.Id,
            Resource_Type__c = resourceType.Id,
            Category__c = 'Labor',
            Unit_of_Measure__c = unitOfMeasure.Id,
            Employee_Type__c = 'Employee',
            Allow_Zero_Unit_Cost_at_TM_Confirmation__c = true,
            Pay_Rule__c = unionPayRule.Id);
        insert laborResource;

        Resource__c equipmentRes = new Resource__c(
                RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Equipment').getRecordTypeId(),
                Name = 'Bobcat',
                Status__c = 'Available',
                Start_Date__c = Date.valueOf('2010-01-01'),
                Subsidiary_Company__c = subsidiaryCompany.Id,
                Service_Center__c = serviceCenter.Id,
                Resource_Type__c = equipmentResourceType.Id,
                Category__c = 'Equipment',
                Allow_Zero_Unit_Cost_at_TM_Confirmation__c = true,
                Unit_of_Measure__c = unitOfMeasure.Id
        );
        insert equipmentRes;

        Holiday__c holiday = new Holiday__c(
                Name = 'New Year',
                Date__c = Date.valueOf('2018-01-01'),
                Holiday_Name_Map__c = 'New Year\'s Day Actual',
                Rate_Type__c = 'DBT'
        );
        insert holiday;

        List<Week_Number__c> wkNumbersLst = new List<Week_Number__c>();
        Week_Number__c wkNumber1 = new Week_Number__c(
                Name = '2018/01',
                Week_Start_Date__c = Date.valueOf('2018-01-1'),
                Week_End_Date__c = Date.valueOf('2018-01-07'),
                Week_No__c = '01',
                Year__c = '2018'
        );
        wkNumbersLst.add(wkNumber1);
        Week_Number__c wkNumber2 = new Week_Number__c(
                Name = '2018/02',
                Week_Start_Date__c = Date.valueOf('2018-01-8'),
                Week_End_Date__c = Date.valueOf('2018-01-14'),
                Week_No__c = '02',
                Year__c = '2018'
        );
        wkNumbersLst.add(wkNumber2);
        insert wkNumbersLst;

        Billing_Rule__c billingRule = new Billing_Rule__c();
        billingRule.Name = 'Company Default';
        billingRule.Holidays_Bill_in_DT_Rate__c = 'Christmas Day Company';
        billingRule.Holidays_Bill_in_OT_Rate__c = 'Thanksgiving';
        billingRule.Sunday_Rate_Code__c = EnumUtil.TimeRateCode.DT.name();
        billingRule.Saturday_Rate_Code__c = EnumUtil.TimeRateCode.OT.name();
        billingRule.Quote_Order_Assumption__c = 'PortalBasisAdv;LumpSum;DailyRate;OvertimeRate;PortalBasis';
        insert billingRule;

        //billing rule lines
        List<Billing_Rule_Line__c> billingRuleLines = new List<Billing_Rule_Line__c>();
        Billing_Rule_Line__c billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,30,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.Hours_After_Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Tuesday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Friday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Hours_After_Number_of_Hours__c = 3;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'DT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = billingRule.Id;
        billingRuleLine.Billing_Rule__r = billingRule;
        billingRuleLine.Calculation_Type__c = 'Day_Based';
        billingRuleLine.Day__c = 'Saturday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLines.add(billingRuleLine);
        insert billingRuleLines;

        Company_Setup__c CompanySetupRecord = new Company_Setup__c(
                Name = userinfo.getOrganizationname(),
                Lines_to_Insert__c = 5,
                Allow_Posting_From__c = Date.newInstance(2015, 1, 1),
                Allow_Posting_To__c = Date.newInstance(2019, 1, 1),
                Company_Pay_Rule__c = unionPayRule.Id,
                Standard_Rate__c = 'REG',
                Overtime_Rate__c = 'O/T',
                Double_Time_Rate__c = 'DBT',
                Default_Billing_Rule__c = billingRule.Id
        );

        insert CompanySetupRecord;

        //PW Job Data
        Sales_Order__c pwOrder = new Sales_Order__c(
                Name = 'NJPWJOB001',
                Bill_to_Customer_No__c = acc.Id,
                Service_Center__c = serviceCenter.Id,
                Sales_Order_Type__c = salesOrderType.Id,
                Subsidiary_Company__c = subsidiaryCompany.Id,
                Project_Coordinator__c= salesperson.Id,
                Surcharge_Type__c = 'N/A',
                Pay_Rule__c = payRule.Id,
                Prevailing_Wage_Job__c = true
        );
        insert pwOrder;

        TM__c tm = new TM__c(
                Bill_to_Customer__c = acc.Id,
                Project_Coordinator__c = salesperson.Id,
                Account_Executive__c = salesperson.Id,
                Prevailing_Wage_Job__c = true,
                Certified_PW_Job__c = true,
                Service_Center__c = serviceCenter.Id,
                Subsidiary_Company__c = subsidiaryCompany.Id,
                Tax_Area__c = taxArea.Id,
                Sales_Order__c = pwOrder.Id,
                Scheduled_Date__c = wkNumber1.Week_Start_Date__c.addDays(1),
                Status__c = 'Confirmed'
        );
        insert tm;

        Resource__c stdLabor = new Resource__c(
                RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Labor').getRecordTypeId(),
                Name = 'STD Labor',
                Status__c = 'Active',
                Start_Date__c = Date.valueOf('2010-01-01'),
                Subsidiary_Company__c = subsidiaryCompany.Id,
                Service_Center__c = serviceCenter.Id,
                Resource_Type__c = resourceType.Id,
                Category__c = 'Labor',
                Unit_of_Measure__c = unitOfMeasure.Id,
                Allow_Zero_Unit_Cost_at_TM_Confirmation__c = true,
                Employee_Type__c = 'Employee'
        );
        insert stdLabor;

        //sales order job task
        List<Sales_Order_Job_Task__c> salesOrderJobTasks = new List<Sales_Order_Job_Task__c>();
        Sales_Order_Job_Task__c salesOrderJobTask = new Sales_Order_Job_Task__c();
        salesOrderJobTask.Sales_Order__c = pwOrder.Id;
        salesOrderJobTask.Billing_Type__c = 'T&M';
        salesOrderJobTask.Line_No__c = 1;
        salesOrderJobTask.Task_No__c = 1;
        salesOrderJobTask.Name = 'Field Service';
        salesOrderJobTasks.add(salesOrderJobTask);
        insert salesOrderJobTasks;

        List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
        TM_Job_Task__c jobTask = new TM_Job_Task__c();
        jobTask.TM__c = tm.Id;
        jobTask.Name = salesOrderJobTask.Name;
        jobTask.Line_No__c = salesOrderJobTask.Line_No__c;
        jobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
        jobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;

        jobTasks.add(jobTask);
        insert jobTasks;

        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        TM_Line__c tml = new TM_Line__c(
                Line_No__c = 1,
                Description__c = 'Test Labor',
                Quantity__c = 12,
                Category__c = 'Labor',
                TM__c = tm.Id,
                TM_Job_Task__c = jobTask.Id,
                TM_Job_Task__r = jobTask,
                Resource_Type__c = resourceType.Id,
                Resource__c = stdLabor.Id,
                Tax_Group__c = 'TX',
                Service_Center__c = serviceCenter.Id,
                Unit_of_Measure__c = unitOfMeasure.Id,
                Job_Start_Time__c = Time.newInstance(13, 0, 0, 0),
                Site_Start_Time__c = Time.newInstance(14, 0, 0 ,0),
                Site_End_Time__c = Time.newInstance(24, 0, 0, 0),
                Job_End_Time__c = Time.newInstance(01, 0, 0, 0),
                Lunch_Start_Time__c = Time.newInstance(14, 0, 0, 0),
                Lunch_End_Time__c = Time.newInstance(14,30,0,0),
                Lunch__c = '1/2 Hour',
                Total_Site_Hours__c = 12,
                Total_Job_Hours__c = 12,
                Regular_Hours__c = 8,
                Regular_Rate__c = 50,
                Overtime_Rate__c = 70,
                Overtime_Hours__c = 4,
                Unit_Price__c =  56.667,
                Unit_Cost__c = 20,
                Hour__c = 12
        );
        tmLines.add(tml);

        TM_Line__c unionLine = new TM_Line__c(
                Line_No__c = 1,
                Description__c = 'Test Labor',
                Quantity__c = 12,
                Category__c = 'Labor',
                TM__c = tm.Id,
                TM_Job_Task__c = jobTask.Id,
                TM_Job_Task__r = jobTask,
                Resource_Type__c = resourceType.Id,
                Resource__c = laborResource.Id,
                Tax_Group__c = 'TX',
                Service_Center__c = serviceCenter.Id,
                Unit_of_Measure__c = unitOfMeasure.Id,
                Job_Start_Time__c = Time.newInstance(13, 0, 0, 0),
                Site_Start_Time__c = Time.newInstance(14, 0, 0 ,0),
                Site_End_Time__c = Time.newInstance(24, 0, 0, 0),
                Job_End_Time__c = Time.newInstance(01, 0, 0, 0),
                Lunch_Start_Time__c = Time.newInstance(14, 0, 0, 0),
                Lunch_End_Time__c = Time.newInstance(14,30,0,0),
                Lunch__c = '1/2 Hour',
                Total_Site_Hours__c = 12,
                Total_Job_Hours__c = 12,
                Regular_Hours__c = 8,
                Regular_Rate__c = 50,
                Overtime_Rate__c = 70,
                Overtime_Hours__c = 4,
                Unit_Price__c =  56.667,
                Unit_Cost__c = 20,
                Hour__c = 12,
                Eligible_Dispatch_from_Home_Pay__c = true
        );
        tmLines.add(unionLine);

        TM_Line__c equipmentLine = new TM_Line__c(
                Line_No__c = 3,
                Description__c = 'Bobcat',
                Quantity__c = 12,
                Category__c = 'Equipment',
                TM__c = tm.Id,
                TM_Job_Task__c = jobTask.Id,
                TM_Job_Task__r = jobTask,
                Resource_Type__c = equipmentResourceType.Id,
                Resource__c = equipmentRes.Id,
                Tax_Group__c = 'TX',
                Service_Center__c = serviceCenter.Id,
                Unit_of_Measure__c = unitOfMeasure.Id,
                Job_Start_Time__c = Time.newInstance(13, 0, 0, 0),
                Job_End_Time__c = Time.newInstance(01, 0, 0, 0),
                Total_Job_Hours__c = 12,
                Unit_Cost__c = 20,
                Hour__c = 12
        );
        tmLines.add(equipmentLine);
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        insert tmLines;

        List<Field_Activity_Log__c> fieldActivityLogs = new List<Field_Activity_Log__c>();
        Field_Activity_Log__c fieldActivityLog = new Field_Activity_Log__c(
                T_M_Line__c = unionLine.Id,
                Equipment__c = equipmentRes.Id,
                Resource_Type__c = resourceType.Id,
                Start_Time__c = Time.newInstance(15, 0, 0, 0),
                End_Time__c = Time.newInstance(18, 0, 0, 0)
        );
        fieldActivityLogs.add(fieldActivityLog);
        insert fieldActivityLogs;
        //PW Job Data
    }

    private static testMethod void testSetPayRateByPayRuleAndResTypeMap(){
        Resource__c laborRes = [SELECT Id, Pay_Rule__c FROM Resource__c WHERE Category__c = 'Labor' LIMIT 1];
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        tsMgmt.setPayRateByPayRuleAndResTypeMap(new Set<Id>{laborRes.Pay_Rule__c});
        System.assertEquals(tsMgmt.mapPayRateByPayRuleAndResType.size(), 1);
    }

    private static testMethod void testCustomPayRuleExist(){
        Resource__c laborRes = [SELECT Id, Pay_Rule__c FROM Resource__c WHERE Category__c = 'Labor' LIMIT 1];
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        tsMgmt.setPayRuleMap(new Set<Id>{laborRes.Pay_Rule__c});
        tsMgmt.customPayRuleExist(laborRes);
    }

    private static testMethod void testValidateWeekNo(){
    Test.startTest();
        Resource__c laborRes = [SELECT Id, Pay_Rule__c FROM Resource__c WHERE Category__c = 'Labor' LIMIT 1];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Service_Center__c serviceCenter = [SELECT Id FROM Service_Center__c WHERE Name = '01' LIMIT 1];
        Timesheet__c ts = new Timesheet__c(
                Resource__c = laborRes.Id,
                Service_Center__c = serviceCenter.Id,
                Week_No__c = wkNumber.Id,
                Starting_Date__c = wkNumber.Week_Start_Date__c,
                Ending_Date__c = wkNumber.Week_End_Date__c);
        insert ts;
        TimesheetMgmt.validateWeekNo(ts);
        ts.Week_No__c = null;
        TimesheetMgmt.validateWeekNo(ts);
     Test.stopTest();
    }

    private static testMethod void testDeleteTimesheetLine(){

    }

    private static testMethod void testGetDatetimeInUserTZ(){
        Datetime dt = Datetime.now();
        TimesheetMgmt.getDatetimeInUserTZ(dt);
    }

    private static testMethod void testGetResourceByResId(){
        try{
            Resource__c res = [SELECT Id, Name FROM Resource__c WHERE Name = 'FT'];
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            List<Resource__c> resLst = tsMgmt.getResourcesByResId(new Set<Id>{res.Id});
            System.assertEquals(res.Id, resLst[0].Id);
            resLst = tsMgmt.getResourcesByResId(new Set<Id>{});
        } catch (Exception e){
            System.debug('****e ' + e.getMessage());
            System.assertEquals(e.getMessage(), 'Resource Id Set must not be blank!');
        }
    }

    private static testMethod void testGetResourcesByScId(){
        try{
            Resource__c res = [SELECT Id, Name, Service_Center__c FROM Resource__c WHERE Name = 'FT'];
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            List<Resource__c> resLst = tsMgmt.getResourcesByScId(res.Service_Center__c);
            System.assertEquals(res.Id, resLst[0].Id);
            res.Service_Center__c = null;
            resLst = tsMgmt.getResourcesByScId(res.Service_Center__c);
        } catch (Exception e){
            System.debug('***testGetResourcesByScId ' + e.getMessage());
            System.assertEquals(e.getMessage(), 'Service Center must not be blank!');
        }
    }

    private static testMethod void testSetResMap(){
        try{
            List<Resource__c> resLs = [SELECT Id FROM Resource__c];
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            tsMgmt.setResMap(resLs);
            System.assertEquals(tsMgmt.mapRes.size(), 3);
        } catch (Exception e){

        }
    }

    private static testMethod void testSetSCLaborResource(){
        try{
            Resource__c res = [SELECT Id, Name, Service_Center__c FROM Resource__c WHERE Name = 'FT'];
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            tsMgmt.setSCLaborResource(res.Service_Center__c);
            System.assertEquals(res.Id, tsMgmt.TheScResources[0].Id);
            res.Service_Center__c = null;
            //resLst = tsMgmt.getResourcesByScId(res.Service_Center__c);
        } catch (Exception e){
            System.debug('***testGetResourcesByScId ' + e.getMessage());
            System.assertEquals(e.getMessage(), 'Service Center must not be blank!');
        }
    }

    private static testMethod void testSetServiceCenter(){
        try{
            Service_Center__c sc = [SELECT Id FROM Service_Center__c LIMIT 1];
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            tsMgmt.setServiceCenter(sc.Id);
            System.assertEquals(sc.Id, tsMgmt.TheSc.Id);
        } catch (Exception e){
            
        }
    }
        
    @IsTest static void testCreateTimesheet(){
    Test.startTest();
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        List<Timesheet_Line__c> tsLineLst = new List<Timesheet_Line__c>();
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c, Pay_Rule__r.Type__c, Pay_Rule__r.Mon_Sun_Work_Week__c, Resource_Type__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Name = '01' LIMIT 1];
        Salesperson__c salesperson = [SELECT Id FROM Salesperson__c LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        Subsidiary_Company__c subsidiaryCompany = [SELECT Id FROM Subsidiary_Company__c LIMIT 1];
        Sales_Order__c salesOrder = [SELECT Id, Service_Center__c, Service_Center__r.Name, Subsidiary_Company__c FROM Sales_Order__c LIMIT 1];
        Tax_Area__c taxArea = [SELECT Id FROM Tax_Area__c LIMIT 1];
        Resource_Type__c resourceType = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Unit_of_Measure__c unitOfMeasure = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Off_Type__c offType = [SELECT Id FROM Off_Type__c LIMIT 1];
        List<TM__c> tmLst = new List<TM__c>();
        List<TM_Line__c> tmLineLst = new List<TM_Line__c>();

        //sales order job task
        List<Sales_Order_Job_Task__c> salesOrderJobTasks = new List<Sales_Order_Job_Task__c>();
        Sales_Order_Job_Task__c salesOrderJobTask = new Sales_Order_Job_Task__c();
        salesOrderJobTask.Sales_Order__c = salesOrder.Id;
        salesOrderJobTask.Billing_Type__c = 'T&M';
        salesOrderJobTask.Line_No__c = 1;
        salesOrderJobTask.Task_No__c = 1;
        salesOrderJobTask.Name = 'Field Service';
        salesOrderJobTasks.add(salesOrderJobTask);
        insert salesOrderJobTasks;

        for(Integer i = 0; i < 7; i++){
            TM__c tm = new TM__c(
                    Bill_to_Customer__c = account.Id,
                    Project_Coordinator__c = salesperson.Id,
                    Account_Executive__c = salesperson.Id,
                    Prevailing_Wage_Job__c = true,
                    Certified_PW_Job__c = true,
                    Service_Center__c = sc.Id,
                    Subsidiary_Company__c = subsidiaryCompany.Id,
                    Tax_Area__c = taxArea.Id,
                    Sales_Order__c = salesOrder.Id,
                    Scheduled_Date__c = wkNumber.Week_Start_Date__c.addDays(i),
                    Status__c = 'Confirmed'
            );
            tmLst.add(tm);
        }
        insert tmLst;

        //TM Job Task
        List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
        for(TM__c tm:tmLst){
            TM_Job_Task__c jobTask = new TM_Job_Task__c();
            jobTask.TM__c = tm.Id;
            jobTask.Name = salesOrderJobTask.Name;
            jobTask.Line_No__c = salesOrderJobTask.Line_No__c;
            jobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
            jobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
            jobTasks.add(jobTask);
        }
        insert jobTasks;

        Map<Id, TM_Job_Task__c> tmJobTasksByTMIds = new Map<Id, TM_Job_Task__c>();
        for(TM_Job_Task__c tmJobTask : jobTasks){
            tmJobTasksByTMIds.put(tmJobTask.TM__c, tmJobTask);
        }

        for(TM__c tm : tmLst){
            TM_Job_Task__c tmJobTask = tmJobTasksByTMIds.get(tm.Id);
            TM_Line__c tml = new TM_Line__c(
                    Line_No__c = 1,
                    Description__c = 'Test Labor',
                    Quantity__c = 12,
                    Category__c = 'Labor',
                    TM__c = tm.Id,
                    Resource_Type__c = resourceType.Id,
                    Resource__c = laborResLst[0].Id,
                    Tax_Group__c = 'TX',
                    Service_Center__c = sc.Id,
                    Unit_of_Measure__c = unitOfMeasure.Id,
                    Job_Start_Time__c = Time.newInstance(13, 0, 0, 0),
                    Site_Start_Time__c = Time.newInstance(14, 0, 0 ,0),
                    Site_End_Time__c = Time.newInstance(24, 0, 0, 0),
                    Job_End_Time__c = Time.newInstance(01, 0, 0, 0),
                    Lunch_Start_Time__c = Time.newInstance(14, 0, 0, 0),
                    Lunch_End_Time__c = Time.newInstance(14,30,0,0),
                    Lunch__c = '1/2 Hour',
                    Total_Site_Hours__c = 12,
                    Total_Job_Hours__c = 12,
                    Regular_Hours__c = 8,
                    Regular_Rate__c = 50,
                    Overtime_Rate__c = 70,
                    Overtime_Hours__c = 4,
                    Unit_Price__c =  56.667,
                    Hour__c = 12,
                    TM_Job_Task__c = tmJobTask.Id
            );
            tmLineLst.add(tml);
        }
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        insert tmLineLst;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;

        List<Resource_Flat_Pay__c> resourceFlatPayList = new List<Resource_Flat_Pay__c>();
        for(TM_Line__c tml : tmLineLst){
            Resource_Flat_Pay__c resourceFlatPay = new Resource_Flat_Pay__c(
                Rate__c = 10,
                Rate_Type__c = 'PDL',
                T_M_Line__c = tml.Id,
                T_M__c = tml.TM__c
            );
            resourceFlatPayList.add(resourceFlatPay);
        }
        insert resourceFlatPayList;

        Set<Id> payRuleIdSet = new Set<Id>();
        for(Resource__c res : laborResLst){
            payRuleIdSet.add(res.Pay_Rule__c);
        }

        
        List<TM_Line__c> tmlLst = tsMgmt.getTMLineList(wkNumber.Week_Start_Date__c, wkNumber.Week_End_Date__c, new Set<Id>{laborResLst[0].Id});
        List<Timesheet__c> tsLst = tsMgmt.createTimesheets(laborResLst, wkNumber);
        insert tsLst;

        Map<Id, Timesheet__c> mapTS = new Map<Id, Timesheet__c>();
        for(Timesheet__c ts : tsLst){
            mapTS.put(ts.Resource__c, ts);
        }

        Set<Id> tmIds = tsMgmt.getTMIds(tmLineLst);
        tsMgmt.setResMap(laborResLst);
        tsMgmt.setPayRuleMap(payRuleIdSet);
        //tsMgmt.setPayRuleHolidayMap(payRuleIdSet);
        tsMgmt.setPayRateByPayRuleAndResTypeMap(payRuleIdSet);
        tsMgmt.createTSLinesFromTMLines(mapTS, tsLineLst, tmlLst, wkNumber.Week_Start_Date__c, wkNumber.Week_End_Date__c);
        tsMgmt.processOvernightTravelTime(tsLineLst, wkNumber.Week_End_Date__c); //Ticket#24029
        tsMgmt.createFlatPayLines(mapTS, tsLineLst, tmIds);
        tsMgmt.processTimesheetLineWithPayRule(tsLineLst);
        tsMgmt.finalizeTimesheet(tsLineLst);
        tsMgmt.assignPayRate(tsLineLst);
        insert tsLineLst;

        try{
            tsMgmt.checkTimesheetLineTimeOverlap(tsLineLst);
        } catch (Exception e){
            System.assertEquals(e.getMessage().contains('Overlap time found for Resource'), true);
        }

        List<Timesheet__c> createdTSLst  = [SELECT Id, Name, Total_Hours_Submitted__c, Resource__c, Week_No__c,
                Total_Lunch_Hours__c, Total_OT_Hours__c, Total_PTO_Hours__c, Total_Regular_Hours__c, Total_DT_Hours__c,
                Total_Prevailing_Wage_Job_Hrs__c, Total_Regular_Job_Hours__c, Total_Travel_Time__c, Total_Shop_Time_Hours__c
                FROM Timesheet__c];

        Timesheet__c ts = createdTSLst[0];
        List<Timesheet_Line__c> tsLines = tsMgmt.getTimesheetLines(new Set<Id>{ts.Id});
        ts.recalculateFormulas();

        Resource_Off__c resourceOff = new Resource_Off__c(
            Date__c = Date.valueOf('2018-01-06'),
            Start_Time__c = Time.newInstance(02,0,0,0),
            End_Time__c = Time.newInstance(07, 0, 0, 0),
            Hours__c = 5,
            Total_Hours__c = 5,
            Resource__c = ts.Resource__c,
            Off_Type__c = offType.Id,
            Shop_Time_Category__c = 'Physical'
        );
        insert resourceOff;
        Timesheet__c ts2 = [SELECT Id, Resource__c, Service_Center__c, Week_No__c, Starting_Date__c, Ending_Date__c, Status__c, LastModifiedDate FROM Timesheet__c LIMIT 1];
        try{
            tsMgmt.refreshTimesheet(ts2, tsLineLst);

        } catch (Exception e){
            System.debug('Test Exception ' + e.getStackTraceString());
            // System.assertEquals(e.getMessage().contains('Overlap time found for Resource'), true);
        }
        
        try{
            tsMgmt.addResTimeEntryFromResOff(new List<Resource_Off__c>{resourceOff},null,null,new Map<String, Map<Time, Time>>(),new Set<Id>(),new Map<Id, String>(),new Map<String, Set<String>>());
            //tsMgmt.verifyTimesheetTotalHours(wkNumber, sc.Id);
        } catch (Exception e){
            System.debug('Test Exception ' + e.getStackTraceString());
            System.assertEquals(e.getMessage().contains('Overlap time found for Resource'), true);
        }

        TimesheetMgmt.checkSave(ts2,tsLineLst);
        TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theSalesOrder');
        TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theTM');
        TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theTML');
        TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theScheduledDate');
        TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theTimeType');
        TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theStartTime');
        TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theEndTime');
        TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theLunchStartTime');
        TimesheetMgmt.validateWeekNo(ts2);
        TimesheetMgmt.nullRelationshipFields(ts2);
        tsLineLst[0].Sales_Order__c = null;
        TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theSalesOrder');
         tsLineLst[0].TM__c = null;
         TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theTM');
        tsLineLst[0].T_M_Line__c = null;
     TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theTML');
       tsLineLst[0].Scheduled_Date__c = Date.valueOf('2018-01-06');
     TimesheetMgmt.updateTSL(ts2,tsLineLst[0],'theScheduledDate');

        Test.stopTest();
    }

    /*
    @IsTest
    private static void testSetPayRuleHolidayDateMap(){
        Week_Number__c weekNumber = [SELECT Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c];
        TimesheetMgmt tmMgmt = new TimesheetMgmt();
        tmMgmt.setPayRuleHolidayDateMap(weekNumber.Week_Start_Date__c, weekNumber.Week_End_Date__c, )

    }
    */
    @IsTest
    private static void testIsQualifyForUnionHoliday(){
        Test.startTest();
        // Test Data
        Date holidayDate = Date.valueOf('2018-01-01');
        System.debug('holidayDate ' + holidayDate);
        Resource__c res = [SELECT Id, Pay_Rule__c, Last_Name__c, First_Name__c, Start_Date__c, Resource_Type__c FROM Resource__c LIMIT 1];
        Set<String> workDateSet = new Set<String>();
        workDateSet.add(res.Id + ':' + '2018-01-01 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-02 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-03 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-04 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-05 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-06 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-07 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-08 00:00:00');
        
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        tsMgmt.setPayRuleMap(new Set<Id>{res.Pay_Rule__c});
        //Ticket#23625 >>
        //Boolean isQualify = tsMgmt.isQualifyForUnionHoliday(res, holidayDate, workDateSet);
        Boolean isQualify = tsMgmt.isQualifyForUnionHoliday(res, holidayDate, workDateSet, res.Pay_Rule__c, res.Resource_Type__c);
        //Ticket#23625 <<
        System.assertEquals(false, isQualify);

        holidayDate = Date.valueOf('2018-01-02');
        //Ticket#23625 >>
        //Boolean isQualify = tsMgmt.isQualifyForUnionHoliday(res, holidayDate, workDateSet);
        isQualify = tsMgmt.isQualifyForUnionHoliday(res, holidayDate, workDateSet, res.Pay_Rule__c, res.Resource_Type__c);
        //Ticket#23625 <<
        System.assertEquals(true, isQualify);

        holidayDate = Date.valueOf('2018-01-05');
        //Ticket#23625 >>
        //Boolean isQualify = tsMgmt.isQualifyForUnionHoliday(res, holidayDate, workDateSet);
        isQualify = tsMgmt.isQualifyForUnionHoliday(res, holidayDate, workDateSet, res.Pay_Rule__c, res.Resource_Type__c);
        //Ticket#23625 <<
        System.assertEquals(true, isQualify);
        Test.stopTest();
    }

    @IsTest
    private static void testIsQualifyForCompanyHoliday(){
     Test.startTest();
        Resource__c res = [SELECT Id, Pay_Rule__c, FLSA__c, Start_Date__c, Employee_Type__c FROM Resource__c LIMIT 1];
        res.FLSA__c = 'Non-Exempt';
        res.Pay_Rule__c = null;
        update res;

        Pay_Rule__c payRule = [SELECT Id, Type__c FROM Pay_Rule__c LIMIT 1];
        payRule.Type__c = '';
        update payRule;

        Date holidayDate = Date.valueOf('2018-01-01');
        Date weekStart = Date.valueOf('2018-01-01');
        Date weekEnd = Date.valueOf('2018-01-07');
        System.debug('holidayDate ' + holidayDate);
        Set<String> workDateSet = new Set<String>();
        workDateSet.add(res.Id + ':' + '2018-01-01 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-02 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-03 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-04 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-05 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-06 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-07 00:00:00');
        workDateSet.add(res.Id + ':' + '2018-01-08 00:00:00');

       
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        tsMgmt.setPayRuleMap(new Set<Id>{res.Pay_Rule__c});
        //Boolean isQualify = tsMgmt.isQualifyForCompanyHoliday(res, holidayDate, workDateSet);
        //System.assertEquals(false, isQualify);

        holidayDate = Date.valueOf('2018-01-02');
        Boolean isQualify = tsMgmt.isQualifyForCompanyHoliday(res, holidayDate, workDateSet, weekStart, weekEnd);
        System.assertEquals(true, isQualify);

        holidayDate = Date.valueOf('2018-01-05');
        isQualify = tsMgmt.isQualifyForCompanyHoliday(res, holidayDate, workDateSet, weekStart, weekEnd);
        System.assertEquals(true, isQualify);
        Test.stopTest();
    }

    @IsTest static void testReallocateTimesForTimesheetLines(){
      Test.startTest();
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        List<Timesheet_Line__c> tsLineLst = new List<Timesheet_Line__c>();
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Name = '01' LIMIT 1];
        Salesperson__c salesperson = [SELECT Id FROM Salesperson__c LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        Subsidiary_Company__c subsidiaryCompany = [SELECT Id FROM Subsidiary_Company__c LIMIT 1];
        Sales_Order__c salesOrder = [SELECT Id, Service_Center__c, Service_Center__r.Name, Subsidiary_Company__c FROM Sales_Order__c LIMIT 1];
        Tax_Area__c taxArea = [SELECT Id FROM Tax_Area__c LIMIT 1];
        Resource_Type__c resourceType = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Unit_of_Measure__c unitOfMeasure = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
//        Off_Type__c offType = [SELECT Id FROM Off_Type__c LIMIT 1];
//        List<TM__c> tmLst = new List<TM__c>();
//        List<TM_Line__c> tmLineLst = new List<TM_Line__c>();

        //sales order job task
        List<Sales_Order_Job_Task__c> salesOrderJobTasks = new List<Sales_Order_Job_Task__c>();
        Sales_Order_Job_Task__c salesOrderJobTask = new Sales_Order_Job_Task__c();
        salesOrderJobTask.Sales_Order__c = salesOrder.Id;
        salesOrderJobTask.Billing_Type__c = 'T&M';
        salesOrderJobTask.Line_No__c = 1;
        salesOrderJobTask.Task_No__c = 1;
        salesOrderJobTask.Name = 'Field Service';
        salesOrderJobTasks.add(salesOrderJobTask);
        insert salesOrderJobTasks;

        TM__c tm = new TM__c(
                Bill_to_Customer__c = account.Id,
                Project_Coordinator__c = salesperson.Id,
                Account_Executive__c = salesperson.Id,
                Prevailing_Wage_Job__c = true,
                Certified_PW_Job__c = true,
                Service_Center__c = sc.Id,
                Subsidiary_Company__c = subsidiaryCompany.Id,
                Tax_Area__c = taxArea.Id,
                Sales_Order__c = salesOrder.Id,
                Scheduled_Date__c = wkNumber.Week_Start_Date__c.addDays(1),
                Status__c = 'Confirmed'
        );
        insert tm;

        List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
        TM_Job_Task__c jobTask = new TM_Job_Task__c();
        jobTask.TM__c = tm.Id;
        jobTask.Name = salesOrderJobTask.Name;
        jobTask.Line_No__c = salesOrderJobTask.Line_No__c;
        jobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
        jobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
        jobTasks.add(jobTask);
        insert jobTasks;

        TM_Line__c tml = new TM_Line__c(
                Line_No__c = 1,
                Description__c = 'Test Labor',
                Quantity__c = 12,
                Category__c = 'Labor',
                TM__c = tm.Id,
                Resource_Type__c = resourceType.Id,
                Resource__c = laborResLst[0].Id,
                Tax_Group__c = 'TX',
                Service_Center__c = sc.Id,
                Unit_of_Measure__c = unitOfMeasure.Id,
                Job_Start_Time__c = Time.newInstance(13, 0, 0, 0),
                Site_Start_Time__c = Time.newInstance(14, 0, 0 ,0),
                Site_End_Time__c = Time.newInstance(24, 0, 0, 0),
                Job_End_Time__c = Time.newInstance(01, 0, 0, 0),
                Lunch_Start_Time__c = Time.newInstance(14, 0, 0, 0),
                Lunch_End_Time__c = Time.newInstance(14,30,0,0),
                Lunch__c = '1/2 Hour',
                Total_Site_Hours__c = 12,
                Total_Job_Hours__c = 12,
                Regular_Hours__c = 8,
                Regular_Rate__c = 50,
                Overtime_Rate__c = 70,
                Overtime_Hours__c = 4,
                Unit_Price__c =  56.667,
                Hour__c = 12,
                TM_Job_Task__c = jobTask.Id
        );

        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        insert tml;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;

        Timesheet__c timesheet = new Timesheet__c();
        timesheet.Resource__c = laborResLst[0].Id;
        timesheet.Service_Center__c = laborResLst[0].Service_Center__c;
        timesheet.Week_No__c = wkNumber.Id;
        timesheet.Starting_Date__c = wkNumber.Week_Start_Date__c;
        timesheet.Ending_Date__c = wkNumber.Week_End_Date__c;
        timesheet.Status__c = 'Open';
        insert timesheet;

        Timesheet_Line__c timesheetLine = new Timesheet_Line__c();
        timesheetLine.Timesheet__c = timesheet.Id;
        timesheetLine.Time_Type__c = 'Job Time';
        timesheetLine.Time_Type_Code__c = 'REG';
        timesheetLine.Sales_Order_Service_Center__c = salesOrder.Service_Center__c;
        timesheetLine.Sales_Order__c = salesOrder.Id;
        timesheetLine.TM__c = tm.Id;
        timesheetLine.T_M_Line__c = tml.Id;
        timesheetLine.Week_Day__c = 'Monday';
        timesheetLine.Scheduled_Date__c = Date.valueOf('2018-01-01');
        timesheetLine.Start_Time__c = Time.newInstance(6,0,0,0);
        timesheetLine.End_Time__c = Time.newInstance(12,0,0,0);
        timesheetLine.Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        timesheetLine.Lunch_End_Time__c = Time.newInstance(12,30,0,0);
        timesheetLine.Lunch_Hours__c = 0.5;
        timesheetLine.Total_Hours__c = 6;
        timesheetLine.Net_Hours__c = 5.5;
        tsLineLst.add(timesheetLine);

        timesheetLine = new Timesheet_Line__c();
        timesheetLine.Timesheet__c = timesheet.Id;
        timesheetLine.Time_Type__c = 'Job Time';
        timesheetLine.Time_Type_Code__c = 'REG';
        timesheetLine.Sales_Order_Service_Center__c = salesOrder.Service_Center__c;
        timesheetLine.Sales_Order__c = salesOrder.Id;
        timesheetLine.TM__c = tm.Id;
        timesheetLine.T_M_Line__c = tml.Id;
        timesheetLine.Week_Day__c = 'Monday';
        timesheetLine.Scheduled_Date__c = Date.valueOf('2018-01-01');
        timesheetLine.Start_Time__c = Time.newInstance(12,0,0,0);
        timesheetLine.End_Time__c = Time.newInstance(16,0,0,0);
        timesheetLine.Total_Hours__c = 4;
        timesheetLine.Net_Hours__c = 4;
        tsLineLst.add(timesheetLine);

        insert tsLineLst;

        
        tsMgmt.reallocateTimesForTimesheetLines(tsLineLst[0], tsLineLst[1]);
        System.assertEquals(null, tsLineLst[0].Lunch_Hours__c);
        System.assertEquals(0.5, tsLineLst[1].Lunch_Hours__c);

        tsLineLst[0].Lunch_Start_Time__c = Time.newInstance(11,30,0,0);
        tsLineLst[0].Lunch_End_Time__c = Time.newInstance(12,00,0,0);
        tsLineLst[0].Lunch_Hours__c = 0.5;
        update tsLineLst;
        tsMgmt.reallocateTimesForTimesheetLines(tsLineLst[0], tsLineLst[1]);
        tsLineLst[0].Lunch_Start_Time__c = Time.newInstance(11,00,0,0);
        tsLineLst[0].Lunch_End_Time__c = Time.newInstance(12,00,0,0);
        tsLineLst[0].Lunch_Hours__c = 1;
        tsLineLst[0].Net_Hours__c = 5;
        update tsLineLst;
        tsMgmt.reallocateTimesForTimesheetLines(tsLineLst[0], tsLineLst[1]);
        tsMgmt.allocateLunchHour(tsLineLst[0]);
        tsLineLst[0].End_Time__c = Time.newInstance(0,0,0,0);
        tsLineLst[0].Total_Hours__c = 18;
        tsLineLst[0].Net_Hours__c = 17;
        update tsLineLst;
        tsMgmt.allocateLunchHour(tsLineLst[0]);

        List<Timesheet__c> timesheets2 = tsMgmt.getOpenTimesheetsByWeekAndServiceCenter(wkNumber.Id, sc.Id);
        System.assertEquals(1, timesheets2.size());

        Week_Number__c wk2 = tsMgmt.getWeekNumber(wkNumber.Id);
        System.assertEquals('2018/01', wk2.Name);

        tsMgmt.setServiceCenterByName('01');
        System.assertEquals('01', tsMgmt.TheSC.Name);

        Set<Id> tmIds = tsMgmt.getTMIds(new List<TM_Line__c>{tml});
        System.assertEquals(1, tmIds.size());
        Test.stopTest();
    }

    @IsTest static void testCreateTimesheetMix(){
    Test.startTest();
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        List<Timesheet_Line__c> tsLineLst = new List<Timesheet_Line__c>();
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c, Pay_Rule__r.Type__c, Pay_Rule__r.Mon_Sun_Work_Week__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Name = '01' LIMIT 1];

        Set<Id> payRuleIdSet = new Set<Id>();
        for(Resource__c res : laborResLst){
            payRuleIdSet.add(res.Pay_Rule__c);
        }

        
        List<TM_Line__c> tmlLst = tsMgmt.getTMLineList(wkNumber.Week_Start_Date__c, wkNumber.Week_End_Date__c, new Set<Id>{laborResLst[0].Id});
        List<Timesheet__c> tsLst = tsMgmt.createTimesheets(laborResLst, wkNumber);
        insert tsLst;

        Map<Id, Timesheet__c> mapTS = new Map<Id, Timesheet__c>();
        for(Timesheet__c ts : tsLst){
            mapTS.put(ts.Resource__c, ts);
        }

        tsMgmt.setResMap(laborResLst);
        tsMgmt.setPayRuleMap(payRuleIdSet);
        //tsMgmt.setPayRuleHolidayMap(payRuleIdSet);
        tsMgmt.setPayRateByPayRuleAndResTypeMap(payRuleIdSet);
        tsMgmt.createTSLinesFromTMLines(mapTS, tsLineLst, tmlLst, wkNumber.Week_Start_Date__c, wkNumber.Week_End_Date__c);
        tsMgmt.processOvernightTravelTime(tsLineLst, wkNumber.Week_End_Date__c); //Ticket#24029
        tsMgmt.processTimesheetLineWithPayRule(tsLineLst);
        tsMgmt.finalizeTimesheet(tsLineLst);
        tsMgmt.assignPayRate(tsLineLst);
        insert tsLineLst;

        tsMgmt.checkTimesheetLineTimeOverlap(tsLineLst);

        for(TM_Line__c tmLine:tmlLst){
            tmLine.Job_Start_Time__c = Time.newInstance(05, 0, 0, 0);
        }

        update tmlLst;

        tsMgmt.refreshTimesheetForResources(wkNumber, sc.Id, new Set<Id>{laborResLst[0].Id});

        Test.stopTest();
    }

    @IsTest static void testVerifyTimesheets(){
    
     Test.startTest();
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        List<Timesheet_Line__c> tsLineLst = new List<Timesheet_Line__c>();
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c, Pay_Rule__r.Type__c, Pay_Rule__r.Mon_Sun_Work_Week__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c,Year__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Name = '01' LIMIT 1];

        Set<Id> payRuleIdSet = new Set<Id>();
        for(Resource__c res : laborResLst){
            payRuleIdSet.add(res.Pay_Rule__c);
        }

       
        List<TM_Line__c> tmlLst = tsMgmt.getTMLineList(wkNumber.Week_Start_Date__c, wkNumber.Week_End_Date__c, new Set<Id>{laborResLst[0].Id});
        List<Timesheet__c> tsLst = tsMgmt.createTimesheets(laborResLst, wkNumber);
        insert tsLst;
        
        Map<Id, Timesheet__c> mapTS = new Map<Id, Timesheet__c>();
        for(Timesheet__c ts : tsLst){
            mapTS.put(ts.Resource__c, ts);
        }
         CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        
        //NewTestData testData = new NewTestData();
       // NewTestData.initPayRules();
        //Pay_Rule_Line_Detail__c payRuleLineDetail= [SElect Id from Pay_Rule_Line_Detail__c Limit 1];
        Pay_Rule__c prevailingWagePayRule = new Pay_Rule__c();
        prevailingWagePayRule.Name = 'Prevailing Wage';
        prevailingWagePayRule.Type__c = 'Prevailing Wage';
        prevailingWagePayRule.Pay_Travel_Time__c = true;
        insert prevailingWagePayRule;
        //Resource_Type__c laborResourceType = mapResourceTypeWrappersByName.get('Labor').ResourceType;

        Pay_Rule_Line__c prevailingWagePayRuleLine = new Pay_Rule_Line__c();
        prevailingWagePayRuleLine.Pay_Rule__c = prevailingWagePayRule.Id;
        prevailingWagePayRuleLine.Pay_Rule__r = prevailingWagePayRule;
        prevailingWagePayRuleLine.Rate__c = 32;
        prevailingWagePayRuleLine.Fringe__c = 20;
        prevailingWagePayRuleLine.OT_Fringe_Amount__c = 30;
        prevailingWagePayRuleLine.DT_Fringe_Amount__c = 40;
        prevailingWagePayRuleLine.Daily_OT_After_Num_of_Hours__c = 8;
        prevailingWagePayRuleLine.Overtime_Rate_Multiple__c = 1.5;
        prevailingWagePayRuleLine.Double_Time_Rate_Multiple__c = 2;
        prevailingWagePayRuleLine.Sunday_Pay_Code__c = 'DBT';
        prevailingWagePayRuleLine.Holidays_with_Overtime_Pay__c = 'Labor Day';
        prevailingWagePayRuleLine.Holiday_with_Double_Time_Pay__c = 'Christmas Day Company';
        prevailingWagePayRuleLine.Eligible_Holidays__c = 'Labor Day;Christmas Day Company';
        prevailingWagePayRuleLine.Peak_Season_Start__c= System.today();
            prevailingWagePayRuleLine.Peak_Season_End__c=System.today()+30;
        insert prevailingWagePayRuleLine;
        
         Pay_Rule_Line_Detail__c hoursBasedpayRuleLineDetail = new Pay_Rule_Line_Detail__c();
        hoursBasedpayRuleLineDetail.Pay_Rule_Line__c = prevailingWagePayRuleLine.Id;
        hoursBasedpayRuleLineDetail.Calculation_Type__c = 'Hour_Based';
        hoursBasedpayRuleLineDetail.Day__c = 'Monday';
        hoursBasedpayRuleLineDetail.Number_of_Hours__c = 8;
        hoursBasedpayRuleLineDetail.Rate_Code__c = 'REG';
        hoursBasedpayRuleLineDetail.Hours_After_Number_of_Hours__c = 2;
        hoursBasedpayRuleLineDetail.Rate_Code_After_Number_of_Hours__c = 'OT';
        hoursBasedpayRuleLineDetail.Rate_Code_for_Remaining_Hours__c = 'DT';
        insert hoursBasedpayRuleLineDetail;
        
        tsMgmt.setResMap(laborResLst);
        tsMgmt.setPayRuleMap(payRuleIdSet);
        //tsMgmt.setPayRuleHolidayMap(payRuleIdSet);
        tsMgmt.setPayRateByPayRuleAndResTypeMap(payRuleIdSet);
        tsMgmt.setPayRuleLineDetailMap(new set<Id>{prevailingWagePayRuleLine.Id});
        tsMgmt.createTSLinesFromTMLines(mapTS, tsLineLst, tmlLst, wkNumber.Week_Start_Date__c, wkNumber.Week_End_Date__c);
         for(Timesheet_Line__c tml:tsLineLst){
            tml.Start_Time__c = Time.newInstance(20, 30, 2, 20);
            tml.End_Time__c = Time.newInstance(19, 30, 2, 20);
             tml.Pay_Rule_Line_Detail__c = hoursBasedpayRuleLineDetail.Id;
        }
         CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;
        
        tsMgmt.processOvernightTravelTime(tsLineLst, wkNumber.Week_End_Date__c); //Ticket#24029
        tsMgmt.processTimesheetWithPayRuleLineDetails2(tsLineLst);
        tsMgmt.autoGeneratePayroll(sc,wkNumber);
        tsMgmt.processTimesheetLineWithPayRule(tsLineLst);
        tsMgmt.finalizeTimesheet(tsLineLst);
        tsMgmt.assignPayRate(tsLineLst);
        insert tsLineLst;
        tsMgmt.isPeakSeason(System.Today(),prevailingWagePayRuleLine);
        for(TM_Line__c tmLine:tmlLst){
            tmLine.Job_Start_Time__c = Time.newInstance(05, 0, 0, 0);
        }

        update tmlLst;

        try {

            Map<Id, String> timesheetErrorMsg = tsMgmt.verifyTimesheets(wkNumber, sc.Id);
        } catch (Exception e){

        }

        Test.stopTest();
    }
@IsTest static void testVerifyTimesheets1(){
    
     Test.startTest();
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        List<Timesheet_Line__c> tsLineLst = new List<Timesheet_Line__c>();
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c, Pay_Rule__r.Type__c, Pay_Rule__r.Mon_Sun_Work_Week__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c,Year__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Name = '01' LIMIT 1];

        Set<Id> payRuleIdSet = new Set<Id>();
        for(Resource__c res : laborResLst){
            payRuleIdSet.add(res.Pay_Rule__c);
        }

       
        List<TM_Line__c> tmlLst = tsMgmt.getTMLineList(wkNumber.Week_Start_Date__c, wkNumber.Week_End_Date__c, new Set<Id>{laborResLst[0].Id});
        List<Timesheet__c> tsLst = tsMgmt.createTimesheets(laborResLst, wkNumber);
        insert tsLst;
        
        Map<Id, Timesheet__c> mapTS = new Map<Id, Timesheet__c>();
        for(Timesheet__c ts : tsLst){
            mapTS.put(ts.Resource__c, ts);
        }
         CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        
        
      

        try {

            Map<Id, String> timesheetErrorMsg = tsMgmt.verifyTimesheets(wkNumber, sc.Id);
        } catch (Exception e){

        }

        Test.stopTest();
    }
    @IsTest static void testTimesheetTriggers() {
       Test.startTest();
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Name = '01' LIMIT 1];
        Salesperson__c salesperson = [SELECT Id FROM Salesperson__c LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        Subsidiary_Company__c subsidiaryCompany = [SELECT Id FROM Subsidiary_Company__c LIMIT 1];
        Sales_Order__c salesOrder = [SELECT Id, Service_Center__c, Service_Center__r.Name, Subsidiary_Company__c FROM Sales_Order__c LIMIT 1];
        Tax_Area__c taxArea = [SELECT Id FROM Tax_Area__c LIMIT 1];
        Resource_Type__c resourceType = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Unit_of_Measure__c unitOfMeasure = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];

        TM__c tm = new TM__c(
                Bill_to_Customer__c = account.Id,
                Project_Coordinator__c = salesperson.Id,
                Account_Executive__c = salesperson.Id,
                Prevailing_Wage_Job__c = true,
                Certified_PW_Job__c = true,
                Service_Center__c = sc.Id,
                Subsidiary_Company__c = subsidiaryCompany.Id,
                Tax_Area__c = taxArea.Id,
                Sales_Order__c = salesOrder.Id,
                Scheduled_Date__c = wkNumber.Week_Start_Date__c.addDays(1),
                Status__c = 'Confirmed'
        );
        insert tm;

        //sales order job task
        List<Sales_Order_Job_Task__c> salesOrderJobTasks = new List<Sales_Order_Job_Task__c>();
        Sales_Order_Job_Task__c salesOrderJobTask = new Sales_Order_Job_Task__c();
        salesOrderJobTask.Sales_Order__c = salesOrder.Id;
        salesOrderJobTask.Billing_Type__c = 'T&M';
        salesOrderJobTask.Line_No__c = 1;
        salesOrderJobTask.Task_No__c = 1;
        salesOrderJobTask.Name = 'Field Service';
        salesOrderJobTasks.add(salesOrderJobTask);
        insert salesOrderJobTasks;

        List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
        TM_Job_Task__c jobTask = new TM_Job_Task__c();
        jobTask.TM__c = tm.Id;
        jobTask.Name = salesOrderJobTask.Name;
        jobTask.Line_No__c = salesOrderJobTask.Line_No__c;
        jobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
        jobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;

        jobTasks.add(jobTask);
        insert jobTasks;

        TM_Line__c tml = new TM_Line__c(
                Line_No__c = 1,
                Description__c = 'Test Labor',
                Quantity__c = 12,
                Category__c = 'Labor',
                TM__c = tm.Id,
                Resource_Type__c = resourceType.Id,
                Resource__c = laborResLst[0].Id,
                Tax_Group__c = 'TX',
                Service_Center__c = sc.Id,
                Unit_of_Measure__c = unitOfMeasure.Id,
                Job_Start_Time__c = Time.newInstance(13, 0, 0, 0),
                Site_Start_Time__c = Time.newInstance(14, 0, 0 ,0),
                Site_End_Time__c = Time.newInstance(24, 0, 0, 0),
                Job_End_Time__c = Time.newInstance(01, 0, 0, 0),
                Lunch_Start_Time__c = Time.newInstance(14, 0, 0, 0),
                Lunch_End_Time__c = Time.newInstance(14,30,0,0),
                Lunch__c = '1/2 Hour',
                Total_Site_Hours__c = 12,
                Total_Job_Hours__c = 12,
                Regular_Hours__c = 8,
                Regular_Rate__c = 50,
                Overtime_Rate__c = 70,
                Overtime_Hours__c = 4,
                Unit_Price__c =  56.667,
                Hour__c = 12,
                TM_Job_Task__c = jobTask.Id
        );

        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        insert tml;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;

       
        Timesheet__c timesheet = new Timesheet__c();
        timesheet.Resource__c = laborResLst[0].Id;
        timesheet.Service_Center__c = laborResLst[0].Service_Center__c;
        timesheet.Week_No__c = wkNumber.Id;
        timesheet.Starting_Date__c = wkNumber.Week_Start_Date__c;
        timesheet.Ending_Date__c = wkNumber.Week_End_Date__c;
        timesheet.Status__c = 'Open';
        insert timesheet;

        try{
            timesheet.Name = '';
            update timesheet;
        } catch (Exception e){
            System.assertEquals(true, e.getMessage().contains('You are not allowed to change Timesheet No'));
        }

        Timesheet__c timesheet2 = new Timesheet__c();
        timesheet2.Name = timesheet.Name;
        timesheet2.Resource__c = laborResLst[0].Id;
        timesheet2.Service_Center__c = laborResLst[0].Service_Center__c;
        timesheet2.Week_No__c = wkNumber.Id;
        timesheet2.Starting_Date__c = wkNumber.Week_Start_Date__c;
        timesheet2.Ending_Date__c = wkNumber.Week_End_Date__c;
        timesheet2.Status__c = 'Open';
        try{
            insert timesheet2;
        } catch (Exception e){
            System.assertEquals(e.getMessage(), 'Duplicate Timesheet No. is not allowed. No.');
        }


        Timesheet_Line__c timesheetLine = new Timesheet_Line__c();
        timesheetLine.Timesheet__c = timesheet.Id;
        timesheetLine.Time_Type__c = 'Flat Pay';
        timesheetLine.Time_Type_Code__c = 'SPA';
        timesheetLine.Sales_Order_Service_Center__c = salesOrder.Service_Center__c;
        timesheetLine.Sales_Order__c = salesOrder.Id;
        timesheetLine.TM__c = tm.Id;
        timesheetLine.T_M_Line__c = tml.Id;
        timesheetLine.Week_Day__c = 'Monday';
        timesheetLine.Scheduled_Date__c = Date.valueOf('2018-01-01');

        try{
            timesheetLine.Sales_Order__c = null;
            insert timesheetLine;
        } catch (Exception e){
            timesheetLine.Sales_Order__c = salesOrder.Id;
            System.assertEquals(true, e.getMessage().contains('Sales Order field must not be blank for Flat Pay line!'));
        }

        try{
            timesheetLine.Net_Hours__c = 5.5;
            insert timesheetLine;
        } catch (Exception e){
            timesheetLine.Net_Hours__c = 0;
            System.assertEquals(true, e.getMessage().contains('Net Hours field for Flat Pay line must not have a value!'));
        }

        try{
            timesheetLine.Rate__c = 0;
            insert timesheetLine;
        } catch (Exception e){
            timesheetLine.Rate__c = 50;
            System.assertEquals(true, e.getMessage().contains('Rate field must not be blank or 0 for Flat Pay line!'));
        }

        try{
            timesheetLine.TM__c = null;
            insert timesheetLine;
         } catch (Exception e){
            timesheetLine.TM__c = tm.Id;
            System.assertEquals(true, e.getMessage().contains('T&M field must not be blank for Flat Pay line!'));
        }

        try{
            timesheetLine.T_M_Line__c = null;
            insert timesheetLine;
        } catch (Exception e){
            timesheetLine.T_M_Line__c = tml.Id;
            System.assertEquals(true, e.getMessage().contains('T&M Line must not be blank for Flat Pay line!'));
        }
        insert timesheetLine;

        Test.stopTest();
    }

    @IsTest static void testTLDeleteTriggers() {
    
      Test.startTest();
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Name = '01' LIMIT 1];
        Salesperson__c salesperson = [SELECT Id FROM Salesperson__c LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        Subsidiary_Company__c subsidiaryCompany = [SELECT Id FROM Subsidiary_Company__c LIMIT 1];
        Sales_Order__c salesOrder = [SELECT Id, Service_Center__c, Service_Center__r.Name, Subsidiary_Company__c FROM Sales_Order__c LIMIT 1];
        Tax_Area__c taxArea = [SELECT Id FROM Tax_Area__c LIMIT 1];
        Resource_Type__c resourceType = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Unit_of_Measure__c unitOfMeasure = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];


        TM__c tm = new TM__c(
                Bill_to_Customer__c = account.Id,
                Project_Coordinator__c = salesperson.Id,
                Account_Executive__c = salesperson.Id,
                Prevailing_Wage_Job__c = true,
                Certified_PW_Job__c = true,
                Service_Center__c = sc.Id,
                Subsidiary_Company__c = subsidiaryCompany.Id,
                Tax_Area__c = taxArea.Id,
                Sales_Order__c = salesOrder.Id,
                Scheduled_Date__c = wkNumber.Week_Start_Date__c.addDays(1),
                Status__c = 'Confirmed'
        );
        insert tm;

        //sales order job task
        List<Sales_Order_Job_Task__c> salesOrderJobTasks = new List<Sales_Order_Job_Task__c>();
        Sales_Order_Job_Task__c salesOrderJobTask = new Sales_Order_Job_Task__c();
        salesOrderJobTask.Sales_Order__c = salesOrder.Id;
        salesOrderJobTask.Billing_Type__c = 'T&M';
        salesOrderJobTask.Line_No__c = 1;
        salesOrderJobTask.Task_No__c = 1;
        salesOrderJobTask.Name = 'Field Service';
        salesOrderJobTasks.add(salesOrderJobTask);
        insert salesOrderJobTasks;

        List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
        TM_Job_Task__c jobTask = new TM_Job_Task__c();
        jobTask.TM__c = tm.Id;
        jobTask.Name = salesOrderJobTask.Name;
        jobTask.Line_No__c = salesOrderJobTask.Line_No__c;
        jobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
        jobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;

        jobTasks.add(jobTask);
        insert jobTasks;

        TM_Line__c tml = new TM_Line__c(
                Line_No__c = 1,
                Description__c = 'Test Labor',
                Quantity__c = 12,
                Category__c = 'Labor',
                TM__c = tm.Id,
                Resource_Type__c = resourceType.Id,
                Resource__c = laborResLst[0].Id,
                Tax_Group__c = 'TX',
                Service_Center__c = sc.Id,
                Unit_of_Measure__c = unitOfMeasure.Id,
                Job_Start_Time__c = Time.newInstance(13, 0, 0, 0),
                Site_Start_Time__c = Time.newInstance(14, 0, 0, 0),
                Site_End_Time__c = Time.newInstance(24, 0, 0, 0),
                Job_End_Time__c = Time.newInstance(01, 0, 0, 0),
                Lunch_Start_Time__c = Time.newInstance(14, 0, 0, 0),
                Lunch_End_Time__c = Time.newInstance(14, 30, 0, 0),
                Lunch__c = '1/2 Hour',
                Total_Site_Hours__c = 12,
                Total_Job_Hours__c = 12,
                Regular_Hours__c = 8,
                Regular_Rate__c = 50,
                Overtime_Rate__c = 70,
                Overtime_Hours__c = 4,
                Unit_Price__c = 56.667,
                Hour__c = 12,
                TM_Job_Task__c = jobTask.Id
        );

        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        insert tml;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;

       
        Timesheet__c timesheet = new Timesheet__c();
        timesheet.Resource__c = laborResLst[0].Id;
        timesheet.Service_Center__c = laborResLst[0].Service_Center__c;
        timesheet.Week_No__c = wkNumber.Id;
        timesheet.Starting_Date__c = wkNumber.Week_Start_Date__c;
        timesheet.Ending_Date__c = wkNumber.Week_End_Date__c;
        timesheet.Status__c = 'Approved';
        insert timesheet;

        Timesheet_Line__c timesheetLine = new Timesheet_Line__c();
        timesheetLine.Timesheet__c = timesheet.Id;
        timesheetLine.Time_Type__c = 'Job Time';
        timesheetLine.Time_Type_Code__c = 'REG';
        timesheetLine.Sales_Order_Service_Center__c = salesOrder.Service_Center__c;
        timesheetLine.Sales_Order__c = salesOrder.Id;
        timesheetLine.TM__c = tm.Id;
        timesheetLine.T_M_Line__c = tml.Id;
        timesheetLine.Week_Day__c = 'Monday';
        timesheetLine.Scheduled_Date__c = Date.valueOf('2018-01-01');
        timesheetLine.Start_Time__c = Time.newInstance(6,0,0,0);
        timesheetLine.End_Time__c = Time.newInstance(12,0,0,0);
        timesheetLine.Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        timesheetLine.Lunch_End_Time__c = Time.newInstance(12,30,0,0);
        timesheetLine.Lunch_Hours__c = 0.5;
        timesheetLine.Total_Hours__c = 6;
        timesheetLine.Net_Hours__c = 5.5;
        insert timesheetLine;

        try {
            CompanyMgmt.systemCall = false;
            delete timesheetLine;
        } catch (Exception e) {
            System.debug('eeee' + e.getMessage());
            System.assertEquals(true, e.getMessage().contains('Can not delete timesheet line when timesheet is in'));
        }
         Test.stopTest();
    }

    @IsTest static void testTimeOverlap(){
        Test.startTest();
        
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Name = '01' LIMIT 1];
        Salesperson__c salesperson = [SELECT Id FROM Salesperson__c LIMIT 1];
        Account account = [SELECT Id FROM Account LIMIT 1];
        Subsidiary_Company__c subsidiaryCompany = [SELECT Id FROM Subsidiary_Company__c LIMIT 1];
        Sales_Order__c salesOrder = [SELECT Id, Service_Center__c, Service_Center__r.Name, Subsidiary_Company__c FROM Sales_Order__c LIMIT 1];
        Tax_Area__c taxArea = [SELECT Id FROM Tax_Area__c LIMIT 1];
        Resource_Type__c resourceType = [SELECT Id FROM Resource_Type__c LIMIT 1];
        Unit_of_Measure__c unitOfMeasure = [SELECT Id FROM Unit_of_Measure__c LIMIT 1];
        Off_Type__c offType = [SELECT Id FROM Off_Type__c LIMIT 1];

        Date scheduleDate = wkNumber.Week_Start_Date__c.addDays(1);

        TM__c tm = new TM__c(
                Bill_to_Customer__c = account.Id,
                Project_Coordinator__c = salesperson.Id,
                Account_Executive__c = salesperson.Id,
                Prevailing_Wage_Job__c = true,
                Certified_PW_Job__c = true,
                Service_Center__c = sc.Id,
                Subsidiary_Company__c = subsidiaryCompany.Id,
                Tax_Area__c = taxArea.Id,
                Sales_Order__c = salesOrder.Id,
                Scheduled_Date__c = scheduleDate,
                Status__c = 'Confirmed'
        );
        insert tm;

        //sales order job task
        List<Sales_Order_Job_Task__c> salesOrderJobTasks = new List<Sales_Order_Job_Task__c>();
        Sales_Order_Job_Task__c salesOrderJobTask = new Sales_Order_Job_Task__c();
        salesOrderJobTask.Sales_Order__c = salesOrder.Id;
        salesOrderJobTask.Billing_Type__c = 'T&M';
        salesOrderJobTask.Line_No__c = 1;
        salesOrderJobTask.Task_No__c = 1;
        salesOrderJobTask.Name = 'Field Service';
        salesOrderJobTasks.add(salesOrderJobTask);
        insert salesOrderJobTasks;

        List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
        TM_Job_Task__c jobTask = new TM_Job_Task__c();
        jobTask.TM__c = tm.Id;
        jobTask.Name = salesOrderJobTask.Name;
        jobTask.Line_No__c = salesOrderJobTask.Line_No__c;
        jobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
        jobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;

        jobTasks.add(jobTask);
        insert jobTasks;

        TM_Line__c tml = new TM_Line__c(
                Line_No__c = 1,
                Description__c = 'Test Labor',
                Quantity__c = 12,
                Category__c = 'Labor',
                TM__c = tm.Id,
                Resource_Type__c = resourceType.Id,
                Resource__c = laborResLst[0].Id,
                Tax_Group__c = 'TX',
                Service_Center__c = sc.Id,
                Unit_of_Measure__c = unitOfMeasure.Id,
                Job_Start_Time__c = Time.newInstance(13, 0, 0, 0),
                Site_Start_Time__c = Time.newInstance(14, 0, 0, 0),
                Site_End_Time__c = Time.newInstance(24, 0, 0, 0),
                Job_End_Time__c = Time.newInstance(01, 0, 0, 0),
                Lunch_Start_Time__c = Time.newInstance(14, 0, 0, 0),
                Lunch_End_Time__c = Time.newInstance(14, 30, 0, 0),
                Lunch__c = '1/2 Hour',
                Total_Site_Hours__c = 12,
                Total_Job_Hours__c = 12,
                Regular_Hours__c = 8,
                Regular_Rate__c = 50,
                Overtime_Rate__c = 70,
                Overtime_Hours__c = 4,
                Unit_Price__c = 56.667,
                Hour__c = 12,
                TM_Job_Task__c = jobTask.Id
        );

        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        insert tml;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;

        Resource_Off__c resourceOff = new Resource_Off__c(
                Date__c = scheduleDate,
                Start_Time__c = Time.newInstance(02,0,0,0),
                End_Time__c = Time.newInstance(07, 0, 0, 0),
                Hours__c = 5,
                Total_Hours__c = 5,
                Resource__c = laborResLst[0].Id,
                Off_Type__c = offType.Id,
                Shop_Time_Category__c = 'Physical'
        );
        insert resourceOff;

        
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        Map<String, Map<Time, Time>> resTimeEntries = new Map<String, Map<Time, Time>>();
        Map<Id, String> resNameMap = new Map<Id, String>();
        Set<Id> processedLineIdSet = new Set<Id>();
        try{
            tsMgmt.checkTimeEntryOverlap(new Set<Id>{laborResLst[0].Id}, resTimeEntries, scheduleDate, scheduleDate, processedLineIdSet);
        } catch (Exception e){

        }
        Test.stopTest();
    }

    @IsTest static void testCreateTimesheetLineFromPWJob(){
       Test.startTest();
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c, Pay_Rule__r.Type__c, Pay_Rule__r.Mon_Sun_Work_Week__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Set<Id> payRuleIds = new Set<Id>();
        for(Pay_Rule__c payRule : [SELECT Id FROM Pay_Rule__c]){
            payRuleIds.add(payRule.Id);
        }
        List<Timesheet__c> timeSheets = tsMgmt.createTimesheets(laborResLst, wkNumber);
        Map<Id, Timesheet__c> timeSheetsByIds = new Map<Id, Timesheet__c>();
        for(Timesheet__c timesheet : timeSheets){
            timeSheetsByIds.put(timesheet.Resource__c, timesheet);
        }

        List<Timesheet_Line__c> timesheetLines = new List<Timesheet_Line__c>();


        
        List<TM_Line__c> tmLines = tsMgmt.getTMLineList(wkNumber.Week_Start_Date__c, wkNumber.Week_End_Date__c, new Set<Id>{laborResLst[0].Id});
        Set<Id> tmLineIds = new Set<Id>();
        for(TM_Line__c tmLine : tmLines){
            tmLineIds.add(tmLine.Id);
        }
        tsMgmt.setResourceFieldActivityLogMap(tmLineIds);
        tsMgmt.setResMap(laborResLst);
        tsMgmt.setPayRuleMap(payRuleIds);
        //tsMgmt.setPayRuleHolidayMap(payRuleIds);
        tsMgmt.setPayRateByPayRuleAndResTypeMap(payRuleIds);
        tsMgmt.createTSLinesFromTMLines(timeSheetsByIds, timesheetLines, tmLines, wkNumber.Week_Start_Date__c, wkNumber.Week_End_Date__c);
        tsMgmt.processOvernightTravelTime(timesheetLines, wkNumber.Week_End_Date__c); //Ticket#24029
        TimesheetTriggerMgmt.TSDelete(timeSheets);
        Test.stopTest();
    }

      @IsTest static void testsetTimesheetReopenReasonCode(){
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
        List<Resource__c> laborResLst = [SELECT Id, Description__c, Service_Center__c, Pay_Rule__c, Pay_Rule__r.Type__c, Pay_Rule__r.Mon_Sun_Work_Week__c FROM Resource__c WHERE Category__c = 'Labor'];
        Week_Number__c wkNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Name = '2018/01' LIMIT 1];
        Set<Id> payRuleIds = new Set<Id>();
        for(Pay_Rule__c payRule : [SELECT Id FROM Pay_Rule__c]){
            payRuleIds.add(payRule.Id);
        }
        List<Timesheet__c> timeSheets = tsMgmt.createTimesheets(laborResLst, wkNumber);
          insert timeSheets;
        Map<Id, String> timeSheetsByIds = new Map<Id, String>();
        for(Timesheet__c timesheet : timeSheets){
            timeSheetsByIds.put(timesheet.Resource__c, 'Success');
        }
          
    tsMgmt.setTimesheetReopenReasonCode(timeSheets,timeSheetsByIds);
      }
}