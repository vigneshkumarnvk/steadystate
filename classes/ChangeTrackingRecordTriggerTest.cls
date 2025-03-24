@isTest
private class ChangeTrackingRecordTriggerTest {

    private static testMethod void test() {
        List<INTG__INT_Object_Schema__c> schemas = new List<INTG__INT_Object_Schema__c>();
        INTG__INT_Object_Schema__c NAVSchema = new INTG__INT_Object_Schema__c(Name = 'NAV', INTG__System_Type__c = 'NAV/D365');
        schemas.add(NAVSchema);
        INTG__INT_Object_Schema__c SFSchema = new INTG__INT_Object_Schema__c(Name = 'SF', INTG__System_Type__c = 'Salesforce');
        schemas.add(SFSchema);
        insert schemas;
        
        INTG__INT_Mapping__c mapping = new INTG__INT_Mapping__c(Name = 'mapping', INTG__Direction__c = 'Inbound', INTG__Web_Service_Name__c='CustomerCard', INTG__Source_Object__c = NAVSchema.Id, INTG__Target_Object__c = SFSchema.Id);
        insert mapping;
        
        INTG__INT_Integration_Log__c log = new INTG__INT_Integration_Log__c(INTG__Mapping__c = mapping.Id, INTG__Status__c = 'Error');
        insert log;
        
        INTG__INT_Integration_Record__c integr = new INTG__INT_Integration_Record__c(INTG__Integration_Log__c = log.Id, INTG__Action__c = 'Insert/Update', INTG__Mapping__c = mapping.Id, INTG__Status__c = 'Error', INTG__Error_Message__c = 'error text');
        insert integr;
        
        INTG__INT_Change_Tracking_Record__c tracking = new INTG__INT_Change_Tracking_Record__c (INTG__Record_Id__c = mapping.Id, INTG__Mapping__c = mapping.Id, INTG__Status__c = 'Error', INTG__Integration_Record__c = integr.Id, INTG__Last_Action_Date__c = system.today(), INTG__Last_Action__c = 'Update', INTG__Batch_Number__c = 1, INTG__Total_Batches__c = 1);
        insert tracking;
    }
}