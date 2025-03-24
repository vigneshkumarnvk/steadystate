@IsTest
private class InterCompanyCostTrackingControllerTest {

    @IsTest
    private static void testCheckDates(){
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        ITMLinesSelector selectorTMLMock = new Mocks.TMLinesSelector(mocks);
        String dateStr = Date.today().month() + '/' + Date.today().day() + '/' + Date.today().year();



        mocks.startStubbing();
        Service_Center__c theSC = new Service_Center__c(
                Id = fflib_IDGenerator.generate(Service_Center__c.SObjectType),
                Name = 'Test'
        );
        TM__c theTM = new TM__c(
                Id = fflib_IDGenerator.generate(TM__c.SObjectType),
                Service_Center__c = theSC.Id
        );
        TM_Line__c tml1 = new TM_Line__c(
                Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                TM__c = theTM.Id,
                Service_Center__c = theSC.Id,
                Category__c = 'Labor',
                Line_Cost__c = 30
        );
        TM_Line__c tml2 = new TM_Line__c(
                Id = fflib_IDGenerator.generate(TM_Line__c.SObjectType),
                TM__c = theTM.Id,
                Service_Center__c = theSC.Id,
                Category__c = 'Labor',
                Line_Cost__c = 20
        );
        List<TM_Line__c> theTMLList = new List<TM_Line__c>{tml1, tml2};
        mocks.when(selectorTMLMock.sObjectType()).thenReturn(TM_Line__c.SObjectType);
        mocks.when(selectorTMLMock.selectInterCompanyLineByScheduledDateRange(Date.parse(dateStr), Date.parse(dateStr))).thenReturn(theTMLList);
        mocks.stopStubbing();
        Application.Selector.setMock(selectorTMLMock);

        System.currentPageReference().getParameters().put('startingDate', dateStr);
        System.currentPageReference().getParameters().put('endingDate', dateStr);
        ApexPages.StandardController standardController = new ApexPages.StandardController(theTM);
        InterCompanyCostTrackingController controller = new InterCompanyCostTrackingController(standardController);
        controller.checkDates();
        controller.startingDateValue = Date.today().month() + '/' + Date.today().addDays(1).day() + '/' + Date.today().year();
        controller.checkDates();
        controller.saveAsExcel();
        controller.showInterCompanyCost();


        ApexPages.StandardSetController standardSetController = new ApexPages.StandardSetController(new List<TM__c>{theTM});
        InterCompanyCostTrackingController setController = new InterCompanyCostTrackingController(standardSetController);
    }
}