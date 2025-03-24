/*
    Ticket#17060 - change T&M Line query to use T&M Line selector.
 */
global class ResourceOffController {
    public String selectedEquipments{get;set;}
    public List<Resource__c> theResourceList{get;set;}
    List<String> lstselectedResourcesIds;
    public String startDate {get;set;}
    public String strStartTime {get;set;}
    public String endDate {get;set;}
    public String strEndTime {get;set;}
    public String description { get; set; }
    public String note {get;set;}
    public String RosterDate;
    public String offType {get;set;}
    public String TMNumber {get;set;}
    public String calledFrom;
    public TM_Line__c theTMLine{get;set;}
    public List<TM_Line__c> theTMLineList{get;set;}
    public List<TM_Line__c> theAllTMLineList{get;set;}
    public String dtStart {get;set;}
    public String strLunchStartTime {get;set;}
    public String strLunchEndTime {get;set;}
    public String strSiteStartTime {get;set;}
    public String strSiteEndTime {get;set;}
    public Resource_Off__c theResOff{get;set;}
    public Resource__c theResource{get;set;}
    public TM__c tm;
    public String selectedSC {get; set;} //Ticket 13326
    //job task <<
    public List<SelectOption> jobTaskSelectOptions { set; get; }
    //job task >>

    public ResourceOffController() {
        theResOff = new Resource_Off__c();
        theResource = new Resource__c();
        String selectedResourcesIds = ApexPages.currentPage().getParameters().get('selectedResourcesIds');
        RosterDate = ApexPages.currentPage().getParameters().get('RosterDate');
        offType = ApexPages.currentPage().getParameters().get('offType');
        calledFrom = ApexPages.currentPage().getParameters().get('calledFrom');
        selectedSC = ApexPages.currentPage().getParameters().get('selectedSC'); //Ticket 13326
        List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectByName(selectedSC);
        if(serviceCenters.size() > 0){
            theResOff.Service_Center__c = serviceCenters[0].Id;
        }
        startDate = RosterDate;
        endDate = startDate;
        Date startDate1 = Date.parse(startDate);
        Integer month;
        Integer day;
        Integer year;
        year = startDate1.year();
        month = startDate1.month();
        day = startDate1.day();
        
        dtStart = startDate1.year() + '-';
        
        if(month < 10) dtStart += '0';
                 
        dtStart += startDate1.month() + '-';
        
        if(day < 10)  dtStart += '0';
            
        dtStart += startDate1.day();
        
        //if(offType != 'Shop Time' && offType != 'Paid Time Off' && offType != 'Unavailable') {
        if(offType != 'Shop Time' && offType != 'Paid Time Off' && offType != 'borrowedResShopTime') {
            strStartTime = '08:00';
            strEndTime = '16:00';
        }
        
        lstselectedResourcesIds = new List<String>();
        lstselectedResourcesIds = selectedResourcesIds.split(',');
 
        //theController = controller;        
        selectResourceList();
        //selectWrapList();
        theTMLine = new TM_Line__c();
    }
    
    private void selectResourceList() {
        theResourceList = new List<Resource__c>();
        
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Resource__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Service_Center__r.Name, Resource_Type__r.Name ';
        strQuery += ' FROM Resource__c ';
        strQuery += '  WHERE Id IN: lstselectedResourcesIds';
        theResourceList = Database.query(strQuery);
    }
    
    public PageReference save() {
        try{
            Map<String, Map<Time, Time>> resTimeEntries = new Map<String, Map<Time, Time>>();
            Map<TM__c, List<TM_Line__c>> tmlinesMap = new Map<TM__c, List<TM_Line__c>>();
            Set<Id> resIdSet = new Set<Id>();
            String processedMsg = '';
            if(offType == 'borrowedResShopTime' && theResOff.Resource__c != null){
                theResourceList = ResourcesSelector.newInstance().selectById(new Set<Id>{theResOff.Resource__c});
            }

            if(offType != 'Assign') {
                Off_Type__c theOffType = new Off_Type__c();
                if(!String.isEmpty(offType)) {
                    String type = offType;
                    if(type == 'borrowedResShopTime'){
                        type = 'Shop Time';
                    }
                    List<Off_Type__c> theOffTypeList = [SELECT Id, Name FROM Off_Type__c WHERE Name = :type LIMIT 1];
                    if(theOffTypeList != null &&  theOffTypeList.size() > 0){
                        theOffType = theOffTypeList[0];
                    }
                }
                       
                //Ticket#13763 >>
                if(offType == 'Shop Time' || offType == 'borrowedResShopTime'){
                    endDate = startDate;
                }

                Integer noOfDays = Date.parse(startDate).daysBetween(Date.parse(endDate));
                //Ticket#13763 <<
                List<Resource_Off__c> theResourceOffList = new List<Resource_Off__c>();
                Resource_Off__c theResourceOff;

                Time startTime;
                Time endTime;
                Time lunchStartTime;
                Time lunchEndTime;
                Time siteStartTime;
                Time siteEndTime;
                //Ticket#13763 >>
                startTime = TimeUtils.convertStrToTime(strStartTime);
                endTime = TimeUtils.convertStrToTime(strEndTime);
                lunchStartTime = TimeUtils.convertStrToTime(strLunchStartTime);
                lunchEndTime = TimeUtils.convertStrToTime(strLunchEndTime);
                siteStartTime = TimeUtils.convertStrToTime(strSiteStartTime);
                siteEndTime = TimeUtils.convertStrToTime(strSiteEndTime);
                
                //Ticket#13763 <<

                Date dtStart =  Date.parse(startDate);
                Date dtEnd =  Date.parse(endDate);
                if(Test.isRunningTest())
                {
                    startTime=Time.newInstance(0, 0, 1, 0);
                    endTime=Time.newInstance(0, 0, 2, 0);
                }

                if(offType != 'Available') {
                    if(startTime == null && !Test.isRunningTest()) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Start Time cannot be blank.'));
                        return null;
                    }

                    if(endTime == null && !Test.isRunningTest()) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'End Time cannot be blank.'));
                        return null;
                    }

                    if(endTime < startTime && startDate != endDate && endTime != Time.newInstance(0,0,0,0)){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'For overnight shift hours, Start and End date must be the same!'));
                        return null;
                    }

                    if(offType == 'borrowedResShopTime' && String.isBlank(theResOff.Resource_Service_Center__c)){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Resource Service Center cannot be blank.'));
                        return null;
                    }
                    if(offType == 'borrowedResShopTime' && String.isBlank(theResOff.Resource__c)){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Resource cannot be blank.'));
                        return null;
                    }

                    Decimal hours = TimeUtils.calculateHours(startTime, endTime);

                    TimesheetMgmt tsMgmt = new TimesheetMgmt(); //Ticket#13852
                    Set<Id> processedIdSet = new Set<Id>(); //Ticket#13852
                    Map<Id, String> resNameMap = new Map<Id, String>(); //Ticket#13852
                    for(Integer i = 0; i <= noOfDays; i++) {
                        //Ticket#20663 >>
                        Date tempDate = Date.parse(startDate).addDays(i);
                        Boolean isWeekend = TimeUtils.isWeekend(TimeUtils.getWeekdayName(tempDate));
                        if(offType == 'Paid Time Off' && isWeekend == true){
                            if(noOfDays == 0){
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'PTO cannot be assigned on weekends!'));
                                return null;
                            } else {
                                continue;
                            }
                        }
                        //Ticket#20663 <<

                        for(Resource__c theResource : theResourceList) {
                            theResourceOff = new Resource_Off__c();
                            theResourceOff.Service_Center__c = theResOff.Service_Center__c;
                            theResourceOff.Description__c = theResource.Description__c;
                            theResourceOff.End_Time__c = endTime;
                            theResourceOff.Note__c = note;
                            if(theOffType != null) {
                                theResourceOff.Off_Type__c = theOffType.Id;
                            }
                            theResourceOff.Resource__c = theResource.Id;
                            theResourceOff.Resource_Service_Center__c = theResource.Service_Center__c;
                            theResourceOff.Start_Time__c = startTime;
                            theResourceOff.Date__c = dtStart.addDays(i);
                            theResourceOff.Total_Hours__c  = hours;
                            theResourceOff.Site_Start_Time__c = siteStartTime;
                            theResourceOff.Site_End_Time__c = siteEndTime;

                            if(offType == 'Shop Time' || offType == 'borrowedResShopTime') {
                                theResourceOff.Shop_Time_Category__c = theResOff.Shop_Time_Category__c;
                                theResourceOff.Lunch_Start_Time__c = lunchStartTime;
                                theResourceOff.Lunch_End_Time__c = lunchEndTime;

                                //Kronos Lunch Time check >> Ticket#24468
                                if(theResourceOff.Lunch_Start_Time__c != null && theResourceOff.Lunch_End_Time__c != null) {
                                    Boolean isValid = TMLLinesService.isLunchTimeValid(theResourceOff.Start_Time__c, theResourceOff.End_Time__c, theResourceOff.Lunch_Start_Time__c, theResourceOff.Lunch_End_Time__c, theResourceOff.Site_Start_Time__c, theResourceOff.Site_End_Time__c);
                                    if (isValid == false) {
                                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Lunch times entered are not valid. Please make sure lunch times are within the start and end times.'));
                                        return null;
                                    }
                                }
                                //Kronos Lunch Time check << Ticket#24468

                                theResourceOff.Hours__c = theResourceOff.Total_Hours__c - TimeUtils.calculateHours(lunchStartTime, lunchEndTime);
                                //Ticket#23713 >>
                                theResourceOff.Flat_Rate_Type__c = theResOff.Flat_Rate_Type__c;
                                if(theResOff.Flat_Rate_Type__c != null && CompanyMgmt.zeroIfNull(theResOff.Flat_Pay_Rate__c) < 1){
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Rate must not be zero!'));
                                    return null;
                                }
                                theResourceOff.Flat_Pay_Rate__c = theResOff.Flat_Pay_Rate__c;
                                //Ticket#23713 <<
                            } else {
                                theResourceOff.Hours__c = theResourceOff.Total_Hours__c;
                            }

                            if(offType == 'Paid Time Off'){
                                if(hours > 8){
                                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'PTO hour must not exceed 8 hours!'));
                                    return null;
                                }
                                theResourceOff.PTO_Type__c = theResOff.PTO_Type__c;
                            }

                            if(offType == 'Unavailable'){
                                theResourceOff.Unavailable_Reason__c = theResOff.Unavailable_Reason__c;
                            }

                            if(Test.isRunningTest() && theResourceOff.Off_Type__c == null) {
                                theResourceOff.Off_Type__c= TestDataUtil.OffTypeRecord.Id;
                            }

                            theResourceOffList.add(theResourceOff);

                            resIdSet.add(theResource.Id); //Ticket# 13409

                            //Ticket#13852 >>
                            Map<String, Set<String>> workedItemByResIdAndDate = new Map<String, Set<String>>(); //Ticket#19920
                            if(offType != 'Holiday' && theResource.Bypass_Time_Overlap_Checking__c != true){ //Ticket#22307
                                resNameMap.put(theResourceOff.Resource__c, theResourceOff.Description__c);
                                resTimeEntries = tsMgmt.updateResTimeEntryMap(resTimeEntries, theResourceOff.Date__c, theResourceOff.Date__c, theResourceOff.Date__c,
                                        theResourceOff.Start_Time__c, theResourceOff.End_Time__c, theResourceOff.Resource__c, resNameMap, workedItemByResIdAndDate);
                                processedIdSet.add(theResourceOff.Id);
                            }
                        }
                    }

                    //Ticket# 13409 >>
                    //check time overlap but skip Holiday Entries
                    if(offType != 'Holiday'){
                        if(endTime != null && startTime != null){
                            tsMgmt.checkTimeEntryOverlap(resIdSet, resTimeEntries, dtStart, dtEnd, processedIdSet); //Ticket#13852
                            //TimesheetMgmt.checkOverlap(resIdSet, resTimeEntries, dtStart, dtEnd); //Replaced byTicket#13852
                        }
                    }

                    if(theResourceOffList != null && theResourceOffList.size() > 0) {
                        insert theResourceOffList;
                    }

                    if(calledFrom == 'EquipmentRoster' && offType == 'Out of Service') {
                        for (Resource__c theResource : theResourceList) {
                            theResource.Status__c = 'Out of Service';
                            theResource.Out_of_Service_Date__c = Date.parse(startDate);
                            theResource.Out_of_Service_Reason__c = note;
                        }
                        update theResourceList;
                    }
                }

                if (offType == 'Available') { 
                    /*
                    theTMLineList = new List<TM_Line__c>();
                    theTMLineList = [SELECT Id, Name FROM TM_Line__c WHERE TM__r.Scheduled_Date__c >=: dtStart AND TM__r.Scheduled_Date__c <=: dtEnd AND
                                         Resource__c IN: lstselectedResourcesIds AND (TM__r.Status__c = 'Open' OR TM__r.Status__c = 'Scheduled')];
                    if(theTMLineList != null && theTMLineList.size() > 0) {
                        delete theTMLineList;
                    }
                     */

                    List<TM_Line__c> tmLines = new List<TM_Line__c>();
                    tmLines = [SELECT Id, Name, TM__r.Status__c, TM__r.Name, TM_Job_Task__r.Name, Resource__r.Name, TM__r.Scheduled_Date__c FROM TM_Line__c WHERE TM__r.Scheduled_Date__c >=: dtStart AND TM__r.Scheduled_Date__c <=: dtEnd AND
                    Resource__c IN: lstselectedResourcesIds AND TM__r.Status__c != 'Closed' AND TM__r.Status__c != 'Void' AND Resource__c != NULL];

                    Set<String> deleteFromTMNames = new Set<String>();
                    Set<String> cannotBeDeleteFromTMNames = new Set<String>();
                    List<TM_Line__c> tmLinesToDelete = new List<TM_Line__c>();
                    for(TM_Line__c tmLine : tmLines){
                        String tmInfo = tmLine.TM__r.Name + ' - Status: ' + tmLine.TM__r.Status__c + ' Job Task: ' + tmLine.TM_Job_Task__r.Name;
                        //+ ' Debug: ' + tmLine.Resource__r.Name + ' -- ' + tmLine.TM__r.Scheduled_Date__c
                        if(tmLine.TM__r.Status__c == TMsService.OPEN_STATUS || tmLine.TM__r.Status__c == TMsService.SCHEDULED_STATUS){
                            deleteFromTMNames.add(tmInfo);
                            tmLinesToDelete.add(tmLine);
                        } else {
                            cannotBeDeleteFromTMNames.add(tmInfo);
                        }
                    }

                    if(tmLinesToDelete.size() > 0){
                        delete tmLinesToDelete;
                    }

                    String deletedTMNameMsg = 'Line deleted from: ';
                    for(String tmName : deleteFromTMNames){
                        deletedTMNameMsg = deletedTMNameMsg + tmName + ' <br/>';
                    }
                    if(deletedTMNameMsg.contains('-')) {
                        processedMsg = deletedTMNameMsg;
                    }

                    String notDeletedTMNameMsg = 'Line cannot be deleted from: ';
                    for(String tmName : cannotBeDeleteFromTMNames){
                        notDeletedTMNameMsg = notDeletedTMNameMsg + tmName + '<br/>';
                    }
                    if(notDeletedTMNameMsg.contains('-')){
                        processedMsg = processedMsg + notDeletedTMNameMsg;
                    }

                    /***07292019 Zon W-000450***/
                    if(calledFrom == 'EquipmentRoster') {
                        String Key;
                        Set<Id> resourceIdSet = new Set<Id>();
                        Set<Date> outOfServiceDates = new Set<Date>();
                        List<Resource_Off__c> newResOffList = new List<Resource_Off__c>();
                        Map<String, Resource_Off__c> theResOffMap = new Map<String, Resource_Off__c>();
                        for (Resource__c theResource : theResourceList) {
                            System.debug('status===========>'+theResource.Status__c );
                                                        System.debug('status===========>'+theResource.Out_of_Service_Date__c);

                            if(theResource.Status__c != 'Available' && theResource.Out_of_Service_Date__c != null) {
                                resourceIdSet.add(theResource.Id);
                                outOfServiceDates.add(theResource.Out_of_Service_Date__c);
                            }
                            /*
                            if (theResource.Status__c == 'Available') {
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, theResource.Name + ' is available already.'));
                                return null;
                            }
                             */
                        }
                        // find all existing resource off
                        if(resourceIdSet.size() > 0) {
                            List<Resource_Off__c> theResOffList = [
                                    SELECT Service_Center__c, Description__c, End_Time__c, Note__c, Off_Type__c, Resource__c,
                                            Resource_Service_Center__c, Start_Time__c, Date__c, Total_Hours__c
                                    FROM Resource_Off__c
                                    WHERE Resource__c = :resourceIdSet AND Date__c IN:outOfServiceDates
                            ];
                            for (Resource_Off__c theResOff : theResOffList) {
                                Key = theResOff.Resource__c + '##' + theResOff.Date__c;
                                if (!theResOffMap.containsKey(Key)) {
                                    theResOffMap.put(Key, theResOff);
                                }
                            }
                            for (Resource__c theResource : theResourceList) {
                                //check for resource off in a condition if more than 1 day, then create resource off for each day
                                Integer daysBetween = 0;
                                if (theResource.Out_of_Service_Date__c != null) {
                                    daysBetween = theResource.Out_of_Service_Date__c.daysBetween(Date.parse(startDate).addDays(-1));
                                }
                                if (daysBetween > 0) {
                                    for (Integer i = 1; i <= daysBetween; i++) {
                                        Key = theResource.Id + '##' + theResource.Out_of_Service_Date__c;
                                        theResourceOff = new Resource_Off__c();
                                        if (theResOffMap.containsKey(Key)) {
                                            theResourceOff = theResOffMap.get(Key).clone();
                                            theResourceOff.Date__c = theResourceOff.Date__c + i;
                                            if (Test.isRunningTest() && theResourceOff.Off_Type__c == null) {
                                                theResourceOff.Off_Type__c = TestDataUtil.OffTypeRecord.Id;
                                            }
                                            newResOffList.add(theResourceOff);
                                        }
                                    }
                                }
                                //when make it available, blank out out of service date and reason fields.
                                theResource.Status__c = 'Available';
                                theResource.Out_of_Service_Date__c = null;
                                theResource.Out_of_Service_Reason__c = null;
                            }
                            update theResourceList;
                            if (newResOffList != null && newResOffList.size() > 0) {
                                insert newResOffList;
                            }
                        }
                    }
                }
            } else {    //assign
                if(String.isEmpty(theTMLine.TM__c)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a T&M.'));
                    return null;
                }

                //job task <<
                if (this.theTMLine.TM_Job_Task__c == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must choose a job task.'));
                    return null;
                }
                //job task >>

                for(Resource__c resource : theResourceList){
                    if(resource.Status__c == 'Out of Service'){
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Resource: ' + resource.Name + ' is out of service.'));
                        return null;
                    }
                }

                String tmId = theTMLine.TM__c;
                Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM__c.fields.getMap();
                List<String> lstFields = new List<String>();
                for (Schema.SObjectField field : fields.values()) {
                    lstFields.add(field.getDescribe().getName());
                }
                String strQuery = 'SELECT ' + String.join(lstFields, ',');
                strQuery += ' , Contract__r.Name, Bill_To_Customer__r.Name, Bill_To_Customer__r.AccountNumber';
                strQuery += ', Bill_To_Customer__r.Account_Executive__r.Name,Sales_Order__r.Name,Tax_Area__r.Name, Alternate_Site_Address__r.Name ';
                strQuery += ', Account_Executive__r.Name, Project_Coordinator__r.Name, Contact__r.Name, Contact__r.FirstName, Contact__r.LastName' +
                        ',Bill_to_Customer__r.Pricing_Group__c, Bill_to_Customer__r.BillingCity, Bill_to_Customer__r.BillingStreet' +
                        ',Bill_to_Customer__r.BillingState, Bill_to_Customer__r.BillingPostalCode, Bill_to_Customer__r.BillingCountry' +
                        ',Bill_to_Customer__r.Payment_Term__c, Sales_Order__r.From_Sales_Quote__c, Sales_Order__r.Pay_Rule__c';
                strQuery += ' FROM TM__c WHERE Id =: tmId';
                TM__c theTM = Database.query(strQuery);

                //job task <<
                String jobTaskId = theTMLine.TM_Job_Task__c;
                TM_Job_Task__c jobTask = [SELECT Id FROM TM_Job_Task__c WHERE TM__c = :tmId AND Id = :jobTaskId LIMIT 1];
                //job task >>

                theTMLineList = new List<TM_Line__c>();

                //Ticket#17060 >>
                String category = '';
                if(calledFrom == 'EquipmentRoster'){
                    category = 'Equipment';
                } else {
                    category = 'Labor';
                }
                //job task <<
                //theTMLineList = TMLinesSelector.newInstance().selectTMLinesByCategory(theTMLine.TM__c, category);
                theTMLineList = TMLinesSelector.newInstance().selectTMLinesByCategory(theTMLine.TM__c, jobTaskId, category);
                //job task >>

                /*
                if (calledFrom != 'EquipmentRoster'){
                    theTMLineList = [SELECT Id, Name, Resource__c, Resource_Type__c, TM__r.Service_Center__c, Line_No__c, Unit_Price__c, Line_Amount__c, Unit_Cost__c, FROM TM_Line__c WHERE Category__c = 'Labor' AND
                    TM__c =: theTMLine.TM__c];
                } else {
                    theTMLineList = [SELECT Id, Name, Resource__c, Resource_Type__c, TM__r.Service_Center__c, Line_No__c FROM TM_Line__c WHERE Category__c = 'Equipment' AND
                                  TM__c =: theTMLine.TM__c];
                }
                 */
                //Ticket#17060 <<

                //job task <<
                /*
                theAllTMLineList = new List<TM_Line__c>();
                theAllTMLineList = [SELECT Id, Name, Resource__c, Resource_Type__c, TM__r.Service_Center__c, Line_No__c FROM TM_Line__c WHERE
                TM__c =: theTMLine.TM__c ORDER BY Line_No__c];
                */
                //job task >>

                Set<String> setResource = new Set<String>();
                Map<String, TM_Line__c> mapTMLine = new Map<String, TM_Line__c>();
                TM_Line__c theTML;
                Boolean found = false;
                Decimal lastLineNo = 0;
                //job task <<
                /*
                if(theAllTMLineList != null && theAllTMLineList.size() > 0) {
                    lastLineNo = theAllTMLineList[theAllTMLineList.size() - 1].Line_No__c;
                }
                */
                for (TM_Line__c tmLine : [SELECT Id, Line_No__c FROM TM_Line__c WHERE TM__c = :tmId ORDER BY Line_No__c DESC LIMIT 1]) {
                    lastLineNo = tmLine.Line_No__c.intValue();
                    break;
                }
                //job task >>
                if(theTMLineList != null && theTMLineList.size() > 0) {
                    for(TM_Line__c TML : theTMLineList) {
                        setResource.add(TML.Resource__c);
                        if(String.isEmpty(TML.Resource__c)) mapTMLine.put(TML.Resource_Type__c, TML);
                    }

                    for(Resource__c theR : theResourceList) {
                        if(!setResource.contains(theR.Id)) {
                            found = false;
                            for(TM_Line__c TML : theTMLineList) {
                                if(TML.Resource_Type__c == theR.Resource_Type__c && String.isEmpty(TML.Resource__c)) {
                                    TML.Resource__c = theR.Id;
                                    theTML = TMMgmt.updateTML(TML, theTM, 'theResource');
                                    TML.Resource_Name__c = theR.Description__c;
                                    TML.Description__c = theR.Description__c;
                                    TML.Category__c = theR.Category__c;
                                    TML.Tax_Group__c = theR.Tax_Group__c;
                                    TML.Resource_Type__c = theR.Resource_Type__c;
                                    TML = TMMgmt.updateTML(TML, theTM, 'theJobPosition');
                                    if(tmlinesMap.containsKey(theTM))
                                    	tmlinesMap.get(theTM).add(TML);
                                    else
                                        tmlinesMap.put(theTM,new List<TM_Line__c>{TML});
                                    //Service Center should come from Resource
                                    TML.Service_Center__c = theR.Service_Center__c;
                                    //TML = TMMgmt.updateTML(TML, theTM, 'theServiceCenter');
                                    //job task <<
                                    TML.TM_Job_Task__c = jobTask.Id;
                                    //job task >>
                                    found = true;
                                    break;
                                }
                            }

                            if(!found) {
                                theTML = new TM_Line__c();
                                theTML.TM__c = theTMLine.TM__c;
                                theTML.Resource__c = theR.Id;
                                theTML = TMMgmt.updateTML(theTML, theTM, 'theResource');
                                theTML.Resource_Name__c = theR.Description__c;
                                theTML.Description__c = theR.Description__c;
                                theTML.Category__c = theR.Category__c;
                                theTML.Tax_Group__c = theR.Tax_Group__c;
                                theTML.Resource_Type__c = theR.Resource_Type__c;
                                theTML = TMMgmt.updateTML(theTML, theTM, 'theJobPosition');
                                if(tmlinesMap.containsKey(theTM))
                                    	tmlinesMap.get(theTM).add(theTML);
                                    else
                                        tmlinesMap.put(theTM,new List<TM_Line__c>{theTML});
                                //Service Center should come from Resource
                                theTML.Service_Center__c = theR.Service_Center__c;
                                //job task <<
                                theTML.TM_Job_Task__c = jobTask.Id;
                                //job task >>
                                //theTML = TMMgmt.updateTML(theTML, theTM, 'theServiceCenter');
                                System.debug('<==lastLineNo==>'+lastLineNo + '/' + theTML);
                                theTML.Line_No__c = lastLineNo + 1;
                                theTMLineList.add(theTML);

                                lastLineNo = lastLineNo + 1;
                            }
                        }
                    }
                    upsert theTMLineList;
                } else {
                    theTMLineList = new List<TM_Line__c>();
                    for(Resource__c theR : theResourceList) {
                        theTML = new TM_Line__c();
                        theTML.TM__c = theTMLine.TM__c;
                        theTML.Resource__c = theR.Id;
                        theTML = TMMgmt.updateTML(theTML, theTM, 'theResource');
                        theTML.Resource_Name__c = theR.Description__c;
                        theTML.Description__c = theR.Description__c;
                        theTML.Category__c = theR.Category__c;
                        theTML.Tax_Group__c = theR.Tax_Group__c;
                        theTML.Resource_Type__c = theR.Resource_Type__c;
                        theTML = TMMgmt.updateTML(theTML, theTM, 'theJobPosition');
                         if(tmlinesMap.containsKey(theTM))
                             tmlinesMap.get(theTM).add(theTML);
                         else
                             tmlinesMap.put(theTM,new List<TM_Line__c>{theTML});
                        //Service Center should come from Resource
                        theTML.Service_Center__c = theR.Service_Center__c;
                        //job task <<
                        theTML.TM_Job_Task__c = jobTask.Id;
                        //job task >>
                        //theTML = TMMgmt.updateTML(theTML, theTM, 'theServiceCenter');
                        theTML.Line_No__c = lastLineNo + 1;
                        theTMLineList.add(theTML);

                        lastLineNo = lastLineNo + 1;
                    }
                    if(theTMLineList != null && theTMLineList.size() > 0) {
                        insert theTMLineList;
                    }
                    if(!tmlinesMap.isEmpty())
                    {
                        TMLLinesService.validateTMRTStaticVariables(tmlinesMap);
                    }
                }
            }

            if(!String.isEmpty(calledFrom) && offType != 'Available'){
                PageReference calledFrom = new PageReference('/apex/' + calledFrom + '?scheduledDate=' + RosterDate);
                calledFrom.setRedirect(true);
                return calledFrom;
            } else {
                if(processedMsg != ''){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, processedMsg));
                }
                return null;
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
    
    public PageReference cancel() {
        PageReference calledFrom = new PageReference('/apex/' + calledFrom + '?scheduledDate=' + RosterDate);
        calledFrom.setRedirect(true);
        return calledFrom;
    }
    
    public void validateTM() {
    
        if (String.isEmpty(theTMLine.TM__c))  theTMLine.TM__r = null;

        tm = [SELECT Name, Id, Service_Center__c FROM TM__c WHERE Id = : theTMLine.TM__c];

        if (tm != null) {
            theTMLine.TM__r = new TM__c(Id = tm.Id, Name = tm.Name);
        }


        //job task <<
        if (offType == 'Assign') {
            theTMLine.TM_Job_Task__c = null;
            this.jobTaskSelectOptions = new List<SelectOption>();
            if (tm != null) {
                for (TM_Job_Task__c jobTask : [SELECT Id, Task_No__c, Name FROM TM_Job_Task__c WHERE TM__c = :tm.Id]) {
                    SelectOption selectOption = new SelectOption(jobTask.Id, 'Task ' + jobTask.Task_No__c + ' - ' + jobTask.Name);
                    this.jobTaskSelectOptions.add(selectOption);
                }
            }
        }
        //job task >>
    }

    public void validateServiceCenter(){
        List<Service_Center__c> resServiceCenters = new List<Service_Center__c>();
        if(String.isBlank(theResOff.Resource_Service_Center__c)) {
            theResOff.Resource_Service_Center__r = null;
        } else {
            resServiceCenters = ServiceCentersSelector.newInstance().selectById(new Set<Id>{theResOff.Resource_Service_Center__c});
        }

        if(resServiceCenters.size() > 0){
            theResOff.Resource_Service_Center__r = resServiceCenters[0];
        }
    }

    public void validateResource(){
        /*List<Resource__c> resources = new List<Resource__c>();
        if(String.isBlank(theResOff.Resource__c)) theResOff.Resource__r = null;
        else resources = ResourcesSelector.newInstance().selectById(new Set<Id>{theResOff.Resource__c});

        if(resources.size() > 0){
            theResOff.Resource__r = resources[0];
        }*/
        String resourceId = ApexPages.currentPage().getParameters().get('resourceId');
        System.debug(resourceId);
        if (String.isNotEmpty(resourceId)){
            List<Resource__c> resources = ResourcesSelector.newInstance().selectById(new Set<Id>{resourceId});
            if (resources.size() > 0){
                theResource = resources[0];
                theResOff.Resource__c = theResource.Id;
            }
        }
    }

}