public with sharing class ParentChildResourceImport {

    public static void importParentChildResources() {
        List<Parent_Child_Resource__c> pcrs = [SELECT Parent_Resource_Type__c, Parent_Resource__c,
                Child_1_Resource_Type__c, Child_1_Resource__c, Child_1_UOM__c,
                Child_2_Resource_Type__c, Child_2_Resource__c, Child_2_UOM__c,
                Child_3_Resource_Type__c, Child_3_Resource__c, Child_3_UOM__c FROM Parent_Child_Resource__c];

        delete [SELECT Id FROM Presumptive_Resource__c];
        List<Presumptive_Resource__c> presumptives = new List<Presumptive_Resource__c>();
        for (Parent_Child_Resource__c pcr : pcrs) {
            //if (pcr.Child_1_Resource_Type__c == 'a1Sf4000001MWPlEAO') { //manual fix
            //    pcr.Child_1_Resource_Type__c = 'a1S3I000000JA5dUAG';
            //}

            if (pcr.Child_1_Resource_Type__c != null || pcr.Child_1_Resource__c != null) {
                presumptives.add(new Presumptive_Resource__c(Parent_Resource_Type__c = pcr.Parent_Resource_Type__c, Parent_Resource__c = pcr.Parent_Resource__c,
                        Child_Resource_Type__c = pcr.Child_1_Resource_Type__c, Child_Resource__c = pcr.Child_1_Resource__c, Child_Unit_of_Measure__c = pcr.Child_1_UOM__c));
            }
            if (pcr.Child_2_Resource_Type__c != null || pcr.Child_2_Resource__c != null) {
                presumptives.add(new Presumptive_Resource__c(Parent_Resource_Type__c = pcr.Parent_Resource_Type__c, Parent_Resource__c = pcr.Parent_Resource__c,
                        Child_Resource_Type__c = pcr.Child_2_Resource_Type__c, Child_Resource__c = pcr.Child_2_Resource__c, Child_Unit_of_Measure__c = pcr.Child_2_UOM__c));
            }
            if (pcr.Child_3_Resource_Type__c != null || pcr.Child_3_Resource__c != null) {
                presumptives.add(new Presumptive_Resource__c(Parent_Resource_Type__c = pcr.Parent_Resource_Type__c, Parent_Resource__c = pcr.Parent_Resource__c,
                        Child_Resource_Type__c = pcr.Child_3_Resource_Type__c, Child_Resource__c = pcr.Child_3_Resource__c, Child_Unit_of_Measure__c = pcr.Child_3_UOM__c));
            }
        }
        insert presumptives;
    }

    public static void importTemplate() {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Template__c> templates = [SELECT Name, Resource_Type__c, Resource__c, Unit_of_Measure__c FROM Template__c];


            Map<Id, Resource__c> mapResourcesById = new Map<Id, Resource__c>();
            Map<Id, Resource_Type__c> mapResourceTypesById = new Map<Id, Resource_Type__c>();
            Set<String> resourceIds = new Set<String>();
            Set<String> resourceTypeIds = new Set<String>();
            for (Template__c template : templates) {
                if (template.Resource__c != null) {
                    resourceIds.add(template.Resource__c);
                }
                if (template.Resource_Type__c != null) {
                    resourceTypeIds.add(template.Resource_Type__c );
                }
            }
            for (Resource__c resource : [SELECT Id, Category__c, Resource_Type__c, Description__c FROM Resource__c WHERE Id IN :resourceIds]) {
                mapResourcesById.put(resource.Id, resource);
            }
            for (Resource_Type__c resourceType : [SELECT Id, Category__c, Description__c FROM Resource_Type__c WHERE Id IN :resourceTypeIds]) {
                mapResourceTypesById.put(resourceType.Id, resourceType);
            }

            Map<String, Wrapper> mapWrappersByName = new Map<String, Wrapper>();
            for (Template__c template : templates) {
                Wrapper wrapper;
                if (mapWrappersByName.containsKey(template.Name)) {
                    wrapper= mapWrappersByName.get(template.Name);
                }
                else {
                    wrapper = new Wrapper();
                    wrapper.Template = new Job_Task_Template__c(Name = template.Name);
                    mapWrappersByName.put(wrapper.Template.Name, wrapper);
                }

                Job_Task_Template_Line__c taskTemplateLine = new Job_Task_Template_Line__c();

                if (template.Resource_Type__c != null) {
                    if (mapResourceTypesById.containsKey(template.Resource_Type__c)) {
                        Resource_Type__c resourceType = mapResourceTypesById.get(template.Resource_Type__c);
                        taskTemplateLine.Resource_Type__c = resourceType.Id;
                        taskTemplateLine.Category__c = resourceType.Category__c;
                        taskTemplateLine.Description__c = resourceType.Description__c;
                    }
                    else {
                        throw new DataException('Resource Type Id ' + template.Resource_Type__c + ' does not exist.');
                    }
                    system.debug('category A = ' + taskTemplateLine.Category__c);

                    if (taskTemplateLine.Category__c == null) {
                        throw new DataException('Category is required for resource type ' + taskTemplateLine.Resource_Type__c);
                    }
                }

                if (template.Resource__c != null) {
                    if (mapResourcesById.containsKey(template.Resource__c)) {
                        Resource__c resource = mapResourcesById.get(template.Resource__c);
                        taskTemplateLine.Resource_Type__c = resource.Resource_Type__c;
                        taskTemplateLine.Resource__c = resource.Id;
                        taskTemplateLine.Category__c = resource.Category__c;
                        taskTemplateLine.Description__c = resource.Description__c;
                    }
                    else {
                        throw new DataException('Resource Id ' + template.Resource__c + ' does not exist.');
                    }
                    system.debug('category B = ' + taskTemplateLine.Category__c);

                    if (taskTemplateLine.Category__c == null) {
                        throw new DataException('Category is required for resource ' + taskTemplateLine.Resource__c);
                    }
                }
                taskTemplateLine.Unit_of_Measure__c = template.Unit_of_Measure__c;


                wrapper.TemplateLines.add(taskTemplateLine);
            }

            List<Job_Task_Template__c> taskTemplates = new List<Job_Task_Template__c>();
            for (Wrapper wrapper : mapWrappersByName.values()) {
                taskTemplates.add(wrapper.Template);
            }
            insert taskTemplates;


            List<Job_Task_Template_Line__c> taskTemplateLines = new List<Job_Task_Template_Line__c>();
            for (Wrapper wrapper : mapWrappersByName.values()) {
                Integer lineNo = 0;
                for (Job_Task_Template_Line__c templateLine : wrapper.TemplateLines) {
                    lineNo++;
                    templateLine.Line_No__c = lineNo;

                    if (templateLine.Category__c == null) {
                        throw new DataException('Category is required for template ' + wrapper.Template.Name + ' resource type/resource ' + templateLine.Resource_Type__c + '/' + templateLine.Resource__c);
                    }
                    templateLine.Job_Task_Template__c = wrapper.Template.Id;
                    taskTemplateLines.add(templateLine);
                }


            }
            insert taskTemplateLines;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void updateSalesOrderTypes() {
        Map<Id, String> mapNamesBySalesOrderTypeId = new Map<Id, String>();
        List<Template__c> templates = [SELECT Name, Sales_Order_Type_Id__c FROM Template__c];
        for (Template__c template : templates) {
            if (template.Sales_Order_Type_Id__c != null) {
                mapNamesBySalesOrderTypeId.put(template.Sales_Order_Type_Id__c, template.Name);
            }
        }

        Map<String, Job_Task_Template__c> mapJobTaskTemplatesByName = new Map<String, Job_Task_Template__c>();
        for (Job_Task_Template__c jobTaskTemplate : [SELECT Id, Name FROM Job_Task_Template__c]) {
            mapJobTaskTemplatesByName.put(jobTaskTemplate.Name, jobTaskTemplate);
        }

        List<Sales_Order_Type__c> salesOrderTypes = [SELECT Id, Name FROM Sales_Order_Type__c];
        for (Sales_Order_Type__c salesOrderType : salesOrderTypes) {
            salesOrderType.Job_Task_Template__c = null;
            if (mapNamesBySalesOrderTypeId.containsKey(salesOrderType.Id)) {
                String templateName = mapNamesBySalesOrderTypeId.get(salesOrderType.Id);
                if (mapJobTaskTemplatesByName.containsKey(templateName)) {
                    Job_Task_Template__c jobTaskTemplate = mapJobTaskTemplatesByName.get(templateName);
                    salesOrderType.Job_Task_Template__c = jobTaskTemplate.Id;
                }
            }
        }

        update salesOrderTypes;
    }

    /*
    public static void cleanUpTemplateName() {
        List<Job_Task_Template__c> jobTaskTemplates = [SELECT Id, Name FROM Job_Task_Template__c];
        for (Job_Task_Template__c jobTaskTemplate : jobTaskTemplates) {
            if (jobTaskTemplate.Name.contains(') ')) {
                Integer pos = jobTaskTemplate.Name.indexOf(')');
                jobTaskTemplate.Name = jobTaskTemplate.Name.substring(pos + 2);
            }
        }
        update jobTaskTemplates;
    }*/

    public static void updateParentChildLines() {
        Savepoint sp = Database.setSavepoint();
        try {
            Set<Id> resIds = new Set<Id>();
            Set<Id> resTypeIds = new Set<Id>();

            List<Job_Task_Template_Line__c> templateLines = [SELECT Id, Job_Task_Template__c, Resource__c, Resource_Type__c, Parent_Line__c FROM Job_Task_Template_Line__c];
            for (Job_Task_Template_Line__c templateLine : templateLines) {
                if (templateLine.Resource_Type__c != null) {
                    resTypeIds.add(templateLine.Resource_Type__c);
                }
                if (templateLine.Resource__c != null) {
                    resIds.add(templateLine.Resource__c);
                }
            }

            Map<Id, Set<Id>> mapParentChildren = new Map<Id, Set<Id>>();
            List<Presumptive_Resource__c> presumptiveResources = [SELECT Parent_Resource_Type__c, Parent_Resource__c, Child_Resource_Type__c, Child_Resource__c FROM Presumptive_Resource__c];
            for (Presumptive_Resource__c presumptiveResource : presumptiveResources) {
                if (presumptiveResource.Parent_Resource_Type__c != null) {
                    Set<Id> children;
                    if (mapParentChildren.containsKey(presumptiveResource.Parent_Resource_Type__c)) {
                        children = mapParentChildren.get(presumptiveResource.Parent_Resource_Type__c);
                    } else {
                        children = new Set<Id>();
                        mapParentChildren.put(presumptiveResource.Parent_Resource_Type__c, children);
                    }

                    if (presumptiveResource.Child_Resource_Type__c != null) {
                        children.add(presumptiveResource.Child_Resource_Type__c);
                    }
                    if (presumptiveResource.Child_Resource__c != null) {
                        children.add(presumptiveResource.Child_Resource__c);
                    }
                }

                if (presumptiveResource.Parent_Resource__c != null) {
                    Set<Id> children;
                    if (mapParentChildren.containsKey(presumptiveResource.Parent_Resource__c)) {
                        children = mapParentChildren.get(presumptiveResource.Parent_Resource__c);
                    } else {
                        children = new Set<Id>();
                        mapParentChildren.put(presumptiveResource.Parent_Resource__c, children);
                    }

                    if (presumptiveResource.Child_Resource_Type__c != null) {
                        children.add(presumptiveResource.Child_Resource_Type__c);
                    }
                    else if (presumptiveResource.Child_Resource__c != null) {
                        children.add(presumptiveResource.Child_Resource__c);
                    }
                }
            }

            Map<Id, List<Job_Task_Template_Line__c>> mapTemplateLinesByTemplateId = new Map<Id, List<Job_Task_Template_Line__c>>();
            for (Job_Task_Template_Line__c templateLine : templateLines) {
                List<Job_Task_Template_Line__c> mapTemplateLinesByResourceId;
                if (mapTemplateLinesByTemplateId.containsKey(templateLine.Job_Task_Template__c)) {
                    mapTemplateLinesByResourceId = mapTemplateLinesByTemplateId.get(templateLine.Job_Task_Template__c);
                } else {
                    mapTemplateLinesByResourceId = new List<Job_Task_Template_Line__c>();
                    mapTemplateLinesByTemplateId.put(templateLine.Job_Task_Template__c, mapTemplateLinesByResourceId);
                }
                mapTemplateLinesByResourceId.add(templateLine);
            }

            Integer childCount = 0;
            List<Job_Task_Template_Line__c> jobTaskTemplateLinesToUpdate = new List<Job_Task_Template_Line__c>();

            for (Id templateId : mapTemplateLinesByTemplateId.keySet()) {
                //check if job task template lines contain a parent resource
                List<Job_Task_Template_Line__c> jobTaskTemplateLines = mapTemplateLinesByTemplateId.get(templateId);

                system.debug('*******template id ' + templateId);

                for (Integer i = 0; i < jobTaskTemplateLines.size(); i++) {
                    Job_Task_Template_Line__c jobTaskTemplateLine = jobTaskTemplateLines[i];

                    Set<Id> childResourceIds = new Set<Id>();
                    if (mapParentChildren.containsKey(jobTaskTemplateLine.Resource_Type__c)) {
                        childResourceIds = mapParentChildren.get(jobTaskTemplateLine.Resource_Type__c);
                    }
                    else if (mapParentChildren.containsKey(jobTaskTemplateLine.Resource__c)) {
                        childResourceIds = mapParentChildren.get(jobTaskTemplateLine.Resource__c);
                    }

                    if (childResourceIds.size() > 0) { //is parent
                        for (Integer j = 0; j < jobTaskTemplateLines.size(); j++) {
                            Job_Task_Template_Line__c childLine = jobTaskTemplateLines[j];

                            if (childLine.Parent_Line__c == null) {
                                if (childLine.Resource_Type__c != null && childResourceIds.contains(childLine.Resource_Type__c)) {
                                    childLine.Parent_Line__c = jobTaskTemplateLine.Id;
                                    System.debug('** -> ' + childLine.Id + ': parent = ' + jobTaskTemplateLine.Id);
                                    jobTaskTemplateLinesToUpdate.add(childLine);
                                } else if (childLine.Resource__c != null && childResourceIds.contains(childLine.Resource__c)) {
                                    childLine.Parent_Line__c = jobTaskTemplateLine.Id;
                                    System.debug('** -> ' + childLine.Id + ': parent = ' + jobTaskTemplateLine.Id);
                                    jobTaskTemplateLinesToUpdate.add(childLine);
                                }
                            }
                        }
                    }
                }
            }
            //if (1==1) throw new DataException('** ' + jobTaskTemplateLinesToUpdate.size());
            update jobTaskTemplateLinesToUpdate;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }


    public static void checkAllowZeroUnitCostResources() {
        List<Resource__c> resources = [SELECT Id FROM Resource__c WHERE Category__c = 'Demurrage'];
        for (Resource__c resource : resources) {
            resource.Allow_Zero_Unit_Cost_at_TM_Confirmation__c = true;
        }
        update resources;
    }

    public class Wrapper {
        Job_Task_Template__c Template;
        List<Job_Task_Template_Line__c> TemplateLines;

        public Wrapper() {
            TemplateLines = new List<Job_Task_Template_Line__c>();
        }
    }
}