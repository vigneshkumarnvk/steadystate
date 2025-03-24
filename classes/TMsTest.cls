@IsTest
private class TMsTest {
    @testSetup static void setupData() {
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;

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

        TM__c tm = new TM__c(
            Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Rate_Sheet__c = rateSheetRec.Id,
            Prevailing_Wage_Job__c = true,
            Certified_PW_Job__c = true,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Sales_Order__c = TestDataUtil.SalesOrderRecord.Id,
            Scheduled_Date__c = Date.today().addDays(-7),
            Status__c = 'Confirmed');
        insert tm;

        TM_Line__c TMLineLaborRecord = new TM_Line__c(
            Line_No__c = 1,
            Description__c = 'Test item',
            Quantity__c = 1,
            Category__c = 'Labor',
            TM__c = tm.Id,
            Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Resource__c = TestDataUtil.ResourceLaborRecord.Id,
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
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            Job_Start_Time__c = system.now().addHours(-8).Time(),
            Job_End_Time__c = system.now().Time()
        );
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        insert TMLineLaborRecord;
    }

    @IsTest
    private static void testUpdateCustomerPONumber(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);

        // Given
        mocks.startStubbing();
        TM__c theTM = new TM__c(
                Id = fflib_IDGenerator.generate(TM__c.SObjectType),
                Customer_PO_No__c = '123',
                Sales_Order__c = fflib_IDGenerator.generate(Sales_Order__c.SObjectType)
        );
        Map<Id, String> poById = new Map<Id, String>{theTM.Sales_Order__c => '1234'};
        Company_Setup__c theCompanySetup = new Company_Setup__c(
                Id = fflib_IDGenerator.generate(Company_Setup__c.SObjectType),
                T_M_Overtime_Multiplier__c = 1.5,
                T_M_Premium_Multiplier__c = 2
        );
        List<TM__c> theTMList = new List<TM__c>{theTM};
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);

        // When
        TMs.theCompanySetupValue = theCompanySetup;
        ITMs domainTM = TMs.newInstance(theTMList);
        domainTM.updateCustomerPONumber(poById,uowMock);
    }

    @IsTest
    private static void testUpdateWithoutDML() {
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ISalesOrdersSelector selectorSOMock = new Mocks.SalesOrdersSelector(mocks);
        ITMLinesSelector selectorTMLMock = new Mocks.TMLinesSelector(mocks);
        IResourcesSelector selectorResourceMock = new Mocks.ResourcesSelector(mocks);
        ITMsSelector selectorTMMock = new Mocks.TMsSelector(mocks);


        mocks.startStubbing();
        Id theSOId = fflib_IDGenerator.generate(Sales_Order__c.SObjectType);
        TM__c newTM = new TM__c(
                Id = fflib_IDGenerator.generate(TM__c.SObjectType),
                Name = 'TL-01',
                Status__c = 'Received By Billing',
                Sales_Order__c = theSOId
        );
        TM__c oldTM = new TM__c(
                Id = newTM.Id,
                Name = 'TM-01',
                Status__c = 'Confirmed',
                Sales_Order__c = theSOId
        );

        String jsonStr = '{"Id" : "' + theSOId + '", "Sales_Order_Type__r" : {"Emergency_Response__c" : true}, "Service_Orders__r" : {"totalSize" : 1, "done" : true, "records" : [{"Id" : "'+  newTM.Id +'", "Sales_Order__c" : "'+ theSOId +'"}]}}';
        Sales_Order__c theSO  = (Sales_Order__c) JSON.deserialize(jsonStr, Sales_Order__c.class);
        Resource__c r = new Resource__c(
                Id = fflib_IDGenerator.generate(Resource__c.SObjectType),
                Description__c = 'test',
                Unit_of_Measure__c = fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType),
                Silver_Rate__c = 1.2
        );
        Company_Setup__c theCompanySetup = new Company_Setup__c(
                Default_Safety_Plan_Resource__c = r.Id
        );
        TMs.theCompanySetupValue = theCompanySetup;
        mocks.when(selectorSOMock.sObjectType()).thenReturn(Sales_Order__c.SObjectType);
        mocks.when(selectorTMLMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.when(selectorResourceMock.sObjectType()).thenReturn(Resource__c.SObjectType);
        mocks.when(selectorTMMock.sObjectType()).thenReturn(TM__c.SObjectType);
        mocks.when(selectorSOMock.selectTMsById(new Set<Id>{theSO.Id})).thenReturn(new List<Sales_Order__c>{theSO});
        mocks.when(selectorTMLMock.selectSafetyPlanLineByTMId(new Set<Id>{newTM.Id}, r.Id)).thenReturn(new List<TM_Line__c>());
        mocks.when(selectorResourceMock.selectById(new Set<Id>{r.Id})).thenReturn(new List<Resource__c>{r});
        mocks.when(selectorTMMock.selectTMLineNOById(new Set<Id>{newTM.Id})).thenReturn(new List<TM__c>{newTM});
        mocks.stopStubbing();
        Application.Selector.setMock(selectorSOMock);
        Application.Selector.setMock(selectorTMLMock);
        Application.Selector.setMock(selectorResourceMock);
        Application.Selector.setMock(selectorTMMock);

        fflib_SObjectDomain.Test.Database.onUpdate(new TM__c[]{newTM}, new Map<Id, TM__c>{newTM.Id => oldTM});
        fflib_SObjectDomain.triggerHandler(TMs.class);
    }

    @IsTest
    private static void testValidateRateSheet(){
        TM__c tm = [SELECT Id FROM TM__c LIMIT 1];
        Rate_Sheet__c rateSheet = [SELECT Id FROM Rate_Sheet__c];
        Test.startTest();
        List<TM__c> tms = TMsSelector.newInstance().selectByIds(new Set<Id>{tm.Id});
        List<TM_Line__c> tmLines = TMLinesSelector.newInstance().selectByTmId(new Set<Id>{tms[0].Id});
        tm = tms[0];
        TMsService.validateRateSheet(tm, tmLines, rateSheet.Id);

        //Ratesheet id does not exist
        Id fakeRatesheetId = fflib_IDGenerator.generate(Rate_Sheet__c.SObjectType);
        tm.Rate_Sheet__c = fakeRatesheetId;
        try{
            TMsService.validateRateSheet(tm, tmLines, rateSheet.Id);
        } catch (Exception e){
            System.assertEquals(e.getMessage().containsIgnoreCase('Rate Sheet is not found with rate sheet id'), true);
        }

        //Test blank
        tm.Rate_Sheet__c = null;
        TMsService.validateRateSheet(tm, tmLines, rateSheet.Id);
        Test.stopTest();
    }

    @IsTest
    private static void testTMLineDelete(){
        Test.startTest();
        TM__c tm = [SELECT Id FROM TM__c LIMIT 1];
        List<TM__c> tms = TMsSelector.newInstance().selectByIds(new Set<Id>{tm.Id});
        List<TM_Line__c> tmLines = TMLinesSelector.newInstance().selectByTmId(new Set<Id>{tms[0].Id});
        tm = tms[0];
        try {
            delete tmLines;
        } catch (Exception e){

        }
        tm.Project_Manager_Reviewed__c = true;
        update tm;
        tm.Scheduled_Date__c = System.today();
        update tm;
        TMsService.PMReviewSetNullByTMLineUpdated = true;
        update tm;
        Test.stopTest();
    }
    //test
}
