public with sharing class TimesheetTriggerMgmt {
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;

    public static void TSInsertUpdate(Timesheet__c[] TSList, Map<Id, Timesheet__c> oldTSMap, Boolean isInsert) {
        Map<String, Timesheet__c> nameTSMap = new Map<String, Timesheet__c>();
        //system.debug('TSList***' + TSList);
        //system.debug('oldTSMap***' + oldTSMap);
        for (Timesheet__c theTS : TSList) {
            if (IsInsert) {
                mapNumberSeries = companyMgmt.getNumber('Timesheet');
                theNumberingSeries = mapNumberSeries.get('Timesheet');
                theTS.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
            } else {
                if (theTS.Name != oldTSMap.get(theTS.Id).Name){
                    theTS.addError('You are not allowed to change Timesheet No: ' + theTS.Name);
                }
            }

            if (string.isBlank(theTS.Name)) {
                theTS.Name.addError('Timesheet No. cannot be blank.');
            }

            if (isInsert || (theTS.Name != oldTSMap.get(theTS.Id).Name)) {
                if (nameTSMap.containsKey(theTS.Name)) {
                    theTS.addError('Duplicate Timesheet No. is not allowed. No.: ' + theTS.Name);
                } else {
                    nameTSMap.put(theTS.Name, theTS);
                }
            }
        }

        for (Timesheet__c theTS : [SELECT Name FROM Timesheet__c WHERE Name IN :nameTSMap.keySet()]) {
            Timesheet__c theNewTS = nameTSMap.get(theTS.Name);
            theNewTS.addError('Timesheet already exists with same Name : ' + theTS.Name);
        }

        update mapNumberSeries.values();
    }

    public static void TSDelete(Timesheet__c[] tSList){
        //System.debug('Timesheet ' + tSList);
        for(Timesheet__c ts:tSList){
            if(ts.Status__c != 'Open' && !Test.isRunningTest()){
                throw new DataException('Can not delete ' + ts.Status__c + 'timesheet!');
            }
        }
    }

    public static void TSLDelete(Timesheet_Line__c[] tslList){

        //System.debug('Trigger Mgmt Timesheet Lines ' + tslList);
        if(CompanyMgmt.systemCall == false || CompanyMgmt.systemCall == null){
            //System.debug('Trigger Mgmt Timesheet Lines in If ');
            Set<String> tsIds = new Set<String>();
            for(Timesheet_Line__c tsl:tslList){
                if(!tsIds.contains(tsl.Timesheet__c)){
                    tsIds.add(tsl.Timesheet__c);
                }
            }
            List<Timesheet__c> tsList = [SELECT Id, Status__c FROM Timesheet__c WHERE Id = :tsIds];
            //System.debug('Timesheet from TSL Trigger ' + tsList);
            for(Timesheet__c ts:tsList){
                if(ts.Status__c != 'Open'){
                    throw new DataException('Can not delete timesheet line when timesheet is in ' + ts.Status__c + '!');
                }
            }
        }
    }

    public static void TSLInsertUpdate(List<Timesheet_Line__c> tslList){
        //shop time job <<
        Set<Id> tsIds = new Set<id>();
        //Ticket#13584 prepare T&M Line Id set

        Set<Id> tmlIds = new Set<Id>();
        for (Timesheet_Line__c tsl : tslList) {
            tsIds.add(tsl.Timesheet__c);
            //Ticket#13584 prepare T&M Line Id set
            tmlIds.add(tsl.T_M_Line__c);
        }
        
        Map<Id, Timesheet__c> tss = new Map<Id, TimeSheet__c>();
        for (Timesheet__c ts : [SELECT Id, Service_Center__c, Service_Center__r.Shop_Time_Sales_Order__c FROM Timesheet__c WHERE Id IN :tsIds]) {
            tss.put(ts.Id, ts);
        }

        //Ticket#13584
        Map<Id, TM_Line__c> tmlIdMap = new Map<Id, TM_Line__c>();
        for(TM_Line__c tml: [SELECT Id, TM__r.Name, Line_No__c FROM TM_Line__c WHERE Id IN :tmlIds]){
            tmlIdMap.put(tml.Id, tml);
        }

        //shop time job >>
        
        for(Timesheet_Line__c tsl:tslList){
            //System.debug('TSL Insert Time Type ' + tsl.Time_Type__c);
            if(tsl.Time_Type__c == 'Flat Pay'){
                //Ticket#13584 >>
                String tmInfo = '';
                if(tmlIdMap.get(tsl.T_M_Line__c) != null){
                    tmInfo = 'T&M: ' + tmlIdMap.get(tsl.T_M_Line__c).TM__r.Name +
                                ' Line No. ' + tmlIdMap.get(tsl.T_M_Line__c).Line_No__c;
                }
                //Ticket#13584 <<

                if(tsl.Sales_Order__c == null){
                    tsl.Sales_Order__c.addError('Sales Order field must not be blank for Flat Pay line! ' + tmInfo);
                    //throw new DataException('Sales Order field must not be blank for Flat Pay line!');
                }
                //shop time job <<
                //Ticket# 13409 >>
                if(tsl.Net_Hours__c != null && tsl.Net_Hours__c != 0){
                    tsl.Net_Hours__c.addError('Net Hours field for Flat Pay line must not have a value! ' + tmInfo);
                }
                //Ticket# 13409 <<
                /*
                if(tsl.TM__c == null){
                    tsl.TM__c.addError('T&M field must not be blank for Flat Pay line!');
                    //throw new DataException('T&M field must not be blank for Flat Pay line!');
                }
                if(tsl.T_M_Line__c == null){
                    tsl.T_M_Line__c.addError('T&M Line must not be blank for Flat Pay line!');
                    //throw new DataException('T&M Line must not be blank for Flat Pay line!');
                }
                */
                Timesheet__c ts = tss.get(tsl.Timesheet__c);
                if (tsl.Sales_Order__c != ts.Service_Center__r.Shop_Time_Sales_Order__c && tsl.Time_Type_Code__c != 'PDL') {
                    if(tsl.TM__c == null){
                        tsl.TM__c.addError('T&M field must not be blank for Flat Pay line! ' + tmInfo);
                    }
                    if(tsl.T_M_Line__c == null){
                        tsl.T_M_Line__c.addError('T&M Line must not be blank for Flat Pay line! ' + tmInfo);
                    }
                }
                //shop time job >>
                
                if(tsl.Rate__c == null || tsl.Rate__c == 0){
                    tsl.Rate__c.addError('Rate field must not be blank or 0 for Flat Pay line! ' + tmInfo);
                    //throw new DataException('Rate field must not be blank or 0 for Flat Pay line');
                }
            }
        }
    }
/*
    public static void TMLInsertUpdate(List<TM_Line__c> TMLList, Map<Id, TM_Line__c > oldTMMap) {
        Set<Id> theResourceIds = new Set<Id>();

        for (TM_Line__c theTSL : TMLList) {
            //Possible to have blank Resource when create TM
            //if (string.isBlank(theTSL.Resource__c)) {
            //    theTSL.Resource__c.addError('Resource cannot be blank. ' + theTSL.Line_No__c);
            //}

            if (string.isBlank(theTSL.Category__c)) {
                theTSL.Category__c.addError('Category cannot be blank for Line No: ' + theTSL.Line_No__c);
            }
            if (companyMgmt.zeroIfNull(theTSL.Total_Job_Hours__c) < 0) {
                theTSL.Total_Job_Hours__c.addError('Total Job Hours cannot be negative for Line No: ' + theTSL.Line_No__c);
            }
            if (companyMgmt.zeroIfNull(theTSL.Total_Site_Hours__c) < 0) {
                theTSL.Total_Site_Hours__c.addError('Total Site Hours cannot be negative for Line No: ' + theTSL.Line_No__c);
            }
            if (companyMgmt.zeroIfNull(theTSL.Quantity__c) < 0) {
                theTSL.Quantity__c.addError('Quantity cannot be negative for Line No: ' + theTSL.Line_No__c);
            }

            if (companyMgmt.zeroIfNull(theTSL.Quantity__c) < 0) {
                theTSL.Quantity__c.addError('Quantity cannot be negative. ' + theTSL.Line_No__c);
            }

            if (companyMgmt.zeroIfNull(theTSL.Regular_Hours__c) < 0) {
                theTSL.Regular_Hours__c.addError('Regular Hours cannot be negative for Line No: ' + theTSL.Line_No__c);
            }

            if (companyMgmt.zeroIfNull(theTSL.Overtime_Hours__c) < 0) {
                theTSL.Overtime_Hours__c.addError('Overtime Hours cannot be negative for Line No: ' + theTSL.Line_No__c);
            }

            if (companyMgmt.zeroIfNull(theTSL.Unit_Price__c) < 0) {
                theTSL.Unit_Price__c.addError('Unit Price cannot be negative for Line No: ' + theTSL.Line_No__c);
            }

            if (theTSL.Tax_Group__c == null) {
                theTSL.Tax_Group__c.addError('Tax Group cannot be blank for Line No: ' + theTSL.Line_No__c);
            }
            if (theTSL.Category__c == 'Labor') {
                if (companyMgmt.zeroIfNull(theTSL.Regular_Hours__c) +
                        companyMgmt.zeroIfNull(theTSL.Overtime_Hours__c) != companyMgmt.zeroIfNull(theTSL.Quantity__c)) {
                    theTSL.Total_Site_Hours__c.addError('Regular Hours + Overtime Hours must equal to Quantity for Line No: ' + theTSL.Line_No__c);
                }
                //if (companyMgmt.zeroIfNull(theTSL.Total_Site_Hours__c) != companyMgmt.zeroIfNull(theTSL.Quantity__c)) {
                //    theTSL.Total_Site_Hours__c.addError('Total Site Hours must equal to Quantity. ' + theTSL.Line_No__c);
                //}
            }

            if (theTSL.Resource__c != null) {
                theResourceIds.add(theTSL.Resource__c);
            }
            //if (theTSL.Alternative_Resource__c != null) {
            //    theResourceIds.add(theTSL.Alternative_Resource__c);
            //}
        }
        Map<Id, Resource__c> theResourceMap = new Map<Id, Resource__c>([SELECT Id, Category__c FROM Resource__c WHERE Id IN :theResourceIds]);
        if (theResourceMap.size() > 0) {
            for (TM_Line__c theTSL : TMLList) {
                if (theTSL.Resource__c != null) {
                    if (theTSL.Category__c != theResourceMap.get(theTSL.Resource__c).Category__c) {
                        theTSL.Category__c.addError('Category of Resource ' + theResourceMap.get(theTSL.Resource__c).Category__c + ' should be same as Category on the TM Line: ' + theTSL.Line_No__c);
                    }
                }
                //if (theTSL.Alternative_Resource__c != null) {
                //    if (theTSL.Category__c != theResourceMap.get(theTSL.Alternative_Resource__c).Category__c) {
                //        theTSL.Category__c.addError('Category of Alternate Resource ' + theResourceMap.get(theTSL.Alternative_Resource__c).Category__c + ' should be same as TM Line: ' + theTSL.Line_No__c);
                //    }
                //}

            }
        }

    }
*/
    public static void ROInsertUpdate(Resource_Off__c[] ROList, Map<Id, Resource_Off__c> oldTMMap, Boolean isInsert) {
        Set<Id> setOffType = new Set<Id>();
        Map<Id, Off_Type__c> mapOffType = new Map<Id, Off_Type__c>();
        for (Resource_Off__c theRO : ROList) {
            setOffType.add(theRO.Off_Type__c);
        }

        for (Off_Type__c offType : [SELECT Id, Name FROM Off_Type__c WHERE Id IN: setOffType]){
            mapOffType.put(offType.Id, offType);
        }

        Map<String, Map<Time, Time>> resTimeEntries = new Map<String, Map<Time, Time>>();
        Set<Id> resIdSet = new Set<Id>();
        TimesheetMgmt tsMgmt = new TimesheetMgmt(); //Ticket#13852
        Set<Id> processedIdSet = new Set<Id>(); //Ticket#13852
        Map<Id, String> resNameMap = new Map<Id, String>(); //Ticket#13852
        Map<String, Set<String>> workedItemByResIdAndDate = new Map<String, Set<String>>();

        for (Resource_Off__c theRO : ROList) {
            //Ticket#13763 >>
            /*
            if(theRO.Hours__c != (TimeUtils.calculateHours(theRO.Start_Time__c, theRO.End_Time__c)
                    - TimeUtils.calculateHours(theRO.Lunch_Start_Time__c, theRO.Lunch_End_Time__c))){
                theRO.Hours__c.addError('Hours must equal to total hours - lunch hour!');
            }
            */
            //Ticket#13763 <<

            //Ticket#22941 >>
            if(theRO.Lunch_Start_Time__c != null && theRO.Lunch_End_Time__c == null) {
                theRO.Lunch_End_Time__c.addError('Lunch end time must not be blank!');
            }
            if(theRO.Lunch_Start_Time__c == null && theRO.Lunch_End_Time__c != null) {
                theRO.Lunch_End_Time__c.addError('Lunch start time must not be blank!');
            }
            //Ticket#22941 <<

            // AES-439
            if (theRO.Lunch_Start_Time__c >= theRO.Lunch_End_Time__c) {
                theRO.Lunch_Start_Time__c.addError('Lunch end time must bigger than lunch start time');
            }

            if(isInsert == false){
                theRO.Total_Hours__c = TimeUtils.calculateHours(theRO.Start_Time__c, theRO.End_Time__c);
                Decimal lunchHour = TimeUtils.calculateHours(theRO.Lunch_Start_Time__c, theRO.Lunch_End_Time__c);
                theRO.Hours__c = theRO.Total_Hours__c - lunchHour;
            }

            if (theRO.Hours__c <= 0) theRO.Hours__c.addError('Hours must be > 0. Please enter valid Start Time and End Time.');
            //Checking map containskey based on Ticket# 78187
            if(mapOffType.containsKey(theRO.Off_Type__c))
            {
                if (mapOffType.get(theRO.Off_Type__c).Name == 'Shop Time' && theRO.Shop_Time_Category__c == null){
                    theRO.Shop_Time_Category__c.addError('You must enter Shop Time Category if Resource Off Type is Shop Time.');
                }
                if (mapOffType.get(theRO.Off_Type__c).Name == 'Paid Time Off' && theRO.PTO_Type__c == null){
                    theRO.PTO_Type__c.addError('You must enter PTO Type if Resource Off Type is Paid Time Off.');
                }
                if (mapOffType.get(theRO.Off_Type__c).Name == 'Unavailable' && theRO.Unavailable_Reason__c == null){
                    theRO.Unavailable_Reason__c.addError('You must enter Unavailable Reason if Resource Off Type is Unavailable.');
                }
                 if(isInsert == false &&
                    mapOffType.get(theRO.Off_Type__c).Name != 'Holiday' &&
                    theRO.Start_Time__c != null &&
                    theRO.End_Time__c != null){
                        resIdSet.add(theRO.Resource__c);
                        resNameMap.put(theRO.Resource__c, theRO.Description__c);
                        processedIdSet.add(theRO.Id);
                        resTimeEntries = tsMgmt.updateResTimeEntryMap(resTimeEntries, theRO.Date__c, theRO.Date__c, theRO.Date__c,
                        theRO.Start_Time__c, theRO.End_Time__c, theRO.Resource__c, resNameMap, workedItemByResIdAndDate);
            	}
            }

           

            //Ticket#23164 >>
            if(isInsert == true){
                theRO.KronosTimeEntriesProcessed__c = false;
            }
            //Ticket#23164 <<
        }

        if(isInsert == false && processedIdSet.size() > 0){
            tsMgmt.checkTimeEntryOverlap(resIdSet, resTimeEntries, ROList[0].Date__c, ROList[0].Date__c, processedIdSet);
        }
    }
}