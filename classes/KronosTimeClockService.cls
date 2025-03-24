public with sharing class KronosTimeClockService {
    public static transient Map<Id, Resource__c> resourcesByIds = new Map<Id, Resource__c>();
    public static transient Map<Id, Pay_Rule__c> payRulesByIds = new Map<Id, Pay_Rule__c>();
    public static transient Map<String, Pay_Rule_Line__c> payRuleLineByPayRuleAndWorkAsResType = new Map<String, Pay_Rule_Line__c>();
    public static transient Map<Id, TM__c> tmsByIds = new Map<Id, TM__c>();
    public static final Date KRONOSCUTOFFDATE = Date.newInstance(2022,6,20);
    public static Boolean forceEntry = false;
    public static Boolean mondayExtraRun = false;
    public static Boolean loggerEnabled = false; //Ticket#25194

    public static void processEmployeeTimeDataByServiceCenter(Id serviceCenterId, Date startDate, Date endDate){
        /* Ticket#24245
        if(startDate == null){
            startDate = Date.today().addMonths(-6);
        }

        if(startDate < KRONOSCUTOFFDATE){
         */

        if(startDate == null || startDate < KRONOSCUTOFFDATE){
            startDate = KRONOSCUTOFFDATE;
        }
        //Ticket#24245

        if(endDate != null && endDate < startDate){
            throw new DataException('End Date cannot be earlier than the Start Date/Kronos cut off date 06/20/2022!');
        }

        /*
        resourcesByIds.putAll([SELECT Id,Resource_Type__c, Pay_Rule__c, Kronos_Time_Punch_Start_Date__c, Kronos_Time_Punch_End_Date__c FROM Resource__c WHERE Service_Center__c = :serviceCenterId
            AND Category__c = 'Labor' AND Employee_Type__c != NULL AND Employee_Type__c != 'Temp'
            AND Non_Payroll_Labor_Resource__c != TRUE AND FLSA__c = 'Non-Exempt' AND RSG_EIN__c != NULL AND RSG_EIN__c != ''
            AND Kronos_Time_Punch_Start_Date__c != NULL]);
         */

        resourcesByIds.putAll([SELECT Id,Resource_Type__c, Pay_Rule__c, Service_Center__c, Kronos_Time_Punch_Start_Date__c, Kronos_Time_Punch_End_Date__c, Kronos_Time_Punch_Enabled__c FROM Resource__c WHERE Service_Center__c = :serviceCenterId
        AND Kronos_Time_Punch_Start_Date__c != NULL]);

        Map<Id, TM_Line__c> tmLinesByIds = new Map<Id, TM_Line__c>(getTMLinesByResIdsAndDates(resourcesByIds.keySet(), startDate, endDate));
        Map<Id, Resource_Off__c> resourceOffsByIds = new Map<Id, Resource_Off__c>(getResourceOffEntriesByResIdsAndDates(resourcesByIds.keySet(), startDate, endDate));

        initData(tmLinesByIds.values());
        processTMLines(tmLinesByIds);
        processResOffEntries(resourceOffsByIds);

        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronos =
            [SELECT Id, Resource__c, Work_Date__c, Time__c, Time_Type__c, Entry_Type__c, Pay_Rule_Line__c, Sales_Order__c, T_M_Line__r.TM__c
                FROM Employee_Clocked_Time_for_Kronos__c
                WHERE Exported__c = FALSE AND Kronos_Action__c != 'Delete'
                ORDER BY Resource__c, Work_Date__c, Kronos_Action__c DESC NULLS LAST, Time__c];

        finalizedKronosTimeClockEntries(employeeClockedTimeForKronos);

        employeeClockedTimeForKronos =
            [SELECT Id, Resource__c, Work_Date__c, Time__c, Time_Type__c, Entry_Type__c, Pay_Rule_Line__c, Sales_Order__c, T_M_Line__r.TM__c
            FROM Employee_Clocked_Time_for_Kronos__c
            WHERE Exported__c = FALSE AND Kronos_Action__c != 'Delete'
            ORDER BY Resource__c, Work_Date__c, Kronos_Action__c DESC NULLS LAST, Time__c];
        System.debug('Info: employeeClockedTimeForKronos ' + employeeClockedTimeForKronos.size());
        finalKronosTimeClockEntriesCleansing(employeeClockedTimeForKronos);
    }

    public static void processEmployeeTimeDataByResource(Id resourceId, Date startDate, Date endDate){
        /* Ticket#24245
        if(startDate == null){
            startDate = Date.today().addMonths(-6);
        }

        if(startDate < KRONOSCUTOFFDATE){
         */

        if(startDate == null || startDate < KRONOSCUTOFFDATE){
            startDate = KRONOSCUTOFFDATE;
        }
        //Ticket#24245

        if(endDate != null && endDate < startDate){
            throw new DataException('End Date cannot be earlier than the Start Date/Kronos cut off date 06/20/2022!');
        }

        resourcesByIds.putAll([SELECT Id,Resource_Type__c, Pay_Rule__c, Service_Center__c, Kronos_Time_Punch_Start_Date__c, Kronos_Time_Punch_End_Date__c, Kronos_Time_Punch_Enabled__c FROM Resource__c WHERE Id = :resourceId
        AND Category__c = 'Labor' AND RSG_EIN__c != NULL AND RSG_EIN__c != '' AND Kronos_Time_Punch_Start_Date__c != NULL]);

        Map<Id, TM_Line__c> tmLinesByIds = new Map<Id, TM_Line__c>(getTMLinesByResIdsAndDates(resourcesByIds.keySet(), startDate, endDate));
        Map<Id, Resource_Off__c> resourceOffsByIds = new Map<Id, Resource_Off__c>(getResourceOffEntriesByResIdsAndDates(resourcesByIds.keySet(), startDate, endDate));

        initData(tmLinesByIds.values());
        System.debug(tmLinesByIds);
        processTMLines(tmLinesByIds);
        processResOffEntries(resourceOffsByIds);

        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronos =
            [SELECT Id, Resource__c, Work_Date__c, Time__c, Entry_Type__c, Time_Type__c, Pay_Rule_Line__c, Sales_Order__c, T_M_Line__r.TM__c
                FROM Employee_Clocked_Time_for_Kronos__c
                WHERE Exported__c = FALSE AND Kronos_Action__c != 'Delete'
                ORDER BY Resource__c, Work_Date__c, Kronos_Action__c DESC NULLS LAST, Time__c];

        finalizedKronosTimeClockEntries(employeeClockedTimeForKronos);

        employeeClockedTimeForKronos =
            [SELECT Id, Resource__c, Work_Date__c, Time__c, Time_Type__c, Entry_Type__c, Pay_Rule_Line__c, Sales_Order__c, T_M_Line__r.TM__c
            FROM Employee_Clocked_Time_for_Kronos__c
            WHERE Exported__c = FALSE AND Kronos_Action__c != 'Delete'
            ORDER BY Resource__c, Work_Date__c, Kronos_Action__c DESC NULLS LAST, Time__c];

        finalKronosTimeClockEntriesCleansing(employeeClockedTimeForKronos);
    }

    /* Not used
    public static void processTMLines(){
        List<TM_Line__c> tmLines = getTMLines(null, null);
        initData(tmLines);
        Map<Id, TM_Line__c> tmLinesByIds = new Map<Id, TM_Line__c>(tmLines);
        processTMLines(tmLinesByIds);
    }


    public static void processTMLines(Date startDate, Date endDate){
        List<TM_Line__c> tmLines = getTMLines(startDate, endDate);
        initData(tmLines);
        Map<Id, TM_Line__c> tmLinesByIds = new Map<Id, TM_Line__c>(tmLines);
        processTMLines(tmLinesByIds);
    }
    */

    /* Not used
    public static void processResOffEntries(Date startDate, Date endDate){
        List<Resource_Off__c> resourceOffEntries = getResourceOffEntries(startDate, endDate);
        Map<Id, Resource_Off__c> resourceOffsByIds = new Map<Id, Resource_Off__c>(resourceOffEntries);
        processResOffEntries(resourceOffsByIds);
    }


    public static List<TM_Line__c> getTMLines(Date startDate, Date endDate){
        String queryStr = 'SELECT Id, Scheduled_Date__c, Job_Start_Time__c, Job_End_Time__c, Lunch_Start_Time__c, Lunch_End_Time__c,' +
                'Site_Start_Time__c,Site_End_Time__c,TM__c,Category__c,TM__r.Status__c, TM__r.Scheduled_Date__c, ' +
                'TM__r.Sales_Order__r.Pay_Rule__c,TM__r.Sales_Order__c, Resource__r.Pay_Rule__c,Resource_Type__c, ' +
                'Resource__r.Resource_Type__c,Service_Center__r.Temporary__c,Service_Center__c,KronosTimeEntriesProcessed__c, Kronos_Integration_Note__c' +
                ' FROM TM_Line__c' +
                ' WHERE TM__r.Sales_Order__c != NULL AND Category__c = \'Labor\' AND Resource__c != NULL AND Resource_Type__c != NULL AND Service_Center__r.Temporary__c != TRUE ';

        if(forceEntry == false){
            queryStr += ' AND KronosTimeEntriesProcessed__c != TRUE';
        }

        if(startDate == null && endDate == null){
            queryStr += ' AND TM__r.Scheduled_Date__c > :KRONOSCUTOFFDATE';
        }
        if(startDate != null && endDate != null){
            queryStr += ' AND TM__r.Scheduled_Date__c >= :startDate AND TM__r.Scheduled_Date__c <= :endDate';
        }

        List<TM_Line__c> tmLines = Database.query(queryStr);
        return tmLines;
    }
     */

    public static List<TM_Line__c> getTMLinesByResIdsAndDates(Set<Id> resIds, Date startDate, Date endDate){
        String queryStr = 'SELECT Id, Scheduled_Date__c,Job_Start_Time__c, Job_End_Time__c, Lunch_Start_Time__c, Lunch_End_Time__c,' +
                'Site_Start_Time__c,Site_End_Time__c,TM__c,Category__c,TM__r.Status__c, TM__r.Scheduled_Date__c, ' + 
                'TM__r.Sales_Order__r.Pay_Rule__c,TM__r.Sales_Order__c, Resource__r.Pay_Rule__c,Resource_Type__c, Resource_Type__r.Name,' + 
                'Resource__r.Resource_Type__c,Service_Center__r.Temporary__c,Service_Center__c,KronosTimeEntriesProcessed__c,Kronos_Integration_Note__c ' +
                ' FROM TM_Line__c' +
                ' WHERE TM__r.Sales_Order__c != NULL AND Resource__c IN :resIds';

        if(forceEntry == false){
            queryStr += ' AND KronosTimeEntriesProcessed__c != TRUE';
        }

        if(startDate == null && endDate == null){
            queryStr += ' AND TM__r.Scheduled_Date__c >= :KRONOSCUTOFFDATE';
        }

        if(startDate != null && endDate != null){
            queryStr += ' AND TM__r.Scheduled_Date__c >= :startDate AND TM__r.Scheduled_Date__c <= :endDate';
        }

        //add order by
        queryStr += ' ORDER BY Resource__c, Scheduled_Date__c ASC NULLS LAST, Job_Start_Time__c ASC NULLS LAST';

        List<TM_Line__c> tmLines = Database.query(queryStr);
        return tmLines;
    }

    /* Not used
    public static List<Resource_Off__c> getResourceOffEntries(Date startDate, Date endDate){
        List<Resource_Off__c> resourceOffEntries = new List<Resource_Off__c>();
        String queryStr = 'SELECT Id, Resource__r.Description__c, Resource__r.RSG_EIN__c, Start_Time__c, End_Time__c, ' +
                'Lunch_Start_Time__c, Lunch_End_Time__c, Date__c, Service_Center__r.Shop_Time_Sales_Order__r.Name,' +
                ' Service_Center__r.Temporary__c, Resource__r.Kronos_Time_Punch_Start_Date__c, Resource__r.Kronos_Time_Punch_End_Date__c, Kronos_Integration_Note__c' +
                ' FROM Resource_Off__c ' +
                ' WHERE Off_Type__r.Name = \'Shop Time\'' +
                ' AND Service_Center__r.Temporary__c != TRUE AND Resource__r.Category__c = \'Labor\'';

        if(forceEntry == false){
            queryStr += ' AND KronosTimeEntriesProcessed__c != TRUE';
        }

        if(startDate == null && endDate == null){
            queryStr += ' AND Date__c > :KRONOSCUTOFFDATE';
        }

        if(startDate != null && endDate != null){
            queryStr += ' AND Date__c >= :startDate AND Date__c <= :endDate';
        }

        resourceOffEntries = Database.query(queryStr);

        return resourceOffEntries;
    }
     */

    public static List<Resource_Off__c> getResourceOffEntriesByResIdsAndDates(Set<Id> resIds, Date startDate, Date endDate){
        List<Resource_Off__c> resourceOffEntries = new List<Resource_Off__c>();
        String queryStr = 'SELECT Id, Resource__r.Description__c, Resource__r.RSG_EIN__c, Start_Time__c, End_Time__c, ' +
                'Lunch_Start_Time__c, Lunch_End_Time__c, Date__c, Service_Center__r.Shop_Time_Sales_Order__r.Name,' +
                ' Service_Center__r.Temporary__c, Resource__r.Kronos_Time_Punch_Start_Date__c, Resource__r.Kronos_Time_Punch_End_Date__c, Kronos_Integration_Note__c,' +
                ' Resource__r.Kronos_Time_Punch_Enabled__c' +
                ' FROM Resource_Off__c ' +
                ' WHERE Off_Type__r.Name = \'Shop Time\' AND Resource__c IN :resIds';

        if(forceEntry == false){
            queryStr += ' AND KronosTimeEntriesProcessed__c != TRUE';
        }

        if(startDate == null && endDate == null){
            queryStr += ' AND Date__c >= :KRONOSCUTOFFDATE';
        }

        if(startDate != null && endDate != null){
            queryStr += ' AND Date__c >= :startDate AND Date__c <= :endDate';
        }

        //add order by
        queryStr += ' ORDER BY Resource__c, Date__c ASC NULLS LAST, Start_Time__c ASC NULLS LAST';

        System.debug('QUERY STRING ---> '+queryStr);


        resourceOffEntries = Database.query(queryStr);
        System.debug(resourceOffEntries);

        return resourceOffEntries;
    }

    public static void initData(List<TM_Line__c> tmLines){
        Set<Id> payRuleIds = new Set<Id>();
        Set<Id> tmIds = new Set<Id>();
        Set<Id> resIds = new Set<Id>();
        for(TM_Line__c tmLine : tmLines) {
            if(tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                if(String.isNotBlank(tmLine.Resource__c)) {
                    resIds.add(tmLine.Resource__c);
                }
                if(String.isNotBlank(tmLine.TM__c)) {
                    tmIds.add(tmLine.TM__c);
                }
            }
        }

        if(resIds.size() > 0 && resourcesByIds.size() == 0) {
            resourcesByIds.putAll([SELECT Id, Resource_Type__c, Service_Center__c, Pay_Rule__c, Kronos_Time_Punch_Start_Date__c, Kronos_Time_Punch_End_Date__c, Kronos_Time_Punch_Enabled__c FROM Resource__c WHERE Id IN :resIds]);
        }

        if(tmIds.size() > 0) {
            tmsByIds.putAll([SELECT Id, Status__c, Scheduled_Date__c, Sales_Order__c, Sales_Order__r.Pay_Rule__c, Sales_Order__r.Pay_Rule__r.Type__c, Sales_Order__r.Bill_to_Customer_No__c, Sales_Order__r.Bill_to_Customer_No__r.Customer_Type__c FROM TM__c WHERE Id IN :tmIds]);
        }


        for(TM__c tm : tmsByIds.values()){
            if(String.isNotBlank(tm.Sales_Order__r.Pay_Rule__c)){
                payRuleIds.add(tm.Sales_Order__r.Pay_Rule__c);
            }
        }

        for(Resource__c resource : resourcesByIds.values()){
            if(String.isNotBlank(resource.Pay_Rule__c)){
                payRuleIds.add(resource.Pay_Rule__c);
            }
        }

        if(payRuleIds.size() > 0){
            setPayRuleMaps(payRuleIds);
        }
    }

    public static void processTMLines(Map<Id, TM_Line__c> tmLinesByIds){
        List<TM_Line__c> tmLinesNeedKronosEntries = new List<TM_Line__c>();
        Set<Id> tmLineIdsWhoseKronosEntriesCanBeRemoved = new Set<Id>();
        List<TM_Line__c> tmLinesNeedToUpdate = new List<TM_Line__c>();

        for(TM_Line__c tmLine : tmLinesByIds.values()){
            if(forceEntry == false) {
                Resource__c resource = resourcesByIds.get(tmLine.Resource__c);
                if (resource.Kronos_Time_Punch_Start_Date__c > tmLine.Scheduled_Date__c) {
                    tmLine.Kronos_Integration_Note__c = 'Auto marked as processed! Before Start Date' + resource.Kronos_Time_Punch_Start_Date__c + ' TM Line Scheduled Date: ' + tmLine.Scheduled_Date__c + ' time stamp: ' + System.now();
                    tmLine.KronosTimeEntriesProcessed__c = true;
                    tmLinesNeedToUpdate.add(tmLine);
                    continue;
                }

                if (resource.Kronos_Time_Punch_End_Date__c != null && tmLine.Scheduled_Date__c > resource.Kronos_Time_Punch_End_Date__c){
                    tmLine.Kronos_Integration_Note__c = 'Auto marked as processed! After End Date ' + resource.Kronos_Time_Punch_End_Date__c + ' TM Line Scheduled Date: ' + tmLine.Scheduled_Date__c + ' time stamp: ' + System.now();
                    tmLine.KronosTimeEntriesProcessed__c = true;
                    tmLinesNeedToUpdate.add(tmLine);
                    continue;
                }

                if (resource.Kronos_Time_Punch_End_Date__c == null && resource.Kronos_Time_Punch_Enabled__c == false){
                    tmLine.Kronos_Integration_Note__c = 'Auto marked as processed! Kronos Time Punch Disabled';
                    tmLine.KronosTimeEntriesProcessed__c = true;
                    tmLinesNeedToUpdate.add(tmLine);
                    continue;
                }
            }

            //Ticket#24285 >>
            if(tmLine.Job_Start_Time__c == tmLine.Site_Start_Time__c &&
                    tmLine.Site_Start_Time__c == tmLine.Site_End_Time__c && tmLine.Site_End_Time__c == tmLine.Job_End_Time__c &&
                    tmLine.Lunch_Start_Time__c == null && tmLine.Lunch_End_Time__c == null){
                tmLine.Kronos_Integration_Note__c = 'Auto marked as processed! Zero hour entry';
                tmLine.KronosTimeEntriesProcessed__c = true;
                tmLinesNeedToUpdate.add(tmLine);
                continue;
            }
            //Ticket#24285 <<

            tmLineIdsWhoseKronosEntriesCanBeRemoved.add(tmLine.Id);
            if(tmLine.TM__r.Status__c == TMsService.VOID_STATUS ||
                    tmLine.TM__r.Status__c == TMsService.OPEN_STATUS ||
                    tmLine.TM__r.Status__c == TMsService.SCHEDULED_STATUS ||
                    tmLine.TM__r.Status__c == TMsService.MOBILE_REVIEW_STATUS)
            {
                //allow Sunday T&M line to create Kronos when it still in Scheduled or Mobile Review status.
                if(TimeUtils.getWeekdayName(tmLine.Scheduled_Date__c) == 'Sunday' &&
                    tmLine.TM__r.Status__c == TMsService.MOBILE_REVIEW_STATUS)
                {
                    if(mondayExtraRun == true) {
                        tmLinesNeedKronosEntries.add(tmLine);
                    }
                } else {
                    tmLine.KronosTimeEntriesProcessed__c = true;
                    tmLinesNeedToUpdate.add(tmLine);
                }
            } else {
                tmLinesNeedKronosEntries.add(tmLine);
            }
        }

        processDeletedTMLines(tmLineIdsWhoseKronosEntriesCanBeRemoved);

        /*
        List<Employee_Clocked_Time_for_Kronos__c> existingTimeClockEntries =
            [SELECT Id, Exported__c, Kronos_Action__c FROM Employee_Clocked_Time_for_Kronos__c
                WHERE T_M_Line__c IN :tmLinesByIds.keySet()];
         */

        List<Employee_Clocked_Time_for_Kronos__c> entryNeedToBeUpsert = new List<Employee_Clocked_Time_for_Kronos__c>();

        /*
        for(Employee_Clocked_Time_for_Kronos__c timeClockEntry : existingTimeClockEntries){
            if(timeClockEntry.Exported__c == true && timeClockEntry.Kronos_Action__c != 'Delete'){
                timeClockEntry.Kronos_Action__c = 'Delete';
                timeClockEntry.Exported__c = false;
                entryNeedToBeUpsert.add(timeClockEntry);
            }
        }
         */

        for(TM_Line__c tmLine : tmLinesNeedKronosEntries){
            List<Employee_Clocked_Time_for_Kronos__c> timeClockEntries = new List<Employee_Clocked_Time_for_Kronos__c>();
            timeClockEntries = generateKronosClockEntriesForTMLine(tmLine);
            if(timeClockEntries.size() > 0){
                entryNeedToBeUpsert.addAll(timeClockEntries);
                tmLine.KronosTimeEntriesProcessed__c = true;
                tmLinesNeedToUpdate.add(tmLine);
            }
        }

        if(tmLinesNeedToUpdate.size() > 0){
            CompanyMgmt.byPassLineTrigger = true;
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.systemCall = true; //Ticket#24469
            update tmLinesNeedToUpdate;
        }

        if(entryNeedToBeUpsert.size() > 0){
            CompanyMgmt.systemCall = true; //Ticket#23796
            upsert entryNeedToBeUpsert;
        }
    }

    public static void processResOffEntries(Map<Id, Resource_Off__c> resourceOffEntryByIds){
        /*
        List<Employee_Clocked_Time_for_Kronos__c> existingTimeClockEntries = [
                SELECT Id, Exported__c, Kronos_Action__c FROM Employee_Clocked_Time_for_Kronos__c
                WHERE Resource_Off__c IN :resourceOffEntryByIds.keySet()
        ];

        */

        List<Employee_Clocked_Time_for_Kronos__c> entryNeedToBeUpsert = new List<Employee_Clocked_Time_for_Kronos__c>();

        /*
        for(Employee_Clocked_Time_for_Kronos__c timeClockEntry : existingTimeClockEntries){
            if(timeClockEntry.Exported__c == true){
                timeClockEntry.Kronos_Action__c = 'Delete';
                timeClockEntry.Exported__c = false;
                entryNeedToBeUpsert.add(timeClockEntry);
            }
        }
         */

        //Delete existing time clock entries for the resource off records.
        processDeletedResourceOffLine(resourceOffEntryByIds.keySet());

        List<Resource_Off__c> resourceOffEntriesToUpdate = new List<Resource_Off__c>();
        for(Resource_Off__c resourceOff : resourceOffEntryByIds.values()){

            if(forceEntry == false) {
                if (resourceOff.Resource__r.Kronos_Time_Punch_Start_Date__c > resourceOff.Date__c) {
                    resourceOff.Kronos_Integration_Note__c = 'Auto marked as processed! Before Start Date' + resourceOff.Resource__r.Kronos_Time_Punch_Start_Date__c + ' Shop Time Date: ' + resourceOff.Date__c + ' time stamp: ' + System.now();
                    resourceOff.KronosTimeEntriesProcessed__c = true;
                    resourceOffEntriesToUpdate.add(resourceOff);
                    continue;
                }

                if (resourceOff.Resource__r.Kronos_Time_Punch_End_Date__c != null && resourceOff.Date__c > resourceOff.Resource__r.Kronos_Time_Punch_End_Date__c){
                    resourceOff.Kronos_Integration_Note__c = 'Auto marked as processed! After End Date'  + resourceOff.Resource__r.Kronos_Time_Punch_End_Date__c + ' Shop Time Date: ' + resourceOff.Date__c + ' time stamp: ' + System.now();
                    resourceOff.KronosTimeEntriesProcessed__c = true;
                    resourceOffEntriesToUpdate.add(resourceOff);
                    continue;
                }

                if (resourceOff.Resource__r.Kronos_Time_Punch_End_Date__c == null && resourceOff.Resource__r.Kronos_Time_Punch_Enabled__c == false){
                    resourceOff.Kronos_Integration_Note__c = 'Auto marked as processed! Kronos Time Punch Disabled';
                    resourceOff.KronosTimeEntriesProcessed__c = true;
                    resourceOffEntriesToUpdate.add(resourceOff);
                    continue;
                }
            }

            List<Employee_Clocked_Time_for_Kronos__c> timeClockEntries = new List<Employee_Clocked_Time_for_Kronos__c>();
            timeClockEntries = generateKronosClockEntriesForResOffEntry(resourceOff);
            if (timeClockEntries.size() > 0) {
                entryNeedToBeUpsert.addAll(timeClockEntries);
                resourceOff.KronosTimeEntriesProcessed__c = true;
                resourceOffEntriesToUpdate.add(resourceOff);
            }
        }

        if(entryNeedToBeUpsert.size() > 0){
            CompanyMgmt.systemCall = true; //Ticket#23796
            upsert entryNeedToBeUpsert;
        }

        if(resourceOffEntriesToUpdate.size() > 0){
            CompanyMgmt.byPassLineTrigger = true;
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.systemCall = true; //Ticket#24469
            update resourceOffEntriesToUpdate;
        }
    }

    /* For on confirm or real time process
    public static void processTMLines(Map<String, List<TM_Line__c>> tmLinesByTypes, Set<Id> employeeLineIds){
        List<TM_Line__c> tmLineWithoutChanges = tmLinesByTypes.get('LineWithoutChanges');
        List<TM_Line__c> tmLinesUpdated = tmLinesByTypes.get('LineWithChanges');

        System.debug('Kronos: process TML Lines!');
        Set<Id> existingEntriesTMLineIds = new Set<Id>();
        List<Employee_Clocked_Time_for_Kronos__c> existingTimeClockEntries =
            [SELECT Id, Resource__c, Work_Date__c, Time__c, Time_Type__c, Time_Type_Code__c, Exported__c, Kronos_Action__c,
                    Sales_Order__c, T_M__c, T_M__r.Scheduled_Date__c, T_M__r.Sales_Order__c, T_M__r.Sales_Order__r.Pay_Rule__c,
                    T_M_Line__c, T_M_Line__r.Resource__c, T_M_Line__r.Job_Start_Time__c,
                    T_M_Line__r.Job_End_Time__c, T_M_Line__r.Site_Start_Time__c, T_M_Line__r.Site_End_Time__c, T_M_Line__r.Lunch_Start_Time__c,
                    T_M_Line__r.Lunch_End_Time__c, T_M_Line__r.Resource__r.Pay_Rule__c
            FROM Employee_Clocked_Time_for_Kronos__c
            WHERE T_M_Line__c IN :employeeLineIds];

        Map<Id, List<Employee_Clocked_Time_for_Kronos__c>> timeClockEntriesByTMLineIds = new Map<Id, List<Employee_Clocked_Time_for_Kronos__c>>();
        for(Employee_Clocked_Time_for_Kronos__c timeClockEntry : existingTimeClockEntries){
            existingEntriesTMLineIds.add(timeClockEntry.T_M_Line__c);
            List<Employee_Clocked_Time_for_Kronos__c> timeClockEntries = new List<Employee_Clocked_Time_for_Kronos__c>();
            if(timeClockEntriesByTMLineIds.containsKey(timeClockEntry.T_M_Line__c)){
                timeClockEntries = timeClockEntriesByTMLineIds.get(timeClockEntry.T_M_Line__c);
            }
            timeClockEntries.add(timeClockEntry);
            timeClockEntriesByTMLineIds.put(timeClockEntry.T_M_Line__c, timeClockEntries);
        }

        //T&M Line does not have change but does not have kronos clock entry
        for(TM_Line__c tmLine : tmLineWithoutChanges){
            if(existingEntriesTMLineIds.contains(tmLine.Id) == false){
                tmLinesUpdated.add(tmLine);
            }
        }

        List<Employee_Clocked_Time_for_Kronos__c> entryCanBeDeleted = new List<Employee_Clocked_Time_for_Kronos__c>();
        List<Employee_Clocked_Time_for_Kronos__c> entryNeedToBeUpsert = new List<Employee_Clocked_Time_for_Kronos__c>();
        for(TM_Line__c tmLine : tmLinesUpdated){
            if(timeClockEntriesByTMLineIds.containsKey(tmLine.Id)){
                List<Employee_Clocked_Time_for_Kronos__c> tmLineExistingTimeClockEntries = timeClockEntriesByTMLineIds.get(tmLine.Id);
                for(Employee_Clocked_Time_for_Kronos__c clockEntry : tmLineExistingTimeClockEntries){
                    if(clockEntry.Exported__c == true){
                        clockEntry.Kronos_Action__c = 'Delete';
                        entryNeedToBeUpsert.add(clockEntry);
                    } else {
                        entryCanBeDeleted.add(clockEntry);
                    }
                }
            }
        }

        if(entryCanBeDeleted.size() > 0){
            delete entryCanBeDeleted;
        }


        if(tmLinesUpdated.size() > 0) {
            for(TM_Line__c tmLine : tmLinesUpdated){
                entryNeedToBeUpsert.addAll(generateKronosClockEntriesForTMLine(tmLine));
            }
        }

        if(entryNeedToBeUpsert.size() > 0){
            upsert entryNeedToBeUpsert;
        }
    }
     */

    public static void processDeletedTMLines(Set<Id> tmLineIds){
        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosLst =
            [SELECT Id, Kronos_Action__c, Exported__c FROM Employee_Clocked_Time_for_Kronos__c WHERE T_M_Line__c IN :tmLineIds];

        deleteKronosTimeClockEnties(employeeClockedTimeForKronosLst);
    }

    public static void processUnconfirmedTM(Set<Id> tmIds){
        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosEntries = [
                SELECT Id, Kronos_Action__c, Exported__c FROM Employee_Clocked_Time_for_Kronos__c WHERE T_M__c IN :tmIds];
        deleteKronosTimeClockEnties(employeeClockedTimeForKronosEntries);
    }

    public static void processDeletedResourceOffLine(Set<Id> resOffEntriesIds){
        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosLst =
        [SELECT Id, Kronos_Action__c, Exported__c FROM Employee_Clocked_Time_for_Kronos__c WHERE Resource_Off__c IN :resOffEntriesIds];

        deleteKronosTimeClockEnties(employeeClockedTimeForKronosLst);
    }

    public static void processIntegrationDisabledResource(Map<Id, Resource__c> resourcesByIds) {
        Date transactionDate = System.today();
        Date startOfWeek = TimeUtils.toStartOfWeek(transactionDate);
        List<Employee_Clocked_Time_for_Kronos__c> timeClockEntriesToBeDeleted = new List<Employee_Clocked_Time_for_Kronos__c>();

        for(Employee_Clocked_Time_for_Kronos__c timeClockEntry : [SELECT Id, Work_Date__c, Resource__c FROM Employee_Clocked_Time_for_Kronos__c WHERE Work_Date__c >= :startOfWeek AND Resource__c IN :resourcesByIds.keySet()]){
            Resource__c resource = resourcesByIds.get(timeClockEntry.Resource__c);
            if(timeClockEntry.Work_Date__c > resource.Kronos_Time_Punch_End_Date__c){
                timeClockEntriesToBeDeleted.add(timeClockEntry);
            }
        }
        deleteKronosTimeClockEnties(timeClockEntriesToBeDeleted);
    }

    public static void processIntegrationEnabledResource(Map<Id, Resource__c> resourcesByIds) {
        Date transactionDate = System.today();
        Date startOfWeek = TimeUtils.toStartOfWeek(transactionDate);
        List<TM_Line__c> tmLinesToUpdate = new List<TM_Line__c>();
        List<Resource_Off__c> resourceOffsToUpdate = new List<Resource_Off__c>();
        for(TM_Line__c tmLine : [SELECT Id, Resource__c, TM__r.Scheduled_Date__c, KronosTimeEntriesProcessed__c, Kronos_Integration_Note__c FROM TM_Line__c WHERE Resource__c IN :resourcesByIds.keySet() AND TM__r.Scheduled_Date__c >= :startOfWeek AND KronosTimeEntriesProcessed__c = TRUE]){
            Resource__c resource = resourcesByIds.get(tmLine.Resource__c);
            if(tmLine.TM__r.Scheduled_Date__c >= resource.Kronos_Time_Punch_Start_Date__c){
                tmLine.KronosTimeEntriesProcessed__c = false;
                tmLine.Kronos_Integration_Note__c = null;
                tmLinesToUpdate.add(tmLine);
            }
        }

        for(Resource_Off__c resourceOff : [SELECT Id, Resource__c, Date__c, KronosTimeEntriesProcessed__c, Kronos_Integration_Note__c FROM Resource_Off__c WHERE Resource__c IN :resourcesByIds.keySet() AND Date__c >= :startOfWeek AND KronosTimeEntriesProcessed__c = TRUE]){
            Resource__c resource = resourcesByIds.get(resourceOff.Resource__c);
            if(resourceOff.Date__c >= resource.Kronos_Time_Punch_Start_Date__c){
                resourceOff.KronosTimeEntriesProcessed__c = false;
                resourceOff.Kronos_Integration_Note__c = null;
                resourceOffsToUpdate.add(resourceOff);
            }
        }

        if(tmLinesToUpdate.size() > 0){
            update tmLinesToUpdate;
        }

        if(resourceOffsToUpdate.size() > 0){
            update resourceOffsToUpdate;
        }
    }

    public static void deleteKronosTimeClockEnties(List<Employee_Clocked_Time_for_Kronos__c> employeeKronosTimeClockEntries){
        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosLstToUpdate = new List<Employee_Clocked_Time_for_Kronos__c>();
        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosLstToDelete = new List<Employee_Clocked_Time_for_Kronos__c>();
        for(Employee_Clocked_Time_for_Kronos__c employeeClockedTimeForKronos : employeeKronosTimeClockEntries){
            if(employeeClockedTimeForKronos.Exported__c == true){
                if(employeeClockedTimeForKronos.Kronos_Action__c != 'Delete') {
                    employeeClockedTimeForKronos.Kronos_Action__c = 'Delete';
                    employeeClockedTimeForKronos.Exported__c = false;
                    employeeClockedTimeForKronosLstToUpdate.add(employeeClockedTimeForKronos);
                }
            } else {
                if(employeeClockedTimeForKronos.Kronos_Action__c != 'Delete') {
                    employeeClockedTimeForKronosLstToDelete.add(employeeClockedTimeForKronos);
                }
            }
        }
        if(employeeClockedTimeForKronosLstToDelete.size() > 0){
            CompanyMgmt.systemCall = true; //Ticket#23796
            delete employeeClockedTimeForKronosLstToDelete;
        }
        if(employeeClockedTimeForKronosLstToUpdate.size() > 0){
            CompanyMgmt.systemCall = true; //Ticket#23796
            update employeeClockedTimeForKronosLstToUpdate;
        }
    }

    public static List<Employee_Clocked_Time_for_Kronos__c> generateKronosClockEntriesForTMLine(TM_Line__c tmLine){
        List<Employee_Clocked_Time_for_Kronos__c> kronosClockEntries = new List<Employee_Clocked_Time_for_Kronos__c>();
        if(isTMLineDataReady(tmLine) == true){
            TM__c tm = tmsByIds.get(tmLine.TM__c);

            Boolean isPWJob = false;
            if(tm.Sales_Order__r.Pay_Rule__r.Type__c == 'Prevailing Wage'){
                isPWJob = true;
            }
            Boolean countTravelTime = isPWJob;
            Date scheduledDate = tm.Scheduled_Date__c;
            Time jobStartTime = tmLine.Job_Start_Time__c;
            Time jobEndTime = tmLine.Job_End_Time__c;
            Time siteStartTime = tmLine.Site_Start_Time__c;
            Time siteEndTime = tmLine.Site_End_Time__c;
            Time lunchStartTime = tmLine.Lunch_Start_Time__c;
            Time lunchEndTime = tmLine.Lunch_End_Time__c;
            if(TimeUtils.getWeekdayName(tmLine.Scheduled_Date__c) == 'Sunday' && jobEndTime == null){
                jobEndTime = TimeUtils.midNight();
            }

            if(TimeUtils.getWeekdayName(tmLine.Scheduled_Date__c) == 'Sunday' && siteStartTime != null && siteEndTime == null) {
                siteEndTime = TimeUtils.midNight();
            }

            if(TimeUtils.getWeekdayName(tmLine.Scheduled_Date__c) == 'Sunday' && (lunchStartTime == null || lunchEndTime == null)) {
                lunchStartTime = null;
                lunchEndTime = null;
            }

            Map<Date, Map<String, Time>> timesByTimeTypeByWorkDate = breakDownSFTimeEntry(
                    scheduledDate,
                    jobStartTime,
                    jobEndTime,
                    lunchStartTime,
                    lunchEndTime,
                    siteStartTime,
                    siteEndTime,
                    countTravelTime
            );

            Resource__c employee = resourcesByIds.get(tmLine.Resource__c);

            Id payRuleLineId = null;
            Id payRuleId = null;
            if(isPWJob == true || String.isNotBlank(tm.Sales_Order__r.Pay_Rule__c)){
                payRuleId = tm.Sales_Order__r.Pay_Rule__c;
            } else if (String.isNotBlank(employee.Pay_Rule__c)){
                payRuleId = employee.Pay_Rule__c;
            }
            /*Ticket#23441 - back out the logic that prevents pay rules from going to Kronos.
            //Ticket#23136 >>
            if(tm.Sales_Order__r.Bill_to_Customer_No__r.Customer_Type__c == 'I/C'){
                payRuleId = null;
            }
            //Ticket#23136 <<
             */
            if(payRuleId != null){
                String lookupKey = payRuleId + ':' + tmLine.Resource_Type__c;
                if(payRuleLineByPayRuleAndWorkAsResType.containsKey(lookupKey)){
                    payRuleLineId = payRuleLineByPayRuleAndWorkAsResType.get(lookupKey).Id;
                }
                //Ticket#22782 >>
                else {
                    if(String.isNotBlank(employee.Pay_Rule__c)) {
                        lookupKey = employee.Pay_Rule__c + ':' + employee.Resource_Type__c;
                        if (payRuleLineByPayRuleAndWorkAsResType.containsKey(lookupKey)) {
                            payRuleLineId = payRuleLineByPayRuleAndWorkAsResType.get(lookupKey).Id;
                        }
                    }
                }
                //Ticket#22782 <<
            }
            /*
            if(isPWJob == true || String.isNotBlank(tm.Sales_Order__r.Pay_Rule__c)){
                String lookupKey = tm.Sales_Order__r.Pay_Rule__c + ':' + tmLine.Resource_Type__c;
                if(payRuleLineByPayRuleAndWorkAsResType.containsKey(lookupKey)){
                    payRuleLineId = payRuleLineByPayRuleAndWorkAsResType.get(lookupKey).Id;
                }
            } else if(String.isNotBlank(employee.Pay_Rule__c)){
                String lookupKey = employee.Pay_Rule__c + ':' + employee.Resource_Type__c;
                if(payRuleLineByPayRuleAndWorkAsResType.containsKey(lookupKey)){
                    payRuleLineId = payRuleLineByPayRuleAndWorkAsResType.get(lookupKey).Id;
                }
            }
             */

            if(resourcesByIds.containsKey(tmLine.Resource__c)){
                for(Date workDate : timesByTimeTypeByWorkDate.keySet()){
                    Map<String, Time> timesByTimeType = timesByTimeTypeByWorkDate.get(workDate);
                    for(String timeKey : timesByTimeType.keySet()){
                        Time clockedTime = timesByTimeType.get(timeKey);
                        List<String> timeDescription = timeKey.split(':');
                        Employee_Clocked_Time_for_Kronos__c timeClock = initKronosTimeClockEntry(
                                tmLine.Resource__c, tm.Sales_Order__c, tmLine.TM__c, tmLine.Id, payRuleLineId, null,
                                workDate, clockedTime, timeDescription[1], timeDescription[0], 'Regular', tmLine.Resource_Type__r.Name
                        );
                        kronosClockEntries.add(timeClock);
                    }
                }
            }
        }
        return kronosClockEntries;
    }

    public static List<Employee_Clocked_Time_for_Kronos__c> generateKronosClockEntriesForResOffEntry(Resource_Off__c resourceOffEntry){
        List<Employee_Clocked_Time_for_Kronos__c> kronosClockEntries = new List<Employee_Clocked_Time_for_Kronos__c>();
        if(isResOffEntryDateReady(resourceOffEntry) == true){
            Map<Date, Map<String, Time>> timesByTimeTypeByWorkDate = breakDownSFTimeEntry(
                    resourceOffEntry.Date__c,
                    resourceOffEntry.Start_Time__c,
                    resourceOffEntry.End_Time__c,
                    resourceOffEntry.Lunch_Start_Time__c,
                    resourceOffEntry.Lunch_End_Time__c,
                    null,
                    null,
                    false
            );

            for(Date workDate : timesByTimeTypeByWorkDate.keySet()){
                Map<String, Time> timesByTimeType = timesByTimeTypeByWorkDate.get(workDate);
                for(String timeKey : timesByTimeType.keySet()){
                    Time clockedTime = timesByTimeType.get(timeKey);
                    List<String> timeDescription = timeKey.split(':');
                    Employee_Clocked_Time_for_Kronos__c timeClock = initKronosTimeClockEntry(
                            resourceOffEntry.Resource__c, resourceOffEntry.Service_Center__r.Shop_Time_Sales_Order__c, null, null, null,
                            resourceOffEntry.Id, workDate, clockedTime, timeDescription[1], timeDescription[0], 'Regular', null
                    );
                    kronosClockEntries.add(timeClock);
                }
            }
        }
        return kronosClockEntries;
    }

    private static Boolean isTMLineDataReady(TM_Line__c tmLine){
        //Service_Center__c serviceCenter = serviceCentersByIds.get(tmLine.Service_Center__c);
        if(String.isBlank(tmLine.TM__r.Sales_Order__c)){
            return false;
        }

        if(tmLine.Service_Center__r.Temporary__c == true){
            return false;
        }

        if(TimeUtils.getWeekdayName(tmLine.Scheduled_Date__c) == 'Sunday' && String.isNotBlank(tmLine.Resource__c) &&
                tmLine.Job_Start_Time__c != null){
            return true;
        }

        if(String.isBlank(tmLine.Resource__c) || tmLine.Job_Start_Time__c == null || tmLine.Job_End_Time__c == null ||
                tmLine.Site_Start_Time__c == null || tmLine.Site_End_Time__c == null){
            return false;
        }

        return true;
    }

    private static Boolean isResOffEntryDateReady(Resource_Off__c resourceOff){
        if(resourceOff.Service_Center__r.Temporary__c == true ||
                String.isBlank(resourceOff.Resource__c) ||
                resourceOff.Start_Time__c == null || resourceOff.End_Time__c == null){
            return false;
        }
        return true;
    }

    private static Employee_Clocked_Time_for_Kronos__c initKronosTimeClockEntry(
            Id resId, Id salesOrderId, Id tmId, Id tmLineId, Id payRuleLineId, Id resOffEntryId,
            Date workDate, Time clockedTime, String entryType, String timeType, String timeTypeCode, String laborType){

        Employee_Clocked_Time_for_Kronos__c timeClockEntry = new Employee_Clocked_Time_for_Kronos__c();
        timeClockEntry.Resource__c = resId;
        timeClockEntry.Sales_Order__c = salesOrderId;
        timeClockEntry.T_M__c = tmId;
        timeClockEntry.T_M_Line__c = tmLineId;
        timeClockEntry.Resource_Off__c = resOffEntryId;
        timeClockEntry.Entry_Type__c = entryType;
        timeClockEntry.Time_Type__c = timeType;
        timeClockEntry.Time_Type_Code__c = timeTypeCode;
        timeClockEntry.Work_Date__c = workDate;
        timeClockEntry.Time__c = clockedTime;
        timeClockEntry.Original_Labor_Type__c = laborType;
        //07222022 - Martha >>
        //if(entryType != 'Out' && entryType != 'Lunch Out') {
        timeClockEntry.Pay_Rule_Line__c = payRuleLineId;
        //}
        //07222022 - Martha <<
        return timeClockEntry;
    }

    /*
     *  Ticket#21502 - add blocked filter to Pay Rule Lines.
     *  Ticket#23635 - remove pay rule holiday check using "Eligible Holidays" setup using Holiday with Overtime Pay and Holiday with Double Time pay instead.
     */
    public static void setPayRuleMaps(Set<Id> payRuleIds){
        List<Pay_Rule__c> payRules = [
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
        payRulesByIds.putAll(payRules);
        for(Pay_Rule__c payRule : payRules){
            for(Pay_Rule_Line__c payRuleLine:payRule.Pay_Rule_Lines__r){
                payRuleLineByPayRuleAndWorkAsResType.put(payRule.Id + ':' + payRuleLine.Resource_Type__c, payRuleLine);
            }
        }
    }

    public static Map<Date, Map<String, Time>> breakDownSFTimeEntry(Date workDate, Time jobStartTime, Time jobEndTime, Time lunchStartTime, Time lunchEndTime, Time siteStartTime, Time siteEndTime, Boolean countTravelTime){
        Map<Date, Map<String, Time>> timeByTimeTypeByDate = new Map<Date, Map<String, Time>>();
        timeByTimeTypeByDate.put(workDate, new Map<String, Time>());
        Boolean isOverNightShift = false;
        //Ticket#25080 - add job start time == job end time check
        if((jobEndTime < jobStartTime || jobStartTime == jobEndTime) && jobEndTime != TimeUtils.midNight()){
            isOverNightShift = true;
            timeByTimeTypeByDate.put(workDate.addDays(1), new Map<String, Time>());
        }

        if(isOverNightShift == false &&
                (jobEndTime == TimeUtils.midNight() || siteEndTime == TimeUtils.midNight())){
            timeByTimeTypeByDate.put(workDate.addDays(1), new Map<String, Time>());
        }

        Boolean isTravelTimeOnlyEntry = false;

        String jobType = 'Job Time';
        if(jobStartTime == siteStartTime && siteEndTime == jobEndTime && countTravelTime == true){
            countTravelTime = false;
            jobType = 'Prevailing Wage';
        }
        //Handle travel time only entries
        //User some time use 07:00, 07:00, 07:00, 08:00 or 07:00, 08:00, 08:00, 08:00 to capture the travel time in T&M line.
        if(countTravelTime == true){
            //Handle travel time only entries
            jobType = 'Prevailing Wage';
            if((jobStartTime == siteStartTime && jobStartTime == siteEndTime && siteEndTime != jobEndTime) ||
                    (siteStartTime == siteEndTime && siteEndTime == jobEndTime && jobStartTime != siteStartTime)){
                isTravelTimeOnlyEntry = true;
                Time travelStart = null;
                Time travelEnd = null;
                Date tempDate = workDate;
                if(jobStartTime != siteStartTime) {
                    travelStart = jobStartTime;
                    travelEnd = siteStartTime;
                } else if (siteEndTime != jobEndTime) {
                    travelStart = siteEndTime;
                    travelEnd = jobEndTime;
                }
                Map<String, Time> timeByTimeTypes = timeByTimeTypeByDate.get(tempDate);
                String timeKey = 'Travel Time:In:' + tempDate + ':' + travelStart;
                timeByTimeTypes.put(timeKey, travelStart);
                timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
                
                if (isOverNightShift == true || travelEnd == TimeUtils.midNight()) {
                    tempDate = workDate.addDays(1);
                    timeByTimeTypes = timeByTimeTypeByDate.get(tempDate);
                }

                if (travelEnd != null) {
                    timeKey = 'Travel Time:Out:' + tempDate + ':' + travelEnd;
                    timeByTimeTypes.put(timeKey, travelEnd);
                    timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
                }
            }
        }

        //Handle start time & travel time
        if(countTravelTime == true){
            if(isTravelTimeOnlyEntry == false) {
                Map<String, Time> timeByTimeTypes = timeByTimeTypeByDate.get(workDate);
                //Travel to Site Time (Travel In)
                if (siteStartTime != jobStartTime) {
                    String timeKey = 'Travel Time:In:' + workDate + ':' + jobStartTime;
                    timeByTimeTypes.put(timeKey, jobStartTime);
                }

                Date tempDate = workDate;
                if((isOverNightShift == true && siteStartTime < jobStartTime) || (jobStartTime != TimeUtils.midNight() && siteStartTime == TimeUtils.midNight())){
                    tempDate = workDate.addDays(1);
                }
                //Site Time Started (Job time In)
                if (siteStartTime != null) {
                    String timeKey = jobType + ':In:' + tempDate + ':' + siteStartTime;
                    timeByTimeTypes.put(timeKey, siteStartTime);
                    timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
                }
            }
        } else {
            Map<String, Time> timeByTimeTypes = timeByTimeTypeByDate.get(workDate);
            String timeKey = jobType + ':In:' + workDate + ':' + jobStartTime;
            timeByTimeTypes.put(timeKey, jobStartTime);
            timeByTimeTypeByDate.put(workDate, timeByTimeTypes);
        }

        //Handle Lunch Time
        if(lunchStartTime != null && lunchEndTime != null) {
            //Ticket#25194 >>
            if(loggerEnabled == false && countTravelTime == true && (
                    isLunchTimeWithInTravelTime(jobStartTime, siteStartTime, lunchStartTime, lunchEndTime)
                            || isLunchTimeWithInTravelTime(siteEndTime, jobEndTime, lunchStartTime, lunchEndTime)))
            {
                loggerEnabled = true;
            }
            //Ticket#25194 <<
            //Lunch In time
            Date tempDate = workDate;
            if ((isOverNightShift == true && lunchStartTime < jobStartTime) || (lunchStartTime == TimeUtils.midNight())) {
                tempDate = workDate.addDays(1);
            }

            Map<String, Time> timeByTimeTypes = new Map<String, Time>();
            if(timeByTimeTypeByDate.containsKey(tempDate)){
                timeByTimeTypes = timeByTimeTypeByDate.get(tempDate);
            } else {
                timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
            }

            String timeKey = jobType + ':Lunch Out:' + tempDate + ':' + lunchStartTime;
            timeByTimeTypes.put(timeKey, lunchStartTime);
            timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);

            //Lunch Out time
            tempDate = workDate;
            if ((isOverNightShift == true && lunchEndTime < jobStartTime) || (lunchEndTime == TimeUtils.midNight())) {
                tempDate = workDate.addDays(1);
            }
            timeByTimeTypes = timeByTimeTypeByDate.get(tempDate);

            //handle lunch time occurs within travel time
            if(countTravelTime == true){
                //lunch occurs within travel to the site
                Boolean isWithin = isLunchTimeWithInTravelTime(jobStartTime, siteStartTime, lunchStartTime, lunchEndTime);
                if(isWithin == true && lunchEndTime != siteStartTime){
                    timeKey = 'Travel Time:In:' + tempDate + ':' + lunchEndTime;
                } else {
                    timeKey = jobType + ':Lunch In:' + tempDate + ':' + lunchEndTime;
                }
            } else {
                timeKey = jobType + ':Lunch In:' + tempDate + ':' + lunchEndTime;
            }
            //timeKey = jobType + ':Lunch In:' + tempDate + ':' + lunchEndTime;
            timeByTimeTypes.put(timeKey, lunchEndTime);
            timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
        }

        //Handle out time
        if(countTravelTime == true){
            if(isTravelTimeOnlyEntry == false) {
                //Job/Site time out
                Date tempDate = workDate;
                if ((isOverNightShift == true && siteEndTime < jobStartTime) || (siteEndTime == TimeUtils.midNight())) {
                    tempDate = workDate.addDays(1);
                }

                Map<String, Time> timeByTimeTypes = timeByTimeTypeByDate.get(tempDate);
                if(siteEndTime == jobEndTime && siteEndTime != null){
                    String timeKey = jobType + ':Out:' + tempDate + ':' + siteEndTime;
                    timeByTimeTypes.put(timeKey, siteEndTime);
                    timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
                }
                //Travel time out
                if (siteEndTime != jobEndTime) {
                    //Ticket#22619 Need Travel In line for travel away from site.
                    String timeKey = 'Travel Time:In:' + tempDate + ':' + siteEndTime;
                    if (siteEndTime != null) {
                        timeByTimeTypes.put(timeKey, siteEndTime);
                        timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
                    }

                    tempDate = workDate;
                    if ((isOverNightShift == true && jobEndTime < jobStartTime) || (jobEndTime == TimeUtils.midNight())) {
                        tempDate = workDate.addDays(1);
                        timeByTimeTypes = timeByTimeTypeByDate.get(tempDate); //Ticket#23475
                    }

                    if(jobEndTime != lunchEndTime) {
                        timeKey = 'Travel Time:Out:' + tempDate + ':' + jobEndTime;
                        if (jobEndTime != null) {
                            timeByTimeTypes.put(timeKey, jobEndTime);
                            timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
                        }
                    } else {
                        timeKey = jobType + ':Out:' + tempDate + ':' + jobEndTime;
                        timeByTimeTypes.put(timeKey, jobEndTime);
                        timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
                    }
                }
            }
        } else {
            Date tempDate = workDate;
            //Ticket#25080 - add job start time == job end time check
            if ((isOverNightShift == true && (jobEndTime < jobStartTime || jobEndTime == jobStartTime)) || (jobEndTime == TimeUtils.midNight())){
                tempDate = workDate.addDays(1);
            }
            /*
            if (isOverNightShift == true && jobEndTime < jobStartTime && jobEndTime != TimeUtils.midNight()) {
                tempDate = workDate.addDays(1);
            }
            if(isOverNightShift == false && jobEndTime == TimeUtils.midNight()){
                tempDate = workDate.addDays(1);
            }
             */
            Map<String, Time> timeByTimeTypes = new Map<String, Time>();
            if(timeByTimeTypeByDate.containsKey(tempDate)) {
                timeByTimeTypes = timeByTimeTypeByDate.get(tempDate);
            }
            if(jobEndTime != null) {
                String timeKey = jobType + ':Out:' + tempDate + ':' + jobEndTime;
                timeByTimeTypes.put(timeKey, jobEndTime);
                timeByTimeTypeByDate.put(tempDate, timeByTimeTypes);
            }
        }

        return timeByTimeTypeByDate;
    }

    public static void finalizedKronosTimeClockEntries(List<Employee_Clocked_Time_for_Kronos__c> kronosTimeClockEntries){
        Integer totalLength = kronosTimeClockEntries.size();
        if(totalLength < 3){
            return;
        }

        //Ticket#25194 >>
        GF_Logger__c gfLogger = new GF_Logger__c();
        gfLogger.SourceRecordType__c = 'Service Center Record';
        if(kronosTimeClockEntries[0].Resource__c != null && resourcesByIds.containsKey(kronosTimeClockEntries[0].Resource__c)) {
            gfLogger.SourceRecordId__c = resourcesByIds.get(kronosTimeClockEntries[0].Resource__c).Service_Center__c;
        }
        gfLogger.Method__c = 'KronosTimeClockService.finalizedKronosTimeClockEntries';
        gfLogger = recordMsg(gfLogger, String.join(kronosTimeClockEntries, '<br />'));
        //gfLogger.Message__c = String.join(kronosTimeClockEntries, '<br />');
        //gfLogger.Message__c += '<br /> =============================== <br /> ';
        //Ticket#25194 <<

        Integer i = 0,j = 1;
        Set<Id> entriesCanBeDeleted = new Set<Id>();
        List<Employee_Clocked_Time_for_Kronos__c> entriesToUpdate = new List<Employee_Clocked_Time_for_Kronos__c>();
        while(j < totalLength){
            //Ticket#25555 >>
            /*
            //Ticket#23867 >>
            if (kronosTimeClockEntries[i].Resource__c == kronosTimeClockEntries[j].Resource__c &&
                kronosTimeClockEntries[i].Entry_Type__c == 'Lunch In' &&
                    (kronosTimeClockEntries[j].Time_Type__c == 'Travel Time' && kronosTimeClockEntries[j].Entry_Type__c == 'Out'))
            {
                kronosTimeClockEntries[i].Time_Type__c = 'Travel Time';
                kronosTimeClockEntries[i].Entry_Type__c = 'In';
                entriesToUpdate.add(kronosTimeClockEntries[i]);
                //Ticket#25194 >>
                gfLogger.Message__c += '<br /> == Lunch In Line Replaced ==== ';
                gfLogger.Message__c = gfLogger.Message__c + ' <br />' + kronosTimeClockEntries[i].Resource__c + ' -- ' + kronosTimeClockEntries[i].Work_Date__c + ' -- ' + kronosTimeClockEntries[i].Time_Type__c + ' -- ' + kronosTimeClockEntries[i].Entry_Type__c + ' -- ' + kronosTimeClockEntries[i].Time__c ;
                gfLogger.Message__c += '<br /> == Lunch In Line Replaced ==== ';
                //Ticket#25194 <<
            }
            //Ticket#23867 <<
             */

            Boolean lunchTimeWithinATravelTime = false;
            if (kronosTimeClockEntries[i].Resource__c == kronosTimeClockEntries[j].Resource__c &&
                    kronosTimeClockEntries[i].Entry_Type__c == 'Lunch In'){
                if (kronosTimeClockEntries[j].Time_Type__c == 'Travel Time' && kronosTimeClockEntries[j].Entry_Type__c == 'Out'){
                    lunchTimeWithinATravelTime = true;
                }
                Integer k = j+1;
                //System.debug('Info: k: ' + k);
                //System.debug('Info: kronosTimeClockEntries size: ' + kronosTimeClockEntries.size());
                if(k < kronosTimeClockEntries.size()) {
                    if (lunchTimeWithinATravelTime == false && kronosTimeClockEntries[i].Sales_Order__c == kronosTimeClockEntries[k].Sales_Order__c &&
                            kronosTimeClockEntries[j].Time__c == kronosTimeClockEntries[k].Time__c &&
                            kronosTimeClockEntries[j].Work_Date__c == kronosTimeClockEntries[k].Work_Date__c &&
                            kronosTimeClockEntries[k].Time_Type__c == 'Travel Time' && kronosTimeClockEntries[k].Entry_Type__c == 'Out') {
                        lunchTimeWithinATravelTime = true;
                    }
                }
            }
            if(lunchTimeWithinATravelTime == true){
                kronosTimeClockEntries[i].Time_Type__c = 'Travel Time';
                kronosTimeClockEntries[i].Entry_Type__c = 'In';
                entriesToUpdate.add(kronosTimeClockEntries[i]);
                //Ticket#25194 >>
                gfLogger.Message__c += '<br /> == Lunch In Line Replaced ==== ';
                gfLogger.Message__c = gfLogger.Message__c + ' <br />' + kronosTimeClockEntries[i].Resource__c + ' -- ' + kronosTimeClockEntries[i].Work_Date__c + ' -- ' + kronosTimeClockEntries[i].Time_Type__c + ' -- ' + kronosTimeClockEntries[i].Entry_Type__c + ' -- ' + kronosTimeClockEntries[i].Time__c ;
                gfLogger.Message__c += '<br /> == Lunch In Line Replaced ==== ';
                //Ticket#25194 <<
            }
            //Ticket#25555 <<

            if(kronosTimeClockEntries[i].Resource__c == kronosTimeClockEntries[j].Resource__c &&
                    kronosTimeClockEntries[i].Work_Date__c == kronosTimeClockEntries[j].Work_Date__c &&
                    kronosTimeClockEntries[i].Time__c == kronosTimeClockEntries[j].Time__c){
                if(kronosTimeClockEntries[i].Sales_Order__c == kronosTimeClockEntries[j].Sales_Order__c &&
                        kronosTimeClockEntries[i].Pay_Rule_Line__c == kronosTimeClockEntries[j].Pay_Rule_Line__c){
                    //lunch end time = job end time then keep job end time
                    if(kronosTimeClockEntries[i].Entry_Type__c != kronosTimeClockEntries[j].Entry_Type__c){
                        if(kronosTimeClockEntries[i].Entry_Type__c == 'In' && kronosTimeClockEntries[j].Entry_Type__c == 'Out'){
                            entriesCanBeDeleted.add(kronosTimeClockEntries[j].Id);
                        } else {
                            entriesCanBeDeleted.add(kronosTimeClockEntries[i].Id);
                        }
                    } else {
                        entriesCanBeDeleted.add(kronosTimeClockEntries[i].Id);
                        entriesCanBeDeleted.add(kronosTimeClockEntries[j].Id);
                    }
                } else {
                    if(kronosTimeClockEntries[i].Entry_Type__c == 'Out'){
                        entriesCanBeDeleted.add(kronosTimeClockEntries[i].Id);
                    } else if(kronosTimeClockEntries[j].Entry_Type__c == 'Out'){
                        entriesCanBeDeleted.add(kronosTimeClockEntries[j].Id);
                    }
                }
            }

            if(kronosTimeClockEntries[i].Resource__c == kronosTimeClockEntries[j].Resource__c &&
                kronosTimeClockEntries[i].Entry_Type__c == 'Out' && kronosTimeClockEntries[j].Entry_Type__c == 'Out' &&
                    kronosTimeClockEntries[i].T_M_Line__r.TM__c == kronosTimeClockEntries[j].T_M_Line__r.TM__c)
            {
                entriesCanBeDeleted.add(kronosTimeClockEntries[i].Id);
            }


            i++;
            j++;
        }

        //Ticket#23867 >>
        if(entriesToUpdate.size() > 0){
            CompanyMgmt.systemCall = true; //Ticket#23796
            update entriesToUpdate;
        }
        //Ticket#23867 <<

        if(entriesCanBeDeleted.size() > 0){
            List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronos = [SELECT Id FROM Employee_Clocked_Time_for_Kronos__c WHERE Id IN :entriesCanBeDeleted];
            CompanyMgmt.systemCall = true; //Ticket#23796
            delete employeeClockedTimeForKronos;
        }

        //Ticket#25194 >>
        if(loggerEnabled == true && gfLogger != null){
            insert gfLogger;
        }
        //Ticket#25194 <<
    }

    public static void finalKronosTimeClockEntriesCleansing(List<Employee_Clocked_Time_for_Kronos__c> kronosTimeClockEntries){
        Integer totalLength = kronosTimeClockEntries.size();

        Integer i = 0,j = 1;
        Map<Id, Employee_Clocked_Time_for_Kronos__c> entriesToUpdate = new Map<Id, Employee_Clocked_Time_for_Kronos__c>();

        //Check to remove all pay rule line id from out entries
        for(Employee_Clocked_Time_for_Kronos__c employeeTimePunchEntry : kronosTimeClockEntries){
            if((employeeTimePunchEntry.Entry_Type__c == 'Out' || employeeTimePunchEntry.Entry_Type__c == 'Lunch Out') && employeeTimePunchEntry.Pay_Rule_Line__c != null){
                employeeTimePunchEntry.Pay_Rule_Line__c = null;
                entriesToUpdate.put(employeeTimePunchEntry.Id, employeeTimePunchEntry);
            }
        }

        Set<Id> entriesCanBeDeleted = new Set<Id>();
        if(totalLength > 2) {
            //Ticket#25194 >>
            GF_Logger__c gfLogger = new GF_Logger__c();
            gfLogger.SourceRecordType__c = 'Service Center Record';
            if(kronosTimeClockEntries[0].Resource__c != null && resourcesByIds.containsKey(kronosTimeClockEntries[0].Resource__c)) {
                gfLogger.SourceRecordId__c = resourcesByIds.get(kronosTimeClockEntries[0].Resource__c).Service_Center__c;
            }
            gfLogger.Method__c = 'KronosTimeClockService.finalKronosTimeClockEntriesCleansing';
            gfLogger = recordMsg(gfLogger, String.join(kronosTimeClockEntries, '<br />'));
            //gfLogger.Message__c = String.join(kronosTimeClockEntries, '<br />');
            //gfLogger.Message__c += '<br /> =============================== <br /> ';
            //Ticket#25194 <<

            //Check if lunch time occurs within the travel time, change entry type for Lunch In to Travel In.
            while (j < totalLength) {
                if (kronosTimeClockEntries[i].Resource__c == kronosTimeClockEntries[j].Resource__c &&
                        kronosTimeClockEntries[i].Sales_Order__c == kronosTimeClockEntries[j].Sales_Order__c) {
                    if (kronosTimeClockEntries[i].Entry_Type__c == 'Lunch In' && (kronosTimeClockEntries[j].Time_Type__c == 'Travel Time' && kronosTimeClockEntries[j].Entry_Type__c == 'Out')) {
                        kronosTimeClockEntries[i].Time_Type__c = 'Travel Time';
                        kronosTimeClockEntries[i].Entry_Type__c = 'In';
                        entriesToUpdate.put(kronosTimeClockEntries[i].Id, kronosTimeClockEntries[i]);
                        //Ticket#25194 >>
                        gfLogger.Message__c += '<br /> == Lunch In Line Replaced ==== ';
                        gfLogger.Message__c = gfLogger.Message__c + ' <br />' + kronosTimeClockEntries[i].Resource__c + ' -- ' + kronosTimeClockEntries[i].Work_Date__c + ' -- ' + kronosTimeClockEntries[i].Time_Type__c + ' -- ' + kronosTimeClockEntries[i].Entry_Type__c + ' -- ' + kronosTimeClockEntries[i].Time__c ;
                        gfLogger.Message__c += '<br /> == Lunch In Line Replaced ==== ';
                        //Ticket#25194 <<
                    }
                }
                i++;
                j++;
            }

            //loop again try to remove two consecutive travel time - in
            i = 0;
            j = 1;

            while (j < totalLength) {
                if (kronosTimeClockEntries[i].Resource__c == kronosTimeClockEntries[j].Resource__c &&
                        kronosTimeClockEntries[i].Sales_Order__c == kronosTimeClockEntries[j].Sales_Order__c) {
                    if ((kronosTimeClockEntries[i].Time_Type__c == 'Travel Time' && kronosTimeClockEntries[i].Entry_Type__c == 'In') &&
                            (kronosTimeClockEntries[j].Time_Type__c == 'Travel Time' && kronosTimeClockEntries[j].Entry_Type__c == 'In') &&
                            (kronosTimeClockEntries[i].Work_Date__c == kronosTimeClockEntries[j].Work_Date__c)) {
                        if (kronosTimeClockEntries[i].Time__c == kronosTimeClockEntries[j].Time__c) {
                            entriesCanBeDeleted.add(kronosTimeClockEntries[i].Id);
                        }
                    }
                }
                i++;
                j++;
            }

            //Ticket#25194 >>
            if(loggerEnabled == true && gfLogger != null){
                insert gfLogger;
            }
            //Ticket#25194 <<
        }

        if(entriesToUpdate.size() > 0){
            for(Id deletedId : entriesCanBeDeleted){
                entriesToUpdate.remove(deletedId);
            }
            CompanyMgmt.systemCall = true; //Ticket#23796
            update entriesToUpdate.values();
        }

        if(entriesCanBeDeleted.size() > 0){
            List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronos = [SELECT Id FROM Employee_Clocked_Time_for_Kronos__c WHERE Id IN :entriesCanBeDeleted];
            CompanyMgmt.systemCall = true; //Ticket#23796
            delete employeeClockedTimeForKronos;
        }
    }

    public static Boolean isLunchTimeWithInTravelTime(Time travelStart, Time travelEnd, Time lunchStart, Time lunchEnd){
        //JS=>08:00, SS=>09:00, LS=>12:00, LE=>13:00, SE=>14:00, JE=>15:00
        if(lunchStart >= travelStart && lunchEnd <= travelEnd && lunchEnd != TimeUtils.midNight()){
            return true;
        }
        //JS=>23:00, SS=>03:00, LS=>00:00, LE=>01:00, SE=>06:00, JE=>08:00
        if(lunchStart == TimeUtils.midNight()){
            if(lunchEnd < travelEnd && travelStart >= travelEnd){
                return true;
            }
        }

        if(travelEnd == TimeUtils.midNight()){
            if(lunchEnd > lunchStart && lunchStart > travelStart){
                return true;
            }
        }

        if(lunchEnd == TimeUtils.midNight()){
            if(lunchStart > travelStart && travelStart >= travelEnd){
                return true;
            }
        }
        return false;
    }

    public static GF_Logger__c recordMsg(GF_Logger__c gfLogger, String msgToProcess){
        Integer maxFieldLength = Schema.SObjectType.GF_Logger__c.fields.Message__c.getLength();
        Integer counter = 1;
        Integer inputMsgTotalLength = msgToProcess.length();
        for(Integer i = 0; i < inputMsgTotalLength; i += maxFieldLength){
            Integer min = Math.min(i + maxFieldLength, inputMsgTotalLength);
            String subString = msgToProcess.substring(i, Math.min(i + maxFieldLength, inputMsgTotalLength));
            switch on (counter) {
                when 1 {gfLogger.Message2__c = subString;}
                when 2 {gfLogger.Message3__c = subString;}
                when 3 {gfLogger.Message4__c = subString;}
                when 4 {gfLogger.Message5__c = subString;}
                when 5 {gfLogger.Message6__c = subString;}
                when 6 {gfLogger.Message7__c = subString;}
                when 7 {gfLogger.Message8__c = subString;}
                when 8 {gfLogger.Message9__c = subString;}
                when 9 {gfLogger.Message10__c = subString;}
                when else {gfLogger.Message__c += '<br /> More records not recorded';}
            }
            counter++;
        }
        return gfLogger;
    }
}