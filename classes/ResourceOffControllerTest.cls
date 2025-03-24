@isTest
public class ResourceOffControllerTest {

    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    @testSetup static void SetupData() {
        //Setup Test Data
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
        Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        List<Company_Setup__c> theCSList = [SELECT Id From Company_Setup__c WHERE Id = : companySetup.Id];
        System.assertEquals(theCSList.size(), 1);
    }

    private static testMethod void Test_ResourceOffController() {
        Resource__c ResourceRecord=TestDataUtil.ResourceLaborRecord;
        TM_Line__c TMLineLaborRecord=TestDataUtil.TMLineLaborRecord;
        Test.setCurrentPageReference(new PageReference('Page.ResourceOff'));
        System.currentPageReference().getParameters().put('selectedResourcesIds', ResourceRecord.id);
        System.currentPageReference().getParameters().put('RosterDate', '12/27/2018');
        System.currentPageReference().getParameters().put('offType', 'Assign');
        ResourceOffController  inst_ROC = new ResourceOffController ();
        inst_ROC.tm=TestDataUtil.TMRecord;

        Test.startTest();

        inst_ROC.theTMLine=TMLineLaborRecord;

        Resource__c newResourceRecord = ResourceRecord.clone();
        newResourceRecord.Name = 'new resource';
        newResourceRecord.External_Unique_Name__c = 'new resource';
        newResourceRecord.VIN__c = '5A3U616D1YL005502Z';
        newResourceRecord.External_ID__c = '34234fdsa';
        insert newResourceRecord;
        inst_ROC.theResourceList.add(newResourceRecord);

        inst_ROC.save();
        inst_ROC.cancel();

        inst_ROC.validateTM();
    }

    //ticket 19130 <<
    private static testMethod void Test_ResourceOffController3() {
        Resource__c ResourceRecord=TestDataUtil.ResourceLaborRecord;
        TM_Line__c TMLineLaborRecord=TestDataUtil.TMLineLaborRecord;
        Test.setCurrentPageReference(new PageReference('Page.ResourceOff'));
        System.currentPageReference().getParameters().put('selectedResourcesIds', ResourceRecord.id);
        System.currentPageReference().getParameters().put('RosterDate', '12/27/2018');
        System.currentPageReference().getParameters().put('offType', 'Assign');
        ResourceOffController  inst_ROC = new ResourceOffController ();
        inst_ROC.tm=TestDataUtil.TMRecord;

        Test.startTest();
        
        TM_Job_Task__c tmJobTask = new TM_Job_Task__c(TM__c = TestDataUtil.TMRecord.Id, Line_No__c = 1, Name = 'Task');
        insert tmJobTask;
        TMLineLaborRecord.TM_Job_Task__c = tmJobTask.Id;

        inst_ROC.theTMLine=TMLineLaborRecord;

        Resource__c newResourceRecord = ResourceRecord.clone();
        newResourceRecord.Name = 'new resource';
        newResourceRecord.External_Unique_Name__c = 'new resource';
        newResourceRecord.VIN__c = '5A3U616D1YL005502Z';
        insert newResourceRecord;
        inst_ROC.theResourceList.add(newResourceRecord);

        inst_ROC.save();
        inst_ROC.validateTM();//sathish
    }
    
    private static testMethod void Test_ResourceOffController7() {
        Resource__c ResourceRecord=TestDataUtil.ResourceLaborRecord;
        TM_Line__c TMLineLaborRecord=TestDataUtil.TMLineLaborRecord;
        Test.setCurrentPageReference(new PageReference('Page.ResourceOff'));
        System.currentPageReference().getParameters().put('selectedResourcesIds', ResourceRecord.id);
        System.currentPageReference().getParameters().put('RosterDate', '12/27/2018');
        System.currentPageReference().getParameters().put('offType', 'Assign');
        ResourceOffController  inst_ROC = new ResourceOffController ();
        inst_ROC.tm=TestDataUtil.TMRecord;

        Test.startTest();
        
        TM_Job_Task__c tmJobTask = new TM_Job_Task__c(TM__c = TestDataUtil.TMRecord.Id, Line_No__c = 1, Name = 'Task');
        insert tmJobTask;
        TMLineLaborRecord.TM_Job_Task__c = tmJobTask.Id;

		update TMLineLaborRecord;
        inst_ROC.theTMLine=TMLineLaborRecord;

        Resource__c newResourceRecord = ResourceRecord.clone();
        newResourceRecord.Name = 'new resource';
        newResourceRecord.External_Unique_Name__c = 'new resource';
        newResourceRecord.VIN__c = '5A3U616D1YL005502Z';
        insert newResourceRecord;
        inst_ROC.theResourceList.add(newResourceRecord);

        inst_ROC.save();
    }
    //ticket 19130 >>

