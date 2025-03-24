trigger SignatureTrigger on Signature__c (after insert, after update) {
    /*
    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {        
            Map<Id, Signature__c> mapSignaturesByTmId = new Map<Id, Signature__c>();

            for (Signature__c sig : Trigger.New) {
                if (sig.Related_To_Object_Name__c == 'TM__c' && sig.Voided__c != true) {
                    mapSignaturesByTmId.put(sig.Related_to_Id__c, sig);
                }
            }

            List<TM__c> tms = new List<TM__c>();
            for (TM__c tm : [SELECT Id FROM TM__c WHERE Id IN :mapSignaturesByTmId.keySet()]) {
                if (mapSignaturesByTmId.containsKey(tm.Id)) {
                    Signature__c sig = mapSignaturesByTmId.get(tm.Id);
                    tm.Accept_Terms_And_Conditions__c = sig.Accept_Terms_And_Conditions__c;
                    tm.Customer_Not_Available__c = sig.Customer_Not_Available__c;
                    tm.Field_TM_PDF_Recipient__c = sig.Email__c;
                    tm.Mobile_TM__c = true;
                    tms.add(tm);                        
                }
            }

            if (tms.size() > 0) {
                update tms;
            }
        }
    }*/

    if (CompanyMgmt.byPassTrigger != true) {
        if (Trigger.isAfter) {
            if (Trigger.isInsert || Trigger.isUpdate) {
                List<TM__c> tms = new List<TM__c>();
                for (Signature__c signature : Trigger.new) {
                    if (signature.Signer_Role__c == 'Supervisor') {
                        TM__c tm = new TM__c(Id = signature.TM__c);
                        tm.Completed_By__c = signature.Print_Name__c;
                        tms.add(tm);
                    }
                }
                CompanyMgmt.byPassTrigger = true;
                update tms;
                CompanyMgmt.byPassTrigger = false;
            }
        }
    }
}