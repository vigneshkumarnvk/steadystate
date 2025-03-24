public interface IContractsSelector extends fflib_ISObjectSelector{
    List<Contract> selectById(Set<Id> idSet);
    List<Contract> selectBillingInstructionsById(Set<Id> idSet);
    List<Contract> selectByAccountId(Set<Id> idSet);
    List<Contract> selectByIdWithBillingRule(Set<Id> idSet);
    List<Account_Contract_Association__c> selectAccountContractAssociationByAcctIdAndConttractId(Id accountId, Id contractId);
}