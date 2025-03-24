public class SalesOrder_BeforeUpdateTriggerHandler extends TriggerHandlerBase{
    public override void mainEntry(){ 
        System.debug('SalesOrder_BeforeUpdateTriggerHandler >> mainEntry()');

        List<Sales_Order__c> SOList = (List<Sales_Order__c>) Trigger.new;
        Map<Id, Sales_Order__c> oldValues = (Map<Id, Sales_Order__c>) Trigger.oldMap;
        Boolean isInsert = Trigger.isInsert;

        SalesOrderTriggersMgt.SOInsertUpdate(SOList, oldValues, isInsert);

        for (Sales_Order__c so : SOList) {
            Sales_Order__c xso = oldValues.get(so.Id);
            if (so.Do_Not_Reset_Sync_Flag__c != true) {
                if (so.Name != xso.Name || so.Bill_to_Customer_No__c != xso.Bill_to_Customer_No__c
                || so.Street__c != xso.Street__c || so.City__c != xso.City__c || so.State__c != xso.State__c
                || so.Postal_Code__c != xso.Postal_Code__c || so.Country__c != xso.Country__c
                || so.Phone_No__c != xso.Phone_No__c || so.Fax_No__c != xso.Fax_No__c
                || so.Document_Status__c != xso.Document_Status__c || so.Billing_Type__c != xso.Billing_Type__c
                || so.Order_Type_Description__c != xso.Order_Type_Description__c || so.Inter_Company_Job__c != xso.Inter_Company_Job__c
                || so.Certified_PW_Job__c != xso.Certified_PW_Job__c || so.Prevailing_Wage_Job__c != xso.Prevailing_Wage_Job__c
                || so.Estimated_Revenue__c != xso.Estimated_Revenue__c || so.Sage_Job_No__c != xso.Sage_Job_No__c
                || so.Project_Coordinator__c != xso.Project_Coordinator__c || so.Account_Executives__c != xso.Account_Executives__c
                || so.CMR_Description__c != xso.CMR_Description__c) {
                    so.Sync_d__c = false;
                }
            }
            so.Do_Not_Reset_Sync_Flag__c = false;

            if(so.Name != xso.Name || so.Document_Status__c != xso.Document_Status__c){
                so.Synced_with_Coupa__c = false;
            }
        }
    }
}