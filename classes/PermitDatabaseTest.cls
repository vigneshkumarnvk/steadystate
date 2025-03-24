@isTest
private class PermitDatabaseTest {
    
    private static testMethod void test() {
        PD_Vehicle_Information__c vehicle = new PD_Vehicle_Information__c();
        PD_Division__c division = new PD_Division__c();
        PD_Equipment_Code__c equipGroup = new PD_Equipment_Code__c();
        PD_EZ_Pass_Code__c ezPassCode = new PD_EZ_Pass_Code__c();
        PD_Resource_Type__c resourceType = new PD_Resource_Type__c();
        PD_Roll_Off_Box__c rollOffBox = new PD_Roll_Off_Box__c();
        PD_State_Permit__c permit = new PD_State_Permit__c();
        
        insert new Resource_Type__c(Name = 'Rolloff Container');
        
        division.Division_Number__c = '02';
        insert division;
        

        equipGroup.Equip_Group__c = 'TRUCK';
        equipGroup.Name = 'Heavy Truck';
        equipGroup.Nav_Equip_Code__c = 'TRUCK';
        insert equipGroup;
        
        resourceType.Name = 'Heavy Truck (>5000)';
        resourceType.Resource_Description__c = 'Heavy Truck (>5000)';
        insert resourceType;
        
        rollOffBox.Division_Number__c = '02';
        rollOffBox.Equipment_Type__c = 'Heavy Truck';
        rollOffBox.Name = 'Container 1';
        insert rollOffBox;
        
        vehicle.Name = 'Heavy Truck';
        vehicle.GL_Prefix__c = '02';
        vehicle.NAV_Equip_Type_Code__c = 'TRUCK';
        vehicle.resource_type__c = 'Heavy Truck';
        insert vehicle;
        
        
        permit.Name = 'NY';
        permit.Agency__c = 'NYC';
        insert permit;
        
        PermitDatabase.matchDivisions();
        PermitDatabase.matchEquipmentGroups();
        PermitDatabase.matchResourceTypes();
        PermitDatabase.createEquipmentTypes();
        PermitDatabase.matchRollOffBoxes();
        PermitDatabase.matchVehicles();
        PermitDatabase.createResourcesFromRollOffBoxes();
        PermitDatabase.createResourcesFromVehicles();
        PermitDatabase.createStatePermits();
    }

}