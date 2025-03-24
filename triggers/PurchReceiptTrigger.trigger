trigger PurchReceiptTrigger on Purchase_Receipt__c (before insert, before update, before delete) {
    if (trigger.isDelete) {
        List<Purchase_Receipt__c> PRList = Trigger.old;        
        PurchTriggersMgmt.PRDelete(PRList);            
    } else {
        List<Purchase_Receipt__c> PRList = Trigger.new;
        PurchTriggersMgmt.PRInsertUpdate(PRList, Trigger.OldMap, Trigger.IsInsert);            
    }    
    
    //change tracking record status update <<
    if (Trigger.isUpdate) {
        List<Id> prIds = new List<Id>();
        
        for (Purchase_Receipt__c pr : Trigger.New) {
            Purchase_Receipt__c xpr = Trigger.oldMap.get(pr.Id);
            if (pr.Sync_d__c == true && xpr.Sync_d__c != pr.Sync_d__c) {
                prIds.add(pr.Id);
            }
        }

        if (prIds.size() > 0) {
            List<INTG__INT_Change_Tracking_Record__c> changeTrackingRecords = [SELECT Id FROM INTG__INT_Change_Tracking_Record__c WHERE (INTG__Mapping__r.Name = 'Purchase Receipt (Outbound) - ACV Enviro' OR INTG__Mapping__r.Name = 'Purchase Receipt (Outbound) - Cycle Chem') AND INTG__Indexed_Record_Id__c IN :prIds AND INTG__Status__c <> 'Synchronized'];
            for (Integer i = 0; i < changeTrackingRecords.size(); i++) {
                changeTrackingRecords[i].INTG__Status__c = 'Synchronized';
            }
            update changeTrackingRecords;
        }
    }
    //change tracking record status update >>
}