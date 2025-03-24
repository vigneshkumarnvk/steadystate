public class EmployeeUtilizationController {

    public static String defaultServiceCenter { get; set; }

    /******************* Method called by the generate document functionality *********************/
    public static List<TMLineWrapper> getTMLaborLinesPDF() {
        String ServiceCenter = System.currentPageReference().getParameters().get('ServiceCenter');
        String startDate = System.currentPageReference().getParameters().get('startDate');
        String endDate = System.currentPageReference().getParameters().get('endDate');
        String includeWeekend = System.currentPageReference().getParameters().get('includeWeekend');

        system.debug('***ServiceCenter' + ServiceCenter);
        system.debug('***startDate' + startDate);
        system.debug('***endDate' + endDate);
        system.debug('***includeWeekend' + includeWeekend);
        List<TMLineWrapper> wrapperList = getTMLaborLines(ServiceCenter, startDate, endDate, includeWeekend);
        return wrapperList;
    }

    /******************* Method to return the TM Lines and populate the report *********************/
    @AuraEnabled
    public static List<TMLineWrapper> getTMLaborLines(String ServiceCenter, String startDate, String endDate, String includeWeekend) {
        Map<String, TMHoursWrapper> TMHoursMap = new Map<String, TMHoursWrapper>();
        Map<String, TMLineWrapper> TMLineMap = new Map<String, TMLineWrapper>();

        system.debug('!!ServiceCenter ' + ServiceCenter);
        system.debug('!!startDate ' + startDate);
        system.debug('!!endDate ' + endDate);

        // Setting the default filter for service center
        if (ServiceCenter == null) {
            ServiceCenter = defaultServiceCenter;
        }

        // Setting the default filter for includeWeekend
        if (includeWeekend == null) {
            includeWeekend = 'false';
        }

        // Build query
        Id blankResourceId = null;
        String query;
        if (ServiceCenter != 'All') {
            query = 'SELECT  Id, Name, Description__c, Total_Job_Hours__c, Resource__r.Service_Center__c, Resource__r.Name, TM__r.Service_Center__c, Resource__r.Resource_Type__r.Name, ' +
                    'Service_Center__c, Resource_Type__r.Name, Resource__r.Description__c, Service_Center__r.Name, TM__r.Scheduled_Date__c, Resource__r.Service_Center__r.Name ' +
                    'FROM TM_Line__c ' +
                    'WHERE Category__c = \'Labor\' ' +
                    'AND Resource__r.Service_Center__c =: ServiceCenter AND Resource__c != :blankResourceId ';
        } else {
            query = 'SELECT  Id, Name, Description__c, Total_Job_Hours__c, Resource__r.Service_Center__c, Resource__r.Name, TM__r.Service_Center__c, Resource__r.Resource_Type__r.Name, ' +
                    'Service_Center__c, Resource_Type__r.Name, Resource__r.Description__c, Service_Center__r.Name, TM__r.Scheduled_Date__c, Resource__r.Service_Center__r.Name ' +
                    'FROM TM_Line__c ' +
                    'WHERE Category__c = \'Labor\' ' +
                    'AND Resource__c != :blankResourceId ';
        }
        Date startDateFilter;
        if (startDate != null) {
            startDateFilter = date.valueOf(startDate);
        } else {
            startDateFilter = getLastWeekFirstDate();
        }

        query += 'AND TM__r.Scheduled_Date__c >= :startDateFilter ';

        Date endDateFilter;
        if (endDate != null) {
            endDateFilter = date.valueOf(endDate);
        } else {
            endDateFilter = getLastWeekLastDate();
        }

        query += 'AND TM__r.Scheduled_Date__c <= :endDateFilter ';

        if (!Boolean.valueOf(includeWeekend)) {
            query += 'AND TM__r.Scheduled_Date_Weekend__c != true ';
        }

        query += ' ORDER BY Description__c';

        // Getting only Labor TMLines 
        List<TM_Line__c> TMLines = Database.query(query);
        system.debug('TMLines' + TMLines);
        // Populate HoursMap
        for (TM_Line__c line : TMLines) {
            if (TMHoursMap.containsKey(line.Resource__c)) {
                // Getting existing wrapper
                TMHoursWrapper wrapper = TMHoursMap.get(line.Resource__c);
                wrapper.ResourceId = line.Resource__c;
                if (wrapper.Total_Hours == null) {
                    wrapper.Total_Hours = 0;
                }
                if (wrapper.SC_Hours == null) {
                    wrapper.SC_Hours = 0;
                }
                if (wrapper.IC_Hours == null) {
                    wrapper.IC_Hours = 0;
                }
                // Populating total hours 
                if (wrapper.Total_Hours != null && line.Total_Job_Hours__c != null) {
                    wrapper.Total_Hours = companyMgmt.halfUpTo2D(wrapper.Total_Hours + line.Total_Job_Hours__c);
                }
                // Validate values to populate either SC Hours or IC Hours
                if (line.TM__r.Service_Center__c == line.Resource__r.Service_Center__c) {
                    if (wrapper.SC_Hours != null && line.Total_Job_Hours__c != null) {
                        wrapper.SC_Hours = companyMgmt.halfUpTo2D(wrapper.SC_Hours + line.Total_Job_Hours__c);
                    }
                } else {
                    if (wrapper.IC_Hours != null && line.Total_Job_Hours__c != null) {
                        wrapper.IC_Hours = companyMgmt.halfUpTo2D(wrapper.IC_Hours + line.Total_Job_Hours__c);
                    }
                }
                // Updating wrapper in the map
                TMHoursMap.put(line.Resource__c, wrapper);
            } else {
                // Creating a new wrapper
                TMHoursWrapper wrapper = new TMHoursWrapper();
                wrapper.ResourceId = line.Resource__c;
                // Set initial hours as zero
                wrapper.SC_Hours = 0;
                wrapper.IC_Hours = 0;
                wrapper.Total_Hours = 0;
                // Populate total hours
                if (line.Total_Job_Hours__c != null)
                    wrapper.Total_Hours = companyMgmt.halfUpTo2D(line.Total_Job_Hours__c);
                // Either populate SC Hours or IC Hours
                if (line.TM__r.Service_Center__c == line.Resource__r.Service_Center__c && line.Total_Job_Hours__c != null) {
                    wrapper.SC_Hours = companyMgmt.halfUpTo2D(line.Total_Job_Hours__c);
                } else if (line.Total_Job_Hours__c != null) {
                    wrapper.IC_Hours = companyMgmt.halfUpTo2D(line.Total_Job_Hours__c);
                }
                TMHoursMap.put(line.Resource__c, wrapper);
            }
        }

        //Loop through all resources with proper sortings
        string category = 'Labor';
        List<Resource__c> theResourceList = new List<Resource__c>();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Resource__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' , Service_Center__r.Name, Resource_Type__r.Equipment_Group__r.Name, Resource_Type__r.Name ';
        strQuery += ' FROM Resource__c ';
        strQuery += ' WHERE (Start_Date__c = null OR Start_Date__c <=: startDateFilter)';
        strQuery += ' AND (End_Date__c = null OR End_Date__c >=: endDateFilter) AND Category__c =: category ';
        if (ServiceCenter != 'All') {
            strQuery += ' AND Service_Center__c =: ServiceCenter';
        }
        strQuery += ' ORDER BY Service_Center__r.Name, Name';

        system.debug('***strQuery' + strQuery);
        theResourceList = Database.query(strQuery);

        system.debug('***theResourceList' + theResourceList);
        if (theResourceList != null && theResourceList.size() > 0) {
            for (Resource__c line : theResourceList) {
                TMLineWrapper wrapper = new TMLineWrapper();
                // Not used yet
                if (!TMHoursMap.containsKey(line.Id)) {
                    wrapper.ResourceNo = line.Name;
                    wrapper.Description = line.Description__c;
                    wrapper.ServiceCenter = line.Service_Center__r.Name;
                    if (line.Resource_Type__r.Name != null) {
                        wrapper.ResourceType = line.Resource_Type__r.Name;
                    }
                    // Make sure all hours are set to zero instead of null
                    wrapper.Total_Hours = 0;
                    wrapper.SC_Hours = 0;
                    wrapper.IC_Hours = 0;
                    if (startDateFilter != null && endDateFilter != null) {
                        wrapper.utilization = calculateUtilization(wrapper.Total_Hours, startDateFilter, endDateFilter, Boolean.valueOf(includeWeekend)).setScale(2);
                    } else {
                        wrapper.utilization = 0;
                    }
                    TMLineMap.put(line.Id, wrapper);
                } else {
                    wrapper.ResourceNo = line.Name;
                    wrapper.Description = line.Description__c;
                    wrapper.ServiceCenter = line.Service_Center__r.Name;
                    if (line.Resource_Type__r.Name != null) {
                        wrapper.ResourceType = line.Resource_Type__r.Name;
                    }
                    wrapper.Total_Hours = TMHoursMap.get(line.id).Total_Hours;
                    wrapper.SC_Hours = TMHoursMap.get(line.id).SC_Hours;
                    wrapper.IC_Hours = TMHoursMap.get(line.id).IC_Hours;
                    if (startDateFilter != null && endDateFilter != null) {
                        wrapper.utilization = calculateUtilization(wrapper.Total_Hours, startDateFilter, endDateFilter, Boolean.valueOf(includeWeekend)).setScale(2);
                    } else {
                        wrapper.utilization = 0;
                    }
                    TMLineMap.put(line.Id, wrapper);
                }
            }
        }
        return TMLineMap.values();
    }
    /******************* Method to retrieve the service centers and populate the picklist *********************/
    @AuraEnabled
    public static List<ServiceCenterWrapper> getServiceCenters() {
        // Getting all service centers to show up on picklist
        List<Service_Center__c> serviceCenterList = [
                SELECT Id, Name, Description__c
                FROM Service_Center__c
                ORDER BY Description__c
        ];

        // Get current user's service center
        String userServiceCenter = getCurrentUserServiceCenter();

        // Setting the first center found as the default 
        if (defaultServiceCenter == null) {
            defaultServiceCenter = serviceCenterList[0].Id;
        }

        // Populating the service center wrapper list
        List<ServiceCenterWrapper> listServiceCenterWrapper = new List<ServiceCenterWrapper>();

        // Add All
        // Create new wrapper instance
        ServiceCenterWrapper scWrapper = new ServiceCenterWrapper();
        scWrapper.Id = 'ALL';
        scWrapper.Name = 'ALL';
        scWrapper.Description = 'ALL Service Centers';
        scWrapper.isDefault = false;
        // Add wrapper to the list
        listServiceCenterWrapper.add(scWrapper);

        for (Service_Center__c sc : serviceCenterList) {
            system.debug('scott1/' + sc.Name);

            // Create new wrapper instance
            scWrapper = new ServiceCenterWrapper();
            scWrapper.Id = sc.Id;
            scWrapper.Name = sc.Name;
            if (sc.Description__c != null) scWrapper.Description = sc.Description__c; else scWrapper.Description = sc.Name;

            // If it is the user's service center, set it as default
            if (sc.Name == userServiceCenter) {
                scWrapper.isDefault = true;
                defaultServiceCenter = sc.Id;
            } else {
                scWrapper.isDefault = false;
            }

            // Add wrapper to the list
            listServiceCenterWrapper.add(scWrapper);
        }

        // Return service centers
        return listServiceCenterWrapper;
    }

    /******************* Method to return service center from the current user *********************/
    public static String getCurrentUserServiceCenter() {
        // Getting the current user's service center
        String serviceCenter = [
                SELECT Id, Service_Center__c
                FROM User
                WHERE Id = :UserInfo.getUserId()
        ][0].Service_Center__c;

        // Return service center
        return serviceCenter;
    }

    /******************* Method to calculate utilization *********************/
    public static Decimal calculateUtilization(Decimal TotalHours, Date startDate, Date endDate, Boolean includeWeekend) {
        Integer days = verifyNumberOfDays(startDate, endDate, includeWeekend);
        Decimal utilization = TotalHours / (days * 8);
        return utilization;
    }

    /******************* Method to calculate number of days between two dates *********************/
    public static Integer verifyNumberOfDays(Date startDate, Date endDate, Boolean includeWeekend) {
        Integer days = 0;
        if (includeWeekend) {
            days = startDate.daysBetween(endDate + 1);
        } else {
            days = startDate.daysBetween(endDate + 1);

            // Counting number of weekends to exclude from the total 
            Integer countWeekends = 0;
            for (Integer i = 0; i < days; i++) {
                Datetime dt = Datetime.newInstance(startDate.year(), startDate.month(), startDate.day());
                String dayOfWeek = (dt.addDays(i)).format('E');
                if (dayOfWeek == 'Sat' || dayOfWeek == 'Sun') {
                    countWeekends = countWeekends + 1;
                }
            }

            // Subtracting the number of weekends from the total of days
            if (countWeekends != 0) {
                days = days - countWeekends;
            }
        }
        System.debug('days ' + days);
        return days;
    }

    /******************* GET THE DATE FOR LAST MONDAY *********************/
    @AuraEnabled
    public static Date getLastWeekFirstDate() {
        Date firstDate = system.today().toStartOfWeek().addDays(-6);
        return firstDate;
    }

    /******************* GET THE DATE FOR LAST SUNDAY *********************/
    @AuraEnabled
    public static Date getLastWeekLastDate() {
        Date lastDate = system.today().toStartOfWeek();
        return lastDate;
    }

    /******************* TM LINE Wrapper class *********************/
    public class TMHoursWrapper {
        @AuraEnabled
        public String ResourceId { get; set; }
        @AuraEnabled
        public Decimal Total_Hours { get; set; }
        @AuraEnabled
        public Decimal SC_Hours { get; set; }
        @AuraEnabled
        public Decimal IC_Hours { get; set; }
    }

    public class TMLineWrapper {
        @AuraEnabled
        public String ResourceNo { get; set; }
        @AuraEnabled
        public String ServiceCenter { get; set; }
        @AuraEnabled
        public String ResourceType { get; set; }
        @AuraEnabled
        public String Description { get; set; }
        @AuraEnabled
        public Decimal Total_Hours { get; set; }
        @AuraEnabled
        public Decimal SC_Hours { get; set; }
        @AuraEnabled
        public Decimal IC_Hours { get; set; }
        @AuraEnabled
        public Decimal Utilization { get; set; }
    }

    /******************* Service Center Wrapper class *********************/
    public class ServiceCenterWrapper {
        @AuraEnabled
        public String Id { get; set; }
        @AuraEnabled
        public String Name { get; set; }
        @AuraEnabled
        public String Description { get; set; }
        @AuraEnabled
        public Boolean isDefault { get; set; }
    }
}