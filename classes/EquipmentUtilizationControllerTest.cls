@isTest
public class EquipmentUtilizationControllerTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        Service_Center__c ServiceCenterRecord = TestDataUtil.ServiceCenterRecord;
        TM_Line__c TML= TestDataUtil.TMLineEquipmentRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }

    public static testmethod void Test_EquipmentUtilizationController() {
        Service_Center__c ServiceCenterRecord = [Select Id From Service_Center__c Limit 1];
		TM_Line__c TML = [Select Id,Description__c,Line_No__c,Job_Start_Time__c,Job_End_Time__c,Site_Start_Time__c,Category__c,Resource_Type__c,Resource__c,Service_Center__c 
                             	,TM__r.Name,Bill_as_Lump_Sum__c,Non_Billable__c,Site_End_Time__c,Lunch_Start_Time__c,
                                Line_Amount__c,Line_Amt_Incl_Tax__c,Regular_Rate__c,Sales_Line__c,
                                Lunch_End_Time__c,Unit_of_Measure__c,Quantity__c,Unit_Price__c From TM_Line__c Where Category__c =: 'Equipment' Limit 1]; 
        
        EquipmentUtilizationController.getTMEquipLinesPDF();
        EquipmentUtilizationController.getLastWeekFirstDate();
        EquipmentUtilizationController.getLastWeekLastDate();
        List<ReportsUtils.ServiceCenterWrapper> ServiceC = EquipmentUtilizationController.getServiceCenters();
        

        EquipmentUtilizationController.TMLineWrapper tmr = new EquipmentUtilizationController.TMLineWrapper();
        tmr.HomeServiceCenter = 'test';
        tmr.ResourceNo = 'test';
        tmr.FleetNumber = 'test';
        tmr.EquipmentGroup = 'test';
        tmr.ResourceType = 'test';
        //tmr.Year = '2008';
        tmr.Make = 'test';
        tmr.Model = 'test';
        tmr.VIN = 'test';
        tmr.Total_Hours = 10;
        tmr.SC_Hours = 10;
        tmr.IC_Hours = 10;
        tmr.Utilization = 10;
        tmr.GoalHoursAssigned = 10;
        tmr.Delta = 10;

        //EquipmentUtilizationController.populateFields(TestDataUtil.TMLineLaborRecord, tmr);
        Date SD=Date.Today().AddDays(-10);
        Date ED=Date.Today().AddDays(10);
        string STS = String.valueof(SD.Year()) + '-' + String.valueof(SD.Month()) + '-' + String.valueof(SD.Day()) +  ' 05:05:05';
        string ETS = String.valueof(ED.Year()) + '-' + String.valueof(ED.Month()) + '-' + String.valueof(ED.Day()) +  ' 05:05:05';
        EquipmentUtilizationController.getTMEquipLines('All',STS,ETS);
        
        EquipmentUtilizationController.TMHoursWrapper tmh = new EquipmentUtilizationController.TMHoursWrapper(); 
        tmh.ResourceId='1234';       
        tmh.Total_Hours=10;       
        tmh.SC_Hours=10;       
        tmh.IC_Hours=10;                               
    }

}