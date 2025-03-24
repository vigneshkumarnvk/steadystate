@IsTest
private class KronosTimeClockServiceTest {
    @IsTest
    static void testKronosTimeClockServiceProcessTM() {
        NewTestData.createTestData();
        Test.startTest();
        CompanyMgmt.systemCall = true; //Ticket#23796
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        //TM__c tm = [SELECT Id, Status__c, Scheduled_Date__c FROM TM__c WHERE Name = :NewTestData.TEST_TM_NAME_01 LIMIT 1];
        tm.Status__c = TMsService.CONFIRMED_STATUS;

        List<TM__c> tms = new List<TM__c>();
        tms.add(tm);


        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        update tm;

        NewTestData.PayRuleWrapper payRuleWrapper = NewTestData.mapPayRuleWrappersByName.get('Prevailing Wage');
        KronosTimeClockService.setPayRuleMaps(new Set<Id>{payRuleWrapper.PayRule.Id});

        //KronosTimeClockService.processTMLines();
        //KronosTimeClockService.processTMLines(Date.today(), Date.today());

        TM_Line__c tmLine = [SELECT Id, TM__c, Job_Start_Time__c, Job_End_Time__c, Category__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                Site_Start_Time__c, Site_End_Time__c, Resource__c, Service_Center__c, Scheduled_Date__c, Service_Center__r.Temporary__c,
                TM__r.Sales_Order__c, KronosTimeEntriesProcessed__c, Kronos_Integration_Note__c,TM__r.Sales_Order__r.Pay_Rule__r.Type__c, Resource_Type__r.Name
        FROM TM_Line__c WHERE Category__c = 'Labor' AND TM__c = :tm.Id LIMIT 1];

        tmLine.Site_Start_Time__c = Time.newInstance(9,0,0,0);
        tmLine.Site_End_Time__c = Time.newInstance(15,0,0,0);
        tmLine.Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        tmLine.Lunch_End_Time__c = Time.newInstance(12,30,0,0);

        KronosTimeClockService.initData(new List<TM_Line__c>{tmLine});
        List<Employee_Clocked_Time_for_Kronos__c> kronosClockEntries = KronosTimeClockService.generateKronosClockEntriesForTMLine(tmLine);
        insert kronosClockEntries;

        for(Employee_Clocked_Time_for_Kronos__c timeClockEntry : kronosClockEntries){
            timeClockEntry.Exported__c = true;
            break;
        }
        update kronosClockEntries;

        KronosTimeClockService.processDeletedTMLines(new Set<Id>{tmLine.Id});

        kronosClockEntries = KronosTimeClockService.generateKronosClockEntriesForTMLine(tmLine);
        insert kronosClockEntries;

        //Ticket#23796 >>
        Employee_Clocked_Time_for_Kronos__c employeeClockedTimeForKronos = [SELECT Id, Kronos_Action__c FROM Employee_Clocked_Time_for_Kronos__c LIMIT 1];
        employeeClockedTimeForKronos.Kronos_Action__c = 'Deleted';
        try{
            update employeeClockedTimeForKronos;
        } catch (Exception ex){

        }
        try {
            CompanyMgmt.systemCall = true;
            update employeeClockedTimeForKronos;
        } catch (Exception ex){

        }
        //Ticket#23796 <<
        //KronosTimeClockService.moveEntriesToSFPuchKronosTable();

        Test.stopTest();
    }

    @IsTest
    static void testKronosTimeClockServiceProcessResOffEntries(){
        NewTestData.createTestData();
        Off_Type__c offType = new Off_Type__c();
        offType.Name = 'Shop Time';
        offType.Map_Time_Rate_Code__c = 'SHP';
        offType.Map_to_Time_Type__c = 'Shop Time';
        offType.Personnel__c = true;
        insert offType;
        Test.startTest();
        CompanyMgmt.systemCall = true; //Ticket#23796
        Resource_Off__c resourceOff = new Resource_Off__c();
        resourceOff.Resource__c = NewTestData.mapResourceByName.get(NewTestData.TEST_EMPLOYEE_NAME_DAVID).Id;
        resourceOff.Service_Center__c = NewTestData.mapServiceCenterWrappersByName.get('02').ServiceCenter.Id;
        resourceOff.Off_Type__c = offType.Id;
        resourceOff.Start_Time__c = Time.newInstance(8,0,0,0);
        resourceOff.End_Time__c = Time.newInstance(16,0,0,0);
        resourceOff.Date__c = Date.today();
        resourceOff.Shop_Time_Category__c = 'Light Duty';
        insert resourceOff;
        //KronosTimeClockService.processResOffEntries(null, null);

        resourceOff.Start_Time__c = Time.newInstance(9,0,0,0);
        update resourceOff;
        //KronosTimeClockService.processResOffEntries(null, null);

        List<Employee_Clocked_Time_for_Kronos__c> employeeClockedTimeForKronosEntries = [SELECT Id, Exported__c FROM Employee_Clocked_Time_for_Kronos__c];
        for(Employee_Clocked_Time_for_Kronos__c employeeClockedTimeForKronos : employeeClockedTimeForKronosEntries ){
            employeeClockedTimeForKronos.Exported__c = true;
        }
        update employeeClockedTimeForKronosEntries;

        resourceOff.End_Time__c = Time.newInstance(17,0,0,0);
        update resourceOff;
        KronosTimeClockService.processEmployeeTimeDataByResource(resourceOff.Resource__c, Date.today(), Date.today().addDays(7));
        //KronosTimeClockService.processResOffEntries(null, null);

        delete resourceOff;

        Test.stopTest();
    }

