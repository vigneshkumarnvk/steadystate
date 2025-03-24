trigger ContractLine on Contract_Line__c (before insert, before update) {
    if(CompanyMgmt.byPassTrigger == true) {
        return;
    }
    if(Trigger.isInsert || Trigger.isUpdate) {
        //aura <<
        //ContractTriggersMgmt.CLInsertUpdate(Trigger.new, Trigger.oldMap, Trigger.isInsert);
        Set<Id> resourceTypeIds = new Set<Id>();
        Set<Id> resourceIds = new Set<Id>();
        for (Contract_Line__c cl : Trigger.New) {
            if (cl.Resource_Type__c != null) {
                resourceTypeIds.add(cl.Resource_Type__c);
            }
            if (cl.Resource__c != null) {
                resourceIds.add(cl.Resource__c);
            }
        }

        //ticket 19861 <<
        /*
        Map<Id, Resource_Type__c> mapResourceTypes = new Map<Id, Resource_Type__c>();
        for (Resource_Type__c resourceType : [SELECT Id, Name, Category__c FROM Resource_Type__c WHERE Id IN :resourceTypeIds]) {
            mapResourceTypes.put(resourceType.Id, resourceType);
        }
        
        Map<Id, Resource__c> mapResources = new Map<Id, Resource__c>();
        for (Resource__c resource : [SELECT Id, Category__c FROM Resource__c WHERE Id IN :resourceIds]) {
            mapResources.put(resource.Id, resource);
        }
        */
        Map<Id, Resource_Type__c> mapResourceTypes = new Map<Id, Resource_Type__c>();
        for (Resource_Type__c resourceType : [SELECT Id, Name, Category__c, Blocked__c FROM Resource_Type__c WHERE Id IN :resourceTypeIds]) {
            mapResourceTypes.put(resourceType.Id, resourceType);
        }

        Map<Id, Resource__c> mapResources = new Map<Id, Resource__c>();
        for (Resource__c resource : [SELECT Id, Category__c, Blocked__c FROM Resource__c WHERE Id IN :resourceIds]) {
            mapResources.put(resource.Id, resource);
        }
        if (Trigger.isInsert) {
            for (Contract_Line__c contractLine : Trigger.new) {
                if (contractLine.Resource_Type__c != null) {
                    if (mapResourceTypes.containsKey(contractLine.Resource_Type__c)) {
                        if (mapResourceTypes.get(contractLine.Resource_Type__c).Blocked__c == true) {
                            contractLine.Resource_Type__c.addError('This resource type is blocked.');
                        }
                    }
                }
                if (contractLine.Resource__c != null) {
                    if (mapResources.containsKey(contractLine.Resource__c)) {
                        if (mapResources.get(contractLine.Resource__c).Blocked__c == true) {
                            contractLine.Resource__c.addError('This resource is blocked.');
                        }
                    }
                }
            }
        }
        else if (Trigger.isUpdate) {
            for (Contract_Line__c contractLine : Trigger.new) {
                Contract_Line__c xContractLine = Trigger.oldMap.get(contractLine.Id);
                if (contractLine.Resource_Type__c != null) {
                    if (contractLine.Resource_Type__c != xContractLine.Resource_Type__c) {
                        if (mapResourceTypes.containsKey(contractLine.Resource_Type__c)) {
                            if (mapResourceTypes.get(contractLine.Resource_Type__c).Blocked__c == true) {
                                contractLine.Resource_Type__c.addError('This resource type is blocked.');
                            }
                        }
                    }
                }
                if (contractLine.Resource__c != null) {
                    if (contractLine.Resource__c != xContractLine.Resource__c) {
                        if (mapResources.containsKey(contractLine.Resource__c)) {
                            if (mapResources.get(contractLine.Resource__c).Blocked__c == true) {
                                contractLine.Resource__c.addError('This resource is blocked.');
                            }
                        }
                    }
                }
            }
        }
        //ticket 19861 >>

        for (Contract_Line__c cl : Trigger.New) {
            if (cl.Resource_Type__c != null) {
                if (mapResourceTypes.containsKey(cl.Resource_Type__c)) {
                    cl.Category__c = mapResourceTypes.get(cl.Resource_Type__c).Category__c;
                }
            }
            else if (cl.Resource__c != null) {
                if (mapResources.containsKey(cl.Resource__c)) {
                    cl.Category__c = mapResources.get(cl.Resource__c).Category__c;
                }
            }
        }

        ContractTriggersMgmt.CLInsertUpdate(Trigger.new, Trigger.oldMap, Trigger.isInsert);
    }
}