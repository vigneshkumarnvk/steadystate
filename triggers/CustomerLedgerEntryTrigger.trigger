trigger CustomerLedgerEntryTrigger on Customer_Ledger_Entry__c (after insert, after update) {
    if (CompanyMgmt.byPassTrigger == true) return;

    //Ticket#22249 >>
    /*
    if(Trigger.isBefore){
        if(Trigger.isUpdate){
            for(Customer_Ledger_Entry__c customerLedgerEntry : Trigger.new){
                customerLedgerEntry.Processed__c = false;
            }
        }
    }
     */
    //Ticket#22249 <<

    if(Trigger.isAfter){
        if(Trigger.isUpdate || Trigger.isInsert){
            Map<String, Id> invoiceNoAndCLEMap = new Map<String, Id>();
            for(Customer_Ledger_Entry__c cle : Trigger.new){
                if(cle.Document_Type__c == 'Invoice'){
                    invoiceNoAndCLEMap.put(cle.Document_No__c, cle.Id);
                }
            }

            List<Sales_Invoice__c> siLst = [SELECT Id,Name,Customer_Ledger_Entry__c FROM Sales_Invoice__c
            WHERE Name IN :invoiceNoAndCLEMap.keySet()
            AND Customer_Ledger_Entry__c = null];
            for(Sales_Invoice__c si : siLst){
                si.Customer_Ledger_Entry__c = invoiceNoAndCLEMap.get(si.Name);
            }
            CompanyMgmt.systemCall = true;
            update siLst;
            CompanyMgmt.systemCall = false;
        }
    }
}