public with sharing class TMProcessTMsController {
    public List<TM__c> theTMList { get; set; }
    public List<TM_Line__c> theTMLList;

    private String currUser;
    public User theUser { get; set; }
    public Service_Center__c theSC { get; set; }

    public String filterInput { get; set; }
    public String selFilterField { get; set; }
    public String selFilterOp { get; set; }
    public String filterInput2 { get; set; }
    public String selFilterField2 { get; set; }
    public String selFilterOp2 { get; set; }

    public List<TMPerStatusWrapper> theTMListPerStatus { get; set; }

    public ProcessTMPerStatusWrapperPagination PaginationByStatus;
    public String orderBy;
    public String orderBy_old;
    public String order;
    public Integer PageSize { get; set; }
    public String selectedTMsIds { get; set; }

    public String stringScheduleDateFilter { get; set; }
    Set<Id> selectedIds = new Set<Id>();

    public static String changeStatusTo {
        get;
        set {
            changeStatusTo = value;
            System.debug('value: ' + value);
        }
    }

    public TMProcessTMsController() {
        theTMLList = new List<TM_Line__c>();
        selFilterField2 = 'Status__c';
        selFilterOp2 = '=';
        filterInput2 = '';
        stringScheduleDateFilter = '';
        currUser = UserInfo.getUserId();
        String flterByStatus = ApexPages.currentPage().getParameters().get('flterByStatus');

        if (flterByStatus != null) filterInput2 = flterByStatus;

        selectUser();
        selectServiceCenter();
        search();
    }

    private void selectUser() {
        theUser = new User();
        List<User> users = UsersSelector.newInstance().selectById(new Set<Id>{currUser});
        if(users.size() > 0){
            theUser = users[0];
        }
    }

    private void selectServiceCenter() {
        theSC = new Service_Center__c();

        if (theUser.Service_Center__c == null) throw new DataException('You must set up Service Center for User: ' + theUser.Name);

        String theSCId = theUser.Service_Center__c;

        List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectByName(theSCId);
        if(serviceCenters.size() > 0){
            theSC = serviceCenters[0];
        }
    }

    public void searchTM() {
        filterInput = '';
        search();
    }

    public void search() {
        PageSize = Integer.valueOf(System.Label.Process_TM_PageSize);
        try {
            if (String.isEmpty(theUser.Service_Center__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Service center not assigned to user.'));
            } else {
                String filterQuery = '';
                String scName = theUser.Service_Center__c;
                String dateRangeFilter = System.Label.Process_TM_CutOff_Days;
    
                if (scName == '04' || scName == '96' || scName == '31') {
                    dateRangeFilter = 'LAST_N_DAYS:155';
                }
    
                String strQuery = 'SELECT Id, Name, Scheduled_Date__c, Site_Name__c, Site_City__c, Site_State__c, ' +
                                  'Bill_to_Customer__c, Sales_Order__c, Status__c, ' +
                                  'Desired_Scheduled_Date__c, Emergency_TM__c, Project_Manager_Reviewed__c';
                strQuery += ' FROM TM__c WHERE (Service_Center__r.Name =: scName OR Service_Center__r.Name = null) ';
    
                // Default filter: Show only 'Open' records initially
                if (String.isEmpty(filterInput2)) {
                    strQuery += ' AND Status__c = \'Open\'';
                } else {
                    // Apply different conditions based on the selected status 
                    if (filterInput2 == 'Fully Invoiced') { 
                        strQuery += ' AND (Status__c = \'Fully Invoiced\' AND Scheduled_Date__c = ' + dateRangeFilter + ')';
                    } else if (filterInput2 == 'Void') { 
                        strQuery += ' AND (Status__c = \'Void\' AND (Scheduled_Date__c = LAST_N_MONTHS:1 OR Scheduled_Date__c = NULL))'; 
                    } else { 
                        strQuery += ' AND Status__c = :filterInput2'; 
                    }
                }
    
                if (String.isNotBlank(selFilterField) && String.isNotBlank(filterInput)) {
                    if (selFilterOp == 'contains') {
                        strQuery += ' AND ' + selFilterField + ' LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\'';
                    } else if (selFilterOp == 'not contains') {
                        strQuery += ' AND (NOT ' + selFilterField + ' LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\')';
                    }
                }
    
                if (!String.isEmpty(orderBy)) {
                    if (orderBy == 'Bill_To_Customer__c') {
                        orderBy = 'Bill_To_Customer__r.Name';
                    } else if (orderBy == 'Service_Center__c') {
                        orderBy = 'Service_Center__r.Name';
                    } else if (orderBy == 'Sales_Order__c') {
                        orderBy = 'Sales_Order__r.Name';
                    }
                    strQuery += ' ORDER BY ' + orderBy + ' ' + order + ' NULLS LAST';
                } else {
                    strQuery += ' ORDER BY NAME';
                }
    
                List<TM__c> lstTM = Database.query(strQuery);
                TMPerStatusWrapper theTMWrap;
                theTMListPerStatus = new List<TMPerStatusWrapper>();
    
                for (TM__c theTM : lstTM) {
                    theTMWrap = new TMPerStatusWrapper(false, theTM);
                    theTMListPerStatus.add(theTMWrap);
                }
    
                PaginationByStatus = new ProcessTMPerStatusWrapperPagination(theTMListPerStatus, PageSize);
                theTMListPerStatus = PaginationByStatus.beginning();
            }
        } catch (Exception e) {
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }

    public List<SelectOption> lstFilterOperator {
        get {
            if (lstFilterOperator == null) {
                lstFilterOperator = new List<SelectOption>();
                lstFilterOperator.add(new SelectOption('contains', 'contains'));
                lstFilterOperator.add(new SelectOption('not contains', 'not contains'));
            }
            return lstFilterOperator;
        }
        set;
    }

    public List<SelectOption> lstFilterField {
        get {
            if (lstFilterField == null) {
                lstFilterField = new List<SelectOption>();
                lstFilterField.add(new SelectOption('Name', 'TM No.'));
                lstFilterField.add(new SelectOption('Bill_To_Customer__r.Name', 'Customer.'));
                lstFilterField.add(new SelectOption('Sales_Order__r.Name', 'Sales Order No.'));
            }
            return lstFilterField;
        }
        set;
    }

    public PageReference setStatus() {
        String changeStatus = changeStatusTo;

        List<TM__c> lstTM = new List<TM__c>();
        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {
            if (theTMWrap.isSelected) {
                theTMWrap.theTM.Status__c = changeStatus;
                theTMWrap.theTM.Ready_to_Close__c = false;
                lstTM.add(theTMWrap.theTM);
            }
        }

        Savepoint sp = Database.setSavepoint();
        try {
            if (lstTM != null && lstTM.size() > 0 && changeStatus == 'Confirmed' || Test.isRunningTest()) {
                createRO(lstTM);
            }
            update lstTM;
            search();
        } catch (Exception e) {
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }

        return null;
    }

    public PageReference setStatusToVoid() {
        List<TM__c> lstTM = new List<TM__c>();
        List<TM_Line__c> lstTMLines = new List<TM_Line__c>();
        Set<String> tmIds = new Set<String>();

        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {
            if (theTMWrap.isSelected) {
                theTMWrap.theTM.Status__c = 'Void';
                theTMWrap.theTM.Ready_to_Close__c = false;
                lstTM.add(theTMWrap.theTM);
                tmIds.add(theTMWrap.theTM.Id);
            }
        }

        lstTMLines = [
                SELECT Id, TM__c, Job_Start_Time__c, Job_End_Time__c, Site_Start_Time__c,
                        Site_End_Time__c
                FROM TM_Line__c
                WHERE TM__c = :tmIds AND (Category__c = 'Labor' OR Category__c = 'Equipment')
        ];
        for (TM_Line__c tmLine : lstTMLines) {
            tmLine.Job_Start_Time__c = null;
            tmLine.Job_End_Time__c = null;
            tmLine.Site_Start_Time__c = null;
            tmLine.Site_End_Time__c = null;
        }

        try {
            update lstTMLines;
            update lstTM;
            search();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }

        return null;
    }

    public List<String> lstFields {
        get {

            lstFields = new List<String>();
            lstFields.add('Name');
            lstFields.add('Bill_To_Customer__c');
            if (filterInput2 == 'Open') {
                lstFields.add('Desired_Scheduled_Date__c');
                lstFields.add('Emergency_TM__c');
            }
            //job task <<
            if (filterInput2 == 'Confirmed') {
                lstFields.add('Sales_Order__c');
            }
            //job task >>
            lstFields.add('Scheduled_Date__c');
            lstFields.add('Sales_Order__c');
            //lstFields.add('Site_Name__c');
            lstFields.add('Site_City__c');
            lstFields.add('Site_State__c');
            lstFields.add('Project_Manager_Reviewed__c');
            //lstFields.add('Site_Country__c');
            //lstFields.add('Total_Lines__c');
            //lstFields.add('Total_Amount__c');
            //lstFields.add('Service_Center__c');
            //lstFields.add('Subsidiary_Company__c');
            //lstFields.add('Status__c');
            //lstFields.add('CreatedDate');
            //lstFields.add('CreatedById');

            return lstFields;
        }
        private set;
    }
    public void setOrderBy() {
        if (order == 'ASC') {
            order = 'DESC';
        } else {
            order = 'ASC';
        }
        orderBy = ApexPages.currentPage().getParameters().get('orderBy');
        if (String.isBlank(orderBy)) {
            orderBy = 'Name';
            order = 'ASC';
        }
        if (orderBy != orderBy_old) {
            order = 'ASC';
            orderBy_old = orderBy;
        }
        search();
    }

    public class TMPerStatusWrapper {
        public Boolean isSelected {
            get;
            set;
        }
        public TM__c theTM {
            get;
            set;
        }

        public TMPerStatusWrapper(Boolean isSelected, TM__c theTM) {
            this.isSelected = isSelected;
            this.theTM = theTM;
        }
    }

    /*
     *  Ticket#16967 - Default Site Scope to "Emergency Response"
     *  Ticket#22270 - Allow user to create ER T&M upto maximum allowance set by the Service Center.
     */
    public PageReference AddEmergencyTMs() {
        Integer maxEmergencyTM;

        if (theSC.Name != theUser.Service_Center__c) {
            selectServiceCenter();
        }

        if(theSC.Blocked__c == true){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                    'Service center ' + theSC.Name + ' is deactivated!'));
            return null;
        }

        if (theSC.Max_No_of_Emergency_T_M__c != null) {
            maxEmergencyTM = Integer.valueOf(theSC.Max_No_of_Emergency_T_M__c);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must define Max No. of Emergency TM on Service Center. ' + theSC.Name));
            return null;
        }

        List<TM__c> theTMEmergencyList = new List<TM__c>();
        theTMEmergencyList = [SELECT Id, Name FROM TM__c
            WHERE Emergency_TM__c = TRUE AND Service_Center__c = :theSC.Id AND Sales_Order__c = :null AND Status__c != 'Void' ORDER BY Name
        ];

        /*
        String openERTMStr = '';
        for (TM__c erTM : theTMEmergencyList) {
            openERTMStr += erTM.Name + '<br />';
        }
         */

        //if (theTMEmergencyList != null && theTMEmergencyList.size() > 0) {
        Integer openERTMCount = theTMEmergencyList.size();
        if (openERTMCount >= maxEmergencyTM) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must use existing Emergency T&Ms first, you have ' + theTMEmergencyList.size() +
            'ER T&M open.'));
            return null;
        }

        //job task <<
        /*
        List<TM__c> theTMList = new List<TM__c>();
        TM__c theTM;

        for (Integer i = 0; i < maxEmergencyTM; i++) {
            theTM = new TM__c();
            theTM.Service_Center__c = theSC.Id;
            theTM.Subsidiary_Company__c = theSC.Subsidiary_Company__c;
            theTM.Status__c = 'Open';
            theTM.Emergency_TM__c = true;
            theTM.Site_Scope__c = 'Emergency Response';
            theTMList.add(theTM);
        }

        if (theTMList != null && theTMList.size() > 0) {
            try {
                insert theTMList;
                search();
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
        */
        try {
            List<TM__c> tms = new List<TM__c>();
            while (openERTMCount < maxEmergencyTM) {
                TM__c tm = new TM__c();
                tm.Service_Center__c = theSC.Id;
                tm.Subsidiary_Company__c = theSC.Subsidiary_Company__c;
                tm.Status__c = 'Open';
                tm.Emergency_TM__c = true;
                tm.Site_Scope__c = 'Emergency Response';
                tms.add(tm);
                openERTMCount += 1;
            }

            /*
            for (Integer i = 0; i < maxEmergencyTM; i++) {
                TM__c tm = new TM__c();
                tm.Service_Center__c = theSC.Id;
                tm.Subsidiary_Company__c = theSC.Subsidiary_Company__c;
                tm.Status__c = 'Open';
                tm.Emergency_TM__c = true;
                tm.Site_Scope__c = 'Emergency Response';
                tms.add(tm);
            }
             */
            insert tms;

            List<TM_Job_Task__c> jobTasks = new List<TM_Job_Task__c>();
            for (TM__c tm : tms) {
                TM_Job_Task__c jobTask = new TM_Job_Task__c();
                jobTask.TM__c = tm.Id;
                jobTask.Line_No__c = 1;
                jobTask.Name = 'Emergency T&M';
                jobTasks.add(jobTask);
            }
            insert jobTasks;
        }
        catch(Exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        //job task >>
        return null;
    }

    /*
     *  Ticket#16967 Skip Bill-to check for ER T&M
     */
    public PageReference ScheduleTMs() {
        String selectedTMId = '';
        for (Integer i = 0; i < theTMListPerStatus.size(); i++) {
            if (theTMListPerStatus[i].isSelected) {
                if (String.isEmpty(theTMListPerStatus[i].theTM.Bill_To_Customer__c) && theTMListPerStatus[i].theTM.Emergency_TM__c != true) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Bill-to Customer cannot be blank for the selected T&Ms.'));
                    return null;
                }

                if (String.isEmpty(theTMListPerStatus[i].theTM.Sales_Order__c)) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Sales Order cannot not be blank for the selected T&Ms.'));
                    return null;
                }

                if (i != 0) {
                    selectedTMId += ',';
                }

                selectedTMId += theTMListPerStatus[i].theTM.Id;
            }
        }

        if (String.isEmpty(selectedTMId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please select a T&M.'));
            return null;
        }
        PageReference ScheduleTMConfirmation = new PageReference('/apex/AddScheduleTMConfirmation?selectedTMId=' + selectedTMId);
        ScheduleTMConfirmation.setRedirect(true);
        return ScheduleTMConfirmation;
    }

    public PageReference manualCloseTM() {
        String selectedTMId = '';
        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {
            if (theTMWrap.isSelected == true) {
                selectedTMId = selectedTMId + theTMWrap.theTM.Id + ',';
            }
        }

        if (String.isNotBlank(selectedTMId) == true) {
            selectedTMId = selectedTMId.removeEnd(',');
        }

        if (String.isBlank(selectedTMId) && !Test.isRunningTest()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please select a T&M'));
            return null;
        }

        PageReference closeTMConfirmation = new PageReference('/apex/AddScheduleTMConfirmation?selectedTMId=' + selectedTMId);
        closeTMConfirmation.setRedirect(true);
        closeTMConfirmation.getParameters().put('setStatus', 'Closed');
        return closeTMConfirmation;
    }

    /*
        Ticket#13461
     */
    public PageReference reopenTM() {
        String selectedTMId = '';
        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {
            if (theTMWrap.isSelected == true) {
                if (theTMWrap.theTM.Ready_to_Close__c == true) {
                    if (theTMWrap.theTM.Status__c == 'Closed') {
                        selectedTMId = selectedTMId + theTMWrap.theTM.Id + ',';
                    }
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You can only reopen T&Ms that were manually closed!'));
                    return null;
                }
            }
        }

        if (String.isNotBlank(selectedTMId) == true) {
            selectedTMId = selectedTMId.removeEnd(',');
        }

        if (String.isBlank(selectedTMId) && !Test.isRunningTest()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please select a T&M'));
            return null;
        }

        PageReference reopenTMConfirmation = new PageReference('/apex/AddScheduleTMConfirmation?selectedTMId=' + selectedTMId);
        reopenTMConfirmation.setRedirect(true);
        reopenTMConfirmation.getParameters().put('setStatus', 'Ready to Bill');
        return reopenTMConfirmation;
    }

    /*
        No need can be removed.
     */
    public PageReference CheckReadyToClose() {
        List<TM__c> lstTM = new List<TM__c>();
        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {

            if (theTMWrap.isSelected) {
                theTMWrap.theTM.Ready_to_Close__c = true; lstTM.add(theTMWrap.theTM);
            }
        }

        System.debug('########## just before updating ready to close' + lstTM);
        try {
            update lstTM;
            search();
        } catch (Exception e) {
            System.debug('#### List of TM not updated due to-->' + e);
        }
        return null;
    }

    public PageReference RemoveFromClose() {
        List<TM__c> lstTM = new List<TM__c>();
        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {

            if (theTMWrap.isSelected) {
                theTMWrap.theTM.Ready_to_Close__c = false; lstTM.add(theTMWrap.theTM);
            }
        }

        System.debug('########## just before updating remove from close' + lstTM);
        try {
            update lstTM;
            search();
        } catch (Exception e) {
            System.debug('#### List of TM not updated due to-->' + e);
        }
        return null;
    }

    public PageReference GoToReadyToBillPDF() {
        selectedTMsIds = '';
        Integer i = 0;
        for(TMPerStatusWrapper tmPerStatusWrapper : theTMListPerStatus){
            if(tmPerStatusWrapper.isSelected){
                if (i > 0) selectedTMsIds += ',';
                selectedTMsIds += tmPerStatusWrapper.theTM.Id;
                i++;
            }
        }

        if (String.isEmpty(selectedTMsIds)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Please select at least one T&M.'));
            return null;
        }
        return null;
    }

    public pagereference returnToOpenTMs() {
        PageReference redirectPage = new PageReference('/apex/ProcessTM?flterByStatus=Open');
        redirectPage.setRedirect(true);
        return redirectPage;
    }

    public pagereference ReloadByStatus() {
        PageReference redirectPage = new PageReference('/apex/ProcessTM?flterByStatus=Ready to Bill');
        redirectPage.setRedirect(true);
        return redirectPage;
    }

    public PageReference GoToFieldTMMultiplePDF() {
        selectedTMsIds = '';
        Boolean tmSelected = false;
        for (Integer i = 0; i < theTMListPerStatus.size(); i++) {
            if (theTMListPerStatus[i].isSelected) {
                if (theTMListPerStatus[i].theTM.Emergency_TM__c == true || theTMListPerStatus[i].theTM.Status__c != 'Open') {
                    selectedTMsIds = selectedTMsIds + theTMListPerStatus[i].theTM.Id + ',';
                } else {
                    tmSelected = true;
                }
            }
        }

        if (string.isEmpty(selectedTMsIds)) {
            if (tmSelected == true) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error – Please select an ER T&M(s)'));
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select atleast one T&M.'));
            }
            return null;
        } else {
            selectedTMsIds = selectedTMsIds.removeEnd(',');
        }
        return null;
    }


