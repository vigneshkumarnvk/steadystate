/************************************************************************
 Class Name   : AutoLostSalesQuoteJob
 Created Date : 10/13/2023
 Description  :
 Author       : Steven
 Contributors  :
 ***************************** Update Logs *****************************
 ***********************************************************************
 */
public with sharing class AutoLostSalesQuoteJob implements Database.Batchable<SObject>, Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new AutoLostSalesQuoteJob(), 1000);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id, Quote_Status__c, Approval_Status__c FROM Sales_Order__c WHERE Document_Type__c = \'Sales Quote\' AND Expired__c = TRUE AND Quote_Status__c = \'Pending\' AND (Convert_Count__c = 0 OR Convert_Count__c = NULL)');
    }

    public void execute(Database.BatchableContext bc, List<Sales_Order__c> expiredSalesQuotes) {
        for(Sales_Order__c salesQuote : expiredSalesQuotes){
            if(salesQuote.Approval_Status__c == 'Approved') {
                salesQuote.Quote_Status__c = 'Lost';
            } else {
                salesQuote.Quote_Status__c = 'Canceled';
            }
        }
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        Database.update(expiredSalesQuotes, false);
    }

    public void finish(Database.BatchableContext bc){

    }
}