/******************************************************************************************************
* Class Name: CreateWorkOrderQuoteOpenSOBatch
* Description: This class is utilized by the MakeCalloutsQueueable class and utilizes Schedulable
             
* ***************************************************************************************************
* Owner		        Task #			Date		Description
* Andrew Simons     
* ******************************************************************************************************/

public class MakeCalloutsSchedulable implements Schedulable {

    private List<String> salesOrderIds;
    private Integer index;

    public MakeCalloutsSchedulable(List<String> salesOrderIds, Integer index) {
        this.salesOrderIds = salesOrderIds;
        this.index = index;
    }

    public void execute(SchedulableContext sc) {
        
        MakeCalloutsQueueable nextJob = new MakeCalloutsQueueable(salesOrderIds, index);
        System.debug('execute...' +salesOrderIds + ' ' +index);
        System.enqueueJob(nextJob);
    }

    // Method to schedule the next job with a delay
    public static void scheduleNextJob(List<String> salesOrderIds, Integer index) {
        MakeCalloutsSchedulable schedulableJob = new MakeCalloutsSchedulable(salesOrderIds, index);
        String uniqueJobName = 'WOQ Delay Job ' + index + ' - ' + Datetime.now().getTime();
        System.schedule(uniqueJobName, System.now().addSeconds(5).format('ss mm HH dd MM ? yyyy'), schedulableJob);
    }
}