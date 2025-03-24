public interface IResourcesSelector extends fflib_ISObjectSelector{
    List<Resource__c> selectById(Set<Id> idSet);
    List<Resource__c> selectLaborResourcesByIds(Set<Id> ids);
    List<Resource__c> selectLaborResourcesByServiceCenter(Id scId);
    List<Resource__c> selectPayrollEmployeeByIdsByActivityDate(Set<Id> resIds, Date activityDate);
    List<Resource__c> selectPayrollEmployeeBySCIdByActivityDate(Id scId, Date activityDate);
    Map<Id, Resource__c> getResourcesByIdsMapByResIds(Set<Id> idSet);
}