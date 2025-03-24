public class BillingRule {

    private Billing_Rule__c billingRule;
    private Map<String, Map<String, List<Billing_Rule_Line__c>>> billingRuleLinesByCalcTypeByDayName = new Map<String, Map<String, List<Billing_Rule_Line__c>>>();
    private Map<Date, String> holidayNamesByDates = new Map<Date, String>();
    private Map<String, Date> dateByDayName = new Map<String, Date>();

    public BillingRule(Id id){
        List<Billing_Rule__c> billingRules = BillingRulesSelector.newInstance().selectByIdsWithLines(new Set<Id>{id});
        if(billingRules.size() > 0) this.billingRule = billingRules[0];
        this.setMap_billingRuleLinesByCalcTypeByDayName();
    }

    public BillingRule(Billing_Rule__c record){
        this.billingRule = record;
        this.setMap_billingRuleLinesByCalcTypeByDayName();
    }

    public BillingRule(Billing_Rule__c record, Map<Date, String> holidayByDates){
        this.billingRule = record;
        this.holidayNamesByDates = holidayByDates;
        this.setMap_billingRuleLinesByCalcTypeByDayName();
    }

    private void setMap_billingRuleLinesByCalcTypeByDayName(){
        for(Billing_Rule_Line__c billingRuleLine : this.billingRule.Billing_Rule_Lines__r){
            Map<String, List<Billing_Rule_Line__c>> billingRuleLineByCalcType = new Map<String, List<Billing_Rule_Line__c>>();
            if(billingRuleLinesByCalcTypeByDayName.containsKey(billingRuleLine.Day__c)){
                billingRuleLineByCalcType = billingRuleLinesByCalcTypeByDayName.get(billingRuleLine.Day__c);
            }

            List<Billing_Rule_Line__c> billingRuleLines = new List<Billing_Rule_Line__c>();
            if(billingRuleLineByCalcType.containsKey(billingRuleLine.Calculation_Type__c)){
                billingRuleLines = billingRuleLineByCalcType.get(billingRuleLine.Calculation_Type__c);
            }

            billingRuleLines.add(billingRuleLine);
            billingRuleLineByCalcType.put(billingRuleLine.Calculation_Type__c, billingRuleLines);
            billingRuleLinesByCalcTypeByDayName.put(billingRuleLine.Day__c, billingRuleLineByCalcType);
        }
    }

    public Boolean isOverTimePayHolidays(String holidayName){
        if(this.billingRule.Holidays_Bill_in_OT_Rate__c == null) {
            return false;
        }
        return this.billingRule.Holidays_Bill_in_OT_Rate__c.contains(holidayName);
    }

    public Boolean isDoubleTimePayHolidays(String holidayName){
        if(this.billingRule.Holidays_Bill_in_DT_Rate__c == null) {
            return false;
        }
        return this.billingRule.Holidays_Bill_in_DT_Rate__c.contains(holidayName);
    }

    public String getSaturdayPayCode(){
        return this.billingRule.Saturday_Rate_Code__c;
    }

    public String getSundayPayCode(){
        return this.billingRule.Sunday_Rate_Code__c;
    }

    public Map<String, Decimal> calcHoursWithRateCodes(Date workStartDate, Time starTime, Time endTime){
        Map<String, Map<Time, Time>> timeIntervalByDays = calcTimeIntervalByDays(workStartDate, starTime, endTime);
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        hoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), 0);

        for(String dayName : timeIntervalByDays.keySet()){
            Date workedDate = dateByDayName.get(dayName);
            Boolean isOTHoliday = false;
            Boolean isDTHoliday = false;
            if(holidayNamesByDates.containsKey(workedDate)){
                List<String> holidayNames = holidayNamesByDates.get(workedDate).split(';');
                for(String holidayName:holidayNames){
                    if(isOverTimePayHolidays(holidayName) == true){
                        isOTHoliday = true;
                        break;
                    }
                    if(isDoubleTimePayHolidays(holidayName) == true){
                        isDTHoliday = true;
                        break;
                    }
                }
            }

            Map<String, Decimal> tempHoursByRateCode = new Map<String, Decimal>();
            Time tempStartTime = null;
            Time tempEndTime = null;
            Map<Time, Time> timeInterval = timeIntervalByDays.get(dayName);
            for(Time mapKey : timeInterval.keySet()){
                tempStartTime = mapKey;
                tempEndTime = timeInterval.get(mapKey);
                String calcType = getCalcType(dayName);
                if(isOTHoliday == true || isDTHoliday){
                    tempHoursByRateCode = calcHolidayHours(tempStartTime, tempEndTime, isOTHoliday, isDTHoliday);
                } else if(calcType == 'Time_Based'){
                    tempHoursByRateCode = calcTimeBasedHours(dayName, tempStartTime, tempEndTime);
                } else if (calcType == 'Hour_Based') {
                    tempHoursByRateCode = calcHourBasedHours(dayName, tempStartTime, tempEndTime);
                } else if (calcType == 'Day_Based'){
                    tempHoursByRateCode = calcDayBasedHours(dayName, tempStartTime, tempEndTime);
                }
                for(String rateCode : tempHoursByRateCode.keySet()){
                    Decimal calcHrs = tempHoursByRateCode.get(rateCode);
                    hoursByRateCode.put(rateCode, hoursByRateCode.get(rateCode) + calcHrs);
                }
            }
        }
        return hoursByRateCode;
    }

    public Map<String, Decimal> getHoursWithRateCodes(Date workStartDate, Time starTime, Time endTime, Time lunchStartTime, Time lunchEndTime, Boolean includeLunch) {

        Map<String, Decimal> hoursByRateCodes = new Map<String, Decimal>();
        hoursByRateCodes = calcHoursWithRateCodes(workStartDate, starTime, endTime);

        if(includeLunch != true) {
            if (lunchStartTime != null && lunchEndTime != null) {
                String dayName = TimeUtils.getDatetimeInUserTZ(Datetime.newInstance(workStartDate.year(), workStartDate.month(), workStartDate.day())).format('EEEE');
                String calcType = getCalcType(dayName);
                if(calcType == 'Time_Based'){
                    Map<String, Decimal> lunchHoursByRateCodes = new Map<String, Decimal>();
                    Map<Date, Map<Time, Time>> lunchTimesByDates = calcLunchTimeSegmentByDate(workStartDate, starTime, endTime, lunchStartTime, lunchEndTime);
                    for(Date calcDate:lunchTimesByDates.keySet()){
                        Map<Time, Time> lunchTimeInterval = lunchTimesByDates.get(calcDate);
                        for(Time tempStartTime: lunchTimeInterval.keySet()){
                            Map<String, Decimal> tempLunchHoursByRateCodes = calcHoursWithRateCodes(calcDate, tempStartTime, lunchTimeInterval.get(tempStartTime));
                            for(String rateCode: tempLunchHoursByRateCodes.keySet()){
                                Decimal calcHour = tempLunchHoursByRateCodes.get(rateCode);
                                if(lunchHoursByRateCodes.containsKey(rateCode)) {
                                    calcHour = calcHour + lunchHoursByRateCodes.get(rateCode);
                                }
                                lunchHoursByRateCodes.put(rateCode, calcHour);
                            }
                        }
                    }

                    for(String rateCode : lunchHoursByRateCodes.keySet()) {
                        hoursByRateCodes.put(rateCode, hoursByRateCodes.get(rateCode) - lunchHoursByRateCodes.get(rateCode));
                    }

                    Decimal numberOfHrsShort = 0;
                    Decimal totalHrsSubmited = 0;
                    for(String rateCode : hoursByRateCodes.keySet()){
                        Decimal hours = hoursByRateCodes.get(rateCode);
                        if(hours < 0){
                            numberOfHrsShort = numberOfHrsShort + Math.abs(hours);
                            hoursByRateCodes.put(rateCode, 0);
                        } else {
                            totalHrsSubmited += hours;
                        }
                    }

                    if(numberOfHrsShort > totalHrsSubmited){
                        throw (Exception) new DataException('Lunch hours is more than the Job hours, Please review your line data!');
                    }

                    while(numberOfHrsShort > 0){
                        for(String rateCode : hoursByRateCodes.keySet()) {
                            Decimal hours = hoursByRateCodes.get(rateCode);
                            if(hours > 0){
                                if(hours > numberOfHrsShort) {
                                    hoursByRateCodes.put(rateCode, hours - numberOfHrsShort);
                                    numberOfHrsShort = 0;
                                } else {
                                    numberOfHrsShort -= hours;
                                    hoursByRateCodes.put(rateCode, 0);
                                }
                            }
                        }
                    }
                } else {
                    Decimal lunchHours = TimeUtils.calculateHours(lunchStartTime, lunchEndTime);
                    Decimal dtHours = hoursByRateCodes.get(EnumUtil.TimeRateCode.DT.name());
                    Decimal otHours = hoursByRateCodes.get(EnumUtil.TimeRateCode.OT.name());
                    Decimal regHours = hoursByRateCodes.get(EnumUtil.TimeRateCode.REG.name());
                    if(lunchHours > 0){
                        if(dtHours > 0 && lunchHours > 0){
                            if(dtHours >= lunchHours){
                                dtHours = dtHours - lunchHours;
                                lunchHours = 0;
                            } else {
                                lunchHours = lunchHours - dtHours;
                                dtHours = 0;
                            }
                        }

                        if(otHours > 0 && lunchHours > 0){
                            if(otHours >= lunchHours){
                                otHours = otHours - lunchHours;
                                lunchHours = 0;
                            } else {
                                lunchHours = lunchHours - otHours;
                                otHours = 0;
                            }
                        }

                        if(regHours > 0 && lunchHours > 0){
                            if(regHours >= lunchHours){
                                regHours = regHours - lunchHours;
                                lunchHours = 0;
                            } else {
                                lunchHours = lunchHours - regHours;
                                regHours = 0;
                            }
                        }

                        hoursByRateCodes.put(EnumUtil.TimeRateCode.DT.name(), dtHours);
                        hoursByRateCodes.put(EnumUtil.TimeRateCode.OT.name(), otHours);
                        hoursByRateCodes.put(EnumUtil.TimeRateCode.REG.name(), regHours);
                    }
                }
            }
        }

        Map<String, Map<Time, Time>> timeIntervalByDays = calcTimeIntervalByDays(workStartDate, starTime, endTime);

        for(String dayName : timeIntervalByDays.keySet()){
            hoursByRateCodes = finalizedTimeBasedHours(dayName, hoursByRateCodes);
        }

        return hoursByRateCodes;
    }

    public Map<String, Decimal> finalizedTimeBasedHours(String dayName, Map<String, Decimal> hoursByRateCode){
        String calcType = getCalcType(dayName);
        if(calcType == 'Time_Based'){
            List<Billing_Rule_Line__c> billingRuleLines = getBillingRuleLines(dayName, calcType);
            Decimal afterNumOfHrs = 0;
            String afterNumOfHrsPayCode = null;
            for(Billing_Rule_Line__c billingRuleLine:billingRuleLines){
                if(CompanyMgmt.zeroIfNull(billingRuleLine.Hours_After_Number_of_Hours__c) > 0
                        && billingRuleLine.Rate_Code_After_Number_of_Hours__c != null
                        && calcType == 'Time_Based') {
                    afterNumOfHrs = billingRuleLine.Hours_After_Number_of_Hours__c;
                    afterNumOfHrsPayCode = billingRuleLine.Rate_Code_After_Number_of_Hours__c;
                    break;
                }
            }

            if(afterNumOfHrs > 0 && afterNumOfHrsPayCode != null){
                Decimal regHr = 0;
                Decimal otHrs = 0;
                Decimal dtHrs = 0;
                for(String payCode : hoursByRateCode.keySet()){
                    if(payCode == EnumUtil.TimeRateCode.REG.name()){
                        regHr += hoursByRateCode.get(payCode);
                    } else if (payCode == EnumUtil.TimeRateCode.OT.name()){
                        otHrs += hoursByRateCode.get(payCode);
                    } else if (payCode == EnumUtil.TimeRateCode.DT.name()){
                        dtHrs += hoursByRateCode.get(payCode);
                    }
                }

                if(afterNumOfHrsPayCode == EnumUtil.TimeRateCode.OT.name()){
                    if(regHr > afterNumOfHrs){
                        otHrs = otHrs + (regHr - afterNumOfHrs);
                        regHr = afterNumOfHrs;
                    }
                }

                if(afterNumOfHrsPayCode == EnumUtil.TimeRateCode.DT.name()){
                    Decimal totalRegAndOTHrs = regHr + otHrs;
                    Decimal totalExtraHours = 0;
                    if(totalRegAndOTHrs > afterNumOfHrs){
                        totalExtraHours = totalRegAndOTHrs - afterNumOfHrs;
                        dtHrs += totalExtraHours;
                        if(otHrs > totalExtraHours){
                            otHrs = otHrs - totalExtraHours;
                        } else {
                            otHrs = 0;
                            totalExtraHours = totalExtraHours - otHrs;
                            regHr = regHr - totalExtraHours;
                        }
                    }
                }

                hoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), regHr);
                hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), otHrs);
                hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), dtHrs);
            }
        }
        return hoursByRateCode;
    }

    public Map<String, Map<Time, Time>> calcTimeIntervalByDays(Date workStartDate, Time starTime, Time endTime){
        /*Changes*/
        //Ticket 16798: only allocate times for overnight shift, only if billing rule line is Time Based
        //System.debug('Info: calcTimeIntervalByDays ' + workStartDate + ' start time: ' + starTime + ' end time: ' + endTime);
        dateByDayName = new Map<String, Date>();
        Map<String, Map<Time, Time>> timeIntervalByDays = new Map<String, Map<Time, Time>>();
        String dayName = TimeUtils.getDatetimeInUserTZ(DateTime.newInstance(workStartDate.year(), workStartDate.month(), workStartDate.day())).format('EEEE');
        String calcType = getCalcType(dayName);
        dateByDayName.put(dayName, workStartDate);
        if(calcType == 'Time_Based' || calcType == 'Day_Based'){
            if((starTime == endTime && starTime != TimeUtils.midNight() && endTime != TimeUtils.midNight()) || (endTime < starTime && endTime != TimeUtils.midNight())){
                Map<Time, Time> timeInterval = new Map<Time, Time>();
                timeInterval.put(starTime, TimeUtils.midNight());
                timeIntervalByDays.put(dayName, timeInterval);

                workStartDate = workStartDate.addDays(1);
                dayName = TimeUtils.getDatetimeInUserTZ(DateTime.newInstance(workStartDate.year(), workStartDate.month(), workStartDate.day())).format('EEEE');
                dateByDayName.put(dayName, workStartDate);
                timeInterval = new Map<Time, Time>();
                timeInterval.put(TimeUtils.midNight(), endTime);
                timeIntervalByDays.put(dayName, timeInterval);
            } else {
                Map<Time, Time> timeInterval = new Map<Time, Time>();
                timeInterval.put(starTime, endTime);
                timeIntervalByDays.put(dayName, timeInterval);
            }
        } else {
            Map<Time, Time> timeInterval = new Map<Time, Time>();
            timeInterval.put(starTime, endTime);
            timeIntervalByDays.put(dayName, timeInterval);
        }

        //System.debug('Info: timeIntervalByDays ' + timeIntervalByDays);

        return timeIntervalByDays;
    }

    public Map<Date, Map<Time, Time>> calcLunchTimeSegmentByDate(Date scheduledDate, Time billingStartTime, Time billingEndTime, Time lunchStartTime, Time lunchEndTime){
        Map<Date, Map<Time, Time>> lunchTimesSegmentsByDate = new Map<Date, Map<Time, Time>>();
        if((billingEndTime < billingStartTime && billingEndTime != TimeUtils.midNight()) || (billingStartTime == billingEndTime && billingStartTime != TimeUtils.midNight())){
            if((lunchStartTime < billingStartTime && lunchEndTime < billingStartTime && lunchEndTime <= billingEndTime && lunchEndTime != TimeUtils.midNight()) || lunchStartTime == TimeUtils.midNight()){
                Map<Time, Time> timeRange = new Map<Time, Time>();
                timeRange.put(lunchStartTime, lunchEndTime);
                lunchTimesSegmentsByDate.put(scheduledDate.addDays(1), timeRange);
            } else if ((lunchStartTime >= billingStartTime && lunchEndTime > billingStartTime) || lunchEndTime == TimeUtils.midNight()){
                Map<Time, Time> timeRange = new Map<Time, Time>();
                timeRange.put(lunchStartTime, lunchEndTime);
                lunchTimesSegmentsByDate.put(scheduledDate, timeRange);
            } else if (lunchStartTime >= billingStartTime && lunchEndTime < billingStartTime){
                Map<Time, Time> timeRange = new Map<Time, Time>();
                timeRange.put(lunchStartTime, TimeUtils.midNight());
                lunchTimesSegmentsByDate.put(scheduledDate, timeRange);

                timeRange = new Map<Time, Time>();
                timeRange.put(TimeUtils.midNight(), lunchEndTime);
                lunchTimesSegmentsByDate.put(scheduledDate.addDays(1), timeRange);

            }
        } else {
            Map<Time, Time> timeRange = new Map<Time, Time>();
            timeRange.put(lunchStartTime, lunchEndTime);
            lunchTimesSegmentsByDate.put(scheduledDate, timeRange);
        }

        return lunchTimesSegmentsByDate;
    }

    /**
     *
     *
     * @param dayName
     *
     * @return
     */
    public String getCalcType(String dayName){
        Boolean timeBased = false;
        Boolean hourBased = false;
        Boolean dayBased = false;
        if(billingRuleLinesByCalcTypeByDayName.containsKey(dayName)){
            Map<String, List<Billing_Rule_Line__c>> billingRuleLinesByCalcType = billingRuleLinesByCalcTypeByDayName.get(dayName);
            for(String mapKey : billingRuleLinesByCalcType.keySet()){
                if(mapKey == 'Time_Based') timeBased = true;
                if(mapKey == 'Hour_Based') hourBased = true;
                if(mapKey == 'Day_Based') dayBased = true;
            }
        }

        if (timeBased == true) {
            return 'Time_Based';
        }
        else if (hourBased == true) {
            return 'Hour_Based';
        }
        else if (dayBased == true) {
            return 'Day_Based';
        } else {
            return '';
        }
    }

    /**
     *
     *
     * @param dayName
     * @param calcType
     *
     * @return
     */
    public List<Billing_Rule_Line__c> getBillingRuleLines(String dayName, String calcType){
        List<Billing_Rule_Line__c> billingRuleLines = new List<Billing_Rule_Line__c>();
        if(billingRuleLinesByCalcTypeByDayName.containsKey(dayName)){
            Map<String, List<Billing_Rule_Line__c>> billingRuleLinesByCalcType = billingRuleLinesByCalcTypeByDayName.get(dayName);
            if(billingRuleLinesByCalcType.containsKey(calcType)){
                billingRuleLines = billingRuleLinesByCalcType.get(calcType);
            }
        }
        return billingRuleLines;
    }

    public Map<String, Decimal> calcTimeBasedHours(String dayName, Time startTime, Time endTime){
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        hoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), 0);

        String calcType = getCalcType(dayName);
        Time tempStartTime = startTime;
        Time tempEndTime = endTime;
        List<Billing_Rule_Line__c> billingRuleLines = getBillingRuleLines(dayName, calcType);
        Decimal totalHours = TimeUtils.calculateHours(tempStartTime, tempEndTime);
        Integer loopCount = 0;
        //System.debug('Info: calcTimeBasedHours ' + startTime + ' -- ' + endTime );
        while(totalHours > 0){
            loopCount += 1;
            //System.debug('Info:  loopCount ' + loopCount);
            //Code:BR999 if this get triggered, there is something wrong with the hours calculation.
            if(loopCount > 20){
                throw (Exception) new DataException('Something wrong with hours calculation! Please contact your system administrator! Code:BR999');
            }

            for(Billing_Rule_Line__c billingRuleLine : billingRuleLines){
                if(totalHours <= 0){
                    continue;
                }

                Time billingRuleStartTime = billingRuleLine.Start_Time__c;
                Time billingRuleEndTime = billingRuleLine.End_Time__c;

                //System.debug('Info: billingRuleLine ' + billingRuleLine.Start_Time__c + ' -- ' + billingRuleLine.End_Time__c);

                if(billingRuleLine.Rate_Code__c == null){
                    throw (Exception) new DataException('Rate Code must not be blank for billing rule ' + billingRuleLine.Billing_Rule__r.Name + ' Line ' + billingRuleLine.Name);
                }
                String billingRuleRateCode = billingRuleLine.Rate_Code__c;
                Decimal calcHrs = 0;

                //if start time is greater than billing rule end time
                //and billing rule end time is not mid-night
                //then skip because billing rule line will not applied.
                if(tempStartTime >= billingRuleEndTime && billingRuleEndTime != TimeUtils.midNight()){
                    //System.debug('Info: skipped ' + tempStartTime + ' -- ' + tempEndTime);
                    continue;
                }

                if(tempStartTime == billingRuleStartTime && tempEndTime == billingRuleEndTime){
                    calcHrs = TimeUtils.calculateHours(tempStartTime, tempEndTime);
                    hoursByRateCode.put(billingRuleRateCode, hoursByRateCode.get(billingRuleRateCode) + calcHrs);
                    totalHours -= calcHrs;
                    //System.debug('Info: 1 ' + tempStartTime + ' - ' + tempEndTime + ' -- calcHrs ' +  calcHrs + ' --- total hr left ' + totalHours );
                    continue;
                }

                if(tempStartTime >= billingRuleStartTime){
                    if(tempEndTime <= billingRuleEndTime){
                        if(tempEndTime != TimeUtils.midNight() || billingRuleEndTime == TimeUtils.midNight()){
                            calcHrs = TimeUtils.calculateHours(tempStartTime, tempEndTime);
                            hoursByRateCode.put(billingRuleRateCode, hoursByRateCode.get(billingRuleRateCode) + calcHrs);
                            totalHours -= calcHrs;
                            //System.debug('Info: 2 ' + tempStartTime + ' - ' + tempEndTime + ' -- calcHrs ' +  calcHrs + ' --- total hr left ' + totalHours );
                            continue;
                        } else if (tempEndTime == TimeUtils.midNight()){
                            calcHrs = TimeUtils.calculateHours(tempStartTime, billingRuleEndTime);
                            hoursByRateCode.put(billingRuleRateCode, hoursByRateCode.get(billingRuleRateCode) + calcHrs);
                            totalHours -= calcHrs;
                            //System.debug('Info: 3 ' + tempStartTime + ' - ' + tempEndTime + ' -- calcHrs ' +  calcHrs + ' --- total hr left ' + totalHours );
                            if(totalHours > 0){
                                tempStartTime = billingRuleEndTime;
                                //System.debug('Info: new time range 3 ' + tempStartTime + ' - ' + tempEndTime);
                            }
                            continue;
                        }
                    } else {
                        Time tempTime = tempEndTime;
                        if(tempTime > billingRuleEndTime && billingRuleEndTime != TimeUtils.midNight()){
                            tempTime = billingRuleEndTime;
                        }
                        calcHrs = TimeUtils.calculateHours(tempStartTime, tempTime);
                        hoursByRateCode.put(billingRuleRateCode, hoursByRateCode.get(billingRuleRateCode) + calcHrs);
                        totalHours -= calcHrs;
                        //System.debug('Info: 4 ' + tempStartTime + ' - ' + tempTime + ' -- calcHrs ' +  calcHrs + ' --- total hr left ' + totalHours );
                        if(totalHours > 0){
                            tempStartTime = billingRuleEndTime;
                            //System.debug('Info: new time range 4 ' + tempStartTime + ' - ' + tempEndTime);
                        }
                        continue;
                    }
                }

                if((tempStartTime < billingRuleEndTime && tempEndTime <= billingRuleEndTime) || billingRuleEndTime == TimeUtils.midNight()){
                    Time innerEndTime = tempEndTime;
                    if(tempEndTime == TimeUtils.midNight() && billingRuleEndTime != TimeUtils.midNight()){
                        innerEndTime = billingRuleEndTime;
                    }
                    calcHrs = TimeUtils.calculateHours(tempStartTime, innerEndTime);
                    hoursByRateCode.put(billingRuleRateCode, hoursByRateCode.get(billingRuleRateCode) + calcHrs);
                    totalHours -= calcHrs;
                    //System.debug('Info: 5 ' + tempStartTime + ' - ' + tempEndTime + ' -- calcHrs ' +  calcHrs + ' --- total hr left ' + totalHours );
                    if(totalHours > 0){
                        tempStartTime = innerEndTime;
                        //System.debug('Info: new time range 5 ' + tempStartTime + ' - ' + tempEndTime);
                    }
                    continue;
                }
            }
        }

        //System.debug('Info:  exit loopCount ' + loopCount);
        return hoursByRateCode;
    }

    public Map<String, Decimal> calcHourBasedHours(String dayName, Time startTime, Time endTime) {
        Decimal totalHours = TimeUtils.calculateHours(startTime, endTime);
        Map<String, Decimal> hoursByRateCode = this.calcHourBasedHours(dayName, totalHours);
        return hoursByRateCode;
    }

    public Map<String, Decimal> calcHourBasedHours(String dayName, Decimal totalHours) {
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        hoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), 0);

        String calcType = getCalcType(dayName);
        List<Billing_Rule_Line__c> billingRuleLines = getBillingRuleLines(dayName, calcType);
        if(billingRuleLines.size() > 0){
            Decimal thresholdHrs = CompanyMgmt.zeroIfNull(billingRuleLines[0].Number_of_Hours__c);
            Decimal secordthresholdHrs = CompanyMgmt.zeroIfNull(billingRuleLines[0].Hours_After_Number_of_Hours__c);
            if(totalHours > thresholdHrs){
                Decimal remainingHrs = totalHours - thresholdHrs;
                hoursByRateCode.put(billingRuleLines[0].Rate_Code__c, thresholdHrs);
                if(secordthresholdHrs > 0){
                    if(remainingHrs > secordthresholdHrs){
                        if(billingRuleLines[0].Rate_Code_After_Number_of_Hours__c == null){
                            throw new DataException('Rate Code After Number of Hours must not be blank for billing rule ' + billingRuleLines[0].Billing_Rule__r.Name + ' Line ' + billingRuleLines[0].Name);
                        }
                        hoursByRateCode.put(billingRuleLines[0].Rate_Code_After_Number_of_Hours__c, secordthresholdHrs);
                        if(billingRuleLines[0].Rate_Code_for_Remaining_Hours__c == null){
                            throw new DataException('Rate Code for Remaining Hours must not be blank for billing rule ' + billingRuleLines[0].Billing_Rule__r.Name + ' Line ' + billingRuleLines[0].Name);
                        }
                        hoursByRateCode.put(billingRuleLines[0].Rate_Code_for_Remaining_Hours__c, remainingHrs - secordthresholdHrs);
                    } else {
                        if(billingRuleLines[0].Rate_Code_After_Number_of_Hours__c == null){
                            throw new DataException('Rate Code After Number of Hours must not be blank for billing rule ' + billingRuleLines[0].Billing_Rule__r.Name + ' Line ' + billingRuleLines[0].Name);
                        }
                        hoursByRateCode.put(billingRuleLines[0].Rate_Code_After_Number_of_Hours__c, remainingHrs);
                    }
                } else {
                    if(billingRuleLines[0].Rate_Code_for_Remaining_Hours__c == null){
                        throw new DataException('Rate Code for Remaining Hours must not be blank for billing rule ' + billingRuleLines[0].Billing_Rule__r.Name + ' Line ' + billingRuleLines[0].Name);
                    }
                    hoursByRateCode.put(billingRuleLines[0].Rate_Code_for_Remaining_Hours__c, remainingHrs);
                }
            } else {
                if(billingRuleLines[0].Rate_Code__c == null){
                    throw new DataException('Rate Code must not be blank for billing rule ' + billingRuleLines[0].Billing_Rule__r.Name + ' Line ' + billingRuleLines[0].Name);
                }
                hoursByRateCode.put(billingRuleLines[0].Rate_Code__c, totalHours);
            }
        }
        return hoursByRateCode;
    }

    public Map<String, Decimal> calcDayBasedHours(String dayName, Time startTime, Time endTime){
        Decimal totalHours = TimeUtils.calculateHours(startTime, endTime);
        Map<String, Decimal> hoursByRateCode = this.calcDayBasedHours(dayName, totalHours);
        return hoursByRateCode;
    }

    public Map<String, Decimal> calcDayBasedHours(String dayName, Decimal totalHours){
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();

        String calcType = getCalcType(dayName);
        List<Billing_Rule_Line__c> billingRuleLines = getBillingRuleLines(dayName, calcType);
        if(billingRuleLines.size() > 0) {
            hoursByRateCode.put(billingRuleLines[0].Rate_Code__c, totalHours);
        }
        return hoursByRateCode;
    }

    public Map<String, Decimal> calcHolidayHours(Time startTime, Time endTime, Boolean isOTHoliday, Boolean isDTHoliday){
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        Decimal totalHours = TimeUtils.calculateHours(startTime, endTime);
        if(isOTHoliday){
            hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), totalHours);
        }
        if(isDTHoliday){
            hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), totalHours);
        }
        return hoursByRateCode;
    }
}