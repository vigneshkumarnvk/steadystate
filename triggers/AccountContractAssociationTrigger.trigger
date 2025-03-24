trigger AccountContractAssociationTrigger on Account_Contract_Association__c (before insert, before update) {
    if(Trigger.isBefore) {
        Map<Id, Account> accountsByIds = new Map<Id, Account>();
        Map<Id, Contract> contractsByIds = new Map<Id, Contract>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        for (Account_Contract_Association__c accountContractAssociation : Trigger.new) {
            accountIds.add(accountContractAssociation.Account__c);
            contractIds.add(accountContractAssociation.Contract__c);
        }

        accountsByIds.putAll([SELECT Id, Account.Subsidiary_Company__r.Name FROM Account WHERE Id IN :accountIds]);
        contractsByIds.putAll([SELECT Id, Subsidiary__c FROM Contract WHERE Id IN :contractIds]);

        for (Account_Contract_Association__c accountContractAssociation : Trigger.new) {
            if (accountsByIds.containsKey(accountContractAssociation.Account__c) &&
                    contractsByIds.containsKey(accountContractAssociation.Contract__c)) {
                if (contractsByIds.get(accountContractAssociation.Contract__c).Subsidiary__c.contains(
                        accountsByIds.get(accountContractAssociation.Account__c).Subsidiary_Company__r.Name) == false) {
                    accountContractAssociation.addError('This contract can only be use for account in following subsidiaries: '
                            + contractsByIds.get(accountContractAssociation.Contract__c).Subsidiary__c);
                }
            }
        }
    }
}