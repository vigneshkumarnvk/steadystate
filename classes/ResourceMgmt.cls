public with sharing class ResourceMgmt {
    /*
    public static Map<string, List<TM_Line__c>> mapAllTML = new Map<string, List<TM_Line__c>>();
    public static Map<string, List<TM_Line__c>> mapRentalTML = new Map<string, List<TM_Line__c>>();
    public static Map<string, List<Resource_Off__c>> mapAllResourceOff = new Map<string, List<Resource_Off__c>>();
    public static Map<string, List<Rental_Order__c>> mapAllRentalOrders = new Map<string, List<Rental_Order__c>>();
    */
    public static Resource__c validateServiceCenter(Resource__c theResource) {        
        if (String.isEmpty(theResource.Service_Center__c)) {
            return theResource;
        } else {
            Service_Center__c sc = [SELECT Id, Name FROM Service_Center__c WHERE Id = : theResource.Service_Center__c];
            theResource.Service_Center__r = new Service_Center__c(Id = sc.Id, Name = sc.Name);
        }

        return theResource;
    }
    
    public static List<TM_Line__c> selectAllTML(string scheduledDateValue,Set<Date> scheduledDatesSet) {
        Date scheduledDate;
        List<TM_Line__c> theAllTMLList = new List<TM_Line__c>();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Resource__r.Name, TM__r.Scheduled_Date__c,Resource__r.Description__c,TM__r.Sales_Order__r.Name, TM__r.Name, Resource_Type__r.Name, TM__r.Service_Center__r.Name';
        strQuery += ' FROM TM_Line__c ';

        if (string.isNotEmpty(scheduledDateValue)) {
            scheduledDate = date.parse(scheduledDateValue);
            strQuery += ' WHERE TM__r.Scheduled_Date__c =: scheduledDate LIMIT 1000';
        }
        else if (scheduledDatesSet != null) {
            strQuery += ' WHERE TM__r.Scheduled_Date__c =: scheduledDatesSet LIMIT 1000';
        } 
        else {
            strQuery += ' LIMIT 1000';
        }
        
        system.debug('**strQuery' + strQuery);

        theAllTMLList = Database.query(strQuery);
        
        return theAllTMLList;
    }

    public static List<TM_Line__c> selectRentalTML(string scheduledDateValue,Set<Date> scheduledDatesSet) {
        Date scheduledDate;
        set<String> setStatus = new set<string>();
        setStatus.add('Scheduled');
        setStatus.add('Confirmed');
        setStatus.add('Received By Billing');
        setStatus.add('Ready to Bill');

        List<TM_Line__c> theRentalTMLList = new List<TM_Line__c>();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Resource__r.Name, TM__r.Scheduled_Date__c,Resource__r.Description__c,TM__r.Sales_Order__r.Name, TM__r.Sales_Order__c, TM__r.Name, Resource_Type__r.Name, TM__r.Service_Center__r.Name';
        strQuery += ' FROM TM_Line__c WHERE TM__r.Status__c IN :setStatus AND Drop_Off_Rental__c = true AND Drop_Off_R_O__c = null ';

        if (string.isNotEmpty(scheduledDateValue)) {
            scheduledDate = date.parse(scheduledDateValue);
            strQuery += ' AND TM__r.Scheduled_Date__c <=: scheduledDate LIMIT 1000';
        } 
        else if (scheduledDatesSet != null) {
            strQuery += ' AND TM__r.Scheduled_Date__c <=: scheduledDatesSet LIMIT 1000';
        }
        else {
            strQuery += ' LIMIT 1000';
        }
        System.debug('scheduledDatesSet' + scheduledDatesSet);
        System.debug('theQuery' + strQuery);
        theRentalTMLList = Database.query(strQuery);
        
        return theRentalTMLList;
    }

    public static List<Resource_Off__c> selectAllResourceOff(string scheduledDateValue,Set<Date> scheduledDatesSet) {
        Date scheduledDate;
        List<Resource_Off__c> theAllResourceOffList = new List<Resource_Off__c>();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Resource_Off__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Off_Type__r.Name,Resource__r.Name, Service_Center__r.Name, Resource_Service_Center__r.Name';
        strQuery += ' FROM Resource_Off__c ';

        if (string.isNotEmpty(scheduledDateValue)) {
            scheduledDate = date.parse(scheduledDateValue);
            strQuery += ' WHERE Resource_Off__c.Date__c =: scheduledDate LIMIT 1000';
        } 
        else if (scheduledDatesSet != null) {
             strQuery += ' WHERE Resource_Off__c.Date__c =: scheduledDatesSet LIMIT 1000';
        }
        else {
            strQuery += ' LIMIT 1000';
        }

        theAllResourceOffList = Database.query(strQuery);
        
        return theAllResourceOffList;
    }
    
    public static List<Rental_Order__c> selectAllRentalOrders(string scheduledDateValue,Set<Date> scheduledDatesSet) {
        Date scheduledDate;
        List<Rental_Order__c> theAllRentalOrdersList = new List<Rental_Order__c>();
        //mapRentalOrders = new Map<String, Rental_Order__c>();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Rental_Order__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Bill_to_Customer__r.Name, Sales_Order__r.Name, Service_Center__r.Name,Resource__r.Name ';
        strQuery += ' FROM Rental_Order__c ';

        if (string.isNotEmpty(scheduledDateValue)) {
            scheduledDate = date.parse(scheduledDateValue);
            strQuery += ' WHERE Drop_Off_Date__c <=: scheduledDate AND (Pick_Up_Date__c >=: scheduledDate OR Pick_Up_Date__c = null) LIMIT 1000';
        } 
            // This may not make sense if there are multiple dates in the set
        else if (scheduledDatesSet != null) {
            strQuery += ' WHERE Drop_Off_Date__c <=: scheduledDatesSet AND (Pick_Up_Date__c >=: scheduledDatesSet OR Pick_Up_Date__c = null) LIMIT 1000';
        }
        else {
            strQuery += ' LIMIT 1000';
        }

        theAllRentalOrdersList = Database.query(strQuery);
        
        return theAllRentalOrdersList;
    }

    //Ticket#13910
    public static List<TM_Line__c> getAllTMLinesByResIdSetAndDate(Set<Id> resIdSet, String fromDate){
        Date scheduledDate;
        List<TM_Line__c> theAllTMLList = new List<TM_Line__c>();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.TM_Line__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ', Resource__r.Name, TM__r.Scheduled_Date__c,Resource__r.Description__c,TM__r.Sales_Order__r.Name, TM__r.Name, Resource_Type__r.Name, TM__r.Service_Center__r.Name';
        strQuery += ' FROM TM_Line__c ';

        if (String.isNotEmpty(fromDate)) {
            scheduledDate = date.parse(fromDate);
            strQuery += ' WHERE TM__r.Scheduled_Date__c =: scheduledDate AND Resource__c IN :resIdSet';
        }

        theAllTMLList = Database.query(strQuery);

        return theAllTMLList;
    }
}