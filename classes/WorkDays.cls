public class WorkDays {

    //array of seven boolean indicating working days, Monday is index 0
    private static final List<Boolean> isWorkingDay;
    //array of seven boolean indicating Saturday, Monday is index 0
    private static final List<Boolean> isSaturday;
    //array of seven boolean indicating Sunday, Monday is index 0
    private static final List<Boolean> isSunday;
    //count of the number of working days in the array
    private static final Integer workingDaysInWeek;

    // place to store info from holiday__c table records
    private static List<Holiday__c> holidays;

    private Boolean includeWeekend = false;
    private Boolean includeHoliday = false;
    private Date startDate;
    private BillingRule billingRule;
    private Integer duration;
    public List<Date> listOfDates{get; set;}

    private static Map<Date, Holiday__c> holidaysByDates = new Map<Date, Holiday__c>();
    private Date lastDateInTheList;

    // Monday final
    private static final Date MONDAY = Date.newInstance(2000, 1, 3);

    static {
        isWorkingDay = new List<Boolean> {true, true, true, true, true, false, false};
        isSaturday = new List<Boolean> {false, false, false, false, false, true, false};
        isSunday = new List<Boolean> {false, false, false, false, false, false, true};
        workingDaysInWeek = 5;
        holidays = HolidaysSelector.newInstance().selectAll();
        holidaysByDates = HolidaysSelector.newInstance().getHolidaysByDates();
    }

    public WorkDays(Date startDate, Integer duration, BillingRule billingRule, Boolean includeWeekend, Boolean includeHoliday){
        this.startDate = startDate;
        this.duration = duration;
        this.billingRule = billingRule;
        this.includeWeekend = includeWeekend;
        this.includeHoliday = includeHoliday;
        initWorkDates();
    }

    private void initWorkDates(){
        listOfDates = new List<Date>();
        for(Integer i = 0; i<this.duration; i++){
            listOfDates.add(this.startDate.addDays(i));
        }
    }

    private static Integer getDayOfWeek(Date value) {
        return Math.mod(MONDAY.daysBetween(value), 7);
    }

    public Date calcEndDate(){
        Integer offSet = calcDayOffSet();
        while(offSet > 0){
            System.debug('Info: offSet ' + offSet);
            if(listOfDates.size() == 0) break;
            else{
                for(Integer i = 1; i <= offSet; i++){
                    listOfDates.add(lastDateInTheList.addDays(i));
                }
                offSet = calcDayOffSet();
            }
        }
        return listOfDates[listOfDates.size()-1];
    }

    public Integer calcDayOffSet(){
        lastDateInTheList = listOfDates[listOfDates.size() - 1];
        Integer offSet = 0;
        List<Date> workDateList = new List<Date>();
        List<Integer> listIndexNeedtoBeRemoved = new List<Integer>();
        workDateList.addAll(listOfDates);
        Map<Integer, Date> workDatesByListIndex = new Map<Integer, Date>();

        for(Integer i = 0; i < listOfDates.size(); i++){
            workDatesByListIndex.put(i, listOfDates[i]);
        }

        for(Integer i = 0; i < workDateList.size(); i++) {
            Boolean dayCounted = false;
            if(this.includeWeekend != true && isWeekend(workDateList[i]) == true){
                offSet += 1;
                dayCounted = true;
                listIndexNeedtoBeRemoved.add(i);
            }
            if(this.includeHoliday != true && isHoliday(workDateList[i]) == true && dayCounted == false){
                offSet += 1;
                listIndexNeedtoBeRemoved.add(i);
            }
        }

        if(listIndexNeedtoBeRemoved.size() > 0){
            for(Integer i : listIndexNeedtoBeRemoved){
                workDatesByListIndex.remove(i);
            }

            listOfDates = workDatesByListIndex.values();
        }

        if(listOfDates.size() == 0){
            listOfDates.add(lastDateInTheList.addDays(1));
            offSet = duration;
        }

        return offSet;
    }

    public Boolean isHoliday(Date value){
        Boolean isHoliday = false;
        if(holidaysByDates.containsKey(value)){
            Holiday__c holiday = holidaysByDates.get(value);
            if(String.isNotBlank(holiday.Holiday_Name_Map__c)){
                List<String> holidayNames = holiday.Holiday_Name_Map__c.split(';');
                for(String holidayName:holidayNames){
                    if(this.billingRule.isOverTimePayHolidays(holidayName) || this.billingRule.isDoubleTimePayHolidays(holidayName)){
                        isHoliday = true;
                        break;
                    }
                }
            }
        }
        return isHoliday;
    }

    public Boolean isWeekend(Date value){
        return isSunday(value) == true || isSaturday(value) == true ? true : false;
    }

    public Boolean isSunday(Date value){
        return getDayOfWeek(value) == 6 ? true : false;
    }

    public Boolean isSaturday(Date value){
        return getDayOfWeek(value) == 5 ? true : false;
    }

    public Map<Date,String> calcWorkDatesWithRateCode(){
        Map<Date, String> rateCodeByDates = new Map<Date, String>();
        Date endDate = calcEndDate();
        Date tempDate = this.startDate;
        String payCode = '';
        while(tempDate <= endDate){
            Boolean dayCounted = false;
            Boolean isWeekend = isWeekend(tempDate);
            Boolean isHoliday = isHoliday(tempDate);
            Boolean isDTPaidHoliday = false;
            Boolean isOTPaidHoliday = false;

            if(isHoliday == true && this.includeHoliday == true){
                Holiday__c holiday = holidaysByDates.get(tempDate);
                List<String> holidayNames = holiday.Holiday_Name_Map__c.split(';');
                for(String holidayName:holidayNames){
                    if(this.billingRule.isOverTimePayHolidays(holidayName)){
                        isOTPaidHoliday = true;
                        break;
                    }
                    if(this.billingRule.isDoubleTimePayHolidays(holidayName)){
                        isDTPaidHoliday = true;
                        break;
                    }
                }

                if(isOTPaidHoliday) {
                    payCode = EnumUtil.TimeRateCode.OT.name();
                }
                if(isDTPaidHoliday) {
                    payCode = EnumUtil.TimeRateCode.DT.name();
                }
                if(String.isBlank(payCode) == true) {
                    payCode = EnumUtil.TimeRateCode.REG.name();
                }
                dayCounted = true;
            }

            if(isWeekend == true && this.includeWeekend == true && dayCounted == false){
                if(isSaturday(tempDate) == true) payCode = billingRule.getSaturdayPayCode();
                if(isSunday(tempDate) == true) payCode = billingRule.getSundayPayCode();
                dayCounted = true;
            }

            if(isWeekend == false && isHoliday == false && dayCounted == false){
                payCode = EnumUtil.TimeRateCode.REG.name();
                dayCounted = true;
            }

            if(dayCounted == true) rateCodeByDates.put(tempDate, payCode);

            tempDate = tempDate.addDays(1);
        }

        return rateCodeByDates;
    }
}