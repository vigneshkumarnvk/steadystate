public with sharing class ResourceUnitOfMeasuresSelector extends fflib_SObjectSelector implements IResourceUnitOfMeasuresSelector{

    public static IResourceUnitOfMeasuresSelector newInstance(){
        return (IResourceUnitOfMeasuresSelector) Application.Selector.newInstance(ResourceUOMAssociation__c.SObjectType);
    }


    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
                ResourceUOMAssociation__c.Id,
                ResourceUOMAssociation__c.Name,
                ResourceUOMAssociation__c.Resource__c,
                ResourceUOMAssociation__c.Unit_of_Measure__c,
                ResourceUOMAssociation__c.Unit_Cost__c,
                ResourceUOMAssociation__c.Unit_Price__c,
                ResourceUOMAssociation__c.Min_Sell_Qty__c,
                ResourceUOMAssociation__c.Facility__c,
                ResourceUOMAssociation__c.Container_Size__c,
                ResourceUOMAssociation__c.ER_Unit_Price__c
        };
    }

    public Schema.SObjectType getSObjectType(){
        return ResourceUOMAssociation__c.SObjectType;
    }

    public List<ResourceUOMAssociation__c> selectById(Set<Id> ids){
        return (List<ResourceUOMAssociation__c>) super.selectSObjectsById(ids);
    }

    public List<ResourceUOMAssociation__c> selectByResId(Set<Id> resIds){
        fflib_QueryFactory resourceUOMAssociationQueryFactory = newQueryFactory();


        //job task <<
        //return Database.query(resourceUOMAssociationQueryFactory.setCondition('Resource__c IN :resIds').toSOQL());
        return Database.query(resourceUOMAssociationQueryFactory
                .selectField('Unit_of_Measure__r.Name')
                .setCondition('Resource__c IN :resIds').toSOQL());
        //job task >>
    }

    public List<ResourceUOMAssociation__c> selectByResByUOM(Id resId, Id uomId){
        fflib_QueryFactory resourceUOMAssociationQueryFactory = newQueryFactory();
        return Database.query(resourceUOMAssociationQueryFactory
                .selectField('Unit_of_Measure__r.Name')
                //aura <<
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                //aura >>
                .setCondition('Resource__c = :resId AND Unit_of_Measure__c = :uomId').toSOQL());
    }
}