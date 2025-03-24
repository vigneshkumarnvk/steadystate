trigger AsyncRequestTrigger on AsyncRequest__c (after insert) {
    if (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
        try {
            AsyncProcessor.enqueue(null);
        } catch (Exception e){
            AsyncProcessor.tryToQueue();
        }
    }
}