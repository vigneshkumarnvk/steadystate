/************************************************************************************************************
 * Name         :  ScheduledFlatPayFileTest
 * Description  :  Test class for ScheduledFlatPayFile
 *
 * @author Michael Duran
 * @date 06/27/2022
 *
 * Modification Log :
 * Developer                 Date                   Description
 * -----------------------------------------------------------------------------------------------------------                 
 * 
 *************************************************************************************************************/

@isTest
public class ScheduledFlatPayFileTest {

    static testmethod void Test_ScheduledFlatPayFile() {
		
        Test.startTest();
        
        ScheduledFlatPayFile s = new ScheduledFlatPayFile();
        
        CompanyMgmt.byPassTrigger = true;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
		
        Service_Center__c sc = TestDataUtil.ServiceCenterRecord;
        Resource__c theResource = TestDataUtil.ResourceRecord;
        Payroll__c thePayroll = TestDataUtil.PayrollRecord;
        Payroll_Line__c thePayrollLine = TestDataUtil.PayrollLineRecord;
        Timesheet__c theTimeSheet = TestDataUtil.TimesheetRecord;
        Timesheet_Line__c theTimeSheetLine = TestDataUtil.TimesheetLineRecord;
        
        CompanyMgmt.byPassTrigger = false;
        Service_Center__c theSC=[Select Id,Name,Code__c from Service_Center__c Limit 1];
        theSC.Name='01';
        update theSC;
        
        thePayroll.End_Date__c = Date.Today();
        thePayroll.Start_Date__c = Date.Today() - 7;
        thePayroll.Status__c = 'Approved';
        thePayroll.Service_Center__c = theSC.Id;
        update thePayroll;
        
        thePayrollLine.Payroll__r = thePayroll;
        thePayrollLine.Timesheet__c = theTimeSheet.Id;
        thePayrollLine.Timesheet_Line__c = theTimeSheetLine.Id;
        update thePayrollLine;
        
        theTimeSheetLine.Time_Type__c = 'Flat Pay';
        update theTimeSheetLine;

        s.execute(null);
        
        Integer invocations = Limits.getEmailInvocations();

        Test.stopTest();
        
        system.assertEquals(1, invocations, 'An email was sent');
        
    }
}