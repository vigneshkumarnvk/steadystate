/******************************************************************************************************
* Class Name: CreateWorkOrderQuoteOpenSOBatch
* Description: This class is utilized by the CreateWorkOrderQuoteOpenSOBatch class and utilizes Queueable 
               interface to perform asynchronous callout to workOrderQuoteHeaderInfo 
* ***************************************************************************************************
* Owner		        Task #			Date		Description
* 
* ******************************************************************************************************/
public class MakeCalloutsQueueable implements Queueable {

    private List<String> salesOrderIds;
    private Integer index;

    public MakeCalloutsQueueable(List<String> salesOrderIds, Integer index) {
        this.salesOrderIds = salesOrderIds;
        this.index = index;
    }

    @future(callout=true)
    public static void executeFuture(String salesOrderId) {
        // Call workOrderQuoteHeaderInfo API for each sales order asynchronously
        System.debug('api called...');
        workOrderQuoteService.workOrderQuoteHeaderInfo(salesOrderId);
    }

    public void execute(QueueableContext context) {
        if (index < salesOrderIds.size()) {
            String salesOrderId = salesOrderIds.get(index);
            System.debug('Making callout for Sales Order ID: ' + salesOrderId);
            executeFuture(salesOrderId);
            if (index + 1 < salesOrderIds.size()) {
                Integer nextIndex = index + 1;
                // Schedule the next job with a delay
                MakeCalloutsSchedulable.scheduleNextJob(salesOrderIds, nextIndex);
            }
        }
    }

    // Method to start the process
    // public static void start(List<String> salesOrderIds) {
    //     if (salesOrderIds != null && !salesOrderIds.isEmpty()) {
    //         MakeCalloutsQueueable firstJob = new MakeCalloutsQueueable(salesOrderIds, 0);
    //         System.enqueueJob(firstJob);
    //     }
    // }
}