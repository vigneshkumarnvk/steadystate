@IsTest
private class TMLinesTest {
    @IsTest
    private static void testUpdateTMLinesWhenResourceTypeChanged (){
        // Create mocks test
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

        // Given
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Account account = new Account(
                Id = fflib_IDGenerator.generate(Account.SObjectType),
                Pricing_Group__c = 'Silver'
        );
        Sales_Order__c theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Emergency_Sales_Order__c = false
        );
        TM__c theTM = new TM__c(
                Id = fflib_IDGenerator.generate(TM__c.SObjectType),
                Sales_Order__c = theSO.Id
        );
        Unit_of_Measure__c uom = new Unit_of_Measure__c(
                Id = fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType)
        );
        Unit_of_Measure__c uom1 = new Unit_of_Measure__c(
                Id = fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType)
        );
        Unit_of_Measure__c uom2 = new Unit_of_Measure__c(
                Id = fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType)
        );
        Unit_of_Measure__c uom3 = new Unit_of_Measure__c(
                Id = fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType)
        );
        Unit_of_Measure__c uom4 = new Unit_of_Measure__c(
                Id = fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType)
        );
        Resource_Type__c rt1 = new Resource_Type__c(
                Id = fflib_IDGenerator.generate(Resource_Type__c.SObjectType),
                Unit_of_Measure__c = uom.Id,
                Unit_of_Measure1__c = uom1.Id,
                Unit_of_Measure2__c = uom2.Id,
                Unit_of_Measure3__c = uom3.Id,
                Unit_of_Measure4__c = uom4.Id
        );
        TM_Line__c theTML = new TM_Line__c(
                Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                TM__c = theTM.Id,
                Category__c = 'Labor',
                Unit_of_Measure__c = uom.Id,
                Resource_Type__c = rt1.Id
        );
        Company_Setup__c theCompanySetup = new Company_Setup__c(
                Id = fflib_IDGenerator.generate(Company_Setup__c.SObjectType),
                T_M_Overtime_Multiplier__c = 1.5,
                T_M_Premium_Multiplier__c = 2
        );
        theTML.TM__r = new TM__c(Id = theTM.Id, Sales_Order__c = theSO.Id, Bill_to_Customer__c = account.Id);
        List<TM_Line__c> theTMLList = new List<TM_Line__c>();
        theTMLList.add(theTML);
        Application.UnitOfWork.setMock(uowMock);

        //When
        TMLines.mapSalesOrders.put(theSO.Id, theSO);
        TMLines.mapAccounts.put(account.Id, account);
        TMLines.mapResourceTypes.put(rt1.Id, rt1);
        TMLines.theCompanySetupValue = theCompanySetup;
        ITMLines TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom1.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom2.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom3.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom4.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theSO.Emergency_Sales_Order__c = true;
        TMLines.mapSalesOrders.put(theSO.Id, theSO);
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom3.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom2.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom1.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Category__c = 'Equipment';
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom1.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom2.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom3.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom4.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theSO.Emergency_Sales_Order__c = false;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom3.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom2.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom1.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Category__c = 'Materials';
        Resource__c r = new Resource__c (
                Id = fflib_IDGenerator.generate(Resource__c.SObjectType),
                Unit_of_Measure__c = uom.Id,
                Unit_of_Measure1__c = uom1.Id,
                Unit_of_Measure2__c = uom2.Id,
                Unit_of_Measure3__c = uom3.Id,
                Unit_of_Measure4__c = uom4.Id
        );
        theTML.Resource__c = r.Id;
        TMLines.mapResources.put(r.Id, r);
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom1.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom2.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom3.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom4.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theSO.Emergency_Sales_Order__c = true;
        theTML.Unit_of_Measure__c = uom4.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom3.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom2.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom1.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Unit_of_Measure__c = uom.Id;
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        Contract_Line__c cl = new Contract_Line__c(
                Id = fflib_IDGenerator.generate(Contract_Line__c.SObjectType),
                Regular_Rate__c = 1
        );
        theTML.Contract_Line__c = cl.Id;
        TMLines.mapContractLines.put(cl.Id, cl);
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Category__c = 'Equipment';
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        theTML.Category__c = 'Labor';
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

        Sales_Line__c theSL = new Sales_Line__c(
                Id = fflib_IDGenerator.generate(Sales_Line__c.SObjectType),
                Unit_Price__c = 998,
                Unit_of_Measure__c = uom.Id
        );
        theTML.Sales_Line__c = theSL.Id;
        TMLines.mapSalesLines.put(theSL.Id, theSL);
        TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenResourceTypeChanged();

    }

    @IsTest
    private static void testUpdateTMLinesWhenUnitOfMeasureChanged (){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        TM_Line__c theTML = new TM_Line__c(
                Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType)
        );
        List<TM_Line__c> theTMLList = new List<TM_Line__c>();
        ITMLines TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesWhenUnitOfMeasureChanged();
    }

    @IsTest
    private static void testUpdateTMLinesRestOfFields (){
        
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        Company_Setup__c theCompanySetup = TestDataUtil.CompanySetupRecord;

        Unit_of_Measure__c uom = new Unit_of_Measure__c(
                Id = fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType),
                Hours_UOM__c = true
        );
        Resource_Type__c rt = new Resource_Type__c(
                Id = fflib_IDGenerator.generate(Resource_Type__c.SObjectType),
                Unit_of_Measure__c = uom.Id
        );
        Resource__c r = new Resource__c(
                Id = fflib_IDGenerator.generate(Resource__c.SObjectType),
                Unit_of_Measure__c = uom.Id
        );
        TM_Line__c theTML = new TM_Line__c(
                Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                Hour__c = 1,
                Bill_Site_Time__c = true,
                Category__c = 'Labor',
                Resource_Type__c = rt.Id,
                Unit_of_Measure__c = uom.Id,
                Resource__c = r.Id,
                Bill_as_Lump_Sum__c = true
        );
        TM_Line__c theTML2 = new TM_Line__c(
                Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                Hour__c = 1,
                Bill_Site_Time__c = false,
                Category__c = 'Materials',
                Resource_Type__c = rt.Id,
                Unit_of_Measure__c = uom.Id,
                Resource__c = r.Id,
                Bill_as_Lump_Sum__c = true
        );
        List<TM_Line__c> theTMLList = new List<TM_Line__c>();
        theTMLList.add(theTML);
        theTMLList.add(theTML2);
        TMLines.mapResourceTypes.put(rt.Id, rt);
        TMLines.mapResources.put(r.Id, r);
        TMLines.mapUnitOfMeasures.put(uom.Id, uom);
        ITMLines TMLDomain = TMLines.newInstance(theTMLList);
        TMLDomain.updateTMLinesRestOfFields();
    }

    @IsTest
    private static void testPopulateLinesInfo(){
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        TM_Line__c tmLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.WASTE_DISPOSAL_CATEGORY);
        tmLines.add(tmLine);
        TM_Line__c laborLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY);
        tmLines.add(laborLine);
        Map<TM__c, List<TM_Line__c>> tmLinesByTm = new Map<TM__c, List<TM_Line__c>>();
        tmLinesByTm.put(tm, tmLines);
        TMLLinesService.populateLinesInfo(tmLinesByTm);
        TMLLinesService.isCalcBaseOnResType(laborLine.Category__c);
        TMLLinesService.validateResourceType(tm, laborLine, false);
        TMLLinesService.validateContractLine(tm, laborLine);
        laborLine.Resource_Type__c = null;
        TMLLinesService.validateContractLine(tm, laborLine);
        TMLLinesService.validateContractLine(tm, tmLine);
        tmLine.Resource__c = null;
        TMLLinesService.validateContractLine(tm, tmLine);
        Test.stopTest();
    }

    @IsTest
    private static void testPopulateLinesInfo2(){
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        TM_Line__c tmLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.WASTE_DISPOSAL_CATEGORY);
        tmLines.add(tmLine);
        TM_Line__c laborLine = NewTestData.mapTMLinesByTMIdByCategory.get(tm.Id).get(ResourceService.LABOR_CATEGORY);
        tmLines.add(laborLine);
        System.debug('Info: tmLines size: ' + tmLines.size());
        System.debug('Info: tmLines: ' + tmLines);
        Map<TM__c, List<TM_Line__c>> tmLinesByTm = new Map<TM__c, List<TM_Line__c>>();
        tmLinesByTm.put(tm, tmLines);
        TMLLinesService.initStaticVariables(tmLinesByTm);
        TMLLinesService.calcLineCost(tmLinesByTm);
        TMLLinesService.calcTotals(tmLinesByTm);
        TMLLinesService.validateResourceType(tm, laborLine, false);
        TMLLinesService.calcUnitCost(tm, laborLine);
        TMLLinesService.calcUnitPrice(tm,laborLine);
        Test.stopTest();
    }
    //test
}