    private static testMethod void Test_ResourceOffController2() {
        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        Resource__c ResourceRecord=TestDataUtil.ResourceRecord;
        CompanyMgmt.byPassTrigger = false;
        TM_Line__c TMLineLaborRecord=TestDataUtil.TMLineLaborRecord;
        Test.setCurrentPageReference(new PageReference('Page.ResourceOff'));
        System.currentPageReference().getParameters().put('selectedResourcesIds', ResourceRecord.id);
        System.currentPageReference().getParameters().put('RosterDate', '12/27/2018');
        System.currentPageReference().getParameters().put('offType', 'Paid Time Off');
        ResourceOffController  inst_ROC = new ResourceOffController();

        
        
        inst_ROC.strLunchStartTime = '12:00:00';
        inst_ROC.strLunchEndTime = '12:30:00';
        inst_ROC.strStartTime = '8:00:00';
        inst_ROC.strEndTime = '18:30:00';
        inst_ROC.theTMLine=TMLineLaborRecord;

        inst_ROC.validateTM();

        //ticket 19130 << - improve test class coverage
        // inst_ROC.validateServiceCenter();
        System.currentPageReference().getParameters().put('resourceId', ResourceRecord.Id);
        inst_ROC.validateResource();
        //ticket 19130 >>

        Resource__c newResourceRecord = ResourceRecord.clone();
        newResourceRecord.Name = 'new resource';
        newResourceRecord.External_Unique_Name__c = 'new resource';
        newResourceRecord.VIN__c = '5A3U616D1YL005502Y';
        newResourceRecord.External_ID__c = '32432fdsafd';
        insert newResourceRecord;
        inst_ROC.theResourceList.add(newResourceRecord);
		
        inst_ROC.save();
		Test.stopTest();
        System.currentPageReference().getParameters().put('offType', 'Available');
        
    }
    //Sathish
    private static testMethod void Test_ResourceOffController4() {
         CompanyMgmt.byPassTrigger = true;
        Resource__c ResourceRecord=TestDataUtil.ResourceRecord;
         TM_Line__c TMLineLaborRecord=TestDataUtil.TMLineLaborRecord;
        Test.setCurrentPageReference(new PageReference('Page.ResourceOff'));
        System.currentPageReference().getParameters().put('selectedResourcesIds', ResourceRecord.id);
        System.currentPageReference().getParameters().put('RosterDate', '12/27/2018');
        System.currentPageReference().getParameters().put('offType', 'Paid Time Off');
        ResourceOffController  inst_ROC1 = new ResourceOffController ();

        //ticket 19130 <<
        inst_ROC1.calledFrom = 'EquipmentRoster';
        inst_ROC1.theTMLine = TMLineLaborRecord;
        ResourceRecord.Out_of_Service_Date__c = System.today().addDays(-10);
        ResourceRecord.Status__c = 'Out of Service';

        update ResourceRecord;
        CompanyMgmt.byPassTrigger = false;
        inst_ROC1.theTMLine = TMLineLaborRecord;
        inst_ROC1.theResourceList.add(ResourceRecord);
        //ticket 19130 >>
        Test.startTest();
        inst_ROC1.save();
        Test.stopTest();
        

    }
     //Sathish
    private static testMethod void Test_ResourceOffController5() {
         CompanyMgmt.byPassTrigger = true;
        Resource__c ResourceRecord=TestDataUtil.ResourceRecord;
        CompanyMgmt.byPassTrigger = false;
         TM_Line__c TMLineLaborRecord=TestDataUtil.TMLineLaborRecord;
        Test.setCurrentPageReference(new PageReference('Page.ResourceOff'));
        System.currentPageReference().getParameters().put('selectedResourcesIds', ResourceRecord.id);
        System.currentPageReference().getParameters().put('RosterDate', '12/27/2018');
        
        System.currentPageReference().getParameters().put('offType', 'Shop Time');
        ResourceOffController  inst_ROC2 = new ResourceOffController ();
        Test.startTest();
        inst_ROC2.save();
        Test.stopTest();
        inst_ROC2.selectedEquipments='test';       
        inst_ROC2.description='test';       
        inst_ROC2.TMNumber='test';

    }
    
      //Sathish
    private static testMethod void Test_ResourceOffController6() {
         CompanyMgmt.byPassTrigger = true;
        Resource__c ResourceRecord=TestDataUtil.ResourceRecord;
        CompanyMgmt.byPassTrigger = false;
         TM_Line__c TMLineLaborRecord=TestDataUtil.TMLineLaborRecord;
        Test.setCurrentPageReference(new PageReference('Page.ResourceOff'));
        System.currentPageReference().getParameters().put('selectedResourcesIds', ResourceRecord.id);
        System.currentPageReference().getParameters().put('RosterDate', '12/27/2018');
        
        System.currentPageReference().getParameters().put('offType', 'Available');
        ResourceOffController  inst_ROC2 = new ResourceOffController ();
         inst_ROC2.calledFrom = 'EquipmentRoster';
        Test.startTest();
        inst_ROC2.save();
        Test.stopTest();


    }
    //Sathish
    
