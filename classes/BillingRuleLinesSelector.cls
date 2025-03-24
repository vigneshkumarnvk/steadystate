public class BillingRuleLinesSelector extends fflib_SObjectSelector{

    public static BillingRuleLinesSelector newInstance(){
        return (BillingRuleLinesSelector) Application.Selector.newInstance(Billing_Rule_Line__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType(){
        return Billing_Rule_Line__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
                Billing_Rule_Line__c.Billing_Rule__c,
                Billing_Rule_Line__c.Calculation_Type__c,
                Billing_Rule_Line__c.Day__c,
                Billing_Rule_Line__c.Start_Time__c,
                Billing_Rule_Line__c.End_Time__c,
                Billing_Rule_Line__c.Id,
                Billing_Rule_Line__c.Name,
                Billing_Rule_Line__c.Number_of_Hours__c,
                Billing_Rule_Line__c.Rate_Code__c,
                Billing_Rule_Line__c.Hours_After_Number_of_Hours__c,
                Billing_Rule_Line__c.Rate_Code_After_Number_of_Hours__c,
                Billing_Rule_Line__c.Rate_Code_for_Remaining_Hours__c
        };
    }
}