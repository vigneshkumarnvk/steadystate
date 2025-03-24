public class CoupaEquipmentAssetSyncBatch implements Database.Batchable<Resource__c>, Database.AllowsCallouts{
    public List<Resource__c> start(Database.BatchableContext bc) {
        List<Resource__c> resources = [
                SELECT Id, Name, Blocked__c, Synced_with_Coupa__c, Coupa_Lookup_Value_Id__c
                FROM Resource__c
                WHERE Synced_with_Coupa__c != TRUE AND Category__c = 'Equipment'
        ];
        return resources;
    }

    public void execute(Database.BatchableContext BC, List<Resource__c> resources){
        List<Resource__c> resourcesToUpdate = new List<Resource__c>();
        Integration_Setting__mdt coupaSetting = IntegrationSettingUtil.coupaSetting;
        for (Resource__c resource : resources) {
            if(resource.Blocked__c == true && String.isBlank(resource.Coupa_Lookup_Value_Id__c)){
                resource.Synced_with_Coupa__c = true;
                resourcesToUpdate.add(resource);
            } else {
                String method = 'POST';
                String recordId = '';
                if (resource.Coupa_Lookup_Value_Id__c != null) {
                    method = 'PUT';
                    recordId = resource.Coupa_Lookup_Value_Id__c;
                } else {
                    Integer coupaId = CoupaIntegrationService.getLookupValueByName(resource.Name, coupaSetting.Coupa_Asset_Lookup_Id__c);
                    System.debug('Info: coupaId ' + resource.Name + ' -- ' + coupaId);
                    if (coupaId != null) {
                        resource.Coupa_Lookup_Value_Id__c = String.valueOf(coupaId);
                        recordId = resource.Coupa_Lookup_Value_Id__c;
                        method = 'PUT';
                    }
                }

                HttpResponse res = CoupaIntegrationService.syncLookupValue(method, 'Asset IDs', recordId, resource.Name, resource.Blocked__c != true);

                if (res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    if (res.getStatusCode() == 201 && String.isNotBlank(res.getBody())) {
                        CoupaIntegrationService.LookupValue lookupValue = (CoupaIntegrationService.LookupValue) JSON.deserialize(res.getBody(), CoupaIntegrationService.LookupValue.class);
                        resource.Coupa_Lookup_Value_Id__c = String.valueOf(lookupValue.id);
                    }
                    resource.Synced_with_Coupa__c = true;
                    resourcesToUpdate.add(resource);
                }
            }
        }
        if(resourcesToUpdate.size() > 0){
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            update resourcesToUpdate;
        }
    }

    public void finish(Database.BatchableContext BC){

    }
}