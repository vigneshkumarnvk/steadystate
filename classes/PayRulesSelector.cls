public class PayRulesSelector extends fflib_SObjectSelector implements IPayRulesSelector{

    public static IPayRulesSelector newInstance(){
        return (IPayRulesSelector) Application.Selector.newInstance(Pay_Rule__c.SObjectType);
    }

    public SObjectType getSObjectType() {
        return Pay_Rule__c.SObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
                Pay_Rule__c.Id,
                Pay_Rule__c.Name,
                //Pay_Rule__c.Overhead_Pct__c,
                Pay_Rule__c.Pay_Holiday__c,
                Pay_Rule__c.Pay_Travel_Time__c,
                Pay_Rule__c.Type__c,
                Pay_Rule__c.Mon_Sun_Work_Week__c
        };
    }

    /*
     *  Ticket#21502 - add blocked filter to Pay Rule Lines.
     */
    public List<Pay_Rule__c> selectPayRulesByIdWithLines(Set<Id> idSet) {
        fflib_QueryFactory qf = newQueryFactory();
        qf.setCondition('Id IN :idSet')
                .subselectQuery('Pay_Rule_Lines__r')
                .selectField('Resource_Type__c')
                .selectField('Unit_Cost__c')
                .selectField('Rate__c')
                .selectField('Overtime_Rate_Multiple__c')
                .selectField('Double_Time_Rate_Multiple__c')
                .selectField('Saturday_Pay_Code__c')
                .selectField('Sunday_Pay_Code__c')
                .selectField('Fringe__c')
                .selectField('OT_Fringe_Amount__c')
                .selectField('DT_Fringe_Amount__c')
                .selectField('Holiday_with_Double_Time_Pay__c')
                .selectField('Holidays_with_Overtime_Pay__c')
                .setCondition('Blocked__c != TRUE');
        String soql = qf.toSOQL();
        return (List<Pay_Rule__c>) Database.query(soql);
    }
}