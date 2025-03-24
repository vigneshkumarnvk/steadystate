/*************************************************************************************************
* Name         :  SalesLinesServiceImpl
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      10-13-2024             US127188 - Salesforce - Modifications to allow ESIC Surcharge Type
* Shahwaz Khan              11-20-2024             US132832 - Salesforce - Do not use profile approval description if Contract line is value is selected
* Sanjana Ravichandran      11-27-2024		   DE36665: [Unplanned] Tax Group Not Updating to NT When Deselecting Tax Liable Checkbox
*************************************************************************************************/
public class SalesLinesServiceImpl implements ISalesLinesService{
    public static Map<Id, Map<Id, Map<Id, Sales_Line__c>>> fromQuoteLinesByUOMIdsByResOrTypeIdsByQuoteIds = new Map<Id, Map<Id, Map<Id, Sales_Line__c>>>();
    public static Map<String, Sales_Line__c> wasteQuoteLinesByQuoteResFacilityCostTypeVolContainer = new Map<String, Sales_Line__c>();
    public static Map<Id, Billing_Rule__c> billingRulesByIds = new Map<Id, Billing_Rule__c>();
    public static Map<String, Billing_Rule__c> mapBillingRulesByAssumption = new Map<String, Billing_Rule__c>();
    public static Map<Id, List<Presumptive_Resource__c>> mapPresumptiveResourcesByParentId = new Map<Id, List<Presumptive_Resource__c>>();
    public static Map<Id, Map<Id, Pay_Rule_Line__c>> payRuleLineByResTypeIdsByPayRuleIds = new Map<Id, Map<Id, Pay_Rule_Line__c>>();

    public static Company_Setup__c defaultCompanySetupValue;
    public static Company_Setup__c defaultCompanySetup {
        get{
            if (defaultCompanySetupValue == null){
                defaultCompanySetupValue = CompanyMgmt.getCompanySetup();
            }
            return defaultCompanySetupValue;
        }
    }
    public static Subsidiary_Company__c subsidiaryCompanySetup; //Ticket#21540

    public static Map<Id, Service_Center__c> serviceCentersByIds = new Map<Id, Service_Center__c>();
    public static Map<Id, Unit_of_Measure__c> unitOfMeasuresByIds = new Map<Id, Unit_of_Measure__c>();
    public static Map<Id, Id> rateSheetIdsByPriceListIds = new Map<Id, Id>();

    public void initStaticVariables(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers){
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
        Set<Id> taxAreaIds = new Set<Id>(); //Ticket#23857

        setServiceCenterByIdsMap();
        if(String.isNotBlank(defaultCompanySetup.Price_List__c)) priceListIds.add(defaultCompanySetup.Price_List__c);
        Date estimatedStartDate = Date.today();

        if(salesOrder.Estimated_Job_Start_Date__c != null){
            estimatedStartDate = salesOrder.Estimated_Job_Start_Date__c;
        }

        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            salesLines.addAll(jobTaskWrapper.SalesLines);
        }

        for(Sales_Line__c salesLine : salesLines){
            if (salesLine.Resource_Type__c != null) {
                resTypeIds.add(salesLine.Resource_Type__c);
            }
            if(salesLine.Resource__c != null) {
                resIds.add(salesLine.Resource__c);
            }
            if(salesLine.Unit_of_Measure__c != null) {
                uomIds.add(salesLine.Unit_of_Measure__c);
            }
        }
		
        resIds.add(defaultCompanySetup.Default_Energy_Insurance_Resource__c);
        resIds.add(defaultCompanySetup.Default_Fuel_Surcharge_Resource__c);
        resIds.add(defaultCompanySetup.Default_Manifest_Fee_Resource__c);
        resIds.add(defaultCompanySetup.Default_ESIC_Surcharge_Resource__c);
        resIds.add(CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c);
		
        //presumptive resources <<
        //ticket 19130 <<
        /*
        for (Resource_Type__c resourceType : [SELECT Id, (SELECT Id, Child_Resource_Type__c, Child_Resource__c, Child_Resource__r.Resource_Type__c, Child_Resource__r.Resource_Type__r.Name, Child_Unit_of_Measure__c, Child_Unit_of_Measure__r.Name, Child_Unit_of_Measure__r.Hours_UOM__c FROM Parent_Resource_Types__r) FROM Resource_Type__c WHERE Id IN :resTypeIds]) {
            if (resourceType.Parent_Resource_Types__r.size() > 0) {
                for (Presumptive_Resource__c presumptiveResource : resourceType.Parent_Resource_Types__r) {
                    if (presumptiveResource.Child_Resource_Type__c != null) {
                        resTypeIds.add(presumptiveResource.Child_Resource_Type__c);
                    }
                    else if (presumptiveResource.Child_Resource__c != null) {
                        resIds.add(presumptiveResource.Child_Resource__c);
                        if (presumptiveResource.Child_Resource__r.Resource_Type__c != null) {
                            resTypeIds.add(presumptiveResource.Child_Resource__r.Resource_Type__c);
                        }
                    }
                    if (presumptiveResource.Child_Unit_of_Measure__c != null) {
                        uomIds.add(presumptiveResource.Child_Unit_of_Measure__c);
                    }
                }
                mapPresumptiveResourcesByParentId.put(resourceType.Id, resourceType.Parent_Resource_Types__r);
            }
        }
        for (Resource__c resource : [SELECT Id, (SELECT Id, Child_Resource_Type__c, Child_Resource__c, Child_Resource__r.Resource_Type__c, Child_Resource__r.Resource_Type__r.Name, Child_Unit_of_Measure__c, Child_Unit_of_Measure__r.Name, Child_Unit_of_Measure__r.Hours_UOM__c FROM Parent_Resources__r) FROM Resource__c WHERE Id IN :resIds]) {
            if (resource.Parent_Resources__r.size() > 0) {
                for (Presumptive_Resource__c presumptiveResource : resource.Parent_Resources__r) {
                    if (presumptiveResource.Child_Resource_Type__c != null) {
                        resTypeIds.add(presumptiveResource.Child_Resource_Type__c);
                    }
                    else if (presumptiveResource.Child_Resource__c != null) {
                        resIds.add(presumptiveResource.Child_Resource__c);
                        if (presumptiveResource.Child_Resource__r.Resource_Type__c != null) {
                            resTypeIds.add(presumptiveResource.Child_Resource__r.Resource_Type__c);
                        }
                    }
                    if (presumptiveResource.Child_Unit_of_Measure__c != null) {
                        uomIds.add(presumptiveResource.Child_Unit_of_Measure__c);
                    }
                }
                mapPresumptiveResourcesByParentId.put(resource.Id, resource.Parent_Resources__r);
            }
        }
        */
        Integer loopCount = 0;
        while (loopCount < 2) { //retrieve 2 levels of child resources
            for (Resource_Type__c resourceType : [SELECT Id, (SELECT Id, Child_Resource_Type__c, Child_Resource__c, Child_Resource__r.Resource_Type__c, Child_Resource__r.Resource_Type__r.Name, Child_Unit_of_Measure__c, Child_Unit_of_Measure__r.Name, Child_Unit_of_Measure__r.Hours_UOM__c FROM Parent_Resource_Types__r) FROM Resource_Type__c WHERE Id IN :resTypeIds]) {
                if (resourceType.Parent_Resource_Types__r.size() > 0) {
                    for (Presumptive_Resource__c presumptiveResource : resourceType.Parent_Resource_Types__r) {
                        if (presumptiveResource.Child_Resource_Type__c != null) {
                            resTypeIds.add(presumptiveResource.Child_Resource_Type__c);
                        } else if (presumptiveResource.Child_Resource__c != null) {
                            resIds.add(presumptiveResource.Child_Resource__c);
                            if (presumptiveResource.Child_Resource__r.Resource_Type__c != null) {
                                resTypeIds.add(presumptiveResource.Child_Resource__r.Resource_Type__c);
                            }
                        }
                        if (presumptiveResource.Child_Unit_of_Measure__c != null) {
                            uomIds.add(presumptiveResource.Child_Unit_of_Measure__c);
                        }
                    }
                    mapPresumptiveResourcesByParentId.put(resourceType.Id, resourceType.Parent_Resource_Types__r);
                }
            }
            for (Resource__c resource : [SELECT Id, (SELECT Id, Child_Resource_Type__c, Child_Resource__c, Child_Resource__r.Resource_Type__c, Child_Resource__r.Resource_Type__r.Name, Child_Unit_of_Measure__c, Child_Unit_of_Measure__r.Name, Child_Unit_of_Measure__r.Hours_UOM__c FROM Parent_Resources__r) FROM Resource__c WHERE Id IN :resIds]) {
                if (resource.Parent_Resources__r.size() > 0) {
                    for (Presumptive_Resource__c presumptiveResource : resource.Parent_Resources__r) {
                        if (presumptiveResource.Child_Resource_Type__c != null) {
                            resTypeIds.add(presumptiveResource.Child_Resource_Type__c);
                        } else if (presumptiveResource.Child_Resource__c != null) {
                            resIds.add(presumptiveResource.Child_Resource__c);
                            if (presumptiveResource.Child_Resource__r.Resource_Type__c != null) {
                                resTypeIds.add(presumptiveResource.Child_Resource__r.Resource_Type__c);
                            }
                        }
                        if (presumptiveResource.Child_Unit_of_Measure__c != null) {
                            uomIds.add(presumptiveResource.Child_Unit_of_Measure__c);
                        }
                    }
                    mapPresumptiveResourcesByParentId.put(resource.Id, resource.Parent_Resources__r);
                }
            }
            loopCount++;
        }
        //ticket 19130 >>
        //presumptive resources >>

        if(salesOrder.From_Sales_Quote__c != null && salesOrder.Document_Type__c == 'Sales Order') {
            fromQuoteIds.add(salesOrder.From_Sales_Quote__c);
        }

        if (salesOrder.Contract__r.Billing_Rule__c != null) {
            billingRuleIds.add(salesOrder.Contract__r.Billing_Rule__c);
        }
        //Ticket#21540
        if(salesOrder.Subsidiary_Company__c != null){
            subsidiaryCompanySetup = CompanySettingUtil.getSubsidiaryCompanySetup(salesOrder.Subsidiary_Company__c);
            if(subsidiaryCompanySetup.Billing_Rule__c != null){
                billingRuleIds.add(subsidiaryCompanySetup.Billing_Rule__c);
            }
        }
        //Ticket#21540
        billingRuleIds.add(defaultCompanySetup.Default_Billing_Rule__c);

        if(salesOrder.Pay_Rule__c != null) payRuleIds.add(salesOrder.Pay_Rule__c);
        if(salesOrder.Contract__c != null) contractIds.add(salesOrder.Contract__c);
        //if(salesOrder.Rate_Sheet__c != null) rateSheetIds.add(salesOrder.Rate_Sheet__c);
        if(serviceCentersByIds.containsKey(salesOrder.Service_Center__c)){
            Service_Center__c serviceCenter = serviceCentersByIds.get(salesOrder.Service_Center__c);
            if(String.isNotBlank(serviceCenter.Price_List__c)) priceListIds.add(serviceCenter.Price_List__c);
        }

        if(salesOrder.Rate_Sheet__c != null){
            rateSheetIds.add(salesOrder.Rate_Sheet__c);
        }

        if(resTypeIds != null) {
            ResourceTypeUtil.setResourceTypeMapsByIds(resTypeIds);
            uomIds.addAll(ResourceTypeUtil.uomIds);
            /* moved to resource type util.
            setResourceTypeByIdsMap(resTypeIds);
            setResourceTypeUOMAssociationsByUOMIdsByResTypeIdsMap(resTypeIds);
             */
        }

        if(resIds != null){
            ResourceService.setResourceMapsByIds(resIds);
            uomIds.addAll(ResourceService.resourceUOMIds);
            /*
            setResourceByIdsMap(resIds);
            setResourceUOMAssociationsByUOMIdsByResIds(resIds);
             */
        }

        //collect union worker pay rule id
        if(ResourceService.resourcesByIds.size() > 0){
            for(Resource__c resource: ResourceService.resourcesByIds.values()){
                if(resource.Pay_Rule__c != null) payRuleIds.add(resource.Pay_Rule__c);
            }
        }

        if(fromQuoteIds != null) setFromQuoteLinesByResOrTypeIdsByQuoteIdsMap(fromQuoteIds);
        if(contractIds != null) {
            ContractUtil.setContractLineByUOMIdsResOrTypeIdsByContractIdsMap(contractIds, estimatedStartDate);
        }

        if (billingRuleIds != null) {
            setBillingRulesByIdsMap(billingRuleIds);
        }

        //billing rule mapping <<
        setBillingRulesByAssumptions();
        //billing rule mapping >>

        if(payRuleIds != null) {
            setPayRuleLinesByResTypeIdsByPayRuleIdsMap(payRuleIds);
        }

        if(uomIds != null) {
            setUnitOfMeasureByIdsMap(uomIds);
        }

        rateSheetIdsByPriceListIds = PriceListSelector.newInstance().getActiveRateSheetIdByPricesListIdsAndWorkDate(priceListIds, estimatedStartDate);
        for(Id rateSheetId : rateSheetIdsByPriceListIds.values()){
            rateSheetIds.add(rateSheetId);
        }

        if(rateSheetIds.size() > 0){
            RateSheetService.setRateSheetLines(rateSheetIds);
            RateSheetService.setMap_RateSheetLinesByUOMByResTypeByRateSheet();
        }

        //Ticket#23857 >>
        if(salesOrder.Tax_Area__c != null){
            taxAreaIds.add(salesOrder.Tax_Area__c);
        }

