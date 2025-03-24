/*************************************************************************************************
* Name         :  ResourceServiceTest
* Description  :  Test Class for ResourceService
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan 		04-04-2024      		84112:Trigger or Flow to update RSG EIN number on User Object
* Prabhu Rathakrishnan      04-30-2024              84924:Salesforce - Updates to Equipment Resource Automation 
**************************************************************************************************/
@IsTest
private class ResourceServiceTest {
    @TestSetup
    static void SetupData(){
        List<Unit_of_Measure__c> unitOfMeasures = new List<Unit_of_Measure__c>();
        Unit_of_Measure__c each = new Unit_of_Measure__c();
        each.Name = 'EA';
        each.Description__c = 'Each';
        unitOfMeasures.add(each);
        Unit_of_Measure__c gram = new Unit_of_Measure__c();
        gram.Name = 'GRAM';
        gram.Weight_Volume__c = true;
        gram.Description__c = 'Gram';
        unitOfMeasures.add(gram);
        Unit_of_Measure__c cs = new Unit_of_Measure__c();
        cs.Name = 'CS';
        cs.Container_Size__c = true;
        cs.Description__c = 'Container Size';
        unitOfMeasures.add(cs);
        insert unitOfMeasures;

        Facility__c facility = new Facility__c();
        facility.Name = 'ACV';
        insert facility;

        List<Resource__c> resources = new List<Resource__c>();
        Resource__c material = new Resource__c();
        material.Name = 'ACV Material';
        material.Category__c = 'Materials';
        material.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Material').getRecordTypeId();
        material.Unit_of_Measure__c = each.Id;
        resources.add(material);

        Resource__c wasteDisposal = new Resource__c();
        wasteDisposal.Name = 'ACV Waste';
        wasteDisposal.Category__c = 'Waste Disposal';
        wasteDisposal.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Waste Disposal').getRecordTypeId();
        wasteDisposal.Unit_of_Measure__c = gram.Id;
        resources.add(wasteDisposal);
       /// insert resources;
        
        Resource__c equipment = new Resource__c();
        equipment.Name = 'ACV Waste';
        equipment.Category__c = 'Equipment';
        equipment.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Equipment').getRecordTypeId();
        equipment.Unit_of_Measure__c = gram.Id;
        resources.add(equipment);
       // insert resources;
        
        Resource__c labor = new Resource__c();
        labor.Name = 'ACV Waste';
        labor.Category__c = 'Labor';
        labor.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Labor').getRecordTypeId();
        labor.Unit_of_Measure__c = gram.Id;
        labor.End_Date__c = System.today()-5;
        resources.add(labor);
        insert resources;

        List<ResourceUOMAssociation__c> resourceUOMAssociations = new List<ResourceUOMAssociation__c>();
        ResourceUOMAssociation__c resourceUOMAssociation = new ResourceUOMAssociation__c();
        resourceUOMAssociation.Name = 'EA';
        resourceUOMAssociation.Resource__c = material.Id;
        resourceUOMAssociation.Unit_of_Measure__c = each.Id;
        resourceUOMAssociation.Unit_Price__c = 100;
        resourceUOMAssociation.ER_Unit_Price__c = 200;
        resourceUOMAssociation.Unit_Cost__c = 50;
        resourceUOMAssociations.add(resourceUOMAssociation);

        resourceUOMAssociation = new ResourceUOMAssociation__c();
        resourceUOMAssociation.Name = 'Gram';
        resourceUOMAssociation.Resource__c = wasteDisposal.Id;
        resourceUOMAssociation.Unit_of_Measure__c = gram.Id;
        resourceUOMAssociation.Unit_Price__c = 10;
        resourceUOMAssociation.ER_Unit_Price__c = 20;
        resourceUOMAssociation.Unit_Cost__c = 1;
        resourceUOMAssociation.Facility__c = facility.Id;
        resourceUOMAssociation.Container_Size__c = cs.Id;
        resourceUOMAssociations.add(resourceUOMAssociation);

        resourceUOMAssociation = new ResourceUOMAssociation__c();
        resourceUOMAssociation.Name = 'CS';
        resourceUOMAssociation.Resource__c = wasteDisposal.Id;
        resourceUOMAssociation.Unit_of_Measure__c = cs.Id;
        resourceUOMAssociation.Unit_Price__c = 10;
        resourceUOMAssociation.ER_Unit_Price__c = 20;
        resourceUOMAssociation.Unit_Cost__c = 1;
        resourceUOMAssociation.Facility__c = facility.Id;
        resourceUOMAssociations.add(resourceUOMAssociation);
        insert resourceUOMAssociations;
    }