    private static testMethod void Test_ResourceOffController10() {
         CompanyMgmt.byPassTrigger = true;
        Resource__c ResourceRecord=TestDataUtil.ResourceRecord;
         TM_Line__c TMLineLaborRecord=TestDataUtil.TMLineLaborRecord;
        Test.setCurrentPageReference(new PageReference('Page.ResourceOff'));
        System.currentPageReference().getParameters().put('selectedResourcesIds', ResourceRecord.id);
        System.currentPageReference().getParameters().put('RosterDate', '12/27/2018');
        
        System.currentPageReference().getParameters().put('offType', 'Available');
        
        ResourceRecord.Status__c = 'Out of Service';
        ResourceRecord.Out_of_Service_Date__c = System.today().addDays(-10);
	
        update ResourceRecord;
        CompanyMgmt.byPassTrigger = false; 
        	ResourceOffController  inst_ROC2 = new ResourceOffController ();
         inst_ROC2.calledFrom = 'EquipmentRoster';
       
        Test.startTest();
        inst_ROC2.save();
        Test.stopTest();


    }
    
	@isTest
    private static  void testByPassTrigger() {
        Test.startTest();
        CompanyMgmt.byPassTrigger = true;

        Test.stopTest();
    }

@isTest
    private static  void Test_ResourceOffUpdateTrigger() {
        // Test data setup
        Resource_Off__c resourceOffRecord = TestDataUtil.ResourceOffRecord;
        Resource__c resourceRecord=TestDataUtil.ResourceRecord;
        Test.startTest();
        resourceOffRecord.Start_Time__c = Time.newInstance(9, 0, 0, 0);
        update ResourceOffRecord;
        Test.stopTest();
       
        
    }
@isTest
    private static  void Test_ResourceOffUpdateTrigger2() {
        // Test data setup
        Resource_Off__c resourceOffRecord = TestDataUtil.ResourceOffRecord;
        Resource__c resourceRecord=TestDataUtil.ResourceRecord;
        Test.startTest();
        resourceOffRecord.End_Time__c = Time.newInstance(21, 0, 0, 0);
        update ResourceOffRecord;
        Test.stopTest(); 
        
    }

    @isTest
    private static  void Test_ResourceOffUpdateTrigger3() {
        // Test data setup
        Resource_Off__c resourceOffRecord = TestDataUtil.ResourceOffRecord;
        Resource__c resourceRecord=TestDataUtil.ResourceRecord;
        resourceOffRecord.Lunch_Start_Time__c = Time.newInstance(10, 0, 0, 0);
        resourceOffRecord.Lunch_End_Time__c = Time.newInstance(12, 0, 0, 0);
        update resourceOffRecord;
        Test.startTest();
        resourceOffRecord.Lunch_Start_Time__c = Time.newInstance(9, 0, 0, 0);
        update ResourceOffRecord;
        Test.stopTest(); 
        
    }

    @isTest
    private static  void Test_ResourceOffUpdateTrigger4() {
        // Test data setup
        Resource_Off__c resourceOffRecord = TestDataUtil.ResourceOffRecord;
        Resource__c resourceRecord=TestDataUtil.ResourceRecord;
        resourceOffRecord.Lunch_Start_Time__c = Time.newInstance(10, 0, 0, 0);
        resourceOffRecord.Lunch_End_Time__c = Time.newInstance(12, 0, 0, 0);
        update resourceOffRecord;
        Test.startTest();
        resourceOffRecord.Lunch_End_Time__c = Time.newInstance(15, 0, 0, 0);
        update ResourceOffRecord;
        Test.stopTest();  
        
    }
@isTest
    private static  void Test_ResourceOffUpdateTrigger5() {
        // Test data setup
        Resource_Off__c resourceOffRecord = TestDataUtil.ResourceOffRecord;
        Resource__c resourceRecord=TestDataUtil.ResourceRecord;
        Test.startTest();
        resourceOffRecord.Date__c = Date.today().addDays(-1);
        update ResourceOffRecord;
        Test.stopTest(); 
        
    }
@isTest
    private static  void Test_ResourceOffDelete() {
        // Test data setup
        Resource_Off__c resourceOffRecord = TestDataUtil.ResourceOffRecord;
        Resource__c resourceRecord=TestDataUtil.ResourceRecord;
        Test.startTest();
        delete resourceOffRecord;
        Test.stopTest(); 
        
    }
    //test
}