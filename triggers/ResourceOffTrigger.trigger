trigger ResourceOffTrigger on Resource_Off__c (before insert, before update, before delete, after delete) {
    if(CompanyMgmt.byPassTrigger == true){
        return;
    }

    if(Trigger.isInsert || Trigger.isUpdate){
        TimesheetTriggerMgmt.ROInsertUpdate(Trigger.new, Trigger.oldMap, Trigger.isInsert);

        Set<Id> laborResIds = new Set<Id>();
        //Kronos time clock
        Map<Id, Off_Type__c> offTypesByIds = new Map<Id, Off_Type__c>([SELECT Id, Name, Personnel__c FROM Off_Type__c]);
        Map<Id, Service_Center__c> serviceCentersByIds = new Map<Id, Service_Center__c>(); //Ticket#25404
        serviceCentersByIds.putAll([SELECT Id, Shop_Time_Sales_Order__c FROM Service_Center__c]);
        for(Resource_Off__c resourceOff : Trigger.new) {
            Off_Type__c offType = offTypesByIds.get(resourceOff.Off_Type__c);
            if(offType.Name == 'Shop Time') {
                //Ticket#25404 >>
                if(serviceCentersByIds.containsKey(resourceOff.Service_Center__c) &&
                        String.isBlank(serviceCentersByIds.get(resourceOff.Service_Center__c).Shop_Time_Sales_Order__c))
                {
                    resourceOff.addError('Shop Time entries are not permitted for this Service Center.');
                    //throw new DataException();
                }
                //Ticket#25404 <<
                //Ticket#24468 >>
                if(resourceOff.Lunch_Start_Time__c != null && resourceOff.Lunch_End_Time__c != null && resourceOff.Start_Time__c != null && resourceOff.End_Time__c != null){
                    Boolean isValid = TMLLinesService.isLunchTimeValid(resourceOff.Start_Time__c, resourceOff.End_Time__c, resourceOff.Lunch_Start_Time__c, resourceOff.Lunch_End_Time__c, resourceOff.Site_Start_Time__c, resourceOff.Site_End_Time__c);
                    if (isValid == false) {
                        resourceOff.addError('Lunch times entered are not valid. Please make sure lunch times are within the start and end times.');
                    }
                }
                //Ticket#24468 <<
                if(Trigger.isUpdate) {
                    Resource_Off__c oldRecord = Trigger.oldMap.get(resourceOff.Id);
                    if((resourceOff.Resource__c != oldRecord.Resource__c ||
                            resourceOff.Start_Time__c != oldRecord.Start_Time__c ||
                            resourceOff.End_Time__c != oldRecord.End_Time__c ||
                            resourceOff.Lunch_Start_Time__c != oldRecord.Lunch_Start_Time__c ||
                            resourceOff.Lunch_End_Time__c != oldRecord.Lunch_End_Time__c ||
                            resourceOff.Date__c != oldRecord.Date__c))
                    {
                        resourceOff.KronosTimeEntriesProcessed__c = false;
                        resourceOff.Kronos_Integration_Note__c = null;
                    }
                }
            }

            //Ticket#24469 >>
            if(offType.Personnel__c == true && CompanyMgmt.systemCall != true){
                laborResIds.add(resourceOff.Resource__c);
                Boolean isPayrollBlockoutPeriod = PayrollMgmt.isPayrollBlockoutPeriod();
                if(isPayrollBlockoutPeriod == true){
                    resourceOff.addError('You are not allow to add/update labor related entry during Monday payroll period.');
                }
            }
            //Ticket#24469 <<
        }
        //Ticket#28061 >>
        Map<Id, Resource__c> laborResourcesByIds = new Map<Id, Resource__c>([SELECT Id, End_Date__c, Status__c FROM Resource__c WHERE Id IN :laborResIds]);
        for(Resource_Off__c resourceOff : Trigger.new){
            if(laborResourcesByIds.containsKey(resourceOff.Resource__c)){
                Resource__c labor = laborResourcesByIds.get(resourceOff.Resource__c);
                if(labor.Status__c == 'Inactive' && labor.End_Date__c < resourceOff.Date__c){
                    resourceOff.addError('The employee is inactive; the last date is ' + labor.End_Date__c);
                }
            }
        }
        //Ticket#28061 <<
    }

    if(Trigger.isBefore){
        if(Trigger.isDelete){
            Set<Id> resOffIdsWhoseKronosEntriesCanBeDeleted = new Set<Id>();
            //Ticket#24469 >>
            //Off_Type__c offType = [SELECT Id FROM Off_Type__c WHERE Name = 'Shop Time' LIMIT 1];
            Map<Id, Off_Type__c> offTypesByIds = new Map<Id, Off_Type__c>([SELECT Id, Name, Personnel__c FROM Off_Type__c]);
            //Ticket#24469 <<
            for(Resource_Off__c resourceOff : Trigger.old){
                Off_Type__c offType = offTypesByIds.get(resourceOff.Off_Type__c);
                if(offType.Personnel__c == true && CompanyMgmt.systemCall != true){
                    Boolean isPayrollBlockoutPeriod = PayrollMgmt.isPayrollBlockoutPeriod();
                    if(isPayrollBlockoutPeriod == true){
                        resourceOff.addError('You are not allow to add/update labor related entry during Monday payroll period.');
                    }
                }
                //if(resourceOff.Off_Type__c == offType.Id){ Ticket#24469
                if(offType.Name == 'Shop Time') {
                    resOffIdsWhoseKronosEntriesCanBeDeleted.add(resourceOff.Id);
                }
            }
            KronosTimeClockService.processDeletedResourceOffLine(resOffIdsWhoseKronosEntriesCanBeDeleted);
        }
    }

}