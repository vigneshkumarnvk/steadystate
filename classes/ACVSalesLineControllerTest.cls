/**
* Created by Kevin on 2/6/2020..
*/
@isTest
public with sharing class ACVSalesLineControllerTest {
    //fix.null.fields 
    /*
private static testMethod void testNewSalesLine() {
NewTestData.createTestData();
Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;

Test.startTest();

ACVSalesOrderWrapper salesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
Sales_Line__c salesLine = ACVSalesLineController.newSalesLine(JSON.serialize(salesOrderWrapper.SalesOrder), 'Labor', 10);

Test.stopTest();
}

private static testMethod void testValidateCategory() {
NewTestData.createTestData();
Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;

Test.startTest();

ACVSalesOrderWrapper salesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
for (Sales_Line__c salesLine : salesOrderWrapper.SalesLines) {
if (salesLine.Category__c == 'Labor') {
salesLine = ACVSalesLineController.validateCategory(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesLine));
break;
}
}

Test.stopTest();
}

private static testMethod void testValidateResourceType() {
NewTestData.createTestData();
Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;

Test.startTest();

ACVSalesOrderWrapper salesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
for (Sales_Line__c salesLine : salesOrderWrapper.SalesLines) {
if (salesLine.Category__c == 'Labor') {
salesLine = ACVSalesLineController.validateResourceType(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesLine));
salesLine = ACVSalesLineController.explodeSalesLineDetails(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesLine));
salesLine = ACVSalesLineController.recalculateSalesLineDetails(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesLine));
break;
}
}

Test.stopTest();
}

private static testMethod void testValidateResource() {
NewTestData.createTestData();
Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;

Test.startTest();

ACVSalesOrderWrapper salesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
for (Sales_Line__c salesLine : salesOrderWrapper.SalesLines) {
if (salesLine.Category__c == 'Waste Disposal') {
salesLine = ACVSalesLineController.validateResource(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesLine));
break;
}
}

Test.stopTest();
}

private static testMethod void testValidateNumberOfDays() {
NewTestData.createTestData();
Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;

Test.startTest();

ACVSalesOrderWrapper salesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
for (Sales_Line__c salesLine : salesOrderWrapper.SalesLines) {
if (salesLine.Category__c == 'Labor') {
salesLine = ACVSalesLineController.validateNumberOfDays(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesLine));
break;
}
}

Test.stopTest();
}

private static testMethod void testValidateUnitOfMeasure() {
NewTestData.createTestData();
Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;

Test.startTest();

ACVSalesOrderWrapper salesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
for (Sales_Line__c salesLine : salesOrderWrapper.SalesLines) {
if (salesLine.Category__c == 'Labor') {
salesLine = ACVSalesLineController.validateUnitOfMeasure(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesLine));
salesLine = ACVSalesLineController.calculatePriceAndCost(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesLine));
salesLine = ACVSalesLineController.calculateSalesLine(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesLine));
break;
}
}

Test.stopTest();
}

private static testMethod void testCalculateAllSalesLinesTotals() {
NewTestData.createTestData();
Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;

Test.startTest();

ACVSalesOrderWrapper salesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
salesOrderWrapper.SalesLines = ACVSalesLineController.calculateAllSalesLinesTotals(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.SalesLines));

Test.stopTest();
}
*/
    private static testMethod void testNewSalesLine() {
        NewTestData.createTestData();
        //Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(salesOrderWrapper.JobTaskWrappers);
        ACVSalesLineController.newSalesLine(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers[0].JobTask), 'Labor', nextSalesLineNo);
        
        Test.stopTest();
    }
    
    private static testMethod void testNewSalesLine2() {
        NewTestData.createTestData();
        //Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(salesOrderWrapper.JobTaskWrappers);
        ACVSalesLineController.newSalesLine(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers[0].JobTask), 'Subcontractors', nextSalesLineNo);
        
        Test.stopTest();
    }
    
    private static testMethod void testNewSalesLine3() {
        NewTestData.createTestData();
        //Sales_Order__c salesOrder = NewTestData.mapSalesOrderWrappersByName.get('SO1').SalesOrder;
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(salesOrderWrapper.JobTaskWrappers);
        ACVSalesLineController.newSalesLine(JSON.serialize(salesOrderWrapper.SalesOrder), JSON.serialize(salesOrderWrapper.JobTaskWrappers[0].JobTask), 'Bundled', nextSalesLineNo);
        
        Test.stopTest();
    }
    
    private static testMethod void testValidateCategory() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
        String JSONSalesOrder = JSON.serialize(salesOrderWrapper.SalesOrder);
        for (Sales_Line__c salesLine : jobTaskWrappers[0].SalesLines) {
            if (salesLine.Category__c == 'Labor') {
                String JSONSalesLine = ACVSalesLineController.validateCategory(JSONSalesOrderWrapper, JSON.serialize(salesLine));
                ACVSalesLineController.calculateLineTotals(JSONSalesOrderWrapper, JSONSalesLine);
                break;
            }
        }
        
        Test.stopTest();
    }
    
    private static testMethod void testValidateResourceType() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
        
        String JSONSalesOrder = JSON.serialize(salesOrderWrapper.SalesOrder);
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(jobTaskWrappers);
        for (Sales_Line__c salesLine : jobTaskWrappers[0].SalesLines) {
            if (salesLine.Category__c == 'Labor') {
                //ticket 19130 <<
                /*
String JSONJobTask = JSON.serialize(jobTaskWrappers[0].JobTask);
String JSONSalesLine = ACVSalesLineController.validateResourceType(JSONSalesOrder, JSONJobTask, JSON.serialize(salesLine), nextSalesLineNo);
*/
                String JSONJobTaskWrapper = JSON.serialize(jobTaskWrappers[0]);
                String JSONSalesLine = ACVSalesLineController.validateResourceType(JSONSalesOrder, JSONJobTaskWrapper, JSON.serialize(salesLine), nextSalesLineNo);
                //ticket 19130 >>
                nextSalesLineNo = ACVSalesLineController.getNextSalesLineNo(jobTaskWrappers[0], nextSalesLineNo);
                //String JSONChildLines = ACVSalesLineController.calculatePresumptiveChildLines(JSONSalesOrder, JSONJobTask, JSON.serialize(salesLine), nextSalesLineNo);
                ACVSalesLineController.calculateSalesLine(JSONSalesOrder, JSONSalesLine, true);
                break;
            }
        }
        
        Test.stopTest();
    }
    
    private static testMethod void testValidateResourceType2() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
        
        String JSONSalesOrder = JSON.serialize(salesOrderWrapper.SalesOrder);
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(jobTaskWrappers);
        for (Sales_Line__c salesLine : jobTaskWrappers[0].SalesLines) {
            if (salesLine.Category__c == 'Equipment') {
                //ticket 19130 <<
                /*
String JSONJobTask = JSON.serialize(jobTaskWrappers[0].JobTask);
String JSONSalesLine = ACVSalesLineController.validateResourceType(JSONSalesOrder, JSONJobTask, JSON.serialize(salesLine), nextSalesLineNo);
*/
                String JSONJobTaskWrapper = JSON.serialize(jobTaskWrappers[0]);
                String JSONSalesLine = ACVSalesLineController.validateResourceType(JSONSalesOrder, JSONJobTaskWrapper, JSON.serialize(salesLine), nextSalesLineNo);
                //ticket 19130 >>
                nextSalesLineNo = ACVSalesLineController.getNextSalesLineNo(jobTaskWrappers[0], nextSalesLineNo);
                //String JSONChildLines = ACVSalesLineController.calculatePresumptiveChildLines(JSONSalesOrder, JSONJobTask, JSON.serialize(salesLine), nextSalesLineNo);
                ACVSalesLineController.calculateSalesLine(JSONSalesOrder, JSONSalesLine, true);
                break;
            }
        }
        
        Test.stopTest();
    }
    
    private static testMethod void testValidateResource() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
        
        String JSONSalesOrder = JSON.serialize(salesOrderWrapper.SalesOrder);
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(jobTaskWrappers);
        for (Sales_Line__c salesLine : jobTaskWrappers[0].SalesLines) {
            if (salesLine.Category__c == 'Waste Disposal') {
                //ticket 19130 <<
                /*
String JSONJobTask = JSON.serialize(jobTaskWrappers[0].JobTask);
String JSONSalesLine = ACVSalesLineController.validateResource(JSONSalesOrder, JSONJobTask, JSON.serialize(salesLine), nextSalesLineNo);
*/
                String JSONJobTaskWrapper = JSON.serialize(jobTaskWrappers[0]);
                String JSONSalesLine = ACVSalesLineController.validateResource(JSONSalesOrder, JSONJobTaskWrapper, JSON.serialize(salesLine), nextSalesLineNo);
                //ticket 19130 >>
                ACVSalesLineController.calculateSalesLine(JSONSalesOrder, JSONSalesLine, true);
                break;
            }
        }
        
        Test.stopTest();
    }
    
    private static testMethod void testValidateNumberOfDays() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
        
        String JSONSalesOrder = JSON.serialize(salesOrderWrapper.SalesOrder);
        for (Sales_Line__c salesLine : jobTaskWrappers[0].SalesLines) {
            if (salesLine.Category__c == 'Labor') {
                ACVSalesLineController.validateNumberOfDays(JSONSalesOrder, JSON.serialize(salesLine));
                break;
            }
        }
        
        Test.stopTest();
    }
    
    private static testMethod void testValidateUnitOfMeasure() {
        NewTestData.createTestData();
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
        
        Test.startTest();
        
        String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
        ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = salesOrderWrapper.JobTaskWrappers;
        
        String JSONSalesOrder = JSON.serialize(salesOrderWrapper.SalesOrder);
        Integer nextSalesLineNo = ACVSalesOrderController.getNextSalesLineNo(jobTaskWrappers);
        for (Sales_Line__c salesLine : jobTaskWrappers[0].SalesLines) {
            if (salesLine.Category__c == 'Labor') {
                String JSONSalesLine = ACVSalesLineController.validateUnitOfMeasure(JSONSalesOrder, JSON.serialize(salesLine));
                JSONSalesLine = ACVSalesLineController.calculatePriceAndCost(JSONSalesOrder, JSONSalesLine);
                JSONSalesLine = ACVSalesLineController.calculateSalesLine(JSONSalesOrder, JSONSalesLine, true);
                break;
            }
        }
        
        Test.stopTest();
    }
    
    
    
    private static testMethod void testAssignUnitOfMeasure() {
        // Create test data
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
            Name = '1-ACV ENVIRO',
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
        
        Contract contract = TestDataUtil.ContractRecord;
        
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
            Surcharge_Type__c = 'N/A',
            Estimated_Job_Start_Date__c = Date.today(),
            Estimated_Job_End_Date__c = Date.today(),
            Duration__c = 1,
            Contract__c = contract.Id
        );
        insert theSO;
        
        Unit_of_Measure__c uom = new Unit_of_Measure__c( Name = 'Day',  Description__c = 'Area', Hours_UOM__c = false );
        insert uom;
        
        Resource_Type__c rt = new Resource_Type__c(Name = 'Test_RT',Unit_of_Measure__c = uom.Id);
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
            Unit_of_Measure__c = uom.Id,
            Employee_Type__c = 'Employee' ,
            Non_Payroll_Labor_Resource__c = false
        );
        insert r;
        
        Sales_Line__c theSL = new Sales_Line__c(
            Line_No__c = 1,
            Description__c = 'Test item',
            Unit_of_Measure__c = uom.Id,
            Quantity__c = 1100,
            UOM_Qty__c = 10,
            Regular_Hours__c = 10,
            Category__c = 'Bundled',
            Resource__c = r.Id,
            Sales_Order__c = theSO.Id,
            // Resource_Type__c = rt.Id,
            Number_of_Day__c = 1
        );
        insert theSL;
        
        SalesLinesServiceImpl sls = new SalesLinesServiceImpl();
        
        //Test Case 1: Test assignUnitOfMeasure with Sales_Line__c.
        sls.assignUnitOfMeasure(theSL);
        
        // // Test Case 2: Test assignUnitOfMeasure with Sales_Order__c and Sales_Line__c
        sls.assignUnitOfMeasure(theSO, theSL);
        
        // // Test Case 3: Test getDefaultContractUnitOfMeasure
        Id contractId = contract.Id; // Replace with a valid Contract Id
        Unit_of_Measure__c defaultUOM =  sls.getDefaultContractUnitOfMeasure(theSL, contractId);
    }
    
     private static testMethod void testAssignUnitOfMeasure1() {
        // Create test data
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
        Pay_Rule__c companyPayRuleRecord = new Pay_Rule__c(
            Name = 'Company Default',
            Pay_Holiday__c = true,
            Work_Before_or_After_Holiday_to_Qualify__c = true
        );
        insert companyPayRuleRecord;
        Company_Setup__c CompanySetupRecord = new Company_Setup__c(
            Name = 'Default',
            Lines_to_Insert__c = 5,
            Allow_Posting_From__c = Date.newInstance(2015, 1, 1),
            Allow_Posting_To__c = Date.newInstance(2019, 1, 1),
            Company_Pay_Rule__c = companyPayRuleRecord.Id
        );
        insert CompanySetupRecord;
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
            Name = '1-ACV ENVIRO',
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
        
        Contract contract = TestDataUtil.ContractRecord;
        
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
            Surcharge_Type__c = 'EEC Fee',
            Estimated_Job_Start_Date__c = Date.today(),
            Estimated_Job_End_Date__c = Date.today(),
            Duration__c = 1,
            Contract__c = contract.Id
        );
        insert theSO;
        
        Unit_of_Measure__c uom = new Unit_of_Measure__c( Name = 'Day',  Description__c = 'Area', Hours_UOM__c = false );
        insert uom;
        
        Resource_Type__c rt = new Resource_Type__c(Name = 'Test_RT',Unit_of_Measure__c = uom.Id);
        insert rt;
        Id recordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByDeveloperName().get('Other').getRecordTypeId();
        Resource__c r = new Resource__c(
            Name = 'ESIC',
            Fleet_Number__c = 'TR7',
            recordTypeId = recordTypeId,
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
            Category__c = 'Misc. Charges And Taxes',
            Unit_of_Measure__c = uom.Id,
            Employee_Type__c = 'Employee' ,
            Non_Payroll_Labor_Resource__c = false
        );
        insert r;
        
        Sales_Line__c theSL = new Sales_Line__c(
            Line_No__c = 1,
            Description__c = 'Test item',
            Unit_of_Measure__c = uom.Id,
            Line_Amount__c = 500,
            Quantity__c = 1100,
            UOM_Qty__c = 10,
            Regular_Hours__c = 10,
            Category__c = 'Bundled',
            Resource__c = r.Id,
            Sales_Order__c = theSO.Id,
            // Resource_Type__c = rt.Id,
            Number_of_Day__c = 1
        );
        insert theSL;
        
        SalesLinesServiceImpl sls = new SalesLinesServiceImpl();
        
        //Test Case 1: Test assignUnitOfMeasure with Sales_Line__c.
        sls.assignUnitOfMeasure(theSL);
        
        // // Test Case 2: Test assignUnitOfMeasure with Sales_Order__c and Sales_Line__c
        sls.assignUnitOfMeasure(theSO, theSL);
        
        // // Test Case 3: Test getDefaultContractUnitOfMeasure
        Id contractId = contract.Id; // Replace with a valid Contract Id
        Unit_of_Measure__c defaultUOM =  sls.getDefaultContractUnitOfMeasure(theSL, contractId);
              String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(theSO.Id);
            ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
            ACVSalesOrderJobTaskWrapper jobTaskWrappers = salesOrderWrapper.JobTaskWrappers[0];
            List<ACVSalesOrderJobTaskWrapper> ListOfjobTaskWrappers = salesOrderWrapper.JobTaskWrappers;   
            list<Sales_line__c>   listofSalesLine =new list<Sales_line__c>();
            for (Sales_Line__c salesLine : ListOfjobTaskWrappers[0].SalesLines) {
                
                listofSalesLine.add(salesLine);
                
            }
         Test.StartTest();
         SalesLinesServiceImpl serviceImpl = new SalesLinesServiceImpl();
         ACVSalesLineController.getValidUOMs('DM05');
         //serviceImpl.calculateSurchargeLine(theSO,jobTaskWrappers,8);
         Test.stopTest();

    }
    //fix.null.fields >>
    public static void testCostPlusMESResource() { 
        // Create a mock ResourceConfig__mdt record
        ResourceConfig__mdt mockConfig = new ResourceConfig__mdt(); 
        mockConfig.DeveloperName ='CostPlusMESResourceId'; 
        mockConfig.Value__c = 'a0rf4000001ZQVmAAO'; 
        // insert mockConfig; 
        // Call the method under test 
        String resourceId = ACVSalesLineController.getCostPlusMESResourceId(); 
        // Assert that the returned value matches the mock config value
        System.assert(resourceId == 'myCostPlusMESResourceId'); 
    }
    
    @isTest
    public static void testCostPlusMESResourceId() { 
        ACVSalesLineController.CostPlusMESResourceId();
    }
    
    @isTest
    public static void testCostPlusMESResourceId2() { 
        ACVSalesLineController.CostPlusMESResourceId2();
    }
    
    @isTest
    public static void testCostPlusMESDevName() { 
        ACVSalesLineController.CostPlusMESDevName();
    }
    
    /*@isTest
static void testcalculateLumpSumLine(){

//NewTestData.createTestData();
Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');


ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.SalesOrderRecord);


Sales_Line__c SalesLineRecord = TestDataUtil.SalesLineRecord;
SalesOrderController inst_SOC = new SalesOrderController(StdCon);
String title = inst_SOC.title;
Boolean open = inst_SOC.Open;
boolean allowDataOverride = inst_SOC.allowDataOverride;
boolean allowToCreateTM = inst_SOC.allowToCreateTM ;
inst_SOC.includeWeekend = false;
inst_SOC.tmCount = 6;
inst_SOC.startingDateValue = '01/02/2017';
Sales_Order__c SO = inst_SOC.salesOrder;
List<Sales_Line__c> SLList = inst_SOC.SLList;
inst_SOC.validateSalesOrderType();
inst_SOC.validateSalespeople();
inst_SOC.validateContract();

List<Sales_Line__c> SOListLaborLines = New List<Sales_Line__c>();
List<Sales_Line__c> SOListMaterialLines = New List<Sales_Line__c>();
List<Sales_Line__c> SOListEquipmentLines = New List<Sales_Line__c>();
List<Sales_Line__c> SOListEquipLines = New List<Sales_Line__c>();
List<Sales_Line__c> SOListLumpSumLines = New List<Sales_Line__c>();
List<Sales_Line__c> SOListWasteDisposalLines = New List<Sales_Line__c>();

SOListEquipLines.add(TestDataUtil.SalesEquipmentLineRecord);
SOListEquipLines.add(TestDataUtil.SalesLineRecord);
SOListEquipLines.add(TestDataUtil.SalesMaterialLineRecord);
SOListEquipLines.add(TestDataUtil.SalesMiscLineRecord);
SOListEquipLines.add(TestDataUtil.SalesLumpSumLineRecord);
SOListLumpSumLines.add(TestDataUtil.SalesLumpSumLineRecord);
SOListEquipLines.add(TestDataUtil.SalesWasteLineRecord);

Test.startTest();
SalesLinesServiceImpl serviceImpl = new SalesLinesServiceImpl();
serviceImpl.calculateLumpSumLine(SalesLineRecord,salesOrder,SOListEquipLines,true);
Test.stoptest();
}*/
    
    @isTest
    static void testremoveRinseOutFeeLine(){
        
        try{
            NewTestData.createTestData();
            
            Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
            String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
            ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
            ACVSalesOrderJobTaskWrapper jobTaskWrappers = salesOrderWrapper.JobTaskWrappers[0];
            List<ACVSalesOrderJobTaskWrapper> ListOfjobTaskWrappers = salesOrderWrapper.JobTaskWrappers;   
            list<Sales_line__c>   listofSalesLine =new list<Sales_line__c>();
            for (Sales_Line__c salesLine : ListOfjobTaskWrappers[0].SalesLines) {
                
                listofSalesLine.add(salesLine);
                
            }
            
            Test.startTest();
            SalesLinesServiceImpl serviceImpl = new SalesLinesServiceImpl();
            serviceImpl.removeRinseOutFeeLine(jobTaskWrappers);
            serviceImpl.addRinseOutFeeLine(salesOrder,jobTaskWrappers,5);
            serviceImpl.calculateSurchargeLine(salesOrder,jobTaskWrappers,8);
            serviceImpl.updateTotals(salesOrder,ListOfjobTaskWrappers);
            serviceImpl.calculateManifestFeeLine(salesOrder,jobTaskWrappers,5);
            // serviceImpl.calculateRinseOutFeeLine(salesOrder,jobTaskWrappers,5);
            //serviceImpl.calculateLumpSumLine(listofSalesLine[0],salesOrder,listofSalesLine,false);
            Test.stoptest();
            
        }catch(Exception e){
            
            
            NewTestData.createTestData();
            
            Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
            String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
            ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
            ACVSalesOrderJobTaskWrapper jobTaskWrappers = salesOrderWrapper.JobTaskWrappers[0];
            
            Test.startTest();
            SalesLinesServiceImpl serviceImpl = new SalesLinesServiceImpl();
            serviceImpl.calculateRinseOutFeeLine(salesOrder,jobTaskWrappers,5);
            
            Test.stoptest();
        }
        
    }
    
    @isTest
    static void testgetUnitCost(){
        
        Unit_of_Measure__c uom = new Unit_of_Measure__c( Name = 'Day',  Description__c = 'Area', Hours_UOM__c = false );
        insert uom;
        
        Resource_Type__c rt = new Resource_Type__c(Name = 'Test_RT');
        insert rt;
        
        Test.startTest();
        SalesLinesServiceImpl serviceImpl = new SalesLinesServiceImpl();
        serviceImpl.getUnitCost('labour',rt.Id,uom.Id);
        serviceImpl.getUnitPrice('labour', rt.Id,uom.Id, true);
        Test.stoptest();
        
    }
    
    @isTest
    static void testgetLaborCostWithFringeBenefitByResType(){
        
        Resource_Type__c rt = new Resource_Type__c(Name = 'Test_RT');
        insert rt;
        
        Subsidiary_Company__c subCompany = new Subsidiary_Company__c();
        subCompany.Name = 'Test Company';
        insert subCompany;
        
        Service_Center__c serviceCenter = new Service_Center__c();
        serviceCenter.Name = 'test center';
        serviceCenter.Code__c = '001';
        serviceCenter.Subsidiary_Company__c = subCompany.Id;
        insert serviceCenter;
        
        Pay_Rule__c payRule = new Pay_Rule__c();
        payRule.Name = 'Test PayRule';
        insert payRule;
        
        Test.startTest();
        SalesLinesServiceImpl serviceImpl = new SalesLinesServiceImpl();
        serviceImpl.getLaborCostWithFringeBenefitByResType(rt.Id, payRule.Id, serviceCenter.Id);
        Test.stoptest();       
    }
    
   /* @isTest
    Static void testassignDescription(){  
        
        Contract contract = new Contract();
        contract.Name = 'Contract of the day ' + Date.today();
        contract.AccountId = TestDataUtil.customerAccountRecord.Id;
        contract.StartDate = Date.today();
        contract.Status = 'Draft';
        contract.Subsidiary__c ='1-REPUBLIC SERVICES';
        insert contract;
        
        Sales_Order__c salesOrder = new Sales_Order__c();
        salesOrder.Name = 'NJ57506-01-2080';
        salesOrder.Surcharge_Type__c = 'N/A';
        salesOrder.Document_Type__c = 'Sales Order';
        salesOrder.Bill_to_Customer_No__c = TestDataUtil.customerAccountRecord.Id;
        salesOrder.Service_Center__c = TestDataUtil.ServiceCenterRecord.Id;
        salesOrder.Sales_Order_Type__c = TestDataUtil.SalesOrdertypeRecord.Id;
        salesOrder.Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id;
        salesOrder.Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id;
        salesOrder.Tax_Area__c = TestDataUtil.TaxAreaRecord.Id;
        salesOrder.Estimated_Job_Start_Date__c = Date.today();
        salesOrder.Contract__c = contract.Id;
        insert salesOrder;
        
        Sales_Order_Job_Task__c jobTask1 = new Sales_Order_Job_Task__c();
        jobTask1.Sales_Order__c = salesOrder.Id;
        jobTask1.Billing_Type__c = 'Fixed Price';
        jobTask1.Fixed_Price_Surcharge_Option__c = 'Fixed Price Does Not Include Surcharge';
        jobTask1.Line_No__c = 1;
        jobTask1.Task_No__c = 1;
        jobTask1.Name = 'Field Service';
        //jobTasks.add(jobTask1);
        insert jobTask1;
        
        Sales_Line__c salesLineLabor = new Sales_Line__c();
        salesLineLabor.Line_No__c = 1;
        salesLineLabor.Category__c = 'Labor';
        salesLineLabor.Description__c = 'Labor Line';
        salesLineLabor.Quantity__c = 1;
        salesLineLabor.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        salesLineLabor.UOM_Qty__c = 1;
        salesLineLabor.Regular_Hours__c = 1;
        salesLineLabor.Overtime_Hours__c= 0;
        salesLineLabor.Premium_Hours__c = 0;
        salesLineLabor.Regular_Day__c = 1;
        salesLineLabor.Overtime_Day__c= 0;
        salesLineLabor.Premium_Day__c = 0;
        salesLineLabor.Number_of_Day__c = 1;
        salesLineLabor.Sales_Order_Job_Task__c = jobTask1.Id;
        salesLineLabor.Sales_Order__c = salesOrder.Id;
        salesLineLabor.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        insert salesLineLabor;
        
        Test.startTest();
        SalesLinesServiceImpl serviceImpl = new SalesLinesServiceImpl();
        serviceImpl.assignDescription(salesOrder, salesLineLabor);
        Test.stoptest(); 
    }*/
    @isTest
    static void TestcalcUnitPrice(){
        NewTestData.createTestData();
            
            Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get('SO1');
            String JSONSalesOrderWrapper = ACVSalesOrderController.getSalesOrder(salesOrder.Id);
            ACVSalesOrderWrapper salesOrderWrapper = (ACVSalesOrderWrapper)JSON.deserialize(JSONSalesOrderWrapper, ACVSalesOrderWrapper.class);
        	List<Contract_Line__c> contractLine = NewTestData.mapContractWrappersByName.get('Contract').ContractLines;    
        Sales_Line__c testSalesLine = salesOrderWrapper.SalesLines[0];
            testSalesLine.Contract_Line__c =  contractLine[0].Id;
        testSalesLine.isContractLineNotEditable__c = false;
        testSalesLine.Regular_Unit_Cost__c = 5;
        testSalesLine.Category__c = 'Labor';
            Update testSalesLine;
       		ACVSalesOrderJobTaskWrapper jobTaskWrappers = salesOrderWrapper.JobTaskWrappers[0];
            SalesLinesServiceImpl myObj = new SalesLinesServiceImpl();
            Test.startTest();
        	myObj.calcUnitPrice(salesOrder,testSalesLine);
            myObj.calcLaborUnitCost(testSalesLine);
        //CompanyMgmt.getVFPageName();
            Test.stopTest();

    }
    //test2
}