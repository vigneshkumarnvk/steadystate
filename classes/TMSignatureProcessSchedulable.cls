public with sharing class TMSignatureProcessSchedulable implements Schedulable {
    public void execute(SchedulableContext sc) {
        TMSignatureProcessBatchable batchable = new TMSignatureProcessBatchable();
        batchable.Task = 'Signature';
        Database.executeBatch(batchable, 1); 
    }
}