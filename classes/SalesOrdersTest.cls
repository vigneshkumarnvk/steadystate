@IsTest
private class SalesOrdersTest {
    @TestSetup static void setupData(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;

        Billing_Rule__c br = new Billing_Rule__c(
                Name = 'test',
                Holidays_Bill_in_DT_Rate__c = 'Christmas Day Company',
                Holidays_Bill_in_OT_Rate__c = 'Thanksgiving',
                Sunday_Rate_Code__c = EnumUtil.TimeRateCode.DT.name(),
                Saturday_Rate_Code__c = EnumUtil.TimeRateCode.OT.name()
        );
        insert br;
		// Create bundles
        List<Billing_Rule_Line__c> billingRuleLines = new List<Billing_Rule_Line__c>();

        Billing_Rule_Line__c billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,30,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.Hours_After_Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Tuesday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Friday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Hours_After_Number_of_Hours__c = 3;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'DT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Day_Based';
        billingRuleLine.Day__c = 'Saturday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        if(billingRuleLines.size() > 0){
            insert billingRuleLines;
        }

        companySetup.Default_Billing_Rule__c = br.Id;
        update companySetup;

    }

    @IsTest
    private static void testUpdateWithoutDML(){
        //new method added
        Sales_Order__c oldSO = new Sales_Order__c(Name = 'Test', Customer_PO_No__c = '123',Document_Status__c='Open');Sales_Order__c newSO = new Sales_Order__c(
                Name = 'Test',
                Customer_PO_No__c = '1234',
                Approval_Step_Completed__c = true,
                Document_Status__c ='Closed',
                Approval_Status__c = EnumUtil.ApprovalStatus.PENDING_APPROVAL.name()
                );
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpBillingJobResponseGenerator());
        fflib_SObjectDomain.Test.Database.onUpdate(new Sales_Order__c[]{newSO}, new Map<Id, Sales_Order__c> {newSO.Id => oldSO});
        fflib_SObjectDomain.triggerHandler(SalesOrders.class);
        Test.stopTest();
    }
    @IsTest
    private static void testReopeJobBilling(){
        Sales_Order__c oldSO = new Sales_Order__c(Name = 'Test', Customer_PO_No__c = '123',Document_Status__c='Closed');Sales_Order__c newSO = new Sales_Order__c(
            Name = 'Test',
            Customer_PO_No__c = '1234',
            Approval_Step_Completed__c = true,
            Document_Status__c ='Open',
            Approval_Status__c = EnumUtil.ApprovalStatus.PENDING_APPROVAL.name()
        );
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpBillingJobResponseGenerator());
        fflib_SObjectDomain.Test.Database.onUpdate(new Sales_Order__c[]{newSO}, new Map<Id, Sales_Order__c> {newSO.Id => oldSO});
        fflib_SObjectDomain.triggerHandler(SalesOrders.class);
        Test.stopTest();
    }
    /*
    @IsTest
    private static void testValidateRateSheet(){
        Rate_Sheet__c rateSheetRec = new Rate_Sheet__c();
        rateSheetRec.Name = 'ACV Rate';
        insert rateSheetRec;

        List<Rate_Sheet_Line__c> rateSheetLines = new List<Rate_Sheet_Line__c>();
        //resource type line
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        //Resource type lines
        rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        insert rateSheetLines;

        Test.startTest();
        Rate_Sheet__c rateSheet = [SELECT Id FROM Rate_Sheet__c LIMIT 1];
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;
        salesOrder.Rate_Sheet__c = rateSheet.Id;
        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        salesLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        salesLines.add(salesLine);
        SalesOrdersService.validateRateSheet(salesOrder, salesLines, rateSheet.Id);

        //Ratesheet id does not exist
        Id fakeRatesheetId = fflib_IDGenerator.generate(Rate_Sheet__c.SObjectType);
        salesOrder.Rate_Sheet__c = fakeRatesheetId;
        try{
            SalesOrdersService.validateRateSheet(salesOrder, salesLines, rateSheet.Id);
        } catch (Exception e){
            System.assertEquals(e.getMessage().containsIgnoreCase('Rate Sheet is not found with rate sheet id'), true);
        }

        //Test blank
        salesOrder.Rate_Sheet__c = null;
        SalesOrdersService.validateRateSheet(salesOrder, salesLines, rateSheet.Id);
        Test.stopTest();
    }
     */

    /*
    @IsTest
    private static void testSalesLineService(){
        Rate_Sheet__c rateSheetRec = new Rate_Sheet__c();
        rateSheetRec.Name = 'ACV Rate';
        insert rateSheetRec;

        List<Rate_Sheet_Line__c> rateSheetLines = new List<Rate_Sheet_Line__c>();
        //resource type line
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        //Resource type lines
        rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        insert rateSheetLines;

        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;

        Rate_Sheet__c rateSheet = [SELECT Id FROM Rate_Sheet__c LIMIT 1];
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;
        salesOrder.Rate_Sheet__c = rateSheet.Id;
        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Category__c = 'Labor';
        salesLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        salesLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        salesLines.add(salesLine);

        Sales_Line__c salesLineResource = new Sales_Line__c();
        salesLineResource.Sales_Order__c = salesOrder.Id;
        salesLineResource.Category__c = 'Material';
        salesLineResource.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        salesLines.add(salesLineResource);

        Sales_Line__c wasteLine = new Sales_Line__c();
        wasteLine.Category__c = 'Waste Disposal';
        wasteLine.Resource__c = TestDataUtil.ResourceWasteDisposalRecord.Id;
        salesLines.add(wasteLine);

        Test.startTest();
        SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{salesOrder => salesLines});
        SalesLinesService.validateResourceType(salesOrder, salesLine);
        SalesLinesService.validateResourceType(salesOrder, salesLineResource);
        SalesLinesService.assignResourceUOM(salesLine);
        SalesLinesService.calcLaborUnitPrice(salesOrder, salesLine);
        SalesLinesService.assignResourceUOM(salesLineResource);
        SalesOrdersService.calcEstimatedDateInfo(salesOrder, salesLines, 1);
        SalesOrdersService.prepareManifestFeeLines(salesOrder, salesLines, new List<Sales_Line__c>{wasteLine}, 4);

        Test.stopTest();
    }
     */

    /*
    @IsTest
    private static void testSalesLineServiceWithQuoteDate(){
        Rate_Sheet__c rateSheetRec = new Rate_Sheet__c();
        rateSheetRec.Name = 'ACV Rate';
        insert rateSheetRec;

        List<Rate_Sheet_Line__c> rateSheetLines = new List<Rate_Sheet_Line__c>();
        //resource type line
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.HRUnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        //Resource type lines
        rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        insert rateSheetLines;

        Pricing__c priceList = new Pricing__c();
        priceList.Name = 'ACV Price List';
        insert priceList;

        Pricing_Rate_Sheet_Association__c pricingRateSheetAssociation = new Pricing_Rate_Sheet_Association__c();
        pricingRateSheetAssociation.Rate_Sheet__c = rateSheetRec.Id;
        pricingRateSheetAssociation.Effective_Date__c = Date.newInstance(2017,1,1);

        Company_Setup__c companySetup = [SELECT Id, Price_List__c FROM Company_Setup__c];
        companySetup.Price_List__c = priceList.Id;
        update companySetup;

        Sales_Order__c salesQuote = TestDataUtil.SalesQuoteRecordCSA;
        List<Sales_Line__c> quoteLines = new List<Sales_Line__c>();
        Sales_Line__c quoteLineRecord = new Sales_Line__c();
        quoteLineRecord.Sales_Order__c = salesQuote.Id;
        quoteLineRecord.Line_No__c = 1;
        quoteLineRecord.Description__c = 'Quoted Labor Item';
        quoteLineRecord.Quantity__c = 1;
        quoteLineRecord.UOM_Qty__c = 10;
        quoteLineRecord.Regular_Rate__c = 10;
        quoteLineRecord.Overtime_Rate__c = 15;
        quoteLineRecord.Premium_Rate__c = 15;
        quoteLineRecord.Regular_Hours__c = 4;
        quoteLineRecord.Overtime_Hours__c= 3;
        quoteLineRecord.Premium_Hours__c = 3;
        quoteLineRecord.Regular_Day__c = 1;
        quoteLineRecord.Overtime_Day__c= 1;
        quoteLineRecord.Premium_Day__c = 1;
        quoteLineRecord.Number_of_Day__c = 3;
        quoteLineRecord.Category__c = 'Labor';
        quoteLineRecord.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        quoteLineRecord.Unit_of_Measure__c = TestDataUtil.HRUnitMeasureRecord.Id;
        quoteLines.add(quoteLineRecord);

        quoteLineRecord = new Sales_Line__c();
        quoteLineRecord.Sales_Order__c = salesQuote.Id;
        quoteLineRecord.Line_No__c = 1;
        quoteLineRecord.Description__c = 'Quoted Labor Item';
        quoteLineRecord.Quantity__c = 1;
        quoteLineRecord.Unit_Price__c = 100;
        quoteLineRecord.Category__c = 'Materials';
        quoteLineRecord.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        quoteLines.add(quoteLineRecord);
        insert quoteLines;

        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.resourceUOMAssociationRec;

        Rate_Sheet__c rateSheet = [SELECT Id FROM Rate_Sheet__c LIMIT 1];
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;
        salesOrder.Rate_Sheet__c = rateSheet.Id;
        salesOrder.From_Sales_Quote__c = salesQuote.Id;

        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Category__c = 'Labor';
        salesLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        salesLine.Unit_of_Measure__c = TestDataUtil.HRUnitMeasureRecord.Id;
        salesLines.add(salesLine);

        Sales_Line__c salesLineResource = new Sales_Line__c();
        salesLineResource.Sales_Order__c = salesOrder.Id;
        salesLineResource.Category__c = 'Materials';
        salesLineResource.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        salesLines.add(salesLineResource);

        Test.startTest();
        SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{salesOrder => salesLines});
        SalesLinesService.validateResourceType(salesOrder, salesLine);
        SalesLinesService.validateResourceType(salesOrder, salesLineResource);
        SalesLinesService.assignResourceUOM(salesLine);
        SalesLinesService.calcLaborUnitPrice(salesOrder, salesLine);
        SalesLinesService.assignResourceUOM(salesLineResource);

        SalesLinesSelector.newInstance().selectLinesWithBundledLines(new Set<Id>{salesOrder.Id});
        SalesLinesSelector.newInstance().selectUnbundledLines(new Set<Id>{salesOrder.Id});
        SalesLinesSelector.newInstance().selectLinesBySalesOrderIdByCategory(new Set<Id>{salesOrder.Id}, new Set<String>{'Labor'});
        SalesLinesSelector.newInstance().selectBundledLines(new Set<Id>{salesOrder.Id});
        Test.stopTest();
    }
     */

    /*
    @IsTest
    private static void testSalesLineServiceWithContract(){

        Rate_Sheet__c rateSheetRec = new Rate_Sheet__c();
        rateSheetRec.Name = 'ACV Rate';
        insert rateSheetRec;

        List<Rate_Sheet_Line__c> rateSheetLines = new List<Rate_Sheet_Line__c>();
        //resource type line
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.HRUnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        //Resource
        rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        insert rateSheetLines;

        Pricing__c priceList = new Pricing__c();
        priceList.Name = 'ACV Price List';
        insert priceList;

        Pricing_Rate_Sheet_Association__c pricingRateSheetAssociation = new Pricing_Rate_Sheet_Association__c();
        pricingRateSheetAssociation.Rate_Sheet__c = rateSheetRec.Id;
        pricingRateSheetAssociation.Effective_Date__c = Date.newInstance(2017,1,1);

        Service_Center__c serviceCenter = [SELECT Id, Price_List__c FROM Service_Center__c];
        serviceCenter.Price_List__c = priceList.Id;
        update serviceCenter;

        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = TestDataUtil.resourceTypeUOMAssociationRec;
        ResourceUOMAssociation__c resourceUOMAssociation = TestDataUtil.materialResourceUOMAssociationRec;

        //System.debug('Info: resourceTypeUOMAssociation: ' + resourceTypeUOMAssociation );
        Contract contract = TestDataUtil.ContractRecordCustomer;
        List<Contract_Line__c> contractLines = new List<Contract_Line__c>();
        Contract_Line__c contractLine = new Contract_Line__c (
                Name = 'Test ContractLine',
                Contract__c = contract.Id,
                Regular_Rate__c = 10,
                Resource__c = TestDataUtil.ResourceMaterialRecord.Id,
                Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id
        );
        contractLines.add(contractLine);
        contractLine = new Contract_Line__c (
                Name = 'Resource Type Contract Line',
                Contract__c = contract.Id,
                Regular_Rate__c = 10,
                Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id,
                Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id
        );

        insert contractLines;

        Rate_Sheet__c rateSheet = [SELECT Id FROM Rate_Sheet__c LIMIT 1];
        Sales_Order__c salesOrder = TestDataUtil.SalesOrderRecordCSA;
        salesOrder.Rate_Sheet__c = rateSheet.Id;
        salesOrder.Contract__c = contract.Id;

        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Category__c = 'Labor';
        salesLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        salesLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        salesLine.Quantity__c = 1;
        salesLine.UOM_Qty__c = 12;
        salesLine.Regular_Hours__c = 8;
        salesLine.Overtime_Hours__c = 2;
        salesLine.Premium_Hours__c = 2;
        salesLine.Number_of_Day__c = 3;
        salesLine.Regular_Day__c = 1;
        salesLine.Overtime_Day__c = 1;
        salesLine.Premium_Day__c = 1;
        salesLines.add(salesLine);

        Sales_Line__c salesLineResource = new Sales_Line__c();
        salesLineResource.Sales_Order__c = salesOrder.Id;
        salesLineResource.Category__c = 'Materials';
        salesLineResource.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        salesLine.Quantity__c = 1;
        salesLines.add(salesLineResource);

        Test.startTest();
        SalesLinesService.populateLinesInfo(new Map<Sales_Order__c, List<Sales_Line__c>>{salesOrder => salesLines});
        SalesLinesService.validateResourceType(salesOrder, salesLine);
        SalesLinesService.validateResourceType(salesOrder, salesLineResource);
        SalesLinesService.assignResourceUOM(salesLine);
        SalesLinesService.calcLaborUnitPrice(salesOrder, salesLine);
        SalesLinesService.assignResourceUOM(salesLineResource);
        Test.stopTest();
    }
    */
    //test2
}