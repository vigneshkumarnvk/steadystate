@IsTest
private class KronosTimeClockBatchTest {
    @IsTest
    static void testKronosTimeClockBatch() {
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        //TM__c tm = [SELECT Id, Status__c, Scheduled_Date__c FROM TM__c WHERE Name = :NewTestData.TEST_TM_NAME_01 LIMIT 1];
        tm.Status__c = TMsService.CONFIRMED_STATUS;
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        update tm;

        TM_Line__c tmLine = [SELECT Id, Resource__r.Employee_No__c, TM__c, Job_Start_Time__c, Job_End_Time__c, Category__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                Site_Start_Time__c, Site_End_Time__c, Resource__c, Service_Center__c, Scheduled_Date__c, Service_Center__r.Temporary__c
        FROM TM_Line__c WHERE Category__c = 'Labor' AND TM__c = :tm.Id LIMIT 1];

        System.debug('Info: tmLine.Resource__r.Employee_No__c ' + tmLine.Resource__r.Employee_No__c);
        tmLine.Site_Start_Time__c = Time.newInstance(9,0,0,0);
        tmLine.Site_End_Time__c = Time.newInstance(15,0,0,0);
        tmLine.Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        tmLine.Lunch_End_Time__c = Time.newInstance(12,30,0,0);
        update tmLine;

        GenerateKronosTimeClockBatch kronosTimeClockBatch = new GenerateKronosTimeClockBatch();
        Database.executeBatch(kronosTimeClockBatch, 1);

        /*
        tmLine = [SELECT Id, KronosTimeEntriesProcessed__c FROM TM_Line__c WHERE Category__c = 'Labor' AND TM__c = :tm.Id LIMIT 1];
        System.assertEquals(true, tmLine.KronosTimeEntriesProcessed__c);

        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosLst = [SELECT Id FROM Employee_Clocked_Time_for_Kronos__c];
        Boolean employeeTimeClockEntriesCreated = false;
        if(employeeClockedTimeForKronosLst.size() > 0){
            employeeTimeClockEntriesCreated = true;
        }

        System.assertEquals(true, employeeTimeClockEntriesCreated);

        List<Salesforce_Punch_to_Kronos__c> salesforcePunchToKronos = [SELECT Id FROM Salesforce_Punch_to_Kronos__c];
        Boolean spkEntriesCreated = false;
        if(salesforcePunchToKronos.size() > 0){
            spkEntriesCreated = true;
        }
        System.assertEquals(true, spkEntriesCreated);
         */
        Test.stopTest();
    }
    
    @isTest
    static void testKronosTimeClockBatch2() {
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
      
        //TM__c tm = [SELECT Id, Status__c, Scheduled_Date__c FROM TM__c WHERE Name = :NewTestData.TEST_TM_NAME_01 LIMIT 1];
        tm.Status__c = TMsService.SCHEDULED_STATUS;
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        update tm;

        TM_Line__c tmLine = [SELECT Id, Resource__r.Employee_No__c, TM__c, Job_Start_Time__c, Job_End_Time__c, Category__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                Site_Start_Time__c, Site_End_Time__c, Resource__c, Service_Center__c, Scheduled_Date__c, Service_Center__r.Temporary__c
        FROM TM_Line__c WHERE Category__c = 'Labor' AND TM__c = :tm.Id LIMIT 1];

        System.debug('Info: tmLine.Resource__r.Employee_No__c ' + tmLine.Resource__r.Employee_No__c);
        tmLine.Site_Start_Time__c = Time.newInstance(9,0,0,0);
        tmLine.Site_End_Time__c = Time.newInstance(15,0,0,0);
        tmLine.Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        tmLine.Lunch_End_Time__c = Time.newInstance(12,30,0,0);
        update tmLine;

        // List<Employee_Clocked_Time_for_Kronos__c> empClockedList = new List<Employee_Clocked_Time_for_Kronos__c>();
        Employee_Clocked_Time_for_Kronos__c emp = new Employee_Clocked_Time_for_Kronos__c();
        
        emp.Kronos_Action__c = 'Delete';
        emp.T_M_Line__c = tmLine.Id;
        emp.T_M__c = tm.Id;
        insert emp;

        Employee_Clocked_Time_for_Kronos__c emp2 = new Employee_Clocked_Time_for_Kronos__c();
    
        emp2.Kronos_Action__c = 'Delete';
        emp2.T_M_Line__c = tmLine.Id;
        emp2.T_M__c = tm.Id;
        insert emp2;

        GenerateKronosTimeClockBatch kronosTimeClockBatch = new GenerateKronosTimeClockBatch();
        Database.executeBatch(kronosTimeClockBatch, 1);


        Test.stopTest();
    }
}