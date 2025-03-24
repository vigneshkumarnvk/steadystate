trigger ChangeTrackingRecordTrigger on INTG__INT_Change_Tracking_Record__c (before insert, before update) {
    if (CompanyMgmt.byPassTrigger == true) return;

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            Set<Id> intgRecIds = new Set<Id>();
            for (INTG__INT_Change_Tracking_Record__c tracking : Trigger.New) {
                if (tracking.INTG__Status__c == 'Error') {
                    if (tracking.INTG__Integration_Record__c != null) {
                        intgRecIds.add(tracking.INTG__Integration_Record__c);
                    }
                }
            }
            
            if (intgRecIds.size() > 0) {
                Map<Id, INTG__INT_Integration_Record__c> mapIntegrationRecordsById = new Map<Id, INTG__INT_Integration_Record__c>();
                for (INTG__INT_Integration_Record__c integrationRecord : [SELECT Id, INTG__Error_Message__c FROM INTG__INT_Integration_Record__c WHERE Id IN :intgRecIds]) {
                    mapIntegrationRecordsById.put(integrationRecord.Id, integrationRecord);
                }

                for (INTG__INT_Change_Tracking_Record__c tracking : Trigger.New) {
                    if (tracking.INTG__Status__c == 'Error') {
                        if (tracking.INTG__Integration_Record__c != null) {
                            if (mapIntegrationRecordsById.containsKey(tracking.INTG__Integration_Record__c)) {
                                String message = mapIntegrationRecordsById.get(tracking.INTG__Integration_Record__c).INTG__Error_Message__c;
                                if (String.isNotEmpty(message)) {
                                    if (message.length() > 255) {
                                        message = message.substring(0, 255);
                                    }
                                    tracking.Error_Message__c = message;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}