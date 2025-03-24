/*
 *  Ticket#16937 Remove PW_Job_Type_Code__c field.
 */
global class PayrollController {
    public User theUser { get; set; }
    public Service_Center__c theSC { get; set; }
    private String currUser;
    public Payroll__c thePayroll { get; set; }
    public Date weekStartingDate { get; set; }
    public Date weekEndingDate { get; set; }
    public String strYear { get; set; }
    public Boolean payrollCreated { get; set; }
    public  ApexPages.StandardSetController setCon;
    public List<Timesheet__c> openTimesheetList {get; set;}
    public List<Payroll__c> selectedPRList { get; set; }
    public List<Payroll_Line__c> selectedPRLineList { get; set; }
    public List<Payroll_Line__c> exportLineList{get; set;}
    public String errMsg {get;set;}
    public String fileName {get; set;}
    public Map<Id, String> mapResTSReopenReason {get; set;}
    private Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();

    @TestVisible
    Set<String> selectedPRIds;
    public PayrollController(ApexPages.StandardSetController controller) {
        setCon = controller;
        thePayroll = new Payroll__c();
        currUser = UserInfo.getUserId();

        if(CompanyMgmt.getVFPageName() == 'exportpayrollconfirmation' ||
                CompanyMgmt.getVFPageName() == 'ExportWorkdayFileConfirmation' ||
                Test.isRunningTest())
        {

            selectedPRIds = new Set<String>();
            List<Id> selectedPayRuleIds = new List<Id>();
            for(Payroll__c thePR : (Payroll__c[])setCon.getSelected()) {
                selectedPRIds.add(thePR.Id);
                selectedPayRuleIds.add(thePR.Id);
            }
            if(CompanyMgmt.getVFPageName() == 'ExportWorkdayFileConfirmation'){
                selectedPRLineList = queryPayrollFlayPayLinesByPayrollIds(selectedPayRuleIds);
            }
            selectSelectedPayroll();
            validatePayroll();            
        }

        selectUser();
        selectServiceCenter();

        payrollCreated = false;
    }
    
    public PayrollController() {
        if(CompanyMgmt.getVFPageName() == 'ExportPayrollAsCSV') {
            String selectedIds = ApexPages.currentPage().getParameters().get('selectedIds');
            selectedPRIds = new Set<String>();
            if(!String.isEmpty(selectedIds)) {
                List<String> lstIds = selectedIds.split(',');
                selectedPRIds.addAll(lstIds);
                //System.debug('selectedPRIds*** ' + selectedPRIds);
                selectSelectedPayrollLines();
                if(selectedPRLineList.size() > 0){
                    fileName = selectedPRLineList[0].Payroll__r.Service_Center__r.ADP_Payroll_Batch_ID__c + selectedPRLineList[0].Payroll__r.Week_Number__r.Name.remove('/');
                }
            }
        } else if(CompanyMgmt.getVFPageName() == 'ExportWorkdayDataAsCSV'){
            String selectedIds = ApexPages.currentPage().getParameters().get('selectedIds');
            List<Id> selectedPayrollIds = new List<Id>();
            if(String.isNotBlank(selectedIds)){
                selectedPayrollIds.addAll(selectedIds.split(','));
                selectedPRLineList = queryPayrollFlayPayLinesByPayrollIds(selectedPayrollIds);
                Boolean multiplePayrolls = false;
                if(selectedPayrollIds.size() > 1){
                    multiplePayrolls = true;
                }
                fileName = generateFileName(selectedPRLineList, multiplePayrolls);
            }
        } else {
            thePayroll = new Payroll__c();
            currUser = UserInfo.getUserId();
            selectUser();
            selectServiceCenter();
            
            payrollCreated = false;
        }
    }
    
    @TestVisible
    private void selectSelectedPayroll() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Payroll__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }

        selectedPRList = new List<Payroll__c>();
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' ,Service_Center__r.Name, Week_Number__r.Name ';
        strQuery += ' FROM Payroll__c WHERE Id IN : selectedPRIds';

        //System.debug('selectedPRIds*** ' + selectedPRIds);
        //System.debug('strQuery*** ' + strQuery);
        selectedPRList = Database.query(strQuery);
        //System.debug('selectedPRList*** ' + selectedPRList);
    }
    
    @TestVisible
    private void selectSelectedPayrollLines() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Payroll_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }

        selectedPRLineList = new List<Payroll_Line__c>();
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' ,Job_Position__r.Name, Payroll__r.Name, Resource__r.Name, Sales_Order__r.Name, TM__r.Name ';
        strQuery += ' ,T_M_Line__r.Name,Resource__r.First_Name__c, Resource__r.Last_Name__c,' +
                'Resource__r.Employee_No__c,Resource__r.Description__c,Payroll__r.Week_Number__r.Name,' +
                'Payroll__r.Service_Center__r.Payroll_CO_Code__c, Payroll__r.Service_Center__r.ADP_Payroll_Batch_ID__c';
        strQuery += ' FROM Payroll_Line__c WHERE Payroll__c IN : selectedPRIds';

        //System.debug('selectedPRIds*** ' + selectedPRIds);
        //System.debug('strQuery*** ' + strQuery);
        selectedPRLineList = Database.query(strQuery);
        //System.debug('selectedPRLineList*** ' + selectedPRLineList);
        prepareExportPayrollLine();
    }

    @TestVisible
    private void prepareExportPayrollLine(){
        //System.debug('In Payroll Export ' + selectedPRLineList.size());
        Map<String, Payroll_Line__c> mapExportPayroll = new Map<String, Payroll_Line__c>();
        Set<String> EarningCodeSet = new Set<String>{'ADV', 'BP', 'COM', 'DRV', 'MLS', 'PDL', 'SPA'};
        Set<String> HourCodeSet = new Set<String>{'DBT','SHP','UNP','JUR','PTO','HOL','BER','BON','OW','OP','PD','VAC','TRV', 'TVO', 'TVD', 'UTRV'};

        for (Payroll_Line__c prLine: selectedPRLineList){
            //System.debug('Payroll Export ' + prLine.Payroll__r.Service_Center__r.ADP_Payroll_Batch_ID__c + '---' + prLine.Payroll__r.Service_Center__r.Payroll_CO_Code__c);
            //System.debug('Payroll Export ' + prLine.Resource__r.Description__c + '----' + prLine.Resource__r.Employee_No__c);
            String mapKey = prLine.Payroll__c + ':' + prLine.Resource__c + ':' + prLine.Sales_Order__c + ':' + prLine.Pay_Code__c + ':' + prLine.Work_as_Resource_Type__c;
            Payroll_Line__c thePRLine;
            if(!mapExportPayroll.containsKey(mapKey)){
                thePRLine = new Payroll_Line__c();
                thePRLine.Payroll_Export_ADP_Batch_ID__c = prLine.Payroll__r.Service_Center__r.ADP_Payroll_Batch_ID__c;
                thePRLine.Payroll_Export_CO_Code__c = prLine.Payroll__r.Service_Center__r.Payroll_CO_Code__c;
                thePRLine.Sales_Order__c = prLine.Sales_Order__c;
                thePRLine.Pay_Code__c = prLine.Pay_Code__c;
                thePRLine.Pay_Rate__c = prLine.Pay_Rate__c;
                thePRLine.Payroll_Export_Temp_Rate__c = prLine.Pay_Rate__c; //Ticket13732
                //thePRLine.PW_Job_Type_Code__c = prLine.PW_Job_Type_Code__c; //Ticket#16937
                thePRLine.Payroll_Export_File_No__c =  '="' + prLine.Resource__r.Employee_No__c  + '"';
                //System.debug('In Export... ' + thePRLine.Payroll_Export_File_No__c);
                //thePRLine.Payroll_Export_Employee_Name__c = prLine.Resource__r.Description__c;
                thePRLine.Payroll_Export_Employee_Name__c = prLine.Resource__r.Last_Name__c + ', ' + prLine.Resource__r.First_Name__c;
                //System.debug('Name Info===>'+prLine.Sales_Order__r.Name);
                if(!Test.isRunningTest()){
                    if(prLine.Sales_Order__c == null){
                        thePRLine.Payroll_Export_Job_No__c = '="0000000000"';
                    } else{
                        if(prLine.Sales_Order__r.Name.contains('-')){
                            thePRLine.Payroll_Export_Job_No__c = '="' + prLine.Sales_Order__r.Name.substringBefore('-').leftPad(10, '0') + '"';
                        } else {
                            thePRLine.Payroll_Export_Job_No__c = '="' + String.valueOf(prLine.Sales_Order__r.Name).leftPad(10, '0')  + '"';
                        }
                    }
                }
                mapExportPayroll.put(mapKey, thePRLine);
            } else {
                thePRLine = mapExportPayroll.get(mapKey);
            }

            if(prLine.Pay_Code__c == 'REG'){
                thePRLine.Net_Hours__c = CompanyMgmt.zeroIfNull(thePRLine.Net_Hours__c) + CompanyMgmt.zeroIfNull(prLine.Net_Hours__c);
            } else if(prLine.Pay_Code__c == 'O/T'){
                thePRLine.Payroll_Export_OT_Hours__c = CompanyMgmt.zeroIfNull(thePRLine.Payroll_Export_OT_Hours__c) + CompanyMgmt.zeroIfNull(prLine.Net_Hours__c);
            } else {
                if (EarningCodeSet.contains(prLine.Pay_Code__c)){
                    thePRLine.Payroll_Export_Temp_Rate__c = null;
                    thePRLine.Payroll_Export_Earning_Code__c = prLine.Pay_Code__c;
                    thePRLine.Payroll_Export_Earning_Amt__c =CompanyMgmt.zeroIfNull(thePRLine.Payroll_Export_Earning_Amt__c) + CompanyMgmt.zeroIfNull(prLine.Pay_Rate__c);
                } else if (HourCodeSet.contains(prLine.Pay_Code__c)){
                    //System.debug('Payroll Line thePRLine' + thePRLine + '-------' + prLine.Net_Hours__c);
                    thePRLine.Payroll_Export_Hour_Code__c = prLine.Pay_Code__c;
                    thePRLine.Payroll_Export_Hour_Amount__c = CompanyMgmt.zeroIfNull(thePRLine.Payroll_Export_Hour_Amount__c) + CompanyMgmt.zeroIfNull(prLine.Net_Hours__c);
                }
            }
            
            //Ticket#13469 >>
            if(thePRLine.Payroll_Export_Temp_Rate__c == 0) {
                thePRLine.Payroll_Export_Temp_Rate__c = null;
            }
            if(thePRLine.Payroll_Export_Hour_Amount__c == 0) {
                thePRLine.Payroll_Export_Hour_Amount__c = null;
            }
            if(thePRLine.Payroll_Export_Earning_Amt__c == 0) {
                thePRLine.Payroll_Export_Earning_Amt__c = null;
            }
            //Ticket#13469 <<
        }

        if(mapExportPayroll.size() > 0){
            //System.debug('Export Map ' + mapExportPayroll);
            Set<String> mapKeySet = mapExportPayroll.keySet();
            //System.debug('Export Map Keys ' + mapKeySet);
            exportLineList = new List<Payroll_Line__c>();
            for(String mapKey : mapKeySet){
                //System.debug('Export Map Key ' + mapKey + '---' + mapExportPayroll.get(mapKey));
                //System.debug('Export Map Key ' + mapExportPayroll.get(mapKey).Payroll_Export_Employee_Name__c);
                Payroll_Line__c exportLine = mapExportPayroll.get(mapKey);
                exportLine.Net_Hours__c = CompanyMgmt.halfUpTo2D(exportLine.Net_Hours__c);
                exportLine.Payroll_Export_OT_Hours__c = CompanyMgmt.halfUpTo2D(exportLine.Payroll_Export_OT_Hours__c);
                exportLine.Payroll_Export_Hour_Amount__c = CompanyMgmt.halfUpTo2D(exportLine.Payroll_Export_Hour_Amount__c);

                if(exportLine.Payroll_Export_Temp_Rate__c == 0){
                    exportLine.Payroll_Export_Temp_Rate__c = null;
                }
                if(exportLine.Payroll_Export_Hour_Amount__c == 0){
                    exportLine.Payroll_Export_Hour_Amount__c = null;
                }
                if(exportLine.Payroll_Export_Earning_Amt__c == 0){
                    exportLine.Payroll_Export_Earning_Amt__c = null;
                }
                if(exportLine.Net_Hours__c == 0){
                    exportLine.Net_Hours__c = null;
                }
                if(exportLine.Payroll_Export_OT_Hours__c == 0){
                    exportLine.Payroll_Export_OT_Hours__c = null;
                }
                
                //exportLineList.add(mapExportPayroll.get(mapKey));
                exportLineList.add(exportLine);
            }
        }
    }

    private void selectUser() {
        theUser = new User();
        //system.debug('theUser1***' + theUser);
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
        //system.debug('theUser2***' + theUser);
        //system.debug('theUser.Service_Center__c***' + theUser.Service_Center__c);
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
        //system.debug('strQuery***' + strQuery);
        theSC = Database.query(strQuery);
    }

    public PageReference validateWeekNo() {
        thePayroll = PayrollMgmt.validateWeekNo(thePayroll);
        weekStartingDate = thePayroll.Start_Date__c;
        weekEndingDate = thePayroll.End_Date__c;
        strYear = thePayroll.Year__c;
        return null;
    }

    public PageReference CreatePayroll() {
        //System.debug('####CreatePayroll Begin####');
        //System.debug('theSC ' + theSC);
        if (!allowToCreatePayroll){
            thePayroll.addError('Please approve all timesheets before creating payroll!');
            return null;
        }

        List<Payroll__c> thePRList = new List<Payroll__c>();
        List<Timesheet__c> theTSList = new List<Timesheet__c>();
        String theSCId = theUser.Service_Center__c;

        Savepoint sp = Database.setSavepoint();
        try {

            Week_Number__c weekNum = PayrollMgmt.getWeekNumber(thePayroll.Week_Number__c);
            TimesheetMgmt timesheetMgmt = new TimesheetMgmt();
            mapResTSReopenReason = timesheetMgmt.verifyTimesheets(weekNum, theSC.Id);
            openTimesheetList = timesheetMgmt.getOpenTimesheetsByWeekAndServiceCenter(thePayroll.Week_Number__c, theSC.Id);
            openTimesheetList = timesheetMgmt.setTimesheetReopenReasonCode(openTimesheetList, mapResTSReopenReason);

            if (!allowToCreatePayroll){
                thePayroll.addError('Please approve all timesheets before creating payroll!');
                return null;
            }

            //no existing payroll records with status = Approved or exported, or error
            thePRList = [SELECT Id, Name FROM Payroll__c
                            WHERE (Status__c = 'Approved' OR Status__c = 'Exported') AND (Service_Center__c =: theSCId) AND (Week_Number__c =: thePayroll.Week_Number__c)];
            if (thePRList != null && thePRList.size() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Payroll records with status Approved or Exported exists.'));
                return null;
            }

            //all timesheets for the Service Center for the week are Approved, or error.
            theTSList = [
                    SELECT Id, Name
                    FROM Timesheet__c
                    WHERE Status__c = 'Open' AND
                    Week_No__c = :thePayroll.Week_Number__c AND Service_Center__c = :theSCId
            ];

            if (theTSList != null && theTSList.size() > 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'All timesheets for the selected Service Center and week must be Approved.'));
                return null;
            }

            Set<String> tsId = new Set<String>();

            List<Timesheet_Line__c> theTSLineList = new List<Timesheet_Line__c>();
            thePRList = new List<Payroll__c>();
            theTSList = new List<Timesheet__c>();
            Payroll__c thePR;
            Payroll_Line__c thePRL;
            List<Payroll_Line__c> thePRLList;
            Integer PayrollLineCount = 0;

            //system.debug('thePayroll.Week_Number__c***' + thePayroll.Week_Number__c);
            //system.debug('thePayroll.theSCId***' + theSCId);
            theTSList = [SELECT Id, Name, Service_Center__c FROM Timesheet__c
                WHERE Week_No__c = :thePayroll.Week_Number__c
                    AND Status__c = 'Approved'
                    AND Service_Center__r.Name = :theSCId];

            //system.debug('theTSList***' + theTSList);
            if (theTSList != null && theTSList.size() > 0) {
                thePR = new Payroll__c();
                thePR.Start_Date__c = weekStartingDate;
                thePR.End_Date__c = weekEndingDate;
                thePR.Service_Center__c = theTSList[0].Service_Center__c;
                thePR.Week_Number__c = thePayroll.Week_Number__c;
                thePR.Year__c = strYear;
                insert thePR;

                for (Timesheet__c TS : theTSList) {
                    tsId.add(TS.Id);
                }

                //Ticket#16937 remove PW_Job_Type_Code__c
                theTSLineList = [
                        SELECT Id, Name, Customer_Name__c, Net_Hours__c, Sales_Order__c, Sales_Order_Description__c, Time_Type_Code__c,
                                T_M_Line__c, Timesheet__c, TM__c, Timesheet__r.Resource__c, Prevailing_Wage_Job__c, Certified_PW_Job__c,
                                Work_as_Resource_Type__c, Rate__c, Timesheet__r.Resource_Name__c, Time_Type__c
                        FROM Timesheet_Line__c
                        WHERE Timesheet__c IN:tsId
                ];

                thePRLList = new List<Payroll_Line__c>();
                if (theTSLineList != null && theTSLineList.size() > 0) {
                    for (Timesheet_Line__c theTSL : theTSLineList) {
                        thePRL = new Payroll_Line__c();
                        thePRL.Payroll__c = thePR.Id;
                        thePRL.Pay_Code__c = theTSL.Time_Type_Code__c;
                        //thePRL.Time_Code__c = theTSL.Time_Code__c;
                        thePRL.Resource__c = theTSL.Timesheet__r.Resource__c;
                        thePRL.Resource_Name__c = theTSL.Timesheet__r.Resource_Name__c;
                        thePRL.Net_Hours__c = CompanyMgmt.zeroIfNull(theTSL.Net_Hours__c);
                        thePRL.Sales_Order__c = theTSL.Sales_Order__c;
                        thePRL.Sales_Order_Description__c = theTSL.Sales_Order_Description__c;
                        thePRL.Prevailing_Wage_Job__c = theTSL.Prevailing_Wage_Job__c;
                        thePRL.Certified_PW_Job__c = theTSL.Certified_PW_Job__c;
                        //thePRL.PW_Job_Type_Code__c = theTSL.PW_Job_Type_Code__c; //Ticket#16937
                        thePRL.Customer_Name__c = theTSL.Customer_Name__c;
                        thePRL.Timesheet__c = theTSL.Timesheet__c;
                        thePRL.Timesheet_Line__c = theTSL.Id;
                        thePRL.TM__c = theTSL.TM__c;
                        thePRL.T_M_Line__c = theTSL.T_M_Line__c;
                        thePRL.Work_as_Resource_Type__c = theTSL.Work_as_Resource_Type__c;
                        thePRL.Pay_Rate__c = CompanyMgmt.zeroIfNull(theTSL.Rate__c);
                        thePRL.Amount__c = thePRL.Net_Hours__c * thePRL.Pay_Rate__c;
                        if(theTSL.Time_Type__c == 'Travel Time'){
                            if(thePRL.Pay_Code__c == 'REG') {
                                thePRL.Pay_Code__c = theCompanySetup.Travel_Time_Rate__c;
                            } else if(thePRL.Pay_Code__c == 'O/T') {
                                thePRL.Pay_Code__c = 'TVO';
                            } else if(thePRL.Pay_Code__c == 'DBT') {
                                thePRL.Pay_Code__c = 'TVD';
                            }
                        }

                        if(thePRL.Prevailing_Wage_Job__c){
                            if(thePRL.Pay_Code__c == 'REG') {
                                thePRL.Pay_Code__c = 'OW';
                            } else if(thePRL.Pay_Code__c == 'O/T') {
                                thePRL.Pay_Code__c = 'OP';
                            } else if(thePRL.Pay_Code__c == 'DBT') {
                                thePRL.Pay_Code__c = 'PD';
                            }
                        }
                        thePRLList.add(thePRL);
                    }
                }

                if (thePRLList != null && thePRLList.size() > 0) {
                    insert thePRLList;
                    PayrollLineCount = thePRLList.size();
                    for(Timesheet__c ts: theTSList){
                        ts.Payroll__c = thePR.Id;
                        ts.Status__c = 'Payroll Created';
                    }
                    update theTSList;
                }

                payrollCreated = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully created 1 payroll with ' + PayrollLineCount + ' lines.'));
            }
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage() + '---' +
                                                                                    e.getLineNumber() + '---' +
                                                                                    e.getCause() + '---' +
                                                                                    e.getStackTraceString()));
        }

        return null;
    }

    public PageReference returnBack() {
        PageReference pageref = new PageReference('/apex/Administration');
        pageref.setRedirect(true);
        return pageref;
    }
    
    public PageReference returnToPayrollList() {
        return new ApexPages.Action('{!List}').invoke();
    }
    
    @TestVisible
    private Boolean validatePayroll() {
        errMsg = '';
        if (selectedPRList != null && selectedPRList.size() > 0) {
            if(selectedPRList.size() == 1) {
                for (Payroll__c thePR : selectedPRList) {
                    //if(thePR.Status__c != 'Approved') {
                    if(thePR.Status__c == 'Open' || String.isBlank(thePR.Status__c)){
                        errMsg = 'Payroll status must be Approved.';
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
                    }
                }
            } else {
                if(CompanyMgmt.getVFPageName() == 'exportpayrollconfirmation') {
                    errMsg = 'Please select only one Payroll';
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
                }
            }
        } else {
            errMsg = 'Please select a Payroll.';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
        }

        if(selectedPRLineList != null && selectedPRLineList.size() == 0){
            errMsg = 'No flat pay line found!';
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errMsg));
        }

        if (errMsg != '') {
            return false;
        } else {
            return true;
        }
    }

    public Boolean allowToCreatePayroll {
        get {
            return getOpenTimesheet().isEmpty();
        }
    }

    public PageReference listOpenTimesheet(){
        //System.debug('###listOpenTimesheet###Begin');
        //System.debug('theSC ' + theSC.Id + ' --- ');
        try{
            Week_Number__c weekNum = PayrollMgmt.getWeekNumber(thePayroll.Week_Number__c);
            //System.debug('***Week No. ' + weekNum);
            TimesheetMgmt timesheetMgmt = new TimesheetMgmt();
            mapResTSReopenReason = timesheetMgmt.verifyTimesheets(weekNum, theSC.Id);
            openTimesheetList = getOpenTimesheet();
            openTimesheetList = timesheetMgmt.setTimesheetReopenReasonCode(openTimesheetList, mapResTSReopenReason);
        } catch (Exception e){
            //System.debug('***Error ' + e.getStackTraceString());
            thePayroll.addError(e.getStackTraceString() + '--' + e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getStackTraceString() + '--' + e.getMessage()));
        }
        //System.debug('###listOpenTimesheet###End');
        return null;
    }

    private List<Timesheet__c> getOpenTimesheet(){
        selectServiceCenter();
        List<Timesheet__c> lstOpenTimesheet = [SELECT Id, Name, Employee_No__c, Resource__c,
                Resource_Name__c, Total_Hours_Submitted__c, Status_Message__c, Status__c
        FROM Timesheet__c
        WHERE Service_Center__c =: theSC.Id
        AND Week_No__c = :thePayroll.Week_Number__c
        AND Status__c = 'Open'];

        return lstOpenTimesheet;
    }

    public PageReference reopen(){
        if (thePayroll.Status__c == 'Approved'){
            thePayroll.Status__c = 'Open';
            update thePayroll;
        }

        return null;
    }

    public PageReference release(){
        if (thePayroll.Status__c == 'Open'){
            thePayroll.Status__c = 'Approved';
            update thePayroll;
        }

        return null;
    }

    public PageReference ExportToCSV() {
        String selectedIds = '';
        for (Integer i = 0; i < selectedPRList.size(); i++) {
            if (i != 0) selectedIds += ',';
            selectedIds += selectedPRList[i].Id;

            selectedPRList[i].Status__c = 'Exported';
        }
        
        String URL = '/apex/ExportPayrollAsCSV?selectedIds=' + selectedIds;        
        PageReference pageRef = new PageReference(URL);
        pageRef.setRedirect(true);

        if(selectedPRList.size() > 0) update selectedPRList;

        return pageRef;
    }

    public PageReference ExportWorkdayDataToCSV(){
        String selectedIds = '';
        for (Integer i = 0; i < selectedPRList.size(); i++) {
            if (i != 0) selectedIds += ',';
            selectedIds += selectedPRList[i].Id;
            //selectedPRList[i].Status__c = 'Exported';
        }

        String URL = '/apex/ExportWorkdayDataAsCSV?selectedIds=' + selectedIds;
        PageReference pageRef = new PageReference(URL);
        pageRef.setRedirect(true);
        return pageRef;
    }

    private List<Payroll_Line__c> queryPayrollFlayPayLinesByPayrollIds(List<Id> payrollIds){
        List<Payroll_Line__c> payrollLines = [SELECT Id, Resource__r.RSG_EIN__c, Resource__r.Employee_No__c,
                Resource__r.Description__c, Timesheet_Line__r.Scheduled_Date__c, Payroll__r.End_Date__c, Pay_Rate__c,
                Pay_Code__c, Sales_Order__r.Name, Payroll__r.Service_Center__r.Name, Payroll__r.Week_Number__r.Name,
                Payroll__r.Start_Date__c
        FROM Payroll_Line__c WHERE Timesheet_Line__r.Time_Type__c = 'Flat Pay' AND Payroll__c IN :payrollIds];

        return payrollLines;
    }

    private String generateFileName(List<Payroll_Line__c> payrollLines, Boolean multipleServiceCenter){
        String tempFileName = 'WorkdayFileExport';
        String startDate = String.valueOf(payrollLines[0].Payroll__r.Start_Date__c.day()) +
                String.valueOf(payrollLines[0].Payroll__r.Start_Date__c.month()) +
                String.valueOf(payrollLines[0].Payroll__r.Start_Date__c.year());
        String endDate = String.valueOf(payrollLines[0].Payroll__r.End_Date__c.day()) +
                String.valueOf(payrollLines[0].Payroll__r.End_Date__c.month()) +
                String.valueOf(payrollLines[0].Payroll__r.End_Date__c.year());

        if(multipleServiceCenter == false){
            tempFileName = tempFileName + '_SC' + payrollLines[0].Payroll__r.Service_Center__r.Name + '_' + startDate
                    + '_' + endDate;
        } else {
            tempFileName = tempFileName + startDate
                    + '_' + endDate;
        }
        return tempFileName;
    }
}