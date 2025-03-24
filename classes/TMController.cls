public with sharing class TMController {
    private final ApexPages.StandardController theController;
    public TM__c theTM { get; set; }
    public List<TM_Line__c> theAllTMLList;
    public List<TM_Line__c> theTMLList;
    public List<TM_Line__c> theTMLListLabor;
    public List<TM_Line__c> theTMLListEquipment;
    public List<TM_Line__c> theTMLListMaterials;
    public List<TM_Line__c> theTMLListSubcontractors;
    public List<TM_Line__c> theTMLListWasteDisposal;
    public List<TM_Line__c> theTMLListDemurrage;
    public List<TM_Line__c> theTMLListLumpSum;
    public List<TM_Line__c> theTMLListMisc;
    public String tmId;
    public List<TM__c> theTMList { get; set; }
    public String scheduledDateValue { get; set; }
    public List<TMWrapper> theTMWrapList { get; set; }
    public Decimal DropOffRentalOrders { get; set; }
    public Decimal PickUpRentalOrders { get; set; }

    public Decimal TMLSubtotal { get; set; }
    public Decimal TMLTaxTotal { get; set; }
    public Decimal TMLTotal { get; set; }

    public Decimal TMLSubtotalLabor { get; set; }
    public Decimal TMLTaxTotalLabor { get; set; }
    public Decimal TMLTotalLabor { get; set; }

    public Decimal TMLSubtotalEquipment { get; set; }
    public Decimal TMLTaxTotalEquipment { get; set; }
    public Decimal TMLTotalEquipment { get; set; }

    public Decimal TMLSubtotalMaterials { get; set; }
    public Decimal TMLTaxTotalMaterials { get; set; }
    public Decimal TMLTotalMaterials { get; set; }

    public Decimal TMLSubtotalSubcontractors { get; set; }
    public Decimal TMLTaxTotalSubcontractors { get; set; }
    public Decimal TMLTotalSubcontractors { get; set; }

    public Decimal TMLSubtotalWasteDisposal { get; set; }
    public Decimal TMLTaxTotalWasteDisposal { get; set; }
    public Decimal TMLTotalWasteDisposal { get; set; }

    public Decimal TMLSubtotalDemurrage { get; set; }
    public Decimal TMLTaxTotalDemurrage { get; set; }
    public Decimal TMLTotalDemurrage { get; set; }

    public Decimal TMLSubtotalLumpSum { get; set; }
    public Decimal TMLTaxTotalLumpSum { get; set; }
    public Decimal TMLTotalLumpSum { get; set; }

    public Decimal TMLSubtotalMisc { get; set; }
    public Decimal TMLTaxTotalMisc { get; set; }
    public Decimal TMLTotalMisc { get; set; }

    private String currUser;
    public User theUser { get; set; }
    public Service_Center__c theSC { get; set; }
    public static Company_Setup__c theCompanySetup {
        get {
            theCompanySetup = CompanyMgmt.getCompanySetup();
            return theCompanySetup;
        }
        set;
    }

    public static Company_Setting__mdt defaultCompanySetting {
        get {
            defaultCompanySetting = CompanySettingUtil.acvSetting;
            return defaultCompanySetting;
        }
        set;
    }

    public String selTMId { get; set; }
    public String filterInput { get; set; }
    public String selFilterField { get; set; }
    public String selFilterOp { get; set; }
    public String filterInput2 { get; set; }
    public String selFilterField2 { get; set; }
    public String selFilterOp2 { get; set; }
    public String selectedItem { get; set; }

    public Map<Boolean, String> checkbxUrl { get; set; }

    public List<TMPerStatusWrapper> theTMListPerStatus { get; set; }
    private Map<String, TM_Line__c> theMapTMReadyToBill;

    //Pagination Status variable
    public TMWrapperPagination Pagination;
    public TMPerStatusWrapperPagination PaginationByStatus;
    public String orderBy;
    public String orderBy_old;
    public String order;
    public Integer PageSize { get; set; }
    //Pagination Status variable    
    public String scheduledDate { get; set; }
    public Date dateScheduledDate { get; set; }

    public Boolean afterInvoiced { get; set; }

    public String selectedTMsIds { get; set; }
    public String selectedId { get; set; }
    public Boolean selectAll { get; set; }
    public Contact theSiteContact { get; set; }
    public Contract theContract { get; set; }
    public String theSCId { get; set; }

    public String invoiceNote { get; set; }
    public Id originSOId { get; set; }

    public String stringScheduleDateFilter { get; set; }
    public List<SelectOption> filterFieldOptn {
        get {
            if (filterFieldOptn == null) {
                filterFieldOptn = new List<SelectOption>();
                filterFieldOptn.add(new SelectOption('Name', 'T&M No.'));
                filterFieldOptn.add(new SelectOption('Bill_to_Customer__r.name', 'Customer'));
            }
            return filterFieldOptn;
        }
        set;
    }

    public List<TMReadyToBillWrapper> theReadyTobillTMList { get; set; }

    public static String changeStatusTo {
        get;
        set {
            changeStatusTo = value;
        }
    }

    //Ticket# 13874 >>
    public static Boolean isTempSCChecked = false;
    public static Map<Id, Service_Center__c> tempServiceCenters;
    //Ticket# 13874 >>

    public TMController() {
        PageSize = 50;
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

    public TMController(ApexPages.StandardController controller) {
        scheduledDate = ApexPages.currentPage().getParameters().get('scheduledDate');
        if (!String.isEmpty(scheduledDate)) {
            scheduledDateValue = scheduledDate;
        } else {
            scheduledDateValue = Date.today().month() + '/' + Date.today().day() + '/' + Date.today().year();
        }

        dateScheduledDate = Date.parse(scheduledDateValue);
        stringScheduleDateFilter = dateScheduledDate.year() + '-' + dateScheduledDate.month() + '-' + dateScheduledDate.day();

        currUser = UserInfo.getUserId();
        theController = controller;
        tmId = ApexPages.currentPage().getParameters().get('id');
        theSiteContact = new Contact(); //Ticket# AES-401
        theContract = new Contract(); //AES-440
        if (tmId == null) {
            theTM = new TM__c();
            theTMLList = new List<TM_Line__c>();
        } else {
            selectTM();
            selectTMLList();

            if (theTM.Desired_Scheduled_Date__c != null) {
                dateScheduledDate = theTM.Desired_Scheduled_Date__c;
            }
        }

        checkbxUrl = new Map<Boolean, String>();
        checkbxUrl.put(true, '<img src="/img/checkbox_checked.gif"/>');
        checkbxUrl.put(false, '<span class="chkbx">&nbsp;&nbsp;&nbsp;&nbsp;</span>');

        selectUser();
        selectServiceCenter();
        setscheduledatefilterFormat();
    }

    public Company_Setup__c CompanySetup {
        get {
            return theCompanySetup;
        }
    }

    //Daily Roster Page
    public PageReference selectTmList() {
        TMWrapper theTMWrap;
        Integer i = 0;
        Integer j = 0;
        theTMList = new List<TM__c>();
        Date scheduledDate;
        List<String> lstStatus = new List<String>();
        lstStatus.add('Scheduled');
        lstStatus.add('Mobile Review');
        lstStatus.add('Confirmed');
        lstStatus.add('Partially Invoiced');
        lstStatus.add('Fully Invoiced');
        lstStatus.add('Closed');
        lstStatus.add('Sent to EQAI');
        if (Test.isRunningTest()) lstStatus.add('Open');

        List<String> subMenuItems = new List<String>();
        subMenuItems.add('Add');
        subMenuItems.add('Labor');
        subMenuItems.add('Equipment');
        subMenuItems.add('Material');

        List<String> selectedTMIds = new List<String>();
        if (getVFPageName() == 'DailyRosterPDF') {
            theSCId = ApexPages.currentPage().getParameters().get('SCId');
            String selectedTMIdsParam = ApexPages.CurrentPage().getParameters().get('selectedTMIds'); //Ticket#17913
            selectedTMIds = selectedTMIdsParam.split(','); //Ticket#17913
        } else {
            theSCId = theUser.Service_Center__c;
        }

        String strQuery = 'SELECT Id,Name,Bill_to_Customer__c,Sales_Order__c,Service_Center__c,Status__c,' +
                'Site_Name__c,Site_Street__c,Site_City__c,Site_State__c,Site_Postal_Code__c,Start_Time__c,' +
                'Project_Coordinator__r.Name,Service_Center__r.Name, Sales_Order__r.Name, ' +
                'Contact__r.FirstName,Bill_To_Customer__r.Name, Project_Manager_Reviewed__c';
        strQuery += ' FROM TM__c WHERE Status__c IN: lstStatus';
        strQuery += ' AND Service_Center__r.Name =: theSCId';

        if (getVFPageName() == 'DailyRosterPDF' && selectedTMIds.size() > 0) {
            strQuery += ' AND Id =: selectedTMIds';
        }

        if (String.isNotEmpty(scheduledDateValue)) {

            String Filtr = '';
            if (String.isBlank(filterInput)) {
                Filtr += '';
            } else {
                if (String.isNotBlank(selFilterField) && String.isNotBlank(filterInput)) {
                    if (selFilterOp == 'contains') {
                        Filtr += ' AND ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\'';

                    } else if (selFilterOp == 'not contains') {
                        Filtr += ' AND  (NOT ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\')';
                    }
                }
            }

            scheduledDate = Date.parse(scheduledDateValue);
            strQuery += ' AND Scheduled_Date__c =: scheduledDate';
            strQuery += Filtr;
        } else {
            String Filtr = '';

            if (String.isBlank(filterInput)) {
                Filtr += '';
            } else {
                if (String.isNotBlank(selFilterField) && String.isNotBlank(filterInput)) {
                    if (selFilterOp == 'contains') {
                        Filtr += ' AND ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\'';

                    } else if (selFilterOp == 'not contains') {
                        Filtr += ' AND  (NOT ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\')';
                    }
                }
            }
            strQuery += Filtr;
        }

        if (!String.isEmpty(orderBy)) {
            if (orderBy == 'Bill_To_Customer__c') orderBy = 'Bill_To_Customer__r.Name';

            else if (orderBy == 'Service_Center__c') orderBy = 'Service_Center__r.Name';

            else if (orderBy == 'Sales_Order__c') orderBy = 'Sales_Order__r.Name';

            //Ticket#23051 >>
            else if (orderBy == 'Status') orderBy = 'Status__c';
            else if (orderBy == 'PM') orderBy = 'Project_Coordinator__r.Name';
            //Ticket#23051 <<
            strQuery += ' ORDER BY ' + orderBy + ' ' + order + ' NULLS LAST';
        } else {
            strQuery += ' ORDER BY NAME' ;
        }

        theTMList = Database.query(strQuery);

        theAllTMLList = new List<TM_Line__c>();
        selectAllTML();

        Map<String, TM_Line__c> mapTML = new Map<String, TM_Line__c>();

        for (TM_Line__c theTML : theAllTMLList) {
            mapTML.put(theTML.TM__c, theTML);
        }

        theTMWrapList = new List<TMWrapper>();
        List<TM_Line__c> theTMLList;
        String startTime = '';
        Datetime dtStart;
        selectAll = false;
        for (i = 0; i < theTMList.size(); i++) {
            if (mapTML.containsKey(theTMList[i].Id)) {
                theTMLList = new List<TM_Line__c>();
                List<String> lstLabour = new List<String>();
                List<String> lstEquipment = new List<String>();
                //Steven 0709
                //Map<TM_Line__c, List<String>> mapLabor = new Map<TM_Line__c, List<String>>();
                //Map<TM_Line__c, List<String>> mapEquipment = new Map<TM_Line__c, List<String>>();
                Map<TM__c, List<String>> mapLabor = new Map<TM__c, List<String>>();
                Map<TM__c, List<String>> mapEquipment = new Map<TM__c, List<String>>();
                theTMLList = mapTML.values();
                for (j = 0; j < theAllTMLList.size(); j++) {
                    if (theAllTMLList[j].TM__c == theTMList[i].Id) {
                        if (theAllTMLList[j].Category__c == 'Labor') {
                            //Ticket# 13421 >>
                            if (theAllTMLList[j].Resource__c != null) {
                                lstLabour.add(theAllTMLList[j].Resource__r.Description__c);
                            } else if (theAllTMLList[j].Resource_Type__c != null) {
                                lstLabour.add(theAllTMLList[j].Resource_Type__r.Name);
                            }
                            //Ticket# 13421 <<
                        } else if (theAllTMLList[j].Category__c == 'Equipment') {
                            //Ticket# 13421 >>
                            if (theAllTMLList[j].Resource__c != null) {
                                lstEquipment.add(theAllTMLList[j].Resource__r.Name + ' - ' + theAllTMLList[j].Resource__r.Description__c);
                            } else if (theAllTMLList[j].Resource_Type__c != null) {
                                lstEquipment.add(theAllTMLList[j].Resource_Type__r.Name);
                            }
                            //Ticket# 13421 <<
                        }
                    }
                }
                //Steven 07/09
                //these code cause List index out of bounds: error if there are more than 1 TM and only 1 TM has line data.
                //mapLabor.put(theAllTMLList[i], lstLabour);
                //mapEquipment.put(theAllTMLList[i], lstEquipment);
                mapLabor.put(theTMList[i], lstLabour);
                mapEquipment.put(theTMList[i], lstEquipment);

                if (theTMList[i].Start_Time__c != null) {
                    dtStart = Datetime.newInstance(Date.today(), theTMList[i].Start_Time__c);
                    startTime = dtStart.format('hh:mm a');
                } else {
                    startTime = '';
                }

                //Steven 07/09
                //theTMWrap = new TMWrapper(subMenuItems, theTMList[i], mapLabor.get(theAllTMLList[i]), mapEquipment.get(theAllTMLList[i]), False, startTime);
                theTMWrap = new TMWrapper(subMenuItems, theTMList[i], mapLabor.get(theTMList[i]), mapEquipment.get(theTMList[i]), false, startTime);

                theTMWrapList.add(theTMWrap);
            } else {
                List<String> emptyList = new List<String>();
                theTMWrap = new TMWrapper(subMenuItems, theTMList[i], emptyList, emptyList, false, '');
                theTMWrapList.add(theTMWrap);
            }
        }

        //Initialize Pagination
        if (getVFPageName() == 'DailyRoster') {
            Pagination = new TMWrapperPagination(theTMWrapList, PageSize); theTMWrapList = Pagination.beginning();
        }
        //Initialize Pagination Ends
        return null;
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
        selectTmList();
    }

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

    /* Depreciated
    public Map<String, String> fieldNameCategoryMap;
    public void setFieldNameCategoryMap() {
        fieldNameCategoryMap = new Map<String, String>();
        fieldNameCategoryMap.put('theMBillasLumpSum', 'Materials');
        fieldNameCategoryMap.put('theMNonBillable', 'Materials');
        fieldNameCategoryMap.put('theDBillasLumpSum', 'Demurrage');
        fieldNameCategoryMap.put('theDNonBillable', 'Demurrage');
        fieldNameCategoryMap.put('theSBillasLumpSum', 'Subcontractors');
        fieldNameCategoryMap.put('theSNonBillable', 'Subcontractors');
        fieldNameCategoryMap.put('theWBillasLumpSum', 'Waste Disposal');
        fieldNameCategoryMap.put('theWNonBillable', 'Waste Disposal');
        fieldNameCategoryMap.put('theMiscBillasLumpSum', 'Misc. Charges And Taxes');
        fieldNameCategoryMap.put('theMiscNonBillable', 'Misc. Charges And Taxes');
    }
     */

    private void selectUser() {
        theUser = new User();

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

        if (theUser.Service_Center__c == null) throw new DataException('You must set up Service Center for User: ' + theUser.Name);

        String theSCId = theUser.Service_Center__c;
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Subsidiary_Company__r.Name';
        strQuery += ' FROM Service_Center__c WHERE Name =: theSCId LIMIT 1';

        theSC = Database.query(strQuery);

    }

    /*
     *   Billing Rule not required - add Sales_Order__r.Billing_Rule_Not_Required__c
     */
    private void selectTM() {
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
                ',Bill_to_Customer__r.Payment_Term__c, Sales_Order__r.From_Sales_Quote__c, Site_Contact_2__r.Name' +
                ',Sales_Order__r.Surcharge_Type__c, Sales_Order__r.Surcharge_Pct__c, Contract__r.ContractNumber, Bill_to_Customer__r.ParentId' +
                ',Contract__r.Allow_Lunch_Time_on_Equipment__c, Sales_Order__r.Sales_Order_Type__r.Emergency_Response__c,Sales_Order__r.Pay_Rule__c' +
                ',Contract__r.Billing_Rule__c, Sales_Order__r.Rate_Sheet__c, TM__c.Rate_Sheet__r.Name,Sales_Order__r.Portal_Basis__c,Sales_Order__r.Overtime_Rate__c' +
                ',Sales_Order__r.Daily_Rate__c,Sales_Order__r.Lump_Sum__c, Sales_Order__r.Billing_Rule_Not_Required__c,Sales_Order__r.Manifest_And_Profile__c' +
                ',Sales_Order__r.Charge_Rinse_Out_Fee__c, Sales_Order__r.Sales_Order_Type__r.Name, Bill_to_Customer__r.Print_TM_Time_Detail__c, Sales_Order__r.Distance_to_Job_Site__c' +
                ',Bill_to_Customer__r.Contact_Type_Filter__c, Bill_to_Customer__r.Invoice_Email_Contact_Types__c' +
                ',Sales_Order__r.Sales_Order_Instructions__c, Bill_to_Customer__r.Customer_Billing_Instructions__c';
        strQuery += ' FROM TM__c WHERE Id =: tmId';
        theTM = Database.query(strQuery);

        originSOId = theTM.Sales_Order__c;//Ticket# 13811;
    }

    /*
     *   Billing Rule not required - add Sales_Order__r.Billing_Rule_Not_Required__c
     */
    private void selectTMLList() {
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        //Ticket 13393: add Resource__r.Employee_No__c
        //Ticket 13457: add TM__r.Name
        //Ticket 13540: add Service_Center__r.Equipment_Fleet_No_Not_Required__c
        //Ticket 14250: add Resource_Type__r.Fuel_Fired_Equipment__c
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',TM__r.Name, Unit_of_Measure__r.Name, Resource__r.Name, Resource__r.Description__c, Resource_Type__r.Name, Job_Type__r.Name,TM__r.Scheduled_Date__c';
        strQuery += ' ,Drop_Off_R_O__r.Sales_Order__c, Drop_Off_R_O__r.Resource__c, Drop_Off_R_O__r.Pick_Up_Date__c, Resource_Type__r.Description__c, Resource_Type__r.Fleet_No_Required__c ';
        strQuery += ' ,Service_Center__r.Name, Resource__r.Silver_Rate__c, Resource__r.Silver_ER_Rate__c, Resource__r.Platinum_Rate__c, Resource__r.Fleet_Number__c, ' +
                'Resource__r.Platinum_ER_Rate__c, Resource__r.Gold_Rate__c, Resource__r.Gold_ER_Rate__c, Contract_Line__r.Name, Resource__r.Employee_No__c, ' +
                'Service_Center__r.Equipment_Fleet_No_Not_Required__c,Resource__r.Service_Center__c, Sales_Line__r.Unit_of_Measure__c, Sales_Line__r.Unit_Price__c';
        strQuery += ', Resource_Type__r.Unit_of_Measure__c, Resource_Type__r.Unit_of_Measure1__c, Resource_Type__r.Unit_of_Measure2__c, Resource_Type__r.Unit_of_Measure3__c, Resource_Type__r.Unit_of_Measure4__c ';
        strQuery += ', Resource__r.Unit_of_Measure__c, Resource__r.Unit_of_Measure1__c, Resource__r.Unit_of_Measure2__c, Resource__r.Unit_of_Measure3__c, Resource__r.Unit_of_Measure4__c ' +
                ',Resource__r.Non_Payroll_Labor_Resource__c, Service_Center__r.Temporary__c, Unit_of_Measure__r.Hours_UOM__c, ' +
                'TM__r.Sales_Order__r.Portal_Basis__c, TM__r.Sales_Order__r.Overtime_Rate__c, TM__r.Sales_Order__r.Daily_Rate__c,' +
                'TM__r.Sales_Order__r.Lump_Sum__c, Resource_Type__r.Fuel_Fired_Equipment__c, Container_Size__r.Name, Unit_Weight_Vol__r.Name, Facility__r.Name, Resource__r.Resource_Type__c,' +
                'TM__r.Sales_Order__r.Billing_Rule_Not_Required__c, Resource__r.Has_Container__c, Resource__r.Has_Weight_Volume__c, Linked_Line__r.Resource_Name__c';
        strQuery += ' FROM TM_Line__c WHERE TM__c =: tmId ORDER BY Line_No__c';
        theTMLList = Database.query(strQuery);
        // Calculate total Drop Off and Pick Up Rental Orders
        DropOffRentalOrders = 0;
        PickUpRentalOrders = 0;
        for (TM_Line__c theTML : theTMLList) {
            if (theTML.Category__c == 'Equipment') {
                if (theTML.Pick_Up_Rental__c && theTML.Pick_Up_R_O__c != null) PickUpRentalOrders += 1;
                if (theTML.Drop_Off_Rental__c && theTML.Drop_Off_R_O__c == null) DropOffRentalOrders += 1;
            }
        }
    }

    /*
     *   Billing Rule not required - add Sales_Order__r.Billing_Rule_Not_Required__c
     */
    @testvisible
    private void selectAllTML() {

        Set<String> tmIds = new Set<String>();
        for (TM__c tm : theTMList) {
            if (!tmIds.contains(tm.Id)) {
                tmIds.add(tm.Id);
            }
        }

        if (!tmIds.isEmpty()) {
            /*
            Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM_Line__c.fields.getMap();
            List<String> lstFields = new List<String>();
            for (Schema.SObjectField field : fields.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            String strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ', Resource__r.Name, Resource__r.Description__c, Resource_Type__r.Name, Resource_Type__r.Fleet_No_Required__c' +
                    ',Service_Center__r.Equipment_Fleet_No_Not_Required__c, Service_Center__r.Temporary__c, Unit_of_Measure__r.Hours_UOM__c,' +
                    'TM__r.Sales_Order__r.Portal_Basis__c, TM__r.Sales_Order__r.Overtime_Rate__c, TM__r.Sales_Order__r.Daily_Rate__c,TM__r.Sales_Order__r.Lump_Sum__c,' +
                    'TM__r.Sales_Order__r.Billing_Rule_Not_Required__c, Facility__r.Name, Resource__r.Non_Payroll_Labor_Resource__c,' +
                    'Resource__r.Has_Container__c, Resource__r.Has_Weight_Volume__c, Linked_Line__r.Resource_Name__c';
            strQuery += ' FROM TM_Line__c WHERE TM__c IN :tmIds ORDER BY TM__c, Line_No__c';
            theAllTMLList = Database.query(strQuery);
             */
            theAllTMLList = [SELECT Id, TM__c, Category__c, Resource__c, Resource_Type__c, Resource__r.Name, Resource__r.Description__c,
                    Resource_Type__r.Name, Resource_Type__r.Description__c
                FROM TM_Line__c WHERE TM__c IN :tmIds ORDER BY TM__c, Line_No__c];
        }
    }

    public String title {
        get {
            if (tmId == null) {
                return 'New TM';
            } else {
                return theTM.Name;
            }
        }
    }

    public TM__c TM {
        get {
            return theTM;
        }
        set {
            theTM = value;
        }
    }

    public String TMStatus {
        get {
            return TM.Status__c;
        }
        set {
            TM.Status__c = value;
        }
    }

    public String NextStatus {
        get {
            if (TM.Status__c == 'Open') {
                return 'Scheduled';
            }
            /*
            } else if (TM.Status__c == 'Scheduled') {
                return 'Confirmed';
            */
            else if (TM.Status__c == 'Scheduled') {
                if (TM.Mobile_TM__c == true) {

                    return 'Mobile Review';
                }
                else {
                    return 'Confirmed';
                }
            } else if (TM.Status__c == 'Mobile Review') {
                return 'Confirmed';
            } else if (TM.Status__c == 'Confirmed') {
                return 'Received By Billing';
            } else if (TM.Status__c == 'Received By Billing') {
                return 'Ready to Bill';
            } else if (TM.Status__c == 'Ready to Bill') {
                return 'Partially Invoiced';
            } else if (TM.Status__c == 'Partially Invoiced') {
                return 'Fully Invoiced';
            } else if (TM.Status__c == 'Fully Invoiced') {
                return 'Closed';
            } else if (TM.Status__c == 'Closed') {
                return 'Void';
            } else {
                return '';
            }
        }
        set {
        }
    }

    /* Depreciated
    public void validateTaxArea() {
        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');

        if (!string.isEmpty(newFieldValue)) {
            //theTM.Tax_Area__c = newFieldValue;

            List<Tax_Area__c> TaxArea = [Select Id,Name from Tax_Area__c where Id = :newFieldValue Limit 1];
            if (TaxArea.size() == 0) {
                TaxArea = [Select Id,Name from Tax_Area__c where Name = :newFieldValue Limit 1];
            }

            if (taxArea.size() > 0) {
                theTM.Tax_Area__c = TaxArea[0].Id;
                theTM.Tax_Area__r = new Tax_Area__c(Id = TaxArea[0].Id, Name = TaxArea[0].Name);
                reInsertTML();
            } else {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Tax Area does not exist! ' + newFieldValue));
                //return null;
            }
            //theTM = TMMgmt.validateTaxArea(theTM);

        }
    }
     */

    //Depreciated
    public void validateTaxLiable() {
        //reInsertTML();
    }

    //Depreciated
    public void validateContact() {
        /*
        String contactId = ApexPages.currentPage().getParameters().get('contactId');
        String fieldId = ApexPages.currentPage().getParameters().get('fieldId');

        if (!String.isEmpty(contactId)){
            List<Contact> contacts = [SELECT Id, FirstName, LastName, Name, Email FROM Contact WHERE Id = :contactId];
            if (contacts.size() > 0){
                if(fieldId == 'theBTContact') {
                    theTM.Contact__c = contacts[0].Id;
                    theTM.Contact__r = contacts[0];
                } else {
                    theTM.Site_Contact_2__c = contacts[0].Id;
                    theTM.Site_Contact_2__r = contacts[0];
                    theSiteContact = contacts[0];
                    //10.07.19 <<
                    theTM.Site_Contact__c = contacts[0].Name;
                    if (theTM.Site_Email_Address__c == null) {
                        theTM.Site_Email_Address__c = contacts[0].Email;
                    }
                    //10.07.19 >>
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact does not exist!' + contactId));
            }
        } else {
            if(fieldId == 'theBTContact') {
                theTM.Contact__c = null;
            } else {
                theTM.Site_Contact_2__c = null;
            }
        }
         */
    }

    /*Depreciated
    public void validateContract(){
        String contractId = ApexPages.currentPage().getParameters().get('contractId');
        if (!String.isEmpty(contractId)){
            List<Contract> contracts = ContractsSelector.newInstance().selectByIdWithBillingRule(new Set<Id>{contractId});
            //[SELECT Id, ContractNumber, Name,  FROM Contract WHERE Id = :contractId];
            if (contracts.size() > 0){
                theTM.Contract__c = contracts[0].Id;
                theTM.Contract__r = contracts[0];
                theContract = contracts[0];
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Contact does not exist!' + contractId));
            }
        }
    }
     */

    /*Depreciated
    public void validateRateSheet() {
        try {
            String rateSheetId = ApexPages.currentPage().getParameters().get('rateSheetId');
            if(String.isBlank(rateSheetId)){
                rateSheetId = null;
            }
            TMsService.validateRateSheet(theTM, theTMLList, rateSheetId);
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
    }
     */

    //Depreciated
    public void validateSalespeople() {
        //theTM = TMMgmt.validateSalespeople(theTM);
    }

    //Depreciated
    public void validateServiceCenter() {
        //theTM = TMMgmt.validateServiceCenter(theTM);
    }

    /*Depreciated
    public void validateSalesOrder() {
        theTM = TMMgmt.validateSalesOrder(theTM);
        theTMLList = TMMgmt.validateTMLListWhileChangingSO(theTM, theTMLList);
    }
     */

    //Depreciated
    public void validateAltSiteAddress() {
        //theTM = TMMgmt.validateAltSiteAddress(theTM);
    }

    //Depreciated
    public void validateStartTime() {
        //theTM = TMMgmt.validateStartTime(theTM);
    }

    public List<TM_Line__c > TMLList {
        get {
            return theTMLList;
        }
        private set {
            theTMLList = value;
        }
    }

    /*Depreciated
    public List<TM_Line__c > TMLListLabor {
        get {
            theTMLListLabor = new List<TM_Line__c>();
            for (TM_Line__c theTML : TMLList) {
                if (theTML.Category__c == 'Labor') {
                    theTMLListLabor.add(theTML);
                }
            }
            return theTMLListLabor;
        }
        private set {
            theTMLListLabor = value;
        }
    }

    public List<TM_Line__c > TMLListEquipment {
        get {
            theTMLListEquipment = new List<TM_Line__c>();
            for (TM_Line__c theTML : TMLList) {
                if (theTML.Category__c == 'Equipment') {
                    theTMLListEquipment.add(theTML);
                }
            }
            return theTMLListEquipment;
        }
        private set {
            theTMLListEquipment = value;
        }
    }

    public List<TM_Line__c > TMLListMaterials {
        get {
            theTMLListMaterials = new List<TM_Line__c>();
            for (TM_Line__c theTML : TMLList) {
                if (theTML.Category__c == 'Materials') theTMLListMaterials.add(theTML);
            }
            return theTMLListMaterials;
        }
        private set {
            theTMLListMaterials = value;
        }
    }

    public List<TM_Line__c > TMLListSubcontractors {
        get {
            theTMLListSubcontractors = new List<TM_Line__c>();
            for (TM_Line__c theTML : TMLList) {
                if (theTML.Category__c == 'Subcontractors') theTMLListSubcontractors.add(theTML);
            }
            return theTMLListSubcontractors;
        }
        private set {
            theTMLListSubcontractors = value;
        }
    }

    public List<TM_Line__c > TMLListWasteDisposal {
        get {
            theTMLListWasteDisposal = new List<TM_Line__c>();
            for (TM_Line__c theTML : TMLList) {
                if (theTML.Category__c == 'Waste Disposal') {
                    if(theTML.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name()){
                        theTML.Unit_of_Measure__c = theTML.Container_Size__c;
                        theTML.Unit_of_Measure__r = theTML.Container_Size__r;
                    } else if (theTML.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()){
                        theTML.Unit_of_Measure__c = theTML.Unit_Weight_Vol__c;
                        theTML.Unit_of_Measure__r = theTML.Unit_Weight_Vol__r;
                    }
                    theTMLListWasteDisposal.add(theTML);
                }
            }
            return theTMLListWasteDisposal;
        }
        private set {
            theTMLListWasteDisposal = value;
        }
    }

    public List<TM_Line__c > TMLListDemurrage {
        get {
            theTMLListDemurrage = new List<TM_Line__c>();
            for (TM_Line__c theTML : TMLList) {

                if (theTML.Category__c == 'Demurrage') theTMLListDemurrage.add(theTML);
            }
            return theTMLListDemurrage;
        }
        private set {
            theTMLListDemurrage = value;
        }
    }

    public List<TM_Line__c > TMLListLumpSum {
        get {
            theTMLListLumpSum = new List<TM_Line__c>();
            for (TM_Line__c theTML : TMLList) {

                if (theTML.Category__c == 'Lump Sum') theTMLListLumpSum.add(theTML);
            }
            return theTMLListLumpSum;
        }
        private set {
            theTMLListLumpSum = value;
        }
    }

    public List<TM_Line__c > TMLListMisc {
        get {
            theTMLListMisc = new List<TM_Line__c>();
            for (TM_Line__c theTML : TMLList) {
                if (theTML.Category__c == 'Misc. Charges And Taxes') theTMLListMisc.add(theTML);
            }
            return theTMLListMisc;
        }
        private set {
            theTMLListMisc = value;
        }
    }
     */

    /*  Depreciated
     *  Ticket#17144 auto add manifest fee line base on Sales Order assumption
     *  TMsService.addRemoveManifestFeeLines(theTM, theTMLList);
     */
    @testvisible
    private void msave() {
        /*
        // To differentiate from standard edit page
        //CompanyMgmt.systemCall = true;
        if (theTMLList == null) {
            theTMLList = new List<TM_Line__c>();
        }

        // Delete lines without Resource Type and Resource in the temporary list
        Integer i = 0;
        while (i < theTMLList.size()) {
            if ((String.isEmpty(theTMLList[i].Resource__c) && String.isEmpty(theTMLList[i].Resource_Type__c) &&
                    theTMLList[i].Category__c != 'Waste Disposal' && theTMLList[i].Category__c != 'Misc. Charges And Taxes') ||
                    ((theTMLList[i].Category__c == 'Waste Disposal' || theTMLList[i].Category__c == 'Misc. Charges And Taxes')
                            && String.isEmpty(theTMLList[i].Resource__c) && String.isEmpty(theTMLList[i].Resource_Type__c) && String.isEmpty(theTMLList[i].Description__c))) {
                theTMLList.remove(i);
            } else {
                i++;
            }
        }

        // Delete subcontract lines without Description and Quantity = 0
        i = 0;
        while (i < theTMLList.size()) {
            if (theTMLList[i].Category__c == 'Subcontractors' && String.isEmpty(theTMLList[i].Description__c)) {
                theTMLList.remove(i);
            } else {
                i++;
            }
        }

        // Delete lump sum lines without Resource Type and Quantity = 0
        i = 0;
        while (i < theTMLList.size()) {
            if (theTMLList[i].Category__c == 'Lump Sum' && string.isEmpty(theTMLList[i].Resource_Type__c) &&
                    theTMLList[i].Quantity__c == 0) {
                theTMLList.remove(i);
            } else {
                i++;
            }
        }

        TMsService.addRemoveManifestFeeLines(theTM, theTMLList);
        TMsService.calcRinseOutFeeLine(theTM, theTMLList);

        List<TM_Line__c> delTMLList = new List<TM_Line__c>();

        // Delete lines that are not found in the temporary list
        for (TM_Line__c tmLine : [SELECT Id FROM TM_Line__c WHERE TM__c = :tmId]) {
            Boolean lineFound = false;
            for (TM_Line__c tmLine2 : theTMLList) {
                if (tmLine.Id == tmLine2.Id) {
                    lineFound = true;
                }
            }
            if (lineFound == false) {
                delTMLList.add(tmLine);
            }
        }

        if (!delTMLList.isEmpty()) {

            try {

                delete delTMLList;
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }

        TM__c oldTM = theTM.clone(true);
        List<TM_Line__c> oldTMLList = new List<TM_Line__c>();
        //Ticket#13576 >>
        //Check Labor and Equipment SC before save
        Set<Id> resIdSet = new Set<Id>();
        Set<Id> resTypeIdSet = new Set<Id>();
        Set<Id> serviceCenterIds = new Set<Id>();
        Set<Id> uomIds = new Set<Id>();
        for (TM_Line__c tml : theTMLList) {
            tml.To_Invoice__c = false;

            if(String.isNotBlank(tml.Unit_of_Measure__c)){
                uomIds.add(tml.Unit_of_Measure__c);
            }
            if (tml.Category__c == 'Labor' || tml.Category__c == 'Equipment') {
                if(String.isNotBlank(tml.Resource__c)){
                    resIdSet.add(tml.Resource__c);
                }
                if (String.isNotBlank(tml.Resource_Type__c)) {
                    resTypeIdSet.add(tml.Resource_Type__c);
                }
                if(String.isNotBlank(tml.Service_Center__c)){
                    serviceCenterIds.add(tml.Service_Center__c);
                }
            }
        }

        //Retrieve Res. and put it into ResId Map
        Map<Id, Resource__c> resIdMap = new Map<Id, Resource__c>();
        Map<Id, Resource_Type__c> resourceTypesByIds = new Map<Id, Resource_Type__c>();
        Map<Id, Service_Center__c> serviceCentersByIds = new Map<Id, Service_Center__c>();
        Map<Id, Unit_of_Measure__c> unitOfMeasuresByIds = new Map<Id, Unit_of_Measure__c>();
        resIdMap.putAll(ResourcesSelector.newInstance().selectById(resIdSet));
        serviceCentersByIds.putAll(ServiceCentersSelector.newInstance().selectById(serviceCenterIds));
        resourceTypesByIds.putAll(ResourceTypesSelector.newInstance().selectById(resTypeIdSet));
        unitOfMeasuresByIds.putAll(UnitOfMeasuresSelector.newInstance().selectById(uomIds));
        List<String> errorList = new List<String>();
        //13576 >>
        //Compare all lines SC with Resource SC update TML SC if not match
        for (TM_Line__c tml : theTMLList) {
            if ((tml.Category__c == 'Labor' || tml.Category__c == 'Equipment') && tml.Resource__c != null) {
                Resource__c res = resIdMap.get(tml.Resource__c);
                if (res != null && res.Service_Center__c != null && tml.Service_Center__c != res.Service_Center__c) {
                    tml.Service_Center__c = res.Service_Center__c;
                }
            }

            if(tml.Category__c == 'Waste Disposal' || tml.Category__c == 'Misc. Charges And Taxes'){
                if((String.isNotEmpty(tml.Description__c) == true || CompanyMgmt.zeroIfNull(tml.Quantity__c) != 0) &&
                        String.isBlank(tml.Resource__c)){
                    String fieldName;
                    if(tml.Category__c == 'Waste Disposal') fieldName = 'Waste Disposal';
                    if(tml.Category__c == 'Misc. Charges And Taxes') fieldName = 'Service';
                    errorList.add(fieldName + ' field must not be blank! Line No. ' + tml.Line_No__c);
                }
            }
        }
        //13576 <<

        //Ticket#14554 >>
        if(String.isBlank(theTM.Site_Scope__c)){
            errorList.add('Site Scope field must not be blank!');
        }
        //Ticket#14554 <<

        //Ticket#13576 <<
        // Savepoint
        Savepoint sp = Database.setSavepoint();

        //Display Errors
        if (errorList.size() > 0) {
            for(i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
            }
        } else {
            try {
                TimesheetMgmt tsMgmt = new TimesheetMgmt();
                Set<Id> resIdSet2 = new Set<Id>();
                Set<Id> processedIdSet = new Set<Id>();
                Map<Id, String> resNameMap = new Map<Id, String>();
                Map<String, Map<Time, Time>> resTimeEntries = new Map<String, Map<Time, Time>>();
                for (TM_Line__c tmLine : theTMLList){
                    //Save TML first in case upsert theTM has error
                    oldTMLList.add(tmLine.clone(true));
                }

                for (TM_Line__c tmLine : theTMLList){
                    Service_Center__c serviceCenter;
                    Resource_Type__c resourceType;
                    Unit_of_Measure__c unitOfMeasure;
                    if(String.isNotBlank(tmLine.Unit_of_Measure__c)){
                        unitOfMeasure = unitOfMeasuresByIds.get(tmLine.Unit_of_Measure__c);
                    }

                    if(String.isNotBlank(tmLine.Service_Center__c)){
                        serviceCenter = serviceCentersByIds.get(tmLine.Service_Center__c);
                    }

                    if(String.isNotBlank(tmLine.Resource_Type__c)){
                        resourceType = resourceTypesByIds.get(tmLine.Resource_Type__c);
                    }

                    if(moveToNextStatus == true){
                        if(NextStatus == 'Confirmed'
                                && tmLine.Service_Center__r.Temporary__c != true
                                && (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment')
                                && tmLine.Resource__r.Non_Payroll_Labor_Resource__c == false
                                && !String.isEmpty(tmLine.Resource__c)){
                            resTimeEntries = tsMgmt.updateResTimeEntryMap(resTimeEntries, theTM.Scheduled_Date__c,theTM.Scheduled_Date__c,theTM.Scheduled_Date__c,
                                    tmLine.Job_Start_Time__c, tmLine.Job_End_Time__c, tmLine.Resource__c, resNameMap);
                            resIdSet2.add(tmLine.Resource__c);
                            processedIdSet.add(tmLine.Id);
                        }

                        //Labor data Checking
                        if (String.isNotBlank(tmLine.TM__c) && tmLine.Category__c == 'Labor') {
                            if (NextStatus == 'Confirmed' || NextStatus == 'Received By Billing' || NextStatus == 'Ready to Bill') {
                                if (tmLine.Job_Start_Time__c == null || tmLine.Job_End_Time__c == null || tmLine.Site_Start_Time__c == null || tmLine.Site_End_Time__c == null) {
                                    throw new DataException('Job Start Time, Job End Time, Site Start Time or Site End Time cannot be blank ' + 'when Status is Confirmed or later for T&M: ' + theTM.Name + ' Line No: ' + tmLine.Line_No__c);
                                }
                            }

                            if(NextStatus == 'Confirmed' && (theTM.Status__c == 'Scheduled' || theTM.Status__c == 'Mobile Review')){
                                //if (tmLine.Resource__c == null) {
                                if (String.isBlank(tmLine.Resource__c)) {
                                    throw new DataException('Resource must not be blank when Status is Confirmed for T&M: ' + theTM.Name + ' Line No: ' + tmLine.Line_No__c);
                                }

                                if(tmLine.Lunch_Start_Time__c != null && tmLine.Lunch_End_Time__c != null){
                                    Decimal hours = TimeUtils.calculateHours(tmLine.Lunch_Start_Time__c, tmLine.Lunch_End_Time__c);
                                    System.debug('Info: hours ' + hours);
                                    if(hours != 0.50 && hours != 1.00){
                                        throw new DataException('Lunch time must be half hour or an hour for Line No: ' + tmLine.Line_No__c);
                                    }
                                }
                            }
                        }

                        //Equipment data checking
                        if (String.isNotBlank(tmLine.TM__c) && tmLine.Category__c == 'Equipment' && String.isNotBlank(tmLine.Resource_Type__c)) {
                            if(NextStatus == 'Confirmed' && (theTM.Status__c == 'Scheduled' || theTM.Status__c == 'Mobile Review')){
                                if(String.isBlank(tmLine.Unit_of_Measure__c)){
                                    throw new DataException('Unit of Measure field must not be blank for T&M: ' + theTM.Name + ' Line No.: ' + tmLine.Line_No__c);
                                }

                                if(resourceType.Fleet_No_Required__c == true){
                                    if(String.isNotBlank(tmLine.Service_Center__c) && serviceCenter.Equipment_Fleet_No_Not_Required__c == false && String.isBlank(tmLine.Resource__c)) {
                                        throw new DataException('Equipment field must not be blank for T&M: ' + theTM.Name + ' Line No.: ' + tmLine.Line_No__c);
                                    }

                                    if (tmLine.Job_Start_Time__c == null || tmLine.Job_End_Time__c == null) {
                                        throw new DataException('Job Start Time & Job End Time field must not be blank for T&M: ' + theTM.Name + ' Line No.: ' + tmLine.Line_No__c);
                                    }
                                } else {
                                    if(unitOfMeasure != null && unitOfMeasure.Hours_UOM__c != true && CompanyMgmt.zeroIfNull(tmLine.Quantity__c) == 0){
                                        throw new DataException('Quantity field must not be blank/zero for T&M: ' + theTM.Name + ' Line No.: ' + tmLine.Line_No__c);
                                    }
                                }
                            }
                        }

                        if (NextStatus == 'Ready to Bill' && theTM.Status__c == 'Received by Billing') {
                            if (CompanyMgmt.zeroIfNull(tmLine.Quantity__c) == 0 || tmLine.Unit_Price__c == null || tmLine.Line_Amount__c == null) {
                                throw (Exception) new DataException('Please review T&M ' + theTM.Name + ' Line No. ' + tmLine.Line_No__c
                                        + ' : Quantity, Unit Price and Line Amount field must have a value');
                            }

                            if(String.isBlank(tmLine.Unit_of_Measure__c)){
                                throw (Exception) new DataException('Please review T&M ' + theTM.Name + ' Line No. ' + tmLine.Line_No__c
                                        + ' : Unit of Measure field must have a value');
                            }

                            if ((tmLine.Bill_as_Lump_Sum__c == true || tmLine.Non_Billable__c == true) && (CompanyMgmt.zeroIfNull(tmLine.Line_Amount__c) != 0 || CompanyMgmt.zeroIfNull(tmline.Line_Amt_Incl_Tax__c) != 0)) {
                                throw (Exception) new DataException('Please review T&M ' + theTM.Name + ' Line No. ' + tmLine.Line_No__c
                                        + ' : Line Amount must be Zero for Bundled or Non Billable line');
                            }

                            if ((tmLine.Bill_as_Lump_Sum__c == true || tmLine.Non_Billable__c == true) &&
                                    (CompanyMgmt.zeroIfNull(tmLine.Regular_Rate__c) != 0 ||
                                            CompanyMgmt.zeroIfNull(tmLine.Premium_Rate__c) != 0 ||
                                            CompanyMgmt.zeroIfNull(tmLine.Overtime_Rate__c) != 0) &&
                                    tmLine.Category__c == 'Labor') {
                                throw (Exception) new DataException('Please review T&M ' + theTM.Name + ' Line No. ' + tmLine.Line_No__c
                                        + ' : all rates must be Zero for Bundled or Non Billable line');
                            }

                            if(String.isBlank(tmLine.Resource__c)){
                                if(tmLine.Category__c == 'Equipment'){
                                    if(resourceType.Fleet_No_Required__c == true) {
                                        if (String.isNotBlank(tmLine.Service_Center__c) && serviceCenter.Equipment_Fleet_No_Not_Required__c == false && String.isBlank(tmLine.Resource__c)) {
                                            throw new DataException('Equipment field must not be blank for T&M: ' + theTM.Name + ' Line No.: ' + tmLine.Line_No__c);
                                        }
                                    }
                                } else {
                                    throw new DataException('Resource must not be blank for T&M: ' + theTM.Name + ' Line No: ' + tmLine.Line_No__c);
                                }
                            }

                            if(tmLine.Category__c == 'Labor' && (tmLine.Job_Start_Time__c == null || tmLine.Job_End_Time__c == null || tmLine.Site_Start_Time__c == null || tmLine.Site_End_Time__c == null)) {
                                throw new DataException('Job Start Time, Job End Time, Site Start Time or Site End Time cannot be blank ' + 'when Status is Confirmed or later for T&M: ' + theTM.Name + ' Line No: ' + tmLine.Line_No__c);
                            }
                        }
                    } else {
                        if (tmLine.Category__c == 'Labor' && (theTM.Status__c == 'Confirmed' || theTM.Status__c == 'Received By Billing' || theTM.Status__c == 'Ready to Bill')) {
                            if (tmLine.Job_Start_Time__c == null || tmLine.Job_End_Time__c == null || tmLine.Site_Start_Time__c == null || tmLine.Site_End_Time__c == null) {
                                throw new DataException('Job Start Time, Job End Time, Site Start Time or Site End Time cannot be blank ' + 'when Status is Confirmed or later for T&M: ' + theTM.Name + ' Line No: ' + tmLine.Line_No__c);
                            }
                        }

                        if(tmLine.Category__c == 'Waste Disposal') {
                            if (theTM.Status__c == 'Ready to Bill' || (moveToNextStatus == true && theTM.Status__c == 'Received By Billing' && NextStatus == 'Ready to Bill')) {
                                if (CompanyMgmt.zeroIfNull(tmLine.Unit_Cost__c) == 0) {
                                    throw new DataException('Unit cost must be greater than zero for T&M: ' + theTM.Name + ' Line No: ' + tmLine.Line_No__c);
                                }
                            }
                        }
                    }
                }


                if (resIdSet2.size() > 0 && resTimeEntries.size() > 0) {
                    tsMgmt.checkTimeEntryOverlap(resIdSet2, resTimeEntries, theTM.Scheduled_Date__c, theTM.Scheduled_Date__c, processedIdSet);
                }

                Boolean isBillingRuleNeeded = theTM.Sales_Order__r.Billing_Rule_Not_Required__c; //Billing Rule not required modification

                theTM = TMMgmt.validateCreateSiteAddress(theTM);
                theTM = TMMgmt.nullRelationshipFields(theTM);
                upsert theTM;


                //Billing Rule not required modification
                if(isBillingRuleNeeded == true){
                    theTM.Sales_Order__r = new Sales_Order__c(Billing_Rule_Not_Required__c = true);
                }

                for (TM_Line__c TML : theTMLList) {
                    if(TML.Invoiced__c != true){
                        if (String.isBlank(tmId)) {
                            TML.TM__c = theTM.Id;
                        }

                        if(TML.Category__c == 'Labor'){
                            if(theTM.Status__c == 'Mobile Review' && (TML.Billing_Start_Time__c == null || TML.Billing_End_Time__c == null)){
                                TMMgmt.populateBillingTimeInfo(TML, theTM);
                            }
                        }

                        TML = TMMgmt.updateTML(TML, theTM, 'TimeValidation');
                        TML.Cost_Qty__c = TMMgmt.calculateCostQy(TML);
                        TML.Resource_Type__r = null;
                        TML.Resource__r = null;

                        if(TML.Category__c == 'Labor' && TML.Bill_as_Lump_Sum__c != true && TML.Non_Billable__c != true){
                            TML = TMMgmt.calculateUnitPrice(TML);
                            //re-calculate amount fields
                            TML = TMMgmt.updateTML(TML, theTM, '');
                        }

                        if(theTM.Status__c == 'Confirmed' && TML.Category__c == 'Labor' && String.isNotBlank(TML.Unit_of_Measure__c)){
                            if(unitOfMeasuresByIds.containsKey(TML.Unit_of_Measure__c)){
                                Unit_of_Measure__c uom = unitOfMeasuresByIds.get(TML.Unit_of_Measure__c);
                                if(uom.Hours_UOM__c != true){
                                    TML.Quantity__c = 1;
                                }
                            }
                        }

                        if(TML.Category__c == 'Lump Sum' && TML.Resource__c == null){
                            TML.Resource__c = theCompanySetup.Default_Lump_Sum_Resource__c;
                        }
                    }

                }

                upsert theTMLList;

                if (moveToNextStatus) {
                    theTM.Status__c = NextStatus;
                    if (theTM.Status__c == 'Confirmed') {
                        TMLLinesService.initStaticVariables(new Map<TM__c, List<TM_Line__c>>{theTM => theTMLList});
                        for(TM_Line__c tmLine : theTMLList){
                            TMLLinesService.calcUnitPrice(theTM, tmLine);
                            TMLLinesService.calcUnitCost(theTM, tmLine);
                        }
                        TMLLinesService.calcTotals(new Map<TM__c, List<TM_Line__c>>{theTM => theTMLList});

                        TMMgmt.applyBillingRules(theTMLList, new Map<Id, TM__c>{
                                theTM.Id => theTM
                        }); //W00028
                        upsert theTMLList; //W00028
                    }
                    theTM = TMMgmt.nullRelationshipFields(theTM);
                    upsert theTM;
                }
                //Ticket# 13811 >>
                //Current TM inclunded in SOQL, must save on "partially invoiced" otherwise one step further error, have to confirm with Steven
                //if (theTM.Sales_Order__c != originSOId && theUser.Super_User__c){
                if (theTM.Sales_Order__c != originSOId){
                    List<Sales_Invoice__c> salesInvoices = [SELECT Id, Name, (SELECT Id, Name, Sales_Invoice__c,Total_Lines__c, Invoiced_Lines__c FROM T_Ms__r)
                            FROM Sales_Invoice__c
                            WHERE Document_Status__c = 'Open'
                            AND Id = :theTM.Sales_Invoice__c
                                                            AND Credit_Memo__c = FALSE LIMIT 1];

                    if (salesInvoices.size() > 0) {
                        Sales_Invoice__c salesInvoice = salesInvoices.get(0);
                        List<TM__c> theTMList = salesInvoice.T_Ms__r;
                        Set<Id> setTM = new Set<Id>();
                        for (TM__c theTM : theTMList) {
                            setTM.add(theTM.Id);
                        }
                        List<TM_Line__c> theTMLList = [SELECT Id, Name, Invoiced__c FROM TM_Line__c WHERE TM__c in :setTM];
                        if (theTMLList != null && theTMLList.size() > 0){
                            for (TM_Line__c TML : theTMLList) {
                                TML.Invoiced__c = false;
                            }
                            upsert theTMLList;
                        }
                        if (theTMList != null && theTMList.size() > 0) {
                            //theTMList = TMMgmt.updateTMStatus(theTMList);
                            for(TM__c theTM : theTMList) {
                                theTM.Sales_Invoice__c = null;
                                theTM.Status__c = 'Ready to Bill';
                            }
                            update theTMList;
                        }
                        delete salesInvoice;
                    }
                }
                //Ticket# 13811 >>
            } catch (Exception e) {
                Database.rollback(sp);
                theTM = oldTM;
                theTMLList = oldTMLList;
                System.debug('Error: ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));

            }
        }
         */
    }

    //Depreciated
    public PageReference saveAndChangeStatus() {
        return null;
        /*
        moveToNextStatus = true;
        msave();
        //theTM.Status__c = NextStatus;
        if (!ApexPages.hasMessages()) {
            PageReference TMPage = new PageReference('/' + theTM.Id);
            TMPage.setRedirect(true);
            return TMPage;
        } else{
            return null;
        }
        //return save();
         */
    }

    public PageReference save() {
        return null;
        /*
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference TMPage = new PageReference('/' + theTM.Id);
            TMPage.setRedirect(true);
            return TMPage;
        } else return null;
         */
    }

    public PageReference editSave() {
        return null;
        /*
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference redirectPage = new PageReference('/apex/DailyRoster?scheduledDate=' + scheduledDate);redirectPage.setRedirect(true); return redirectPage;
        } else return null;
         */
    }

    public PageReference quickSave() {
        return null;
        /*
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference TMPage = new PageReference('/apex/TM?id=' + theTM.Id);TMPage.setRedirect(true);return TMPage;
        } else return null;
         */
    }

    public PageReference quickSave2() {
        return null;
        /*
        msave();
        if (!ApexPages.hasMessages()) {
            PageReference TM2Page = new PageReference('/apex/TM2?id=' + theTM.Id);
            TM2Page.setRedirect(true);
            return TM2Page;
        } else return null;
         */
    }

    public PageReference editQuickSave() {
        return null;
        /*
        msave();
        if (!ApexPages.hasMessages()) {
            //PageReference EditItemsToTMPage = new PageReference('/apex/EditTMLines?Category=Labor&Id=' + theTM.Id + '&scheduledDate=' + scheduledDateValue);
            PageReference EditItemsToTMPage = new PageReference('/apex/TM?Category=Labor&Id=' + theTM.Id + '&scheduledDate=' + scheduledDateValue);
            EditItemsToTMPage.setRedirect(true); return EditItemsToTMPage;

        } else return null;
         */
    }

    public PageReference editCancel() {
        return null;
        /*
        //return theController.cancel();
        PageReference redirectPage = new PageReference('/apex/DailyRoster?scheduledDate=' + scheduledDate);
        redirectPage.setRedirect(true);
        return redirectPage;
         */
    }

    public PageReference cancel() {
        return theController.cancel();
    }

    public PageReference returnBack() {
        return theController.view();
    }

    //Depreciated
    public PageReference addLine() {
        /*
        if (theTMLList == null) theTMLList = new List<TM_Line__c>();
        integer tmLineListSize = theTMLList.size();
        boolean billSiteTime = false;
        string description = '';
        Id resource = null;
        Resource__c theResource;
        Unit_of_Measure__c theUnitOfMeasure;
        integer LinesToInsert = integer.valueof(theCompanySetup.Lines_to_Insert__c);
        //integer LinesToInsert = 5;
        decimal displayNo = 0;
        decimal unitCost = 0;

        if (theTMLList != null && theTMLList.size() > 0) {
            if (theTMLList[tmLineListSize - 1].Line_No__c != null) {
                displayNo = theTMLList[tmLineListSize - 1].Line_No__c;
            }
        }
        String objectType = ApexPages.CurrentPage().getParameters().get('ObjectType');
        String lineCategory = ApexPages.CurrentPage().getParameters().get('LineCategory');

        Service_Center__c theServiceCenter;
        theServiceCenter = [
                SELECT Id, Name, Temporary__c
                FROM Service_Center__c
                WHERE Id = :theTM.Service_Center__c
                LIMIT 1
        ];
        //Ticket# 13874 >>
        if (lineCategory == 'TempLabor' || lineCategory == 'TempEquipment') {
            lineCategory = lineCategory.replace('Temp','');
            theServiceCenter = [SELECT Id, Name, Temporary__c FROM Service_Center__c WHERE Temporary__c = TRUE LIMIT 1];
        }
        //Ticket# 13874 <<

        if (lineCategory == 'Lump Sum') {
            resource = theCompanySetup.Default_Lump_Sum_Resource__c;
            description = theCompanySetup.Default_Lump_Sum_Resource__r.Name;
            LinesToInsert = 5;
            unitCost = companyMgmt.zeroIfNull(theCompanySetup.Default_Lump_Sum_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Misc. Charges And Taxes') {
            resource = theCompanySetup.Default_Misc_Charges_Taxes_Resource__c;
            description = theCompanySetup.Default_Misc_Charges_Taxes_Resource__r.Name;
            LinesToInsert = 1;
            unitCost = companyMgmt.zeroIfNull(theCompanySetup.Default_Misc_Charges_Taxes_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Subcontractors') {
            resource = theCompanySetup.Default_Subcontractor_Resource__c;
            //description = theCompanySetup.Default_Subcontractor_Resource__r.Name;
            LinesToInsert = 5;
            unitCost = companyMgmt.zeroIfNull(theCompanySetup.Default_Subcontractor_Resource__r.Unit_Cost__c);
        } else if (lineCategory == 'Demurrage') {
            description = '';
            LinesToInsert = 1;
        } else if (lineCategory == 'Labor') {
            billSiteTime = false;  // default bill job time
        }


        if (objectType == 'TMLine') {
            if (LinesToInsert > 0) {
                for (Integer i = 0; i < LinesToInsert; i++) {
                    displayNo = displayNo + 1;
                    if (lineCategory != 'Labor' && lineCategory != 'Equipment' && lineCategory != 'Materials' && lineCategory != 'Demurrage' && lineCategory != 'Waste Disposal') {
                        theResource = [SELECT Id, Name, Unit_of_Measure__c FROM Resource__c WHERE Id = :resource LIMIT 1];
                        if (theResource.Unit_of_Measure__c != null) {
                            theUnitOfMeasure = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Id = :theResource.Unit_of_Measure__c LIMIT 1];
                            theTMLList.add(new TM_Line__c(TM__c = tmId, Line_No__c = displayNo,
                                    Category__c = lineCategory, Resource__c = resource, Description__c = description, Tax_Group__c = 'TX',
                                    Service_Center__c = theTM.Service_Center__c, Bill_Site_Time__c = billSiteTime,
                                    Unit_of_Measure__c = theResource.Unit_of_Measure__c,
                                    Unit_of_Measure__r = new Unit_of_Measure__c(Id = theUnitOfMeasure.Id, Name = theUnitOfMeasure.Name),
                                    Service_Center__r = new Service_Center__c(Id = theServiceCenter.Id, Name = theServiceCenter.Name),
                                    Quantity__c = 0, Regular_Hours__c = 0, Regular_Rate__c = 0, Overtime_Hours__c = 0, Overtime_Rate__c = 0, Unit_Price__c = 0,
                                    Unit_Cost__c = unitCost));
                        } else {
                            theTMLList.add(new TM_Line__c(TM__c = tmId, Line_No__c = displayNo,
                                    Category__c = lineCategory, Resource__c = resource, Description__c = description, Tax_Group__c = 'TX',
                                    Service_Center__c = theTM.Service_Center__c, Bill_Site_Time__c = billSiteTime,
                                    Service_Center__r = new Service_Center__c(Id = theServiceCenter.Id, Name = theServiceCenter.Name),
                                    Quantity__c = 0, Regular_Hours__c = 0, Regular_Rate__c = 0, Overtime_Hours__c = 0, Overtime_Rate__c = 0, Unit_Price__c = 0,
                                    Unit_Cost__c = unitCost));
                        }
                    } else { //Ticket# 13874 >>
                        theTMLList.add(new TM_Line__c(TM__c = tmId, Line_No__c = displayNo, Include_Lunch_Y_N__c = true,
                                Category__c = lineCategory, Resource__c = resource, Description__c = description, Tax_Group__c = 'TX',
                                Service_Center__c = theServiceCenter.Id, Bill_Site_Time__c = billSiteTime,
                                Service_Center__r = new Service_Center__c(Id = theServiceCenter.Id, Name = theServiceCenter.Name, Temporary__c = theServiceCenter.Temporary__c),
                                Quantity__c = 0, Regular_Hours__c = 0, Regular_Rate__c = 0, Overtime_Hours__c = 0, Overtime_Rate__c = 0, Unit_Price__c = 0,
                                Unit_Cost__c = unitCost));
                    }
                }
            }
        }
         */
        return null;
    }

    //Depreciated
    public PageReference deleteLine() {
        /*
        String objectType = ApexPages.CurrentPage().getParameters().get('objectType');
        String displayId = ApexPages.CurrentPage().getParameters().get('displayId');
        String lineType = ApexPages.CurrentPage().getParameters().get('lineType');

        if (displayId == '') displayId = '0';

        if (objectType == 'TMLine') {
            for (Integer i = 0; i < theTMLList.size(); i++) {
                if (companyMgmt.zeroIfNull(theTMLList[i].Line_No__c) == decimal.valueOf(displayId) && theTMLList[i].Category__c == lineType) {
                    theTMLList.remove(i);break;
                }
            }
        }
         */
        return null;
    }

    //Depreciated
    public PageReference copyTime() {
        /*
        String objectType = ApexPages.CurrentPage().getParameters().get('objectType');
        String displayId = ApexPages.CurrentPage().getParameters().get('displayId');
        String lineType = ApexPages.CurrentPage().getParameters().get('lineType');
        String timeType = ApexPages.currentPage().getParameters().get('timeType'); //Ticket#13673 - copy billing time

        TM_Line__c TML = new TM_Line__c();

        if (displayId == '') displayId = '0';

        if (objectType == 'TMLine') {
            for (Integer i = 0; i < theTMLList.size(); i++) {
                if ((test.isrunningtest()) || (companyMgmt.zeroIfNull(theTMLList[i].Line_No__c) == decimal.valueOf(displayId)
                        && theTMLList[i].Category__c == lineType)) {
                    TML = theTMLList[i]; break;

                }
            }
        }

        if (TML != null) {
            if (TML.Job_Start_Time__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Job Start Time cannot be blank'));return null;
            }

            if (TML.Job_End_Time__c == null) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Job End Time cannot be blank')); return null;
            }


            if (timeType == 'BillingTime') {
                //Ticket#13673 - copy billing time
                if (TML.Billing_Start_Time__c == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Billing Start Time cannot be blank'));
                    return null;
                }

                if (TML.Billing_End_Time__c == null) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Billing End Time cannot be blank'));
                    return null;
                }
            } else {
                if (TML.Category__c == 'Labor') {
                    if (TML.Site_Start_Time__c == null) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Site Start Time cannot be blank')); return null;
                    }

                    if (TML.Site_End_Time__c == null) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Site End Time cannot be blank')); return null;
                    }

                    if (TML.Lunch_Start_Time__c == null && TML.Lunch__c != 'No') {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Lunch Start Time cannot be blank'));return null;

                    }

                    if (TML.Lunch_End_Time__c == null && TML.Lunch__c != 'No') {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Lunch End Time cannot be blank'));return null;
                    }
                }
            }
        }

        try {
            for (TM_Line__c theTML : theTMLList) {
                if (theTML.Category__c == lineType) {
                    //Ticket 13474 >>
                    if (theTML.Line_No__c > Decimal.valueOf(displayId)) {
                        //Ticket#13673 - copy billing time
                        if (timeType == 'BillingTime') {
                            theTML.Billing_Start_Time__c = TML.Billing_Start_Time__c;
                            theTML.Billing_End_Time__c = TML.Billing_End_Time__c;
                            theTML = TMMgmt.updateTML(theTML, theTM, 'theBillingStartTime');
                            if (theTML.Category__c == 'Labor') {
                                theTML.Regular_Hours__c = TML.Regular_Hours__c;
                                theTML.Overtime_Hours__c = TML.Overtime_Hours__c;
                                theTML.Premium_Hours__c = TML.Premium_Hours__c;
                                theTML = TMMgmt.updateTML(theTML, theTM, 'theRegularHour');
                            }
                        } else {
                            theTML.Job_Start_Time__c = TML.Job_Start_Time__c;
                            //theTML = TMMgmt.updateTML(theTML, theTM, 'theJobStartTime');
                            theTML.Job_End_Time__c = TML.Job_End_Time__c;
                            if (lineType == 'Labor') {
                                theTML.Site_Start_Time__c = TML.Site_Start_Time__c;
                                //theTML = TMMgmt.updateTML(theTML, theTM, 'theSiteStartTime');
                                theTML.Site_End_Time__c = TML.Site_End_Time__c;
                                //theTML = TMMgmt.updateTML(theTML, theTM, 'theSiteEndTime');
                                theTML.Lunch_Start_Time__c = TML.Lunch_Start_Time__c;
                                //theTML = TMMgmt.updateTML(theTML, theTM, 'theLunchStartTime');
                                theTML.Lunch_End_Time__c = TML.Lunch_End_Time__c;
                                //theTML = TMMgmt.updateTML(theTML, theTM, 'theLunchEndTime');
                            }
                            theTML = TMMgmt.updateTML(theTML, theTM, 'theJobEndTime');
                        }
                    }
                }
            }
        } catch (exception e) {
            System.debug('ERROR: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            return null;
        }
         */
        return null;
    }

    //Depreciated
    public PageReference validateField() {
        /*
        setFieldNameCategoryMap(); //Ticket#13673

        String fieldName = ApexPages.currentPage().getParameters().get('fieldName');
        Integer i = Integer.valueOf(ApexPages.currentPage().getParameters().get('lineNo'));
        String newFieldValue = ApexPages.currentPage().getParameters().get('newFieldValue');
        String Category = '';

        if (fieldName == 'theJobPosition') {
            if (String.isBlank(newFieldValue)) {
                theTMLListLabor[i].Resource_Type__c = null;
                theTMLListLabor[i].Resource_Type__r = null;
                theTMLListLabor[i].Description__c = '';
                Decimal lineNo = theTMLListLabor[i].Line_No__c;
                theTMLListLabor[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListLabor[i].Resource_Type__c = newFieldValue;
                    theTMLListLabor[i].Quantity__c = 0;
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theJobPosition');
                    //TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListLabor[i]}});
                    //TMLLinesService.validateResourceType(theTM, theTMLListLabor[i]);
                } catch (Exception e) {
                    System.debug('ERROR: ' + e.getStackTraceString());
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                    return null;
                }
            }
            Category = 'Labor';
        } else if (fieldName == 'theServiceCenter') {
            if (String.isBlank(newFieldValue)) {
                //13576
                theTMLListLabor[i].Resource__c = null;
                theTMLListLabor[i].Resource__r = null;
                theTMLListLabor[i].Service_Center__c = null;
                theTMLListLabor[i].Service_Center__r = null;
                Decimal lineNo = theTMLListLabor[i].Line_No__c;
                theTMLListLabor[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
                //13576
            } else {
                try {
                    //Ticket# 13874 >>
                    if (afterConfirmed) {
                        if (!isTempSCChecked) {
                            tempServiceCenters = new Map<Id, Service_Center__c> ([SELECT Id, Name, Temporary__c FROM Service_Center__c WHERE Temporary__c = TRUE]);
                            isTempSCChecked = true;
                        }
                        if(!tempServiceCenters.containsKey(newFieldValue)){
                            theTMLListLabor[i].Service_Center__c = tempServiceCenters.values()[0].Id;
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only temporary resource are allowed after T&M is confirmed'));
                            return null;
                        }
                    }
                    //Ticket# 13874 >>
                    theTMLListLabor[i].Service_Center__c = newFieldValue;
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theServiceCenter');
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Labor';
        } else if (fieldName == 'theEquipment') {
            if (String.isBlank(newFieldValue)) {
                theTMLListEquipment[i].Resource_Type__c = null;
                theTMLListEquipment[i].Resource_Type__r = null;
                theTMLListEquipment[i].Description__c = '';
                Decimal lineNo = theTMLListEquipment[i].Line_No__c;
                theTMLListEquipment[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListEquipment[i].Resource_Type__c = newFieldValue;
                    theTMLListEquipment[i].Quantity__c = 0;
                    theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theEquipment');
                    //TMLLinesService.validateResourceType(theTM, theTMLListEquipment[i]);
                    //TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListEquipment[i]}});

                } catch (Exception e) {
                    System.debug('ERROR ' + e.getStackTraceString());
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                    return null;
                }
            }
            Category = 'Equipment';
        } else if (fieldName == 'theLumpSumResourceType') {
            if (String.isBlank(newFieldValue)) {
                theTMLListLumpSum[i].Resource_Type__c = null;
                theTMLListLumpSum[i].Resource_Type__r = null;
                theTMLListLumpSum[i].Description__c = '';
                Decimal lineNo = theTMLListLumpSum[i].Line_No__c;
                theTMLListLumpSum[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListLumpSum[i].Resource_Type__c = newFieldValue;
                    theTMLListLumpSum[i].Quantity__c = 0;
                    theTMLListLumpSum[i] = TMMgmt.updateTML(theTMLListLumpSum[i], theTM, 'theLumpSumResourceType');
                    TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListLumpSum[i]}});

                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Lump Sum';
        } else if (fieldName == 'theEServiceCenter') {
            if (String.isBlank(newFieldValue)) {
                //13576
                theTMLListEquipment[i].Resource__c = null;
                theTMLListEquipment[i].Resource__r = null;
                theTMLListEquipment[i].Service_Center__c = null;
                theTMLListEquipment[i].Service_Center__r = null;
                Decimal lineNo = theTMLListEquipment[i].Line_No__c;
                theTMLListEquipment[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
                //13576
            } else {
                try {
                    //Ticket# 13874 >>
                    if (afterConfirmed) {
                        if (!isTempSCChecked) {
                            tempServiceCenters = new Map<Id, Service_Center__c> ([SELECT Id, Name, Temporary__c FROM Service_Center__c WHERE Temporary__c = TRUE]);
                            isTempSCChecked = true;
                        }
                        if(!tempServiceCenters.containsKey(newFieldValue)){
                            theTMLListEquipment[i].Service_Center__c = tempServiceCenters.values()[0].Id;
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only temporary resource are allowed after T&M is confirmed'));
                            return null;
                        }
                    }
                    //Ticket# 13874 >>
                    theTMLListEquipment[i].Service_Center__c = newFieldValue;
                    theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theServiceCenter');
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Equipment';
        } else if (fieldName == 'theMResource') {
            if (String.isBlank(newFieldValue)) {
                theTMLListMaterials[i].Resource__c = null;
                theTMLListMaterials[i].Resource__r = null;
                theTMLListMaterials[i].Description__c = '';
                Decimal lineNo = theTMLListMaterials[i].Line_No__c;
                theTMLListMaterials[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListMaterials[i].Resource__c = newFieldValue;
                    theTMLListMaterials[i].Quantity__c = 0;
                    //theTMLListMaterials[i] = TMMgmt.updateTML(theTMLListMaterials[i], theTM, 'theResource');
                    //TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListMaterials[i]}});
                    TMLLinesService.validateResource(theTM, theTMLListMaterials[i]);
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Materials';
        } else if (fieldName == 'theLResource') {
            if (String.isBlank(newFieldValue)) {
                theTMLListLabor[i].Resource__c = null;
                theTMLListLabor[i].Resource__r = null;
                theTMLListLabor[i].Resource_Name__c = '';
                Decimal lineNo = theTMLListLabor[i].Line_No__c;
                theTMLListLabor[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListLabor[i].Resource__c = newFieldValue;
                    theTMLListLabor[i].Quantity__c = 0;
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theLResource');
                    //new cost
                    TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListLabor[i]}});
                } catch (exception e) {
                    theTMLListLabor[i].Resource__c = null;
                    theTMLListLabor[i].Resource__r = null;
                    theTMLListLabor[i].Resource_Name__c = '';
                    System.debug('Error: ' + e.getStackTraceString());
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                    return null;
                }
            }
            Category = 'Labor';
        } else if (fieldName == 'theEResource') {
            if (String.isBlank(newFieldValue)) {
                theTMLListEquipment[i].Resource__c = null;
                theTMLListEquipment[i].Resource__r = null;
                theTMLListEquipment[i].Resource_Name__c = '';
                Decimal lineNo = theTMLListEquipment[i].Line_No__c;
                theTMLListEquipment[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListEquipment[i].Resource__c = newFieldValue;
                    theTMLListEquipment[i].Quantity__c = 0;
                    theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theEResource');
                    TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListEquipment[i]}});
                } catch (exception e) {
                    theTMLListEquipment[i].Resource__c = null;
                    theTMLListEquipment[i].Resource__r = null;
                    theTMLListEquipment[i].Resource_Name__c = '';
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                    return null;
                }
            }
            Category = 'Equipment';
        } else if (fieldName == 'theSResource') {

        } else if (fieldName == 'theWResource') {
            //Ticket#13594
            if (String.isBlank(newFieldValue)) {
                theTMLListWasteDisposal[i].Resource__c = null;
                theTMLListWasteDisposal[i].Resource__r = null;
                Decimal lineNo = theTMLListWasteDisposal[i].Line_No__c;
                theTMLListWasteDisposal[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    List<Resource__c> resources = ResourcesSelector.newInstance().selectById(new Set<Id>{newFieldValue});
                    if(resources.size() > 0){
                        theTMLListWasteDisposal[i].Resource__c = newFieldValue;
                        theTMLListWasteDisposal[i].Quantity__c = 0;
                        theTMLListWasteDisposal[i] = TMMgmt.updateTML(theTMLListWasteDisposal[i], theTM, 'theResource');
                        TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListWasteDisposal[i]}});
                        TMsService.addRemoveManifestFeeLines(theTM, theTMLListWasteDisposal);
                        theTMLListWasteDisposal[i].Resource__r = resources[0];
                        System.debug('Info: theTMLListWasteDisposal[i].Resource__r  ' + theTMLListWasteDisposal[i].Resource__r.Has_Container__c + ' --- ' + theTMLListWasteDisposal[i].Resource__r.Has_Weight_Volume__c);
                    }
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Waste Disposal';
        } else if (fieldName == 'theDResource') {
            if (String.isBlank(newFieldValue)) {
                theTMLListDemurrage[i].Resource__c = null;
                theTMLListDemurrage[i].Resource__r = null;
                Decimal lineNo = theTMLListDemurrage[i].Line_No__c;
                theTMLListDemurrage[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListDemurrage[i].Resource__c = newFieldValue;
                    theTMLListDemurrage[i].Quantity__c = 0;
                    theTMLListDemurrage[i] = TMMgmt.updateTML(theTMLListDemurrage[i], theTM, 'theResource');

                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
                Category = 'Demurrage';
            }
        } else if (fieldName == 'theMiscResource') { //AES-388
            if (String.isBlank(newFieldValue)) {
                theTMLListMisc[i].Resource__c = null;
                theTMLListMisc[i].Resource__r = null;
                Decimal lineNo = theTMLListMisc[i].Line_No__c;
                theTMLListMisc[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListMisc[i].Resource__c = newFieldValue;
                    theTMLListMisc[i].Quantity__c = 0;
                    theTMLListMisc[i] = TMMgmt.updateTML(theTMLListMisc[i], theTM, 'theResource');
                } catch (Exception e) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theLUOM') {
            //theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theUOM');
            if (String.isBlank(newFieldValue)) {
                theTMLListLabor[i].Unit_of_Measure__c = null;
                theTMLListLabor[i].Unit_of_Measure__r = null;
                theTMLListLabor[i].Resource_Type_UOM__c = null;
                theTMLListLabor[i].Resource_Type_UOM__r = null;
            } else {
                List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                        ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeIdByUOMId(theTMLListLabor[i].Resource_Type__c, newFieldValue);

                if(resourceTypeUOMAssociations.size() > 0){
                    //SOListLaborLines[i].Unit_of_Measure__c = newFieldValue;
                    theTMLListLabor[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id=resourceTypeUOMAssociations[0].Unit_of_Measure__c,
                            Name=resourceTypeUOMAssociations[0].Unit_of_Measure__r.Name,
                            Hours_UOM__c=resourceTypeUOMAssociations[0].Unit_of_Measure__r.Hours_UOM__c);
                    theTMLListLabor[i].Unit_of_Measure__c = resourceTypeUOMAssociations[0].Unit_of_Measure__c;
                    theTMLListLabor[i].Resource_Type_UOM__c = resourceTypeUOMAssociations[0].Id;
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theUOM');
                    TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListLabor[i]}});
                } else {
                    theTMLListLabor[i].Unit_of_Measure__c = null;
                    theTMLListLabor[i].Resource_Type_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            //system.debug('theTMLListLabor[i].Unit_of_Measure__c***' + theTMLListLabor[i].Unit_of_Measure__c);
            Category = 'Labor';
        } else if (fieldName == 'theMUOM') {
            if (String.isBlank(newFieldValue)) {
                theTMLListMaterials[i].Unit_of_Measure__c = null;
                theTMLListMaterials[i].Unit_of_Measure__r = null;
                theTMLListMaterials[i].Resource_UOM__c = null;
                theTMLListMaterials[i].Resource_UOM__r = null;
            } else {
                List<ResourceUOMAssociation__c> resourceUOMAssociations =
                        ResourceUnitOfMeasuresSelector.newInstance().selectByResByUOM(theTMLListMaterials[i].Resource__c, newFieldValue);

                if (resourceUOMAssociations.size() > 0) {
                    //SOListLaborLines[i].Unit_of_Measure__c = newFieldValue;
                    theTMLListMaterials[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id = resourceUOMAssociations[0].Unit_of_Measure__c, Name = resourceUOMAssociations[0].Unit_of_Measure__r.Name);
                    theTMLListMaterials[i].Unit_of_Measure__c = resourceUOMAssociations[0].Unit_of_Measure__c;
                    theTMLListMaterials[i].Resource_UOM__c = resourceUOMAssociations[0].Id;
                    theTMLListMaterials[i] = TMMgmt.updateTML(theTMLListMaterials[i], theTM, 'theUOM');
                    TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{
                            theTM => new List<TM_Line__c>{
                                    theTMLListMaterials[i]
                            }
                    });
                } else {
                    theTMLListMaterials[i].Unit_of_Measure__c = null;
                    theTMLListMaterials[i].Resource_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            //theTMLListMaterials[i] = TMMgmt.updateTML(theTMLListMaterials[i], theTM, 'theUOM');
            Category = 'Materials';
        } else if (fieldName == 'theEUOM') {
            if (String.isBlank(newFieldValue)) {
                theTMLListEquipment[i].Unit_of_Measure__c = null;
                theTMLListEquipment[i].Unit_of_Measure__r = null;
                theTMLListEquipment[i].Resource_Type_UOM__c = null;
                theTMLListEquipment[i].Resource_Type_UOM__r = null;
            } else {
                List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                        ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeIdByUOMId(theTMLListEquipment[i].Resource_Type__c, newFieldValue);

                if(resourceTypeUOMAssociations.size() > 0){
                    theTMLListEquipment[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id=resourceTypeUOMAssociations[0].Unit_of_Measure__c, Name=resourceTypeUOMAssociations[0].Unit_of_Measure__r.Name);
                    theTMLListEquipment[i].Unit_of_Measure__c = resourceTypeUOMAssociations[0].Unit_of_Measure__c;
                    theTMLListEquipment[i].Resource_Type_UOM__c = resourceTypeUOMAssociations[0].Id;
                    theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theUOM');
                    TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListEquipment[i]}});
                } else {
                    theTMLListEquipment[i].Unit_of_Measure__c = null;
                    theTMLListEquipment[i].Resource_Type_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            Category = 'Equipment';
        } else if (fieldName == 'theSUOM') {
            if (String.isBlank(newFieldValue)) {
                theTMLListSubcontractors[i].Unit_of_Measure__c = null;
                theTMLListSubcontractors[i].Unit_of_Measure__r = null;
            } else {
                set<Id> setUOM = new set<Id>();
                if (!string.isEmpty(theTMLListSubcontractors[i].Resource__c)) {
                    Resource__c theResource = CompanyMgmt.getResource(theTMLListSubcontractors[i].Resource__c);
                }

                theTMLListSubcontractors[i].Unit_of_Measure__c = newFieldValue;
                theTMLListSubcontractors[i] = TMMgmt.updateTML(theTMLListSubcontractors[i], theTM, 'theUOM');
            }
            Category = 'Subcontractors';
        } else if (fieldName == 'theWUOM') {
            if (String.isBlank(newFieldValue)) {
                theTMLListWasteDisposal[i].Unit_of_Measure__c = null;
                theTMLListWasteDisposal[i].Unit_of_Measure__r = null;
                theTMLListWasteDisposal[i].Resource_UOM__c = null;
                theTMLListWasteDisposal[i].Resource_UOM__r = null;
            } else {
                List<ResourceUOMAssociation__c> resourceUOMAssociations =
                        ResourceUnitOfMeasuresSelector.newInstance().selectByResByUOM(theTMLListWasteDisposal[i].Resource__c, newFieldValue);

                if(resourceUOMAssociations.size() > 0){
                    theTMLListWasteDisposal[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id=resourceUOMAssociations[0].Unit_of_Measure__c, Name=resourceUOMAssociations[0].Unit_of_Measure__r.Name);
                    theTMLListWasteDisposal[i].Unit_of_Measure__c = resourceUOMAssociations[0].Unit_of_Measure__c;
                    theTMLListWasteDisposal[i].Resource_UOM__c = resourceUOMAssociations[0].Id;
                    theTMLListWasteDisposal[i] = TMMgmt.updateTML(theTMLListWasteDisposal[i], theTM, 'theUOM');
                    TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListWasteDisposal[i]}});
                } else {
                    theTMLListWasteDisposal[i].Unit_of_Measure__c = null;
                    theTMLListWasteDisposal[i].Resource_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource.'));
                    return null;
                }
            }
            Category = 'Waste Disposal';
        } else if (fieldName == 'theDUOM') {
            if (String.isBlank(newFieldValue)) {
                theTMLListDemurrage[i].Unit_of_Measure__c = null;
                theTMLListDemurrage[i].Unit_of_Measure__r = null;
                theTMLListDemurrage[i].Resource_UOM__c = null;
                theTMLListDemurrage[i].Resource_UOM__r = null;
            } else {
                List<ResourceUOMAssociation__c> resourceUOMAssociations =
                        ResourceUnitOfMeasuresSelector.newInstance().selectByResByUOM(theTMLListDemurrage[i].Resource__c, newFieldValue);

                if (resourceUOMAssociations.size() > 0) {
                    //SOListLaborLines[i].Unit_of_Measure__c = newFieldValue;
                    theTMLListDemurrage[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id = resourceUOMAssociations[0].Unit_of_Measure__c, Name = resourceUOMAssociations[0].Unit_of_Measure__r.Name);
                    theTMLListDemurrage[i].Unit_of_Measure__c = resourceUOMAssociations[0].Unit_of_Measure__c;
                    theTMLListDemurrage[i].Resource_UOM__c = resourceUOMAssociations[0].Id;
                    theTMLListDemurrage[i] = TMMgmt.updateTML(theTMLListDemurrage[i], theTM, 'theUOM');
                    TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{
                            theTM => new List<TM_Line__c>{
                                    theTMLListDemurrage[i]
                            }
                    });
                } else {
                    theTMLListDemurrage[i].Unit_of_Measure__c = null;
                    theTMLListDemurrage[i].Resource_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }
            Category = 'Demurrage';
        } else if (fieldName == 'theLumpUOM') {
            if (String.isBlank(newFieldValue)) {
                theTMLListLumpSum[i].Unit_of_Measure__c = null;
                theTMLListLumpSum[i].Unit_of_Measure__r = null;
                theTMLListLumpSum[i].Resource_Type_UOM__c = null;
                theTMLListLumpSum[i].Resource_Type_UOM__r = null;
            } else {
                List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                        ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeIdByUOMId(theTMLListLumpSum[i].Resource_Type__c, newFieldValue);

                if (resourceTypeUOMAssociations.size() > 0) {
                    theTMLListLumpSum[i].Unit_of_Measure__r = new Unit_of_Measure__c(Id = resourceTypeUOMAssociations[0].Unit_of_Measure__c, Name = resourceTypeUOMAssociations[0].Unit_of_Measure__r.Name);
                    theTMLListLumpSum[i].Unit_of_Measure__c = resourceTypeUOMAssociations[0].Unit_of_Measure__c;
                    theTMLListLumpSum[i].Resource_Type_UOM__c = resourceTypeUOMAssociations[0].Id;
                    theTMLListLumpSum[i] = TMMgmt.updateTML(theTMLListLumpSum[i], theTM, 'theUOM');
                    TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{
                            theTM => new List<TM_Line__c>{
                                    theTMLListLumpSum[i]
                            }
                    });
                } else {
                    theTMLListLumpSum[i].Unit_of_Measure__c = null;
                    theTMLListLumpSum[i].Resource_Type_UOM__c = null;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unit of Measure is not defined on the Resource Type.'));
                    return null;
                }
            }

            Category = 'Lump Sum';
        } else if (fieldName == 'theMiscUOM') {
            if (String.isBlank(newFieldValue)) {
                theTMLListMisc[i].Unit_of_Measure__c = null;
                theTMLListMisc[i].Unit_of_Measure__r = null;
            } else {
                theTMLListMisc[i].Unit_of_Measure__c = newFieldValue;
                theTMLListMisc[i] = TMMgmt.updateTML(theTMLListMisc[i], theTM, 'theUOM');
            }
            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theLunchStartTime' || fieldName == 'theLunchEndTime' || fieldName == 'theJobStartTime' ||
                fieldName == 'theJobEndTime' || fieldName == 'theBillingStartTime' || fieldName == 'theBillingEndTime' ||
                fieldName == 'theSiteStartTime' || fieldName == 'theSiteEndTime') {

            List<string> theTime = new List<string>();
            Integer hrs;
            Integer min;

            try {
                if (string.isEmpty(newFieldValue)) {
                    hrs = 0;
                    min = 0;
                } else {
                    if (newFieldValue.contains(':')) {
                        theTime = newFieldValue.split(':');
                        hrs = integer.valueOf(theTime[0]);
                        min = integer.valueOf(theTime[1]);
                    } else {
                        hrs = integer.valueOf(newFieldValue);
                        min = 0;
                    }
                }

                if (fieldName == 'theLunchStartTime') {
                    theTMLListLabor[i].Lunch_Start_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theLunchStartTime');
                }
                if (fieldName == 'theLunchEndTime') {
                    theTMLListLabor[i].Lunch_End_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theLunchEndTime');
                }
                if (fieldName == 'theJobStartTime') {
                    theTMLListLabor[i].Job_Start_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theJobStartTime');
                }
                if (fieldName == 'theJobEndTime') {
                    theTMLListLabor[i].Job_End_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theJobEndTime');
                }
                if (fieldName == 'theSiteStartTime') {
                    theTMLListLabor[i].Site_Start_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theSiteStartTime');
                }
                if (fieldName == 'theSiteEndTime') {
                    theTMLListLabor[i].Site_End_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theSiteEndTime');
                }
                if (fieldName == 'theBillingStartTime') {
                    theTMLListLabor[i].Billing_Start_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theBillingStartTime');
                }
                if (fieldName == 'theBillingEndTime') {
                    theTMLListLabor[i].Billing_End_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theBillingEndTime');
                }
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Labor';
        } else if (fieldName == 'theEBillingStartTime' || fieldName == 'theEBillingEndTime') {
            //Ticket#13673
            List<string> theTime = new List<string>();
            Integer hrs;
            Integer min;

            try {
                if (string.isEmpty(newFieldValue)) {
                    hrs = 0;
                    min = 0;
                } else {
                    if (newFieldValue.contains(':')) {
                        theTime = newFieldValue.split(':');
                        hrs = integer.valueOf(theTime[0]);
                        min = integer.valueOf(theTime[1]);
                    } else {
                        hrs = integer.valueOf(newFieldValue);
                        min = 0;
                    }
                }
                if (fieldName == 'theEBillingStartTime') {
                    theTMLListEquipment[i].Billing_Start_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theBillingStartTime');
                }
                if (fieldName == 'theEBillingEndTime') {
                    theTMLListEquipment[i].Billing_End_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theBillingEndTime');
                }
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Equipment';
        } else if (fieldName == 'theELunch') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListEquipment[i].Lunch__c = '';
                } else {
                    theTMLListEquipment[i].Lunch__c = newFieldValue;
                }
                theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theELunch');
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Equipment';
        } else if (fieldName == 'theRegularHour') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Regular_Hours__c = 0;
                } else {
                    theTMLListLabor[i].Regular_Hours__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theRegularHour');
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theOvertimeHour') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Overtime_Hours__c = 0;
                } else {
                    theTMLListLabor[i].Overtime_Hours__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theOvertimeHour');
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'thePremiumHours') { //Ticket#13673 >>
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Premium_Hours__c = 0;
                } else {
                    theTMLListLabor[i].Premium_Hours__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'thePremiumHours');
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor'; //Ticket#13673 <<
        } else if (fieldName == 'theRegularRate') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Regular_Rate__c = 0;
                } else {
                    theTMLListLabor[i].Regular_Rate__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theRegularRate');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'thePremiumRate') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Premium_Rate__c = 0;
                } else {
                    theTMLListLabor[i].Premium_Rate__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'thePremiumRate');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theUsePremiumRate') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Use_Premium_Rate__c = false;
                } else {
                    theTMLListLabor[i].Use_Premium_Rate__c = boolean.valueOf(newFieldValue);
                }

                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theUsePremiumRate');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theLBillasLumpSum') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Bill_as_Lump_Sum__c = false;
                } else {
                    theTMLListLabor[i].Bill_as_Lump_Sum__c = boolean.valueOf(newFieldValue);
                }

                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theLBillasLumpSum');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theLNonBillable') { //Ticket#13673
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Non_Billable__c = false;
                } else {
                    theTMLListLabor[i].Non_Billable__c = Boolean.valueOf(newFieldValue);
                }

                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, fieldName);

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theOvertimeRate') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Overtime_Rate__c = 0;
                } else {
                    theTMLListLabor[i].Overtime_Rate__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theOvertimeRate');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theOvertimeHour') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Overtime_Hours__c = 0;
                } else {
                    theTMLListLabor[i].Overtime_Hours__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theOvertimeHour');
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'thePremiumRate') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Premium_Rate__c = 0;
                } else {
                    theTMLListLabor[i].Premium_Rate__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'thePremiumRate');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theOvertimeRate') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Overtime_Rate__c = 0;
                } else {
                    theTMLListLabor[i].Overtime_Rate__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theOvertimeRate');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theLUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Unit_Price__c = 0;
                } else {
                    theTMLListLabor[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Tax_Group__c = '';
                } else {
                    theTMLListLabor[i].Tax_Group__c = newFieldValue;
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theLQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Quantity__c = 0;
                } else {
                    theTMLListLabor[i].Quantity__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theMQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListMaterials[i].Quantity__c = 0;
                } else {
                    theTMLListMaterials[i].Quantity__c = decimal.valueOf(newFieldValue);
                }
                theTMLListMaterials[i] = TMMgmt.updateTML(theTMLListMaterials[i], theTM, 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Materials';
        } else if (fieldName == 'theMUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListMaterials[i].Unit_Price__c = 0;
                } else {
                    theTMLListMaterials[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theTMLListMaterials[i] = TMMgmt.updateTML(theTMLListMaterials[i], theTM, 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Materials';
        } else if (fieldName == 'theMTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListMaterials[i].Tax_Group__c = '';
                } else {
                    theTMLListMaterials[i].Tax_Group__c = newFieldValue;
                }
                theTMLListMaterials[i] = TMMgmt.updateTML(theTMLListMaterials[i], theTM, 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Materials';
        } else if (fieldName == 'theESiteStartTime' || fieldName == 'theESiteEndTime') {
            List<string> theTime = new List<string>();
            Integer hrs;
            Integer min;
            try {
                if (string.isEmpty(newFieldValue)) {
                    hrs = 0;
                    min = 0;
                } else {
                    if (newFieldValue.contains(':')) {
                        theTime = newFieldValue.split(':');
                        hrs = integer.valueOf(theTime[0]);
                        min = integer.valueOf(theTime[1]);
                    } else {
                        hrs = integer.valueOf(newFieldValue);
                        min = 0;
                    }
                }
                if (fieldName == 'theESiteStartTime') {
                    theTMLListEquipment[i].Job_Start_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theJobStartTime');
                }

                if (fieldName == 'theESiteEndTime') {
                    theTMLListEquipment[i].Job_End_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theJobEndTime');
                }
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theEQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListEquipment[i].Quantity__c = 0;
                } else {
                    theTMLListEquipment[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theEBillasLumpSum') { //Ticket#13673
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListEquipment[i].Bill_as_Lump_Sum__c = false;
                } else {
                    theTMLListEquipment[i].Bill_as_Lump_Sum__c = boolean.valueOf(newFieldValue);
                }

                theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theEBillasLumpSum');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theENonBillable') { //Ticket#13673
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListEquipment[i].Non_Billable__c = false;
                } else {
                    theTMLListEquipment[i].Non_Billable__c = boolean.valueOf(newFieldValue);
                }

                theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, fieldName);

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theEUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListEquipment[i].Unit_Price__c = 0;
                } else {
                    theTMLListEquipment[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theUnitPrice');

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theETaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListEquipment[i].Tax_Group__c = '';
                } else {
                    theTMLListEquipment[i].Tax_Group__c = newFieldValue;
                }
                theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Equipment';
        } else if (fieldName == 'theSQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListSubcontractors[i].Quantity__c = 0;
                } else {
                    theTMLListSubcontractors[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                //theTMLListSubcontractors[i] = TMMgmt.updateTML(theTMLListSubcontractors[i], theTM, 'theQuantity');
                TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{theTMLListSubcontractors[i]}});

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theSUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListSubcontractors[i].Unit_Price__c = 0;
                } else {
                    theTMLListSubcontractors[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theTMLListSubcontractors[i] = TMMgmt.updateTML(theTMLListSubcontractors[i], theTM, 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theSTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListSubcontractors[i].Tax_Group__c = '';
                } else {
                    theTMLListSubcontractors[i].Tax_Group__c = newFieldValue;
                }
                theTMLListSubcontractors[i] = TMMgmt.updateTML(theTMLListSubcontractors[i], theTM, 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theSMarkup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListSubcontractors[i].Markup__c = 0;
                } else {
                    theTMLListSubcontractors[i].Markup__c = decimal.valueOf(newFieldValue);
                }
                theTMLListSubcontractors[i] = TMMgmt.updateTML(theTMLListSubcontractors[i], theTM, 'theMarkup');
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theSMarkupOption') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListSubcontractors[i].Markup_Option__c = '';
                } else {
                    theTMLListSubcontractors[i].Markup_Option__c = newFieldValue;
                }
                theTMLListSubcontractors[i] = TMMgmt.updateTML(theTMLListSubcontractors[i], theTM, 'theMarkupOption');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Subcontractors';
        } else if (fieldName == 'theWQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListWasteDisposal[i].Quantity__c = 0;
                } else {
                    theTMLListWasteDisposal[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theTMLListWasteDisposal[i] = TMMgmt.updateTML(theTMLListWasteDisposal[i], theTM, 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theWUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListWasteDisposal[i].Unit_Price__c = 0;
                } else {
                    theTMLListWasteDisposal[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theTMLListWasteDisposal[i] = TMMgmt.updateTML(theTMLListWasteDisposal[i], theTM, 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theWTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListWasteDisposal[i].Tax_Group__c = '';
                } else {
                    theTMLListWasteDisposal[i].Tax_Group__c = newFieldValue;
                }

                theTMLListWasteDisposal[i] = TMMgmt.updateTML(theTMLListWasteDisposal[i], theTM, 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theWMarkup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListWasteDisposal[i].Markup__c = 0;
                } else {
                    theTMLListWasteDisposal[i].Markup__c = decimal.valueOf(newFieldValue);
                }
                theTMLListWasteDisposal[i] = TMMgmt.updateTML(theTMLListWasteDisposal[i], theTM, 'theMarkup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theWMarkupOption') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListWasteDisposal[i].Markup_Option__c = '';
                } else {
                    theTMLListWasteDisposal[i].Markup_Option__c = newFieldValue;
                }
                theTMLListWasteDisposal[i] = TMMgmt.updateTML(theTMLListWasteDisposal[i], theTM, 'theMarkupOption');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Waste Disposal';
        } else if (fieldName == 'theDSiteStartTime' || fieldName == 'theDSiteEndTime') {
            List<string> theTime = new List<string>();
            Integer hrs;
            Integer min;
            try {
                if (string.isEmpty(newFieldValue)) {
                    hrs = 0;
                    min = 0;
                } else {
                    if (newFieldValue.contains(':')) {
                        theTime = newFieldValue.split(':');
                        hrs = integer.valueOf(theTime[0]);
                        min = integer.valueOf(theTime[1]);
                    } else {
                        hrs = integer.valueOf(newFieldValue);
                        min = 0;
                    }
                }
                if (fieldName == 'theDSiteStartTime') {
                    theTMLListDemurrage[i].Site_Start_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListDemurrage[i] = TMMgmt.updateTML(theTMLListDemurrage[i], theTM, 'theSiteStartTime');
                }

                if (fieldName == 'theDSiteEndTime') {
                    theTMLListDemurrage[i].Site_End_Time__c = time.newInstance(hrs, min, 0, 0);
                    theTMLListDemurrage[i] = TMMgmt.updateTML(theTMLListDemurrage[i], theTM, 'theSiteEndTime');
                }
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Demurrage';
        } else if (fieldName == 'theDQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListDemurrage[i].Quantity__c = 0;
                } else {
                    theTMLListDemurrage[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theTMLListDemurrage[i] = TMMgmt.updateTML(theTMLListDemurrage[i], theTM, 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Demurrage';
        } else if (fieldName == 'theDUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListDemurrage[i].Unit_Price__c = 0;
                } else {
                    theTMLListDemurrage[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theTMLListDemurrage[i] = TMMgmt.updateTML(theTMLListDemurrage[i], theTM, 'theUnitPrice');
            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Demurrage';
        } else if (fieldName == 'theDTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListDemurrage[i].Tax_Group__c = '';
                } else {
                    theTMLListDemurrage[i].Tax_Group__c = newFieldValue;
                }
                theTMLListDemurrage[i] = TMMgmt.updateTML(theTMLListDemurrage[i], theTM, 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Demurrage';
        } else if (fieldName == 'theLumpQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLumpSum[i].Quantity__c = 0;
                } else {
                    theTMLListLumpSum[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theTMLListLumpSum[i] = TMMgmt.updateTML(theTMLListLumpSum[i], theTM, 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Lump Sum';
        } else if (fieldName == 'theLumpUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLumpSum[i].Unit_Price__c = 0;
                } else {
                    theTMLListLumpSum[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theTMLListLumpSum[i] = TMMgmt.updateTML(theTMLListLumpSum[i], theTM, 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Lump Sum';
        } else if (fieldName == 'theLumpTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLumpSum[i].Tax_Group__c = '';
                } else {
                    theTMLListLumpSum[i].Tax_Group__c = newFieldValue;
                }
                theTMLListLumpSum[i] = TMMgmt.updateTML(theTMLListLumpSum[i], theTM, 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Lump Sum';
        } else if (fieldName == 'theMiscQuantity') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListMisc[i].Quantity__c = 0;
                } else {
                    theTMLListMisc[i].Quantity__c = decimal.valueOf(newFieldValue);
                }

                theTMLListMisc[i] = TMMgmt.updateTML(theTMLListMisc[i], theTM, 'theQuantity');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theMiscUnitPrice') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListMisc[i].Unit_Price__c = 0;
                } else {
                    theTMLListMisc[i].Unit_Price__c = decimal.valueOf(newFieldValue);
                }
                theTMLListMisc[i] = TMMgmt.updateTML(theTMLListMisc[i], theTM, 'theUnitPrice');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theMiscTaxGroup') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListMisc[i].Tax_Group__c = '';
                } else {
                    theTMLListMisc[i].Tax_Group__c = newFieldValue;
                }
                theTMLListMisc[i] = TMMgmt.updateTML(theTMLListMisc[i], theTM, 'theTaxGroup');

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Misc. Charges And Taxes';
        } else if (fieldName == 'theLContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                theTMLListLabor[i].Contract_Line__c = null;
                theTMLListLabor[i].Contract_Line__r = null;
                theTMLListLabor[i].Contract_Regular_Rate__c = 0;
                theTMLListLabor[i].Contract_Premium_Rate__c = 0;
                theTMLListLabor[i].Contract_Overtime_Rate__c = 0;
                Decimal lineNo = theTMLListLabor[i].Line_No__c;
                theTMLListLabor[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListLabor[i].Contract_Line__c = newFieldValue;
                    //theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theLContractLine');
                    TMLLinesService.validateContractLine(theTM, theTMLListLabor[i]);
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }

            }
            Category = 'Labor';
        } else if (fieldName == 'theEContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                theTMLListEquipment[i].Contract_Line__c = null;
                theTMLListEquipment[i].Contract_Line__r = null;
                theTMLListEquipment[i].Contract_Regular_Rate__c = 0;
                Decimal lineNo = theTMLListEquipment[i].Line_No__c;
                theTMLListEquipment[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListEquipment[i].Contract_Line__c = newFieldValue;
                    //theTMLListEquipment[i] = TMMgmt.updateTML(theTMLListEquipment[i], theTM, 'theEContractLine');
                    TMLLinesService.validateContractLine(theTM, theTMLListEquipment[i]);
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }

            }
            Category = 'Equipment';
        } else if (fieldName == 'theLumpSumContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                theTMLListLumpSum[i].Contract_Line__c = null;
                theTMLListLumpSum[i].Contract_Line__r = null;
                theTMLListLumpSum[i].Contract_Regular_Rate__c = 0;
                Decimal lineNo = theTMLListLumpSum[i].Line_No__c;
                theTMLListLumpSum[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListLumpSum[i].Contract_Line__c = newFieldValue;
                    //theTMLListLumpSum[i] = TMMgmt.updateTML(theTMLListLumpSum[i], theTM, 'theLumpSumContractLine');
                    TMLLinesService.validateContractLine(theTM, theTMLListLumpSum[i]);
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }

            }
            Category = 'Lump Sum';
        } else if (fieldName == 'theMContractLine') {
            if (String.isBlank(newFieldValue)) {
                // not allowed to blank out because custom lookup may receive view state error
                theTMLListMaterials[i].Contract_Line__c = null;
                theTMLListMaterials[i].Contract_Line__r = null;
                theTMLListMaterials[i].Contract_Regular_Rate__c = 0;
                Decimal lineNo = theTMLListMaterials[i].Line_No__c;
                theTMLListMaterials[i] = new TM_Line__c(TM__c = tmId, Line_No__c = lineNo);
            } else {
                try {
                    theTMLListMaterials[i].Contract_Line__c = newFieldValue;
                    //theTMLListMaterials[i] = TMMgmt.updateTML(theTMLListMaterials[i], theTM, 'theMContractLine');
                    TMLLinesService.validateContractLine(theTM, theTMLListMaterials[i]);
                } catch (exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
                }
            }
            Category = 'Materials';
        } else if (fieldName == 'theWDContractLine') {
            try {
                if(String.isBlank(newFieldValue)){
                    theTMLListWasteDisposal[i].Contract_Line__c = null;
                    theTMLListWasteDisposal[i].Contract_Line__r = null;
                } else {
                    theTMLListWasteDisposal[i].Contract_Line__c = newFieldValue;
                }
                //TMLLinesService.initStaticVariables(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{ theTMLListWasteDisposal[i] }});
                //TMLLinesService.calcUnitPrice(theTM, theTMLListWasteDisposal[i]);
                TMLLinesService.validateContractLine(theTM, theTMLListWasteDisposal[i]);
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            Category = 'Waste Disposal';
        } else if (fieldName == 'theTMLDemurrageContractLine') { //Ticket#18265 >>
            try {
                if(String.isBlank(newFieldValue)){
                    theTMLListDemurrage[i].Contract_Line__c = null;
                    theTMLListDemurrage[i].Contract_Line__r = null;
                } else {
                    theTMLListDemurrage[i].Contract_Line__c = newFieldValue;
                }
                //TMLLinesService.initStaticVariables(new Map<TM__c, List<TM_Line__c>>{theTM => new List<TM_Line__c>{ theTMLListDemurrage[i] }});
                TMLLinesService.validateContractLine(theTM, theTMLListDemurrage[i]);
            } catch (Exception e) {
                System.debug('Error: ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
            Category = 'Demurrage'; //Ticket#18265 <<
        } else if (fieldName == 'laborDispatchFromHome') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Eligible_Dispatch_from_Home_Pay__c = false;
                } else {
                    theTMLListLabor[i].Eligible_Dispatch_from_Home_Pay__c = Boolean.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'laborDispatchFromHome');
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Labor';
        } else if (fieldName == 'selectedLabor') {
            System.debug('Info: selectedLabor ' + newFieldValue);
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].To_Invoice__c = false;
                } else {
                    theTMLListLabor[i].To_Invoice__c = Boolean.valueOf(newFieldValue);
                    selectedLaborLineId = theTMLListLabor[i].Id;
                    System.debug('Info: selectedLabor selectedLaborLineId ' + selectedLaborLineId);
                    System.debug('Info: theTMLListLabor[i].To_Invoice__c ' + theTMLListLabor[i].To_Invoice__c);
                    for(TM_Line__c tmline : theTMLListLabor){
                        if(tmline.Id != selectedLaborLineId){
                            tmline.To_Invoice__c = false;
                        }
                    }
                    System.debug('Info: theTMLListLabor[i].To_Invoice__c 2 ' + theTMLListLabor[i].To_Invoice__c);
                }
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Labor';
        } else if (fieldName == 'theBillSiteTime') {
            try {
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Bill_Site_Time__c = false;
                } else {
                    theTMLListLabor[i].Bill_Site_Time__c = Boolean.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theBillSiteTime');
            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage())); return null;
            }

            Category = 'Labor';
        } else if (fieldName == 'theInclLunchYN'){ //Ticket#13764
            try{
                if (String.isBlank(newFieldValue)) {
                    theTMLListLabor[i].Include_Lunch_Y_N__c = false;
                } else {
                    theTMLListLabor[i].Include_Lunch_Y_N__c = boolean.valueOf(newFieldValue);
                }
                theTMLListLabor[i] = TMMgmt.updateTML(theTMLListLabor[i], theTM, 'theInclLunchYN');
            } catch (Exception e){
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
            Category = 'Labor';
        } else if (fieldName == 'theMBillasLumpSum' || fieldName == 'theSBillasLumpSum' || fieldName == 'theWBillasLumpSum' ||
                fieldName == 'theDBillasLumpSum' || fieldName == 'theMiscBillasLumpSum') {
            try {

                Category = fieldNameCategoryMap.get(fieldName);
                Boolean isChecked = false;

                if (String.isNotBlank(newFieldValue)) {
                    //isChecked = true;
                    isChecked = Boolean.valueOf(newFieldValue);
                }

                switch on Category {
                    when 'Subcontractors' {
                        theTMLListSubcontractors[i].Bill_as_Lump_Sum__c = isChecked;
                        theTMLListSubcontractors[i] = TMMgmt.updateTML(theTMLListSubcontractors[i], theTM, fieldName);
                    }
                    when 'Waste Disposal' {
                        theTMLListWasteDisposal[i].Bill_as_Lump_Sum__c = isChecked;
                        theTMLListWasteDisposal[i] = TMMgmt.updateTML(theTMLListWasteDisposal[i], theTM, fieldName);
                    }
                    when 'Demurrage' {
                        theTMLListDemurrage[i].Bill_as_Lump_Sum__c = isChecked;
                        theTMLListDemurrage[i] = TMMgmt.updateTML(theTMLListDemurrage[i], theTM, fieldName);
                    }
                    when 'Misc. Charges And Taxes' {
                        theTMLListMisc[i].Bill_as_Lump_Sum__c = isChecked;
                        theTMLListMisc[i] = TMMgmt.updateTML(theTMLListMisc[i], theTM, fieldName);
                    }
                    when 'Materials' {
                        theTMLListMaterials[i].Bill_as_Lump_Sum__c = isChecked;
                        theTMLListMaterials[i] = TMMgmt.updateTML(theTMLListMaterials[i], theTM, fieldName);
                    }
                }

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }

        } else if (fieldName == 'theMNonBillable' || fieldName == 'theSNonBillable' || fieldName == 'theWNonBillable' ||
                fieldName == 'theDNonBillable' || fieldName == 'theMiscNonBillable') {
            try {
                Category = fieldNameCategoryMap.get(fieldName);
                Boolean isChecked = false;

                if (String.isNotBlank(newFieldValue)) {
                    //isChecked = true;
                    isChecked = Boolean.valueOf(newFieldValue);
                }

                switch on Category {
                    when 'Subcontractors' {
                        theTMLListSubcontractors[i].Non_Billable__c = isChecked;
                        theTMLListSubcontractors[i] = TMMgmt.updateTML(theTMLListSubcontractors[i], theTM, fieldName);
                    }
                    when 'Waste Disposal' {
                        theTMLListWasteDisposal[i].Non_Billable__c = isChecked;
                        theTMLListWasteDisposal[i] = TMMgmt.updateTML(theTMLListWasteDisposal[i], theTM, fieldName);
                    }
                    when 'Demurrage' {
                        theTMLListDemurrage[i].Non_Billable__c = isChecked;
                        theTMLListDemurrage[i] = TMMgmt.updateTML(theTMLListDemurrage[i], theTM, fieldName);
                    }
                    when 'Misc. Charges And Taxes' {
                        theTMLListMisc[i].Non_Billable__c = isChecked;
                        theTMLListMisc[i] = TMMgmt.updateTML(theTMLListMisc[i], theTM, fieldName);
                    }
                    when 'Materials' {
                        theTMLListMaterials[i].Non_Billable__c = isChecked;
                        theTMLListMaterials[i] = TMMgmt.updateTML(theTMLListMaterials[i], theTM, fieldName);
                    }
                }

            } catch (exception e) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage())); return null;
            }
        }
        else if (fieldName == 'theWContainerSize'){
            if(String.isBlank(newFieldValue)){
                theTMLListWasteDisposal[i].Container_Size__c = null;
                theTMLListWasteDisposal[i].Container_Size__r = null;
            } else {
                theTMLListWasteDisposal[i].Container_Size__c = newFieldValue;
                List<Unit_of_Measure__c> uoms = UnitOfMeasuresSelector.newInstance().selectSObjectsById(new Set<Id>{newFieldValue});
                theTMLListWasteDisposal[i].Container_Size__r = new Unit_of_Measure__c(Id = uoms[0].Id, Name = uoms[0].Name);
            }

            TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{
                    theTM => new List<TM_Line__c>{theTMLListWasteDisposal[i]}});
            Category = 'Waste Disposal';
        } else if (fieldName == 'theWUnitVol'){
            if(String.isBlank(newFieldValue)){
                theTMLListWasteDisposal[i].Unit_Weight_Vol__c = null;
                theTMLListWasteDisposal[i].Unit_Weight_Vol__r = null;
            } else {
                theTMLListWasteDisposal[i].Unit_Weight_Vol__c = newFieldValue;
                List<Unit_of_Measure__c> uoms = UnitOfMeasuresSelector.newInstance().selectSObjectsById(new Set<Id>{newFieldValue});
                theTMLListWasteDisposal[i].Unit_Weight_Vol__r = new Unit_of_Measure__c(Id = uoms[0].Id, Name = uoms[0].Name);
            }
            TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{
                    theTM => new List<TM_Line__c>{theTMLListWasteDisposal[i]}});
            Category = 'Waste Disposal';
        } else if (fieldName == 'theWCostMethod'){
            TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{
                    theTM => new List<TM_Line__c>{theTMLListWasteDisposal[i]}});
            Category = 'Waste Disposal';
        } else if (fieldName == 'theWFacility'){
            if(String.isBlank(newFieldValue)){
                theTMLListWasteDisposal[i].Facility__c = null;
                theTMLListWasteDisposal[i].Facility__c = null;
            } else {
                theTMLListWasteDisposal[i].Facility__c = newFieldValue;
                List<Facility__c> facilities = FacilitiesSelector.newInstance().selectById(new Set<Id>{newFieldValue});
                theTMLListWasteDisposal[i].Facility__r = new Facility__c(Id = facilities[0].Id, Name = facilities[0].Name);
            }
            TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{
                    theTM => new List<TM_Line__c>{theTMLListWasteDisposal[i]}});
            Category = 'Waste Disposal';
        }

        if (theTM.Status__c != 'Open' && theTM.Status__c != 'Scheduled') {
            if (!Test.isRunningTest()) {
                if (Category == 'Labor') {
                    CalculateTotalLabor();
                    CalculateTotalOrder();
                }
                if (Category == 'Equipment') {
                    CalculateTotalEquipment();
                    CalculateTotalOrder();
                }
                if (Category == 'Materials') {
                    CalculateTotalMaterials();
                    CalculateTotalOrder();
                }
                if (Category == 'Subcontractors') {
                    CalculateTotalSubcontractors();
                    CalculateTotalOrder();
                }
                if (Category == 'Waste Disposal') {
                    CalculateTotalWasteDisposal();
                    CalculateTotalOrder();
                }
                if (Category == 'Demurrage') {
                    CalculateTotalDemurrage();
                    CalculateTotalOrder();
                }
                if (Category == 'Lump Sum') {
                    CalculateTotalLumpSum();
                    CalculateTotalOrder();
                }
                if (Category == 'Misc. Charges And Taxes') {
                    CalculateTotalMisc();
                    CalculateTotalOrder();
                }
            }
        }
        */
        return null;
    }

    public class TMWrapper {
        public List<String> subMenuItems {
            get;
            set;
        }
        public TM__c theTM {
            get;
            set;
        }
        public List<String> labor {
            get;
            set;
        }
        public List<String> equipment {
            get;
            set;
        }

        public Boolean isSelected {
            get;
            set;
        }

        public String startTime {
            get;
            set;
        }

        public TMWrapper(List<String> subMenuItems, TM__c theTM, List<String> labor, List<String> equipment, Boolean isSelected, string startTime) {
            this.subMenuItems = subMenuItems;
            this.theTM = theTM;
            this.labor = labor;
            this.equipment = equipment;
            this.isSelected = isSelected;
            this.startTime = startTime;
        }
    }

    //Depreciated
    public void searchTM() {
        /*
        filterInput = '';
        search();
         */
    }

    public void search() {
        PageSize = 60;
        try {
            if (String.isEmpty(theUser.Service_Center__c)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Service center not assigned to user.'));

            } else {
                String filterQuery = '';
                String scName = theUser.Service_Center__c;
                /*
                Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM__c.fields.getMap();
                List<String> lstFields = new List<String>();
                for (Schema.SObjectField field : fields.values()) {
                    lstFields.add(field.getDescribe().getName());
                }
                 */

                String strQuery = 'SELECT Id, Name,Scheduled_Date__c,Site_Name__c,Site_City__c,Site_State__c,' +
                        'Total_Amount__c, Bill_to_Customer__c, Sales_Order__c,Ready_to_Close__c, Status__c,' +
                        'Desired_Scheduled_Date__c,Emergency_TM__c';
                strQuery += ' FROM TM__c WHERE (Service_Center__r.Name =: scName OR Service_Center__r.Name = null) ';
                //Mobile T&M review status
                strQuery += ' AND (Status__c = \'Open\' OR Status__c = \'Scheduled\'' +
                        ' OR Status__c = \'Mobile Review\'' +
                        ' OR Status__c = \'Confirmed\' OR Status__c = \'Received by Billing\'' +
                        ' OR Status__c = \'Ready to Bill\'' +
                        ' OR Status__c = \'Partially Invoiced\'' +
                        ' OR (Status__c = \'Fully Invoiced\' AND Scheduled_Date__c = LAST_90_DAYS)' +
                        ' OR (Status__c = \'Closed\' AND Scheduled_Date__c = LAST_90_DAYS)' +
                        ' OR (Status__c = \'Void\' AND Scheduled_Date__c = LAST_90_DAYS))';



                if (!String.isEmpty(filterInput2) && filterInput2 != 'Ready to Close') {
                    filterQuery += 'AND ' + selFilterField2 + '  LIKE \'%' + String.escapeSingleQuotes(filterInput2) + '%\'';
                }

                if (String.isBlank(selFilterField)) {
                    strQuery += '';
                } else {
                    if (String.isNotBlank(selFilterField) && String.isNotBlank(filterInput)) {

                        if (selFilterOp == 'contains') {
                            strQuery += ' AND ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\'';

                        } else if (selFilterOp == 'not contains') {
                            strQuery += ' AND  (NOT ' + selFilterField + '  LIKE \'%' + String.escapeSingleQuotes(filterInput) + '%\')';
                        }
                    }
                }


                strQuery += (String.isBlank(filterQuery) ? '' : ' AND ' + filterQuery.removeStart('AND')) ;
                if (!String.isEmpty(orderBy)) {

                    if (orderBy == 'Bill_To_Customer__c') orderBy = 'Bill_To_Customer__r.Name';

                    else if (orderBy == 'Service_Center__c') orderBy = 'Service_Center__r.Name';

                    else if (orderBy == 'Sales_Order__c') orderBy = 'Sales_Order__r.Name';

                    strQuery += ' ORDER BY ' + orderBy + ' ' + order + ' NULLS LAST';
                } else {
                    strQuery += ' ORDER BY NAME' ;
                }

                List<TM__c> lstTM = new List<TM__c>();
                lstTM = Database.query(strQuery);
                TMPerStatusWrapper theTMWrap;
                theTMListPerStatus = new List<TMPerStatusWrapper>();
                for (TM__c theTM : lstTM) {
                    theTMWrap = new TMPerStatusWrapper(
                            false,
                            theTM
                    );
                    theTMListPerStatus.add(theTMWrap);
                }

                PaginationByStatus = new TMPerStatusWrapperPagination(theTMListPerStatus, PageSize);
                theTMListPerStatus = PaginationByStatus.beginning();
            }

        } catch (Exception e) {
            System.debug('Error: ' + e.getStackTraceString());
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.Error, e.getMessage()));
        }
    }

    public List<SelectOption> lstFilterOperator {
        get {
            if (lstFilterOperator == null) {
                lstFilterOperator = new List<SelectOption>();
                /* lstFilterOperator.add(new SelectOption('equals', 'equals'));
                 lstFilterOperator.add(new SelectOption('not equal to', 'not equal to'));
                 lstFilterOperator.add(new SelectOption('Like', 'Like'));*/
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
                //  lstFilterField.add(new SelectOption('', '--None--'));
                lstFilterField.add(new SelectOption('Name', 'TM No.'));
                lstFilterField.add(new SelectOption('Bill_To_Customer__r.Name', 'Customer.'));
                lstFilterField.add(new SelectOption('Sales_Order__r.Name', 'Sales Order No.'));
            }
            return lstFilterField;
        }
        set;
    }

    //Depreciated
    public pagereference setStatus() {
        /*
        String changeStatus = changeStatusTo;

        List<TM__c> lstTM = new List<TM__c>();
        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {
            if (theTMWrap.isSelected) {
                theTMWrap.theTM.Status__c = changeStatus;
                theTMWrap.theTM.Ready_to_Close__c = false;
                lstTM.add(theTMWrap.theTM);
            }
        }

        Savepoint sp = database.setSavePoint();

        try {
            CompanyMgmt.systemCall = true;
            update lstTM;
            CompanyMgmt.systemCall = false;
            search();
        } catch (Exception e) {
            Database.Rollback(sp);
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            System.debug('#### List of TM not updated due to-->' + e);
            return null;
        }
         */
        return null;
    }

    //Depreciated
    public pagereference setStatusToVoid() {
        /*
        List<TM__c> lstTM = new List<TM__c>();

        //Ticket 13348 - set labor and equipment time to null when void.
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
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
            return null;
        }
        */
        return null;
    }

    //Depreciated
    public void DeleteTM() {
    }

    //Depreciated
    public List<String> lstFields {
        get {
            lstFields = new List<String>();
            lstFields.add('Name');
            lstFields.add('Bill_To_Customer__c');
            if (filterInput2 == 'Open') {
                lstFields.add('Desired_Scheduled_Date__c');
                lstFields.add('Emergency_TM__c');
            }
            lstFields.add('Scheduled_Date__c');
            lstFields.add('Sales_Order__c');
            lstFields.add('Site_City__c');
            lstFields.add('Site_State__c');
            lstFields.add('Total_Amount__c');
            return lstFields;
        }
        private set;
    }

    //Depreciated
    /*
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
    */

    public class TMPerStatusWrapper {
        public Boolean isSelected {
            get;
            set;
        }
        public TM__c theTM {
            get;
            set;
        }

        public TMPerStatusWrapper(boolean isSelected, TM__c theTM) {
            this.isSelected = isSelected;
            this.theTM = theTM;
        }
    }

    public PageReference editTM() {
        selectedId = ApexPages.CurrentPage().getParameters().get('tmRecId');
        return null;
    }

    public PageReference CreateInvoice() {
        return CreateSIfromList();
    }

    //Depreciated
    public PageReference CreateSIfromList() {
        /*
        Boolean hasLumpSumTM = false;
        theMapTMReadyToBill = new Map<String, TM_Line__c>();
        List<Rental_Order__c> theROList = new List<Rental_Order__c>();
        Map<String, String> mapROTML = new Map<String, String>();

        Sales_Invoice__c theSI = new Sales_Invoice__c();

        if (theTMList != null && theTMList.size() > 0) {
            for (Integer i = 0; i < theTMList.size(); i++) {

                if (theTMList[i].Lump_Sum_Order__c && !hasLumpSumTM) hasLumpSumTM = true;

                if (i != 0) {
                    if (theTMList[i].Bill_To_Customer__c != theTMList[i - 1].Bill_To_Customer__c ||
                            theTMList[i].Sales_Order__c != theTMList[i - 1].Sales_Order__c ||
                            theTMList[i].Subsidiary_Company__c != theTMList[i - 1].Subsidiary_Company__c) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'All T&Ms checked must have same Customer, Sales Order and Subsidiary Company.')); return null;
                    }

                    if (theTMList[i].Tax_Area__c != theTMList[i - 1].Tax_Area__c) {
                        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'All T&Ms checked must have same Tax Area.')); return null;
                    }
                }

                if (hasLumpSumTM && !theTMList[i].Lump_Sum_Order__c) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You cannot combine Lump Sum T&M with non Lump Sum T&Ms.')); return null;
                }

                if (!hasLumpSumTM && i == (theTMList.size() - 1) && theTMList[i].Lump_Sum_Order__c) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You cannot combine Lump Sum T&M with non Lump Lump Sum T&Ms.'));return null;
                }

                if (string.isEmpty(theTMList[i].Subsidiary_Company__c)) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Subsidiary Company cannot be blank for T&M: ' + theTMList[i].Name)); return null;
                }

                if (string.isEmpty(theTMList[i].Service_Center__c)) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Service Center cannot be blank for T&M: ' + theTMList[i].Name)); return null;
                }

                if (string.isEmpty(theTMList[i].Sales_Order__c)) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Sales Order cannot be blank for T&M: ' + theTMList[i].Name)); return null;
                }

                //if (!string.isEmpty(theTMList[i].Sales_Invoice__c)) {
                //    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Sales Invoice must be blank for T&M: ' + theTMList[i].Name)); return null;
                //}

                if (theTMList[i].Status__c != 'Ready to Bill' && theTMList[i].Status__c != 'Partially Invoiced') {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'T&M Status must be Ready to Bill or Partially Invoiced for T&M: ' + theTMList[i].Name));return null;
                }

                if (string.isEmpty(theTMList[i].Tax_Area__c)) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Tax Area cannot be blank for T&M: ' + theTMList[i].Name)); return null;
                }

                if (theTMLList != null && theTMLList.size() > 0) {
                    for (TM_Line__c theTML : theTMLList) {
                        theMapTMReadyToBill.put(theTML.TM__c, theTML);
                    }
                }

                if (!theMapTMReadyToBill.containsKey(theTMList[i].Id)) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Every T&M must have at least one T&M Line.')); return null;
                }
            }

        } else {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You must select at least one T&M to create invoice.')); return null;
        }

        // Savepoint
        Savepoint sp = Database.setSavepoint();
        List<String> errorList = new List<String>();
        //Need this flag to bypass some trigger codes in order reduce SOQL
        //Only 200 records are processed at one time in trigger
        CompanyMgmt.massCreateInvoice = true;
        errorList = TMMgmt.checkCreateInvoice(theTMList, theTMLList);
        if (errorList.size() > 0) {
            for (Integer i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
            }
            return null;
        } else {
            try {
                String recordIdStr = TMsService.createSalesInvoice(
                        theTMList[0].Sales_Order__c,
                        new Map<Id, TM__c>(theTMList).keySet(),
                        new Map<Id, TM_Line__c>(theTMLList).keySet(),
                        invoiceNote);
                if (recordIdStr.indexOf('Async:') != -1) {
                    recordIdStr = recordIdStr.remove('Async:');
                }
                return new PageReference('/' + recordIdStr);
            } catch (Exception e) {
                // Rollback
                Database.rollback(sp);
                System.debug('Info: Exception ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        }
         */
        return null;
    }

    //Depreciated
    // Create SI from T&M Card
    public PageReference CreateSI() {
        /*
        System.debug('###CreateSI Begin###');
        List<TM__c> theTMList = new List<TM__c>();

        Savepoint sp = Database.setSavepoint();

        theTMList.add(theTM);

        List<String> errorList = new List<String>();
        errorList = TMMgmt.checkCreateInvoice(theTMList, theTMLList);
        if (invoiceNote != null) {
            if (invoiceNote.length() > 250) {
                errorList.add('Invoice Note exceeded 250 characters: ' + invoiceNote.length());
            }
        }

        if (errorList.size() > 0) {
            for (Integer i = 0; i < errorList.size(); i++) {
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, errorList[i]));
            }
            return null;
        } else {
            try {
                String recordIdStr = TMsService.createSalesInvoice(
                        theTM.Sales_Order__c,
                        new Set<Id>{theTM.Id},
                        new Map<Id, TM_Line__c>(theTMLList).keySet(),
                        invoiceNote);
                if (recordIdStr.indexOf('Async:') != -1){
                    recordIdStr = recordIdStr.remove('Async:');
                }
                return new PageReference('/' + recordIdStr);

            } catch (Exception e) {
                Database.rollback(sp);
                System.debug('Error: ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        }
         */
        return null;
    }

