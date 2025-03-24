public with sharing class GenerateTimesheetBatch implements Database.Batchable<Service_Center__c> {
    private Date processingDate = null;

    public GenerateTimesheetBatch(Date inputDate){
        processingDate = inputDate;
    }

    public List<Service_Center__c> start(Database.BatchableContext bc){
        List<Service_Center__c> serviceCenters = [
                SELECT Id, Name FROM Service_Center__c
                WHERE Blocked__c != TRUE OR Name = 'USE'];
        return serviceCenters;
    }

    public void execute(Database.BatchableContext bc, List<Service_Center__c> serviceCenters){
        //Company_Setup__c theCompanySetup = CompanyMgmt.getCompanySetup();
        if(processingDate == null){
            throw new DataException('You must input a date!');
        }
        Date startOfWeek = TimeUtils.toStartOfWeek(processingDate);
        //System.debug('Info: startOfWeek ' + startOfWeek);
        Week_Number__c weekNumber = [SELECT Id, Week_Start_Date__c, Week_End_Date__c, Year__c FROM Week_Number__c WHERE Week_Start_Date__c = :startOfWeek LIMIT 1];
        if(weekNumber == null || weekNumber.Id == null){
            throw new DataException('Week number is not setup for date: ' + System.today());
        }
        //System.debug('Info: weekNumber ' + weekNumber.Week_Start_Date__c + ' --- ' + weekNumber.Week_End_Date__c);

        for(Service_Center__c serviceCenter : serviceCenters){
            TimesheetMgmt timesheetMgmt = new TimesheetMgmt();
            timesheetMgmt.autoGeneratePayroll(serviceCenter, weekNumber);
        }
    }

    public void finish(Database.BatchableContext bc){

    }
}