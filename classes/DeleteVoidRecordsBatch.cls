public without sharing class DeleteVoidRecordsBatch implements Database.Batchable<SObject>{
    private String queryString = '';

    public DeleteVoidRecordsBatch(String inputQuery){
        queryString = inputQuery;
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        Database.delete(scope, false);
    }

    public void finish(Database.BatchableContext bc){}

}