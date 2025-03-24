@isTest
public class TimesheetControllerTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = :companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }

    private static testMethod void Test_TimesheetSetController() {
        List<Timesheet__c>TSList = New List<Timesheet__c>();
        TSList.add(TestDataUtil.TimesheetRecord);

        ApexPages.StandardSetController StdCon = new ApexPages.StandardSetController (TSList);
        TimesheetController TC = new TimesheetController(StdCon);
    }

    private static testMethod void Test_TimesheetController() {

        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        PageReference pref = Page.Timesheet;
        Test.setCurrentPage(pref);
        Timesheet__c TimesheetRecord = new Timesheet__c (Name = 'Test TimesheetName', Resource__c = TestDataUtil.ResourceLaborRecord.Id, Service_Center__c = TestDataUtil.ServiceCenterRecord.Id, Status__c = 'Approved', Week_No__c = TestDataUtil.WeekNumberRecord.Id);
        insert TimesheetRecord ;
        pref.getParameters().put('id', TimesheetRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.TimesheetRecord);
        TimesheetController TC = new TimesheetController(StdCon);

        Timesheet_Line__c TimesheetLineRecord = TestDataUtil.TimesheetLineRecord;
        List<Timesheet_Line__c> timesheetLineList = New List<Timesheet_Line__c>();
        timesheetLineList.add(TimesheetLineRecord);
        Map<String, Timesheet__c> mapTS = New Map<String, Timesheet__c>();
        Set<String> tmIdSet = New Set<String>();
        mapTS.put(TestDataUtil.TimesheetRecord.Id, TestDataUtil.TimesheetRecord);
        tmIdSet.add(TestDataUtil.TimesheetRecord.Id);

        List<TM_Line__c > TMLineList = New List<TM_Line__c >();
        TMLineList.Add(TestDataUtil.TMLineLaborRecord);
        TC.RefreshTimesheet();
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theJobPosition');
        pref.getParameters().put('newFieldValue', '');
        String title = TC.title;
        Timesheet__c TS = TC.TS;

        List<Timesheet_Line__c > TSLList = TC.TSLList;
        Company_Setup__c CompanySetup = TC.CompanySetup;
        TC.msave();
        TC.save();
        TC.quickSave();
        TC.saveNapprove();
        TC.insertLine();
        TC.deleteLine();
        TC.cancel();
        TC.release();
        TC.reopen();
        Tc.validateWeekNo();
        TC.returnBack();
        TC.returnToTimesheetList();
        Service_Center__c ServiceCenterRecord = TestDataUtil.ServiceCenterRecord;
        TC.theSC = ServiceCenterRecord;
        TC.weekStartingDate = Date.Today().toStartofWeek();
        TC.weekEndingDate = Date.Today().toStartofWeek().addDays(7);
        TC.listTMNotReadyForTimesheet();
        TC.listLaborResNotReadyForTimesheet();
        Set<String> pwJobIds = new Set<String>();
        //TC.CreateTimesheet();
        mapTS.Put(TestDataUtil.ResourceRecord.Id, TestDataUtil.TimesheetRecord);
        Resource_Off__c ResourceOffRecord = TestDataUtil.ResourceOffRecord;
        TC.refreshTimesheets();
        mapTS.Clear();
        mapTS.Put(TestDataUtil.ResourceLaborRecord.Id, TestDataUtil.TimesheetRecord);
        tmIdSet.add(TestDataUtil.TMRecord.Id);
        CompanyMgmt.byPassTrigger = false;
        Test.stopTest();
    }

    private static testMethod void Test_TimesheetValidate() {
        PageReference pref = Page.Timesheet;
        Test.setCurrentPage(pref);
        pref.getParameters().put('id', TestDataUtil.TimesheetRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TestDataUtil.TimesheetRecord);
        TimesheetController TC = new TimesheetController(StdCon);
        Test.StartTest();
        Timesheet_Line__c TimesheetLineRecord = TestDataUtil.TimesheetLineRecord;
        List<Timesheet_Line__c> theTSLList = new List<Timesheet_Line__c>();
        theTSLList.Add(TimesheetLineRecord);
        TC.theTSLList = theTSLList;
        pref.getParameters().put('lineNo', '0');
        pref.getParameters().put('fieldName', 'theResourceOff');
        pref.getParameters().put('newFieldValue', TestDataUtil.ResourceOffRecord.Id);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theParentLine');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theSalesOrder');
        pref.getParameters().put('newFieldValue', TestDataUtil.SalesOrderRecord.Id);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theSalesOrderSC');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theTM');
        pref.getParameters().put('newFieldValue', TestDataUtil.TMRecord.Id);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theTML');
        pref.getParameters().put('newFieldValue', TestDataUtil.TMLineLaborRecord.Id);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theCertifiedPWJob');
        pref.getParameters().put('newFieldValue', 'True');
        TC.validateField();

        pref.getParameters().put('fieldName', 'theCustomerName');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theJobDescription');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theLunchHours');
        pref.getParameters().put('newFieldValue', '1');
        TC.validateField();

        pref.getParameters().put('fieldName', 'theNetHours');
        pref.getParameters().put('newFieldValue', '2');
        TC.validateField();

        pref.getParameters().put('fieldName', 'thePrevailingWageJob');
        pref.getParameters().put('newFieldValue', 'true');
        TC.validateField();

        pref.getParameters().put('fieldName', 'thePWJobTypeCode');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();
        /*
        pref.getParameters().put('fieldName', 'theRateType');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();
        */
        pref.getParameters().put('fieldName', 'theSalesOrderDescription');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theSalesOrderType');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theScheduledDate');
        pref.getParameters().put('newFieldValue', '03/03/2019');
        TC.validateField();

        pref.getParameters().put('fieldName', 'theTimeType');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theTotalHours');
        pref.getParameters().put('newFieldValue', '10');
        TC.validateField();

        pref.getParameters().put('fieldName', 'theWeekDay');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();
        /*
        pref.getParameters().put('fieldName', 'theRateType');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theRateType');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();
          */
        pref.getParameters().put('fieldName', 'theLunchStartTime');
        pref.getParameters().put('newFieldValue', '2');
        TC.validateField();

        pref.getParameters().put('fieldName', 'theLunchEndTime');
        pref.getParameters().put('newFieldValue', '10:2');
        TC.validateField();

        pref.getParameters().put('fieldName', 'theStartTime');
        pref.getParameters().put('newFieldValue', Null);
        TC.validateField();

        pref.getParameters().put('fieldName', 'theLunchStartTime');
        pref.getParameters().put('newFieldValue', '2');
        TC.validateField();

        pref.getParameters().put('fieldName', 'theEndTime');
        pref.getParameters().put('newFieldValue', '2');
        TC.validateField();

        Test.StopTest();
    }


    private static testMethod void Test_TimesheetMgmt() {

        Test.StartTest();
        Timesheet__c TimesheetRecord = TestDataUtil.TimesheetRecord;
        Timesheet_Line__c TimesheetLineRecord = TestDataUtil.TimesheetLineRecord;
        List<Timesheet_Line__c> theTSLList = new List<Timesheet_Line__c>();
        theTSLList.add(TimesheetLineRecord);
        TimesheetMgmt.checkSave(TimesheetRecord, theTSLList);
        TimesheetMgmt.updateTSL(TimesheetRecord, TimesheetLineRecord, 'theScheduledDate');
        TimesheetMgmt.updateTSL(TimesheetRecord, TimesheetLineRecord, 'theTimeType');
        TimesheetMgmt.updateTSL(TimesheetRecord, TimesheetLineRecord, 'theStartTime');
        TimesheetMgmt.updateTSL(TimesheetRecord, TimesheetLineRecord, 'theEndTime');
        TimesheetMgmt.updateTSL(TimesheetRecord, TimesheetLineRecord, 'theLunchStartTime');
        TimesheetMgmt.getDatetimeInUserTZ(System.now());
        //TimesheetMgmt.calculateHours(Time.newInstance(1, 2, 3, 4),Time.newInstance(2, 2, 3, 4));
        TimesheetMgmt.validateWeekNo(TimesheetRecord);
        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        tsMgmt.deleteTimesheetLine(theTSLList);
        TimesheetMgmt.nullRelationshipFields(TimesheetRecord);
        Test.StopTest();
    }
    private static testMethod void Test_TimesheetController1() {
        Test.startTest();
        PageReference pref = Page.Timesheet;
        Test.setCurrentPage(pref);
        Timesheet__c TimesheetRecord = new Timesheet__c (Name = 'Test TimesheetName', Resource__c = TestDataUtil.ResourceLaborRecord.Id, Service_Center__c = TestDataUtil.ServiceCenterRecord.Id, Status__c = 'Approved', Week_No__c = TestDataUtil.WeekNumberRecord.Id);
        insert TimesheetRecord ;
        pref.getParameters().put('id', TimesheetRecord.Id);
        ApexPages.StandardController StdCon = new ApexPages.StandardController(TimesheetRecord);
        TimesheetController TC = new TimesheetController(StdCon);
        Service_Center__c ServiceCenterRecord = TestDataUtil.ServiceCenterRecord;
        TC.theSC = ServiceCenterRecord;
        TC.weekStartingDate = Date.Today().toStartofWeek();
        TC.weekEndingDate = Date.Today().toStartofWeek().addDays(7);
        TC.CreateTimesheet();
        Test.stopTest(); 
    }
    //test
}