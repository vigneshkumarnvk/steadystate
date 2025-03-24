public with sharing class ResourceTypeUnitOfMeasuresSelector extends fflib_SObjectSelector {

    public static ResourceTypeUnitOfMeasuresSelector newInstance(){
        return (ResourceTypeUnitOfMeasuresSelector) Application.Selector.newInstance(ResourceTypeUOMAssociation__c.SObjectType);
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
            ResourceTypeUOMAssociation__c.Id,
            ResourceTypeUOMAssociation__c.Name,
            ResourceTypeUOMAssociation__c.Resource_Type__c,
            ResourceTypeUOMAssociation__c.Unit_of_Measure__c,
            ResourceTypeUOMAssociation__c.Unit_Cost__c,
            ResourceTypeUOMAssociation__c.Unit_Price__c,
            ResourceTypeUOMAssociation__c.ER_Unit_Price__c
        };
    }

    public Schema.SObjectType getSObjectType(){
        return ResourceTypeUOMAssociation__c.SObjectType;
    }

    public List<ResourceTypeUOMAssociation__c> selectById(Set<Id> ids){
        return (List<ResourceTypeUOMAssociation__c>) super.selectSObjectsById(ids);
    }

    public List<ResourceTypeUOMAssociation__c> selectByResTypeId(Set<Id> resTypeIds){
        fflib_QueryFactory resourceTypeUOMAssociationQueryFactory = newQueryFactory();
        //aura <<
        //return Database.query(resourceTypeUOMAssociationQueryFactory.setCondition('Resource_Type__c IN :resTypeIds').toSOQL());
        return Database.query(resourceTypeUOMAssociationQueryFactory
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .setCondition('Resource_Type__c IN :resTypeIds').toSOQL());
        //aura >>
    }

    public List<ResourceTypeUOMAssociation__c> selectByResTypeIdByUOMId(Id resTypeId, Id uomId){
        return new List<ResourceTypeUOMAssociation__c>(
                (List<ResourceTypeUOMAssociation__c>) Database.query(newQueryFactory(true).
                    selectField('Unit_of_Measure__r.Name').
                    //aura <<
                    selectField('Unit_of_Measure__r.Hours_UOM__c').
                    //aura >>
                    setCondition('Resource_Type__c = :resTypeId AND Unit_of_Measure__c = :uomId').toSOQL())
                );
    }
}