public interface IResourceUnitOfMeasuresSelector {
    List<ResourceUOMAssociation__c> selectByResId(Set<Id> resIds);
    List<ResourceUOMAssociation__c> selectByResByUOM(Id resId, Id uomId);
}