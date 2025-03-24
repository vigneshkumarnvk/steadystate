@IsTest
private class RateSheetTest {
    @IsTest
    static void testRateSheetLineUpdate() {
        NewTestData.createTestData();
        Test.startTest();
        List<Rate_Sheet_Line__c> rateSheetLines = [SELECT Id, Unit_Price__c FROM Rate_Sheet_Line__c];
        for(Rate_Sheet_Line__c rateSheetLine : rateSheetLines){
            rateSheetLine.Unit_Price__c = 200;
        }
        update rateSheetLines;
        Test.stopTest();
    }

    @IsTest
    static void testRateSheetController(){
        NewTestData.createTestData();
        Test.startTest();
        RateSheetController.getSetupData();
        Rate_Sheet__c rateSheet = [SELECT Id FROM Rate_Sheet__c LIMIT 1];
        RateSheetController.updateDefaultResAndResTypePriceByRateSheet(rateSheet.Id);
        Test.stopTest();
    }
}