    @IsTest
    private static void testResourceService(){
        Test.startTest();
        Set<Id> resIds = new Set<Id>();
        for(Resource__c resource : [SELECT Id FROM Resource__c]){
            resIds.add(resource.Id);
        }
        ResourceService.setResourceMapsByIds(resIds);
        List<Id> ids = new List<Id>(resIds);
        Resource__c resource = ResourceService.getResource(ids[0]);
        ResourceUOMAssociation__c resourceUOMAssociation = ResourceService.getResourceUOMAssociation(resource.Id, resource.Unit_of_Measure__c);
        Decimal unitCost = ResourceService.getUnitCost(resource.Id, resource.Unit_of_Measure__c);
        Decimal unitPrice = ResourceService.getUnitPrice(resource.Id, resource.Unit_of_Measure__c, false);
        Decimal erUnitPrice = ResourceService.getUnitPrice(resource.Id, resource.Unit_of_Measure__c, true);
        Test.stopTest();
    }

    @IsTest
    private static void testWasteResource(){
        Test.startTest();
        Id unitWeightVolUOM = null;
        Id containerSizeUOM = null;
        Facility__c facility = [SELECT Id FROM Facility__c LIMIT 1];
        Resource__c wasteResource = [SELECT Id FROM Resource__c WHERE Category__c = 'Waste Disposal' LIMIT 1];

        for(Unit_of_Measure__c unitOfMeasure : [SELECT Id, Container_Size__c, Weight_Volume__c FROM Unit_of_Measure__c]){
            if(unitOfMeasure.Container_Size__c == true && containerSizeUOM == null){
                containerSizeUOM = unitOfMeasure.Id;
            }
            if(unitOfMeasure.Weight_Volume__c == true && unitWeightVolUOM == null){
                unitWeightVolUOM = unitOfMeasure.Id;
            }
        }

        String costMethod = EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name();
        ResourceService.setResourceMapsByIds(new Set<Id>{wasteResource.Id});
        ResourceService.getWasteResUOMSetup(wasteResource.Id, unitWeightVolUOM, containerSizeUOM, facility.Id, costMethod);
        costMethod = EnumUtil.CostMethod.CONTAINER.name();
        ResourceService.getWasteResUOMSetup(wasteResource.Id, unitWeightVolUOM, containerSizeUOM, facility.Id, costMethod);
        Test.stopTest();
    }
        @IsTest
    private static void testLaborResource(){
        Test.startTest();
                Resource__c labor = [SELECT Id FROM Resource__c WHERE Category__c = 'Labor' LIMIT 1];
        Off_Type__c offType = new Off_Type__c (
                Name = 'Shop Time',
                Equipment__c = false,
                Map_to_Time_Type__c = 'Shop Time'
        );
        insert offType;
        
         Numbering_Series__c NumberingSeries = TestDataUtil.NumberingSeriesRecord;
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;

        Rate_Sheet__c rateSheetRec = new Rate_Sheet__c();
        rateSheetRec.Name = 'ACV Rate';
        insert rateSheetRec;

        List<Rate_Sheet_Line__c> rateSheetLines = new List<Rate_Sheet_Line__c>();
        //resource type line
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        //Resource type lines
        rateSheetLine = new Rate_Sheet_Line__c();
        rateSheetLine.Rate_Sheet__c = rateSheetRec.Id;
        rateSheetLine.Resource__c = TestDataUtil.ResourceMaterialRecord.Id;
        rateSheetLine.Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id;
        rateSheetLine.Unit_Price__c = 100;
        rateSheetLine.ER_Unit_Price__c = 100;
        rateSheetLine.Unit_Cost__c = 50;
        rateSheetLine.Default__c = true;
        rateSheetLines.add(rateSheetLine);

        insert rateSheetLines;

        TM__c tm = new TM__c(
            Bill_to_Customer__c = TestDataUtil.customerAccountRecord.Id,
            Project_Coordinator__c = TestDataUtil.SalespersonRecord.Id,
            Account_Executive__c = TestDataUtil.SalespersonRecord.Id,
            Rate_Sheet__c = rateSheetRec.Id,
            Prevailing_Wage_Job__c = true,
            Certified_PW_Job__c = true,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Subsidiary_Company__c = TestDataUtil.SubsidiaryCompanyRecord.Id,
            Tax_Area__c = TestDataUtil.TaxAreaRecord.Id,
            Sales_Order__c = TestDataUtil.SalesOrderRecord.Id,
            Scheduled_Date__c = Date.today().addDays(7),
            Status__c = 'Confirmed');
        insert tm;

        TM_Line__c TMLineLaborRecord = new TM_Line__c(
            Line_No__c = 1,
            Description__c = 'Test item',
            Quantity__c = 1,
            Category__c = 'Labor',
            TM__c = tm.Id,
            Resource_Type__c = TestDataUtil.ResourceTypeRecord.Id,
            Service_Center__c = TestDataUtil.ServiceCenterRecord.Id,
            Resource__c = labor.Id,
            Total_Site_Hours__c = 1650,
            Regular_Hours__c = 550,
            Regular_Rate__c = 1,
            Overtime_Rate__c = 1,
            Overtime_Hours__c = 550,
            Premium_Hours__c = 550,
            Premium_Rate__c = 1,
            Unit_Price__c = 1,
            Hour__c = 1650,
            Tax_Group__c = 'TX',
            Unit_of_Measure__c = TestDataUtil.UnitMeasureRecord.Id,
            Job_Start_Time__c = system.now().addHours(-8).Time(),
            Job_End_Time__c = system.now().Time()
        );
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        insert TMLineLaborRecord;
        tm.Id = null;
        tm.Scheduled_Date__c = Date.today().addDays(8);
        insert tm;
        TMLineLaborRecord.Id = null;
        TMLineLaborRecord.TM__c = tm.Id;
        insert TMLineLaborRecord;
        Resource_Off__c resourceOff = new Resource_Off__c(
            Date__c = Date.today().addDays(9),
            Start_Time__c = Time.newInstance(02,0,0,0),
            End_Time__c = Time.newInstance(07, 0, 0, 0),
            Hours__c = 5,
            Total_Hours__c = 5,
            Resource__c = labor.Id,
            Off_Type__c = offType.Id,
            Shop_Time_Category__c = 'Physical'
        );
        insert resourceOff;
        resourceOff.Date__c =Date.today().addDays(10);
        resourceOff.Id = null;
        insert resourceOff;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;
        
        try{
            
            labor.End_Date__c= System.today();
          update labor;  
        }catch(Exception e){
            
        }
        try{
            labor.Kronos_Time_Punch_Start_Date__c =System.today();
            labor.Employee_Type__c ='Temp';
            labor.Kronos_Time_Punch_Enabled__c = true;
            labor.End_Date__c= System.today();
          update labor;  
        }catch(Exception e){
            
        }
        try{
            labor.Kronos_Time_Punch_End_Date__c = System.today();
            labor.End_Date__c= System.today();
          update labor;  
        }catch(Exception e){
            
        }
         try{
             labor.Start_Date__c=system.today();
             labor.Kronos_Time_Punch_Start_Date__c = null;
            labor.FLSA__c = 'Non-Exempt';
             labor.Employee_Type__c = 'Employee';
             labor.Bypass_Time_Overlap_Checking__c = false;
             labor.RSG_EIN__c ='23';
            labor.End_Date__c= null;
          update labor;  
        }catch(Exception e){
            
        }
        try{
            labor.Kronos_Time_Punch_Enabled__c = false;
            labor.End_Date__c= System.today();
                    labor.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Equipment').getRecordTypeId();

            labor.Category__c ='Equipment';
          update labor;  
        }catch(Exception e){
            
        }

		Test.stopTest();
    }
    
