public with sharing class MassDeleteCustomerRevenueBatch implements Database.Batchable<SObject>{
    public Database.QueryLocator start(Database.BatchableContext bc){
        String query = 'SELECT Id FROM Customer_Revenue__c';
        //List<Customer_Revenue__c> customerRevenues = [SELECT Id FROM Customer_Revenue__c];
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, List<SObject> scope){
        try{
            List<Customer_Revenue__c> customerRevenues = new List<Customer_Revenue__c>();
            customerRevenues.addAll((List<Customer_Revenue__c>)scope);
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            Database.delete(customerRevenues, false);
        } catch (Exception ex) {
            throw new DataException('Error: ' + ex.getStackTraceString() + '   msg: ' + ex.getMessage());
        }
    }

    public void finish(Database.BatchableContext BC){

    }
}