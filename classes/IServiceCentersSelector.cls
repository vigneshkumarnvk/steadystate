public interface IServiceCentersSelector extends fflib_ISObjectSelector{
    List<Service_Center__c> selectById(Set<Id> idSet);
    List<Service_Center__c> selectByName(String name);
    List<Service_Center__c> selectAll();
}