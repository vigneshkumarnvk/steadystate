/*
Dated    : 07/22/2023
Summary  : Trigger framework interface that defines structure for trigger handler classes
* Modification Log :
 * Developer                 Date                   Description
 * ----------------------------------------------------------------------------                 
Harika Madapathi           07/22/2023              68128 - Tech Debt: Update Trigger Framework for SalesOrder object
Shahwaz Khan               10/21/2024              DE36096: SF-Remove ability for user to delete sales quotes/orders
*************************************************************************************************************/
trigger SalesOrderTrigger  on Sales_Order__c (after update, after insert, before insert, before update,before delete) {
    if(trigger.isInsert || trigger.isupdate){
    rsgTriggerStrategy.executeTriggerHandler(Trigger.operationType); 
    }
    //DE36096
    if(Trigger.isBefore && Trigger.isDelete){
        SalesOrderTriggersMgt.beforDelateValidation(Trigger.isBefore,Trigger.isDelete);
    }
    if(trigger.isAfter && trigger.isupdate){
        SalesOrderTriggersMgt.handleAfterUpdate(Trigger.new, Trigger.oldMap);           
    }
}
/*trigger SalesOrderTrigger on Sales_Order__c (before insert, before update, before delete, after insert, after update, after delete) {

    if(CompanyMgmt.byPassTrigger != true){
        fflib_SObjectDomain.triggerHandler(SalesOrders.class);

        if(Trigger.isBefore){
            if(Trigger.isInsert || Trigger.isUpdate){
                List<Sales_Order__c> SOList = Trigger.new;
                SalesOrderTriggersMgt.SOInsertUpdate(SOList, Trigger.oldMap, Trigger.isInsert);

                if (Trigger.isUpdate) {
                    for (Sales_Order__c so : Trigger.new) {
                        Sales_Order__c xso = Trigger.oldMap.get(so.Id);
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

            if(Trigger.isDelete){
                List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
                if(profiles.size() > 0){
                    if(profiles[0].Name != 'System Administrator'){
                        throw new DataException('You are not allowed to delete Sales Order');
                    }
                }

                Set<Id> quoteIds = new Set<Id>();
                for(Sales_Order__c salesOrder : Trigger.old){
                    if(salesOrder.Document_Type__c == 'Sales Quote'){
                        quoteIds.add(salesOrder.Id);
                    }
                }

                if(quoteIds.size() > 0){
                    List<Sales_Order__c> salesOrders = [SELECT Id, Name, From_Sales_Quote__r.Name FROM Sales_Order__c WHERE From_Sales_Quote__c IN :quoteIds];
                    if(salesOrders.size() > 0){
                        throw new DataException('You are not allowed to delete Sales Quote ' + salesOrders[0].From_Sales_Quote__r.Name + ' because it is linked to Sales Order# ' + salesOrders[0].Name);
                    }
                }
            }
        }
    }
}*/