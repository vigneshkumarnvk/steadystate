@isTest
private class AutoNumberControllerTest {
    private static testMethod void test() {
        Auto_Number__c an = new Auto_Number__c(Name = 'Corporate No. Series', Displaying_Format__c = 'CORP-{00000}', Starting_Number__c = 1);
        insert an;

        AutoNumberController.ValidateFormatString('CORP-{00000}');
        Account corp = new Account(Name = 'Test', Type = 'Corporate');
        insert corp;
    }
}