    @IsTest
    static void testKronosTimeClockServiceProcessByServiceCenter(){
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        //TM__c tm = [SELECT Id, Status__c, Scheduled_Date__c FROM TM__c WHERE Name = :NewTestData.TEST_TM_NAME_01 LIMIT 1];
        tm.Status__c = TMsService.CONFIRMED_STATUS;
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        update tm;

        NewTestData.PayRuleWrapper payRuleWrapper = NewTestData.mapPayRuleWrappersByName.get('Prevailing Wage');
        KronosTimeClockService.setPayRuleMaps(new Set<Id>{payRuleWrapper.PayRule.Id});

        TM_Line__c tmLine = [SELECT Id, TM__c, Job_Start_Time__c, Job_End_Time__c, Category__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                Site_Start_Time__c, Site_End_Time__c, Resource__c, Service_Center__c, Scheduled_Date__c, Service_Center__r.Temporary__c
        FROM TM_Line__c WHERE Category__c = 'Labor' AND TM__c = :tm.Id LIMIT 1];
        tmLine.Site_Start_Time__c = Time.newInstance(9,0,0,0);
        tmLine.Site_End_Time__c = Time.newInstance(15,0,0,0);
        tmLine.Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        tmLine.Lunch_End_Time__c = Time.newInstance(12,30,0,0);
        update tmLine;

        Off_Type__c offType = new Off_Type__c();
        offType.Name = 'Shop Time';
        offType.Map_Time_Rate_Code__c = 'SHP';
        offType.Map_to_Time_Type__c = 'Shop Time';
        offType.Personnel__c = true;
        insert offType;
        Resource_Off__c resourceOff = new Resource_Off__c();
        resourceOff.Resource__c = NewTestData.mapResourceByName.get(NewTestData.TEST_EMPLOYEE_NAME_DAVID).Id;
        resourceOff.Service_Center__c = NewTestData.mapServiceCenterWrappersByName.get('02').ServiceCenter.Id;
        resourceOff.Off_Type__c = offType.Id;
        resourceOff.Start_Time__c = Time.newInstance(1,0,0,0);
        resourceOff.End_Time__c = Time.newInstance(5,0,0,0);
        resourceOff.Date__c = Date.today().addDays(2);
        resourceOff.Shop_Time_Category__c = 'Light Duty';
        insert resourceOff;

        KronosTimeClockService.processEmployeeTimeDataByServiceCenter(tmLine.Service_Center__c, Date.today(), Date.today().addDays(7));
        KronosTimeClockService.processUnconfirmedTM(new Set<Id>{tm.Id});
        KronosTimeClockService.processEmployeeTimeDataByResource(tmLine.Resource__c, Date.today(), Date.today().addDays(7));
        KronosTimeClockService.initData(new List<TM_Line__c>{tmLine});
        KronosTimeClockService.processIntegrationDisabledResource(KronosTimeClockService.resourcesByIds);
        KronosTimeClockService.processIntegrationEnabledResource(KronosTimeClockService.resourcesByIds);
        Test.stopTest();
    }

    @IsTest
    static void testKronosTimeClockServiceProcessForPWJob(){
        NewTestData.createTestData();
        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        NewTestData.PayRuleWrapper payRuleWrapper = NewTestData.mapPayRuleWrappersByName.get('Prevailing Wage');
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        salesOrder.Pay_Rule__c = payRuleWrapper.PayRule.Id;
        update salesOrder;

        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        tm.Status__c = TMsService.CONFIRMED_STATUS;
        update tm;

        KronosTimeClockService.setPayRuleMaps(new Set<Id>{payRuleWrapper.PayRule.Id});

        TM_Line__c tmLine = [SELECT Id, TM__c, Job_Start_Time__c, Job_End_Time__c, Category__c, Lunch_Start_Time__c, Lunch_End_Time__c,
                Site_Start_Time__c, Site_End_Time__c, Resource__c, Service_Center__c, Scheduled_Date__c, Service_Center__r.Temporary__c
        FROM TM_Line__c WHERE Category__c = 'Labor' AND TM__c = :tm.Id LIMIT 1];
        tmLine.Site_Start_Time__c = Time.newInstance(9,0,0,0);
        tmLine.Site_End_Time__c = Time.newInstance(15,0,0,0);
        tmLine.Lunch_Start_Time__c = Time.newInstance(12,0,0,0);
        tmLine.Lunch_End_Time__c = Time.newInstance(12,30,0,0);
        update tmLine;
        KronosTimeClockService.processEmployeeTimeDataByServiceCenter(tmLine.Service_Center__c, Date.today(), Date.today().addDays(7));

        Time jobStartTime = Time.newInstance(8,0,0,0);
        Time siteStartTime = Time.newInstance(8,0,0,0);
        Time siteEndTime = Time.newInstance(8,0,0,0);
        Time jobEndTime = Time.newInstance(16,0,0,0);
        KronosTimeClockService.breakDownSFTimeEntry(tm.Scheduled_Date__c, jobStartTime, jobEndTime, null, null, siteStartTime, siteEndTime, true);

        jobStartTime = Time.newInstance(8,0,0,0);
        siteStartTime = Time.newInstance(15,0,0,0);
        siteEndTime = Time.newInstance(15,0,0,0);
        jobEndTime = Time.newInstance(15,0,0,0);
        KronosTimeClockService.breakDownSFTimeEntry(tm.Scheduled_Date__c, jobStartTime, jobEndTime, null, null, siteStartTime, siteEndTime, true);

        Test.stopTest();
    }
    //test
}