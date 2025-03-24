@IsTest
private class TMLLinesServiceTest {
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
    }
    
    @IsTest
    private static void testRetrieveContractLinesTMDescription(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        ITMLines domainMock = new Mocks.TMLines(mocks);
        IContractLinesSelector selectorMock = new Mocks.ContractLinesSelector(mocks);
        
        // Given
        mocks.startStubbing();
        Contract_Line__c cl = new Contract_Line__c(
            Id = fflib_IDGenerator.generate(Contract_Line__c.SObjectType),
            Name = 'Test Contract Line',
            T_M_Description__c = 'Test T&M Decription'
        );
        List<TM_Line__c> theTMLList = new List<TM_Line__c> {
            new TM_Line__c(
                Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                //Name = 'Test T&M Line',
                Contract_Line__c = cl.Id
            )
                };
                    mocks.when(domainMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.when(selectorMock.sObjectType()).thenReturn(Contract_Line__c.SObjectType);
        mocks.when(selectorMock.selectTMDescriptionById(new Set<Id>{cl.Id})).thenReturn(new Map<Id, Contract_Line__c>(new List<Contract_Line__c>{cl}));
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Domain.setMock(domainMock);
        Application.Selector.setMock(selectorMock);
        
        // When
        TMLLinesService.retrieveContractLinesTMDescription(theTMLList);
        
        // Then
        ((IContractLinesSelector)mocks.verify(selectorMock)).selectTMDescriptionById(new Set<Id>{cl.Id});
    }
    
    @IsTest
    private static void testValidateTMLinesResourceType(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        ITMLines domainMock = new Mocks.TMLines(mocks);
        ITMLinesSelector selectorMock = new Mocks.TMLinesSelector(mocks);
        
        // Given
        mocks.startStubbing();
        Resource_Type__c rt1 = new Resource_Type__c(
            Id = fflib_IDGenerator.generate(Resource_Type__c.SObjectType),
            Name = 'Robert Downey Jr'
        );
        Resource_Type__c rt2 = new Resource_Type__c(
            Id = fflib_IDGenerator.generate(Resource_Type__c.SObjectType),
            Name = 'Robert Downey Sr.'
        );
        
        TM_Line__c tml1 = new TM_Line__c(
            Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
            Resource_Type__c = rt1.Id
        );
        TM_Line__c tml2 = new TM_Line__c(
            Id = tml1.Id,
            Resource_Type__c = rt2.Id
        );
        List<TM_Line__c> theTMLList = new List<TM_Line__c>{tml1};
            Set<Id> testTMLSet = new Map<Id, TM_Line__c>(theTMLList).keySet();
        Map<Id, TM_Line__c> returnMap = new Map<Id, TM_Line__c>(new List<TM_Line__c>{tml2});
        mocks.when(domainMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.when(selectorMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.when(selectorMock.selectTMLMapWithResourceTypeAndResourceById(testTMLSet)).thenReturn(returnMap);
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Domain.setMock(domainMock);
        Application.Selector.setMock(selectorMock);
        
        // When
        TMLLinesService.validateTMLinesResourceType(theTMLList);
        
        // Then
        ((ITMLines) mocks.verify(domainMock)).updateTMLinesWhenResourceTypeChanged();
    }
    
    @IsTest
    private static void testValidateTMLinesUnitOfMeasure(){
        // Create mocks test
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        fflib_ISObjectUnitOfWork uowMock = new fflib_SObjectMocks.SObjectUnitOfWork(mocks);
        ITMLines domainMock = new Mocks.TMLines(mocks);
        ITMLinesSelector selectorMock = new Mocks.TMLinesSelector(mocks);
        IContractLinesSelector selectorMock2 = new Mocks.ContractLinesSelector(mocks);
        
        // Given test
        mocks.startStubbing();
        Contract c = new Contract(
            Id = fflib_IDGenerator.generate(Contract.SObjectType),
            Name = 'Test Contract'
        );
        Contract_Line__c cl = new Contract_Line__c(
            Id = fflib_IDGenerator.generate(Contract_Line__c.SObjectType),
            Name = 'Test Contract Line',
            T_M_Description__c = 'Test T&M Decription',
            Contract__c = c.Id
        );
        Unit_of_Measure__c uom1 = new Unit_of_Measure__c(
            Id = fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType),
            Name = 'Day'
        );
        Unit_of_Measure__c uom2 = new Unit_of_Measure__c(
            Id = fflib_IDGenerator.generate(Unit_of_Measure__c.SObjectType),
            Name = 'HR'
        );
        TM_Line__c tml1 = new TM_Line__c(
            Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
            Unit_of_Measure__c = uom1.Id
        );
        TM_Line__c tml2 = new TM_Line__c(
            Id = tml1.Id,
            Unit_of_Measure__c = uom2.Id
        );
        List<TM_Line__c> theTMLList = new List<TM_Line__c>{tml1};
            Set<Id> testTMLSet = new Map<Id, TM_Line__c>(theTMLList).keySet();
        Map<Id, TM_Line__c> returnMap = new Map<Id, TM_Line__c>(new List<TM_Line__c>{tml2});
        Set<Id> contractIdSet = new Set<Id>{c.Id};
            List<Contract_Line__c> returnList = new List<Contract_Line__c>{cl};
                
                mocks.when(domainMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.when(selectorMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.when(selectorMock2.sObjectType()).thenReturn(Contract_Line__c.SObjectType);
        mocks.when(selectorMock.selectTMLMapWithUnitOfMeasureById(testTMLSet)).thenReturn(returnMap);
        mocks.when(selectorMock2.selectLinesByContractId(contractIdSet)).thenReturn(returnList);
        mocks.stopStubbing();
        Application.UnitOfWork.setMock(uowMock);
        Application.Domain.setMock(domainMock);
        Application.Selector.setMock(selectorMock);
        //Application.Selector.setMock(selectorMock2);
        
        // When
        TMLLinesService.validateTMLinesUnitOfMeasure(theTMLList);
        // Then
        ((ITMLines) mocks.verify(domainMock)).updateTMLinesWhenUnitOfMeasureChanged();
    }
    @IsTest
    private static void testValidateTMLinesRestOfFields(){
        // Create mocks
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ITMLines domainMock = new Mocks.TMLines(mocks);
        
        // Given
        mocks.startStubbing();
        TM_Line__c tml1 = new TM_Line__c(
            Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType)
        );
        List<TM_Line__c> theTMLList = new List<TM_Line__c>{tml1};
            mocks.when(domainMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.stopStubbing();
        Application.Domain.setMock(domainMock);
        
        // When
        TMLLinesService.validateTMLinesRestOfFields(theTMLList);
        // TMLLinesService.validateTMResourceType(theTMLList);
        
        // Then
        ((ITMLines) mocks.verify(domainMock)).updateTMLinesRestOfFields();
        
        Map<TM__c, List<TM_Line__c>> tmlineMap = new Map<TM__c, List<TM_Line__c>>();
        TMLLinesService.validateTMRTStaticVariables(tmlineMap);
    }
    @isTest
    Private static void calcUnitCostTest(){
        
        /* Map<TM__c, List<TM_Line__c>>  mapOfTMLine = new Map<TM__c, List<TM_Line__c>>();

List<TM_Line__c> listOfTMLine = new List<TM_Line__c>();
listOfTMLine.add(TestDataUtil.TMLineDemurrageRecord);
listOfTMLine.add(TestDataUtil.TMLineLaborRecord);
listOfTMLine.add(TestDataUtil.TMLineSubcontractorsRecord);
listOfTMLine.add(TestDataUtil.TMLineMisChargeRecord);
listOfTMLine.add(TestDataUtil.TMLineLumpSumRecord);   
mapOfTMLine.put(TestDataUtil.TMRecord,listOfTMLine);
*/
        Map<TM__c, List<TM_Line__c>> tmlineMap = new Map<TM__c, List<TM_Line__c>>();
        test.StartTest();
        //TMLLinesService.initStaticVariables(mapOfTMLine);
        //TMLLinesService.validateUnitOfMeasure(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        //  TMLLinesService.validateUnitOfMeasure(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord,true);
        
        
        TMLLinesService.calcUnitCost(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        TMLLinesService.calcUnitPrice(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        TMLLinesService.validateResourceType(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        TMLLinesService.validateTMResourceType(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        TMLLinesService.initStaticVariables(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        TMLLinesService.calculateTravelHours(TestDataUtil.TMLineDemurrageRecord);
        // TMLLinesService.validateContractLine(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        TMLLinesService.isCalcBaseOnResType('Labour');
        //TMLLinesService.validateUnitOfMeasure(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        //TMLLinesService.validateUnitOfMeasure(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord,true);
        
        test.StopTest();
    }
    
    @isTest
    Private static void validateResourceTypeTest(){
        
        test.StartTest();
        TMLLinesService.validateResourceType(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        //TMLLinesService.validateResource(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        TMLLinesService.validateContractLine(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        
        test.StopTest();
    }
    @isTest
    Private static void validateResourceTest(){
        
        test.StartTest();
        TMLLinesService.validateResource(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        test.StopTest();
    }
    
    @isTest
    Private static void vvalidateContractLineTest(){
        
        test.StartTest();
        TMLLinesService.validateContractLine(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        TMLLinesService.validateResourceType(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord,true);
        test.StopTest();
    }
    
    @isTest
    Private static void validateUnitOfMeasureTest(){
        test.StartTest();
        TMLLinesService.validateUnitOfMeasure(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord);
        TMLLinesService.validateUnitOfMeasure(TestDataUtil.TMRecord,TestDataUtil.TMLineDemurrageRecord,true);
        test.StopTest();
    }
    
    
    @isTest
    Private static void testIsJobAndSiteTimeValid(){
        
        test.StartTest();
        TMLLinesService.isLunchTimeValid(system.now().addHours(-8).Time(),  system.now().Time(), system.now().addHours(-6).Time(), system.now().addHours(-5).Time(), system.now().addHours(-7).Time(), system.now().addHours(-1).Time());
        TMLLinesService.isJobAndSiteTimeValid(system.now().addHours(-8).Time(), system.now().Time(), system.now().addHours(-7).Time(), system.now().addHours(-1).Time());
        TMLLinesService.lunchTimeCheckForKronos(system.now().addHours(-8).Time(),  system.now().Time(), system.now().addHours(-6).Time(), system.now().addHours(-5).Time(), system.now().addHours(-7).Time(), system.now().addHours(-1).Time());
        test.StopTest();
    }
    
    @isTest
    Private static void initStaticVariablesTest(){
        
        Map<TM__c, List<TM_Line__c>> tmlineMap = new Map<TM__c, List<TM_Line__c>>();        
        test.StartTest();
        TMLLinesService.initStaticVariables(tmlineMap);
        TMLLinesService.populateLinesInfo(tmlineMap);
        TMLLinesService.calcTotals(tmlineMap);
        TMLLinesService.calcLineCost(tmlineMap);
        test.StopTest();
    }
    
    
    
    /* @isTest
Private static void testCreateSafetyPlanLine(){



test.StartTest();
NewTestData.createTestData();
ACVTMJobTaskWrapper queryJobWrapper = new ACVTMJobTaskWrapper();
queryJobWrapper.JobTask = [Select Id,Name FROM TM_Job_Task__c];
system.debug('queryJobWrapper.JobTask-----'+queryJobWrapper.JobTask);
//        TMLLinesService.initStaticVariables(TestDataUtil.TMRecord, jobTaskWrappers);

test.StopTest();

}*/
    
    @isTest
    Private static void testPopulateLinesInfo(){
        
        
    }
}