trigger SalesInvoiceTrigger on Sales_Invoice__c (before insert, before update, before delete, after update, after insert) {

    fflib_SObjectDomain.triggerHandler(SalesInvoices.class);

    if(Trigger.isBefore){
        if (trigger.isDelete) {
            List<Sales_Invoice__c> InvoiceList = Trigger.old;
            SalesInvoiceTriggersMgmt.SIDelete(InvoiceList);
        } else {
            List<Sales_Invoice__c> InvoiceList = Trigger.new;
            SalesInvoiceTriggersMgmt.SIInsertUpdate(InvoiceList, trigger.oldMap, trigger.isInsert);
        }
    }
}