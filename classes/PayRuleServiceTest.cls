@IsTest
private class PayRuleServiceTest {
    @IsTest
    static void testHolidayFunctions() {
        NewTestData.createTestData();
        Test.startTest();
        Id pwPayRuleId = NewTestData.mapPayRuleWrappersByName.get('Prevailing Wage').PayRule.Id;
        PayRuleService.initStaticVariables(new Set<Id>{pwPayRuleId}, Date.today());
        Id resTypeId = NewTestData.mapResourceTypeWrappersByName.get('Labor').ResourceType.Id;
        Boolean isHoliday = false;
        Date workDate = Date.today();
        isHoliday = PayRuleService.isCompanyHoliday(workDate);
        System.assertEquals(false, isHoliday);
        isHoliday = PayRuleService.isPayRuleHoliday(pwPayRuleId, resTypeId, workDate);
        System.assertEquals(false, isHoliday);
        isHoliday = PayRuleService.isHoliday(pwPayRuleId, resTypeId, workDate);
        System.assertEquals(false, isHoliday);

        workDate = workDate.addDays(1);
        String holidayPayCode = PayRuleService.getHolidayPayCode(pwPayRuleId, resTypeId, workDate);
        workDate = workDate.addDays(-1);
        holidayPayCode = PayRuleService.getHolidayPayCode(pwPayRuleId, resTypeId, workDate);
        Test.stopTest();
    }

    @IsTest
    static void testIsPeakSeason(){
        Test.startTest();
        Date peakSeasonStart = Date.today();
        Date peakSeasonEnd = Date.today().addDays(30);
        Date workDate = Date.today().addDays(15);
        Boolean isPeakSeasonWorkDate = PayRuleService.isPeakSeason(workDate, peakSeasonStart, peakSeasonEnd);
        System.assertEquals(true, isPeakSeasonWorkDate);
        isPeakSeasonWorkDate = PayRuleService.isPeakSeason(workDate.addDays(30), peakSeasonStart, peakSeasonEnd);
        System.assertEquals(false, isPeakSeasonWorkDate);
        workDate = null;
        isPeakSeasonWorkDate = PayRuleService.isPeakSeason(workDate, peakSeasonStart, peakSeasonEnd);
        System.assertEquals(false, isPeakSeasonWorkDate);
        Test.stopTest();
    }

    @IsTest
    static void testCalcHoursWithRateCodes(){
        NewTestData.createTestData();
        Test.startTest();
        Id pwPayRuleId = NewTestData.mapPayRuleWrappersByName.get('Prevailing Wage').PayRule.Id;
        PayRuleService.initStaticVariables(new Set<Id>{pwPayRuleId}, Date.today());
        Id resTypeId = NewTestData.mapResourceTypeWrappersByName.get('Labor').ResourceType.Id;
        Id fieldTechId = NewTestData.mapResourceTypeWrappersByName.get('FT').ResourceType.Id;
        Date workDate = Date.newInstance(2021,8,2); //Monday
        Time startTime = Time.newInstance(1,0,0,0);
        Time endTime = Time.newInstance(23,0,0,0);
        Time lunchStartTime = Time.newInstance(12, 0, 0, 0);
        Time lunchEndTime = Time.newInstance(12, 30, 0, 0);
        Map<String, Decimal> hoursByRateCode = PayRuleService.calcHoursWithRateCodes(pwPayRuleId, resTypeId, workDate, startTime, endTime, lunchStartTime, lunchEndTime);

        //Field Tech, Hours Before and After logic
        hoursByRateCode = PayRuleService.calcHoursWithRateCodes(pwPayRuleId, fieldTechId, workDate, startTime, endTime, lunchStartTime, lunchEndTime);

        workDate = Date.newInstance(2021, 8, 1); //Sunday
        hoursByRateCode = PayRuleService.calcHoursWithRateCodes(pwPayRuleId, resTypeId, workDate, startTime, endTime, lunchStartTime, lunchEndTime);

        Test.stopTest();
    }

    @IsTest
    static void TestProcessTimeSheetLineWithPayRuleLineDetail(){
        NewTestData.createTestData();
        Test.startTest();
        Id pwPayRuleId = NewTestData.mapPayRuleWrappersByName.get('PW Pay Rule with Detail Lines').PayRule.Id;
        PayRuleService.initStaticVariables(new Set<Id>{pwPayRuleId}, Date.today());
        Id resTypeId = NewTestData.mapResourceTypeWrappersByName.get('Labor').ResourceType.Id;
        Date workDate = Date.newInstance(2021,8,2); //Monday
        Time startTime = Time.newInstance(1,0,0,0);
        Time endTime = Time.newInstance(23,0,0,0);
        Time lunchStartTime = Time.newInstance(12, 0, 0, 0);
        Time lunchEndTime = Time.newInstance(12, 30, 0, 0);
        Map<String, Decimal> hoursByRateCode = PayRuleService.calcHoursWithRateCodes(pwPayRuleId, resTypeId, workDate, startTime, endTime, lunchStartTime, lunchEndTime);

        workDate = Date.newInstance(2021, 8, 1); //Sunday
        hoursByRateCode = PayRuleService.calcHoursWithRateCodes(pwPayRuleId, resTypeId, workDate, startTime, endTime, lunchStartTime, lunchEndTime);

        List<Pay_Rule_Line_Detail__c> timeBasedDetailLines = [SELECT Id, Name, Pay_Rule_Line__c, Day__c, Rate_Code__c, Start_Time__c, End_Time__c, Pay_Rule_Line__r.Pay_Rule__r.Name, Pay_Rule_Line__r.Name FROM Pay_Rule_Line_Detail__c WHERE Day__c = 'TuesDay'];
        hoursByRateCode = PayRuleService.calcTimeBasedHours(timeBasedDetailLines, startTime, endTime);
        Test.stopTest();
    }

