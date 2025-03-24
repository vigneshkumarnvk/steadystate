public with sharing class FacilitiesSelector extends fflib_SObjectSelector {

    public static FacilitiesSelector newInstance(){
        return (FacilitiesSelector) Application.Selector.newInstance(Facility__c.SObjectType);
    }

    public SObjectType getSObjectType(){
        return Facility__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList(){
        return new List<SObjectField>{
                Facility__c.Id,
                Facility__c.Name,
                //aura <<
                Facility__c.Third_Party_Facility__c
                //aura >>
        };
    }

    public List<Facility__c> selectById(Set<Id> idSet){
        return (List<Facility__c>) Database.query(newQueryFactory().setCondition('Id IN :idSet').toSOQL());
    }

    public List<Facility__c> selectByName(String facilityName){
        return (List<Facility__c>) Database.query(newQueryFactory().setCondition('Name = :facilityName').toSOQL());
    }
    
}