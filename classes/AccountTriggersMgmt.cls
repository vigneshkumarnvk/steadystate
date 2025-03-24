/**
 * Created by Steven on 2/27/2018.
 */

public with sharing class AccountTriggersMgmt {
    public static void accountInsertUpdate(List<Account> acctList, Map<Id, Account> oldAcctMap, Boolean isInsert){
        Set<Id> acctIds = new Set<Id>();
        Map<Id, Account> acctMap = new Map<Id, Account>();
        for (Account acct: acctList) {
            acctIds.add(acct.Id);
            acctMap.put(acct.Id, acct);
        }

        Map<Id, Purchase_Price__c> accountPurchasePriceMap = new Map<Id, Purchase_Price__c>();
        List<Purchase_Price__c> ppInsertLst = new List<Purchase_Price__c>();
        List<Purchase_Price__c> ppDeleteLst = new List<Purchase_Price__c>();
        for(Purchase_Price__c pp : [SELECT Id, Name, Account__c FROM Purchase_Price__c WHERE Account__c IN :acctIds AND Name = 'NEW']){
            accountPurchasePriceMap.put(pp.Account__c, pp);
        }

        for(Id acctId : acctMap.keySet()){
            Account acct = acctMap.get(acctId);
            if(acct.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId() &&
                    !accountPurchasePriceMap.containsKey(acctId) &&
                    acct.Auto_Create_Catalog_Item__c == true) {
                Purchase_Price__c pp = new Purchase_Price__c();
                pp.Account__c = acct.Id;
                pp.Name = 'NEW';
                pp.Status__c = 'Approved';
                ppInsertLst.add(pp);
            }

            if(acct.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId() &&
                    accountPurchasePriceMap.containsKey(acctId) &&
                    acct.Auto_Create_Catalog_Item__c == false) {
                ppDeleteLst.add(accountPurchasePriceMap.get(acctId));
            }
        }

        if(ppInsertLst.size() > 0){
            insert ppInsertLst;
        }

        if(ppDeleteLst.size() > 0){
            delete ppDeleteLst;
        }
        /*
        for (Account acct: acctList){
            if(acct.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId()){
                List<Purchase_Price__c> ppList = [SELECT Id, Name, Account__c FROM Purchase_Price__c WHERE Account__c =: acct.Id AND Name = 'NEW'];
                if(acct.Auto_Create_Catalog_Item__c){
                    if(ppList.size() == 0){
                        Purchase_Price__c pp = new Purchase_Price__c();
                        pp.Account__c = acct.Id;
                        pp.Name = 'NEW';
                        pp.Status__c = 'Approved';
                        insert pp;
                    }
                } else {
                    if(ppList.size() != 0){
                        delete ppList;
                    }
                }
            }
        }
        */
    }

    public static String updateAccountExecutives(String accountExecutiveIds, Map<Id, Salesperson__c> salesPersonRecords){
        String hyperlinks = '';
        integer count = 0;
        
        if(!String.isEmpty(accountExecutiveIds)){      
            integer totalSalesPersons = accountExecutiveIds.split(',').size();     
            String baseUrl = URL.getOrgDomainURL().toExternalForm();
            for (String salesPersonId : accountExecutiveIds.split(',')) {
                Salesperson__c salesPerson = salesPersonRecords.get(salesPersonId);
                if (salesPerson != null) {
                    String recordUrl = baseUrl + '/' + salesPerson.Id;
                    String hyperlink = '<a href="' + recordUrl + '">' + salesPerson.Name + '</a>';
                    hyperlinks += hyperlink;
                    // Append a comma if it's not the last record
                    if (count < totalSalesPersons - 1) {
                        hyperlinks += ', ';
                    }
                }
                count++;
            }                
        }        
        return hyperlinks;
    }
}