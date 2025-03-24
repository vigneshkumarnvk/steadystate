/**
 * Created by Steven on 7/20/2018.
 */

global class TimesheetLineWrapper implements Comparable{

    public Timesheet_Line__c theTL;

    // Constructor
    public TimesheetLineWrapper(Timesheet_Line__c tl){
        theTL = tl;
    }

    // Compare timesheet line based on the date.
    global Integer compareTo(Object compareTo){
        // Cast argument to TimesheetLineWrapper
        TimesheetLineWrapper compareToTheTL = (TimesheetLineWrapper)compareTo;

        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if(theTL.Scheduled_Date__c > compareToTheTL.theTL.Scheduled_Date__c){
            returnValue = 1;
        } else if (theTL.Scheduled_Date__c < compareToTheTL.theTL.Scheduled_Date__c){
            returnValue = -1;
        } else {
            if(theTL.Start_Time__c < compareToTheTL.theTL.Start_Time__c){
                returnValue = -1;
            } else if(theTL.Start_Time__c > compareToTheTL.theTL.Start_Time__c){
                returnValue = 1;
            }
        }

        return returnValue;
    }
}