public class PresumptiveResourcesSelector extends fflib_SObjectSelector implements IPresumptiveResourcesSelector {
    public static PresumptiveResourcesSelector newInstance() {
        return (PresumptiveResourcesSelector)Application.Selector.newInstance(Presumptive_Resource__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Presumptive_Resource__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField> {
                Presumptive_Resource__c.Id,
                Presumptive_Resource__c.Name,
                Presumptive_Resource__c.Parent_Resource_Type__c,
                Presumptive_Resource__c.Parent_Resource__c,
                Presumptive_Resource__c.Child_Resource_Type__c,
                Presumptive_Resource__c.Child_Resource__c,
                Presumptive_Resource__c.Child_Unit_of_Measure__c
        };
    }

    public List<Presumptive_Resource__c> selectByParentIds(Set<Id> resourceTypeIdSet, Set<Id> resourceIdSet) {
        fflib_QueryFactory queryFactory = newQueryFactory(true);
        return Database.query(queryFactory.toSOQL());
    }

    public Map<Id, List<Presumptive_Resource__c>> getPresumptiveResourceMapByParentIds(Set<Id> resourceTypeIdSet, Set<Id> resourceIdSet) {
        Map<Id, List<Presumptive_Resource__c>> mapPresumptiveResourcesByParentId = new Map<Id, List<Presumptive_Resource__c>>();
        for (Presumptive_Resource__c presumptiveResource : selectByParentIds(resourceTypeIdSet, resourceIdSet)) {
            List<Presumptive_Resource__c> presumptiveResources;
            if (presumptiveResource.Parent_Resource_Type__c != null) {
                if (mapPresumptiveResourcesByParentId.containsKey(presumptiveResource.Parent_Resource_Type__c)) {
                    presumptiveResources = mapPresumptiveResourcesByParentId.get(presumptiveResource.Parent_Resource_Type__c);
                } else {
                    presumptiveResources = new List<Presumptive_Resource__c>();
                    mapPresumptiveResourcesByParentId.put(presumptiveResource.Parent_Resource_Type__c, presumptiveResources);
                }
                presumptiveResources.add(presumptiveResource);
            }

            if (presumptiveResource.Parent_Resource__c != null) {
                if (mapPresumptiveResourcesByParentId.containsKey(presumptiveResource.Parent_Resource__c)) {
                    presumptiveResources = mapPresumptiveResourcesByParentId.get(presumptiveResource.Parent_Resource__c);
                } else {
                    presumptiveResources = new List<Presumptive_Resource__c>();
                    mapPresumptiveResourcesByParentId.put(presumptiveResource.Parent_Resource__c, presumptiveResources);
                }
                presumptiveResources.add(presumptiveResource);
            }
        }
        return mapPresumptiveResourcesByParentId;
    }
}