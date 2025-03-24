@isTest
public class PayrollMgmtTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }


    private static testMethod void Test_PayrollMgmt() {

        Payroll__c PayrollRecord =TestDataUtil.PayrollRecord;
        PayrollMgmt.validateWeekNo(PayrollRecord);
    }

    private static testMethod void Test_CompanyMgmt() {

        decimal halfUpTo5D=CompanyMgmt.halfUpTo5D(10);
        List<String>chkdelete=CompanyMgmt.checkDeleteGLB(TestDataUtil.GLBatchRecord);
        Decimal getSalesTax=CompanyMgmt.getSalesTax('test','test');
    }

}