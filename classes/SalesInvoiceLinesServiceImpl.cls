public with sharing class SalesInvoiceLinesServiceImpl implements ISalesInvoiceLinesService {
    public static Map<Id, Resource_Type__c> resourceTypesByIds = new Map<Id, Resource_Type__c>();
    public static Map<Id, Resource__c> resourcesByIds = new Map<Id, Resource__c>();
    public static Map<Id, Map<Id, ResourceTypeUOMAssociation__c>> resourceTypeUOMAssociationsByUOMIdsByResTypeIds = new Map<Id, Map<Id, ResourceTypeUOMAssociation__c>>();
    public static Map<Id, Map<Id, List<ResourceUOMAssociation__c>>> resourceUOMAssociationsByUOMIdsByResIds = new Map<Id, Map<Id, List<ResourceUOMAssociation__c>>>();
    public static Map<Id, Service_Center__c> serviceCentersByIds = new Map<Id, Service_Center__c>();
    public static Map<Id, Unit_of_Measure__c> unitOfMeasuresByIds = new Map<Id, Unit_of_Measure__c>();
    
    public static Company_Setup__c defaultCompanySetupValue;
    public static Company_Setup__c defaultCompanySetup {
        get{
            if (defaultCompanySetupValue == null){
                defaultCompanySetupValue = CompanyMgmt.getCompanySetup();
            }
            return defaultCompanySetupValue;
        }
    }
    
    public void initStaticVariables(Sales_Invoice__c salesInvoice, List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers){
        //get ids from sales lines
        Set<Id> resIds = new Set<Id>();
        Set<Id> resTypeIds = new Set<Id>();
        Set<Id> fromQuoteIds = new Set<Id>();
        Set<Id> billingRuleIds = new Set<Id>();
        Set<Id> payRuleIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> uomIds = new Set<Id>();
        Set<Id> rateSheetIds = new Set<Id>();
        Set<Id> priceListIds = new Set<Id>();

        setServiceCenterByIdsMap();
        if(String.isNotBlank(defaultCompanySetup.Price_List__c)) priceListIds.add(defaultCompanySetup.Price_List__c);
        Date estimatedStartDate = Date.today();
        
        List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
        for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            salesInvoiceLines.addAll(jobTaskWrapper.SalesInvoiceLines);
        }

        for(Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines){
            if(isCalcBaseOnResType(salesInvoiceLine.Category__c) == true && salesInvoiceLine.Resource_Type__c != null) {
                resTypeIds.add(salesInvoiceLine.Resource_Type__c);
            }
            if(isCalcBaseOnResType(salesInvoiceLine.Category__c) == false && salesInvoiceLine.Resource__c != null) {
                resIds.add(salesInvoiceLine.Resource__c);
            }
            if(salesInvoiceLine.Unit_of_Measure__c != null) {
                uomIds.add(salesInvoiceLine.Unit_of_Measure__c);
            }
        }

        resIds.add(defaultCompanySetup.Default_Energy_Insurance_Resource__c);
        resIds.add(defaultCompanySetup.Default_Fuel_Surcharge_Resource__c);
        resIds.add(defaultCompanySetup.Default_Manifest_Fee_Resource__c);
        resIds.add(CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c);

        if (salesInvoice.Contract__r.Billing_Rule__c != null) {
            billingRuleIds.add(salesInvoice.Contract__r.Billing_Rule__c);
        }
        billingRuleIds.add(defaultCompanySetup.Default_Billing_Rule__c);

        if(salesInvoice.Contract__c != null) contractIds.add(salesInvoice.Contract__c);
        if(serviceCentersByIds.containsKey(salesInvoice.Service_Center__c)){
            Service_Center__c serviceCenter = serviceCentersByIds.get(salesInvoice.Service_Center__c);
            if(String.isNotBlank(serviceCenter.Price_List__c)) priceListIds.add(serviceCenter.Price_List__c);
        }

        if(resTypeIds != null) {
            setResourceTypeByIdsMap(resTypeIds);
            setResourceTypeUOMAssociationsByUOMIdsByResTypeIdsMap(resTypeIds);
        }

        if(resIds != null){
            setResourceByIdsMap(resIds);
            setResourceUOMAssociationsByUOMIdsByResIds(resIds);
        }

        //collect union worker pay rule id
        if(resourcesByIds.size() > 0){
            for(Resource__c resource:resourcesByIds.values()){
                if(resource.Pay_Rule__c != null) payRuleIds.add(resource.Pay_Rule__c);
            }
        }

        if(contractIds != null) {
            ContractUtil.setContractLineByUOMIdsResOrTypeIdsByContractIdsMap(contractIds, estimatedStartDate);
        }

        if(uomIds != null) {
            setUnitOfMeasureByIdsMap(uomIds);
        }
    }

    public void assignDescription(Sales_Invoice_Line__c salesInvoiceLine) {
        if(isCalcBaseOnResType(salesInvoiceLine.Category__c) == true) {
            if (salesInvoiceLine.Resource_Type__c != null) {
                Resource_Type__c resourceType = resourceTypesByIds.get(salesInvoiceLine.Resource_Type__c);
                salesInvoiceLine.Description__c = resourceType.Description__c;
            }
        }
        else {
            if (salesInvoiceLine.Resource__c != null) {
                Resource__c resource = resourcesByIds.get(salesInvoiceLine.Resource__c);
                salesInvoiceLine.Description__c = resource.Description__c;
            }
        }
    }

    public void assignUnitOfMeasure(Sales_Invoice_Line__c salesInvoiceLine) {
        if(isCalcBaseOnResType(salesInvoiceLine.Category__c) == true) {
            if (salesInvoiceLine.Resource_Type__c != null) {
                Resource_Type__c resourceType = resourceTypesByIds.get(salesInvoiceLine.Resource_Type__c);
                salesInvoiceLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
                salesInvoiceLine.Unit_of_Measure__r = resourceType.Unit_of_Measure__r;
            }
        } else {
            if (salesInvoiceLine.Resource__c != null) {
                Resource__c resource = resourcesByIds.get(salesInvoiceLine.Resource__c);
                salesInvoiceLine.Unit_of_Measure__c = resource.Unit_of_Measure__c;
                salesInvoiceLine.Unit_of_Measure__r = resource.Unit_of_Measure__r;
            }
        }
    }

    public void assignResourceTypeUOM(Sales_Invoice_Line__c salesInvoiceLine){
        if(isCalcBaseOnResType(salesInvoiceLine.Category__c) == true && salesInvoiceLine.Resource_Type__c != null && salesInvoiceLine.Unit_of_Measure__c != null){
            if(resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(salesInvoiceLine.Resource_Type__c)){
                Map<Id, ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsByUOMIds = resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(salesInvoiceLine.Resource_Type__c);
                if(resourceTypeUOMAssociationsByUOMIds.containsKey(salesInvoiceLine.Unit_of_Measure__c)){
                    ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = resourceTypeUOMAssociationsByUOMIds.get(salesInvoiceLine.Unit_of_Measure__c);
                    salesInvoiceLine.Resource_Type_UOM__c = resourceTypeUOMAssociation.Id;
                    salesInvoiceLine.Resource_Type_UOM__r = resourceTypeUOMAssociation;
                }
            }
        }
    }

    public void assignResourceUOM(Sales_Invoice_Line__c salesInvoiceLine){
        if(isCalcBaseOnResType(salesInvoiceLine.Category__c) == false && salesInvoiceLine.Resource__c != null && salesInvoiceLine.Unit_of_Measure__c != null){
            ResourceUOMAssociation__c resourceUOMAssociation = new ResourceUOMAssociation__c();
            if(salesInvoiceLine.Category__c == 'Waste Disposal') {
                resourceUOMAssociation = getWasteResUOMSetup(salesInvoiceLine);
            }
            else if(resourceUOMAssociationsByUOMIdsByResIds.containsKey(salesInvoiceLine.Resource__c)){
                Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(salesInvoiceLine.Resource__c);
                if(resourceUOMAssociationsByUOMIds.containsKey(salesInvoiceLine.Unit_of_Measure__c)) {
                    resourceUOMAssociation = resourceUOMAssociationsByUOMIds.get(salesInvoiceLine.Unit_of_Measure__c)[0];
                }
            }
            if (resourceUOMAssociation.Id != null) {
                salesInvoiceLine.Resource_UOM__c = resourceUOMAssociation.Id;
                salesInvoiceLine.Resource_UOM__r = resourceUOMAssociation;
            }
        }
    }

    public void calcUnitCost(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine){
        String lineCategory = salesInvoiceLine.Category__c;
        Boolean unitCostFound = false;
        Id resOrResTypeId = null;
        Decimal unitCost = 0;
        if( lineCategory == 'Subcontractors') {
            if (salesInvoiceLine.Bill_as_Lump_Sum__c == true || salesInvoiceLine.Non_Billable__c == true) {
                unitCost = salesInvoiceLine.xUnit_Price__c;
            }
            else {
                unitCost = salesInvoiceLine.Unit_Price__c;
            }
            unitCostFound = true;
        }

        if (!unitCostFound) {
            if (isCalcBaseOnResType(lineCategory) == true && salesInvoiceLine.Resource_Type__c != null) {
                resOrResTypeId = salesInvoiceLine.Resource_Type__c;
            } else if (isCalcBaseOnResType(lineCategory) == false && salesInvoiceLine.Resource__c != null) {
                resOrResTypeId = salesInvoiceLine.Resource__c;
            }

            if (resOrResTypeId != null) {
                Service_Center__c serviceCenter = new Service_Center__c();
                if (serviceCentersByIds.containsKey(salesInvoice.Service_Center__c)) {
                    serviceCenter = serviceCentersByIds.get(salesInvoice.Service_Center__c);
                }

                if (salesInvoiceLine.Category__c == 'Waste Disposal') {
                    ResourceUOMAssociation__c wasteResourceUOMAssociation = getWasteResUOMSetup(salesInvoiceLine);
                    if (wasteResourceUOMAssociation.Id != null) unitCost = wasteResourceUOMAssociation.Unit_Cost__c;
                } else if (salesInvoiceLine.Unit_of_Measure__c != null) {
                    unitCost = getUnitCost(salesInvoiceLine.Category__c, resOrResTypeId, salesInvoiceLine.Unit_of_Measure__c);
                }
            }
        }

        salesInvoiceLine.Unit_Cost__c = unitCost;
        if (salesInvoiceLine.Bill_as_Lump_Sum__c == true) {
            salesInvoiceLine.Unit_Cost__c = 0;
        }
    }

    public Decimal getUnitCost(String category, Id resOrTypeId, Id uomId){
        Decimal unitCost = 0;
        if(isCalcBaseOnResType(category) == true){
            if(resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(resOrTypeId)){
                Map<Id, ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsByUOMIds = resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(resOrTypeId);
                if(resourceTypeUOMAssociationsByUOMIds.containsKey(uomId)){
                    ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = resourceTypeUOMAssociationsByUOMIds.get(uomId);
                    unitCost = CompanyMgmt.zeroIfNull(resourceTypeUOMAssociation.Unit_Cost__c);
                }
            }
        } else {
            if(resourceUOMAssociationsByUOMIdsByResIds.containsKey(resOrTypeId)){
                Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(resOrTypeId);
                if(resourceUOMAssociationsByUOMIds.containsKey(uomId)){
                    ResourceUOMAssociation__c resourceUOMAssociation = resourceUOMAssociationsByUOMIds.get(uomId)[0];
                    unitCost = CompanyMgmt.zeroIfNull(resourceUOMAssociation.Unit_Cost__c);
                }
            }
        }
        return  unitCost;
    }

    public void assignTaxPercent(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine) {
        if (salesInvoice.Tax_Liable__c && salesInvoiceLine.Tax_Group__c != null) {
            salesInvoiceLine.Tax_Pct__c = CompanyMgmt.getSalesTax(salesInvoice.Tax_Area__c, salesInvoiceLine.Tax_Group__c);
        }
        else {
            salesInvoiceLine.Tax_Pct__c = 0;
        }
    }

    /*  Ticket#19931
     *    - Job times is not required for Resource Type with Rental Resource Type checked.
     */
    public void calculateLineTotals(Sales_Invoice__c salesInvoice, Sales_Invoice_Line__c salesInvoiceLine) {
        if (salesInvoiceLine.Category__c == 'Subcontractors') {
            if (salesInvoiceLine.Bill_as_Lump_Sum__c == true || salesInvoiceLine.Non_Billable__c == true) {
                salesInvoiceLine.Unit_Cost__c = salesInvoiceLine.xUnit_Price__c;
            }
            else {
                salesInvoiceLine.Unit_Cost__c = salesInvoiceLine.Unit_Price__c;
            }
        }

        Decimal qty = CompanyMgmt.zeroIfNull(salesInvoiceLine.Quantity__c);
        Decimal costQty = CompanyMgmt.zeroIfNull(salesInvoiceLine.Cost_Qty__c);
        Decimal unitPrice = CompanyMgmt.zeroIfNull(salesInvoiceLine.Unit_Price__c);
        Decimal unitCost = CompanyMgmt.zeroIfNull(salesInvoiceLine.Unit_Cost__c);

        if (salesInvoice.Tax_Liable__c == true && salesInvoiceLine.Tax_Group__c != null) {
            salesInvoiceLine.Tax_Pct__c = CompanyMgmt.getSalesTax(salesInvoice.Tax_Area__c, salesInvoiceLine.Tax_Group__c);
        }
        else {
            salesInvoiceLine.Tax_Pct__c = 0;
        }

        if (salesInvoiceLine.Category__c == 'Labor' || (salesInvoiceLine.Resource_Type__r != null && salesInvoiceLine.Resource_Type__r.Fleet_No_Required__c == true && salesInvoiceLine.Resource_Type__r.Rental_Resource_Type__c != true)) {
            salesInvoiceLine.Line_Cost__c = CompanyMgmt.halfUpTo2D(unitCost * costQty);
        }
        else {
            salesInvoiceLine.Line_Cost__c = CompanyMgmt.halfUpTo2D(unitCost * qty);
        }

        salesInvoiceLine.Line_Amount__c = CompanyMgmt.halfUpTo2D(unitPrice * qty);
        salesInvoiceLine.Tax__c = CompanyMgmt.halfUpTo2D(salesInvoiceLine.Line_Amount__c * salesInvoiceLine.Tax_Pct__c / 100);
        salesInvoiceLine.Line_Amt_Incl_Tax__c = salesInvoiceLine.Line_Amount__c + salesInvoiceLine.Tax__c;
    }

    public ResourceUOMAssociation__c getWasteResUOMSetup(Sales_Invoice_Line__c salesInvoiceLine){
        Id lookupUOMId = salesInvoiceLine.Unit_of_Measure__c;
        ResourceUOMAssociation__c wasteResUOMSetup = new ResourceUOMAssociation__c();
        Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = new Map<Id, List<ResourceUOMAssociation__c>>();
        Boolean pricingInfoFound = true;

        if(salesInvoiceLine.Category__c != 'Waste Disposal') return null;

        if (salesInvoiceLine.Resource__c == null) pricingInfoFound = false;

        /*Waste001
        if(salesInvoiceLine.Cost_Method__c == null) lookupUOMId = salesInvoiceLine.Unit_of_Measure__c;
        if(salesInvoiceLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) lookupUOMId = salesInvoiceLine.Unit_Weight_Vol__c;
        if(salesInvoiceLine.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name()) lookupUOMId = salesInvoiceLine.Container_Size__c;
         */

        if(resourceUOMAssociationsByUOMIdsByResIds.containsKey(salesInvoiceLine.Resource__c))
            resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(salesInvoiceLine.Resource__c);

        if(resourceUOMAssociationsByUOMIds.containsKey(lookupUOMId))
        {
            List<ResourceUOMAssociation__c> resourceUOMAssociations = resourceUOMAssociationsByUOMIds.get(lookupUOMId);
            Map<String, ResourceUOMAssociation__c> resUOMByFacilityAndUOM = new Map<String, ResourceUOMAssociation__c>();
            for(ResourceUOMAssociation__c resourceUOMAssociation:resourceUOMAssociations) {
                /*Waste001
                String mapKey;
                if (salesInvoiceLine.Cost_Method__c == null) {
                    mapKey = resourceUOMAssociation.Facility__c + ':' + resourceUOMAssociation.Unit_of_Measure__c;
                }
                else {
                    mapKey = resourceUOMAssociation.Facility__c + ':' + resourceUOMAssociation.Container_Size__c;
                }
                 */
                String mapKey = resourceUOMAssociation.Facility__c + ':' + resourceUOMAssociation.Unit_of_Measure__c;
                resUOMByFacilityAndUOM.put(mapKey, resourceUOMAssociation);
            }

            String lookupKey = '';

            /*Waste001
            if (salesInvoiceLine.Cost_Method__c != null) {
                if (salesInvoiceLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) {
                    if (String.isNotBlank(salesInvoiceLine.Container_Size__c))
                        lookupKey = salesInvoiceLine.Facility__c + ':' + salesInvoiceLine.Container_Size__c; else lookupKey = salesInvoiceLine.Facility__c + ':null';
                } else {
                    lookupKey = salesInvoiceLine.Facility__c + ':null';
                }

                if (!resUOMByContainerSizeByFacility.containsKey(lookupKey)) {
                    if (salesInvoiceLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name() && String.isNotBlank(salesInvoiceLine.Container_Size__c)) {
                        lookupKey = salesInvoiceLine.Facility__c + ':null';
                        if (!resUOMByContainerSizeByFacility.containsKey(lookupKey)) {
                            pricingInfoFound = false;
                        }
                    } else {
                        pricingInfoFound = false;
                    }
                }
            }
            else {

                if (String.isNotBlank(salesInvoiceLine.Unit_of_Measure__c)) {
                    lookupKey = salesInvoiceLine.Facility__c + ':' + salesInvoiceLine.Unit_of_Measure__c;
                }
                else {
                    lookupKey = salesInvoiceLine.Facility__c + ':null';
                }

                Set<String> keys = new Set<String>();
                for (String key : resUOMByContainerSizeByFacility.keySet()) {
                    keys.add(key);
                }

                if (!resUOMByContainerSizeByFacility.containsKey(lookupKey)) {
                    pricingInfoFound = false;
                }
            }
             */
            if (String.isNotBlank(salesInvoiceLine.Unit_of_Measure__c)) {
                lookupKey = salesInvoiceLine.Facility__c + ':' + salesInvoiceLine.Unit_of_Measure__c;
            }
            else {
                lookupKey = salesInvoiceLine.Facility__c + ':null';
            }

            Set<String> keys = new Set<String>();
            for (String key : resUOMByFacilityAndUOM.keySet()) {
                keys.add(key);
            }

            if (!resUOMByFacilityAndUOM.containsKey(lookupKey)) {
                pricingInfoFound = false;
            }

            if(pricingInfoFound == true && lookupKey != '') {
                wasteResUOMSetup = resUOMByFacilityAndUOM.get(lookupKey);
            }
        }
        return wasteResUOMSetup;
    }

    public void setResourceTypeByIdsMap(Set<Id> resTypeIds) {
        resourceTypesByIds.putAll(ResourceTypesSelector.newInstance().selectById(resTypeIds));
    }

    public void setResourceByIdsMap(Set<Id> resIds){
        resourcesByIds.putAll(ResourcesSelector.newInstance().selectById(resIds));
    }

    public void setServiceCenterByIdsMap(){
        serviceCentersByIds.putAll(ServiceCentersSelector.newInstance().selectAll());
    }

    public void setUnitOfMeasureByIdsMap(Set<Id> uomIds){
        unitOfMeasuresByIds.putAll(UnitOfMeasuresSelector.newInstance().selectById(uomIds));
    }

    public void setResourceTypeUOMAssociationsByUOMIdsByResTypeIdsMap(Set<Id> resTypeIds){
        List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeId(resTypeIds);
        for(ResourceTypeUOMAssociation__c resourceTypeUOMAssociation: resourceTypeUOMAssociations){
            Map<Id, ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsByUOMIds = new Map<Id, ResourceTypeUOMAssociation__c>();
            if(resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(resourceTypeUOMAssociation.Resource_Type__c)) {
                resourceTypeUOMAssociationsByUOMIds = resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(resourceTypeUOMAssociation.Resource_Type__c);
            }
            resourceTypeUOMAssociationsByUOMIds.put(resourceTypeUOMAssociation.Unit_of_Measure__c, resourceTypeUOMAssociation);
            resourceTypeUOMAssociationsByUOMIdsByResTypeIds.put(resourceTypeUOMAssociation.Resource_Type__c, resourceTypeUOMAssociationsByUOMIds);
        }
    }

    public void setResourceUOMAssociationsByUOMIdsByResIds(Set<Id> resIds){
        List<ResourceUOMAssociation__c> resourceUOMAssociations = ResourceUnitOfMeasuresSelector.newInstance().selectByResId(resIds);
        for(ResourceUOMAssociation__c resourceUOMAssociation:resourceUOMAssociations){
            Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = new Map<Id, List<ResourceUOMAssociation__c>>();
            if(resourceUOMAssociationsByUOMIdsByResIds.containsKey(resourceUOMAssociation.Resource__c)){
                resourceUOMAssociationsByUOMIds = resourceUOMAssociationsByUOMIdsByResIds.get(resourceUOMAssociation.Resource__c);
            }


            if(resourceUOMAssociationsByUOMIds.containsKey(resourceUOMAssociation.Unit_of_Measure__c)){
                List<ResourceUOMAssociation__c> existingResourceUOMAssociations = resourceUOMAssociationsByUOMIds.get(resourceUOMAssociation.Unit_of_Measure__c);
                existingResourceUOMAssociations.add(resourceUOMAssociation);
                resourceUOMAssociationsByUOMIds.put(resourceUOMAssociation.Unit_of_Measure__c, existingResourceUOMAssociations);
            } else {
                resourceUOMAssociationsByUOMIds.put(resourceUOMAssociation.Unit_of_Measure__c, new List<ResourceUOMAssociation__c>{resourceUOMAssociation});
            }

            resourceUOMAssociationsByUOMIdsByResIds.put(resourceUOMAssociation.Resource__c, resourceUOMAssociationsByUOMIds);
        }
    }
    
    public Boolean isCalcBaseOnResType(String lineCategory){
        if(lineCategory == 'Labor' || lineCategory == 'Equipment' || lineCategory == 'Bundled') return true;
        else return  false;
    }

}