/////////////////////////////////////CUSTOM PAGINATION////////////////////////////////////////////////
// returns the page number of the current page set
    public Integer pageNumber {
        get {
            return Pagination.pageNumber();
        }
        set;
    }

// indicates whether there are more records after the current page set.
    public Boolean hasNextpage {
        get {
            return Pagination.getDisableNext();
        }
        set;
    }

// indicates whether there are more records before the current page set.
    public Boolean hasPreviouspage {
        get {
            return Pagination.getDisablePrevious();
        }
        set;
    }

// get the start Index.
    public Integer getStartIndex {
        get {
            return Pagination.currStartIndex;
        }
        set;
    }

// get the End Index.
    public Integer getEndIndex {
        get {
            return Pagination.currEndIndex;
        }
        set;
    }

// returns the page number of the current page set
    public Integer getTotalRecords {
        get {
            return Pagination.totalSize;
        }
        set;
    }

// returns the first page of records
    public void firstpage() {
        theTMWrapList = Pagination.beginning();
    }

// returns the last page of records
    public void lastpage() {
        theTMWrapList = Pagination.last();
    }

// returns the previous page of records
    public void previouspage() {
        theTMWrapList = Pagination.previous();
    }

// returns the next page of records
    public void nextpage() {
        theTMWrapList = Pagination.next();
    }
