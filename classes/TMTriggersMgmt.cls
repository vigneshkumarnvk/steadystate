public with sharing class TMTriggersMgmt {
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    public static Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup(); // 14484
    public static Map<Id, Resource_Type__c> mapResourceTypes = new Map<Id, Resource_Type__c>();
    public static Map<Id, Resource__c> mapResources = new Map<Id, Resource__c>();

    /*  Ticket#19931
     *    - Job times is not required for Resource Type with Rental Resource Type checked.
     */
    public static void TMInsertUpdate(TM__c[] TMList, Map<Id, TM__c> oldTMMap, Boolean isInsert) {
        if(CompanyMgmt.byPassTrigger != true){
            CompanyMgmt.byPassTrigger = true;
            Map<String, TM__c> nameTMMap = new Map<String, TM__c>();
            Set<Id> theServiceCenterIds = new Set<Id>();
            Map<Id, TM__c> mapTM = new Map<Id, TM__c>();
            Map<Id, TM__c> oldMapTM = new Map<Id, TM__c>();
            Boolean isValidStatus = true;
            if (isInsert) {
                for (TM__c theTM : TMList) {
                    theServiceCenterIds.add(theTM.Service_Center__c);
                }

                Map<Id, Service_Center__c> theSCMap = new Map<Id, Service_Center__c>([
                        SELECT Id, Name, TM_No_Series__c, TM_No_Series__r.Name, Blocked__c
                        FROM Service_Center__c
                        WHERE Id IN :theServiceCenterIds
                ]);

                for (TM__c theTM : TMList) {
                    if (theSCMap.get(theTM.Service_Center__c).TM_No_Series__c == null) {
                        theTM.addError('TM No. Series cannot be blank.');
                    }
                    if (theTM.Status__c == 'Closed') {
                        theTM.addError('Status must be open.');
                    }
                    if(theSCMap.get(theTM.Service_Center__c).Blocked__c == true){
                        theTM.addError('Service center ' + theSCMap.get(theTM.Service_Center__c).Name + ' is deactivated!');
                    }

                    mapNumberSeries = CompanyMgmt.getNumber(theSCMap.get(theTM.Service_Center__c).TM_No_Series__r.Name);
                    theNumberingSeries = mapNumberSeries.get(theSCMap.get(theTM.Service_Center__c).TM_No_Series__r.Name);
                    theTM.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c +
                            String.valueOf(theNumberingSeries.Last_Number_Used__c);
                }
            }

            Set<Id> accountIds = new Set<Id>();
            Set<Id> salesOrderIds = new Set<Id>();
            Map<Id, Account> accountsByIds = new Map<Id, Account>();
            Map<Id, Sales_Order__c> salesOrdersByIds = new Map<Id, Sales_Order__c>();
            for (TM__c theTM : TMList) {
                accountIds.add(theTM.Bill_to_Customer__c);
                salesOrderIds.add(theTM.Sales_Order__c);
            }

            if(accountIds.size() > 0){
                accountsByIds.putAll([SELECT Id, Name, Inter_co_Account__c, Customer_Billing_Instructions__c, Billing_Instructions__c FROM Account WHERE Id IN :accountIds]);
            }

            if(salesOrderIds.size() > 0){
                salesOrdersByIds.putAll([SELECT Id, Name, Sales_Order_Instructions__c FROM Sales_Order__c WHERE Id IN :salesOrderIds]);
            }

            //06.01.2020 << void signature when status is checked to scheduled or open
            Set<Id> tmIdsSignature = new Set<Id>();
            //06.01.2020 >>

            for (TM__c theTM : TMList) {
                if (String.isBlank(theTM.Name)) theTM.Name.addError('T&M No. cannot be blank.');

                if ((isInsert || (theTM.Name != oldTMMap.get(theTM.Id).Name)) && !String.isBlank(theTM.Name)) {
                    if (nameTMMap.containsKey(theTM.Name)) theTM.addError('Duplicate T&M No. is not allowed. No.: ' + theTM.Name); else nameTMMap.put(theTM.Name, theTM);
                }

                if (theTM.Emergency_TM__c != true || (!String.isBlank(theTM.Sales_Order__c))) {
                    if (String.isBlank(theTM.Bill_to_Customer__c)) theTM.Bill_to_Customer__c.addError('Bill-to Customer cannot be blank.');
                }

                //Change Record Id
                if (theTM.Status__c == 'Open'){
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Open').getRecordTypeId();
                } else if (theTM.Status__c == 'Scheduled'){
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Scheduled').getRecordTypeId();
                } else if (theTM.Status__c == 'Mobile Review'){//Mobile T&M review status
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Mobile Review').getRecordTypeId();
                    if(theTM.Mobile_TM__c != true){
                        theTM.Status__c = 'Confirmed';
                        theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Confirmed').getRecordTypeId();
                    }
                } else if (theTM.Status__c == 'Confirmed') {
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Confirmed').getRecordTypeId();
                } else if (theTM.Status__c == 'Received By Billing') {
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Received By Billing').getRecordTypeId();
                } else if (theTM.Status__c == 'Ready to Bill') {
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Ready to Bill').getRecordTypeId();
                } else if (theTM.Status__c == 'Partially Invoiced') {
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Partially Invoiced').getRecordTypeId();
                } else if (theTM.Status__c == 'Fully Invoiced') {
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Fully Invoiced').getRecordTypeId();
                } else if (theTM.Status__c == 'Closed') {
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Closed').getRecordTypeId();
                } else if (theTM.Status__c == 'Void') {
                    theTM.RecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Void').getRecordTypeId();
                }

                if (String.isBlank(theTM.Sales_Order__c)) {
                    if(theTM.Emergency_TM__c == true && theTM.Status__c != TMsService.SCHEDULED_STATUS && theTM.Status__c != TMsService.OPEN_STATUS && theTM.Status__c != TMsService.VOID_STATUS && theTM.Status__c != TMsService.MOBILE_REVIEW_STATUS){
                        theTM.Sales_Order__c.addError('Sales Order cannot be blank with Status: ' + theTM.Status__c);
                    } else if (theTM.Emergency_TM__c == false && theTM.Status__c != TMsService.OPEN_STATUS && theTM.Status__c != TMsService.VOID_STATUS){
                        theTM.Sales_Order__c.addError('Sales Order cannot be blank with Status: ' + theTM.Status__c);
                    }
                } else {
                    Sales_Order__c salesOrder = salesOrdersByIds.get(theTM.Sales_Order__c);
                    if(salesOrder.Sales_Order_Instructions__c != theTM.Sales_Order_Instructions__c){
                        theTM.Sales_Order_Instructions__c = salesOrder.Sales_Order_Instructions__c;
                    }
                }

                if (theTM.Bill_to_Customer__c != null){
                    Account account = accountsByIds.get(theTM.Bill_to_Customer__c);
                    if (account == null) {
                        theTM.addError('T&M must have a bill-to customer.');
                    }
                    if(account.Inter_co_Account__c == true &&
                            theTM.Tax_Liable__c == true) {
                        //Ticket#21211 Inter_co_Account__c - re-labeled to Intra-Co
                        theTM.Tax_Liable__c.addError('Tax Liable must be No for Intra-Co Account.');
                    }
                    theTM.Customer_Billing_Instructions__c = AccountsService.generateCustomerBillingInstructions(account);
                }

                if (String.isBlank(theTM.Status__c)) {
                    theTM.Status__c.addError('Status cannot be blank.');
                }

                if (String.isBlank(theTM.Subsidiary_Company__c)) {
                    theTM.Subsidiary_Company__c.addError('Subsidiary Company cannot be blank.');
                }

                if (String.isBlank(theTM.Service_Center__c)) {
                    theTM.Service_Center__c.addError('Service Center cannot be blank.');
                }

                if (theTM.Scheduled_Date__c == null && theTM.Status__c != 'Open' && theTM.Status__c != 'Void') {
                    theTM.Scheduled_Date__c.addError('Scheduled Date cannot be blank with Status: ' + theTM.Status__c);
                }

                if (!isInsert) {
                    if (theTM.Print_Site_Name__c == true && String.isBlank(theTM.Site_Name__c)) {
                        theTM.Site_Name__c.addError('Site Name cannot be blank');
                    }
                    // Check Status One Step or After
                    if (theTM.Status__c != oldTMMap.get(theTM.Id).Status__c) {
                        String preStatus = oldTMMap.get(theTM.Id).Status__c;

                        if (theTM.Status__c == 'Open' && (preStatus != 'Scheduled' && preStatus != 'Void')) {
                            isValidStatus = false;
                        }

                        //Mobile T&M review status >>
                        if (theTM.Status__c == 'Scheduled' && (preStatus != 'Open' && preStatus != 'Confirmed' && preStatus != 'Mobile Review')) {
                            isValidStatus = false;
                        }

                        if (theTM.Status__c == TMsService.MOBILE_REVIEW_STATUS && (preStatus != TMsService.CONFIRMED_STATUS && preStatus != TMsService.SCHEDULED_STATUS)) {
                            isValidStatus = false;
                        }

                        if(theTM.Mobile_TM__c == true) {
                            if(CompanyMgmt.systemCall == false){
                                if (theTM.Status__c == 'Confirmed' && (preStatus != 'Mobile Review')){
                                    isValidStatus = false;
                                }
                            } else {
                                if (theTM.Status__c == 'Confirmed' && (preStatus != 'Mobile Review' && preStatus != 'Fully Invoiced' && preStatus != 'Sent to EQAI')){
                                    isValidStatus = false;
                                }
                            }
                        } else {
                            if(CompanyMgmt.systemCall == false){
                                if (theTM.Status__c == 'Confirmed' && (preStatus != 'Scheduled')) {
                                    isValidStatus = false;
                                }
                            } else {
                                if (theTM.Status__c == 'Confirmed' && (preStatus != 'Scheduled' && preStatus != 'Fully Invoiced' && preStatus != 'Sent to EQAI')) {
                                    isValidStatus = false;
                                }
                            }
                        }
                        if(theTM.Status__c == 'Confirmed' && (preStatus == 'Scheduled' || preStatus == 'Mobile Review')){
                            theTM.Confirmed_by__c = UserInfo.getUserId();
                            //Ticket#29996 >>
                            logConfirmedDatetimeInfo(theTM);
                            //Ticket#29996 <<
                        }

                        if (theTM.Status__c == 'Void' && preStatus != 'Open') {
                            theTM.addError('You can only Void T&M when status is Open. ' + theTM.Name);
                        }

                        if (!isValidStatus) {
                            theTM.addError('New Status must be one step before or after Old Status. ' + theTM.Name + ' New Status: ' + theTM.Status__c + ' Old: ' + preStatus);
                        }

                        if(CompanyMgmt.systemCall != true){
                            if(theTM.Status__c == 'Closed'){
                                theTM.addError('You cannot manually change T&M status to ' + theTM.Status__c + ' using status path!');
                            }

                            if(theTM.Status__c == 'Fully Invoiced' || theTM.Status__c == 'Partially Invoiced'){
                                theTM.addError('You cannot manually change T&M status to ' + theTM.Status__c);
                            }

                            if(theTM.Status__c == TMsService.CONFIRMED_STATUS && preStatus == TMsService.FULLY_INVOICED_STATUS){
                                theTM.addError('You cannot manually change T&M status from ' + preStatus + ' to ' + theTM.Status__c);
                            }

                            if (theTM.Status__c == 'Ready to Bill' && (preStatus == 'Fully Invoiced' || preStatus == 'Partially Invoiced')) {
                                theTM.addError('You cannot manually change T&M status from ' + preStatus + ' to ' + theTM.Status__c);
                            }
                        }

                        //06.01.2020 << void signature when status is checked to scheduled or open
                        if (preStatus != 'Open' && preStatus != 'Scheduled' && (theTM.Status__c == 'Scheduled' || theTM.Status__c == 'Open')) {
                            theTM.Field_TM_PDF_Sent__c = false;
                            theTM.Field_TM_PDF_Saved__c = false;
                            theTM.Accept_Terms_and_Conditions__c = false;
                            theTM.Customer_Not_Available__c = false;
                            tmIdsSignature.add(theTM.Id);
                        }
                        //06.01.2020 >>

                        //Ticket#19105
                        if(((preStatus == TMsService.SCHEDULED_STATUS || preStatus == TMsService.MOBILE_REVIEW_STATUS) && theTM.Status__c == TMsService.CONFIRMED_STATUS)) {
                            if (String.isBlank(theTM.Tax_Area__c)) {
                                theTM.Tax_Area__c.addError('Tax Area cannot be blank.');
                            }
                        }
                    }
                    // Check No
                    if (!isInsert && (theTM.Name != oldTMMap.get(theTM.Id).Name)) {
                        theTM.addError('You are not allowed to change T&M No: ' + theTM.Name);
                    }

                    mapTM.put(theTM.Id, theTM);
                    oldMapTM.put(theTM.Id, oldTMMap.get(theTM.Id));

                    //Ticket#21817 >>
                    if(TMsService.PMReviewSetNullByTMLineUpdated == false) {
                        if (theTM.Project_Manager_Reviewed__c == true && oldTMMap.get(theTM.Id).Project_Manager_Reviewed__c != true) {
                            theTM.Reviewed_Date__c = System.now();
                            theTM.Reviewed_By__c = UserInfo.getUserId();
                            theTM.Reviewed_At_Status__c = oldTMMap.get(theTM.Id).Status__c;
                        } else if (theTM.Project_Manager_Reviewed__c == true && oldTMMap.get(theTM.Id).Project_Manager_Reviewed__c == true) {
                            if (isTMHeaderUpdated(theTM, oldTMMap.get(theTM.Id)) == true) {
                                theTM.Project_Manager_Reviewed__c = false;
                                theTM.Reviewed_Date__c = null;
                                theTM.Reviewed_By__c = null;
                                theTM.Reviewed_At_Status__c = null;
                            }
                        }
                    } else {
                        theTM.Project_Manager_Reviewed__c = false;
                        theTM.Reviewed_Date__c = null;
                        theTM.Reviewed_By__c = null;
                        theTM.Reviewed_At_Status__c = null;
                    }
                    //Ticket#21817 <<
                }
            }

            if (tmIdsSignature.size() > 0) {
                updateSignatures(tmIdsSignature);
                //signature request <<
                /*List<Signature__c> signatures = [SELECT Id FROM Signature__c WHERE TM__c IN :tmIdsSignature AND Voided__c <> TRUE];
                //signature request >>
                for (Signature__c signature : signatures) {
                    signature.Voided__c = true;
                }
                if (signatures.size() > 0) {
                    update signatures;
                }*/
            }

            for (TM__c theTM : [SELECT Name FROM TM__c WHERE Name IN :nameTMMap.keySet()]) {
                TM__c theNewTM = nameTMMap.get(theTM.Name.toUpperCase());
                theNewTM.addError('Duplicate T&M No. is not allowed. Purchase Order: ' + theNewTM.Name);
            }

            update mapNumberSeries.values();

            //Must be kept on TM level in order to display errors when changing Status using Path.
            //Ticket#22307 - add Resource__r.Bypass_Time_Overlap_Checking__c
            List<TM_Line__c> TMLList = new List<TM_Line__c>();
            TMLList = [
                    SELECT Id, Name, Resource__c, TM__r.Scheduled_Date__c, TM__c, TM__r.Name, Category__c, Line_No__c, Job_Start_Time__c,
                            Job_End_Time__c, Site_Start_Time__c, Site_End_Time__c, Pick_Up_Rental__c,Resource_Type__r.Fleet_No_Required__c,
                            Service_Center__r.Equipment_Fleet_No_Not_Required__c, Quantity__c, Unit_Price__c, Line_Amount__c, Service_Center__c,
                            Resource__r.Non_Payroll_Labor_Resource__c,Resource__r.Bypass_Time_Overlap_Checking__c, Resource_Name__c,To_Invoice__c, Invoiced__c,
                            Bill_as_Lump_Sum__c, Non_Billable__c, Line_Amt_Incl_Tax__c, TM__r.Sales_Order__r.Portal_Basis__c,
                            TM__r.Sales_Order__r.Portal_Basis_Adv__c, TM__r.Sales_Order__r.Overtime_Rate__c,
                            TM__r.Sales_Order__r.Lump_Sum__c, TM__r.Sales_Order__r.Daily_Rate__c,Billing_Start_Time__c,
                            Billing_End_Time__c, Resource__r.Status__c, Resource__r.Out_of_Service_Date__c, Resource__r.Name,
                            Unit_of_Measure__c,Regular_Rate__c,Premium_Rate__c, Overtime_Rate__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                            Cost_Method__c, Facility__c, Container_Size__c, Min_Sell_Qty__c, Unit_Weight_Vol__c,
                            Markup__c, Cost_Qty__c, Tax_Group__c, Tax_Pct__c, Line_Cost__c, Markup_Option__c, Tax__c,
                            Regular_Hours__c, Overtime_Hours__c, Premium_Hours__c, Parent_Line__c, Parent_Line__r.Line_No__c,
                            Resource_Type__r.Rental_Resource_Type__c,KronosTimeEntriesProcessed__c, Kronos_Integration_Note__c, Total_Job_Hours__c, Total_Site_Hours__c
                    FROM TM_Line__c
                    WHERE TM__c IN:mapTM.keySet()
            ];

            String status = '';
            String oldStatus = '';
            Map<Id, String> theMapTMError = new Map<Id, String>();

            //Check Overlap
            if (mapTM.size() > 0 && TMLList != null && TMLList.size() > 0) {
                for (TM_Line__c theTML : TMLList) {
                    //Check time buckets and Resource <> blank
                    status = mapTM.get(theTML.TM__c).Status__c;
                    oldStatus = oldTMMap.get(theTML.TM__c).Status__c;
                    if(oldStatus != 'Fully Invoiced' && oldStatus != 'Partially Invoiced') {
                        if (theTML.TM__c != null && theTML.Category__c == 'Labor') {
                            if (status == 'Confirmed' || status == 'Received By Billing' || status == 'Ready to Bill') {
                                if (theTML.Job_Start_Time__c == null || theTML.Job_End_Time__c == null || theTML.Site_Start_Time__c == null || theTML.Site_End_Time__c == null) {
                                    theMapTMError.put(theTML.TM__c, '*Job Start Time, Job End Time, Site Start Time or Site End Time cannot be blank ' + 'when Status is Confirmed or later for T&M: ' + theTML.TM__r.Name + ' Line No: ' + theTML.Line_No__c);
                                }
                            }
                            if (status == 'Confirmed' && (oldStatus == 'Scheduled' || oldStatus == 'Mobile Review')) {
                                if (theTML.Resource__c == null) {
                                    theMapTMError.put(theTML.TM__c, 'Resource must not be blank when Status is Confirmed for T&M: ' + theTML.TM__r.Name + ' Line No: ' + theTML.Line_No__c);
                                }

                                if(theTML.Lunch_Start_Time__c != null && theTML.Lunch_End_Time__c == null){
                                    theMapTMError.put(theTML.TM__c, 'Lunch End Time must not be blank when Status is Confirmed for T&M: ' + theTML.TM__r.Name + ' Line No: ' + theTML.Line_No__c);
                                }

                                if(theTML.Lunch_End_Time__c != null && theTML.Lunch_Start_Time__c == null){
                                    theMapTMError.put(theTML.TM__c, 'Lunch Start Time must not be blank when Status is Confirmed for T&M: ' + theTML.TM__r.Name + ' Line No: ' + theTML.Line_No__c);
                                }

                                //Kronos Lunch Time check >>
                                Boolean isValid = TMLLinesService.isLunchTimeValid(theTML.Job_Start_Time__c, theTML.Job_End_Time__c, theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c, theTML.Site_Start_Time__c, theTML.Site_End_Time__c);
                                if (isValid == false) {
                                    theMapTMError.put(theTML.TM__c, 'Lunch times entered are not valid. Please make sure lunch times are either within the job start and job end times / job start and site start times / site start and site end times / or site end and job end times. T&M: ' + theTML.TM__r.Name + ' Line No: ' + theTML.Line_No__c);
                                } else {
                                    //Ticket#23365
                                    isValid = TMLLinesService.lunchTimeCheckForKronos(theTML.Job_Start_Time__c, theTML.Job_End_Time__c, theTML.Site_Start_Time__c, theTML.Site_End_Time__c, theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c);
                                    if(isValid == false){
                                        theMapTMError.put(theTML.TM__c, 'Lunch start times entered are not valid. Please make sure lunch start/end time is not the same as job start, site start, site end and job end times. T&M: ' + theTML.TM__r.Name + ' Line No: ' + theTML.Line_No__c);
                                    }
                                }
                                //Kronos Lunch Time check <<
                                //Ticket#24918 >>
                                isValid = TMLLinesService.isJobAndSiteTimeValid(theTML.Job_Start_Time__c, theTML.Job_End_Time__c, theTML.Site_Start_Time__c, theTML.Site_End_Time__c);
                                if (isValid == false) {
                                    theMapTMError.put(theTML.TM__c, 'Please make sure site times are valid! For Line No. ' + theTML.Line_No__c);
                                }
                                //Ticket#24918 <<
                            }
                        }

                        if (String.isNotBlank(theTML.TM__c) && theTML.Category__c == 'Equipment' && String.isNotBlank(theTML.Resource_Type__c) && String.isNotBlank(theTML.Service_Center__c)) {
                            if (status == 'Confirmed' && (oldStatus == 'Scheduled' || oldStatus == 'Mobile Review')) {
                                if (theTML.Service_Center__r.Equipment_Fleet_No_Not_Required__c == false && theTML.Resource_Type__r.Fleet_No_Required__c == true && String.isBlank(theTML.Resource__c)) {
                                    theMapTMError.put(theTML.TM__c, 'Equipment field must not be blank for T&M: ' + theTML.TM__r.Name + ' Line No.: ' + theTML.Line_No__c);
                                }
                                if ((theTML.Job_Start_Time__c == null || theTML.Job_End_Time__c == null) && theTML.Resource_Type__r.Fleet_No_Required__c == true && theTML.Resource_Type__r.Rental_Resource_Type__c != true) {
                                    theMapTMError.put(theTML.TM__c, 'Job Start Time & Job End Time field must not be blank for T&M: ' + theTML.TM__r.Name + ' Line No.: ' + theTML.Line_No__c);
                                }

                                if (CompanyMgmt.zeroIfNull(theTML.Quantity__c) == 0 && theTML.Parent_Line__r == null) {
                                    theMapTMError.put(theTML.TM__c, 'Quantity must not be zero when Status is Confirmed for T&M: ' + theTML.TM__r.Name + ' Line No: ' + theTML.Line_No__c);
                                }
                                //job task >>
                                if (String.isBlank(theTML.Unit_of_Measure__c)) {
                                    theMapTMError.put(theTML.TM__c, 'Unit of Measure must not be blank when Status is Confirmed for T&M: ' + theTML.TM__r.Name + ' Line No: ' + theTML.Line_No__c);
                                }

                                if(theTML.Lunch_Start_Time__c != null && theTML.Lunch_End_Time__c != null){
                                    Decimal hours = TimeUtils.calculateHours(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c);
                                    if(hours != 0.50 && hours != 1.00){
                                        theMapTMError.put(theTML.TM__c,'Lunch time must be half hour or an hour T&M: ' + theTML.TM__r.Name + ' Line No: ' + theTML.Line_No__c);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Date scheduleDate;
            Date StartDate;
            Date EndDate;

            Set<Id> resIdSet = new Set<Id>(); //Ticket#13852
            Set<Id> processedIdSet = new Set<Id>(); //Ticket#13852
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            Map<String, Map<Time, Time>> resTimeEntries = new Map<String, Map<Time, Time>>();
            if (mapTM.size() > 0 && TMLList != null && TMLList.size() > 0) {
                Map<Id, String> resNameMap = new Map<Id, String>();
                Map<String, Set<String>> workedItemByResIdAndDate = new Map<String, Set<String>>(); //Ticket#19920
                for (TM_Line__c tml1 : TMLList) {
                    status = mapTM.get(tml1.TM__c).Status__c;
                    oldStatus = oldTMMap.get(tml1.TM__c).Status__c;
                    if (status == 'Confirmed' && (oldStatus == 'Scheduled' || oldStatus == 'Mobile Review')){
                        scheduleDate = mapTM.get(tml1.TM__c).Scheduled_Date__c;
                        if (scheduleDate == null) {
                            theMapTMError.put(tml1.TM__c, 'Scheduled Date cannot be blank ' + 'when Status is Confirmed for T&M: ' + tml1.TM__r.Name + ' Line No: ' + tml1.Line_No__c);
                        } else {
                            //Ticket#24469 >>
                            if(CompanyMgmt.systemCall != true) {
                                Boolean isPayrollBlockoutPeriod = PayrollMgmt.isPayrollBlockoutPeriod();
                                if (isPayrollBlockoutPeriod == true && tml1.Category__c == 'Labor' && String.isNotBlank(tml1.Resource__c)) {
                                    theMapTMError.put(tml1.TM__c, 'You are not allow to confirm T&M with labor resource during Monday payroll period.');
                                }
                            }
                            //Ticket#24469 <<

                            if (StartDate == null || StartDate > scheduleDate) {
                                StartDate = scheduleDate;
                            }
                            if (EndDate == null || EndDate < scheduleDate) {
                                EndDate = scheduleDate;
                            }

                            //Ticket#24946 >>
                            Boolean identicalJobTimesDetected = false;
                            if(tml1.Job_Start_Time__c == tml1.Site_Start_Time__c && tml1.Site_Start_Time__c == tml1.Site_End_Time__c && tml1.Site_End_Time__c == tml1.Job_End_Time__c){
                                identicalJobTimesDetected = true;
                            }
                            //Ticket#24946 <<

                            // Ticket#22307
                            //if (tml1.Resource__r.Non_Payroll_Labor_Resource__c == false
                            if (tml1.Resource__r.Bypass_Time_Overlap_Checking__c == false
                                    && (tml1.Category__c == 'Labor' || tml1.Category__c == 'Equipment')
                                    && identicalJobTimesDetected == false //Ticket#24946
                                    && !String.isEmpty(tml1.Resource__c)) {

                                resIdSet.add(tml1.Resource__c);
                                resNameMap.put(tml1.Resource__c, tml1.Resource_Name__c + ' Line No. ' + tml1.Line_No__c);
                                resTimeEntries = tsMgmt.updateResTimeEntryMap(resTimeEntries, scheduleDate, scheduleDate, scheduleDate,
                                        tml1.Job_Start_Time__c, tml1.Job_End_Time__c, tml1.Resource__c, resNameMap, workedItemByResIdAndDate);
                                processedIdSet.add(tml1.Id);
                            }
                        }
                    }
                    //Ticket#24469 >>
                    if (oldStatus == 'Confirmed' && (status == 'Scheduled' || status == 'Mobile Review')) {
                        if(CompanyMgmt.systemCall != true) {
                            Boolean isPayrollBlockoutPeriod = PayrollMgmt.isPayrollBlockoutPeriod();
                            if (isPayrollBlockoutPeriod == true && tml1.Category__c == 'Labor' && String.isNotBlank(tml1.Resource__c)) {
                                theMapTMError.put(tml1.TM__c, 'You are not allow to unconfirm T&M with labor resource during Monday payroll period.');
                            }
                        }
                    }
                    //Ticket#24469 <<
                }
            }

            if (resIdSet.size() > 0 && resTimeEntries.size() > 0) {
                tsMgmt.checkTimeEntryOverlap(resIdSet, resTimeEntries, StartDate, EndDate, processedIdSet);
            }

            if (Test.isRunningTest()) {
                StartDate = Date.today();
                EndDate = Date.today().addDays(1);
            }

            // Display error
            for (TM__c theTM : TMList) {
                if (theMapTMError.get(theTM.Id) != null) {
                    theTM.Status__c.addError(theMapTMError.get(theTM.Id));
                }
            }


            // Test Equipment Available
            String scheduledDateValue;
            Set<Date> setScheduleDate = new Set<Date>();
            List<Resource_Off__c> theAllResourceOffList = new List<Resource_Off__c>();

            for (TM__c theTM : TMList) {
                if (theTM.Scheduled_Date__c != null) {
                    setScheduleDate.add(theTM.Scheduled_Date__c);
                }

                if (theTM.Check_Confirmed_Date__c != true && theTM.Status__c == 'Confirmed') {
                    theTM.Confirmed_Date__c =  System.today();
                }
            }

            if (mapTM.size() > 0 && TMLList != null && TMLList.size() > 0) {
                Map<Date, List<Resource_Off__c>> theAllResourceOffMap = new Map<Date, List<Resource_Off__c>>();
                Set<Date> theScheduledDateSet = new Set<Date>();

                List<TM_Line__c> TMLines = new List<TM_Line__c>();
                Set<Id> confirmedAndProcessedLaborLineIds = new Set<Id>();
                Map<Id, TM_Line__c> tmLinesByIds = new Map<Id, TM_Line__c>(TMLList);
                for (TM_Line__c tml1 : TMLList) {
                    // Only check change Status from Scheduled to Confirmed for easier error correction
                    if (status == 'Confirmed' && oldMapTM.get(tml1.TM__c).Status__c == 'Scheduled' || Test.isRunningTest()) {
                        if (tml1.Category__c == 'Equipment') {
                            if (mapTM.get(tml1.TM__c).Scheduled_Date__c != null) {
                                theScheduledDateSet.add(mapTM.get(tml1.TM__c).Scheduled_Date__c);
                            }
                        }
                    } else if (mapTM.get(tml1.TM__c).Status__c == 'Void') {
                        tml1.Job_Start_Time__c = null;
                        tml1.Job_End_Time__c = null;
                        tml1.Site_Start_Time__c = null;
                        tml1.Site_End_Time__c = null;
                        tml1.Quantity__c = null;
                        tml1.Total_Site_Hours__c = null;
                        tml1.Total_Job_Hours__c = null;
                        tml1.KronosTimeEntriesProcessed__c = false;
                        tml1.Kronos_Integration_Note__c = null;
                        TMLines.add(tml1);
                    }

                    //Kronos
                    status = mapTM.get(tml1.TM__c).Status__c;
                    oldStatus = oldMapTM.get(tml1.TM__c).Status__c;
                    TM__c oldTM = oldMapTM.get(tml1.TM__c);
                    TM__c newTM = mapTM.get(tml1.TM__c);
                    if((status != TMsService.CONFIRMED_STATUS && status != TMsService.FULLY_INVOICED_STATUS && status != TMsService.CLOSED_STATUS &&
                            (oldStatus == TMsService.CONFIRMED_STATUS || oldStatus == TMsService.FULLY_INVOICED_STATUS || oldStatus == TMsService.CLOSED_STATUS))
                            || (oldTM.Scheduled_Date__c != null && oldTM.Scheduled_Date__c != newTM.Scheduled_Date__c)
                            || (oldTM.Sales_Order__c != newTM.Sales_Order__c))
                    {
                        if(tml1.Category__c == ResourceService.LABOR_CATEGORY){
                            tml1.KronosTimeEntriesProcessed__c = false;
                            tml1.Kronos_Integration_Note__c = null;
                            if(TMLines.contains(tml1) == false){
                                TMLines.add(tml1);
                            }
                        }
                    }

                    //Ticket#26568 >>
                    if(TimeUtils.getWeekdayName(newTM.Scheduled_Date__c) == 'Sunday'
                            && status == TMsService.SCHEDULED_STATUS
                            && oldStatus == TMsService.MOBILE_REVIEW_STATUS
                            && tml1.Category__c == ResourceService.LABOR_CATEGORY
                            && tml1.KronosTimeEntriesProcessed__c == true) {
                        //TM_Line__c tempTMLine = tmLinesToUpdateByIds.get(tml1.Id);
                        tml1.KronosTimeEntriesProcessed__c = false;
                        tml1.Kronos_Integration_Note__c = null;
                        if(TMLines.contains(tml1) == false) {
                            TMLines.add(tml1);
                        }
                    }
                    //Ticket#26568 <<

                    if(status == TMsService.CONFIRMED_STATUS &&
                            tml1.Category__c == ResourceService.LABOR_CATEGORY &&
                            tml1.KronosTimeEntriesProcessed__c == true){
                        confirmedAndProcessedLaborLineIds.add(tml1.Id);
                    }
                    //Kronos
                }

                //Kronos
                Set<Id> confirmedLaborLineHasClockEntry = new Set<Id>();
                if(confirmedAndProcessedLaborLineIds.size() > 0){
                    List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosLst =
                            [SELECT Id, T_M_Line__c
                                FROM Employee_Clocked_Time_for_Kronos__c
                                WHERE Kronos_Action__c != 'Delete' AND T_M_Line__c IN :confirmedAndProcessedLaborLineIds
                            ];
                    for(Employee_Clocked_Time_for_Kronos__c employeeClockedTimeForKronos : employeeClockedTimeForKronosLst){
                        if(confirmedLaborLineHasClockEntry.contains(employeeClockedTimeForKronos.T_M_Line__c) == false){
                            confirmedLaborLineHasClockEntry.add(employeeClockedTimeForKronos.T_M_Line__c);
                        }
                    }

                    confirmedAndProcessedLaborLineIds.removeAll(confirmedLaborLineHasClockEntry);

                    if(confirmedAndProcessedLaborLineIds.size() > 0){
                        for(Id tmLineId : confirmedAndProcessedLaborLineIds){
                            if(tmLinesByIds.containsKey(tmLineId)){
                                TM_Line__c tempLine = tmLinesByIds.get(tmLineId);
                                tempLine.KronosTimeEntriesProcessed__c = false;
                                tempLine.Kronos_Integration_Note__c = null;
                                if(TMLines.contains(tempLine) == false){
                                    TMLines.add(tempLine);
                                }
                            }
                        }
                    }
                }
                //Kronos

                if (TMLines.size() > 0) {
                    update TMLines;
                }

                if (theScheduledDateSet.size() > 0) {
                    //Get all open Resource Off entries in theScheduledDateSet
                    theAllResourceOffList = ResourceMgmt.selectAllResourceOff('', theScheduledDateSet);
                    for (Resource_Off__c theResourceOff : theAllResourceOffList) {
                        if (theAllResourceOffMap.containsKey(theResourceOff.Date__c)) {
                            theAllResourceOffMap.get(theResourceOff.Date__c).add(theResourceOff);
                        } else {
                            theAllResourceOffMap.put(theResourceOff.Date__c, new List<Resource_Off__c>{
                                    theResourceOff
                            });
                        }
                    }

                    for (TM_Line__c tml1 : TMLList) {
                        status = mapTM.get(tml1.TM__c).Status__c;
                        // Only check change Status from Scheduled to Confirmed for easier error correction
                        if (status == 'Confirmed' && oldMapTM.get(tml1.TM__c).Status__c == 'Scheduled' || Test.isRunningTest()) {
                            if (tml1.Category__c == 'Equipment' && tml1.Resource__c != null) {
                                scheduleDate = mapTM.get(tml1.TM__c).Scheduled_Date__c;
                                if(tml1.Resource__r.Status__c == 'Out of Service' && tml1.Resource__r.Out_of_Service_Date__c <= scheduleDate){
                                    theMapTMError.put(tml1.TM__c, 'Equipment ' + tml1.Resource__r.Name + ' is not available: Out of Service');
                                }
                                if (scheduleDate != null) {
                                    scheduledDateValue = scheduleDate.month() + '/' + scheduleDate.day() + '/' + scheduleDate.year();
                                    if (theAllResourceOffMap != null && theAllResourceOffMap.size() > 0) {
                                        for (Date recordId : theAllResourceOffMap.keySet()) {
                                            if (theAllResourceOffMap.get(recordId) != null) {
                                                for (Resource_Off__c theResourceOff : theAllResourceOffMap.get(recordId)) {
                                                    if (tml1.Resource__c == theResourceOff.Resource__c) {
                                                        theMapTMError.put(tml1.TM__c, 'Equipment ' + theResourceOff.Resource__r.Name + ' is not available: ' + theResourceOff.Off_Type__r.Name);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Display error
            for (TM__c theTM : TMList) {
                if (theMapTMError.get(theTM.Id) != null) {
                    theTM.Status__c.addError(theMapTMError.get(theTM.Id));
                } 
            }

            //Ticket# 13835 >>
            if (!Test.isRunningTest()) {//Otherwise cannot deploy, nonsense test is throw too many query 101 error.
               updateSalesOrderFromTMMap(TMList,mapTM,oldMapTM);
              /*  Set<Id> soIds = new Set<Id>();
                for (TM__c tm : mapTM.values()) {
                    if (tm.Status__c == 'Scheduled' && oldMapTM.get(tm.Id).Status__c == 'Open'){
                        soIds.add(tm.Sales_Order__c);
                    }
                }

                if(soIds.size() > 0){
                    Map<Id, Sales_Order__c> SOFromTMMap = new Map<Id, Sales_Order__c>([
                            SELECT Id, Name, Start_Date__c, End_Date__c, (SELECT Id, Scheduled_Date__c FROM Service_Orders__r WHERE Id NOT IN :mapTM.keySet() AND Status__c <> 'Open' AND Status__c <> 'Void')
                            FROM Sales_Order__c
                            WHERE Id IN :soIds
                    ]);

                    if (mapTM.size() > 0 && SOFromTMMap.size() > 0) {
                        for (TM__c theTM : TMList) {
                            Sales_Order__c theSO = SOFromTMMap.get(theTM.Sales_Order__c);
                            List<TM__c> theTMList = theSO.Service_Orders__r;
                            Boolean isScheduling = false;
                            Date tempStartDate = null;
                            Date tempEndDate = null;

                            if (theTM.Status__c == 'Scheduled' && oldMapTM.get(theTM.Id).Status__c == 'Open') isScheduling = true;
                            if (theTMList.isEmpty() && isScheduling == true) {
                                tempStartDate = theTM.Scheduled_Date__c;
                                tempEndDate = theTM.Scheduled_Date__c;
                            }
                            if (theTMList.isEmpty() && isScheduling == false) {
                                tempStartDate = null;
                                tempEndDate = null;
                            }

                            for (TM__c tm : theTMList) {
                                if (tempStartDate == null) {
                                    if(isScheduling) {
                                        tempStartDate = theTM.Scheduled_Date__c;
                                    } else {
                                        tempStartDate = tm.Scheduled_Date__c;
                                    }
                                }

                                if (tempEndDate == null) {
                                    if(isScheduling) {
                                        tempEndDate = theTM.Scheduled_Date__c;
                                    } else {
                                        tempEndDate = tm.Scheduled_Date__c;
                                    }
                                }

                                if (tm.Scheduled_Date__c < tempStartDate) {
                                    tempStartDate = tm.Scheduled_Date__c;
                                }
                                if (tm.Scheduled_Date__c > tempEndDate) {
                                    tempEndDate = tm.Scheduled_Date__c;
                                }
                            }

                            theSO.Start_Date__c = tempStartDate;
                            theSO.End_Date__c = tempEndDate;
                            SOFromTMMap.put(theSO.Id, theSO);
                        }
                        update SOFromTMMap.values();
                    }
                }*/
            }
            //job task <<
            CompanyMgmt.byPassTrigger = false;
            //job task >>
        }
    }

    //job task <<
    public static void TMAfterInsertUpdate(TM__c[] TMList, Map<Id, TM__c> oldTMMap, Boolean isInsert) {
        if(isInsert == false) {
            if (CompanyMgmt.byPassTrigger != true) {
                Set<TM__c> confirmedTMs = new Set<TM__c>();
                Set<TM__c> unconfirmedTMs = new Set<TM__c>();
                Set<Id> unconfirmedTMIds = new Set<Id>(); //Kronos
                for (TM__c tm : TMList) {
                    if (tm.Status__c == 'Confirmed') {
                        confirmedTMs.add(tm);
                    } else if (tm.Status__c != 'Fully Invoiced' && tm.Status__c != 'Closed' && tm.Status__c != 'Sent to EQAI') {
                        unconfirmedTMs.add(tm);
                        if(TimeUtils.getWeekdayName(tm.Scheduled_Date__c) != 'Sunday') {
                            unconfirmedTMIds.add(tm.Id); //Kronos
                        } else {
                            TM__c oldTM = oldTMMap.get(tm.Id);
                            if(oldTM.Status__c == TMsService.CONFIRMED_STATUS && (tm.Status__c == TMsService.MOBILE_REVIEW_STATUS || tm.Status__c == TMsService.SCHEDULED_STATUS)){
                                unconfirmedTMIds.add(tm.Id);
                            }
                            //Ticket#26568 >>
                            if(oldTM.Status__c == TMsService.MOBILE_REVIEW_STATUS && tm.Status__c == TMsService.SCHEDULED_STATUS){
                                unconfirmedTMIds.add(tm.Id);
                            }
                            //Ticket#26568 <<
                        }
                    }
                }

                if (confirmedTMs.size() > 0) {
                    createBillingWorksheetLinesFromTM(confirmedTMs,TMList);
                   /* try {
                        CompanyMgmt.byPassTrigger = true;
                        //ticket 19916 <<
                        //TMsService.createBillingWorksheetLines(confirmedTMs);
                        if (TMsService.ByPassCreatingBillingWorksheetLines != true) {
                            TMsService.createBillingWorksheetLines(confirmedTMs);
                        }
                        //ticket 19916 >>
                        CompanyMgmt.byPassTrigger = false;
                    } catch (exception ex) {
                        System.debug('Error: ' + ex.getStackTraceString());
                        for (TM__c tm : TMList) {
                            tm.addError(ex.getMessage());
                        }
                    }*/
                }

                if (unconfirmedTMs.size() > 0 || unconfirmedTMIds.size() > 0) {
                    CompanyMgmt.byPassTrigger = true;
                    if(unconfirmedTMs.size() > 0) {
                        TMsService.deleteBillingWorksheetLines(unconfirmedTMs);
                    }
                    //Kronos
                    if(unconfirmedTMIds.size() > 0) {
                        KronosTimeClockService.processUnconfirmedTM(unconfirmedTMIds);
                    }
                    //Kronos
                    CompanyMgmt.byPassTrigger = false;
                }
            }
        }
    }
    //job task >>

    public static void TMLInsertUpdate(List<TM_Line__c> TMLList, Map<Id, TM_Line__c > oldTMLMap, Boolean isInsert) {

        if(CompanyMgmt.byPassLineTrigger != true) {
            //CompanyMgmt.byPassLineTrigger = true; //Ticket#22099
            Set<Id> theSLIds = new Set<Id>();
            Set<Id> setTMIds = new Set<Id>();
            Map<Id, TM__c> theTMMap = new Map<Id, TM__c>();

            Set<Id> uomIdSet = new Set<Id>();
            for (TM_Line__c theTML : TMLList) {
                if(theTML.TM__c != null) {
                    setTMIds.add(theTML.TM__c);
                }
                if(String.isNotBlank(theTML.Unit_of_Measure__c)) {
                    uomIdSet.add(theTML.Unit_of_Measure__c);
                }
            }

            //Map<Id,Unit_of_Measure__c> uomById = new Map<Id, Unit_of_Measure__c>([SELECT Id, Hours_UOM__c FROM Unit_of_Measure__c]);
            //Kronos - add Scheduled Date field
            for (TM__c theTM : [
                    SELECT Id, Name,Status__c,Tax_Liable__c, Tax_Area__c, Scheduled_Date__c, Sales_Order__r.Pay_Rule__c, Sales_Order__c,
                    		Reviewed_By__c, Reviewed_Date__c, Reviewed_At_Status__c, Project_Manager_Reviewed__c
                    FROM TM__c
                    WHERE Id IN :setTMIds
            ]) {
                theTMMap.put(theTM.Id, theTM);
            }

            //Check Invoiced flag when modify
            //We could also modify TM page but are concerned about the performance and complexity of it
            String e1 = 'Invoiced T&M Line cannot be modified for Line No: ';

            if (!isInsert) {
                if (CompanyMgmt.systemCall != true) {
                    Id processedTMId = null;
                    for (TM_Line__c theTML : TMLList) {
                        //Ticket#21817 >>
                        TM__c tm = theTMMap.get(theTML.TM__c);
                        if(processedTMId != tm.Id){
                            processedTMId = tm.Id;
                            TMsService.PMReviewSetNullByTMLineUpdated = false;
                        }
                        //Ticket#21817 <<

                        if (theTML.Invoiced__c){
                            if (theTML.Resource_Type__c != oldTMLMap.get(theTML.Id).Resource_Type__c) {
                                theTML.Resource_Type__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Resource__c != oldTMLMap.get(theTML.Id).Resource__c) {
                                theTML.Resource__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Service_Center__c != oldTMLMap.get(theTML.Id).Service_Center__c) {
                                theTML.Service_Center__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Description__c != oldTMLMap.get(theTML.Id).Description__c) {
                                theTML.Description__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Bill_Site_Time__c != oldTMLMap.get(theTML.Id).Bill_Site_Time__c) {
                                theTML.Bill_Site_Time__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Include_Lunch_Y_N__c != oldTMLMap.get(theTML.Id).Include_Lunch_Y_N__c) {
                                theTML.Include_Lunch_Y_N__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Billing_Start_Time__c != oldTMLMap.get(theTML.Id).Billing_Start_Time__c) {
                                theTML.Billing_Start_Time__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Billing_End_Time__c != oldTMLMap.get(theTML.Id).Billing_End_Time__c) {
                                theTML.Billing_End_Time__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Quantity__c != oldTMLMap.get(theTML.Id).Quantity__c) {
                                theTML.Quantity__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Unit_of_Measure__c != oldTMLMap.get(theTML.Id).Unit_of_Measure__c) {
                                theTML.Unit_of_Measure__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Regular_Hours__c != oldTMLMap.get(theTML.Id).Regular_Hours__c) {
                                theTML.Regular_Hours__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Overtime_Hours__c != oldTMLMap.get(theTML.Id).Overtime_Hours__c) {
                                theTML.Overtime_Hours__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Premium_Hours__c != oldTMLMap.get(theTML.Id).Premium_Hours__c) {
                                theTML.Premium_Hours__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Tax_Group__c != oldTMLMap.get(theTML.Id).Tax_Group__c) {
                                theTML.Tax_Group__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Bill_as_Lump_Sum__c != oldTMLMap.get(theTML.Id).Bill_as_Lump_Sum__c) {
                                theTML.Bill_as_Lump_Sum__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Non_Billable__c != oldTMLMap.get(theTML.Id).Non_Billable__c) {
                                theTML.Non_Billable__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Regular_Rate__c != oldTMLMap.get(theTML.Id).Regular_Rate__c) {
                                theTML.Regular_Rate__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Overtime_Rate__c != oldTMLMap.get(theTML.Id).Overtime_Rate__c) {
                                theTML.Overtime_Rate__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Premium_Rate__c != oldTMLMap.get(theTML.Id).Premium_Rate__c) {
                                theTML.Premium_Rate__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Line_Amount__c != oldTMLMap.get(theTML.Id).Line_Amount__c) {
                                theTML.Line_Amount__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Line_Amt_Incl_Tax__c != oldTMLMap.get(theTML.Id).Line_Amt_Incl_Tax__c) {
                                theTML.Line_Amt_Incl_Tax__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Job_Start_Time__c != oldTMLMap.get(theTML.Id).Job_Start_Time__c) {
                                theTML.Job_Start_Time__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Job_End_Time__c != oldTMLMap.get(theTML.Id).Job_End_Time__c) {
                                theTML.Job_End_Time__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Site_Start_Time__c != oldTMLMap.get(theTML.Id).Site_Start_Time__c) {
                                theTML.Site_Start_Time__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Site_End_Time__c != oldTMLMap.get(theTML.Id).Site_End_Time__c) {
                                theTML.Site_End_Time__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Lunch_Start_Time__c != oldTMLMap.get(theTML.Id).Lunch_Start_Time__c) {
                                theTML.Lunch_Start_Time__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Lunch_End_Time__c != oldTMLMap.get(theTML.Id).Lunch_End_Time__c) {
                                theTML.Lunch_End_Time__c.addError(e1 + theTML.Line_No__c);
                            }
                            if (theTML.Overtime__c != oldTMLMap.get(theTML.Id).Overtime__c) {
                                theTML.Overtime__c.addError(e1 + theTML.Line_No__c);
                            }
                        }
                        //Ticket#21817 >>
                        if(TMsService.PMReviewSetNullByTMLineUpdated == false && isTMLineUpdated(theTML, oldTMLMap.get(theTML.Id)) == true){
                            if(tm.Project_Manager_Reviewed__c == true){
                                TMsService.PMReviewSetNullByTMLineUpdated = true;
                            }
                        }
                        //Ticket#21817 <<
                    }
                }
            } else {
                if (CompanyMgmt.systemCall != true) {
                    for (TM_Line__c tmLine : TMLList) {
                        TM__c tm = theTMMap.get(tmLine.TM__c);
                        if (tm.Project_Manager_Reviewed__c == true) {
                            TMsService.PMReviewSetNullByTMLineUpdated = true;
                        }
                    }
                }
            }

            Set<Id> resourceTypeIdSet = new Set<Id>();
            Set<Id> resourceIdSet = new Set<Id>();
            Map<Id, TM_Line__c> updatedTMLinesByIds = new Map<Id, TM_Line__c>(); //Ticket#23028
            for (TM_Line__c theTML : TMLList) {
                TM__c tm = theTMMap.get(theTML.TM__c); //Kronos
                String tmStatus =  tm.Status__c; //Kronos
                if (String.isBlank(theTML.Category__c)) {
                    theTML.Category__c.addError('Category cannot be blank for Line No: ' + theTML.Line_No__c);
                }
                if (tmStatus != 'Open' && tmStatus != 'Scheduled' && CompanyMgmt.zeroIfNull(theTML.Total_Job_Hours__c) < 0) {
                    theTML.Total_Job_Hours__c.addError('Total Job Hours cannot be negative for Line No: ' + theTML.Line_No__c);
                }
                if (CompanyMgmt.zeroIfNull(theTML.Quantity__c) < 0) {
                    theTML.Quantity__c.addError('Quantity cannot be negative for Line No: ' + theTML.Line_No__c);
                }
                if (CompanyMgmt.zeroIfNull(theTML.Regular_Hours__c) < 0 && theTML.Category__c == 'Labor'
                        && tmStatus != 'Open' && tmStatus != 'Scheduled' && tmStatus != 'Void' && tmStatus != 'Closed') {
                    theTML.Regular_Hours__c.addError('Regular Hours cannot be negative for Line No: ' + theTML.Line_No__c);
                }
                if (CompanyMgmt.zeroIfNull(theTML.Overtime_Hours__c) < 0 && theTML.Category__c == 'Labor'
                        && tmStatus != 'Open' && tmStatus != 'Scheduled' && tmStatus != 'Void' && tmStatus != 'Closed') {
                    theTML.Overtime_Hours__c.addError('Overtime Hours cannot be negative for Line No: ' + theTML.Line_No__c);
                }
                if(CompanyMgmt.zeroIfNull(theTML.Premium_Hours__c) < 0 && theTML.Category__c == 'Labor'
                        && tmStatus != 'Open' && tmStatus != 'Scheduled' && tmStatus != 'Void' && tmStatus != 'Closed') {
                    theTML.Premium_Hours__c.addError('Double Time Hours cannot be negative for Line No: ' + theTML.Line_No__c);
                }

                if ((tmStatus == 'Confirmed' || tmStatus == 'Received By Billing' || tmStatus == 'Ready to Bill')
                        && (theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment')) {
                    if(theTML.Resource_Type__c == null){
                        theTML.Resource_Type__c.addError('Resource Type must not be blank for Line No.: ' + theTML.Line_No__c);
                    }
                }

                if (theTML.Resource__c != null && !mapResources.containsKey(theTML.Resource__c)) {
                    resourceIdSet.add(theTML.Resource__c);
                }

                if (theTML.Sales_Line__c != null) {
                    theSLIds.add(theTML.Sales_Line__c);
                }

                // update Resource Type Unit of Measure 1,2,3,4
                if ((theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment' || theTML.Category__c == 'Bundled') && String.isNotBlank(theTML.Resource_Type__c)){
                    if (!mapResourceTypes.containsKey(theTML.Resource_Type__c)) {
                        resourceTypeIdSet.add(theTML.Resource_Type__c);
                    }
                }

                if ((theTML.Category__c == 'Materials' ||  theTML.Category__c =='Demurrage' || theTML.Category__c == 'Misc. Charges And Taxes'|| theTML.Category__c == 'Waste Disposal') && String.isNotBlank(theTML.Resource__c)) {
                    if (!mapResources.containsKey(theTML.Resource__c)) {
                        resourceIdSet.add(theTML.Resource__c);
                    }
                }

                //Ticket#21547 >>
                if(CompanyMgmt.systemCall != true){
                    if (theTML.Site_Start_Time__c != null && theTML.Site_End_Time__c != null
                            && theTML.Job_Start_Time__c != null && theTML.Job_End_Time__c != null) {
                        Boolean isValid = TMLLinesService.isJobAndSiteTimeValid(theTML.Job_Start_Time__c, theTML.Job_End_Time__c, theTML.Site_Start_Time__c, theTML.Site_End_Time__c);
                        if (isValid == false) {
                            theTML.Site_Start_Time__c.addError('Please make sure site times are valid! For Line No. ' + theTML.Line_No__c);
                        }
                    }
                }
                //Ticket#21547 <<

                //Fix void re-checking issue
                if(CompanyMgmt.systemCall != true) {
                    if (theTML.Lunch_Start_Time__c != null && theTML.Lunch_End_Time__c != null
                            && theTML.Job_Start_Time__c != null && theTML.Job_End_Time__c != null) {
                        Boolean isValid = TMLLinesService.isLunchTimeValid(theTML.Job_Start_Time__c, theTML.Job_End_Time__c, theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c, theTML.Site_Start_Time__c, theTML.Site_End_Time__c);
                        if (isValid == false) {
                            theTML.Lunch_Start_Time__c.addError('Lunch times entered are not valid. Please make sure lunch times are either within the job start and job end times / job start and site start times / site start and site end times / or site end and job end times.');
                        } else {
                            theTML.Lunch__c = TimeUtils.generateLunchHourString(theTML.Lunch_Start_Time__c, theTML.Lunch_End_Time__c);
                        }
                    }
                }

                //PW Travel Hours Cost
                if(theTML.Category__c == ResourceService.LABOR_CATEGORY &&
                        theTML.Job_Start_Time__c != null && theTML.Job_End_Time__c != null &&
                        theTML.Site_Start_Time__c != null && theTML.Site_End_Time__c != null){
                    theTML.Travel_Hours__c = TMLLinesService.calculateTravelHours(theTML);
                }
                //PW Travel Hours Cost

                //Kronos
                if(isInsert == false && tm.Scheduled_Date__c != null && tm.Scheduled_Date__c >= KronosTimeClockService.KRONOSCUTOFFDATE){
                    if(theTML.Category__c == ResourceService.LABOR_CATEGORY &&
                            String.isNotBlank(theTML.Resource__c) &&
                            String.isNotBlank(theTML.Service_Center__c) &&
                            theTML.Service_Center__r.Temporary__c != true &&
                            theTML.Job_Start_Time__c != null){
                        if(oldTMLMap != null && oldTMLMap.containsKey(theTML.Id)){
                            TM_Line__c oldLine = oldTMLMap.get(theTML.Id);
                            if(oldLine.Resource__c != theTML.Resource__c ||
                                    oldLine.Job_Start_Time__c != theTML.Job_Start_Time__c || oldLine.Job_End_Time__c != theTML.Job_End_Time__c ||
                                    oldLine.Site_Start_Time__c != theTML.Site_Start_Time__c || oldLine.Site_End_Time__c != theTML.Site_End_Time__c ||
                                    oldLine.Lunch_Start_Time__c != theTML.Lunch_Start_Time__c || oldLine.Lunch_End_Time__c != theTML.Lunch_End_Time__c ||
                                    (oldLine.Resource_Type__c != theTML.Resource_Type__c && String.isNotBlank(tm.Sales_Order__r.Pay_Rule__c))){
                                theTML.KronosTimeEntriesProcessed__c = false;
								theTML.Kronos_Integration_Note__c = null;

                            }
                        }
                    }
                }

               //Ticket#23028 >>
                if(isInsert == false && theTML.Category__c != ResourceService.LABOR_CATEGORY){
                    TM_Line__c oldLine = oldTMLMap.get(theTML.Id);
                    //System.debug('Info: TMLine: ' + theTML.Line_No__c + ' Qty. -- ' + theTML.Quantity__c + '  OldLine: ' + oldLine.Quantity__c);
                    if (oldLine.Resource_Type__c != theTML.Resource_Type__c || oldLine.Resource__c != theTML.Resource__c
                            || oldLine.Service_Center__c != theTML.Service_Center__c || oldLine.Unit_of_Measure__c != theTML.Unit_of_Measure__c
                            || oldLine.Quantity__c != theTML.Quantity__c || oldLine.Description__c != theTML.Description__c
                            || oldLine.Resource_Name__c != theTML.Resource_Name__c || oldLine.Facility__c != theTML.Facility__c
                            || oldLine.BOL_Manifest__c != theTML.BOL_Manifest__c || oldLine.Fleet_No__c != theTML.Fleet_No__c
                            || oldLine.Fleet_No_Required__c != theTML.Fleet_No_Required__c || oldLine.Non_Billable__c != theTML.Non_Billable__c
                            || (theTML.Category__c == ResourceService.EQUIPMENT_CATEGORY
                            && (oldLine.Job_Start_Time__c != theTML.Job_Start_Time__c || oldLine.Job_End_Time__c != theTML.Job_End_Time__c)))
                    {
                        updatedTMLinesByIds.put(theTML.Id, theTML);
                    }
                }
                //Ticket#23028 <<
            }
            //Ticket#23028 >>
            //System.debug('Info: updatedTMLinesByIds: ' + updatedTMLinesByIds);
            if(updatedTMLinesByIds.size() > 0) {
                TMsService.updateExistingBillingWorksheetLines(updatedTMLinesByIds);
            }
            //Ticket#23028 <<

            if (resourceTypeIdSet.size() > 0) {
                Map<Id, Resource_Type__c> theResourceTypes = new Map<Id, Resource_Type__c>([
                        SELECT Id, Name, Unit_of_Measure__c, Unit_of_Measure1__c, Unit_of_Measure2__c, Unit_of_Measure3__c, Unit_of_Measure4__c, Fuel_Fired_Equipment__c
                        FROM Resource_Type__c
                        WHERE Id IN :resourceTypeIdSet
                ]);
                mapResourceTypes.putAll(theResourceTypes);
            }

            if (resourceIdSet.size() > 0){
                Map<Id, Resource__c> theResources = new Map<Id, Resource__c>([
                        SELECT Id, Name, Unit_of_Measure__c, Unit_of_Measure1__c, Unit_of_Measure2__c, Unit_of_Measure3__c,
                                Unit_of_Measure4__c,Category__c, Service_Center__c,
                                Employee_No__c, Description__c,
                                Service_Center__r.Name, Service_Center__r.Temporary__c
                        FROM Resource__c
                        WHERE Id IN :resourceIdSet
                ]);
                mapResources.putAll(theResources);
            }

            //Need this flag to bypass some trigger codes in order reduce SOQL
            //Only 200 records are processed at one time in trigger
            //We don't need to check these conditions when creating invoices
            if (CompanyMgmt.massCreateInvoice != true) {
                if (mapResources.size() > 0) {
                    for (TM_Line__c theTML : TMLList) {
                        if (String.isNotBlank(theTML.Resource__c)) {
                            if (theTML.Category__c != mapResources.get(theTML.Resource__c).Category__c) {
                                theTML.Category__c.addError('Category of Resource ' + mapResources.get(theTML.Resource__c).Category__c + ' should be same as Category on the TM Line: ' + theTML.Line_No__c);
                            }
                            if ((theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment') && String.isNotBlank(theTML.Resource__c)) {
                                Resource__c res = mapResources.get(theTML.Resource__c);
                                if (theTML.Service_Center__c != res.Service_Center__c && res.Service_Center__r.Temporary__c == false) {
                                    theTML.Service_Center__c = res.Service_Center__c;
                                }
                                if (theTML.Category__c == 'Labor' && String.isNotBlank(res.Employee_No__c)
                                        && res.Description__c != theTML.Resource_Name__c) {
                                    theTML.Resource_Name__c = res.Description__c;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    public static void TMLDelete(List<TM_Line__c> TMLList, Map<Id, TM_Line__c > oldTMMap) {
        System.debug('##Delete Trigger begin### ');
        Set<Id> setTMIds = new Set<Id>();
        Set<Id> setSCIds = new Set<Id>();
        Map<Id, TM__c> theTMMap = new Map<Id, TM__c>();
        Map<Id, Service_Center__c> theSCMap = new Map<Id, Service_Center__c>();

        for (TM_Line__c theTML : TMLList) {
            if (theTML.TM__c != null) setTMIds.add(theTML.TM__c);
            if (String.isNotBlank(theTML.Service_Center__c)) setSCIds.add(theTML.Service_Center__c);

            //TM data check <<
            if (theTML.Invoiced__c == true) {
                theTML.Invoiced__c.addError('You cannot delete invoiced T&M Line.;');
            }
            //TM data check >>
        }

        for (TM__c theTM : [
                SELECT Id, Name, Status__c, Project_Manager_Reviewed__c, Reviewed_By__c, Reviewed_Date__c, Reviewed_At_Status__c
                FROM TM__c
                WHERE Id IN :setTMIds
        ]) {
            theTMMap.put(theTM.Id, theTM);
        }

        for(Service_Center__c sc: [SELECT Id, Temporary__c FROM Service_Center__c WHERE Id IN :setSCIds]){
            theSCMap.put(sc.Id, sc);
        }

        String Status = '';
        Boolean isTemp = false;
        for (TM_Line__c theTML : TMLList) {
            //Ticket#21817 >>
            TM__c tm = theTMMap.get(theTML.TM__c);
            Status = tm.Status__c;
            //Ticket#21817 <<

            if(theSCMap.containsKey(theTML.Service_Center__c)) {
                isTemp = theSCMap.get(theTML.Service_Center__c).Temporary__c;
            }
            if (theTML.Category__c == 'Labor' || theTML.Category__c == 'Equipment') {
                if ((Status != 'Open' && Status != 'Scheduled' && Status != 'Mobile Review' && Status != 'Void') && (isTemp == false)) {
                    theTML.Category__c.addError('You cannot delete Labor & Equipment T&M Line with status: ' + Status + '. Line No: ' + theTML.Line_No__c);
                }
            }
            if (Status == 'Fully Invoiced' || Status == 'Closed') {
                theTML.Category__c.addError('You cannot delete T&M Line with status: ' + Status + '. Line No: ' + theTML.Line_No__c);
            }
            if (theTML.Invoiced__c == true) {
                theTML.Invoiced__c.addError('You cannot delete T&M Line because it is invoiced already for Line No: ' + theTML.Line_No__c);
            }
            //Ticket#21817 >>
            if (tm.Project_Manager_Reviewed__c == true) {
                TMsService.PMReviewSetNullByTMLineUpdated = true;
            }
            //Ticket#21817 <<
        }

        Set<Id> tmLineIds = new Set<Id>();
        for (TM_Line__c tmLine : TMLList) {
            tmLineIds.add(tmLine.Id);
        }

        if (tmLineIds.size() > 0) {
            BillingWorksheetController.ByPassTrigger = true;
            CompanyMgmt.systemCall = true;
            delete [SELECT Id FROM Billing_Worksheet_Line__c WHERE TM_Line__c IN :tmLineIds];
            BillingWorksheetController.ByPassTrigger = false;
        }
        System.debug('##Delete Trigger end### ');
    }

    //Ticket#21817
    public static Boolean isTMHeaderUpdated(TM__c newTM, TM__c oldTM){
        Boolean isChanged = false;
        Set<String> fieldsToCheck = new Set<String>{
                'Sales_Order__c',
                'Bill_to_Customer__c',
                'From_Sales_Quote__c',
                'Contract__c',
                'Contact__c',
                'Scheduled_Date__c',
                'Start_Time__c',
                'Desired_Scheduled_Date__c',
                'Day_of_Job__c',
                'Project_Coordinator__c',
                'Alternate_Site_Address__c',
                'Site_Contact_2__c',
                'Site_Name__c',
                'Site_Phone_No__c',
                'Site_Street__c',
                'Site_Email_Address__c',
                'Site_City__c',
                'Tax_Area__c',
                'Site_State__c',
                'Print_Site_Name__c',
                'Site_Postal_Code__c',
                'Tax_Liable__c',
                'Site_Country__c',
                'Site_Scope__c',
                'Customer_Comments__c',
                'Internal_Comments__c'
        };
        for(String fieldName : fieldsToCheck){
            if(newTM.get(fieldName) != oldTM.get(fieldName)){
                //System.debug('Info: TM Header Field Changed ' + fieldName);
                isChanged = true;
                break;
            }
        }
        return isChanged;
    }

    //Ticket#21817
    private static Boolean isTMLineUpdated(TM_Line__c newTmLine, TM_Line__c oldTmLine){
        Boolean isChanged = false;
        //Can't track Linked_Line__c it auto updates
        Set<String> fieldsToCheck = new Set<String>{
                'Resource_Type__c',
                'Resource__c',
                'Service_Center__c',
                'Resource_Name__c',
                'Description__c',
                'Job_Start_Time__c',
                'Job_End_Time__c',
                'Site_Start_Time__c',
                'Site_End_Time__c',
                'Lunch_Start_Time__c',
                'Lunch_End_Time__c',
                'Quantity__c',
                'Unit_of_Measure__c',
                'Non_Billable__c',
                'Facility__c',
                'BOL_Manifest__c'
        };
        for(String fieldName : fieldsToCheck){
            if(newTmLine.get(fieldName) != oldTmLine.get(fieldName)){
                //System.debug('Info: TM Line Field Changed ' + fieldName + ' new: ' + newTmLine.get(fieldName) + ' old: ' + oldTmLine.get(fieldName));
                isChanged = true;
                break;
            }
        }
        return isChanged;
    }

    private static void logConfirmedDatetimeInfo(TM__c tm){
        String confirmedInfo = 'Confirmed At SystemTime>> ' + System.now() + ' UserLocalTime>> ' + TimeUtils.getCurrentLocalTime() + ' DayName>> ' + TimeUtils.getCurrentDayNameInLocalTime();
        tm.Note__c = confirmedInfo;
    }
    public static void updateSalesOrderFromTMMap(List<TM__c>TMList,Map<Id, TM__c> mapTM ,Map<Id, TM__c>oldMapTM){
        Set<Id> soIds = new Set<Id>();
                for (TM__c tm : mapTM.values()) {
                    if (tm.Status__c == 'Scheduled' && oldMapTM.get(tm.Id).Status__c == 'Open'){
                        soIds.add(tm.Sales_Order__c);
                    }
                }

                if(soIds.size() > 0){
                    Map<Id, Sales_Order__c> SOFromTMMap = new Map<Id, Sales_Order__c>([
                            SELECT Id, Name, Start_Date__c, End_Date__c, (SELECT Id, Scheduled_Date__c FROM Service_Orders__r WHERE Id NOT IN :mapTM.keySet() AND Status__c <> 'Open' AND Status__c <> 'Void')
                            FROM Sales_Order__c
                            WHERE Id IN :soIds
                    ]);

                    if (mapTM.size() > 0 && SOFromTMMap.size() > 0) {
                        for (TM__c theTM : TMList) {
                            Sales_Order__c theSO = SOFromTMMap.get(theTM.Sales_Order__c);
                            List<TM__c> theTMList = theSO.Service_Orders__r;
                            Boolean isScheduling = false;
                            Date tempStartDate = null;
                            Date tempEndDate = null;

                            if (theTM.Status__c == 'Scheduled' && oldMapTM.get(theTM.Id).Status__c == 'Open') isScheduling = true;
                            if (theTMList.isEmpty() && isScheduling == true) {
                                tempStartDate = theTM.Scheduled_Date__c;
                                tempEndDate = theTM.Scheduled_Date__c;
                            }
                            if (theTMList.isEmpty() && isScheduling == false) {
                                tempStartDate = null;
                                tempEndDate = null;
                            }
							System.debug('theTMList========>'+theTMList);
                            for (TM__c tm : theTMList) {
                                if (tempStartDate == null) {
                                    if(isScheduling) {
                                        tempStartDate = theTM.Scheduled_Date__c;
                                    } else {
                                        tempStartDate = tm.Scheduled_Date__c;
                                    }
                                }

                                if (tempEndDate == null) {
                                    if(isScheduling) {
                                        tempEndDate = theTM.Scheduled_Date__c;
                                    } else {
                                        tempEndDate = tm.Scheduled_Date__c;
                                    }
                                }

                                if (tm.Scheduled_Date__c < tempStartDate) {
                                    tempStartDate = tm.Scheduled_Date__c;
                                }
                                if (tm.Scheduled_Date__c > tempEndDate) {
                                    tempEndDate = tm.Scheduled_Date__c;
                                }
                            }

                            theSO.Start_Date__c = tempStartDate;
                            theSO.End_Date__c = tempEndDate;
                            SOFromTMMap.put(theSO.Id, theSO);
                        }
                        update SOFromTMMap.values();
                    }
                }
    }
    
    public static void createBillingWorksheetLinesFromTM(Set<TM__c>confirmedTMs,List<TM__c>TMList){
         try {
                        CompanyMgmt.byPassTrigger = true;
                        //ticket 19916 <<
                        //TMsService.createBillingWorksheetLines(confirmedTMs);
                        if (TMsService.ByPassCreatingBillingWorksheetLines != true) {
                            TMsService.createBillingWorksheetLines(confirmedTMs);
                        }
                        //ticket 19916 >>
                        CompanyMgmt.byPassTrigger = false;
                    } catch (exception ex) {
                        System.debug('Error: ' + ex.getStackTraceString());
                        for (TM__c tm : TMList) {
                            tm.addError(ex.getMessage());
                        }
                    }
    }
    public static void updateSignatures(Set<Id> tmIdsSignature){
        List<Signature__c> signatures = [SELECT Id FROM Signature__c WHERE TM__c IN :tmIdsSignature AND Voided__c <> TRUE];
        //signature request >>
        for (Signature__c signature : signatures) {
            signature.Voided__c = true;
        }
        if (signatures.size() > 0) {
            update signatures;
        }
    }
}