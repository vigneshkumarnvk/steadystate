@IsTest
private class BillingRulesSelectorTest {

    @IsTest
    private static void test(){

        Billing_Rule__c br = new Billing_Rule__c(
                Name = 'test',
                Holidays_Bill_in_DT_Rate__c = 'Christmas Day Company',
                Holidays_Bill_in_OT_Rate__c = 'Thanksgiving',
                Sunday_Rate_Code__c = EnumUtil.TimeRateCode.DT.name(),
                Saturday_Rate_Code__c = EnumUtil.TimeRateCode.OT.name(),
                Time_After__c = Time.newInstance(16,30,0,0),
                Time_After_Rate_Code__c = EnumUtil.TimeRateCode.OT.name(),
                Time_Before__c = Time.newInstance(7,0,0,0),
                Time_Before_Rate_Code__c = EnumUtil.TimeRateCode.DT.name()
        );
        insert br;
        List<Billing_Rule__c> billingRules = BillingRulesSelector.newInstance().selectById(new Set<Id>{br.Id});

        BillingRule billingRule = new BillingRule(billingRules[0].Id);
        System.assertEquals(EnumUtil.TimeRateCode.DT.name(), billingRule.getSundayPayCode());
        System.assertEquals(EnumUtil.TimeRateCode.OT.name(), billingRule.getSaturdayPayCode());
        System.assertEquals(true, billingRule.isDoubleTimePayHolidays('Christmas Day Company'));
        System.assertEquals(false, billingRule.isOverTimePayHolidays('Christmas Day Company'));
        System.assertEquals(true, billingRule.isOverTimePayHolidays('Thanksgiving'));
        BillingRule billingRule2 = new BillingRule(billingRules[0]);
        System.assertEquals(false, billingRule2.isDoubleTimePayHolidays('Thanksgiving'));
    }

    @IsTest
    private static void testHolidaySelector(){
        Date chritmasDate = Date.newInstance(Date.today().year(), 12, 25);
        Holiday__c holiday = new Holiday__c(
                Name = 'Christmas 2019',
                Date__c = chritmasDate,
                Holiday__c = 'Christmas Day Company',
                Holiday_Name_Map__c = 'Christmas Day Company'
        );

        insert holiday;

        List<Holiday__c> holidays = HolidaysSelector.newInstance().selectAll();
        System.assertEquals(1, holidays.size());

        Map<Date, Holiday__c> holidaysByDates = HolidaysSelector.newInstance().getHolidaysByDates();
        System.assertEquals(true, holidaysByDates.containsKey(chritmasDate));
    }

    @IsTest
    private static void testWorkDate(){
        Billing_Rule__c br = new Billing_Rule__c(
                Name = 'test',
                Holidays_Bill_in_DT_Rate__c = 'Christmas Day Company',
                Holidays_Bill_in_OT_Rate__c = 'Thanksgiving',
                Sunday_Rate_Code__c = EnumUtil.TimeRateCode.DT.name(),
                Saturday_Rate_Code__c = EnumUtil.TimeRateCode.OT.name(),
                Time_After__c = Time.newInstance(16,30,0,0),
                Time_After_Rate_Code__c = EnumUtil.TimeRateCode.OT.name(),
                Time_Before__c = Time.newInstance(7,0,0,0),
                Time_Before_Rate_Code__c = EnumUtil.TimeRateCode.DT.name()
        );
        insert br;
        BillingRule billingRule = new BillingRule(br);
        Date chritmasDate = Date.newInstance(Date.today().year(), 12, 25);
        Holiday__c holiday = new Holiday__c(
                Name = 'Christmas 2019',
                Date__c = chritmasDate,
                Holiday__c = 'Christmas Day Company'
        );

        insert holiday;

        WorkDays workDays = new WorkDays(chritmasDate, 1, billingRule, true, true);
        Date endDate = workDays.calcEndDate();
        System.assertEquals(chritmasDate, endDate);
        Map<Date, String> rateCodeByDates = workDays.calcWorkDatesWithRateCode();
    }

}