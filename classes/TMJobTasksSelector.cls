public with sharing class TMJobTasksSelector extends fflib_SObjectSelector implements ITMJobTasksSelector {
    public static ITMJobTasksSelector newInstance() {
        return (ITMJobTasksSelector) Application.Selector.newInstance(TM_Job_Task__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType() {
        return TM_Job_Task__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                TM_Job_Task__c.Id,
                TM_Job_Task__c.Name,
                TM_Job_Task__c.Line_No__c,
                TM_Job_Task__c.Task_No__c,
                TM_Job_Task__c.TM__c,
                TM_Job_Task__c.Job_Task_Template__c,
                TM_Job_Task__c.Billing_Type__c,
                TM_Job_Task__c.Sales_Order_Job_Task__c
        };
    }

    public List<TM_Job_Task__c> selectByTMId(Set<Id> idSet){
        return (List<TM_Job_Task__c>) Database.query(newQueryFactory()
                .selectField('TM__r.Name')
                .selectField('Job_Task_Template__r.Name')
                .selectField('Sales_Order_Job_Task__c.Name')
                .setCondition('TM__c IN :idSet')
                .setOrdering('Task_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }

    public List<TM_Job_Task__c> selectById(Set<Id> idSet){
        return (List<TM_Job_Task__c>) Database.query(newQueryFactory()
                .selectField('TM__r.Name')
                .selectField('Job_Task_Template__r.Name')
                .selectField('Sales_Order_Job_Task__c.Name')
                .setCondition('Id IN :idSet')
                .setOrdering('Task_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }

    public List<TM_Job_Task__c> selectBySalesOrderJobTaskId(Set<Id> idSet){
        return (List<TM_Job_Task__c>) Database.query(newQueryFactory()
                .selectField('TM__r.Name')
                .selectField('Job_Task_Template__r.Name')
                .selectField('Sales_Order_Job_Task__c.Name')
                .setCondition('Sales_Order_Job_Task__c IN :idSet')
                .setOrdering('Task_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }
}