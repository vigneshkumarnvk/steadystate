@isTest
private class ParentChildResourceImportTest {
    private static testMethod void test() {
        createTestData();
        ParentChildResourceImport.importParentChildResources();
        ParentChildResourceImport.importTemplate();
        ParentChildResourceImport.updateSalesOrderTypes();
        ParentChildResourceImport.updateParentChildLines();
        ParentChildResourceImport.checkAllowZeroUnitCostResources();
    }


    private static void createTestData() {
        Map<String, Resource_Type__c> mapResourceTypesByName = new Map<String, Resource_Type__c>();
        Map<String, Resource__c> mapResourcesByName = new Map<String, Resource__c>();

        Unit_of_Measure__c unitOfMeasure = new Unit_of_Measure__c();
        unitOfMeasure.Name = 'EA';
        insert unitOfMeasure;

        Resource_Type__c parentResourceType = new Resource_Type__c();
        parentResourceType.Category__c = 'Labor';
        parentResourceType.Name = 'Parent Labor';
        parentResourceType.Unit_of_Measure__c = unitOfMeasure.Id;
        mapResourceTypesByName.Put(parentResourceType.Name, parentResourceType);

        Resource_Type__c childResourceType = new Resource_Type__c();
        childResourceType.Category__c = 'Labor';
        childResourceType.Name = 'Child Labor';
        childResourceType.Unit_of_Measure__c = unitOfMeasure.Id;
        mapResourceTypesByName.Put(childResourceType.Name, childResourceType);

        insert mapResourceTypesByName.values();

        Id recordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Material').getRecordTypeId();
        Resource__c childResource = new Resource__c();
        childResource.RecordTypeId = recordTypeId;
        childResource.Name = 'Child Material';
        childResource.Category__c = 'Materials';
        childResource.Unit_of_Measure__c = unitOfMeasure.Id;
        mapResourcesByName.put(childResource.Name, childResource);

        recordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        Resource__c childDemurageResource = new Resource__c();
        childDemurageResource.RecordTypeId = recordTypeId;
        childDemurageResource.Name = 'Child Demurrage';
        childDemurageResource.Category__c = 'Demurrage';
        childDemurageResource.Unit_of_Measure__c = unitOfMeasure.Id;
        mapResourcesByName.put(childDemurageResource.Name, childDemurageResource);

        insert mapResourcesByName.values();


        List<Parent_Child_Resource__c> parentChildResources = new List<Parent_Child_Resource__c>();

        Parent_Child_Resource__c parentChildResource = new Parent_Child_Resource__c();
        parentChildResource.Parent_Resource_Type__c = parentResourceType.Id;
        parentChildResource.Child_1_Resource_Type__c = childResourceType.Id;
        parentChildResource.Child_1_UOM__c = unitOfMeasure.Id;
        parentChildResources.add(parentChildResource);

        parentChildResource = new Parent_Child_Resource__c();
        parentChildResource.Parent_Resource_Type__c = parentResourceType.Id;
        parentChildResource.Child_2_Resource__c = childResource.Id;
        parentChildResource.Child_2_UOM__c = unitOfMeasure.Id;
        parentChildResources.add(parentChildResource);

        parentChildResource = new Parent_Child_Resource__c();
        parentChildResource.Parent_Resource_Type__c = parentResourceType.Id;
        parentChildResource.Child_3_Resource__c = childResource.Id;
        parentChildResource.Child_3_UOM__c = unitOfMeasure.Id;
        parentChildResources.add(parentChildResource);

        insert parentChildResources;


        //sales order type
        Sales_Order_Type__c salesOrderType = new Sales_Order_Type__c();
        salesOrderType.Name = 'Field Services';
        salesOrderType.Description__c = 'Field Services';
        insert salesOrderType;

        //templates
        List<Template__c> templates = new List<Template__c>();

        Template__c template = new Template__c();
        template.Name = 'Field Services';
        template.Sales_Order_Type_Id__c = salesOrderType.Id;
        template.Resource_Type__c = parentResourceType.Id;
        template.Unit_of_Measure__c = unitOfMeasure.Id;
        templates.add(template);

        template = new Template__c();
        template.Name = 'Field Services';
        template.Sales_Order_Type_Id__c = salesOrderType.Id;
        template.Resource__c = childResource.Id;
        template.Unit_of_Measure__c = unitOfMeasure.Id;
        templates.add(template);

        template = new Template__c();
        template.Name = 'Field Services';
        template.Sales_Order_Type_Id__c = salesOrderType.Id;
        template.Resource_Type__c = childResourceType.Id;
        template.Unit_of_Measure__c = unitOfMeasure.Id;
        templates.add(template);

        insert templates;
    }
}