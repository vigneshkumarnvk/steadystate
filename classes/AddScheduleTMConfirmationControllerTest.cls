@isTest
public class AddScheduleTMConfirmationControllerTest {

    private static testMethod void Test_AddScheduleTMConfirmation() {
        NewTestData.createTestData();

        /*
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];

        TM__c TMRecord=TestDataUtil.TMRecord;
        TM_Line__c TMLineRecord = TestDataUtil.TMLineLaborRecord;
         */
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        Test.setCurrentPageReference(new PageReference('Page.AddScheduleTMConfirmation'));
        System.currentPageReference().getParameters().put('selectedTMId', tm.id);
        AddScheduleTMConfirmationController a=new AddScheduleTMConfirmationController();
        a.returnToOpenTMs();
        a.changeStatusToSchedule();
        Datetime d = Date.today() ;
        a.scheduledDateValue =  d.format('MM/dd/yyyy') ;
        a.changeStatusToSchedule();
        
        a.ClosingNote = 'note';
        a.manuallyCloseTM();
        
        a.openTM();
        
        a.scheduledDateValue = '8/1/2018';
        a.cloneAndScheduleTM();
        Test.stopTest();
    }

}