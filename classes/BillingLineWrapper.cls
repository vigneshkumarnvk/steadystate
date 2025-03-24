global class BillingLineWrapper implements Comparable {

    public BillingLine billingLine;

    //Contractor
    public BillingLineWrapper(BillingLine line){
        billingLine = line;
    }

    //Compare billing line based on schedule date.
    global Integer compareTo(Object compareTo){
        BillingLineWrapper compareToTheBillingLine = (BillingLineWrapper)compareTo;

        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if(billingLine.ScheduleDate > compareToTheBillingLine.billingLine.ScheduleDate){
            returnValue = 1;
        } else if (billingLine.ScheduleDate < compareToTheBillingLine.billingLine.ScheduleDate){
            returnValue = -1;
        }

        return returnValue;
    }
}