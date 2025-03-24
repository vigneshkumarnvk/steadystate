public class BillingRulesSelector extends fflib_SObjectSelector {

    public static BillingRulesSelector newInstance(){
        return (BillingRulesSelector) Application.Selector.newInstance(Billing_Rule__c.SObjectType);
    }

    public Schema.SObjectType getSObjectType(){
        return Billing_Rule__c.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList(){
        return new List<Schema.SObjectField>{
                Billing_Rule__c.Id,
                Billing_Rule__c.Name,
                Billing_Rule__c.Holidays_Bill_in_DT_Rate__c,
                Billing_Rule__c.Holidays_Bill_in_OT_Rate__c,
                Billing_Rule__c.Saturday_Rate_Code__c,
                Billing_Rule__c.Sunday_Rate_Code__c,
                Billing_Rule__c.Time_After__c,
                Billing_Rule__c.Time_After_Rate_Code__c,
                Billing_Rule__c.Time_Before__c,
                Billing_Rule__c.Time_Before_Rate_Code__c,
                Billing_Rule__c.Quote_Order_Assumption__c,
                //Ticket#20496 >>
                Billing_Rule__c.Enable_Weekly_Total_Calculation__c,
                Billing_Rule__c.Billing_Rate_After_Weekly_Threshold__c,
                Billing_Rule__c.Weekly_Hour_Threshold__c
                //Ticket#20496
        };
    }

    public List<Billing_Rule__c> selectById(Set<Id> idSet){
        return (List<Billing_Rule__c>) Database.query(newQueryFactory().setCondition('Id IN :idSet').toSOQL());
    }

    //billing rule mapping <<
    public List<Billing_Rule__c> selectByAssumptions(){
        return (List<Billing_Rule__c>) Database.query(newQueryFactory().setCondition('Quote_Order_Assumption__c != NULL').toSOQL());
    }
    //billing rule mapping >>

    public List<Billing_Rule__c> selectByIdsWithLines(Set<Id> ids){
        fflib_QueryFactory billingRuleQueryFactory = newQueryFactory();
        new BillingRuleLinesSelector().addQueryFactorySubselect(billingRuleQueryFactory)
                .selectField('Billing_Rule__r.Name')
                .setOrdering(Billing_Rule_Line__c.Day__c, fflib_QueryFactory.SortOrder.ASCENDING, true)
                .addOrdering(Billing_Rule_Line__c.Start_Time__c, fflib_QueryFactory.SortOrder.ASCENDING, true);

        System.debug('Info: ' + billingRuleQueryFactory.toSOQL());

        return (List<Billing_Rule__c>) Database.query(billingRuleQueryFactory
                .setCondition('Id IN :ids')
                .toSOQL());
    }
}