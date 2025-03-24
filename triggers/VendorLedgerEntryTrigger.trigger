trigger VendorLedgerEntryTrigger on Vendor_Ledger_Entry__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    if(Trigger.isBefore){
        if(Trigger.isInsert){
            Map<String, Set<String>> navVenNoBySubCompany = new Map<String, Set<String>>();
            for(Vendor_Ledger_Entry__c vendorLedgerEntry:Trigger.new){
                if(navVenNoBySubCompany.containsKey(vendorLedgerEntry.Subsidiary_Company__c)){
                    Set<String> navVenNos = navVenNoBySubCompany.get(vendorLedgerEntry.Subsidiary_Company__c);
                    navVenNos.add(vendorLedgerEntry.NAV_Vendor_No__c);
                    navVenNoBySubCompany.put(vendorLedgerEntry.Subsidiary_Company__c, navVenNos);
                } else {
                    navVenNoBySubCompany.put(vendorLedgerEntry.Subsidiary_Company__c, new Set<String>{vendorLedgerEntry.NAV_Vendor_No__c});
                }
            }

            Map<String, Map<String, Subsidiary_Vendor__c>> subVendorByNAVVenNoBySubCompany = new Map<String, Map<String, Subsidiary_Vendor__c>>();
            for(String subId: navVenNoBySubCompany.keySet()){
                Set<String> navVendNos = navVenNoBySubCompany.get(subId);
                List<Subsidiary_Vendor__c> subsidiaryVendors = SubsidiaryVendorsSelector.newInstance().selectBySubsidiaryByName(subId, navVendNos);
                for(Subsidiary_Vendor__c subsidiaryVendor:subsidiaryVendors){
                    if(subVendorByNAVVenNoBySubCompany.containsKey(subsidiaryVendor.Subsidiary_Company__c)){
                        Map<String, Subsidiary_Vendor__c> subsidiaryVendorByNAVNo = new Map<String, Subsidiary_Vendor__c>();
                        subsidiaryVendorByNAVNo = subVendorByNAVVenNoBySubCompany.get(subsidiaryVendor.Subsidiary_Company__c);
                        if(!subsidiaryVendorByNAVNo.containsKey(subsidiaryVendor.Name)){
                            subsidiaryVendorByNAVNo.put(subsidiaryVendor.Name, subsidiaryVendor);
                        }
                        subVendorByNAVVenNoBySubCompany.put(subsidiaryVendor.Subsidiary_Company__c, subsidiaryVendorByNAVNo);
                    } else {
                        Map<String, Subsidiary_Vendor__c> subsidiaryVendorByNAVNo = new Map<String, Subsidiary_Vendor__c>();
                        subsidiaryVendorByNAVNo.put(subsidiaryVendor.Name, subsidiaryVendor);
                        subVendorByNAVVenNoBySubCompany.put(subsidiaryVendor.Subsidiary_Company__c, subsidiaryVendorByNAVNo);
                    }
                }
            }

            for(Vendor_Ledger_Entry__c vendorLedgerEntry:Trigger.new){
                if(subVendorByNAVVenNoBySubCompany.containsKey(vendorLedgerEntry.Subsidiary_Company__c)){
                    Map<String, Subsidiary_Vendor__c> subsidiaryVendorsByNAVVenNo = new Map<String, Subsidiary_Vendor__c>();
                    subsidiaryVendorsByNAVVenNo = subVendorByNAVVenNoBySubCompany.get(vendorLedgerEntry.Subsidiary_Company__c);
                    if(subsidiaryVendorsByNAVVenNo.containsKey(vendorLedgerEntry.NAV_Vendor_No__c)){
                        vendorLedgerEntry.Vendor__c = subsidiaryVendorsByNAVVenNo.get(vendorLedgerEntry.NAV_Vendor_No__c).Account__c;
                    }
                }
            }
        }
    }
}