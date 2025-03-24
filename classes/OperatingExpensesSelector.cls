public with sharing class OperatingExpensesSelector extends fflib_SObjectSelector {

    public static OperatingExpensesSelector newInstance(){
        return (OperatingExpensesSelector) Application.Selector.newInstance(Operating_Expense__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType(){
        return Operating_Expense__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
                Operating_Expense__c.Id,
                Operating_Expense__c.Name,
                Operating_Expense__c.Service_Center__c,
                Operating_Expense__c.Operating_Expense_Cost_Pct__c,
                Operating_Expense__c.Effective_Date__c
        };
    }

    public Operating_Expense__c selectByServiceCenterIdAndEffectiveDate(Id serviceCenterId, Date dateValue){
        List<Operating_Expense__c> operatingExpenses = System.Database.query(
                newQueryFactory(true)
                        .setCondition('Service_Center__c = :serviceCenterId AND Effective_Date__c <= :dateValue')
                        .setOrdering('Effective_Date__c', fflib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );

        if(operatingExpenses.size() > 0){
            return operatingExpenses[0];
        } else {
            return null;
        }
    }

}