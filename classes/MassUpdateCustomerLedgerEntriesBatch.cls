public with sharing class MassUpdateCustomerLedgerEntriesBatch implements Database.Batchable<SObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id, Processed__c FROM Customer_Ledger_Entry__c WHERE Processed__c = TRUE AND Document_Type__c IN (\'Invoice\', \'Credit_Memo\')';
        return Database.getQueryLocator(query);
        /*
        List<Customer_Ledger_Entry__c> customerLedgerEntries = [SELECT Id, Processed__c FROM Customer_Ledger_Entry__c WHERE Processed__c = TRUE
            AND Document_Type__c IN ('Invoice', 'Credit_Memo')
        ];
        return customerLedgerEntries;
         */
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope){
        try {
            List<Customer_Ledger_Entry__c> customerLedgerEntries = new List<Customer_Ledger_Entry__c>();
            customerLedgerEntries.addAll((List<Customer_Ledger_Entry__c>) scope);

            for (Customer_Ledger_Entry__c customerLedgerEntry : customerLedgerEntries) {
                customerLedgerEntry.Processed__c = false;
            }

            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            Database.update(customerLedgerEntries, false);
        } catch (Exception ex){
            throw new DataException('Error: ' + ex.getStackTraceString() + '   msg: ' + ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext bc){

    }
}