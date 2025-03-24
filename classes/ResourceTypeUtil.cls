public class ResourceTypeUtil {

    public static Map<Id, Resource_Type__c> resourceTypesByIds = new Map<Id, Resource_Type__c>();
    public static Map<Id, Map<Id, ResourceTypeUOMAssociation__c>> resourceTypeUOMAssociationsByUOMIdsByResTypeIds = new Map<Id, Map<Id, ResourceTypeUOMAssociation__c>>();
    public static Set<Id> uomIds = new Set<Id>();

    public static void setResourceTypeMapsByIds(Set<Id> resTypeIds){
        if(resTypeIds.size() > 0){
            List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                    ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeId(resTypeIds);

            for (ResourceTypeUOMAssociation__c resourceTypeUOMAssociation : resourceTypeUOMAssociations) {
                uomIds.add(resourceTypeUOMAssociation.Unit_of_Measure__c);
                Map<Id, ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsByUOMIds = new Map<Id, ResourceTypeUOMAssociation__c>();
                if (resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(resourceTypeUOMAssociation.Resource_Type__c)) {
                    resourceTypeUOMAssociationsByUOMIds = resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(resourceTypeUOMAssociation.Resource_Type__c);
                }
                resourceTypeUOMAssociationsByUOMIds.put(resourceTypeUOMAssociation.Unit_of_Measure__c, resourceTypeUOMAssociation);
                resourceTypeUOMAssociationsByUOMIdsByResTypeIds.put(resourceTypeUOMAssociation.Resource_Type__c, resourceTypeUOMAssociationsByUOMIds);
            }

            resourceTypesByIds.putAll(ResourceTypesSelector.newInstance().selectById(resTypeIds));
        }
    }

    public static Resource_Type__c getResourceType(Id resTypeId){
        Resource_Type__c resourceType = new Resource_Type__c();
        if(resourceTypesByIds.containsKey(resTypeId)){
            resourceType = resourceTypesByIds.get(resTypeId);
        }
        return resourceType;
    }

    public static ResourceTypeUOMAssociation__c getResourceTypeUOMAssociation(Id resTypeId, Id uomId){
        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = new ResourceTypeUOMAssociation__c();
        if (resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(resTypeId)) {
            Map<Id, ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsByUOMIds = resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(resTypeId);
            if (resourceTypeUOMAssociationsByUOMIds.containsKey(uomId)) {
                resourceTypeUOMAssociation = resourceTypeUOMAssociationsByUOMIds.get(uomId);
            }
        }

        return resourceTypeUOMAssociation;
    }

    public static Decimal getUnitPrice(Id resTypeId, Id uomId, Boolean isER){
        Decimal unitPrice = 0;
        if (resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(resTypeId)) {
            Map<Id, ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsByUOMIds = resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(resTypeId);
            if (resourceTypeUOMAssociationsByUOMIds.containsKey(uomId)) {
                ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = resourceTypeUOMAssociationsByUOMIds.get(uomId);
                if(isER) {
                    unitPrice = CompanyMgmt.zeroIfNull(resourceTypeUOMAssociation.ER_Unit_Price__c);
                } else {
                    unitPrice = CompanyMgmt.zeroIfNull(resourceTypeUOMAssociation.Unit_Price__c);
                }
            }
        }
        return unitPrice;
    }

    public static Decimal getUnitCost(Id resTypeId, Id uomId){
        Decimal unitCost = 0;
        if (resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(resTypeId)) {
            Map<Id, ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsByUOMIds = resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(resTypeId);
            if (resourceTypeUOMAssociationsByUOMIds.containsKey(uomId)) {
                ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = resourceTypeUOMAssociationsByUOMIds.get(uomId);
                unitCost = CompanyMgmt.zeroIfNull(resourceTypeUOMAssociation.Unit_Cost__c);
            }
        }
        return unitCost;
    }
}