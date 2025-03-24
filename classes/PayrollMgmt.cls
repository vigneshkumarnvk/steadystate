public with sharing class PayrollMgmt {
	public static Payroll__c validateWeekNo(Payroll__c thePayroll) {
        if (String.isEmpty(thePayroll.Week_Number__c)) {
            return thePayroll;
        } else {
            Week_Number__c WeekNo = [SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c, Year__c FROM Week_Number__c WHERE Id = :thePayroll.Week_Number__c LIMIT 1];
            thePayroll.Week_Number__r = new Week_Number__c(Id = WeekNo.Id, Name = WeekNo.Name);
            
            thePayroll.Start_Date__c = WeekNo.Week_Start_Date__c;
            thePayroll.End_Date__c = WeekNo.Week_End_Date__c;
            thePayroll.Year__c = WeekNo.Year__c;
        }
        return thePayroll;
    }

    public static Week_Number__c getWeekNumber(Id weekNoId){
        return [SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c FROM Week_Number__c WHERE Id = :weekNoId LIMIT 1];
    }

    //Ticket#24469
    public static Boolean isPayrollBlockoutPeriod(){
        String dayInTheWeek = TimeUtils.getCurrentDayNameInLocalTime();
        Integer blockoutStartHour = CompanyMgmt.zeroIfNull(CompanySettingUtil.acvSetting.Payroll_Blockout_Start_Hour__c).intValue();
        Integer blockoutStartMinute = CompanyMgmt.zeroIfNull(CompanySettingUtil.acvSetting.Payroll_Blockout_Start_Minute__c).intValue();
        Integer blockoutEndMinute = CompanyMgmt.zeroIfNull(CompanySettingUtil.acvSetting.Payroll_Blockout_End_Minute__c).intValue();
        if(dayInTheWeek == 'Mon'){
            Integer currentHr = System.now().hour();
            Integer currentMin = System.now().minute();
            if(currentHr == blockoutStartHour && currentMin >= blockoutStartMinute && currentMin <= blockoutEndMinute){
                return true;
            }
        }
        return false;
    }
}