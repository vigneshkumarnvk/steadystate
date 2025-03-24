trigger ContractTrigger on Contract (before insert, before update, before delete, after insert, after update, after delete) {
    if(CompanyMgmt.byPassTrigger == true){
        return;
    }
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            for(Contract contract : Trigger.new){
                if(String.isNotBlank(contract.AccountId)){
                    ContractUtil.insertAccountContractAssociation(contract.AccountId, contract.Id);
                }
            }
        }
        
        if(Trigger.isUpdate){
            Map<Id, Contract> contractsByIds = new Map<Id, Contract>();
            List<Id> contractIds = new List<Id>();
            for(Contract contract : Trigger.new){
                Contract oldContract = Trigger.oldMap.get(contract.Id);
                if(contract.Surcharge_Type__c != oldContract.Surcharge_Type__c || contract.Surcharge_Pct__c != oldContract.Surcharge_Pct__c){
                    contractsByIds.put(contract.Id, contract);
                }
                if(contract.AccountId != oldContract.AccountId){
                    if(String.isNotBlank(contract.AccountId)){
                        ContractUtil.insertAccountContractAssociation(contract.AccountId, contract.Id);
                    }
                    if(String.isNotBlank(oldContract.AccountId)){
                        ContractUtil.deleteAccountContractAssociation(oldContract.AccountId, contract.Id);
                    }
                }
                if(contract.Status != oldContract.Status && contract.Status=='Activated'){
                    contractIds.add(contract.Id);
                }
            }
            if(contractIds.size()>0){
              //  System.enqueueJob(new ContractBillingProjectServiceQueueable(contractIds));
            }
            if(contractsByIds.size() > 0){
                ContractUtil.updateSalesOrderSurchargeCharge(contractsByIds);
            }
        }
    }
}