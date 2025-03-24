@isTest
public class PayrollControllerTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @TestSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Service_Center__c sc = TestDataUtil.ServiceCenterRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }

    @IsTest
    private static void Test_PayrollController() {

        Test.setCurrentPageReference(new PageReference('Page.ExportPayrollAsCSV'));
        Service_Center__c theSC=[Select Id,Name,Code__c from Service_Center__c Limit 1];
        theSC.Name='02';
        update theSC;
        User theUser=[Select Id,Service_Center__c From User where ID=:Userinfo.getUserId()]; 
        theUser.Service_Center__c='02';
        update theUser;

        Payroll__c    PayrollRecord = new Payroll__c (
                    Name='Test Payroll',
                    End_Date__c=Date.Today().addMonths(1).toStartofMonth().addDays(-1),
                    Start_Date__c=Date.Today().toStartofMonth(),
                  //Timesheet__c=TimesheetRecord.Id,
                    Service_Center__c= theSC.Id,
                    Week_Number__c=TestDataUtil.WeekNumberRecord.id
                );
        insert PayrollRecord ; 
        Resource__c ResourceRecord = new Resource__c(
                    Name = 'TRAN',
                    Fleet_Number__c = 'TR7',
                    Status__c = 'Active',
                    Plate_Number__c = 'TDF19P',
                    Plate_State__c = 'NJ',
                    Make__c = 'Car Mate',
                    //Vehicle_Year__c = 2000,
                    VIN__c = '5A3U616D1YL005502',
                    Country__c = 'US',
                    Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
                    Service_Center__c = theSC.Id,
                    Rent_Company__c = 'CVI',
                    Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id,
                    Unit_of_Measure__c=TestDataUtil.UnitMeasureRecord.id,
                    Tax_Group__c='NT',
                    Category__c='Labor',
                    Employee_Type__c='Employee'
                );
        insert ResourceRecord;        


        Timesheet__c  TimesheetRecord = new Timesheet__c (
                Name= 'Test TimesheetName',Service_Center__c=theSC.Id,
                Resource__c=ResourceRecord.Id,Status__c='Approved', Week_No__c=TestDataUtil.WeekNumberRecord.Id);
        TimesheetRecord.Service_Center__r = theSC;
        insert TimesheetRecord ;       

        PayrollController pc=new PayrollController();
        pc.listOpenTimesheet();
        pc.returnBack();
        pc.returnToPayrollList();
        pc.thePayroll=PayrollRecord;

        pc.CreatePayroll();
        List<Payroll__c> selectedPRList=New List<Payroll__c>();
        selectedPRList.add(PayrollRecord);
        pc.selectedPRList =selectedPRList;
        pc.validateWeekNo();
        pc.validatePayroll();
        pc.thePayroll=PayrollRecord;
        PayrollRecord.Status__c='open';
        update PayrollRecord;
        pc.release();
        PayrollRecord.Status__c='Approved';
        update PayrollRecord;
        pc.reopen();


    }

    @IsTest
    private static void Test_PayrollController2() {
        PageReference pref = Page.ExportPayrollConfirmation;
        Test.setCurrentPage(pref);
        List<Payroll__c>PCList=new List<Payroll__c>();
        PCList.add(TestDataUtil.PayrollRecord);
        ApexPages.StandardSetController  StdCon = new ApexPages.StandardSetController (PCList);
        PayrollController ROC = new PayrollController(StdCon);
        ROC.selectedPRList=PCList;
        ROC.ExportToCSV();
        List<Payroll_Line__c> selectedPRLineList=new List<Payroll_Line__c>();
        Payroll_Line__c payrollLine=TestDataUtil.PayrollLineRecord;
        selectedPRLineList.add(payrollLine);
        ROC.selectedPRLineList =selectedPRLineList ;
        ROC.prepareExportPayrollLine();
        Set<String>SetselectedPRIds = new Set<String>();
        SetselectedPRIds.add(TestDataUtil.PayrollRecord.Id);
        ROC.selectedPRIds=SetselectedPRIds;
        ROC.selectSelectedPayrollLines();
        ROC.selectSelectedPayroll();   
        ROC.fileName='Test';   
    }

    @IsTest
    private static void Test_PayrollMgmt() {
        Payroll__c PayrollRecord = TestDataUtil.PayrollRecord;
        PayrollMgmt.validateWeekNo(PayrollRecord);
    }

    @IsTest
    private static void Test_CompanyMgmt() {
        Decimal halfUpTo5D = CompanyMgmt.halfUpTo5D(10);
        List<String> chkdelete = CompanyMgmt.checkDeleteGLB(TestDataUtil.GLBatchRecord); 
        Decimal getSalesTax = CompanyMgmt.getSalesTax('test','test');       
    }

}