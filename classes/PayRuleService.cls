public with sharing class PayRuleService {
    public static transient Map<Id, Pay_Rule__c> payRulesByIds = new Map<Id, Pay_Rule__c>(); //mapPayRules
    public static transient Map<String, Pay_Rule_Holiday__c> payRuleHolidayByPayRuleAndHolidayName = new Map<String, Pay_Rule_Holiday__c>(); //mapPayRuleHoliday
    public static transient Map<String, Decimal> payRateByPayRuleAndResType = new Map<String, Decimal>(); //mapPayRateByPayRuleAndResType
    public static transient Map<String, List<Date>> payRuleHolidayDateByPayRuleAndResourceType = new Map<String, List<Date>>(); //mapPayRuleHolidayDate
    public static transient Map<String, Pay_Rule_Line__c> payRuleLineByPayRuleAndWorkAsResType = new Map<String, Pay_Rule_Line__c>(); //mapPayRuleResTypeWithPayRuleLine
    public static transient Map<String, String> eligibleHolidayByPayRuleAndResType = new Map<String, String>(); //mapPayRuleResTypeWithHolidays
    public static transient Set<String> payRuleResTypeWithDoubleTimeHolidayPayCodeSet = new Set<String>();
    public static transient Set<String> payRuleResTypeWithOverTimeHolidayPayCodeSet = new Set<String>();
    public static transient Map<Id, Map<String, List<Pay_Rule_Line_Detail__c>>> payRuleLineDetailLinesByDayByPayRuleLineIds = new Map<Id, Map<String, List<Pay_Rule_Line_Detail__c>>>();

    public static transient Map<String, String> payRuleHolidayNameBypayRuleIdAndResTypeAndDate = new Map<String, String>();
    public static transient Map<String, String> companyHolidayPayCodesByHolidayName = new Map<String, String>();
    public static transient Map<Date, String> companyHolidayNameByDate = new Map<Date, String>();
    //public static transient Map<Date, Holiday__c> holidaysByDates = new Map<Date, Holiday__c>();

    public static void initStaticVariables(Set<Id> payRuleIds, Date scheduleDate){
        Date firstDateOftheYear = Date.newInstance(scheduleDate.year(), 1, 1);
        Date lastDateOftheYear = Date.newInstance(scheduleDate.year(), 12, 31);
        setCompanyHolidayMap(firstDateOftheYear.addDays(-2), lastDateOftheYear.addDays(2));
        if(payRuleIds.size() > 0) {
            setPayRuleMap(payRuleIds);
            setPayRuleHolidayMap(payRuleIds);
            setPayRateByPayRuleAndResTypeMap(payRuleIds);
            setPayRuleHolidayDateMap(firstDateOftheYear.addDays(-2), lastDateOftheYear.addDays(2));
        }
    }

    /*
     *  Ticket#21502 - add blocked filter to Pay Rule Lines.
     *  Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
     */
    private static void setPayRuleMap(Set<Id> payRuleIds) {
        payRuleIds.add(CompanySettingUtil.defaultCompanySetup.Company_Pay_Rule__c);
        List<Pay_Rule__c> payRuleLst = [
                SELECT Id, Name, Type__c, Pay_Holiday__c, Pay_Travel_Time__c, Travel_Time_Pay_Rate__c,
                        Work_Before_or_After_Holiday_to_Qualify__c, Work_x_out_y_days_to_qualify__c, Work_Before_and_After_Holiday_to_Qualify__c, Enable_Dispatch_from_Home_Pay__c,
                        Use_Pay_Rule_Line_Detail_for_Hour_Calc__c, (
                        SELECT Id, Resource_Type__c, Daily_OT_After_Num_of_Hours__c, Pay_Rule__c,
                                Saturday_Pay_Code__c, Sunday_Pay_Code__c, Overtime_Rate_Multiple__c, Double_Time_Rate_Multiple__c,
                                Rate__c, Before_Time__c, Time_After_Pay_Code__c, After_Time__c, Time_Before_Pay_Code__c,
                                Holiday_with_Double_Time_Pay__c, Holidays_with_Overtime_Pay__c,Fringe__c, OT_Fringe_Amount__c, DT_Fringe_Amount__c,
                                Peak_Season_Sunday_Pay_Code__c, Peak_Season_Start__c, Peak_Season_End__c
                        FROM Pay_Rule_Lines__r WHERE Blocked__c != TRUE
                )
                FROM Pay_Rule__c
                WHERE Id IN :payRuleIds
        ];

        Set<Id> payRuleLineIds = new Set<Id>();
        for(Pay_Rule__c pr : payRuleLst){
            payRulesByIds.put(pr.Id, pr);
            if(pr.Pay_Rule_Lines__r != null) {
                for (Pay_Rule_Line__c payRuleLine : pr.Pay_Rule_Lines__r) {
                    payRuleLineIds.add(payRuleLine.Id);
                }
            }
        }

        setPayRuleResTypeWithPayRuleLineMap(payRulesByIds);
        //Ticket#23635 setPayRuleResTypeWithHolidayMap(payRulesByIds);
        setPayRuleResTypeHolidayPayCodeSet(payRulesByIds);
        setPayRuleLineDetailMap(payRuleLineIds);
    }

    private static void setPayRuleResTypeWithPayRuleLineMap(Map<Id, Pay_Rule__c> payRulesByIds){
        for(Pay_Rule__c payRule : payRulesByIds.values()){
            for(Pay_Rule_Line__c payRuleLine:payRule.Pay_Rule_Lines__r){
                payRuleLineByPayRuleAndWorkAsResType.put(payRule.Id + ':' + payRuleLine.Resource_Type__c, payRuleLine);
            }
        }
    }

    public static void setCompanyHolidayMap(Date startDate, Date endDate){
        if(String.isBlank(CompanySettingUtil.defaultCompanySetup.Company_Pay_Rule__c)) {
            throw new DataException('Company Pay Rule is not setup!');
        }

        Set<String> companyPaidHolidaySet = new Set<String>();
        for(Pay_Rule_Holiday__c payRuleHoliday:[SELECT Holiday__c, Pay_Code__c FROM Pay_Rule_Holiday__c WHERE Pay_Rule__c = :CompanySettingUtil.defaultCompanySetup.Company_Pay_Rule__c]){
            companyPaidHolidaySet.add(payRuleHoliday.Holiday__c);
            companyHolidayPayCodesByHolidayName.put(payRuleHoliday.Holiday__c, payRuleHoliday.Pay_Code__c);
        }

        List<Holiday__c> theHolidayList = [SELECT Name,Date__c,Rate_Type__c, Holiday_Name_Map__c
        FROM Holiday__c
        WHERE Date__c >= :startDate AND Date__c <= :endDate AND Holiday_Name_Map__c != null];
        if(theHolidayList.size() > 0 && companyPaidHolidaySet.size() > 0){
            for (Holiday__c theHoliday : theHolidayList){
                if(String.isNotBlank(theHoliday.Holiday_Name_Map__c)){
                    List<String> holidayNames = theHoliday.Holiday_Name_Map__c.split(';');
                    for(String holidayName:holidayNames){
                        if(companyPaidHolidaySet.contains(holidayName)){
                            companyHolidayNameByDate.put(theHoliday.Date__c, holidayName);
                            break;
                        }
                    }
                }
            }
        }
    }

    /*Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
    public static void setPayRuleResTypeWithHolidayMap(Map<Id, Pay_Rule__c> payRulesByIds){
        for(Pay_Rule__c payRule : payRulesByIds.values()){
            for(Pay_Rule_Line__c payRuleLine:payRule.Pay_Rule_Lines__r){
                eligibleHolidayByPayRuleAndResType.put(payRule.Id + ':' + payRuleLine.Resource_Type__c, payRuleLine.Eligible_Holidays__c);
            }
        }
    }
     */

    public static void setPayRuleResTypeHolidayPayCodeSet(Map<Id, Pay_Rule__c> payRulesByIds){
        for(Pay_Rule__c payRule : payRulesByIds.values()){
            for(Pay_Rule_Line__c payRuleLine:payRule.Pay_Rule_Lines__r){
                String holidayNames = null; //Ticket#23635
                if(String.isNotBlank(payRuleLine.Holidays_with_Overtime_Pay__c)){
                    for(String holiday:payRuleLine.Holidays_with_Overtime_Pay__c.split(';')){
                        payRuleResTypeWithOverTimeHolidayPayCodeSet.add(payRule.Id + ':' + payRuleLine.Resource_Type__c + ':' + holiday);
                    }
                    holidayNames = payRuleLine.Holidays_with_Overtime_Pay__c; //Ticket#23635
                }

                if(String.isNotBlank(payRuleLine.Holiday_with_Double_Time_Pay__c)){
                    for(String holiday:payRuleLine.Holiday_with_Double_Time_Pay__c.split(';')){
                        payRuleResTypeWithDoubleTimeHolidayPayCodeSet.add(payRule.Id + ':' + payRuleLine.Resource_Type__c + ':' + holiday);
                    }
                    //Ticket#23635 >>
                    if(holidayNames != null){
                        holidayNames = holidayNames + ';' + payRuleLine.Holiday_with_Double_Time_Pay__c;
                    } else {
                        holidayNames = payRuleLine.Holiday_with_Double_Time_Pay__c;
                    }
                    //Ticket#23635 <<
                }
                //Ticket#23635 >>
                if(holidayNames != null){
                    eligibleHolidayByPayRuleAndResType.put(payRule.Id + ':' + payRuleLine.Resource_Type__c, holidayNames);
                }
                //Ticket#23635 <<
            }
        }
    }

    public static void setPayRuleLineDetailMap(Set<Id> payRuleLineIds){
        for(Pay_Rule_Line_Detail__c payRuleLineDetail : [
                SELECT Name, Calculation_Type__c, Day__c, End_Time__c, Hours_After_Number_of_Hours__c, Id,
                        Number_of_Hours__c, Pay_Rule_Line__c, Rate_Code__c, Rate_Code_After_Number_of_Hours__c,
                        Rate_Code_for_Remaining_Hours__c, Pay_Rule_Line__r.Name, Pay_Rule_Line__r.Pay_Rule__r.Name
                FROM Pay_Rule_Line_Detail__c WHERE Pay_Rule_Line__c IN :payRuleLineIds]){
            Map<String, List<Pay_Rule_Line_Detail__c>> payRuleLineDetailLinesByDays = new Map<String, List<Pay_Rule_Line_Detail__c>>();
            List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines = new List<Pay_Rule_Line_Detail__c>();
            if(payRuleLineDetailLinesByDayByPayRuleLineIds.containsKey(payRuleLineDetail.Pay_Rule_Line__c)){
                payRuleLineDetailLinesByDays = payRuleLineDetailLinesByDayByPayRuleLineIds.get(payRuleLineDetail.Pay_Rule_Line__c);
            }
            if(payRuleLineDetailLinesByDays.containsKey(payRuleLineDetail.Day__c)){
                payRuleLineDetailLines = payRuleLineDetailLinesByDays.get(payRuleLineDetail.Day__c);
            }
            payRuleLineDetailLines.add(payRuleLineDetail);
            payRuleLineDetailLinesByDays.put(payRuleLineDetail.Day__c, payRuleLineDetailLines);
            payRuleLineDetailLinesByDayByPayRuleLineIds.put(payRuleLineDetail.Pay_Rule_Line__c, payRuleLineDetailLinesByDays);
        }
    }

    public static void setPayRuleHolidayMap(Set<Id> payRuleIdSet){
        List<Pay_Rule_Holiday__c> payRuleHolidayLst = [SELECT Id, Date__c, Pay_Rule__c, Pay_Code__c, Name, Holiday__c
        FROM Pay_Rule_Holiday__c WHERE Pay_Rule__c IN :payRuleIdSet];

        for(Pay_Rule_Holiday__c payRuleHoliday: payRuleHolidayLst){
            payRuleHolidayByPayRuleAndHolidayName.put(payRuleHoliday.Pay_Rule__c + ':' + payRuleHoliday.Holiday__c, payRuleHoliday);
        }
    }

    /*
     *  Ticket#21502 - add blocked filter to Pay Rule Lines.
     */
    public static void setPayRateByPayRuleAndResTypeMap(Set<Id> payRuleIdSet){
        List<Pay_Rule_Line__c> payRuleLineLst = [SELECT Id, Resource_Type__c, Rate__c, Pay_Rule__c
        FROM Pay_Rule_Line__c WHERE Pay_Rule__c IN :payRuleIdSet AND Blocked__c != TRUE];

        for(Pay_Rule_Line__c prl : payRuleLineLst){
            payRateByPayRuleAndResType.put(prl.Pay_Rule__c + ':' + prl.Resource_Type__c, prl.Rate__c);
        }
    }

    /*
        Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
     */
    public static void setPayRuleHolidayDateMap(Date startDate, Date endDate){
        //payRuleResTypeKeySet key format: payRuleId:ResourceTypeId
        List<Holiday__c> holidays = [SELECT Id, Name, Date__c, Holiday_Name_Map__c FROM Holiday__c
        WHERE Holiday_Name_Map__c != null AND Date__c >= :startDate AND Date__c <= :endDate];

        for(Holiday__c holiday:holidays){
            for(String mapKey:payRuleLineByPayRuleAndWorkAsResType.keySet()){
                Pay_Rule_Line__c payRuleLine = payRuleLineByPayRuleAndWorkAsResType.get(mapKey);
                List<String> holidayList = new List<String>();
                if(payRuleLine.Holidays_with_Overtime_Pay__c != null) {
                    holidayList.addAll(payRuleLine.Holidays_with_Overtime_Pay__c.split(';'));
                }
                if(payRuleLine.Holiday_with_Double_Time_Pay__c != null) {
                    holidayList.addAll(payRuleLine.Holiday_with_Double_Time_Pay__c.split(';'));
                }

                if(String.isNotBlank(holiday.Holiday_Name_Map__c) && holidayList.size() > 0){
                    List<String> holidayNames = holiday.Holiday_Name_Map__c.split(';');
                    for(String holidayName : holidayNames){
                        if(holidayList.contains(holidayName)){
                            //key payRule:resourceType:date, value holiday name;
                            payRuleHolidayNameBypayRuleIdAndResTypeAndDate.put(mapKey + ':' + holiday.Date__c, holidayName);
                            if(payRuleHolidayDateByPayRuleAndResourceType.containsKey(mapKey)){
                                List<Date> holidayDateLst = payRuleHolidayDateByPayRuleAndResourceType.get(mapKey);
                                holidayDateLst.add(holiday.Date__c);
                                payRuleHolidayDateByPayRuleAndResourceType.put(mapKey, holidayDateLst);
                            } else {
                                payRuleHolidayDateByPayRuleAndResourceType.put(mapKey, new List<Date>{holiday.Date__c});
                            }
                            break;
                        }
                    }
                }
            }
        }
    }

    public static String getHolidayPayCode(Id payRuleId, Id workAsResourceTypeId, Date workDate){
        String payCode = '';
        if(isPayRuleHoliday(payRuleId, workAsResourceTypeId, workDate)){
            String lookupKey = payRuleId + ':' + workAsResourceTypeId + ':' + workDate;
            String payRuleHolidayName = payRuleHolidayNameBypayRuleIdAndResTypeAndDate.get(lookupKey);
            if(payRuleResTypeWithOverTimeHolidayPayCodeSet.contains(payRuleId + ':' + workAsResourceTypeId + ':' + payRuleHolidayName)){
                payCode = 'OT';
            } else if (payRuleResTypeWithDoubleTimeHolidayPayCodeSet.contains(payRuleId + ':' + workAsResourceTypeId + ':' + payRuleHolidayName)) {
                payCode = 'DT';
            } else {
                payCode = 'REG';
            }
        } else if(isCompanyHoliday(workDate)){
            String companyHolidayName = companyHolidayNameByDate.get(workDate);
            payCode = companyHolidayPayCodesByHolidayName.get(companyHolidayName);
            if(payCode == 'O/T'){
                payCode = 'OT';
            }
            if(payCode == 'DBT'){
                payCode = 'DT';
            }
        }

        return payCode;
    }

    public static Boolean isCompanyHoliday(Date workDate){
        return companyHolidayNameByDate.containsKey(workDate);
    }

    public static Boolean isPayRuleHoliday(Id payRuleId, Id workAsResourceTypeId, Date workDate){
        String lookupKey = payRuleId + ':' + workAsResourceTypeId;
        if(payRuleHolidayDateByPayRuleAndResourceType.containsKey(lookupKey)){
            if(payRuleHolidayDateByPayRuleAndResourceType.get(lookupKey).contains(workDate)){
                return true;
            }
        }
        return false;
    }

    public static Boolean isHoliday(Id payRuleId, Id workAsResourceTypeId, Date workDate){
        return isCompanyHoliday(workDate) || isPayRuleHoliday(payRuleId, workAsResourceTypeId, workDate);
    }

    public static Map<String, Decimal> calcHoursWithRateCodes(Id payRuleId, Id workAsResourceType, Date scheduledDate, Time startTime, Time endTime, Time lunchStartTime, Time lunchEndTime){
        Map<String, Decimal> hoursByRateCodes = new Map<String, Decimal>();
        hoursByRateCodes.put(EnumUtil.TimeRateCode.REG.name(), 0);
        hoursByRateCodes.put(EnumUtil.TimeRateCode.OT.name(), 0);
        hoursByRateCodes.put(EnumUtil.TimeRateCode.DT.name(), 0);
        String mapKey = payRuleId + ':' + workAsResourceType;
        Pay_Rule_Line__c payRuleLine = null;
        if(payRuleLineByPayRuleAndWorkAsResType.containsKey(mapKey)) {
            payRuleLine = payRuleLineByPayRuleAndWorkAsResType.get(mapKey);
        }

        Pay_Rule__c payRule = payRulesByIds.get(payRuleId);
        Decimal lunchHours = TimeUtils.calculateHours(lunchStartTime, lunchEndTime);
        if(payRuleLine != null) {
            Integer workDay = 1;
            if(endTime != TimeUtils.midNight() && endTime < startTime){
                workDay = 2;
            }
            Integer dayCount = 1;
            while(dayCount <= workDay) {
                Boolean allHoursAllocated = false;
                Date workDate = scheduledDate;
                if(dayCount == 2){
                    workDate = workDate.addDays(1);
                }

                Time tempStartTime = startTime;
                Time tempEndTme = endTime;
                //Day 1 of overnight shift
                if(workDay == 2 && dayCount == 1){
                    tempEndTme = TimeUtils.midNight();
                }

                //Day 2 of overnight shift
                if(workDay == 2 && dayCount == 2){
                    tempStartTime = tempEndTme;
                    tempEndTme = endTime;
                }

                String weekDay = TimeUtils.getWeekdayName(workDate);
                Decimal totalHours = TimeUtils.calculateHours(tempStartTime, tempEndTme);
                //Holiday
                if (isHoliday(payRuleId, workAsResourceType, workDate) == true) {
                    String payCode = getHolidayPayCode(payRuleId, workAsResourceType, workDate);
                    if(lunchHours > 0) {
                        totalHours = totalHours - lunchHours;
                        if(totalHours < 0){
                            lunchHours = lunchHours - totalHours;
                            totalHours = 0;
                        }
                    }
                    //System.debug('******************* payCode=' + payCode + ' : ' + hoursByRateCodes.get(payCode) + ' , ' + totalHours);
                    hoursByRateCodes.put(payCode, hoursByRateCodes.get(payCode) + totalHours);
                    allHoursAllocated = true;
                }

                if(allHoursAllocated == false) {
                    if (payRule.Use_Pay_Rule_Line_Detail_for_Hour_Calc__c != true) {
                        //weekend special pay
                        if (allHoursAllocated == false && TimeUtils.isWeekend(weekDay)) {
                            if (weekDay == 'Sunday') {
                                if (isPeakSeason(scheduledDate, payRuleLine.Peak_Season_Start__c, payRuleLine.Peak_Season_End__c) == true && payRuleLine.Peak_Season_Sunday_Pay_Code__c != null) {
                                    if(lunchHours > 0) {
                                        totalHours = totalHours - lunchHours;
                                        if(totalHours < 0){
                                            lunchHours = lunchHours - totalHours;
                                            totalHours = 0;
                                        }
                                    }
                                    String payCode = getConvertedPayCodeString(payRuleLine.Peak_Season_Sunday_Pay_Code__c);
                                    hoursByRateCodes.put(payCode, hoursByRateCodes.get(payCode + totalHours));
                                    allHoursAllocated = true;
                                } else if (String.isNotBlank(payRuleLine.Sunday_Pay_Code__c)) {
                                    if(lunchHours > 0) {
                                        totalHours = totalHours - lunchHours;
                                        if(totalHours < 0){
                                            lunchHours = lunchHours - totalHours;
                                            totalHours = 0;
                                        }
                                    }
                                    String payCode = getConvertedPayCodeString(payRuleLine.Sunday_Pay_Code__c);
                                    hoursByRateCodes.put(payCode, hoursByRateCodes.get(payCode) + totalHours);
                                    allHoursAllocated = true;
                                }
                            }

                            if (weekDay == 'Saturday' && String.isNotBlank(payRuleLine.Saturday_Pay_Code__c)) {
                                if(lunchHours > 0) {
                                    totalHours = totalHours - lunchHours;
                                    if(totalHours < 0){
                                        lunchHours = lunchHours - totalHours;
                                        totalHours = 0;
                                    }
                                }

                                String payCode = getConvertedPayCodeString(payRuleLine.Saturday_Pay_Code__c);
                                hoursByRateCodes.put(payCode, hoursByRateCodes.get(payCode) + totalHours);
                                allHoursAllocated = true;
                            }
                        }

                        //daily special pay
                        if (allHoursAllocated == false && CompanyMgmt.zeroIfNull(payRuleLine.Daily_OT_After_Num_of_Hours__c) > 0) {
                            if (totalHours > payRuleLine.Daily_OT_After_Num_of_Hours__c) {
                                Decimal regHrs = payRuleLine.Daily_OT_After_Num_of_Hours__c;
                                Decimal otHrs = totalHours - regHrs;

                                if(lunchHours > 0) {
                                    otHrs = otHrs - lunchHours;
                                    if(otHrs < 0){
                                        lunchHours = lunchHours - otHrs;
                                        otHrs = 0;
                                        regHrs = regHrs - lunchHours;
                                    }
                                }

                                hoursByRateCodes.put(EnumUtil.TimeRateCode.REG.name(), hoursByRateCodes.get(EnumUtil.TimeRateCode.REG.name()) + regHrs);
                                hoursByRateCodes.put(EnumUtil.TimeRateCode.OT.name(), hoursByRateCodes.get(EnumUtil.TimeRateCode.OT.name()) + otHrs);
                                allHoursAllocated = true;
                            } else {
                                if(lunchHours > 0) {
                                    totalHours = totalHours - lunchHours;
                                    if(totalHours < 0){
                                        lunchHours = lunchHours - totalHours;
                                        totalHours = 0;
                                    }
                                }
                                hoursByRateCodes.put(EnumUtil.TimeRateCode.OT.name(), hoursByRateCodes.get(EnumUtil.TimeRateCode.OT.name()) + totalHours);
                                allHoursAllocated = true;
                            }
                        }

                        if(allHoursAllocated == false) {
                            Time timeBefore = payRuleLine.Before_Time__c;
                            Time timeAfter = payRuleLine.After_Time__c;
                            //special pay hours, hours before "Before Time"
                            Boolean lunchTimeInRange = false;
                            if(lunchStartTime >= tempStartTime){
                                lunchTimeInRange = true;
                            } else if (lunchEndTime <= tempEndTme || tempEndTme == TimeUtils.midNight()){
                                lunchTimeInRange = true;
                            }

                            if (tempStartTime != null && timeBefore != null && tempStartTime < timeBefore) {
                                String payCode = getConvertedPayCodeString(payRuleLine.Time_Before_Pay_Code__c);
                                if (tempEndTme < timeBefore) {
                                    Decimal hours = TimeUtils.calculateHours(tempStartTime, tempEndTme);
                                    if(lunchTimeInRange == true && lunchHours > 0){
                                        hours = hours - lunchHours;
                                        if(hours < 0){
                                            lunchHours = lunchHours - hours;
                                            hours = 0;
                                        }
                                    }

                                    hoursByRateCodes.put(payCode, hoursByRateCodes.get(payCode) + hours);
                                    allHoursAllocated = true;
                                } else {
                                    Decimal beforeHours = TimeUtils.calculateHours(tempStartTime, timeBefore);
                                    if(lunchTimeInRange == true && lunchHours > 0){
                                        beforeHours = beforeHours - lunchHours;
                                        if(beforeHours < 0){
                                            lunchHours = lunchHours - beforeHours;
                                            beforeHours = 0;
                                        }
                                    }
                                    hoursByRateCodes.put(payCode, hoursByRateCodes.get(payCode) + beforeHours);
                                    tempStartTime = timeBefore;
                                }
                            }

                            //special pay hours, hours after "After Time"
                            if(allHoursAllocated == false && tempEndTme != null && timeAfter != null && (tempEndTme > timeAfter || tempEndTme == TimeUtils.midNight())) {
                                String payCode = getConvertedPayCodeString(payRuleLine.Time_After_Pay_Code__c);
                                if(tempStartTime > timeAfter) {
                                    Decimal hours = TimeUtils.calculateHours(tempStartTime, tempEndTme);
                                    if(lunchTimeInRange == true && lunchHours > 0){
                                        hours = hours - lunchHours;
                                        if(hours < 0){
                                            lunchHours = lunchHours - hours;
                                            hours = 0;
                                        }
                                    }
                                    hoursByRateCodes.put(payCode, hoursByRateCodes.get(payCode) + hours);
                                    allHoursAllocated = true;
                                } else {
                                    Decimal afterHours = TimeUtils.calculateHours(timeAfter, tempEndTme);
                                    if(lunchTimeInRange == true && lunchHours > 0){
                                        afterHours = afterHours - lunchHours;
                                        if(afterHours < 0){
                                            lunchHours = lunchHours - afterHours;
                                            afterHours = 0;
                                        }
                                    }
                                    hoursByRateCodes.put(payCode, hoursByRateCodes.get(payCode) + afterHours);
                                    tempEndTme = timeAfter;
                                }
                            }

                            //at this point only time left should be regular hours
                            if(allHoursAllocated == false && tempStartTime != null && tempEndTme != null) {
                                Decimal regHours = TimeUtils.calculateHours(tempStartTime, tempEndTme);
                                if(lunchTimeInRange == true && lunchHours > 0){
                                    regHours = regHours - lunchHours;
                                    if(regHours < 0){
                                        lunchHours = lunchHours - regHours;
                                        regHours = 0;
                                    }
                                }
                                hoursByRateCodes.put(EnumUtil.TimeRateCode.REG.name(), hoursByRateCodes.get(EnumUtil.TimeRateCode.REG.name()) + regHours);
                                allHoursAllocated = true;
                            }
                        }
                    } else {
                        processTimeSheetLineWithPayRuleLineDetail(payRuleLine, weekDay, startTime, endTime, lunchStartTime, lunchEndTime);
                    }
                }
                dayCount++;
            }
        }
        return hoursByRateCodes;
    }

    public static Map<String, Decimal> processTimeSheetLineWithPayRuleLineDetail(Pay_Rule_Line__c payRuleLine, String weekDay, Time startTime, Time endTime, Time lunchStartTime, Time lunchEndTime){
        Map<String, Decimal> hoursByRateCodes = new Map<String, Decimal>();
        if(payRuleLineDetailLinesByDayByPayRuleLineIds.containsKey(payRuleLine.Id)) {
            Map<String, List<Pay_Rule_Line_Detail__c>> payRuleLineDetailLinesByDay = payRuleLineDetailLinesByDayByPayRuleLineIds.get(payRuleLine.Id);
            if(payRuleLineDetailLinesByDay.containsKey(weekDay)){
                List<Pay_Rule_Line_Detail__c> payRuleLineDetails = payRuleLineDetailLinesByDay.get(weekDay);
                hoursByRateCodes = calcHoursWithRateCodes(payRuleLineDetails, startTime, endTime, lunchStartTime, lunchEndTime);
            }
        }
        return hoursByRateCodes;
    }

    public static Map<String, Decimal> calcHoursWithRateCodes(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Time starTime, Time endTime, Time lunchStartTime, Time lunchEndTime){
        //Map<String, Map<Time, Time>> timeIntervalByDays = calcTimeIntervalByDays(workStartDate, starTime, endTime);
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        hoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), 0);

        Map<String, Decimal> tempHoursByRateCode = new Map<String, Decimal>();
        Time tempStartTime = null;
        Time tempEndTime = null;
        Map<Time, Time> timeInterval = new Map<Time, Time>();
        timeInterval.put(starTime, endTime);
        Decimal lunchHours = TimeUtils.calculateHours(lunchStartTime, lunchEndTime);
        for(Time mapKey : timeInterval.keySet()){
            tempStartTime = mapKey;
            tempEndTime = timeInterval.get(mapKey);
            String calcType = payRuleLineDetailLines[0].Calculation_Type__c;
            if(calcType == 'Time_Based'){
                tempHoursByRateCode = calcTimeBasedHours(payRuleLineDetailLines, tempStartTime, tempEndTime);
            } else if (calcType == 'Hour_Based') {
                tempHoursByRateCode = calcHourBasedHours(payRuleLineDetailLines, tempStartTime, tempEndTime);
            } else if (calcType == 'Day_Based'){
                tempHoursByRateCode = calcDayBasedHours(payRuleLineDetailLines, tempStartTime, tempEndTime);
            }

            //Deduct lunch hours for hour_base and day_base
            if(lunchHours > 0){
                Decimal regHours = tempHoursByRateCode.get(EnumUtil.TimeRateCode.REG.name());
                Decimal otHours = tempHoursByRateCode.get(EnumUtil.TimeRateCode.OT.name());
                Decimal dtHours = tempHoursByRateCode.get(EnumUtil.TimeRateCode.DT.name());
                if(dtHours > 0 && lunchHours > 0){
                    dtHours = dtHours - lunchHours;
                    if(dtHours < 0){
                        lunchHours = lunchHours - dtHours;
                        dtHours = 0;
                    }
                    tempHoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), dtHours);
                }

                if(otHours > 0 && lunchHours > 0){
                    otHours = otHours - lunchHours;
                    if(otHours < 0){
                        lunchHours = lunchHours - otHours;
                        otHours = 0;
                    }
                    tempHoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), dtHours);
                }

                if(regHours > 0 && lunchHours > 0){
                    regHours = regHours - lunchHours;
                    if(regHours < 0){
                        lunchHours = lunchHours - regHours;
                        regHours = 0;
                    }
                    tempHoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), regHours);
                }
            }

            for(String rateCode : tempHoursByRateCode.keySet()){
                Decimal calcHrs = tempHoursByRateCode.get(rateCode);
                hoursByRateCode.put(rateCode, hoursByRateCode.get(rateCode) + calcHrs);
            }
        }
        return hoursByRateCode;
    }

    public static Map<String, Decimal> calcTimeBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Time startTime, Time endTime){
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        hoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), 0);
        Time tempStartTime = startTime;
        Time tempEndTime = endTime;
        Decimal totalHours = TimeUtils.calculateHours(tempStartTime, tempEndTime);
        Integer loopCount = 0;
        while(totalHours > 0){
            loopCount += 1;
            //Code:BR999 if this get triggered, there is something wrong with the hours calculation.
            if(loopCount > 20){
                throw (Exception) new DataException('Something wrong with hours calculation! Please contact your system administrator! Code:BR999');
            }

            for(Pay_Rule_Line_Detail__c payRuleLineDetail : payRuleLineDetailLines){
                if(totalHours <= 0){
                    continue;
                }

                Time payRuleDetailLineStartTime = payRuleLineDetail.Start_Time__c;
                Time payRuleDetailLineEndTime = payRuleLineDetail.End_Time__c;

                if(payRuleLineDetail.Rate_Code__c == null){
                    throw (Exception) new DataException('Rate Code must not be blank for pay rule line detail: ' + payRuleLineDetail.Pay_Rule_Line__r.Pay_Rule__r.Name + ' Line ' + payRuleLineDetail.Pay_Rule_Line__r.Name + ' Line Detail ' + payRuleLineDetail.Name);
                }

                String payRuleRateCode = payRuleLineDetail.Rate_Code__c;
                Decimal calcHrs = 0;

                //if start time is greater than billing rule end time
                //and billing rule end time is not mid-night
                //then skip because billing rule line will not applied.
                if(tempStartTime >= payRuleDetailLineEndTime && payRuleDetailLineEndTime != TimeUtils.midNight()){
                    continue;
                }

                if(tempStartTime == payRuleDetailLineStartTime && tempEndTime == payRuleDetailLineEndTime){
                    calcHrs = TimeUtils.calculateHours(tempStartTime, tempEndTime);
                    hoursByRateCode.put(payRuleRateCode, hoursByRateCode.get(payRuleRateCode) + calcHrs);
                    totalHours -= calcHrs;
                    continue;
                }

                if(tempStartTime >= payRuleDetailLineStartTime){
                    if(tempEndTime <= payRuleDetailLineEndTime){
                        if(tempEndTime != TimeUtils.midNight() || payRuleDetailLineEndTime == TimeUtils.midNight()){
                            calcHrs = TimeUtils.calculateHours(tempStartTime, tempEndTime);
                            hoursByRateCode.put(payRuleRateCode, hoursByRateCode.get(payRuleRateCode) + calcHrs);
                            totalHours -= calcHrs;
                            continue;
                        } else if (tempEndTime == TimeUtils.midNight()){
                            calcHrs = TimeUtils.calculateHours(tempStartTime, payRuleDetailLineEndTime);
                            hoursByRateCode.put(payRuleRateCode, hoursByRateCode.get(payRuleRateCode) + calcHrs);
                            totalHours -= calcHrs;
                            if(totalHours > 0){
                                tempStartTime = payRuleDetailLineEndTime;
                            }
                            continue;
                        }
                    } else {
                        Time tempTime = tempEndTime;
                        if(tempTime > payRuleDetailLineEndTime && payRuleDetailLineEndTime != TimeUtils.midNight()){
                            tempTime = payRuleDetailLineEndTime;
                        }
                        calcHrs = TimeUtils.calculateHours(tempStartTime, tempTime);
                        hoursByRateCode.put(payRuleRateCode, hoursByRateCode.get(payRuleRateCode) + calcHrs);
                        totalHours -= calcHrs;
                        if(totalHours > 0){
                            tempStartTime = payRuleDetailLineEndTime;
                        }
                        continue;
                    }
                }

                if((tempStartTime < payRuleDetailLineEndTime && tempEndTime <= payRuleDetailLineEndTime) || payRuleDetailLineEndTime == TimeUtils.midNight()){
                    Time innerEndTime = tempEndTime;
                    if(tempEndTime == TimeUtils.midNight() && payRuleDetailLineEndTime != TimeUtils.midNight()){
                        innerEndTime = payRuleDetailLineEndTime;
                    }
                    calcHrs = TimeUtils.calculateHours(tempStartTime, innerEndTime);
                    hoursByRateCode.put(payRuleRateCode, hoursByRateCode.get(payRuleRateCode) + calcHrs);
                    totalHours -= calcHrs;
                    if(totalHours > 0){
                        tempStartTime = innerEndTime;
                    }
                    continue;
                }
            }
        }
        return hoursByRateCode;
    }

    public static Map<String, Decimal> calcHourBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Time startTime, Time endTime) {
        Decimal totalHours = TimeUtils.calculateHours(startTime, endTime);
        Map<String, Decimal> hoursByRateCode = calcHourBasedHours(payRuleLineDetailLines, totalHours);
        return hoursByRateCode;
    }

    public static Map<String, Decimal> calcHourBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Decimal totalHours) {
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        hoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), 0);

        if(payRuleLineDetailLines.size() > 0){
            Decimal thresholdHrs = CompanyMgmt.zeroIfNull(payRuleLineDetailLines[0].Number_of_Hours__c);
            Decimal secordthresholdHrs = CompanyMgmt.zeroIfNull(payRuleLineDetailLines[0].Hours_After_Number_of_Hours__c);
            String recordLookupString = payRuleLineDetailLines[0].Pay_Rule_Line__r.Pay_Rule__r.Name + ' Line ' + payRuleLineDetailLines[0].Pay_Rule_Line__r.Name + ' Line Detail ' + payRuleLineDetailLines[0].Name;
            if(totalHours > thresholdHrs){
                Decimal remainingHrs = totalHours - thresholdHrs;
                hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code__c, thresholdHrs);
                if(secordthresholdHrs > 0){
                    if(remainingHrs > secordthresholdHrs){
                        if(payRuleLineDetailLines[0].Rate_Code_After_Number_of_Hours__c == null){
                            throw new DataException('Rate Code After Number of Hours must not be blank for billing rule ' + recordLookupString);
                        }
                        hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code_After_Number_of_Hours__c, secordthresholdHrs);
                        if(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c == null){
                            throw new DataException('Rate Code for Remaining Hours must not be blank for billing rule ' + recordLookupString);
                        }
                        hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c, remainingHrs - secordthresholdHrs);
                    } else {
                        if(payRuleLineDetailLines[0].Rate_Code_After_Number_of_Hours__c == null){
                            throw new DataException('Rate Code After Number of Hours must not be blank for billing rule ' + recordLookupString);
                        }
                        hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code_After_Number_of_Hours__c, remainingHrs);
                    }
                } else {
                    if(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c == null){
                        throw new DataException('Rate Code for Remaining Hours must not be blank for billing rule ' + recordLookupString);
                    }
                    hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c, remainingHrs);
                }
            } else {
                if(payRuleLineDetailLines[0].Rate_Code__c == null){
                    throw new DataException('Rate Code must not be blank for billing rule ' + recordLookupString);
                }
                hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code__c, totalHours);
            }
        }
        return hoursByRateCode;
    }

    public static Map<String, Decimal> calcDayBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Time startTime, Time endTime){
        Decimal totalHours = TimeUtils.calculateHours(startTime, endTime);
        Map<String, Decimal> hoursByRateCode = calcDayBasedHours(payRuleLineDetailLines, totalHours);
        return hoursByRateCode;
    }

    public static Map<String, Decimal> calcDayBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Decimal totalHours){
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        if(payRuleLineDetailLines.size() > 0) {
            hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code__c, totalHours);
        }
        return hoursByRateCode;
    }

    public static Boolean isPeakSeason(Date workDate, Date peakSeasonStart, Date peakSeasonEnd){
        if(workDate == null || peakSeasonStart == null || peakSeasonEnd == null){
            return false;
        } else {
            if(workDate >= peakSeasonStart && workDate <= peakSeasonEnd){
                return true;
            }
        }
        return false;
    }

    public static String getConvertedPayCodeString(String oldPayCodeString){
        if(String.isBlank(oldPayCodeString)){
            return '';
        } else {
            if(oldPayCodeString == 'O/T'){
                return EnumUtil.TimeRateCode.OT.name();
            } else if (oldPayCodeString == 'DBT'){
                return EnumUtil.TimeRateCode.DT.name();
            } else {
                return oldPayCodeString;
            }
        }
    }
}