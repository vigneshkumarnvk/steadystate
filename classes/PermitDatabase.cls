public with sharing class PermitDatabase {

    public static void matchDivisions() {
        Map<String, Service_Center__c> mapServiceCentersByName = new Map<String, Service_Center__c>();
        for (Service_Center__c sc : [SELECT Id, Name FROM Service_Center__c]) {
            if (sc.Name == '99 - Temp') {
                sc.Name = '99';
            }
            mapServiceCentersByName.put(sc.Name, sc);
        }
        
        List<PD_Division__c> divisions = [SELECT Id, Division_Number__c FROM PD_Division__c];
        for (PD_Division__c division : divisions) {
            if (mapServiceCentersByName.containsKey(division.Division_Number__c)) {
                division.Salesforce_ID__c = mapServiceCentersByName.get(division.Division_Number__c).Id;
            }
        }
        update divisions;
    }
    
    public static void matchEquipmentGroups() {
        Map<String, Equipment_Group__c> mapEquipmentGroupsByName = new Map<String, Equipment_Group__c>();
        for (Equipment_Group__c eg : [SELECT Id, Name FROM Equipment_Group__c]) {
            mapEquipmentGroupsByName.put(eg.Name, eg);
        }
        
        List<PD_Equipment_Code__c> equipmentCodes = [SELECT Id, Name, Equip_Group__c FROM PD_Equipment_Code__c];
        for (PD_Equipment_Code__c equipmentCode : equipmentCodes) {
            if (equipmentCode.Equip_Group__c != null) {
                if (mapEquipmentGroupsByName.containsKey(equipmentCode.Equip_Group__c.toUpperCase())) {
                    equipmentCode.Salesforce_Equipment_Group_ID__c = mapEquipmentGroupsByName.get(equipmentCode.Equip_Group__c.toUpperCase()).Id;
                }
            }
        }
        update equipmentCodes;
    }
    
    public static void matchResourceTypes() {
        Map<String, Resource_Type__c> mapResourceTypesByName = new Map<String, Resource_Type__c>();
        for (Resource_Type__c rt : [SELECT Id, Name FROM Resource_Type__c]) {
            if (rt.Name == 'Frac Tank - 20,000 Gal') {
                rt.Name = '20,000 Gal Frac Tank';
            }
            else if (rt.Name == 'Pressure Washer - 3000psi, Hot Water') {
                rt.Name = '3000psi Hot Water Pressure Washer';
            }
            else if (rt.Name == 'Dump Trailer (Trailer Only, Staged on Site)') {
                rt.Name = 'Dump Trailer (Trailer Only)';
            }
            else if (rt.Name == 'Dump Truck, Double Axel, 10 Wheel') {
                rt.Name = 'Dump Truck, 10 Wheel';
            }
            else if (rt.Name == 'Hydrovac/ Hydro Excavator') {
                rt.Name = 'Hydro Excavator';
            }
            else if (rt.Name == 'Pump - Pressure') {
                rt.Name = 'Pressure Pump';
            }
        
            mapResourceTypesByName.put(rt.Name, rt);
        }
        
        List<PD_Resource_Type__c> resourceTypes = [SELECT Id, Name, Resource_Description__c FROM PD_Resource_Type__c];
        for (PD_Resource_Type__c resourceType : resourceTypes) {
            if (mapResourceTypesByName.containsKey(resourceType.Resource_Description__c)) {
                resourceType.Salesforce_ID__c = mapResourceTypesByName.get(resourceType.Resource_Description__c).Id;
            }
        }
        update resourceTypes;
    }
    
    public static void createEquipmentTypes() {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Equipment_Type__c> ets = new List<Equipment_Type__c>();
            
            List<PD_Equipment_Code__c> equipmentCodes = [SELECT Id, Name, Salesforce_Equipment_Group_ID__c FROM PD_Equipment_Code__c];
            for (PD_Equipment_Code__c equipmentCode : equipmentCodes) {
                ets.add(new Equipment_Type__c(Name = equipmentCode.Name, Equipment_Group__c = equipmentCode.Salesforce_Equipment_Group_ID__c));
            }
            insert ets;
            
            for (Integer i = 0; i < ets.size(); i++) {
                equipmentCodes[i].Salesforce_Equipment_Type_ID__c = ets[i].Id;
            }
            
            update equipmentCodes;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    
    public static void matchRollOffBoxes() {
        Map<String, PD_Division__c> mapDivisionsByName = new Map<String, PD_Division__c>();
        for (PD_Division__c division : [SELECT Division_Number__c, Salesforce_ID__c FROM PD_Division__c]) {
            mapDivisionsByName.put(division.Division_Number__c, division);
        }
        
        Map<String, Resource__c> mapResourcesByName = new Map<String, Resource__c>();
        for (Resource__c resource : [SELECT Id, Name FROM Resource__c WHERE Category__c = 'Equipment']) {
            mapResourcesByName.put(resource.Name, resource);
        }
        
        Map<String, PD_Equipment_Code__c> mapEquipmentTypesByName = new Map<String, PD_Equipment_Code__c>();
        for (PD_Equipment_Code__c equipmentCode : [SELECT Id, Name, Auto_Equip_ID__c, Equip_Group__c, Salesforce_Equipment_Group_ID__c, Salesforce_Equipment_Type_ID__c FROM PD_Equipment_Code__c]) {
            mapEquipmentTypesByname.put(equipmentCode.Name, equipmentCode);
        }
        
        Resource_Type__c rolloffContainer = [SELECT Id FROM Resource_Type__c WHERE Name = 'Rolloff Container'][0];
        
        List<PD_Roll_Off_Box__c> boxes = [SELECT Id, Name, Division_Number__c, Equipment_Type__c FROM PD_Roll_Off_Box__c];
        for (PD_Roll_Off_Box__c box : boxes) {
            if (mapDivisionsByName.containsKey(box.Division_Number__c)) {
                box.Service_Center_ID__c = mapDivisionsByName.get(box.Division_Number__c).Salesforce_ID__c;
            }
        
            if (mapEquipmentTypesByName.containsKey(box.Equipment_Type__c)) {
                PD_Equipment_Code__c equipmentCode = mapEquipmentTypesByName.get(box.Equipment_Type__c);
                box.Equipment_Type_ID__c = equipmentCode.Salesforce_Equipment_Type_ID__c;
                box.Equipment_Group_ID__c = equipmentCode.Salesforce_Equipment_Group_ID__c;
            }
            
            box.Resource_Type_ID__c = rolloffContainer.Id;
            
            if (mapResourcesByName.containsKey(box.Name.toUpperCase())) {
                box.Salesforce_ID__c = mapResourcesByName.get(box.Name.toUpperCase()).Id;
            }
        }
        update boxes;
    }
    
    public static void matchVehicles() {
        Map<String, PD_Division__c> mapDivisionsByName = new Map<String, PD_Division__c>();
        for (PD_Division__c division : [SELECT Division_Number__c, Salesforce_ID__c FROM PD_Division__c]) {
            mapDivisionsByName.put(division.Division_Number__c, division);
        }
        
        Map<String, Resource__c> mapResourcesByName = new Map<String, Resource__c>();
        for (Resource__c resource : [SELECT Id, Name FROM Resource__c WHERE Category__c = 'Equipment']) {
            mapResourcesByName.put(resource.Name, resource);
        }
        
        Map<String, PD_Equipment_Code__c> mapEquipmentTypesByName = new Map<String, PD_Equipment_Code__c>();
        for (PD_Equipment_Code__c equipmentCode : [SELECT Id, Name, Auto_Equip_ID__c, Equip_Group__c, Salesforce_Equipment_Group_ID__c, Salesforce_Equipment_Type_ID__c FROM PD_Equipment_Code__c]) {
            mapEquipmentTypesByname.put(equipmentCode.Auto_Equip_ID__c, equipmentCode);
        }
        
        Map<String, PD_Resource_Type__c> mapResourceTypesByName = new Map<String, PD_Resource_Type__c>();
        for (PD_Resource_Type__c resourceType : [SELECT Id, Name, Salesforce_ID__c FROM PD_Resource_Type__c]) {
            mapResourceTypesByName.put(resourceType.Name, resourceType);
        }
        
        
        List<PD_Vehicle_Information__c> vehicles = [SELECT Id, Name, GL_Prefix__c, NAV_Equip_Type_Code__c, resource_type__c FROM PD_Vehicle_Information__c];
        for (PD_Vehicle_Information__c vehicle : vehicles) {
            if (mapDivisionsByName.containsKey(vehicle.GL_Prefix__c)) {
                vehicle.Service_Center_ID__c = mapDivisionsByName.get(vehicle.GL_Prefix__c).Salesforce_ID__c;
            }
        
            if (mapResourcesByName.containsKey(vehicle.Name.toUpperCase())) {
                vehicle.Salesforce_ID__c = mapResourcesByName.get(vehicle.Name.toUpperCase()).Id;
            }
            
            if (mapEquipmentTypesByName.containsKey(vehicle.NAV_Equip_Type_Code__c)) {
                PD_Equipment_Code__c equipmentCode = mapEquipmentTypesByName.get(vehicle.NAV_Equip_Type_Code__c);
                vehicle.Equipment_Type_ID__c = equipmentCode.Salesforce_Equipment_Type_ID__c;
                vehicle.Equipment_Group_ID__c = equipmentCode.Salesforce_Equipment_Group_ID__c;
            }
            
            if (mapResourceTypesByName.containsKey(vehicle.resource_type__c)) {
                PD_Resource_Type__c resourceType = mapResourceTypesByName.get(vehicle.resource_type__c);
                vehicle.Resource_Type_ID__c = resourceType.Salesforce_ID__c;
            }
        }
        update vehicles;
    }
    

    public static void createResourcesFromRollOffBoxes() {
        Savepoint sp = Database.setSavepoint();
        try {
            Map<String, Schema.SObjectField> mapFieldsByName = PD_Roll_Off_Box__c.SObjectType.getDescribe().fields.getMap();
            List<String> fieldNames = new List<String>(mapFieldsByName.keySet());
            String strQuery = 'SELECT ' + String.JOIN(fieldNames, ',') + ' FROM PD_Roll_Off_Box__c WHERE Box_Imported__c != TRUE';
            List<SObject> boxes = Database.query(strQuery);
            
            List<Resource__c> resourcesToUpdate = new List<Resource__c>();
            List<Resource__c> resourcesToInsert = new List<Resource__c>();
            
            for (PD_Roll_Off_Box__c box : (List<PD_Roll_Off_Box__c>)boxes) {
                Resource__c resource = new Resource__c();
                resource.Category__c = 'Equipment';
                resource.Name = box.Name;
                resource.Fleet_Number__c = box.Name;
                resource.Description__c = box.Name;
                resource.Location__c = box.Location__c;
                resource.HW_Decal__c = box.HW_Decal__c;
                resource.SW_Decal__c = box.SW_Decal__c;
                resource.Status_Comments__c = box.Status_Comments__c;
                
                if (box.Salesforce_ID__c == null) {
                    resource.VIN__C = box.Serial_Number__c;
                    resource.Navision_No__c = box.NAV_Resource_ID__c;
                    resource.Equipment_Group__c = box.Equipment_Group_ID__c;
                    resource.Resource_Type__c = box.Resource_Type_ID__c;
                    resource.Service_Center__c = box.Service_Center_ID__c;
                    resource.From_Permit_Database__c = true;
                    resource.Status__c = 'Available';
                    resourcesToInsert.add(resource);
                }
                else {
                    resource.Id = box.Salesforce_ID__c;
                    resourcesToUpdate.add(resource);
                }
                
                box.Box_Imported__c = true;
            }
        

            if (resourcesToInsert.size() > 0) {
                insert resourcesToInsert;
            }
            if (resourcesToUpdate.size() > 0) {
                update resourcesToUpdate;
            }
            if (boxes.size() > 0) {
                update boxes;
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    
    public static void createResourcesFromVehicles() {
        Savepoint sp = Database.setSavepoint();
        try {
            Map<String, Schema.SObjectField> mapFieldsByName = PD_Vehicle_Information__c.SObjectType.getDescribe().fields.getMap();
            List<String> fieldNames = new List<String>(mapFieldsByName.keySet());
            String strQuery = 'SELECT ' + String.JOIN(fieldNames, ',') + ' FROM PD_Vehicle_Information__c WHERE Vehicle_Imported__c != TRUE LIMIT 1000';
            List<SObject> vehicles = Database.query(strQuery);
            
            List<Resource__c> resourcesToUpdate = new List<Resource__c>();
            List<Resource__c> resourcesToInsert = new List<Resource__c>();
            
            for (PD_Vehicle_Information__c vehicle : (List<PD_Vehicle_Information__c>)vehicles) {
                Resource__c resource = new Resource__c();
                
                //unavailble fields for new and existing records
                resource.NJ_Amber_Light_Permit__c = (vehicle.Amber_Light_Permit__c == 1);
                resource.Axles__c = vehicle.Axles__c;
                //resource.DEIC_Completed__c = (vehicle.DEIC_Completed__c == 1);
                resource.Delcora__c = (vehicle.Delcora__c == 1);
                //resource.DOT_Inspection__c = vehicle.DOT_Inspection__c;
                //resource.DOT_No__c = vehicle.DOT_No__c;
                resource.DOT_Spec__c = (vehicle.DOT_Spec__c == 1);
                resource.NJ_Edgeboro__c = (vehicle.Edgeboro__c == 1);
                //resource.External_Visual__c = vehicle.External_Visual__c;
                resource.EZ_Pass_Account__c = vehicle.EZ_Pass_Account__c;
                resource.EZ_Pass_Code__c = vehicle.EZ_Pass_Code__c;
                resource.EZ_Pass_Number__c = vehicle.EZ_Pass_Number__c;
                if (vehicle.EZ_Pass_Tag_Date__c != null) {
                    resource.EZ_Pass_Tag_Date__c = parseDate(vehicle.EZ_Pass_Tag_Date__c);
                }
                resource.EZ_Pass_Tag_Status__c  = vehicle.EZ_Pass_Tag_Status__c;
                resource.EZ_Pass_Tag_Type__c = vehicle.EZ_Pass_Tag_Type__c;
                resource.Falls_Decal__c = vehicle.Falls_Decal__c;
                resource.Falls_Twp__c = (vehicle.Falls_Twp__c == 1);
                resource.Fuel__c = vehicle.Fuel__c;
                resource.GPS__c = (vehicle.GPS__c == 1);
                resource.H_Mat_Cert__c = (vehicle.H_Mat_Cert__c == 1);
                resource.Hauler__c = (vehicle.Hauler__c == 1);
                resource.Insurance__c = vehicle.Insurance__c;
                //resource.Internal_Visual__c = vehicle.Internal_Visual__c;
                resource.Equipment__c = (vehicle.Equipment__c == 1);
                String IRPFee = vehicle.IRP_Fee__c;
                if (IRPFee != null) {
                    if (IRPFee.left(1) == '$') {
                        IRPFee = IRPFee.substring(1).replace(',', '');
                    }
                    resource.IRP_Fee__c = Decimal.valueOf(IRPFee);
                }
                
                resource.IRP_Registration__c = (vehicle.IRP_Registration__c == 1);
                //resource.Leakage__c = vehicle.Leakage__c;
                //resource.Lease_to_APV__c = (vehicle.Lease_To_APV__c == 1);
                //resource.Lease_to_CVI__c = (vehicle.Lease_to_CVI__c == 1);
                resource.License_State__c = vehicle.License_State__c;
                //if (vehicle.Opacity_Test_Last_Done__c != null) {
                //    resource.Opacity_Test_Last_Done__c = parseDate(vehicle.Opacity_Test_Last_Done__c);
                //}
                resource.Operator__c = vehicle.Operator__c;
                resource.Permits__c = vehicle.Permits__c;
                //if (vehicle.PM_Date__c != null) {
                //    resource.PM_Date__c = parseDate(vehicle.PM_Date__c);
                //}
                //resource.Pressure__c = vehicle.Pressure__c;
                resource.Previous_Company__c = vehicle.Previous_Company__c;
                resource.Previous_ID__c = vehicle.Previous_ID__c;
                
                String purchasePrice = vehicle.PurchasePrice__c;
                if (purchasePrice != null) {
                    if (purchasePrice.left(1) == '$') {
                        purchasePrice = purchasePrice.substring(1).replace(',', '');
                    }
                    resource.Purchase_Price__c = Decimal.valueOf(purchasePrice);
                }
                
                resource.NJ_PVSC__c = (vehicle.PVSC__c == 1);
                resource.Reg_Date__c = vehicle.Reg_Date__c;
                
                resource.Registered__c = vehicle.Registered__c;
                //if (vehicle.Tank_Test_Date__c != null) {
                //    resource.Tank_Test_Date__c = parseDate(vehicle.Tank_Test_Date__c);
                //}
                //resource.Thickness__c = vehicle.Thickness__c;
                resource.Title__c = vehicle.Title__c;
                resource.Title_Owner__c = vehicle.Title_Owner__c;
                resource.NYC_BIC_Trade_Waste__c = vehicle.Trade_Waste__c;
                if (vehicle.Unladen_Weight__c != null) {
                    resource.Unladen_Weight__c = Decimal.valueOf(vehicle.Unladen_Weight__c.replace(',', ''));
                }
                //resource.Upper_Coupler__c = vehicle.Upper_Coupler__c;
                //resource.Year__c = vehicle.Year__c;
                resource.Status_Comments__c = vehicle.Comments_Status__c;
                
                resource.Rent_Company__c = vehicle.Rent_Company__c; 
                //if (vehicle.Permit_bk__c != null) {
                //    resource.Permit_bk__c = parseDate(vehicle.Permit_bk__c);
                //}
                //resource.Permit_bk_Status__c = vehicle.Permit_bk_Status__c;


                //permit fields
                resource.AL_HW_Permit__c = false;
                resource.AR_HW_Permit__c = false;
                resource.CT_BioMed__c = false;
                resource.CT_HW_Permit__c = (vehicle.CT_HW_Permit__c == 1);
                resource.DE_HW_Permit__c = (vehicle.DE_HW_Permit__c == 1);
                resource.FL_HW_Permit__c = false;
                resource.GA_HW_Permit__c = (vehicle.GA_HW_Permit__c == 1);
                resource.IN_HW_Permit__c = (vehicle.IN_HW_Permit__c == 1);
                resource.IA_HW_Permit__c = (vehicle.IA_HW_Permit__c == 1);
                resource.ID_HW_Permit__c = false;
                resource.IL_Special_Permit__c = (vehicle.IL_Special_Permit__c == 1);
                resource.KS_HW_Permit__c = (vehicle.KS_HW_Permit__c == 1);
                resource.KY_HW_Permit__c = false;
                resource.MA_HW_Permit__c = (vehicle.MA_HW_Permit__c == 1);
                resource.ME_HW_Permit__c = (vehicle.ME_HW_Permit__c == 1);
                resource.MD_HW_Permit__c = (vehicle.MD_HW_Permit__c == 1);
                resource.MO_HW_Permit__c = (vehicle.MO_HW_Permit__c == 1);
                resource.NJ_Decal__c = vehicle.NJ_Decal__c;
                resource.NJ_HW_Category__c = vehicle.NJ_HW_Category__c;
                resource.NM_HW_Permit__c = (vehicle.NM_HW_Permit__c == 1);
                resource.NY_HW_Permit__c = (vehicle.NY_HW_Permit__c == 1);
                resource.OH_Permit__c = (vehicle.OH_Permit__c == 1);
                resource.PA_HW_Permit__c = (vehicle.PA_HW_Permit__c == 1);
                resource.RI_HW_Permit__c = (vehicle.RI_HW_Permit__c == 1);
                resource.RI_HW_Decal__c = vehicle.RI_Decal__c;
                resource.TN_HW_Permit__c = false;
                resource.TX_HW_Permit__c = false;
                resource.VT_HW_Permit__c = (vehicle.VT_HW_Permit__c == 1);
                resource.WI_HW_Permit__c = (vehicle.WI_HW_Permit__c == 1);
                resource.Quebec_HW_Permit__c = (vehicle.Quebec_HW_Permit__c == 1);
                resource.Ontario_HW_Permit__c = (vehicle.Ontario_HW_Permit__c == 1);
                resource.ND_SW_Permit__c = (vehicle.ND_SW_Permit__c == 1);
                //resource.NJ_SW_Permit__c = (vehicle.NJ_SW_Permit__c != null);  NJ_SW_Permit is a text field
                resource.NJ_SW_Category__c = vehicle.NJ_SW_Category__c;
                resource.DE_SW_Permit__c = (vehicle.DE_SW_Permit__c == 1);
                resource.DE_Nonhaz_Liquid__c = false;
                resource.ME_SW_Permit__c = (vehicle.ME_SW_Permit__c == 1);
                resource.ME_SW_Decal__c = vehicle.ME_SW_Decal__c;
                resource.MI_Nonhaz_Liquid__c = false;
                resource.PA_SW_Permit__c = (vehicle.PA_SW_Permit__c == 1);
                resource.WI_SW_Permit__c = false;
                resource.OH_Brine__c = (vehicle.OH_Brine__c == 1);
                resource.MA_Millbury_WWTP__c = false;
                resource.MA_Upper_Blackstone_WWTP__c = false;
                resource.PA_Derry_WWTP__c = false;
                resource.PA_Lehigh_WWTP__c = false;
                resource.PA_Milton_WWTP__c = false;
                resource.PA_Springettsbury_WWTP__c = false;
                resource.Westchester_Home_Improv__c = (vehicle.Westchester_Home_Improv__c != null);
                resource.MD_Tire_Permit__c = false;
                resource.PA_Tire_Permit__c = false;
                resource.NJ_IFTA_Decal__c = vehicle.NJ_IFTA_Decal__c;
                resource.NY_HUT_Decal__c = vehicle.NY_HUT_Decal__c;
                resource.NY_Fire_Exp_Date__c = parseDate(vehicle.NY_Fire_Exp_Date__c);
                resource.NY_Fire_Account__c = vehicle.NY_Fire_Account__c;
                resource.NY_Fire_Decal__c = vehicle.NY_Fire_Decal__c;
                resource.MD_Oil_Transporter__c = (vehicle.MD_Oil_Transporter__c == 1);
                resource.H_Mat_Cert__c = (vehicle.H_Mat_Cert__c == 1);
                resource.NJ_Jurisdiction__c = vehicle.NJ_Jurisdiction__c;
                resource.NJ_Jurisdicition_Insp_Date__c = parseDate(vehicle.NJ_Jurisdicition_Insp_Date__c);
                resource.NJ_Amber_Light_Permit__c = (vehicle.Amber_Light_Permit__c == 1);
                resource.CT_Amber_Light__c = false;
                if (vehicle.Date_Sold__c  != null) {
                    resource.End_Date__c = parseDate(vehicle.Date_Sold__c);
                }
                if (vehicle.Purchase_Date__c != null) {
                    resource.Start_Date__c = parseDate(vehicle.Purchase_Date__c);
                }
                if (vehicle.GVWR__c != null) {
                    resource.GVW__c = vehicle.GVWR__c;
                }
                resource.Make__c = vehicle.Make__c;
                resource.Model__c = vehicle.Model__c;
                resource.NJ_Hazardous_Decal_No__c = vehicle.NJ_Decal__c;
                resource.NJ_Solid_Decal_No__c = vehicle.NJ_SW_Permit__c;
                resource.Plate_Number__c = vehicle.License_Plate__c;
                resource.Size__c = vehicle.Capacity__c;

                resource.Vehicle_Year__c = vehicle.Year_Built__c;

                if (vehicle.Salesforce_ID__c == null) {
                    resource.Name = vehicle.Name;
                    if (vehicle.Description__c != null) {
                        resource.Description__c = vehicle.Description__c.toUpperCase();
                    }
                    resource.Navision_No__c = vehicle.NAV_Resource_ID__c;
                    resource.Category__c = 'Equipment';
                    resource.Equipment_Group__c = vehicle.Equipment_Group_ID__c;
                    resource.Resource_Type__c = vehicle.Resource_Type_ID__c;


                    resource.From_Permit_Database__c = true;
                    if (vehicle.Status__c == 'OOS- On Lot' || vehicle.Status__c == 'OOS- Pending Sale') {
                        resource.Status__c = 'Out of Service';
                        resource.Blocked__c = true;
                    }
                    else {
                        resource.Status__c = vehicle.Status__c;
                    }
                    resource.VIN__c = vehicle.Serial_Number__c;
                    resource.Fleet_Number__c = vehicle.Name; //fleet number = name
                    resource.Service_Center__c = vehicle.Service_Center_ID__c;
                    resourcesToInsert.add(resource);
                }
                else {
                    resource.Id = vehicle.Salesforce_ID__c;
                    resourcesToUpdate.add(resource);
                }
                
                vehicle.Vehicle_Imported__c = true;
            }
            
            if (resourcesToInsert.size() > 0) {
                insert resourcesToInsert;
            }
            if (resourcesToUpdate.size() > 0) {
                update resourcesToUpdate;
            }
            
            if (vehicles.size() > 0) {
                update vehicles;
            }
            
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    
    public static void createStatePermits() {
        Map<String, Schema.SObjectField> mapFieldsByName = PD_State_Permit__c.SObjectType.getDescribe().fields.getMap();
        List<String> fieldNames = new List<String>(mapFieldsByName.keySet());
        String strQuery = 'SELECT ' + String.JOIN(fieldNames, ',') + ' FROM PD_State_Permit__c';
        List<SObject> permits = Database.query(strQuery);

        List<State_Permit__c> statePermitsToInsert = new List<State_Permit__c>();
        for (PD_State_Permit__c permit : (List<PD_State_Permit__c>)permits) {
            State_Permit__c statePermit = new State_Permit__c();
            statePermit.Name = permit.Name;
            statePermit.Additional_Costs__c = permit.Additional_Costs__c;
            statePermit.Agency__c = permit.Agency__c;
            statePermit.Contact__c = permit.Contact__c;
            statePermit.Contact_Email__c = permit.Contact_Email__c;
            statePermit.Cost_of_Renewal__c = permit.Cost_of_Renewal__c;
            if (permit.Expiration__c != null) {
                statePermit.Expiration__c = parseDate(permit.Expiration__c);
            }
            if (permit.Expiration_CVI__c != null) {
                statePermit.Expiration_CVI__c = parseDate(permit.Expiration_CVI__c );
            }
            statePermit.Include__c = (permit.Include__c == 1);
            statePermit.Marking_Requirements__c = permit.Marking_Requirements__c;
            statePermit.Notes__c = permit.Notes__c;
            statePermit.Permit_Book_Requirements__c = permit.Permit_Book_Requirements__c;
            statePermit.Permit_Location__c = permit.Permit_Location__c;
            statePermit.Permit_Number__c = permit.Permit_Number__c;
            statePermit.Permit_Number_CVI__c = permit.Permit_Number_CVI__c;
            statePermit.Phone_Number__c = permit.Phone_Number__c;
            statePermit.Requirement__c = permit.Requirement__c;
            statePermit.Time__c = permit.Time__c;
            statePermit.Transportation_Permit__c = (permit.Transportation_Permit__c == 1);
            statePermit.Type_of_Permit__c = permit.Type_of_Permit__c;
            statePermit.Web_Address__c = permit.Web_Address__c;
            statePermit.Web_Capabilities__c = permit.Web_Capabilities__c;
            statePermit.Web_User_Information__c = permit.Web_User_Information__c;
            
            statePermitsToInsert.add(statePermit);
        }            
        
        insert statePermitsToInsert;
    }

    
    private static Date parseDate(String input) {
        Date dt = null;
        try {
            if (input != null) {
                Integer p = input.indexOf(' ');
                if (p > 0) {
                    input = input.substring(0, p);
                }

                Integer m;
                Integer d;
                Integer y;
                String[] items = input.split('/');
                if (items.size() == 3) {
                    m = Integer.valueOf(items[0]);
                    d = Integer.valueOf(items[1]);
                    y = Integer.valueOf(items[2]);
                    if (y < 1000) { //2 digit
                        if (y > 50) {
                            y += 1900;
                        } else {
                            y += 2000;
                        }
                    }

                    dt = Date.newInstance(y, m, d);
                }
            }
        }
        catch(exception ex) {
            throw new DataException(ex.getMessage() + ': ' + input + '\n' + ex.getStackTraceString());
        }
        
        return dt;
    }
}