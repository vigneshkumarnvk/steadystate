trigger PurchReceiptLineTrigger on Purch_Rcpt_Line__c (before insert, before update, before delete) {
    if (CompanyMgmt.byPassLineTrigger != true) {
        if (trigger.isDelete) {
            List<Purch_Rcpt_Line__c > PRLList = [SELECT Id,Receipt__c,Receipt__r.Document_Status__c FROM Purch_Rcpt_Line__c WHERE Id IN :Trigger.oldmap.keyset()];
            PurchTriggersMgmt.PRLDelete(PRLList, Trigger.OldMap);
        } else {
            List<Purch_Rcpt_Line__c > PRLList = Trigger.new;
            PurchTriggersMgmt.PRLInsertUpdate(PRLList);
        }
    }
}