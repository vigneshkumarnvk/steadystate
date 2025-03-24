public with sharing class Mobile_TMSearchController {
    //deprecated
    /*
    @AuraEnabled
    //cache <<
    //public static List<TM__c> Search(String keyword, Date scheduledDate, String userScope, String resource) {
    public static List<TM__c> Search(String keyword, Date scheduledDate, String userScope, String resource, String version) {
    //cache >>
        
        try {
            //cache <<
            String currentVersion = CompanySettingUtil.acvSetting.Mobile_TM_Version_No__c;
            if (version != null && version != currentVersion) {
                throw new DataException('VERSION_ERROR');
            }
            //cache >>

            //schedule date filter
            Date today = system.today();
            String dateFilter  = '';
            if (scheduledDate != null) {
                //dateFilter = '((Scheduled_Date__c = :scheduledDate AND Status__c = \'Scheduled\') OR (Scheduled_Date__c = :today AND Status__c = \'Mobile Review\'))';
                dateFilter = '((Scheduled_Date__c = :scheduledDate AND Status__c = \'Scheduled\') OR (Scheduled_Date__c = :today AND Status__c = \'Mobile Review\') OR (Scheduled_Date__c = null AND Emergency_TM__c = true AND Status__c = \'Scheduled\'))';
            }
            else {
                dateFilter = '(Status__c = \'Scheduled\' OR (Scheduled_Date__c = :today AND Status__c = \'Mobile Review\') OR (Scheduled_Date__c = null AND Emergency_TM__c = true AND Status__c = \'Open\'))';
            }

            User user = GetUserInfo();
            //user service centers <<
            //String serviceCenterName = user.Service_Center__c;
            List<String> myServiceCenters = new List<String>();
            for (User_Service_Center__c usc : [SELECT Service_Center__r.Code__c FROM User_Service_Center__c WHERE User__c = :user.Id]) {
                myServiceCenters.add(usc.Service_Center__r.Code__c);
            }
            //user service centers >>

            //filter set 1
            List<String> filterSet1 = new List<String>();
            //user service centers <<
            if (myServiceCenters.size() > 0) {
                filterSet1.add('Service_Center__r.Code__c IN :myServiceCenters');
            }
            //user service centers >>
            filterSet1.add(dateFilter);

            //filter set 2
            List<String> filterSet2 = new List<String>();
            List<String> resourceFilters = new List<String>();
            resourceFilters.add('Category__c = \'Labor\'');
            List<Id> resourceIds = new List<Id>();
            for (Resource__c res : [SELECT Id FROM Resource__c WHERE User__c = :user.Id]) {
                resourceIds.add(res.Id);
            }
            resourceFilters.add('Resource__c IN : resourceIds');

            Set<Id> tmIds = new Set<Id>();
            String resourceQueryString = 'SELECT Id, TM__c FROM TM_Line__c WHERE ' + String.join(resourceFilters, ' AND ');
            for (TM_Line__c tml : Database.query(resourceQueryString)) {
                tmIds.add(tml.TM__c);
            }
            filterSet2.add('Id IN :tmIds');
            filterSet2.add(dateFilter);

            //keyword filter
            if (String.isNotEmpty(keyword)) {
                String[] fields = new String[] { 'Name', 'Sales_Order__r.Name', 'Bill_to_Customer__r.Name', 'Site_Name__c', 'Site_Street__c', 'Site_Contact__c', 'Site_City__c', 'Site_Postal_Code__c', 'Site_Phone_No__c', 'PO_Reference_No__c' };
                for (Integer i = 0; i < fields.size(); i++) {
                    fields[i] = fields[i] + ' LIKE \'%' + String.escapeSingleQuotes(keyword) + '%\''; 
                }
                filterSet1.add('(' + String.join(fields, ' OR ') + ')');
                filterSet2.add('(' + String.join(fields, ' OR ') + ')');
            }

            //combine filters
            List<String> filters = new List<String>();
            if (userScope == 'My'){
                if (filterSet2.size() > 0) {
                    filters.add('(' + String.join(filterSet2, ' AND ') + ')');
                }
            }
            else {
                if (filterSet1.size() > 0) {
                    filters.add('(' + String.join(filterSet1, ' AND ') + ')');
                }
                if (filterSet2.size() > 0) {
                    filters.add('(' + String.join(filterSet2, ' AND ') + ')');
                }
            }

            String queryString = 'SELECT Id, Name, Status__c, Bill_to_Customer__r.Name, Service_Center__c, Service_Center__r.Id, Service_Center__r.Name, Sales_Order__r.Name, Scheduled_Date__c, Site_Street__c, Site_City__c, Site_State__c, Site_Postal_Code__c, Emergency_TM__c FROM TM__c';
            queryString += ' WHERE ' + String.join(filters, ' OR ');
            queryString += '  ORDER BY Scheduled_Date__c DESC LIMIT 100';
            system.debug('*** ' + queryString);
            List<TM__c> tms = Database.query(queryString);
            return tms;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    
    @AuraEnabled
    public static List<Resource__c> GetLaborResources() {
        try {
            String serviceCenterName = GetUserInfo().Service_Center__c;
            return [SELECT Id, Name, Resource_Type__r.Name, Description__c FROM Resource__c WHERE Category__c = 'Labor' AND Blocked__c <> TRUE AND Service_Center__r.Name = :serviceCenterName ORDER BY Description__c];
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }                
    }
    
    @AuraEnabled
    public static User GetUserInfo() {
        try {
            return [SELECT Id, Name, FirstName, LastName, Service_Center__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }    
    }
    */
}