public class SalesOrderTypesSelector extends fflib_SObjectSelector {

    public static SalesOrderTypesSelector newInstance(){
        return (SalesOrderTypesSelector) Application.Selector.newInstance(Sales_Order_Type__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType(){
        return Sales_Order_Type__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
                Sales_Order_Type__c.Blocked__c,
                Sales_Order_Type__c.Code__c,
                Sales_Order_Type__c.CreatedById,
                Sales_Order_Type__c.CreatedDate,
                Sales_Order_Type__c.Description__c,
                Sales_Order_Type__c.Emergency_Response__c,
                Sales_Order_Type__c.Id,
                Sales_Order_Type__c.Name,
                //job task <<
                Sales_Order_Type__c.Job_Task_Template__c
                //job task >>
        };
    }

    public List<Sales_Order_Type__c> selectByIds(Set<Id> salesOrderTypeIds){
        return System.Database.query(
                newQueryFactory().setCondition('Id IN :salesOrderTypeIds').toSOQL());
    }

    public Map<Id, Sales_Order_Type__c> getSalesOrderTypesByIdsMap(Set<Id> salesOrderTypeIds){
        Map<Id, Sales_Order_Type__c> salesOrderTypesByIds = new Map<Id, Sales_Order_Type__c>();
        salesOrderTypesByIds.putAll(selectByIds(salesOrderTypeIds));
        return salesOrderTypesByIds;
    }
}