/////////////////////////////////////CUSTOM PAGINATION////////////////////////////////////////////////
// returns the page number of the current page set
    public Integer pageNumberStatusWrap {
        get {
            return PaginationByStatus.pageNumber();
        }
        set;
    }

// indicates whether there are more records after the current page set.
    public Boolean hasNextpageStatusWrap {
        get {
            return PaginationByStatus.getDisableNext();
        }
        set;
    }

// indicates whether there are more records before the current page set.
    public Boolean hasPreviouspageStatusWrap {
        get {
            return PaginationByStatus.getDisablePrevious();
        }
        set;
    }

// get the start Index.
    public Integer getStartIndexStatusWrap {
        get {
            return PaginationByStatus.currStartIndex;
        }
        set;
    }

// get the End Index.
    public Integer getEndIndexStatusWrap {
        get {
            return PaginationByStatus.currEndIndex;
        }
        set;
    }

// returns the page number of the current page set
    public Integer getTotalRecordsStatusWrap {
        get {
            return PaginationByStatus.totalSize;
        }
        set;
    }

// returns the first page of records
    public void firstpageStatusWrap() {
        collectSelectedIds();
        theTMListPerStatus = PaginationByStatus.beginning();
        establishSelectedTMs();
    }

// returns the last page of records
    public void lastpageStatusWrap() {
        collectSelectedIds();
        theTMListPerStatus = PaginationByStatus.last();
        establishSelectedTMs();
    }

