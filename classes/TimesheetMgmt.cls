/*************************************************************************************************
* Name         :  TimesheetMgmt
* Description  :  Apex Class for creating time sheet
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* ShahwazKhan     12-06-2023             Task79176: Salesforce Employee Timesheet Logic – Include “Sent to EQAI” T&Ms
* Andrew Simons   10-28-2024             US130143: Updated timesheets & timesheet line logic to handle pay rules with different pay periods (Mon-Sun or Sat-Sun)
*************************************************************************************************/
public with sharing class TimesheetMgmt {
    public static Map<Id, Sales_Order__c> mapSalesOrder = new Map<Id, Sales_Order__c>();
    public static Map<Id, TM__c> mapTM = new Map<Id, TM__c>();
    //public static Map<Id, TM_Line__c> mapTML = new Map<Id, TM_Line__c>();
    public static Map<Id, TM_Line__c> tmLinesByIds = new Map<Id, TM_Line__c>();
    public transient Map<Id, Resource__c> mapRes = new Map<Id, Resource__c>();
    private transient Map<String, Pay_Rule__c> mapPayRules = new Map<String, Pay_Rule__c>();
    //private transient Map<String, Pay_Rule_Holiday__c> mapPayRuleHoliday = new Map<String, Pay_Rule_Holiday__c>();
    private transient Map<Date, Holiday__c> mapCompanyHoliday = new Map<Date, Holiday__c>();
    private transient Map<String, String> payCodeByCompanyHoliday = new Map<String, String>();
    public transient List<TM_Line__c> TMLineLst = new List<TM_Line__c>();
    public Map<Id, Timesheet__c> mapResTimesheet = new Map<Id, Timesheet__c>();
    public List<Timesheet__c> TimesheetLst = new List<Timesheet__c>();
    public List<Timesheet_Line__c> TimeSheetLinesLst = new List<Timesheet_Line__c>();
    private static Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup(); // 14484
    public transient Service_Center__c theSC = new Service_Center__c();
    public transient List<Resource__c> TheScResources = new List<Resource__c>();
    public transient List<Resource_Off__c> TheResourceOffList = new List<Resource_Off__c>();
    public transient Map<String, Decimal> mapPayRateByPayRuleAndResType = new Map<String, Decimal>();
    public transient Map<Id, List<Date>> mapResNonPTODate = new Map<Id, List<Date>>();
    public transient Map<String, List<Date>> mapPayRuleHolidayDate = new Map<String, List<Date>>();
    public transient Set<String> resHolidayPayDateSet = new Set<String>();
    public transient Map<String, Pay_Rule_Line__c> mapPayRuleResTypeWithPayRuleLine = new Map<String, Pay_Rule_Line__c>();
    public transient Map<String, String> mapPayRuleResTypeWithHolidays = new Map<String, String>();
    public transient Set<String> payRuleResTypeWithDobuleTimeHolidayPayCodeSet = new Set<String>();
    public transient Set<String> payRuleResTypeWithOverTimeHolidayPayCodeSet = new Set<String>();
    public transient Map<Id, String> payRuleWorkDaysNeededMap = new Map<Id, String>();
    static final Decimal WEEKLY_OT_THRESHOLD = 40;
    public transient Set<String> resHolidayTakenSet = new Set<String>();
    public transient Map<Id, List<Field_Activity_Log__c>> fieldActivityLogByTMLineIds = new Map<Id, List<Field_Activity_Log__c>>();
    public transient Map<Id, Field_Activity_Log__c> fieldActivityLogByIds = new Map<Id, Field_Activity_Log__c>();
    public transient Map<Id, Map<String, List<Pay_Rule_Line_Detail__c>>> payRuleLineDetailLinesByDayByPayRuleLineIds = new Map<Id, Map<String, List<Pay_Rule_Line_Detail__c>>>();
    public transient Map<Id, Pay_Rule_Line_Detail__c> payRuleLineDetailsByIds = new Map<Id, Pay_Rule_Line_Detail__c>(); //Ticket#22944
	public transient Map<Id, Pay_Rule_Line__c> payRuleLinesByIds = new Map<Id, Pay_Rule_Line__c>(); //Ticket#22782
    public Map<Id, Date> tmScheduledDateByTMId = new Map<Id, Date>(); //Ticket#25502
    public static List <String> checkSave(Timesheet__c theTS, List<Timesheet_Line__c> theTSLList) {
        List<String> errorList = new List<String>();
        // Bypass checking when allow data override
        if (CompanyMgmt.allowDataOverride()) {
            return errorList;
        }

        //Ticket#24132 >>
        List<Timesheet__c> oldTimesheets = [SELECT Id, Status__c, LastModifiedDate FROM Timesheet__c WHERE Id = :theTS.Id];
        if(oldTimesheets.size() > 0){
            if(oldTimesheets[0].Status__c == 'Payroll Created' || theTS.LastModifiedDate < oldTimesheets[0].LastModifiedDate){
                errorList.add('Timesheet have been modified after you retrieved the data. Please refresh page and try again.');
            }
        }
        //Ticket#24132 <<

        for(Timesheet_Line__c theTSL:theTSLList){
            if((theTSL.Scheduled_Date__c < theTS.Starting_Date__c) || (theTSL.Scheduled_Date__c > theTS.Ending_Date__c)){
                theTSL.Scheduled_Date__c.addError('Date entered is not in the payroll period!');
            }

            if((theTSL.Time_Type__c != 'Flat Pay') && (!theTSL.System_Created_Entry__c)){
                theTSL.Time_Type__c.addError('Only Flat Pay entry are allowed!');
            }
        }
        return errorList;
    }

    public static Timesheet_Line__c updateTSL(Timesheet__c theTS, Timesheet_Line__c theTSL, String sourceField) {
        //#13487 SF-01 >>
        if(sourceField == 'theSalesOrder'){
            if(theTSL.Sales_Order__c == null){
                theTSL.Sales_Order__c = null;
                theTSL.Sales_Order__r = null;
                theTSL.TM__c = null;
                theTSL.TM__r = null;
                theTSL.T_M_Line__c = null;
                theTSL.T_M_Line__r = null;
                theTSL.Scheduled_Date__c = null;
            } else {
                Sales_Order__c theSalesOrder = new Sales_Order__c();
                if (!mapSalesOrder.containsKey(theTSL.Sales_Order__c)) {
                    theSalesOrder = [
                        SELECT Id, Name, Service_Center__c
                        FROM Sales_Order__c
                        WHERE Id = :theTSL.Sales_Order__c
                    ];
                    mapSalesOrder.put(theTSL.Sales_Order__c, theSalesOrder);
                }
                theSalesOrder = mapSalesOrder.get(theTSL.Sales_Order__c);
                theTSL.Sales_Order__r = new Sales_Order__c(Id = theSalesOrder.Id, Name = theSalesOrder.Name);
            }
        }

        if(sourceField == 'theTM'){
            if(theTSL.TM__c == null){
                theTSL.TM__c = null;
                theTSL.TM__r = null;
                theTSL.T_M_Line__c = null;
                theTSL.T_M_Line__r = null;
                theTSL.Scheduled_Date__c = null;
            } else {
                TM__c theTM = new TM__c();
                if(!mapTM.containsKey(theTSL.TM__c)){
                    theTM = [
                            SELECT Id, Name, Scheduled_Date__c
                            FROM TM__c
                            WHERE Id = :theTSL.TM__c
                    ];
                    mapTM.put(theTSL.TM__c, theTM);
                }

                theTM = mapTM.get(theTSL.TM__c);
                theTSL.Scheduled_Date__c = theTM.Scheduled_Date__c;
                theTSL.TM__r = new TM__c(Id=theTM.Id, Name = theTM.Name);
            }
        }

        if(sourceField == 'theTML'){
            if(theTSL.T_M_Line__c == null){
                theTSL.T_M_Line__r = null;
            } else {
                TM_Line__c theTML = new TM_Line__c();
                if(!tmLinesByIds.containsKey(theTSL.T_M_Line__c)){
                    theTML = [SELECT Id, Name
                    FROM TM_Line__c
                    WHERE Id =: theTSL.T_M_Line__c];

                    tmLinesByIds.put(theTSL.T_M_Line__c, theTML);
                }

                theTML = tmLinesByIds.get(theTSL.T_M_Line__c);
                theTSL.T_M_Line__c = theTML.Id;
                theTSL.T_M_Line__r = new TM_Line__c(Id=theTML.Id);
            }
        }
        //#13487 SF-01 <<

        if (sourceField == 'theScheduledDate') {
            if(theTSL.Scheduled_Date__c != null){
                if((theTSL.Scheduled_Date__c < theTS.Starting_Date__c) || (theTSL.Scheduled_Date__c > theTS.Ending_Date__c)){
                    //throw new DataException('Date entered is not in the payroll period!');
                    theTSL.Scheduled_Date__c.addError('Date entered is not in the payroll period!');
                }
                theTSL.Week_Day__c = getDatetimeInUserTZ(theTSL.Scheduled_Date__c).format('EEEE');
            }
        }
        if(sourceField == 'theTimeType'){
            if((theTSL.Time_Type__c != 'Flat Pay') && (!theTSL.System_Created_Entry__c)){
                theTSL.Time_Type__c.addError('Only Flat Pay entry are allowed!');
            }
        }
        if ((sourceField == 'theStartTime') || (sourceField == 'theEndTime')){
            theTSL.Total_Hours__c = TimeUtils.calculateHours(theTSL.Start_Time__c, theTSL.End_Time__c);
        }

        if ((sourceField == 'theLunchStartTime') || (sourceField == 'theLunchEndTime')){
            theTSL.Lunch_Hours__c = TimeUtils.calculateHours(theTSL.Lunch_Start_Time__c, theTSL.Lunch_End_Time__c);
        }

        theTSL.Net_Hours__c = CompanyMgmt.zeroIfNull(theTSL.Total_Hours__c) - CompanyMgmt.zeroIfNull(theTSL.Lunch_Hours__c);

        return theTSL;
    }

    public static Datetime getDatetimeInUserTZ(Datetime theDatetime){
        TimeZone tz = UserInfo.getTimeZone();
        theDatetime = theDatetime.addSeconds(tz.getOffset(theDatetime) / 1000 * -1);
        return theDatetime;
    }

    public static Timesheet__c validateWeekNo(Timesheet__c theTS) {
        if (String.isEmpty(theTS.Week_No__c)) {
            return theTS;
        } else {
            Week_Number__c WeekNo = [SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Id = :theTS.Week_No__c LIMIT 1];
            theTS.Week_No__r = new Week_Number__c(Id = WeekNo.Id, Name = WeekNo.Name);

            if (theTS.Resource__c != null) {
                Resource__c resource = [SELECT Id, Pay_Rule__r.Mon_Sun_Work_Week__c FROM Resource__c WHERE Id = :theTS.Resource__c LIMIT 1];
                theTS.Resource__r = new Resource__c(Id = resource.Id, Pay_Rule__c = resource.Pay_Rule__r.Id);
                theTS.Mon_Sun_Work_Week__c = resource.Pay_Rule__r.Mon_Sun_Work_Week__c;  
            }
            
            theTS.Starting_Date__c = WeekNo.Week_Start_Date__c;
            theTS.Ending_Date__c = WeekNo.Week_End_Date__c;
        }
        return theTS;
    }

    public List<Timesheet_Line__c> deleteTimesheetLine(List<Timesheet_Line__c> theTSList){
        List<Timesheet_Line__c> deleteTimesheetLine = new List<Timesheet_Line__c>();
        List<Timesheet_Line__c> keepTimesheetLines = new List<Timesheet_Line__c>();
        if(theTSList.size() > 0){
            for(Timesheet_Line__c theTL : theTSList){
                if (theTL.System_Created_Entry__c){
                    deleteTimesheetLine.add(theTL);
                } else {
                    Timesheet_Line__c theTL2 = theTL.clone();
                    keepTimesheetLines.add(theTL2);
                    deleteTimesheetLine.add(theTL);
                }
            }
            if(deleteTimesheetLine.size() > 0){
                CompanyMgmt.systemCall = true;
                delete deleteTimesheetLine;
            }
        }

        return keepTimesheetLines;
    }

    public static Timesheet__c nullRelationshipFields(Timesheet__c theTS) {
        theTS.Resource__r = null;
        theTS.Service_Center__r = null;
        theTS.Week_No__r = null;
        return theTS;
    }

    public Map<String, Map<Time, Time>> updateResTimeEntryMap(Map<String, Map<Time, Time>> resTimeEntries, Date dateToCompare,
            Date startDate, Date endDate, Time startTime, Time endTime, Id resId, Map<Id, String> resNameMap, Map<String, Set<String>> tmNamesByResIdAndWorkDate)
    {
        //System.debug('###updateResTimeEntryMap method begin####');
        Time calcStartTime = null;
        Time calcEndTime = null;
        Integer entryCount = 0;

        if (startTime != null && endTime != null) {
            //Time from previous payroll that crossed midnight of the Sunday
            if (dateToCompare < startDate && TimeUtils.isCorssedMidNight(startTime, endTime) == true){
                //Collect current period Monday time from previous period
                dateToCompare = startDate;
                calcStartTime = TimeUtils.midNight();
                calcEndTime = endTime;
            } else if (dateToCompare >= startDate) {
                calcStartTime = startTime;
                calcEndTime = endTime;
            }

            if (calcStartTime != null && calcEndTime != null) {
                Integer timeEntryNeed = TimeUtils.timeEntryNeeded(startDate, endDate, calcStartTime, calcEndTime, true);

                while (entryCount < timeEntryNeed) {
                    entryCount += 1;
                    if (timeEntryNeed == 2) {
                        if (entryCount == 1) {
                            calcEndTime = TimeUtils.midNight();
                        } else if (entryCount == 2) {
                            dateToCompare = dateToCompare.addDays(1);
                            calcStartTime = TimeUtils.midNight();
                            calcEndTime = endTime;
                        }
                    }

                    String mapKey = resId + ':' + dateToCompare;
                    Map<Time, Time> resTimesInterval = resTimeEntries.get(mapKey);
                    if (resTimesInterval == null) {
                        resTimesInterval = new Map<Time, Time>();
                    }

                    if (!resTimesInterval.containsKey(calcStartTime)) {
                        resTimesInterval.put(calcStartTime, calcEndTime);
                        resTimeEntries.put(mapKey, resTimesInterval);
                    } else {
                        String nameToDisplay = '';
                        if(resNameMap.containsKey(resId)){
                            nameToDisplay = resNameMap.get(resId);
                        } else {
                            Resource__c res = [SELECT Id, Name FROM Resource__c WHERE Id = :resId LIMIT 1];
                            nameToDisplay = res.Name;
                        }
                        String msg = 'Overlap time found for Resource ' + nameToDisplay + ' on ' + dateToCompare;
                        if(tmNamesByResIdAndWorkDate.containsKey(mapKey)){
                            msg = msg + '. Please review following T&M/Resource Off entries: ';
                            for(String workedItem : tmNamesByResIdAndWorkDate.get(mapKey)){
                                msg = msg + ' ' + workedItem + ',';
                            }
                        }
                        throw new DataException(msg);
                    }
                }
            }
        }
        //System.debug('###updateResTimeEntryMap method end####');
        return resTimeEntries;
    }

    //Ticket#13852 >>
    public Map<String, Map<Time, Time>> addResTimeEntryFromTML(
            List<TM_Line__c> tmlLst,
            Date startDate,
            Date endDate,
            Map<String, Map<Time, Time>> resTimeEntries,
            Set<Id> processedLineIdSet,
            Map<Id, String> resNameMap,
            Map<String, Set<String>> tmNamesByResIdAndWorkDate
    )
    {
        //System.debug('###Method addResTimeEntryFromTML begin###');
        for(TM_Line__c tmLine:tmlLst) {
            Boolean isAllTimeIdentical = TimeUtils.isAllTimesIdentical(new List<Time>{tmLine.Job_Start_Time__c, tmLine.Job_End_Time__c, tmLine.Site_Start_Time__c, tmLine.Site_End_Time__c});
            if(!processedLineIdSet.contains(tmLine.Id) && isAllTimeIdentical == false){
                if (tmLine.Job_Start_Time__c != null && tmLine.Job_End_Time__c != null) {
                    updateResTimeEntryMap(resTimeEntries,
                            tmLine.TM__r.Scheduled_Date__c, startDate, endDate,
                            tmLine.Job_Start_Time__c, tmLine.Job_End_Time__c,
                            tmLine.Resource__c, resNameMap, tmNamesByResIdAndWorkDate);
                    processedLineIdSet.add(tmLine.Id);
                }
            }
        }
        //System.debug('###Method addResTimeEntryFromTML end###');
        return resTimeEntries;
    }

    public Map<String, Map<Time, Time>> addResTimeEntryFromResOff(
            List<Resource_Off__c> ResOffLst,
            Date startDate,
            Date endDate,
            Map<String, Map<Time, Time>> resTimeEntries,
            Set<Id> processedLineIdSet,
            Map<Id, String> resNameMap,
            Map<String, Set<String>> tmNamesByResIdAndWorkDate
    )
    {
        for(Resource_Off__c resOff:ResOffLst) {
            if(!processedLineIdSet.contains(resOff.Id)){
                if(resoff.Start_Time__c != null && resoff.End_Time__c != null){
                    updateResTimeEntryMap(resTimeEntries,
                            resOff.Date__c, startDate, endDate,
                            resOff.Start_Time__c, resOff.End_Time__c,
                            resOff.Resource__c, resNameMap, tmNamesByResIdAndWorkDate);
                    processedLineIdSet.add(resOff.Id);
                }
            }
        }
        return resTimeEntries;
    }

    public void checkTimeEntryOverlap(Set<Id> resIdSet, Map<String, Map<Time, Time>> resTimeEntries, Date startDate, Date endDate, Set<Id> processedLineIdSet){
        //System.debug('###checkTimeEntryOverlap Method begin###');

        //Prepare resNameMap for user friendly error message
        Map<Id, String> resNameMap = new Map<Id, String>();
        Map<String, Set<String>> tmNamesByResIdAndWorkDate = new Map<String, Set<String>>();
        Map<Id, Resource__c> resourcesByIds = new Map<Id, Resource__c>(ResourcesSelector.newInstance().selectById(resIdSet)); //Ticket#22307
        //for(Resource__c res : ResourcesSelector.newInstance().selectById(resIdSet)){
        for(Resource__c res : resourcesByIds.values()){
            if(res.Category__c == 'Labor'){
                resNameMap.put(res.Id, res.First_Name__c + ' ' + res.Last_Name__c + ' (' +  res.Name + ')');
            } else {
                resNameMap.put(res.Id, res.Description__c + '(' +  res.Name + ')');
            }
        }

        //Get time entry from T&M Lines
        List<TM_Line__c> tmLineLst = getTMLineList(startDate.addDays(-1), endDate.addDays(1), resIdSet);
        for(TM_Line__c tmLine : tmLineLst){
            String lookupKey = tmLine.Resource__c + ':' + tmLine.TM__r.Scheduled_Date__c;
            Set<String> workedItems = new Set<String>();
            if(tmNamesByResIdAndWorkDate.containsKey(lookupKey)){
                workedItems = tmNamesByResIdAndWorkDate.get(lookupKey);
            }
            workedItems.add(tmLine.TM__r.Name);
            tmNamesByResIdAndWorkDate.put(lookupKey, workedItems);
        }
        //System.debug('Info: checkTimeEntryOverlap : ' + startDate + '  .... endDate: ' + endDate);
        addResTimeEntryFromTML(tmLineLst, startDate, endDate, resTimeEntries, processedLineIdSet, resNameMap, tmNamesByResIdAndWorkDate);
        /*
        for(String mapkey: resTimeEntries.keySet()){
            System.debug('Info: timeEntries ' + mapkey + ' ----entries: ' + resTimeEntries.get(mapkey));
        }
         */

        //Get time entry from resource off records
        List<String> offTypeName = new List<String>();
        offTypeName.add('Shop Time');
        offTypeName.add('Paid Time Off');
        offTypeName.add('Jury Duty');
        offTypeName.add('Bereavement');
        offTypeName.add('Unavailable');
        offTypeName.add('Unpaid Time Off');
        offTypeName.add('DOT Reset');
        List<Resource_Off__c> resOffLst = getResOffListByResIdByDateByTypeName(resIdSet, startDate.addDays(-1), endDate.addDays(1), offTypeName);
        for(Resource_Off__c resourceOff : resOffLst){
            String lookupKey = resourceOff.Resource__c + ':' + resourceOff.Date__c;
            Set<String> workedItems = new Set<String>();
            if(tmNamesByResIdAndWorkDate.containsKey(lookupKey)){
                workedItems = tmNamesByResIdAndWorkDate.get(lookupKey);
            }
            workedItems.add(resourceOff.Name);
            tmNamesByResIdAndWorkDate.put(lookupKey, workedItems);
        }
        addResTimeEntryFromResOff(resOffLst, startDate, endDate, resTimeEntries, processedLineIdSet, resNameMap, tmNamesByResIdAndWorkDate);
        /*
        for(String mapkey: resTimeEntries.keySet()){
            System.debug('Info: timeEntries after resoff ' + mapkey + ' ----entries: ' + resTimeEntries.get(mapkey));
        }
         */
        //check time overlap
        if(resTimeEntries.size() > 0){
            for(String mapKey: resTimeEntries.keySet()){
                //Ticket#22307
                String resId = mapKey.split(':')[0];
                Boolean bypassOverlapCheck = false;
                if(resourcesByIds.containsKey(resId) && resourcesByIds.get(resId).Bypass_Time_Overlap_Checking__c == true){
                    bypassOverlapCheck = true;
                }
                if (isOverlap(resTimeEntries.get(mapKey)) == true && bypassOverlapCheck == false) {
                    //System.debug('Info: mapKey ' + mapKey);
                    //System.debug('Info: tmNamesByResIdAndWorkDate ' + tmNamesByResIdAndWorkDate);
                    String msg = 'Overlap time found for resource: ' + resNameMap.get(mapKey.split(':')[0]) + ' on date ' + mapKey.split(':')[1];
                    if(tmNamesByResIdAndWorkDate.containsKey(mapKey)){
                        msg = msg + '. Please review following T&M/Resource Off entries: ';
                        for(String workedItem : tmNamesByResIdAndWorkDate.get(mapKey)){
                            msg = msg + ' ' + workedItem + ',';
                        }
                    }
                    throw new DataException(msg);
                }
            }
        }
        //System.debug('###checkTimeEntryOverlap Method end###');
    }

    /* Ticket# 13409 */
    public static Boolean isOverlap(Map<Time, Time> timeEntries){
        Boolean overlap = false;
        //System.debug('###isOverlap Method Begin with overlap ' + overlap);
        List<Time> startTimeLst = new List<Time>();
        startTimeLst.addAll(timeEntries.keySet());
        startTimeLst.sort();
        if(timeEntries.size() > 1){
            for(Integer i = 1; i < startTimeLst.size(); i++){
                /*
                System.debug('Info: Previous Time Range ' + startTimeLst[i - 1] + ' -- ' + timeEntries.get(startTimeLst[i - 1]));
                System.debug('Info: Current Time Range ' + startTimeLst[i] + ' -- ' + timeEntries.get(startTimeLst[i]));
                System.debug('Info: Previous Entry End Time ' + timeEntries.get(startTimeLst[i - 1]) + ' > Current entry Start Time? ' + startTimeLst[i]);
                 */
                if(timeEntries.get(startTimeLst[i - 1]) == Time.newInstance(24,0,0,0)){
                    if(startTimeLst[i - 1] < startTimeLst[i]){
                        overlap = true;
                    }
                }
                if(timeEntries.get(startTimeLst[i - 1]) > startTimeLst[i]){
                    overlap = true;
                }
            }
        }
        //System.debug('###isOverlap Method End with overlap ' + overlap);
        return overlap;
    }

    /* Ticket# 13409 */
    public void checkTimesheetLineTimeOverlap(List<Timesheet_Line__c> timesheetLines){
        //System.debug('Info: checkTimesheetLineTimeOverlap begin');
        Map<String, Map<Time,Time>> resTimeEntries = new Map<String, Map<Time, Time>>();
        for(Timesheet_Line__c tl:timesheetLines){
            if(tl.Start_Time__c != null && tl.End_Time__c != null && tl.Time_Type__c != 'Travel Time' && tl.Time_Type_Code__c != 'HOL' && tl.Time_Type__c != 'Holiday'
                    && tl.Start_Time__c != tl.End_Time__c && tl.Net_Hours__c > 0){
                String mapKey = tl.Resource__c + ':' + tl.Scheduled_Date__c;
                if(resTimeEntries.containsKey(mapKey)){
                    Map<Time, Time> resTimesInterval = resTimeEntries.get(mapKey);
                    if(!resTimesInterval.containsKey(tl.Start_Time__c)){
                        resTimesInterval.put(tl.Start_Time__c, tl.End_Time__c);
                        resTimeEntries.put(mapKey, resTimesInterval);
                    } else{
                        String msg = 'Overlap time found for Resource ' + tl.Resource__c + ' on ' + tl.Scheduled_Date__c;
                        msg += 'Time entry 1 ' + tl.Start_Time__c + ' ----- ' + tl.End_Time__c + ' ---- ' + tl.TM__c;
                        msg += 'Time entry 2 ' + tl.Start_Time__c + ' ----- ' + resTimesInterval.get(tl.Start_Time__c) + ' ---- ' + tl.TM__c;
                        throw new DataException(msg);
                    }
                } else {
                    Map<Time, Time> resTimesInterval = new Map<Time, Time>();
                    resTimesInterval.put(tl.Start_Time__c, tl.End_Time__c);
                    resTimeEntries.put(mapKey, resTimesInterval);
                }
            }
        }

        for(String mapKey: resTimeEntries.keySet()){
            Map<Time, Time> resTimes = resTimeEntries.get(mapKey);
            if(isOverlap(resTimes) == true){
                String msg = 'Overlap time found for Resource ' + mapKey;
                throw new DataException(msg);
            }
        }

        //System.debug('Info: checkTimesheetLineTimeOverlap end');
    }

    /*  Ticket# 23136
    *       - add Sales Order - Bill-to Customer, and Bill-to Customer - Customer Type
    *   Ticket#24285
    *       - add Total Job Hours field.
    *   Ticket#24867
    *       - add Sunday Mobile Review T&M to the timesheet
    */

    public List<TM_Line__c> getTMLineList(Date startDate, Date endDate, Set<Id> resIdsSet){
        List<String> lstStatus = new List<String>();
        lstStatus.add('Confirmed');
        lstStatus.add('Received By Billing');
        lstStatus.add('Ready to Bill');
        lstStatus.add('Fully Invoiced');
        lstStatus.add('Partially Invoiced');
        //Task#79176
        if(System.Label.Release_Flag =='true')
        lstStatus.add('Sent to EQAI'); 
        lstStatus.add('Closed');

        List<TM_Line__c> theTMLineList = new List<TM_Line__c>();
        theTMLineList = [
                SELECT Id, Name, Resource__c, TM__r.Scheduled_Date__c, TM__c, Site_Start_Time__c, Site_End_Time__c, Lunch_Start_Time__c, Lunch_End_Time__c, Eligible_Dispatch_from_Home_Pay__c,
                        TM__r.Prevailing_Wage_Job__c, TM__r.Certified_PW_Job__c, TM__r.Sales_Order__c, TM__r.Bill_to_Customer__r.Name,
                        TM__r.Sales_Order__r.CMR_Description__c,Resource_Type__r.Name,TM__r.Sales_Order__r.Sales_Order_Type__c,
                        TM__r.Service_Center__c, Resource_Type__r.Description__c, Overtime__c, Job_Start_Time__c, Job_End_Time__c, Lunch__c, TM__r.Sales_Order__r.Pay_Rule__c,
                        TM__r.Sales_Order__r.Pay_Rule__r.Type__c, TM__r.Sales_Order__r.Pay_Rule__r.Mon_Sun_Work_Week__c, TM__r.Name, Line_No__c,Resource__r.Resource_Type__c,TM__r.Sales_Order__r.Distance_to_Job_Site__c,
                        TM__r.Sales_Order__r.Bill_to_Customer_No__r.Customer_Type__c, TM__r.Sales_Order__r.Bill_to_Customer_No__c,
                        Total_Job_Hours__c
                FROM TM_Line__c
                WHERE TM__r.Scheduled_Date__c >= :startDate AND
                TM__r.Scheduled_Date__c <= :endDate AND
                (TM__r.Status__c IN:lstStatus OR (TM__r.Status__c = 'Mobile Review' AND TM__r.T_M_Scheduled_Day__c = 'Sunday')) AND
                Resource__c IN:resIdsSet AND (Category__c = 'Labor' OR Category__c = 'Equipment')
        ];

        return theTMLineList;
    }

    public void refreshTimesheetForResources(Week_Number__c weekNo, Id scId, Set<Id> resIdSet){
        if(resIdSet.size() > 0){
            Date weekStartingDate = weekNo.Week_Start_Date__c;
            Date weekEndingDate = weekNo.Week_End_Date__c;
            List<Resource__c> resNeedTimesheetLst = new List<Resource__c>();
            Map<Id, Timesheet__c> mapResTimesheetRefresh = new Map<Id, Timesheet__c>();

            mapRes.clear();
            //Retrieve resources
            List<Resource__c> resLst = ResourcesSelector.newInstance().selectPayrollEmployeeByIdsByActivityDate(resIdSet, weekStartingDate.addDays(-1));

            Set<Id> resourcesForRefresh = new Set<Id>();

            for (Resource__c res : resLst) {
                resourcesForRefresh.add(res.Id);
            }

            List<TM_Line__c> theTMLList = getTMLineList(weekStartingDate.addDays(-1), weekEndingDate, resourcesForRefresh);

            setTMLineByIdsMap(theTMLList);
            setResourceFieldActivityLogMap(tmLinesByIds.keySet());

            Set<Id> payruleId = new Set<Id>();
            //Map resource id with resource object
            for(Resource__c res : resLst){
                mapRes.put(res.Id, res);
                //record resource that does not have timesheet created yet.
                if(!mapResTimesheet.containsKey(res.Id)){
                    resNeedTimesheetLst.add(res);
                } else {
                    //create map for resource with timesheet that needs update
                    mapResTimesheetRefresh.put(res.Id, mapResTimesheet.get(res.Id));
                }

                if(String.isNotBlank(res.Pay_Rule__c)){
                    payruleId.add(res.Pay_Rule__c);
                }
            }

            //Collect pay rule Id from PW Job
            for(TM_Line__c tml : theTMLList){
                if(String.isNotBlank(tml.TM__r.Sales_Order__r.Pay_Rule__c)){
                    if(tml.TM__r.Sales_Order__r.Pay_Rule__r.Type__c == 'Prevailing Wage') payruleId.add(tml.TM__r.Sales_Order__r.Pay_Rule__c);
                }
            }

            //Set pay rules
            setPayRuleMap(payruleId);
            //setPayRuleHolidayMap(payruleId);
            setPayRateByPayRuleAndResTypeMap(payruleId);

            //Collect timesheet Ids
            Set<Id> tsIdSet = new Set<Id>();
            for(Id resId: resIdSet){
                if(mapResTimesheetRefresh.containsKey(resId)){
                    tsIdSet.add(mapResTimesheetRefresh.get(resId).Id);
                }
            }

            //retrieve timesheet lines
            TimeSheetLinesLst = getTimesheetLines(tsIdSet);

            //Populate TheSC
            setServiceCenter(scId);

            Integer TimesheetLinesCount = 0;
            Set<Id> tmIdSet = new Set<Id>();

            Savepoint sp = Database.setSavepoint();

            try {
                //Create timesheet for resource that needs a timesheet
                List<Timesheet__c> newTimesheetLst = new List<Timesheet__c>();
                newTimesheetLst = createTimesheets(resNeedTimesheetLst, weekNo);
                if(newTimesheetLst.size() > 0){
                    insert newTimesheetLst;

                    //Put new timesheet to the Resource id and Timesheet object map
                    for(Timesheet__c ts : newTimesheetLst){
                        mapResTimesheetRefresh.put(ts.Resource__c, ts);
                    }
                }

                //Remove all system created timesheet time
                TimeSheetLinesLst = deleteTimesheetLine(TimeSheetLinesLst);
                deleteHolidayResOff(mapResTimesheetRefresh.keySet(), weekStartingDate, weekEndingDate);

                //Map timesheet id with timesheet object
                for(Id resId : mapResTimesheetRefresh.keySet()){
                    Timesheet__c ts = mapResTimesheetRefresh.get(resId);
                    ts.Status__c = 'Open';
                    TimesheetLst.add(ts);
                }
                setResourceHolidayTaken(resIdSet, weekStartingDate, weekEndingDate);
                createTSLinesFromTMLines(mapResTimesheetRefresh,TimeSheetLinesLst, theTMLList, weekStartingDate, weekEndingDate);
                processOvernightTravelTime(TimeSheetLinesLst, weekEndingDate); //Ticket#24029
                assignHolidays(mapResTimesheetRefresh, TimeSheetLinesLst, weekStartingDate, weekEndingDate);
                assignPayruleHolidays(mapResTimesheetRefresh, TimeSheetLinesLst, weekStartingDate, weekEndingDate);
                createTSLinesFromResOffTable(mapResTimesheetRefresh, TimeSheetLinesLst, weekStartingDate, weekEndingDate);
                assignHolidayPayCode(TimeSheetLinesLst);
                processTimesheetLineWithPayRule(TimeSheetLinesLst);
                //processTimesheetWithPayRuleLineDetails(TimeSheetLinesLst); //Ticket#22944
                processTimesheetWithPayRuleLineDetails2(TimeSheetLinesLst); //Ticket#23239
                finalizeTimesheet(TimeSheetLinesLst);
                checkTimesheetLineTimeOverlap(TimeSheetLinesLst);
                assignPayRate(TimeSheetLinesLst);
                for(Timesheet_Line__c tml : TimeSheetLinesLst) tmIdSet.add(tml.TM__c);
                createFlatPayLines(mapResTimesheetRefresh, TimeSheetLinesLst, tmIdSet);

                if (TimeSheetLinesLst != null && TimeSheetLinesLst.size() > 0) {
                    insert TimeSheetLinesLst;
                    update TimesheetLst;
                    TimesheetLinesCount = TimesheetLst.size();
                }
            } catch (Exception e) {
                System.debug('Error: ' + e.getMessage() + ' --- ' + e.getStackTraceString());
                Database.rollback(sp);
                throw e;
            }
        }
    }

    public Map<Id, String> verifyTimesheets(Week_Number__c weekNo, Id scId){
        //System.debug('#####verifyTimesheetTotalHours Method begin#####');
        Map<Id, String> mapResTSReopenReason = new Map<Id, String>();
        //Retrieve existing timesheets by week number and service center id
        List<Timesheet__c> timesheetLst = [SELECT Id, Name, Employee_No__c, Resource_Name__c, Total_Hours_Submitted__c,Resource__c, Resource__r.Pay_Rule__c,
                                                    Resource__r.Pay_Rule__r.Type__c, Resource__r.Pay_Rule__r.Mon_Sun_Work_Week__c, Payroll__r.Status__c,Payroll__c, Payroll__r.Name, Starting_Date__c, Ending_Date__c, Resource__r.Resource_Type__c,
                                                        (SELECT Time_Type__c, Time_Type_Code__c, Rate__c, Resource__c,
                                                                Pay_Rule__c, Pay_Rule__r.Name,Scheduled_Date__c,
                                                                Work_as_Resource_Type__c,Work_as_Resource_Type__r.Name,
                                                                Sales_Order__c, T_M_Line__c, System_Created_Entry__c
                                                        FROM Timesheet_Lines__r)
                                                FROM Timesheet__c
                                                WHERE Service_Center__c =: scId
                                                AND Week_No__c = :weekNo.Id];

        //Collect timesheet data for comparison
        Set<Id> resWithTimesheetIdSet = new Set<Id>();
        Map<Id, Decimal> resTimesheetSubmittedHrsMap = new Map<Id, Decimal>();
        Map<Id, Decimal> resFlatSubmitted = new Map<Id, Decimal>();
        Map<String, Decimal> payRuleResTypePayRateMap = new Map<String, Decimal>();
        Map<Id, String> payRuleNameMap = new Map<Id, String>();
        Map<Id, String> resTypeNameMap = new Map<Id, String>();
        Set<Id> tsPayRuleIdSet = new Set<Id>();
        Set<String> resHolidaySet = new Set<String>();
        for(Timesheet__c ts : timesheetLst){
            if(ts.Resource__r.Pay_Rule__c != null) tsPayRuleIdSet.add(ts.Resource__r.Pay_Rule__c);
            for(Timesheet_Line__c tsl : ts.Timesheet_Lines__r){
                if(String.isNotBlank(tsl.Pay_Rule__c)) tsPayRuleIdSet.add(tsl.Pay_Rule__c);
            }
        }

        setPayRuleMap(tsPayRuleIdSet);

        for(Timesheet__c ts : timesheetLst){
            if(ts.Payroll__c != null){
                throw new DataException('Payroll# ' + ts.Payroll__r.Name + ' already been created for your service center!');
            }

            //Collect Resource Id Set
            resWithTimesheetIdSet.add(ts.Resource__c);

            //Map resource with submitted hours
            resTimesheetSubmittedHrsMap.put(ts.Resource__c, ts.Total_Hours_Submitted__c);

            //Map resource with timesheet
            mapResTimesheet.put(ts.Resource__c, ts);

            for(Timesheet_Line__c tsl : ts.Timesheet_Lines__r){
                payRuleNameMap.put(tsl.Pay_Rule__c, tsl.Pay_Rule__r.Name);
                resTypeNameMap.put(tsl.Work_as_Resource_Type__c, tsl.Work_as_Resource_Type__r.Name);
                //if(tsl.Time_Type__c == 'Flat Pay' && CompanyMgmt.zeroIfNull(tsl.Rate__c) > 0 && tsl.T_M_Line__c != null && tsl.Resource__c != null){
                if(tsl.Time_Type__c == 'Flat Pay' && CompanyMgmt.zeroIfNull(tsl.Rate__c) > 0 && tsl.System_Created_Entry__c == true && tsl.Resource__c != null){
                    Id mapkey = tsl.Resource__c;
                    if(resFlatSubmitted.containsKey(mapKey)){
                        resFlatSubmitted.put(mapkey, resFlatSubmitted.get(mapkey) + tsl.Rate__c);
                    } else {
                        resFlatSubmitted.put(mapkey, tsl.Rate__c);
                    }
                }               

                if(tsl.Time_Type__c == 'Prevailing Wage' && (tsl.Time_Type_Code__c != 'TRV' || tsl.Time_Type__c != 'Travel Time')){
                    String mapKey = tsl.Pay_Rule__c + ':' + tsl.Sales_Order__c + ':' + tsl.Resource__c + ':' + tsl.Work_as_Resource_Type__c;
                    String payRuleLineMapKey = tsl.Pay_Rule__c + ':' + tsl.Work_as_Resource_Type__c;
                    Decimal payRuleResTypePayRate = 0;
                    Pay_Rule_Line__c payRuleLine = new Pay_Rule_Line__c();
                    if(mapPayRuleResTypeWithPayRuleLine.containsKey(payRuleLineMapKey)){
                        payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(payRuleLineMapKey);
                    }
                    if(tsl.Time_Type_Code__c == 'REG') {
                        payRuleResTypePayRate = CompanyMgmt.zeroIfNull(tsl.Rate__c);
                    } else if (tsl.Time_Type_Code__c == 'O/T' && payRuleLine != null && CompanyMgmt.zeroIfNull(payRuleLine.Overtime_Rate_Multiple__c) > 0){
                        payRuleResTypePayRate = CompanyMgmt.zeroIfNull(tsl.Rate__c) / CompanyMgmt.zeroIfNull(payRuleLine.Overtime_Rate_Multiple__c);
                    } else if (tsl.Time_Type_Code__c == 'DBT' && payRuleLine != null && CompanyMgmt.zeroIfNull(payRuleLine.Double_Time_Rate_Multiple__c) > 0){
                        payRuleResTypePayRate = CompanyMgmt.zeroIfNull(tsl.Rate__c) / CompanyMgmt.zeroIfNull(payRuleLine.Double_Time_Rate_Multiple__c);
                    }
                    if(!payRuleResTypePayRateMap.containsKey(mapKey)) {
                        payRuleResTypePayRateMap.put(mapKey, payRuleResTypePayRate);
                        //System.debug('Info: payRuleResTypePayRateMap ' + mapKey + ' -- ' + payRuleResTypePayRate); //debug pw rate added
                    }
                }

                if(tsl.Time_Type_Code__c == 'HOL'){
                    resHolidaySet.add(tsl.Resource__c + ':' + tsl.Scheduled_Date__c);
                }
            }
        }

        if(timesheetLst.size() > 0){
            //List<Resource__c> resources = ResourcesSelector.newInstance().selectPayrollEmployeeByIdsByActivityDate(mapResTimesheet.keySet(), timesheetLst[0].Starting_Date__c);
            TheScResources = ResourcesSelector.newInstance().selectPayrollEmployeeBySCIdByActivityDate(scId, timesheetLst[0].Starting_Date__c);
        }

        //Collect Resource Ids
        Set<Id> resIdSet = new Set<Id>();
        if(TheScResources.isEmpty()){
            TheScResources = ResourcesSelector.newInstance().selectPayrollEmployeeBySCIdByActivityDate(scId, weekNo.Week_Start_Date__c);
            //setSCLaborResource(scId);
        }

        setResMap(TheScResources);

        for(Resource__c res : TheScResources){
            resIdSet.add(res.Id);
        }

        //Retrieve T&M Lines for all resources in the SC for the payroll period
        TMLineLst = getTMLineList(weekNo.Week_Start_Date__c.addDays(-1), weekNo.Week_End_Date__c, resIdSet);

        Set<Id> payRuleIdSet = new Set<Id>();
        for(TM_Line__c tml:TMLineLst){
            if(String.isNotBlank(tml.TM__r.Sales_Order__r.Pay_Rule__c)) {
                payRuleIdSet.add(tml.TM__r.Sales_Order__r.Pay_Rule__c);
            }
        }

        for(Resource__c res: TheScResources){
            if(String.isNotBlank(res.Pay_Rule__c)){
                payRuleIdSet.add(res.Pay_Rule__c);
            }
        }

        for(Resource__c res: mapRes.values()){
            if(String.isNotBlank(res.Pay_Rule__c)){
                payRuleIdSet.add(res.Pay_Rule__c);
            }
        }

        if(payRuleIdSet.size() > 0) {
            setPayRuleMap(payRuleIdSet);
            setPayRateByPayRuleAndResTypeMap(payRuleIdSet);
        }

        //Map resource with hours record in T&M Line
        Map<Id, Decimal> resHourMap = new Map<Id, Decimal>();
        Set<Id> tmIdSet = new Set<Id>();
        Map<String, Decimal> calculatedPayRulePayRate = new Map<String, Decimal>();
        for(TM_Line__c tml : TMLineLst){
            Time startTime, endTime;
            Decimal numOfHours = 0;
            tmIdSet.add(tml.TM__c);

            //Union Travel Time mod
            Time jobStartTime = tml.Job_Start_Time__c;
            Time jobEndTime = tml.Job_End_Time__c;
            if(isEligibleForDispatchFromHomePay(tml) == true){
                jobStartTime = tml.Site_Start_Time__c;
                jobEndTime = tml.Site_End_Time__c;
            }

            if(tml.TM__r.Scheduled_Date__c < weekNo.Week_Start_Date__c){
                //cover over night shift time from previous payroll(Sunday)
                if(jobEndTime < jobStartTime && jobEndTime != Time.newInstance(24,0,0,0)){
                    startTime = Time.newInstance(24,0,0,0);
                    endTime = jobEndTime;
                }
            } else {
                startTime = jobStartTime;
                endTime = jobEndTime;
                if(tml.TM__r.Scheduled_Date__c == weekNo.Week_End_Date__c){
                    //exclude time that span into next payroll period
                    if(jobEndTime < jobStartTime){
                        endTime = Time.newInstance(24,0,0,0);
                    }
                }
            }
            /*
            if(tml.TM__r.Scheduled_Date__c < weekNo.Week_Start_Date__c){
                //cover over night shift time from previous payroll(Sunday)
                if(tml.Job_End_Time__c < tml.Job_Start_Time__c && tml.Job_End_Time__c != Time.newInstance(24,0,0,0)){
                    startTime = Time.newInstance(24,0,0,0);
                    endTime = tml.Job_End_Time__c;
                }
            } else {
                startTime = tml.Job_Start_Time__c;
                endTime = tml.Job_End_Time__c;
                if(tml.TM__r.Scheduled_Date__c == weekNo.Week_End_Date__c){
                    //exclude time that span into next payroll period
                    if(tml.Job_End_Time__c < tml.Job_Start_Time__c){
                        endTime = Time.newInstance(24,0,0,0);
                    }
                }
            }
             */
            //Union Tralve Time mod
            numOfHours = CompanyMgmt.halfUpTo2D(TimeUtils.calculateHours(startTime, endTime));

            Resource__c laborRes = mapRes.get(tml.Resource__c);
            if (String.isNotBlank(laborRes.Pay_Rule__c) && tml.Eligible_Dispatch_from_Home_Pay__c == true){
                Pay_Rule__c payRule = mapPayRules.get(laborRes.Pay_Rule__c);
                if(payRule.Type__c == 'Union' && payRule.Enable_Dispatch_from_Home_Pay__c == true){
                    Decimal utrvHours = 1;
                    if (tml.TM__r.Sales_Order__r.Distance_to_Job_Site__c == 'GREATER_THAN_FORTY_MILES') {
                        utrvHours = 2;
                    }
                    numOfHours += utrvHours;
                }
            }

            if(numOfHours > 0){
                if(resHourMap.containsKey(tml.Resource__c)) {
                    numOfHours += resHourMap.get(tml.Resource__c);
                }
                resHourMap.put(tml.Resource__c, numOfHours);
            }

            if(numOfHours > 0
                    && String.isNotBlank(tml.TM__r.Sales_Order__r.Pay_Rule__c)
                    && tml.TM__r.Sales_Order__r.Pay_Rule__r.Type__c == 'Prevailing Wage'){
                String payRuleId = tml.TM__r.Sales_Order__r.Pay_Rule__c;
                String mapKey = payRuleId + ':' + tml.Resource_Type__c;
                Decimal payRate = 0;
                if(mapPayRateByPayRuleAndResType.containsKey(mapKey)){
                    payRate = mapPayRateByPayRuleAndResType.get(mapKey);
                    String mapKey2 = payRuleId + ':' + tml.TM__r.Sales_Order__c + ':' + tml.Resource__c + ':' + tml.Resource_Type__c;
                    if(!calculatedPayRulePayRate.containsKey(mapKey2)) {
                        //System.debug('Info: tmline ' + tml.Id);
                        //System.debug('Info: calculatedPayRulePayRate ' + mapKey2 + ' -- ' + payRate); //debug pw rate added
                        calculatedPayRulePayRate.put(mapKey2, payRate);
                    }
                }
            }
        }

        //Retrieve time from resource off table
        TheResourceOffList = getResOffList(resIdSet, weekNo.Week_Start_Date__c.addDays(-1), weekNo.Week_End_Date__c);

        //Map resource with resource off hours
        for(Resource_Off__c resOff : TheResourceOffList){
            if(resOff.Off_Type__r.Name != 'No Work Available' && resOff.Off_Type__r.Name != 'DOT Reset' && resOff.Off_Type__r.Name != 'Unpaid Time Off'){
                Time startTime, endTime;
                Decimal numOfHours = 0;
                if(resOff.Date__c < weekNo.Week_Start_Date__c){
                    //cover over night shift time from previous payroll(Sunday)
                    if(resOff.End_Time__c < resOff.Start_Time__c && resOff.End_Time__c != Time.newInstance(24,0,0,0)){
                        startTime = Time.newInstance(24,0,0,0);
                        endTime = resOff.End_Time__c;
                    }
                } else {
                    startTime = resOff.Start_Time__c;
                    endTime = resOff.End_Time__c;
                    if(resOff.Date__c == weekNo.Week_End_Date__c){
                        //exclude time that span into next payroll period
                        if(resOff.End_Time__c < resOff.Start_Time__c){
                            endTime = Time.newInstance(24,0,0,0);
                        }
                    }
                }

                numOfHours = CompanyMgmt.halfUpTo2D(TimeUtils.calculateHours(startTime, endTime));
                //numOfHours = CompanyMgmt.zeroIfNull(resOff.Total_Hours__c);
                if(numOfHours > 0){
                    if(resHourMap.containsKey(resOff.Resource__c)){
                        numOfHours += resHourMap.get(resOff.Resource__c);
                    }
                    resHourMap.put(resOff.Resource__c, numOfHours);
                }
            }
        }

        //Collect resource id that need to refresh/create timesheet.
        Set<Id> resTimesheetNeedRefresh = new Set<Id>();
        Map<Id, List<Resource_Flat_Pay__c>> mapFlatPaySetup = new Map<Id, List<Resource_Flat_Pay__c>>();
        mapFlatPaySetup = getFlatPayMap(tmIdSet, resHourMap.keySet());

        //Add Resource to refresh list if flat rate change detected.
        for(Id resId : mapFlatPaySetup.keySet()){
            Decimal calculatedTotalFlatPayAmt = 0;
            for(Resource_Flat_Pay__c resFlatPay : mapFlatPaySetup.get(resId)){
                if(resFlatPay.T_M__r.Scheduled_Date__c >= weekNo.Week_Start_Date__c && resFlatPay.T_M__r.Scheduled_Date__c <= weekNo.Week_End_Date__c && CompanyMgmt.zeroIfNull(resFlatPay.Rate__c) > 0){
                    calculatedTotalFlatPayAmt += resFlatPay.Rate__c;
                }
            }

            if(!resFlatSubmitted.containsKey(resId) && calculatedTotalFlatPayAmt > 0){
                resTimesheetNeedRefresh.add(resId);
                if(!mapResTSReopenReason.containsKey(resId)) mapResTSReopenReason.put(resId, 'New flat pay entries added.');
            }
            else if (resFlatSubmitted.containsKey(resId) && resFlatSubmitted.get(resId) != calculatedTotalFlatPayAmt){
                resTimesheetNeedRefresh.add(resId);
                if(!mapResTSReopenReason.containsKey(resId)) mapResTSReopenReason.put(resId, 'Flat pay changes detected! Rate changed from ' + resFlatSubmitted.get(resId) + ' to ' + calculatedTotalFlatPayAmt);
            }
        }

        //Check Resource Flat Pay been removed.
        for(Id resId: resFlatSubmitted.keySet()){
            if(!mapFlatPaySetup.containsKey(resId)){
                resTimesheetNeedRefresh.add(resId);
                if(!mapResTSReopenReason.containsKey(resId)) mapResTSReopenReason.put(resId, 'Flat pay removed! ');
            }
        }

        for(String mapKey : calculatedPayRulePayRate.keySet()){
            Id resId = mapKey.split(':')[2];
            Decimal newPayRate = CompanyMgmt.halfUpTo2D(calculatedPayRulePayRate.get(mapKey));
            //System.debug('Info: checking pw rate ' + mapKey +  ' -- ' + newPayRate);
            if(payRuleResTypePayRateMap.containsKey(mapKey)){
                Decimal oldPayRate = CompanyMgmt.halfUpTo2D(payRuleResTypePayRateMap.get(mapKey));
                if(newPayRate != oldPayRate){
                    resTimesheetNeedRefresh.add(resId);
                    if(!mapResTSReopenReason.containsKey(resId)) mapResTSReopenReason.put(resId, 'PW wage rate changes detected. Rate changed from ' + oldPayRate + ' to ' + newPayRate);
                }
            } else {
                resTimesheetNeedRefresh.add(mapKey.split(':')[2]);
                if(!mapResTSReopenReason.containsKey(resId)) {
                    //System.debug('Info: new PW Wage detected key ' + mapKey);
                    mapResTSReopenReason.put(resId, 'new PW wage rate added!');
                }
            }
        }

        for(Id resId : resHourMap.keySet()){
            if(resTimesheetSubmittedHrsMap.containsKey(resId)) {
                Decimal oldSubmmitedHrs = CompanyMgmt.halfUpTo2D(resTimesheetSubmittedHrsMap.get(resId));
                Decimal newSubmmitedHrs = CompanyMgmt.halfUpTo2D(resHourMap.get(resId));
                if (oldSubmmitedHrs != newSubmmitedHrs) {
                    resTimesheetNeedRefresh.add(resId);
                    if(!mapResTSReopenReason.containsKey(resId)) mapResTSReopenReason.put(resId, 'Total Hours difference detected. Total submitted hours changed from ' + oldSubmmitedHrs + ' to ' + newSubmmitedHrs);
                }
            } else {
                resTimesheetNeedRefresh.add(resId);
                if(!mapResTSReopenReason.containsKey(resId)) mapResTSReopenReason.put(resId, 'new timesheet added');
            }
        }

        Set<Id> resIdTimesheetNeedToBeRemoved = new Set<Id>();
        //Handle holiday changes
        //Company Holiday
        Set<String> newResHolidaySet = new Set<String>();
        Set<String> payRuleAndResType = new Set<String>();
        setCompanyHolidayMap(weekNo.Week_Start_Date__c, weekNo.Week_End_Date__c);
        setResNonPTODateMap(weekNo.Week_Start_Date__c, weekNo.Week_End_Date__c);

        //find earliest T&M scheduled date needed to calculate union holiday pay
        Integer minDaysWorkNeeded = 0;
        Integer numOfDayToIncludedInTheCount = 0;
        for(Id resId : mapResTimesheet.keySet()){
            Timesheet__c resTimesheet = mapResTimesheet.get(resId);
            if(resTimesheet.Resource__r.Pay_Rule__c != null){
                payRuleAndResType.add(resTimesheet.Resource__r.Pay_Rule__c + ':' + resTimesheet.Resource__r.Resource_Type__c);
                Pay_Rule__c payRule = mapPayRules.get(resTimesheet.Resource__r.Pay_Rule__c);
                if(payRule.Pay_Holiday__c == true && String.isNotBlank(payRule.Work_x_out_y_days_to_qualify__c)){
                    try{
                        List<String> ruleInputs = payRule.Work_x_out_y_days_to_qualify__c.split('|');
                        if(Integer.valueOf(ruleInputs[0]) > minDaysWorkNeeded) minDaysWorkNeeded = Integer.valueOf(ruleInputs[0]);
                        if(Integer.valueOf(ruleInputs[2]) > numOfDayToIncludedInTheCount) numOfDayToIncludedInTheCount = Integer.valueOf(ruleInputs[2]);
                    } catch (Exception e){
                        throw e;
                    }
                }
            }
        }

        //Ticket#20185
        //Date tmStartDate = numOfDayToIncludedInTheCount > 0 ? TimeUtils.addDaysWithOutWeekend(weekNo.Week_Start_Date__c, numOfDayToIncludedInTheCount, true):weekNo.Week_Start_Date__c.addDays(-3);
        Date tmStartDate = numOfDayToIncludedInTheCount > 0 ? TimeUtils.addDaysWithOutWeekend(weekNo.Week_Start_Date__c, numOfDayToIncludedInTheCount, true):weekNo.Week_Start_Date__c.addDays(-4);
        //Ticket#20185
        Date tmEndDate = weekNo.Week_End_Date__c.addDays(1);

        tmStartDate = tmStartDate < weekNo.Week_Start_Date__c ? tmStartDate : weekNo.Week_Start_Date__c;
        tmEndDate = tmEndDate > weekNo.Week_End_Date__c ? tmEndDate : weekNo.Week_End_Date__c;
        List<TM_Line__c> tmLines = getTMLineList(tmStartDate, tmEndDate, mapResTimesheet.keySet());
        List<Resource_Off__c> paidOffDays = getResOffList(mapResTimesheet.keySet(), tmStartDate, tmEndDate);
        Set<String> resWorkDateSet = new Set<String>();
        Set<String> resPWJobWorkDateSet = new Set<String>();
        for(TM_Line__c tmLine:tmLines){
            //String resIdAndScheduleDate = tmLine.Resource__c + ':' + tmLine.TM__r.Scheduled_Date__c; //Ticket#25014
            String resIdAndScheduleDate = tmLine.Resource__c + ':' + tmLine.TM__r.Scheduled_Date__c + ':' + tmLine.Resource_Type__c;
            resWorkDateSet.add(resIdAndScheduleDate);

            Time jobStartTime = tmLine.Job_Start_Time__c;
            Time jobEndTime = tmLine.Job_End_Time__c;
            if(isEligibleForDispatchFromHomePay(tmLine) == true){
                jobStartTime = tmLine.Site_Start_Time__c;
                jobEndTime = tmLine.Site_End_Time__c;
            }

            if(jobStartTime != null && jobEndTime != null && jobStartTime >= jobEndTime && jobEndTime != TimeUtils.midNight()){
                resWorkDateSet.add(tmLine.Resource__c + ':' + tmLine.TM__r.Scheduled_Date__c.addDays(1));
            }

            if(tmLine.TM__r.Sales_Order__r.Pay_Rule__r.Type__c == 'Prevailing Wage'){
                resPWJobWorkDateSet.add(resIdAndScheduleDate);

                //Ticket#16140
                if(jobStartTime != null && jobEndTime != null && jobStartTime >= jobEndTime && jobEndTime != TimeUtils.midNight()){
                    //resPWJobWorkDateSet.add(tmLine.Resource__c + ':' + tmLine.TM__r.Scheduled_Date__c.addDays(1)); //Ticket#25014
                    resPWJobWorkDateSet.add(tmLine.Resource__c + ':' + tmLine.TM__r.Scheduled_Date__c.addDays(1) + ':' + tmLine.Resource_Type__c);
                }
                payRuleAndResType.add(tmLine.TM__r.Sales_Order__r.Pay_Rule__c + ':' + tmLine.Resource__r.Resource_Type__c);
                payRuleAndResType.add(tmLine.TM__r.Sales_Order__r.Pay_Rule__c + ':' + tmLine.Resource_Type__c); //Ticket#19834
            }
        }

        for(Resource_Off__c paidOffDay:paidOffDays){
            if(paidOffDay.PTO_Type__c != 'PTO-Sick') {
                resWorkDateSet.add(paidOffDay.Resource__c + ':' + paidOffDay.Date__c);
            }
        }

        Set<String> holidayAlreadyTook = new Set<String>();
        if(mapCompanyHoliday.size() > 0){
            for (Date holidayDate : mapCompanyHoliday.keySet()) {
                for (Id resId : mapResTimesheet.keySet()) {
                    Resource__c res = mapRes.get(resId);
                    if (!holidayAlreadyTook.contains(res.Id + ':' + holidayDate) &&
                            isQualifyForCompanyHoliday(res, holidayDate, resWorkDateSet, weekNo.Week_Start_Date__c, weekNo.Week_End_Date__c) == true) {
                        newResHolidaySet.add(resId + ':' + holidayDate);
                        holidayAlreadyTook.add(resId + ':' + holidayDate);
                    }
                }
            }
        }

        if(payRuleAndResType.size() > 0) setPayRuleHolidayDateMap(weekNo.Week_Start_Date__c, weekNo.Week_End_Date__c, payRuleAndResType);
        if(mapPayRuleHolidayDate.size() > 0) {
            //Union Holiday
            for (Id resId : mapResTimesheet.keySet()) {
                Resource__c res = mapRes.get(resId);
                if (res.Pay_Rule__c != null && mapPayRuleHolidayDate.containsKey(res.Pay_Rule__c + ':' + res.Resource_Type__c)
                        && mapPayRules.get(res.Pay_Rule__c).Pay_Holiday__c == true) {
                    for (Date holidayDate : mapPayRuleHolidayDate.get(res.Pay_Rule__c + ':' + res.Resource_Type__c)) {
                        if (!holidayAlreadyTook.contains(res.Id + ':' + holidayDate) &&
                                //Ticket#23635 >> isQualifyForUnionHoliday(res, holidayDate, resWorkDateSet, res.Pay_Rule__c, res.Resource_Type__c) == true) {
                                isQualifyForUnionHoliday(res, holidayDate, resWorkDateSet, res.Pay_Rule__c, res.Resource_Type__c) == true) {
                                //Ticket#23635 <<
                            newResHolidaySet.add(resId + ':' + holidayDate);
                            holidayAlreadyTook.add(resId + ':' + holidayDate);
                        }
                    }
                }
            }

            //PW Holiday
            for(TM_Line__c tmLine:tmLines){
                if(tmLine.TM__r.Sales_Order__r.Pay_Rule__c != null && tmLine.Resource__c != null
                        && tmLine.TM__r.Scheduled_Date__c >= weekNo.Week_Start_Date__c && tmLine.TM__r.Scheduled_Date__c <= weekNo.Week_End_Date__c){
                    Pay_Rule__c payRule = mapPayRules.get(tmLine.TM__r.Sales_Order__r.Pay_Rule__c);
                    Resource__c res = mapRes.get(tmLine.Resource__c);
                    //Ticket#19834 from res.Resource_Type__c to tmLine.Resource_Type__c
                    if(payRule.Type__c == 'Prevailing Wage' && payRule.Pay_Holiday__c == true &&
                            mapPayRuleHolidayDate.containsKey(payRule.Id + ':' + tmLine.Resource_Type__c)){
                        for(Date holidayDate:mapPayRuleHolidayDate.get(payRule.Id + ':' + tmLine.Resource_Type__c)) {
                            //Ticket#25014 isQualifyForPWHoliday(res, holidayDate, resPWJobWorkDateSet) == true) {
                            if (!holidayAlreadyTook.contains(res.Id + ':' + holidayDate) &&
                                    isQualifyForPWHoliday(res, holidayDate, tmLine.Resource_Type__c, resPWJobWorkDateSet) == true) {
                                newResHolidaySet.add(res.Id + ':' + holidayDate);
                                holidayAlreadyTook.add(res.Id + ':' + holidayDate);
                            }
                        }
                    }
                }
            }
        }

        for(String resHoliday:resHolidaySet){
            if(!newResHolidaySet.contains(resHoliday)){
                Id resId = resHoliday.split(':')[0];
                if (resId != null) resTimesheetNeedRefresh.add(resId);
                resIdTimesheetNeedToBeRemoved.add(resId);
                if(!mapResTSReopenReason.containsKey(resId)) mapResTSReopenReason.put(resId, 'Holiday pay removed ' + resHoliday.split(':')[1]);
            }
        }

        for(String resHoliday:newResHolidaySet){
            if(!resHolidaySet.contains(resHoliday)){
                Id resId = resHoliday.split(':')[0];
                if (resId != null) resTimesheetNeedRefresh.add(resId);
                if(!mapResTSReopenReason.containsKey(resId)) mapResTSReopenReason.put(resId, 'Holiday pay added ' + resHoliday.split(':')[1]);
            }
        }

        //collect resource id that used to have timesheet, but all time entries was removed before refresh
        List<Timesheet__c> timesheetNeedToBeRemoved = new List<Timesheet__c>();
        Set<Id> timesheetIdSet = new Set<Id>();
        for(Id resId : resTimesheetSubmittedHrsMap.keySet()){
            if(!resHourMap.containsKey(resId)){
                timesheetNeedToBeRemoved.add(mapResTimesheet.get(resId));
                timesheetIdSet.add(mapResTimesheet.get(resId).Id);
                resIdTimesheetNeedToBeRemoved.add(resId);
            }
        }

        refreshTimesheetForResources(weekNo, scId, resTimesheetNeedRefresh);

        if(timesheetNeedToBeRemoved.size() > 0){
            delete timesheetNeedToBeRemoved;
            deleteHolidayResOff(resIdTimesheetNeedToBeRemoved, weekNo.Week_Start_Date__c, weekNo.Week_End_Date__c);
        }
        //System.debug('#####verifyTimesheetTotalHours Method end#####');
        return mapResTSReopenReason;
    }

    public List<Timesheet__c> createTimesheets(List<Resource__c> resLst, Week_Number__c weekNumber){
        // System.debug('creating timesheet...');
        Timesheet__c TS = new Timesheet__c();
        List<Timesheet__c> theTSList = new List<Timesheet__c>();
        for (Resource__c theResource : resLst) {
            TS = new Timesheet__c();
            if(theResource.Pay_Rule__r.Mon_Sun_Work_Week__c == true) {
                TS.Starting_Date__c = weekNumber.Week_Start_Date__c;
                TS.Ending_Date__c = weekNumber.Week_End_Date__c;
            } else {
                TS.Starting_Date__c = weekNumber.Week_Start_Date__c.addDays(-1);
                TS.Ending_Date__c = weekNumber.Week_End_Date__c.addDays(-1);
            }
            
            TS.Resource__c = theResource.Id;
            // TS.Ending_Date__c = weekNumber.Week_End_Date__c;
            TS.Resource__c = theResource.Id;
            TS.Resource_Name__c = theResource.Description__c;
            TS.Service_Center__c = theResource.Service_Center__c;
            // TS.Starting_Date__c = weekNumber.Week_Start_Date__c;
            TS.Week_No__c = weekNumber.Id;
            TS.System_Created_Entry__c = true;
            theTSList.add(TS);
        }
        return theTSList;
    }

    public List<Timesheet_Line__c> getTimesheetLines(Set<Id> tsIdSet){
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Timesheet_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Parent_Line__r.Name, Resource_Off__r.Name, Sales_Order__r.Name, Sales_Order_Service_Center__r.Name ';
        strQuery += ',TM__r.Name, T_M_Line__r.Name, Timesheet__r.Name, Timesheet__r.Resource__c, T_M_Line__r.Category__c ';
        strQuery += ' FROM Timesheet_Line__c WHERE Timesheet__c =: tsIdSet ORDER BY Scheduled_Date__c, Sales_Order__c ';
        return Database.query(strQuery);
    }

    public void createFlatPayLines(Map<Id, Timesheet__c> timesheetsByResIds, List<Timesheet_Line__c> tslLst, Set<Id> tmIdSet){
        // System.debug('###createFlatPayLines method call begin ####');
        Map<Id, List<Resource_Flat_Pay__c>> mapFlatPaySetup = new Map<Id, List<Resource_Flat_Pay__c>>();
        mapFlatPaySetup = getFlatPayMap(tmIdSet, timesheetsByResIds.keySet());
        for(Id mapKey : mapFlatPaySetup.keySet()){
            List<Resource_Flat_Pay__c> flatpayList = mapFlatPaySetup.get(mapKey);
            Timesheet__c ts = timesheetsByResIds.get(mapKey);
            for(Resource_Flat_Pay__c flatPay2:flatpayList){
                if(flatPay2.T_M__r.Scheduled_Date__c >= ts.Starting_Date__c && flatPay2.T_M__r.Scheduled_Date__c <= ts.Ending_Date__c){
                    Timesheet_Line__c timesheetLine = new Timesheet_Line__c();
                    timesheetLine.Timesheet__c = ts.Id;
                    timesheetLine.Time_Type__c = 'Flat Pay';
                    timesheetLine.Resource__c = flatPay2.T_M_Line__r.Resource__c;
                    timesheetLine.Time_Type_Code__c = flatPay2.Rate_Type__c;
                    timesheetLine.Sales_Order_Service_Center__c = flatPay2.T_M__r.Service_Center__c;
                    timesheetLine.Sales_Order__c = flatPay2.T_M__r.Sales_Order__c;
                    timesheetLine.Work_as_Resource_Type__c = flatPay2.T_M_Line__r.Resource_Type__c;
                    timesheetLine.TM__c = flatPay2.T_M__c;
                    timesheetLine.T_M_Line__c = flatPay2.T_M_Line__c;
                    timesheetLine.Scheduled_Date__c = flatPay2.T_M__r.Scheduled_Date__c;
                    Datetime scheduleDateTime = TimesheetMgmt.getDatetimeInUserTZ(timesheetLine.Scheduled_Date__c);
                    timesheetLine.Week_Day__c = scheduleDateTime.format('EEEE');
                    timesheetLine.Net_Hours__c = 0;
                    timesheetLine.Rate__c = CompanyMgmt.zeroIfNull(flatPay2.Rate__c);
                    timesheetLine.System_Created_Entry__c = true;
                    tslLst.add(timesheetLine);
                }
            }
        }
        //System.debug('###createFlatPayLines method call end ####');
    }

    public void finalizeTimesheet(List<Timesheet_Line__c> timesheetLineList){
        Map<String, List<Timesheet_Line__c>> timesheetMap = new Map<String, List<Timesheet_Line__c>>();
        for(Timesheet_Line__c tsLine: timesheetLineList){
            if(timesheetMap.containsKey(tsLine.Timesheet__c)){
                List<Timesheet_Line__c> tsLineList = timesheetMap.get(tsLine.Timesheet__c);
                tsLineList.add(tsLine);
                timesheetMap.put(tsLine.Timesheet__c, tsLineList);
            } else {
                timesheetMap.put(tsLine.Timesheet__c, new List<Timesheet_Line__c>{tsLine});
            }
        }

        if(timesheetMap.size() > 0){
            Set<String> mapKeys = timesheetMap.keySet();
            List<Timesheet_Line__c> otList = new List<Timesheet_Line__c>();
            for(String mapKey:mapKeys) {
                Map<Date, Decimal> dailyOTDateAndHourMap = new Map<Date, Decimal>();
                List<Timesheet_Line__c> tsLinesList = timesheetMap.get(mapKey);

                //copy timesheet line to wrapper for custom sorting
                TimesheetLineWrapper[] tlLst = new List<TimesheetLineWrapper>();
                for (Timesheet_Line__c tsLine : tsLinesList) {
                    tlLst.add(new TimesheetLineWrapper(tsLine));
                }

                //Sort by Scheduled Date and by Start Time(ASC)
                tlLst.sort();

                for(TimesheetLineWrapper tLineWrapper : tlLst) {
                    if(tLineWrapper.theTL.Calculate_OT_Daily__c == true && (tLineWrapper.theTL.Time_Type_Code__c == 'REG' || tLineWrapper.theTL.Time_Type_Code__c == 'SHP')){
                        dailyOTDateAndHourMap.put(tLineWrapper.theTL.Scheduled_Date__c, tLineWrapper.theTL.Daily_OT_After_Number_of_Hrs__c);
                    }
                }
                //System.debug('Info: dailyOTDateAndHourMap ' + dailyOTDateAndHourMap);

                Decimal weeklyOTRemainingHrs = WEEKLY_OT_THRESHOLD;
                Boolean weeklyOTReached = false;
                Boolean dailyOTReached = false;
                Decimal totalDailyHrs = 0;
                Date currentProcessingDate;

                for (TimesheetLineWrapper tLineWrapper : tlLst) {
                    if ((tLineWrapper.theTL.Time_Type__c == 'Job Time' || tLineWrapper.theTL.Time_Type__c == 'Prevailing Wage' || tLineWrapper.theTL.Time_Type__c == 'Shop Time' || tLineWrapper.theTL.Time_Type__c == 'Travel Time')
                        && (tLineWrapper.theTL.Time_Type_Code__c == 'REG' || tLineWrapper.theTL.Time_Type_Code__c == 'SHP' || tLineWrapper.theTL.Time_Type_Code__c == 'TRV' || tLineWrapper.theTL.Time_Type__c == 'UTRV')) {

                        //System.debug('Info: ' + tLineWrapper.theTL.Scheduled_Date__c + ' -- ' + tLineWrapper.theTL.Start_Time__c + ' -- ' + tLineWrapper.theTL.Time_Type__c + ' -- ' + tLineWrapper.theTL.Time_Type_Code__c + ' -- ' + tLineWrapper.theTL.Net_Hours__c);
                        Decimal lineHrs = tLineWrapper.theTL.Net_Hours__c;
                        Decimal otHrs = 0;
                        //Ticket#23663 >>
                        //if (tLineWrapper.theTL.Calculate_OT_Daily__c == true && (tLineWrapper.theTL.Time_Type_Code__c != 'TRV' || tLineWrapper.theTL.Time_Type__c != 'Travel Time')){
                        if (tLineWrapper.theTL.Calculate_OT_Daily__c == true){
                        //Ticket#23663 <<
                            if(tLineWrapper.theTL.Scheduled_Date__c != currentProcessingDate){
                                //Ticket#22942 >>
                                currentProcessingDate = tLineWrapper.theTL.Scheduled_Date__c;
                                totalDailyHrs = lineHrs;
                                dailyOTReached = false;
                                //Ticket#22942 <<
                                if(totalDailyHrs > dailyOTDateAndHourMap.get(currentProcessingDate)){
                                    otHrs = totalDailyHrs - dailyOTDateAndHourMap.get(currentProcessingDate);
                                    lineHrs = lineHrs - otHrs;
                                    dailyOTReached = true;
                                }
                            } else {
                                if(dailyOTReached == false){
                                    totalDailyHrs += lineHrs;
                                    if (totalDailyHrs > dailyOTDateAndHourMap.get(currentProcessingDate)) {
                                        otHrs = totalDailyHrs - dailyOTDateAndHourMap.get(currentProcessingDate);
                                        lineHrs = lineHrs - otHrs;
                                        dailyOTReached = true;
                                    }
                                } else {
                                    otHrs = lineHrs;
                                    lineHrs = 0;
                                }
                            }
                            //System.debug('Info: Daily OT currentProcessingDate ' + currentProcessingDate);
                            //System.debug('Info: Daily OT totalDailyHrs ' + totalDailyHrs);
                        }

                        if(weeklyOTRemainingHrs > 0){
                            weeklyOTRemainingHrs -= lineHrs;
                        }

                        //System.debug('Info: lineHrs ' + lineHrs);
                        //System.debug('Info: weeklyOTReached ' + weeklyOTReached + ' weeklyOTRemainingHrs: '+ weeklyOTRemainingHrs);

                        if(weeklyOTRemainingHrs == 0 && weeklyOTReached){
                            otHrs = otHrs + lineHrs;
                            lineHrs = 0;
                        } else if(weeklyOTRemainingHrs == 0 && !weeklyOTReached){
                            weeklyOTReached = true;
                        } else if (weeklyOTRemainingHrs < 0 && !weeklyOTReached){
                            lineHrs = lineHrs - Math.abs(weeklyOTRemainingHrs);
                            otHrs = Math.abs(weeklyOTRemainingHrs);
                            weeklyOTReached = true;
                            weeklyOTRemainingHrs = 0;
                        }

                        //System.debug('Info: Daily OT dailyOTReached ' + dailyOTReached);
                        //System.debug('Info: WeeklyOT Reached: ' + weeklyOTReached + ' lineHrs: ' + lineHrs + ' -- otHrs: ' + otHrs);

                        if((dailyOTReached == true || weeklyOTReached) && lineHrs == 0 && otHrs != 0){
                            if(tLineWrapper.theTL.Time_Type_Code__c == 'REG' || tLineWrapper.theTL.Time_Type_Code__c == 'SHP') tLineWrapper.theTL.Time_Type_Code__c = theCompanySetup.Overtime_Rate__c;
                        }

                        //Split Reg hour line into two lines Reg and OT if Daily or Weekly limit reach
                        if (otHrs != 0 && lineHrs != 0 && (tLineWrapper.theTL.Time_Type_Code__c == 'REG' || tLineWrapper.theTL.Time_Type_Code__c == 'SHP')) {
                                dailyOTReached = true;
                                Timesheet_Line__c otLine = new Timesheet_Line__c();
                                otLine = createSysCalcLine(tLineWrapper.theTL,
                                        null,
                                        null,
                                        otHrs,
                                        tLineWrapper.theTL.Time_Type__c,
                                        theCompanySetup.Overtime_Rate__c);
                            tLineWrapper.theTL.Total_Hours__c = lineHrs;
                            reallocateTimesForTimesheetLines(tLineWrapper.theTL, otLine);
                                otList.add(otLine);
                        }
                    }
                }
            }
            if (otList.size() > 0) {
                /*
                for(Timesheet_Line__c tsl : otList){
                    System.debug('Info: OT Line: ' + tsl.Scheduled_Date__c + ' -- ' + tsl.Start_Time__c + ' -- ' + tsl.Time_Type__c + ' -- ' + tsl.Time_Type_Code__c + ' -- ' + tsl.Net_Hours__c);
                }
                 */
                timesheetLineList.addAll(otList);
            }
        }
    }

    public void assignPayRate(List<Timesheet_Line__c> timesheetLineList) {
        Set<Id> payRuleIdSet = new Set<Id>();
        payRuleIdSet = collectPayRuleIdsFromTimesheetLines(timesheetLineList);
        setPayRateByPayRuleAndResTypeMap(payRuleIdSet);
        for (Timesheet_Line__c tsl : timesheetLineList) {
            /*
            //Ticket#23136 >>
            Boolean isInterCompanyJob = false;
            if(tsl.T_M_Line__c != null && tmLinesByIds.containsKey(tsl.T_M_Line__c)){
                TM_Line__c tmLine = tmLinesByIds.get(tsl.T_M_Line__c);
                if(tmLine.TM__r.Sales_Order__c != null && tmLine.TM__r.Sales_Order__r.Bill_to_Customer_No__c != null &&
                    tmLine.TM__r.Sales_Order__r.Bill_to_Customer_No__r.Customer_Type__c == 'I/C'){
                    isInterCompanyJob = true;
                }
            }
            //Ticket#23136 <<
             */

            //Ticket#22782 >>
            Pay_Rule_Line__c payRuleLine = null;
            //if(isInterCompanyJob == false) {
            if (String.isNotBlank(tsl.Pay_Rule_Line__c)) {
                if (payRuleLinesByIds.containsKey(tsl.Pay_Rule_Line__c)) {
                    payRuleLine = payRuleLinesByIds.get(tsl.Pay_Rule_Line__c);
                }
            } else {
                if (mapPayRuleResTypeWithPayRuleLine.size() > 0
                        && tsl.Work_as_Resource_Type__c != null
                        && String.isNotBlank(tsl.Pay_Rule__c)) {
                    Pay_Rule__c payRule = mapPayRules.get(tsl.Pay_Rule__c);
                    String mapKey = payRule.Id + ':' + tsl.Work_as_Resource_Type__c;
                    if (mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                        payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                    }
                }
            }
            //}
            //Ticket#22782 <<
            //Ticket#22946 - Exclude shop time entry from rate assignment
            //Ticket#23136 - Exclude Inter-Company Job from rate assignment
            //Ticket#22782 >>
            if(payRuleLine != null) {
                Pay_Rule__c payRule = mapPayRules.get(payRuleLine.Pay_Rule__c);
                tsl.Pay_Rule_Line__c = payRuleLine.Id;
                Decimal resTypePayRate = CompanyMgmt.zeroIfNull(payRuleLine.Rate__c);
                if (tsl.Time_Type__c == 'Travel Time') {
                    if (payRule.Pay_Travel_Time__c == true) {
                        resTypePayRate = CompanyMgmt.zeroIfNull(payRule.Travel_Time_Pay_Rate__c);
                    } else {
                        resTypePayRate = 0;
                    }
                }
                if (tsl.Time_Type_Code__c == theCompanySetup.Standard_Rate__c || tsl.Time_Type_Code__c == 'SHP') {
                    tsl.Rate__c = resTypePayRate;
                } else if (tsl.Time_Type_Code__c == theCompanySetup.Overtime_Rate__c) {
                    tsl.Rate__c = resTypePayRate * CompanyMgmt.zeroIfNull(payRuleLine.Overtime_Rate_Multiple__c);
                } else if (tsl.Time_Type_Code__c == theCompanySetup.Double_Time_Rate__c) {
                    tsl.Rate__c = resTypePayRate * CompanyMgmt.zeroIfNull(payRuleLine.Double_Time_Rate_Multiple__c);
                }
            }
            //Ticket#22782 <<
            /*
            if (mapPayRuleResTypeWithPayRuleLine.size() > 0
                    && tsl.Time_Type__c != 'Shop Time'
                    && isInterCompanyJob == false
                    && tsl.Work_as_Resource_Type__c != null
                    && String.isNotBlank(tsl.Pay_Rule__c)) {
                Pay_Rule__c payRule = mapPayRules.get(tsl.Pay_Rule__c);
                String mapKey = payRule.Id + ':' + tsl.Work_as_Resource_Type__c;
                if (mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                    Pay_Rule_Line__c payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                    tsl.Pay_Rule_Line__c = payRuleLine.Id; //Ticket#22504
                    Decimal resTypePayRate = CompanyMgmt.zeroIfNull(payRuleLine.Rate__c);
                    if (tsl.Time_Type__c == 'Travel Time') {
                        if (payRule.Pay_Travel_Time__c == true) {
                            resTypePayRate = CompanyMgmt.zeroIfNull(payRule.Travel_Time_Pay_Rate__c);
                        } else {
                            resTypePayRate = 0;
                        }
                    }
                    if (tsl.Time_Type_Code__c == theCompanySetup.Standard_Rate__c || tsl.Time_Type_Code__c == 'SHP') {
                        tsl.Rate__c = resTypePayRate;
                    } else if (tsl.Time_Type_Code__c == theCompanySetup.Overtime_Rate__c) {
                        tsl.Rate__c = resTypePayRate * CompanyMgmt.zeroIfNull(payRuleLine.Overtime_Rate_Multiple__c);
                    } else if (tsl.Time_Type_Code__c == theCompanySetup.Double_Time_Rate__c) {
                        tsl.Rate__c = resTypePayRate * CompanyMgmt.zeroIfNull(payRuleLine.Double_Time_Rate_Multiple__c);
                    }
                }
            }
             */
            if (tsl.Rate__c == 0) {
                tsl.Rate__c = null;
            }
        }
    }

    public Timesheet_Line__c createSysCalcLine(Timesheet_Line__c parentLine, Time starTime, Time endTime, Decimal hrs,
            String timeType, String timeCode){

        Timesheet_Line__c sysCalcLine = parentLine.clone();
        sysCalcLine.Lunch_Start_Time__c = null;
        sysCalcLine.Lunch_End_Time__c = null;
        sysCalcLine.Lunch_Hours__c = null;

        sysCalcLine.Start_Time__c = starTime;
        sysCalcLine.End_Time__c = endTime;
        sysCalcLine.Net_Hours__c = hrs;
        sysCalcLine.Total_Hours__c = hrs;
        sysCalcLine.System_Created_Entry__c = true;
        sysCalcLine.Calculated_by_System__c = true;
        sysCalcLine.Parent_Line__c = parentLine.Id;
        sysCalcLine.Time_Type__c = timeType;
        sysCalcLine.Time_Type_Code__c = timeCode;
        sysCalcLine.Pay_Rule__c = parentLine.Pay_Rule__c;
        sysCalcLine.Pay_Rule_Line__c = parentLine.Pay_Rule_Line__c; //Ticket#22504
        //sysCalcLine.OT_Over_Eight_Hrs_Daily__c = parentLine.OT_Over_Eight_Hrs_Daily__c;
        sysCalcLine.Calculate_OT_Daily__c = parentLine.Calculate_OT_Daily__c;
        sysCalcLine.Daily_OT_After_Number_of_Hrs__c = parentLine.Daily_OT_After_Number_of_Hrs__c;
        return sysCalcLine;

    }

    public Map<Id, List<Resource_Flat_Pay__c>> getFlatPayMap(Set<Id> tmIds, Set<Id> resIds){
        Map<Id, List<Resource_Flat_Pay__c>> mapFlatPaySetup = new Map<Id, List<Resource_Flat_Pay__c>>();
        List<Resource_Flat_Pay__c> flatRateSetupList = [SELECT Id, T_M__c, T_M__r.Sales_Order__c, T_M__r.Scheduled_Date__c, Rate__c,
                T_M_Line__c, T_M__r.Service_Center__c, Rate_Type__c, T_M_Line__r.Resource__c, T_M_Line__r.Resource_Type__c
        FROM Resource_Flat_Pay__c
        WHERE T_M__c IN :tmIds AND
        T_M_Line__r.Resource__c IN :resIds];

        for(Resource_Flat_Pay__c flatPay:flatRateSetupList){
            Id mapKey = flatPay.T_M_Line__r.Resource__c;
            if(mapFlatPaySetup.containsKey(mapKey)){
                List<Resource_Flat_Pay__c> flatPayList = mapFlatPaySetup.get(mapKey);
                flatPayList.add(flatPay);
                mapFlatPaySetup.put(mapKey, flatPayList);
            } else {
                mapFlatPaySetup.put(mapKey, new List<Resource_Flat_Pay__c>{flatPay});
            }
        }

        return mapFlatPaySetup;
    }

    /*
     *  Ticket#23713 - add Flat Pay Rate and Flat Rate Type fields to the query
     */
    public List<Resource_Off__c> getResOffList(Set<Id> resIds, Date staDate, Date endDate){
        // List Off Code
        //Todo use query instead of hard code
        List<String> lstOff = new List<String>();
        lstOff.add('Shop Time');
        lstOff.add('Paid Time Off');
        lstOff.add('Jury Duty');
        lstOff.add('Holiday');
        lstOff.add('Bereavement');
        lstOff.add('No Work Available');
        lstOff.add('Unpaid Time Off');
        //lstOff.add('Unavailable');
        lstOff.add('DOT Reset');

        List<Resource_Off__c> theResourceOffList = [
                SELECT Id, Name, Resource__c, Start_Time__c, End_Time__c, Resource__r.Resource_Type__r.Name, Hours__c, Note__c, Off_Type__r.Name,
                        Date__c, Off_Type__r.Map_Time_Rate_Code__c, Off_Type__r.Map_to_Time_Type__c, Lunch_End_Time__c, Lunch_Start_Time__c, Shop_Time_Category__c,
                        Resource__r.Pay_Rule__c, Total_Hours__c, Pay_Rule__c, System_Created_Entry__c,Service_Center__c, Resource_Service_Center__c, Service_Center__r.Shop_Time_Sales_Order__c,
                        PTO_Type__c, Unavailable_Reason__c, Work_as_Resource_Type__c, Flat_Pay_Rate__c, Flat_Rate_Type__c, Sales_Order__c
                FROM Resource_Off__c
                WHERE Date__c >= :staDate AND
                Date__c <= :endDate AND Resource__c IN :resIds
                AND Off_Type__r.Name IN:lstOff
        ];

        return theResourceOffList;
    }

    public List<Resource_Off__c> getResOffListByResIdByDateByTypeName(Set<Id> resIds, Date staDate, Date endDate, List<String> offTypeName){
        List<Resource_Off__c> theResourceOffList = [
                SELECT Id, Name, Resource__c, Start_Time__c, End_Time__c, Resource__r.Resource_Type__r.Name, Hours__c, Note__c, Off_Type__r.Name,
                        Date__c, Off_Type__r.Map_Time_Rate_Code__c, Off_Type__r.Map_to_Time_Type__c, Lunch_End_Time__c, Lunch_Start_Time__c, Shop_Time_Category__c,
                        Resource__r.Pay_Rule__c, Total_Hours__c, Pay_Rule__c, System_Created_Entry__c, Service_Center__c, Resource_Service_Center__c, Service_Center__r.Shop_Time_Sales_Order__c,
                        PTO_Type__c,Unavailable_Reason__c, Work_as_Resource_Type__c
                FROM Resource_Off__c
                WHERE Date__c >= :staDate AND
                Date__c <= :endDate AND Resource__c IN :resIds
                AND Off_Type__r.Name IN:offTypeName
        ];

        return theResourceOffList;
    }

    public Map<Date, Holiday__c> getHolidayMap(){
        Map<Date,Holiday__c> holidayRateMap = new Map<Date,Holiday__c>();
        List<Holiday__c> theHolidayList = [SELECT Name,Date__c,Rate_Type__c, Holiday_Name_Map__c
                                                FROM Holiday__c WHERE Holiday_Name_Map__c != null];
        for (Holiday__c theHoliday : theHolidayList){
            holidayRateMap.put(theHoliday.Date__c, theHoliday);
        }
        return holidayRateMap;
    }

    public void setCompanyHolidayMap(Date startDate, Date endDate){
        if(String.isBlank(theCompanySetup.Company_Pay_Rule__c)) throw new DataException('Company Pay Rule is not setup!');
        Set<String> companyPaidHolidaySet = new Set<String>();
        for(Pay_Rule_Holiday__c payRuleHoliday:[SELECT Holiday__c, Pay_Code__c FROM Pay_Rule_Holiday__c WHERE Pay_Rule__c = :theCompanySetup.Company_Pay_Rule__c]){
            companyPaidHolidaySet.add(payRuleHoliday.Holiday__c);
            payCodeByCompanyHoliday.put(payRuleHoliday.Holiday__c, payRuleHoliday.Pay_Code__c);
        }

        List<Holiday__c> theHolidayList = [SELECT Name,Date__c,Rate_Type__c, Holiday_Name_Map__c
            FROM Holiday__c
            WHERE Date__c >= :startDate AND Date__c <= :endDate AND Holiday_Name_Map__c != null];
        if(theHolidayList.size() > 0 && companyPaidHolidaySet.size() > 0){
            //if(companyPaidHolidaySet.contains(theHoliday.Holiday__c)) mapCompanyHoliday.put(theHoliday.Date__c, theHoliday);
            for (Holiday__c theHoliday : theHolidayList){
                if(String.isNotBlank(theHoliday.Holiday_Name_Map__c)){
                    List<String> holidayNames = theHoliday.Holiday_Name_Map__c.split(';');
                    for(String holidayName:holidayNames){
                        if(companyPaidHolidaySet.contains(holidayName)){
                            mapCompanyHoliday.put(theHoliday.Date__c, theHoliday);
                            break;
                        }
                    }
                }
            }
        }
    }

    public Set<Id> getTMIds(List<TM_Line__c> theTMLList){
        Set<Id> tmIdSet = new Set<Id>();
        for(TM_Line__c tmLine: theTMLList){
            if(!tmIdSet.contains(tmLine.TM__c)){
                tmIdSet.add(tmLine.TM__c);
            }
        }

        return tmIdSet;
    }

    /*
     *  Ticket#21502 - add blocked filter to Pay Rule Lines.
     *  Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
     *  Ticket#24645 - reverse change made through ticket#23635
     */
    public void setPayRuleMap(Set<Id> payRuleIdSet){
        payRuleIdSet.add(theCompanySetup.Company_Pay_Rule__c);
        List<Pay_Rule__c> payRuleLst = [SELECT Id, Name, Type__c, Pay_Holiday__c, Pay_Travel_Time__c, Travel_Time_Pay_Rate__c,
                Work_Before_or_After_Holiday_to_Qualify__c, Work_x_out_y_days_to_qualify__c, Work_Before_and_After_Holiday_to_Qualify__c, Enable_Dispatch_from_Home_Pay__c,
                Use_Pay_Rule_Line_Detail_for_Hour_Calc__c,
                (SELECT Id, Resource_Type__c, Daily_OT_After_Num_of_Hours__c, Pay_Rule__c,
                        Saturday_Pay_Code__c, Sunday_Pay_Code__c, Overtime_Rate_Multiple__c, Double_Time_Rate_Multiple__c,
                        Rate__c, Before_Time__c, Time_After_Pay_Code__c, After_Time__c, Time_Before_Pay_Code__c,
                        Holiday_with_Double_Time_Pay__c, Holidays_with_Overtime_Pay__c,Fringe__c, OT_Fringe_Amount__c, DT_Fringe_Amount__c,
                        Peak_Season_Sunday_Pay_Code__c, Peak_Season_Start__c, Peak_Season_End__c, Eligible_Holidays__c
                FROM Pay_Rule_Lines__r WHERE Blocked__c != TRUE)
        FROM Pay_Rule__c
        WHERE Id IN :payRuleIdSet];

        Set<Id> payRuleLineIds = new Set<Id>();
        for(Pay_Rule__c pr : payRuleLst){
            mapPayRules.put(pr.Id, pr);
            if(pr.Pay_Rule_Lines__r != null) {
                for (Pay_Rule_Line__c payRuleLine : pr.Pay_Rule_Lines__r) {
                    payRuleLineIds.add(payRuleLine.Id);
                }
            }
        }
        setPayRuleResTypeWithPayRuleLineMap(mapPayRules);
        //Ticket#23635 setPayRuleResTypeWithHolidayMap(mapPayRules);
        setPayRuleResTypeHolidayPayCodeSet(mapPayRules);
        setPayRuleLineDetailMap(payRuleLineIds);
    }

    /*Not needed
    public void setPayRuleHolidayMap(Set<Id> payRuleIdSet){
        List<Pay_Rule_Holiday__c> payRuleHolidayLst = [SELECT Id, Date__c, Pay_Rule__c, Pay_Code__c, Name, Holiday__c
        FROM Pay_Rule_Holiday__c WHERE Pay_Rule__c IN :payRuleIdSet];

        for(Pay_Rule_Holiday__c payRuleHoliday: payRuleHolidayLst){
            mapPayRuleHoliday.put(payRuleHoliday.Pay_Rule__c + ':' + payRuleHoliday.Holiday__c, payRuleHoliday);
        }
    }
     */

    public void setServiceCenter(Id scId) {
        theSC = new Service_Center__c();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Service_Center__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Subsidiary_Company__r.Name';
        strQuery += ' FROM Service_Center__c WHERE Id =: scId LIMIT 1';
        strQuery = String.escapeSingleQuotes(strQuery);
        theSC = Database.query(strQuery);
    }

    public void setServiceCenterByName(String scName){
        theSC = new Service_Center__c();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Service_Center__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Subsidiary_Company__r.Name';
        strQuery += ' FROM Service_Center__c WHERE Name =: scName LIMIT 1';
        strQuery = String.escapeSingleQuotes(strQuery);
        theSC = Database.query(strQuery);

        if(theSC == null){
            throw new DataException('Service Center with Name: ' + scName + ' does not exist.');
        }
    }

    public void setSCLaborResource(Id scId){
        TheScResources = ResourcesSelector.newInstance().selectLaborResourcesByServiceCenter(scId);
    }

    public List<Resource__c> getResourcesByResId(Set<Id> resIdSet){
        if(resIdSet.isEmpty()){
            throw new DataException('Resource Id Set must not be blank!');
        }

        return ResourcesSelector.newInstance().selectLaborResourcesByIds(resIdSet);
    }

    public List<Resource__c> getResourcesByScId(Id scId){
        if(String.isBlank(scId)){
            throw new DataException('Service Center must not be blank!');
        }

        return ResourcesSelector.newInstance().selectLaborResourcesByServiceCenter(scId);
    }

    public void setResMap(List<Resource__c> resLst){
        for(Resource__c laborRes : resLst){
            mapRes.put(laborRes.Id, laborRes);
        }
    }

    /*
     *  Ticket#21502 - add blocked filter to Pay Rule Lines.
     *  Ticket#22782 - add more fields to the pay rule line query.
     *  Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
     *  Ticket#24645 - reverse change made through ticket#23635
     */
    public void setPayRateByPayRuleAndResTypeMap(Set<Id> payRuleIdSet){
        List<Pay_Rule_Line__c> payRuleLineLst = [SELECT Id, Resource_Type__c, Daily_OT_After_Num_of_Hours__c,
                Pay_Rule__c, Saturday_Pay_Code__c, Sunday_Pay_Code__c, Overtime_Rate_Multiple__c,
                Double_Time_Rate_Multiple__c, Rate__c, Before_Time__c, Time_After_Pay_Code__c, After_Time__c, Time_Before_Pay_Code__c,
                Holiday_with_Double_Time_Pay__c, Holidays_with_Overtime_Pay__c,Fringe__c, OT_Fringe_Amount__c, DT_Fringe_Amount__c,
                Peak_Season_Sunday_Pay_Code__c, Peak_Season_Start__c, Peak_Season_End__c, Eligible_Holidays__c
                                                    FROM Pay_Rule_Line__c WHERE Pay_Rule__c IN :payRuleIdSet AND Blocked__c != TRUE];

        for(Pay_Rule_Line__c prl : payRuleLineLst){
            mapPayRateByPayRuleAndResType.put(prl.Pay_Rule__c + ':' + prl.Resource_Type__c, prl.Rate__c);
            payRuleLinesByIds.put(prl.Id, prl); //Ticket#22782
        }
    }

    public Boolean customPayRuleExist(Resource__c res){
        Pay_Rule__c resPayRule = new Pay_Rule__c();
        if(String.isNotBlank(res.Pay_Rule__c)){
            resPayRule = mapPayRules.get(res.Pay_Rule__c);
            if(resPayRule != null) {
                return true;
            }
        }
        return false;
    }

    public Week_Number__c getWeekNumber(Id weekNumberId){
        return [SELECT Id, Name, Week_No__c, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Id =: weekNumberId LIMIT 1];
    }

    public void createTSLinesFromTMLines(Map<Id, Timesheet__c> timesheetsByResIds, List<Timesheet_Line__c> tsLineLst, List<TM_Line__c> theTMLineList, Date startDate, Date endDate){
        // System.debug('Info#Method-createTSLinesFromTMLines begin');
        /*
        Map<Date,Holiday__c> holidayRateMap = new Map<Date,Holiday__c>();
        holidayRateMap = getHolidayMap();
         */
        Timesheet_Line__c theTSL;
        Boolean isSunday;
        Boolean isHoliday;
        Boolean isOverNightShift;
        Datetime scheduleDateTime;

        if (theTMLineList != null && theTMLineList.size() > 0) {
            for (TM_Line__c theTML : theTMLineList) {
                isSunday = false;
                isHoliday = false;
                isOverNightShift = false;
                Integer dayNeeded = 1;
                Integer dayCount = 0;
                Time startTime, endTime;
                Boolean inPayrollPeriod = true;
                Boolean timeFromPrePeriod = false;
                Boolean isPrevailingJob = false;
                Boolean eligibleForDispatchFromHomePay = isEligibleForDispatchFromHomePay(theTML);
                Boolean lunchCaptured = false;
                Boolean isZeroHourJobTimeLine = false; //Ticket#24285
                Boolean identicalJobTimesDetected = false; //Ticket#24285
                if(theTML.TM__r.Sales_Order__r.Pay_Rule__r.Type__c == 'Prevailing Wage') {
                    isPrevailingJob = true;
                }

                //Ticket#25502 >>
                if(tmScheduledDateByTMId.containsKey(theTML.TM__c) == false){
                    tmScheduledDateByTMId.put(theTML.TM__c, theTML.TM__r.Scheduled_Date__c);
                }
                //Ticket#25502 <<

                //Union Travel Time Mod
                Time jobStartTime = theTML.Job_Start_Time__c;
                Time jobEndTime = theTML.Job_End_Time__c;
                if(eligibleForDispatchFromHomePay){
                    jobStartTime = theTML.Site_Start_Time__c;
                    jobEndTime = theTML.Site_End_Time__c;
                }

                //isOverNightShift = TimeUtils.isCorssedMidNight(theTML.Job_Start_Time__c, theTML.Job_End_Time__c);
                isOverNightShift = TimeUtils.isCorssedMidNight(jobStartTime, jobEndTime);
                //Union Travel Time Mod

                scheduleDateTime = TimeUtils.getDatetimeInUserTZ(theTML.TM__r.Scheduled_Date__c);

                if(scheduleDateTime.date() < startDate){
                    if (isOverNightShift){
                        scheduleDateTime = scheduleDateTime.addDays(1);
                        timeFromPrePeriod = true;
                    }
                    else{
                        inPayrollPeriod = false;
                    }
                }

                //Ticket#24285 >>
                //System.debug('Info: theTML ' + theTML.TM__r.Name + ' Line No. ' + theTML.Line_No__c);
                if(theTML.Job_Start_Time__c == theTML.Site_Start_Time__c &&
                        theTML.Site_Start_Time__c == theTML.Site_End_Time__c && theTML.Site_End_Time__c == theTML.Job_End_Time__c){
                    identicalJobTimesDetected = true;
                    if(theTML.Lunch_Start_Time__c == null && theTML.Lunch_End_Time__c == null) {
                        isZeroHourJobTimeLine = true;
                    }
                }
                //System.debug('Info: isZeroHourJobTimeLine ' + isZeroHourJobTimeLine);
                //Ticket#24285 <<

                if (inPayrollPeriod) {
                    //Create two entries for overnight shift but exclude time cross payroll period.
                    if (isOverNightShift && (!timeFromPrePeriod) && (scheduleDateTime.date().addDays(1) <= endDate)) {
                        dayNeeded = 2;
                    }

                    while (dayCount < dayNeeded) {
                        dayCount++;
                        if (dayNeeded == 1) {
                            if(timeFromPrePeriod){
                                startTime = Time.newInstance(24, 0, 0, 0);
                                endTime = jobEndTime;
                            } else {
                                if(isOverNightShift){
                                    startTime = jobStartTime;
                                    endTime = Time.newInstance(24, 0, 0, 0);
                                } else {
                                    startTime = jobStartTime;
                                    endTime = jobEndTime;
                                }
                            }
                        } else {
                            if (dayCount == 1) {
                                startTime = jobStartTime;
                                if (theTML.Site_End_Time__c > jobEndTime && isPrevailingJob == true) {
                                    endTime = theTML.Site_End_Time__c;
                                } else {
                                    endTime = Time.newInstance(24, 0, 0, 0);
                                }
                            }
                        }

                        theTSL = new Timesheet_Line__c();
                        theTSL.Prevailing_Wage_Job__c = isPrevailingJob;

                        if (isPrevailingJob == true) {
                            theTSL.Time_Type__c = 'Prevailing Wage';
                        } else {
                            theTSL.Time_Type__c = 'Job Time';
                        }

                        theTSL.Resource__c = theTML.Resource__c; //Ticket# 13409
                        theTSL.Time_Type_Code__c = theCompanySetup.Standard_Rate__c;

                        theTSL.Scheduled_Date__c = scheduleDateTime.dateGmt(); //Ticket23713

                        theTSL.TM__c = theTML.TM__c;
                        theTSL.Work_as_Resource_Type__c = theTML.Resource_Type__c;

                        theTSL.Week_Day__c = scheduleDateTime.formatGMT('EEEE'); //Ticket#23713

                        Resource__c res = mapRes.get(theTML.Resource__c);

                        if(String.isNotBlank(theTML.TM__r.Sales_Order__r.Pay_Rule__c)){
                            theTSL.Pay_Rule__c = theTML.TM__r.Sales_Order__r.Pay_Rule__c;
                        } else if (String.isNotBlank(res.Pay_Rule__c)){
                            theTSL.Pay_Rule__c = res.Pay_Rule__c;
                        } else {
                            theTSL.Pay_Rule__c = theCompanySetup.Company_Pay_Rule__c;
                        }

                        if (theTML.Overtime__c == true) {
                            theTSL.Time_Type_Code__c = theCompanySetup.Overtime_Rate__c;
                        }
                        theTSL.System_Created_Entry__c = true;
                        theTSL.Sales_Order__c = theTML.TM__r.Sales_Order__c;
                        theTSL.Customer_Name__c = theTML.TM__r.Bill_to_Customer__r.Name;
                        theTSL.T_M_Line__c = theTML.Id;
                        theTSL.Sales_Order_Description__c = theTML.TM__r.Sales_Order__r.CMR_Description__c;
                        theTSL.Sales_Order_Type__c = theTML.TM__r.Sales_Order__r.Sales_Order_Type__c;
                        theTSL.Sales_Order_Service_Center__c = theTML.TM__r.Service_Center__c;
                        theTSL.Work_as_Resource_Type__c = theTML.Resource_Type__c;
                        theTSL.Timesheet__c = timesheetsByResIds.get(theTML.Resource__c).Id;

                        theTSL.Start_Time__c = startTime;
                        theTSL.End_Time__c = endTime;
                        //Lunch capture on day 1 entry and ignore time from previous payroll period
                        if(theTML.Lunch_Start_Time__c >= theTSL.Start_Time__c && lunchCaptured == false) {
                            if(theTSL.End_Time__c == TimeUtils.midNight()){
                                //ticket 20586 <<
                                if (theTML.Lunch_End_Time__c == null) {
                                    throw new DataException('TM line ' + theTML.Id + ' cannot have blank lunch end time.');
                                }
                                //ticket 20586 >>
                                if(theTML.Lunch_End_Time__c.addSeconds(-1) <= theTSL.End_Time__c.addSeconds(-1)){
                                    theTSL.Lunch_Start_Time__c = theTML.Lunch_Start_Time__c;
                                    theTSL.Lunch_End_Time__c = theTML.Lunch_End_Time__c;
                                    //theTSL.Lunch_Hours__c = TMMgmt.calculateLunchHours(theTML.Lunch__c);
                                    theTSL.Lunch_Hours__c = TimeUtils.calculateHours(theTSL.Lunch_Start_Time__c, theTSL.Lunch_End_Time__c);
                                    lunchCaptured = true;
                                }
                            } else if(theTML.Lunch_End_Time__c <= theTSL.End_Time__c){
                                theTSL.Lunch_Start_Time__c = theTML.Lunch_Start_Time__c;
                                theTSL.Lunch_End_Time__c = theTML.Lunch_End_Time__c;
                                //theTSL.Lunch_Hours__c = TMMgmt.calculateLunchHours(theTML.Lunch__c);
                                theTSL.Lunch_Hours__c = TimeUtils.calculateHours(theTSL.Lunch_Start_Time__c, theTSL.Lunch_End_Time__c);
                                lunchCaptured = true;
                            }
                        }

                        Boolean isSecondDay = dayCount == 2;
                        unionLaobrProcessor(tsLineLst, theTML, theTSL, isOverNightShift, isSecondDay);

                        theTSL.Total_Hours__c = TimeUtils.calculateHours(theTSL.Start_Time__c, theTSL.End_Time__c);
                        theTSL.Net_Hours__c = CompanyMgmt.zeroIfNull(theTSL.Total_Hours__c) - CompanyMgmt.zeroIfNull(theTSL.Lunch_Hours__c);

                        theTSL.Timesheet__c = timesheetsByResIds.get(theTML.Resource__c).Id;
                        //Ticket#24285 >>
                        if(isZeroHourJobTimeLine == true){
                            theTSL.Start_Time__c = null;
                            theTSL.End_Time__c = null;
                            theTSL.Total_Hours__c = 0;
                            theTSL.Net_Hours__c = 0;
                            tsLineLst.add(theTSL);
                            break;
                        }
                        //Ticket#24285 <<
                        if ((isPrevailingJob || Test.isRunningTest()) && eligibleForDispatchFromHomePay == false) {
                            //Ticket#13838 >>
                            Decimal toSiteTime = 0;
                            Decimal fromSiteTime = 0;
                            if(theTML.Job_Start_Time__c != theTML.Site_Start_Time__c){
                                toSiteTime = TimeUtils.calculateHours(theTML.Job_Start_Time__c, theTML.Site_Start_Time__c);
                            }

                            if(theTML.Site_End_Time__c != theTML.Job_End_Time__c){
                                fromSiteTime = TimeUtils.calculateHours(theTML.Site_End_Time__c, theTML.Job_End_Time__c);
                            }
                            //Ticket#13838 <<


                            //Ticket#24029 >>
                            //if ((toSiteTime > 0) && (!timeFromPrePeriod) && dayCount == 1) {
                            if ((toSiteTime > 0) && dayCount == 1) {
                                Time travelTimeStart = theTML.Job_Start_Time__c;
                                Time travelTimeEnd = theTML.Site_Start_Time__c;
                                if(timeFromPrePeriod && travelTimeStart > travelTimeEnd){
                                    travelTimeStart = TimeUtils.midNight();
                                    toSiteTime = TimeUtils.calculateHours(travelTimeStart, travelTimeEnd);
                                }
                            //Ticket#24029 <<

                                Timesheet_Line__c theTSL2 = createSysCalcLine(theTSL,
                                        travelTimeStart,
                                        travelTimeEnd,
                                        toSiteTime,
                                        'Travel Time',
                                        theCompanySetup.Standard_Rate__c);

                                if(CompanyMgmt.zeroIfNull(theTSL.Lunch_Hours__c) != 0){
                                    if(theTSL2.Start_Time__c <= theTSL.Lunch_Start_Time__c && theTSL.Lunch_Start_Time__c <= theTSL2.End_Time__c){
                                        //move lunch time to travel to site time
                                        theTSL2.Lunch_Start_Time__c = theTSL.Lunch_Start_Time__c;
                                        theTSL2.Lunch_End_Time__c = theTSL.Lunch_End_Time__c;
                                        theTSL2.Lunch_Hours__c = theTSL.Lunch_Hours__c;
                                        theTSL2.Net_Hours__c = theTSL2.Total_Hours__c - theTSL2.Lunch_Hours__c;
                                        theTSL.Lunch_Hours__c = 0;
                                        theTSL.Net_Hours__c = theTSL.Total_Hours__c - theTSL.Lunch_Hours__c;
                                        theTSL.Lunch_Start_Time__c = null;
                                        theTSL.Lunch_End_Time__c = null;
                                    }
                                }
                                startTime = theTML.Site_Start_Time__c;
                                tsLineLst.add(theTSL2);

                                //Day one travel time only
                                if(theTML.Site_Start_Time__c < theTML.Job_Start_Time__c && !timeFromPrePeriod){
                                    scheduleDateTime = scheduleDateTime.addDays(1);
                                    endTime = theTML.Job_End_Time__c;
                                    continue;
                                }
                            }

                            if ((fromSiteTime > 0) && (!isOverNightShift || dayCount == 2 || timeFromPrePeriod)){
                                Time travelTimeStart = theTML.Site_End_Time__c;
                                Time travelTimeEnd = theTML.Job_End_Time__c;
                                if(timeFromPrePeriod && travelTimeStart > travelTimeEnd){
                                    travelTimeStart = TimeUtils.midNight();
                                    fromSiteTime = TimeUtils.calculateHours(travelTimeStart, travelTimeEnd);
                                }
                                Timesheet_Line__c theTSL2 = createSysCalcLine(theTSL,
                                        travelTimeStart,
                                        travelTimeEnd,
                                        fromSiteTime,
                                        'Travel Time',
                                        theCompanySetup.Standard_Rate__c);

                                //Ticket#25502 >>
                                if(timeFromPrePeriod != true && theTML.Site_End_Time__c > theTML.Job_End_Time__c){
                                    theTSL2.Scheduled_Date__c = tmScheduledDateByTMId.get(theTML.TM__c);
                                }
                                //Ticket#25502 <<

                                if(CompanyMgmt.zeroIfNull(theTSL.Lunch_Hours__c) != 0){
                                    if(theTSL2.Start_Time__c <= theTSL.Lunch_Start_Time__c && theTSL.Lunch_Start_Time__c <= theTSL2.End_Time__c){
                                        //move lunch time to travel to site time
                                        theTSL2.Lunch_Start_Time__c = theTSL.Lunch_Start_Time__c;
                                        theTSL2.Lunch_End_Time__c = theTSL.Lunch_End_Time__c;
                                        theTSL2.Lunch_Hours__c = theTSL.Lunch_Hours__c;
                                        theTSL2.Net_Hours__c = theTSL2.Total_Hours__c - theTSL2.Lunch_Hours__c;
                                        theTSL.Lunch_Hours__c = 0;
                                        theTSL.Net_Hours__c = theTSL.Total_Hours__c - theTSL.Lunch_Hours__c;
                                        theTSL.Lunch_Start_Time__c = null;
                                        theTSL.Lunch_End_Time__c = null;
                                    }
                                }
                                tsLineLst.add(theTSL2);

                                //update end time
                                endTime = theTML.Site_End_Time__c;
                            }

                            if (!isOverNightShift) {
                                /*Ticket#24029 >>
                                theTSL.Net_Hours__c = theTSL.Net_Hours__c - toSiteTime - fromSiteTime;
                                theTSL.Total_Hours__c = theTSL.Total_Hours__c - toSiteTime - fromSiteTime;
                                 */
                                theTSL.Start_Time__c = theTML.Site_Start_Time__c;
                                theTSL.End_Time__c = theTML.Site_End_Time__c;
                                //Ticket#24029 >>
                                theTSL.Total_Hours__c = TimeUtils.calculateHours(theTSL.Start_Time__c, theTSL.End_Time__c);
                                theTSL.Net_Hours__c = CompanyMgmt.zeroIfNull(theTSL.Total_Hours__c) - CompanyMgmt.zeroIfNull(theTSL.Lunch_Hours__c);
                                //Ticket#24029 <<
                                //System.debug('Info: theTSL 4 ' + theTSL.Start_Time__c + ' -- ' + theTSL.End_Time__c + ' --Net: ' + theTSL.Net_Hours__c + ' ---Daily OT: ' + theTSL.Daily_OT_After_Number_of_Hrs__c);
                            } else {
                                /* Ticket#24029
                                if (dayCount == 1) {
                                    if (timeFromPrePeriod){
                                        theTSL.Net_Hours__c = theTSL.Net_Hours__c - fromSiteTime;
                                        theTSL.Total_Hours__c = theTSL.Total_Hours__c - fromSiteTime;
                                    } else {
                                        theTSL.Net_Hours__c = theTSL.Net_Hours__c - toSiteTime;
                                        theTSL.Total_Hours__c = theTSL.Total_Hours__c - toSiteTime;
                                    }
                                } else if (dayCount == 2) {
                                    theTSL.Net_Hours__c = theTSL.Net_Hours__c - fromSiteTime;
                                    theTSL.Total_Hours__c = theTSL.Total_Hours__c - fromSiteTime;
                                }
                                 */

                                theTSL.Start_Time__c = startTime;
                                theTSL.End_Time__c = endTime;
                                //Ticket#24029 >>
                                theTSL.Total_Hours__c = TimeUtils.calculateHours(theTSL.Start_Time__c, theTSL.End_Time__c);
                                theTSL.Net_Hours__c = CompanyMgmt.zeroIfNull(theTSL.Total_Hours__c) - CompanyMgmt.zeroIfNull(theTSL.Lunch_Hours__c);
                                //Ticket#24029 <<
                                if(dayCount == 2 && theTML.Site_End_Time__c > theTML.Job_End_Time__c) {
                                    theTSL = new Timesheet_Line__c();
                                }
                            }
                        } else {
                            if(dayCount == 1){
                                unionTravelTimeProcessor(tsLineLst, theTML, theTSL);
                            }
                        }

                        if ((dayCount == 1) && (isOverNightShift) && (!timeFromPrePeriod)) {
                            scheduleDateTime = scheduleDateTime.addDays(1);
                            startTime = endTime;
                            //endTime = theTML.Job_End_Time__c;
                            endTime = jobEndTime;
                        }

                        if(theTSL.Timesheet__c != null && theTSL.Total_Hours__c > 0) {
                            /* Ticket#19411
                            Boolean insertRecord = true;
                            if(res.Pay_Rule__r.Type__c == 'Union' && theTSL.Start_Time__c == TimeUtils.midNight() && theTSL.End_Time__c == TimeUtils.midNight()){
                                insertRecord = false;
                            }
                            if(insertRecord){
                                tsLineLst.add(theTSL);
                            }
                             */

                            Boolean insertTSLine = true; //Ticket#25080
                            if(identicalJobTimesDetected == false) { //Ticket#24285
                                if(isPrevailingJob == true) {
                                    //Ticket#24268 Travel time only, so ignore PW site/job time entry
                                    if (((theTML.Job_Start_Time__c == theTML.Site_Start_Time__c && theTML.Site_Start_Time__c == theTML.Site_End_Time__c) ||
                                            (theTML.Site_Start_Time__c == theTML.Site_End_Time__c && theTML.Site_End_Time__c == theTML.Job_End_Time__c)))
                                    {
                                        insertTSLine = false;
                                    }
                                    //Ticket#25080 - Site are equal, zero site time.>>
                                    if(theTML.Site_Start_Time__c == theTML.Site_End_Time__c){
                                        insertTSLine = false;
                                    }
                                    //Ticket#25080 <<
                                }
                            }

                            if(insertTSLine == true){ //Ticket#25080
                                tsLineLst.add(theTSL);
                            }
                        }

                        if(scheduleDateTime.date() > endDate) {
                            break;
                        }
                    }
                }
            }
        }
        //System.debug('Info#Method-createTSLinesFromTMLines end');
    }

    //Ticket#13763 - updated
    public void createTSLinesFromResOffTable(Map<Id, Timesheet__c> timesheetsByResIds, List<Timesheet_Line__c> tsLineLst, Date startDate, Date endDate){
        Timesheet_Line__c theTSL;
        List<Resource_Off__c> theResourceOffList;

        theResourceOffList = getResOffList(timesheetsByResIds.keySet(), startDate.addDays(-1), endDate);

        // handles scenario where timesheet is manually created
        if(timesheetsByResIds != null && timesheetsByResIds.size() == 1) {
            theResourceOffList = getResOffList(timesheetsByResIds.keySet(), startDate, endDate);
        }
        
        if (theResourceOffList != null && theResourceOffList.size() > 0) {
            for (Resource_Off__c theResourceOff : theResourceOffList) {
                //if (theResourceOff.Off_Type__r.Name != 'No Work Available' && theResourceOff.Off_Type__r.Name != 'DOT Reset' && theResourceOff.Off_Type__r.Name != 'Unavailable') {
                if (theResourceOff.Off_Type__r.Name != 'No Work Available' && theResourceOff.Off_Type__r.Name != 'DOT Reset' && theResourceOff.Off_Type__r.Name != 'Unpaid Time Off') {
                    Time startTime = null;
                    Time endTime = null;
                    Date offDate = theResourceOff.Date__c;
                    Integer entryNeeded = 1;
                    //handle times that cross day from previous payroll period
                    if(offDate < startDate && !(theResourceOff.End_Time__c > theResourceOff.Start_Time__c) && theResourceOff.End_Time__c != Time.newInstance(0,0,0,0)){ //Ticket#13838
                        offDate = offDate.addDays(1);
                        startTime = Time.newInstance(0,0,0,0);
                        endTime = theResourceOff.End_Time__c;
                    } else if (offDate == endDate && !(theResourceOff.End_Time__c > theResourceOff.Start_Time__c) && theResourceOff.End_Time__c != Time.newInstance(0,0,0,0)){ //Ticket#13838
                        //handle time that span to next payroll period
                        startTime = theResourceOff.Start_Time__c;
                        endTime = Time.newInstance(0,0,0,0);
                    } else if (offDate >= startDate.addDays(-1)){
                        startTime = theResourceOff.Start_Time__c;
                        endTime = theResourceOff.End_Time__c;
                    }

                    if(startTime != null && endTime != null){
                        if(!(endTime > startTime) && endTime != Time.newInstance(0,0,0,0)) {
                            entryNeeded = 2;
                        }

                        Integer entryCount = 0;

                        while(entryCount < entryNeeded) {
                            entryCount += 1;
                            theTSL = new Timesheet_Line__c();
                            theTSL.Time_Type__c = theResourceOff.Off_Type__r.Map_to_Time_Type__c;
                            theTSL.Resource__c = theResourceOff.Resource__c;
                            //Ticket#19834 >>
                            if (String.isNotBlank(theResourceOff.Work_as_Resource_Type__c)) {
                                theTSL.Work_as_Resource_Type__c = theResourceOff.Work_as_Resource_Type__c;
                            } else {
                                theTSL.Work_as_Resource_Type__c = theResourceOff.Resource__r.Resource_Type__c;
                            }
                            //Ticket#19834 >>
                            theTSL.Time_Type_Code__c = theResourceOff.Off_Type__r.Map_Time_Rate_Code__c;
                            theTSL.Resource_Off__c = theResourceOff.Id;
                            theTSL.Sales_Order_Service_Center__c = theSC.Id;
                            theTSL.Job_Description__c = theResourceOff.Shop_Time_Category__c;

                            if(entryCount == 1 && entryNeeded == 1){
                                theTSL.Start_Time__c = startTime;
                                theTSL.End_Time__c = endTime;
                            } else if (entryNeeded == 2 && entryCount == 1){
                                theTSL.Start_Time__c = startTime;
                                theTSL.End_Time__c = Time.newInstance(0,0,0,0);
                            } else if (entryNeeded == 2 && entryCount == 2){
                                theTSL.Start_Time__c = Time.newInstance(0,0,0,0);
                                theTSL.End_Time__c = endTime;
                            }

                            theTSL.Scheduled_Date__c = offDate;
                            Datetime scheduleDateTime;
                            scheduleDateTime = TimeUtils.getDatetimeInUserTZ(offDate);
                            theTSL.Week_Day__c = scheduleDateTime.format('EEEE');

                            theTSL.Total_Hours__c = TimeUtils.calculateHours(theTSL.Start_Time__c, theTSL.End_Time__c);
                            theTSL.Net_Hours__c = theTSL.Total_Hours__c;

                            if(theTSL.Time_Type__c == 'Shop Time'){
                                if(theResourceOff.Service_Center__c != null){
                                    theTSL.Sales_Order_Service_Center__c = theResourceOff.Service_Center__c;
                                    theTSL.Sales_Order__c = theResourceOff.Service_Center__r.Shop_Time_Sales_Order__c;
                                } else {
                                    theTSL.Sales_Order__c = theSC.Shop_Time_Sales_Order__c;
                                }

                                theTSL.Lunch_Start_Time__c = theResourceOff.Lunch_Start_Time__c;
                                theTSL.Lunch_End_Time__c = theResourceOff.Lunch_End_Time__c;
                                theTSL = allocateLunchHour(theTSL);
                                theTSL.Net_Hours__c = CompanyMgmt.zeroIfNull(theTSL.Total_Hours__c) - CompanyMgmt.zeroIfNull(theTSL.Lunch_Hours__c);
                            }

                            if (String.isNotBlank(theResourceOff.Pay_Rule__c) && theTSL.Time_Type_Code__c == 'HOL') {
                                theTSL.Pay_Rule__c = theResourceOff.Pay_Rule__c;
                            }
                            else if(String.isNotBlank(theResourceOff.Resource__r.Pay_Rule__c)) {
                                theTSL.Pay_Rule__c = theResourceOff.Resource__r.Pay_Rule__c;
                            } else {
                                theTSL.Pay_Rule__c = theCompanySetup.Company_Pay_Rule__c;
                            }

                            theTSL.System_Created_Entry__c = true;
                            theTSL.Timesheet__c = timesheetsByResIds.get(theResourceOff.Resource__c).Id;
                            Date tsStartingDate = timesheetsByResIds.get(theResourceOff.Resource__c).Starting_Date__c;
                            Date tsEndingDate = timesheetsByResIds.get(theResourceOff.Resource__c).Ending_Date__c;

                            if(theTSL.Scheduled_Date__c >= tsStartingDate && theTSL.Scheduled_Date__c <= tsEndingDate) {
                                tsLineLst.add(theTSL);
                            }
                            offDate = offDate.addDays(1);
                        }
                    }
                }

                //Ticket#23713 >>
                if(theResourceOff.Off_Type__r.Map_to_Time_Type__c == 'Shop Time' &&
                        theResourceOff.Flat_Rate_Type__c != null &&
                        CompanyMgmt.zeroIfNull(theResourceOff.Flat_Pay_Rate__c) > 1){
                    Timesheet_Line__c newTimesheetLine = new Timesheet_Line__c();
                    newTimesheetLine.Timesheet__c = timesheetsByResIds.get(theResourceOff.Resource__c).Id;
                    newTimesheetLine.Time_Type__c = 'Flat Pay';
                    newTimesheetLine.Resource__c = theResourceOff.Resource__c;
                    newTimesheetLine.Time_Type_Code__c = theResourceOff.Flat_Rate_Type__c;
                    newTimesheetLine.Rate__c = theResourceOff.Flat_Pay_Rate__c;
                    newTimesheetLine.Scheduled_Date__c = theResourceOff.Date__c;
                    if(theResourceOff.Service_Center__c != null){
                        newTimesheetLine.Sales_Order_Service_Center__c = theResourceOff.Service_Center__c;
                        newTimesheetLine.Sales_Order__c = theResourceOff.Service_Center__r.Shop_Time_Sales_Order__c;
                    } else {
                        newTimesheetLine.Sales_Order__c = theSC.Shop_Time_Sales_Order__c;
                    }
                    Datetime scheduleDateTime = TimesheetMgmt.getDatetimeInUserTZ(newTimesheetLine.Scheduled_Date__c);
                    newTimesheetLine.Week_Day__c = scheduleDateTime.format('EEEE');
                    newTimesheetLine.Net_Hours__c = 0;
                    newTimesheetLine.System_Created_Entry__c = true;
                    newTimesheetLine.Timesheet__c = timesheetsByResIds.get(theResourceOff.Resource__c).Id;
                    Date tsStartingDate = timesheetsByResIds.get(theResourceOff.Resource__c).Starting_Date__c;
                    Date tsEndingDate = timesheetsByResIds.get(theResourceOff.Resource__c).Ending_Date__c;
                    if(newTimesheetLine.Scheduled_Date__c >= tsStartingDate && newTimesheetLine.Scheduled_Date__c <= tsEndingDate) {
                        tsLineLst.add(newTimesheetLine);
                    }
                }
                //Ticket#23713 <<
            }
        }
    }

    public Timesheet__c refreshTimesheet(Timesheet__c theTS, List<Timesheet_Line__c> theTSLineLst){
        if (theTS.Resource__r.Pay_Rule__r.Mon_Sun_Work_Week__c == true) {
            theTS.Starting_Date__c = theTS.Week_No__r.Week_Start_Date__c;
            theTS.Ending_Date__c = theTS.Week_No__r.Week_End_Date__c;
        } else {
            theTS.Starting_Date__c = theTS.Week_No__r.Week_Start_Date__c.addDays(-1);
            theTS.Ending_Date__c = theTS.Week_No__r.Week_End_Date__c.addDays(-1);
        }
        update theTS;
        // System.debug('Info: Method Name: refreshTimesheet');
        this.setServiceCenter(theTS.Service_Center__c);
        //Ticket#15509 >>
        //List<Resource__c> resLst = this.getResourcesByResId(new Set<Id>{theTS.Resource__c});
        List<Resource__c> resLst = ResourcesSelector.newInstance().selectPayrollEmployeeByIdsByActivityDate(new Set<Id>{theTS.Resource__c}, theTS.Starting_Date__c);
        //Ticket#15509 <<
        this.setResMap(resLst);

        Map<Id, Timesheet__c> timesheetsByResIds = new Map<Id, Timesheet__c>();

        timesheetsByResIds.put(theTS.Resource__c, theTS);
        theTSLineLst = this.deleteTimesheetLine(theTSLineLst);
        this.deleteHolidayResOff(timesheetsByResIds.keySet(), theTS.Starting_Date__c, theTS.Ending_Date__c);

        List<TM_Line__c> theTMLineList = new List<TM_Line__c>();
        theTMLineList = this.getTMLineList(theTS.Starting_Date__c.addDays(-1), theTS.Ending_Date__c, new Set<Id>{theTS.Resource__c});

        setTMLineByIdsMap(theTMLineList);
        setResourceFieldActivityLogMap(tmLinesByIds.keySet());

        if(String.isNotBlank(mapRes.get(theTS.Resource__c).Pay_Rule__c)){
            Set<Id> payRuleIdSet = new Set<Id>{mapRes.get(theTS.Resource__c).Pay_Rule__c};
            this.setPayRuleMap(payRuleIdSet);
            //this.setPayRuleHolidayMap(payRuleIdSet);
            this.setPayRateByPayRuleAndResTypeMap(payRuleIdSet);
        }
        this.setResourceHolidayTaken(new Set<Id>{theTS.Resource__c}, theTS.Starting_Date__c, theTS.Ending_Date__c);
        this.createTSLinesFromTMLines(timesheetsByResIds, theTSLineLst, theTMLineList, theTS.Starting_Date__c, theTS.Ending_Date__c);
        this.processOvernightTravelTime(theTSLineLst, theTS.Ending_Date__c); //Ticket#24029
        //System.debug('Info: 2 theTSLineLst size ' + theTSLineLst.size());
        this.assignHolidays(timesheetsByResIds, theTSLineLst, theTS.Starting_Date__c, theTS.Ending_Date__c);
        this.assignPayruleHolidays(timesheetsByResIds, theTSLineLst, theTS.Starting_Date__c, theTS.Ending_Date__c);
        this.createTSLinesFromResOffTable(timesheetsByResIds, theTSLineLst, theTS.Starting_Date__c, theTS.Ending_Date__c);
        this.assignHolidayPayCode(theTSLineLst);
        this.processTimesheetLineWithPayRule(theTSLineLst);
        //this.processTimesheetWithPayRuleLineDetails(theTSLineLst); //Ticket#22944
        this.processTimesheetWithPayRuleLineDetails2(theTSLineLst); //Ticket#23239
        this.finalizeTimesheet(theTSLineLst);
        this.checkTimesheetLineTimeOverlap(theTSLineLst);
        this.assignPayRate(theTSLineLst);
        this.createFlatPayLines(timesheetsByResIds, theTSLineLst, this.getTMIds(theTMLineList));

        if (theTSLineLst != null && theTSLineLst.size() > 0) {
            insert theTSLineLst;
            theTS.Status__c = 'Open';
            update theTS;
        }
        return theTS;
    }

    public void assignHolidays(Map<Id, Timesheet__c> timesheetsByResIds, List<Timesheet_Line__c> tsLineLst, Date startDate, Date endDate){
        //System.debug('Info: assignHolidays begin >>>');
        setCompanyHolidayMap(startDate, endDate);
        setResNonPTODateMap(startDate, endDate);
        List<Resource_Off__c> resourceOffLst = new List<Resource_Off__c>();

        //Ticket#20185
        //List<TM_Line__c> tmLines = getTMLineList(startDate.addDays(-3), endDate.addDays(1), timesheetsByResIds.keySet());
        List<TM_Line__c> tmLines = getTMLineList(startDate.addDays(-4), endDate.addDays(1), timesheetsByResIds.keySet());
        //Ticket#20185
        Set<String> resWorkDateSet = new Set<String>();
        //Map<Id, List<Date>> resPTOSickDaysByResIds = new Map<Id, List<Date>>();
        for(TM_Line__c tmLine:tmLines){
            resWorkDateSet.add(tmLine.Resource__c + ':' + tmLine.TM__r.Scheduled_Date__c);

            //Union Travel Time Mod
            Time jobStartTime = tmLine.Job_Start_Time__c;
            Time jobEndTime = tmLine.Job_End_Time__c;
            if(isEligibleForDispatchFromHomePay(tmLine)){
                jobStartTime = tmLine.Site_Start_Time__c;
                jobEndTime = tmLine.Site_End_Time__c;
            }

            if(jobStartTime != null && jobEndTime != null && jobStartTime >= jobEndTime && jobEndTime != TimeUtils.midNight()){
                resWorkDateSet.add(tmLine.Resource__c + ':' + tmLine.TM__r.Scheduled_Date__c.addDays(1));
            }
            /*
            if(tmLine.Job_Start_Time__c != null && tmLine.Job_End_Time__c != null && tmLine.Job_Start_Time__c >= tmLine.Job_End_Time__c && tmLine.Job_End_Time__c != TimeUtils.midNight()){
                resWorkDateSet.add(tmLine.Resource__c + ':' + tmLine.TM__r.Scheduled_Date__c.addDays(1));
            }
             */
            //Union Travel Time Mod
        }

        List<Resource_Off__c> paidOffDays = getResOffList(timesheetsByResIds.keySet(), startDate.addDays(-3), endDate.addDays(1));
        for(Resource_Off__c paidOffDay:paidOffDays){
            if(paidOffDay.PTO_Type__c != 'PTO-Sick'){
                resWorkDateSet.add(paidOffDay.Resource__c + ':' + paidOffDay.Date__c);
                /*
                if(paidOffDay.Off_Type__r.Name != 'Unavailable'){
                    resWorkDateSet.add(paidOffDay.Resource__c + ':' + paidOffDay.Date__c);
                } else if(paidOffDay.Off_Type__r.Name == 'Unavailable' && paidOffDay.Unavailable_Reason__c == 'Unpaid Time Off'){
                    resWorkDateSet.add(paidOffDay.Resource__c + ':' + paidOffDay.Date__c);
                }
                 */
            }
        }

        /*
        System.debug('Info: mapCompanyHoliday: ' + mapCompanyHoliday);
        System.debug('Info: resWorkDateSet: ' + resWorkDateSet);
         */

        if(mapCompanyHoliday.size() > 0){
            Off_Type__c holidayOffType = [SELECT Id FROM Off_Type__c WHERE Name = 'Holiday' LIMIT 1];
            for(Date holidayDate : mapCompanyHoliday.keySet()){
                Holiday__c holiday = mapCompanyHoliday.get(holidayDate);
                for(Id resId : timesheetsByResIds.keySet()){
                    Resource__c res = mapRes.get(resId);
                    if(!resHolidayPayDateSet.contains(res.Id + ':' + holidayDate) &&
                            isQualifyForCompanyHoliday(res, holidayDate, resWorkDateSet, startDate, endDate) == true){

                        if(!resHolidayTakenSet.contains(res.Id + ':' + holidayDate)){
                            Resource_Off__c resOff = new Resource_Off__c();
                            resOff.Off_Type__c = holidayOffType.Id;
                            resOff.Service_Center__c = res.Service_Center__c;
                            resOff.Resource_Service_Center__c = res.Service_Center__c;
                            resOff.Resource__c = res.Id;
                            resOff.Work_as_Resource_Type__c = res.Resource_Type__c; //Tikcet#19834
                            resOff.Date__c = holidayDate;
                            resOff.Description__c = holiday.Name;
                            resOff.Start_Time__c = Time.newInstance(6,0,0,0);
                            resOff.End_Time__c = Time.newInstance(14,0,0,0);
                            resOff.Total_Hours__c = 8;
                            resOff.Hours__c = 8;
                            resOff.Pay_Rule__c = theCompanySetup.Company_Pay_Rule__c;
                            resOff.System_Created_Entry__c = true;
                            resourceOffLst.add(resOff);
                        }
                        resHolidayPayDateSet.add(res.Id + ':' + holidayDate);
                    }
                }
            }
            if(resourceOffLst.size() > 0) insert resourceOffLst;
        }
    }

    public void assignPayruleHolidays(Map<Id, Timesheet__c> timesheetsByResIds, List<Timesheet_Line__c> tsLineLst, Date startDate, Date endDate){
        //System.debug('Info: ###assignPayruleHolidays begin###');
        Set<Id> payRuleSet = new Set<Id>();
        Set<Id> resIdSet = new Set<Id>();
        Set<String> resWorkDateSet = new Set<String>();
        Set<String> resPWJobWorkDate = new Set<String>();
        Set<String> payRuleAndResType = new Set<String>();
        List<Resource_Off__c> resourceOffLst = new List<Resource_Off__c>();
        Integer minDaysWorkNeeded = 0;
        Integer numOfDayToIncludedInTheCount = 0;

        //union holiday
        for(Id resId : timesheetsByResIds.keySet()){
            if(mapRes.get(resId).Pay_Rule__c != null){
                Resource__c res = mapRes.get(resId);
                payRuleSet.add(res.Pay_Rule__c);
                payRuleAndResType.add(res.Pay_Rule__c + ':' + res.Resource_Type__c);
                Pay_Rule__c payRule = mapPayRules.get(res.Pay_Rule__c);
                if(payRule.Pay_Holiday__c == true && String.isNotBlank(payRule.Work_x_Out_y_Days_to_Qualify__c)){
                    try{
                        payRuleWorkDaysNeededMap.put(payRule.Id, payRule.Work_x_Out_y_Days_to_Qualify__c);
                        List<String> ruleInputs = payRule.Work_x_Out_y_Days_to_Qualify__c.split('|');
                        if(Integer.valueOf(ruleInputs[0]) > minDaysWorkNeeded) {
                            minDaysWorkNeeded = Integer.valueOf(ruleInputs[0]);
                        }
                        if(Integer.valueOf(ruleInputs[2]) > numOfDayToIncludedInTheCount) {
                            numOfDayToIncludedInTheCount = Integer.valueOf(ruleInputs[2]);
                        }
                    } catch (Exception e){
                        throw e;
                    }
                }
            }
        }

        //pw holiday
        for(Timesheet_Line__c tsLine:tsLineLst){
            //Resource__c res = mapRes.get(tsLine.Resource__c);
            if(tsLine.Pay_Rule__c != null){
                payRuleSet.add(tsLine.Pay_Rule__c);
                //Ticket#19843 >>
                //payRuleAndResType.add(tsLine.Pay_Rule__c + ':' + res.Resource_Type__c);
                payRuleAndResType.add(tsLine.Pay_Rule__c + ':' + tsLine.Work_as_Resource_Type__c);
                //Ticket#19843 >>
            }
        }

        //Ticket#20185
        //Date tmStartDate = numOfDayToIncludedInTheCount > 0 ? TimeUtils.addDaysWithOutWeekend(startDate, numOfDayToIncludedInTheCount, true):startDate.addDays(-3);
        Date tmStartDate = numOfDayToIncludedInTheCount > 0 ? TimeUtils.addDaysWithOutWeekend(startDate, numOfDayToIncludedInTheCount, true):startDate.addDays(-4);
        //Ticket#20185
        Date tmEndDate = endDate.addDays(1);

        setPayRuleMap(payRuleSet);

        if(payRuleAndResType.size() > 0) {
            setPayRuleHolidayDateMap(startDate, endDate, payRuleAndResType);
        }
        if(mapPayRuleHolidayDate.size() > 0){
            //union payrule
            for (Id resId : timesheetsByResIds.keySet()) {
                Resource__c res = mapRes.get(resId);
                if (res.Pay_Rule__c != null && mapPayRuleHolidayDate.containsKey(res.Pay_Rule__c + ':' + res.Resource_Type__c)
                        && mapPayRules.get(res.Pay_Rule__c).Pay_Holiday__c == true){
                    resIdSet.add(res.Id);
                }
            }

            //pw payrule
            for(Timesheet_Line__c tsLine:tsLineLst){
                //Resource__c res = mapRes.get(tsLine.Resource__c);
                //mapPayRuleHolidayDate.containsKey(tsLine.Pay_Rule__c + ':' + res.Resource_Type__c) && //Ticket#19843 >>
                if(tsLine.Pay_Rule__c != null &&
                        mapPayRuleHolidayDate.containsKey(tsLine.Pay_Rule__c + ':' + tsLine.Work_as_Resource_Type__c) &&
                        mapPayRules.get(tsLine.Pay_Rule__c).Pay_Holiday__c == true)
                // Ticket#23635&& mapPayRules.get(tsLine.Pay_Rule__c).Type__c == 'Prevailing Wage'){
                {
                    resIdSet.add(tsLine.Resource__c);
                }
            }
        }

        List<TM_Line__c> tmLineLst = getTMLineList(tmStartDate, tmEndDate, resIdSet);
        for(TM_Line__c tml:tmLineLst){
            resWorkDateSet.add(tml.Resource__c + ':' + tml.TM__r.Scheduled_Date__c);

            //Union Travel Time mod
            Time jobStartTime = tml.Job_Start_Time__c;
            Time jobEndTime = tml.Job_End_Time__c;
            if(isEligibleForDispatchFromHomePay(tml) == true){
                jobStartTime = tml.Site_Start_Time__c;
                jobEndTime = tml.Site_End_Time__c;
            }
            //Union Travel Time mod
            if(jobStartTime != null && jobEndTime != null && jobStartTime >= jobEndTime && jobEndTime != TimeUtils.midNight()){
                resWorkDateSet.add(tml.Resource__c + ':' + tml.TM__r.Scheduled_Date__c.addDays(1));
            }
            if(tml.TM__r.Sales_Order__r.Pay_Rule__r.Type__c == 'Prevailing Wage'){
                Decimal travelTime = 0;
                Decimal netWorkHrs = 0;
                Decimal lunchHour = TimeUtils.calculateHours(tml.Lunch_Start_Time__c, tml.Lunch_End_Time__c);
                netWorkHrs = TimeUtils.calculateHours(jobStartTime, jobEndTime) - lunchHour;
                if(jobStartTime != tml.Site_Start_Time__c){
                    travelTime += TimeUtils.calculateHours(jobStartTime, tml.Site_Start_Time__c);
                }

                if(tml.Site_End_Time__c != jobEndTime){
                    travelTime += TimeUtils.calculateHours(tml.Site_End_Time__c, jobEndTime);
                }
                netWorkHrs -= travelTime;
                if(netWorkHrs != 0){
                    resPWJobWorkDate.add(tml.Resource__c + ':' + tml.TM__r.Scheduled_Date__c + ':' + tml.Resource_Type__c);
                }
            }
        }

        List<Resource_Off__c> paidOffDays = getResOffList(timesheetsByResIds.keySet(), tmStartDate, tmEndDate);
        for(Resource_Off__c paidOffDay:paidOffDays){
            if(paidOffDay.PTO_Type__c != 'PTO-Sick'){
                resWorkDateSet.add(paidOffDay.Resource__c + ':' + paidOffDay.Date__c);
            }
        }

        if(mapPayRuleHolidayDate.size() > 0) {
            Off_Type__c holidayOffType = [SELECT Id FROM Off_Type__c WHERE Name = 'Holiday' LIMIT 1];
            //Union holiday
            for (Id resId : timesheetsByResIds.keySet()) {
                Resource__c res = mapRes.get(resId);
                if (res.Pay_Rule__c != null && mapPayRuleHolidayDate.containsKey(res.Pay_Rule__c + ':' + res.Resource_Type__c)
                        && mapPayRules.get(res.Pay_Rule__c).Pay_Holiday__c == true) {
                    for (Date holidayDate : mapPayRuleHolidayDate.get(res.Pay_Rule__c + ':' + res.Resource_Type__c)) {
                        if(!resHolidayPayDateSet.contains(res.Id + ':' + holidayDate) &&
                                //Ticket#23635 >> isQualifyForUnionHoliday(res, holidayDate, resWorkDateSet) == true) {
                                isQualifyForUnionHoliday(res, holidayDate, resWorkDateSet, res.Pay_Rule__c, res.Resource_Type__c) == true) {
                                //Ticket#23635 <<
                            if(!resHolidayTakenSet.contains(res.Id + ':' + holidayDate)){
                                Resource_Off__c resOff = new Resource_Off__c();
                                resOff.Off_Type__c = holidayOffType.Id;
                                resOff.Resource__c = res.Id;
                                resOff.Work_as_Resource_Type__c = res.Resource_Type__c; //Tikcet#19834
                                resOff.Date__c = holidayDate;
                                resOff.Service_Center__c = res.Service_Center__c;
                                resOff.Resource_Service_Center__c = res.Service_Center__c;
                                resOff.Start_Time__c = Time.newInstance(6,0,0,0);
                                resOff.End_Time__c = Time.newInstance(14,0,0,0);
                                resOff.Total_Hours__c = 8;
                                resOff.Hours__c = 8;
                                resOff.Pay_Rule__c = res.Pay_Rule__c;
                                resOff.System_Created_Entry__c = true;
                                resourceOffLst.add(resOff);
                            }
                            resHolidayPayDateSet.add(res.Id + ':' + holidayDate);
                        }
                    }
                }
            }

            //PW holiday
            for(Timesheet_Line__c tsLine:tsLineLst){
                if(tsLine.Pay_Rule__c != null){
                    Pay_Rule__c payRule = mapPayRules.get(tsLine.Pay_Rule__c);
                    Resource__c res = mapRes.get(tsLine.Resource__c);
                    /* Ticket#23635
                    //Ticket#19843 >> from res.Resource_Type__c to tsLine.Work_as_Resource_Type__c
                    if(payRule.Pay_Holiday__c == true && payRule.Type__c == 'Prevailing Wage' &&
                            mapPayRuleHolidayDate.containsKey(payRule.Id + ':' + tsLine.Work_as_Resource_Type__c)){
                        for(Date holidayDate:mapPayRuleHolidayDate.get(payRule.Id + ':' + tsLine.Work_as_Resource_Type__c)){
                            if(!resHolidayPayDateSet.contains(res.Id + ':' + holidayDate) &&
                                    isQualifyForPWHoliday(res, holidayDate, resPWJobWorkDate) == true){
                                if(!resHolidayTakenSet.contains(res.Id + ':' + holidayDate)){
                                    Resource_Off__c resOff = new Resource_Off__c();
                                    resOff.Off_Type__c = holidayOffType.Id;
                                    resOff.Resource__c = res.Id;
                                    resOff.Work_as_Resource_Type__c = tsLine.Work_as_Resource_Type__c; //Tikcet#19843
                                    resOff.Date__c = holidayDate;
                                    resOff.Service_Center__c = res.Service_Center__c;
                                    resOff.Resource_Service_Center__c = res.Service_Center__c;
                                    resOff.Start_Time__c = Time.newInstance(6,0,0,0);
                                    resOff.End_Time__c = Time.newInstance(14,0,0,0);
                                    resOff.Total_Hours__c = 8;
                                    resOff.Hours__c = 8;
                                    resOff.Pay_Rule__c = payRule.Id;
                                    resOff.System_Created_Entry__c = true;
                                    resourceOffLst.add(resOff);
                                }
                                resHolidayPayDateSet.add(res.Id + ':' + holidayDate);
                            }
                        }
                    }
                     */
                    //System.debug('Info: ' + tsLine.Week_Day__c + ' -- ST: ' + tsLine.Start_Time__c + ' --- work as rt: ' + tsLine.Work_as_Resource_Type__c);
                    if(payRule.Pay_Holiday__c == true && mapPayRuleHolidayDate.containsKey(payRule.Id + ':' + tsLine.Work_as_Resource_Type__c)){
                        for(Date holidayDate:mapPayRuleHolidayDate.get(payRule.Id + ':' + tsLine.Work_as_Resource_Type__c)){
                            //System.debug('Info: holidayDate ' + holidayDate);
                            //System.debug('Info: resHolidayPayDateSet ' + resHolidayPayDateSet);
                            if(!resHolidayPayDateSet.contains(res.Id + ':' + holidayDate)){
                                Boolean qualifyForHolidayPay = false;
                                if(payRule.Type__c == 'Prevailing Wage'){
                                    //Ticket#25014 qualifyForHolidayPay = isQualifyForPWHoliday(res, holidayDate, resPWJobWorkDate);
                                    qualifyForHolidayPay = isQualifyForPWHoliday(res, holidayDate, tsLine.Work_as_Resource_Type__c, resPWJobWorkDate);
                                }
                                if(payRule.Type__c == 'Union') {
                                    //System.debug('Info: resWorkDateSet: ' + resWorkDateSet);
                                    qualifyForHolidayPay = isQualifyForUnionHoliday(res, holidayDate, resWorkDateSet, payRule.Id, tsLine.Work_as_Resource_Type__c);
                                }
                                //System.debug('Info:  + qualifyForHolidayPay: ' + qualifyForHolidayPay + ' ,weekday: ' + tsLine.Week_Day__c + ' -- ST: ' + tsLine.Start_Time__c + ' --- work as rt: ' + tsLine.Work_as_Resource_Type__c);

                                //System.debug('Info: resHolidayTakenSet: ' + resHolidayTakenSet);
                                if(qualifyForHolidayPay == true && !resHolidayTakenSet.contains(res.Id + ':' + holidayDate)){
                                    Resource_Off__c resOff = new Resource_Off__c();
                                    resOff.Off_Type__c = holidayOffType.Id;
                                    resOff.Resource__c = res.Id;
                                    resOff.Work_as_Resource_Type__c = tsLine.Work_as_Resource_Type__c; //Tikcet#19843
                                    resOff.Date__c = holidayDate;
                                    resOff.Service_Center__c = res.Service_Center__c;
                                    resOff.Resource_Service_Center__c = res.Service_Center__c;
                                    resOff.Start_Time__c = Time.newInstance(6,0,0,0);
                                    resOff.End_Time__c = Time.newInstance(14,0,0,0);
                                    resOff.Total_Hours__c = 8;
                                    resOff.Hours__c = 8;
                                    resOff.Pay_Rule__c = payRule.Id;
                                    resOff.System_Created_Entry__c = true;
                                    resourceOffLst.add(resOff);
                                    resHolidayPayDateSet.add(res.Id + ':' + holidayDate);
                                }
                            }
                        }
                    }
                    //Ticket#23635
                }
            }
        }
        if(resourceOffLst.size() > 0) {
            insert resourceOffLst;
        }
        System.debug('Info:###assignPayruleHolidays end###');
    }

    /*
        Ticket#16163 Per Martha resource with union payrule assigned are not qualify for company holiday.
     */
    public Boolean isQualifyForCompanyHoliday(Resource__c res, Date holidayDate, Set<String> resWorkDateSet, Date weekStartDate, Date weekEndDate){

        //System.debug('Info: isQualifyForCompanyHoliday Employee_Type__c ' + res.Name + ' '  + res.Employee_Type__c);
        //Ticket#15509 >>
        if(res.Employee_Type__c != 'Employee'){
            return false;
        }

        //Ticket#15509 <<
        //System.debug('Info: isQualifyForCompanyHoliday FLSA__c ' + res.FLSA__c);
        if(res.FLSA__c != 'Non-Exempt'){
            return false;
        }

        /* Ticket#20665 remove 90 day employment prerequisite
        if(res.Start_Date__c == null || holidayDate == null || res.Start_Date__c.daysBetween(holidayDate) < 90){
            return false;
        }
         */

        String holidayDayName = getDatetimeInUserTZ(holidayDate).format('E').toUpperCase();

        if(mapResNonPTODate.containsKey(res.Id)){
            List<Date> offDateLst = mapResNonPTODate.get(res.Id);
            for(Date offDate : offDateLst){
                //Ticket#23635 >>
                /*
                if(holidayDayName == 'MON' || holidayDayName == 'FRI'){
                    if(Math.abs(holidayDate.daysBetween(offDate)) == 3) {
                        return false;
                    }
                */
                if(holidayDayName == 'MON'){
                    //If employee takes previous Friday off, then they will not be eligible for Mon. holiday pay.
                    if(holidayDate.daysBetween(offDate) == -3){
                        return false;
                    }
                } else if (holidayDayName == 'FRI') {
                    //If employee takes following Monday off, then they will not be eligible for Friday holiday pay.
                    if(holidayDate.daysBetween(offDate) == 3){
                        return false;
                    }
                } else if(holidayDayName == 'SAT'){
                    //If employee takes following Monday off, then they will not be eligible for Sat. holiday pay.
                    if(holidayDate.daysBetween(offDate) == 2){
                        return false;
                    }
                } else if(holidayDayName == 'SUN'){
                    //If employee takes Friday off, then they will not be eligible for Sun. holiday pay.
                    if(holidayDate.daysBetween(offDate) == -2){
                        return false;
                    }
                }

                if(Math.abs(holidayDate.daysBetween(offDate)) == 1) {
                    return false;
                }
                //Ticket#23635 <<
            }
        }

        Date dayBeforeHolidayDate = null;
        Date dayAfterHolidayDate = null;
        Boolean dayBeforeQualified = false;
        Boolean dayAfterQualified = false;

        /*
        if(dayName.toUpperCase() == 'MON'){
            dayBeforeHolidayDate = holidayDate.addDays(-3);
            dayAfterHolidayDate = holidayDate.addDays(1);
        } else if (dayName.toUpperCase() == 'FRI'){
            dayBeforeHolidayDate = holidayDate.addDays(-1);
            dayAfterHolidayDate = holidayDate.addDays(3);
        } else {
            dayBeforeHolidayDate = holidayDate.addDays(-1);
            dayAfterHolidayDate = holidayDate.addDays(1);
        }
         */

        dayBeforeHolidayDate = calcBusinessDay(holidayDate, true);
        dayAfterHolidayDate = calcBusinessDay(holidayDate, false);

        /*
        System.debug('Info: PreiousBusinessDay by Recurssive function ' + dayBeforeHolidayDate);
        System.debug('Info: dayAfterHolidayDate by Recurssive function ' + dayAfterHolidayDate);
        System.debug('Info: Company Holiday Qualification Check: work before holiday must be true ' +
                resWorkDateSet.contains(res.Id + ':' + dayBeforeHolidayDate));
        System.debug('Info: Company Holiday Qualification Check: work after holiday must be true ' +
                resWorkDateSet.contains(res.Id + ':' + dayAfterHolidayDate));
         */

        if(resWorkDateSet.contains(res.Id + ':' + dayBeforeHolidayDate) == true ||
                mapCompanyHoliday.containsKey(dayBeforeHolidayDate) == true){
            dayBeforeQualified = true;
        }

        if(resWorkDateSet.contains(res.Id + ':' + dayAfterHolidayDate) ||
                mapCompanyHoliday.containsKey(dayAfterHolidayDate) == true){
            dayAfterQualified = true;
        }

        //System.debug('Info:  dayBeforeQualified ' + dayBeforeQualified + ' --- dayAfterQualified: ' + dayAfterQualified);

        if(holidayDayName != 'FRI'){
            if(dayBeforeQualified == false){
                return false;
            } else if(dayAfterQualified == false && (dayAfterHolidayDate >= weekStartDate && dayAfterHolidayDate <= weekEndDate)){
                return false;
            }
        } else if (holidayDayName == 'FRI' && dayBeforeQualified == false){
        //If holiday occurs on Friday then only need to work on the day before to qualify
            return false;
        }

        /*
        if((resWorkDateSet.contains(res.Id + ':' + dayBeforeHolidayDate) != true) ||
                (resWorkDateSet.contains(res.Id + ':' + dayAfterHolidayDate) != true)) {
            return false;
        }

        if(resSickDateByResIds.containsKey(res.Id)){
            List<Date> offDates = resSickDateByResIds.get(res.Id);
            for(Date offDate : offDates){
                if(dayName.toUpperCase() == 'MON' || dayName.toUpperCase() == 'FRI'){
                    if(Math.abs(holidayDate.daysBetween(offDate)) == 3) return false;
                }
                if(Math.abs(holidayDate.daysBetween(offDate)) == 1) return false;
            }
        }
         */


        if(String.isNotBlank(res.Pay_Rule__c) && mapPayRules.get(res.Pay_Rule__c).Type__c == 'Union'){
            return false;
        }

        return true;
    }

    public Boolean isQualifyForUnionHoliday(Resource__c res, Date holidayDate, Set<String> resWorkDateSet, Id lookupByPayRuleId, Id lookupByResTypeId){
        String dayName = TimeUtils.getDatetimeInUserTZ(holidayDate).format('E');
        Date dayBeforeHolidayDate = null;
        Date dayAfterHolidayDate = null;
        Boolean workDayBeforeAndAfter = false;
        Boolean workDayBefore = false;
        Boolean workDayAfter = false;
        Boolean workedXoutOfYDay = false;
        Boolean payHoliday = false;
        Boolean isDayBeforeAHolidayDate = false;
        Boolean isDayAfterAHolidayDate = false;
        /*Ticket#23635 >>
        //Pay_Rule__c payRule = mapPayRules.get(res.Pay_Rule__c);
         */
        Pay_Rule__c payRule = mapPayRules.get(lookupByPayRuleId);
        //Ticket#23635

        //if(payRule.Work_Before_or_After_Holiday_to_Qualify__c == true){
        if(payRule.Work_Before_and_After_Holiday_to_Qualify__c == true){
            /*
            if(dayName.toUpperCase() == 'MON'){
                dayBeforeHolidayDate = holidayDate.addDays(-3);
                dayAfterHolidayDate = holidayDate.addDays(1);
            } else if (dayName.toUpperCase() == 'FRI'){
                dayBeforeHolidayDate = holidayDate.addDays(-1);
                dayAfterHolidayDate = holidayDate.addDays(3);
            } else {
                dayBeforeHolidayDate = holidayDate.addDays(-1);
                dayAfterHolidayDate = holidayDate.addDays(1);
            }
             */

            dayBeforeHolidayDate = calcBusinessDay(holidayDate, true);
            //System.debug('Info: dayBeforeHolidayDate ' + dayBeforeHolidayDate);
            /*Ticket#23635 >>
            if(mapPayRuleHolidayDate.containsKey(res.Pay_Rule__c +  ':' + res.Resource_Type__c)) {
                isDayBeforeAHolidayDate = mapPayRuleHolidayDate.get(res.Pay_Rule__c + ':' + res.Resource_Type__c).contains(dayBeforeHolidayDate);
                //System.debug('Info: isDayBeforeAHolidayDate ' + isDayBeforeAHolidayDate);
            }
             */
            String lookupKey = lookupByPayRuleId +  ':' + lookupByResTypeId;
            if(mapPayRuleHolidayDate.containsKey(lookupKey)) {
                isDayBeforeAHolidayDate = mapPayRuleHolidayDate.get(lookupKey).contains(dayBeforeHolidayDate);
                //System.debug('Info: isDayBeforeAHolidayDate ' + isDayBeforeAHolidayDate);
            }
            //Ticket#23635 <<

            dayAfterHolidayDate = calcBusinessDay(holidayDate, false);
            //System.debug('Info: dayAfterHolidayDate ' + dayAfterHolidayDate);
            /*Ticket#23625 >>
            if(mapPayRuleHolidayDate.containsKey(res.Pay_Rule__c +  ':' + res.Resource_Type__c)) {
                isDayAfterAHolidayDate = mapPayRuleHolidayDate.get(res.Pay_Rule__c + ':' + res.Resource_Type__c).contains(dayAfterHolidayDate);
                //System.debug('Info: isDayAfterAHolidayDate ' + isDayAfterAHolidayDate);
            }
             */
            if(mapPayRuleHolidayDate.containsKey(lookupKey)) {
                isDayAfterAHolidayDate = mapPayRuleHolidayDate.get(lookupKey).contains(dayAfterHolidayDate);
                //System.debug('Info: isDayAfterAHolidayDate ' + isDayAfterAHolidayDate);
            }
            //Ticket#23635 <<

            //System.debug('Info: dayBeforeHolidayDate ' + dayBeforeHolidayDate);
            //System.debug('Info: dayAfterHolidayDate ' + dayAfterHolidayDate);


            if(resWorkDateSet.contains(res.Id + ':' + dayBeforeHolidayDate) == true || isDayBeforeAHolidayDate == true){
                workDayBefore = true;
            }

            //System.debug('Info: workDayBefore ' + workDayBefore);

            if(resWorkDateSet.contains(res.Id + ':' + dayAfterHolidayDate) == true || isDayAfterAHolidayDate == true){
                workDayAfter = true;
            }

            //System.debug('Info: workDayAfter ' + workDayAfter);

            //System.debug('Info: workDayBeforeOrAfter 1 ' + workDayBeforeAndAfter);

            if(workDayBefore == true && workDayAfter == true){
                workDayBeforeAndAfter = true;
            }

            //System.debug('Info: workDayBeforeAndAfter ' + workDayBeforeAndAfter);

            //Ticket#23635 >>
            //if(workDayBeforeAndAfter == false && dayName == 'FRI' && workDayBefore == true){
            if(workDayBeforeAndAfter == false && workDayBefore == true && (dayName == 'FRI' || dayName == 'SAT' || dayName == 'SUN')){
            //Ticket#23635 <<
                workDayBeforeAndAfter = true;
            }

            //System.debug('Info: workDayBeforeOrAfter 2 ' + workDayBeforeAndAfter);
            //System.debug('Info: Union Holiday Qualification Checking...');
        }

        if(String.isNotBlank(payRule.Work_x_out_y_days_to_qualify__c) == true){
            List<String> ruleInputs = payRule.Work_x_out_y_days_to_qualify__c.split('|');
            Integer minDaysWorkNeeded = Integer.valueOf(ruleInputs[0]);
            Integer numberOfDayCounted = Integer.valueOf(ruleInputs[2]);
            Integer qualifyDayCount = 0;
            Date checkDate = holidayDate;
            
            for(Integer i = 0; i < numberOfDayCounted; i++){
                Boolean isWeekend = true;
                while(isWeekend){
                    checkDate = checkDate.addDays(-1);
                    String checkDatedayName = TimeUtils.getDatetimeInUserTZ(checkDate).format('EEEE');
                    isWeekend = TimeUtils.isWeekend(checkDateDayName) ? true : false;
                }

                if(resWorkDateSet.contains(res.Id + ':' + checkDate) == true) qualifyDayCount += 1;
                if(qualifyDayCount >= minDaysWorkNeeded){
                    workedXoutOfYDay = true;
                    break;
                }
            }
        }

        if(String.isNotBlank(payRule.Work_x_out_y_days_to_qualify__c) && payRule.Work_Before_and_After_Holiday_to_Qualify__c){
            payHoliday = workDayBeforeAndAfter || workedXoutOfYDay;
        } else if(String.isNotBlank(payRule.Work_x_out_y_days_to_qualify__c)){
            payHoliday = workedXoutOfYDay;
        } else if(payRule.Work_Before_and_After_Holiday_to_Qualify__c == true){
            payHoliday = workDayBeforeAndAfter;
        }

        /* Ticket#20665 remove 90 day employment prerequisite
        if(res.Start_Date__c == null || holidayDate == null || res.Start_Date__c.daysBetween(holidayDate) < 90){
            payHoliday = false;
        }
         */
        //System.debug('Info: payUnionHoliday ' + payHoliday);

        return payHoliday;
    }

    /*Ticket#25014
    public Boolean isQualifyForPWHoliday(Resource__c res, Date holidayDate, Set<String> resWorkDateSet){
        return resWorkDateSet.contains(res.Id + ':' + holidayDate);
    }
     */

    public Boolean isQualifyForPWHoliday(Resource__c res, Date holidayDate, Id tmLineResTypeId, Set<String> resWorkDateSet){
        return resWorkDateSet.contains(res.Id + ':' + holidayDate + ':' + tmLineResTypeId);
    }

    public void setResNonPTODateMap(Date startDate, Date endDate){
        List<Resource_Off__c> nonPTOOffLst = new List<Resource_Off__c>();
        nonPTOOffLst = [SELECT Id, Resource__c, Date__c, Unavailable_Reason__c
            FROM Resource_Off__c
            WHERE Date__c >= :startDate.addDays(-3) AND Date__c <= :endDate.addDays(1) AND Off_Type__c = :theCompanySetup.Non_PTO_Off_Type__c];
        for(Resource_Off__c nonPTOOff : nonPTOOffLst){
            if(mapResNonPTODate.containsKey(nonPTOOff.Resource__c)){
                List<Date> dateLst = mapResNonPTODate.get(nonPTOOff.Resource__c);
                dateLst.add(nonPTOOff.Date__c);
                mapResNonPTODate.put(nonPTOOff.Resource__c, dateLst);
            } else {
                mapResNonPTODate.put(nonPTOOff.Resource__c, new List<Date>{nonPTOOff.Date__c});
            }
        }
    }

    /*
        Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
    */
    public void setPayRuleHolidayDateMap(Date startDate, Date endDate, Set<String> payRuleResTypeKeySet){
        List<Holiday__c> holidays = [SELECT Id, Name, Date__c, Holiday_Name_Map__c FROM Holiday__c
            WHERE Holiday_Name_Map__c != NULL AND Date__c >= :startDate AND Date__c <= :endDate];

        for(Holiday__c holiday:holidays){
            for(String mapKey:payRuleResTypeKeySet){
                if(mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)){
                    Pay_Rule_Line__c payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                    if(payRuleLine.Eligible_Holidays__c != null){
                        List<String> holidayList = payRuleLine.Eligible_Holidays__c.split(';');
                        if(String.isNotBlank(holiday.Holiday_Name_Map__c)){
                            List<String> holidayNames = holiday.Holiday_Name_Map__c.split(';');
                            for(String holidayName : holidayNames){
                                if(holidayList.contains(holidayName)){
                                    if(mapPayRuleHolidayDate.containsKey(mapKey)){
                                        List<Date> holidayDateLst = mapPayRuleHolidayDate.get(mapKey);
                                        holidayDateLst.add(holiday.Date__c);
                                        mapPayRuleHolidayDate.put(mapKey, holidayDateLst);
                                    } else {
                                        mapPayRuleHolidayDate.put(mapKey, new List<Date>{holiday.Date__c});
                                    }
                                }
                            }
                        }
                    }
                    /*
                    List<String> holidayList = new List<String>();
                    if(payRuleLine.Holidays_with_Overtime_Pay__c != null){
                        holidayList.addAll(payRuleLine.Holidays_with_Overtime_Pay__c.split(';'));
                    }
                    if(payRuleLine.Holiday_with_Double_Time_Pay__c != null){
                        holidayList.addAll(payRuleLine.Holiday_with_Double_Time_Pay__c.split(';'));
                    }
                    if(String.isNotBlank(holiday.Holiday_Name_Map__c) && holidayList.size() > 0){
                        List<String> holidayNames = holiday.Holiday_Name_Map__c.split(';');
                        for(String holidayName : holidayNames){
                            if(holidayList.contains(holidayName)){
                                List<Date> holidayDateLst = new List<Date>();
                                if(mapPayRuleHolidayDate.containsKey(mapKey)) {
                                    holidayDateLst = mapPayRuleHolidayDate.get(mapKey);
                                }
                                holidayDateLst.add(holiday.Date__c);
                                mapPayRuleHolidayDate.put(mapKey, holidayDateLst);
                            }
                        }
                    }
                     */
                }
            }
        }
    }

    public List<Timesheet__c> getOpenTimesheetsByWeekAndServiceCenter(Id weekNumber, Id scId){
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Timesheet__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM Timesheet__c WHERE Service_Center__c =: scId AND Week_No__c = :weekNumber AND Status__c = \'Open\'';
        return Database.query(strQuery);
    }

    //Ticket#13763
    public Timesheet_Line__c allocateLunchHour(Timesheet_Line__c tsLine){
        Time lunchStart = null;
        Time lunchEnd = null;
        Decimal lunchHr = 0;
        Boolean captureLunch = false;
        if(tsLine.Lunch_Start_Time__c != null && tsLine.Lunch_End_Time__c != null
                && tsLine.Start_Time__c != null && tsLine.End_Time__c != null){

            if(tsLine.Start_Time__c <= tsLine.Lunch_Start_Time__c && tsLine.Lunch_End_Time__c <= tsLine.End_Time__c) {
                captureLunch = true;
            }

            if(captureLunch == false && tsLine.End_Time__c == Time.newInstance(0,0,0,0)
                    && tsLine.Start_Time__c <= tsLine.Lunch_Start_Time__c && tsLine.Start_Time__c <= tsLine.Lunch_End_Time__c){
                captureLunch = true;
            }

            if(captureLunch == true) {
                lunchStart = tsLine.Lunch_Start_Time__c;
                lunchEnd = tsLine.Lunch_End_Time__c;
                lunchHr = TimeUtils.calculateHours(lunchStart, lunchEnd);
            }

            tsLine.Lunch_Start_Time__c = lunchStart;
            tsLine.Lunch_End_Time__c = lunchEnd;
            tsLine.Lunch_Hours__c = lunchHr;
        }
        return tsLine;
    }

    public List<Timesheet_Line__c> processTimesheetLineWithPayRule(List<Timesheet_Line__c> tslLst){
        //System.debug('Info#Method: processTimesheetLineWithPayRule Begin');
        Set<Id> payRuleIdSet = collectPayRuleIdsFromTimesheetLines(tslLst);
        //Pay Rule Map key: Pay Rule Id
        setPayRuleMap(payRuleIdSet);
        List<Timesheet_Line__c> otLineLst = new List<Timesheet_Line__c>();
        for(Timesheet_Line__c tsLine:tslLst){
            /*
            if(tsLine.Time_Type__c == 'Travel Time' && String.isNotBlank(tsLine.Pay_Rule__c) && tsLine.Time_Type_Code__c == 'REG' &&
                    String.isNotBlank(tsLine.Work_as_Resource_Type__c)){
                String mapKey = tsLine.Pay_Rule__c + ':' + tsLine.Work_as_Resource_Type__c;
                Pay_Rule_Line__c payRuleLine = null;
                if(mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                    payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                    tsLine.Pay_Rule_Line__c = payRuleLine.Id;
                } else {
                    //Ticket#22782 >>
                    if(String.isNotBlank(mapRes.get(tsLine.Resource__c).Pay_Rule__c)){
                        mapKey = mapRes.get(tsLine.Resource__c).Pay_Rule__c + ':' + mapRes.get(tsLine.Resource__c).Resource_Type__c;
                        if (mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                            payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                            tsLine.Pay_Rule_Line__c = payRuleLine.Id;
                        }
                    }
                    else {
                        mapKey = theCompanySetup.Company_Pay_Rule__c + ':' + tsLine.Work_as_Resource_Type__c;
                        if (mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                            payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                            tsLine.Pay_Rule_Line__c = payRuleLine.Id;
                        }
                    }
                    //Ticket#22782 <<
                }
                //Ticket#23241 >>
                if(payRuleLine != null && tsLine.Week_Day__c == 'Sunday' &&
                        isPeakSeason(tsLine.Scheduled_Date__c, payRuleLine) == true &&
                        payRuleLine.Peak_Season_Sunday_Pay_Code__c != null)
                {
                    tsLine.Time_Type_Code__c = payRuleLine.Peak_Season_Sunday_Pay_Code__c;
                }
                //Ticket#23241 <<
            }
             */
            //Ticket#23663
            if(tsLine.Time_Type__c == 'Travel Time' && tsLine.Time_Type_Code__c == 'REG'){
                String mapKey = '';
                Pay_Rule_Line__c payRuleLine = null;
                if(String.isNotBlank(mapRes.get(tsLine.Resource__c).Pay_Rule__c)){
                    mapKey = mapRes.get(tsLine.Resource__c).Pay_Rule__c + ':' + mapRes.get(tsLine.Resource__c).Resource_Type__c;
                    if (mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                        payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                        tsLine.Pay_Rule_Line__c = payRuleLine.Id;
                    }
                }
                else {
                    mapKey = theCompanySetup.Company_Pay_Rule__c + ':' + tsLine.Work_as_Resource_Type__c;
                    if (mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                        payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                        tsLine.Pay_Rule_Line__c = payRuleLine.Id;
                    }
                }

                if(payRuleLine == null){
                    tsLine.Pay_Rule__c = theCompanySetup.Company_Pay_Rule__c;
                } else {
                    tsLine.Pay_Rule__c = payRuleLine.Pay_Rule__c;
                }
            }
            
            if((tsLine.Time_Type__c == 'Job Time' || tsLine.Time_Type__c == 'Prevailing Wage' || tsLine.Time_Type__c == 'Shop Time' || tsLine.Time_Type__c == 'Travel Time')
                && String.isNotBlank(tsLine.Pay_Rule__c) && (tsLine.Time_Type_Code__c == 'REG' || tsLine.Time_Type_Code__c == 'SHP') &&
                    String.isNotBlank(tsLine.Work_as_Resource_Type__c)){
                String mapKey = tsLine.Pay_Rule__c + ':' + tsLine.Work_as_Resource_Type__c;
                Pay_Rule_Line__c payRuleLine = null;
                Pay_Rule__c tempPayRule = mapPayRules.get(tsLine.Pay_Rule__c);
                if(mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                    payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                } else if(tsLine.Time_Type__c == 'Prevailing Wage' || tempPayRule.Type__c == 'Union'){
                    //Ticket#22782 >>
                    /*
                    mapKey = theCompanySetup.Company_Pay_Rule__c + ':' + tsLine.Work_as_Resource_Type__c;
                    if (mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                        payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                        tsLine.Pay_Rule__c = theCompanySetup.Company_Pay_Rule__c;
                    }
                     */
                    if(String.isNotBlank(mapRes.get(tsLine.Resource__c).Pay_Rule__c)){
                        mapKey = mapRes.get(tsLine.Resource__c).Pay_Rule__c + ':' + mapRes.get(tsLine.Resource__c).Resource_Type__c;
                        if (mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                            payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                        }
                    }
                    else {
                        mapKey = theCompanySetup.Company_Pay_Rule__c + ':' + tsLine.Work_as_Resource_Type__c;
                        if (mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                            payRuleLine = mapPayRuleResTypeWithPayRuleLine.get(mapKey);
                        }
                    }
                    //Ticket#22782 <<
                }

                //Ticket#22782 >>
                //Pay_Rule__c payRule = mapPayRules.get(tsLine.Pay_Rule__c);
                Pay_Rule__c payRule = null;
                if(payRuleLine != null){
                    payRule = mapPayRules.get(payRuleLine.Pay_Rule__c);
                } else {
                    payRule = mapPayRules.get(tsLine.Pay_Rule__c);
                }
                //Ticket#22782 <<

                if(payRuleLine != null) {
                    tsLine.Pay_Rule_Line__c = payRuleLine.Id; //Ticket#22504
                    if (tsLine.Week_Day__c == 'Sunday' && isPeakSeason(tsLine.Scheduled_Date__c, payRuleLine) == true && payRuleLine.Peak_Season_Sunday_Pay_Code__c != null) {
                        tsLine.Time_Type_Code__c = payRuleLine.Peak_Season_Sunday_Pay_Code__c;
                    } else {
                        if (payRule.Use_Pay_Rule_Line_Detail_for_Hour_Calc__c != true) {
                            if (CompanyMgmt.zeroIfNull(payRuleLine.Daily_OT_After_Num_of_Hours__c) > 0) {
                                tsLine.Calculate_OT_Daily__c = true;
                                tsLine.Daily_OT_After_Number_of_Hrs__c = payRuleLine.Daily_OT_After_Num_of_Hours__c;
                            }

                            if (tsLine.Week_Day__c == 'Sunday' && String.isNotBlank(payRuleLine.Sunday_Pay_Code__c)) {
                                tsLine.Time_Type_Code__c = payRuleLine.Sunday_Pay_Code__c;
                            }

                            if (tsLine.Week_Day__c == 'Saturday' && String.isNotBlank(payRuleLine.Saturday_Pay_Code__c)) {
                                tsLine.Time_Type_Code__c = payRuleLine.Saturday_Pay_Code__c;
                            }

                            //Handle different pay rate for certain premium time.
                            //Ticket#23663 >>
                            //if ((tsLine.Time_Type__c == 'Job Time' || tsLine.Time_Type__c == 'Prevailing Wage')
                            //Ticket#23781 -- Include shop time entries to the calculation
                            if ((tsLine.Time_Type__c == 'Job Time' || tsLine.Time_Type__c == 'Prevailing Wage' || tsLine.Time_Type__c == 'Travel Time' || tsLine.Time_Type__c == 'Shop Time')
                            //Ticket#23663 <<
                                    && (tsLine.Time_Type_Code__c == 'REG' || tsLine.Time_Type_Code__c == 'SHP')
                                    && String.isNotBlank(tsLine.Work_as_Resource_Type__c)
                                    && String.isNotBlank(tsLine.Pay_Rule__c)) {
                                Time timeBefore = payRuleLine.Before_Time__c;
                                Time timeAfter = payRuleLine.After_Time__c;
                                Time timesheetStartTime = tsLine.Start_Time__c;
                                Time timesheetEndTime = tsLine.End_Time__c;
                                if (timesheetStartTime < timeBefore && timeBefore != null && timesheetStartTime != null) {
                                    if (timesheetEndTime < timeBefore) {
                                        tsLine.Time_Type_Code__c = payRuleLine.Time_Before_Pay_Code__c;
                                    } else {
                                        Decimal otHrs = TimeUtils.calculateHours(timesheetStartTime, timeBefore);
                                        if(otHrs == tsLine.Total_Hours__c){
                                            tsLine.Time_Type_Code__c = payRuleLine.Time_Before_Pay_Code__c;
                                        } else {
                                            Timesheet_Line__c otLine = new Timesheet_Line__c();
                                            otLine = createSysCalcLine(tsLine,
                                                    timesheetStartTime,
                                                    timeBefore,
                                                    otHrs,
                                                    tsLine.Time_Type__c,
                                                    payRuleLine.Time_Before_Pay_Code__c);
                                            tsLine.Total_Hours__c = tsLine.Total_Hours__c - otHrs;
                                            tsLine.Net_Hours__c = tsLine.Net_Hours__c - otHrs;
                                            tsLine.Start_Time__c = timeBefore;
                                            otLineLst.add(otLine);
                                            //System.debug('Info: otLine 1 ' + otLine.Start_Time__c + ' -- ' + otLine.End_Time__c);
                                        }
                                    }
                                }

                                if ((timesheetEndTime > timeAfter || timesheetEndTime == TimeUtils.midNight()) &&
                                        timeAfter != null && timesheetEndTime != null) {
                                    Decimal otHrs = 0;
                                    Time newTLStartTime = null;
                                    if (timesheetStartTime > timeAfter) {
                                        otHrs = TimeUtils.calculateHours(timesheetStartTime, timesheetEndTime);
                                        newTLStartTime = timesheetStartTime;
                                    } else {
                                        otHrs = TimeUtils.calculateHours(timeAfter, timesheetEndTime);
                                        newTLStartTime = timeAfter;
                                    }

                                    if(otHrs == tsLine.Total_Hours__c){
                                        tsLine.Time_Type_Code__c = payRuleLine.Time_After_Pay_Code__c;
                                    } else {
                                        Timesheet_Line__c otLine = new Timesheet_Line__c();
                                        otLine = createSysCalcLine(tsLine,
                                                newTLStartTime,
                                                timesheetEndTime,
                                                otHrs,
                                                tsLine.Time_Type__c,
                                                payRuleLine.Time_After_Pay_Code__c);
                                        tsLine.Total_Hours__c = tsLine.Total_Hours__c - otHrs;
                                        tsLine.Net_Hours__c = tsLine.Net_Hours__c - otHrs;
                                        tsLine.End_Time__c = newTLStartTime;
                                        otLineLst.add(otLine);
                                        //System.debug('Info: otLine 2 ' + otLine.Start_Time__c + ' -- ' + otLine.End_Time__c);
                                    }
                                }
                            }

                            if (tsLine.Time_Type_Code__c == 'REG'
                                    && tsLine.Calculate_OT_Daily__c == true
                                    && tsLine.Net_Hours__c > tsLine.Daily_OT_After_Number_of_Hrs__c) {
                                //System.debug('Info: tsLine ' + tsLine.Start_Time__c + ' -- ' + tsLine.End_Time__c + ' --Net: ' + tsLine.Net_Hours__c + ' ---Daily OT: ' + tsLine.Daily_OT_After_Number_of_Hrs__c);
                                Timesheet_Line__c otLine = createSysCalcLine(
                                        tsLine,
                                        null,
                                        null,
                                        tsLine.Net_Hours__c - tsLine.Daily_OT_After_Number_of_Hrs__c,
                                        tsLine.Time_Type__c,
                                        theCompanySetup.Overtime_Rate__c
                                );
                                tsLine.Total_Hours__c = tsLine.Daily_OT_After_Number_of_Hrs__c;
                                reallocateTimesForTimesheetLines(tsLine, otLine);
                                //System.debug('Info: otLine 3 ' + otLine.Start_Time__c + ' -- ' + otLine.End_Time__c);
                                otLineLst.add(otLine);
                            }
                        } else {
                            processTimeSheetLineWithPayRuleLineDetail(payRuleLine, tsLine, otLineLst);
                        }
                    }
                }
            }
        }

        if(otLineLst.size() > 0) {
            tslLst.addAll(otLineLst);
        }

        //System.debug('Info: Method: processTimesheetLineWithPayRule End');
        return tslLst;
    }
    public void processTimeSheetLineWithPayRuleLineDetail(Pay_Rule_Line__c payRuleLine, Timesheet_Line__c timesheetLine, List<Timesheet_Line__c> timesheetLines){
        if(payRuleLineDetailLinesByDayByPayRuleLineIds.containsKey(payRuleLine.Id)){
            Map<String, List<Pay_Rule_Line_Detail__c>> payRuleLineDetailLinesByDay = payRuleLineDetailLinesByDayByPayRuleLineIds.get(payRuleLine.Id);
            if(payRuleLineDetailLinesByDay.containsKey(timesheetLine.Week_Day__c)){
                List<Pay_Rule_Line_Detail__c> payRuleLineDetails = payRuleLineDetailLinesByDay.get(timesheetLine.Week_Day__c);
                //System.debug('Info: payRuleLineDetails ' + payRuleLineDetails.size());
                //System.debug('Info: payRuleLineDetails ' + payRuleLineDetails);
                Map<String, Decimal> hoursByRateCode = calcHoursWithRateCodes(payRuleLineDetails, timesheetLine.Start_Time__c, timesheetLine.End_Time__c);
                Integer count = 0;
                Integer nonZeroHrRateCount = 0;
                Time startTime = timesheetLine.Start_Time__c;
                Time endTime = timesheetLine.End_Time__c;
                //System.debug('Info: hoursByRateCode ' + hoursByRateCode);
                for(String rateCode : hoursByRateCode.keySet()) {
                    Decimal hours = hoursByRateCode.get(rateCode);
                    if(hours > 0){
                        nonZeroHrRateCount++;
                    }
                }
                //System.debug('Info: Day ' + timesheetLine.Scheduled_Date__c + ' -- Day Name: ' + timesheetLine.Week_Day__c);
                //System.debug('Info: hoursByRateCode ' + hoursByRateCode);
                for(String rateCode : hoursByRateCode.keySet()){
                    Decimal hours = hoursByRateCode.get(rateCode);
                    String timeSheetLineRateCode = rateCode;
                    if(rateCode == 'OT'){
                        timeSheetLineRateCode = 'O/T';
                    } else if (rateCode == 'DT'){
                        timeSheetLineRateCode = 'DBT';
                    }
                    if(hours > 0){
                        count++;
                        if(count == 1){
                            timesheetLine.Time_Type_Code__c = timeSheetLineRateCode;
                            timesheetLine.Pay_Rule_Line_Detail__c = payRuleLineDetails[0].Id;
                            timesheetLine.Pay_Rule_Line_Detail__r = payRuleLineDetails[0];
                            if(count == nonZeroHrRateCount){
                                continue;
                            } else {
                                timesheetLine.Net_Hours__c = hours;
                                timesheetLine.Total_Hours__c = CompanyMgmt.zeroIfNull(timesheetLine.Lunch_Hours__c) + hours;
                                Decimal totalSeconds = timesheetLine.Total_Hours__c * 3600;
                                timesheetLine.End_Time__c = timesheetLine.Start_Time__c.addSeconds(Integer.valueOf(totalSeconds));
                                endTime = timesheetLine.End_Time__c;
                                //System.debug('Info: count++ ' + totalSeconds + ' --- ' + startTime + ' --- ' + endTime);
                            }
                        } else {
                            if (count == 2) {
                                if(count == nonZeroHrRateCount){
                                    hours = hours - CompanyMgmt.zeroIfNull(timesheetLine.Lunch_Hours__c);
                                }
                                Decimal totalSeconds = hours * 3600;
                                startTime = endTime;
                                endTime = startTime.addSeconds(Integer.valueOf(totalSeconds));
                                //System.debug('Info: count' + count);
                                //System.debug('Info: start time : ' + startTime);
                                //System.debug('Info: totalSeconds : ' + startTime);
                            } else {
                                if(count == nonZeroHrRateCount){
                                    hours = hours - CompanyMgmt.zeroIfNull(timesheetLine.Lunch_Hours__c);
                                }
                                Decimal totalSeconds = hours * 3600;
                                startTime = endTime;
                                endTime = startTime.addSeconds(Integer.valueOf(totalSeconds));
                                //System.debug('Info: count++ ' + totalSeconds + ' --- ' + startTime + ' --- ' + endTime);
                            }

                            timesheetLine.Pay_Rule_Line_Detail__c = payRuleLineDetails[0].Id;
                            timesheetLine.Pay_Rule_Line_Detail__r = payRuleLineDetails[0];
                            Timesheet_Line__c newTimesheetLine = createSysCalcLine(
                                    timesheetLine,
                                    startTime,
                                    endTime,
                                    hours,
                                    timesheetLine.Time_Type__c,
                                    timeSheetLineRateCode
                            );
                            newTimesheetLine.Pay_Rule_Line_Detail__c = payRuleLineDetails[0].Id;
                            newTimesheetLine.Pay_Rule_Line_Detail__r = payRuleLineDetails[0];
                            timesheetLines.add(newTimesheetLine);
                        }
                    }
                }
            }
        }
    }

    public Map<String, Decimal> calcHoursWithRateCodes(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Time starTime, Time endTime){
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
            for(String rateCode : tempHoursByRateCode.keySet()){
                Decimal calcHrs = tempHoursByRateCode.get(rateCode);
                hoursByRateCode.put(rateCode, hoursByRateCode.get(rateCode) + calcHrs);
            }
        }
        return hoursByRateCode;
    }

    public Map<String, Decimal> calcTimeBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Time startTime, Time endTime){
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        hoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), 0);
        Time tempStartTime = startTime;
        Time tempEndTime = endTime;
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

            for(Pay_Rule_Line_Detail__c payRuleLineDetail : payRuleLineDetailLines){
                if(totalHours <= 0){
                    continue;
                }

                Time payRuleDetailLineStartTime = payRuleLineDetail.Start_Time__c;
                Time payRuleDetailLineEndTime = payRuleLineDetail.End_Time__c;

                //System.debug('Info: billingRuleLine ' + billingRuleLine.Start_Time__c + ' -- ' + billingRuleLine.End_Time__c);

                if(payRuleLineDetail.Rate_Code__c == null){
                    throw (Exception) new DataException('Rate Code must not be blank for pay rule line detail: ' + payRuleLineDetail.Pay_Rule_Line__r.Pay_Rule__r.Name + ' Line ' + payRuleLineDetail.Pay_Rule_Line__r.Name + ' Line Detail ' + payRuleLineDetail.Name);
                }

                String payRuleRateCode = payRuleLineDetail.Rate_Code__c;
                Decimal calcHrs = 0;

                //if start time is greater than billing rule end time
                //and billing rule end time is not mid-night
                //then skip because billing rule line will not applied.
                if(tempStartTime >= payRuleDetailLineEndTime && payRuleDetailLineEndTime != TimeUtils.midNight()){
                    //System.debug('Info: skipped ' + tempStartTime + ' -- ' + tempEndTime);
                    continue;
                }

                if(tempStartTime == payRuleDetailLineStartTime && tempEndTime == payRuleDetailLineEndTime){
                    calcHrs = TimeUtils.calculateHours(tempStartTime, tempEndTime);
                    hoursByRateCode.put(payRuleRateCode, hoursByRateCode.get(payRuleRateCode) + calcHrs);
                    totalHours -= calcHrs;
                    //System.debug('Info: 1 ' + tempStartTime + ' - ' + tempEndTime + ' -- calcHrs ' +  calcHrs + ' --- total hr left ' + totalHours );
                    continue;
                }

                if(tempStartTime >= payRuleDetailLineStartTime){
                    if(tempEndTime <= payRuleDetailLineEndTime){
                        if(tempEndTime != TimeUtils.midNight() || payRuleDetailLineEndTime == TimeUtils.midNight()){
                            calcHrs = TimeUtils.calculateHours(tempStartTime, tempEndTime);
                            hoursByRateCode.put(payRuleRateCode, hoursByRateCode.get(payRuleRateCode) + calcHrs);
                            totalHours -= calcHrs;
                            //System.debug('Info: 2 ' + tempStartTime + ' - ' + tempEndTime + ' -- calcHrs ' +  calcHrs + ' --- total hr left ' + totalHours );
                            continue;
                        } else if (tempEndTime == TimeUtils.midNight()){
                            calcHrs = TimeUtils.calculateHours(tempStartTime, payRuleDetailLineEndTime);
                            hoursByRateCode.put(payRuleRateCode, hoursByRateCode.get(payRuleRateCode) + calcHrs);
                            totalHours -= calcHrs;
                            //System.debug('Info: 3 ' + tempStartTime + ' - ' + tempEndTime + ' -- calcHrs ' +  calcHrs + ' --- total hr left ' + totalHours );
                            if(totalHours > 0){
                                tempStartTime = payRuleDetailLineEndTime;
                                //System.debug('Info: new time range 3 ' + tempStartTime + ' - ' + tempEndTime);
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
                        //System.debug('Info: 4 ' + tempStartTime + ' - ' + tempTime + ' -- calcHrs ' +  calcHrs + ' --- total hr left ' + totalHours );
                        if(totalHours > 0){
                            tempStartTime = payRuleDetailLineEndTime;
                            //System.debug('Info: new time range 4 ' + tempStartTime + ' - ' + tempEndTime);
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

    public Map<String, Decimal> calcHourBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Time startTime, Time endTime) {
        Decimal totalHours = TimeUtils.calculateHours(startTime, endTime);
        Map<String, Decimal> hoursByRateCode = this.calcHourBasedHours(payRuleLineDetailLines, totalHours);
        return hoursByRateCode;
    }

    public Map<String, Decimal> calcHourBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Decimal totalHours) {
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        hoursByRateCode.put(EnumUtil.TimeRateCode.REG.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.OT.name(), 0);
        hoursByRateCode.put(EnumUtil.TimeRateCode.DT.name(), 0);

        if(payRuleLineDetailLines.size() > 0){
            //System.debug('Info: Hour Base payRuleLineDetailLines ' + payRuleLineDetailLines[0]);
            Decimal thresholdHrs = CompanyMgmt.zeroIfNull(payRuleLineDetailLines[0].Number_of_Hours__c);
            Decimal secordthresholdHrs = CompanyMgmt.zeroIfNull(payRuleLineDetailLines[0].Hours_After_Number_of_Hours__c);
            //System.debug('Info: totalHours ' + totalHours);
            //System.debug('Info: thresholdHrs ' + thresholdHrs);
            //System.debug('Info: secordthresholdHrs ' + secordthresholdHrs);
            String recordLookupString = payRuleLineDetailLines[0].Pay_Rule_Line__r.Pay_Rule__r.Name + ' Line ' + payRuleLineDetailLines[0].Pay_Rule_Line__r.Name + ' Line Detail ' + payRuleLineDetailLines[0].Name;
            if(totalHours > thresholdHrs){
                Decimal remainingHrs = totalHours - thresholdHrs;
                hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code__c, thresholdHrs + hoursByRateCode.get(payRuleLineDetailLines[0].Rate_Code__c));
                if(secordthresholdHrs > 0){
                    if(remainingHrs > secordthresholdHrs){
                        if(payRuleLineDetailLines[0].Rate_Code_After_Number_of_Hours__c == null){
                            throw new DataException('Rate Code After Number of Hours must not be blank for billing rule ' + recordLookupString);
                        }
                        hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code_After_Number_of_Hours__c, secordthresholdHrs);
                        if(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c == null){
                            throw new DataException('Rate Code for Remaining Hours must not be blank for billing rule ' + recordLookupString);
                        }
                        hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c, hoursByRateCode.get(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c) + remainingHrs - secordthresholdHrs);
                    } else {
                        if(payRuleLineDetailLines[0].Rate_Code_After_Number_of_Hours__c == null){
                            throw new DataException('Rate Code After Number of Hours must not be blank for billing rule ' + recordLookupString);
                        }
                        hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code_After_Number_of_Hours__c, hoursByRateCode.get(payRuleLineDetailLines[0].Rate_Code_After_Number_of_Hours__c) + remainingHrs);
                    }
                } else {
                    if(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c == null){
                        throw new DataException('Rate Code for Remaining Hours must not be blank for billing rule ' + recordLookupString);
                    }
                    hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c, hoursByRateCode.get(payRuleLineDetailLines[0].Rate_Code_for_Remaining_Hours__c) + remainingHrs);
                }
            } else {
                if(payRuleLineDetailLines[0].Rate_Code__c == null){
                    throw new DataException('Rate Code must not be blank for billing rule ' + recordLookupString);
                }
                hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code__c, hoursByRateCode.get(payRuleLineDetailLines[0].Rate_Code__c) + totalHours);
            }
        }
        //System.debug('Info: Hour Base hoursByRateCode ' + hoursByRateCode);
        return hoursByRateCode;
    }

    public Map<String, Decimal> calcDayBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Time startTime, Time endTime){
        Decimal totalHours = TimeUtils.calculateHours(startTime, endTime);
        Map<String, Decimal> hoursByRateCode = this.calcDayBasedHours(payRuleLineDetailLines, totalHours);
        return hoursByRateCode;
    }

    public Map<String, Decimal> calcDayBasedHours(List<Pay_Rule_Line_Detail__c> payRuleLineDetailLines, Decimal totalHours){
        //System.debug('Info: Day Base payRuleLineDetailLines ' + payRuleLineDetailLines[0]);
        Map<String, Decimal> hoursByRateCode = new Map<String, Decimal>();
        if(payRuleLineDetailLines.size() > 0) {
            hoursByRateCode.put(payRuleLineDetailLines[0].Rate_Code__c, totalHours);
        }
        //System.debug('Info: Day Base hoursByRateCode ' + hoursByRateCode);
        return hoursByRateCode;
    }


    public void reallocateTimesForTimesheetLines(Timesheet_Line__c tsLine1, Timesheet_Line__c tsLine2){
        tsLine2.End_Time__c = tsLine1.End_Time__c;

        //re-calculate Start Time and End Time for the timesheet lines
        Decimal lunchHours = tsLine1.Lunch_Hours__c;

        tsLine1.End_Time__c =
                tsLine1.Start_Time__c.addMilliseconds(Integer.valueOf(tsLine1.Total_Hours__c * 60 * 60 * 1000));

        tsLine2.Start_Time__c = tsLine1.End_Time__c;

        //re-allocate hours and times if there is lunch hours
        if(lunchHours > 0) {
            Time lunchST = tsLine1.Lunch_Start_Time__c;
            Time lunchET = tsLine1.Lunch_End_Time__c;

            if(lunchST >= tsLine1.End_Time__c) {
                tsLine2.Lunch_Start_Time__c = lunchST;
                tsLine2.Lunch_End_Time__c = lunchET;
                tsLine2.Lunch_Hours__c = lunchHours;

                tsLine1.Lunch_Start_Time__c = null;
                tsLine1.Lunch_End_Time__c = null;
                tsLine1.Lunch_Hours__c = null;
            } else {
                /*
                Integer lunchInMinutes = 0;
                if(lunchHours == 0.5){
                    lunchInMinutes = 30;
                } else if (lunchHours == 1){
                    lunchInMinutes = 60;
                } else {
                }
                 */
                Integer lunchInMinutes = (60 * lunchHours).intValue();
                tsLine1.End_Time__c = tsLine1.End_Time__c.addMinutes(lunchInMinutes);
                tsLine2.Start_Time__c = tsLine1.End_Time__c;
            }
        }

        //Recalculate Totals
        tsLine1.Total_Hours__c =  TimeUtils.calculateHours(tsLine1.Start_Time__c, tsLine1.End_Time__c);
        tsLine1.Net_Hours__c = tsLine1.Total_Hours__c - CompanyMgmt.zeroIfNull(tsLine1.Lunch_Hours__c);

        tsLine2.Total_Hours__c = TimeUtils.calculateHours(tsLine2.Start_Time__c,tsLine2.End_Time__c);
        tsLine2.Net_Hours__c = tsLine2.Total_Hours__c - CompanyMgmt.zeroIfNull(tsLine2.Lunch_Hours__c);
    }

    /*
        Ticket#19667 Travel time will be affect by holiday pay code.
        Ticket#21128 Travel time
        Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
     */
    public void assignHolidayPayCode(List<Timesheet_Line__c> tslineLst){
        //System.debug('Info: ###assignHolidayPayCode begin###');

        Map<Date, Holiday__c> holidayMap = getHolidayMap();
        //Set<Id> payRuleIdSet = collectPayRuleIdsFromTimesheetLines(tslineLst);
        //Pay Rule Holiday Map key format (Pay_Rule__c + ':' + Date__c) : Pay_Rule_Holiday__c
        //not needed setPayRuleHolidayMap(payRuleIdSet);

        for(Timesheet_Line__c tsline:tslineLst){
            Resource__c employee = mapRes.get(tsline.Resource__c);
            Boolean isUnionEmployee = false;
            if(employee.Pay_Rule__c != null && employee.Pay_Rule__r.Type__c == 'Union'){
                isUnionEmployee = true;
            }
            //if(tsline.Time_Type__c == 'Prevailing Wage' || tsline.Time_Type__c == 'Travel Time'){

            /*
            if(tsline.Time_Type__c == 'Prevailing Wage'){
                String mapKey = tsline.Pay_Rule__c + ':' + tsline.Work_as_Resource_Type__c;
                if(!mapPayRuleResTypeWithHolidays.containsKey(mapKey)){
                    mapKey = theCompanySetup.Company_Pay_Rule__c + ':' + tsline.Work_as_Resource_Type__c;
                    if(mapPayRuleResTypeWithHolidays.containsKey(mapKey) && !mapPayRuleResTypeWithPayRuleLine.containsKey(mapKey)) {
                        tsline.Pay_Rule__c = theCompanySetup.Company_Pay_Rule__c;
                    }
                }
            }

            if((tsLine.Time_Type__c == 'Job Time' || tsline.Time_Type__c == 'Prevailing Wage')
                    && tsline.Pay_Rule__c == theCompanySetup.Company_Pay_Rule__c
                    && tsline.Scheduled_Date__c != null
                    && holidayMap.containsKey(tsline.Scheduled_Date__c)){
                Holiday__c holiday = holidayMap.get(tsline.Scheduled_Date__c);
                if(String.isNotBlank(holiday.Holiday_Name_Map__c)){
                    List<String> holidayNames = holiday.Holiday_Name_Map__c.split(';');
                    for(String holidayName : holidayNames){
                        if(payCodeByCompanyHoliday.containsKey(holidayName)){
                            tsline.Time_Type_Code__c = payCodeByCompanyHoliday.get(holidayName);
                            break;
                        }
                    }
                }
            }
             */

            if((tsline.Time_Type__c == 'Job Time' || tsline.Time_Type__c == 'Prevailing Wage' || tsline.Time_Type__c == 'Travel Time' || tsline.Time_Type__c == 'Shop Time')
                    && String.isNotBlank(tsline.Pay_Rule__c) && tsline.Scheduled_Date__c != null
                    && holidayMap.containsKey(tsline.Scheduled_Date__c)){

                Id payRuleIdForLookup = tsline.Pay_Rule__c;
                Id resTypeForLookup = tsline.Work_as_Resource_Type__c;

                if(tsline.Time_Type__c == 'Travel Time' && isUnionEmployee == true){
                    payRuleIdForLookup = employee.Pay_Rule__c;
                    resTypeForLookup = employee.Resource_Type__c;
                //Ticket#25406 >>
                //} else if((tsline.Time_Type__c == 'Job Time' || tsline.Time_Type__c == 'Prevailing Wage' || tsline.Time_Type__c == 'Shop Time') &&
                } else if((tsline.Time_Type__c == 'Job Time' || tsline.Time_Type__c == 'Shop Time') &&
                //Ticket#25406 <<
                        (mapPayRuleResTypeWithHolidays.containsKey(payRuleIdForLookup + ':' + resTypeForLookup) == false) &&
                        isUnionEmployee == true){
                    payRuleIdForLookup = employee.Pay_Rule__c;
                    resTypeForLookup = employee.Resource_Type__c;
                }

                //System.debug('Info: resTypeForLookup>>> ' + resTypeForLookup);
                //System.debug('Info: payRuleIdForLookup>>> ' + payRuleIdForLookup);
                //System.debug('Info: mapPayRuleResTypeWithHolidays >>> ' + mapPayRuleResTypeWithHolidays);
                Boolean holidayPayFound = false;
                if(String.isNotBlank(resTypeForLookup)
                    && mapPayRuleResTypeWithHolidays.containsKey(payRuleIdForLookup + ':' + resTypeForLookup)) {
                    Holiday__c holiday = holidayMap.get(tsline.Scheduled_Date__c);
                    if (String.isNotBlank(holiday.Holiday_Name_Map__c)) {
                        List<String> holidayNames = holiday.Holiday_Name_Map__c.split(';');
                        for (String holidayName : holidayNames) {
                            String mapKey = payRuleIdForLookup + ':' + resTypeForLookup + ':' + holidayName;
                            if (payRuleResTypeWithOverTimeHolidayPayCodeSet.contains(mapKey)) {
                                tsline.Time_Type_Code__c = theCompanySetup.Overtime_Rate__c;
                                holidayPayFound = true;
                            }

                            if (payRuleResTypeWithDobuleTimeHolidayPayCodeSet.contains(mapKey)) {
                                tsline.Time_Type_Code__c = theCompanySetup.Double_Time_Rate__c;
                                holidayPayFound = true;
                            }

                            if (holidayPayFound == true) {
                                if (tsline.Time_Type__c == 'Travel Time') {
                                    tsline.Pay_Rule__c = payRuleIdForLookup;
                                }
                                break;
                            }
                        }
                    }
                }

                //get company default holiday pay code
                if(holidayPayFound == false && isUnionEmployee == false){
                    if((tsLine.Time_Type__c == 'Job Time' || tsline.Time_Type__c == 'Prevailing Wage' || tsline.Time_Type__c == 'Shop Time')
                            && tsline.Scheduled_Date__c != null
                            && holidayMap.containsKey(tsline.Scheduled_Date__c)){
                        Holiday__c holiday = holidayMap.get(tsline.Scheduled_Date__c);
                        if(String.isNotBlank(holiday.Holiday_Name_Map__c)){
                            List<String> holidayNames = holiday.Holiday_Name_Map__c.split(';');
                            for(String holidayName : holidayNames){
                                if(payCodeByCompanyHoliday.containsKey(holidayName)){
                                    tsline.Time_Type_Code__c = payCodeByCompanyHoliday.get(holidayName);
                                    break;
                                }
                            }
                        }
                    }
                }
            }

        }
        //System.debug('Info: ###assignHolidayPayCode end###');
    }

    public set<Id> collectPayRuleIdsFromTimesheetLines(List<Timesheet_Line__c> tslLst) {
        set<Id> payRuleIdSet = new Set<Id>();
        for (Timesheet_Line__c tsLine : tslLst) {
            if (String.isNotBlank(tsLine.Pay_Rule__c)) {
                payRuleIdSet.add(tsLine.Pay_Rule__c);
            }
        }
        return payRuleIdSet;
    }

    public void setResourceHolidayTaken(Set<Id> resIdSet, Date startDate, Date endDate){
        List<Resource_Off__c> resOffLst = getResOffListByResIdByDateByTypeName(resIdSet, startDate, endDate, new List<String>{'Holiday'});
        for(Resource_Off__c resOff:resOffLst){
            resHolidayTakenSet.add(resOff.Resource__c + ':' + resOff.Date__c);
        }
    }

    public List<Timesheet__c> setTimesheetReopenReasonCode(List<Timesheet__c> timesheetLst, Map<Id, String> mapResTsReopenReason){
        for(TimeSheet__c ts:timesheetLst){
            if(mapResTsReopenReason.containsKey(ts.Resource__c)) ts.Status_Message__c = mapResTsReopenReason.get(ts.Resource__c);
        }
        update timesheetLst;
        return timesheetLst;
    }

    public void setPayRuleResTypeWithPayRuleLineMap(Map<String, Pay_Rule__c> payRuleMap){
        for(Pay_Rule__c payRule : payRuleMap.values()){
            for(Pay_Rule_Line__c payRuleLine:payRule.Pay_Rule_Lines__r){
                mapPayRuleResTypeWithPayRuleLine.put(payRule.Id + ':' + payRuleLine.Resource_Type__c, payRuleLine);
                payRuleLinesByIds.put(payRuleLine.Id, payRuleLine); //Ticket#22782
            }
        }
    }

    /*Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
    public void setPayRuleResTypeWithHolidayMap(Map<String, Pay_Rule__c> payRuleMap){
        for(Pay_Rule__c payRule : payRuleMap.values()){
            for(Pay_Rule_Line__c payRuleLine:payRule.Pay_Rule_Lines__r){
                mapPayRuleResTypeWithHolidays.put(payRule.Id + ':' + payRuleLine.Resource_Type__c, payRuleLine.Eligible_Holidays__c);

            }
        }
    }
     */

    /*
        Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
     */
    public void setPayRuleResTypeHolidayPayCodeSet(Map<String, Pay_Rule__c> payRuleMap){
        for(Pay_Rule__c payRule : payRuleMap.values()){
            for(Pay_Rule_Line__c payRuleLine:payRule.Pay_Rule_Lines__r){
                String holidayNames = null;
                if(String.isNotBlank(payRuleLine.Holidays_with_Overtime_Pay__c)){
                    for(String holiday:payRuleLine.Holidays_with_Overtime_Pay__c.split(';')){
                        payRuleResTypeWithOverTimeHolidayPayCodeSet.add(payRule.Id + ':' + payRuleLine.Resource_Type__c + ':' + holiday);
                    }
                    holidayNames = payRuleLine.Holidays_with_Overtime_Pay__c; //Ticket#23635
                }

                if(String.isNotBlank(payRuleLine.Holiday_with_Double_Time_Pay__c)){
                    for(String holiday:payRuleLine.Holiday_with_Double_Time_Pay__c.split(';')){
                        payRuleResTypeWithDobuleTimeHolidayPayCodeSet.add(payRule.Id + ':' + payRuleLine.Resource_Type__c + ':' + holiday);
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
                    mapPayRuleResTypeWithHolidays.put(payRule.Id + ':' + payRuleLine.Resource_Type__c, holidayNames);
                }
                //Ticket#23635 <<
            }
        }
    }

    //Ticket#19667
    public void setPayRuleLineDetailMap(Set<Id> payRuleLineIds){
        for(Pay_Rule_Line_Detail__c payRuleLineDetail : [
                SELECT Name, Calculation_Type__c, Day__c, Start_Time__c, End_Time__c, Hours_After_Number_of_Hours__c, Id,
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
            payRuleLineDetailsByIds.put(payRuleLineDetail.Id, payRuleLineDetail); //Ticket#22944
        }
    }

    public void deleteHolidayResOff(Set<Id> resIds, Date startDate, Date endDate){
        Off_Type__c offType = [SELECT Id FROM Off_Type__c WHERE Name = 'Holiday' LIMIT 1];
        List<Resource_Off__c> resourceOffs = [SELECT Id, Off_Type__c FROM Resource_Off__c WHERE Off_Type__c = :offType.Id
            AND System_Created_Entry__c = true AND Date__c >= :startDate AND Date__c <= :endDate AND Resource__c IN :resIds];
        try{
            if(resourceOffs.size() > 0) delete resourceOffs;
        } catch (Exception e){
            throw e;
        }
    }

    public Boolean isPeakSeason(Date workDate, Pay_Rule_Line__c payRuleLine){
        if(workDate == null || payRuleLine.Peak_Season_Start__c == null || payRuleLine.Peak_Season_End__c == null){
            return false;
        } else {
            Integer workDateMonth = workDate.month();
            Integer workDateDay = workDate.day();
            Integer peakStartDateMonth = payRuleLine.Peak_Season_Start__c.month();
            Integer peakStartDateDay = payRuleLine.Peak_Season_Start__c.day();
            Integer peakEndDateMonth = payRuleLine.Peak_Season_End__c.month();
            Integer peakEndDateDay = payRuleLine.Peak_Season_End__c.day();

            if(workDateMonth >= peakStartDateMonth && workDateMonth <= peakEndDateMonth){
                if(workDateMonth == peakStartDateMonth && workDateMonth == peakEndDateMonth){
                    if(workDateDay >= peakStartDateDay && workDateDay <= peakEndDateDay){
                        return true;
                    }
                } else {
                    return true;
                }
            }
            return false;
        }
    }

    public Date calcBusinessDay(Date inputDate, Boolean isPrevious){
        if(inputDate == null){
            return inputDate;
        }
        Date calcDate;
        if(isPrevious == true){
            calcDate = inputDate.addDays(-1);
        } else {
            calcDate = inputDate.addDays(1);
        }

        String dayName = getDatetimeInUserTZ(calcDate).format('E');
        if(dayName == 'FRI' && mapCompanyHoliday.containsKey(calcDate)){
            return calcDate;
        }

        if(dayName != 'Sun' && dayName != 'Sat' && !mapCompanyHoliday.containsKey(calcDate)){
        //if(dayName != 'Sun' && dayName != 'Sat'){
            return calcDate;
        }

        return calcBusinessDay(calcDate, isPrevious);
    }

    public void setTMLineByIdsMap(List<TM_Line__c> tmLines){
        if(tmLines.size() > 0){
            tmLinesByIds.putAll(tmLines);
        }
    }

    public void setResourceFieldActivityLogMap(Set<Id> tmLineIds){
        List<Field_Activity_Log__c> fieldActivityLogs = [
                SELECT Id, T_M_Line__c, Equipment__c, Resource_Type__c, Start_Time__c, End_Time__c
                FROM Field_Activity_Log__c
                WHERE T_M_Line__c IN :tmLineIds ORDER BY T_M_Line__c, Start_Time__c];
        fieldActivityLogByIds.putAll(fieldActivityLogs);
        for(Field_Activity_Log__c fieldActivityLog: fieldActivityLogs){
            Id tmlLineId = fieldActivityLog.T_M_Line__c;
            List<Field_Activity_Log__c> tempFieldActivityLogs = new List<Field_Activity_Log__c>();
            if(fieldActivityLogByTMLineIds.containsKey(tmlLineId)){
                tempFieldActivityLogs = fieldActivityLogByTMLineIds.get(tmlLineId);
            }
            tempFieldActivityLogs.add(fieldActivityLog);
            fieldActivityLogByTMLineIds.put(tmlLineId, tempFieldActivityLogs);
        }
    }

    public void unionTravelTimeProcessor(List<Timesheet_Line__c> timesheetLines, TM_Line__c tmLine, Timesheet_Line__c timesheetLine){
        if(isEligibleForDispatchFromHomePay(tmLine) == true){
            Timesheet_Line__c unionTravelTime = new Timesheet_Line__c();
            Decimal utrvHours = 1;
            if(tmLine.TM__r.Sales_Order__r.Distance_to_Job_Site__c == 'GREATER_THAN_FORTY_MILES'){
                utrvHours = 2;
            }
            unionTravelTime = createSysCalcLine(timesheetLine, null, null, utrvHours, 'Travel Time', 'UTRV');
            timesheetLines.add(unionTravelTime);
        }
    }

    public void unionLaobrProcessor(List<Timesheet_Line__c> timesheetLines, TM_Line__c tmLine, Timesheet_Line__c timesheetLine, Boolean isOvernightShift, Boolean isSecondDay){
        //System.debug('Info: unionLaobrProcessor begin >> ');
        Resource__c resource = mapRes.get(tmLine.Resource__c);
        if(fieldActivityLogByTMLineIds.containsKey(tmLine.Id)) {
            List<Field_Activity_Log__c> fieldActivityLogs = fieldActivityLogByTMLineIds.get(tmLine.Id);
            if (String.isNotBlank(resource.Pay_Rule__c) && fieldActivityLogs.size() > 0) {
                Pay_Rule__c payRule = mapPayRules.get(resource.Pay_Rule__c);
                Pay_Rule__c pwPayRule = mapPayRules.get(tmLine.TM__r.Sales_Order__r.Pay_Rule__c);
                if (payRule.Type__c == 'Union' && payRule.Enable_Dispatch_from_Home_Pay__c == true) {
                    Time tslStartTime = timesheetLine.Start_Time__c;
                    Time tslEndTime = timesheetLine.End_Time__c;
                    Decimal totalHours = TimeUtils.calculateHours(tslStartTime, tslEndTime);
                    //System.debug('Info: tsl times ' + tslStartTime + ' -- ' + tslEndTime);
                    Map<Time, Time> activityLogTimeEntries = new Map<Time, Time>();
                    Map<String, Id> workAsTypeByTimeString = new Map<String, Id>();
                    Map<Time, Time> jobTimeEntries = new Map<Time, Time>();
                    //System.debug('Info: isSecondDay ' + isSecondDay);
                    for(Field_Activity_Log__c fieldActivityLog: fieldActivityLogs){
                        //System.debug('Info: fieldActivityLog ' + fieldActivityLog);
                        if(isOvernightShift){
                            if(fieldActivityLog.End_Time__c < fieldActivityLog.Start_Time__c && fieldActivityLog.End_Time__c != TimeUtils.midNight()){
                                if(isSecondDay == false){
                                    activityLogTimeEntries.put(fieldActivityLog.Start_Time__c, TimeUtils.midNight());
                                } else {
                                    activityLogTimeEntries.put(TimeUtils.midNight(), fieldActivityLog.End_Time__c);
                                }
                            } else {
                                if(fieldActivityLog.End_Time__c <= tslEndTime || (tslEndTime == TimeUtils.midNight() && fieldActivityLog.Start_Time__c >= tslStartTime)){
                                    activityLogTimeEntries.put(fieldActivityLog.Start_Time__c, fieldActivityLog.End_Time__c);
                                }
                            }
                        } else {
                            activityLogTimeEntries.put(fieldActivityLog.Start_Time__c, fieldActivityLog.End_Time__c);
                            String mapKey = String.valueOf(fieldActivityLog.Start_Time__c) + '-' + String.valueOf(fieldActivityLog.End_Time__c);
                            workAsTypeByTimeString.put(mapKey, fieldActivityLog.Resource_Type__c);
                        }
                    }

                    //System.debug('Info: activityLogTimeEntries ' + activityLogTimeEntries);
                    //System.debug('Info: workAsTypeByTimeString ' + workAsTypeByTimeString);
                    List<Time> startTimes = new List<Time>();
                    startTimes.addAll(activityLogTimeEntries.keySet());
                    startTimes.sort();

                    for(Time actStartTime: startTimes){
                        Time actEndTime = activityLogTimeEntries.get(actStartTime);
                        //System.debug('Info: actStartTime ' + actStartTime);
                        //System.debug('Info: actEndTime ' + actEndTime);
                        //System.debug('Info: tslStartTime ' + tslStartTime);
                        //System.debug('Info: tslEndTime ' + tslEndTime);
                        jobTimeEntries.put(actStartTime, actEndTime);
                        if(actStartTime == tslStartTime && actEndTime != tslEndTime){
                            tslStartTime = actEndTime;
                        }

                        //System.debug('Info: actStartTime2 ' + actStartTime);
                        //System.debug('Info: actEndTime2 ' + actEndTime);
                        //System.debug('Info: tslStartTime2 ' + tslStartTime);
                        //System.debug('Info: tslEndTime2 ' + tslEndTime);

                        if(actStartTime > tslStartTime){
                            jobTimeEntries.put(tslStartTime, actStartTime);
                            tslStartTime = actEndTime;
                        }
                        //System.debug('Info: actStartTime3 ' + actStartTime);
                        //System.debug('Info: actEndTime3 ' + actEndTime);
                        //System.debug('Info: tslStartTime3 ' + tslStartTime);
                        //System.debug('Info: tslEndTime3 ' + tslEndTime);
                    }

                    //System.debug('Info: tslStartTime4 ' + tslStartTime);
                    //System.debug('Info: tslEndTime4 ' + tslEndTime);

                    //System.debug('Info: jobTimeEntries ' + jobTimeEntries);
                    timesheetLine.Start_Time__c = tslStartTime;
                    timesheetLine.End_Time__c = tslEndTime;
                    //jobTimeEntries.put(tslStartTime, tslEndTime);

                    Decimal hoursAllocated = 0;
                    for(Time startTime: jobTimeEntries.keySet()){
                        Time endTime = jobTimeEntries.get(startTime);
                        Double hours = TimeUtils.calculateHours(startTime, endTime);
                        hoursAllocated += hours;
                        Timesheet_Line__c pwTSL = createSysCalcLine(timesheetLine, startTime, endTime, hours, timesheetLine.Time_Type__c, timesheetLine.Time_Type_Code__c);
                        String mapKey = String.valueOf(startTime) + '-' + String.valueOf(endTime);
                        if(workAsTypeByTimeString.containsKey(mapKey)){
                            Id resTypeId = workAsTypeByTimeString.get(mapKey);
                            //System.debug('Info: resTypeId ' + resTypeId);
                            if(String.isNotBlank(resTypeId)){
                                pwTSL.Work_as_Resource_Type__c = resTypeId;
                            }
                        }
                        //System.debug('Info: pwTSL ' + pwTSL);
                        timesheetLines.add(pwTSL);
                    }
                    //System.debug('Info totalHours ' + totalHours);
                    //System.debug('Info hoursAllocated ' + hoursAllocated);
                    if(totalHours == hoursAllocated){
                        //zero out Timesheet Line
                        timesheetLine.Start_Time__c = TimeUtils.midNight();
                        timesheetLine.End_Time__c = TimeUtils.midNight();
                    }
                    /*
                    System.debug('Info: timesheetLines ' + timesheetLines.size());
                    for(Timesheet_Line__c tsl : timesheetLines){
                        System.debug('Info: tsl ' + tsl);
                    }
                     */
                }
            }
        }
        //System.debug('Info: unionLaobrProcessor end >> ');
    }

    /*
    public void processTimesheetWithPayRuleLineDetails(List<Timesheet_Line__c> timesheetLineList) {
        //System.debug('Info: processTimesheetWithPayRuleLineDetails >>');
        Map<String, List<Timesheet_Line__c>> timesheetLinesByTimesheetIds = new Map<String, List<Timesheet_Line__c>>();
        for (Timesheet_Line__c tsLine : timesheetLineList) {
            //System.debug('Info: xx Time Type Code: ' + tsLine.Time_Type_Code__c + ' -- Detail Rule Id: ' + tsLine.Pay_Rule_Line_Detail__c + ' -- Calculation Type: ' + tsLine.Pay_Rule_Line_Detail__r.Calculation_Type__c);
            //if(tsLine.Time_Type_Code__c == 'REG' && tsLine.Pay_Rule_Line_Detail__c != null
            if(tsLine.Pay_Rule_Line_Detail__c != null && tsLine.Pay_Rule_Line_Detail__r.Calculation_Type__c == 'Hour_Based') {
                //System.debug('Info: 1 new line: ' + tsLine.Week_Day__c + ' -- Pay Code: ' + tsLine.Time_Type_Code__c + ' -- hours: ' + tsLine.Net_Hours__c);
                if (timesheetLinesByTimesheetIds.containsKey(tsLine.Timesheet__c)) {
                    List<Timesheet_Line__c> tsLineList = timesheetLinesByTimesheetIds.get(tsLine.Timesheet__c);
                    tsLineList.add(tsLine);
                    timesheetLinesByTimesheetIds.put(tsLine.Timesheet__c, tsLineList);
                } else {
                    timesheetLinesByTimesheetIds.put(tsLine.Timesheet__c, new List<Timesheet_Line__c>{
                            tsLine
                    });
                }
            }
        }

        for(String timesheetId : timesheetLinesByTimesheetIds.keySet()){
            List<Timesheet_Line__c> newLines = new List<Timesheet_Line__c>();
            List<Timesheet_Line__c> tsLinesList = timesheetLinesByTimesheetIds.get(timesheetId);
            Map<Id, Map<String, Decimal>> dailyTotalHoursByDayNameByPayRuleLineDetailId = new Map<Id, Map<String, Decimal>>();
            TimesheetLineWrapper[] timesheetLineWrappers = new List<TimesheetLineWrapper>();
            Map<Id, Map<String, Decimal>> resourceDailyWorkedHoursByResIds = new Map<Id, Map<String, Decimal>>(); //Ticket#23239
            for(Timesheet_Line__c timesheetLine : tsLinesList){
                Map<String, Decimal> dailyTotalHrsByDayName = new Map<String, Decimal>();
                Decimal dailyTotalHrs = 0;
                if (dailyTotalHoursByDayNameByPayRuleLineDetailId.containsKey(timesheetLine.Pay_Rule_Line_Detail__c)) {
                    dailyTotalHrsByDayName = dailyTotalHoursByDayNameByPayRuleLineDetailId.get(timesheetLine.Pay_Rule_Line_Detail__c);
                }
                if (dailyTotalHrsByDayName.containsKey(timesheetLine.Week_Day__c)) {
                    dailyTotalHrs = dailyTotalHrsByDayName.get(timesheetLine.Week_Day__c);
                }
                dailyTotalHrs = dailyTotalHrs + timesheetLine.Net_Hours__c;
                dailyTotalHrsByDayName.put(timesheetLine.Week_Day__c, dailyTotalHrs);
                dailyTotalHoursByDayNameByPayRuleLineDetailId.put(timesheetLine.Pay_Rule_Line_Detail__c, dailyTotalHrsByDayName);
                timesheetLineWrappers.add(new TimesheetLineWrapper(timesheetLine));
            }

            if(timesheetLineWrappers.size() > 0){
                //Sort by Scheduled Date and by Start Time(ASC)
                timesheetLineWrappers.sort();
            }

            Map<String, List<Timesheet_Line__c>> timesheetLinesByPayRuleLineDetailIdAndWeekdayName = new Map<String, List<Timesheet_Line__c>>();
            for(TimesheetLineWrapper tsLineWrapper : timesheetLineWrappers) {
                String payRuleDetailIdWithWeekDayName = tsLineWrapper.theTL.Pay_Rule_Line_Detail__c + tsLineWrapper.theTL.Week_Day__c;
                List<Timesheet_Line__c> tempTimesheetLines = new List<Timesheet_Line__c>();
                if(timesheetLinesByPayRuleLineDetailIdAndWeekdayName.containsKey(payRuleDetailIdWithWeekDayName)){
                    tempTimesheetLines = timesheetLinesByPayRuleLineDetailIdAndWeekdayName.get(payRuleDetailIdWithWeekDayName);
                }
                tempTimesheetLines.add(tsLineWrapper.theTL);
                timesheetLinesByPayRuleLineDetailIdAndWeekdayName.put(payRuleDetailIdWithWeekDayName, tempTimesheetLines);
            }

            for(Id payRuleLineDetailId : dailyTotalHoursByDayNameByPayRuleLineDetailId.keySet()){
                for(String dayName : dailyTotalHoursByDayNameByPayRuleLineDetailId.get(payRuleLineDetailId).keySet()){
                    Decimal dailyTotalHr = dailyTotalHoursByDayNameByPayRuleLineDetailId.get(payRuleLineDetailId).get(dayName);
                    if(dailyTotalHr > 0){
                        Map<String, Decimal> hoursByRateCode = calcHourBasedHours(new List<Pay_Rule_Line_Detail__c>{payRuleLineDetailsByIds.get(payRuleLineDetailId)}, dailyTotalHr);
                        Decimal regHr = hoursByRateCode.get('REG');
                        Decimal overtimeHr = hoursByRateCode.get('OT');
                        Decimal doubleTimeHr = hoursByRateCode.get('DT');
                        List<Timesheet_Line__c> tsLines = timesheetLinesByPayRuleLineDetailIdAndWeekdayName.get(payRuleLineDetailId + dayName);
                        //System.debug('Info: hoursByRateCode: ' + hoursByRateCode);
                        for (Timesheet_Line__c tsLine : tsLines) {
                            //System.debug('Info: 1 new line: ' + tsLine.Week_Day__c + ' -- Pay Code: ' + tsLine.Time_Type_Code__c + ' -- hours: ' + tsLine.Net_Hours__c);
                            Decimal remainingHr = tsLine.Net_Hours__c;
                            if (regHr > 0) {
                                remainingHr = remainingHr - regHr;
                                if (remainingHr == 0) {
                                    regHr = 0;
                                    continue;
                                } else if (remainingHr > 0) {
                                    regHr = 0;
                                } else if (remainingHr < 0) {
                                    regHr = Math.abs(remainingHr);
                                    continue;
                                }
                            }

                            //Timesheet_Line__c tempOTLine = new Timesheet_Line__c();
                            //Boolean tempOTLineCreated = false;
                            //Boolean newOTLineNeeded = false;
                            if (overtimeHr > 0 && remainingHr > 0) {
                                //System.debug('Info: 1 overtimeHr: ' + overtimeHr + ' remainingHr: ' + remainingHr);
                                Decimal otLineHr = overtimeHr;
                                remainingHr = remainingHr - overtimeHr;
                                if (remainingHr == 0) {
                                    overtimeHr = 0;
                                } else if (remainingHr > 0) {
                                    overtimeHr = 0;
                                } else if (remainingHr < 0) {
                                    otLineHr = remainingHr + overtimeHr;
                                    overtimeHr = Math.abs(remainingHr);
                                }

                                if (otLineHr > 0) {
                                    //System.debug('Info: 1 tsLine.Net_Hours__c: ' + tsLine.Net_Hours__c + ' otLineHr: ' + otLineHr + ' remainingHr: ' + remainingHr);
                                    if (tsLine.Net_Hours__c == otLineHr) {
                                        tsLine.Time_Type_Code__c = 'O/T';
                                    } else {
                                        tsLine.Net_Hours__c = tsLine.Net_Hours__c - otLineHr;
                                        tsLine.Total_Hours__c = tsLine.Net_Hours__c;
                                        Timesheet_Line__c newLine = new Timesheet_Line__c();
                                        Time tempStartTime = tsLine.Start_Time__c;
                                        Time tempEndTime = tsLine.End_Time__c;
                                        tsLine.Start_Time__c = null;
                                        tsLine.End_Time__c = null;
                                        newLine = createSysCalcLine(tsLine,
                                                tempStartTime,
                                                tempEndTime,
                                                otLineHr,
                                                tsLine.Time_Type__c,
                                                theCompanySetup.Overtime_Rate__c);
                                        reallocateTimesForTimesheetLines(newLine, tsLine);
                                        newLines.add(newLine);
                                        //System.debug('Info: 1 tsLine ' + tsLine.Week_Day__c + ' -- Pay Code: ' + tsLine.Time_Type_Code__c + ' Net Hours: '+ tsLine.Net_Hours__c + ' -- ' + tsLine.Start_Time__c + ' -- ' + tsLine.End_Time__c);
                                        //System.debug('Info: 1 newLine ' + newLine.Week_Day__c + ' -- Pay Code: ' + newLine.Time_Type_Code__c + ' Net Hours: '+ newLine.Net_Hours__c + ' -- ' + newLine.Start_Time__c + ' -- ' + newLine.End_Time__c);
                                    }
                                }
                            }

                            if (doubleTimeHr > 0 && remainingHr > 0) {
                                Decimal dtLineHr = doubleTimeHr;
                                remainingHr = remainingHr - doubleTimeHr;
                                if (remainingHr == 0) {
                                    doubleTimeHr = 0;
                                } else if (remainingHr > 0) {
                                    doubleTimeHr = 0;
                                } else if (remainingHr < 0) {
                                    dtLineHr = remainingHr + dtLineHr;
                                    dtLineHr = Math.abs(remainingHr);
                                }

                                if (dtLineHr > 0) {
                                    if (tsLine.Net_Hours__c == dtLineHr) {
                                        tsLine.Time_Type_Code__c = 'DBT';
                                    } else {
                                        tsLine.Net_Hours__c = tsLine.Net_Hours__c - dtLineHr;
                                        tsLine.Total_Hours__c = tsLine.Net_Hours__c;
                                        Timesheet_Line__c newLine = new Timesheet_Line__c();
                                        Time tempStartTime = tsLine.Start_Time__c;
                                        Time tempEndTime = tsLine.End_Time__c;
                                        tsLine.Start_Time__c = null;
                                        tsLine.End_Time__c = null;
                                        //Timesheet_Line__c tempParentLine = new Timesheet_Line__c();
                                        newLine = createSysCalcLine(tsLine,
                                                tempStartTime,
                                                tempEndTime,
                                                dtLineHr,
                                                tsLine.Time_Type__c,
                                                theCompanySetup.Double_Time_Rate__c);
                                        reallocateTimesForTimesheetLines(newLine, tsLine);
                                        newLines.add(newLine);
                                        //System.debug('Info: 1 tempParentLine ' + tempParentLine.Week_Day__c + ' -- Pay Code: ' + tempParentLine.Time_Type_Code__c + ' Net Hours: '+ tempParentLine.Net_Hours__c + ' -- ' + tempParentLine.Start_Time__c + ' -- ' + tempParentLine.End_Time__c);
                                        //System.debug('Info: 1 newLine ' + newLine.Week_Day__c + ' -- Pay Code: ' + newLine.Time_Type_Code__c + ' Net Hours: '+ newLine.Net_Hours__c + ' -- ' + newLine.Start_Time__c + ' -- ' + newLine.End_Time__c);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if(newLines.size() > 0){
                timesheetLineList.addAll(newLines);
            }
        }
        //System.debug('Info: processTimesheetWithPayRuleLineDetails <<');
    }    
     */

    public void processTimesheetWithPayRuleLineDetails2(List<Timesheet_Line__c> timesheetLineList) {
        //System.debug('Info: processTimesheetWithPayRuleLineDetails >>');
        Map<String, List<Timesheet_Line__c>> timesheetLinesByTimesheetIds = new Map<String, List<Timesheet_Line__c>>();
        Map<String, List<Timesheet_Line__c>> timesheetLinesByResIdAndWeekdayName = new Map<String, List<Timesheet_Line__c>>();

        for (Timesheet_Line__c tsLine : timesheetLineList) {
            if(tsLine.Pay_Rule_Line_Detail__c != null) {
                List<Timesheet_Line__c> tempTimesheetLines = new List<Timesheet_Line__c>();
                if (timesheetLinesByTimesheetIds.containsKey(tsLine.Timesheet__c)) {
                    tempTimesheetLines = timesheetLinesByTimesheetIds.get(tsLine.Timesheet__c);
                }
                tempTimesheetLines.add(tsLine);
                timesheetLinesByTimesheetIds.put(tsLine.Timesheet__c, tempTimesheetLines);

                tempTimesheetLines = new List<Timesheet_Line__c>();
                String resIdAndWeekDayName = tsLine.Resource__c + ':' + tsLine.Week_Day__c;
                if(timesheetLinesByResIdAndWeekdayName.containsKey(resIdAndWeekDayName)){
                    tempTimesheetLines = timesheetLinesByResIdAndWeekdayName.get(resIdAndWeekDayName);
                }
                tempTimesheetLines.add(tsLine);
                timesheetLinesByResIdAndWeekdayName.put(resIdAndWeekDayName, tempTimesheetLines);
            }
        }

        for(String resIdAndDayName : timesheetLinesByResIdAndWeekdayName.keySet()){
            //System.debug('Info: resIdAndDayName: ' + resIdAndDayName);
            Map<Id, Map<String, Decimal>> resourceDailyWorkedHoursByResIds = new Map<Id, Map<String, Decimal>>();
            TimesheetLineWrapper[] timesheetLineWrappers = new List<TimesheetLineWrapper>();
            for(Timesheet_Line__c tsLine : timesheetLinesByResIdAndWeekdayName.get(resIdAndDayName)){
                timesheetLineWrappers.add(new TimesheetLineWrapper(tsLine));
            }

            if(timesheetLineWrappers.size() > 0){
                //Sort by Scheduled Date and by Start Time(ASC)
                timesheetLineWrappers.sort();
            }

            String resId = resIdAndDayName.split(':')[0];
            String workDay = resIdAndDayName.split(':')[1];
            Decimal workedHr = 0;
            //System.debug('Info: resId: ' + resId);
            //System.debug('Info: workDay: ' + workDay);
            //System.debug('Info: resourceDailyWorkedHoursByResIds: ' + resourceDailyWorkedHoursByResIds);
            for(TimesheetLineWrapper tsLineWrapper : timesheetLineWrappers) {
                //System.debug('Info: Line ' + tsLineWrapper.theTL.Week_Day__c + ' >>>>>> ');
                Decimal lineNetHrs = tsLineWrapper.theTL.Net_Hours__c;
                Map<String, Decimal> resourceDailyWorkedHr = new Map<String, Decimal>();
                if (resourceDailyWorkedHoursByResIds.containsKey(resId)) {
                    resourceDailyWorkedHr = resourceDailyWorkedHoursByResIds.get(resId);
                    //System.debug('Info: resourceDailyWorkedHr: ' + resourceDailyWorkedHr);
                    if (resourceDailyWorkedHr.containsKey(workDay)) {
                        workedHr = resourceDailyWorkedHr.get(workDay);
                        //System.debug('Info: resourceDailyWorkedHr workedHr: ' + workedHr);
                    }
                }
                resourceDailyWorkedHr.put(workDay, workedHr + lineNetHrs);
                //System.debug('Info: resourceDailyWorkedHr 2: ' + resourceDailyWorkedHr);
                resourceDailyWorkedHoursByResIds.put(resId, resourceDailyWorkedHr);
                Id payruleLineId = tsLineWrapper.theTL.Pay_Rule_Line_Detail__c;
                Pay_Rule_Line_Detail__c payRuleLineDetail = payRuleLineDetailsByIds.get(payruleLineId);
                //System.debug('Info: ' + payRuleLineDetail);
                if (payRuleLineDetail.Calculation_Type__c == 'Hour_Based') {
                    List<Timesheet_Line__c> relatedLines = new List<Timesheet_Line__c>();

                    Decimal tempDailyTotal = workedHr + lineNetHrs;
                    //System.debug('Info: tmLine: ' +  tsLineWrapper.theTL.Week_Day__c + ' -- ' + tsLineWrapper.theTL.Start_Time__c + ' -- ' + tsLineWrapper.theTL.End_Time__c);
                    //System.debug('Info: tempDailyTotal ' + tempDailyTotal);
                    Map<String, Decimal> hoursByRateCode = calcHourBasedHours(new List<Pay_Rule_Line_Detail__c>{
                            payRuleLineDetail
                    }, tempDailyTotal);
                    //System.debug('Info: hoursByRateCode: ' + hoursByRateCode);
                    Decimal regHr = hoursByRateCode.get('REG');
                    Decimal overtimeHr = hoursByRateCode.get('OT');
                    Decimal doubleTimeHr = hoursByRateCode.get('DT');
                    Decimal tempWorkedHr = workedHr;
                    /*
                    System.debug('Info: regHr: ' + regHr);
                    System.debug('Info: overtimeHr: ' + overtimeHr);
                    System.debug('Info: doubleTimeHr: ' + doubleTimeHr);
                    System.debug('Info: tempWorkedHr: ' + tempWorkedHr);
                     */
                    Integer count = 0;
                    while (tempWorkedHr > 0) {
                        count++;
                        tempWorkedHr = tempWorkedHr - regHr;
                        //System.debug('Info: tempWorkedHr after reg hr deduction: ' + tempWorkedHr);
                        if (tempWorkedHr <= 0) {
                            if (tempWorkedHr == 0) {
                                regHr = 0;
                            } else {
                                regHr = Math.abs(tempWorkedHr);
                            }
                            break;
                        } else {
                            regHr = 0;
                        }

                        tempWorkedHr = tempWorkedHr - overtimeHr;
                        //System.debug('Info: tempWorkedHr after ot hr deduction: ' + tempWorkedHr);
                        if (tempWorkedHr <= 0) {
                            if (tempWorkedHr == 0) {
                                overtimeHr = 0;
                            } else {
                                overtimeHr = Math.abs(tempWorkedHr);
                            }
                            break;
                        } else {
                            overtimeHr = 0;
                        }

                        tempWorkedHr = tempWorkedHr - doubleTimeHr;
                        //System.debug('Info: tempWorkedHr after dt hr deduction: ' + tempWorkedHr);
                        if (tempWorkedHr <= 0) {
                            if (tempWorkedHr == 0) {
                                doubleTimeHr = 0;
                            } else {
                                doubleTimeHr = Math.abs(tempWorkedHr);
                            }
                        } else {
                            doubleTimeHr = 0;
                        }
                        if (count > 10){
                            break;
                        }
                    }
                    /*
                    System.debug('Info: regHr: ' + regHr);
                    System.debug('Info: overtimeHr: ' + overtimeHr);
                    System.debug('Info: doubleTimeHr: ' + doubleTimeHr);
                     */
                    Decimal remainingHr = lineNetHrs;
                    Decimal calcualtedOTHrs = 0;
                    Decimal calcualtedDTHrs = 0;
                    if (regHr > 0) {
                        remainingHr = remainingHr - regHr;
                        if (remainingHr == 0) {
                            regHr = 0;
                            continue;
                        } else if (remainingHr > 0) {
                            regHr = 0;
                        } else if (remainingHr < 0) {
                            regHr = Math.abs(remainingHr);
                            continue;
                        }
                    }
                    //System.debug('Info: after regHr');

                    if (overtimeHr > 0 && remainingHr > 0) {
                        //System.debug('Info: 1 overtimeHr: ' + overtimeHr + ' remainingHr: ' + remainingHr);
                        //Decimal otLineHr = overtimeHr;
                        calcualtedOTHrs = overtimeHr;
                        remainingHr = remainingHr - overtimeHr;
                        if (remainingHr == 0) {
                            overtimeHr = 0;
                        } else if (remainingHr > 0) {
                            overtimeHr = 0;
                        } else if (remainingHr < 0) {
                            calcualtedOTHrs = remainingHr + overtimeHr;
                            overtimeHr = Math.abs(remainingHr);
                        }

                        if (calcualtedOTHrs > 0) {
                            //System.debug('Info: 1 tsLine.Net_Hours__c: ' + tsLineWrapper.theTL.Net_Hours__c + ' otLineHr: ' + calcualtedOTHrs + ' remainingHr: ' + remainingHr);
                            if (lineNetHrs == calcualtedOTHrs) {
                                tsLineWrapper.theTL.Time_Type_Code__c = 'O/T';
                            } else {
                                tsLineWrapper.theTL.Net_Hours__c = tsLineWrapper.theTL.Net_Hours__c - calcualtedOTHrs;
                                tsLineWrapper.theTL.Total_Hours__c = tsLineWrapper.theTL.Net_Hours__c;
                                Timesheet_Line__c newLine = new Timesheet_Line__c();
                                newLine = createSysCalcLine(tsLineWrapper.theTL,
                                        null,
                                        null,
                                        calcualtedOTHrs,
                                        tsLineWrapper.theTL.Time_Type__c,
                                        theCompanySetup.Overtime_Rate__c);
                                relatedLines.add(newLine);
                                /*
                                System.debug('Info: 1 tsLine ' + tsLineWrapper.theTL.Week_Day__c + ' -- Pay Code: ' + tsLineWrapper.theTL.Time_Type_Code__c + ' Net Hours: ' + tsLineWrapper.theTL.Net_Hours__c + ' -- ' + tsLineWrapper.theTL.Start_Time__c + ' -- ' + tsLineWrapper.theTL.End_Time__c);
                                System.debug('Info: 1 newLine ' + newLine.Week_Day__c + ' -- Pay Code: ' + newLine.Time_Type_Code__c + ' Net Hours: ' + newLine.Net_Hours__c + ' -- ' + newLine.Start_Time__c + ' -- ' + newLine.End_Time__c);
                                 */
                            }
                        }
                    }

                    if (doubleTimeHr > 0 && remainingHr > 0) {
                        //Decimal dtLineHr = doubleTimeHr;
                        calcualtedDTHrs = doubleTimeHr;
                        remainingHr = remainingHr - doubleTimeHr;
                        /*
                        System.debug('Info: dtLineHr: ' + calcualtedDTHrs);
                        System.debug('Info: remainingHr: ' + remainingHr);
                         */
                        if (remainingHr == 0) {
                            doubleTimeHr = 0;
                        } else if (remainingHr > 0) {
                            doubleTimeHr = 0;
                        } else if (remainingHr < 0) {
                            calcualtedDTHrs = remainingHr + doubleTimeHr;
                            doubleTimeHr = Math.abs(remainingHr);
                        }

                        if (calcualtedDTHrs > 0) {
                            if (tsLineWrapper.theTL.Net_Hours__c == calcualtedDTHrs) {
                                //System.debug('Debug: ' + relatedLines.size());
                                //System.debug('Debug: #relatedLines[0] line ' + relatedLines[0].Week_Day__c + relatedLines[0].Time_Type_Code__c + relatedLines[0].Net_Hours__c + ' -- ' + relatedLines[0].Start_Time__c + ' -- ' + relatedLines[0].End_Time__c);
                                if(relatedLines.size() > 0 && relatedLines[0].Net_Hours__c == tsLineWrapper.theTL.Net_Hours__c){
                                    relatedLines[0].Time_Type_Code__c = 'DBT';
                                    tsLineWrapper.theTL.Time_Type_Code__c = 'O/T';
                                } else {
                                    tsLineWrapper.theTL.Time_Type_Code__c = 'DBT';
                                }
                            } else {
                                tsLineWrapper.theTL.Net_Hours__c = tsLineWrapper.theTL.Net_Hours__c - calcualtedDTHrs;
                                tsLineWrapper.theTL.Total_Hours__c = tsLineWrapper.theTL.Net_Hours__c;
                                Timesheet_Line__c newLine = new Timesheet_Line__c();
                                newLine = createSysCalcLine(tsLineWrapper.theTL,
                                        null,
                                        null,
                                        calcualtedDTHrs,
                                        tsLineWrapper.theTL.Time_Type__c,
                                        theCompanySetup.Double_Time_Rate__c);
                                relatedLines.add(newLine);
                                /*
                                System.debug('Info: 1 tempParentLine ' + tsLineWrapper.theTL.Week_Day__c + ' -- Pay Code: ' + tsLineWrapper.theTL.Time_Type_Code__c + ' Net Hours: ' + tsLineWrapper.theTL.Net_Hours__c + ' -- ' + tsLineWrapper.theTL.Start_Time__c + ' -- ' + tsLineWrapper.theTL.End_Time__c);
                                System.debug('Info: 1 newLine ' + newLine.Week_Day__c + ' -- Pay Code: ' + newLine.Time_Type_Code__c + ' Net Hours: ' + newLine.Net_Hours__c + ' -- ' + newLine.Start_Time__c + ' -- ' + newLine.End_Time__c);
                                 */
                            }
                        }
                    }

                    if(relatedLines.size() > 0){
                        /*
                        System.debug('Info: Time reallocation >>>>');
                        System.debug('Info: relatedLines size: ' + relatedLines.size());
                        System.debug('Info: lineStartTime ' + lineStartTime);
                        System.debug('Info: lineEndTime ' + lineEndTime);
                         */
                        //tsLineWrapper.theTL.Start_Time__c = lineStartTime;
                        //tsLineWrapper.theTL.End_Time__c = lineEndTime;
                        /*
                        System.debug('Info: #tsLineWrapper line ' + tsLineWrapper.theTL.Net_Hours__c + ' -- ' + tsLineWrapper.theTL.Start_Time__c + ' -- ' + tsLineWrapper.theTL.End_Time__c);
                        System.debug('Info: #relatedLines[0] line ' + relatedLines[0].Net_Hours__c + ' -- ' + relatedLines[0].Start_Time__c + ' -- ' + relatedLines[0].End_Time__c);
                         */
                        reallocateTimesForTimesheetLines(tsLineWrapper.theTL, relatedLines[0]);
                        /*
                        System.debug('Info: tsLineWrapper line ' + tsLineWrapper.theTL.Net_Hours__c + ' -- ' + tsLineWrapper.theTL.Start_Time__c + ' -- ' + tsLineWrapper.theTL.End_Time__c);
                        System.debug('Info: relatedLines[0] line ' + relatedLines[0].Net_Hours__c + ' -- ' + relatedLines[0].Start_Time__c + ' -- ' + relatedLines[0].End_Time__c);
                         */
                        if(relatedLines.size() == 2){
                            /*
                            System.debug('Info: #relatedLines[0] line ' + relatedLines[0].Net_Hours__c + ' -- ' +  relatedLines[0].Start_Time__c + ' -- ' + relatedLines[0].End_Time__c);
                            System.debug('Info: #relatedLines[1] line ' + relatedLines[1].Net_Hours__c + ' -- ' +  relatedLines[1].Start_Time__c + ' -- ' + relatedLines[1].End_Time__c);
                             */
                            relatedLines[0].Net_Hours__c = calcualtedOTHrs;
                            relatedLines[0].Total_Hours__c = calcualtedOTHrs;
                            reallocateTimesForTimesheetLines(relatedLines[0], relatedLines[1]);
                            /*
                            System.debug('Info: relatedLines[0] line ' + relatedLines[0].Net_Hours__c + ' -- ' +  relatedLines[0].Start_Time__c + ' -- ' + relatedLines[0].End_Time__c);
                            System.debug('Info: relatedLines[1] line ' + relatedLines[1].Net_Hours__c + ' -- ' +  relatedLines[1].Start_Time__c + ' -- ' + relatedLines[1].End_Time__c);
                             */
                        }
                        //System.debug('Info: Time reallocation <<<<');

                        timesheetLineList.addAll(relatedLines);
                    }
                }
                //System.debug('Info: Line ' + tsLineWrapper.theTL.Week_Day__c + ' <<<<<< ');
            }
        }
    }

    private Boolean isEligibleForDispatchFromHomePay(TM_Line__c tmLine){
        Boolean isEligible = false;
        Resource__c resource = mapRes.get(tmLine.Resource__c);
        if(mapRes.containsKey(tmLine.Resource__c) == false){
            System.debug('Error: Resource Not Found TM Line: ' + tmLine);
        }
        if(resource != null && String.isNotBlank(resource.Pay_Rule__c)){
            Pay_Rule__c payRule = mapPayRules.get(resource.Pay_Rule__c);
            if(payRule.Type__c == 'Union' && payRule.Enable_Dispatch_from_Home_Pay__c == true && tmLine.Eligible_Dispatch_from_Home_Pay__c == true){
                isEligible = true;
            }
        }
        return isEligible;
    }

    //Ticket#23713
    public void autoGeneratePayroll(Service_Center__c serviceCenter, Week_Number__c weekNumber){
        CompanyMgmt.systemCall = true;

        // Retrieve all resources including those with Sun-Sat pay period
        Date weekNumberStartDate = weekNumber.Week_Start_Date__c.addDays(-1);

        //Retrieve resources
        List<Resource__c> resources = ResourcesSelector.newInstance().selectPayrollEmployeeBySCIdByActivityDate(serviceCenter.Id, weekNumberStartDate);
 
        Set<Id> resIds = new Set<Id>();
        for(Resource__c resource : resources){
            resIds.add(resource.Id);
        }
        //Retrieve existing timesheets by week number and service center id
        List<Timesheet__c> timesheets = [SELECT Id, Name, Employee_No__c, Resource_Name__c, Total_Hours_Submitted__c,Resource__c, Resource__r.Pay_Rule__c,
                Resource__r.Pay_Rule__r.Type__c, Resource__r.Pay_Rule__r.Mon_Sun_Work_Week__c, Payroll__r.Status__c,Payroll__c, Payroll__r.Name, Starting_Date__c, Ending_Date__c, Resource__r.Resource_Type__c,
        (SELECT Time_Type__c, Time_Type_Code__c, Rate__c, Resource__c,
                Pay_Rule__c, Pay_Rule__r.Name,Scheduled_Date__c,
                Work_as_Resource_Type__c,Work_as_Resource_Type__r.Name,
                Sales_Order__c, T_M_Line__c, System_Created_Entry__c
        FROM Timesheet_Lines__r)
        FROM Timesheet__c
        WHERE Service_Center__c =: serviceCenter.Id
        AND Week_No__c = :weekNumber.Id];

        for(Timesheet__c timesheet : timesheets){
            mapResTimesheet.put(timesheet.Resource__c, timesheet);
        }
        refreshTimesheetForResources(weekNumber, serviceCenter.Id, resIds);
        List<Timesheet_Line__c> timesheetLines = [SELECT Id, Timesheet__c FROM Timesheet_Line__c WHERE Timesheet__r.Week_No__c = :weekNumber.Id AND Timesheet__r.Service_Center__c = :serviceCenter.Id];
        Set<Id> timesheetIds = new Set<Id>();
        for(Timesheet_Line__c timesheetLine : timesheetLines){
            timesheetIds.add(timesheetLine.Timesheet__c);
        }

        List<Timesheet__c> timesheetsCreated = [SELECT Id, Name, Employee_No__c, Resource_Name__c, Total_Hours_Submitted__c,Resource__c, Resource__r.Pay_Rule__c,
                Resource__r.Pay_Rule__r.Type__c, Resource__r.Pay_Rule__r.Mon_Sun_Work_Week__c, Payroll__r.Status__c,Payroll__c, Payroll__r.Name, Starting_Date__c, Ending_Date__c, Resource__r.Resource_Type__c,
        (SELECT Id, Time_Type__c, Time_Type_Code__c, Rate__c, Resource__c, Net_Hours__c, Sales_Order_Description__c,
                Pay_Rule__c, Pay_Rule__r.Name,Scheduled_Date__c, Prevailing_Wage_Job__c, Certified_PW_Job__c,
                Work_as_Resource_Type__c,Work_as_Resource_Type__r.Name, Customer_Name__c, TM__c,
                Sales_Order__c, T_M_Line__c, System_Created_Entry__c
        FROM Timesheet_Lines__r)
        FROM Timesheet__c WHERE Id IN :timesheetIds];

        delete [SELECT Id FROM Timesheet__c WHERE Week_No__c = :weekNumber.Id AND Service_Center__c = :serviceCenter.Id AND Id NOT IN :timesheetIds];
        //Create Payroll for the SC
        if(timesheetsCreated.size() > 0){
            Payroll__c payroll = new Payroll__c();
            payroll.Start_Date__c = weekNumber.Week_Start_Date__c;
            payroll.End_Date__c = weekNumber.Week_End_Date__c;
            payroll.Service_Center__c = serviceCenter.Id;
            payroll.Week_Number__c = weekNumber.Id;
            payroll.Year__c = weekNumber.Year__c;
            payroll.Status__c = 'Approved'; //Ticket#23713
            insert payroll;
            List<Payroll_Line__c> payrollLines = new List<Payroll_Line__c>();
            for(Timesheet__c timesheet : timesheetsCreated) {
                for (Timesheet_Line__c timesheetLine : timesheet.Timesheet_Lines__r) {
                    Payroll_Line__c payrollLine = new Payroll_Line__c();
                    payrollLine.Payroll__c = payroll.Id;
                    payrollLine.Pay_Code__c = timesheetLine.Time_Type_Code__c;
                    payrollLine.Resource__c = timesheet.Resource__c;
                    payrollLine.Resource_Name__c = timesheet.Resource_Name__c;
                    payrollLine.Net_Hours__c = CompanyMgmt.zeroIfNull(timesheetLine.Net_Hours__c);
                    payrollLine.Sales_Order__c = timesheetLine.Sales_Order__c;
                    payrollLine.Sales_Order_Description__c = timesheetLine.Sales_Order_Description__c;
                    payrollLine.Prevailing_Wage_Job__c = timesheetLine.Prevailing_Wage_Job__c;
                    payrollLine.Certified_PW_Job__c = timesheetLine.Certified_PW_Job__c;
                    payrollLine.Customer_Name__c = timesheetLine.Customer_Name__c;
                    payrollLine.Timesheet__c = timesheet.Id;
                    payrollLine.Timesheet_Line__c = timesheetLine.Id;
                    payrollLine.TM__c = timesheetLine.TM__c;
                    payrollLine.T_M_Line__c = timesheetLine.T_M_Line__c;
                    payrollLine.Work_as_Resource_Type__c = timesheetLine.Work_as_Resource_Type__c;
                    payrollLine.Pay_Rate__c = CompanyMgmt.zeroIfNull(timesheetLine.Rate__c);
                    payrollLine.Amount__c = timesheetLine.Net_Hours__c * payrollLine.Pay_Rate__c;
                    if (timesheetLine.Time_Type__c == 'Travel Time') {
                        if (payrollLine.Pay_Code__c == 'REG') {
                            payrollLine.Pay_Code__c = theCompanySetup.Travel_Time_Rate__c;
                        } else if (payrollLine.Pay_Code__c == 'O/T') {
                            payrollLine.Pay_Code__c = 'TVO';
                        } else if (payrollLine.Pay_Code__c == 'DBT') {
                            payrollLine.Pay_Code__c = 'TVD';
                        }
                    }
                    if (payrollLine.Prevailing_Wage_Job__c) {
                        if (payrollLine.Pay_Code__c == 'REG') {
                            payrollLine.Pay_Code__c = 'OW';
                        } else if (payrollLine.Pay_Code__c == 'O/T') {
                            payrollLine.Pay_Code__c = 'OP';
                        } else if (payrollLine.Pay_Code__c == 'DBT') {
                            payrollLine.Pay_Code__c = 'PD';
                        }
                    }
                    payrollLines.add(payrollLine);
                }
            }

            if(payrollLines.size() > 0){
                insert payrollLines;
                for(Timesheet__c timesheet : timesheetsCreated){
                    timesheet.Payroll__c = payroll.Id;
                    timesheet.Status__c = 'Payroll Created';
                }
                update timesheetsCreated;
            }
        }
    }

    public void processOvernightTravelTime(List<Timesheet_Line__c> tsLineLst, Date periodEndDate){
        List<Timesheet_Line__c> newTravelTimeEntries = new List<Timesheet_Line__c>();
        for(Timesheet_Line__c timesheetLine : tsLineLst){
            Time startTime = timesheetLine.Start_Time__c;
            Time endTime = timesheetLine.End_Time__c;
            if(timesheetLine.Time_Type__c == 'Travel Time' &&
                startTime > endTime &&
                endTime != TimeUtils.midNight())
            {
                //adjust times in travel entry before midnight (first day)
                timesheetLine.End_Time__c = TimeUtils.midNight();
                timesheetLine.Total_Hours__c = TimeUtils.calculateHours(timesheetLine.Start_Time__c, timesheetLine.End_Time__c);
                timesheetLine.Net_Hours__c = CompanyMgmt.zeroIfNull(timesheetLine.Total_Hours__c) - CompanyMgmt.zeroIfNull(timesheetLine.Lunch_Hours__c);

                //Ticket#25502 >>
                //Datetime newScheduleDateTime = TimeUtils.getDatetimeInUserTZ(timesheetLine.Scheduled_Date__c).addDays(1);
                Date tmScheduledDate = tmScheduledDateByTMId.get(timesheetLine.TM__c);
                Datetime newScheduleDateTime = TimeUtils.getDatetimeInUserTZ(tmScheduledDate).addDays(1);
                //Ticket#25502 <<
                if(newScheduleDateTime.dateGmt() <= periodEndDate) {
                    //create new entry for travel for time after midnight (second day)
                    startTime = timesheetLine.End_Time__c;
                    Decimal travelHrs = TimeUtils.calculateHours(startTime, endTime);
                    Timesheet_Line__c newTravelTimeEntry = createSysCalcLine(timesheetLine,
                            startTime,
                            endTime,
                            travelHrs,
                            'Travel Time',
                            theCompanySetup.Standard_Rate__c);

                    newTravelTimeEntry.Scheduled_Date__c = newScheduleDateTime.dateGmt();
                    newTravelTimeEntry.Week_Day__c = newScheduleDateTime.formatGMT('EEEE');
                    newTravelTimeEntry.Total_Hours__c = TimeUtils.calculateHours(newTravelTimeEntry.Start_Time__c, newTravelTimeEntry.End_Time__c);
                    newTravelTimeEntry.Net_Hours__c = CompanyMgmt.zeroIfNull(newTravelTimeEntry.Total_Hours__c) - CompanyMgmt.zeroIfNull(newTravelTimeEntry.Lunch_Hours__c);
                    //reallocateTimesForTimesheetLines(timesheetLine, newTravelTimeEntry);
                    newTravelTimeEntries.add(newTravelTimeEntry);
                }
            }
        }
        if(newTravelTimeEntries.size() > 0){
            tsLineLst.addAll(newTravelTimeEntries);
        }
    }

}