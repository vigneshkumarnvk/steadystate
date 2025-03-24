public with sharing class BillingRuleService {
    public static Map<String, Billing_Rule__c> billingRulesByAssumptions = new Map<String, Billing_Rule__c>();

    public static void setBillingRulesByAssumptions() {
        for (Billing_Rule__c billingRule : BillingRulesSelector.newInstance().selectByAssumptions()) {
            if (billingRule.Quote_Order_Assumption__c != null) {
                //Quote_Order_Assumption__c is a multi picklist
                for (String assumption : billingRule.Quote_Order_Assumption__c.split(';')) {
                    billingRulesByAssumptions.put(assumption, billingRule);
                }
            }
        }
    }

    public static Billing_Rule__c getBillingRuleIdForSalesOrderAssumption(Sales_Order__c salesOrder){
        if(billingRulesByAssumptions.size() == 0){
            setBillingRulesByAssumptions();
        }

        String assumption = '';
        if (salesOrder.Portal_Basis__c == true) {
            assumption = 'PortalBasis';
        } else if (salesOrder.Overtime_Rate__c == true) {
            assumption = 'OvertimeRate';
        } else if (salesOrder.Daily_Rate__c == true) {
            assumption = 'DailyRate';
        } else if (salesOrder.Lump_Sum__c == true) {
            if(salesOrder.CreatedDate < CompanySettingUtil.acvSetting.X2023_Billing_Rule_Start_Date__c) {
                assumption = 'LumpSum';
            } else {
                assumption = 'LumpSum2023';
            }
        } else if (salesOrder.Portal_Basis_Adv__c == true) {
            assumption = 'PortalBasisAdv';
        } else if (salesOrder.Default_Billing_Rule_2023__c == true) {
            assumption = 'DefaultBillingRule2023';
        }

        System.debug('Info: assumption --> ' + assumption);
        if (billingRulesByAssumptions.containsKey(assumption)) {
            return billingRulesByAssumptions.get(assumption);
        } else {
            throw new DataException('Order assumption ' + assumption + ' is not mapped to a billing rule. Please contact admin to set up the mapping for the assumption.');
        }
    }
}