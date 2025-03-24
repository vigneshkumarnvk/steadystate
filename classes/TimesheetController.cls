/*************************************************************************************************
* Name         :  TimesheetController
* Description  :  Apex Class to handle timesheets
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Andrew Simons             10/30/2024              US130143 - Updated timesheets & timesheet line logic to handle pay rules with different pay periods (Mon-Sun or Sat-Sun)
*************************************************************************************************/

global class TimesheetController {
    private final ApexPages.StandardController theController;
    public User theUser { get; set; }
    public Service_Center__c theSC { get; set; }
    private String currUser;
    public Timesheet__c theTS { get; set; }
    public List<Timesheet_Line__c> theTSLList { get; set; }
    public List<TM__c> theTMNotReadyList{get; set;}
    public List<Resource__c> theResNotReadyList{get; set;}
    private String TSId;
    public Date weekStartingDate { get; set; }
    public Date weekEndingDate { get; set; }
    public Boolean timesheetCreated{get;set;}
    private Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();
    public  ApexPages.StandardSetController setCon;
    public List<Timesheet__c> timesheets{get; set;}
    public Map<Id, String> mapResTSReopenReason {get; set;}

    public TimesheetController(ApexPages.StandardSetController controller) {
        setCon = controller;
        theTS = new Timesheet__c();
        currUser = UserInfo.getUserId();
        selectUser();
        selectServiceCenter();
        timesheetCreated = false;
    }
    
    public TimesheetController(ApexPages.StandardController controller) {
        theController = controller;
        TSId = ApexPages.currentPage().getParameters().get('id');
        
        if (TSId != null) {
            selectTS();
            selectTSLList();
        } else {
            theTS = new Timesheet__c();
            theTSLList = new List<Timesheet_Line__c>();
        }
        
        currUser = UserInfo.getUserId();
        selectUser();
        selectServiceCenter();
        timesheetCreated = false;
    }
    
    private void selectTS() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Timesheet__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Resource__r.Name, Service_Center__r.Name, Week_No__r.Name, Week_No__r.Week_End_Date__c,Week_No__r.Week_Start_Date__c, Resource__r.Pay_Rule__r.Mon_Sun_Work_Week__c,' +
                'Payroll__r.Name ';
        strQuery += ' FROM Timesheet__c WHERE Id =: TSId';
        theTS = Database.query(strQuery);
    }

    /*Ticket# 13409*/
    private void selectTSLList() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Timesheet_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Parent_Line__r.Name, Resource_Off__r.Name, Sales_Order__r.Name, Sales_Order_Service_Center__r.Name ';
        strQuery += ',TM__r.Name, T_M_Line__r.Name, Timesheet__r.Name, Timesheet__r.Resource__c, T_M_Line__r.Category__c ';
        strQuery += ' FROM Timesheet_Line__c WHERE Timesheet__c =: TSId ORDER BY Scheduled_Date__c, Start_Time__c,Sales_Order__c ASC NULLS LAST';
        theTSLList = Database.query(strQuery);
    }

    private void selectUser() {
        theUser = new User();
        System.debug('theUser1***' + theUser);
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.User.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' FROM User WHERE Id =: currUser LIMIT 1';
        theUser = Database.query(strQuery);
    }

    private void selectServiceCenter() {
        theSC = new Service_Center__c();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Service_Center__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        if (theUser.Service_Center__c == null) {
            throw new DataException('You must set up Service Center for User: ' + theUser.Name);
        }
        String theSCId = theUser.Service_Center__c;
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Subsidiary_Company__r.Name';
        strQuery += ' FROM Service_Center__c WHERE Name =: theSCId LIMIT 1';
        theSC = Database.query(strQuery);
    }

    public String title {
        get {
        
            if (TSId == null){
                return 'New Timesheet';
            }
            else{
                return theTS.Name;
            }
               
        }
    }
    
    public Timesheet__c ts {
        get {
            return theTS;
        }
    }
    
    public List<Timesheet_Line__c > tsLList {
        get {
            return theTSLList;
        }
        private set {
            theTSLList = value;
        }
    }
    
    public Company_Setup__c companySetup {
        get {
            return theCompanySetup;
        }
    }
    
    public void msave() {
        // To differentiate from stanadrd edit page
        //CompanyMgmt.systemCall = true;
        Integer i = 0;

        while (i < theTSLList.size()) {
            if (String.isEmpty(theTSLList[i].Time_Type__c )) {
                theTSLList.remove(i);
            } else {
                i++;
            }
        }

        List<Timesheet_Line__c> delTSLList = new List<Timesheet_Line__c>();

        // Delete lines that are not found in the temporary list
        for (Timesheet_Line__c tsLine : [SELECT Id FROM Timesheet_Line__c WHERE Timesheet__c = :TSId]) {
            Boolean lineFound = false;
            for (Timesheet_Line__c tsLine2 : theTSLList) {
                if (tsLine.Id == tsLine2.Id)  lineFound = true;
            }
            if (lineFound == false)  delTSLList.add(tsLine);
        }
        if (!delTSLList.isEmpty()) {
            try {
                delete delTSLList;
            } catch (Exception e) { ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); }
        }

        Timesheet__c oldTS = theTS.clone(true);
        List<Timesheet_Line__c> oldTSLList = new List<Timesheet_Line__c>();
        // Savepoint
        Savepoint sp = Database.setSavepoint();

        //Check Errors
        List<String> errorList = new List<String>();
        errorList = TimesheetMgmt.checkSave(theTS, theTSLList);
        if (errorList.size() > 0) {
        
            for (i = 0; i < errorList.size(); i++) ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
            return;
        } else {
            try {
                //Save TSL first in case upsert theSI has error
                for (Timesheet_Line__c TSL : theTSLList) oldTSLList.add(TSL.clone(true));

                theTS = TimesheetMgmt.nullRelationshipFields(theTS);

                upsert theTS;

                for (Timesheet_Line__c TSL : theTSLList) {

                    if (String.isBlank(TSId)) TSL.Timesheet__c = theTS.Id;

                    //Ticket#13487 SF-01
                    TSL.Sales_Order__r = null;
                    TSL.TM__r = null;
                    TSL.T_M_Line__r = null;
                    //Ticket#13487 SF-01
                }
                upsert theTSLList;
                return;
            } catch (Exception e) {
                System.debug('Error:' + e.getMessage());
                Database.rollback(sp);
                theTS = oldTS;
                theTSLList = oldTSLList;
                return;
            }
        }
    }

    public PageReference save() {
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference TimesheetPage = new PageReference('/' + theTS.Id);
            TimesheetPage.setRedirect(true);
            return TimesheetPage;
        } else{
            return null;
        }
    }

    public PageReference quickSave() {
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference TimesheetPage = new PageReference('/apex/Timesheet?id=' + theTS.Id);
            TimesheetPage.setRedirect(true);
            return TimesheetPage;
        } else {
            return null;
        }
    }

    public PageReference saveNapprove(){
        //Ticket#13769
        try {
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            List<Timesheet_Line__c> tsLineLst = tsMgmt.getTimesheetLines(new Set<Id>{
                    theTS.Id
            });
            if (tsLineLst.size() > 0) {
                tsMgmt.checkTimesheetLineTimeOverlap(tsLineLst);
            }
            theTS.Status__c = 'Approved';
            theTS.Status_Message__c = null;
            msave();
            PageReference TimesheetPage = new PageReference('/' + theTS.Id);
            TimesheetPage.setRedirect(true);
            return TimesheetPage;
        } catch (Exception e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + '---' + e.getStackTraceString()));
            return null;
        }
    }
    
    public PageReference insertLine() {
        Integer tsLineListSize = theTSLList.size();
        Integer LinesToInsert = Integer.valueOf(theCompanySetup.Lines_to_Insert__c);
        Decimal lineNo = 0;

        if (theTSLList != null && theTSLList.size() > 0) {
            if (theTSLList[tsLineListSize - 1].Line_No__c != null) {
                lineNo = theTSLList[tsLineListSize - 1].Line_No__c;
            }
        }

        String objectType = ApexPages.currentPage().getParameters().get('ObjectType');

        if (objectType == 'TimesheetLine') {
            if (LinesToInsert > 0) {
                for (Integer i = 0; i < LinesToInsert; i++) {
                    lineNo = lineNo + 1;
                    theTSLList.add(new Timesheet_Line__c(Timesheet__c = TSId, Line_No__c = lineNo, Sales_Order_Service_Center__c = ts.Service_Center__c, Resource__c = ts.Resource__c ));
                }
            }
        }
        
        return null;
    }
    public PageReference deleteLine() {
        String objectType = ApexPages.currentPage().getParameters().get('objectType');
        String displayId = ApexPages.currentPage().getParameters().get('displayId');
        if (displayId == '') {
            displayId = '0';
        }
        if (objectType == 'TimesheetLine') {
            for (Integer i = 0; i < theTSLList.size(); i++) {

                if (theTSLList[i].Line_No__c == Decimal.valueOf(displayId)) {
                    theTSLList.remove(i);
                    break;
                }
            }
        }
        
        return null;
    }
    
    //Ticket#13487 >> //SF-01
    public PageReference validateField() {
        String fieldName = ApexPages.currentPage().getParameters().get('fieldName');
        Integer i = Integer.valueOf(ApexPages.currentPage().getParameters().get('lineNo'));
        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');
        if (fieldName == 'theResourceOff') {
            // Default Fields
            theTSLList[i].Resource_Off__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theResourceOff');
        } else if (fieldName == 'theParentLine') {
            theTSLList[i].Parent_Line__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theParentLine');
        } else if (fieldName == 'theSalesOrder') {
            if(String.isBlank(newFieldValue)){
                theTSLList[i].Sales_Order__c = null;
            } else {
            theTSLList[i].Sales_Order__c = newFieldValue;
            }
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theSalesOrder');
        } else if (fieldName == 'theSalesOrderSC') {
            theTSLList[i].Sales_Order_Service_Center__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theSalesOrderSC');
        } else if (fieldName == 'theTM') {
            if(String.isBlank(newFieldValue)){
                theTSLList[i].TM__c = null;
            } else {
            theTSLList[i].TM__c = newFieldValue;
            }
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theTM');
        } else if (fieldName == 'theTML') {
            if(String.isBlank(newFieldValue)){
                theTSLList[i].T_M_Line__c = null;
            } else {
            theTSLList[i].T_M_Line__c = newFieldValue;
            }
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theTML');
        } else if (fieldName == 'theCertifiedPWJob') {
            theTSLList[i].Certified_PW_Job__c = Boolean.valueOf(newFieldValue);
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theCertifiedPWJob');
        } else if (fieldName == 'theCustomerName') {
            theTSLList[i].Customer_Name__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theCustomerName');
        } else if (fieldName == 'theJobDescription') {
            theTSLList[i].Job_Description__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theJobDescription');
        } else if (fieldName == 'theLunchHours') {
            theTSLList[i].Lunch_Hours__c = Decimal.valueOf(newFieldValue);
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theLunchHours');
        } else if (fieldName == 'theNetHours') {
            System.debug('newFieldValue***' + newFieldValue);
            theTSLList[i].Net_Hours__c = Decimal.valueOf(newFieldValue);
            System.debug('theTSLList[i].Net_Hours__c***' + theTSLList[i].Net_Hours__c);
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theNetHours');
        } else if (fieldName == 'thePrevailingWageJob') {
            theTSLList[i].Prevailing_Wage_Job__c = Boolean.valueOf(newFieldValue);
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'thePrevailingWageJob');
        } else if (fieldName == 'thePWJobTypeCode') {
            theTSLList[i].PW_Job_Type_Code__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'thePWJobTypeCode');
        } else if (fieldName == 'theSalesOrderDescription') {
            theTSLList[i].Sales_Order_Description__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theSalesOrderDescription');
        } else if (fieldName == 'theSalesOrderType') {
            theTSLList[i].Sales_Order_Type__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theSalesOrderType');
        } else if (fieldName == 'theScheduledDate') {
            if(String.isBlank(newFieldValue)){
                theTSLList[i].Scheduled_Date__c = null;
            } else{
                theTSLList[i].Scheduled_Date__c = Date.parse(newFieldValue);
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theScheduledDate');
            }
        } else if (fieldName == 'theTimeType') {
            theTSLList[i].Time_Type__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theTimeType');
        } else if (fieldName == 'theTotalHours') {
            theTSLList[i].Total_Hours__c = Decimal.valueOf(newFieldValue);
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theTotalHours');
        } else if (fieldName == 'theWeekDay') {
            theTSLList[i].Week_Day__c = newFieldValue;
            theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theWeekDay');
        } else if ((fieldName == 'theLunchStartTime') || (fieldName == 'theLunchEndTime') || (fieldName == 'theStartTime') ||(fieldName == 'theEndTime')) {
            List<String> theTime = new List<String>();
            Integer hrs;
            Integer min;

            try {
                if (String.isEmpty(newFieldValue)) {
                    hrs = 0;
                    min = 0;
                } else {
                    if (newFieldValue.contains(':')) {
                        theTime = newFieldValue.split(':');
                        hrs = Integer.valueOf(theTime[0]);
                        min = Integer.valueOf(theTime[1]);
                    } else {
                        hrs = Integer.valueOf(newFieldValue);
                        min = 0;
                    }
                }

                if (fieldName == 'theLunchStartTime') {
                    theTSLList[i].Lunch_Start_Time__c = Time.newInstance(hrs, min, 0, 0);
                    theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theLunchStartTime');
                }
                if (fieldName == 'theLunchEndTime') {
                    theTSLList[i].Lunch_End_Time__c = Time.newInstance(hrs, min, 0, 0);
                    theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theLunchEndTime');
                }
                if (fieldName == 'theStartTime') {
                    theTSLList[i].Start_Time__c = Time.newInstance(hrs, min, 0, 0);
                    theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theStartTime');
                }
                if (fieldName == 'theEndTime') {
                    theTSLList[i].End_Time__c = Time.newInstance(hrs, min, 0, 0);
                    theTSLList[i] = TimesheetMgmt.updateTSL(theTS, theTSLList[i], 'theEndTime');
                }
            }
            catch (DataException de){
                System.debug('Data Exception!!!!');
                theTSLList[i].Scheduled_Date__c.addError(de.getMessage());
            }
            /*
            catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }*/
        }

        System.debug('Week Day in Controller ' + theTSLList[i].Week_Day__c);
        return null;
    }
    
    public PageReference cancel() {
        return theController.cancel();
    }

    public PageReference release(){
        //Ticket#13769
        try {
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            List<Timesheet_Line__c> tsLineLst = tsMgmt.getTimesheetLines(new Set<Id>{theTS.Id});
            if (tsLineLst.size() > 0) {
                tsMgmt.checkTimesheetLineTimeOverlap(tsLineLst);
            }
            theTS.Status__c = 'Approved';
            theTS.Status_Message__c = null;
            msave();
            PageReference TimesheetPage = new PageReference('/' + theTS.Id);
            TimesheetPage.setRedirect(true);
            return TimesheetPage;
        } catch (Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() + '---' + e.getStackTraceString()));
        return null;
    }
        //Ticket#13769
    }

    public PageReference reopen(){
        if(theTS.Status__c == 'Approved'){
            theTS.Status__c = 'Open';
            update theTS;
        }

        return null;
    }

    public PageReference validateWeekNo() {
        theTS = TimesheetMgmt.validateWeekNo(theTS);
        if (theTS.Mon_Sun_Work_Week__c == true) {
            weekStartingDate = theTS.Starting_Date__c;
            weekEndingDate = theTS.Ending_Date__c;
        } else {
            weekStartingDate = theTS.Starting_Date__c.addDays(-1);
            weekEndingDate = theTS.Ending_Date__c.addDays(-1);
        }
      
        return null;
    }

    public PageReference refreshTimesheet(){
        Savepoint sp = Database.setSavepoint();
        try {
            if(theTS.Payroll__c != null){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payroll# ' + ts.Payroll__r.Name + ' already been created for your service center!'));
                return null;
            }
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            tsMgmt.refreshTimesheet(theTS, theTSLList);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully refreshed the timesheet.'));
            PageReference currentPage = ApexPages.currentPage();
            currentPage.setRedirect(true);
            return currentPage;
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + '---' + e.getStackTraceString()));
            return null;
        }
    }

    public PageReference refreshTimesheets(){
        Savepoint sp = Database.setSavepoint();
        try{
            TimesheetMgmt tsMgmt = new TimesheetMgmt();
            List<Timesheet__c> timeSheets = [SELECT Id, Status__c, Week_No__c, Service_Center__c FROM Timesheet__c WHERE Week_No__c = :theTS.Week_No__c AND Service_Center__c = :tsMgmt.TheSc.Id];
            for(Timesheet__c timesheet : timeSheets){
                if(timesheet.Status__c == 'Payroll Created' || timesheet.Payroll__c != null){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Payroll already been created for the service center please review!'));
                    return null;
                }
            }
            tsMgmt.setServiceCenterByName(theUser.Service_Center__c);
            mapResTSReopenReason = tsMgmt.verifyTimesheets(tsMgmt.getWeekNumber(theTS.Week_No__c), tsMgmt.TheSc.Id);
            timesheets = tsMgmt.getOpenTimesheetsByWeekAndServiceCenter(theTS.Week_No__c, tsMgmt.TheSc.Id);
            timesheets = tsMgmt.setTimesheetReopenReasonCode(timesheets, mapResTSReopenReason);
        } catch (Exception e){
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + '---' + e.getStackTraceString()));
        }
        return null;
    }

    public PageReference listTMNotReadyForTimesheet(){
        selectServiceCenter();
        theTMNotReadyList = [SELECT Id, Name, Sales_Order__c, Scheduled_Date__c, Status__c FROM TM__c
            WHERE Status__c IN ('Open', 'Scheduled', 'Mobile Review')
                    AND Scheduled_Date__c >= :weekStartingDate.addDays(-1)
                    AND Scheduled_Date__c <= :weekEndingDate
                    AND Service_Center__c = :theSC.Id];
        return null;
    }

    public PageReference listLaborResNotReadyForTimesheet(){
        selectServiceCenter();
        theResNotReadyList = [
                SELECT Id, Name, Description__c FROM Resource__c
                WHERE Status__c = 'Active'
                AND Category__c = 'Labor'
                AND Service_Center__c = :theSC.Id
                AND Employee_No__c = NULL
                AND Non_Payroll_Labor_Resource__c = FALSE];

        System.debug('TM Not Ready Count ' + theResNotReadyList.size() + '----' + theResNotReadyList);
        return null;
    }


    public PageReference createTimesheet(){
        List<Resource__c> theResourceList = new List<Resource__c>();
        List<TM_Line__c> theTMLineList;
        Set<Id> resIdSet = new Set<Id>();
        String theSCId = theUser.Service_Center__c;
        Map<Id, Timesheet__c> mapTS = new Map<Id, Timesheet__c>();
        List<Timesheet__c> theTSList;
        Integer TimesheetCount = 0;
        Integer emptyTimesheetCount = 0;
        Integer totalTimesheetCreated = 0;
        List<Timesheet__c> theTSListDel = new List<Timesheet__c>();

        Savepoint sp = Database.setSavepoint();
        TimesheetMgmt tsMgt = new TimesheetMgmt();
        tsMgt.setServiceCenterByName(theSCId);
        if (!String.isEmpty(theTS.Resource__c)) {
            theResourceList = ResourcesSelector.newInstance().selectPayrollEmployeeByIdsByActivityDate(new Set<Id>{theTS.Resource__c}, theTS.Starting_Date__c);
            theTSListDel = [SELECT Id, Name, Status__c, Week_No__c, Week_No__r.Name FROM Timesheet__c
                            WHERE Resource__c =: theTS.Resource__c AND Week_No__c =: theTS.Week_No__c];
        } else {
            theResourceList = ResourcesSelector.newInstance().selectPayrollEmployeeBySCIdByActivityDate(tsMgt.TheSc.Id, theTS.Starting_Date__c);
            theTSListDel = [SELECT Id, Name, Status__c, Week_No__c, Week_No__r.Name FROM Timesheet__c
                            WHERE Week_No__c =: theTS.Week_No__c AND Service_Center__r.Name = :theSCId];
        }
        
        tsMgt.setResMap(theResourceList);
        
        if(theTSListDel != null && theTSListDel.size() > 0) {
            for(Timesheet__c TS : theTSListDel) {
                if(TS.Status__c == 'Approved') {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Approved Timesheets exist for the Week No:' + TS.Week_No__r.Name));
                    if(!Test.isRunningTest()) return null;
                }
            }
        }
        
        Set<Id> payRuleIdSet = new Set<Id>();
        if (weekStartingDate != null && weekEndingDate != null || Test.isRunningTest()) {
            if (theResourceList != null && theResourceList.size() > 0) {
                for (Resource__c theResource : theResourceList) {

                    if(String.isNotBlank(theResource.Pay_Rule__c)){
                        payRuleIdSet.add(theResource.Pay_Rule__c);
                    }
                    if (!resIdSet.contains(theResource.Id)) {
                        resIdSet.add(theResource.Id);
                    }
                }
            }

            Set<Id> tmIdSet = new Set<Id>();
            theTSList = new List<Timesheet__c>();
            try {
                //get week number record
                Week_Number__c wkNumber = tsMgt.getWeekNumber(theTS.Week_No__c);
                //create timesheet for all resources
                theTSList = tsMgt.createTimesheets(theResourceList, wkNumber);

                //delete exiting open timesheet
                if(theTSListDel != null && theTSListDel.size() > 0){
                    delete theTSListDel;
                }

                if (theTSList != null && theTSList.size() > 0) {

                    insert theTSList;

                    TimesheetCount = theTSList.size();

                    for (Timesheet__c TS1 : theTSList){
                        mapTS.put(TS1.Resource__c, TS1);
                    }
                    tsMgt.setPayRuleMap(payRuleIdSet);
                    //tsMgt.setPayRuleHolidayMap(payRuleIdSet);
                    tsMgt.setPayRateByPayRuleAndResTypeMap(payRuleIdSet);
                    theTMLineList = tsMgt.getTMLineList(weekStartingDate, weekEndingDate, resIdSet);
                    //Ticket#23136 >>
                    tsMgt.setTMLineByIdsMap(theTMLineList);
                    //Ticket#23136 <<
                    tmIdSet = tsMgt.getTMIds(theTMLineList);

                    theTSLList = new List<Timesheet_Line__c>();
                    tsMgt.setResourceHolidayTaken(resIdSet, weekStartingDate, weekEndingDate);
                    tsMgt.createTSLinesFromTMLines(mapTS,theTSLList,theTMLineList,weekStartingDate, weekEndingDate);
                    tsMgt.processOvernightTravelTime(theTSLList, theTS.Ending_Date__c); //Ticket#24029
                    /*
                    for(Timesheet_Line__c timesheetLine : theTSLList){
                        if(timesheetLine.Resource__c == 'a0rf4000001ZSL3AAO') {
                            System.debug('Info: timesheetLine ' + timesheetLine);
                            System.debug('Info: ' + timesheetLine.Time_Type__c + ' - ' + timesheetLine.Time_Type_Code__c + ' - ' + timesheetLine.Scheduled_Date__c + ' - ' + timesheetLine.Week_Day__c + ' - ' + timesheetLine.Start_Time__c + ' - ' + timesheetLine.End_Time__c);
                        }
                    }
                     */
                    tsMgt.assignHolidays(mapTS, theTSLList, weekStartingDate, weekEndingDate);
                    tsMgt.assignPayruleHolidays(mapTS, theTSLList, weekStartingDate, weekEndingDate);
                    tsMgt.createTSLinesFromResOffTable(mapTS,theTSLList,weekStartingDate, weekEndingDate);
                    /*
                    for(Timesheet_Line__c timesheetLine : theTSLList){
                        if(timesheetLine.Resource__c == 'a0rf4000001ZSL3AAO') {
                            System.debug('Info: timesheetLine2 ' + timesheetLine);
                            System.debug('Info: ' + timesheetLine.Time_Type__c + ' - ' + timesheetLine.Time_Type_Code__c + ' - ' + timesheetLine.Scheduled_Date__c + ' - ' + timesheetLine.Week_Day__c + ' - ' + timesheetLine.Start_Time__c + ' - ' + timesheetLine.End_Time__c);
                        }
                    }
                     */
                    tsMgt.assignHolidayPayCode(theTSLList);
                    tsMgt.processTimesheetLineWithPayRule(theTSLList);
                    //tsMgt.processTimesheetWithPayRuleLineDetails(theTSLList); //Ticket#22944
                    tsMgt.processTimesheetWithPayRuleLineDetails2(theTSLList); //Ticket#23239
                    /*
                    for(Timesheet_Line__c timesheetLine : theTSLList){
                        if(timesheetLine.Resource__c == 'a0rf4000001ZSL3AAO') {
                            System.debug('Info: timesheetLine3 ' + timesheetLine);
                            System.debug('Info: ' + timesheetLine.Time_Type__c + ' - ' + timesheetLine.Time_Type_Code__c + ' - ' + timesheetLine.Scheduled_Date__c + ' - ' + timesheetLine.Week_Day__c + ' - ' + timesheetLine.Start_Time__c + ' - ' + timesheetLine.End_Time__c);
                        }
                    }
                     */
                    tsMgt.finalizeTimesheet(theTSLList);
                    /*
                    for(Timesheet_Line__c timesheetLine : theTSLList){
                        if(timesheetLine.Resource__c == 'a0rf4000001ZSL3AAO') {
                            System.debug('Info: timesheetLine4 ' + timesheetLine);
                            System.debug('Info: ' + timesheetLine.Time_Type__c + ' - ' + timesheetLine.Time_Type_Code__c + ' - ' + timesheetLine.Scheduled_Date__c + ' - ' + timesheetLine.Week_Day__c + ' - ' + timesheetLine.Start_Time__c + ' - ' + timesheetLine.End_Time__c);
                        }
                    }
                     */
                    tsMgt.checkTimesheetLineTimeOverlap(theTSLList);
                    tsMgt.assignPayRate(theTSLList);
                    tsMgt.createFlatPayLines(mapTS, theTSLList, tmIdSet);
                    insert theTSLList;
                    Set<String> timesheetIds = new Set<String>();
                    List<Timesheet__c> emptyTimesheets = new List<Timesheet__c>();
                    for(Timesheet_Line__c timesheetLine : theTSLList){
                        if(!timesheetIds.contains(timesheetLine.Timesheet__c)) timesheetIds.add(timesheetLine.Timesheet__c);
                    }
                    for(Timesheet__c ts1: theTSList){
                        if(!timesheetIds.contains(ts1.Id)) emptyTimesheets.add(ts1);
                    }

                    if(emptyTimesheets.size() > 0){
                        emptyTimesheetCount = emptyTimesheets.size();
                        delete emptyTimesheets;
                    }

                    totalTimesheetCreated = TimesheetCount - emptyTimesheetCount;
                }

                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully created ' +  totalTimesheetCreated + ' timesheets out of ' + TimesheetCount + ' employees.'));
                       
            } catch (Exception e) {
                Database.rollback(sp);
                System.debug('Error: ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
        return null;
    }

    public PageReference returnBack() {
        PageReference pageref = new PageReference('/apex/Administration');
        pageref.setRedirect(true);
        return pageref;
    }
    
    public PageReference returnToTimesheetList() {
        return new ApexPages.Action('{!List}').invoke();
    }
}