public with sharing class RateSheetService {

    public static Map<Id, Map<Id, Map<Id, List<Rate_Sheet_Line__c>>>> rateSheetLinesByUOMByResOrResTypeByRateSheet = new Map<Id, Map<Id, Map<Id, List<Rate_Sheet_Line__c>>>>();
    public static List<Rate_Sheet_Line__c> rateSheetLines = new List<Rate_Sheet_Line__c>();

    public static void setRateSheetLines(Set<Id> rateSheetIds){
        rateSheetLines = RatesheetLinesSelector.newInstance().selectByRateSheetIds(rateSheetIds);
    }

    public static void setMap_RateSheetLinesByUOMByResTypeByRateSheet(){
        for(Rate_Sheet_Line__c rateSheetLine : rateSheetLines){
            Map<Id, Map<Id, List<Rate_Sheet_Line__c>>> rateSheetLineByUOMByResType = new Map<Id, Map<Id, List<Rate_Sheet_Line__c>>>();
            Map<Id, List<Rate_Sheet_Line__c>> rateSheetLineByUOM = new Map<Id, List<Rate_Sheet_Line__c>>();

            //assign resource or resource type id
            Id resOrResTypeIds = null;
            if(String.isBlank(rateSheetLine.Resource__c)){
                resOrResTypeIds = rateSheetLine.Resource_Type__c;
            } else {
                resOrResTypeIds = rateSheetLine.Resource__c;
            }

            //if first level map by rate sheet id exist get 2nd level map => Map<Id(Res or Res Type Id), Map<Id(UOM Id), List<Rate_Sheet_Line__c>>> by rate sheet id.
            if(rateSheetLinesByUOMByResOrResTypeByRateSheet.containsKey(rateSheetLine.Rate_Sheet__c)) {
                rateSheetLineByUOMByResType = rateSheetLinesByUOMByResOrResTypeByRateSheet.get(rateSheetLine.Rate_Sheet__c);
            }

            //if 2and level map by res or res type id exist, get 3rd level map => Map<Id(UOM Id), List<Rate_Sheet_Line__c>> by res or res type id.
            if(rateSheetLineByUOMByResType.containsKey(resOrResTypeIds)){
                rateSheetLineByUOM = rateSheetLineByUOMByResType.get(resOrResTypeIds);
            }

            //add rate sheet line to mapped rate sheet lines
            if(rateSheetLineByUOM.containsKey(rateSheetLine.Unit_of_Measure__c)){
                List<Rate_Sheet_Line__c> existingRateSheetLines = rateSheetLineByUOM.get(rateSheetLine.Unit_of_Measure__c);
                existingRateSheetLines.add(rateSheetLine);
            } else {
                rateSheetLineByUOM.put(rateSheetLine.Unit_of_Measure__c, new List<Rate_Sheet_Line__c>{rateSheetLine});
            }

            //add 3rd level Map<Id(UOM Id), List<Rate_Sheet_Line__c>> to 2nd level Map<Id(Res/Res Type Id), Map<Id(UOM Id), List<Rate_Sheet_Line__c>>>
            rateSheetLineByUOMByResType.put(resOrResTypeIds, rateSheetLineByUOM);

            //2nd level map to first level map
            rateSheetLinesByUOMByResOrResTypeByRateSheet.put(rateSheetLine.Rate_Sheet__c, rateSheetLineByUOMByResType);
        }
    }

    public static Rate_Sheet_Line__c getDefaultRateSheetLine(Id rateSheetId, Id resOrTypeId){
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        if(rateSheetLinesByUOMByResOrResTypeByRateSheet.containsKey(rateSheetId)){
            Map<Id, Map<Id, List<Rate_Sheet_Line__c>>> rateSheetLineByUOMByResType = rateSheetLinesByUOMByResOrResTypeByRateSheet.get(rateSheetId);
            if(rateSheetLineByUOMByResType.containsKey(resOrTypeId)){
                Map<Id, List<Rate_Sheet_Line__c>> rateSheetLineByUOM = rateSheetLineByUOMByResType.get(resOrTypeId);
                for(Id uomId : rateSheetLineByUOM.keySet()){
                    for(Rate_Sheet_Line__c rateSheetLine2: rateSheetLineByUOM.get(uomId)){
                        if(rateSheetLine2.Default__c == true){
                            rateSheetLine = rateSheetLine2;
                            break;
                        }
                    }
                }
            }
        }
        return rateSheetLine;
    }

    public static Rate_Sheet_Line__c getRateSheetLine(Id rateSheetId, Id resOrTypeId, Id uomId){
        /*
        System.debug('Info: getRateSheetLine ');
        System.debug('Info: rateSheetId ' + rateSheetId);
        System.debug('Info: resOrTypeId ' + resOrTypeId);
        System.debug('Info: uomId ' + uomId);
         */

        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        if(rateSheetLinesByUOMByResOrResTypeByRateSheet.containsKey(rateSheetId)){
            Map<Id, Map<Id, List<Rate_Sheet_Line__c>>> rateSheetLineByUOMByResType = rateSheetLinesByUOMByResOrResTypeByRateSheet.get(rateSheetId);
            //System.debug('Info: rateSheetLineByUOMByResType ' + rateSheetLineByUOMByResType);
            if(rateSheetLineByUOMByResType.containsKey(resOrTypeId)){
                Map<Id, List<Rate_Sheet_Line__c>> rateSheetLineByUOM = rateSheetLineByUOMByResType.get(resOrTypeId);
                //System.debug('Info: rateSheetLineByUOM ' + rateSheetLineByUOM);
                //System.debug('Info: uomId ' + uomId);
                if(rateSheetLineByUOM.containsKey(uomId)){
                    rateSheetLine = rateSheetLineByUOM.get(uomId)[0];
                    //System.debug('Info: rateSheetLine ' + rateSheetLine);
                }
            }
        }
        return rateSheetLine;
    }

    //Waste001
    public static Rate_Sheet_Line__c getWasteRateSheetLine(Id rateSheetId, Id resId, Id pricingUOMId, Id facilityId){

        Boolean pricingInfoFound = true;
        Rate_Sheet_Line__c wasteRateSheetLine = new Rate_Sheet_Line__c();

        //Second level Map<Id(Res/Res Type Id), Map<Id(UOM Id), List<Rate_Sheet_Line__c>>>
        Map<Id, Map<Id, List<Rate_Sheet_Line__c>>> rateSheetLineByUOMByRes = new Map<Id, Map<Id, List<Rate_Sheet_Line__c>>>();
        if(rateSheetLinesByUOMByResOrResTypeByRateSheet.containsKey(rateSheetId)) {
            rateSheetLineByUOMByRes = rateSheetLinesByUOMByResOrResTypeByRateSheet.get(rateSheetId);
        }

        //Third level Map<Id(UOM Id), List<Rate_Sheet_Line__c>>
        Map<Id, List<Rate_Sheet_Line__c>> rateSheetLineByUOM = new Map<Id, List<Rate_Sheet_Line__c>>();
        if(rateSheetLineByUOMByRes.containsKey(resId)){
            rateSheetLineByUOM = rateSheetLineByUOMByRes.get(resId);
        }

        if(rateSheetLineByUOM.containsKey(pricingUOMId))
        {
            List<Rate_Sheet_Line__c> rateSheetLines = rateSheetLineByUOM.get(pricingUOMId);
            for(Rate_Sheet_Line__c rateSheetLine : rateSheetLines){
                if((facilityId != null && rateSheetLine.Facility__c == facilityId) ||
                        (facilityId == null && rateSheetLine.Facility__c == null)){
                    wasteRateSheetLine = rateSheetLine;
                    break;
                }
            }
        }

        return wasteRateSheetLine;
    }

    /*
        Waste001 - Depreciated
     */
    public static Rate_Sheet_Line__c getWasteRateSheetLine(Id rateSheetId, Id resId, String costMethod, Id pricingUOMId, Id facilityId, Id containerSizeUOM){

        Boolean pricingInfoFound = true;
        Rate_Sheet_Line__c wasteRateSheetLine = new Rate_Sheet_Line__c();
        if(resId == null || String.isBlank(costMethod)) pricingInfoFound = false;

        //Second level Map<Id(Res/Res Type Id), Map<Id(UOM Id), List<Rate_Sheet_Line__c>>>
        Map<Id, Map<Id, List<Rate_Sheet_Line__c>>> rateSheetLineByUOMByRes = new Map<Id, Map<Id, List<Rate_Sheet_Line__c>>>();
        if(rateSheetLinesByUOMByResOrResTypeByRateSheet.containsKey(rateSheetId)) {
            rateSheetLineByUOMByRes = rateSheetLinesByUOMByResOrResTypeByRateSheet.get(rateSheetId);
        }

        //Third level Map<Id(UOM Id), List<Rate_Sheet_Line__c>>
        Map<Id, List<Rate_Sheet_Line__c>> rateSheetLineByUOM = new Map<Id, List<Rate_Sheet_Line__c>>();
        if(rateSheetLineByUOMByRes.containsKey(resId)){
            rateSheetLineByUOM = rateSheetLineByUOMByRes.get(resId);
        }

        if(rateSheetLineByUOM.containsKey(pricingUOMId))
        {
            List<Rate_Sheet_Line__c> rateSheetLines = rateSheetLineByUOM.get(pricingUOMId);
            Map<String, Rate_Sheet_Line__c> rateSheetLineByContainerSizeByFacility = new Map<String, Rate_Sheet_Line__c>();

            for(Rate_Sheet_Line__c rateSheetLine : rateSheetLines) {
                String mapKey = rateSheetLine.Facility__c + ':' + rateSheetLine.Container_Size__c;
                rateSheetLineByContainerSizeByFacility.put(mapKey, rateSheetLine);
            }

            String lookupKey = '';
            if(costMethod == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()){
                if(String.isNotBlank(containerSizeUOM)) {
                    lookupKey = facilityId + ':' + containerSizeUOM;
                }
                else {
                    lookupKey = facilityId + ':null';
                }
            } else {
                lookupKey = facilityId + ':null';
            }

            //System.debug('Info: lookupKey ' + lookupKey);

            if(!rateSheetLineByContainerSizeByFacility.containsKey(lookupKey)){
                if(costMethod == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name() && String.isNotBlank(containerSizeUOM)){
                    lookupKey = facilityId + ':null';
                    if(!rateSheetLineByContainerSizeByFacility.containsKey(lookupKey)) pricingInfoFound = false;
                } else {
                    pricingInfoFound = false;
                }
            }

            if(pricingInfoFound == true && lookupKey != '') wasteRateSheetLine = rateSheetLineByContainerSizeByFacility.get(lookupKey);

            //System.debug('Info: pricingInfoFound ' + pricingInfoFound);
            //System.debug('Info: wasteRateSheetLine ' + wasteRateSheetLine);
        }

        return wasteRateSheetLine;
    }

    public static Decimal getUnitPrice(Rate_Sheet_Line__c rateSheetLine, Boolean isEmergency){
        if(rateSheetLine == null || rateSheetLine.Id == null) return 0;
        if(isEmergency == true && CompanyMgmt.zeroIfNull(rateSheetLine.ER_Unit_Price__c) > 0){
            return CompanyMgmt.zeroIfNull(rateSheetLine.ER_Unit_Price__c);
        } else {
            return CompanyMgmt.zeroIfNull(rateSheetLine.Unit_Price__c);
        }
    }

    public static Decimal getUnitCost(Rate_Sheet_Line__c rateSheetLine){
        if(rateSheetLine == null || rateSheetLine.Id == null) {
            return 0;
        }
        else {
            return CompanyMgmt.zeroIfNull(rateSheetLine.Unit_Cost__c);
        }
    }

    //RSM >>
    public static Rate_Sheet__c getDefaultCompanyRateSheet(Date startDate){
        Rate_Sheet__c rateSheet = new Rate_Sheet__c();
        Map<Id, Id> rateSheetIdByPriceListId = new Map<Id, Id>();
        rateSheetIdByPriceListId = PriceListSelector.newInstance().getActiveRateSheetIdByPricesListIdsAndWorkDate(new Set<Id>{CompanySettingUtil.defaultCompanySetup.Price_List__c}, startDate);
        if(rateSheetIdByPriceListId.size() > 0){
            rateSheet = RateSheetsSelector.newInstance().selectByIds(new Set<Id>{rateSheetIdByPriceListId.values()[0]})[0];
        }
        return rateSheet;
    }

    /*
     *  Ticket#19788
     *      -   update default resource/resource type rate by ratesheet line
     */
    public static void tryToUpdateDefaultResAndResTypePriceByRateSheetLines(List<Rate_Sheet_Line__c> inputRateSheetLines){
        if(inputRateSheetLines.size() > 0) {
            Rate_Sheet__c companyDefaultRateSheet = getDefaultCompanyRateSheet(Date.today());
            List<Rate_Sheet_Line__c> defaultCompanyRateSheetLines = new List<Rate_Sheet_Line__c>();
            for(Rate_Sheet_Line__c rateSheetLine : inputRateSheetLines){
                if(rateSheetLine.Rate_Sheet__c == companyDefaultRateSheet.Id){
                    defaultCompanyRateSheetLines.add(rateSheetLine);
                }
            }
            if(defaultCompanyRateSheetLines.size() > 0){
                updateDefaultResAndResTypePriceByRateSheetLines(defaultCompanyRateSheetLines);
            }
        }
    }

    /*
     *  Ticket#19788
     *      -   Mass update default resource/resource type rate from selected rate sheet
     */
    public static void updateDefaultResAndResTypePriceByRateSheet(Id rateSheetId){
        setRateSheetLines(new Set<Id>{rateSheetId});
        updateDefaultResAndResTypePriceByRateSheetLines(rateSheetLines);
    }

    /*
     *  Ticket#19788
     *      -   update default resource/resource type rate by ratesheet line
     */
    public static void updateDefaultResAndResTypePriceByRateSheetLines(List<Rate_Sheet_Line__c> inputRateSheetLines){
        if(inputRateSheetLines.size() > 0){
            rateSheetLines = inputRateSheetLines;
            setMap_RateSheetLinesByUOMByResTypeByRateSheet();

            Set<Id> resIds = new Set<Id>();
            Set<Id> resTypeIds = new Set<Id>();
            for(Rate_Sheet_Line__c rateSheetLine : rateSheetLines){
                if(String.isNotBlank(rateSheetLine.Resource_Type__c)){
                    resTypeIds.add(rateSheetLine.Resource_Type__c);
                }

                if(String.isNotBlank(rateSheetLine.Resource__c)){
                    resIds.add(rateSheetLine.Resource__c);
                }
            }

            if(resTypeIds.size() > 0){
                ResourceTypeUtil.setResourceTypeMapsByIds(resTypeIds);
            }

            if(resIds.size() > 0){
                ResourceService.setResourceMapsByIds(resIds);
            }

            List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsToUpdate = new List<ResourceTypeUOMAssociation__c>();
            List<ResourceUOMAssociation__c> resourceUOMAssociationsToUpdate = new List<ResourceUOMAssociation__c>();
            for(Rate_Sheet_Line__c rateSheetLine : rateSheetLines) {
                if (String.isNotBlank(rateSheetLine.Unit_of_Measure__c)) {
                    if (String.isNotBlank(rateSheetLine.Resource_Type__c)) {
                        ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = ResourceTypeUtil.getResourceTypeUOMAssociation(rateSheetLine.Resource_Type__c, rateSheetLine.Unit_of_Measure__c);
                        if (resourceTypeUOMAssociation.Id != null) {
                            resourceTypeUOMAssociation.Unit_Price__c = rateSheetLine.Unit_Price__c;
                            if (CompanyMgmt.zeroIfNull(rateSheetLine.ER_Unit_Price__c) > 0) {
                                resourceTypeUOMAssociation.ER_Unit_Price__c = rateSheetLine.ER_Unit_Price__c;
                            }
                            resourceTypeUOMAssociationsToUpdate.add(resourceTypeUOMAssociation);
                        }
                    }

                    if(String.isNotBlank(rateSheetLine.Resource__c)){
                        ResourceUOMAssociation__c resourceUOMAssociation = ResourceService.getResourceUOMAssociation(rateSheetLine.Resource__c, rateSheetLine.Unit_of_Measure__c);
                        if (resourceUOMAssociation.Id != null) {
                            resourceUOMAssociation.Unit_Price__c = rateSheetLine.Unit_Price__c;
                            if (CompanyMgmt.zeroIfNull(rateSheetLine.ER_Unit_Price__c) > 0) {
                                resourceUOMAssociation.ER_Unit_Price__c = rateSheetLine.ER_Unit_Price__c;
                            }
                            resourceUOMAssociationsToUpdate.add(resourceUOMAssociation);
                        }
                    }
                }
            }

            if(resourceUOMAssociationsToUpdate.size() > 0){
                update resourceUOMAssociationsToUpdate;
            }

            if(resourceTypeUOMAssociationsToUpdate.size() > 0){
                update resourceTypeUOMAssociationsToUpdate;
            }
        }
    }
}