// returns the previous page of records
    public void previouspageStatusWrap() {
        collectSelectedIds();
        theTMListPerStatus = PaginationByStatus.previous();
        establishSelectedTMs();
    }

// returns the next page of records
    public void nextpageStatusWrap() {
        collectSelectedIds();
        theTMListPerStatus = PaginationByStatus.next();
        establishSelectedTMs();
    }
/////////////////////////////////////CUSTOM PAGINATION////////////////////////////////////////////////

    public String sortBy {
        get {
            return orderBy;
        }
    }

    public String sortDirection {
        get {
            return order;
        }
    }

    public PageReference CreateInvoiceFromProcessTM() {
        collectSelectedIds();
        system.debug('selectedIds***' + selectedIds);
        string selectedTMs = '';
        for (Integer i = 0; i < lstSelectedIds.size(); i++) {
            if (i != 0) selectedTMs += ',';
            selectedTMs += lstSelectedIds[i] ;
        }

        if (string.isEmpty(selectedTMs) && !Test.isRunningTest()) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select at least one T&M.'));
            return null;
        }

        system.debug('selectedTMs***' + selectedTMs);
        PageReference BillingPage = new PageReference('/apex/CreateInvoiceFromProcessTM?selectedTMIds=' + selectedTMs);
        BillingPage.setRedirect(true);
        return BillingPage;
    }



    public void CreateSIFromProcessTM() {
        /*
        string selectedTMIds = ApexPages.CurrentPage().getParameters().get('selectedTMIds');

        List<string> lstSelectedTMIds = new List<string>();
        lstSelectedTMIds = selectedTMIds.split(',');

        String strQuery = 'SELECT Lump_Sum_Order__c, Bill_To_Customer__c, Tax_Area__c, Service_Center__c, Sales_Order__c, Status__c, Account_Executive__c, Customer_PO_No__c, ' +
                'Contact__c, Contract__c, Site_Contact_2__c, Site_Name__c, Site_Street__c, Site_City__c, Site_State__c, Site_Phone_No__c, Site_Country__c, Site_Contact__c, ' +
                'Site_Email_Address__c, Tax_Liable__c, Subsidiary_Company__c, Bill_to_Customer__r.Payment_Term__c, Bill_to_Customer__r.Name, Name';
        strQuery += ' FROM TM__c WHERE Id IN: lstSelectedTMIds';

        theTMList = Database.query(strQuery);

        if (theTMList != null && theTMList.size() > 0) {
            Map<String, Schema.SObjectField> fields1 = Schema.SObjectType.TM_Line__c.fields.getMap();
            lstFields = new List<String>();
            for (Schema.SObjectField field : fields1.values()) {
                lstFields.add(field.getDescribe().getName());
            }

            strQuery = 'SELECT Invoiced__c, Resource_Type__c, Resource__c, Resource_Type__r.Fleet_No_Required__c, Service_Center__r.Equipment_Fleet_No_Not_Required__c, ' +
                    'Resource_Type__r.Name, Description__c, Category__c, Unit_of_Measure__c, Tax_Group__c, Tax_Pct__c, Tax__c, Id, TM__c, Service_Center__c, ' +
                    'Bill_as_Lump_Sum__c, Non_Billable__c, BOL_Manifest__c, TM__r.Scheduled_Date__c, Hour__c, Quantity__c, ' +
                    'Unit_Cost__c, Line_Cost__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Regular_Hours__c, Regular_Rate__c, Use_Premium_Rate__c, ' +
                    'Premium_Hours__c, Premium_Rate__c, Overtime_Hours__c, Overtime_Rate__c, Pick_Up_Rental__c, TM__r.Name, Line_No__c, Pick_Up_R_O__c, ' +
                    'TM__r.Sales_Order__c, Pick_Up_R_O__r.Sales_Order__c, Pick_Up_R_O__r.Resource__c, Unit_Price__c, Drop_Off_Rental__c ';

            strQuery += ' FROM TM_Line__c WHERE TM__c IN: lstSelectedTMIds ORDER BY TM__c';
            theTMLList = Database.query(strQuery);

            system.debug('theTMLList***' + theTMLList);
        }

        DropOffRentalOrders = 0;
        PickUpRentalOrders = 0;
        if (theTMLList != null && theTMLList.size() > 0) {
            for (TM_Line__c theTML : theTMLList) {
                if (theTML.Category__c == 'Equipment') {
                    if (theTML.Pick_Up_Rental__c && theTML.Pick_Up_R_O__c != null) PickUpRentalOrders += 1;
                    if (theTML.Drop_Off_Rental__c && theTML.Drop_Off_R_O__c == null) DropOffRentalOrders += 1;
                }
            }
        }
         */
    }

    public pagereference returnToProcessTM() {
        PageReference redirectPage = new PageReference('/apex/ProcessTM?flterByStatus=Ready to Bill');
        redirectPage.setRedirect(true);
        return redirectPage;
    }
    
    public pagereference returnToProcessTMDummy() {
        PageReference redirectPage = new PageReference('/apex/ProcessTM?flterByStatus=Ready to Bill');
        redirectPage.setRedirect(true);
        return redirectPage;
    }

    public void createRO(List<TM__c> lstTM) {
        /*
        List<string> lstSelectedTMIds = new List<string>();
        List<TM_Line__c> lstTML = new List<TM_Line__c>();
        Map<Id, List<TM_Line__c>> mapTMLList = new map<Id, List<TM_Line__c>>();
        Map<Id, TM__c> mapTM = new map<Id, TM__c>();
        Map<Id, TM_Line__c> mapPickUpROTML = new map<Id, TM_Line__c>();
        List<Rental_Order__c> lstRentalOrder = new List<Rental_Order__c>();
        Map<String, String> mapROTML = new Map<String, String>();
        List<TM_Line__c> theTMLList;


        if (lstTM != null && lstTM.size() > 0) {
            for (TM__c TM : lstTM) {
                if (!lstSelectedTMIds.contains(TM.Id)) {
                    lstSelectedTMIds.add(TM.Id);
                }
            }

            system.debug('lstSelectedTMIds***' + lstSelectedTMIds);

            Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM_Line__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }

            system.debug('lstFields***' + lstFields);
            string strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ',Unit_of_Measure__r.Name, Resource__r.Name, Resource__r.Description__c, Resource_Type__r.Name,Job_Type__r.Name';
            strQuery += ' ,Service_Center__r.Name, Resource__r.Silver_Rate__c, Resource__r.Silver_ER_Rate__c, Resource__r.Platinum_Rate__c, Resource__r.Fleet_Number__c, ' +
                    'Resource__r.Platinum_ER_Rate__c, Resource__r.Gold_Rate__c, Resource__r.Gold_ER_Rate__c, Resource__r.Unit_of_Measure__c, Contract_Line__r.Name ';
            strQuery += ' FROM TM_Line__c WHERE TM__c IN: lstSelectedTMIds ORDER BY TM__c';
            lstTML = Database.query(strQuery);
            system.debug('strQuery**' + strQuery);
            system.debug('lstTML***' + lstTML);

            for (TM__c TM : lstTM) {
                theTMLList = new List<TM_Line__c>();
                for (Integer i = 0; i < lstTML.size(); i++) {
                    mapTM.put(lstTML[i].Id, TM);
                    if (lstTML[i].TM__c == TM.Id) {
                        theTMLList.add(lstTML[i]);
                        lstTML.remove(i);
                    }
                }
                mapTMLList.put(TM.Id, theTMLList);
            }

            for (TM__c TM : lstTM) {
                lstRentalOrder.addAll(insertRO(TM, mapTMLList.get(TM.Id), new Sales_Invoice__c()));
            }

            if (lstRentalOrder != null && lstRentalOrder.size() > 0) {
                insert lstRentalOrder;
            }

            for (Rental_Order__c RO : lstRentalOrder) {
                mapROTML.put(RO.Drop_Off_T_M_Line__c, RO.Id);
            }

            theTMLList = new List<TM_Line__c>();
            for (List<TM_Line__c> TMLList : mapTMLList.values()) {
                theTMLList.addAll(TMLList);
            }

            for (TM_Line__c theTML : theTMLList) {
                if (theTML.Drop_Off_Rental__c == true) {
                    if (mapROTML.containsKey(theTML.Id)) {
                        theTML.Drop_Off_R_O__c = mapROTML.get(theTML.Id);
                    }
                }
            }

            update theTMLList;
            // Update Pickup Rental Order
            Set<Id> PickupROIds = new Set<Id>();
            for (TM_Line__c theTML : theTMLList) {
                if (theTML.Pick_Up_Rental__c == true) {
                    mapPickUpROTML.put(theTML.Pick_Up_R_O__c, theTML);
                    PickupROIds.add(theTML.Pick_Up_R_O__c);
                }
            }
            List<Rental_Order__c> PickupROList = [SELECT Name, Pick_Up_Date__c FROM Rental_Order__c WHERE Id IN :PickupROIds];

            for (Integer i = 0; i < PickupROList.size(); i++) {
                PickupROList[i].Pick_Up_Date__c = mapTM.get(mapPickUpROTML.get(PickupROList[i].Id).Id).Scheduled_Date__c;
                PickupROList[i].Pickup_T_M__c = mapTM.get(mapPickUpROTML.get(PickupROList[i].Id).Id).Id;
                PickupROList[i].Pickup_T_M_Line__c = mapPickUpROTML.get(PickupROList[i].Id).Id;
            }

            update PickupROList;
        }
         */
    }

    private Set<Id> collectSelectedIds() {
        if (theTMListPerStatus != null && theTMListPerStatus.size() > 0) {
            for (Integer i = 0; i < theTMListPerStatus.size(); i++) {
                if (theTMListPerStatus[i].isSelected) {
                    if (!selectedIds.contains(theTMListPerStatus[i].theTM.Id)) {
                        selectedIds.add(theTMListPerStatus[i].theTM.Id);
                    }
                } else if (!theTMListPerStatus[i].isSelected && selectedIds.contains(theTMListPerStatus[i].theTM.Id)) {
                    selectedIds.remove(theTMListPerStatus[i].theTM.Id);
                }
            }
        }

        return selectedIds;
    }

    private void establishSelectedTMs() {
        if (theTMListPerStatus != null && theTMListPerStatus.size() > 0 && selectedIds != null && selectedIds.size() > 0) {
            for (Integer i = 0; i < theTMListPerStatus.size(); i++) {
                if (selectedIds.contains(theTMListPerStatus[i].theTM.Id)) {
                    theTMListPerStatus[i].isSelected = true;
                }
            }
        }
    }

    public List<Id> lstSelectedIds {
        get {
            return new List<Id>(selectedIds);
        }
    }
}