trigger RetainageLedgerEntryTrigger on Retainage_Ledger_Entry__c (before insert, before update, before delete) {
    if(Trigger.isBefore && CompanyMgmt.systemCall != true){
        throw new DataException('Retainage Ledger Entry is system only entry! Manual operation not allowed!');
    }
}