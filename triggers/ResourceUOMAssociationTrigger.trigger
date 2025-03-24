trigger ResourceUOMAssociationTrigger on ResourceUOMAssociation__c (after insert, after update, after delete) {
    if (Trigger.isAfter) {
        Set<Id> resourceIds = new Set<Id>();
        if (Trigger.isInsert || Trigger.isUpdate) {
            for (ResourceUOMAssociation__c resourceUOM : Trigger.new) {
                resourceIds.add(resourceUOM.Resource__c);
            }
        }
        else if (Trigger.isDelete) {
            for (ResourceUOMAssociation__c resourceUOM : Trigger.old) {
                resourceIds.add((resourceUOM.Resource__c));
            }
        }
        if (resourceIds.size() > 0) {
            List<Resource__c> resources = new List<Resource__c>();
            for (Id resourceId : resourceIds) {
                resources.add(new Resource__c(Id = resourceId));
            }
            update resources;
        }
    }
}