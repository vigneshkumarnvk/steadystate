/************************************************************************
 Class Name   : AutoLostSalesQuotesJobTest
 Created Date : 11/9/2023  
 Description  : 
 Author       : Steven 
 Contributors  :
 ***************************** Update Logs *****************************
 ***********************************************************************
 */
@IsTest
private class AutoLostSalesQuotesJobTest {
    @TestSetup
    static void testDataSetup(){
        NewTestData.createTestData();
        Sales_Order__c salesQuote = NewTestData.mapSalesOrdersByName.get('SQ1');
        salesQuote.Estimated_Job_Start_Date__c = System.today().addDays(-70);
        salesQuote.Quote_Status__c = 'Pending';
        salesQuote.Convert_Count__c = 0;
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        update salesQuote;
    }
    @IsTest
    static void autoLostSalesQuoteJob() {
        Test.startTest();
        AutoLostSalesQuoteJob autoLostSalesQuoteJob = new AutoLostSalesQuoteJob();
        String cronJob = '0 48 * * * ?';
        String jobId = System.schedule('Test Job', cronJob, autoLostSalesQuoteJob);
        Database.executeBatch(new AutoLostSalesQuoteJob(), 10);
        Sales_Order__c salesQuote = [SELECT Id, Expired__c, Expiration_Date__c, Convert_Count__c, Quote_Status__c, Approval_Status__c FROM Sales_Order__c WHERE Name = 'SQ1' LIMIT 1];
        salesQuote.Quote_Status__c = 'Pending';
        salesQuote.Approval_Status__c = 'Approved';
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        Database.executeBatch(new AutoLostSalesQuoteJob(), 10);
        update salesQuote;
        Test.stopTest();
    }
}