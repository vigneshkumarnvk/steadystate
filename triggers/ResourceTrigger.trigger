/*************************************************************************************************
* Name         :  ResourceTrigger
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan 		04-04-2024      		84112:Trigger or Flow to update RSG EIN number on User Object 
* Prabhu Rathakrishnan      04-08-2024              84913: Automate External ID update workflow for Resource and Resource type object
* Prabhu Rathakrishnan      04-10-2024              84316: Observation - External id field is not getting bank while trying to clone from existing resources.
* Prabhu Rathakrishnan      04-30-2024             84924:Salesforce - Updates to Equipment Resource Automation 
*************************************************************************************************/
trigger ResourceTrigger on Resource__c (before insert, before update, before delete, after insert, after update) {
    if(CompanyMgmt.byPassTrigger == true){
        return;
    }
    //Prabhu_ReleaseFlag
    if(System.Label.Release_Flag == 'true'){
        if(Trigger.isAfter){
            if(Trigger.isInsert || Trigger.isUpdate){
                List<Resource__c> resourceswithExternalId = new List<Resource__c>();
                List<Resource__c> resourcesList = [Select id,External_ID__c,Category__c from Resource__c where Id in :Trigger.New];
                if(resourcesList!=null && resourcesList.size()>0){
                    for (Resource__c resource : resourcesList) {
                        if(resource.External_ID__c=='' ||resource.External_ID__c == null){
                            resource.External_ID__c = String.ValueOf(resource.Id);
                            resourceswithExternalId.add(resource);
                        }
                    }
                }
                if(resourceswithExternalId !=null && resourceswithExternalId.size()>0)
                    update resourceswithExternalId;
                if(Trigger.isInsert){
                    for (Resource__c resource : resourcesList) {
                        if(resource.Category__c == 'Equipment'){
                            System.debug('Fire the integration to create Resource in EQAI');
                            ResourceService.syncNewResourcewithEQAI(resource.Id);
                        }
                    }
                }
            }
        }
    }
    if(Trigger.isBefore){
        if(Trigger.isInsert || Trigger.isUpdate) {
            Map<Id, Resource__c> resourcesEnabledForKronosIntegrationByIds = new Map<Id, Resource__c>();
            Map<Id, Resource__c> resourcesDisabledForKronosIntegrationByIds = new Map<Id, Resource__c>();
            Map<Id, User> resourceUserMap = new Map<Id, User>();
            User userRecord;
            Set<Id> resourceUsers = new Set<Id>();
            for (Resource__c resource : Trigger.new) {
                resourceUsers.add(resource.User__c);
            }
            List<User> userList = [select id,RSG_EIN__c from User where id = :resourceUsers];
            if(userList!=null && !userList.isEmpty()){
                for(User user: userList){
                    resourceUserMap.put(user.Id, user);
                }
            }
            Set<Id> deActivatedLaborIds = new Set<Id>();//Ticket#28061
            Date earliestEndDate = null; //Ticket#28061
			List<User> users = new List<User>();
            for (Resource__c resource : Trigger.new) {
                if(Trigger.isInsert)
                	resource.External_ID__c = '';//This is to work around duplicate External ID while cloning. External Id will be set in After Insert
                if (resource.Category__c == ResourceService.LABOR_CATEGORY) {
                    //84112
                    //Prabhu_ReleaseFlag
                    if(System.Label.Release_Flag == 'true'){
                        userRecord =(ResourceService.updateUserEmpNo(resource,resourceUserMap));
                        if(userRecord!=null && userRecord.Id !=null){
                            users.add(userRecord);
                        }
                    }
                    if(Trigger.isUpdate){
                        Resource__c oldResource = Trigger.oldMap.get(resource.Id);
                        //Auto disable Kronos Integration
                        if(resource.Kronos_Time_Punch_Start_Date__c != null && resource.Kronos_Time_Punch_End_Date__c == null){
                            if((oldResource.Employee_Type__c != 'Temp' && resource.Employee_Type__c == 'Temp') ||
                                    (oldResource.Bypass_Time_Overlap_Checking__c != true && resource.Bypass_Time_Overlap_Checking__c == true) ||
                                    (String.isNotBlank(oldResource.RSG_EIN__c) && String.isBlank(resource.RSG_EIN__c)) ||
                                    (oldResource.FLSA__c == 'Non-Exempt' && resource.FLSA__c != 'Non-Exempt')){
                                resource.Kronos_Time_Punch_Enabled__c = false;
                                resource.Kronos_Time_Punch_End_Date__c = System.today();
                            }
                        }

                        if(resource.End_Date__c != null && oldResource.End_Date__c != resource.End_Date__c && resource.Kronos_Time_Punch_Enabled__c == true && resource.Kronos_Time_Punch_Start_Date__c != null){
                            if(resource.End_Date__c < KronosTimeClockService.KRONOSCUTOFFDATE){
                                resource.Kronos_Time_Punch_Enabled__c = false;
                                resource.Kronos_Time_Punch_Start_Date__c = null;
                                resource.Kronos_Time_Punch_End_Date__c = null;
                            } else {
                                resource.Kronos_Time_Punch_Enabled__c = false;
                                resource.Kronos_Time_Punch_End_Date__c = resource.End_Date__c;
                            }
                        }

                        if(oldResource.Kronos_Time_Punch_Enabled__c == true && resource.Kronos_Time_Punch_Enabled__c != true && resource.Kronos_Time_Punch_End_Date__c == null){
                            resource.Kronos_Time_Punch_Enabled__c.addError('Please enter Kronos Time Punch End Date to disable Kronos time punch sync!');
                        }

                        if(oldResource.Kronos_Time_Punch_Enabled__c == true && resource.Kronos_Time_Punch_Enabled__c != true){
                            resourcesDisabledForKronosIntegrationByIds.put(resource.Id, resource);
                        }

                        if(oldResource.Kronos_Time_Punch_Enabled__c != true && resource.Kronos_Time_Punch_Enabled__c == true){
                            resourcesEnabledForKronosIntegrationByIds.put(resource.Id, resource);
                        }
                        //Ticket#28061 >>
                        if(resource.End_Date__c != null && oldResource.End_Date__c != resource.End_Date__c){
                            deActivatedLaborIds.add(resource.Id);
                            if(earliestEndDate == null || earliestEndDate > resource.End_Date__c){
                                earliestEndDate = resource.End_Date__c;
                            }
                        }
                        //Ticket#28061 <<
                    }


                    if (resource.Kronos_Time_Punch_Enabled__c == true
                            && (resource.FLSA__c != 'Non-Exempt' || resource.Employee_Type__c == 'Temp' || resource.Employee_Type__c == null
                            || resource.Kronos_Time_Punch_Start_Date__c == null || resource.Bypass_Time_Overlap_Checking__c == true
                            || resource.RSG_EIN__c == null || resource.RSG_EIN__c == '')) {
                        resource.Kronos_Time_Punch_Enabled__c.addError('To enable Kronos time punch sync, Employee must be FLSA Non-Exempt, Employee Type should not be Temp, RSG EIN must be assigned, Non-Payroll Labor Resource should not be checked and Kronos Time Punch Start Date field cannot be blank!');
                    }

                    if(resource.Kronos_Time_Punch_End_Date__c != null && resource.Kronos_Time_Punch_Start_Date__c == null){
                        resource.Kronos_Time_Punch_End_Date__c.addError('To save the change, you also need to enter a Kronos Time Punch Start Date!');
                    }

                    //Auto flag employee as Kronos Enabled.
                    if(resource.Start_Date__c != null && resource.FLSA__c == 'Non-Exempt' && resource.Employee_Type__c != 'Temp' && resource.Employee_Type__c != null &&
                            resource.Bypass_Time_Overlap_Checking__c != true && String.isNotBlank(resource.RSG_EIN__c)){
                        if(resource.End_Date__c == null) {
                            resource.Kronos_Time_Punch_Enabled__c = true;
                            resource.Kronos_Time_Punch_End_Date__c = null;
                            if(resource.Kronos_Time_Punch_Start_Date__c == null) {
                                if (resource.Start_Date__c >= KronosTimeClockService.KRONOSCUTOFFDATE) {
                                    resource.Kronos_Time_Punch_Start_Date__c = resource.Start_Date__c;
                                } else {
                                    resource.Kronos_Time_Punch_Start_Date__c = KronosTimeClockService.KRONOSCUTOFFDATE;
                                }
                            }
                        }
                    }
                }
            }
            //84112
            if(users!=null && users.size()>0){
                update users;
            }
            if(deActivatedLaborIds.size() > 0){
                Map<Id, Date> laborLastActivityDatesByResIds = new Map<Id, Date>();
                for(TM_Line__c tmLine : [SELECT Resource__c, Scheduled_Date__c FROM TM_Line__c WHERE Resource__c IN :deActivatedLaborIds AND Scheduled_Date__c >= :earliestEndDate]){
                    if(laborLastActivityDatesByResIds.containsKey(tmLine.Resource__c)){
                        Date lastActivityDate = laborLastActivityDatesByResIds.get(tmLine.Resource__c);
                        if(lastActivityDate < tmLine.Scheduled_Date__c){
                            laborLastActivityDatesByResIds.put(tmLine.Resource__c, tmLine.Scheduled_Date__c);
                        }
                    } else {
                        laborLastActivityDatesByResIds.put(tmLine.Resource__c, tmLine.Scheduled_Date__c);
                    }
                }
                for(Resource_Off__c resourceOff : [SELECT Resource__c, Date__c FROM Resource_Off__c WHERE Resource__c IN :deActivatedLaborIds AND Date__c >= :earliestEndDate]){
                    if(laborLastActivityDatesByResIds.containsKey(resourceOff.Resource__c)){
                        Date lastActivityDate = laborLastActivityDatesByResIds.get(resourceOff.Resource__c);
                        if(lastActivityDate < resourceOff.Date__c){
                            laborLastActivityDatesByResIds.put(resourceOff.Resource__c, resourceOff.Date__c);
                        }
                    } else {
                        laborLastActivityDatesByResIds.put(resourceOff.Resource__c, resourceOff.Date__c);
                    }
                }

                for (Resource__c resource : Trigger.new) {
                    if(Trigger.isUpdate && laborLastActivityDatesByResIds.containsKey(resource.Id)){
                        Date lastActivityDate = laborLastActivityDatesByResIds.get(resource.Id);
                        if(lastActivityDate > resource.End_Date__c){
                            resource.End_Date__c.addError('T&M and/or Resource Off entries found after the End Date! Employee activity found on ' + lastActivityDate);
                        }
                    }
                }
            }

            if(resourcesDisabledForKronosIntegrationByIds.size() > 0){
                KronosTimeClockService.processIntegrationDisabledResource(resourcesDisabledForKronosIntegrationByIds);
            }

            if(resourcesEnabledForKronosIntegrationByIds.size() > 0){
                KronosTimeClockService.processIntegrationEnabledResource(resourcesEnabledForKronosIntegrationByIds);
            }
        }

        if(Trigger.isInsert){
            for(Resource__c res: Trigger.new){
                if(res.Category__c == 'Equipment'){
                    res.RecordTypeId = Schema.SObjectType.Resource__c.getRecordTypeInfosByName().get('Equipment').getRecordTypeId();
                }
            }
        }

        if(Trigger.isUpdate){
            for(Resource__c res: Trigger.new){
                if(res.End_Date__c != null){
                    if(res.Category__c == 'Equipment'){
                        res.Blocked__c = true;
                    } else{
                        res.Blocked__c = true;
                        res.Status__c = 'Inactive';
                    }
                } else if(res.End_Date__c == null){
                    if(res.Category__c == 'Equipment'){
                        res.Blocked__c = false;
                    } else{
                        res.Blocked__c = false;
                        res.Status__c = 'Active';
                    }
                }

                //handle Status SF and Access database status discrepancy when sync
                //if(res.Category__c == 'Equipment'){
                //    if(res.Status__c != 'Out of Service' && res.Out_of_Service_Date__c != null){
                //        res.Status__c = 'Out of Service';
                //    }
                //}
                if(res.Category__c == 'Equipment'){
                    if(res.Blocked__c != Trigger.oldMap.get(res.Id).Blocked__c){
                        res.Synced_with_Coupa__c = false;
                    }

                    if(res.Name != Trigger.oldMap.get(res.Id).Name){
                        res.Synced_with_Coupa__c = false;
                    }
                }
            }

            //cost method <<
            Set<Id> resIds = new Set<Id>();
            for (Resource__c resource : Trigger.new) {
                resIds.add(resource.Id);
            }

            Map<Id, Resource__c> mapResourceUOMsByResId = new Map<Id, Resource__c>();
            List<Resource__c> resources = [SELECT Id, (SELECT Id, Unit_of_Measure__r.Weight_Volume__c, Unit_of_Measure__r.Container_Size__c FROM ResourceUOMAssociations__r) FROM Resource__c WHERE Id IN :resIds AND Category__c = 'Waste Disposal'];
            for (Resource__c resource : resources) {
                mapResourceUOMsByResId.put(resource.Id, resource);
            }

            for (Resource__c resource : Trigger.new) {
                Boolean hasContainer = false;
                Boolean hasWeightVolume = false;

                if (mapResourceUOMsByResId.containsKey(resource.Id)) {
                    Resource__c resource2 = mapResourceUOMsByResId.get(resource.Id);

                    if (resource2.ResourceUOMAssociations__r != null) {
                        for (ResourceUOMAssociation__c association : resource2.ResourceUOMAssociations__r) {
                            if (association.Unit_of_Measure__r.Container_Size__c == true && hasContainer != true) {
                                hasContainer = true;
                            }
                            if (association.Unit_of_Measure__r.Weight_Volume__c == true && hasWeightVolume != true) {
                                hasWeightVolume = true;
                            }
                        }
                    }

                    resource.Has_Container__c = hasContainer;
                    resource.Has_Weight_Volume__c = hasWeightVolume;
                }
            }
            //cost method >>
        }
    }

}