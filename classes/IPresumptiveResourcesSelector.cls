public interface IPresumptiveResourcesSelector extends fflib_ISObjectSelector {
    List<Presumptive_Resource__c> selectByParentIds(Set<Id> resourceTypeIdSet, Set<Id> resourceIdSet);
    Map<Id, List<Presumptive_Resource__c>> getPresumptiveResourceMapByParentIds(Set<Id> resourceTypeIdSet, Set<Id> resourceIdSet);
}