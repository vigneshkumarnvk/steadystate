public with sharing class SalesOrderLightningDataXFieldsBatchable implements Database.Batchable<Sales_Line__c> {

    public List<Sales_Line__c> start(Database.BatchableContext bc) {
        //return [SELECT Id, Unit_Price__c, xUnit_Price__c, Unit_Cost__c, Line_Cost__c, Line_Amount__c FROM Sales_Line__c WHERE Category__c <> 'Lump Sum' AND Bill_as_Lump_Sum__c <> TRUE AND xUnit_Cost_Updated__c <> TRUE LIMIT 50000];
        return null;
    }

    public void execute(Database.BatchableContext BC, List<Sales_Line__c> salesLines) {
        /*
        try {
            SalesOrderLightningDataManagement.UpdateXFields(salesLines);
        }
        catch(exception ex) {
            System.abortJob(bc.GetJobId());
            throw ex;
        }
        */
    }
    
    public void finish(Database.BatchableContext bc) {

    }

}