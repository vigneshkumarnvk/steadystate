public with sharing class IntegrationSettingUtil {
    //Ticket25259 - add Client_Id__c, Client_Secret__c, Scope__c, Grant_Type__c to query
    public static Integration_Setting__mdt coupaSetting {
        get{
            if(coupaSetting == null){
                coupaSetting = [
                        SELECT Id, Label, API_Key__c, Base_URL__c, Coupa_Sales_Order_Lookup_Id__c, Coupa_Asset_Lookup_Id__c, Enabled__c,
                                Client_Id__c, Client_Secret__c, Scope__c, Grant_Type__c
                        FROM Integration_Setting__mdt
                        WHERE Label = 'Coupa'
                        LIMIT 1];
            }
            return coupaSetting;
        }
        private set;
    }
}