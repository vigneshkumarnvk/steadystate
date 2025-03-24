global class ResourceController {
    private final ApexPages.StandardController theController;
    private String currUser;
    public User theUser { get; set; }
    public Service_Center__c theSC { get; set; }
    public String scheduledDateValue { get; set; }
    public List<TM_Line__c> theAllTMLList;
    public List<TM_Line__c> theRentalTMLList;
    public List<Resource_Off__c> theAllResourceOffList;
    public List<Rental_Order__c> theAllRentalOrdersList;
    Map<String, TM_Line__c> mapResourceTML;
    Map<String, Resource_Off__c> mapResourceOff;
    Map<String, Rental_Order__c> mapRentalOrders;
    Map<String, TM_Line__c> mapRentalTML;
    public List<ResourceWrapper> theResourceWrapList { get; set; }
    public List<Resource__c> theResourceList;
    public ApexPages.StandardSetController stdCon;
    public String filterInput { get; set; }
    public String selFilterField { get; set; }
    public String selFilterOp { get; set; }
    Integer pageSize = 200;
    private Integer recordListSize;
    public String offType { get; set; }
    public String calledFrom { get; set; }
    public String orderBy;
    public String orderBy_old;
    public String order;
    public String category = '';

    public ResourceController(ApexPages.StandardController controller) {
        theResourceWrapList = new List<ResourceWrapper>();
        String scheduledDate = ApexPages.currentPage().getParameters().get('scheduledDate');
        if (!String.isEmpty(scheduledDate)) {
            scheduledDateValue = scheduledDate;
        } else {
            scheduledDateValue = Date.today().month() + '/' + Date.today().day() + '/' + Date.today().year();
        }

        category = 'Labor';
        if (CompanyMgmt.getVFPageName() == 'EquipmentRoster') {
            category = 'Equipment';
        }

        currUser = UserInfo.getUserId();
        theController = controller;
        selectUser();
        selectServiceCenter();
        selectResourceList();
    }

    public PageReference selectResourceList() {

        theResourceList = new List<Resource__c>();

        String theSCId = theUser.Service_Center__c;

        category = 'Labor';
        if (CompanyMgmt.getVFPageName() == 'EquipmentRoster') {
            category = 'Equipment';
        }

        Date scheduledDate;
        scheduledDate = Date.parse(scheduledDateValue);
        // 14523 >>
        Set<Id> awaySCResourceId = new Set<Id>();

        List<TM_Line__c> awaySCTMLines = TMLinesSelector.newInstance().selectAwayServiceCenterLinesByScheduledDateServiceCenterAndCategory(scheduledDate, theSCId, category);
        for (TM_Line__c theTML : awaySCTMLines) {
            if (theTML.Resource__c != null) awaySCResourceId.add(theTML.Resource__c);
        }

        if(category == 'Labor'){
            List<Resource_Off__c> borrowedResResOffs = ResourceOffsSelector.newInstance().selectBorrowedResOffByDate(theSCId, scheduledDate);
            for(Resource_Off__c resourceOff:borrowedResResOffs){
                if(resourceOff.Resource__c != null) awaySCResourceId.add(resourceOff.Resource__c);
            }
        }
        System.debug('Info: awaySCResourceId ' + awaySCResourceId);
        // 14523 <<
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Resource__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Service_Center__r.Name, Resource_Type__r.Name ';
        strQuery += ' FROM Resource__c WHERE ((Category__c =: category ';
        strQuery += ' AND Service_Center__r.Name =: theSCId AND Status__c != \'OOS-Pending\'' +
                ' AND (Start_Date__c = null OR Start_Date__c <= :scheduledDate) ';
        strQuery += ' AND (End_Date__c = null OR End_Date__c >= :scheduledDate)) OR Id IN :awaySCResourceId)'; // 14523

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

        if (!String.isEmpty(orderBy)) {
            
            if (orderBy == 'Resource_Type__c') {
                orderBy = 'Resource_Type__r.Name';
            }
            strQuery += ' ORDER BY ' + orderBy + ' ' + order + ' NULLS LAST';
        } else {
            strQuery += ' ORDER BY NAME' ;
        }

        strQuery += ' LIMIT 1000';

        theResourceList = Database.query(strQuery);
        stdCon = new ApexPages.StandardSetController(Database.getQueryLocator(strQuery));
        stdCon.setPageSize(pageSize);
        theResourceWrapList = new List<ResourceWrapper>();

        if (theResourceList != null && theResourceList.size() > 0) {
            recordListSize = theResourceList.size();
        }
        return null;
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
                if (CompanyMgmt.getVFPageName() == 'PersonnelRoster') {
                    lstFilterField.add(new SelectOption('Description__c', 'Name'));
                    lstFilterField.add(new SelectOption('Name', 'No.'));
                } else if (CompanyMgmt.getVFPageName() == 'EquipmentRoster') {
                    lstFilterField.add(new SelectOption('Name', 'No.'));
                    lstFilterField.add(new SelectOption('Fleet_Number__c', 'Fleet Number'));
                    lstFilterField.add(new SelectOption('Description__c', 'Name'));
                    lstFilterField.add(new SelectOption('Resource_Type__r.Name', 'Resource Type'));
                }
            }
            return lstFilterField;
        }
        set;
    }

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
        if (theUser.Service_Center__c == null) {
            throw new DataException('You must set up Service Center for User: ' + theUser.Name);
        }
        String theSCId = theUser.Service_Center__c;
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ',Subsidiary_Company__r.Name';
        strQuery += ' FROM Service_Center__c WHERE Name = :theSCId LIMIT 1';
        theSC = Database.query(strQuery);
    }

    //Ticket#13910
    private void rosterPagesGetAllTML(Set<Id> resIdSet){
        theAllTMLList = new List<TM_Line__c>();
        mapResourceTML = new Map<String, TM_Line__c>();
        theAllTMLList = ResourceMgmt.getAllTMLinesByResIdSetAndDate(resIdSet, scheduledDateValue);

        if (theAllTMLList != null && theAllTMLList.size() > 0) {
            for (TM_Line__c theTML : theAllTMLList) {
                mapResourceTML.put(theTML.Resource__c, theTML);
            }
        }
    }

    private void selectRentalTML() {
        theRentalTMLList = new List<TM_Line__c>();
        mapRentalTML = new Map<String, TM_Line__c>();

        theRentalTMLList = ResourceMgmt.selectRentalTML(scheduledDateValue,null);

        if (theRentalTMLList != null && theRentalTMLList.size() > 0) {
            for (TM_Line__c theTML : theRentalTMLList) {
                mapRentalTML.put(theTML.Resource__c, theTML);
            }
        }
    }

    private void selectAllResourceOff() {
        theAllResourceOffList = new List<Resource_Off__c>();
        mapResourceOff = new Map<String, Resource_Off__c>();

        theAllResourceOffList = ResourceMgmt.selectAllResourceOff(scheduledDateValue,null);

        if (theAllResourceOffList != null && theAllResourceOffList.size() > 0) {
            for (Resource_Off__c theResourceOff : theAllResourceOffList) {
                mapResourceOff.put(theResourceOff.Resource__c, theResourceOff);
            }
        }
    }

    private void selectAllRentalOrders() {
        theAllRentalOrdersList = new List<Rental_Order__c>();
        mapRentalOrders = new Map<String, Rental_Order__c>();

        theAllRentalOrdersList = ResourceMgmt.selectAllRentalOrders(scheduledDateValue,null);

        if (theAllRentalOrdersList != null && theAllRentalOrdersList.size() > 0) {
            for (Rental_Order__c theRO : theAllRentalOrdersList) {
                mapRentalOrders.put(theRO.Resource__c, theRO);
            }
        }
    }

    
    public static String getCostPlusMESResourceId() {
        ResourceConfig__mdt config = [SELECT Value__c FROM ResourceConfig__mdt WHERE DeveloperName = 'CostPlusMESResourceId' LIMIT 1];
        return config.Value__c;
    }


    public class ResourceWrapper {
        public Boolean isSelected { get; set; }
        public Resource__c theResource { get; set; }
        //public List<String> salesOrder { get; set; }
        public Map<String,String> mapSalesOrder{get;set;}

        public ResourceWrapper(Resource__c theResource, Map<String,String> mapSalesOrder, Boolean isSelected) {
            this.theResource = theResource;
            this.mapSalesOrder = mapSalesOrder;
            this.isSelected = isSelected;
        }
    }

    // indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return stdCon.getHasNext();
        }
        set;
    }

    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return stdCon.getHasPrevious();
        }
        set;
    }

    // returns the page number of the current page set
    public Integer pageNumber {
        get {
            return stdCon.getPageNumber();
        }
        set;
    }

    // returns the first page of records
    public void first() {
        selectResourceList();
        stdCon.first();
    }

    // returns the last page of records
    public void last() {
        selectResourceList();
        Integer remainder = 0;
        Integer lastPageNumber = 0;
        if((pageSize != null) && (recordListSize != null)){
            remainder = Math.mod(recordListSize, pageSize);
            lastPageNumber = (Integer) (recordListSize / pageSize);
        }
        if (remainder != 0) {
            lastPageNumber = lastPageNumber + 1;
        }
        stdCon.setPageNumber(lastPageNumber);
    }

    // returns the previous page of records
    public void previous() {
        Integer Pagenumber = stdCon.getPageNumber();
        Pagenumber = Pagenumber - 1;
        selectResourceList();
        stdCon.setPageNumber(Pagenumber);
    }

    // returns the next page of records
    public void next() {

        Integer Pagenumber = stdCon.getPageNumber();
        Pagenumber = Pagenumber + 1;
        selectResourceList();
        stdCon.setPageNumber(Pagenumber);

    }

    public String paginationStat {
        get {
            Integer pageRangeStart = ((stdCon.getPageNumber() - 1) * pageSize) + 1;
            Integer pageRangeEnd = stdCon.getPageNumber() * pageSize;
            if (pageRangeEnd > stdCon.getResultSize()) {
                pageRangeEnd = stdCon.getResultSize();
            }
            return 'Showing  ' + pageRangeStart + '  to  ' +
                    pageRangeEnd + '  of  ' + stdCon.getResultSize() ;
        }
    }

    public Boolean hasRecords {
        get {
            return stdCon.getResultSize() > 0;
        }
    }

    public List<ResourceWrapper> ResourceWrapList {
        get {
            Integer i, j;
            ResourceWrapper theResourceWrap;
            stdCon.setPageSize(pageSize);
            theResourceList = (List<Resource__c>) stdCon.getRecords();
            Date scheduledDate = Date.parse(scheduledDateValue);

            //Ticket#13910 >>
            Set<Id> resIdSet = new Set<Id>();
            for(Resource__c res:theResourceList){
                resIdSet.add(res.Id);
            }
            rosterPagesGetAllTML(resIdSet);
            //Ticket#13910 <<

            selectAllResourceOff();
            selectAllRentalOrders();
            selectRentalTML();

            for (i = 0; i < theResourceList.size(); i++) {
                Map<String,String> mapSalesOrder = new Map<String, String>();
                String strSalesOrder = '';
                //Get T&M
                if (mapResourceTML.containsKey(theResourceList[i].Id)) {
                    for (j = 0; j < theAllTMLList.size(); j++) {

                        if (theAllTMLList[j].Resource__c == theResourceList[i].Id) {
                            if (!String.isEmpty(theAllTMLList[j].TM__r.Sales_Order__r.Name)) {
                                String note = '';
                                if (theAllTMLList[j].TM__r.Service_Center__c != theResourceList[i].Service_Center__c &&
                                        theResourceList[i].Service_Center__c != null && theAllTMLList[j].TM__r.Service_Center__c != null) {
                                    if(theUser.Service_Center__c != theResourceList[i].Service_Center__r.Name) {
                                        note = 'Borrowed from SC ' + theResourceList[i].Service_Center__r.Name;
                                    } else {
                                        note = 'Shared with SC  ' + theAllTMLList[j].TM__r.Service_Center__r.Name;
                                    }
                                }

                                strSalesOrder = theAllTMLList[j].TM__r.Sales_Order__r.Name + '/' + theAllTMLList[j].TM__r.Name + ' ' + note;

                                if (!mapSalesOrder.containsKey(theAllTMLList[j].TM__r.Id)){
                                    mapSalesOrder.put(theAllTMLList[j].TM__r.Id, strSalesOrder);
                                }
                            }
                        }
                    }
                }
                //Get Offs
                if (mapResourceOff.containsKey(theResourceList[i].Id)) {
                    for (j = 0; j < theAllResourceOffList.size(); j++) {
                        if (theAllResourceOffList[j].Resource__c == theResourceList[i].Id) {
                            String note = '';
                            if (!String.isEmpty(theAllResourceOffList[j].Off_Type__r.Name)) {
                                if(theAllResourceOffList[j].Service_Center__c != theAllResourceOffList[j].Resource_Service_Center__c &&
                                        theAllResourceOffList[j].Resource_Service_Center__c != null && theAllResourceOffList[j].Service_Center__c != null){

                                    if(theUser.Service_Center__c != theAllResourceOffList[j].Resource_Service_Center__r.Name) {
                                        note = 'Borrowed from SC ' + theAllResourceOffList[j].Resource_Service_Center__r.Name;
                                    } else {
                                        note = 'Shared with SC  ' + theAllResourceOffList[j].Service_Center__r.Name;
                                    }
                                }
                                if (!String.isEmpty(theAllResourceOffList[j].Note__c)) {
                                    mapSalesOrder.put(theAllResourceOffList[j].Id, theAllResourceOffList[j].Off_Type__r.Name + ' ' + theAllResourceOffList[j].Note__c + ' ' + note);
                                } else {
                                    mapSalesOrder.put(theAllResourceOffList[j].Id, theAllResourceOffList[j].Off_Type__r.Name + ' ' + note);
                                }
                            }
                        }
                    }
                } else if ((theResourceList[i].Status__c == 'Out of Service') && (theResourceList[i].Out_of_Service_Date__c <= scheduledDate)){
                    mapSalesOrder.put('Nolink', 'OOS-On Lot'); //Out of Service labeled OOS-On Lot
                }
                
                //rental Orders
                if (mapRentalOrders.containsKey(theResourceList[i].Id)) {
                    for (j = 0; j < theAllRentalOrdersList.size(); j++) {
                        if (theAllRentalOrdersList[j].Resource__c == theResourceList[i].Id) {
                        if (!String.isEmpty(theAllRentalOrdersList[j].Name)) {
                            if (theAllRentalOrdersList[j].Service_Center__c != theResourceList[i].Service_Center__c) {
                                    mapSalesOrder.put(theAllRentalOrdersList[j].Id, theAllRentalOrdersList[j].Sales_Order__r.Name + '/' + theAllRentalOrdersList[j].Name + ' Shared with SC: ' + theAllRentalOrdersList[j].Service_Center__r.Name);
                            } else {
                                    mapSalesOrder.put(theAllRentalOrdersList[j].Id, theAllRentalOrdersList[j].Sales_Order__r.Name + '/' + theAllRentalOrdersList[j].Name);
                                }
                            }
                        }
                    }
                }

                //Get Pending Rental T&M
                if (mapRentalTML.containsKey(theResourceList[i].Id)) {
                    for (j = 0; j < theRentalTMLList.size(); j++) {
                        if (theRentalTMLList[j].Resource__c == theResourceList[i].Id) {
                            if (!String.isEmpty(theRentalTMLList[j].TM__r.Sales_Order__r.Name)) {
                                if (theRentalTMLList[j].TM__r.Service_Center__c != theResourceList[i].Service_Center__c) {
                                    strSalesOrder = theRentalTMLList[j].TM__r.Sales_Order__r.Name + '/' + theRentalTMLList[j].TM__r.Name + ' Shared with SC: ' + theAllTMLList[j].TM__r.Service_Center__r.Name;
                                } else {
                                    strSalesOrder = theRentalTMLList[j].TM__r.Sales_Order__r.Name + '/' + theRentalTMLList[j].TM__r.Name;
                                }
                                strSalesOrder = 'Drop Off/' + strSalesOrder;
                                if (!mapSalesOrder.containsKey(theRentalTMLList[j].TM__r.Id)){
                                    mapSalesOrder.put(theRentalTMLList[j].TM__r.Id, strSalesOrder);
                                }
                            }
                        }
                    }
                }

                if (mapSalesOrder == null) {
                    mapSalesOrder.put('Nolink', 'Available');
                }

                theResourceWrap = new ResourceWrapper(
                        theResourceList[i],
                        mapSalesOrder,
                        false
                );
                theResourceWrapList.add(theResourceWrap);
            }
            return theResourceWrapList;
        }
        set {
            theResourceWrapList = value;
        }
    }

    public PageReference setPreviousDate() {
        Date scheduledDate = Date.parse(scheduledDateValue);
        scheduledDate = scheduledDate.addDays(-1);
        scheduledDateValue = scheduledDate.month() + '/' + scheduledDate.day() + '/' + scheduledDate.year();
        return selectResourceList();
    }

    public PageReference setNextDate() {
        Date scheduledDate = Date.parse(scheduledDateValue);
        scheduledDate = scheduledDate.addDays(1);
        scheduledDateValue = scheduledDate.month() + '/' + scheduledDate.day() + '/' + scheduledDate.year();
        return selectResourceList();
    }

    public PageReference resourceOff() {
        String selectedResources = '';
        for (Integer i = 0; i < theResourceWrapList.size(); i++) {
            if (theResourceWrapList[i].isSelected) {
                if (i != 0) {
                    selectedResources += ',';
                }

                selectedResources += theResourceWrapList[i].theResource.Id;
            }
        }

        //Ticket#14523
        if (String.isEmpty(selectedResources) && offType != 'borrowedResShopTime') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select at least one resource.'));
            return null;
        }

        PageReference ResourceOff = new PageReference('/apex/ResourceOff?selectedResourcesIds=' + selectedResources +
                '&RosterDate=' + scheduledDateValue + '&offType=' + offType +
                '&calledFrom=' + calledFrom + '&selectedSC=' + theUser.Service_Center__c); //Ticket 13326
        ResourceOff.setRedirect(true);
        return ResourceOff;
    }
    
    public List<String> lstFields {
        get {

            lstFields = new List<String>();
            if (category == 'Equipment') {
                lstFields.add('Name');
                lstFields.add('Fleet_Number__c');
                lstFields.add('Description__c');
                lstFields.add('Resource_Type__c');
            }
            
            if (category == 'Labor') {
                lstFields.add('Name');
                lstFields.add('Description__c');
                lstFields.add('Resource_Type__c');
            }
            

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
        selectResourceList();
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

    @AuraEnabled(cacheable=true)
    public static boolean isSystemAdmin(){
    
            User currentUser = [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            Boolean isAdmin = currentUser.Profile.Name == 'System Administrator';
            return isAdmin;
      
    }
}