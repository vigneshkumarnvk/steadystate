public with sharing class TMLLinesServiceImpl implements ITMLLinesService {

    public static Set<Id> resourceTypeIdSet = new Set<Id>();
    public static Set<Id> resourceIdSet = new Set<Id>();
    public static Set<Id> billToCustomerIdSet = new Set<Id> ();
    public static Set<Id> salesOrderIdSet = new Set<Id>();
    public static Set<Id> salesLineIdSet = new Set<Id>();
    public static Set<Id> contractLineIdSet = new Set<Id>();
    public static Set<Id> UOMIdSet = new Set<Id>();

    public static Company_Setup__c defaultCompanySetup = CompanyMgmt.getCompanySetup();
    public static Map<Id, Sales_Order__c> salesOrdersByIds = new Map<Id, Sales_Order__c>();
    public static Map<Id, Unit_of_Measure__c> unitOfMeasuresByIds = new Map<Id, Unit_of_Measure__c>();
    public static Map<Id, Service_Center__c> serviceCentersByIds = new Map<Id, Service_Center__c>();
    public static Map<Id, Map<Id, Map<Id, Sales_Line__c>>> salesLinesByUOMIdsByResOrTypeIdsBySalesOrderIds = new Map<Id, Map<Id, Map<Id, Sales_Line__c>>>();
    public static Map<Id, Sales_Line__c> salesLinesByIds = new Map<Id, Sales_Line__c>();
    //String Key = Sales Order Id:Res Id:Facility:Unit Weight Volume:Container Size
    //public static Map<String, Sales_Line__c> wasteSalesLinesBySalesOrderResFacilityUwvContainerSize = new Map<String, Sales_Line__c>();
    //String Key = Sales Order Id:Res Id:Unit of Measure Id:Facility
    public static Map<String, Sales_Line__c> wasteSalesLinesBySalesOrderResUomFacility = new Map<String, Sales_Line__c>();
    //String key = Description //Ticket#18075
    public static Map<String, Sales_Line__c> subContractLinesByDescription = new Map<String, Sales_Line__c>(); //Ticket#18075
    public static Map<Id, Map<Id, Pay_Rule_Line__c>> payRuleLineByResTypeIdsByPayRuleIds = new Map<Id, Map<Id, Pay_Rule_Line__c>>();
    public static Map<Id, Map<Id, ResourceTypeUOMAssociation__c>> resourceTypeUOMAssociationsByUOMIdsByResTypeIds = new Map<Id, Map<Id, ResourceTypeUOMAssociation__c>>();
    public static Map<Id, Map<Id, List<ResourceUOMAssociation__c>>> resourceUOMAssociationsByUOMIdsByResIds = new Map<Id, Map<Id, List<ResourceUOMAssociation__c>>>();
    public static Map<Date, Holiday__c> holidaysByDates = new Map<Date, Holiday__c>();
    public static Map<Id, Id> rateSheetIdsByPriceListIds = new Map<Id, Id>();
    public static Map<Id, List<Presumptive_Resource__c>> mapPresumptiveResourcesByParentId = new Map<Id, List<Presumptive_Resource__c>>();
    public static Map<Id, Boolean> mapHasSafetyPlanLineByOrderId = new Map<Id, Boolean>(); //duplicated safety plan lines issue >>


    public Map<Id, String> retrieveContractLinesTMDescription(List<TM_Line__c> theTMLList) {
        Map<Id, String> returnMap = new Map<Id, String>();
        Set<Id> idSet = new Set<Id>();
        for (TM_Line__c theTML : theTMLList) {
            if (theTML.Contract_Line__c != null) {
                idSet.add(theTML.Contract_Line__c);
            }
        }
        Map<Id, Contract_Line__c> contractLineRecords = ContractLinesSelector.newInstance().selectTMDescriptionById(idSet);
        for (TM_Line__c theTML : theTMLList) {
            if (theTML.Contract_Line__c != null) {
                returnMap.put(theTML.Id, contractLineRecords.get(theTML.Contract_Line__c).T_M_Description__c);
            }
        }
        return returnMap;
    }

    public void validateTMLinesResourceType(List<TM_Line__c> theTMLList) {
        if (theTMLList.size() == 0) {
            return;
        }

        Set<Id> tmlIds = new Set<Id>();
        for (TM_Line__c theTML : theTMLList) {
            if (theTML.Id != null) {
                tmlIds.add(theTML.Id);
            }
        }
        Map<Id, TM_Line__c> tmlsOrigin = TMLinesSelector.newInstance().selectTMLMapWithResourceTypeAndResourceById(tmlIds);

        List<TM_Line__c> changedTMLList = new List<TM_Line__c>();
        for (TM_Line__c theTML : theTMLList) {
            if (tmlsOrigin.containsKey(theTML.Id)) {
                if (theTML.Resource_Type__c != tmlsOrigin.get(theTML.Id).Resource_Type__c || theTML.Resource__c != tmlsOrigin.get(theTML.Id).Resource__c) {
                    changedTMLList.add(theTML);
                }
            } else {
                changedTMLList.add(theTML); //new TM Lines
            }
        }

        if (changedTMLList.size() == 0) {
            return;
        }

        updateTMLSalesLineValue(changedTMLList);
        updateTMLContractLineValue(changedTMLList);

        prepareStaticMaps(changedTMLList);
        ITMLines tmls = TMLines.newInstance(changedTMLList);
        tmls.updateTMLinesWhenResourceTypeChanged();
    }

    public void validateTMLinesUnitOfMeasure(List<TM_Line__c> theTMLList) {
        if (theTMLList.size() == 0) {
            return;
        }

        Set<Id> tmlIds = new Set<Id>();
        for (TM_Line__c theTML : theTMLList) {
            if (theTML.Id != null) {
                tmlIds.add(theTML.Id);
            }
        }
        Map<Id, TM_Line__c> tmlsOrigin = TMLinesSelector.newInstance().selectTMLMapWithUnitOfMeasureById(tmlIds);
        List<TM_Line__c> changedTMLList = new List<TM_Line__c>();
        for (TM_Line__c theTML : theTMLList) {
            if (tmlsOrigin.containsKey(theTML.Id)) {
                if (theTML.Unit_of_Measure__c != tmlsOrigin.get(theTML.Id).Unit_of_Measure__c) {
                    changedTMLList.add(theTML);
                }
            } else {
                changedTMLList.add(theTML); //new TM Lines
            }
        }

        if (changedTMLList.size() == 0) {
            return;
        }

        updateTMLSalesLineValue(changedTMLList);
        updateTMLContractLineValue(changedTMLList);

        prepareStaticMaps(changedTMLList);
        ITMLines tmls = TMLines.newInstance(changedTMLList);
        tmls.updateTMLinesWhenUnitOfMeasureChanged();
    }

    public void validateTMLinesRestOfFields(List<TM_Line__c> theTMLList) {
        if (theTMLList.size() == 0) return;
        prepareStaticMaps(theTMLList);
        ITMLines tmls = TMLines.newInstance(theTMLList);
        tmls.updateTMLinesRestOfFields();
    }

    public void prepareStaticMaps(List<TM_Line__c> theTMLList) {
        for (TM_Line__c theTML : theTMLList) {
            resourceTypeIdSet.add(theTML.Resource_Type__c);
            resourceIdSet.add(theTML.Resource__c);
            billToCustomerIdSet.add(theTML.TM__r.Bill_to_Customer__c);
            salesOrderIdSet.add(theTML.TM__r.Sales_Order__c);
            salesLineIdSet.add(theTML.Sales_Line__c);
            contractLineIdSet.add(theTML.Contract_Line__c);
            UOMIdSet.add(theTML.Unit_of_Measure__c);
        }
        TMLines.mapResourceTypes.putAll(ResourceTypesSelector.newInstance().selectById(resourceTypeIdSet));
        TMLines.mapResources.putAll(ResourcesSelector.newInstance().selectById(resourceIdSet));
        TMLines.mapSalesLines.putAll(SalesLinesSelector.newInstance().selectLinesById(salesLineIdSet));
        TMLines.mapContractLines.putAll(ContractLinesSelector.newInstance().selectById(contractLineIdSet));
        TMLines.mapAccounts.putAll(AccountsSelector.newInstance().selectById(billToCustomerIdSet));
        TMLines.mapSalesOrders.putAll(SalesOrdersSelector.newInstance().selectById(salesOrderIdSet));
        TMLines.mapUnitOfMeasures.putAll(UnitOfMeasuresSelector.newInstance().selectById(UOMIdSet));
    }

    // From Edit Billing page there be only one Sales Order. But we should assume T&M were from a list of sales orders for future use like processing TM
    public void updateTMLSalesLineValue(List<TM_Line__c> theTMLList) {
        Set<Id> salesOrderIdSet = new Set<Id>();
        for (TM_Line__c theTML : theTMLList) {
            //fix.001 << sales order should have higher priorty than sales quote
            /*
            if (theTML.TM__r.From_Sales_Quote__c == null) { // decision of finding sales line or quote line
                salesOrderIdSet.add(theTML.TM__r.Sales_Order__c);
            } else {
                salesOrderIdSet.add(theTML.TM__r.From_Sales_Quote__c);
            }
            */
            if (theTML.TM__r.Sales_Order__c != null) { // decision of finding sales line or quote line
                salesOrderIdSet.add(theTML.TM__r.Sales_Order__c);
            } else {
                salesOrderIdSet.add(theTML.TM__r.From_Sales_Quote__c);
            }
            //fix.001 >>

        }
        if (salesOrderIdSet.size() == 0) return;
        List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesBySalesOrderId(salesOrderIdSet);

        // Matching criteria: key = sales order + Category + Unit of Measure + (Resource Type[Labor, Equipment, Lump Sum] || Resource[Materials, Waste, Demurage, Misc,] || Description [SubContractor])
        Map<String, Id> mapping = new Map<String, Id>();
        for (Sales_Line__c salesLine : salesLines) {
            String mapKey = salesLine.Sales_Order__c + ':' + salesLine.Category__c + ':' + salesLine.Unit_of_Measure__c + ':';
            switch on salesLine.Category__c {
                when 'Labor', 'Equipment', 'Bundled' {
                    mapKey += salesLine.Resource_Type__c;
                }
                when 'Materials', 'Demurrage', 'Misc. Charges And Taxes', 'Waste Disposal' {
                    mapKey += salesLine.Resource__c;
                }
                when else {
                    mapKey += salesLine.Description__c;
                }
            }
            mapping.put(mapKey, salesLine.Id);
        }


        // Assign TML Sales_Order__c value if match
        for (TM_Line__c theTML : theTMLList) {
            String mapKey;

            //fix.001 << match key fields with sales order map key fields  From_Sales_Quote__c or Sales_Order__c
            /*
            switch on theTML.Category__c {
                when 'Labor', 'Equipment', 'Lump Sum' {
                    mapKey = theTML.TM__r.Sales_Order__c + ':' + theTML.Category__c + ':' + theTML.Unit_of_Measure__c
                            + ':' + theTML.Resource_Type__c;
                }
                when 'Materials', 'Demurrage', 'Misc. Charges And Taxes', 'Waste Disposal' {
                    mapKey = theTML.TM__r.Sales_Order__c + ':' + theTML.Category__c + ':' + theTML.Unit_of_Measure__c
                            + ':' + theTML.Resource__c;
                }
                when else {
                    mapKey = theTML.TM__r.Sales_Order__c + ':' + theTML.Category__c + ':' + theTML.Unit_of_Measure__c
                            + ':' + theTML.Description__c;
                }
            }
            */
            Id salesOrderId;
            if (theTML.TM__r.Sales_Order__c != null) {
                salesOrderId = theTML.TM__r.Sales_Order__c;
            } else {
                salesOrderId = theTML.TM__r.From_Sales_Quote__c;
            }

            switch on theTML.Category__c {
                when 'Labor', 'Equipment', 'Bundled' {
                    mapKey = salesOrderId + ':' + theTML.Category__c + ':' + theTML.Unit_of_Measure__c
                            + ':' + theTML.Resource_Type__c;
                }
                when 'Materials', 'Demurrage', 'Misc. Charges And Taxes', 'Waste Disposal' {
                    mapKey = salesOrderId + ':' + theTML.Category__c + ':' + theTML.Unit_of_Measure__c
                            + ':' + theTML.Resource__c;
                }
                when else {
                    mapKey = salesOrderId + ':' + theTML.Category__c + ':' + theTML.Unit_of_Measure__c
                            + ':' + theTML.Description__c;
                }
            }
            //fix.001 >>


            if (mapping.containsKey(mapKey)) {
                theTML.Sales_Line__c = mapping.get(mapKey);
            } else {
                theTML.Sales_Line__c = null;
            }
        }
    }

    public void updateTMLContractLineValue(List<TM_Line__c> theTMLList) {
        Set<Id> contractIdSet = new Set<Id>();
        for (TM_Line__c theTML : theTMLList) {
            contractIdSet.add(theTML.TM__r.Contract__c);
        }
        if (contractIdSet.size() == 0) return;
        List<Contract_Line__c> contractLines = ContractLinesSelector.newInstance().selectLinesByContractId(contractIdSet);

        // Matching criteria: sales order + Category + Unit of Measure + (Resource Type[Labor, Equipment, Lump Sum] || Resource[Materials, Waste, Demurage, Misc,] || Description [SubContractor])
        Map<String, Id> mapping = new Map<String, Id>();
        for (Contract_Line__c contractLine : contractLines) {
            String mapKey = '';
            if (String.isNotBlank(contractLine.Resource__c)) {
                mapKey = contractLine.Contract__c + ':' + contractLine.Resource__c + ':' + contractLine.Unit_of_Measure__c;
            } else {
                if (String.isNotBlank(contractLine.Resource_Type__c)) {
                    mapKey = contractLine.Contract__c + ':' + contractLine.Resource_Type__c + ':' + contractLine.Unit_of_Measure__c;
                }
            }
            if (mapKey != '') {
                mapping.put(mapKey, contractLine.Id);
            }
        }

        // Assign TML Contract_Line__c value if match
        for (TM_Line__c theTML : theTMLList) {
            String mapKey = '';
            switch on theTML.Category__c {
                when 'Labor', 'Equipment', 'Bundled' {
                    mapKey = theTML.TM__r.Contract__c + ':' + theTML.Resource_Type__c + ':' + theTML.Unit_of_Measure__c;
                }
                when 'Materials', 'Demurrage', 'Misc. Charges And Taxes', 'Waste Disposal' {
                    mapKey = theTML.TM__r.Contract__c + ':' + theTML.Resource__c + ':' + theTML.Unit_of_Measure__c;
                }
                when else {
                }
            }
            if (mapping.containsKey(mapKey)) {
                theTML.Contract_Line__c = mapping.get(mapKey);
            } else {
                theTML.Contract_Line__c = null;
            }
        }
    }

    public void populateLinesInfo(Map<TM__c, List<TM_Line__c>> tmLinesByTMs) {
        System.debug('Info# populateLinesInfo Begin: ');
        initStaticVariables(tmLinesByTMs);
        for (TM__c tm : tmLinesByTMs.keySet()) {
            List<TM_Line__c> tmLines = tmLinesByTMs.get(tm);
            for (TM_Line__c tmLine : tmLines) {
                if (isCalcBaseOnResType(tmLine.Category__c) == true) {
                    assignResourceTypeUOM(tmLine);
                } else {
                    assignResourceUOM(tmLine);
                }
                setDescription(tm, tmLine);
            }
        }
        System.debug('Info# populateLinesInfo End: ');
    }

    public void initStaticVariables(Map<TM__c, List<TM_Line__c>> tmLinesByTMs) {
        Set<Id> resIds = new Set<Id>();
        Set<Id> resTypeIds = new Set<Id>();
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> payRuleIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> uomIds = new Set<Id>();
        Set<Id> rateSheetIds = new Set<Id>();
        Set<Id> priceListIds = new Set<Id>();
        setServiceCenterByIdsMap();
        if (String.isNotBlank(defaultCompanySetup.Price_List__c)) {
            priceListIds.add(defaultCompanySetup.Price_List__c);
        }
        Date tmScheduledDate = null;
        for (TM__c tm : tmLinesByTMs.keySet()) {
            List<TM_Line__c> tmLines = tmLinesByTMs.get(tm);
            tmScheduledDate = tm.Scheduled_Date__c;
            for (TM_Line__c tmLine : tmLines) {
                if (isCalcBaseOnResType(tmLine.Category__c) == true){
                    if(tmLine.Resource_Type__c != null) {
                        resTypeIds.add(tmLine.Resource_Type__c);
                    }
                }
                if (isCalcBaseOnResType(tmLine.Category__c) == false && tmLine.Resource__c != null) {
                    resIds.add(tmLine.Resource__c);
                }

                if (tmLine.Unit_of_Measure__c != null) {
                    uomIds.add(tmLine.Unit_of_Measure__c);
                }
                if (tmLine.Resource__c != null) {
                    resIds.add(tmLine.Resource__c);
                }

                //Ticket18265
                if(String.isNotBlank(tm.Contract__c)){
                    contractIds.add(tm.Contract__c);
                }
            }

            if (tm.Sales_Order__c != null) {
                salesOrderIds.add(tm.Sales_Order__c);
            }
            if (tm.From_Sales_Quote__c != null) {
                salesOrderIds.add(tm.From_Sales_Quote__c);
            }

            if (serviceCentersByIds.containsKey(tm.Service_Center__c)) {
                Service_Center__c serviceCenter = serviceCentersByIds.get(tm.Service_Center__c);
                if (String.isNotBlank(serviceCenter.Price_List__c)) {
                    priceListIds.add(serviceCenter.Price_List__c);
                }
            }

            if (tm.Rate_Sheet__c != null) {
                rateSheetIds.add(tm.Rate_Sheet__c);
            }
        }

        //duplicated safety plan lines issue <<
        for (TM_Line__c tmLine : [SELECT Id, TM__r.Sales_Order__c FROM TM_Line__c WHERE TM__r.Sales_Order__c IN :salesOrderIds AND Category__c = 'Misc. Charges And Taxes' AND Resource__c = :defaultCompanySetup.Default_Safety_Plan_Resource__c AND TM__r.Status__c <> 'Void']) {
            mapHasSafetyPlanLineByOrderId.put(tmLine.TM__r.Sales_Order__c, true);
        }
        //duplicated safety plan lines issue >>

        //job task <<
        //19130 <<
        /*
        for (Resource_Type__c resourceType : [SELECT Id, (SELECT Id, Child_Resource_Type__c, Child_Resource__c, Child_Resource__r.Resource_Type__c, Child_Resource__r.Resource_Type__r.Name, Child_Unit_of_Measure__c, Child_Unit_of_Measure__r.Name FROM Parent_Resource_Types__r) FROM Resource_Type__c WHERE Id IN :resTypeIds]) {
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

        for (Resource__c resource : [SELECT Id, (SELECT Id, Child_Resource_Type__c, Child_Resource__c, Child_Resource__r.Resource_Type__c, Child_Resource__r.Resource_Type__r.Name, Child_Unit_of_Measure__c, Child_Unit_of_Measure__r.Name FROM Parent_Resources__r) FROM Resource__c WHERE Id IN :resIds]) {
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

        //safety plan line
        resIds.add(defaultCompanySetup.Default_Safety_Plan_Resource__c);
        resIds.add(CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c);
        uomIds.add(defaultCompanySetup.Default_Lump_Sum_Resource__r.Unit_of_Measure__c);
        resIds.add(defaultCompanySetup.Default_Subcontractor_Resource__c);
        resIds.add(defaultCompanySetup.Default_Manifest_Fee_Resource__c);
        //job task >>

        if (resIds.size() > 0) {
            ResourceService.setResourceMapsByIds(resIds);            
            uomIds.addAll(ResourceService.resourceUOMIds);
            for (Resource__c resource : ResourceService.resourcesByIds.values()) {
                if (resource.Pay_Rule__c != null) {
                    payRuleIds.add(resource.Pay_Rule__c);
                }
                if (resource.Resource_Type__c != null && resource.Category__c == 'Labor') {
                    resTypeIds.add(resource.Resource_Type__c);
                }
            }
        }

        if (salesOrderIds.size() > 0) {
            setSalesOrderByIdsMap(salesOrderIds);
            for (Sales_Order__c salesOrder : salesOrdersByIds.values()) {
                if (salesOrder.Pay_Rule__c != null) {
                    payRuleIds.add(salesOrder.Pay_Rule__c);
                }
                if (salesOrder.Contract__c != null) {
                    contractIds.add(salesOrder.Contract__c);
                }
            }
        }

        if (resTypeIds.size() > 0) {
            ResourceTypeUtil.setResourceTypeMapsByIds(resTypeIds);
            //job task << reactivate the code
            setResourceTypeUOMAssociationsByUOMIdsByResTypeIdsMap(resTypeIds);
            //replace by ResourceTypeUtil.resourceTypesByIds
            //resourceTypesByIds.putAll(ResourceTypesSelector.newInstance().selectById(resTypeIds));
            //job task >>
        }

        //job task <<
        if (resIds.size() > 0) {
            ResourceService.setResourceMapsByIds(resIds);
        }
        //job task >>

        if (uomIds.size() > 0) setUnitOfMeasureByIdsMap(uomIds);
        if (payRuleIds.size() > 0) setPayRuleLinesByResTypeIdsByPayRuleIdsMap(payRuleIds);
        if(contractIds.size() > 0) {
            ContractUtil.setContractLineByUOMIdsResOrTypeIdsByContractIdsMap(contractIds, tmScheduledDate);
        }
        if (salesOrderIds.size() > 0) setSalesLinesByResOrTypeIdsBySalesOrderIdsMap(salesOrderIds);
        //if (states.size() > 0) payrollTaxRateByState = PayrollTaxesSelector.newInstance().getPayrollTaxbyStatesMap(states);
        setHolidaysByIdsMap();

        rateSheetIdsByPriceListIds = PriceListSelector.newInstance().getActiveRateSheetIdByPricesListIdsAndWorkDate(priceListIds, tmScheduledDate);
        for (Id rateSheetId : rateSheetIdsByPriceListIds.values()) {
            rateSheetIds.add(rateSheetId);
        }

        if (rateSheetIds.size() > 0) {
            RateSheetService.setRateSheetLines(rateSheetIds);
            RateSheetService.setMap_RateSheetLinesByUOMByResTypeByRateSheet();
        }
    }

    public void calcUnitPrice(TM__c tm, TM_Line__c tmLine) {
        /*
        System.debug('Info# calcUnitPrice Begin');
        Id resOrTypeId = null;
        Boolean pricingInfoFound = false;
        Boolean isER = false;
        Boolean wasteLineSpecialTreatment = false;
        if(isCalcBaseOnResType(tmLine.Category__c) == true && tmLine.Resource_Type__c != null) {
            resOrTypeId = tmLine.Resource_Type__c;
        } else if(isCalcBaseOnResType(tmLine.Category__c) == false && tmLine.Resource__c != null) {
            resOrTypeId = tmLine.Resource__c;

            if(tmLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                if(resOrTypeId != defaultCompanySetup.Default_Waste_Disposal_Resource__c) {
                    if (String.isNotBlank(tmLine.Cost_Method__c)) {
                        wasteLineSpecialTreatment = true;
                    }
                }
            }
        }
        Service_Center__c serviceCenter = new Service_Center__c();
        if (serviceCentersByIds.containsKey(tm.Service_Center__c)) {
            serviceCenter = serviceCentersByIds.get(tm.Service_Center__c);
        }

        if (resOrTypeId != null) {
            Sales_Order__c salesOrder = salesOrdersByIds.get(tm.Sales_Order__c);
            if(tm.Sales_Order__c == null && tm.Emergency_TM__c == true){
                isER = true;
            } else if(String.isNotBlank(tm.Sales_Order__c)){
                isER = salesOrder.Emergency_Sales_Order__c;
            }

            //check sales lines
            if (tm.Sales_Order__c != null) {
                System.debug('Info: Sales Order Pricing');
                Sales_Line__c salesLine = new Sales_Line__c();
                if(wasteLineSpecialTreatment == true) {
                    salesLine = getWasteSalesLine(tm, tmLine, false);
                } else if (tmLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY){
                    salesLine = getSalesLineByLineDesc(tmLine.Description__c);
                } else {
                    salesLine = getSalesLine(tm.Sales_Order__c, resOrTypeId, tmLine.Unit_of_Measure__c);
                }

                if (String.isNotBlank(salesLine.Id)) {
                    tmLine.Sales_Line__c = salesLine.Id;
                    if (tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                        if(salesLine.Bill_as_Lump_Sum__c == true || salesLine.Non_Billable__c == true){
                            tmLine.Regular_Rate__c = salesLine.xRegular_Rate__c;
                            tmLine.Overtime_Rate__c = salesLine.xOvertime_Rate__c;
                            tmLine.Premium_Rate__c = salesLine.xPremium_Rate__c;
                        } else {
                            tmLine.Regular_Rate__c = salesLine.Regular_Rate__c;
                            tmLine.Overtime_Rate__c = salesLine.Overtime_Rate__c;
                            tmLine.Premium_Rate__c = salesLine.Premium_Rate__c;
                        }
                        calcLaborUnitPrice(tmLine);
                    } else {
                        if(salesLine.Bill_as_Lump_Sum__c == true || salesLine.Non_Billable__c == true) {
                            tmLine.Unit_Price__c = salesLine.xUnit_Price__c;
                        } else {
                            tmLine.Unit_Price__c = salesLine.Unit_Price__c;
                        }
                    }
                    tmLine.Pricing_Source_2__c = EnumUtil.PricingSource.SALES_ORDER.name();
                    if(String.isNotBlank(salesLine.Contract_Line__c)){
                        tmLine.Contract_Line__c = salesLine.Contract_Line__c;
                    }
                    pricingInfoFound = true;
                }
            }

            //check quote lines
            if (tm.From_Sales_Quote__c != null && pricingInfoFound == false) {
                System.debug('Info: Quote Pricing ' + pricingInfoFound);
                //Sales_Line__c quotedLine = getSalesLine(tm.From_Sales_Quote__c, resOrTypeId, tmLine.Unit_of_Measure__c);

                Sales_Line__c quotedLine = new Sales_Line__c();
                if(wasteLineSpecialTreatment == false) {
                    quotedLine = getSalesLine(tm.From_Sales_Quote__c, resOrTypeId, tmLine.Unit_of_Measure__c);
                } else {
                    quotedLine = getWasteSalesLine(tm, tmLine, true);
                }

                if (String.isNotBlank(quotedLine.Id)) {
                    tmLine.Sales_Line__c = quotedLine.Id;
                    if (tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                        tmLine.Regular_Rate__c = quotedLine.Regular_Rate__c;
                        tmLine.Overtime_Rate__c = quotedLine.Overtime_Rate__c;
                        tmLine.Premium_Rate__c = quotedLine.Premium_Rate__c;
                        calcLaborUnitPrice(tmLine);
                    } else {
                        if(quotedLine.Bill_as_Lump_Sum__c == true || quotedLine.Non_Billable__c == true){
                            tmLine.Unit_Price__c = quotedLine.xUnit_Price__c;
                        } else {
                            tmLine.Unit_Price__c = quotedLine.Unit_Price__c;
                        }
                    }
                    tmLine.Pricing_Source_2__c = EnumUtil.PricingSource.SALES_QUOTE.name();
                    if(String.isNotBlank(quotedLine.Contract_Line__c)){
                        tmLine.Contract_Line__c = quotedLine.Contract_Line__c;
                    }
                    pricingInfoFound = true;
                }
            }

            //check contract lines
            if(pricingInfoFound == false){
                //System.debug('Info: Contract Pricing ' + pricingInfoFound);
                Contract_Line__c contractLine = getContractLine(tm, tmLine);
                if (String.isBlank(contractLine.Id) == false) {
                    tmLine.Contract_Line__c = contractLine.Id;
                    tmLine.Contract_Regular_Rate__c = contractLine.Regular_Rate__c;
                    tmLine.Contract_Overtime_Rate__c = contractLine.Overtime_Rate__c;
                    tmLine.Contract_Premium_Rate__c = contractLine.Premium_Rate__c;
                    if (tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                        tmLine.Regular_Rate__c = contractLine.Regular_Rate__c;
                        tmLine.Overtime_Rate__c = contractLine.Overtime_Rate__c;
                        tmLine.Premium_Rate__c = contractLine.Premium_Rate__c;
                        calcLaborUnitPrice(tmLine);
                    } else {
                        tmLine.Unit_Price__c = contractLine.Regular_Rate__c;
                    }
                    tmLine.Pricing_Source_2__c = EnumUtil.PricingSource.CONTRACT.name();
                    tmLine.Contract_Line__c = contractLine.Id;
                    tmLine.Contract_Line__r = contractLine;
                    pricingInfoFound = true;
                }
            }

            //Rate Sheet pricing
            if (pricingInfoFound == false && String.isNotBlank(tm.Rate_Sheet__c)) {
                System.debug('Info: tm RateSheet Pricing begin ');
                Decimal unitPrice = 0;
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Pricing', tmLine, tm.Rate_Sheet__c);
                if(rateSheetLine != null && rateSheetLine.Id != null) {
                    tmLine.Min_Sell_Qty__c = CompanyMgmt.zeroIfNull(rateSheetLine.Min_Sell_Qty__c);
                }
                unitPrice = RateSheetService.getUnitPrice(rateSheetLine, isER);
                if (unitPrice > 0) {
                    if (tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                        tmLine.Regular_Rate__c = unitPrice;
                        tmLine.Overtime_Rate__c = unitPrice * 1.5;
                        tmLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(tmLine);
                    } else {
                        tmLine.Unit_Price__c = unitPrice;
                    }
                    tmLine.Pricing_Source_2__c = rateSheetLine.Rate_Sheet__r.Name;
                    pricingInfoFound = true;
                }
            }

            if (pricingInfoFound == false && String.isNotBlank(serviceCenter.Price_List__c)) {
                System.debug('Info: SC RateSheet Pricing begin ');
                Decimal unitPrice = 0;
                Id rateSheetId = null;
                if (rateSheetIdsByPriceListIds.containsKey(serviceCenter.Price_List__c)) {
                    rateSheetId = rateSheetIdsByPriceListIds.get(serviceCenter.Price_List__c);
                }
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Pricing', tmLine, rateSheetId);
                if (rateSheetLine != null && rateSheetLine.Id != null) {
                    tmLine.Min_Sell_Qty__c = CompanyMgmt.zeroIfNull(rateSheetLine.Min_Sell_Qty__c);
                }

                unitPrice = RateSheetService.getUnitPrice(rateSheetLine, isER);
                if (unitPrice > 0) {
                    if (tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                        tmLine.Regular_Rate__c = unitPrice;
                        tmLine.Overtime_Rate__c = unitPrice * 1.5;
                        tmLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(tmLine);
                    } else {
                        tmLine.Unit_Price__c = unitPrice;
                    }
                    tmLine.Pricing_Source_2__c = rateSheetLine.Rate_Sheet__r.Name;
                    pricingInfoFound = true;
                }
            }

            if (pricingInfoFound == false && String.isNotBlank(defaultCompanySetup.Price_List__c)) {
                System.debug('Info: Company RateSheet Pricing begin ');
                Decimal unitPrice = 0;
                Id rateSheetId = null;
                if (rateSheetIdsByPriceListIds.containsKey(defaultCompanySetup.Price_List__c)){
                    rateSheetId = rateSheetIdsByPriceListIds.get(defaultCompanySetup.Price_List__c);
                }
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Pricing', tmLine, rateSheetId);
                if (rateSheetLine != null && rateSheetLine.Id != null) {
                    tmLine.Min_Sell_Qty__c = CompanyMgmt.zeroIfNull(rateSheetLine.Min_Sell_Qty__c);
                }

                unitPrice = RateSheetService.getUnitPrice(rateSheetLine, isER);
                if (unitPrice > 0) {
                    if (tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                        tmLine.Regular_Rate__c = unitPrice;
                        tmLine.Overtime_Rate__c = unitPrice * 1.5;
                        tmLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(tmLine);
                    } else {
                        tmLine.Unit_Price__c = unitPrice;
                    }
                    tmLine.Pricing_Source_2__c = rateSheetLine.Rate_Sheet__r.Name;
                    pricingInfoFound = true;
                }
            }

            //standard rate
            if (pricingInfoFound == false) {
                System.debug('Info: Standard Pricing ');
                if (tmLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY && String.isNotBlank(tmLine.Cost_Method__c) == true) {
                    ResourceUOMAssociation__c wasteResUOMAssociation = getWasteResUOMSetup(tmLine);
                    if (wasteResUOMAssociation.Id != null) {
                        if(isER) {
                            tmLine.Unit_Price__c = wasteResUOMAssociation.ER_Unit_Price__c;
                        } else {
                            tmLine.Unit_Price__c = wasteResUOMAssociation.Unit_Price__c;
                        }
                        tmLine.Min_Sell_Qty__c = wasteResUOMAssociation.Min_Sell_Qty__c;
                    } else {
                        tmLine.Unit_Price__c = 0;
                        tmLine.Min_Sell_Qty__c = 0;
                    }
                } else {
                    Decimal unitPrice = getUnitPrice(tmLine.Category__c, resOrTypeId, tmLine.Unit_of_Measure__c, isER);
                    if (tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                        tmLine.Regular_Rate__c = unitPrice;
                        tmLine.Overtime_Rate__c = unitPrice * 1.5;
                        tmLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(tmLine);
                    } else {
                        tmLine.Unit_Price__c = unitPrice;
                    }
                }
                if (CompanyMgmt.zeroIfNull(tmLine.Unit_Price__c) > 0) {
                    tmLine.Pricing_Source_2__c = EnumUtil.PricingSource.BASE.name();
                }
            }

            //Handle Bill-as-Lump Sum or Non-Billable
            if(tmLine.Bill_as_Lump_Sum__c == true || tmLine.Non_Billable__c == true){
                if(tmLine.Category__c == ResourceService.LABOR_CATEGORY){
                    tmLine.xRegular_Rate__c = tmLine.Regular_Rate__c;
                    tmLine.xOvertime_Rate__c = tmLine.Overtime_Rate__c;
                    tmLine.xPremium_Rate__c = tmLine.Premium_Rate__c;
                    tmLine.Regular_Rate__c = 0;
                    tmLine.Overtime_Rate__c = 0;
                    tmLine.Premium_Rate__c = 0;
                }
                tmLine.xUnit_Price__c = tmLine.Unit_Price__c;
                tmLine.Unit_Price__c = 0;
            }
        }
        System.debug('Info# calcUnitPrice End');
         */
    }

    public void calcLaborUnitPrice(TM_Line__c tmLine) {
        /*
        if (tmLine.Category__c != ResourceService.LABOR_CATEGORY) {
            return;
        }
        if (!String.isBlank(tmLine.Unit_of_Measure__c)) {
            Unit_of_Measure__c unitOfMeasure = unitOfMeasuresByIds.get(tmLine.Unit_of_Measure__c);
            if (unitOfMeasure.Hours_UOM__c != true) {
                tmLine.Unit_Price__c = tmLine.Regular_Rate__c;
                return;
            }
        }

        //Calculate Unit Price
        Decimal totalHours = 0;
        Decimal totalPrice = 0;

        totalPrice = (CompanyMgmt.zeroIfNull(tmLine.Regular_Hours__c) * CompanyMgmt.zeroIfNull(tmLine.Regular_Rate__c)) +
                (CompanyMgmt.zeroIfNull(tmLine.Overtime_Hours__c) * CompanyMgmt.zeroIfNull(tmLine.Overtime_Rate__c)) +
                (CompanyMgmt.zeroIfNull(tmLine.Premium_Hours__c) * CompanyMgmt.zeroIfNull(tmLine.Premium_Rate__c));

        totalHours = CompanyMgmt.zeroIfNull(tmLine.Regular_Hours__c) + CompanyMgmt.zeroIfNull(tmLine.Overtime_Hours__c) +
                CompanyMgmt.zeroIfNull(tmLine.Premium_Hours__c);
        System.debug(totalHours + ' ' + totalPrice);
        if (totalHours != 0) {
            tmLine.Unit_Price__c = CompanyMgmt.halfUpTo5D(totalPrice / totalHours);
        } else {
            tmLine.Unit_Price__c = CompanyMgmt.zeroIfNull(tmLine.Regular_Rate__c);
        }
         */
    }

    public void calcUnitCost(TM__c tm, TM_Line__c tmLine) {
        /*
        String lineCategory = tmLine.Category__c;
        Boolean unitCostFound = false;
        Id resOrResTypeId = null;
        Decimal unitCost = 0;
        Sales_Order__c salesOrder = salesOrdersByIds.get(tm.Sales_Order__c);

        if (lineCategory == ResourceService.SUBCONTRACTORS_CATEGORY) {
            tmLine.Unit_Cost__c = tmLine.Unit_Price__c;
            return;
        }

        if (isCalcBaseOnResType(lineCategory) == true) {
            resOrResTypeId = tmLine.Resource_Type__c;
            //use resource resource type for unit cost calculation
            if (salesOrder != null && (String.isBlank(salesOrder.Pay_Rule__c) || salesOrder.Pay_Rule__r.Type__c != 'Prevailing Wage')) {
                if (String.isNotBlank(tmLine.Resource__c)) {
                    Resource__c resource = ResourceService.resourcesByIds.get(tmLine.Resource__c);
                    if (resource.Resource_Type__c != null) {
                        resOrResTypeId = resource.Resource_Type__c;
                    }
                }
            }
        } else if (isCalcBaseOnResType(lineCategory) == false && tmLine.Resource__c != null) {
            resOrResTypeId = tmLine.Resource__c;
        }

        if (resOrResTypeId != null) {
            System.debug('Info: resOrResTypeId ' + resOrResTypeId);
            Service_Center__c serviceCenter = new Service_Center__c();
            if (serviceCentersByIds.containsKey(tm.Service_Center__c)) {
                serviceCenter = serviceCentersByIds.get(tm.Service_Center__c);
            }

            if (salesOrder != null && isCalcBaseOnResType(lineCategory) == true && String.isNotBlank(salesOrder.Pay_Rule__c) && salesOrder.Pay_Rule__r.Type__c == 'Prevailing Wage') {
                System.debug('Info: PW Fringe BF ');
                Id payRuleId = salesOrder.Pay_Rule__c;
                if (lineCategory == 'Labor' && payRuleId != null && tm.Scheduled_Date__c != null) {
                    unitCost = getLaborCostWithFringeBenefitByResTypeAndRes(resOrResTypeId, payRuleId, tm.Service_Center__c, tm.Scheduled_Date__c);
                    //usePayRuleCost = true;
                    if (unitCost > 0) {
                        unitCostFound = true;
                    }
                }
                System.debug('Info: PW Fringe BF unitCost ' + unitCost);
            }

            //Use Sales Line Cost
            if(unitCostFound == false && salesOrder != null && tmLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                System.debug('Info: Waste Cost');
                //if(resOrResTypeId != defaultCompanySetup.Default_Waste_Disposal_Resource__c){
                Sales_Line__c salesLine = new Sales_Line__c();
                if(String.isBlank(tmLine.Cost_Method__c)){
                    System.debug('Info: Cost Method is blank');
                    salesLine = getSalesLine(salesOrder.Id, resOrResTypeId, tmLine.Unit_of_Measure__c);
                } else {
                    System.debug('Info: Cost Method is not blank');
                    salesLine = getWasteSalesLine(tm, tmLine, false);
                }
                System.debug('Info: salesLine found ' + salesLine);
                if(String.isNotBlank(salesLine.Id)){
                    if(CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c) > 0){
                        unitCost = salesLine.Unit_Cost__c;
                        unitCostFound = true;
                    }
                }
                //}
            }

            //TM Rate sheet
            if (unitCostFound == false && String.isNotBlank(tm.Rate_Sheet__c)) {
                System.debug('Info: TM Ratesheet Cost ');
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Costing', tmLine, tm.Rate_Sheet__c);
                unitCost = RateSheetService.getUnitCost(rateSheetLine);
                if (unitCost > 0) {
                    unitCostFound = true;
                }
                System.debug('Info: TM Ratesheet Cost unitCost ' + unitCost);
            }

            //SC Rate Sheet
            if (unitCostFound == false && String.isNotBlank(serviceCenter.Price_List__c)) {
                System.debug('Info: SC RateSheet Cost');
                Id rateSheetId = null;
                if (rateSheetIdsByPriceListIds.containsKey(serviceCenter.Price_List__c)) rateSheetId = rateSheetIdsByPriceListIds.get(serviceCenter.Price_List__c);
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Costing', tmLine, rateSheetId);
                unitCost = RateSheetService.getUnitCost(rateSheetLine);
                if (unitCost > 0) {
                    unitCostFound = true;
                }
                System.debug('Info: SC RateSheet Cost unitCost ' + unitCost);
            }

            //Company Default Rate Sheet
            if (unitCostFound == false && String.isNotBlank(defaultCompanySetup.Price_List__c)) {
                System.debug('Info: Company RateSheet Cost');
                Id rateSheetId = null;
                if (rateSheetIdsByPriceListIds.containsKey(defaultCompanySetup.Price_List__c)){
                    rateSheetId = rateSheetIdsByPriceListIds.get(defaultCompanySetup.Price_List__c);
                }
                System.debug('Info: rateSheetId ' + rateSheetId);
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Costing', tmLine, rateSheetId);
                System.debug('Info: rateSheetLine ' + rateSheetLine);
                unitCost = RateSheetService.getUnitCost(rateSheetLine);
                if (unitCost > 0) {
                    unitCostFound = true;
                }
                System.debug('Info: Company RateSheet Cost unitCost ' + unitCost);
            }

            if (unitCostFound == false) {
                System.debug('Info: default unit ');
                if (tmLine.Category__c == 'Waste Disposal' && String.isNotBlank(tmLine.Cost_Method__c)) {
                    ResourceUOMAssociation__c wasteResourceUOMAssociation = getWasteResUOMSetup(tmLine);
                    if (wasteResourceUOMAssociation.Id != null) {
                        unitCost = wasteResourceUOMAssociation.Unit_Cost__c;
                    }
                } else if (tmLine.Unit_of_Measure__c != null) {
                    unitCost = getUnitCost(tmLine.Category__c, resOrResTypeId, tmLine.Unit_of_Measure__c);
                }
                System.debug('Info: default unit cost ' + unitCost);
            }
        }

        tmLine.Unit_Cost__c = unitCost;
         */
    }

    /*
    public Decimal getUnitPrice(String category, Id resOrTypeId, Id uomId, Boolean isEmergency) {

        Decimal unitPrice = 0;
        if (isCalcBaseOnResType(category) == true) {
            unitPrice = ResourceTypeUtil.getUnitPrice(resOrTypeId, uomId, isEmergency);
        } else {
            unitPrice = ResourceService.getUnitPrice(resOrTypeId, uomId, isEmergency);
        }

        return unitPrice;
    }
     */

    /*
    public Decimal getLaborCostWithFringeBenefitByResTypeAndRes(Id resOrResTypeId, Id payRuleId, Id serviceCenterId, Date scheduleDate) {

        Decimal unitCost = 0;
        if (resOrResTypeId != null && payRuleId != null) {
            if (payRuleLineByResTypeIdsByPayRuleIds.containsKey(payRuleId)) {
                Pay_Rule_Line__c payRuleLine = new Pay_Rule_Line__c();
                if(payRuleLineByResTypeIdsByPayRuleIds.get(payRuleId).containsKey(resOrResTypeId)) {
                    payRuleLine = payRuleLineByResTypeIdsByPayRuleIds.get(payRuleId).get(resOrResTypeId);
                }

                String payCode = getPayrulePayCodeByDate(payRuleLine, scheduleDate);
                Decimal payRuleFringe = CompanyMgmt.zeroIfNull(payRuleLine.Fringe__c);
                Decimal payRateMultiplier = 1;

                if (payCode == EnumUtil.TimeRateCode.OT.name() || payCode == 'O/T') {
                    if (payRuleLine.Overtime_Rate_Multiple__c != null) payRateMultiplier = payRuleLine.Overtime_Rate_Multiple__c;
                    if (payRuleLine.OT_Fringe_Amount__c != null) payRuleFringe = payRuleLine.OT_Fringe_Amount__c;
                } else if (payCode == EnumUtil.TimeRateCode.DT.name()) {
                    if (payRuleLine.Double_Time_Rate_Multiple__c != null) payRateMultiplier = payRuleLine.Double_Time_Rate_Multiple__c;
                    if (payRuleLine.DT_Fringe_Amount__c != null) payRuleFringe = payRuleLine.DT_Fringe_Amount__c;
                }

                Decimal payRulePayRate = CompanyMgmt.zeroIfNull(payRuleLine.Rate__c) * payRateMultiplier;

                System.debug('Info: payRuleLine ' + payRuleLine);

                if (payRulePayRate > 0 || payRuleFringe > 0) {
                    Service_Center__c serviceCenter = serviceCentersByIds.get(serviceCenterId);
                    Decimal companyCompPct = CompanyMgmt.zeroIfNull(defaultCompanySetup.Workers_Comp_Pct__c) / 100;
                    Decimal corpOverHead = CompanyMgmt.zeroIfNull(defaultCompanySetup.Corporate_Overhead__c);
                    Decimal serviceCenterTaxRate = CompanyMgmt.zeroIfNull(serviceCenter.Payroll_Tax_Pct__c) / 100;
                    Decimal payrollTaxAmt = payRulePayRate * serviceCenterTaxRate;
                    Decimal workerCompAmt = payRulePayRate * companyCompPct;

                    Decimal resPayRateTotalAmt = 0;

                    resPayRateTotalAmt = payRulePayRate + corpOverHead + payrollTaxAmt + workerCompAmt;
                    unitCost = resPayRateTotalAmt + payRuleFringe;
                    System.debug('Info:unitCost ' + unitCost);
                }
            }
        }

        return unitCost;
    }
     */

    //Depreciated
    public Decimal getUnitCost(String category, Id resOrTypeId, Id uomId) {
        Decimal unitCost = 0;
        /*
        if (isCalcBaseOnResType(category) == true) {
            unitCost = ResourceTypeUtil.getUnitCost(resOrTypeId, uomId);
        } else {
            unitCost = ResourceService.getUnitCost(resOrTypeId, uomId);
        }
        System.debug('Info: getUnitCost ' + resOrTypeId + ' -- ' + unitCost);
         */
        return unitCost;
    }

    //Depreciated
    public void calcTotals(Map<TM__c, List<TM_Line__c>> tmLinesByTMs) {
        /*
        for (TM__c tm : tmLinesByTMs.keySet()) {
            for (TM_Line__c tmLine : tmLinesByTMs.get(tm)) {
                Decimal unitCost = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(tmLine.Unit_Cost__c));
                Decimal qty = CompanyMgmt.zeroIfNull(tmLine.Quantity__c);
                Decimal minSellQty = CompanyMgmt.zeroIfNull(tmLine.Min_Sell_Qty__c);
                Decimal unitPrice = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(tmLine.Unit_Price__c));
                Decimal markup = CompanyMgmt.zeroIfNull(tmLine.Markup__c);
                Decimal totalMarkupAmt = 0;
                Decimal costQty = CompanyMgmt.zeroIfNull(tmLine.Cost_Qty__c);
                Decimal taxRate = CompanyMgmt.getSalesTax(tm.Tax_Area__c, tmLine.Tax_Group__c); //W-000453

                if (tm.Tax_Liable__c && tmLine.Tax_Group__c != null) {
                    tmLine.Tax_Pct__c = taxRate;
                } else {
                    tmLine.Tax_Pct__c = 0;
                }

                tmLine.Line_Amount__c = unitPrice * qty;
                if (tmLine.Category__c == 'Waste Disposal' && minSellQty > qty) {
                    tmLine.Line_Amount__c = unitPrice * minSellQty;
                }

                tmLine.Line_Cost__c = unitCost * costQty;

                if (tmLine.Markup_Option__c == '%') {
                    totalMarkupAmt = tmLine.Line_Amount__c * markup / 100;
                }
                if (tmLine.Markup_Option__c == 'Amount') {
                    totalMarkupAmt = markup;
                }
                tmLine.Line_Amount__c += totalMarkupAmt;
                tmLine.Tax__c = CompanyMgmt.halfUpTo2D(tmLine.Line_Amount__c * CompanyMgmt.zeroIfNull(tmLine.Tax_Pct__c) / 100);
                tmLine.Line_Amt_Incl_Tax__c = tmLine.Line_Amount__c + tmLine.Tax__c;

            }
        }
         */
    }


    public Sales_Line__c getSalesLine(Id quoteId, Id resOrTypeId, Id uomId) {
        Sales_Line__c quotedLine = new Sales_Line__c();
        if (salesLinesByUOMIdsByResOrTypeIdsBySalesOrderIds.containsKey(quoteId)) {
            Map<Id, Map<Id, Sales_Line__c>> quoteLinesByUOMIdsByResOrTypeId = salesLinesByUOMIdsByResOrTypeIdsBySalesOrderIds.get(quoteId);
            if (quoteLinesByUOMIdsByResOrTypeId.containsKey(resOrTypeId)) {
                Map<Id, Sales_Line__c> quoteLinesByUOMId = quoteLinesByUOMIdsByResOrTypeId.get(resOrTypeId);
                if (quoteLinesByUOMId.containsKey(uomId)) {
                    quotedLine = quoteLinesByUOMId.get(uomId);
                }
            }
        }
        return quotedLine;
    }

    public Sales_Line__c getWasteSalesLine(TM__c tm, TM_Line__c tmLine, Boolean useQuoteIdAsLookupKey){
        Sales_Line__c salesLine = new Sales_Line__c();
        if(String.isNotBlank(tmLine.Sales_Line__c) && salesLinesByIds.containsKey(tmLine.Sales_Line__c)){
            salesLine = salesLinesByIds.get(tmLine.Sales_Line__c);
        } else {
            //Key = Sales Order Id:Res Id:Facility:Unit Weight Volume:Container Size
            String facilityId = 'null';
            if(String.isNotBlank(tmLine.Facility__c)){
                facilityId = tmLine.Facility__c;
            }
            String recordId = tm.Sales_Order__c;
            if(useQuoteIdAsLookupKey == true){
                recordId = tm.From_Sales_Quote__c;
            }
            String lookupKey = recordId + ':' + tmLine.Resource__c + ':' + tmLine.Unit_of_Measure__c + ':' + facilityId;
            if(wasteSalesLinesBySalesOrderResUomFacility.containsKey(lookupKey)){
                salesLine = wasteSalesLinesBySalesOrderResUomFacility.get(lookupKey);
            }
        }
        return salesLine;
    }

    /*
        Ticket#18075
        For subcontractor line allow to match T&M Line with Sales Line by line description.
    */
    public Sales_Line__c getSalesLineByLineDesc(String lineDescription){
        Sales_Line__c salesLine = new Sales_Line__c();
        if(String.isNotBlank(lineDescription)){
            lineDescription = lineDescription.trim();
            if(subContractLinesByDescription.containsKey(lineDescription) == true){
                salesLine = subContractLinesByDescription.get(lineDescription);
            }
        }
        return salesLine;
    }

    public Contract_Line__c getContractLine(Id contractId, Id resOrTypeId, Id uomId) {
        Contract_Line__c contractLine = new Contract_Line__c();
        if(ContractUtil.contractLineByUOMIdsResOrTypeIdsByContractIds.containsKey(contractId)){
            Map<Id, Map<Id, Contract_Line__c>> contractLineByUOMIdsByResTypeId = ContractUtil.contractLineByUOMIdsResOrTypeIdsByContractIds.get(contractId);
            if (contractLineByUOMIdsByResTypeId.containsKey(resOrTypeId)) {
                Map<Id, Contract_Line__c> contractLinesByUOMIds = contractLineByUOMIdsByResTypeId.get(resOrTypeId);
                if (contractLinesByUOMIds.containsKey(uomId)) contractLine = contractLinesByUOMIds.get(uomId);
            }
        }
        return contractLine;
    }

    public ResourceUOMAssociation__c getWasteResUOMSetup(TM_Line__c tmLine) {
        return ResourceService.getWasteResUOMSetup(tmLine.Resource__c, tmLine.Unit_of_Measure__c, tmLine.Facility__c);
    }

    public void assignResourceTypeUOM(TM_Line__c tmLine) {
        if (isCalcBaseOnResType(tmLine.Category__c) == true && tmLine.Resource_Type__c != null && tmLine.Unit_of_Measure__c != null) {
            ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = ResourceTypeUtil.getResourceTypeUOMAssociation(tmLine.Resource_Type__c, tmLine.Unit_of_Measure__c);
            if(resourceTypeUOMAssociation.Id != null){
                tmLine.Resource_Type_UOM__c = resourceTypeUOMAssociation.Id;
            }
        }
    }

    public void assignResourceUOM(TM_Line__c tmLine) {
        if (isCalcBaseOnResType(tmLine.Category__c) == false && tmLine.Resource__c != null && tmLine.Unit_of_Measure__c != null) {
            ResourceUOMAssociation__c resourceUOMAssociation = new ResourceUOMAssociation__c();
            if (tmLine.Category__c == 'Waste Disposal' && String.isNotBlank(tmLine.Facility__c)) {
                resourceUOMAssociation = getWasteResUOMSetup(tmLine);
            } else {
                resourceUOMAssociation = ResourceService.getResourceUOMAssociation(tmLine.Resource__c, tmLine.Unit_of_Measure__c);
            }
            if(resourceUOMAssociation.Id != null){
                tmLine.Resource_UOM__c = resourceUOMAssociation.Id;
            }
        }
    }

    public void setSalesOrderByIdsMap(Set<Id> salesOrdIds) {
        salesOrdersByIds.putAll(SalesOrdersSelector.newInstance().selectById(salesOrdIds));
    }

    public void setUnitOfMeasureByIdsMap(Set<Id> uomIds) {
        unitOfMeasuresByIds.putAll(UnitOfMeasuresSelector.newInstance().selectById(uomIds));
    }

    public void setServiceCenterByIdsMap() {
        serviceCentersByIds.putAll(ServiceCentersSelector.newInstance().selectAll());
    }

    public void setPayRuleLinesByResTypeIdsByPayRuleIdsMap(Set<Id> payRuleIds) {
        List<Pay_Rule__c> payRules = PayRulesSelector.newInstance().selectPayRulesByIdWithLines(payRuleIds);
        for (Pay_Rule__c payRule : payRules) {
            Map<Id, Pay_Rule_Line__c> payRuleLineByResTypeIds = new Map<Id, Pay_Rule_Line__c>();
            for (Pay_Rule_Line__c payRuleLine : payRule.Pay_Rule_Lines__r) {
                payRuleLineByResTypeIds.put(payRuleLine.Resource_Type__c, payRuleLine);
            }
            payRuleLineByResTypeIdsByPayRuleIds.put(payRule.Id, payRuleLineByResTypeIds);
        }
    }

    public void setSalesLinesByResOrTypeIdsBySalesOrderIdsMap(Set<Id> salesOrderIds) {
        List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesBySalesOrderId(salesOrderIds);
        for (Sales_Line__c salesLine : salesLines) {
            //DE37333: Salesforce - Not able to Change the UOM in T&M for Indirect Disposal Method
            //Since the loop has continue statement to fill wasteSalesLinesBySalesOrderResUomFacility Map
            //salesLinesByIds Map is not filled correctly so moved it to above.
            salesLinesByIds.put(salesLine.Id, salesLine);
            Map<Id, Map<Id, Sales_Line__c>> quoteLinesByUOMIdsByResOrTypeIds = new Map<Id, Map<Id, Sales_Line__c>>();
            Map<Id, Sales_Line__c> salesLinesByUOMIds = new Map<Id, Sales_Line__c>();
            if (salesLinesByUOMIdsByResOrTypeIdsBySalesOrderIds.containsKey(salesLine.Sales_Order__c)) {
                quoteLinesByUOMIdsByResOrTypeIds = salesLinesByUOMIdsByResOrTypeIdsBySalesOrderIds.get(salesLine.Sales_Order__c);
            }

            if (isCalcBaseOnResType(salesLine.Category__c) == true &&
                    salesLine.Resource_Type__c != null &&
                    quoteLinesByUOMIdsByResOrTypeIds.containsKey(salesLine.Resource_Type__c))
            {
                salesLinesByUOMIds = quoteLinesByUOMIdsByResOrTypeIds.get(salesLine.Resource_Type__c);
            } else if(isCalcBaseOnResType(salesLine.Category__c) == false &&
                    salesLine.Resource__c != null &&
                    quoteLinesByUOMIdsByResOrTypeIds.containsKey(salesLine.Resource__c)) {
                salesLinesByUOMIds = quoteLinesByUOMIdsByResOrTypeIds.get(salesLine.Resource__c);
            }

            salesLinesByUOMIds.put(salesLine.Unit_of_Measure__c, salesLine);

            if(isCalcBaseOnResType(salesLine.Category__c) == true && salesLine.Resource_Type__c != null) {
                quoteLinesByUOMIdsByResOrTypeIds.put(salesLine.Resource_Type__c, salesLinesByUOMIds);
            } else if(isCalcBaseOnResType(salesLine.Category__c) == false && salesLine.Resource__c != null) {
                quoteLinesByUOMIdsByResOrTypeIds.put(salesLine.Resource__c, salesLinesByUOMIds);
            }

            salesLinesByUOMIdsByResOrTypeIdsBySalesOrderIds.put(salesLine.Sales_Order__c, quoteLinesByUOMIdsByResOrTypeIds);

            if(salesLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY && String.isNotBlank(salesLine.Resource__c)){
                String mapKey =  salesLine.Sales_Order__c + ':' + salesLine.Resource__c + ':' + salesLine.Unit_of_Measure__c + ':' + salesLine.Facility__c;
                if(wasteSalesLinesBySalesOrderResUomFacility.containsKey(mapKey)){
                    continue;
                } else {
                    wasteSalesLinesBySalesOrderResUomFacility.put(mapKey, salesLine);
                }
            }

            //Ticket#18075
            if(salesLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY && String.isNotBlank(salesLine.Description__c)){
                String lineDesc = salesLine.Description__c.trim();
                if(subContractLinesByDescription.containsKey(lineDesc) == false){
                    subContractLinesByDescription.put(lineDesc, salesLine);
                }
            }
        }
    }

    public void setResourceTypeUOMAssociationsByUOMIdsByResTypeIdsMap(Set<Id> resTypeIds) {
        List<ResourceTypeUOMAssociation__c> resourceTypeUOMAssociations =
                ResourceTypeUnitOfMeasuresSelector.newInstance().selectByResTypeId(resTypeIds);
        for (ResourceTypeUOMAssociation__c resourceTypeUOMAssociation : resourceTypeUOMAssociations) {
            Map<Id, ResourceTypeUOMAssociation__c> resourceTypeUOMAssociationsByUOMIds = new Map<Id, ResourceTypeUOMAssociation__c>();
            if (resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(resourceTypeUOMAssociation.Resource_Type__c)) {
                resourceTypeUOMAssociationsByUOMIds = resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(resourceTypeUOMAssociation.Resource_Type__c);
            }
            resourceTypeUOMAssociationsByUOMIds.put(resourceTypeUOMAssociation.Unit_of_Measure__c, resourceTypeUOMAssociation);
            resourceTypeUOMAssociationsByUOMIdsByResTypeIds.put(resourceTypeUOMAssociation.Resource_Type__c, resourceTypeUOMAssociationsByUOMIds);
        }
    }

    /*
    public void setResourceUOMAssociationsByUOMIdsByResIds(Set<Id> resIds) {
        List<ResourceUOMAssociation__c> resourceUOMAssociations = ResourceUnitOfMeasuresSelector.newInstance().selectByResId(resIds);
        for (ResourceUOMAssociation__c resourceUOMAssociation : resourceUOMAssociations) {
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
    }
     */

    public void setHolidaysByIdsMap() {
        holidaysByDates = HolidaysSelector.newInstance().getHolidaysByDates();
    }

    public Boolean isCalcBaseOnResType(String lineCategory) {
        if(lineCategory == ResourceService.LABOR_CATEGORY || lineCategory == ResourceService.EQUIPMENT_CATEGORY || lineCategory == ResourceService.LUMP_SUM_CATEGORY) {
            return true;
        } else {
            return  false;
        }
    }

    public Id getResOrResTypeId(TM_Line__c tmLine){
        if (isCalcBaseOnResType(tmLine.Category__c) == true) {
            return tmLine.Resource_Type__c;
        } else {
            return tmLine.Resource__c;
        }
    }

    //Depreciated
    public Rate_Sheet_Line__c getRateSheetLine(String useForType, TM_Line__c tmLine, Id rateSheetId) {
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        /*
        if (rateSheetId != null) {
            if (tmLine.Category__c == 'Waste Disposal') {
                Id lookupUOMId = null;
                if (tmLine.Category__c != 'Waste Disposal') return null;
                if (tmLine.Resource__c == null || tmLine.Cost_Method__c == null) return null;
                if (tmLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) lookupUOMId = tmLine.Unit_Weight_Vol__c;
                if (tmLine.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name()) lookupUOMId = tmLine.Container_Size__c;
                rateSheetLine = RateSheetService.getWasteRateSheetLine(rateSheetId,
                        tmLine.Resource__c, tmLine.Cost_Method__c,
                        lookupUOMId, tmLine.Facility__c, tmLine.Container_Size__c);
            } else {
                Id resOrTypeId = null;
                if (isCalcBaseOnResType(tmLine.Category__c) == true) {
                    if (String.isNotBlank(tmLine.Resource_Type__c)) {
                        resOrTypeId = tmLine.Resource_Type__c;
                    }

                    if (useForType == 'Costing') {
                        if (String.isNotBlank(tmLine.Resource__c)) {
                            //Resource__c res = resourcesByIds.get(tmLine.Resource__c);
                            Resource__c res = ResourceService.resourcesByIds.get(tmLine.Resource__c);
                            if (String.isNotBlank(res.Resource_Type__c)) {
                                resOrTypeId = res.Resource_Type__c;
                            }
                        }
                    }
                } else if (isCalcBaseOnResType(tmLine.Category__c) == false && String.isNotBlank(tmLine.Resource__c)) {
                    resOrTypeId = tmLine.Resource__c;
                }
                rateSheetLine = RateSheetService.getRateSheetLine(rateSheetId, resOrTypeId, tmLine.Unit_of_Measure__c);
            }
        }
         */
        return rateSheetLine;
    }

    //Depreciated
    public void calcLineCost(Map<TM__c, List<TM_Line__c>> tmLinesByTMs) {
        /*
        initStaticVariables(tmLinesByTMs);
        for (TM__c tm : tmLinesByTMs.keySet()) {
            List<TM_Line__c> tmLines = tmLinesByTMs.get(tm);
            for (TM_Line__c tmLine : tmLines) {
                calcUnitCost(tm, tmLine);
                calcTotals(tmLinesByTMs);
            }
        }
         */
    }

    //Depreciated
    public void calcLineTotals(TM__c tm, TM_Line__c tmLine) {
        /*
        Decimal unitCost = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(tmLine.Unit_Cost__c));
        Decimal qty = CompanyMgmt.zeroIfNull(tmLine.Quantity__c);
        Decimal minSellQty = CompanyMgmt.zeroIfNull(tmLine.Min_Sell_Qty__c);
        Decimal unitPrice = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(tmLine.Unit_Price__c));
        Decimal markup = CompanyMgmt.zeroIfNull(tmLine.Markup__c);
        Decimal totalMarkupAmt = 0;
        Decimal costQty = CompanyMgmt.zeroIfNull(tmLine.Cost_Qty__c);
        Decimal taxRate = CompanyMgmt.getSalesTax(tm.Tax_Area__c, tmLine.Tax_Group__c); //W-000453

        if (tm.Tax_Liable__c && tmLine.Tax_Group__c != null) {
            tmLine.Tax_Pct__c = taxRate;
        } else {
            tmLine.Tax_Pct__c = 0;
        }

        tmLine.Line_Amount__c = unitPrice * qty;
        if (tmLine.Category__c == 'Waste Disposal' && minSellQty > qty) {
            tmLine.Line_Amount__c = unitPrice * minSellQty;
        }

        tmLine.Line_Cost__c = unitCost * costQty;

        if (tmLine.Markup_Option__c == '%') {
            totalMarkupAmt = tmLine.Line_Amount__c * markup / 100;
        }
        if (tmLine.Markup_Option__c == 'Amount') {
            totalMarkupAmt = markup;
        }
        tmLine.Line_Amount__c += totalMarkupAmt;
        tmLine.Tax__c = CompanyMgmt.halfUpTo2D(tmLine.Line_Amount__c * CompanyMgmt.zeroIfNull(tmLine.Tax_Pct__c) / 100);
        tmLine.Line_Amt_Incl_Tax__c = tmLine.Line_Amount__c + tmLine.Tax__c;
         */
    }

    public void validateResourceType(TM__c tm, TM_Line__c tmLine){
        Resource_Type__c resourceType = ResourceTypeUtil.getResourceType(tmLine.Resource_Type__c);
        tmLine.Contract_Line__c = null;
        tmLine.Sales_Line__c = null;
        tmLine.Unit_of_Measure__c = null;
        tmLine.Unit_of_Measure__r = null;
        if(String.isNotBlank(resourceType.Id)){
            tmLine.Resource_Type__r = resourceType;
            this.assignContractLine(tm, tmLine);
            if (tmLine.Contract_Line__c == null) {
                tmLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
                tmLine.Unit_of_Measure__r = resourceType.Unit_of_Measure__r;
            }
            if (tmLine.Category__c == ResourceService.LABOR_CATEGORY || tmLine.Category__c == ResourceService.EQUIPMENT_CATEGORY) {
                if (unitOfMeasuresByIds.containsKey(tmLine.Unit_of_Measure__c)) {
                    Unit_of_Measure__c unitOfMeasure = unitOfMeasuresByIds.get(tmLine.Unit_of_Measure__c);
                    if (unitOfMeasure.Hours_UOM__c != true) {
                        tmLine.Quantity__c = 1;
                    }
                }
            }
            setDescription(tm, tmLine);
        }
    }

    public void validateResource(TM__c tm, TM_Line__c tmLine){
        Resource__c resource = ResourceService.getResource(tmLine.Resource__c);
        if(isCalcBaseOnResType(tmLine.Category__c) == false){
            tmLine.Contract_Line__c = null;
            tmLine.Sales_Line__c = null;
            tmLine.Unit_of_Measure__c = null;
            tmLine.Unit_of_Measure__r = null;
            if(String.isNotBlank(resource.Id)){
                tmLine.Resource__r = resource;
                this.assignContractLine(tm, tmLine);
                if (tmLine.Contract_Line__c == null) {
                    tmLine.Unit_of_Measure__c = resource.Unit_of_Measure__c;
                    tmLine.Unit_of_Measure__r = resource.Unit_of_Measure__r;
                }
                if(tmLine.Category__c == ResourceService.LABOR_CATEGORY || tmLine.Category__c == ResourceService.EQUIPMENT_CATEGORY){
                    if(unitOfMeasuresByIds.containsKey(tmLine.Unit_of_Measure__c)){
                        Unit_of_Measure__c unitOfMeasure = unitOfMeasuresByIds.get(tmLine.Unit_of_Measure__c);
                        if(unitOfMeasure.Hours_UOM__c != true){
                            tmLine.Quantity__c = 1;
                        }
                    }
                }
                setDescription(tm, tmLine);
            }
        } else {
            //Ticket#20410 >>
            this.assignContractLine(tm, tmLine);
            setDescription(tm, tmLine);
            //Ticket#20410 <<
        }
    }

    public void validateUnitOfMeasure(TM__c tm, TM_Line__c tmLine) {
        this.assignContractLine(tm, tmLine);
        this.setDescription(tm, tmLine);
    }

    public void assignContractLine(TM__c tm, TM_Line__c tmLine) {
        if (tm.Contract__c != null) {
            Contract_Line__c contractLine;
            if (tmLine.Contract_Line__c != null) {
                contractLine = ContractUtil.getContractLine(tmLine.Contract_Line__c);
            }
            else {
                Id resOrTypeId = getResOrResTypeId(tmLine);
                if (ContractUtil.contractLineByUOMIdsResOrTypeIdsByContractIds.containsKey(tm.Contract__c)) {
                    Map<Id, Map<Id, Contract_Line__c>> mapContractLinesByUOMIdsByResOrTypeIds = ContractUtil.contractLineByUOMIdsResOrTypeIdsByContractIds.get(tm.Contract__c);
                    if (mapContractLinesByUOMIdsByResOrTypeIds.containsKey(resOrTypeId)) {
                        Map<Id, Contract_Line__c> mapContractLinesByUOMIds = mapContractLinesByUOMIdsByResOrTypeIds.get(resOrTypeId);
                        if (tmLine.Unit_of_Measure__c != null) {
                            contractLine = mapContractLinesByUOMIds.get(tmLine.Unit_of_Measure__c);
                        }
                        else {
                            for (Contract_Line__c contractLine2 : mapContractLinesByUOMIds.values()) {
                                contractLine = contractLine2;
                                break;
                            }
                        }
                    }
                }
            }
            if (contractLine != null) {
                tmLine.Unit_of_Measure__c = contractLine.Unit_of_Measure__c;
                tmLine.Unit_of_Measure__r = contractLine.Unit_of_Measure__r;
                tmLine.Contract_Line__c = contractLine.Id;
                //Ticket#24869 tmLine.Contract_Line__r = new Contract_Line__c(Id = contractLine.Id, Name = contractLine.Name); 
            }
        }
    }

    //Ticket#18265
    public void validateContractLine(TM__c tm, TM_Line__c tmLine){
        if(String.isNotBlank(tmLine.Contract_Line__c)){
            Contract_Line__c contractLine = ContractUtil.getContractLine(tmLine.Contract_Line__c);
            Unit_of_Measure__c unitOfMeasure = new Unit_of_Measure__c();
            if(unitOfMeasuresByIds.containsKey(contractLine.Unit_of_Measure__c)){
                unitOfMeasure = unitOfMeasuresByIds.get(contractLine.Unit_of_Measure__c);
            } else {
                unitOfMeasure = [SELECT Id, Name FROM Unit_of_Measure__c WHERE Id = :contractLine.Unit_of_Measure__c LIMIT 1];
            }
            if(isCalcBaseOnResType(tmLine.Category__c)){
                if(String.isBlank(tmLine.Resource_Type__c)){
                    tmLine.Resource_Type__c = contractLine.Resource_Type__c;
                    Resource_Type__c resourceType = new Resource_Type__c();
                    if(ResourceTypeUtil.resourceTypesByIds.containsKey(contractLine.Resource_Type__c)){
                        resourceType = ResourceTypeUtil.getResourceType(contractLine.Resource_Type__c);
                    } else {
                        resourceType = [SELECT Id, Name FROM Resource_Type__c WHERE Id = :contractLine.Resource_Type__c LIMIT 1];
                    }
                    tmLine.Resource_Type__r = resourceType;
                    tmLine.Unit_of_Measure__c = contractLine.Unit_of_Measure__c;
                    tmLine.Unit_of_Measure__r = unitOfMeasure;
                }
            } else {
                if(String.isBlank(tmLine.Resource__c)){
                    tmLine.Resource__c = contractLine.Resource__c;
                    Resource__c resource = new Resource__c();
                    if(ResourceService.resourcesByIds.containsKey(contractLine.Resource__c)){
                        resource = ResourceService.getResource(contractLine.Resource__c);
                    } else {
                        resource = [SELECT Id, Name FROM Resource__c WHERE Id = :contractLine.Resource__c LIMIT 1];
                    }
                    tmLine.Resource__r = resource;
                    tmLine.Unit_of_Measure__c = contractLine.Unit_of_Measure__c;
                    tmLine.Unit_of_Measure__r = unitOfMeasure;
                }
            }
            tmLine.Contract_Line__r = contractLine;
        } else {
            tmLine.Contract_Line__c = null;
            tmLine.Sales_Line__c = null;
        }

        setDescription(tm, tmLine);
    }

    public void setDescription(TM__c tm, TM_Line__c tmLine){
        Boolean contractLineDescriptionFound = false;
        if(String.isNotBlank(tm.Contract__c) && tmLine.Contract_Line__c != null) {
            Contract_Line__c contractLine = ContractUtil.getContractLine(tmLine.Contract_Line__c);
            if (String.isNotBlank(contractLine.Customer_Description__c)) {
                tmLine.Description__c = contractLine.Customer_Description__c;
                contractLineDescriptionFound = true;
            }
        }

        if (!contractLineDescriptionFound) {
            Id resOrResTypeId = getResOrResTypeId(tmLine);
            Boolean salesLineDescriptionFound = false;
            Sales_Line__c salesLine = new Sales_Line__c();
            if (tmLine.Sales_Line__c != null) {
                salesLine = salesLinesByIds.get(tmLine.Sales_Line__c);
            }

            if (String.isBlank(salesLine.Id)) {
                if (tmLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY) {
                    salesLine = getWasteSalesLine(tm, tmLine, false);
                } else if (tmLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY) {
                    salesLine = getSalesLineByLineDesc(tmLine.Description__c);
                } else {
                    salesLine = getSalesLine(tm.Sales_Order__c, resOrResTypeId, tmLine.Unit_of_Measure__c);
                }
            }
            //DE37326
            if (String.isNotBlank(salesLine.Id) && tmLine.Profile_Id__c == salesLine.Profile_Id__c) {
                tmLine.Description__c = salesLine.Description__c;
                salesLineDescriptionFound = true;
            }
            //DE37326
            if(salesLineDescriptionFound == false && tmLine.Profile_Id__c == Null) {
                if (isCalcBaseOnResType(tmLine.Category__c)) {
                    Resource_Type__c resourceType = ResourceTypeUtil.getResourceType(tmLine.Resource_Type__c);
                    if (String.isNotBlank(resourceType.Id)) {
                        tmLine.Description__c = resourceType.Description__c;
                    }
                } else {
                    if (ResourceService.resourcesByIds.containsKey(resOrResTypeId)) {
                        Resource__c resource = ResourceService.resourcesByIds.get(resOrResTypeId);
                        if (String.isNotBlank(resource.Description__c)) {
                            tmLine.Description__c = resource.Description__c;
                        }
                    }
                }
            }
        }
    }

    public Contract_Line__c getContractLine(TM__c tm, TM_Line__c tmLine){
        Contract_Line__c contractLine = new Contract_Line__c();
        if (String.isNotBlank(tmLine.Contract_Line__c)){
            contractLine = ContractUtil.getContractLine(tmLine.Contract_Line__c);
        }

        if (String.isBlank(contractLine.Id) && String.isNotBlank(tm.Contract__c)) {
            Id resOrTypeId = getResOrResTypeId(tmLine);
            Id uomId = tmLine.Unit_of_Measure__c;
            if (tmLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY) {
                contractLine = ContractUtil.getContractLine(tm.Contract__c, resOrTypeId, uomId, tmLine.Facility__c);
            } else {
                contractLine = ContractUtil.getContractLine(tm.Contract__c, resOrTypeId, uomId);
            }
        }
        return contractLine;
    }

    //ticket 19130 05.13.2023 <<
    /*
    public List<TM_Line__c> calculatePresumptiveChildLines(TM__c tm, TM_Job_Task__c jobTask, TM_Line__c parentLine, Integer nextTMLineNo) {
        List<TM_Line__c> childLines = new List<TM_Line__c>();
        if (mapPresumptiveResourcesByParentId.containsKey(parentLine.Resource_Type__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(parentLine.Resource_Type__c);
            childLines = insertPresumptiveChildLines(tm, jobTask, parentLine, presumptiveResources, nextTMLineNo);
        } else if (mapPresumptiveResourcesByParentId.containsKey(parentLine.Resource__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(parentLine.Resource__c);
            childLines = insertPresumptiveChildLines(tm, jobTask, parentLine, presumptiveResources, nextTMLineNo);
        }
        return childLines;
    }

    private List<TM_Line__c> insertPresumptiveChildLines(TM__c tm, TM_Job_Task__c jobTask, TM_Line__c parentLine, List<Presumptive_Resource__c> presumptiveResources, Integer nextTMLineNo) {
        List<TM_Line__c> tmLines = new List<TM_Line__c>();
        for (Presumptive_Resource__c presumptiveResource : presumptiveResources) {
            if (presumptiveResource.Child_Resource_Type__c != null || presumptiveResource.Child_Resource__c != null) {
                TM_Line__c tmLine = new TM_Line__c();
                tmLine.Line_No__c = nextTMLineNo;
                tmLine.TM__c = tm.Id;
                tmLine.TM_Job_Task__c = jobTask.Id;
                tmLine.TM_Job_Task__r = jobTask;

                if (presumptiveResource.Child_Resource_Type__c != null && ResourceTypeUtil.resourceTypesByIds.containsKey(presumptiveResource.Child_Resource_Type__c)) {
                    Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource_Type__c);
                    tmLine.Category__c = resourceType.Category__c;
                    tmLine.Resource_Type__c = resourceType.Id;
                    tmLine.Resource_Type__r = resourceType;
                    tmLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                    tmLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                    tmLine.Description__c = resourceType.Description__c;
                } else if (presumptiveResource.Child_Resource__c != null && ResourceService.resourcesByIds.containsKey(presumptiveResource.Child_Resource__c)) {
                    Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource__r.Resource_Type__c);
                    Resource__c resource = ResourceService.resourcesByIds.get(presumptiveResource.Child_Resource__c);
                    tmLine.Category__c = resource.Category__c;
                    if (resourceType != null) {
                        tmLine.Resource_Type__c = resourceType.Id;
                        tmLine.Resource_Type__r = resourceType;
                        tmLine.Description__c = resourceType.Description__c;
                    }
                    if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment') {
                        tmLine.Resource_Name__c = resource.Description__c;
                    }
                    else {
                        tmLine.Description__c = resource.Description__c;
                    }
                    tmLine.Resource__c = resource.Id;
                    tmLine.Resource__r = resource;
                    tmLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                    tmLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                }

                if (tmLine.Category__c == 'Labor' || tmLine.Category__c == 'Equipment') {
                    if (tmLine.Resource__r != null) {
                        tmLine.Resource_Name__c = tmLine.Resource__r.Description__c;
                    }
                    tmLine.Service_Center__c = parentLine.Service_Center__c;
                    tmLine.Service_Center__r = parentLine.Service_Center__r;
                }

                tmLine.Parent_Line__c = parentLine.Id;
                tmLine.Parent_Line__r = new TM_Line__c(Id = parentLine.Id, Line_No__c = parentLine.Line_No__c);
                tmLine.Is_Child_Resource__c = true;

                tmLines.add(tmLine);
                nextTMLineNo++;
            }
        }
        return tmLines;
    }
    */

    public TM_Line__c calculatePresumptiveChildLines(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, TM_Line__c tmLine, Integer nextTMLineNo) {
        if (mapPresumptiveResourcesByParentId.containsKey(tmLine.Resource_Type__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(tmLine.Resource_Type__c);
            return insertPresumptiveChildLines(tm, jobTaskWrapper, tmLine, presumptiveResources, nextTMLineNo);
        } else if (mapPresumptiveResourcesByParentId.containsKey(tmLine.Resource__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(tmLine.Resource__c);
            return insertPresumptiveChildLines(tm, jobTaskWrapper, tmLine, presumptiveResources, nextTMLineNo);
        }
        return tmLine;
    }

    private TM_Line__c insertPresumptiveChildLines(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, TM_Line__c tmLine, List<Presumptive_Resource__c> presumptiveResources, Integer nextTMLineNo) {
        Map<Id, TM_Parent_Child_Relation__c> mapRelationsByResourceId = new Map<Id, TM_Parent_Child_Relation__c>();
        if (tmLine.TM_Child_Lines__r != null) {
            for (TM_Parent_Child_Relation__c relation : tmLine.TM_Child_Lines__r) {
                Id childResourceId = getResOrResTypeId(relation.Child_Line__r);
                mapRelationsByResourceId.put(childResourceId, relation);
            }
        }

        Map<Id, TM_Line__c> mapTMLinesByResourceId = new Map<Id, TM_Line__c>();
        for (TM_Line__c tmLine2 : jobTaskWrapper.TMLines) {
            Id resourceId = getResOrResTypeId(tmLine2);
            mapTMLinesByResourceId.put(resourceId, tmLine2);
        }

        for (Presumptive_Resource__c presumptiveResource : presumptiveResources) {
            if (presumptiveResource.Child_Resource_Type__c != null || presumptiveResource.Child_Resource__c != null) {
                Id resourceId = null;
                if (presumptiveResource.Child_Resource_Type__c != null) {
                    resourceId = presumptiveResource.Child_Resource_Type__c;
                }
                else {
                    resourceId = presumptiveResource.Child_Resource__c;
                }

                if (!mapRelationsByResourceId.containsKey(resourceId)) { //if relationship does not exist
                    TM_Line__c childTMLine;
                    if (mapTMLinesByResourceId.containsKey(resourceId)) {
                        childTMLine = mapTMLinesByResourceId.get(resourceId);
                    }
                    else {
                        childTMLine = new TM_Line__c();
                        childTMLine.Line_No__c = nextTMLineNo;
                        childTMLine.TM__c = tm.Id;
                        childTMLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                        childTMLine.TM_Job_Task__r = jobTaskWrapper.JobTask;

                        if (presumptiveResource.Child_Resource_Type__c != null && ResourceTypeUtil.resourceTypesByIds.containsKey(presumptiveResource.Child_Resource_Type__c)) {
                            Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource_Type__c);
                            childTMLine.Category__c = resourceType.Category__c;
                            childTMLine.Resource_Type__c = resourceType.Id;
                            childTMLine.Resource_Type__r = resourceType;
                            childTMLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                            childTMLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                            childTMLine.Description__c = resourceType.Description__c;
                        } else if (presumptiveResource.Child_Resource__c != null && ResourceService.resourcesByIds.containsKey(presumptiveResource.Child_Resource__c)) {
                            Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource__r.Resource_Type__c);
                            Resource__c resource = ResourceService.resourcesByIds.get(presumptiveResource.Child_Resource__c);
                            childTMLine.Category__c = resource.Category__c;
                            if (resourceType != null) {
                                childTMLine.Resource_Type__c = resourceType.Id;
                                childTMLine.Resource_Type__r = resourceType;
                                childTMLine.Description__c = resourceType.Description__c;
                            }
                            if (childTMLine.Category__c == 'Labor' || childTMLine.Category__c == 'Equipment') {
                                childTMLine.Resource_Name__c = resource.Description__c;
                            } else {
                                childTMLine.Description__c = resource.Description__c;
                            }
                            childTMLine.Resource__c = resource.Id;
                            childTMLine.Resource__r = resource;
                            childTMLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                            childTMLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                        }
                        childTMLine.Quantity__c = 0;
                        if (childTMLine.Category__c == 'Labor' || childTMLine.Category__c == 'Equipment') {
                            if (childTMLine.Resource__r != null) {
                                childTMLine.Resource_Name__c = childTMLine.Resource__r.Description__c;
                            }
                            childTMLine.Service_Center__c = tmLine.Service_Center__c;
                            childTMLine.Service_Center__r = tmLine.Service_Center__r;
                        }

                        childTMLine.Is_Child_Resource__c = true;
                        jobTaskWrapper.TMLines.add(childTMLine);

                        nextTMLineNo++;
                    }

                    TM_Parent_Child_Relation__c relation = new TM_Parent_Child_Relation__c();
                    relation.Parent_Line__c = tmLine.Id;
                    relation.Parent_Line__r = tmLine;
                    relation.Child_Line__c = childTMLine.Id;
                    relation.Child_Line__r = childTMLine;
                    mapRelationsByResourceId.put(resourceId, relation);
                }
            }
        }
        jobTaskWrapper.NextTMLineNo = nextTMLineNo;
        tmLine = (TM_Line__c)JSONUtils.attachListToParent(tmLine, mapRelationsByResourceId.values(), 'TM_Child_Lines__r');
        return tmLine;
    }
    //ticket 19130 05.13.2023 >>

    public void calculateManifestFeeLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo) {
        //duplicated safety plan lines issue <<
        //Boolean manifest = tm.Sales_Order__r.Manifest_And_Profile__c;
        Sales_Order__c salesOrder = salesOrdersByIds.get(tm.Sales_Order__c);
        Boolean manifest = salesOrder.Manifest_And_Profile__c;
        //duplicated safety plan lines issue >>

        Boolean addManifestFeeLine = false;
        if (manifest == true) {
            for (Integer i = 0; i < jobTaskWrapper.TMLines.size(); i++) {
                TM_Line__c tmLine = jobTaskWrapper.TMLines[i];
                if (tmLine.Category__c == 'Waste Disposal' && tmLine.System_Calculated_Line__c != true) {
                    addManifestFeeLine = true;
                    break;
                }
            }
        }

        if (addManifestFeeLine == true) {
            Boolean manifestLineExists = false;
            for (Integer i = 0; i < jobTaskWrapper.TMLines.size(); i++) {
                TM_Line__c tmLine = jobTaskWrapper.TMLines[i];
                if (tmLine.Category__c == 'Waste Disposal' && tmLine.System_Calculated_Line__c == true && tmLine.Resource__c == defaultCompanySetup.Default_Manifest_Fee_Resource__c) {
                    manifestLineExists = true;
                    break;
                }
            }

            if (!manifestLineExists) {
                //Resource__c manifestFee = resourcesByIds.get(defaultCompanySetup.Default_Manifest_Fee_Resource__c);
                Resource__c manifestFee = ResourceService.resourcesByIds.get(defaultCompanySetup.Default_Manifest_Fee_Resource__c);
                TM_Line__c manifestFeeLine = new TM_Line__c();
                manifestFeeLine.TM__c = tm.Id;
                manifestFeeLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                manifestFeeLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                manifestFeeLine.Line_No__c = nextTMLineNo;
                manifestFeeLine.Category__c = 'Waste Disposal';
                manifestFeeLine.Resource__c = manifestFee.Id;
                manifestFeeLine.Resource__r = manifestFee;
                manifestFeeLine.Description__c = manifestFee.Description__c;
                manifestFeeLine.Unit_of_Measure__c = manifestFee.Unit_of_Measure__c;
                manifestFeeLine.Unit_of_Measure__r = manifestFee.Unit_of_Measure__r;
                manifestFeeLine.Quantity__c = 0;
                manifestFeeLine.System_Calculated_Line__c = true;
                jobTaskWrapper.TMLines.add(manifestFeeLine);
            }
        }
        else {
            for (Integer i = 0; i < jobTaskWrapper.TMLines.size(); i++) {
                TM_Line__c tmLine = jobTaskWrapper.TMLines[i];
                if (tmLine.Invoiced__c != true) { //only removed if the line has not been invoiced
                    if (tmLine.Category__c == 'Waste Disposal' && tmLine.System_Calculated_Line__c == true && tmLine.Resource__c == defaultCompanySetup.Default_Manifest_Fee_Resource__c) {
                        jobTaskWrapper.TMLines.remove(i);
                        i--;
                    }
                }
            }
        }
    }

    public void calculateRinseOutFeeLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo) {
        Sales_Order__c salesOrder = salesOrdersByIds.get(tm.Sales_Order__c);
        Integer rinseOutQuantity = 0;
        if (salesOrder != null) {
            if (salesOrder.Charge_Rinse_Out_Fee__c == true) {
                for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                    //calc number of rinse out fee needed
                    if (tmLine.Category__c == ResourceService.EQUIPMENT_CATEGORY && String.isNotBlank(tmLine.Resource_Type__c)) {
                        //if (resourceTypesByIds.get(tmLine.Resource_Type__c).Charge_Rinse_Out_Fee__c == true) {
                        if (ResourceTypeUtil.resourceTypesByIds.get(tmLine.Resource_Type__c).Charge_Rinse_Out_Fee__c == true) {
                            rinseOutQuantity += 1;
                        }
                    }
                }
            }
        }

        if (rinseOutQuantity > 0) {
            addRinseOutFeeLine(tm, jobTaskWrapper, rinseOutQuantity, nextTMLineNo);
        } else {
            removeRinseOutFeeLine(jobTaskWrapper);
        }
    }

    private void addRinseOutFeeLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer quantity, Integer nextTMLineNo){
        TM_Line__c rinseOutFeeLine;
        for(TM_Line__c tmLine : jobTaskWrapper.TMLines){
            if(tmLine.Category__c == ResourceService.MISC_CHARGES_AND_TAX_CATEGORY && tmLine.System_Calculated_Line__c == true && tmLine.Resource__c == CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c) {
                rinseOutFeeLine = tmLine;
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
                rinseOutFeeLine = new TM_Line__c();
                rinseOutFeeLine.TM__c = tm.Id;
                rinseOutFeeLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                rinseOutFeeLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                rinseOutFeeLine.Line_No__c = nextTMLineNo;
                rinseOutFeeLine.Category__c = ResourceService.MISC_CHARGES_AND_TAX_CATEGORY;
                rinseOutFeeLine.Resource__c = rinseOutResource.Id;
                rinseOutFeeLine.Description__c = rinseOutResource.Name;
                if (resourceUOMAssociation != null) {
                    rinseOutFeeLine.Unit_of_Measure__c = resourceUOMAssociation.Unit_of_Measure__c;
                    rinseOutFeeLine.Unit_of_Measure__r = resourceUOMAssociation.Unit_of_Measure__r;
                }

                rinseOutFeeLine.Quantity__c = quantity;
                rinseOutFeeLine.System_Calculated_Line__c = true;
                jobTaskWrapper.TMLines.add(rinseOutFeeLine);
            } else {
                rinseOutFeeLine.Quantity__c = quantity;
            }
        }
    }

    private void removeRinseOutFeeLine(ACVTMJobTaskWrapper jobTaskWrapper){
        for (Integer i = 0 ; i < jobTaskWrapper.TMLines.size(); i++) {
            TM_Line__c tmLine = jobTaskWrapper.TMLines[i];
            if (tmLine.Category__c == 'Misc. Charges And Taxes' && tmLine.System_Calculated_Line__c == true && tmLine.Resource__c == CompanySettingUtil.acvSetting.Rinse_Out_Fee_Resource_Id__c){
                jobTaskWrapper.TMLines.remove(i);
                i--;
            }
        }
    }

    public void createSafetyPlanLine(TM__c tm, ACVTMJobTaskWrapper jobTaskWrapper, Integer nextTMLineNo) {
        Sales_Order__c salesOrder = salesOrdersByIds.get(tm.Sales_Order__c);
        if (salesOrder != null && salesOrder.Sales_Order_Type__r.Emergency_Response__c == true) {
            Id defaultSafetyPlanResourceId = defaultCompanySetup.Default_Safety_Plan_Resource__c;
            Boolean hasSafetyPlanLine = false;
            for (TM_Line__c tmLine : jobTaskWrapper.TMLines) {
                if (tmLine.Category__c == 'Misc. Charges And Taxes' && tmLine.Resource__c ==  defaultSafetyPlanResourceId) {
                    hasSafetyPlanLine = true;
                    break;
                }
            }

            if (!hasSafetyPlanLine) {
                //duplicated safety plan lines issue <<
                //List<TM_Line__c> tmLines = [SELECT Id FROM TM_Line__c WHERE TM__r.Sales_Order__c = :salesOrder.Id AND Category__c = 'Misc. Charges And Taxes' AND Resource__c = :defaultSafetyPlanResourceId];
                //if (tmLines.size() == 0) {
                if (!mapHasSafetyPlanLineByOrderId.containsKey(tm.Sales_Order__c)) {
                //duplicated safety plan lines issue >>
                    Resource__c safetyPlanResource = defaultCompanySetup.Default_Safety_Plan_Resource__r;

                    TM_Line__c newLine = new TM_Line__c();
                    newLine.TM__c = tm.Id;
                    newLine.TM_Job_Task__c = jobTaskWrapper.JobTask.Id;
                    newLine.TM_Job_Task__r = jobTaskWrapper.JobTask;
                    newLine.Category__c = 'Misc. Charges And Taxes';
                    newLine.Line_No__c = nextTMLineNo;
                    newLine.Tax_Group__c = 'NT';
                    newLine.Resource__c = safetyPlanResource.Id;
                    newLine.Description__c = safetyPlanResource.Description__c;
                    newLine.Unit_of_Measure__c = safetyPlanResource.Unit_of_Measure__c;
                    newLine.Quantity__c = 1;
                    newLine.System_Calculated_Line__c = true;
                    jobTaskWrapper.TMLines.add(newLine);
                    nextTMLineNo++;
                }
            }
        }
    }
}
