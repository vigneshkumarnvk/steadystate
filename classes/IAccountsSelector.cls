public interface IAccountsSelector extends fflib_ISObjectSelector
{
    List<Account> selectById(Set<Id> idSet);
    List<Account> selectBillingInstructionsById(Set<Id> idSet);
    List<Account> selectTaxAreaNameById(Set<Id> idSet);
    List<Account> selectSubsidiaryCompInfoById(Set<Id> idSet);
    List<Account> selectParentAccountById(Set<Id> idSet);
}