trigger PurchOrderTrigger on Purchase_Order__c (before insert, before update, before delete, after update, after insert ) {
    if (CompanyMgmt.byPassTrigger != true) {
        if (Trigger.isDelete) {
            List<Purchase_Order__c> POList = Trigger.old;
            PurchTriggersMgmt.PODelete(POList);
        } else {
            List<Purchase_Order__c> POList = Trigger.new;
            if (Trigger.isBefore) {
                if(Trigger.isInsert) {
                    Integration_Setting__mdt coupaIntegrationSetting = IntegrationSettingUtil.coupaSetting;
                    if (coupaIntegrationSetting.Enabled__c == true && String.isBlank(Trigger.new[0].Coupa_Id__c) == true) {
                        Trigger.new[0].addError('New purchases order need to be create in Coupa!');
                    }
                }

                PurchTriggersMgmt.POInsertUpdate(POList, Trigger.oldMap, Trigger.isInsert);

                //control the sync flag update
                if (Trigger.isUpdate) {

                    //change tracking record status update <<
                    List<Id> poIds = new List<Id>();
                    //change tracking record status update >>

                    for (Purchase_Order__c po : Trigger.new) {
                        Purchase_Order__c xpo = Trigger.oldMap.get(po.Id);
                        if (po.Name != xpo.Name || po.Create_User_Name__c != xpo.Create_User_Name__c || po.Document_Status__c != xpo.Document_Status__c || po.Expected_Receipt_Date__c != xpo.Expected_Receipt_Date__c
                                || po.Order_Date__c != xpo.Order_Date__c || po.Payment_Terms_Code__c != xpo.Payment_Terms_Code__c || po.Service_Center__c != xpo.Service_Center__c || po.Buy_from_Vendor__c != xpo.Buy_from_Vendor__c
                                || po.Estimated_Freight_Amount__c != xpo.Estimated_Freight_Amount__c
                                || po.Billing_Street__c != xpo.Billing_Street__c || po.Billing_City__c != xpo.Billing_City__c || po.Billing_State__c != xpo.Billing_State__c || po.Billing_Postal_Code__c != xpo.Billing_Postal_Code__c || po.Billing_Country__c != xpo.Billing_Country__c
                                || po.Shipping_Street__c != xpo.Shipping_Street__c || po.Shipping_City__c != xpo.Shipping_City__c || po.Shipping_State__c != xpo.Shipping_State__c || po.Shipping_Postal_Code__c != xpo.Shipping_Postal_Code__c || po.Shipping_Country__c != xpo.Shipping_Country__c
                                || po.Closed__c != xpo.Closed__c) {
                            po.Sync_d__c = false;
                        }

                        //change tracking record status update <<
                        if (po.Sync_d__c == true && xpo.Sync_d__c != po.Sync_d__c) {
                            poIds.add(po.Id);
                        }
                        //change tracking record status update >>
                    }

                    //change tracking record status update <<
                    if (poIds.size() > 0) {
                        if (!Test.isRunningTest()) {
                            List<INTG__INT_Change_Tracking_Record__c> changeTrackingRecords = [SELECT Id FROM INTG__INT_Change_Tracking_Record__c WHERE (INTG__Mapping__r.Name = 'Purchase Order (Outbound) - ACV Enviro' OR INTG__Mapping__r.Name = 'Purchase Order (Outbound) - Cycle Chem') AND INTG__Indexed_Record_Id__c IN :poIds AND INTG__Status__c <> 'Synchronized'];
                            for (Integer i = 0; i < changeTrackingRecords.size(); i++) {
                                changeTrackingRecords[i].INTG__Status__c = 'Synchronized';
                            }
                            if (changeTrackingRecords.size() > 0) {
                                update changeTrackingRecords;
                            }
                        }
                    }
                    //change tracking record status update >>
                }
            }

            if (Trigger.isAfter && Trigger.isUpdate) {
                PurchTriggersMgmt.POAferUpdate(Trigger.newMap, Trigger.oldMap);

                //po void <<
                List<Id> poIds = new List<Id>();
                for (Purchase_Order__c po : Trigger.new) {
                    Purchase_Order__c xpo = Trigger.oldMap.get(po.Id);
                    if (po.Name != null && !po.Name.startsWithIgnoreCase('PROCESSID') && ((xpo.Document_Status__c != 'Open' && po.Document_Status__c == 'Voided') || xpo.Document_Status__c == 'Voided') && xpo.Document_Status__c != po.Document_Status__c) { //find POs that are voided and reactivated.
                        poIds.add(po.Id);
                    }
                }

                Map<String, Map<String, List<Purchase_Order__c>>> mmpos = new Map<String, Map<String, List<Purchase_Order__c>>>(); //by mapping, by status
                for (Purchase_Order__c po : [SELECT Id, Name, Document_Status__c, Subsidiary_Company__r.Name, LastModifiedDate FROM Purchase_Order__c WHERE Id IN :poIds]) {
                    Map<String, List<Purchase_Order__c>> mpos;

                    String mappingName;
                    if (po.Subsidiary_Company__r.Name == '1-REPUBLIC SERVICES') {
                        mappingName = 'Purchase Order (Outbound) - ACV Enviro';
                    } else if (po.Subsidiary_Company__r.Name == '2-CYCLE CHEM., INC.') {
                        mappingName = 'Purchase Order (Outbound) - Cycle Chem';
                    }

                    if (String.isNotEmpty(mappingName)) {
                        if (mmpos.containsKey(mappingName)) {
                            mpos = mmpos.get(mappingName);
                        } else {
                            mpos = new Map<String, List<Purchase_Order__c>>();
                            mmpos.put(mappingName, mpos);
                        }

                        String status;
                        if (po.Document_Status__c == 'Voided') {
                            status = 'Voided';
                        } else {
                            status = 'Unvoided';
                        }

                        List<Purchase_Order__c> pos;
                        if (mpos.containsKey(status)) {
                            pos = mpos.get(status);
                        } else {
                            pos = new List<Purchase_Order__c>();
                            mpos.put(status, pos);
                        }
                        pos.add(po);
                    }
                }

                for (String mappingName : mmpos.keySet()) {
                    Map<String, List<Purchase_Order__c>> mpos = mmpos.get(mappingName);
                    for (String status : mpos.keySet()) {
                        List<Purchase_Order__c> pos = mpos.get(status);
                        if (status == 'Voided') {
                            if (!Test.isRunningTest()) {
                                INTG.INTG_GlobalAPIs.TrackDeleted(mappingName, pos);
                            }
                        } else if (status == 'Unvoided') {
                            if (!Test.isRunningTest()) {
                                INTG.INTG_GlobalAPIs.TrackUndeleted(mappingName, pos);
                            }
                        }
                    }
                }
                //po void >>
            }
        }
    }
}