public interface ISignaturesSelector extends fflib_ISObjectSelector {
    List<Signature__c> selectById(Set<Id> ids);
    List<Signature__c> selectByTMId(Set<Id> tmIds);
    List<Signature__c> selectByRoles(Set<Id> tmIds, List<String> roles);
    Signature__c selectCustomerSignatureBySiteAccessToken(String siteAccessToken);
}