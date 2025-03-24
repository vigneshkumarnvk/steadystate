/*************************************************************************************************
* Name         :  ResourceTypeTrigger
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      08-04-2024              84913: Automate External ID update workflow for Resource and Resource type object
* Prabhu Rathakrishnan      04-10-2024              84316: Observation - External id field is not getting bank while trying to clone from existing resources.
* Andrew Simons             11-18-2024              US132562: When End Date is set, the system will prevent users from selecting that resource type by setting Blocked = true
*************************************************************************************************/
trigger ResourceTypeTrigger on Resource_Type__c (before insert, before update, after insert,after update) {
	//Prabhu_ReleaseFlag
    if(System.Label.Release_Flag == 'true'){
        if(Trigger.isAfter){
            if(Trigger.isInsert || Trigger.isUpdate){
                List<Resource_Type__c> resourceTypewithExternalId = new List<Resource_Type__c>();
                List<Resource_Type__c> resourceTypeList = [Select id,External_ID__c from Resource_Type__c where Id in :Trigger.New];
                if(resourceTypeList!=null && resourceTypeList.size()>0){
                    for (Resource_Type__c resource : resourceTypeList) {
                        if(resource.External_ID__c=='' ||resource.External_ID__c == null){
                            resource.External_ID__c = String.ValueOf(resource.Id);
                            resourceTypewithExternalId.add(resource);
                        }
                    }
                }
                if(resourceTypewithExternalId !=null && resourceTypewithExternalId.size()>0)
                    update resourceTypewithExternalId;
            }
        }
        if(Trigger.isBefore){
            if(Trigger.isInsert){
                for(Resource_Type__c resourceType :Trigger.New){
                    resourceType.External_ID__c = '';
                }
            }
            if (Trigger.isUpdate) {
                for (Resource_Type__c resourceType : Trigger.New) {
                    // Check if End_Date__c is less than or equal to today's date
                    if (resourceType.End_Date__c != null && resourceType.End_Date__c <= Date.today()) {
                        resourceType.Blocked__c = true;
                    } else {
                        resourceType.Blocked__c = false;
                    }
                }
            }
        }
	}
}