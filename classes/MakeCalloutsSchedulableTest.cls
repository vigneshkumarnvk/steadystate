@isTest
public class MakeCalloutsSchedulableTest {

    
    @isTest
    static void testQueueableJobExecution() {
        // Prepare test data
        List<String> testSalesOrderIds = new List<String>{'a0u1L00004bbKgPQAU', 'a0u1L00004bbKgPQRE'};
        
        // Create a Queueable job instance
        MakeCalloutsQueueable queueableJob = new MakeCalloutsQueueable(testSalesOrderIds, 0);
        
        // Execute the Queueable job
        Test.startTest();
        System.enqueueJob(queueableJob);
        Test.stopTest();
        
        // Verify the Queueable job execution
        List<AsyncApexJob> jobs = [SELECT Id, Status, JobType FROM AsyncApexJob WHERE JobType = 'Queueable' AND Status = 'Completed'];
        System.assertEquals(1, jobs.size(), 'Queueable job should be executed');
    }
}