public with sharing class SalesOrderJobTasksSelector extends fflib_SObjectSelector implements ISalesOrderJobTasksSelector {
    public static ISalesOrderJobTasksSelector newInstance() {
        return (ISalesOrderJobTasksSelector) Application.Selector.newInstance(Sales_Order_Job_Task__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType() {
        return Sales_Order_Job_Task__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                Sales_Order_Job_Task__c.Id,
                Sales_Order_Job_Task__c.Name,
                Sales_Order_Job_Task__c.Line_No__c,
                Sales_Order_Job_Task__c.Task_No__c,
                Sales_Order_Job_Task__c.Sales_Order__c,
                Sales_Order_Job_Task__c.Job_Task_Template__c,
                Sales_Order_Job_Task__c.Billing_Type__c, 
                Sales_Order_Job_Task__c.Fixed_Price__c,
                Sales_Order_Job_Task__c.Surcharge_Amount__c,
                Sales_Order_Job_Task__c.Rolled_Up_Sales_Lines_Amount__c,
                Sales_Order_Job_Task__c.Tax__c,
                Sales_Order_Job_Task__c.Tax_Pct__c,
                Sales_Order_Job_Task__c.Tax_Group__c,
                Sales_Order_Job_Task__c.Pct_Billed__c,
                Sales_Order_Job_Task__c.Pct_To_Bill__c,
                Sales_Order_Job_Task__c.Amount_To_Bill__c,
                Sales_Order_Job_Task__c.Custom_Assumption1__c,
                Sales_Order_Job_Task__c.Custom_Assumption2__c,
                Sales_Order_Job_Task__c.Custom_Assumption3__c,
                Sales_Order_Job_Task__c.Custom_Assumption4__c,
                Sales_Order_Job_Task__c.Custom_Assumption5__c,
                Sales_Order_Job_Task__c.Custom_Assumption6__c,
                Sales_Order_Job_Task__c.Custom_Assumption7__c,
                Sales_Order_Job_Task__c.Custom_Assumption8__c,
                Sales_Order_Job_Task__c.Custom_Assumption9__c,
                Sales_Order_Job_Task__c.Custom_Assumption10__c,
                Sales_Order_Job_Task__c.Total_Amount__c,
                Sales_Order_Job_Task__c.Total_Amount_Incl_Tax__c,
                //ticket 19672 <<
                Sales_Order_Job_Task__c.Fixed_Price_Surcharge_Option__c
                //ticket 19672 >>
        };
    }

    public List<Sales_Order_Job_Task__c> selectById(Set<Id> idSet){
        return (List<Sales_Order_Job_Task__c>) Database.query(newQueryFactory()
                .selectField('Sales_Order__r.Name')
                .selectField('Sales_Order__r.Operating_Expense_Cost_Pct__c') //Ticket#24560
                .selectField('Job_Task_Template__r.Name')
                .setCondition('Id IN :idSet')
                .setOrdering('Task_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }

    public List<Sales_Order_Job_Task__c> selectBySalesOrderId(Set<Id> idSet){
        return selectByJobTaskId(idSet, null);
    }

    //ticket 20566 <<
    public List<Sales_Order_Job_Task__c> selectBySalesOrderId2(Set<Id> salesOrderIds){
        List<String> filters = new List<String>();
        filters.add('Sales_Order__c IN :salesOrderIds');

        return (List<Sales_Order_Job_Task__c>) Database.query(newQueryFactory()
                .selectField('Job_Task_Template__r.Name')
                .setCondition(String.join(filters, ' AND '))
                .setOrdering('Task_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }
    //ticket 20566 >>

    public List<Sales_Order_Job_Task__c> selectByJobTaskId(Set<Id> salesOrderIds, Set<Id> jobTaskIds){
        List<String> filters = new List<String>();
        filters.add('Sales_Order__c IN :salesOrderIds');
        if (jobTaskIds != null && jobTaskIds.size() > 0) {
            filters.add('Id IN :jobTaskIds');
        }

        //ticket 20177 <<
        /*
        return (List<Sales_Order_Job_Task__c>) Database.query(newQueryFactory()
                .selectField('Job_Task_Template__r.Name')
                .setCondition(String.join(filters, ' AND '))
                .setOrdering('Task_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
        */
        fflib_QueryFactory queryFactory = newQueryFactory(true);
        queryFactory.selectField('Job_Task_Template__r.Name')
                .setCondition(String.join(filters, ' AND '))
                .setOrdering('Task_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true);
        queryFactory.subselectQuery('TM_Job_Tasks__r')
                .selectField('Id')
                .selectField('TM__r.Sales_Invoice__c');
        return (List<Sales_Order_Job_Task__c>) Database.query(queryFactory.toSOQL());
        //ticket 20177 >>
    }
}