    @IsTest
    private static void testWasteResUOMSetup(){
        Test.startTest();
        Unit_of_Measure__c unitOfMeasure = [SELECT Id, Container_Size__c, Weight_Volume__c FROM Unit_of_Measure__c limit 1];        
        Resource__c material = [SELECT Id FROM Resource__c WHERE Category__c = 'Waste Disposal' LIMIT 1];
        
        Facility__c facility = [SELECT Id FROM Facility__c LIMIT 1];
        
        ResourceService.getWasteResUOMSetup(material.Id,unitOfMeasure.Id, facility.Id);
        Test.stopTest();
    }
    
    @IsTest
    private static void testWasteResUOMSetup2(){
        Test.startTest();
        Id unitWeightVolUOM = null;
        Id containerSizeUOM = null;
        Facility__c facility = [SELECT Id FROM Facility__c LIMIT 1];
        Resource__c wasteResource = [SELECT Id FROM Resource__c WHERE Category__c = 'Waste Disposal' LIMIT 1];

        for(Unit_of_Measure__c unitOfMeasure : [SELECT Id, Container_Size__c, Weight_Volume__c FROM Unit_of_Measure__c]){
            if(unitOfMeasure.Container_Size__c == true && containerSizeUOM == null){
                containerSizeUOM = unitOfMeasure.Id;
            }
            if(unitOfMeasure.Weight_Volume__c == true && unitWeightVolUOM == null){
                unitWeightVolUOM = unitOfMeasure.Id;
            }
        }

        String costMethod = EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name();
        ResourceService.setResourceMapsByIds(new Set<Id>{wasteResource.Id});
        ResourceService.getWasteResUOMSetup(wasteResource.Id,containerSizeUOM, unitWeightVolUOM, containerSizeUOM, facility.Id, costMethod);
        costMethod = EnumUtil.CostMethod.CONTAINER.name();
        ResourceService.getWasteResUOMSetup(wasteResource.Id, containerSizeUOM, unitWeightVolUOM, containerSizeUOM, facility.Id, costMethod);
        Test.stopTest();
    }
	@IsTest
    private static void testupdateUserEmpNo(){
        Test.startTest();
        Resource__c labor = [SELECT Id,Name,User__c FROM Resource__c WHERE Category__c = 'Labor' LIMIT 1];
        labor.Name='100002224';
        labor.User__c = UserInfo.getUserId();
        update labor;
        
        Resource_Type__c resourceType = new Resource_Type__c();//[Select id,External_ID__c from Resource_Type__c limit 1];
        resourceType.name = 'Test Resource Type';
        resourceType.Category__c = 'Equipment';
        insert resourceType;
        
        Map<Id, User> resourceUserMap = new Map<Id, User>();
        User user = [select id,RSG_EIN__c from User where id = :UserInfo.getUserId()];
        resourceUserMap.put(UserInfo.getUserId(), user);
        ResourceService.updateUserEmpNo(Labor,resourceUserMap);
        Test.stopTest();
    }

    @IsTest
    private static void testEQAIIntegration(){
        Test.startTest();
        Resource__c equipment = new Resource__c();
        equipment.Name = 'ACV Waste1';
        equipment.Category__c = 'Equipment';
        equipment.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Equipment').getRecordTypeId();
        insert equipment;
        
        Resource_Type__c resourceType = new Resource_Type__c();
        resourceType.name = 'Test Resource Type';
        resourceType.Category__c = 'Equipment';
        insert resourceType;
        
        ResourceService.syncNewResourcewithEQAI(equipment.ID);
        Test.stopTest();
    }
}