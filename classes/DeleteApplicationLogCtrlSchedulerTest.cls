/*************************************************************************************************
* Name         :  DeleteApplicationLogCtrlSchedulerTest
* Description  :  Schedule the DeleteApplicationLogCtrl Batch class.
* class        :  DeleteApplicationLogCtrlScheduler

* Modification Log :
* Developer                   Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* 
*************************************************************************************************/
@isTest
public class DeleteApplicationLogCtrlSchedulerTest {
    @isTest
    static void batchSchedulerTest(){
        
        String cronExpression = '0 0 0 1 * ? *'; // 1st of every month at midnight
        
        Test.startTest();
        String jobId = System.schedule('Test Monthly Batch Job', cronExpression, new DeleteApplicationLogCtrlScheduler());

        Test.stopTest();

        Assert.areEqual(jobId !=null, true);
        
       /* DeleteApplicationLogCtrlScheduler scheduler = new DeleteApplicationLogCtrlScheduler();
        scheduler.execute(null);
        
        Test.stopTest();*/
    }
}