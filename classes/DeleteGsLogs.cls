public without sharing class DeleteGsLogs implements Database.Batchable<SObject>{

    public DeleteGsLogs(){}

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator('SELECT Id FROM RDNACadence__Logger__c');
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope){
        Database.delete(scope, false);
    }

    public void finish(Database.BatchableContext BC){}
}