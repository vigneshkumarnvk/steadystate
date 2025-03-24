/*************************************************************************************************
* Name         :  DeleteApplicationLogCtrlScheduler 
* Description  :  Schedule the DeleteApplicationLogCtrl Batch class.
* Test class   :  DeleteApplicationLogCtrlSchedulerTest

* Modification Log :
* Developer                   Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* 
*************************************************************************************************/
public  class DeleteApplicationLogCtrlScheduler Implements Schedulable{
    
    public void execute(system.SchedulableContext sc) {
        
        DeleteApplicationLogCtrl batchJob = new DeleteApplicationLogCtrl();
        Database.executeBatch(batchJob, 200);
        
    }
}