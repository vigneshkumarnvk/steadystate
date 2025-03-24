@isTest
private class PicklistInputControllerTest {

    private static testMethod void test() {
        PicklistInputController.getFieldLabel('Account', 'Type');
        PicklistInputController.GetPicklistOptions('Country', 'Type', 'TEST');
        PicklistInputController.GetPicklistOptions('State', 'Type', 'TEST');
        PicklistInputController.GetPicklistOptions('TM__c', 'Site_State__c', 'Site_Country__c');
        
    }
}