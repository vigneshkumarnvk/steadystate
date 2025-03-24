public class TimeUtils {
    public static Time convertStrToTime(String strTime){
        if(!String.isBlank(strTime) && strTime.contains(':')){
            Integer hrs;
            Integer min;
            hrs = Integer.valueOf(strTime.split(':')[0]);
            min = Integer.valueOf(strTime.split(':')[1]);
            return Time.newInstance(hrs, min, 0, 0);
        } else {
            return null;
        }
    }

    public static Datetime getDatetimeInUserTZ(Datetime theDatetime){
        if(theDatetime != null){
            TimeZone tz = UserInfo.getTimeZone();
            theDatetime = theDatetime.addSeconds(tz.getOffset(theDatetime) / 1000 * -1);
        }
        return theDatetime;
    }

    public static Decimal calculateHours(Time startTime, Time endTime) {
        Decimal hours;
        if (startTime != null && endTime != null) {
            if(startTime == endTime){
                hours = 24;
            } else {
                Datetime dtStart = Datetime.newInstanceGmt(Date.today(), startTime);
                Datetime dtEnd = Datetime.newInstanceGmt(Date.today(), endTime);
                Long dt1Long = dtStart.getTime();
                Long dt2Long = dtEnd.getTime();
                Decimal milliseconds = dt2Long - dt1Long;
                Decimal seconds = milliseconds / 1000;
                Decimal minutes = seconds / 60;
                hours = minutes / 60;
            }
        } else {
            hours = 0;
        }
        if (hours < 0) {
            hours += 24;
        }
        return CompanyMgmt.halfUpTo2D(hours);
    }

    public static Time midNight(){
        return Time.newInstance(24,0,0,0);
    }

    public static Boolean isCorssedMidNight(Time startTime, Time endTime){
        if (!(endTime > startTime) && (endTime != TimeUtils.midNight())){
            return true;
        } else {
            return false;
        }
    }

    public static Integer timeEntryNeeded(Date processingDate, Date endDate, Time startTime, Time endTime, Boolean inclNextPayrollPeriodTimeWhenCorssed){
        Integer timeEntryNeed = 1;

        if (isCorssedMidNight(startTime, endTime) == true){
            timeEntryNeed = 2;
            if(inclNextPayrollPeriodTimeWhenCorssed == false){
                if(processingDate == endDate) timeEntryNeed = 1;
            }
        }
        return timeEntryNeed;
    }

    //aura <<
    public static String getWeekdayName(Date dt) {
        String weekdayName = '';
        if (dt != null) {
            weekdayName = TimeUtils.getDatetimeInUserTZ(dt).format('EEEE');
        }
        return weekdayName;
    }
    //aura >>
    
    public static Boolean isWeekend(String dayName){
        return (dayName == 'Sunday' || dayName == 'Saturday');
    }

    public static Date addDaysWithOutWeekend(Date inputDate, Integer numberOfDays, Boolean isPreceeding){
        Date calculatedDate = inputDate;
        Date tempStartDate;
        Date tempEndDate;
        Boolean weekendDayFound = true;

        if(isPreceeding == true){
            numberOfDays = Math.abs(numberOfDays) * -1;
        }

        if(numberOfDays != 0){
            if(isPreceeding == false){
                tempStartDate = inputDate;
                tempEndDate = calculatedDate.addDays(numberOfDays);
            } else {
                tempStartDate = calculatedDate.addDays(numberOfDays);
                tempEndDate = inputDate;
            }

            while(weekendDayFound == true){
                weekendDayFound = false;
                Integer weekendDayCount = 0;

                for(Date d=tempStartDate; d <= tempEndDate; d = d.addDays(1)){
                    String dayName = TimeUtils.getDatetimeInUserTZ(d).format('EEEE');
                    if(isWeekend(dayName) == true){
                        weekendDayFound = true;
                        weekendDayCount += 1;
                    }
                }
                System.debug('tempStartDate --- tempEndDate1 ' + tempStartDate + ' --- ' + tempEndDate  + '  ' + weekendDayCount);

                if(weekendDayFound == true){
                    if(isPreceeding == false){
                        tempStartDate = tempEndDate.addDays(1);
                        tempEndDate = tempStartDate.addDays(weekendDayCount - 1);
                        System.debug('tempStartDate --- tempEndDate2 ' + tempStartDate + ' --- ' + tempEndDate);
                    } else {
                        tempEndDate = tempStartDate.addDays(-1);
                        tempStartDate = tempStartDate.addDays(weekendDayCount * -1);
                    }
                } else {
                    calculatedDate = (isPreceeding == true) ? tempStartDate : tempEndDate;
                }
            }

        }
        return calculatedDate;
    }

    public static String generateLunchHourString(Time lunchStartTime, Time lunchEndTime){
        Decimal minutes = calculateHours(lunchStartTime, lunchEndTime) * 60;
        String lunchHrString = '';
        if (minutes == 0) {
            lunchHrString = 'No';
        } else if (minutes == 30) {
            lunchHrString = '1/2 Hour';
        } else if (minutes == 60) {
            lunchHrString = '1 Hour';
        }
        return lunchHrString;
    }

    public static Decimal convertLunchHourStringToDecimal(String lunchHourString){
        Decimal hours = 0;
        if (lunchHourString == '1/2 Hour') {
            hours = 0.5;
        } else if (lunchHourString == '1 Hour') {
            hours = 1;
        }
        return hours;
    }

    public static Date toStartOfWeek(Date inputDate){
        if(inputDate == null){
            return null;
        }
        inputDate = inputDate.addDays(-1);
        return inputDate.toStartOfWeek().addDays(1);
    }

    //Ticket#23713
    public static String getCurrentDayNameInLocalTime(){
        Datetime localTime = getCurrentLocalTime();
        return getDayNameFromDatetime(localTime);
    }

    //Ticket#23713
    public static Datetime getCurrentLocalTime(){
        Datetime localDatetime = System.now();
        TimeZone tz = UserInfo.getTimeZone();
        Integer offSet = tz.getOffset(System.now());
        return localDatetime.addSeconds(offSet / 1000);
    }

    //Ticket#23713
    /*
     *  Return day name in following format
     *  Mon, Tue, Wed, Thu, Fri, Sat, Sun
     */
    public static String getDayNameFromDatetime(Datetime inputDateTime){
        TimeZone tz = UserInfo.getTimeZone();
        Integer offSet = tz.getOffset(inputDateTime);
        Datetime localDateTime = inputDateTime.addSeconds(offSet / 1000);
        return localDateTime.format('E');
    }

    //Ticket#25007
    public static Boolean isAllTimesIdentical(List<Time> inputTimes){
        if(inputTimes.size() == 0){
            return true;
        }
        Time tempTime = inputTimes[0];
        for(Integer i = 1; i < inputTimes.size(); i++){
            if(tempTime != inputTimes[i]){
                return false;
            }
        }
        return true;
    }

    //Ticket#26574
    public static Date calcStartDateForTMsThatNeedToBeResent(Datetime referenceDateTime){
        String dayName = getDayNameFromDatetime(referenceDateTime);
        Date referenceDate = referenceDateTime.date();
        //if reference datetime is before Monday payroll cut off time
        //  start date will be previous payroll's start date.
        if(dayName == 'Mon'){
            Integer blockoutStartHour = CompanyMgmt.zeroIfNull(CompanySettingUtil.acvSetting.Payroll_Blockout_Start_Hour__c).intValue();
            Integer blockoutStartMinute = CompanyMgmt.zeroIfNull(CompanySettingUtil.acvSetting.Payroll_Blockout_Start_Minute__c).intValue();
            Integer referencingHr = referenceDateTime.hour();
            Integer referencingMin = referenceDateTime.minute();
            if(referencingHr < blockoutStartHour || (referencingHr == blockoutStartHour && referencingMin <= blockoutStartMinute)){
                referenceDate = referenceDate.addDays(-2);
            }
        }
        return TimeUtils.toStartOfWeek(referenceDate);
    }
}