public interface IContractLinesSelector extends fflib_ISObjectSelector{
    Map<Id, Contract_Line__c> selectTMDescriptionById (Set<Id> idSet);
    List<Contract_Line__c> selectById(Set<Id> idSet);
    List<Contract_Line__c> selectLinesByContractId(Set<Id> idSet);
    List<Contract_Line__c> selectLinesByContractIdByWorkDate(Set<Id> idSet, Date workDate);
    Map<String, Contract_Line__c> selectLinesWithContractIdResTypeAndUOMByContractId(Set<Id> contractIdSet);
    Map<String, Contract_Line__c> selectLinesWithContractIdResAndUOMByContractId(Set<Id> contractIdSet);
    Map<String, Contract_Line__c> mapLineByContractResORResourceTypeAndUOM(Set<Id> contractIds);
}