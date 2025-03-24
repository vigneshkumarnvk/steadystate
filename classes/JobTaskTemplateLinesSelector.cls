public class JobTaskTemplateLinesSelector extends fflib_SObjectSelector implements IJobTaskTemplateLinesSelector {

    public static IJobTaskTemplateLinesSelector newInstance() {
        return (IJobTaskTemplateLinesSelector) Application.Selector.newInstance(Job_Task_Template_Line__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType() {
        return Job_Task_Template_Line__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                Job_Task_Template_Line__c.Id,
                Job_Task_Template_Line__c.Name,
                Job_Task_Template_Line__c.Job_Task_Template__c,
                Job_Task_Template_Line__c.Line_No__c,
                Job_Task_Template_Line__c.Category__c,
                Job_Task_Template_Line__c.Resource__c,
                Job_Task_Template_Line__c.Resource_Type__c,
                Job_Task_Template_Line__c.Resource_UOM__c,
                Job_Task_Template_Line__c.Resource_Type_UOM__c,
                Job_Task_Template_Line__c.Description__c,
                Job_Task_Template_Line__c.Unit_of_Measure__c,
                Job_Task_Template_Line__c.Cost_Method__c,
                Job_Task_Template_Line__c.Unit_Weight_Vol__c,
                Job_Task_Template_Line__c.Container_Size__c,
                Job_Task_Template_Line__c.Quantity__c,
                Job_Task_Template_Line__c.Question__c,
                //ticket 19130 <<
                /*
                Job_Task_Template_Line__c.Parent_Line__c,
                Job_Task_Template_Line__c.Has_Child_Lines__c,
                */
                Job_Task_Template_Line__c.Is_Child_Resource__c,
                Job_Task_Template_Line__c.Dereferenced_Child_Resource__c
                // ticket 19130 >>

        };
    }

    public List<Job_Task_Template_Line__c> selectByTemplateId(Set<Id> idSet, List<String> filters) {
        if (filters == null) {
            filters = new List<String>();
        }
        if (idSet != null) {
            filters.add('Job_Task_Template__c IN :idSet');
        }
        fflib_QueryFactory queryFactory = newQueryFactory(true);
        queryFactory.selectField('Job_Task_Template__r.Name')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Has_Container__c')
                .selectField('Resource__r.Has_Weight_Volume__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Fleet_No_Required__c')
                .selectField('Resource_UOM__r.Name')
                .selectField('Resource_UOM__r.Unit_of_Measure__r.Name')
                .selectField('Resource_UOM__r.Container_Size__c')
                .selectField('Resource_Type_UOM__r.Name')
                .selectField('Resource_Type_UOM__r.Unit_of_Measure__r.Name')
                //ticket 19130 <<
                .selectField('Resource__r.Blocked__c')
                .selectField('Resource_Type__r.Blocked__c')
                //ticket 19130 >>
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Unit_of_Measure__r.Description__c')
                .selectField('Unit_of_Measure__r.Hours_UOM__c')
                .selectField('Unit_Weight_Vol__r.Name')
                .selectField('Unit_Weight_Vol__r.Container_Size__c')
                .selectField('Container_Size__r.Name')
                //ticket 19130 <<
                //.selectField('Parent_Line__r.Line_No__c')
                //ticket 19130 >>
                .setCondition(String.join(filters, ' AND '))
                .setOrdering('Name', fflib_QueryFactory.SortOrder.ASCENDING, true);
                //ticket 19130 <<
                /*
                .subselectQuery('Job_Task_Template_Lines__r')
                .selectField('Id')
                .selectField('Category__c')
                .selectField('Resource__c')
                .selectField('Resource__r.Name')
                .selectField('Resource__r.Description__c')
                .selectField('Resource_Type__c')
                .selectField('Resource_Type__r.Name')
                .selectField('Resource_Type__r.Description__c')
                .selectField('Description__c')
                .selectField('Unit_of_Measure__c')
                .selectField('Unit_of_Measure__r.Name')
                .selectField('Question__c')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
                */
                //ticket 19130 >>
        return (List<Job_Task_Template_Line__c>) Database.query(queryFactory.toSOQL());
    }
}