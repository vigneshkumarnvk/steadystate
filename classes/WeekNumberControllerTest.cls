@isTest
public class WeekNumberControllerTest {


    private static testMethod void Test_WeekNumberController() {

        Week_Number__c WeekNumberRecord =TestDataUtil.WeekNumberRecord ;
        WeekNumberController wn=New WeekNumberController();
        wn.Year=Date.Today().Year();
        wn.CreateWeekNumbers();
        wn.returnBack();
    }

}