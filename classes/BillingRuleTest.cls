@IsTest
private class BillingRuleTest {
    @IsTest
    static void testBehavior() {
        Billing_Rule__c br = new Billing_Rule__c(
                Name = 'test',
                Holidays_Bill_in_DT_Rate__c = 'Christmas Day Company',
                Holidays_Bill_in_OT_Rate__c = 'Thanksgiving',
                Sunday_Rate_Code__c = EnumUtil.TimeRateCode.DT.name(),
                Saturday_Rate_Code__c = EnumUtil.TimeRateCode.OT.name()
        );
        insert br;

        List<Billing_Rule_Line__c> billingRuleLines = new List<Billing_Rule_Line__c>();

        Billing_Rule_Line__c billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,30,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.Hours_After_Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Monday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,30,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Tuesday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Wednesday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Start_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(7,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Time_Based';
        billingRuleLine.Day__c = 'Thursday';
        billingRuleLine.Rate_Code__c = 'DT';
        billingRuleLine.Start_Time__c = Time.newInstance(15,0,0,0);
        billingRuleLine.End_Time__c = Time.newInstance(0,0,0,0);
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Hour_Based';
        billingRuleLine.Day__c = 'Friday';
        billingRuleLine.Number_of_Hours__c = 8;
        billingRuleLine.Rate_Code__c = 'REG';
        billingRuleLine.Hours_After_Number_of_Hours__c = 3;
        billingRuleLine.Rate_Code_After_Number_of_Hours__c = 'OT';
        billingRuleLine.Rate_Code_for_Remaining_Hours__c = 'DT';
        billingRuleLines.add(billingRuleLine);

        billingRuleLine = new Billing_Rule_Line__c();
        billingRuleLine.Billing_Rule__c = br.Id;
        billingRuleLine.Calculation_Type__c = 'Day_Based';
        billingRuleLine.Day__c = 'Saturday';
        billingRuleLine.Rate_Code__c = 'OT';
        billingRuleLines.add(billingRuleLine);

        if(billingRuleLines.size() > 0){
            insert billingRuleLines;
        }


        Billing_Rule__c brRecord = BillingRulesSelector.newInstance().selectByIdsWithLines(new Set<Id>{br.Id})[0];

        BillingRule billingRule = new BillingRule(brRecord);
        String dtHoliday = 'Christmas Day Company';
        String otHoliday = 'Thanksgiving';

        System.assertEquals(true, billingRule.isDoubleTimePayHolidays(dtHoliday));
        System.assertEquals(false, billingRule.isOverTimePayHolidays(dtHoliday));
        System.assertEquals(true, billingRule.isOverTimePayHolidays(otHoliday));
        System.assertEquals(false, billingRule.isOverTimePayHolidays(dtHoliday));

        System.assertEquals('OT', billingRule.getSaturdayPayCode());
        System.assertEquals('DT', billingRule.getSundayPayCode());

        Date workDate = Date.newInstance(2019, 10, 14);
        Time startTime = Time.newInstance(7,30,0,0);
        Time endTime = Time.newInstance(16,0,0,0);
        Time lunchStartTime = Time.newInstance(12,0,0,0);
        Time lunchEndTime = Time.newInstance(12,30,0,0);
        billingRule.getHoursWithRateCodes(workDate, startTime, endTime, lunchStartTime, lunchEndTime, true);
        billingRule.getHoursWithRateCodes(workDate, startTime, endTime, lunchStartTime, lunchEndTime, false);

        workDate = Date.newInstance(2019,10,15);
        billingRule.calcHoursWithRateCodes(workDate, startTime, endTime);

        workDate = Date.newInstance(2019, 10, 16);
        startTime = Time.newInstance(6,0,0,0);
        endTime = Time.newInstance(7,0,0,0);
        billingRule.getHoursWithRateCodes(workDate, startTime, endTime, lunchStartTime, lunchEndTime, true);

        workDate = Date.newInstance(2019, 10, 18);
        startTime = Time.newInstance(0,0,0,0);
        endTime = Time.newInstance(0,0,0,0);
        billingRule.calcHoursWithRateCodes(workDate, startTime, endTime);

        workDate = Date.newInstance(2019,10,19);
        startTime = Time.newInstance(7,0,0,0);
        endTime = Time.newInstance(15,0,0,0);
        billingRule.calcHoursWithRateCodes(workDate, startTime, endTime);
    }
}