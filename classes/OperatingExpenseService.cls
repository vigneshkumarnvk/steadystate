public with sharing class OperatingExpenseService {

    public static Decimal getOperatingExpense(Id serviceCenterId, Date operationDate){
        Decimal operatingExpensePct = 0;
        Operating_Expense__c operatingExpense = OperatingExpensesSelector.newInstance().selectByServiceCenterIdAndEffectiveDate(serviceCenterId, operationDate);
        if(operatingExpense != null){
            operatingExpensePct = operatingExpense.Operating_Expense_Cost_Pct__c;
        }
        return operatingExpensePct;
    }

}