        if(taxAreaIds.size() > 0){
            TaxService.setTaxPctByTaxGroupByTaxAreaIdMap(taxAreaIds);
        }
        //Ticket#23857 <<
    }

    public Sales_Line__c newSalesLine(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, String category, Integer lineNo) {
        Sales_Line__c salesLine = new Sales_Line__c();
        salesLine.Sales_Order__c = salesOrder.Id;
        salesLine.Category__c = category;
        salesLine.Line_No__c = lineNo;
        salesLine.Sales_Order_Job_Task__c = jobTask.Id;
        salesLine.Sales_Order_Job_Task__r = jobTask;
        salesLine.Resource_Type__c = null;
        salesLine.Quantity__c = 0;

        //assign default resource for specific categories
        if (category == 'Subcontractors') {
            salesLine.Resource__c = defaultCompanySetup.Default_Subcontractor_Resource__c;
            salesLine.Resource__r = defaultCompanySetup.Default_Subcontractor_Resource__r;
            salesLine.Unit_of_Measure__c = defaultCompanySetup.Default_Subcontractor_Resource__r.Unit_of_Measure__c;
            salesLine.Unit_of_Measure__r = defaultCompanySetup.Default_Subcontractor_Resource__r.Unit_of_Measure__r;
            salesLine.Description__c = defaultCompanySetup.Default_Subcontractor_Resource__r.Description__c;
        }
        else if (category == 'Bundled') {
            salesLine.Resource__c = defaultCompanySetup.Default_Lump_Sum_Resource__c;
            salesLine.Resource__r = defaultCompanySetup.Default_Lump_Sum_Resource__r;
            salesLine.Unit_of_Measure__c = defaultCompanySetup.Default_Lump_Sum_Resource__r.Unit_of_Measure__c;
            salesLine.Unit_of_Measure__r = defaultCompanySetup.Default_Lump_Sum_Resource__r.Unit_of_Measure__r;
            salesLine.Description__c = defaultCompanySetup.Default_Lump_Sum_Resource__r.Description__c;
            salesLine.Quantity__c = 1;
        }
        else if (category == 'Labor' || category == 'Equipment' || category == 'Materials') {
            salesLine.Number_of_Day__c = salesOrder.Duration__c;
        }
        
        //Whild updating Sales Line, facility is still exists for other category also
        if(category != 'Waste Disposal')
        {
            salesLine.facility__c = null;
        }
        salesLine.Unit_Price__c = 0;
        salesLine.Unit_Cost__c = 0;
        salesLine.Tax_Group__c = (salesOrder.Tax_Liable__c ? 'TX' : 'NT');
        assignTaxPercent(salesOrder, salesLine);

        return salesLine;
    }

    public void assignDescription(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        Boolean contractLineDescriptionFound = false;
        //US132832
        if(String.isNotBlank(salesOrder.Contract__c) && salesLine.Contract_Line__c != null) {
            Contract_Line__c contractLine = ContractUtil.getContractLine(salesLine.Contract_Line__c);
            if (String.isNotBlank(contractLine.Customer_Description__c)) {
                salesLine.Description__c = contractLine.Customer_Description__c;
                contractLineDescriptionFound = true;
            }
        }

        if (!contractLineDescriptionFound) {
            if(isCalcBaseOnResType(salesLine.Category__c) == true) {
                if (salesLine.Resource_Type__c != null) {
                    Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(salesLine.Resource_Type__c);
                    salesLine.Description__c = resourceType.Description__c;
                }
            }
            else {
                if (salesLine.Resource__c != null && salesLine.Approval_Id__c == null) {
                    Resource__c resource = ResourceService.resourcesByIds.get(salesLine.Resource__c);
                    //ticket 20112 <<
                    //salesLine.Description__c = resource.Description__c;
                    if (resource.Description__c != null) {
                        salesLine.Description__c = resource.Description__c;
                    }
                    //ticket 20112 >>
                }
            }
        }
    }

    public Id getResOrResTypeId(Sales_Line__c salesLine){
        if (isCalcBaseOnResType(salesLine.Category__c) == true) {
            return salesLine.Resource_Type__c;
        } else {
            return salesLine.Resource__c;
        }
    }

    public void assignUnitOfMeasure(Sales_Line__c salesLine) {
        if(isCalcBaseOnResType(salesLine.Category__c) == true) {
            if (salesLine.Resource_Type__c != null) {
                Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(salesLine.Resource_Type__c);
                salesLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
                salesLine.Unit_of_Measure__r = resourceType.Unit_of_Measure__r;
            }
        } else {
            if (salesLine.Resource__c != null) {
                Resource__c resource = ResourceService.resourcesByIds.get(salesLine.Resource__c);
                salesLine.Unit_of_Measure__c = resource.Unit_of_Measure__c;
                salesLine.Unit_of_Measure__r = resource.Unit_of_Measure__r;
            }
        }
    }

    public void assignUnitOfMeasure(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        Unit_of_Measure__c defaultUnitOfMeasure;
        Id resOrResTypeId;
        if(isCalcBaseOnResType(salesLine.Category__c)){
            resOrResTypeId = salesLine.Resource_Type__c;
        } else {
            resOrResTypeId = salesLine.Resource__c;
        }

        if(String.isNotBlank(salesOrder.Contract__c)){
            defaultUnitOfMeasure = getDefaultContractUnitOfMeasure(salesLine, salesOrder.Contract__c);
        }

        if(defaultUnitOfMeasure == null && String.isNotBlank(salesOrder.Rate_Sheet__c)){
            Rate_Sheet_Line__c rateSheetLine = RateSheetService.getDefaultRateSheetLine(salesOrder.Rate_Sheet__c, resOrResTypeId);
            defaultUnitOfMeasure = rateSheetLine.Unit_of_Measure__r;
        }

        //contract specific resource <<
        if(String.isNotBlank(salesOrder.Contract__c) && defaultUnitOfMeasure != null){
            salesLine.Unit_of_Measure__c = defaultUnitOfMeasure.Id;
            salesLine.Unit_of_Measure__r = defaultUnitOfMeasure;
            return;
        }
        //contract specific resource >>

        if(defaultUnitOfMeasure == null){
            if(isCalcBaseOnResType(salesLine.Category__c) == true) {
                if (salesLine.Resource_Type__c != null) {
                    Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(salesLine.Resource_Type__c);
                    salesLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
                    salesLine.Unit_of_Measure__r = resourceType.Unit_of_Measure__r;
                }
            } else {
                if (salesLine.Resource__c != null) {
                    Resource__c resource = ResourceService.resourcesByIds.get(salesLine.Resource__c);
                    salesLine.Unit_of_Measure__c = resource.Unit_of_Measure__c;
                    salesLine.Unit_of_Measure__r = resource.Unit_of_Measure__r;
                }
            }
        } else {
            salesLine.Unit_of_Measure__c = defaultUnitOfMeasure.Id;
            salesLine.Unit_of_Measure__r = defaultUnitOfMeasure;
        }
    }

    public Unit_of_Measure__c getDefaultContractUnitOfMeasure(Sales_Line__c salesLine, Id contractId) {
        Unit_of_Measure__c defaultUnitOfMeasure;
        Id resOrResTypeId = null;
        if(isCalcBaseOnResType(salesLine.Category__c) == true){
            resOrResTypeId = salesLine.Resource_Type__c;
        } else {
            resOrResTypeId = salesLine.Resource__c;
        }

        if(String.isNotBlank(contractId)) {
            if (ContractUtil.contractLineByUOMIdsResOrTypeIdsByContractIds.containsKey(contractId)) {
                Map<Id, Map<Id, Contract_Line__c>> contractLineByUOMIdsByResTypeId = ContractUtil.contractLineByUOMIdsResOrTypeIdsByContractIds.get(contractId);
                if (contractLineByUOMIdsByResTypeId.containsKey(resOrResTypeId)) {
                    Map<Id, Contract_Line__c> contractLinesByUOMIds = contractLineByUOMIdsByResTypeId.get(resOrResTypeId);
                    for(Id uomId : contractLinesByUOMIds.keySet()){
                        Contract_Line__c contractLine = contractLinesByUOMIds.get(uomId);
                        //auto select if there is only one contract line <<
                        //if(contractLine.Default__c == true){
                        if(contractLine.Default__c == true || contractLinesByUOMIds.size() == 1) {
                            //auto select if there is only one contract line >>
                            defaultUnitOfMeasure = contractLine.Unit_of_Measure__r;
                        }
                    }
                }
            }
        }
        return defaultUnitOfMeasure;
    }
    public void assignResourceTypeUOM(Sales_Line__c salesLine){
        if(isCalcBaseOnResType(salesLine.Category__c) == true && salesLine.Resource_Type__c != null && salesLine.Unit_of_Measure__c != null){
            if(ResourceTypeUtil.resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(salesLine.Resource_Type__c)){
                Map<Id, ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsByUOMIds = ResourceTypeUtil.resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(salesLine.Resource_Type__c);
                if(resourceTypeUOMAssociationsByUOMIds.containsKey(salesLine.Unit_of_Measure__c)){
                    ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = resourceTypeUOMAssociationsByUOMIds.get(salesLine.Unit_of_Measure__c);
                    salesLine.Resource_Type_UOM__c = resourceTypeUOMAssociation.Id;
                    salesLine.Resource_Type_UOM__r = resourceTypeUOMAssociation;
                }
            }
        }
    }

    public void assignResourceUOM(Sales_Line__c salesLine){
        if(isCalcBaseOnResType(salesLine.Category__c) == false && salesLine.Resource__c != null && salesLine.Unit_of_Measure__c != null){
            ResourceUOMAssociation__c resourceUOMAssociation = new ResourceUOMAssociation__c();
            if(salesLine.Category__c == 'Waste Disposal') {
                resourceUOMAssociation = getWasteResUOMSetup(salesLine);
            }
            else if(ResourceService.resourceUOMAssociationsByUOMIdsByResIds.containsKey(salesLine.Resource__c)){
                Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = ResourceService.resourceUOMAssociationsByUOMIdsByResIds.get(salesLine.Resource__c);
                if(resourceUOMAssociationsByUOMIds.containsKey(salesLine.Unit_of_Measure__c)) {
                    resourceUOMAssociation = resourceUOMAssociationsByUOMIds.get(salesLine.Unit_of_Measure__c)[0];
                }
            }

            if (resourceUOMAssociation.Id != null) {
                salesLine.Resource_UOM__c = resourceUOMAssociation.Id;
                salesLine.Resource_UOM__r = resourceUOMAssociation;
            }
        }
    }

    public void assignTaxPercent(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        if (salesOrder.Tax_Liable__c && salesLine.Tax_Group__c != null) {
            //Ticket#23857 >>
            //salesLine.Tax_Pct__c = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, salesLine.Tax_Group__c);
            salesLine.Tax_Pct__c = TaxService.getTaxPct(salesOrder.Tax_Area__c, salesLine.Tax_Group__c);
            //Ticket#23857 <<
        }
        else {
            salesLine.Tax_Pct__c = 0;
        }
    }

    public void calcUnitPrice(Sales_Order__c salesOrder, Sales_Line__c salesLine){
        // System.debug('Info# calcUnitPrice Begin');
        //System.debug('Info: salesOrder ' + salesOrder);
        //System.debug('Info: salesOrder Name ' + salesOrder.Name);
    
        Id resOrTypeId = null;
        Boolean pricingInfoFound = false;
        if (isCalcBaseOnResType(salesLine.Category__c) == true && salesLine.Resource_Type__c != null) {
            resOrTypeId = salesLine.Resource_Type__c;
        }
        else if(isCalcBaseOnResType(salesLine.Category__c) == false && salesLine.Resource__c != null) {
            resOrTypeId = salesLine.Resource__c;
        }

        Service_Center__c serviceCenter = new Service_Center__c();
        if(serviceCentersByIds.containsKey(salesOrder.Service_Center__c)) {
            serviceCenter = serviceCentersByIds.get(salesOrder.Service_Center__c);
        }

        //ticket 20112 <<
        Decimal originalUnitPrice = 0;
        if (salesLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY || salesLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY) {
            if (salesLine.Bill_as_Lump_Sum__c == true) {
                originalUnitPrice = salesLine.xUnit_Price__c;
            }
            else {
                originalUnitPrice = salesLine.Unit_Price__c;
            }
        }
        //ticket 20112 >>

        //contract pricing fix 11.10.2020 <<
        salesLine.Unit_Price__c = 0;
        salesLine.Regular_Rate__c = 0;
        salesLine.Overtime_Rate__c = 0;
        salesLine.Premium_Rate__c = 0;
        salesLine.xRegular_Rate__c = 0;
        salesLine.xOvertime_Rate__c = 0;
        salesLine.xPremium_Rate__c = 0;
        //contract pricing fix 11.10.2020 <<

        if(resOrTypeId != null) {
            //check quote lines
            
            if(salesOrder.From_Sales_Quote__c != null) {
                Sales_Line__c quotedLine = getQuotedLine(salesOrder.From_Sales_Quote__c, resOrTypeId, salesLine.Unit_of_Measure__c);
                if (String.isNotBlank(quotedLine.Id)) {
                    salesLine.Quote_Line__c = quotedLine.Id;
                    if (salesLine.Category__c == 'Labor') {
                        salesLine.Regular_Rate__c = quotedLine.Regular_Rate__c;
                        salesLine.Overtime_Rate__c = quotedLine.Overtime_Rate__c;
                        salesLine.Premium_Rate__c = quotedLine.Premium_Rate__c;
                        calcLaborUnitPrice(salesOrder, salesLine);
                    } else {
                        salesLine.Unit_Price__c = quotedLine.Unit_Price__c;
                    }
                    //job task <<
                    //salesLine.Pricing_Source_2__c = quotedLine.Pricing_Source_2__c;
                    salesLine.Pricing_Source_2__c = quotedLine.Sales_Order__r.Name;
                    if(String.isNotBlank(quotedLine.Contract_Line__c) && salesLine.isContractLineNotEditable__c == false) { //andrew
                        salesLine.Contract_Line__c = quotedLine.Contract_Line__c;
                        salesLine.Contract_Line__r = quotedLine.Contract_Line__r;
                        salesLine.Pricing_Source_2__c = salesOrder.Contract__r.Name;
                         //Update sales line descriptions if the contract changes on the sales order
                        Contract_Line__c SOcontractLine = new Contract_Line__c();
                        if (salesLine.Contract_Line__c != null) {
                            SOcontractLine = ContractUtil.getContractLine(salesLine.Contract_Line__c);
                        } else {
                            SOcontractLine = ContractUtil.getContractLine(salesOrder.Contract__c, resOrTypeId, salesLine.Unit_of_Measure__c);
                        }
                        salesLine.Description__c = ContractUtil.generateLineDescription(salesLine.Description__c, SOcontractLine.Customer_Item_No__c, SOcontractLine.Customer_Description__c);
                    }
                    //job task >>
                    pricingInfoFound = true;
                    System.debug('Get Quote Line Price >>> '+quotedLine);
                    //System.debug('Info: Quote Pricing ' + pricingInfoFound);
                    //System.debug('Info: Pricing ' + salesLine.Unit_of_Measure__c + ' ' + salesLine.Unit_Price__c);
                    //aura << let the code run to the last line to set xUnit Price
                    //return;
                    //arua >>

                   
                  
                }
            }

            //check contract lines
            if(salesOrder.Contract__c != null && pricingInfoFound == false){
                system.debug('Info: contract pricing');
                Contract_Line__c contractLine = new Contract_Line__c();
                if (salesLine.Contract_Line__c != null) {
                    contractLine = ContractUtil.getContractLine(salesLine.Contract_Line__c);
                }
                else {
                    /* Ticket#21616
                    if (salesLine.Category__c == 'Waste Disposal') {
                        contractLine = ContractUtil.getContractLine(salesOrder.Contract__c, resOrTypeId, salesLine.Unit_of_Measure__c, salesLine.Facility__c);
                    } else {
                        contractLine = ContractUtil.getContractLine(salesOrder.Contract__c, resOrTypeId, salesLine.Unit_of_Measure__c);
                    }
                     */
                    contractLine = ContractUtil.getContractLine(salesOrder.Contract__c, resOrTypeId, salesLine.Unit_of_Measure__c);
                }

                if(String.isBlank(contractLine.Id) == false && salesLine.isContractLineNotEditable__c == false){  //andrew 
                    salesLine.Contract_Line__c = contractLine.Id;
                    salesLine.Contract_Line__r = contractLine;

                    salesLine.Description__c = ContractUtil.generateLineDescription(salesLine.Description__c, contractLine.Customer_Item_No__c, contractLine.Customer_Description__c);

                    salesLine.Contract_Regular_Rate__c = contractLine.Regular_Rate__c;
                    salesLine.Contract_Overtime_Rate__c = contractLine.Overtime_Rate__c;
                    salesLine.Contract_Premium_Rate__c = contractLine.Premium_Rate__c;
                    if(salesLine.Category__c == 'Labor'){
                        salesLine.Regular_Rate__c = contractLine.Regular_Rate__c;
                        salesLine.Overtime_Rate__c = contractLine.Overtime_Rate__c;
                        salesLine.Premium_Rate__c = contractLine.Premium_Rate__c;
                        calcLaborUnitPrice(salesOrder, salesLine);
                    } else if (salesLine.Category__c == 'Waste Disposal') {
                        salesLine.Unit_Price__c = contractLine.Regular_Rate__c;
                        salesLine.Min_Sell_Qty__c = contractLine.Min_Sell_Qty__c;
                    } else {
                        salesLine.Unit_Price__c = contractLine.Regular_Rate__c;
                    }

                    salesLine.Pricing_Source_2__c = contractLine.Contract__r.Name;

                    pricingInfoFound = true;
                    //aura << let the code run to the last line to set xUnit Price
                    //return;
                    //aura >>
                }

                // andrew
                if(salesLine.isContractLineNotEditable__c == true) { 
                    salesLine.Contract_Line__c = null;
                    salesLine.Contract_Line__r = null;
                }
                // andrew
            }

            if(pricingInfoFound == false && String.isNotBlank(salesOrder.Rate_Sheet__c)){
                Decimal unitPrice = 0;
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine(salesOrder, salesLine, salesOrder.Rate_Sheet__c);
                if(rateSheetLine != null && rateSheetLine.Id != null) {
                    salesLine.Min_Sell_Qty__c = CompanyMgmt.zeroIfNull(rateSheetLine.Min_Sell_Qty__c);
                }
                unitPrice = RateSheetService.getUnitPrice(rateSheetLine, salesOrder.Emergency_Sales_Order__c);
                if(unitPrice > 0){
                    if(salesLine.Category__c == 'Labor'){
                        salesLine.Regular_Rate__c = unitPrice;
                        salesLine.Overtime_Rate__c = unitPrice * 1.5;
                        salesLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(salesOrder, salesLine);
                    } else {
                        salesLine.Unit_Price__c = unitPrice;
                    }
                    salesLine.Pricing_Source_2__c = rateSheetLine.Rate_Sheet__r.Name;
                    pricingInfoFound = true;
                    System.debug('Rate Sheet Price >>> '+rateSheetLine);
                }
            }

            if(pricingInfoFound == false && String.isNotBlank(serviceCenter.Price_List__c)){
                //system.debug('Info: service center pricing sheet');
                Decimal unitPrice = 0;
                Id rateSheetId = null;
                if(rateSheetIdsByPriceListIds.containsKey(serviceCenter.Price_List__c)) {
                    rateSheetId = rateSheetIdsByPriceListIds.get(serviceCenter.Price_List__c);
                }
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine(salesOrder, salesLine, rateSheetId);
                if(rateSheetLine != null && rateSheetLine.Id != null) {
                    salesLine.Min_Sell_Qty__c = CompanyMgmt.zeroIfNull(rateSheetLine.Min_Sell_Qty__c);
                }
                unitPrice = RateSheetService.getUnitPrice(rateSheetLine, salesOrder.Emergency_Sales_Order__c);
                if(unitPrice > 0){
                    if(salesLine.Category__c == 'Labor'){
                        salesLine.Regular_Rate__c = unitPrice;
                        salesLine.Overtime_Rate__c = unitPrice * 1.5;
                        salesLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(salesOrder, salesLine);
                    } else {
                        salesLine.Unit_Price__c = unitPrice;
                    }
                    salesLine.Pricing_Source_2__c = rateSheetLine.Rate_Sheet__r.Name;
                    pricingInfoFound = true;
                    System.debug('Rate Sheet2 Price >>> '+rateSheetLine);
                }
            }

            if(pricingInfoFound == false && String.isNotBlank(defaultCompanySetup.Price_List__c)){
                //system.debug('Info: company pricing sheet');
                Decimal unitPrice = 0;
                Id rateSheetId = null;
                if(rateSheetIdsByPriceListIds.containsKey(defaultCompanySetup.Price_List__c)) {
                    rateSheetId = rateSheetIdsByPriceListIds.get(defaultCompanySetup.Price_List__c);
                }
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine(salesOrder, salesLine, rateSheetId);
                if(rateSheetLine != null && rateSheetLine.Id != null) {
                    salesLine.Min_Sell_Qty__c = CompanyMgmt.zeroIfNull(rateSheetLine.Min_Sell_Qty__c);
                }
                unitPrice = RateSheetService.getUnitPrice(rateSheetLine, salesOrder.Emergency_Sales_Order__c);
                if(unitPrice > 0){
                    if(salesLine.Category__c == 'Labor'){
                        salesLine.Regular_Rate__c = unitPrice;
                        salesLine.Overtime_Rate__c = unitPrice * 1.5;
                        salesLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(salesOrder, salesLine);
                    } else {
                        salesLine.Unit_Price__c = unitPrice;
                    }
                    salesLine.Pricing_Source_2__c = rateSheetLine.Rate_Sheet__r.Name;
                    pricingInfoFound = true;
                    System.debug('Rate Sheet 3 Price >>> '+rateSheetLine);
                }
            }

            //standard rate
            if(pricingInfoFound == false) {
                //system.debug('Info: resource pricing ');
                if(salesLine.Category__c == 'Waste Disposal'){
                    ResourceUOMAssociation__c wasteResUOMAssociation = getWasteResUOMSetup(salesLine);
                    if(wasteResUOMAssociation.Id != null){
                        if(salesOrder.Emergency_Sales_Order__c == true) {
                            salesLine.Unit_Price__c = wasteResUOMAssociation.ER_Unit_Price__c;
                        }
                        else {
                            salesLine.Unit_Price__c = wasteResUOMAssociation.Unit_Price__c;
                        }
                        salesLine.Min_Sell_Qty__c = wasteResUOMAssociation.Min_Sell_Qty__c;
                    } else {
                        salesLine.Unit_Price__c = 0;
                        salesLine.Min_Sell_Qty__c = 0;
                    }
                } else {
                    Decimal unitPrice = this.getUnitPrice(salesLine.Category__c, resOrTypeId, salesLine.Unit_of_Measure__c, salesOrder.Emergency_Sales_Order__c);
                    if(salesLine.Category__c == 'Labor'){
                        salesLine.Regular_Rate__c = unitPrice;
                        salesLine.Overtime_Rate__c = unitPrice * 1.5;
                        salesLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(salesOrder, salesLine);
                    } else {
                        salesLine.Unit_Price__c = unitPrice;
                    }
                    System.debug('unit Price cals >>> '+unitPrice);
                }
                //Ticket#25378
                //if(CompanyMgmt.zeroIfNull(salesLine.Unit_Price__c) > 0) {
                if(CompanyMgmt.zeroIfNull(salesLine.Unit_Price__c) > 0 || (salesLine.Category__c == 'Labor' && salesLine.Bill_as_Lump_Sum__c == true)) {
                    //contract pricing fix 11.10.2020 <<
                    pricingInfoFound = true;
                    //contract pricing fix 11.10.2020 <<
                    salesLine.Pricing_Source_2__c = EnumUtil.PricingSource.BASE.name();
                }
            }
        }

        //contract pricing fix 11.10.2020 <<
        if (pricingInfoFound != true) {
            //ticket 20112 <<
            //salesLine.Pricing_Source_2__c = null;
            if (salesLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY || salesLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY) {
                salesLine.Unit_Price__c = originalUnitPrice;
                System.debug('unit Price originalUnitPrice >>> '+originalUnitPrice);
            }
            else {
                salesLine.Pricing_Source_2__c = null;
            }
            //ticket 20112 >>
        }
        //contract pricing fix 11.10.2020 >>
        //system.debug('Info: sales line unit price = ' + salesLine.Unit_Price__c);

        //aura <<
        salesLine.xUnit_Price__c = salesLine.Unit_Price__c;
        if (salesLine.Bill_as_Lump_Sum__c == true) {
            salesLine.Unit_Price__c = 0;
        }
        
        if(salesLine.Category__c == 'Waste Disposal' && salesLine.Disposal_Billing_Method__c == 'Direct')
        {
             salesLine.Unit_Price__c = 0;
             salesLine.xUnit_Price__c = 0;
        }
           
        //aura >>
    }

    public void calcLaborUnitPrice(Sales_Order__c salesOrder, Sales_Line__c salesLine){
        if(salesLine.Category__c != 'Labor') {
            return;
        }

        Boolean isDayUOM = false;

        Unit_of_Measure__c unitOfMeasure = new Unit_of_Measure__c();
        if (!String.isBlank(salesLine.Unit_of_Measure__c)) {
            if(!unitOfMeasuresByIds.containsKey(salesLine.Unit_of_Measure__c)){
                Unit_of_Measure__c uom = UnitOfMeasuresSelector.newInstance().selectById(new Set<Id>{salesLine.Unit_of_Measure__c})[0];
                unitOfMeasuresByIds.put(uom.Id, uom);
            }

            unitOfMeasure = unitOfMeasuresByIds.get(salesLine.Unit_of_Measure__c);
            //all UOMs except HR should have Regular Rate
            if (unitOfMeasure.Hours_UOM__c != true) {
                salesLine.Unit_Price__c = salesLine.Regular_Rate__c;
                //let the code run to the last line to set xUnit Price
                isDayUOM = true;
            }
        }

        if (!isDayUOM) {
            //Calculate Unit Price
            Decimal totalHours = 0;
            Decimal totalPrice = 0;
            Decimal unitPrice = 0;
            Decimal lineRegHr = CompanyMgmt.zeroIfNull(salesLine.Regular_Hours__c);
            Decimal lineOTHr = CompanyMgmt.zeroIfNull(salesLine.Overtime_Hours__c);
            Decimal lineDTHr = CompanyMgmt.zeroIfNull(salesLine.Premium_Hours__c);
            Decimal lineRegRate = CompanyMgmt.zeroIfNull(salesLine.Regular_Rate__c);
            Decimal lineOTRate = CompanyMgmt.zeroIfNull(salesLine.Overtime_Rate__c);
            Decimal lineDTRate = CompanyMgmt.zeroIfNull(salesLine.Premium_Rate__c);
            Decimal lineRegRateDay = CompanyMgmt.zeroIfNull(salesLine.Regular_Day__c);
            Decimal lineOTRateDay = CompanyMgmt.zeroIfNull(salesLine.Overtime_Day__c);
            Decimal lineDTRateDay = CompanyMgmt.zeroIfNull(salesLine.Premium_Day__c);
            Decimal totalRegRate = 0;
            Decimal totalOTRate = 0;
            Decimal totalDTRate = 0;
            //Decimal uomQty = CompanyMgmt.zeroIfNull(salesLine.UOM_Qty__c); not used
            //TA476021 Fixed for this.
            if (salesLine.Tax_Group__c != null && salesLine.Tax_Group__c == 'TX') {
            //if (salesOrder.Tax_Liable__c && salesLine.Tax_Group__c != null) {
                //Ticket#23857 >>
                //salesLine.Tax_Pct__c = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, salesLine.Tax_Group__c);
                salesLine.Tax_Pct__c = TaxService.getTaxPct(salesOrder.Tax_Area__c, salesLine.Tax_Group__c);
                //Ticket#23857 <<
            }
            else {
                salesLine.Tax_Pct__c = 0;
            }

            if (unitOfMeasure.Hours_UOM__c == true) {
                totalPrice = CompanyMgmt.halfUpTo2D((lineRegHr * lineRegRate) +
                        (lineOTHr * lineOTRate) +
                        (lineDTHr * lineDTRate));

                totalHours = lineRegHr + lineOTHr + lineDTHr;
            } else {
                if (salesLine.Number_of_Day__c != null) {
                    if (lineRegRateDay > 0) totalRegRate = lineRegRateDay * lineRegRate;
                    if (lineOTRateDay > 0) totalOTRate = lineOTRateDay * lineOTRate;
                    if (lineDTRateDay > 0) totalDTRate = lineDTRateDay * lineDTRate;
                    totalPrice = totalRegRate + totalOTRate + totalDTRate;
                    totalHours = lineRegRateDay + lineOTRateDay + lineDTRateDay;
                }
            }

            if (totalHours != 0) {
                //unitPrice = totalPrice / totalHours;
                unitPrice = CompanyMgmt.halfUpTo5D(totalPrice / totalHours);
            } else {
                unitPrice = CompanyMgmt.zeroIfNull(salesLine.Regular_Rate__c);
            }

            //System.debug('Info: unitPrice ' + unitPrice);
            salesLine.Unit_Price__c = unitPrice;
            //System.debug('Info: salesLine.Unit_Price__c  ' + salesLine.Unit_Price__c);
        }

        salesLine.xUnit_Price__c = salesLine.Unit_Price__c;
        if (salesLine.Bill_as_Lump_Sum__c == true) {
            salesLine.Unit_Price__c = 0;
        }
    }

    //Ticket#22710 - Unit Cost calc
    public void calcLaborUnitCost(Sales_Line__c salesLine){
        if(salesLine.Category__c != 'Labor' || CompanyMgmt.zeroIfNull(salesLine.Regular_Unit_Cost__c) == 0) {
            return;
        }

        Boolean isDayUOM = false;

        Unit_of_Measure__c unitOfMeasure = new Unit_of_Measure__c();
        if (!String.isBlank(salesLine.Unit_of_Measure__c)) {
            if(!unitOfMeasuresByIds.containsKey(salesLine.Unit_of_Measure__c)){
                Unit_of_Measure__c uom = UnitOfMeasuresSelector.newInstance().selectById(new Set<Id>{salesLine.Unit_of_Measure__c})[0];
                unitOfMeasuresByIds.put(uom.Id, uom);
            }
            unitOfMeasure = unitOfMeasuresByIds.get(salesLine.Unit_of_Measure__c);
            //all UOMs except HR should have Regular Cost
            if (unitOfMeasure.Hours_UOM__c != true) {
                salesLine.Unit_Cost__c = salesLine.Regular_Unit_Cost__c;
                //let the code run to the last line to set xUnit Price
                isDayUOM = true;
            }
        }

        if (!isDayUOM) {
            //Calculate Unit Price
            Decimal totalHours = 0;
            Decimal totalCost = 0;
            Decimal unitCost = 0;
            Decimal lineRegHr = CompanyMgmt.zeroIfNull(salesLine.Regular_Hours__c);
            Decimal lineOTHr = CompanyMgmt.zeroIfNull(salesLine.Overtime_Hours__c);
            Decimal lineDTHr = CompanyMgmt.zeroIfNull(salesLine.Premium_Hours__c);
            Decimal lineRegCost = CompanyMgmt.zeroIfNull(salesLine.Regular_Unit_Cost__c);
            Decimal lineOTCost = CompanyMgmt.zeroIfNull(salesLine.Overtime_Unit_Cost__c);
            Decimal lineDTCost = CompanyMgmt.zeroIfNull(salesLine.Double_Time_Unit_Cost__c);
            /*
            Decimal lineRegCostDay = CompanyMgmt.zeroIfNull(salesLine.Regular_Day__c);
            Decimal lineOTCostDay = CompanyMgmt.zeroIfNull(salesLine.Overtime_Day__c);
            Decimal lineDTCostDay = CompanyMgmt.zeroIfNull(salesLine.Premium_Day__c);
            Decimal totalRegCost = 0;
            Decimal totalOTCost = 0;
            Decimal totalDTCost = 0;
             */

            if (unitOfMeasure.Hours_UOM__c == true) {
                totalCost = CompanyMgmt.halfUpTo2D((lineRegHr * lineRegCost) +
                        (lineOTHr * lineOTCost) +
                        (lineDTHr * lineDTCost));

                totalHours = lineRegHr + lineOTHr + lineDTHr;
            }

            if (totalHours != 0) {
                //unitPrice = totalPrice / totalHours;
                unitCost = CompanyMgmt.halfUpTo5D(totalCost / totalHours);
            } else {
                unitCost = CompanyMgmt.zeroIfNull(salesLine.Regular_Rate__c);
            }
            salesLine.Unit_Cost__c = unitCost;
        }
        salesLine.xUnit_Cost__c = salesLine.Unit_Cost__c;
    }

    public Decimal getUnitPrice(String category, Id resOrTypeId, Id uomId, Boolean isEmergency){
        Decimal unitPrice = 0;
        if(isCalcBaseOnResType(category) == true){
            unitPrice = ResourceTypeUtil.getUnitPrice(resOrTypeId, uomId, isEmergency);
        } else {
            unitPrice = ResourceService.getUnitPrice(resOrTypeId, uomId, isEmergency);
        }

        return unitPrice;
    }

    public void calcUnitCost(Sales_Order__c salesOrder, Sales_Line__c salesLine){
        String lineCategory = salesLine.Category__c;
        Boolean unitCostFound = false;
        Id resOrResTypeId = null;
        Decimal unitCost = 0;

        Service_Center__c serviceCenter = new Service_Center__c();
        if (serviceCentersByIds.containsKey(salesOrder.Service_Center__c)) {
            serviceCenter = serviceCentersByIds.get(salesOrder.Service_Center__c);
        }

        Decimal originalUnitCost = 0;
        if (lineCategory == ResourceService.SUBCONTRACTORS_CATEGORY || lineCategory == ResourceService.WASTE_DISPOSAL_CATEGORY) {
            if (salesLine.Bill_as_Lump_Sum__c == true) {
                originalUnitCost = salesLine.xUnit_Cost__c;
            }
            else {
                originalUnitCost = salesLine.Unit_Cost__c;
            }
        }

        //Ticket#21883 >>
        if (salesLine.Resource__c == defaultCompanySetup.Default_Energy_Insurance_Resource__c ||
                salesLine.Resource__c == defaultCompanySetup.Default_Fuel_Surcharge_Resource__c||
           			salesLine.Resource__c == defaultCompanySetup.Default_ESIC_Surcharge_Resource__c) {
            Decimal surchargeCostPct = 0;
            if(salesLine.Resource__c == defaultCompanySetup.Default_Energy_Insurance_Resource__c){
                if(subsidiaryCompanySetup != null && CompanyMgmt.zeroIfNull(subsidiaryCompanySetup.EEC_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = subsidiaryCompanySetup.EEC_Surcharge_Cost_Pct__c / 100;
                }
                if(serviceCenter != null && CompanyMgmt.zeroIfNull(serviceCenter.EEC_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = serviceCenter.EEC_Surcharge_Cost_Pct__c / 100;
                }
            } 
            else if(salesLine.Resource__c == defaultCompanySetup.Default_ESIC_Surcharge_Resource__c){
                if(subsidiaryCompanySetup != null && CompanyMgmt.zeroIfNull(subsidiaryCompanySetup.ESIC_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = subsidiaryCompanySetup.ESIC_Surcharge_Cost_Pct__c / 100;
                }
                if(serviceCenter != null && CompanyMgmt.zeroIfNull(serviceCenter.ESIC_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = serviceCenter.ESIC_Surcharge_Cost_Pct__c / 100;
                }
            }             
            else {
                if(subsidiaryCompanySetup != null && CompanyMgmt.zeroIfNull(subsidiaryCompanySetup.Fuel_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = subsidiaryCompanySetup.Fuel_Surcharge_Cost_Pct__c / 100;
                }
                if(serviceCenter != null && CompanyMgmt.zeroIfNull(serviceCenter.Fuel_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = serviceCenter.Fuel_Surcharge_Cost_Pct__c / 100;
                }
            }
            unitCost = CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c) * surchargeCostPct;
            unitCostFound = true;
        }
        //Ticket#21883 <<

        if (!unitCostFound) {
            if (isCalcBaseOnResType(lineCategory) == true && salesLine.Resource_Type__c != null) {
                resOrResTypeId = salesLine.Resource_Type__c;
            } else if (isCalcBaseOnResType(lineCategory) == false && salesLine.Resource__c != null) {
                resOrResTypeId = salesLine.Resource__c;
            }

            if (resOrResTypeId != null) {
                if (isCalcBaseOnResType(lineCategory) == true) {
                    //labor line with pay rule assign
                    if (lineCategory == 'Labor' && salesOrder.Pay_Rule__c != null) {
                        unitCost = getLaborCostWithFringeBenefitByResType(resOrResTypeId, salesOrder.Pay_Rule__c, salesOrder.Service_Center__c);
                        //usePayRuleCost = true;
                        if (unitCost > 0) {
                            unitCostFound = true;
                        }
                    }
                } else {
                    if(lineCategory == ResourceService.MISC_CHARGES_AND_TAX_CATEGORY == true &&
                            String.isNotBlank(salesOrder.From_Sales_Quote__c) &&
                            String.isNotBlank(salesLine.Unit_of_Measure__c)){
                        Sales_Line__c quoteLine = getQuotedLine(salesOrder.From_Sales_Quote__c, resOrResTypeId, salesLine.Unit_of_Measure__c);
                        if(quoteLine.Id != null && CompanyMgmt.zeroIfNull(quoteLine.Unit_Cost__c) > 0){
                            unitCost = quoteLine.Unit_Cost__c;
                            unitCostFound = true;
                        }
                    }
                }

                if (unitCostFound == false && String.isNotBlank(salesOrder.Rate_Sheet__c)) {
                    Rate_Sheet_Line__c rateSheetLine = getRateSheetLine(salesOrder, salesLine, salesOrder.Rate_Sheet__c);
                    unitCost = RateSheetService.getUnitCost(rateSheetLine);
                    if (unitCost > 0) {
                        unitCostFound = true;
                    }
                }

                //SC Rate Sheet Line
                if (unitCostFound == false && String.isNotBlank(serviceCenter.Price_List__c)) {
                    Id rateSheetId = null;
                    if (rateSheetIdsByPriceListIds.containsKey(serviceCenter.Price_List__c)) {
                        rateSheetId = rateSheetIdsByPriceListIds.get(serviceCenter.Price_List__c);
                    }
                    Rate_Sheet_Line__c rateSheetLine = getRateSheetLine(salesOrder, salesLine, rateSheetId);
                    unitCost = RateSheetService.getUnitCost(rateSheetLine);
                    if (unitCost > 0) {
                        unitCostFound = true;
                    }
                    //System.debug('Info: SC RateSheet Cost unitCostFound ' + unitCostFound);
                }

                //Company Default Rate Sheet Line
                if (unitCostFound == false && String.isNotBlank(defaultCompanySetup.Price_List__c)) {
                    Id rateSheetId = null;
                    if (rateSheetIdsByPriceListIds.containsKey(defaultCompanySetup.Price_List__c)) {
                        rateSheetId = rateSheetIdsByPriceListIds.get(defaultCompanySetup.Price_List__c);
                    }
                    Rate_Sheet_Line__c rateSheetLine = getRateSheetLine(salesOrder, salesLine, rateSheetId);
                    unitCost = RateSheetService.getUnitCost(rateSheetLine);
                    if (unitCost > 0) {
                        unitCostFound = true;
                    }
                    //System.debug('Info: Company RateSheet Cost unitCostFound ' + unitCostFound);
                }

                if (unitCostFound == false) {
                    if (salesLine.Category__c == 'Waste Disposal') {
                        ResourceUOMAssociation__c wasteResourceUOMAssociation = getWasteResUOMSetup(salesLine);
                        if (wasteResourceUOMAssociation.Id != null) unitCost = wasteResourceUOMAssociation.Unit_Cost__c;
                    } else if (salesLine.Unit_of_Measure__c != null) {
                        unitCost = getUnitCost(salesLine.Category__c, resOrResTypeId, salesLine.Unit_of_Measure__c);
                    }

                    if (unitCost > 0) {
                        unitCostFound = true;
                    }
                }
            }
        }

        if (lineCategory == ResourceService.SUBCONTRACTORS_CATEGORY || lineCategory == ResourceService.WASTE_DISPOSAL_CATEGORY) {
            if (!unitCostFound) {
                unitCost = originalUnitCost;
            }
        }

        salesLine.Unit_Cost__c = unitCost;

        salesLine.xUnit_Cost__c = salesLine.Unit_Cost__c;
        //Ticket#22710 >>
        salesLine.Regular_Unit_Cost__c = salesLine.Unit_Cost__c;
        salesLine.Overtime_Unit_Cost__c = CompanyMgmt.halfUpTo2D(salesLine.Unit_Cost__c * CompanyMgmt.zeroIfNull(defaultCompanySetup.Overtime_Unit_Cost_Multiplier__c));
        salesLine.Double_Time_Unit_Cost__c = CompanyMgmt.halfUpTo2D(salesLine.Unit_Cost__c * CompanyMgmt.zeroIfNull(defaultCompanySetup.Double_Time_Unit_Cost_Multiplier__c));
        calcLaborUnitCost(salesLine);
        //Ticket#22710 <<
        if (salesLine.Bill_as_Lump_Sum__c == true) {
            salesLine.Unit_Cost__c = 0;
        }
        //aura >>
    }

    public Decimal getLaborCostWithFringeBenefitByResType(Id resTypeId, Id payRuleId, Id serviceCenterId){
        Decimal unitCost = 0;
        if(resTypeId != null && payRuleId != null){
            if(payRuleLineByResTypeIdsByPayRuleIds.containsKey(payRuleId)){
                Pay_Rule_Line__c payRuleLine = new Pay_Rule_Line__c();
                if(payRuleLineByResTypeIdsByPayRuleIds.get(payRuleId).containsKey(resTypeId)) {
                    payRuleLine = payRuleLineByResTypeIdsByPayRuleIds.get(payRuleId).get(resTypeId);
                }
                Decimal payRateWithFringe = CompanyMgmt.zeroIfNull(payRuleLine.Rate__c) + CompanyMgmt.zeroIfNull(payRuleLine.Fringe__c);
                if(payRateWithFringe > 0) {
                    Service_Center__c serviceCenter = serviceCentersByIds.get(serviceCenterId);
                    Decimal companyCompPct = CompanyMgmt.zeroIfNull(defaultCompanySetup.Workers_Comp_Pct__c) / 100;
                    Decimal corpOverHead = CompanyMgmt.zeroIfNull(defaultCompanySetup.Corporate_Overhead__c);
                    Decimal serviceCenterTaxRate = CompanyMgmt.zeroIfNull(serviceCenter.Payroll_Tax_Pct__c) / 100;
                    Decimal payrollTaxAmt = payRateWithFringe * serviceCenterTaxRate;
                    Decimal workerCompAmt = payRateWithFringe * companyCompPct;
                    unitCost = payRateWithFringe + corpOverHead + payrollTaxAmt + workerCompAmt;
                }
            }
        }
        return unitCost;
    }

    public ResourceUOMAssociation__c getWasteResUOMSetup(Sales_Line__c salesLine) {
        if (salesLine.Category__c != 'Waste Disposal') {
            return null;
        } else {
            return ResourceService.getWasteResUOMSetup(
                    salesLine.Resource__c,
                    salesLine.Unit_of_Measure__c,
                    salesLine.Facility__c
            );
        }
    }

    public Rate_Sheet_Line__c getRateSheetLine(Sales_Order__c salesOrder, Sales_Line__c salesLine, Id rateSheetId){
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();

        if(rateSheetId != null){
            if(salesLine.Category__c == 'Waste Disposal'){
                /*Waste001
                Id lookupUOMId = null;
                if(salesLine.Category__c != 'Waste Disposal') return null;
                if(salesLine.Resource__c == null || salesLine.Cost_Method__c == null) return null;
                if(salesLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) lookupUOMId = salesLine.Unit_Weight_Vol__c;
                if(salesLine.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name()) lookupUOMId = salesLine.Container_Size__c;
                rateSheetLine = RateSheetService.getWasteRateSheetLine(
                        rateSheetId,
                        salesLine.Resource__c, salesLine.Cost_Method__c,
                        lookupUOMId, salesLine.Facility__c, salesLine.Container_Size__c);
                 */
                rateSheetLine = RateSheetService.getWasteRateSheetLine(rateSheetId, salesLine.Resource__c, salesLine.Unit_of_Measure__c, salesLine.Facility__c);
            } else {
                Id resOrTypeId = null;
                if(isCalcBaseOnResType(salesLine.Category__c) == true && salesLine.Resource_Type__c != null){
                    resOrTypeId = salesLine.Resource_Type__c;
                } else if(isCalcBaseOnResType(salesLine.Category__c) == false && salesLine.Resource__c != null) {
                    resOrTypeId = salesLine.Resource__c;
                }

                //System.debug('Info: resOrTypeId ' + resOrTypeId);
                //System.debug('Info: salesLine ' + salesLine.Unit_of_Measure__c);
                rateSheetLine = RateSheetService.getRateSheetLine(rateSheetId, resOrTypeId, salesLine.Unit_of_Measure__c);
            }
        }
        return rateSheetLine;
    }

    public Decimal getUnitCost(String category, Id resOrTypeId, Id uomId){
        Decimal unitCost = 0;
        if(isCalcBaseOnResType(category) == true){
            unitCost = ResourceTypeUtil.getUnitCost(resOrTypeId, uomId);
        } else {
            unitCost = ResourceService.getUnitCost(resOrTypeId, uomId);
        }
        return  unitCost;
    }

    public Sales_Line__c getQuotedLine(Id quoteId, Id resOrTypeId, Id uomId){
        Sales_Line__c quotedLine = new Sales_Line__c();
        if(fromQuoteLinesByUOMIdsByResOrTypeIdsByQuoteIds.containsKey(quoteId)) {
            Map<Id, Map<Id, Sales_Line__c>> quoteLinesByUOMIdsByResOrTypeId = fromQuoteLinesByUOMIdsByResOrTypeIdsByQuoteIds.get(quoteId);
            if(quoteLinesByUOMIdsByResOrTypeId.containsKey(resOrTypeId)){
                Map<Id, Sales_Line__c> quoteLinesByUOMId = quoteLinesByUOMIdsByResOrTypeId.get(resOrTypeId);
                if(quoteLinesByUOMId.containsKey(uomId)) quotedLine = quoteLinesByUOMId.get(uomId);
            }
        }
        return quotedLine;
    }

    public void calculateLineTotals(Sales_Order__c salesOrder, Sales_Line__c salesLine) {
        Decimal qty = CompanyMgmt.zeroIfNull(salesLine.Quantity__c);
        Decimal minSellQty = CompanyMgmt.zeroIfNull(salesLine.Min_Sell_Qty__c);
        Decimal unitPrice;
        Decimal unitCost;
        if (salesLine.Bill_as_Lump_Sum__c == true || salesLine.Non_Billable__c == true) {
            if (salesLine.Bill_as_Lump_Sum__c == true) {
                unitCost = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(salesLine.xUnit_Cost__c));
            }
            else {
                unitCost = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c));
            }
            unitPrice = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(salesLine.xUnit_Price__c));
        }
        else {
            unitPrice = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(salesLine.Unit_Price__c));
            unitCost = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c));
        }

        Decimal markup = CompanyMgmt.zeroIfNull(salesLine.Markup__c);
        Decimal markupAmount = 0;
        Decimal uomQty = CompanyMgmt.zeroIfNull(salesLine.UOM_Qty__c);
        Decimal numberOfDays = CompanyMgmt.zeroIfNull(salesLine.Number_of_Day__c);
		if (salesLine.Tax_Group__c != null && salesLine.Tax_Group__c == 'TX') {
         //if (salesOrder.Tax_Liable__c && salesLine.Tax_Group__c != null) {
            //Ticket#23857 >>
            //salesLine.Tax_Pct__c = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, salesLine.Tax_Group__c);
            salesLine.Tax_Pct__c = TaxService.getTaxPct(salesOrder.Tax_Area__c, salesLine.Tax_Group__c);
            //salesLine.Tax_Group__c = 'TX';
            system.debug('salesOrder.Tax_Area__c'+salesOrder.Tax_Area__c);
            system.debug('salesLine.Tax_Group__c'+salesLine.Tax_Group__c);
                        system.debug('inside taxliable'+salesLine.Tax_Pct__c);

            //Ticket#23857 <<
        }
        else {
            system.debug('inside else taxliable');
            salesLine.Tax_Pct__c = 0;
            //salesLine.Tax_Group__c = 'NT';
        }

        Decimal lineAmount = 0;
        Decimal lineCost = 0;
        if (salesLine.Category__c == 'Labor') {
            if (salesLine.Sales_Line_Details__r != null) {
                lineAmount = 0;
                lineCost = 0;
                salesLine.Regular_Hours__c = 0;
                salesLine.Overtime_Hours__c = 0;
                salesLine.Premium_Hours__c = 0;

                //update sales line qty uom if there is only one schedule line <<
                if (salesLine.Sales_Line_Details__r.size() == 1) {
                    if (salesLine.Unit_of_Measure__c == salesLine.Sales_Line_Details__r[0].Unit_of_Measure__c) {
                        salesLine.UOM_Qty__c = salesLine.Sales_Line_Details__r[0].UOM_Qty__c;
                    }
                }
                //update sales line qty uom if there is only one schedule line >>

                for (Sales_Line_Detail__c salesLineDetail : salesLine.Sales_Line_Details__r) {
                    lineAmount += salesLineDetail.Line_Amount__c;
                    lineCost += salesLineDetail.Line_Cost__c;

                    salesLine.Regular_Hours__c += CompanyMgmt.halfUpTo2D(salesLineDetail.Regular_Hours__c);
                    salesLine.Overtime_Hours__c += CompanyMgmt.halfUpTo2D(salesLineDetail.Overtime_Hours__c);
                    salesLine.Premium_Hours__c += CompanyMgmt.halfUpTo2D(salesLineDetail.Premium_Hours__c);
                }
            }
            calcLaborUnitPrice(salesOrder, salesLine);
            calcLaborUnitCost(salesLine); //Ticket#22710
        }
        else if (salesLine.Category__c == 'Equipment') {
            //equipment schedule lines <<
            /*
            if (salesLine.Number_of_Day__c != null) { // W-000391
                lineAmount = unitPrice * qty * uomQty * numberOfDays;
                lineCost = unitCost * qty * uomQty * numberOfDays;
            }
            else {
                lineAmount = unitPrice * qty * uomQty;
                lineCost = unitCost * qty * uomQty;
            }
            */
            if (salesLine.Sales_Line_Details__r != null) {
                lineAmount = 0;
                lineCost = 0;

                //update sales line qty uom if there is only one schedule line <<
                if (salesLine.Sales_Line_Details__r.size() == 1) {
                    if (salesLine.Unit_of_Measure__c == salesLine.Sales_Line_Details__r[0].Unit_of_Measure__c) {
                        salesLine.UOM_Qty__c = salesLine.Sales_Line_Details__r[0].UOM_Qty__c;
                    }
                }
                //update sales line qty uom if there is only one schedule line >>

                for (Sales_Line_Detail__c salesLineDetail : salesLine.Sales_Line_Details__r) {
                    lineAmount += salesLineDetail.Line_Amount__c;
                    lineCost += salesLineDetail.Line_Cost__c;
                }
            }
            //equipment schedule lines >>
        }
        //job task <<
        else if (salesLine.Category__c == 'Materials') {
            lineAmount = unitPrice * numberOfDays * qty;
            lineCost = unitCost * numberOfDays * qty;
        }
        //job task >>
        else if (salesLine.Category__c == 'Bundled') {
            lineAmount = unitPrice * qty;
            lineCost = unitCost * qty;
        }
        else {
            if(salesLine.Category__c == 'Waste Disposal' && minSellQty > qty){
                lineAmount = unitPrice * minSellQty;
                lineCost = unitCost * minSellQty;
            } else {
                lineAmount = unitPrice * qty;
                lineCost = unitCost * qty;
            }

        }

        lineAmount = CompanyMgmt.halfUpTo2D(lineAmount);
        lineCost = CompanyMgmt.halfUpTo2D(lineCost);

        if(salesLine.Category__c != ResourceService.SUBCONTRACTORS_CATEGORY) {
            if (salesLine.Markup_Option__c == '%') {
                markupAmount = CompanyMgmt.halfUpTo2D(lineAmount * markup / 100);
            } else if (salesLine.Markup_Option__c == 'Amount') {
                markupAmount = markup;
            }
            lineAmount += markupAmount;
        }

        //non-billable <<
        /*
        if (salesLine.Bill_as_Lump_Sum__c == true) {
            salesLine.Unit_Price__c = 0;
            salesLine.Unit_Cost__c = 0;
            salesLine.Line_Amount__c = 0;
            salesLine.Line_Cost__c = 0;
            salesLine.xLine_Amount__c = lineAmount;
            salesLine.xLine_Cost__c = lineCost;
        */
        if (salesLine.Bill_as_Lump_Sum__c == true || salesLine.Non_Billable__c == true) {
            if (salesLine.Bill_as_Lump_Sum__c == true) {
                salesLine.Unit_Cost__c = 0;
                salesLine.Line_Cost__c = 0;
                salesLine.xLine_Cost__c = lineCost;
            }
            else {
                salesLine.Line_Cost__c = lineCost;
                salesLine.xLine_Cost__c = lineCost;
            }
            salesLine.Unit_Price__c = 0;
            salesLine.Line_Amount__c = 0;
            salesLine.xLine_Amount__c = lineAmount;
            //non-billable >>
        }
        else {
            salesLine.Line_Amount__c = lineAmount;
            salesLine.xLine_Amount__c = lineAmount;
            salesLine.Line_Cost__c = lineCost;
            salesLine.xLine_Cost__c = lineCost;
        }

        //aura >>

        //fix subcontractors cost << move the code above the bill as lump sum and non-billable
        /*
        if (salesLine.Markup_Option__c == '%') totalMarkupAmt = salesLine.Line_Amount__c * markup / 100;
        if (salesLine.Markup_Option__c == 'Amount') totalMarkupAmt = markup;

        salesLine.Line_Amount__c += totalMarkupAmt;
         */
        //fix subcontractors cost >>
        System.debug('saleslinecategory'+salesLine.Category__c);
        system.debug('salesLine.Line_Amount__c'+salesLine.Line_Amount__c);
        system.debug('CompanyMgmt.zeroIfNull(salesLine.Tax_Pct__c)'+CompanyMgmt.zeroIfNull(salesLine.Tax_Pct__c));
        salesLine.Tax__c = CompanyMgmt.halfUpTo2D(salesLine.Line_Amount__c * CompanyMgmt.zeroIfNull(salesLine.Tax_Pct__c) / 100);
                system.debug('salesLine.Tax__c'+salesLine.Tax__c);
        salesLine.Line_Amt_Incl_Tax__c = salesLine.Line_Amount__c + salesLine.Tax__c;
        salesLine.Profit_Margin__c = salesLine.Line_Amount__c - salesLine.Line_Cost__c;
    }

    public void updateTotals(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers){
        for(ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers){
            for(Sales_Line__c salesLine: jobTaskWrapper.SalesLines){
                Decimal unitCost = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c));
                Decimal qty = CompanyMgmt.zeroIfNull(salesLine.Quantity__c);
                Decimal minSellQty = CompanyMgmt.zeroIfNull(salesLine.Min_Sell_Qty__c);
                Decimal unitPrice = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(salesLine.Unit_Price__c));
                Decimal markup = CompanyMgmt.zeroIfNull(salesLine.Markup__c);
                Decimal totalMarkupAmt = 0;
                Decimal uomQty = CompanyMgmt.zeroIfNull(salesLine.UOM_Qty__c);
                Decimal numberOfDays = CompanyMgmt.zeroIfNull(salesLine.Number_of_Day__c);
				if (salesLine.Tax_Group__c != null && salesLine.Tax_Group__c == 'TX') {
                //if (salesOrder.Tax_Liable__c && salesLine.Tax_Group__c != null) {
                    //Ticket#23857 >>
                    //salesLine.Tax_Pct__c = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, salesLine.Tax_Group__c);
                    salesLine.Tax_Pct__c = TaxService.getTaxPct(salesOrder.Tax_Area__c, salesLine.Tax_Group__c);
                    //Ticket#23857 <<
                }
                else {
                    salesLine.Tax_Pct__c = 0;
                }

                if (salesLine.Category__c != 'Labor' && salesLine.Category__c != 'Equipment') {
                    salesLine.Line_Cost__c = unitCost * qty;
                    if(salesLine.Category__c == 'Waste Disposal' && minSellQty > qty){
                        salesLine.Line_Amount__c = unitPrice * minSellQty;
                        salesLine.Line_Cost__c = unitCost * minSellQty;
                    } else {
                        salesLine.Line_Amount__c = unitPrice * qty;
                        salesLine.Line_Cost__c = unitCost * qty;
                    }
                } else {
                    if (salesLine.Number_of_Day__c != null) { // W-000391
                        salesLine.Line_Cost__c = unitCost * qty * uomQty * numberOfDays;
                        salesLine.Line_Amount__c = unitPrice * qty * uomQty * numberOfDays;
                    } else {
                        salesLine.Line_Cost__c = unitCost * qty * uomQty;
                        salesLine.Line_Amount__c = unitPrice * qty * uomQty;
                    }
                }

                //Ticket#19964
                if(salesLine.Category__c != ResourceService.SUBCONTRACTORS_CATEGORY) {
                    if (salesLine.Markup_Option__c == '%') totalMarkupAmt = salesLine.Line_Amount__c * markup / 100;
                    if (salesLine.Markup_Option__c == 'Amount') totalMarkupAmt = markup;
                }

                salesLine.Line_Amount__c += totalMarkupAmt;
                salesLine.Tax__c = CompanyMgmt.halfUpTo2D(salesLine.Line_Amount__c * CompanyMgmt.zeroIfNull(salesLine.Tax_Pct__c) / 100);
                salesLine.Line_Amt_Incl_Tax__c = salesLine.Line_Amount__c + salesLine.Tax__c;
                salesLine.Profit_Margin__c = salesLine.Line_Amount__c - salesLine.Line_Cost__c;
            }
        }
    }

    public void setFromQuoteLinesByResOrTypeIdsByQuoteIdsMap(Set<Id> quoteIds){
        List<Sales_Line__c> quoteLines = SalesLinesSelector.newInstance().selectLinesBySalesOrderId(quoteIds);
        for(Sales_Line__c quoteLine:quoteLines){
            if(quoteLine.Category__c == 'Waste Disposal'){
                if(quoteLine.Resource__c != null){
                    /*Waste001
                    wasteQuoteLinesByQuoteResFacilityCostTypeVolContainer.put(
                            quoteLine.Sales_Order__c + ':' + quoteLine.Resource__c + ':' + quoteLine.Facility__c
                                    + ':' + quoteLine.Cost_Method__c + ':' + quoteLine.Unit_Weight_Vol__c + ':' + quoteLine.Container_Size__c,
                            quoteLine
                    );
                     */
                    wasteQuoteLinesByQuoteResFacilityCostTypeVolContainer.put(
                            quoteLine.Sales_Order__c + ':' + quoteLine.Resource__c + ':' + quoteLine.Facility__c
                                    + ':' + quoteLine.Unit_of_Measure__c,
                            quoteLine
                    );
                }
            } else {
                Map<Id, Map<Id, Sales_Line__c>> quoteLinesByUOMIdsByResOrTypeIds = new Map<Id, Map<Id, Sales_Line__c>>();
                Map<Id, Sales_Line__c> quoteLinesByUOMIds = new Map<Id, Sales_Line__c>();
                if(fromQuoteLinesByUOMIdsByResOrTypeIdsByQuoteIds.containsKey(quoteLine.Sales_Order__c)){
                    quoteLinesByUOMIdsByResOrTypeIds = fromQuoteLinesByUOMIdsByResOrTypeIdsByQuoteIds.get(quoteLine.Sales_Order__c);
                }

                if(isCalcBaseOnResType(quoteLine.Category__c) == true && quoteLine.Resource_Type__c != null && quoteLinesByUOMIdsByResOrTypeIds.containsKey(quoteLine.Resource_Type__c))
                    quoteLinesByUOMIds = quoteLinesByUOMIdsByResOrTypeIds.get(quoteLine.Resource_Type__c);
                else if(isCalcBaseOnResType(quoteLine.Category__c) == false && quoteLine.Resource__c != null && quoteLinesByUOMIdsByResOrTypeIds.containsKey(quoteLine.Resource__c))
                    quoteLinesByUOMIds = quoteLinesByUOMIdsByResOrTypeIds.get(quoteLine.Resource__c);

                quoteLinesByUOMIds.put(quoteLine.Unit_of_Measure__c, quoteLine);

                if(isCalcBaseOnResType(quoteLine.Category__c) == true && quoteLine.Resource_Type__c != null) quoteLinesByUOMIdsByResOrTypeIds.put(quoteLine.Resource_Type__c, quoteLinesByUOMIds);
                else if(isCalcBaseOnResType(quoteLine.Category__c) == false && quoteLine.Resource__c != null) quoteLinesByUOMIdsByResOrTypeIds.put(quoteLine.Resource__c, quoteLinesByUOMIds);

                fromQuoteLinesByUOMIdsByResOrTypeIdsByQuoteIds.put(quoteLine.Sales_Order__c, quoteLinesByUOMIdsByResOrTypeIds);
            }
        }
    }

    public void setServiceCenterByIdsMap(){
        serviceCentersByIds.putAll(ServiceCentersSelector.newInstance().selectAll());
    }

    public void setUnitOfMeasureByIdsMap(Set<Id> uomIds){
        unitOfMeasuresByIds.putAll(UnitOfMeasuresSelector.newInstance().selectById(uomIds));
    }

    public void setBillingRulesByIdsMap(Set<Id> billingRuleIds) {
        billingRulesByIds.putAll(BillingRulesSelector.newInstance().selectById(billingRuleIds));
    }

    //billing rule mapping <<
    public void setBillingRulesByAssumptions() {
        for (Billing_Rule__c billingRule : BillingRulesSelector.newInstance().selectByAssumptions()) {
            if (billingRule.Quote_Order_Assumption__c != null) {
                for (String assumption : billingRule.Quote_Order_Assumption__c.split(';')) { //Quote_Order_Assumption__c is a multi picklist
                    mapBillingRulesByAssumption.put(assumption, billingRule);
                }
            }
        }
    }
    //billing rule mapping >>

    public void setPayRuleLinesByResTypeIdsByPayRuleIdsMap(Set<Id> payRuleIds){
        List<Pay_Rule__c> payRules = PayRulesSelector.newInstance().selectPayRulesByIdWithLines(payRuleIds);
        for(Pay_Rule__c payRule:payRules){
            Map<Id, Pay_Rule_Line__c> payRuleLineByResTypeIds = new Map<Id, Pay_Rule_Line__c>();
            for(Pay_Rule_Line__c payRuleLine:payRule.Pay_Rule_Lines__r){
                payRuleLineByResTypeIds.put(payRuleLine.Resource_Type__c, payRuleLine);
            }
            payRuleLineByResTypeIdsByPayRuleIds.put(payRule.Id, payRuleLineByResTypeIds);
        }
    }

    public Boolean isCalcBaseOnResType(String lineCategory){
        if(lineCategory == 'Labor' || lineCategory == 'Equipment' || lineCategory == 'Bundled') {
            return true;
        } else {
            return  false;
        }
    }

    //recalculate lines on contract change 10.16.2020 <<
    public void recalculateSalesLines(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                calcUnitPrice(salesOrder, salesLine);
                calcUnitCost(salesOrder, salesLine);
                calculateLineTotals(salesOrder, salesLine);
            }
        }
        this.recalculateSalesLineDetails(salesOrder, jobTaskWrappers, false);
    }

    public void explodeSalesLineDetails(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        //ticket 20876 <<
        BillingLine tempBillingLine = new BillingLine();
        tempBillingLine.BillingRuleId = salesOrder.Billing_Rule__c;
        BillingService.initSetupData(new List<BillingLine>{ tempBillingLine });
        //ticket 20876 >>
        //Ticket#20496 >>
        Map<Date, Week_Number__c> weekNumbersByWeekStartDate = new Map<Date, Week_Number__c>();
        if(salesOrder.Estimated_Job_Start_Date__c != null && salesOrder.Estimated_Job_End_Date__c != null) {
            Date tempStartDate = salesOrder.Estimated_Job_Start_Date__c.toStartOfWeek().addDays(1);
            Date tempEndDate = salesOrder.Estimated_Job_End_Date__c.toStartOfWeek().addDays(8);
            List<Week_Number__c> weekNumbers = [
                    SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c
                    FROM Week_Number__c
                    WHERE Week_Start_Date__c >= :tempStartDate AND Week_Start_Date__c <= :tempEndDate
            ];
            for (Week_Number__c weekNumber : weekNumbers) {
                weekNumbersByWeekStartDate.put(weekNumber.Week_Start_Date__c, weekNumber);
            }
        }
        //}
        //Ticket#20496 <<
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            Map<Integer, Map<Date, Sales_Line_Detail__c>> mapSalesLineDetailsByDateBySalesLineNo = new Map<Integer, Map<Date, Sales_Line_Detail__c>>();
            List<BillingLine> billingLines = new List<BillingLine>();

            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                if (salesLine.Category__c == 'Labor') {
                    Map<Date, Sales_Line_Detail__c> mapSalesLineDetailsByDate = new Map<Date, Sales_Line_Detail__c>();

                    //ticket 20876 <<
                    /*
                    BillingLine tempBillingLine = new BillingLine();
                    tempBillingLine.BillingRuleId = salesOrder.Billing_Rule__c;
                    BillingService.initSetupData(new List<BillingLine>{ tempBillingLine });
                    */
                    //ticket 20876 >>

                    //init billing rule map for getScheduleDates
                    List<Date> scheduledDates = BillingService.getScheduledDates(salesOrder.Estimated_Job_Start_Date__c, salesLine.Number_of_Day__c.intValue(), salesOrder.Include_Holiday__c, salesOrder.Include_Weekend__c, salesOrder.Billing_Rule__c);
                    for (Integer i = 0; i < scheduledDates.size(); i++) {
                        Date scheduledDate = scheduledDates[i];
                        Sales_Line_Detail__c salesLineDetail = new Sales_Line_Detail__c();
                        salesLineDetail.Scheduled_Date__c = scheduledDate;
                        //Ticket#20496 >>
                        if(weekNumbersByWeekStartDate.containsKey(scheduledDate.toStartOfWeek().addDays(1))){
                            salesLineDetail.Week_Number__c = weekNumbersByWeekStartDate.get(scheduledDate.toStartOfWeek().addDays(1)).Id;
                        }
                        //Ticket#20496 <<
                        if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            salesLineDetail.Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                            salesLineDetail.End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                        }
                        salesLineDetail.Sales_Line__c = salesLine.Id;
                        salesLineDetail.Sales_Line__r = new Sales_Line__c(Id = salesLine.Id, Category__c = salesLine.Category__c);
                        salesLineDetail.Regular_Rate__c = salesLine.Regular_Rate__c;
                        salesLineDetail.Overtime_Rate__c = salesLine.Overtime_Rate__c;
                        salesLineDetail.Premium_Rate__c = salesLine.Premium_Rate__c;
                        salesLineDetail.Unit_Price__c = salesLine.Unit_Price__c;
                        if (salesLine.Bill_as_Lump_Sum__c != true) {
                            salesLineDetail.Unit_Cost__c = salesLine.Unit_Cost__c;
                        } else {
                            salesLineDetail.Unit_Cost__c = salesLine.xUnit_Cost__c;
                        }
                        //Ticket#22710 >>
                        salesLineDetail.Regular_Unit_Cost__c = salesLine.Regular_Unit_Cost__c;
                        salesLineDetail.Overtime_Unit_Cost__c = salesLine.Overtime_Unit_Cost__c;
                        salesLineDetail.Double_Time_Unit_Cost__c = salesLine.Double_Time_Unit_Cost__c;
                        //Ticket#22710 <<
                        salesLineDetail.Quantity__c = salesLine.Quantity__c;
                        salesLineDetail.UOM_Qty__c = salesLine.UOM_Qty__c;
                        salesLineDetail.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                        salesLineDetail.Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                        mapSalesLineDetailsByDate.put(salesLineDetail.Scheduled_Date__c, salesLineDetail);

                        BillingLine billingLine = this.initBillingLine(i, salesOrder, salesLine, salesLineDetail);
                        billingLines.add(billingLine);
                    }
                    mapSalesLineDetailsByDateBySalesLineNo.put(salesLine.Line_No__c.intValue(), mapSalesLineDetailsByDate);

                    //ticket 20876 << free memory to reduce heap size
                    mapSalesLineDetailsByDate = null;
                    //ticket 20876 >>
                }
                //equipment schedule lines <<
                else if (salesLine.Category__c == 'Equipment') {
                    Map<Date, Sales_Line_Detail__c> mapSalesLineDetailsByDate = new Map<Date, Sales_Line_Detail__c>();
                    //ticket 20876 <<
                    /*
                    BillingLine tempBillingLine = new BillingLine();
                    tempBillingLine.BillingRuleId = salesOrder.Billing_Rule__c;
                    BillingService.initSetupData(new List<BillingLine>{ tempBillingLine });
                    */
                    //ticket 20876 >>
                    List<Date> scheduledDates = BillingService.getScheduledDates(salesOrder.Estimated_Job_Start_Date__c, salesLine.Number_of_Day__c.intValue(), salesOrder.Include_Holiday__c, salesOrder.Include_Weekend__c, salesOrder.Billing_Rule__c);
                    for (Integer i = 0; i < scheduledDates.size(); i++) {
                        Date scheduledDate = scheduledDates[i];
                        Sales_Line_Detail__c salesLineDetail = new Sales_Line_Detail__c();
                        salesLineDetail.Scheduled_Date__c = scheduledDate;

                        if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            salesLineDetail.Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                            salesLineDetail.End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                        }
                        salesLineDetail.Sales_Line__c = salesLine.Id;
                        //equipment schedule lines <<
                        salesLineDetail.Sales_Line__r = new Sales_Line__c(Id = salesLine.Id, Category__c = salesLine.Category__c);
                        //equipment schedule lines >>
                        salesLineDetail.Regular_Rate__c = 0;
                        salesLineDetail.Overtime_Rate__c = 0;
                        salesLineDetail.Premium_Rate__c = 0;
                        salesLineDetail.Unit_Price__c = salesLine.Unit_Price__c;
                        if (salesLine.Bill_as_Lump_Sum__c != true) {
                            salesLineDetail.Unit_Cost__c = salesLine.Unit_Cost__c;
                        } else {
                            salesLineDetail.Unit_Cost__c = salesLine.xUnit_Cost__c;
                        }
                        salesLineDetail.Quantity__c = salesLine.Quantity__c;
                        salesLineDetail.UOM_Qty__c = salesLine.UOM_Qty__c;
                        salesLineDetail.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                        salesLineDetail.Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                        mapSalesLineDetailsByDate.put(salesLineDetail.Scheduled_Date__c, salesLineDetail);
                    }
                    mapSalesLineDetailsByDateBySalesLineNo.put(salesLine.Line_No__c.intValue(), mapSalesLineDetailsByDate);

                    //ticket 20876 << free memory to reduce heap size
                    mapSalesLineDetailsByDate = null;
                    //ticket 20876 >>
                }
                //equipment schedule lines
            }

            if (mapSalesLineDetailsByDateBySalesLineNo.size() > 0) {
                List<Sales_Line_Detail__c> salesLineDetails = new List<Sales_Line_Detail__c>();
                //equipment schedule line <<
                /*
                for (Map<Date, Sales_Line_Detail__c> mapSalesLineDetailsByDates : mapSalesLineDetailsByDateBySalesLineNo.values()) {
                    for (Sales_Line_Detail__c salesLineDetail : mapSalesLineDetailsByDates.values()) {
                        salesLineDetails.add(salesLineDetail);
                    }
                }
                this.calculateBillingLines(salesLineDetails, billingLines);
                */
                for (Integer salesLineNo : mapSalesLineDetailsByDateBySalesLineNo.keySet()) {
                    Map<Date, Sales_Line_Detail__c> mapSalesLineDetailsByDates = mapSalesLineDetailsByDateBySalesLineNo.get(salesLineNo);
                    for (Sales_Line_Detail__c salesLineDetail : mapSalesLineDetailsByDates.values()) {
                        if (salesLineDetail.Sales_Line__r.Category__c == 'Labor') {
                            salesLineDetails.add(salesLineDetail);
                        }
                    }
                }
                if (salesLineDetails.size() > 0) {
                    this.calculateBillingLines(salesLineDetails, billingLines);
                }

                //calculate schedule line totals
                for (Map<Date, Sales_Line_Detail__c> mapSalesLineDetailsByDates : mapSalesLineDetailsByDateBySalesLineNo.values()) {
                    for (Sales_Line_Detail__c salesLineDetail : mapSalesLineDetailsByDates.values()) {
                        //Ticket#22710 >>
                        //this.calculateScheduleLineTotals(salesLineDetail);
                        this.calculateScheduleLineTotals(salesOrder, salesLineDetail);
                        //Ticket#22710 <<
                    }
                }
                //equipment schedule line >>
            }

            //ticket 20876 <<
            billingLines = null;
            //ticket 20876 >>
            
            //update sales lines with the details
            for (Integer i = 0; i < jobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c salesLine = jobTaskWrapper.SalesLines[i];
                //equipment schedule line <<
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                    //equipment schedule line >>
                    Integer salesLineNo = salesLine.Line_No__c.intValue();
                    if (mapSalesLineDetailsByDateBySalesLineNo.containsKey(salesLineNo)) {
                        List<Sales_Line_Detail__c> salesLineDetails = mapSalesLineDetailsByDateBySalesLineNo.get(salesLineNo).values();
                        jobTaskWrapper.SalesLines[i] = (Sales_Line__c)JSONUtils.attachListToParent(salesLine, salesLineDetails, 'Sales_Line_Details__r');

                        //rollup amount and cost
                        this.calculateLineTotals(salesOrder, jobTaskWrapper.SalesLines[i]);
                    }
                }
            }

            //ticket 20876 <<
            mapSalesLineDetailsByDateBySalesLineNo = null;
            //ticket 20876 >>
        }
    }
    //job task >>

    public void recalculateSalesLineDetails(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers, Boolean recalculateHours) {
        Map<Integer, Map<Date, Sales_Line_Detail__c>> mapSalesLineDetailsByDateBySalesLineNo = new Map<Integer, Map<Date, Sales_Line_Detail__c>>();
        List<BillingLine> billingLines = new List<BillingLine>();
        //Ticket#20496 >>
        /*
        BillingLine tempBillingLine = new BillingLine();
        tempBillingLine.BillingRuleId = salesOrder.Billing_Rule__c;
        BillingService.initSetupData(new List<BillingLine>{ tempBillingLine });
        Map<Date, Week_Number__c> weekNumbersByWeekStartDate = new Map<Date, Week_Number__c>();
        if(BillingService.mapBillingRulesById.get(tempBillingLine.BillingRuleId).Enable_Weekly_Total_Calculation__c == true){
         */
        Map<Date, Week_Number__c> weekNumbersByWeekStartDate = new Map<Date, Week_Number__c>();
        if(salesOrder.Estimated_Job_Start_Date__c != null && salesOrder.Estimated_Job_End_Date__c != null) {
            Date tempStartDate = salesOrder.Estimated_Job_Start_Date__c.toStartOfWeek().addDays(1);
            Date tempEndDate = salesOrder.Estimated_Job_End_Date__c.toStartOfWeek().addDays(8);
            List<Week_Number__c> weekNumbers = [
                    SELECT Id, Name, Week_Start_Date__c, Week_End_Date__c
                    FROM Week_Number__c
                    WHERE Week_Start_Date__c >= :tempStartDate AND Week_Start_Date__c <= :tempEndDate
            ];
            for (Week_Number__c weekNumber : weekNumbers) {
                weekNumbersByWeekStartDate.put(weekNumber.Week_Start_Date__c, weekNumber);
            }
        }
        //}
        //Ticket#20496 <<

        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                //System.debug('***heap size: sales line ' + Limits.getHeapSize());
                if (salesLine.Category__c == 'Labor') {
                    Map<Date, Sales_Line_Detail__c> mapSalesLineDetailsByDate = new Map<Date, Sales_Line_Detail__c>();
                    if (recalculateHours == true) {
                        if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                                salesLine.UOM_Qty__c = TimeUtils.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                            }
                        }
                    }

                    if (salesLine.Sales_Line_Details__r != null) {
                        for (Integer i = 0; i < salesLine.Sales_Line_Details__r.size(); i++) {
                            Sales_Line_Detail__c salesLineDetail = salesLine.Sales_Line_Details__r[i];

                            if (salesLine.Unit_of_Measure__c == salesLineDetail.Unit_of_Measure__c) {
                                if (recalculateHours == true) {
                                    if (salesLineDetail.Unit_of_Measure__r.Hours_UOM__c == true) {
                                        if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                                            salesLineDetail.Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                                            salesLineDetail.End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                                        }
                                        if (salesLineDetail.Start_Time__c != null && salesLineDetail.End_Time__c != null) {
                                            salesLineDetail.UOM_Qty__c = TimeUtils.calculateHours(salesLineDetail.Start_Time__c, salesLineDetail.End_Time__c);
                                        }
                                    }
                                }

                                salesLineDetail.Regular_Rate__c = salesLine.Regular_Rate__c;
                                salesLineDetail.Overtime_Rate__c = salesLine.Overtime_Rate__c;
                                salesLineDetail.Premium_Rate__c = salesLine.Premium_Rate__c;
                                salesLineDetail.Unit_Price__c = salesLine.Unit_Price__c;
                                if (salesLine.Bill_as_Lump_Sum__c != true) {
                                    salesLineDetail.Unit_Cost__c = salesLine.Unit_Cost__c;
                                } else {
                                    salesLineDetail.Unit_Cost__c = salesLine.xUnit_Cost__c;
                                }
                                salesLineDetail.Quantity__c = salesLine.Quantity__c;
                                salesLineDetail.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                                salesLineDetail.Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                                //Ticket#20496 >>
                                if(weekNumbersByWeekStartDate.containsKey(salesLineDetail.Scheduled_Date__c.toStartOfWeek().addDays(1))) {
                                    salesLineDetail.Week_Number__c = weekNumbersByWeekStartDate.get(salesLineDetail.Scheduled_Date__c.toStartOfWeek().addDays(1)).Id;
                                }
                                //Ticket#20496 <<
                                mapSalesLineDetailsByDate.put(salesLineDetail.Scheduled_Date__c, salesLineDetail);

                                BillingLine billingLine = this.initBillingLine(i, salesOrder, salesLine, salesLineDetail);
                                billingLines.add(billingLine);
                            }
                        }
                        mapSalesLineDetailsByDateBySalesLineNo.put(salesLine.Line_No__c.intValue(), mapSalesLineDetailsByDate);
                    }
                    mapSalesLineDetailsByDate = null; //free memory from heap
                }
                else if (salesLine.Category__c == 'Equipment') {
                    //equipment schedule lines <<
                    /*
                    if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true && recalculateHours == true ) {
                        if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                            salesLine.UOM_Qty__c = TimeUtils.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                        }
                    }
                    */
                    Map<Date, Sales_Line_Detail__c> mapSalesLineDetailsByDate = new Map<Date, Sales_Line_Detail__c>();
                    if (recalculateHours == true) {
                        if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true && recalculateHours == true) {
                            if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                                salesLine.UOM_Qty__c = TimeUtils.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                            }
                        }
                    }

                    if (salesLine.Sales_Line_Details__r != null) {
                        for (Integer i = 0; i < salesLine.Sales_Line_Details__r.size(); i++) {
                            Sales_Line_Detail__c salesLineDetail = salesLine.Sales_Line_Details__r[i];

                            if (salesLine.Unit_of_Measure__c == salesLineDetail.Unit_of_Measure__c) {
                                if (recalculateHours == true) {
                                    if (salesLineDetail.Unit_of_Measure__r.Hours_UOM__c == true) {
                                        if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                                            salesLineDetail.Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                                            salesLineDetail.End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                                        }
                                        if (salesLineDetail.Start_Time__c != null && salesLineDetail.End_Time__c != null) {
                                            salesLineDetail.UOM_Qty__c = TimeUtils.calculateHours(salesLineDetail.Start_Time__c, salesLineDetail.End_Time__c);
                                        }
                                    }
                                }

                                //ticket 19535 <<
                                //if (salesLine.Bill_as_Lump_Sum__c != true) {
                                if (salesLine.Bill_as_Lump_Sum__c != true && salesLine.Non_Billable__c != true) {
                                //ticket 19535 >>
                                    salesLineDetail.Unit_Price__c = salesLine.Unit_Price__c;
                                    salesLineDetail.Unit_Cost__c = salesLine.Unit_Cost__c;
                                } else {
                                    salesLineDetail.Unit_Price__c = salesLine.xUnit_Price__c;
                                    salesLineDetail.Unit_Cost__c = salesLine.xUnit_Cost__c;
                                }
                                salesLineDetail.Quantity__c = salesLine.Quantity__c;
                                salesLineDetail.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                                salesLineDetail.Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
                                mapSalesLineDetailsByDate.put(salesLineDetail.Scheduled_Date__c, salesLineDetail);
                            }
                        }
                        mapSalesLineDetailsByDateBySalesLineNo.put(salesLine.Line_No__c.intValue(), mapSalesLineDetailsByDate);
                    }
                    //equipment schedule lines >>
                    mapSalesLineDetailsByDate = null; //free memory from heap
                }
            }
        }

        if (mapSalesLineDetailsByDateBySalesLineNo.size() > 0) {
            List<Sales_Line_Detail__c> salesLineDetails = new List<Sales_Line_Detail__c>();
            //equipment schedule lines <<
            for (Integer salesLineNo : mapSalesLineDetailsByDateBySalesLineNo.keySet()) {
                Map<Date, Sales_Line_Detail__c> mapSalesLineDetailsByDates = mapSalesLineDetailsByDateBySalesLineNo.get(salesLineNo);
                for (Sales_Line_Detail__c salesLineDetail : mapSalesLineDetailsByDates.values()) {
                    if (salesLineDetail.Sales_Line__r.Category__c == 'Labor') {
                        salesLineDetails.add(salesLineDetail);
                    }
                }
            }
            if (salesLineDetails.size() > 0) {
                this.calculateBillingLines(salesLineDetails, billingLines);
            }

            //calculate schedule line totals
            for (Map<Date, Sales_Line_Detail__c> mapSalesLineDetailsByDates : mapSalesLineDetailsByDateBySalesLineNo.values()) {
                for (Sales_Line_Detail__c salesLineDetail : mapSalesLineDetailsByDates.values()) {
                    //Ticket#22710 >>
                    //this.calculateScheduleLineTotals(salesLineDetail);
                    this.calculateScheduleLineTotals(salesOrder, salesLineDetail);
                    //Ticket#22710 <<
                }
            }
            //equipment schedule lines >>
        }
        billingLines = null; //free memory from heap


        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Integer i = 0; i < jobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c salesLine = jobTaskWrapper.SalesLines[i];
                //equipment schedule lines <<
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                    //equipment schedule lines >>
                    Integer salesLineNo = salesLine.Line_No__c.intValue();
                    if (mapSalesLineDetailsByDateBySalesLineNo.containsKey(salesLineNo)) {
                        List<Sales_Line_Detail__c> salesLineDetails = mapSalesLineDetailsByDateBySalesLineNo.get(salesLineNo).values();

                        jobTaskWrapper.SalesLines[i] = (Sales_Line__c) JSONUtils.attachListToParent(salesLine, salesLineDetails, 'Sales_Line_Details__r');

                        salesLineDetails = null; //free memory from heap
                        mapSalesLineDetailsByDateBySalesLineNo.remove(salesLineNo); //free memory from heap

                        //rollup amount and cost
                        this.calculateLineTotals(salesOrder, jobTaskWrapper.SalesLines[i]);
                    }
                }
            }
        }
        mapSalesLineDetailsByDateBySalesLineNo = null; //free memory from heap
        //ticket 19754 >>
    }
    //job task >>

    private void calculateBillingLines(List<Sales_Line_Detail__c> salesLineDetails, List<BillingLine> billingLines) {
        //BillingService.initSetupData(billingLines); this line of code already exists in BillingService.calculateBillingLines()
        //Ticket#20496 >>
        if(billingLines[0].BillingRule.Enable_Weekly_Total_Calculation__c != true){
            BillingService.calculateBillingLines(billingLines);
        } else {
            Map<Id, Map<Id, Decimal>> numberOfHoursBilledByWeekNumberIdByResourceId = new Map<Id, Map<Id, Decimal>>();
            BillingService.calculateBillingLinesWeeklyTotalRule(billingLines, numberOfHoursBilledByWeekNumberIdByResourceId);
        }
        //Ticket#20496 <<

        for (Integer i = 0; i < salesLineDetails.size(); i++) {
            salesLineDetails[i].Day_Rate_Code__c = billingLines[i].DayRateCode;
            salesLineDetails[i].Regular_Hours__c = billingLines[i].RegularHours;
            salesLineDetails[i].Overtime_Hours__c = billingLines[i].OvertimeHours;
            salesLineDetails[i].Premium_Hours__c = billingLines[i].DoubleTimeHours;

            //equipment schedule lines <<
            /*
            if (salesLineDetails[i].Quantity__c == null) {
                salesLineDetails[i].Quantity__c = 0;
            }

            if (salesLineDetails[i].UOM_Qty__c == null) {
                salesLineDetails[i].UOM_Qty__c = 0;
            }

            if (salesLineDetails[i].Unit_Cost__c == null) {
                salesLineDetails[i].Unit_Cost__c = 0;
            }

            if (salesLineDetails[i].Regular_Rate__c == null) {
                salesLineDetails[i].Regular_Rate__c = 0;
            }

            if (salesLineDetails[i].Overtime_Rate__c == null) {
                salesLineDetails[i].Overtime_Rate__c = 0;
            }

            if (salesLineDetails[i].Premium_Rate__c == null) {
                salesLineDetails[i].Premium_Rate__c = 0;
            }

            if (salesLineDetails[i].Unit_of_Measure__r != null) {
                if (salesLineDetails[i].Unit_of_Measure__r.Hours_UOM__c == true) {
                    salesLineDetails[i].Line_Amount__c =
                            CompanyMgmt.halfUpTo2D(salesLineDetails[i].Regular_Rate__c * salesLineDetails[i].Regular_Hours__c * salesLineDetails[i].Quantity__c)
                                    + CompanyMgmt.halfUpTo2D(salesLineDetails[i].Overtime_Rate__c * salesLineDetails[i].Overtime_Hours__c * salesLineDetails[i].Quantity__c)
                                    + CompanyMgmt.halfUpTo2D(salesLineDetails[i].Premium_Rate__c * salesLineDetails[i].Premium_Hours__c * salesLineDetails[i].Quantity__c);
                }
                else if (salesLineDetails[i].Unit_of_Measure__r.Name == 'DAY') {
                    Integer regularDays = 0;
                    Integer overtTimeDays = 0;
                    Integer doubleTimeDays = 0;
                    if (salesLineDetails[i].Day_Rate_Code__c == 'REG' ) {
                        regularDays = 1;
                    }
                    if (salesLineDetails[i].Day_Rate_Code__c == 'OT' ) {
                        overtTimeDays = 1;
                    }
                    if (salesLineDetails[i].Day_Rate_Code__c == 'DT' ) {
                        doubleTimeDays = 1;
                    }

                    salesLineDetails[i].Line_Amount__c =
                            CompanyMgmt.halfUpTo2D(salesLineDetails[i].Regular_Rate__c * regularDays * salesLineDetails[i].Quantity__c * salesLineDetails[i].UOM_Qty__c)
                                    + CompanyMgmt.halfUpTo2D(salesLineDetails[i].Regular_Rate__c * overtTimeDays * salesLineDetails[i].Quantity__c * salesLineDetails[i].UOM_Qty__c)
                                    + CompanyMgmt.halfUpTo2D(salesLineDetails[i].Regular_Rate__c * doubleTimeDays * salesLineDetails[i].Quantity__c * salesLineDetails[i].UOM_Qty__c);
                }
                else {
                    salesLineDetails[i].Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetails[i].Quantity__c * salesLineDetails[i].UOM_Qty__c * salesLineDetails[i].Unit_Price__c);
                }
            }
            else {
                salesLineDetails[i].Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetails[i].Quantity__c * salesLineDetails[i].UOM_Qty__c * salesLineDetails[i].Unit_Price__c);
            }
            salesLineDetails[i].Line_Cost__c = CompanyMgmt.halfUpTo2D(salesLineDetails[i].Unit_Cost__c * salesLineDetails[i].Quantity__c * salesLineDetails[i].UOM_Qty__c);
            */
            //equipment schedule lines >>
        }
    }

    //equipment schedule lines <<
    //Ticket#22710
    //private void calculateScheduleLineTotals(Sales_Line_Detail__c salesLineDetail) {
    private void calculateScheduleLineTotals(Sales_Order__c salesOrder, Sales_Line_Detail__c salesLineDetail) {
        if (salesLineDetail.Quantity__c == null) {
            salesLineDetail.Quantity__c = 0;
        }

        if (salesLineDetail.UOM_Qty__c == null) {
            salesLineDetail.UOM_Qty__c = 0;
        }

        if (salesLineDetail.Unit_Cost__c == null) {
            salesLineDetail.Unit_Cost__c = 0;
        }

        if (salesLineDetail.Regular_Rate__c == null) {
            salesLineDetail.Regular_Rate__c = 0;
        }

        if (salesLineDetail.Overtime_Rate__c == null) {
            salesLineDetail.Overtime_Rate__c = 0;
        }

        if (salesLineDetail.Premium_Rate__c == null) {
            salesLineDetail.Premium_Rate__c = 0;
        }

        //Ticket#22710 >>
        Boolean laborTotalCostCalculated = false; //Ticket#22710
        if(salesLineDetail.Regular_Unit_Cost__c == null){
            salesLineDetail.Regular_Unit_Cost__c = 0;
        }
        if(salesLineDetail.Overtime_Unit_Cost__c == null){
            salesLineDetail.Overtime_Unit_Cost__c = 0;
        }
        if(salesLineDetail.Double_Time_Unit_Cost__c == null){
            salesLineDetail.Double_Time_Unit_Cost__c = 0;
        }
        //Ticket#22710 <<
        if (salesLineDetail.Unit_of_Measure__r != null) {
            if (salesLineDetail.Sales_Line__r.Category__c == 'Labor') {
                if (salesLineDetail.Unit_of_Measure__r.Hours_UOM__c == true) {
                    salesLineDetail.Line_Amount__c =
                            CompanyMgmt.halfUpTo2D(salesLineDetail.Regular_Rate__c * salesLineDetail.Regular_Hours__c * salesLineDetail.Quantity__c)
                                    + CompanyMgmt.halfUpTo2D(salesLineDetail.Overtime_Rate__c * salesLineDetail.Overtime_Hours__c * salesLineDetail.Quantity__c)
                                    + CompanyMgmt.halfUpTo2D(salesLineDetail.Premium_Rate__c * salesLineDetail.Premium_Hours__c * salesLineDetail.Quantity__c);
                    //Ticket#22710 >>
                    if((salesOrder.Prevailing_Wage_Job__c != true || salesOrder.Pay_Rule__c == null || salesOrder.Pay_Rule__r.Type__c != 'Prevailing Wage') &&
                            (salesLineDetail.Regular_Unit_Cost__c != 0 || salesLineDetail.Overtime_Unit_Cost__c != 0 || salesLineDetail.Double_Time_Unit_Cost__c != 0)) {
                        salesLineDetail.Line_Cost__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Regular_Unit_Cost__c * salesLineDetail.Regular_Hours__c * salesLineDetail.Quantity__c)
                                + CompanyMgmt.halfUpTo2D(salesLineDetail.Overtime_Unit_Cost__c * salesLineDetail.Overtime_Hours__c * salesLineDetail.Quantity__c)
                                + CompanyMgmt.halfUpTo2D(salesLineDetail.Double_Time_Unit_Cost__c * salesLineDetail.Premium_Hours__c * salesLineDetail.Quantity__c);
                        laborTotalCostCalculated = true;
                    }
                    //Ticket#22710 <<
                } else if (salesLineDetail.Unit_of_Measure__r.Name == 'DAY') {
                    Integer regularDays = 0;
                    Integer overtTimeDays = 0;
                    Integer doubleTimeDays = 0;
                    if (salesLineDetail.Day_Rate_Code__c == 'REG') {
                        regularDays = 1;
                    }
                    if (salesLineDetail.Day_Rate_Code__c == 'OT') {
                        overtTimeDays = 1;
                    }
                    if (salesLineDetail.Day_Rate_Code__c == 'DT') {
                        doubleTimeDays = 1;
                    }

                    salesLineDetail.Line_Amount__c =
                            CompanyMgmt.halfUpTo2D(salesLineDetail.Regular_Rate__c * regularDays * salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c)
                                    + CompanyMgmt.halfUpTo2D(salesLineDetail.Regular_Rate__c * overtTimeDays * salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c)
                                    + CompanyMgmt.halfUpTo2D(salesLineDetail.Regular_Rate__c * doubleTimeDays * salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c);
                } else {
                    salesLineDetail.Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c * salesLineDetail.Unit_Price__c);
                }
            }
            else if (salesLineDetail.Sales_Line__r.Category__c == 'Equipment') {
                salesLineDetail.Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c * salesLineDetail.Unit_Price__c);
            }
        }
        else {
            salesLineDetail.Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c * salesLineDetail.Unit_Price__c);
        }

        salesLineDetail.Line_Cost__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Unit_Cost__c * salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c);
    }
    //equipment schedule lines >>

    private BillingLine initBillingLine(Integer lineNo, Sales_Order__c salesOrder, Sales_Line__c salesLine, Sales_Line_Detail__c salesLineDetail) {
        BillingLine billingLine = new BillingLine();
        billingLine.LineNumber = lineNo;

        //billing rule mapping <<
        /*
        //rate.code.fix <<
        //billingLine.BillingRuleId = salesOrder.Billing_Rule__c;
        billingLine.BillingRuleId = salesOrder.Contract__r.Billing_Rule__c;
        //rate.code.fix >>

        billingLine.PortalBasisAssumption = salesOrder.Portal_Basis__c;
        billingLine.OvertimeRateAssumption = salesOrder.Overtime_Rate__c;
        billingLine.DailyRateAssumption = salesOrder.Daily_Rate__c;
        billingLine.LumpSumAssumption = salesOrder.Lump_Sum__c;
        */
        if (salesOrder.Contract__r != null && salesOrder.Contract__r.Billing_Rule__c != null) {
            billingLine.BillingRule = salesOrder.Contract__r.Billing_Rule__r;
            billingLine.BillingRuleId = salesOrder.Contract__r.Billing_Rule__c;
        }
        //Ticket#21540 >>
        else if (salesOrder.Service_Center__r != null && salesOrder.Service_Center__r.Billing_Rule__c != null){
            billingLine.BillingRule = salesOrder.Service_Center__r.Billing_Rule__r;
            billingLine.BillingRuleId = salesOrder.Service_Center__r.Billing_Rule__c;
        } else if (salesOrder.Subsidiary_Company__r != null && salesOrder.Subsidiary_Company__r.Billing_Rule__c != null){
            billingLine.BillingRule = salesOrder.Subsidiary_Company__r.Billing_Rule__r;
            billingLine.BillingRuleId = salesOrder.Subsidiary_Company__r.Billing_Rule__c;
        }
        //Ticket#21540 <<
        else {
            /*Ticket#24650 >>
            String assumption = '';
            if (salesOrder.Portal_Basis__c == true) {
                assumption = 'PortalBasis';
            } else if (salesOrder.Overtime_Rate__c == true) {
                assumption = 'OvertimeRate';
            } else if (salesOrder.Daily_Rate__c == true) {
                assumption = 'DailyRate';
            } else if (salesOrder.Lump_Sum__c == true) {
                //Ticket#24559 >>
                //assumption = 'LumpSum';
                if(salesOrder.CreatedDate < CompanySettingUtil.acvSetting.X2023_Billing_Rule_Start_Date__c) {
                    assumption = 'LumpSum';
                } else {
                    assumption = 'LumpSum2023';
                }
                //Ticket#24559 <<
            } else if (salesOrder.Portal_Basis_Adv__c == true) {
                assumption = 'PortalBasisAdv';
            }
            //Ticket#24559 >>
            else if (salesOrder.Default_Billing_Rule_2023__c == true){
                assumption = 'DefaultBillingRule2023';
            }
            //Ticket#24559 <<

            if (mapBillingRulesByAssumption.containsKey(assumption)) {
                billingLine.BillingRule = mapBillingRulesByAssumption.get(assumption);
                billingLine.BillingRuleId = billingLine.BillingRule.Id;
            }
            else {
                throw new DataException('Quote/order assumption ' + assumption + ' is not mapped to a billing rule. Please contact admin to set up the mapping for the assumption.');
            }
             */
            billingLine.BillingRule = BillingRuleService.getBillingRuleIdForSalesOrderAssumption(salesOrder);
            billingLine.BillingRuleId = billingLine.BillingRule.Id;
            //Ticket#24650 <<
        }
        //Ticket#24650 >>
        salesOrder.Billing_Rule__c = billingLine.BillingRuleId;
        //Ticket#24650 <<
        //billing rule mapping >>

        billingLine.ScheduleDate = salesLineDetail.Scheduled_Date__c;
        billingLine.StartTime = salesLineDetail.Start_Time__c;
        billingLine.EndTime = salesLineDetail.End_Time__c;
        billingLine.UOMQty = salesLineDetail.UOM_Qty__c;
        billingLine.LunchStartTime = null;
        billingLine.LunchEndTime = null;
        billingLine.IncludeLunch = false;
        billingLine.Quantity = salesLine.Quantity__c;
        billingLine.UnitOfMeasureId = salesLine.Unit_of_Measure__c;
        billingLine.UnitOfMeasure = salesLine.Unit_of_Measure__r;
        billingLine.RegularRate = salesLine.Regular_Rate__c;
        billingLine.OvertimeRate = salesLine.Overtime_Rate__c;
        billingLine.DoubleTimeRate = salesLine.Premium_Rate__c;
        billingLine.UnitPrice = salesLine.Unit_Price__c;
        billingLine.UnitCost = salesLine.Unit_Cost__c;
        billingLine.TaxPercent = salesLine.Tax_Pct__c;
        billingLine.ContractId = salesOrder.Contract__c;
        billingLine.TMStatus = null;
        billingLine.RegularHours = 0;
        billingLine.OvertimeHours = 0;
        billingLine.DoubleTimeHours = 0;
        billingLine.DayRateCode = '';
        //Ticket#20496 >>
        billingLine.resourceId = salesLine.Resource_Type__c;
        billingLine.weekNumberId = salesLineDetail.Week_Number__c;
        //Ticket#20496 <<
        return billingLine;
    }

    //ticket 19130 05.03.20.23 <<
    /*
    public List<Sales_Line__c> calculatePresumptiveChildLines(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, Sales_Line__c parentLine, Integer nextSalesLineNo) {
        List<Sales_Line__c> childLines = new List<Sales_Line__c>();
        if (mapPresumptiveResourcesByParentId.containsKey(parentLine.Resource_Type__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(parentLine.Resource_Type__c);
            childLines = insertPresumptiveChildLines(salesOrder, jobTask, parentLine, presumptiveResources, nextSalesLineNo);
        } else if (mapPresumptiveResourcesByParentId.containsKey(parentLine.Resource__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(parentLine.Resource__c);
            childLines = insertPresumptiveChildLines(salesOrder, jobTask, parentLine, presumptiveResources, nextSalesLineNo);
        }
        return childLines;
    }

    private List<Sales_Line__c> insertPresumptiveChildLines(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, Sales_Line__c parentLine, List<Presumptive_Resource__c> presumptiveResources, Integer nextSalesLineNo) {
        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
        for (Presumptive_Resource__c presumptiveResource : presumptiveResources) {
            if (presumptiveResource.Child_Resource_Type__c != null || presumptiveResource.Child_Resource__c != null) {
                Sales_Line__c salesLine = new Sales_Line__c();
                salesLine.Line_No__c = nextSalesLineNo;
                salesLine.Sales_Order__c = salesOrder.Id;
                salesLine.Sales_Order_Job_Task__c = jobTask.Id;
                salesLine.Sales_Order_Job_Task__r = jobTask;
                if (presumptiveResource.Child_Resource_Type__c != null && ResourceTypeUtil.resourceTypesByIds.containsKey(presumptiveResource.Child_Resource_Type__c)) {
                    Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource_Type__c);
                    salesLine.Category__c = resourceType.Category__c;
                    salesLine.Resource_Type__c = resourceType.Id;
                    salesLine.Resource_Type__r = resourceType;
                    salesLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                    salesLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                    salesLine.Description__c = resourceType.Description__c;
                }
                else if (presumptiveResource.Child_Resource__c != null && ResourceService.resourcesByIds.containsKey(presumptiveResource.Child_Resource__c)) {
                    Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource__r.Resource_Type__c);
                    Resource__c resource = ResourceService.resourcesByIds.get(presumptiveResource.Child_Resource__c);
                    salesLine.Category__c = resource.Category__c;
                    if (resourceType != null) {
                        salesLine.Resource_Type__c = resourceType.Id;
                        salesLine.Resource_Type__r = resourceType;
                        salesLine.Description__c = resourceType.Description__c;
                    }
                    else {
                        salesLine.Description__c = resource.Description__c;
                    }
                    salesLine.Resource__c = resource.Id;
                    salesLine.Resource__r = resource;
                    salesLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                    salesLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                }

                salesLine.Tax_Group__c = parentLine.Tax_Group__c;
                salesLine.Quantity__c = 0;
                if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Materials') {
                    salesLine.Number_of_Day__c = salesOrder.Duration__c;
                    salesLine.UOM_Qty__c = 0;
                }

                salesLine.Parent_Line__c = parentLine.Id;
                salesLine.Parent_Line__r = new Sales_Line__c(Id = parentLine.Id, Line_No__c = parentLine.Line_No__c);
                salesLine.Is_Child_Resource__c = true;

                calcUnitPrice(salesOrder, salesLine);
                calcUnitCost(salesOrder, salesLine);
                assignTaxPercent(salesOrder, salesLine);
                calculateLineTotals(salesOrder, salesLine);

                salesLines.add(salesLine);
                nextSalesLineNo++;
            }
        }
        return salesLines;
    }
    */

    public Sales_Line__c calculatePresumptiveChildLines(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Sales_Line__c salesLine, Integer nextSalesLineNo) {
        if (mapPresumptiveResourcesByParentId.containsKey(salesLine.Resource_Type__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(salesLine.Resource_Type__c);
            return insertPresumptiveChildLines(salesOrder, jobTaskWrapper, salesLine, presumptiveResources, nextSalesLineNo);
        } else if (mapPresumptiveResourcesByParentId.containsKey(salesLine.Resource__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(salesLine.Resource__c);
            return insertPresumptiveChildLines(salesOrder, jobTaskWrapper, salesLine, presumptiveResources, nextSalesLineNo);
        }
        return salesLine;
    }

    private Sales_Line__c insertPresumptiveChildLines(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Sales_Line__c salesLine, List<Presumptive_Resource__c> presumptiveResources, Integer nextSalesLineNo) {
        Map<Id, Sales_Parent_Child_Relation__c> mapRelationsByResourceId = new Map<Id, Sales_Parent_Child_Relation__c>();
        if (salesLine.Sales_Child_Lines__r != null) {
            for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                Id childResourceId = getResOrResTypeId(relation.Child_Line__r);
                mapRelationsByResourceId.put(childResourceId, relation);
            }
        }

        Map<Id, Sales_Line__c> mapSalesLinesByResourceId = new Map<Id, Sales_Line__c>();
        for (Sales_Line__c salesLine2 : jobTaskWrapper.SalesLines) {
            Id resourceId = getResOrResTypeId(salesLine2);
            mapSalesLinesByResourceId.put(resourceId, salesLine2);
        }

        for (Presumptive_Resource__c presumptiveResource : presumptiveResources) {
            if (presumptiveResource.Child_Resource_Type__c != null || presumptiveResource.Child_Resource__c != null) {
                Id resourceId = null;
                if (presumptiveResource.Child_Resource_Type__c != null) {
                    resourceId = presumptiveResource.Child_Resource_Type__c;
                } else {
                    resourceId = presumptiveResource.Child_Resource__c;
                }

                if (!mapRelationsByResourceId.containsKey(resourceId)) { //if relationship does not exist
                    Sales_Line__c childSalesLine;
                    if (mapSalesLinesByResourceId.containsKey(resourceId)) {
                        childSalesLine = mapSalesLinesByResourceId.get(resourceId);
                    }
                    else {
                        childSalesLine = new Sales_Line__c();
                        childSalesLine.Line_No__c = nextSalesLineNo;
                        childSalesLine.Sales_Order__c = salesOrder.Id;
                        childSalesLine.Sales_Order_Job_Task__c = jobTaskWrapper.JobTask.Id;
                        childSalesLine.Sales_Order_Job_Task__r = jobTaskWrapper.JobTask;
                        if (presumptiveResource.Child_Resource_Type__c != null && ResourceTypeUtil.resourceTypesByIds.containsKey(presumptiveResource.Child_Resource_Type__c)) {
                            Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource_Type__c);
                            childSalesLine.Category__c = resourceType.Category__c;
                            childSalesLine.Resource_Type__c = resourceType.Id;
                            childSalesLine.Resource_Type__r = resourceType;
                            childSalesLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                            childSalesLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                            childSalesLine.Description__c = resourceType.Description__c;
                        } else if (presumptiveResource.Child_Resource__c != null && ResourceService.resourcesByIds.containsKey(presumptiveResource.Child_Resource__c)) {
                            Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource__r.Resource_Type__c);
                            Resource__c resource = ResourceService.resourcesByIds.get(presumptiveResource.Child_Resource__c);
                            childSalesLine.Category__c = resource.Category__c;
                            if (resourceType != null) {
                                childSalesLine.Resource_Type__c = resourceType.Id;
                                childSalesLine.Resource_Type__r = resourceType;
                                childSalesLine.Description__c = resourceType.Description__c;
                            } else {
                                childSalesLine.Description__c = resource.Description__c;
                            }
                            childSalesLine.Resource__c = resource.Id;
                            childSalesLine.Resource__r = resource;
                            childSalesLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                            childSalesLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                        }

                        childSalesLine.Tax_Group__c = salesLine.Tax_Group__c;
                        childSalesLine.Quantity__c = 0;
                        if (childSalesLine.Category__c == 'Labor' || childSalesLine.Category__c == 'Equipment' || childSalesLine.Category__c == 'Materials') {
                            childSalesLine.Number_of_Day__c = salesOrder.Duration__c;
                            childSalesLine.UOM_Qty__c = 0;
                        }

                        childSalesLine.Is_Child_Resource__c = true;
                        jobTaskWrapper.SalesLines.add(childSalesLine);

                        calcUnitPrice(salesOrder, childSalesLine);
                        calcUnitCost(salesOrder, childSalesLine);
                        assignTaxPercent(salesOrder, childSalesLine);
                        calculateLineTotals(salesOrder, childSalesLine);
                        nextSalesLineNo++;
                    }

                    Sales_Parent_Child_Relation__c relation = new Sales_Parent_Child_Relation__c();
                    relation.Parent_Line__c = salesLine.Id;
                    relation.Parent_Line__r = salesLine;
                    relation.Child_Line__c = childSalesLine.Id;
                    relation.Child_Line__r = childSalesLine;
                    mapRelationsByResourceId.put(resourceId, relation);
                }
            }
        }
        jobTaskWrapper.NextSalesLineNo = nextSalesLineNo;
        salesLine = (Sales_Line__c)JSONUtils.attachListToParent(salesLine, mapRelationsByResourceId.values(), 'Sales_Child_Lines__r');
        return salesLine;
    }
    //ticket 19130 05.13.2023 >>

    public void calculateSurchargeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo) {
        Decimal amount = 0;
        if (salesOrder.Surcharge_Type__c == 'EEC Fee' || salesOrder.Surcharge_Type__c == 'Fuel Surcharge' || salesOrder.Surcharge_Type__c == 'ESIC') {
            //calculate surcharge amount
            switch on salesOrder.Surcharge_Type__c {
                when 'EEC Fee' {
                    //ticket 19672 <<
                    if (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price') {
                        amount = (jobTaskWrapper.JobTask.Fixed_Price__c != null ? jobTaskWrapper.JobTask.Fixed_Price__c : 0);
                    }
                    else {
                        //ticket 19672 >>
                        for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                            //ticket 19942 <<
                            if (salesLine.Non_Billable__c == true) continue;
                            //ticket 19942 >>

                            if (salesLine.Resource__c != defaultCompanySetup.Default_Energy_Insurance_Resource__c && salesLine.Resource__c != defaultCompanySetup.Default_Fuel_Surcharge_Resource__c) {
                                Boolean exempted = false;
                                if (ResourceTypeUtil.resourceTypesByIds.containsKey(salesLine.Resource_Type__c)) {
                                    exempted = ResourceTypeUtil.resourceTypesByIds.get(salesLine.Resource_Type__c).EEC_Surcharge_Exempted__c;
                                }
                                if (exempted != true && ResourceService.resourcesByIds.containsKey(salesLine.Resource__c)) {
                                    exempted = ResourceService.resourcesByIds.get(salesLine.Resource__c).EEC_Surcharge_Exempted__c;
                                }

                                if (exempted != true) {
                                    amount += CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                                }
                            }
                        }
                    //ticket 19672 <<
                    }
                    //ticket 19672 >>
                }
                when 'ESIC' {
                    if (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price') {
                    	amount = (jobTaskWrapper.JobTask.Fixed_Price__c != null ? jobTaskWrapper.JobTask.Fixed_Price__c : 0);
                    }
                    else{
                        for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                                //ticket 19942 <<
                                if (salesLine.Non_Billable__c == true) continue;
                                //ticket 19942 >>
    
                                /*if (salesLine.Resource__c != defaultCompanySetup.Default_Energy_Insurance_Resource__c && salesLine.Resource__c != defaultCompanySetup.Default_Fuel_Surcharge_Resource__c) {
                                    Boolean exempted = false;
                                    if (ResourceTypeUtil.resourceTypesByIds.containsKey(salesLine.Resource_Type__c)) {
                                        exempted = ResourceTypeUtil.resourceTypesByIds.get(salesLine.Resource_Type__c).EEC_Surcharge_Exempted__c;
                                    }
                                    if (exempted != true && ResourceService.resourcesByIds.containsKey(salesLine.Resource__c)) {
                                        exempted = ResourceService.resourcesByIds.get(salesLine.Resource__c).EEC_Surcharge_Exempted__c;
                                    }
    
                                    if (exempted != true) {
                                        amount += CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                                    }
                                }*/
                            if (salesLine.Resource__c != defaultCompanySetup.Default_Energy_Insurance_Resource__c && salesLine.Resource__c != defaultCompanySetup.Default_Fuel_Surcharge_Resource__c && salesLine.Resource__c !=defaultCompanySetup.Default_ESIC_Surcharge_Resource__c){
                                //Boolean exempted = false;
                                amount += CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                            }
                        }
                	}
                }
                when 'Fuel Surcharge' {
                    for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                        //ticket 19942 <<
                        if (salesLine.Non_Billable__c == true) continue;
                        //ticket 19942 >>

                        if (salesLine.Category__c == 'Equipment') {
                            if (ResourceTypeUtil.resourceTypesByIds.containsKey(salesLine.Resource_Type__c)) {
                                if (ResourceTypeUtil.resourceTypesByIds.get(salesLine.Resource_Type__c).Fuel_Fired_Equipment__c == true) {
                                    amount += CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                                    if (salesLine.Bill_as_Lump_Sum__c == true || salesLine.Non_Billable__c == true) {
                                        //ticket 21536 <<
                                        //amount += CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(salesLine.xUnit_Price__c) * companyMgmt.zeroIfNull(salesLine.Quantity__c) * companyMgmt.zeroIfNull(salesLine.UOM_Qty__c));
                                        amount += CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(salesLine.xUnit_Price__c) * companyMgmt.zeroIfNull(salesLine.Quantity__c) * companyMgmt.zeroIfNull(salesLine.UOM_Qty__c) * companyMgmt.zeroIfNull(salesLine.Number_of_Day__c));
                                        //ticket 21536 >>
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        if (amount > 0) {
            Decimal surchargeAmount = (amount * CompanyMgmt.zeroIfNull(salesOrder.Surcharge_Pct__c) / 100).setScale(2);
            //add/update the surcharge line
            Boolean surchargeLineFound = false;
            for (Integer i = 0; i < jobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c salesLine = jobTaskWrapper.SalesLines[i];
                if (salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true &&
                        (salesLine.Resource__c == defaultCompanySetup.Default_Energy_Insurance_Resource__c || salesLine.Resource__c == defaultCompanySetup.Default_Fuel_Surcharge_Resource__c || salesLine.Resource__c == defaultCompanySetup.Default_ESIC_Surcharge_Resource__c)) {
                            salesLine.Unit_Price__c = surchargeAmount;
                    salesLine.Line_Amount__c = surchargeAmount;
                    salesLine.Line_Amt_Incl_Tax__c = surchargeAmount;
                     if (salesOrder.Surcharge_Type__c == 'EEC Fee' && salesLine.Resource__c != defaultCompanySetup.Default_Energy_Insurance_Resource__c) {
                        Resource__c resource = ResourceService.resourcesByIds.get(defaultCompanySetup.Default_Energy_Insurance_Resource__c);
                        salesLine.Resource__c = resource.Id;
                        salesLine.Resource__r = resource;
                        salesLine.Description__c = resource.Description__c;
                    }
                    if (salesOrder.Surcharge_Type__c == 'Fuel Surcharge' && salesLine.Resource__c != defaultCompanySetup.Default_Fuel_Surcharge_Resource__c) {
                        
                        Resource__c resource = ResourceService.resourcesByIds.get(defaultCompanySetup.Default_Fuel_Surcharge_Resource__c);
                        salesLine.Resource__c = resource.Id;
                        salesLine.Resource__r = resource;
                        salesLine.Description__c = resource.Description__c;
                    }
                    if (salesOrder.Surcharge_Type__c == 'ESIC' && salesLine.Resource__c != defaultCompanySetup.Default_ESIC_Surcharge_Resource__c) {
                        Resource__c resource = ResourceService.resourcesByIds.get(defaultCompanySetup.Default_ESIC_Surcharge_Resource__c);
                        salesLine.Resource__c = resource.Id;
                        salesLine.Resource__r = resource;
                        salesLine.Description__c = resource.Description__c;
                        
                    }
                    surchargeLineFound = true;
                    break;
                }
            }
            if (!surchargeLineFound) {
                Resource__c resource;
                if (salesOrder.Surcharge_Type__c == 'EEC Fee') {
                    resource = ResourceService.resourcesByIds.get(defaultCompanySetup.Default_Energy_Insurance_Resource__c);
                }
                else if(salesOrder.Surcharge_Type__c == 'ESIC'){
                    resource = ResourceService.resourcesByIds.get(defaultCompanySetup.Default_ESIC_Surcharge_Resource__c);
                }
                else {
                    resource = ResourceService.resourcesByIds.get(defaultCompanySetup.Default_Fuel_Surcharge_Resource__c);
                }

                Sales_Line__c surchargeLine = new Sales_Line__c();
                surchargeLine.Category__c = 'Misc. Charges And Taxes';
                surchargeLine.Line_No__c = nextSalesLineNo;
                surchargeLine.Sales_Order__c = salesOrder.Id;
                surchargeLine.Resource__c = resource.Id;
                surchargeLine.Resource__r = resource;
                surchargeLine.Description__c = resource.Description__c;
                surchargeLine.Unit_of_Measure__c = resource.Unit_of_Measure__c;
                surchargeLine.Unit_of_Measure__r = resource.Unit_of_Measure__r;
                surchargeLine.Quantity__c = 1;
                surchargeLine.Unit_Price__c = surchargeAmount;
                surchargeLine.Line_Amount__c = surchargeAmount;
                if(salesOrder.Tax_Liable__c){
                    surchargeLine.Tax_Group__c = 'TX';    
                	surchargeLine.Tax_Pct__c = TaxService.getTaxPct(salesOrder.Tax_Area__c, surchargeLine.Tax_Group__c);
                	surchargeLine.Tax__c = CompanyMgmt.halfUpTo2D(surchargeLine.Line_Amount__c * CompanyMgmt.zeroIfNull(surchargeLine.Tax_Pct__c) / 100);
                	surchargeLine.Line_Amt_Incl_Tax__c = surchargeLine.Line_Amount__c + surchargeLine.Tax__c;
                }else{
                	surchargeLine.Tax_Group__c = 'NT';    
                	surchargeLine.Tax_Pct__c = 0; 
                	surchargeLine.Tax__c = 0; 
                	surchargeLine.Line_Amt_Incl_Tax__c = surchargeAmount; 
                }               
                surchargeLine.System_Calculated_Line__c = true;
                surchargeLine.Sales_Order_Job_Task__c = jobTaskWrapper.JobTask.Id;
                surchargeLine.Sales_Order_Job_Task__r = jobTaskWrapper.JobTask;
                jobTaskWrapper.SalesLines.add(surchargeLine);
                nextSalesLineNo++;
            }
            jobTaskWrapper.JobTask.Surcharge_Amount__c = surchargeAmount;
        }
        else {
            //remove surcharge lines
            for (Integer i = 0 ; i < jobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c salesLine = jobTaskWrapper.SalesLines[i];
                if (salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true &&
                        (salesLine.Resource__c == defaultCompanySetup.Default_Energy_Insurance_Resource__c || salesLine.Resource__c == defaultCompanySetup.Default_Fuel_Surcharge_Resource__c || salesLine.Resource__c == defaultCompanySetup.Default_ESIC_Surcharge_Resource__c)) {
                    jobTaskWrapper.SalesLines.remove(i);
                    i--;
                }
            }
            jobTaskWrapper.JobTask.Surcharge_Amount__c = 0;
        }

        //calculate unit cost and line cost for surcharge lines
        for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
            if (salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true &&
                    (salesLine.Resource__c == defaultCompanySetup.Default_Energy_Insurance_Resource__c || salesLine.Resource__c == defaultCompanySetup.Default_Fuel_Surcharge_Resource__c || salesLine.Resource__c == defaultCompanySetup.Default_ESIC_Surcharge_Resource__c)) {
					if(salesOrder.Tax_Liable__c){
                		salesLine.Tax_Group__c = 'TX'; 
                    }else{
                     	salesLine.Tax_Group__c = 'NT'; 
                    }
    				    SalesLinesService.calcUnitCost(salesOrder, salesLine);
                SalesLinesService.calculateLineTotals(salesOrder, salesLine);
            }
        }
    }

    public void calculateManifestFeeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo) {
        Boolean manifest = salesOrder.Manifest_And_Profile__c;

        Boolean addManifestFeeLine = false;
        if (manifest == true) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                if (salesLine.Category__c == 'Waste Disposal' && salesLine.Resource__c != null && salesLine.System_Calculated_Line__c == false) {
                    addManifestFeeLine = true;
                    break;
                }
            }
        }

        if (addManifestFeeLine == true) {
            Resource__c resource = ResourceService.getResource(defaultCompanySetup.Default_Manifest_Fee_Resource__c);
            Boolean manifestLineExists = false;
            Sales_Line__c manifestLine;
            for(Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                if (salesLine.Category__c == 'Waste Disposal' && salesLine.System_Calculated_Line__c == true && salesLine.Resource__c == resource.Id) {
                    manifestLine = salesLine;
                    //Ticket#28704 >>
                    manifestLine.Unit_Price__c = ResourceService.getUnitPrice(resource.Id, resource.Unit_of_Measure__c, false);
                    manifestLine.Unit_Cost__c = ResourceService.getUnitCost(resource.Id, resource.Unit_of_Measure__c);
                    //Ticket#28704 <<
                    /*
                    manifestLine.Unit_Price__c = 25;
                    manifestLine.Unit_Cost__c = manifestLine.Unit_Price__c;
                    */
                    manifestLine.xUnit_Price__c = manifestLine.Unit_Price__c;
                    manifestLine.xUnit_Cost__c = manifestLine.Unit_Cost__c;
                    manifestLineExists = true;
                    break;
                }
            }

            if (!manifestLineExists) {
                manifestLine = new Sales_Line__c();
                manifestLine.Sales_Order__c = salesOrder.Id;
                manifestLine.Sales_Order_Job_Task__c = jobTaskWrapper.JobTask.Id;
                manifestLine.Sales_Order_Job_Task__r = jobTaskWrapper.JobTask;
                manifestLine.Category__c = 'Waste Disposal';
                manifestLine.Line_No__c = nextSalesLineNo;
                manifestLine.Tax_Group__c = 'TX';
                manifestLine.Resource__c = resource.Id;
                manifestLine.Resource__r = resource;
                manifestLine.Description__c = resource.Description__c;
                manifestLine.Unit_of_Measure__c = resource.Unit_of_Measure__c;
                manifestLine.Unit_of_Measure__r = resource.Unit_of_Measure__r;
                manifestLine.Quantity__c = 0;
                //Ticket#28704 >>
                manifestLine.Unit_Price__c = ResourceService.getUnitPrice(resource.Id, resource.Unit_of_Measure__c, false);
                manifestLine.Unit_Cost__c = ResourceService.getUnitCost(resource.Id, resource.Unit_of_Measure__c);
                //Ticket#28704 <<
                /*
                manifestLine.Unit_Price__c = 25;
                manifestLine.Unit_Cost__c = manifestLine.Unit_Price__c;
                 */
                manifestLine.xUnit_Price__c = manifestLine.Unit_Price__c;
                manifestLine.xUnit_Cost__c = manifestLine.Unit_Cost__c;
                manifestLine.System_Calculated_Line__c = true;
                jobTaskWrapper.SalesLines.add(manifestLine);
                nextSalesLineNo++;
            }
            SalesLinesService.calculateLineTotals(salesOrder, manifestLine);
        }
        else {
            for (Integer i = 0; i < jobTaskWrapper.SalesLines.size(); i++) {
                Sales_Line__c salesLine = jobTaskWrapper.SalesLines[i];
                if(salesLine.Category__c == 'Waste Disposal' && salesLine.System_Calculated_Line__c == true && salesLine.Resource__c == defaultCompanySetup.Default_Manifest_Fee_Resource__c) {
                    jobTaskWrapper.SalesLines.remove(i);
                    i--;
                }
            }
        }
    }

    public void calculateRinseOutFeeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo) {
        Integer rinseOutQuantity = 0;
        if(salesOrder.Charge_Rinse_Out_Fee__c == true) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                //calc number of rinse out fee needed
                if (salesLine.Category__c == ResourceService.EQUIPMENT_CATEGORY && String.isNotBlank(salesLine.Resource_Type__c)) {
                    if (!ResourceTypeUtil.resourceTypesByIds.containsKey(salesLine.Resource_Type__c)) {
                        throw new DataException('Resource type \'' + salesLine.Resource_Type__c + '\' is not found.');
                    }
                    if (ResourceTypeUtil.resourceTypesByIds.get(salesLine.Resource_Type__c).Charge_Rinse_Out_Fee__c == true) {
                        rinseOutQuantity += 1;
                    }
                }
            }
        }

        if (rinseOutQuantity > 0) {
            addRinseOutFeeLine(salesOrder, jobTaskWrapper, nextSalesLineNo);
        } else {
            removeRinseOutFeeLine(jobTaskWrapper);
        }
    }

    @TestVisible
    private void addRinseOutFeeLine(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper,Integer nextSalesLineNo){
        Sales_Line__c rinseOutFeeLine;
        for(Sales_Line__c salesLine : jobTaskWrapper.SalesLines){
            if(salesLine.Category__c == ResourceService.MISC_CHARGES_AND_TAX_CATEGORY && salesLine.System_Calculated_Line__c == true && salesLine.Resource__c == CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c){
                rinseOutFeeLine = salesLine;
                break;
            }
        }

        if (ResourceService.resourcesByIds.containsKey(CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c)) {
            Resource__c rinseOutResource = ResourceService.resourcesByIds.get(CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c);
            if (rinseOutFeeLine == null) {
                Map<Id, List<ResourceUOMAssociation__c>> mapResourceUOMAssociationsByUOMId = ResourceService.resourceUOMAssociationsByUOMIdsByResIds.get(rinseOutResource.Id);
                ResourceUOMAssociation__c resourceUOMAssociation;
                for (List<ResourceUOMAssociation__c> resourceUOMAssociations : mapResourceUOMAssociationsByUOMId.values()) {
                    resourceUOMAssociation = resourceUOMAssociations[0];
                    break;
                }
                rinseOutFeeLine = new Sales_Line__c();
                rinseOutFeeLine.Sales_Order__c = salesOrder.Id;
                rinseOutFeeLine.Sales_Order_Job_Task__c = jobTaskWrapper.JobTask.Id;
                rinseOutFeeLine.Sales_Order_Job_Task__r = jobTaskWrapper.JobTask;
                rinseOutFeeLine.Line_No__c = nextSalesLineNo;
                rinseOutFeeLine.Category__c = ResourceService.MISC_CHARGES_AND_TAX_CATEGORY;
                rinseOutFeeLine.Resource__c = rinseOutResource.Id;
                rinseOutFeeLine.Resource__r = rinseOutResource;
                rinseOutFeeLine.Description__c = rinseOutResource.Name;
                if (resourceUOMAssociation != null) {
                    rinseOutFeeLine.Unit_of_Measure__c = resourceUOMAssociation.Unit_of_Measure__c;
                    rinseOutFeeLine.Unit_of_Measure__r = resourceUOMAssociation.Unit_of_Measure__r;
                }
                rinseOutFeeLine.Quantity__c = 0;
                rinseOutFeeLine.Unit_Price__c = resourceUOMAssociation.Unit_Price__c;
                rinseOutFeeLine.Unit_Cost__c = resourceUOMAssociation.Unit_Cost__c;
                rinseOutFeeLine.System_Calculated_Line__c = true;
                jobTaskWrapper.SalesLines.add(rinseOutFeeLine);
            }
        }
    }

    @TestVisible
    private void removeRinseOutFeeLine(ACVSalesOrderJobTaskWrapper jobTaskWrapper){
        for (Integer i = 0 ; i < jobTaskWrapper.SalesLines.size(); i++) {
            Sales_Line__c salesLine = jobTaskWrapper.SalesLines[i];
            if (salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true && salesLine.Resource__c == CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c){
                jobTaskWrapper.SalesLines.remove(i);
                i--;
            }
        }
    }

    //recalculate lines on contract change 10.16.2020 <<
    public void calculateLumpSumLine(Sales_Line__c lumpSumLine, Sales_Order__c salesOrder, List<Sales_Line__c> salesLines, Boolean overwriteUnitPrice) {
        List<Sales_Line__c> bundledSalesLines = new List<Sales_Line__c>();
        for (Sales_Line__c salesLine : salesLines) {
            if (salesLine.Category__c != 'Bundled' && salesLine.Bill_as_Lump_Sum__c == true && salesLine.Bundle_Line__r != null && salesLine.Bundle_Line__r.Line_No__c == lumpSumLine.Line_No__c) {
                bundledSalesLines.add(salesLine);
            }
        }

        if (lumpSumLine.Quantity__c == null) {
            lumpSumLine.Quantity__c = 0;
        }

        Decimal lumpSumAmount = 0;
        Decimal lumpSumCost = 0;

        if (bundledSalesLines.size() > 0) {
            for (Sales_Line__c bundledSalesLine : bundledSalesLines) {
                if (bundledSalesLine.Non_Billable__c != true) {
                    lumpSumAmount += bundledSalesLine.xLine_Amount__c;
                }
                lumpSumCost += bundledSalesLine.xLine_Cost__c;
            }

            //bundle line pricing method <<
            Decimal unitPrice = 0;
            Decimal unitCost = 0;
            if (lumpSumLine.Bundle_Pricing_Method__c == 'Per Unit') {
                if (lumpSumLine.Quantity__c > 0) {
                    unitPrice = CompanyMgmt.halfUpTo2D(lumpSumAmount / lumpSumLine.Quantity__c);
                    unitCost = CompanyMgmt.halfUpTo2D(lumpSumCost / lumpSumLine.Quantity__c);
                }
            } else {
                unitPrice = lumpSumAmount;
                unitCost = lumpSumCost;
            }

            if (lumpSumLine.Contract_Line__c != null) {
                unitPrice = lumpSumLine.xUnit_Price__c;
            }
            //bundle line pricing method >>

            lumpSumLine.Rolled_up_Unit_Price__c = lumpSumAmount;
            if (overwriteUnitPrice == true) {
                lumpSumLine.Unit_Price__c = unitPrice;
            }
            lumpSumLine.Unit_Cost__c = unitCost;
        }
        else {
            lumpSumLine.Rolled_up_Unit_Price__c = 0;
            lumpSumLine.Unit_Price__c = lumpSumLine.xUnit_Price__c;
            lumpSumLine.Unit_Cost__c = lumpSumLine.xUnit_Cost__c;
        }
        this.calculateLineTotals(salesOrder, lumpSumLine);

        lumpSumLine.Profit_Margin__c = lumpSumLine.Line_Amount__c - lumpSumLine.Line_Cost__c;
    }
    //recalculate lines on contract change 10.16.2020 >>
    //job task >>
}