/////////////////////////////////////CUSTOM PAGINATION////////////////////////////////////////////////

    public String getVFPageName() {
        String pageName = ApexPages.currentPage().getUrl();
        pageName = pageName.replaceFirst('/apex/', '');
        pageName = EncodingUtil.urlEncode(pageName, 'UTF-8');
        String[
        ] pageNameExtra = pageName.split('%3F', 0);
        pageName = pageNameExtra[0];
        return pageName;
    }

    /*   Depreciated
     *   Ticket#16967 Default Site Scope to "Emergency Response"
     */
    public PageReference AddEmergencyTMs() {
        /*
        Integer maxEmergencyTM;

        //Ticket# 13463 >>
        if (theSC.Name != theUser.Service_Center__c) {
            selectServiceCenter();
        }
        //Ticket# 13463 <<

        if(theSC.Blocked__c == true){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,
                    'Service center ' + theSC.Name + ' is deactivated!'));
            return null;
        }

        if (theSC.Max_No_of_Emergency_T_M__c != null) {
            maxEmergencyTM = Integer.valueOf(theSC.Max_No_of_Emergency_T_M__c);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must define Max No. of Emergency TM on Service Center. ' + theSC.Name));return null;
        }

        List<TM__c> theTMEmergencyList = new List<TM__c>();
        //Ticket#13793 - add status to WHERE clause
        theTMEmergencyList = [
                SELECT Id, Name
                FROM TM__c
                WHERE Emergency_TM__c = true AND Service_Center__c = :theSC.Id
                AND Sales_Order__c = :null AND Status__c != 'Void'
                ORDER BY Name
        ];

        //Ticket# 13463 >>
        String openERTMStr = '';
        for (TM__c erTM : theTMEmergencyList) {
            openERTMStr += erTM.Name + '<br />';
        }

        if (theTMEmergencyList != null && theTMEmergencyList.size() > 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must use existing Emergency T&Ms first: <br />' + openERTMStr));return null;
        }
        //Ticket# 13463 <<

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
                insert theTMList; search();

            } catch (Exception e) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            }
        }
         */
        return null;
    }

    /*   Depreciated
     *   Ticket#16967 by pass bill-to and sales order check if T&M is an ER.
     */
    public PageReference ScheduleTMs() {
        return null;
        /*
        String selectedTMId = '';
        for (Integer i = 0; i < theTMListPerStatus.size(); i++) {
            if (theTMListPerStatus[i].isSelected) {
                if(theTMListPerStatus[i].theTM.Emergency_TM__c != true){
                    if (String.isEmpty(theTMListPerStatus[i].theTM.Bill_to_Customer__c)) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Bill-to Customer cannot be blank for the selected T&Ms.'));
                        return null;
                }

                    if (String.isEmpty(theTMListPerStatus[i].theTM.Sales_Order__c)) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Sales Order cannot not be blank for the selected T&Ms.'));
                        return null;
                    }
                }

                if (i != 0) selectedTMId += ',';

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
         */
    }

    /*  Depreciated
        Ticket#13461
     */
    public PageReference manualCloseTM() {
        return null;
        /*
        String selectedTMId = '';
        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {
            if (theTMWrap.isSelected == true) {
                selectedTMId = selectedTMId + theTMWrap.theTM.Id + ',';
            }
        }

        if (String.isNotBlank(selectedTMId) == true) {
            selectedTMId = selectedTMId.removeEnd(',');
        }

        if (String.isBlank(selectedTMId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please select a T&M'));
            return null;
        }

        PageReference closeTMConfirmation = new PageReference('/apex/AddScheduleTMConfirmation?selectedTMId=' + selectedTMId);
        closeTMConfirmation.setRedirect(true);
        closeTMConfirmation.getParameters().put('setStatus', 'Closed');
        return closeTMConfirmation;
         */
    }

    /* Depreciated
       Ticket#13461
     */
    public PageReference reopenTM() {
        return null;
        /*
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

        if (String.isBlank(selectedTMId)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please select a T&M'));
            return null;
        }

        PageReference reopenTMConfirmation = new PageReference('/apex/AddScheduleTMConfirmation?selectedTMId=' + selectedTMId);
        reopenTMConfirmation.setRedirect(true);
        reopenTMConfirmation.getParameters().put('setStatus', 'Ready to Bill');
        return reopenTMConfirmation;
         */
    }

    /*  Depreciated
        No need can be removed.
     */
    public PageReference CheckReadyToClose() {
        /*
        List<TM__c> lstTM = new List<TM__c>();
        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {

            if (theTMWrap.isSelected) {
                theTMWrap.theTM.Ready_to_Close__c = true; lstTM.add(theTMWrap.theTM);
            }
        }

        try {
            update lstTM;
            search();
        } catch (Exception e) {
            System.debug('#### List of TM not updated due to-->' + e);
        }
         */
        return null;
    }

    //Depreciated
    public PageReference RemoveFromClose() {
        /*
        List<TM__c> lstTM = new List<TM__c>();
        for (TMPerStatusWrapper theTMWrap : theTMListPerStatus) {

            if (theTMWrap.isSelected) {
                theTMWrap.theTM.Ready_to_Close__c = false; lstTM.add(theTMWrap.theTM);
            }
        }

        try {
            update lstTM;
            search();
        } catch (Exception e) {
            System.debug('#### List of TM not updated due to-->' + e);
        }
         */
        return null;
    }

    //Depreciated
    public PageReference GoToReadyToBillPDF() {
        /*
        selectedTMsIds = '';
        for (Integer i = 0; i < theTMListPerStatus.size(); i++) {
            if (theTMListPerStatus[i].isSelected) {

                if (i != 0) selectedTMsIds += ',';
                selectedTMsIds += theTMListPerStatus[i].theTM.Id;
            }
        }

        if (string.isEmpty(selectedTMsIds)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select at least one T&M.'));
            return null;
        }
         */
        return null;
    }

    // 14472
    public Map<Id, String> tmlIdwithContractLineTMDescription {get; set;}
    public void getContractLineTMDescription () {
        tmlIdwithContractLineTMDescription = TMLLinesService.retrieveContractLinesTMDescription(theTMLList);
    }

    //Depreciated
    public void PrintBillingTM() {
        /*
        List<TM__c> lstTM = new List<TM__c>();
        List<TM_Line__c> lstTML = new List<TM_Line__c>();
        theReadyTobillTMList = new List<TMReadyToBillWrapper>();
        TMReadyToBillWrapper theReadyTobillTM;

        string selectedTMIds = ApexPages.CurrentPage().getParameters().get('selectedTMIds');

        List<string> lstSelectedTMIds = new List<string>();
        lstSelectedTMIds = selectedTMIds.split(',');

        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' , Contract__r.Name, Bill_To_Customer__r.Name, Bill_To_Customer__r.AccountNumber';
        strQuery += ', Bill_To_Customer__r.Account_Executive__r.Name,Sales_Order__r.Name,Tax_Area__r.Name';
        strQuery += ', Account_Executive__r.Name, Project_Coordinator__r.Name, Contact__r.Name, Contact__r.FirstName, Contact__r.LastName';
        strQuery += ', Bill_to_Customer__r.Pricing_Group__c, Bill_to_Customer__r.BillingCity, Bill_to_Customer__r.BillingStreet';
        strQuery += ', Bill_to_Customer__r.BillingState, Bill_to_Customer__r.BillingPostalCode, Bill_to_Customer__r.BillingCountry';
        strQuery += ', Bill_to_Customer__r.Payment_Term__c, Contract__r.Allow_Lunch_Time_on_Equipment__c,Sales_Order__r.Sales_Order_Type__r.Name, Bill_to_Customer__r.Print_TM_Time_Detail__c';
        strQuery += ' FROM TM__c WHERE Id IN: lstSelectedTMIds';
        lstTM = Database.query(strQuery);

        if (lstTM != null && lstTM.size() > 0) {
            Map<String, Schema.SObjectField> fields1 = Schema.SObjectType.TM_Line__c.fields.getMap();
            lstFields = new List<String>();
            for (Schema.SObjectField field : fields1.values()) {
                lstFields.add(field.getDescribe().getName());
            }
            strQuery = 'SELECT ' + String.join(lstFields, ',');
            strQuery += ',Unit_of_Measure__r.Name, Resource__r.Name, Resource__r.Description__c, Resource_Type__r.Name,Job_Type__r.Name';
            strQuery += ' ,Service_Center__r.Name, Resource__r.Silver_Rate__c, Resource__r.Silver_ER_Rate__c, Resource__r.Platinum_Rate__c, Resource__r.Fleet_Number__c, ' +
                    'Resource__r.Platinum_ER_Rate__c, Resource__r.Gold_Rate__c, Resource__r.Gold_ER_Rate__c, Resource__r.Unit_of_Measure__c, Contract_Line__r.Name,' +
                    'Facility__r.Name, Container_Size__r.Name, Unit_Weight_Vol__r.Name';
            strQuery += ' FROM TM_Line__c WHERE TM__c IN: lstSelectedTMIds ORDER BY TM__c, Line_No__c';
            lstTML = Database.query(strQuery);

            theTMLList = new List<TM_Line__c>();
            for (TM_Line__c tmline : lstTML) {
                theTMLList.add(tmline);
            }

            getContractLineTMDescription();

            //signatures <<
            Map<Id, SignatureWrapper> mapSignatureWrappersByTMId = new Map<Id, SignatureWrapper>();
            for (TM__c TM : lstTM) {
                mapSignatureWrappersByTMId.put(TM.Id, new SignatureWrapper());
            }

            Set<Id> signatureIds = new Set<Id>();
            //signature request <<

            List<Signature__c> signatures = [SELECT Id, Name, Signer_Role__c, Print_Name__c, TM__c, Signature_Date__c, Customer_Not_Available__c, Request_Signature__c, Signed__c, (SELECT Id FROM Attachments) FROM Signature__c WHERE TM__c IN :lstSelectedTMIds AND Voided__c <> TRUE];
            for (Signature__c signature : signatures) {
                if (mapSignatureWrappersByTMId.containsKey(signature.TM__c)) {
                    SignatureWrapper signatureWrapper = mapSignatureWrappersByTMId.get(signature.TM__c);
            //signature request <<
                    //signature request <<
                    //if (signature.Name == 'supervisor_signature') {
                    if (signature.Signer_Role__c == 'Supervisor') {
                    //signature request >>
                        signatureWrapper.SupervisorName = signature.Print_Name__c;
                        if (signature.Attachments != null && signature.Attachments.size() > 0) {
                            signatureWrapper.SupervisorSignatureFileId = signature.Attachments[0].Id;
                        }
                    }
                    //signature request <<
                    else if (signature.Signer_Role__c == 'Customer A') {
                    //signature request >>
                        signatureWrapper.CustomerName = signature.Print_Name__c;
                        signaturewrapper.CustomerNotAvailable = signature.Customer_Not_Available__c;
                        signatureWrapper.SignatureDate = signature.Signature_Date__c.date();
                        if (signature.Attachments != null && signature.Attachments.size() > 0) {
                            signatureWrapper.CustomerSignatureFileId = signature.Attachments[0].Id;
                        }
                        //signature request <<
                        if (signature.Request_Signature__c == true && signature.Signed__c != true) {
                            signatureWrapper.RequestingSignature = true;
                        }
                        else {
                            signatureWrapper.RequestingSignature = false;
                        }
                        //signature request >>
                    }
                }
            }
            //signatures >>

            for (TM__c TM : lstTM) {
                theReadyTobillTM = new TMReadyToBillWrapper();
                theTMLList = new List<TM_Line__c>();
                theTM = new TM__c();
                theTM = TM;

                //signatures <<
                if (mapSignatureWrappersByTMId.containsKey(theTM.Id)) {
                    SignatureWrapper signatureWrapper = mapSignatureWrappersByTMId.get(theTM.Id);
                    theReadyTobillTM.SupervisorSignatureFileId = signatureWrapper.SupervisorSignatureFileId;
                    theReadyTobillTM.CustomerSignatureFileId = signatureWrapper.CustomerSignatureFileId;
                    theReadyTobillTM.CustomerNotAvailable = signatureWrapper.CustomerNotAvailable;
                    theReadyTobillTM.SignatureDate = signatureWrapper.SignatureDate;
                    theReadyTobillTM.CustomerName = signatureWrapper.CustomerName;
                    theReadyTobillTM.SupervisorName = signatureWrapper.SupervisorName;
                }
                //signatures >>

                for (TM_Line__c TML : lstTML) {
                    if (TML.TM__c == TM.Id) {
                        theTMLList.add(TML);
                    }
                }

                CalculateTotalLabor();
                CalculateTotalEquipment();
                CalculateTotalMaterials();
                CalculateTotalSubcontractors();
                CalculateTotalWasteDisposal();
                CalculateTotalDemurrage();
                CalculateTotalLumpSum();
                CalculateTotalMisc();
                CalculateTotalOrder();

                theReadyTobillTM.theTM = TM;
                theReadyTobillTM.theTMLListLabor = TMLListLabor;
                theReadyTobillTM.theTMLListEquipment = theTMLListEquipment;
                theReadyTobillTM.theTMLListMaterials = theTMLListMaterials;
                theReadyTobillTM.theTMLListSubcontractors = theTMLListSubcontractors;
                theReadyTobillTM.theTMLListWasteDisposal = theTMLListWasteDisposal;
                theReadyTobillTM.theTMLListDemurrage = theTMLListDemurrage;
                theReadyTobillTM.theTMLListLumpSum = theTMLListLumpSum;
                theReadyTobillTM.theTMLListMisc = theTMLListMisc;
                theReadyTobillTM.TMLSubtotalLabor = TMLSubtotalLabor;
                theReadyTobillTM.TMLTaxTotalLabor = TMLTaxTotalLabor;
                theReadyTobillTM.TMLTotalLabor = TMLTotalLabor;
                theReadyTobillTM.TMLSubtotalEquipment = TMLSubtotalEquipment;
                theReadyTobillTM.TMLTaxTotalEquipment = TMLTaxTotalEquipment;
                theReadyTobillTM.TMLTotalEquipment = TMLTotalEquipment;
                theReadyTobillTM.TMLSubtotalMaterials = TMLSubtotalMaterials;
                theReadyTobillTM.TMLTaxTotalMaterials = TMLTaxTotalMaterials;
                theReadyTobillTM.TMLTotalMaterials = TMLTotalMaterials;
                theReadyTobillTM.TMLSubtotalSubcontractors = TMLSubtotalSubcontractors;
                theReadyTobillTM.TMLTaxTotalSubcontractors = TMLTaxTotalSubcontractors;
                theReadyTobillTM.TMLTotalSubcontractors = TMLTotalSubcontractors;
                theReadyTobillTM.TMLSubtotalWasteDisposal = TMLSubtotalWasteDisposal;
                theReadyTobillTM.TMLTaxTotalWasteDisposal = TMLTaxTotalWasteDisposal;
                theReadyTobillTM.TMLTotalWasteDisposal = TMLTotalWasteDisposal;
                theReadyTobillTM.TMLSubtotalDemurrage = TMLSubtotalDemurrage;
                theReadyTobillTM.TMLTaxTotalDemurrage = TMLTaxTotalDemurrage;
                theReadyTobillTM.TMLTotalDemurrage = TMLTotalDemurrage;
                theReadyTobillTM.TMLSubtotalLumpSum = TMLSubtotalLumpSum;
                theReadyTobillTM.TMLTaxTotalLumpSum = TMLTaxTotalLumpSum;
                theReadyTobillTM.TMLTotalLumpSum = TMLTotalLumpSum;
                theReadyTobillTM.TMLSubtotalMisc = TMLSubtotalMisc;
                theReadyTobillTM.TMLTaxTotalMisc = TMLTaxTotalMisc;
                theReadyTobillTM.TMLTotalMisc = TMLTotalMisc;
                theReadyTobillTM.TMLSubtotal = TMLSubtotal;
                theReadyTobillTM.TMLTaxTotal = TMLTaxTotal;
                theReadyTobillTM.TMLTotal = TMLTotal;
                theReadyTobillTM.laborLinesWithNotes = TMLFieldListLaborWithNotes;
                theReadyTobillTMList.add(theReadyTobillTM);
            }
        }
         */
    }

    //Depreciated
    public class TMReadyToBillWrapper {
        /*
        public TM__c theTM {
            get;
            set;
        }
        public List<TM_Line__c> theTMLListLabor {
            get;
            set;
        }
        public List<TM_Line__c> theTMLListEquipment { get; set; }
        public List<TM_Line__c> theTMLListMaterials {
            get;
            set;
        }
        public List<TM_Line__c> theTMLListSubcontractors {
            get;
            set;
        }
        public List<TM_Line__c> theTMLListWasteDisposal {
            get;
            set;
        }
        public List<TM_Line__c> theTMLListDemurrage { get; set; }
        public List<TM_Line__c> theTMLListLumpSum {
            get;
            set;
        }
        public List<TM_Line__c> theTMLListMisc {
            get;
            set;
        }

        public Decimal TMLSubtotalLabor {
            get;
            set;
        }
        public Decimal TMLTaxTotalLabor {
            get;
            set;
        }
        public Decimal TMLTotalLabor {
            get;
            set;
        }

        public Decimal TMLSubtotalEquipment { get; set; }
        public Decimal TMLTaxTotalEquipment {
            get;
            set;
        }
        public Decimal TMLTotalEquipment {
            get;
            set;
        }

        public Decimal TMLSubtotalMaterials {
            get;
            set;
        }
        public Decimal TMLTaxTotalMaterials {
            get;
            set;
        }
        public Decimal TMLTotalMaterials {
            get;
            set;
        }

        public Decimal TMLSubtotalSubcontractors {
            get;
            set;
        }
        public Decimal TMLTaxTotalSubcontractors {
            get;
            set;
        }
        public Decimal TMLTotalSubcontractors {
            get;
            set;
        }

        public Decimal TMLSubtotalFieldRemediation {
            get;
            set;
        }
        public Decimal TMLTaxTotalFieldRemediation { get; set; }
        public Decimal TMLTotalFieldRemediation {
            get;
            set;
        }

        public Decimal TMLSubtotalWasteDisposal {
            get;
            set;
        }
        public Decimal TMLTaxTotalWasteDisposal {
            get;
            set;
        }
        public Decimal TMLTotalWasteDisposal {
            get;
            set;
        }

        public Decimal TMLSubtotalDemurrage {
            get;
            set;
        }
        public Decimal TMLTaxTotalDemurrage {
            get;
            set;
        }
        public Decimal TMLTotalDemurrage {
            get;
            set;
        }

        public Decimal TMLSubtotalLumpSum {
            get;
            set;
        }
        public Decimal TMLTaxTotalLumpSum {
            get;
            set;
        }
        public Decimal TMLTotalLumpSum { get; set; }

        public Decimal TMLSubtotalMisc {
            get;
            set;
        }
        public Decimal TMLTaxTotalMisc {
            get;
            set;
        }
        public Decimal TMLTotalMisc {
            get;
            set;
        }

        public Decimal TMLSubtotal {
            get;
            set;
        }
        public Decimal TMLTaxTotal {
            get;
            set;
        }
        public Decimal TMLTotal {
            get;
            set;
        }

        public List<TM_Line__c> theTMLListLaborNotes {
            get;
            set;
        }

        public List<TMLWithNote> laborLinesWithNotes {
            get;
            set;
        }

        //signatures <<
        public Id SupervisorSignatureFileId { get; set; }
        public Id CustomerSignatureFileId { get; set; }
        public Boolean CustomerNotAvailable { set; get; }
        public Date SignatureDate { set; get; }
        public String SupervisorName { set; get; }
        public String CustomerName { set; get; }
        //signature request <<
        public Boolean RequestingSignature { set; get; }
        //signature request >>
        //signatures >>
         */
    }

    //Depreciated
    /*
    //signatures <<
    public class SignatureWrapper {
        public Signature__c Signature { set; get; }
        public Id SupervisorSignatureFileId { get; set; }
        public Id CustomerSignatureFileId { get; set; }
        public Boolean CustomerNotAvailable { set; get; }
        public String SupervisorName { set; get; }
        public String CustomerName { set; get; }
        public Date SignatureDate { set; get; }
        //signature request <<
        public Boolean RequestingSignature { set; get; }
        //signature request >>
    }
    //signatures >>
     */

    public PageReference returnToOpenTMs() {
        return null;
        /*
        PageReference redirectPage = new PageReference('/apex/ProcessTM?flterByStatus=Open');
        redirectPage.setRedirect(true);
        return redirectPage;
         */
    }

    public PageReference ReloadByStatus() {
        return null;
        /*
        PageReference redirectPage = new PageReference('/apex/ProcessTM?flterByStatus=Ready to Bill');
        redirectPage.setRedirect(true);
        return redirectPage;
         */
    }

    //Depreciated
    public PageReference GoToFieldTMMultiplePDF() {
        /*
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
         */
        return null;
    }

    /*
        Ticket#13619
     */
    public PageReference cloneAndSchedule() {
        selectedTMsIds = '';
        for (Integer i = 0; i < theTMWrapList.size(); i++) {
            if (theTMWrapList[i].isSelected) {
                if (i != 0) selectedTMsIds += ',';
                selectedTMsIds += theTMWrapList[i].theTM.Id;
            }
        }

        if (String.isEmpty(selectedTMsIds)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select at least one T&M.'));
            return null;
        } else {
            PageReference ScheduleTMConfirmation = new PageReference('/apex/AddScheduleTMConfirmation?selectedTMId=' + selectedTMsIds + '&actionType=clone');
            ScheduleTMConfirmation.setRedirect(true);
            return ScheduleTMConfirmation;
        }
    }

    public PageReference deleteTMConfirmation() {
        ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, 'You are not allowed to delete T&M.'));
        return null;
    }

    public PageReference setPreviousDate() {
        Date scheduledDate = Date.parse(scheduledDateValue);
        scheduledDate = scheduledDate.addDays(-1);
        scheduledDateValue = scheduledDate.month() + '/' + scheduledDate.day() + '/' + scheduledDate.year();
        return selectTmList();
    }

    public PageReference setNextDate() {
        Date scheduledDate = Date.parse(scheduledDateValue);
        scheduledDate = scheduledDate.addDays(1);
        scheduledDateValue = scheduledDate.month() + '/' + scheduledDate.day() + '/' + scheduledDate.year();
        return selectTmList();
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
        theTMListPerStatus = PaginationByStatus.beginning();
    }

