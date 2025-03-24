/*************************************************************************************************
* Name         :  ResourceService
* Description  :  Apex Class for ResourceTrigger
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan 		04-04-2024      		84112:Trigger or Flow to update RSG EIN number on User Object 
* Prabhu Rathakrishnan      04-30-2024             84924:Salesforce - Updates to Equipment Resource Automation 
* Prabhu Rathakrishnan      05-14-2024              86829Salesforce - Newly created resource is not integrated into the EQAI if the user does not enter/Select the  Resource class code (Required fields) in SF.
*************************************************************************************************/

public class ResourceService {
    public static final String LABOR_CATEGORY = 'Labor';
    public static final String EQUIPMENT_CATEGORY = 'Equipment';
    public static final String MATERIALS_CATEGORY = 'Materials';
    public static final String SUBCONTRACTORS_CATEGORY = 'Subcontractors';
    public static final String WASTE_DISPOSAL_CATEGORY = 'Waste Disposal';
    public static final String DEMURRAGE_CATEGORY = 'Demurrage';
    public static final String LUMP_SUM_CATEGORY = 'Bundled';
    public static final String MISC_CHARGES_AND_TAX_CATEGORY = 'Misc. Charges And Taxes';

    public static Map<Id, Resource__c> resourcesByIds = new Map<Id, Resource__c>();
    public static Map<Id, Map<Id, List<ResourceUOMAssociation__c>>> resourceUOMAssociationsByUOMIdsByResIds = new Map<Id, Map<Id, List<ResourceUOMAssociation__c>>>();
    public static Set<Id> resourceUOMIds = new Set<Id>();

    public static void setResourceMapsByIds(Set<Id> resIds){
        if(resIds.size() > 0){
            List<ResourceUOMAssociation__c> resourceUOMAssociations = ResourceUnitOfMeasuresSelector.newInstance().selectByResId(resIds);
            for (ResourceUOMAssociation__c resourceUOMAssociation : resourceUOMAssociations) {
                resourceUOMIds.add(resourceUOMAssociation.Unit_of_Measure__c);
                Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = new Map<Id, List<ResourceUOMAssociation__c>>();
                if (resourceUOMAssociationsByUOMIdsByResIds.containsKey(resourceUOMAssociation.Resource__c)) {
                    resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(resourceUOMAssociation.Resource__c);
                }

                if (resourceUOMAssociationsByUOMIds.containsKey(resourceUOMAssociation.Unit_of_Measure__c)) {
                    List<ResourceUOMAssociation__c> existingResourceUOMAssociations = resourceUOMAssociationsByUOMIds.get(resourceUOMAssociation.Unit_of_Measure__c);
                    existingResourceUOMAssociations.add(resourceUOMAssociation);
                    resourceUOMAssociationsByUOMIds.put(resourceUOMAssociation.Unit_of_Measure__c, existingResourceUOMAssociations);
                } else {
                    resourceUOMAssociationsByUOMIds.put(resourceUOMAssociation.Unit_of_Measure__c, new List<ResourceUOMAssociation__c>{
                            resourceUOMAssociation
                    });
                }
                resourceUOMAssociationsByUOMIdsByResIds.put(resourceUOMAssociation.Resource__c, resourceUOMAssociationsByUOMIds);
            }
            resourcesByIds.putAll(ResourcesSelector.newInstance().selectById(resIds));
        }
    }

    public static Resource__c getResource(Id resId){
        Resource__c resource = new Resource__c();
        if(resourcesByIds.containsKey(resId)){
            resource = resourcesByIds.get(resId);
        }
        return resource;
    }

    public static ResourceUOMAssociation__c getResourceUOMAssociation(Id resId, Id uomId){
        List<ResourceUOMAssociation__c> resourceUOMAssociations = new List<ResourceUOMAssociation__c>();
        if (resourceUOMAssociationsByUOMIdsByResIds.containsKey(resId)) {
            Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(resId);
            if (resourceUOMAssociationsByUOMIds.containsKey(uomId)) {
                resourceUOMAssociations = resourceUOMAssociationsByUOMIds.get(uomId);
            }
        }
        if(resourceUOMAssociations.size() > 0){
            return resourceUOMAssociations[0];
        } else {
            return new ResourceUOMAssociation__c();
        }
    }