    @IsTest
    static void testTimeSheetLineWithPayRuleLineDetailRule(){
        NewTestData.createTestData();
        Test.startTest();
        Id pwPayRuleId = NewTestData.mapPayRuleWrappersByName.get('PW Pay Rule with Detail Lines').PayRule.Id;
        Set<Id> payRuleLinesIds = new Set<Id>();
        Pay_Rule_Line__c payRuleLineWithDetail = new Pay_Rule_Line__c();
        for(Pay_Rule_Line__c payRuleLine : NewTestData.mapPayRuleWrappersByName.get('PW Pay Rule with Detail Lines').PayRuleLines){
            payRuleLinesIds.add(payRuleLine.Id);
            payRuleLineWithDetail = payRuleLine;
        }

        TimesheetMgmt tsMgmt = new TimesheetMgmt();
        tsMgmt.setPayRuleLineDetailMap(payRuleLinesIds);

        //Id resTypeId = NewTestData.mapResourceTypeWrappersByName.get('Labor').ResourceType.Id;
        //Date workDate = Date.newInstance(2021,8,2); //Monday
        Time startTime = Time.newInstance(1,0,0,0);
        Time endTime = Time.newInstance(23,0,0,0);
        //Time lunchStartTime = Time.newInstance(12, 0, 0, 0);
        //Time lunchEndTime = Time.newInstance(12, 30, 0, 0);

        List<Timesheet_Line__c> timesheetLines = new List<Timesheet_Line__c>();
        Timesheet_Line__c timesheetLine = new Timesheet_Line__c();
        timesheetLine.Week_Day__c = 'Monday';
        timesheetLine.Start_Time__c = startTime;
        timesheetLine.End_Time__c = endTime;
        tsMgmt.processTimeSheetLineWithPayRuleLineDetail(payRuleLineWithDetail, timesheetLine, timesheetLines);

        timesheetLine.Week_Day__c = 'Tuesday';
        tsMgmt.processTimeSheetLineWithPayRuleLineDetail(payRuleLineWithDetail, timesheetLine, timesheetLines);

        timesheetLine.Week_Day__c = 'Sunday';
        tsMgmt.processTimeSheetLineWithPayRuleLineDetail(payRuleLineWithDetail, timesheetLine, timesheetLines);
        /*
        List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines = [SELECT Id, Name, Calculation_Type__c, Pay_Rule_Line__c, Number_of_Hours__c, Hours_After_Number_of_Hours__c, Rate_Code_for_Remaining_Hours__c, Rate_Code_After_Number_of_Hours__c, Day__c, Rate_Code__c, Start_Time__c, End_Time__c, Pay_Rule_Line__r.Pay_Rule__r.Name, Pay_Rule_Line__r.Name FROM Pay_Rule_Line_Detail__c WHERE Day__c = 'Monday'];
        Map<String, Decimal> hoursByRateCode = tsMgmt.calcHoursWithRateCodes(payRuleLineDetailLines, startTime, endTime);

        payRuleLineDetailLines = [SELECT Id, Name, Calculation_Type__c, Pay_Rule_Line__c, Number_of_Hours__c, Hours_After_Number_of_Hours__c, Rate_Code_for_Remaining_Hours__c, Rate_Code_After_Number_of_Hours__c, Day__c, Rate_Code__c, Start_Time__c, End_Time__c, Pay_Rule_Line__r.Pay_Rule__r.Name, Pay_Rule_Line__r.Name FROM Pay_Rule_Line_Detail__c WHERE Day__c = 'Tuesday'];
        hoursByRateCode = tsMgmt.calcHoursWithRateCodes(payRuleLineDetailLines, startTime, endTime);

        payRuleLineDetailLines = [SELECT Id, Name, Calculation_Type__c, Pay_Rule_Line__c, Day__c, Number_of_Hours__c, Hours_After_Number_of_Hours__c, Rate_Code_for_Remaining_Hours__c, Rate_Code_After_Number_of_Hours__c, Rate_Code__c, Start_Time__c, End_Time__c, Pay_Rule_Line__r.Pay_Rule__r.Name, Pay_Rule_Line__r.Name FROM Pay_Rule_Line_Detail__c WHERE Day__c = 'Sunday'];
        hoursByRateCode = tsMgmt.calcHoursWithRateCodes(payRuleLineDetailLines, startTime, endTime);
         */

        Test.stopTest();
    }

    @IsTest static void testTimeSheetProcessTimeSheetLineWithPayRuleLineDetail(){
        NewTestData.createTestData();
        Test.startTest();
            //empty method
        Test.stopTest();
    }
    //test
}