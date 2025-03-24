global class WeekNumberController {
    public Integer Year { get; set; }
    List<Week_Number__c> theWNList;
    public ApexPages.StandardSetController setCon;

    public WeekNumberController(ApexPages.StandardSetController controller) {
        setCon = controller;
    }

    public WeekNumberController() {

    }

    public PageReference CreateWeekNumbers() {
        if (Year != null && Year >= 2015 && Year <=2050) {
            try {
                List<Week_Number__c> theWNListDel = new List<Week_Number__c>();
                theWNListDel = [SELECT Id, Name FROM Week_Number__c WHERE Year__c =: String.valueOf(Year)];
                
                if(theWNListDel != null && theWNListDel.size() > 0) {
                    try{
                        delete theWNListDel;
                    } catch (Exception e) {
                        throw new DataException(e.getMessage());
                    }
                }
                
                theWNList = new List<Week_Number__c>();
                Week_Number__c theWN;
                Date yearStartDate = Date.newInstance(Year, 1, 1);
                Date weekStartDate = yearStartDate.toStartOfWeek().addDays(1);
                Date weekEndDate = weekStartDate.addDays(6);
                List<Week_Number__c> weekNumbers = [SELECT Id FROM Week_Number__c WHERE Week_Start_Date__c = :weekStartDate AND Week_End_Date__c = :weekEndDate];
                if(weekNumbers.size() == 1){
                    weekStartDate = weekStartDate.addDays(7);
                    weekEndDate = weekEndDate.addDays(7);
                } else if (weekNumbers.size() > 1){
                    throw new DataException('Week Number setup error found! Multiple week number start and end at the same date! ' + weekStartDate + ' -- ' + weekEndDate);
                }

                Integer calculatedYear = yearStartDate.year();
                Integer i = 0;
                while(calculatedYear == Year){
                    theWN = new Week_Number__c();
                    theWN.Week_Start_Date__c = weekStartDate.addDays(7 * i);
                    theWN.Week_End_Date__c = weekEndDate.addDays(7 * i);
                    theWN.Week_No__c = String.valueOf(i + 1);
                    if (theWN.Week_No__c.length() == 1) {
                        theWN.Week_No__c = '0' + theWN.Week_No__c;
                    }
                    theWN.Year__c = String.valueOf(Year);
                    theWN.Name = theWN.Year__c + '/' + theWN.Week_No__c;
                    theWNList.add(theWN);
                    ++i;

                    //get next start date year.
                    calculatedYear = weekStartDate.addDays(7 * i).year();
                }
                insert theWNList;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully created ' + theWNList.size() +' Week Numbers.'));
            } catch (Exception e) {
                throw new DataException(e.getMessage());
            }

        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Year must be between 2015 to 2050.'));
            return null;
        }
        return null;
    }

    public PageReference returnBack() {
        //PageReference pageref = new PageReference('/apex/Administration');
        //PageReference pageref = new PageReference('/a18');
        return new ApexPages.Action('{!List}').invoke();
        //pageref.setRedirect(true);
        //return pageref;
    }

}