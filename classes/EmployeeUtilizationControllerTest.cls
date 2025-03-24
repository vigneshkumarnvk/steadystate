@isTest
public class EmployeeUtilizationControllerTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }

    public static testmethod void GetServiceCenters() {

        Service_Center__c sc = TestDataUtil.ServiceCenterRecord;
        TM__c TMRecord = TestDataUtil.TMRecord;

        Test.startTest();
        TM_Line__c TMLineLaborRecord = TestDataUtil.TMLineLaborRecord ;
        List<EmployeeUtilizationController.ServiceCenterWrapper> scList = EmployeeUtilizationController.getServiceCenters();
        List<EmployeeUtilizationController.TMLineWrapper> twrap = EmployeeUtilizationController.getTMLaborLinesPDF();
        EmployeeUtilizationController.TMLineWrapper wrp = New EmployeeUtilizationController.TMLineWrapper();
        wrp.ResourceNo = 'test';
        wrp.ResourceType = 'test';
        wrp.Description = 'test';
        wrp.Total_Hours = 10;
        wrp.SC_Hours = 10;
        wrp.IC_Hours = 10;
        wrp.Utilization = 10;
        EmployeeUtilizationController.verifyNumberOfDays(Date.Today().AddDays(-7), Date.Today().AddDays(7), True);
        EmployeeUtilizationController.verifyNumberOfDays(Date.Today().AddDays(-7), Date.Today().AddDays(7), False);
        EmployeeUtilizationController.calculateUtilization(10, Date.Today().AddDays(-7), Date.Today().AddDays(7), False);

        String SD = String.valueof(Date.Today().AddDays(-10).Year()) + '-' + String.valueof(Date.Today().AddDays(-10).Month()) + '-' + String.valueof(Date.Today().AddDays(-10).Day());
        String ED = String.valueof(Date.Today().AddDays(10).Year()) + '-' + String.valueof(Date.Today().AddDays(10).Month()) + '-' + String.valueof(Date.Today().AddDays(10).Day());
        EmployeeUtilizationController.getTMLaborLines(TMLineLaborRecord.Service_Center__c, SD, ED, 'true');

        Test.stopTest();
    }

}