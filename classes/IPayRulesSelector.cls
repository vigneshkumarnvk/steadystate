public interface IPayRulesSelector extends fflib_ISObjectSelector{
    List<Pay_Rule__c> selectPayRulesByIdWithLines(Set<Id> idSet);
}