    public static Decimal getUnitPrice(Id resId, Id uomId, Boolean isER){
        Decimal unitPrice = 0;
        if (resourceUOMAssociationsByUOMIdsByResIds.containsKey(resId)) {
            Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(resId);
            if (resourceUOMAssociationsByUOMIds.containsKey(uomId)) {
                ResourceUOMAssociation__c resourceUOMAssociation = resourceUOMAssociationsByUOMIds.get(uomId)[0];
                if(isER) {
                    unitPrice = CompanyMgmt.zeroIfNull(resourceUOMAssociation.ER_Unit_Price__c);
                } else {
                    unitPrice = CompanyMgmt.zeroIfNull(resourceUOMAssociation.Unit_Price__c);
                }
            }
        }
        return unitPrice;
    }

    public static Decimal getUnitCost(Id resId, Id uomId){
        Decimal unitCost = 0;
        if (resourceUOMAssociationsByUOMIdsByResIds.containsKey(resId)) {
            Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(resId);
            if (resourceUOMAssociationsByUOMIds.containsKey(uomId)) {
                ResourceUOMAssociation__c resourceUOMAssociation = resourceUOMAssociationsByUOMIds.get(uomId)[0];
                unitCost = CompanyMgmt.zeroIfNull(resourceUOMAssociation.Unit_Cost__c);
            }
        }
        return unitCost;
    }

    //Waste001
    public static ResourceUOMAssociation__c getWasteResUOMSetup(Id resId, Id uomId, Id facilityId) {
        ResourceUOMAssociation__c wasteResUOMSetup = new ResourceUOMAssociation__c();
        Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = new Map<Id, List<ResourceUOMAssociation__c>>();

        if (resourceUOMAssociationsByUOMIdsByResIds.containsKey(resId)) {
            resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(resId);
        }

        if(resourceUOMAssociationsByUOMIds.containsKey(uomId)) {
            List<ResourceUOMAssociation__c> resourceUOMAssociations = resourceUOMAssociationsByUOMIds.get(uomId);

            for(ResourceUOMAssociation__c resourceUOMAssociation : resourceUOMAssociations){
                if((facilityId != null && resourceUOMAssociation.Facility__c == facilityId) ||
                        (facilityId == null && resourceUOMAssociation.Facility__c == null)){
                    wasteResUOMSetup = resourceUOMAssociation;
                    break;
                }
            }
        }
        return wasteResUOMSetup;
    }

    //Waste001 Depreciated
    public static ResourceUOMAssociation__c getWasteResUOMSetup(Id resId, Id unitWeightVolId, Id containerSizeId, Id facilityId, String costMethod) {
        Id lookupUOMId = null;
        ResourceUOMAssociation__c wasteResUOMSetup = new ResourceUOMAssociation__c();
        Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = new Map<Id, List<ResourceUOMAssociation__c>>();
        Boolean pricingInfoFound = true;
        if (resId == null || costMethod == null) {
            pricingInfoFound = false;
        }
        if (costMethod == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) {
            lookupUOMId = unitWeightVolId;
        }
        if (costMethod == EnumUtil.CostMethod.CONTAINER.name()) {
            lookupUOMId = containerSizeId;
        }
        if (resourceUOMAssociationsByUOMIdsByResIds.containsKey(resId)) {
            resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(resId);
        }
        if(resourceUOMAssociationsByUOMIds.containsKey(lookupUOMId)) {
            List<ResourceUOMAssociation__c> resourceUOMAssociations = resourceUOMAssociationsByUOMIds.get(lookupUOMId);
            Map<String, ResourceUOMAssociation__c> resUOMByContainerSizeByFacilty = new Map<String, ResourceUOMAssociation__c>();
            for (ResourceUOMAssociation__c resourceUOMAssociation : resourceUOMAssociations) {
                String mapKey = resourceUOMAssociation.Facility__c + ':' + resourceUOMAssociation.Container_Size__c;
                resUOMByContainerSizeByFacilty.put(mapKey, resourceUOMAssociation);
            }

            String lookupKey = '';

            if (costMethod == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) {
                if (String.isNotBlank(containerSizeId)) {
                    lookupKey = facilityId + ':' + containerSizeId;
                }
                else {
                    lookupKey = facilityId + ':null';
                }
            } else {
                lookupKey = facilityId + ':null';
            }

            //System.debug('Info# lookupKey ' + lookupKey);

            if (!resUOMByContainerSizeByFacilty.containsKey(lookupKey)) {
                if (costMethod == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name() && String.isNotBlank(containerSizeId)) {
                    lookupKey = facilityId + ':null';
                    if (!resUOMByContainerSizeByFacilty.containsKey(lookupKey)) pricingInfoFound = false;
                } else {
                    pricingInfoFound = false;
                }
            }

            if (pricingInfoFound == true && lookupKey != '') {
                wasteResUOMSetup = resUOMByContainerSizeByFacilty.get(lookupKey);
            }

            //System.debug('Info# pricingInfoFound ' + pricingInfoFound);
        }

        return wasteResUOMSetup;
    }

