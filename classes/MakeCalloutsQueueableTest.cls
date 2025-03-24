@isTest
public class MakeCalloutsQueueableTest {

    @isTest
    static void testMakeCalloutsQueueable() {
        // Create test data - Sales Order IDs
        List<String> testSalesOrderIds = new List<String>{'a0u1L00004bbKgPQAU', 'a0u1L00004bbKgPQRE', 'a0u1L00004bbKgPQHF'};

        // Instantiate the MakeCalloutsQueueable with test data
        MakeCalloutsQueueable queueable = new MakeCalloutsQueueable(testSalesOrderIds, 0);

        // Enqueue the Queueable job
        Test.startTest();
        System.enqueueJob(queueable);
        Test.stopTest();

        // Validate the Queueable job has been enqueued
        List<AsyncApexJob> jobs = [SELECT Id FROM AsyncApexJob WHERE JobType = 'Queueable' LIMIT 1];
        System.assertNotEquals(0, jobs.size(), 'Queueable job should be enqueued');
    }
}