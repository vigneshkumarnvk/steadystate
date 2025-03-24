public class EquipmentUtilizationController {

    public static String defaultServiceCenter { get; set; }

    /******************* Method called by the generate document functionality *********************/
    public static List<TMLineWrapper> getTMEquipLinesPDF() {
        String ServiceCenter = System.currentPageReference().getParameters().get('ServiceCenter');
        String startDate = System.currentPageReference().getParameters().get('startDate');
        String endDate = System.currentPageReference().getParameters().get('endDate');

        /*
        system.debug('***ServiceCenter' + ServiceCenter);
        system.debug('***startDate' + startDate);
        system.debug('***endDate' + endDate);
         */
        List<TMLineWrapper> wrapperList = getTMEquipLines(ServiceCenter, startDate, endDate);
        return wrapperList;
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

    public static Decimal getNoWeeks(Date startDate, Date endDate){
        integer noDays = startDate.daysBetween(endDate);
        return (decimal.valueOf(noDays+1)/7).setScale(2,RoundingMode.HALF_UP);
    }
    /******************* Method to retrieve the service centers and populate the picklist *********************/
    @AuraEnabled
    public static List<ReportsUtils.ServiceCenterWrapper> getServiceCenters() {
        // Getting all service centers to show up on picklist
        List<Service_Center__c> serviceCenterList = [
                SELECT Id, Name, Description__c
                FROM Service_Center__c
                ORDER BY Description__c
        ];

        // Get current user's service center
        String userServiceCenter = ReportsUtils.getCurrentUserServiceCenter();

        // Setting the first center found as the default 
        if (defaultServiceCenter == null) {
            defaultServiceCenter = serviceCenterList[0].Id;
        }

        // Populating the service center wrapper list
        List<ReportsUtils.ServiceCenterWrapper> listServiceCenterWrapper = new List<ReportsUtils.ServiceCenterWrapper>();

        // Add All
        // Create new wrapper instance
        ReportsUtils.ServiceCenterWrapper scWrapper = new ReportsUtils.ServiceCenterWrapper();
        scWrapper.Id = 'ALL';
        scWrapper.Name = 'ALL';
        scWrapper.Description = 'ALL Service Centers';
        scWrapper.isDefault = false;
        // Add wrapper to the list
        listServiceCenterWrapper.add(scWrapper);

        for (Service_Center__c sc : serviceCenterList) {

            // Create new wrapper instance
            //ReportsUtils.ServiceCenterWrapper scWrapper = new ReportsUtils.ServiceCenterWrapper();
            scWrapper = new ReportsUtils.ServiceCenterWrapper();
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

    /******************* Method to return the TM Lines and populate the report *********************/
    @AuraEnabled
    public static List<TMLineWrapper> getTMEquipLines(String ServiceCenter, String startDate, String endDate) {
        Map<String, TMHoursWrapper> TMHoursMap = new Map<String, TMHoursWrapper>();
        Map<String, TMLineWrapper> TMLineMap = new Map<String, TMLineWrapper>();

        /*
        system.debug('!!ServiceCenter ' + ServiceCenter);
        system.debug('!!startDate ' + startDate);
        system.debug('!!endDate ' + endDate);
         */

        // Setting the default filter for service center
        if (ServiceCenter == null) {
            ServiceCenter = defaultServiceCenter;
        }

        // Build query
        Id blankResourceId = null;
        String query;
        if (ServiceCenter != 'All') {
            query = 'SELECT Id, Resource_Type__r.Name, Resource__r.Make__c, Resource__r.Model__c, Quantity__c,Resource__r.Resource_Type__r.Name,' +
                    ' Resource__r.VIN__c, Resource__r.Vehicle_Year__c, Resource__r.Name, Fleet_No__c, Resource__r.Fleet_Number__c, ' +
                    ' Total_Job_Hours__c, Resource__r.Service_Center__c, Resource__r.Equipment_Group__c, Resource__r.Resource_Type__r.Equipment_Group__r.Name, ' +
                    ' Resource__r.Goal_hours__c, Resource__r.Service_Center__r.Name, TM__r.Service_Center__c ' +
                    ' FROM TM_Line__c ' +
                    ' WHERE Category__c = \'Equipment\' ' +
                    //	' AND TM__r.Status__c IN (\'Confirmed\', \'Received by Billing\', \'Ready to Bill\', \'Fully Invoiced\' ,\'Closed\')' +
                    ' AND Resource__r.Service_Center__c =: ServiceCenter AND Resource__c != :blankResourceId ';
        } else {
            query = 'SELECT Id, Resource_Type__r.Name, Resource__r.Make__c, Resource__r.Model__c, Quantity__c,Resource__r.Resource_Type__r.Name,' +
                    ' Resource__r.VIN__c, Resource__r.Vehicle_Year__c, Resource__r.Name, Fleet_No__c, Resource__r.Fleet_Number__c, ' +
                    ' Total_Job_Hours__c, Resource__r.Service_Center__c, Resource__r.Equipment_Group__c, Resource__r.Resource_Type__r.Equipment_Group__r.Name, ' +
                    ' Resource__r.Goal_hours__c, Resource__r.Service_Center__r.Name, TM__r.Service_Center__c ' +
                    ' FROM TM_Line__c ' +
                    ' WHERE Category__c = \'Equipment\' ' +
                    //	' AND TM__r.Status__c IN (\'Confirmed\', \'Received by Billing\', \'Ready to Bill\', \'Fully Invoiced\' ,\'Closed\')' +
                    ' AND Resource__c != :blankResourceId ';
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

        query += ' ORDER BY Resource__r.Name';

        // Getting only Equipment TMLines 
        List<TM_Line__c> TMLines = Database.query(query);

        //system.debug('TMLines' + TMLines);
        // Populate TMHoursMap
        for (TM_Line__c line : TMLines) {
            if (TMHoursMap.containsKey(line.Resource__c)) {
                // Getting existing wrapper
                TMHoursWrapper wrapper = TMHoursMap.get(line.Resource__c);
                //wrapper = populateFields(line,wrapper);
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
        string category = 'Equipment';
        List<Resource__c> theResourceList = new List<Resource__c>();
        Map<String, Schema.SObjectField> fields = Schema.SObjectType.Resource__c.fields.getMap();
        List<String> lstFields = new List<String>();
        for (Schema.SObjectField field : fields.values()) {
            lstFields.add(field.getDescribe().getName());
        }
        String strQuery = 'SELECT ' + String.join(lstFields, ',');
        strQuery += ' , Service_Center__r.Name, Resource_Type__r.Equipment_Group__r.Name, Resource_Type__r.Name ';
        strQuery += ' FROM Resource__c ';
        strQuery += ' WHERE (Start_Date__c = null OR Start_Date__c <=: endDateFilter)';
        strQuery += ' AND (End_Date__c = null OR End_Date__c >=: startDateFilter) AND Category__c =: category ';
        if (ServiceCenter != 'All') {
            strQuery += ' AND Service_Center__c =: ServiceCenter';
        }
        strQuery += ' ORDER BY Service_Center__c, Name';

        //system.debug('***strQuery' + strQuery);
        theResourceList = Database.query(strQuery);

        //system.debug('***theResourceList' + theResourceList);
        if (theResourceList != null && theResourceList.size() > 0) {
            for (Resource__c line : theResourceList) {
                TMLineWrapper wrapper = new TMLineWrapper();
                if (!TMHoursMap.containsKey(line.Id)) {
                    wrapper.HomeServiceCenter = line.Service_Center__r.Name;
                    wrapper.ResourceNo = line.Name;
                    wrapper.ResourceName = line.Description__c;
                    wrapper.FleetNumber = line.Fleet_Number__c;
                    wrapper.EquipmentGroup = line.Resource_Type__r.Equipment_Group__r.Name;
                    wrapper.ResourceType = line.Resource_Type__r.Name;
                    //Ticket 13360 >>
                    wrapper.Year = line.Vehicle_Year__c;
                    //Ticket 13360 <<
                    wrapper.Make = line.Make__c;
                    wrapper.Model = line.Model__c;
                    wrapper.VIN = line.VIN__c;
                    wrapper.SC_Hours = 0;
                    wrapper.IC_Hours = 0;
                    wrapper.Total_Hours = 0;
                    wrapper.Utilization = 0;
                    //wrapper.GoalHoursAssigned = 5 * CompanyMgmt.zeroIfNull(line.Goal_hours__c);
                    //wrapper.GoalHoursAssigned = getDaysBetweenExcludeingWeekends(startDateFilter, endDateFilter) * CompanyMgmt.zeroIfNull(line.Goal_hours__c);
                    wrapper.GoalHoursAssigned = 5 * CompanyMgmt.zeroIfNull(line.Goal_hours__c) * getNoWeeks (startDateFilter,endDateFilter);
                    wrapper.Delta = wrapper.Total_Hours - wrapper.GoalHoursAssigned;
                    TMLineMap.put(line.Id, wrapper);
                } else {
                    wrapper.HomeServiceCenter = line.Service_Center__r.Name;
                    wrapper.ResourceNo = line.Name;
                    wrapper.ResourceName = line.Description__c;
                    wrapper.FleetNumber = line.Fleet_Number__c;
                    wrapper.EquipmentGroup = line.Resource_Type__r.Equipment_Group__r.Name;
                    wrapper.ResourceType = line.Resource_Type__r.Name;
                    //Ticket 13360 >>
                    wrapper.Year = line.Vehicle_Year__c;
                    //Ticket 13360 <<
                    wrapper.Make = line.Make__c;
                    wrapper.Model = line.Model__c;
                    wrapper.VIN = line.VIN__c;
                    wrapper.Total_Hours = TMHoursMap.get(line.id).Total_Hours;
                    wrapper.SC_Hours = TMHoursMap.get(line.id).SC_Hours;
                    wrapper.IC_Hours = TMHoursMap.get(line.id).IC_Hours;
                    if (CompanyMgmt.zeroIfNull(wrapper.Total_Hours) != 0) {
                        wrapper.Utilization = wrapper.Total_Hours / (50 * getNoWeeks (startDateFilter,endDateFilter));
                    } else {
                        wrapper.Utilization = 0;
                    }
                    //wrapper.GoalHoursAssigned = 5 * CompanyMgmt.zeroIfNull(line.Goal_hours__c);
                    //wrapper.GoalHoursAssigned = getDaysBetweenExcludeingWeekends(startDateFilter, endDateFilter) * CompanyMgmt.zeroIfNull(line.Goal_hours__c);
                    wrapper.GoalHoursAssigned = 5 * CompanyMgmt.zeroIfNull(line.Goal_hours__c) * getNoWeeks (startDateFilter,endDateFilter);
                    wrapper.Delta = wrapper.Total_Hours - wrapper.GoalHoursAssigned;
                    TMLineMap.put(line.Id, wrapper);
                }
            }
        }

        return TMLineMap.values();
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
        public String HomeServiceCenter { get; set; }
        @AuraEnabled
        public String ResourceNo { get; set; }
        @AuraEnabled
        public String ResourceName {get; set; }
        @AuraEnabled
        public String FleetNumber { get; set; }
        @AuraEnabled
        public String EquipmentGroup { get; set; }
        @AuraEnabled
        public String ResourceType { get; set; }
        @AuraEnabled
        public String Year { get; set; } //Ticket# 13360
        @AuraEnabled
        public String Make { get; set; }
        @AuraEnabled
        public String Model { get; set; }
        @AuraEnabled
        public String VIN { get; set; }
        @AuraEnabled
        public Decimal Total_Hours { get; set; }
        @AuraEnabled
        public Decimal SC_Hours { get; set; }
        @AuraEnabled
        public Decimal IC_Hours { get; set; }
        @AuraEnabled
        public Decimal Utilization { get; set; }
        @AuraEnabled
        public Decimal GoalHoursAssigned { get; set; }
        @AuraEnabled
        public Decimal Delta { get; set; }
    }
}