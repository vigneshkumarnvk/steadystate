public with sharing class BillingService {
    public static Company_Setup__c companySetup;
    public static Map<Id, Billing_Rule__c> mapBillingRulesById;
    public static Map<Id, Unit_of_Measure__c> mapUnitOfMeasuresById;
    public static Map<Date, String> mapHolidayDate;

    public static void initSetupData(List<BillingLine> billingLines) {
        companySetup = CompanyMgmt.getCompanySetup();
        if (companySetup.Default_Billing_Rule__c == null) {
            throw new DataException('Default billing rule must be set up.');
        }

        Date fromDate;
        Date toDate;
        Set<Id> billingRuleIds = new Set<Id>();
        Set<Id> uomIds = new Set<Id>();
        for (BillingLine billingLine : billingLines) {
            if (billingLine.BillingRuleId != null) {
                billingRuleIds.add(billingLine.BillingRuleId);
            }
            if (billingLine.UnitOfMeasureId != null) {
                uomIds.add(billingLine.UnitOfMeasureId);
            }

            if (billingLine.ScheduleDate != null) {
                if (fromDate == null) {
                    fromDate = billingLine.ScheduleDate;
                }

                if (toDate == null) {
                    toDate = billingLine.ScheduleDate;
                }

                if (fromDate > billingLine.ScheduleDate) {
                    fromDate = billingLine.ScheduleDate;
                }

                if (toDate < billingLine.ScheduleDate) {
                    toDate = billingLine.ScheduleDate;
                }
            }
        }

        mapBillingRulesById = new Map<Id, Billing_Rule__c>();
        billingRuleIds.add(companySetup.Default_Billing_Rule__c);
        for (Billing_Rule__c billingRule : BillingRulesSelector.newInstance().selectByIdsWithLines(billingRuleIds)) {
            mapBillingRulesById.put(billingRule.Id, billingRule);
        }

        mapUnitOfMeasuresById = new Map<Id, Unit_of_Measure__c>();
        for (Unit_of_Measure__c uom : UnitOfMeasuresSelector.newInstance().selectById(uomIds)) {
            mapUnitOfMeasuresById.put(uom.Id, uom);
        }

        //populate UnitOfMeasure for line total calculation
        for (BillingLine billingLine : billingLines) {
            if (mapUnitOfMeasuresById.containsKey(billingLine.UnitOfMeasureId)) {
                billingLine.UnitOfMeasure = mapUnitOfMeasuresById.get(billingLine.UnitOfMeasureId);
            }
        }

        mapHolidayDate = getHolidayDateMap(fromDate, toDate);
    }

    public static void calculateBillingLines(List<BillingLine> billingLines) {
        initSetupData(billingLines);
        for (BillingLine billingLine : billingLines) {
            calculateBillingLine(billingLine);
        }
    }

    private static void calculateBillingLine(BillingLine billingLine) {
        //init return values
        billingLine.RegularHours = 0;
        billingLine.OvertimeHours = 0;
        billingLine.DoubleTimeHours = 0;
        billingLine.DayRateCode = '';

        if (billingLine.StartTime != null && billingLine.EndTime != null) {
            if (billingLine.BillingRuleId == null) {
                billingLine.BillingRuleId = companySetup.Default_Billing_Rule__c;
            }

            //if (Test.isRunningTest() == false) {
                if (mapBillingRulesById.containsKey(billingLine.BillingRuleId)) {
                    Billing_Rule__c rule = mapBillingRulesById.get(billingLine.BillingRuleId);

                    String holidayPayCode = getHolidayPayCodeByDateByBillingRule(billingLine.ScheduleDate, rule);
                    //system.debug('*** holidayPayCode: ' + holidayPayCode + ' Hours = ' + billingLine.Hours);

                    if (holidayPayCode != null) {
                        if (holidayPayCode == EnumUtil.TimeRateCode.OT.name()) {
                            billingLine.RegularHours = 0;
                            billingLine.OvertimeHours = billingLine.Hours;
                            if(billingLine.IncludeLunch != true){
                                billingLine.OvertimeHours = billingLine.Hours - TimeUtils.calculateHours(billingLine.LunchStartTime, billingLine.LunchEndTime);
                            }
                            billingLine.DoubleTimeHours = 0;
                        }
                        if (holidayPayCode == EnumUtil.TimeRateCode.DT.name()) {
                            billingLine.RegularHours = 0;
                            billingLine.OvertimeHours = 0;
                            billingLine.DoubleTimeHours = billingLine.Hours;
                            if(billingLine.IncludeLunch != true){
                                billingLine.DoubleTimeHours = billingLine.Hours - TimeUtils.calculateHours(billingLine.LunchStartTime, billingLine.LunchEndTime);
                            }
                        }
                    } else {
                        BillingRule billingRule = new BillingRule(rule);
                        //calculate hours
                        Map<String, Decimal> hoursByRateCodes = billingRule.getHoursWithRateCodes(
                                billingLine.ScheduleDate,
                                billingLine.StartTime,
                                billingLine.EndTime,
                                billingLine.LunchStartTime,
                                billingLine.LunchEndTime,
                                billingLine.IncludeLunch);

                        //.debug('*** mapHoursByRateCodes: ' + hoursByRateCodes.keySet());
                        for (String rateCode : hoursByRateCodes.keySet()) {
                            Decimal hrs = hoursByRateCodes.get(rateCode);
                            //system.debug('*** rateCode: ' + rateCode + ' = ' + hrs);
                            if (rateCode == EnumUtil.TimeRateCode.REG.name()) {
                                billingLine.RegularHours = hrs;
                            }
                            if (rateCode == EnumUtil.TimeRateCode.OT.name()) {
                                billingLine.OvertimeHours = hrs;
                            }
                            if (rateCode == EnumUtil.TimeRateCode.DT.name()) {
                                billingLine.DoubleTimeHours = hrs;
                            }
                        }

                        String dayName = TimeUtils.getWeekdayName(billingLine.ScheduleDate);
                        if (CompanyMgmt.zeroIfNull(billingLine.Hours) > 0 && billingLine.RegularHours == 0 && billingLine.OvertimeHours == 0 && billingLine.DoubleTimeHours == 0) {
                            if (dayName == 'Sunday') {
                                switch on rule.Sunday_Rate_Code__c {
                                    when 'DT' {
                                        billingLine.DoubleTimeHours = billingLine.Hours;
                                    }
                                    when 'OT' {
                                        billingLine.OvertimeHours = billingLine.Hours;
                                    }
                                    when else {
                                        billingLine.RegularHours = billingLine.Hours;
                                    }
                                }
                            } else if (dayName == 'Saturday') {
                                switch on rule.Saturday_Rate_Code__c {
                                    when 'DT' {
                                        billingLine.DoubleTimeHours = billingLine.Hours;
                                    }
                                    when 'OT' {
                                        billingLine.OvertimeHours = billingLine.Hours;
                                    }
                                    when else {
                                        billingLine.RegularHours = billingLine.Hours;
                                    }
                                }
                            }
                        }
                    }
                }
            //}
        }
        //billing rule mapping <<
        else if (billingLine.UnitOfMeasure.Hours_UOM__c == true && billingLine.BillingRule.Quote_Order_Assumption__c != null) {
            if (billingLine.BillingRule.Quote_Order_Assumption__c.contains('PortalBasis') || billingLine.BillingRule.Quote_Order_Assumption__c.contains('OvertimeRate')) {
                if (billingLine.UnitOfMeasure.Hours_UOM__c == true) {
                    if (billingLine.Hours > 8) {
                        billingLine.RegularHours = 8;
                        billingLine.OvertimeHours = billingLine.Hours - billingLine.RegularHours;
                    } else {
                        billingLine.RegularHours = billingLine.Hours;
                    }
                }
                else {
                    billingLine.DayRateCode = 'REG';
                }
            }
            //else if (billingLine.BillingRuleId == null && billingLine.DailyRateAssumption == true) {
            else if (billingLine.BillingRule.Quote_Order_Assumption__c.contains('DailyRate')) {
                if (billingLine.UnitOfMeasure.Hours_UOM__c == true) {
                    if (billingLine.Hours > 10) {
                        billingLine.RegularHours = 10;
                        billingLine.OvertimeHours = billingLine.Hours - billingLine.RegularHours;
                    } else {
                        billingLine.RegularHours = billingLine.Hours;
                    }
                }
                else {
                    billingLine.DayRateCode = 'REG';
                }
            }
        }
        //billing rule mapping >>
        //rate.code.fix <<
        else if (billingLine.UnitOfMeasure.Name == 'DAY') {
            if (billingLine.BillingRuleId == null) {
                billingLine.BillingRuleId = companySetup.Default_Billing_Rule__c;
            }

            Billing_Rule__c rule = mapBillingRulesById.get(billingLine.BillingRuleId);
            String holidayPayCode = getHolidayPayCodeByDateByBillingRule(billingLine.ScheduleDate, rule);

            billingLine.DayRateCode = 'REG';
            if (holidayPayCode != null) {
                billingLine.DayRateCode = holidayPayCode;
            } else {
                BillingRule billingRule = new BillingRule(rule);
                String dayName1 = TimeUtils.getWeekdayName(billingLine.ScheduleDate);
                String calcType = BillingRule.getCalcType(dayName1);
                if (calcType == 'Day_Based') {
                    Map<String, Decimal> hoursByRateCode = BillingRule.calcDayBasedHours(dayName1, 8);
                    for (String rateCode : hoursByRateCode.keySet()) {
                        billingLine.DayRateCode = rateCode;
                        break;
                    }
                }
            }
        }
        //rate.code.fix >>
        else {
            // if start time and end time are not entered, all are regular hours
            billingLine.RegularHours = billingLine.Hours;
            billingLine.OvertimeHours = 0;
            billingLine.DoubleTimeHours = 0;
        }
    }


    //Ticket#20496
    //public static void calculateBillingLinesWeeklyTotalRule(List<BillingLine> billingLines, Map<Id, Map<Id, Decimal>> numberOfHoursBilledByWeekNumberIdByResourceId, Map<Date, Week_Number__c> weekNumbersByWeekStartDate){
    public static void calculateBillingLinesWeeklyTotalRule(List<BillingLine> billingLines, Map<Id, Map<Id, Decimal>> numberOfHoursBilledByWeekNumberIdByResourceId){
        initSetupData(billingLines);
        for(BillingLine billingLine : billingLines){
            Map<Id, Decimal> billedHoursByWeekId = new Map<Id, Decimal>();
            if(numberOfHoursBilledByWeekNumberIdByResourceId.containsKey(billingLine.resourceId)){
                billedHoursByWeekId = numberOfHoursBilledByWeekNumberIdByResourceId.get(billingLine.resourceId);
            } else {
                billedHoursByWeekId.put(billingLine.weekNumberId, 0);
            }
            calculateBillingLineWeeklyTotalRule(billingLine, billedHoursByWeekId);
            System.debug('Info: xxx ' + billingLine.weekNumberId + ' --- ' + billedHoursByWeekId);
            numberOfHoursBilledByWeekNumberIdByResourceId.put(billingLine.resourceId, billedHoursByWeekId);
        }
    }

    //private static void calculateBillingLineWeeklyTotalRule(BillingLine billingLine, Map<Id, Decimal> billedHoursByWeekId, Map<Date, Week_Number__c> weekNumbersByWeekStartDate){
    private static void calculateBillingLineWeeklyTotalRule(BillingLine billingLine, Map<Id, Decimal> billedHoursByWeekId){
        billingLine.RegularHours = 0;
        billingLine.OvertimeHours = 0;
        billingLine.DoubleTimeHours = 0;
        Billing_Rule__c rule = mapBillingRulesById.get(billingLine.BillingRuleId);
        String holidayPayCode = getHolidayPayCodeByDateByBillingRule(billingLine.ScheduleDate, rule);
        Decimal billableHours = billingLine.Hours;
        if(billingLine.IncludeLunch != true){
            billableHours = billableHours - TimeUtils.calculateHours(billingLine.LunchStartTime, billingLine.LunchEndTime);
        }

        //handle holiday
        if (holidayPayCode != null) {
            if (holidayPayCode == EnumUtil.TimeRateCode.OT.name()) {
                billingLine.RegularHours = 0;
                billingLine.OvertimeHours = billableHours;
                billingLine.DoubleTimeHours = 0;
                billableHours = 0;
            }
            if (holidayPayCode == EnumUtil.TimeRateCode.DT.name()) {
                billingLine.RegularHours = 0;
                billingLine.OvertimeHours = 0;
                billingLine.DoubleTimeHours = billableHours;
                billableHours = 0;
            }
        }

        if(billableHours > 0) {
            String dayName = TimeUtils.getWeekdayName(billingLine.ScheduleDate);
            //handle weekend
            if (dayName == 'Sunday') {
                switch on rule.Sunday_Rate_Code__c {
                    when 'DT' {
                        billingLine.DoubleTimeHours = billableHours;
                        billableHours = 0;
                    }
                    when 'OT' {
                        billingLine.OvertimeHours = billableHours;
                        billableHours = 0;
                    }
                }
            } else if (dayName == 'Saturday') {
                switch on rule.Saturday_Rate_Code__c {
                    when 'DT' {
                        billingLine.DoubleTimeHours = billableHours;
                        billableHours = 0;
                    }
                    when 'OT' {
                        billingLine.OvertimeHours = billableHours;
                        billableHours = 0;
                    }
                }
            }

            //handle remaining regular hour rate hours
            if(billableHours > 0) {
                Decimal billedRegHours = 0;
                if(billedHoursByWeekId.containsKey(billingLine.weekNumberId)){
                    billedRegHours = billedHoursByWeekId.get(billingLine.weekNumberId);
                }

                Decimal weeklyHourThreshold = CompanyMgmt.zeroIfNull(rule.Weekly_Hour_Threshold__c);
                if(weeklyHourThreshold == 0){
                    throw new DataException('Weekly Hour Threshold is not setup for billing rule ' + rule.Name);
                }

                String payCodeAfterWeeklyThreshold = rule.Billing_Rate_After_Weekly_Threshold__c;
                if(String.isBlank(payCodeAfterWeeklyThreshold)){
                    throw new DataException('Billing Rate After Weekly Threshold is not setup for billing rule '+ rule.Name);
                }

                Decimal remainingThreshold = weeklyHourThreshold - billedRegHours;
                if(remainingThreshold == 0 || remainingThreshold < 0){
                    switch on payCodeAfterWeeklyThreshold {
                        when 'DT'{
                            billingLine.DoubleTimeHours = billableHours;
                        }
                        when 'OT'{
                            billingLine.OvertimeHours = billableHours;
                        }
                    }
                } else {
                    remainingThreshold = remainingThreshold - billableHours;
                    if(remainingThreshold > 0 || remainingThreshold == 0){
                        billingLine.RegularHours = billableHours;
                    } else {
                        switch on payCodeAfterWeeklyThreshold {
                            when 'DT'{
                                billingLine.DoubleTimeHours = Math.abs(remainingThreshold);
                            }
                            when 'OT'{
                                billingLine.OvertimeHours = Math.abs(remainingThreshold);
                            }
                        }
                        billingLine.RegularHours = billableHours - Math.abs(remainingThreshold);
                    }

                    billedRegHours = billedRegHours + billingLine.RegularHours;
                    billedHoursByWeekId.put(billingLine.weekNumberId, billedRegHours);
                }
            }
        }
    }
    //Ticket#20496

    public static String getHolidayPayCodeByDateByBillingRule(Date workDate, Billing_Rule__c billingRule){
        String paidCode = null;
        if(mapHolidayDate.containsKey(workDate)){
            String holidayNameList = mapHolidayDate.get(workDate);
            if(String.isNotBlank(holidayNameList)){
                List<String> holidayNames = holidayNameList.split(';');
                for(String holidayName:holidayNames){
                    if(billingRule.Holidays_Bill_in_OT_Rate__c != null && billingRule.Holidays_Bill_in_OT_Rate__c.contains(holidayName)){
                        paidCode = EnumUtil.TimeRateCode.OT.name();
                        break;
                    }
                    if(billingRule.Holidays_Bill_in_DT_Rate__c != null && billingRule.Holidays_Bill_in_DT_Rate__c.contains(holidayName)){
                        paidCode = EnumUtil.TimeRateCode.DT.name();
                        break;
                    }
                }
            }
        }
        return paidCode;
    }

    public static Map<Date, String> getHolidayDateMap(Date fromDate, Date toDate){
        Map<Date, String> mapHolidays = new Map<Date, String>();
        for(Holiday__c holiday: [ SELECT Date__c, Holiday_Name_Map__c FROM Holiday__c WHERE Date__c >= :fromDate AND Date__c <= :toDate AND Holiday_Name_Map__c != null]) {
            mapHolidays.put(holiday.Date__c, holiday.Holiday_Name_Map__c);
        }
        return mapHolidays;
    }

    public static List<Date> getScheduledDates(Date startDate, Integer duration, Boolean includeHoliday, Boolean includeWeekend, Id billingRuleId) {
        if (billingRuleId == null) {
            //throw new DataException('Billing rule id must be provided.');
            billingRuleId = companySetup.Default_Billing_Rule__c;
        }

        //job task <<
        if (startDate == null) {
            throw new DataException('Start date must not be null.');
        }
        //job task >>

        if (!mapBillingRulesById.containsKey(billingRuleId)) {
            throw new DataException('Billing rule \'' + billingRuleId + '\' is not found.');
        }
        Billing_Rule__c billingRule = mapBillingRulesById.get(billingRuleId);

        List<Date> scheduledDates = new List<Date>();
        Date dt = startDate;
        Integer dayCount = 0;
        while (dayCount < duration) {
            String holidayPayCode = getHolidayPayCodeByDateByBillingRule(dt, billingRule);
            String weekdayName = TimeUtils.getWeekdayName(dt);
            if (holidayPayCode != null) {
                if (includeHoliday == true) {
                    scheduledDates.add(dt);
                    dayCount++;
                }
            }
            else if (TimeUtils.isWeekend(weekdayName) == true) {
                if (includeWeekend == true) {
                    scheduledDates.add(dt);
                    dayCount++;
                }
            }
            else {
                scheduledDates.add(dt);
                dayCount++;
            }

            dt = dt.addDays(1);
        }
        return scheduledDates;
    }
}