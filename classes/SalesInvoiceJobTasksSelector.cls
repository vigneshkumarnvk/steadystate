public with sharing class SalesInvoiceJobTasksSelector extends fflib_SObjectSelector implements ISalesInvoiceJobTasksSelector {
    public static ISalesInvoiceJobTasksSelector newInstance() {
        return (ISalesInvoiceJobTasksSelector) Application.Selector.newInstance(Sales_Invoice_Job_Task__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType() {
        return Sales_Invoice_Job_Task__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
                Sales_Invoice_Job_Task__c.Id,
                Sales_Invoice_Job_Task__c.Name,
                Sales_Invoice_Job_Task__c.Line_No__c,
                Sales_Invoice_Job_Task__c.Task_No__c,
                Sales_Invoice_Job_Task__c.Print_Order__c, //Ticket#20402
                Sales_Invoice_Job_Task__c.Sales_Invoice__c,
                Sales_Invoice_Job_Task__c.Sales_Order_Job_Task__c,
                Sales_Invoice_Job_Task__c.Billing_Type__c,
                Sales_Invoice_Job_Task__c.Billing_Amount__c,
                Sales_Invoice_Job_Task__c.Tax__c,
                Sales_Invoice_Job_Task__c.Tax_Pct__c,
                Sales_Invoice_Job_Task__c.Tax_Group__c,
                Sales_Invoice_Job_Task__c.Billing_Pct__c,
                Sales_Invoice_Job_Task__c.Voided__c,
                //ticket 19127 <<
                Sales_Invoice_Job_Task__c.Invoice_Format__c,
                //ticket 19127 >>
                //ticket 19672 <<
                Sales_Invoice_Job_Task__c.Fixed_Price_Surcharge_Option__c
                //ticket 19672 >>
        };
    }

    public List<Sales_Invoice_Job_Task__c> selectById(Set<Id> idSet){
        return (List<Sales_Invoice_Job_Task__c>) Database.query(newQueryFactory()
                .selectField('Sales_Invoice__r.Name')
                .setCondition('Id IN :idSet')
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }

    public List<Sales_Invoice_Job_Task__c> selectBySalesInvoiceId(Set<Id> idSet){
        return selectByJobTaskId(idSet, null);
    }

    public List<Sales_Invoice_Job_Task__c> selectByJobTaskId(Set<Id> salesInvoiceIds, Set<Id> jobTaskIds){
        List<String> filters = new List<String>();
        filters.add('Sales_Invoice__c IN :salesInvoiceIds');
        if (jobTaskIds != null && jobTaskIds.size() > 0) {
            filters.add('Id IN :jobTaskIds');
        }

        return (List<Sales_Invoice_Job_Task__c>) Database.query(newQueryFactory(true)
                .setCondition(String.join(filters, ' AND '))
                .setOrdering('Line_No__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }

    //Ticket#20402
    public List<Sales_Invoice_Job_Task__c> selectBySalesInvoiceIdForPrint(Set<Id> ids){
        return (List<Sales_Invoice_Job_Task__c>) Database.query(newQueryFactory()
                .setCondition('Sales_Invoice__c IN :ids')
                .setOrdering('Print_Order__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL());
    }
}