    //Waste001 Depreciated
    public static ResourceUOMAssociation__c getWasteResUOMSetup(Id resId, Id uomId, Id unitWeightVolId, Id containerSizeId, Id facilityId, String costMethod) {
        Id lookupUOMId = null;
        ResourceUOMAssociation__c wasteResUOMSetup = new ResourceUOMAssociation__c();
        Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = new Map<Id, List<ResourceUOMAssociation__c>>();
        Boolean pricingInfoFound = true;
        if (resId == null) {
            pricingInfoFound = false;
        }

        if (resourceUOMAssociationsByUOMIdsByResIds.containsKey(resId)) {
            resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(resId);
        }

        if(costMethod == null) {
            lookupUOMId = uomId;
        }
        if (costMethod == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) {
            lookupUOMId = unitWeightVolId;
        }
        if (costMethod == EnumUtil.CostMethod.CONTAINER.name()) {
            lookupUOMId = containerSizeId;
        }

        if(resourceUOMAssociationsByUOMIds.containsKey(lookupUOMId)) {
            List<ResourceUOMAssociation__c> resourceUOMAssociations = resourceUOMAssociationsByUOMIds.get(lookupUOMId);
            Map<String, ResourceUOMAssociation__c> resUOMByContainerSizeByFacility = new Map<String, ResourceUOMAssociation__c>();
            for (ResourceUOMAssociation__c resourceUOMAssociation : resourceUOMAssociations) {
                String mapKey;
                if (costMethod == null) {
                    mapKey = resourceUOMAssociation.Facility__c + ':' + resourceUOMAssociation.Unit_of_Measure__c;
                }
                else {
                    mapKey = resourceUOMAssociation.Facility__c + ':' + resourceUOMAssociation.Container_Size__c;
                }
                resUOMByContainerSizeByFacility.put(mapKey, resourceUOMAssociation);
            }

            String lookupKey = '';

            if (costMethod != null) {
                if (costMethod == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) {
                    if (String.isNotBlank(containerSizeId)) {
                        lookupKey = facilityId + ':' + containerSizeId;
                    } else {
                        lookupKey = facilityId + ':null';
                    }
                } else {
                    lookupKey = facilityId + ':null';
                }

                //System.debug('Info# lookupKey ' + lookupKey);
                if (!resUOMByContainerSizeByFacility.containsKey(lookupKey)) {
                    if (costMethod == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name() && String.isNotBlank(containerSizeId)) {
                        lookupKey = facilityId + ':null';
                        if (!resUOMByContainerSizeByFacility.containsKey(lookupKey)) pricingInfoFound = false;
                    } else {
                        pricingInfoFound = false;
                    }
                }
            }
            else {
                if (String.isNotBlank(uomId)) {
                    lookupKey = facilityId + ':' + uomId;
                }
                else {
                    lookupKey = facilityId + ':null';
                }

                /*
                Set<String> keys = new Set<String>();
                for (String key : resUOMByContainerSizeByFacility.keySet()) {
                    keys.add(key);
                }
                 */

                if (!resUOMByContainerSizeByFacility.containsKey(lookupKey)) {
                    pricingInfoFound = false;
                }
            }
            if (pricingInfoFound == true && lookupKey != '') {
                wasteResUOMSetup = resUOMByContainerSizeByFacility.get(lookupKey);
            }
        }
        return wasteResUOMSetup;
    }

    public static Boolean isCalcBaseOnResType(String lineCategory){
        if(lineCategory == LABOR_CATEGORY || lineCategory == EQUIPMENT_CATEGORY || lineCategory == LUMP_SUM_CATEGORY) {
            return true;
        } else {
            return  false;
        }
    }
    
