trigger TMTrigger on TM__c (before insert, before update, before delete, after insert, after update, after delete) {

    if(Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate){
            TMTriggersMgmt.TMInsertUpdate(Trigger.new, Trigger.oldMap, Trigger.isInsert);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            TMTriggersMgmt.TMAfterInsertUpdate(Trigger.new, Trigger.oldMap, Trigger.isInsert);
        }
    }

    if(Trigger.isDelete){
        List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
        if(profiles.size() > 0){
            if(profiles[0].Name != 'System Administrator'){
                Trigger.old[0].addError('You are not allowed to delete T&M');
            }
        }

        Set<Id> tmIds = new Set<Id>();
        for(TM__c tm : Trigger.old){
            if(tm.Status__c != TMsService.OPEN_STATUS && tm.Status__c != TMsService.VOID_STATUS){
                tm.addError('T&M with ' + tm.Status__c + ' status cannot be deleted!');
            }
            tmIds.add(tm.Id);
        }

        if(tmIds.size() > 0){
            List<Billing_Worksheet_Line__c> billingWorksheetLines = [SELECT Id FROM Billing_Worksheet_Line__c WHERE TM__c IN :tmIds];
            if(billingWorksheetLines.size() > 0){
                Trigger.old[0].addError('T&M with linked billing worksheet lines cannot be deleted!');
            }

            List<Timesheet_Line__c> timesheetLines = [SELECT Id FROM Timesheet_Line__c WHERE TM__c IN :tmIds];
            if(timesheetLines.size() > 0){
                Trigger.old[0].addError('T&M with linked timesheet lines cannot be deleted!');
            }
        }
    }

    /* move the code to MobileTMController for realtime pd. FieldTMPDFQueue object and FieldTMPDFQueueController are not needed. to be delete after real time pdf works stable
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            //Send/save Field TM PDF
            Set<Id> tmIds = new Set<Id>();
            Set<Id> voidedTmIds = new Set<ID>();
            for (TM__c tm : Trigger.New) {
                if (tm.Mobile_TM__c == true) {
                    TM__c xTm = Trigger.oldMap.get(tm.Id);
                    if (tm.Status__c == 'Scheduled' && (xTm.Status__c == 'Mobile Review' || xTm.Status__c == 'Confirmed')) {
                        voidedTmIds.add(tm.Id);
                    }
                    else {
                        if ((tm.Accept_Terms_and_Conditions__c == true || tm.Customer_Not_Available__c == true) && (TM.Status__c == 'Scheduled' || TM.Status__c == 'Mobile Review')) {
                            tmIds.add(tm.Id);
                        }
                    }
                }
            }
            
            if (voidedTmIds.size() > 0) {
                if (FieldTMPDFQueueController.ByPassTrigger != true) {
                    FieldTMPDFQueueController.UndoPDF(voidedTmIds);
                }
            }
            
            if (tmIds.size() > 0) {
                if (FieldTMPDFQueueController.ByPassTrigger != true) {
                    FieldTMPDFQueueController.Queue(tmIds);
                    FieldTMPDFQueueController.Process();
                }
            }
        }
    }
    */
}