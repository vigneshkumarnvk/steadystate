/**
 * Created by Steven on 2/27/2018.
 */

trigger SubsidiaryVendorTrigger on Subsidiary_Vendor__c (before insert, before update) {
    if (Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate){
            Set<Id> vendIds = new Set<Id>();
            Set<Id> acctIds = new Set<Id>();
            for(Subsidiary_Vendor__c vendor : Trigger.new) {
                acctIds.add(vendor.Account__c);
                vendIds.add(vendor.Id);
            }

            List<Subsidiary_Vendor__c> subVends = [SELECT Id, Account__c, Service_Center__c, Subsidiary_Company__c FROM Subsidiary_Vendor__c WHERE Account__c IN :acctIds AND (Id NOT IN :vendIds)];
            Set<String> subVendNCompanyCombo = new Set<String>();
            for (Subsidiary_Vendor__c subVend : subVends) {
                String key = subVend.Subsidiary_Company__c + ';' + subVend.Service_Center__c + ';' + subVend.Account__c;
                subVendNCompanyCombo.add(subVend.Subsidiary_Company__c + ';' + subVend.Service_Center__c + ';' + subVend.Account__c);
            }

            for (Subsidiary_Vendor__c subVendor: Trigger.new) {
                if(subVendNCompanyCombo.contains(subVendor.Subsidiary_Company__c + ';' + subVendor.Service_Center__c + ';' + subVendor.Account__c)){
                    if (subVendor.Service_Center__c == null) {
                        subVendor.addError('There is already a subsidiary vendor account exists in the subsidiary company with a blank service center.');
                    }
                    else {
                        subVendor.addError('There is already a subsidiary vendor account exists for the service center in the subsidiary company.');
                    }
                }
                else {
                    subVendNCompanyCombo.add(subVendor.Subsidiary_Company__c + ';' + subVendor.Service_Center__c + ';' + subVendor.Account__c);
                }
            }
        }
    }
}