    public static User updateUserEmpNo(Resource__c resource,Map<Id, User> resourceUserMap){
        User user = new User();
        if(resource.User__c != null && resource.Name!=null){
            if(resourceUserMap!=null){
            	user = resourceUserMap.get(resource.User__c);
                if(resource.Name != user.RSG_EIN__c){
                    user.RSG_EIN__c = resource.Name;
                    return user;
                }
            }
        }
        return user;
    }
    @future (callout=true)
    public static void syncNewResourcewithEQAI(String resourceId){
        Map<String,String> company_Id_EQIMap = new Map<String,String>();
        Map<String,String> profit_Ctr_Id_EQIMap = new Map<String,String>();
        Map<String,String> bill_Unit_Code_EQIMap = new Map<String,String>();
        
        Resource__c resource = [Select id,Service_Center__c,Service_Center__r.Name,Category__c,Resource_Class_Code__c,Unit_of_Measure__c, Unit_of_Measure__r.Name,Name, Description__c from Resource__c where id = :resourceId];
        String employeeId = [SELECT RSG_EIN__c from User WHERE Id =: userinfo.getUserId() limit 1].RSG_EIN__c;
        for(Sales_Order_EQAI_Mapping__mdt salesOrderEQIMappingRecord :[select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,EQAI_Table_Name__c,Salesforce_Field_API_Name__c,Salesforce_Field_Value__c from Sales_Order_EQAI_Mapping__mdt]){
            if(salesOrderEQIMappingRecord.EQAI_Field_Name__c =='company_id'){
                company_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
            }
            else if(salesOrderEQIMappingRecord.EQAI_Field_Name__c=='profit_ctr_id'){
                profit_Ctr_Id_EQIMap.put(salesOrderEQIMappingRecord.Salesforce_Field_Value__c,salesOrderEQIMappingRecord.EQAI_Field_Value__c);
            }
            
       }
       for(Sales_Line_EQAI_Mapping__mdt salesLineEQIMappingRecord : [select Id,EQAI_Field_Name__c,EQAI_Field_Value__c,Salesforce_Field_Value__c from Sales_Line_EQAI_Mapping__mdt where EQAI_Field_Name__c = 'bill_unit_code']){
            bill_Unit_Code_EQIMap.put(salesLineEQIMappingRecord.Salesforce_Field_Value__c ,salesLineEQIMappingRecord.EQAI_Field_Value__c); 
       }
       
      List<ResourceJSON> resourcesList = new List<ResourceJSON>();
      ResourceJSON resourceJSON = new ResourceJSON(resource,employeeId,bill_Unit_Code_EQIMap,company_Id_EQIMap,profit_Ctr_Id_EQIMap );
	  resourcesList.add(resourceJSON);
      System.debug('resoure JSON body: '+ System.Json.serialize(resourcesList));
      EQAI_API_URL_Extensions__mdt getResourceEQAIAPIURLExtensions = [select API_Extension__c, API_Key__c, API_Token__c, DeveloperName from EQAI_API_URL_Extensions__mdt where DeveloperName='getResourceEQAIAPIURLExtensions'];
      getPostCalloutResponseContents(getResourceEQAIAPIURLExtensions.API_Extension__c,System.Json.serialize(resourcesList),'POST',getResourceEQAIAPIURLExtensions.API_Key__c,getResourceEQAIAPIURLExtensions.API_Token__c  );  
    }
    
    public static String getPostCalloutResponseContents(String endPointURL, String requestBody, String methodType , String Key, String Token) {
            
        try{
            HttpRequest req = new HttpRequest();
            req.setEndpoint('callout:EQAI_Base_URL'+endPointURL);
            req.setHeader('Content-Type','application/json');
            req.setHeader('x-api-key',Key);
            req.setHeader('x-secret-token',Token);
            req.setMethod(methodType);
            req.setBody(requestBody);
            req.setTimeout(120000);
            Http http = new Http();
            HTTPResponse res = http.send(req);
            String response = res.getBody();
            System.debug('Response: '+ response);            
            return string.valueof(res.getStatusCode()) != '200' ? response : (string.valueof(res.getStatusCode()) == '200' && response.trim() == 'Integration Successful') ?string.valueof(res.getStatusCode()) : response ;
        }catch(Exception e){
            System.Debug('Error at  - '+e.getLineNumber()+' Message - '+e.getMessage()+' cause '+e.getCause());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return e.getMessage();
        }
        
   }
}