// returns the last page of records
    public void lastpageStatusWrap() {
        theTMListPerStatus = PaginationByStatus.last();
    }

// returns the previous page of records
    public void previouspageStatusWrap() {
        theTMListPerStatus = PaginationByStatus.previous();
    }

// returns the next page of records
    public void nextpageStatusWrap() {
        theTMListPerStatus = PaginationByStatus.next();
    }
/////////////////////////////////////CUSTOM PAGINATION////////////////////////////////////////////////

    //Depreciated
    public PageReference CreateInvoiceFromProcessTM() {
        return null;
        /*
        string selectedTMs = '';
        for (Integer i = 0; i < theTMListPerStatus.size(); i++) {
            if (theTMListPerStatus[i].isSelected) {

                if (i != 0) selectedTMs += ',';
                selectedTMs += theTMListPerStatus[i].theTM.Id;
            }
        }

        if (string.isEmpty(selectedTMs)) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please select atleast one T&M.'));
            return null;
        }

        PageReference BillingPage = new PageReference('/apex/CreateInvoiceFromProcessTM?selectedTMIds=' + selectedTMs); BillingPage.setRedirect(true);
        return BillingPage;
         */
    }

    //Depreciated
    public void CreateSIFromProcessTM() {
        /*
        String selectedTMIds = ApexPages.CurrentPage().getParameters().get('selectedTMIds');

        List<String> lstSelectedTMIds = new List<string>();
        lstSelectedTMIds = selectedTMIds.split(',');

        //Ticket#14585 - add Bill_to_Customer__r.AccountNumber 14554
        String strQuery = 'SELECT Lump_Sum_Order__c, Bill_To_Customer__c, Tax_Area__c, Service_Center__c, Sales_Order__c, Status__c, Account_Executive__c, Customer_PO_No__c, ' +
                'Contact__c, Contract__c, Sales_Invoice__c, Site_Contact_2__c, Site_Name__c, Site_Street__c, Site_City__c, Site_State__c, Site_Phone_No__c, Site_Country__c, Site_Contact__c, ' +
                'Site_Email_Address__c, Tax_Liable__c, Subsidiary_Company__c, Bill_to_Customer__r.Payment_Term__c, Bill_to_Customer__r.Name, Name,Sales_Order__r.Surcharge_Type__c, Sales_Order__r.Surcharge_Pct__c,' +
                'Bill_to_Customer__r.AccountNumber, Billing_Instructions__c, Internal_Comments__c, Site_Postal_Code__c, Site_Scope__c';
        strQuery += ' FROM TM__c WHERE Id IN: lstSelectedTMIds';
        theTMList = Database.query(strQuery);

        if (theTMList != null && theTMList.size() > 0) {
            strQuery = 'SELECT Invoiced__c, Resource_Type__c, Resource__c, Resource_Type__r.Fleet_No_Required__c, Service_Center__r.Equipment_Fleet_No_Not_Required__c, ' +
                    'Resource_Type__r.Name, Description__c, Category__c, Unit_of_Measure__c, Tax_Group__c, Tax_Pct__c, Tax__c, Id, TM__c, Service_Center__c, ' +
                    'Bill_as_Lump_Sum__c, Non_Billable__c, BOL_Manifest__c, TM__r.Scheduled_Date__c, Hour__c, Quantity__c, ' +
                    'Unit_Cost__c, Line_Cost__c, Line_Amount__c, Line_Amt_Incl_Tax__c, Regular_Hours__c, Regular_Rate__c, Use_Premium_Rate__c, ' +
                    'Premium_Hours__c, Premium_Rate__c, Overtime_Hours__c, Overtime_Rate__c, Pick_Up_Rental__c, TM__r.Name, Line_No__c, Pick_Up_R_O__c, ' +
                    'TM__r.Sales_Order__c, Pick_Up_R_O__r.Sales_Order__c, Pick_Up_R_O__r.Resource__c, Unit_Price__c, Drop_Off_Rental__c, Service_Center__r.Temporary__c, Cost_Qty__c,' +
                    'Resource_Type__r.Fuel_Fired_Equipment__c, xRegular_Rate__c,xUnit_Price__c,xPremium_Rate__c,xOvertime_Rate__c,Facility__r.Name, Pricing_Source_2__c,' +
                    'Container_Size__r.Name, Unit_Weight_Vol__r.Name, Container_Size__c, Unit_Weight_Vol__c, Cost_Method__c';

            strQuery += ' FROM TM_Line__c WHERE TM__c IN: lstSelectedTMIds ORDER BY TM__c';
            theTMLList = Database.query(strQuery);
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

    //Depreciated
    public PageReference returnToProcessTM() {
        return null;
        /*
        PageReference redirectPage = new PageReference('/apex/ProcessTM?flterByStatus=Ready to Bill');
        redirectPage.setRedirect(true);
        return redirectPage;
         */
    }

    public PageReference PrintFieldTM() {
        selectedTMsIds = '';
        for (Integer i = 0; i < theTMWrapList.size(); i++) {
            if (theTMWrapList[i].isSelected) {
                if (i != 0) {
                    selectedTMsIds += ',';
                }
                selectedTMsIds += theTMWrapList[i].theTM.Id;
            }
            selectedTMsIds = selectedTMsIds.removeStart(',');
            selectedTMsIds = selectedTMsIds.removeEnd(',');
        }

        if (String.isEmpty(selectedTMsIds)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select at least one T&M.'));
            return null;
        }
        return null;
    }

    public PageReference selectAllTMs() {
        if (theTMWrapList != null && theTMWrapList.size() > 0) {
            for (Integer i = 0; i < theTMWrapList.size(); i++) {
                theTMWrapList[i].isSelected = selectAll;
            }
        }
        return null;
    }

    /*Depreciated
    public List<TM_Line__c > TMLFieldListLabor {
        get {
            TMLFieldListLabor = new List<TM_Line__c>();
            TMLFieldListLabor = TMLListLabor;
            Integer LinesToInsert = 10 - TMLFieldListLabor.size();
            for (Integer i = 0; i < LinesToInsert; i++) {
                TMLFieldListLabor.add(new TM_Line__c(TM__c = theTM.Id));
            }
            return TMLFieldListLabor;
        }
        set {
            TMLFieldListLabor = value;
        }
    }

    public List<TM_Line__c > TMLFieldListLaborNotes {
        get {
            TMLFieldListLaborNotes = new List<TM_Line__c>();
            TMLFieldListLaborNotes = TMLFieldListLabor;
            if (TMLFieldListLaborNotes != null && TMLFieldListLaborNotes.size() > 2) {
                TMLFieldListLaborNotes.remove(0);
                TMLFieldListLaborNotes.remove(1);
            }

            return TMLFieldListLaborNotes;
        }
        set {
            TMLFieldListLaborNotes = value;
        }
    }

    public class TMLWithNote { //Ticket# 14468
        public TM_Line__c tml {get; set;}
        public String note {get; set; }
        public String contractLineTMDescription {get;set;}
        public TMLWithNote(TM_Line__c tml, String note, String contractLineTMDescription){
            this.tml = tml;
            this.note = note;
            this.contractLineTMDescription = contractLineTMDescription;
        }
    }

    public List<TMLWithNote> TMLFieldListLaborWithNotes { // Ticket# 14468
        get {
            TMLFieldListLaborWithNotes = new List<TMLWithNote>();
            Integer count = TMLListLabor.size();
            String note = '';
            for (Integer i = 0; i < count; i++) {
                if (i == 0) {
                    note = 'Lunch Taken:  Yes  No';
                } else if (i == 1) {
                    note = 'If Yes, Time: ';
                } else {
                    note = '';
                }
                TMLFieldListLaborWithNotes.add(new TMLWithNote(TMLListLabor[i], note, tmlIdwithContractLineTMDescription.get(TMLListLabor[i].Id))); // 14472
            }
            if (count == 1){
                TMLFieldListLaborWithNotes.add(new TMLWithNote(new TM_Line__c(TM__c = theTM.Id) , 'If Yes, Time: ', null)); //14472
                count++;
            }
            if (count == 0){ //15223
                TMLFieldListLaborWithNotes.add(new TMLWithNote(new TM_Line__c(TM__c = theTM.Id) , 'Lunch Taken:  Yes  No', null));
                TMLFieldListLaborWithNotes.add(new TMLWithNote(new TM_Line__c(TM__c = theTM.Id) , 'If Yes, Time: ', null));
                count = 2;
            }
            note = '';
            for (Integer i = 0; i < 10 - count; i++) {
                TMLFieldListLaborWithNotes.add(new TMLWithNote(new TM_Line__c(TM__c = theTM.Id) , note, null));
            }
            return TMLFieldListLaborWithNotes;
        }
        set {
            TMLFieldListLaborWithNotes = value;
        }
    }

    public List<TMLWithNote> TMLFieldListEquipment {
        get {
            TMLFieldListEquipment = new List<TMLWithNote>();
            //TMLFieldListEquipment = TMLListEquipment;
            for (TM_Line__c theTML : TMLListEquipment) {
                TMLFieldListEquipment.add(new TMLWithNote(theTML, null, tmlIdwithContractLineTMDescription.get(theTML.Id)));
            }
            // Insert blank lines
            Integer LinesToInsert = 18 - TMLFieldListEquipment.size();
            for (Integer i = 0; i < LinesToInsert; i++) {
                TMLFieldListEquipment.add(new TMLWithNote(new TM_Line__c(TM__c = theTM.Id), null, null));
            }
            return TMLFieldListEquipment;
        }
        set {
            TMLFieldListEquipment = value;
        }
    }

    public List<TMLWithNote > TMLFieldListMaterials {
        get {
            TMLFieldListMaterials = new List<TMLWithNote>();
            //TMLFieldListMaterials = TMLListMaterials;
            for (TM_Line__c theTML : TMLListMaterials) {
                TMLFieldListMaterials.add(new TMLWithNote(theTML, null, tmlIdwithContractLineTMDescription.get(theTML.Id)));
            }

            // Insert blank lines
            Integer LinesToInsert = 18 - TMLFieldListMaterials.size();
            for (Integer i = 0; i < LinesToInsert; i++) {
                TMLFieldListMaterials.add(new TMLWithNote(new TM_Line__c(TM__c = theTM.Id), null, null));
            }
            return TMLFieldListMaterials;
        }
        set {
            TMLFieldListMaterials = value;
        }
    }

    public List<TM_Line__c > TMLFieldListSubcontractors {
        get {
            TMLFieldListSubcontractors = new List<TM_Line__c>();
            TMLFieldListSubcontractors = TMLListSubcontractors;
            Integer LinesToInsert = 3 - TMLFieldListSubcontractors.size();
            for (Integer i = 0; i < LinesToInsert; i++) {
                TMLFieldListSubcontractors.add(new TM_Line__c(TM__c = theTM.Id));
            }
            return TMLFieldListSubcontractors;
        }
        set {
            TMLFieldListSubcontractors = value;
        }
    }

    public List<TM_Line__c > TMLFieldListWasteDisposal {
        get {
            TMLFieldListWasteDisposal = new List<TM_Line__c>();

            //TMLFieldListWasteDisposal = TMLListWasteDisposal;
            for(TM_Line__c tmLine : TMLListWasteDisposal){
                if(tmLine.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name()){
                    tmLine.Unit_of_Measure__c = tmLine.Container_Size__c;
                    tmLine.Unit_of_Measure__r = tmLine.Container_Size__r;
                } else if (tmLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()){
                    tmLine.Unit_of_Measure__c = tmLine.Unit_Weight_Vol__c;
                    tmLine.Unit_of_Measure__r = tmLine.Unit_Weight_Vol__r;
                }
                TMLFieldListWasteDisposal.add(tmLine);
            }

            Integer LinesToInsert = 3 - TMLFieldListWasteDisposal.size();
            for (Integer i = 0; i < LinesToInsert; i++) {
                TMLFieldListWasteDisposal.add(new TM_Line__c(TM__c = theTM.Id));
            }
            return TMLFieldListWasteDisposal;
        }
        set {
            TMLFieldListWasteDisposal = value;
        }
    }
     */

    //Depreciated
    public void PrintFieldMultiplePDF2() {
        /*
        PrintBillingTM();
        if (theReadyTobillTMList == null) {
            theReadyTobillTMList = new List<TMReadyToBillWrapper>();
        }

        if (theReadyTobillTMList != null && theReadyTobillTMList.size() > 0) {
            Integer LinesToInsert = 0;
            for (TMReadyToBillWrapper theReadyTobillTM : theReadyTobillTMList) {
                if (theReadyTobillTM.theTMLListLabor == null) {
                    theReadyTobillTM.theTMLListLabor = new List<TM_Line__c>();
                }

                if (theReadyTobillTM.theTMLListLaborNotes == null) {
                    theReadyTobillTM.theTMLListLaborNotes = new List<TM_Line__c>();
                }

                if (theReadyTobillTM.theTMLListEquipment == null) {
                    theReadyTobillTM.theTMLListEquipment = new List<TM_Line__c>();
                }

                if (theReadyTobillTM.theTMLListMaterials == null) {
                    theReadyTobillTM.theTMLListMaterials = new List<TM_Line__c>();
                }

                if (theReadyTobillTM.theTMLListSubcontractors == null) {
                    theReadyTobillTM.theTMLListSubcontractors = new List<TM_Line__c>();
                }

                if (theReadyTobillTM.theTMLListWasteDisposal == null) {
                    theReadyTobillTM.theTMLListWasteDisposal = new List<TM_Line__c>();
                }

                LinesToInsert = 10 - theReadyTobillTM.theTMLListLabor.size();
                for (Integer i = 0; i < LinesToInsert; i++) {
                    theReadyTobillTM.theTMLListLabor.add(new TM_Line__c(TM__c = theReadyTobillTM.theTM.Id));
                }

                theReadyTobillTM.theTMLListLaborNotes = theReadyTobillTM.theTMLListLabor.clone();
                if (theReadyTobillTM.theTMLListLaborNotes != null && theReadyTobillTM.theTMLListLaborNotes.size() > 2) {
                    theReadyTobillTM.theTMLListLaborNotes.remove(0);
                    theReadyTobillTM.theTMLListLaborNotes.remove(1);
                }

                LinesToInsert = 18 - theReadyTobillTM.theTMLListEquipment.size();
                for (Integer i = 0; i < LinesToInsert; i++) {
                    theReadyTobillTM.theTMLListEquipment.add(new TM_Line__c(TM__c = theReadyTobillTM.theTM.Id));
                }
                //Truncate Description in order to fit on one line
                for (Integer i = 0; i < theReadyTobillTM.theTMLListMaterials.size(); i++) {
                    if(String.isNotBlank(theReadyTobillTM.theTMLListMaterials[i].Description__c) == true) {
                        theReadyTobillTM.theTMLListMaterials[i].Description__c = theReadyTobillTM.theTMLListMaterials[i].Description__c.left(45);
                    }
                }
                LinesToInsert = 18 - theReadyTobillTM.theTMLListMaterials.size();
                for (Integer i = 0; i < LinesToInsert; i++) {
                    theReadyTobillTM.theTMLListMaterials.add(new TM_Line__c(TM__c = theReadyTobillTM.theTM.Id));
                }

                LinesToInsert = 3 - theReadyTobillTM.theTMLListSubcontractors.size();
                for (Integer i = 0; i < LinesToInsert; i++) {
                    theReadyTobillTM.theTMLListSubcontractors.add(new TM_Line__c(TM__c = theReadyTobillTM.theTM.Id));
                }

                LinesToInsert = 3 - theReadyTobillTM.theTMLListWasteDisposal.size();
                for (Integer i = 0; i < LinesToInsert; i++) {
                    theReadyTobillTM.theTMLListWasteDisposal.add(new TM_Line__c(TM__c = theReadyTobillTM.theTM.Id));
                }
            }
        }
         */
    }

    //Daily Roster
    public PageReference saveRoster() {
        List<TM__c> lstTM = new List<TM__c>();

        if (theTMWrapList != null && theTMWrapList.size() > 0) {
            for (TMWrapper wrapper : theTMWrapList) {
                lstTM.add(wrapper.theTM);
            }

            update lstTM;
        }
        return null;
    }

    /* Depreciated
    public PageReference setScheduleDate() {
        if (TM.Scheduled_Date__c == null) {
            scheduledDateValue = '';
        } else {
            scheduledDateValue = TM.Scheduled_Date__c.month() + '/' + TM.Scheduled_Date__c.day() + '/' + TM.Scheduled_Date__c.year();
            stringScheduleDateFilter = TM.Scheduled_Date__c.year() + '-' + TM.Scheduled_Date__c.month() + '-' + TM.Scheduled_Date__c.day();
        }

        if(theTMLListLabor != null && theTMLListLabor.size() > 0){
            Id payRuleId = null;
            if(String.isNotBlank(TM.Sales_Order__r.Pay_Rule__c)){
                payRuleId = TM.Sales_Order__r.Pay_Rule__c;
            }
            if(payRuleId != null){
                TMLLinesService.populateLinesInfo(new Map<TM__c, List<TM_Line__c>>{theTM => theTMLListLabor});
            }
        }
        return null;
    }
     */

    public String scheduledatefilterFormat { get; set; }

    public void setscheduledatefilterFormat() {
        String mon, dt, filterFormat;

        if (dateScheduledDate.month() < 10) mon = '0' + dateScheduledDate.month(); else mon = String.valueOf(dateScheduledDate.month());

        if (dateScheduledDate.day() < 10) dt = '0' + dateScheduledDate.day(); else dt = String.valueOf(dateScheduledDate.day());

        filterFormat = dateScheduledDate.year() + '-' + mon + '-' + dt;
        scheduledatefilterFormat = filterFormat;
    }

    //Depreciated
    public PageReference updateHours() {
        /*
        List<TM_Line__c> lstTML = new List<TM_Line__c>();
        Integer Counter = 0;

        theTMLList = [
                SELECT Category__c, Job_Start_Time__c, Job_End_Time__c, Billing_Start_Time__c, Billing_End_Time__c,Lunch__c, Hour__c
                FROM TM_Line__c
                WHERE (Category__c = :'Equipment')
        ];
        for (TM_Line__c theTML : theTMLList) {
            Decimal Hour = 0;
            if (theTML.Category__c == 'Equipment') {
                Hour = TimeUtils.calculateHours(theTML.Job_Start_Time__c, theTML.Job_End_Time__c);
                if (theTML.Hour__c <> Hour && Hour > 0) {
                    theTML.Hour__c = Hour;
                    Counter += 1;
                    lstTML.add(theTML);
                }
            }
            if (theTML.Category__c == 'Labor') {
                Hour = TimeUtils.calculateHours(theTML.Billing_Start_Time__c, theTML.Billing_End_Time__c) -
                        TMMgmt.calculateLunchHours(theTML.Lunch__c);
                if (theTML.Hour__c <> Hour && Hour > 0) {
                    theTML.Hour__c = Hour;
                    Counter += 1;
                    lstTML.add(theTML);
                }
            }
        }

        if (lstTML != null && lstTML.size() > 0) {
            update lstTML;
        }

        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Counter +
                ' T&M Lines are updated.'));
         */
        return null;
    }

    /*
    public PageReference navToLineFieldLogPage() {
        if(String.isBlank(selectedLaborLineId)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a labor line to continue!'));
            return null;
            //throw new DataException('Please select a labor line to continue!');
        }

        try {
            msave();
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }

        if (ApexPages.hasMessages()) {
            return null;
        }

        PageReference FieldLogEntry = new PageReference('/apex/FieldLogEntry?tmlId=' + selectedLaborLineId + '&tmId=' + theTM.Id);
        FieldLogEntry.setRedirect(true);
        return FieldLogEntry;
    }
     */

    /*
    public Integer countSiteScopeLines {
        get{
            return theTM.Site_Scope__c.countMatches('\n');
        }
    }
     */
}