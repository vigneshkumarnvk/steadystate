/******************************************************************************************************
* Class Name: CreateContractBillingProjectBatch
* Description: This batch class query's all Contracts that status equal 'Activated' and utilizes asynchronous callout Contract Billing Package EQAI integration.
* ***************************************************************************************************
* Owner		        Task #			Date		Description
* Andrew Simons         76686                   2/21            Batch class created to send activated contracts to eqai create contract billing package
* ******************************************************************************************************/


public with sharing class CreateContractBillingProjectBatch implements Database.Batchable<SObject>, Database.Stateful{
    private List<String> contractIds;
    Integer queryLimit;
    String queryFilter;

    public CreateContractBillingProjectBatch() {
        BatchSettings__mdt contractBillingProjectQuerySize = [SELECT MasterLabel, Value__c FROM BatchSettings__mdt WHERE MasterLabel ='ContractBillingProjectQuerySize' LIMIT 1];
        BatchSettings__mdt contractBillingProjectQueryFilter = [SELECT MasterLabel, Query_Filter__c FROM BatchSettings__mdt WHERE MasterLabel ='ContractBillingProjectQueryFilter' LIMIT 1];
        // Retrieve the value from the custom metadata record
        queryLimit = Integer.valueOf(contractBillingProjectQuerySize.Value__c);
        queryFilter = String.valueOf(contractBillingProjectQueryFilter.Query_Filter__c);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query Activated Contracts
        String query = 'SELECT Id FROM Contract WHERE ' + queryFilter + ' LIMIT :queryLimit';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // Process records in batches based on the specified batch size - 10
        contractIds = new List<String>();
        List<Contract> contracts = (List<Contract>) scope;

        for (Contract contract : contracts) {
            contractIds.add(contract.Id);
        }

        if (!contractIds.isEmpty()) {
            // Create an instance of the queueable job
            ContractBillingProjectServiceQueueable cb = new ContractBillingProjectServiceQueueable(contractIds);

            // Enqueue the queueable job for execution
            System.debug(cb);
            System.enqueueJob(cb);

            System.debug('Enqueued Queueable job for callouts.');
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: Add any additional processing after batch completion
        System.debug('finished...');
    }
}
