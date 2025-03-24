/*
 *  Ticket#19992
 *      - allow post to resource sales gl account when bundled.
 *      - copy xLine_Amount__c to invoice.
 *  Ticket#80939
 *     - Changed surcharge type picklist field from "Energy & Insurance" to "Energy and Environmental Compliance Fee"
 *   Ticket#85807
        - Changed surcharge type picklist field from "Energy and Environmental Compliance Fee" to "EEC Fee"
*    Prabhu Rathakrishnan 10-113-2024 US127188 - Salesforce - Modifications to allow ESIC Surcharge Type
*    Pavithra Periyasamy  11-18-2023  DE36562-	 Salesforce - Disposal Billing Method selected in Sales Order prompts again in Billing Worksheet
* 	Prabhu Rathakrishnan      12/05/2024   US132386: Salesforce - Move 'Disposal Billing Method' field to be on Sales Lines of Sales Quote/Order
*   Yuvraj Ganesan            12/31/2024   US135286: Change Time of Surcharge Calculation from Time of Quote to Time of Invoice
*   Sai Kumar                 02/12/2025   US139238:  Show 'Sent to EQAI' on T&M Line Level
 */
public class BillingWorksheetServiceImpl implements IBillingWorksheetService {
    public static Company_Setup__c defaultCompanySetup = CompanyMgmt.getCompanySetup();
    public static Map<Id, Sales_Order__c> salesOrdersByIds = new Map<Id, Sales_Order__c>();
    public static Map<Id, TM__c> tmsByIds = new Map<Id, TM__c>();
    public static Map<Id, Unit_of_Measure__c> unitOfMeasuresByIds = new Map<Id, Unit_of_Measure__c>();
    public static Map<Id, Service_Center__c> serviceCentersByIds = new Map<Id, Service_Center__c>();
    public static Map<Id, Map<Id, Map<Id, Sales_Line__c>>> salesLinesByUOMIdsByResOrTypeIdsBySalesOrderIds = new Map<Id, Map<Id, Map<Id, Sales_Line__c>>>();
    public static Map<Id, Sales_Line__c> salesLinesByIds = new Map<Id, Sales_Line__c>();
    public static Map<String, Sales_Line__c> wasteSalesLinesBySalesOrderResFacilityUwvContainerSize = new Map<String, Sales_Line__c>();
    public static Map<String, Sales_Line__c> subContractLinesByDescription = new Map<String, Sales_Line__c>(); //Ticket#18075
    //public static Map<Id, Map<Id, Pay_Rule_Line__c>> payRuleLineByResTypeIdsByPayRuleIds = new Map<Id, Map<Id, Pay_Rule_Line__c>>();
    public static Map<Date, Holiday__c> holidaysByDates = new Map<Date, Holiday__c>();
    public static List<Pricing_Rate_Sheet_Association__c> pricingRateSheetAssociations = new List<Pricing_Rate_Sheet_Association__c>();
    public static Map<String, Billing_Rule__c> mapBillingRulesByAssumption = new Map<String, Billing_Rule__c>();
    public static Map<Id, List<Presumptive_Resource__c>> mapPresumptiveResourcesByParentId = new Map<Id, List<Presumptive_Resource__c>>();
    //Ticket#19663 >>
    //public static Map<Id, Pay_Rule__c> payRulesByIds = new Map<Id, Pay_Rule__c>();
    public static Boolean payRuleChangeCostUpdate = false;
    public static Id worksheetWrapperPayRuleId = null;
    //Ticket#19663 >>

    public void initStaticVariables(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers) {
        Set<Id> salesOrderIds = new Set<Id>();
        Set<Id> tmIds = new Set<Id>();
        Set<Id> resIds = new Set<Id>();
        Set<Id> resTypeIds = new Set<Id>();
        Set<Id> payRuleIds = new Set<Id>();
        Set<Id> contractIds = new Set<Id>();
        Set<Id> uomIds = new Set<Id>();
        Set<Id> rateSheetIds = new Set<Id>();
        Set<Id> priceListIds = new Set<Id>();
        salesOrderIds.add(salesOrderId);
        setServiceCenterByIdsMap();

        if (String.isNotBlank(defaultCompanySetup.Price_List__c)) {
            priceListIds.add(defaultCompanySetup.Price_List__c);
        }

        for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
            //Ticket#19663 >>
            if(String.isNotBlank(worksheetWrapper.PayRuleId)){
                payRuleIds.add(worksheetWrapper.PayRuleId);
                worksheetWrapperPayRuleId = worksheetWrapper.PayRuleId;
            }
            payRuleChangeCostUpdate = worksheetWrapper.IsPayRuleCostUpdateCall;
            //Ticket#19663 >>
            for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                if (worksheetLine.TM__c != null) {
                    tmIds.add(worksheetLine.TM__c);
                }

                if (worksheetLine.Resource_Type__c != null) {
                    resTypeIds.add(worksheetLine.Resource_Type__c);
                }

                if (worksheetLine.Resource__c != null) {
                    resIds.add(worksheetLine.Resource__c);
                }

                if (worksheetLine.Unit_of_Measure__c != null) {
                    uomIds.add(worksheetLine.Unit_of_Measure__c);
                }

                if (worksheetLine.Sales_Order__c != null){
                    salesOrderIds.add(worksheetLine.Sales_Order__c);
                }
            }
        }

        //get T&Ms
        tmsByIds.putAll(TMsSelector.newInstance().selectByIds(tmIds));

        Date minScheduledDate = null;
        Date maxScheduleDate = null;
        for (TM__c tm : tmsByIds.values()) {
            if (minScheduledDate == null || minScheduledDate > tm.Scheduled_Date__c) {
                minScheduledDate = tm.Scheduled_Date__c;
            }
            if (maxScheduleDate == null || maxScheduleDate < tm.Scheduled_Date__c) {
                maxScheduleDate = tm.Scheduled_Date__c;
            }

            if (tm.From_Sales_Quote__c != null) {
                salesOrderIds.add(tm.From_Sales_Quote__c);
            }

            if (tm.Sales_Order__c != null){
                salesOrderIds.add(tm.Sales_Order__c);
            }

            if (tm.Rate_Sheet__c != null) {
                rateSheetIds.add(tm.Rate_Sheet__c);
            }

            if (serviceCentersByIds.containsKey(tm.Service_Center__c)) {
                Service_Center__c serviceCenter = serviceCentersByIds.get(tm.Service_Center__c);
                if (String.isNotBlank(serviceCenter.Price_List__c)) {
                    priceListIds.add(serviceCenter.Price_List__c);
                }
            }
        }

        if (salesOrderIds.size() > 0) {
            setSalesOrderByIdsMap(salesOrderIds);
            for (Sales_Order__c salesOrder : salesOrdersByIds.values()) {
                if(payRuleChangeCostUpdate != true && salesOrder.Pay_Rule__c != null) {
                    payRuleIds.add(salesOrder.Pay_Rule__c);
                }
                if (salesOrder.Contract__c != null) {
                    contractIds.add(salesOrder.Contract__c);
                }
            }
        }

        //presumptive child resources
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

        resIds.add(defaultCompanySetup.Default_Energy_Insurance_Resource__c);
        resIds.add(defaultCompanySetup.Default_Fuel_Surcharge_Resource__c);
        resIds.add(defaultCompanySetup.Default_Manifest_Fee_Resource__c);
        resIds.add(CompanySettingUtil.acvSetting.Fixed_Price_Job_Resource__c);
        resIds.add(defaultCompanySetup.Default_ESIC_Surcharge_Resource__c);

        if (resIds.size() > 0) {
            ResourceService.setResourceMapsByIds(resIds);
            uomIds.addAll(ResourceService.resourceUOMIds);
            /*
                //setResourceByIdsMap(resIds);
                //setResourceUOMAssociationsByUOMIdsByResIds(resIds); moved to resourceService
             */
            Sales_Order__c salesOrder = salesOrdersByIds.get(salesOrderId);
            for (Resource__c resource : ResourceService.resourcesByIds.values()) {
                if (resource.Pay_Rule__c != null) {
                    payRuleIds.add(resource.Pay_Rule__c);
                }

                if (resource.Resource_Type__c != null && resource.Category__c == 'Labor') {
                    resTypeIds.add(resource.Resource_Type__c);
                }
                //include resource's resource type for calcUnitCost function
                else if (String.isNotBlank(salesOrder.Pay_Rule__c) || salesOrder.Pay_Rule__r.Type__c != 'Prevailing Wage') {
                    resTypeIds.add(resource.Resource_Type__c);
                }
            }

            //Ticket#27074 >>
            if(String.isNotBlank(salesOrder.Tax_Area__c)){
                TaxService.setTaxPctByTaxGroupByTaxAreaIdMap(new Set<Id>{salesOrder.Tax_Area__c});
            }
            //Ticket#27074 <<
        }

        if (resTypeIds.size() > 0) {
            ResourceTypeUtil.setResourceTypeMapsByIds(resTypeIds);
            uomIds.addAll(ResourceTypeUtil.uomIds);
            /* moved to resource type util
            //setResourceTypeUOMAssociationsByUOMIdsByResTypeIdsMap(resTypeIds);
            resourceTypesByIds.putAll(ResourceTypesSelector.newInstance().selectById(resTypeIds));
             */
        }

        if (uomIds.size() > 0) setUnitOfMeasureByIdsMap(uomIds);

        if (payRuleIds.size() > 0 && minScheduledDate != null) {
            PayRuleService.initStaticVariables(payRuleIds, minScheduledDate);
            //setPayRuleLinesByResTypeIdsByPayRuleIdsMap(payRuleIds);
        }
        if(contractIds.size() > 0) {
            ContractUtil.setContractLineByUOMIdsResOrTypeIdsByContractIdsMap(contractIds, minScheduledDate);
        }

        if (salesOrderIds.size() > 0) {
            setSalesLinesByResOrTypeIdsBySalesOrderIdsMap(salesOrderIds);
        }

        setHolidaysByIdsMap();

        pricingRateSheetAssociations = PriceListSelector.newInstance().getPricingRateSheetAssociationsByPriceListId(priceListIds, maxScheduleDate);
        for (Pricing_Rate_Sheet_Association__c pricingRateSheetAssociation : pricingRateSheetAssociations) {
            rateSheetIds.add(pricingRateSheetAssociation.Rate_Sheet__c);
        }

        if (rateSheetIds.size() > 0) {
            RateSheetService.setRateSheetLines(rateSheetIds);
            RateSheetService.setMap_RateSheetLinesByUOMByResTypeByRateSheet();
        }

        setBillingRulesByAssumptions();

    }

    public void calcUnitPrice(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        //ticket 20143 <<
        if (worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY && worksheetLine.Resource__r != null && worksheetLine.Resource__r.Name == 'WD' && worksheetLine.Inserted_by_User__c == true) {
            return;
        }
        //ticket 20143 >>
        //Ticket#19964 >>
        if(worksheetLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY){
            calcSubcontractorUnitCostAndPrice(worksheetLine);
            return;
        }
        //Ticket#19964 <<

        Sales_Order__c salesOrder = salesOrdersByIds.get(salesOrderId);

        Id resOrTypeId = null;
        Boolean pricingInfoFound = false;
        Boolean wasteLineSpecialTreatment = false;
        //85225
        /*if(isCalcBaseOnResType(worksheetLine.Category__c) == true && worksheetLine.Resource__c != null) {
          		 Resource__c resource = ResourceService.resourcesByIds.get(worksheetLine.Resource__c);
                    if (resource.Resource_Type__c != null) {
                        resOrTypeId = resource.Resource_Type__c;
                    }
        }*/
         if(isCalcBaseOnResType(worksheetLine.Category__c) == true && worksheetLine.Resource_Type__c != null && resOrTypeId == null) {
            resOrTypeId = worksheetLine.Resource_Type__c;
        } else if(isCalcBaseOnResType(worksheetLine.Category__c) == false && worksheetLine.Resource__c != null) {
            resOrTypeId = worksheetLine.Resource__c;

            if(worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                wasteLineSpecialTreatment = true;
            }
                /*
                if(resOrTypeId != defaultCompanySetup.Default_Waste_Disposal_Resource__c) {
                    if (String.isNotBlank(worksheetLine.Cost_Method__c)) {
                        wasteLineSpecialTreatment = true;
                    }
                }
            }
                 */
        }

        Service_Center__c serviceCenter = new Service_Center__c();
        if (serviceCentersByIds.containsKey(salesOrder.Service_Center__c)) {
            serviceCenter = serviceCentersByIds.get(salesOrder.Service_Center__c);
        }

        worksheetLine.Pricing_Source_2__c = null;

        if (resOrTypeId != null) {
            //check quote lines
            if (salesOrder.From_Sales_Quote__c != null && pricingInfoFound == false) {
                //Sales_Line__c quotedLine = getSalesLine(salesOrder.From_Sales_Quote__c, resOrTypeId, worksheetLine.Unit_of_Measure__c);
                Sales_Line__c quotedLine = new Sales_Line__c();
                //handle same resource type/resource and UOM on the same order
                if (String.isNotBlank(worksheetLine.Quote_Line__c)) {
                    quotedLine = salesLinesByIds.get(worksheetLine.Quote_Line__c);
                }

                if (String.isBlank(worksheetLine.Quote_Line__c)) {
                    if (wasteLineSpecialTreatment == false) {
                        quotedLine = getSalesLine(salesOrder.From_Sales_Quote__c, resOrTypeId, worksheetLine.Unit_of_Measure__c);
                    } else {
                        quotedLine = getWasteSalesLine(salesOrder, worksheetLine, true);
                    }
                }

                //Ticket#20749 >>
                if (String.isNotBlank(quotedLine.Id)) {
                    if (String.isNotBlank(quotedLine.Contract_Line__c) && worksheetLine.TM__r.Scheduled_Date__c != null) {
                        if (worksheetLine.TM__r.Scheduled_Date__c < quotedLine.Contract_Line__r.Contract__r.StartDate ||
                                worksheetLine.TM__r.Scheduled_Date__c > quotedLine.Contract_Line__r.Contract__r.EndDate) {
                            quotedLine.Id = null;
                        }
                    }
                }
                System.debug('quotedLine====>'+quotedLine);
                //Ticket#20749 <<

                if (String.isNotBlank(quotedLine.Id)) {
                    worksheetLine.Quote_Line__c = quotedLine.Id;
                    if (worksheetLine.Category__c == 'Labor') {
                        worksheetLine.Regular_Rate__c = quotedLine.Regular_Rate__c;
                        worksheetLine.Overtime_Rate__c = quotedLine.Overtime_Rate__c;
                        worksheetLine.Premium_Rate__c = quotedLine.Premium_Rate__c;
                        calcLaborUnitPrice(worksheetLine);
                    } else {
                        if(quotedLine.Bill_as_Lump_Sum__c == true || quotedLine.Non_Billable__c == true){
                            worksheetLine.Unit_Price__c = quotedLine.xUnit_Price__c;
                        } else {
                            worksheetLine.Unit_Price__c = quotedLine.Unit_Price__c;
                        }
                    }

                    if(worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY
                            && CompanyMgmt.zeroIfNull(quotedLine.Min_Sell_Qty__c) > 0){
                        worksheetLine.Min_Sell_Qty__c = quotedLine.Min_Sell_Qty__c;
                    }
				
                     System.debug('worksheetLine.Contract_Line__c1++++++++++' +worksheetLine.Contract_Line__c);
                    if(String.isNotBlank(quotedLine.Contract_Line__c)) {                        
                        worksheetLine.Contract_Line__c = quotedLine.Contract_Line__c;
                        worksheetLine.Contract_Line__r = quotedLine.Contract_Line__r;
                    }
                    worksheetLine.Pricing_Source_2__c = quotedLine.Sales_Order__r.Name;
                    pricingInfoFound = true;
                }
                
                System.debug('worksheetLine.Contract_Line__c2++++++++++' +worksheetLine.Contract_Line__c);
            }

            //check contract lines
            if(pricingInfoFound == false && salesOrder.Contract__c != null){
                //System.debug('Info: Contract Pricing');
                Contract_Line__c contractLine = new Contract_Line__c();
                if (String.isNotBlank(worksheetLine.Contract_Line__c)){
                    if (worksheetLine.TM__r != null) {
                        contractLine = ContractUtil.getContractLine(worksheetLine.Contract_Line__c, worksheetLine.TM__r.Scheduled_Date__c);
                    }
                }

                if (String.isBlank(contractLine.Id) && String.isNotBlank(salesOrder.Contract__c)) {
                    /* Ticket#21616
                    if(worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                        contractLine = ContractUtil.getContractLine(salesOrder.Contract__c, resOrTypeId, worksheetLine.Unit_of_Measure__c, worksheetLine.Facility__c);
                        if (String.isBlank(contractLine.Id)){
                            contractLine = ContractUtil.getContractLine(salesOrder.Contract__c, resOrTypeId, worksheetLine.Unit_of_Measure__c);
                        }
                    } else {
                        if (worksheetLine.TM__r != null) {
                            contractLine = ContractUtil.getContractLine(salesOrder.Contract__c, resOrTypeId, worksheetLine.Unit_of_Measure__c, worksheetLine.TM__r.Scheduled_Date__c);
                        }
                    }
                     */
                    if (worksheetLine.TM__r != null) {
                        contractLine = ContractUtil.getContractLine(salesOrder.Contract__c, resOrTypeId, worksheetLine.Unit_of_Measure__c, worksheetLine.TM__r.Scheduled_Date__c);
                    }
                }

                //Ticket#20749
                Boolean applyContractPrice = true; //Ticket#24869
                if(String.isNotBlank(contractLine.Id) && worksheetLine.TM__r.Scheduled_Date__c != null){
                    if(worksheetLine.TM__r.Scheduled_Date__c < salesOrder.Contract__r.StartDate ||
                            worksheetLine.TM__r.Scheduled_Date__c > salesOrder.Contract__r.EndDate){
                        //contractLine.Id = null;
                        applyContractPrice = false; //Ticket#24869
                    }
                }

                //Ticket#24869
                //if (String.isBlank(contractLine.Id) == false) {
                System.debug('worksheetLine.Contract_Line__c++++++++++' +worksheetLine.Contract_Line__c);
                if (String.isBlank(contractLine.Id) == false && applyContractPrice == true) {
                    worksheetLine.Contract_Line__c = contractLine.Id;
                    worksheetLine.Contract_Line__r = new Contract_Line__c(Id = contractLine.Id, Name = contractLine.Name);
                    worksheetLine.Contract_Regular_Rate__c = contractLine.Regular_Rate__c;
                    worksheetLine.Contract_Overtime_Rate__c = contractLine.Overtime_Rate__c;
                    worksheetLine.Contract_Premium_Rate__c = contractLine.Premium_Rate__c;
                    if (worksheetLine.Category__c == ResourceService.LABOR_CATEGORY) {
                        worksheetLine.Regular_Rate__c = contractLine.Regular_Rate__c;
                        worksheetLine.Overtime_Rate__c = contractLine.Overtime_Rate__c;
                        worksheetLine.Premium_Rate__c = contractLine.Premium_Rate__c;
                        calcLaborUnitPrice(worksheetLine);
                    } else if (worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                        worksheetLine.Unit_Price__c = contractLine.Regular_Rate__c;
                        worksheetLine.Min_Sell_Qty__c = contractLine.Min_Sell_Qty__c;
                    } else {
                        worksheetLine.Unit_Price__c = contractLine.Regular_Rate__c;
                    }
                    worksheetLine.Contract_Line__c = contractLine.Id;
                    worksheetLine.Pricing_Source_2__c = contractLine.Contract__r.Name;
                    pricingInfoFound = true;
                }
            }
 			System.debug('worksheetLine.Contract_Line__c++++++++++' +worksheetLine.Contract_Line__c);
            //check sales lines
            if (pricingInfoFound == false && salesOrder.Id != null) {
                //System.debug('Info: Sales Order Pricing');
                /*
                 * If linked Sales Order Line is a Lump Sum or Non-Billable line, temporarily get pricing from x fields
                 * from linked sales line.
                 */
                //Sales_Line__c salesLine = getSalesLine(salesOrder.Id, resOrTypeId, worksheetLine.Unit_of_Measure__c);
                Sales_Line__c salesLine = new Sales_Line__c();
                if (String.isNotBlank(worksheetLine.Sales_Line__c)) {
                    //System.debug('Info: worksheetLine.Sales_Line__c ' + worksheetLine.Sales_Line__c);
                    salesLine = salesLinesByIds.get(worksheetLine.Sales_Line__c);
                }
                if (String.isBlank(salesLine.Id)) {
                    if (wasteLineSpecialTreatment == true) {
                        salesLine = getWasteSalesLine(salesOrder, worksheetLine, false);
                    }
                    /* Ticket#19964
                    else if (worksheetLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY) {
                        salesLine = getSalesLineByLineDesc(worksheetLine.Description__c);
                    }
                     */
                    else {
                        salesLine = getSalesLine(salesOrder.Id, resOrTypeId, worksheetLine.Unit_of_Measure__c);
                    }
                }

                //Ticket#20749 >>
                Boolean applySalesLinePricing = true; //Ticket#24869
                if (String.isNotBlank(salesLine.Id)) {
                    if (String.isNotBlank(salesLine.Contract_Line__c) && worksheetLine.TM__r.Scheduled_Date__c != null) {
                        if (worksheetLine.TM__r.Scheduled_Date__c < salesLine.Contract_Line__r.Contract__r.StartDate ||
                                worksheetLine.TM__r.Scheduled_Date__c > salesLine.Contract_Line__r.Contract__r.EndDate) {
                            //salesLine.Id = null;
                            applySalesLinePricing = false; //Ticket#24869
                        }
                    }
                }
                //Ticket#20749 <<
                //Ticket#24869
                //if (String.isNotBlank(salesLine.Id)) {
                if (String.isNotBlank(salesLine.Id) && applySalesLinePricing == true) {
                    worksheetLine.Sales_Line__c = salesLine.Id;
                    if (worksheetLine.Category__c == 'Labor') {
                        worksheetLine.Regular_Rate__c = salesLine.Regular_Rate__c;
                        worksheetLine.Overtime_Rate__c = salesLine.Overtime_Rate__c;
                        worksheetLine.Premium_Rate__c = salesLine.Premium_Rate__c;
                        worksheetLine.xRegular_Rate__c = salesLine.xRegular_Rate__c;
                        worksheetLine.xOvertime_Rate__c = salesLine.xOvertime_Rate__c;
                        worksheetLine.xPremium_Rate__c = salesLine.xPremium_Rate__c;

                        calcLaborUnitPrice(worksheetLine);
                    } else {
                        if(salesLine.Bill_as_Lump_Sum__c == true || salesLine.Non_Billable__c == true) {
                            worksheetLine.Unit_Price__c = salesLine.xUnit_Price__c;
                        } else {
                            worksheetLine.Unit_Price__c = salesLine.Unit_Price__c;
                        }
                    }

                    if(worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY
                            && CompanyMgmt.zeroIfNull(salesLine.Min_Sell_Qty__c) > 0){
                        worksheetLine.Min_Sell_Qty__c = salesLine.Min_Sell_Qty__c;
                    }
					 System.debug('worksheetLine.Contract_Line__c++++++++++' +worksheetLine.Contract_Line__c);
                    if(String.isNotBlank(salesLine.Contract_Line__c)){
                        worksheetLine.Contract_Line__c = salesLine.Contract_Line__c;
                        worksheetLine.Contract_Line__r = salesLine.Contract_Line__r;
                    }
					System.debug('worksheetLine.Contract_Line__c++++++++++' +worksheetLine.Contract_Line__c);
                    worksheetLine.Pricing_Source_2__c = 'Order-' + salesLine.Sales_Order__r.Name;
                    pricingInfoFound = true;
                }
            }

            //Rate Sheet pricing
            if (pricingInfoFound == false && worksheetLine.TM__c != null) {
                TM__c tm = tmsByIds.get(worksheetLine.TM__c);
                if (tm != null) {
                    if (tm.Rate_Sheet__c == null) {
                        Id rateSheetId = getEffectiveRateSheetId(worksheetLine.TM__r.Scheduled_Date__c);
                        tm.Rate_Sheet__c = rateSheetId;
                    }

                    if (tm.Rate_Sheet__c != null) {
                        //System.debug('Info: tm RateSheet Pricing begin ');
                        Decimal unitPrice = 0;
                        Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Pricing', worksheetLine, tm.Rate_Sheet__c);
                        if (rateSheetLine != null && rateSheetLine.Id != null) {
                            worksheetLine.Min_Sell_Qty__c = CompanyMgmt.zeroIfNull(rateSheetLine.Min_Sell_Qty__c);
                        }
                        unitPrice = RateSheetService.getUnitPrice(rateSheetLine, salesOrder.Emergency_Sales_Order__c);
                        if (unitPrice > 0) {
                            if (worksheetLine.Category__c == 'Labor') {
                                worksheetLine.Regular_Rate__c = unitPrice;
                                worksheetLine.Overtime_Rate__c = unitPrice * 1.5;
                                worksheetLine.Premium_Rate__c = unitPrice * 2;
                                calcLaborUnitPrice(worksheetLine);
                            } else {
                                worksheetLine.Unit_Price__c = unitPrice;
                            }

                            worksheetLine.Pricing_Source_2__c = rateSheetLine.Rate_Sheet__r.Name;
                            pricingInfoFound = true;
                        }
                    }
                }
            }

            if (pricingInfoFound == false && String.isNotBlank(serviceCenter.Price_List__c)) {
                //System.debug('Info: SC RateSheet Pricing begin ');
                Decimal unitPrice = 0;
                Id rateSheetId = null;
                if (worksheetLine.TM__r != null) {
                    rateSheetId = getEffectiveRateSheetId(serviceCenter.Price_List__c, worksheetLine.TM__r.Scheduled_Date__c);
                }
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Pricing', worksheetLine, rateSheetId);
                if (rateSheetLine != null && rateSheetLine.Id != null) {
                    worksheetLine.Min_Sell_Qty__c = CompanyMgmt.zeroIfNull(rateSheetLine.Min_Sell_Qty__c);
                }

                unitPrice = RateSheetService.getUnitPrice(rateSheetLine, salesOrder.Emergency_Sales_Order__c);
                if (unitPrice > 0) {
                    if (worksheetLine.Category__c == 'Labor') {
                        worksheetLine.Regular_Rate__c = unitPrice;
                        worksheetLine.Overtime_Rate__c = unitPrice * 1.5;
                        worksheetLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(worksheetLine);
                    } else {
                        worksheetLine.Unit_Price__c = unitPrice;
                    }

                    worksheetLine.Pricing_Source_2__c = rateSheetLine.Rate_Sheet__r.Name;
                    pricingInfoFound = true;
                }
            }

            if (pricingInfoFound == false && String.isNotBlank(defaultCompanySetup.Price_List__c)) {
                //System.debug('Info: Company RateSheet Pricing begin ');
                Decimal unitPrice = 0;
                Id rateSheetId = null;
                if (worksheetLine.TM__r != null) {
                    rateSheetId = getEffectiveRateSheetId(defaultCompanySetup.Price_List__c, worksheetLine.TM__r.Scheduled_Date__c);
                }
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Pricing', worksheetLine, rateSheetId);
                if (rateSheetLine != null && rateSheetLine.Id != null) {
                    worksheetLine.Min_Sell_Qty__c = CompanyMgmt.zeroIfNull(rateSheetLine.Min_Sell_Qty__c);
                }
                unitPrice = RateSheetService.getUnitPrice(rateSheetLine, salesOrder.Emergency_Sales_Order__c);
                if (unitPrice > 0) {
                    if (worksheetLine.Category__c == 'Labor') {
                        worksheetLine.Regular_Rate__c = unitPrice;
                        worksheetLine.Overtime_Rate__c = unitPrice * 1.5;
                        worksheetLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(worksheetLine);
                    } else {
                        worksheetLine.Unit_Price__c = unitPrice;
                    }

                    worksheetLine.Pricing_Source_2__c = rateSheetLine.Rate_Sheet__r.Name;
                    pricingInfoFound = true;
                }
            }

            //standard rate
            if (pricingInfoFound == false) {
                //System.debug('Info: Standard Pricing ');
                if (worksheetLine.Category__c == 'Waste Disposal') {
                    ResourceUOMAssociation__c wasteResUOMAssociation = getWasteResUOMSetup(worksheetLine);
                    if (wasteResUOMAssociation.Id != null) {
                        if(salesOrder.Emergency_Sales_Order__c == true) {
                            worksheetLine.Unit_Price__c = wasteResUOMAssociation.ER_Unit_Price__c;
                        } else {
                            worksheetLine.Unit_Price__c = wasteResUOMAssociation.Unit_Price__c;
                        }
                        worksheetLine.Min_Sell_Qty__c = wasteResUOMAssociation.Min_Sell_Qty__c;
                    } else {
                        worksheetLine.Unit_Price__c = 0;
                        worksheetLine.Min_Sell_Qty__c = 0;
                    }
                } else {
                    Decimal unitPrice = getUnitPrice(worksheetLine.Category__c, resOrTypeId, worksheetLine.Unit_of_Measure__c, salesOrder.Emergency_Sales_Order__c);
                    if (worksheetLine.Category__c == 'Labor') {
                        worksheetLine.Regular_Rate__c = unitPrice;
                        worksheetLine.Overtime_Rate__c = unitPrice * 1.5;
                        worksheetLine.Premium_Rate__c = unitPrice * 2;
                        calcLaborUnitPrice(worksheetLine);
                    }
                    else if (worksheetLine.Category__c != 'Subcontractors') {
                        worksheetLine.Unit_Price__c = unitPrice;
                    }
                }

                if (CompanyMgmt.zeroIfNull(worksheetLine.Unit_Price__c) > 0) {
                    worksheetLine.Pricing_Source_2__c = EnumUtil.PricingSource.BASE.name();
                }
            }

            worksheetLine.xUnit_Price__c = worksheetLine.Unit_Price__c;
            worksheetLine.xRegular_Rate__c = worksheetLine.Regular_Rate__c;
            worksheetLine.xOvertime_Rate__c = worksheetLine.Overtime_Rate__c;
            worksheetLine.xPremium_Rate__c = worksheetLine.Premium_Rate__c;


            //Handle Bill-as-Lump Sum or Non-Billable
            /*
            if(worksheetLine.Bill_as_Lump_Sum__c == true || worksheetLine.Non_Billable__c == true){
                if(worksheetLine.Category__c == 'Labor') {
                    worksheetLine.xRegular_Rate__c = worksheetLine.Regular_Rate__c;
                    worksheetLine.xOvertime_Rate__c = worksheetLine.Overtime_Rate__c;
                    worksheetLine.xPremium_Rate__c = worksheetLine.Premium_Rate__c;
                    worksheetLine.Regular_Rate__c = 0;
                    worksheetLine.Overtime_Rate__c = 0;
                    worksheetLine.Premium_Rate__c = 0;
                }
                worksheetLine.xUnit_Price__c = worksheetLine.Unit_Price__c;
                worksheetLine.Unit_Price__c = 0;
            }
            */
            if (worksheetLine.Bill_as_Lump_Sum__c == true || worksheetLine.Non_Billable__c == true){
                worksheetLine.Unit_Price__c = 0;
            }
        }

        //System.debug('Info# calcUnitPrice End');
    }

    public void calcLaborUnitPrice(Billing_Worksheet_Line__c worksheetLine) {
        if (worksheetLine.Category__c != 'Labor') return;
        if (!String.isBlank(worksheetLine.Unit_of_Measure__c)) {
            Unit_of_Measure__c unitOfMeasure = unitOfMeasuresByIds.get(worksheetLine.Unit_of_Measure__c);
            if (unitOfMeasure.Hours_UOM__c != true) {
                worksheetLine.Unit_Price__c = worksheetLine.Regular_Rate__c;
                return;
            }
        }

        //Calculate Unit Price
        Decimal totalHours = 0;
        Decimal totalPrice = 0;

        totalPrice = (CompanyMgmt.zeroIfNull(worksheetLine.Regular_Hours__c) * CompanyMgmt.zeroIfNull(worksheetLine.Regular_Rate__c)) +
                (CompanyMgmt.zeroIfNull(worksheetLine.Overtime_Hours__c) * CompanyMgmt.zeroIfNull(worksheetLine.Overtime_Rate__c)) +
                (CompanyMgmt.zeroIfNull(worksheetLine.Premium_Hours__c) * CompanyMgmt.zeroIfNull(worksheetLine.Premium_Rate__c));

        totalHours = CompanyMgmt.zeroIfNull(worksheetLine.Regular_Hours__c) + CompanyMgmt.zeroIfNull(worksheetLine.Overtime_Hours__c) +
                CompanyMgmt.zeroIfNull(worksheetLine.Premium_Hours__c);
        //System.debug(totalHours + ' ' + totalPrice);
        if (totalHours != 0) {
            worksheetLine.Unit_Price__c = CompanyMgmt.halfUpTo3D(totalPrice / totalHours);
        } else {
            worksheetLine.Unit_Price__c = CompanyMgmt.zeroIfNull(worksheetLine.Regular_Rate__c);
        }
    }

    public void calcUnitCost(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        //ticket 20143 <<
        if (worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY && worksheetLine.Resource__r != null && worksheetLine.Resource__r.Name == 'WD' && worksheetLine.Inserted_by_User__c == true) {
            return;
        }
        //ticket 20143 >>

        //System.debug('Info: Billing Worksheet Line calcUnitCost');
        String lineCategory = worksheetLine.Category__c;
        //Boolean usePayRuleCost = false;
        Boolean unitCostFound = false;
        Id resOrResTypeId = null;
        Decimal unitCost = 0;
        Boolean fringeCostUsed = false; //Ticket#22710

        //Sales_Order__c salesOrder = salesOrdersByIds.get(worksheetLine.Sales_Order__c);
        Sales_Order__c salesOrder = salesOrdersByIds.get(salesOrderId);

        //Ticket#19964
        if (lineCategory == ResourceService.SUBCONTRACTORS_CATEGORY) {
            calcSubcontractorUnitCostAndPrice(worksheetLine);
            return;
        }
        //US120369
        if (lineCategory == 'Misc. Charges And Taxes') {
            worksheetLine.Unit_Cost__c = worksheetLine.Unit_Cost__c;
            worksheetLine.Line_Cost__c = worksheetLine.Line_Cost__c;
            return;
        }
        //Ticket#19964

        if (isCalcBaseOnResType(lineCategory) == true) {
            resOrResTypeId = worksheetLine.Resource_Type__c;

            //use resource resource type for unit cost calculation
            if (String.isNotBlank(salesOrder.Pay_Rule__c) && salesOrder.Pay_Rule__r.Type__c != 'Prevailing Wage') {
                if (String.isNotBlank(worksheetLine.Resource__c)) {
                    Resource__c resource = ResourceService.resourcesByIds.get(worksheetLine.Resource__c);
                    if (resource.Resource_Type__c != null) {
                        resOrResTypeId = resource.Resource_Type__c;
                    }
                }
            } //85225
          /* else if(String.isBlank(salesOrder.Pay_Rule__c))
            {
                if (String.isNotBlank(worksheetLine.Resource__c)) {
                    Resource__c resource = ResourceService.resourcesByIds.get(worksheetLine.Resource__c);
                    if (resource.Resource_Type__c != null) {
                        resOrResTypeId = resource.Resource_Type__c;
                    }
                }
                
            }*/
        } else if (isCalcBaseOnResType(lineCategory) == false && worksheetLine.Resource__c != null) {
            resOrResTypeId = worksheetLine.Resource__c;
        }

        if (resOrResTypeId != null) {
            Service_Center__c serviceCenter = new Service_Center__c();
            if (serviceCentersByIds.containsKey(salesOrder.Service_Center__c)) {
                serviceCenter = serviceCentersByIds.get(salesOrder.Service_Center__c);
            }

            //Ticket#19663 >>
            Id payRuleId = null;
            if(payRuleChangeCostUpdate == true && worksheetWrapperPayRuleId != null) {
                payRuleId = worksheetWrapperPayRuleId;
            } else if (String.isNotBlank(salesOrder.Pay_Rule__c)){
                payRuleId = salesOrder.Pay_Rule__c;
            }

            Pay_Rule__c payRule = new Pay_Rule__c();
            if(payRuleId != null) {
                payRule = PayRuleService.payRulesByIds.get(payRuleId);
            }
            //Ticket#19663
            //if (isCalcBaseOnResType(lineCategory) == true && String.isNotBlank(salesOrder.Pay_Rule__c) && salesOrder.Pay_Rule__r.Type__c == 'Prevailing Wage') {
            if (isCalcBaseOnResType(lineCategory) == true && payRule != null && String.isNotBlank(payRule.Id) && payRule.Type__c == 'Prevailing Wage') { //Ticket#19663
                //System.debug('Info: Billing Worksheet Line payRuleId ' + payRuleId);
                if (lineCategory == 'Labor' && payRuleId != null && worksheetLine.TM__r.Scheduled_Date__c != null) {
                    if(worksheetLine.Service_Center__c == null || (worksheetLine.Service_Center__c != null && worksheetLine.Service_Center__r.Temporary__c == true)){
                        //unitCost = getLaborCostWithFringeBenefitByResTypeAndRes(payRuleId, resOrResTypeId, worksheetLine.Resource__c, payRuleId, salesOrder.Service_Center__c, worksheetLine.TM__r.Scheduled_Date__c, worksheetLine.Job_Start_Time__c, worksheetLine.Job_End_Time__c);
                        unitCost = calcLaborCostWithFringeBenefitByResTypeAndRes(payRuleId, salesOrder.Service_Center__c, resOrResTypeId, worksheetLine.TM__r.Scheduled_Date__c, worksheetLine);
                    } else {
                        unitCost = calcLaborCostWithFringeBenefitByResTypeAndRes(payRuleId, worksheetLine.Service_Center__c, resOrResTypeId, worksheetLine.TM__r.Scheduled_Date__c, worksheetLine);
                        //unitCost = getLaborCostWithFringeBenefitByResTypeAndRes(payRuleId, resOrResTypeId, worksheetLine.Resource__c, payRuleId, worksheetLine.Service_Center__c, worksheetLine.TM__r.Scheduled_Date__c, worksheetLine.Job_Start_Time__c, worksheetLine.Job_End_Time__c);
                    }

                    worksheetLine.Non_Travel_Hour_Unit_Cost__c = CompanyMgmt.halfUpTo5D(unitCost); //PW Travel Cost
                    //usePayRuleCost = true;
                    if (unitCost > 0) {
                        unitCostFound = true;
                        worksheetLine.Costing_Source__c = 'Pay Rule';
                        fringeCostUsed = true; //Ticket#22710
                        //PW Travel Cost
                        //Cost Qty. = Total Job Hours - Lunch Hours
                        Decimal jobHours = CompanyMgmt.zeroIfNull(worksheetLine.Cost_Qty__c);
                        Decimal travelHrs = CompanyMgmt.zeroIfNull(worksheetLine.Travel_Hours__c);
                        if(lineCategory == ResourceService.LABOR_CATEGORY && jobHours > 0 && travelHrs > 0){
                            if(String.isNotBlank(defaultCompanySetup.Hour_Unit_of_Measure__c)){
                                worksheetLine.Travel_Hour_Unit_Cost__c = getUnitCost(lineCategory, resOrResTypeId, defaultCompanySetup.Hour_Unit_of_Measure__c);
                            } else {
                                throw new DataException('Please setup a default Hour Unit of Measure in company setup!');
                            }

                            Unit_of_Measure__c unitOfMeasure = new Unit_of_Measure__c();
                            if(String.isNotBlank(worksheetLine.Unit_of_Measure__c)) {
                                if (unitOfMeasuresByIds.containsKey(worksheetLine.Unit_of_Measure__c)) {
                                    unitOfMeasure = unitOfMeasuresByIds.get(worksheetLine.Unit_of_Measure__c);
                                } else {
                                    unitOfMeasure = [SELECT Hours_UOM__c FROM Unit_of_Measure__c WHERE Id = :worksheetLine.Unit_of_Measure__c LIMIT 1];
                                }
                            }

                            if(unitOfMeasure.Hours_UOM__c == true){
                                Decimal travelHrUnitCost = CompanyMgmt.zeroIfNull(worksheetLine.Travel_Hour_Unit_Cost__c);
                                //System.debug('Info: travelHrUnitCost ' + travelHrUnitCost + ' travel hours ==> ' + travelHrs);
                                Decimal totalCost = CompanyMgmt.halfUpTo5D(unitCost * (jobHours - travelHrs));
                                //System.debug('Info: totalCost without travel hours ' + totalCost);
                                totalCost = CompanyMgmt.halfUpTo5D(totalCost + travelHrUnitCost * travelHrs);
                                //System.debug('Info: totalCost with travel hours ' + totalCost);
                                unitCost = CompanyMgmt.halfUpTo3D(totalCost / jobHours);
                                //System.debug('Info: new unitCost ' + unitCost);
                            }
                        }
                        //PW Travel Cost
                    }
                }
            }

            //Use Sales Line Cost
            if(unitCostFound == false && salesOrder != null && worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                Sales_Line__c salesLine = new Sales_Line__c();
                salesLine = getWasteSalesLine(salesOrder, worksheetLine, false);
                /*
                if(String.isBlank(worksheetLine.Cost_Method__c)){
                    salesLine = getSalesLine(salesOrder.Id, resOrResTypeId, worksheetLine.Unit_of_Measure__c);
                } else {
                    salesLine = getWasteSalesLine(salesOrder, worksheetLine, false);
                }
                 */
                if(String.isNotBlank(salesLine.Id)) {
                    if (salesLine.Bill_as_Lump_Sum__c != true && salesLine.Non_Billable__c != true) {
                        unitCost = CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c);
                    }
                    else {
                        unitCost = CompanyMgmt.zeroIfNull(salesLine.xUnit_Cost__c);
                    }
                    if (unitCost > 0) {
                        unitCostFound = true;
                        worksheetLine.Costing_Source__c = 'Order-' + salesOrder.Name;
                    }
                }
            }

            //TM Rate sheet
            if (unitCostFound == false && String.isNotBlank(salesOrder.Rate_Sheet__c)) {
                //TM__c tm = tmsByIds.get(worksheetLine.TM__c);
                //if (tm != null) {
                //    if (tm.Rate_Sheet__c == null) {
                //        tm.Rate_Sheet__c = getEffectiveRateSheetId(worksheetLine.TM__r.Scheduled_Date__c);
                //    }

                //    if (unitCostFound == false && String.isNotBlank(tm.Rate_Sheet__c)) {
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Costing', worksheetLine, salesOrder.Rate_Sheet__c);
                unitCost = RateSheetService.getUnitCost(rateSheetLine);
                if (unitCost > 0) {
                    unitCostFound = true;
                    worksheetLine.Costing_Source__c = salesOrder.Rate_Sheet__r.Name;
                }
                //    }
                //}
            }

            //SC Rate Sheet
            if (unitCostFound == false && String.isNotBlank(serviceCenter.Price_List__c)) {
                Id rateSheetId = null;
                if (worksheetLine.TM__r != null) {
                    rateSheetId = getEffectiveRateSheetId(serviceCenter.Price_List__c, worksheetLine.TM__r.Scheduled_Date__c);
                }
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Costing', worksheetLine, rateSheetId);
                unitCost = RateSheetService.getUnitCost(rateSheetLine);
                if (unitCost > 0) {
                    unitCostFound = true;
                    worksheetLine.Costing_Source__c = 'SC Rate Sheet';
                }
                //System.debug('Info: SC RateSheet Cost unitCostFound ' + unitCostFound);
            }

            //Company Default Rate Sheet
            if (unitCostFound == false && String.isNotBlank(defaultCompanySetup.Price_List__c)) {
                Id rateSheetId = null;
                if (worksheetLine.TM__r != null) {
                    rateSheetId = getEffectiveRateSheetId(defaultCompanySetup.Price_List__c, worksheetLine.TM__r.Scheduled_Date__c);
                }
                Rate_Sheet_Line__c rateSheetLine = getRateSheetLine('Costing', worksheetLine, rateSheetId);
                unitCost = RateSheetService.getUnitCost(rateSheetLine);
                if (unitCost > 0) {
                    unitCostFound = true;
                    worksheetLine.Costing_Source__c = 'Company Rate Sheet';
                }
                //System.debug('Info: Company RateSheet Cost unitCostFound ' + unitCostFound);
            }

            if (unitCostFound == false) {
                /*Ticket#28704
                if (worksheetLine.Category__c == 'Waste Disposal' && worksheetLine.Resource__c == defaultCompanySetup.Default_Manifest_Fee_Resource__c) {
                    if(worksheetLine.Non_Billable__c == true || worksheetLine.Bill_as_Lump_Sum__c == true){
                        unitCost = CompanyMgmt.zeroIfNull(worksheetLine.xUnit_Price__c);
                    } else {
                        unitCost = CompanyMgmt.zeroIfNull(worksheetLine.Unit_Price__c);
                    }
                }
                else if (worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY && String.isNotBlank(worksheetLine.Facility__c)) {
                 */
                if (worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY && String.isNotBlank(worksheetLine.Facility__c)) {
                    ResourceUOMAssociation__c wasteResourceUOMAssociation = getWasteResUOMSetup(worksheetLine);
                    if (wasteResourceUOMAssociation.Id != null) {
                        unitCost = wasteResourceUOMAssociation.Unit_Cost__c;
                        unitCostFound = true;
                        worksheetLine.Costing_Source__c = 'BASE';
                    }
                } else if (worksheetLine.Unit_of_Measure__c != null) {
                    //Ticket#25287 >>
                    if(worksheetLine.Category__c == ResourceService.LABOR_CATEGORY && String.isNotBlank(worksheetLine.Resource__c)){
                        Resource__c res = ResourceService.resourcesByIds.get(worksheetLine.Resource__c);
                        if (String.isNotBlank(res.Resource_Type__c)) {
                            resOrResTypeId = res.Resource_Type__c;
                        }
                    }
                    //Ticket#25287 <<
                    unitCost = getUnitCost(worksheetLine.Category__c, resOrResTypeId, worksheetLine.Unit_of_Measure__c);
                    if (unitCost > 0) {
                        unitCostFound = true;
                        worksheetLine.Costing_Source__c = 'BASE';
                    }
                }
            }

            //Ticket#22710 >>
            if(worksheetLine.Category__c == ResourceService.LABOR_CATEGORY) {
                if (fringeCostUsed != true) {
                    worksheetLine.Regular_Unit_Cost__c = unitCost;
                    worksheetLine.Overtime_Unit_Cost__c = CompanyMgmt.halfUpTo2D(unitCost * CompanyMgmt.zeroIfNull(defaultCompanySetup.Overtime_Unit_Cost_Multiplier__c));
                    worksheetLine.Double_Time_Unit_Cost__c = CompanyMgmt.halfUpTo2D(unitCost * CompanyMgmt.zeroIfNull(defaultCompanySetup.Double_Time_Unit_Cost_Multiplier__c));
                    calcLaborUnitCost(worksheetLine);
                    unitCost = worksheetLine.Unit_Cost__c;
                } else {
                    worksheetLine.Regular_Unit_Cost__c = unitCost;
                    worksheetLine.Overtime_Unit_Cost__c = unitCost;
                    worksheetLine.Double_Time_Unit_Cost__c = unitCost;
                }
            }
            //Ticket#22710 <<

            worksheetLine.Unit_Cost__c = unitCost;
            worksheetLine.xUnit_Cost__c = unitCost;
        }
    }

    public static Decimal calculateLunchHours(String lunchString) {
        Decimal hours = 0;
        if (lunchString == '1/2 Hour') hours = 0.5;
        else if (lunchString == '1 Hour') hours = 1;

        return hours;
    }

    public void calculateCostQty(Billing_Worksheet_Line__c worksheetLine) {
        worksheetLine.Cost_Qty__c = 0;
        Unit_of_Measure__c unitOfMeasure = new Unit_of_Measure__c();
        if(String.isNotBlank(worksheetLine.Unit_of_Measure__c)) {
            if (unitOfMeasuresByIds.containsKey(worksheetLine.Unit_of_Measure__c)) {
                unitOfMeasure = unitOfMeasuresByIds.get(worksheetLine.Unit_of_Measure__c);
            } else {
                unitOfMeasure = [SELECT Hours_UOM__c FROM Unit_of_Measure__c WHERE Id = :worksheetLine.Unit_of_Measure__c LIMIT 1];
            }
        }

        if (String.isNotBlank(unitOfMeasure.Id) && (worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') && (unitOfMeasure.Hours_UOM__c == true)) {
            worksheetLine.Cost_Qty__c = TimeUtils.calculateHours(worksheetLine.Job_Start_Time__c, worksheetLine.Job_End_Time__c) -
                    TimeUtils.calculateHours(worksheetLine.Lunch_Start_Time__c, worksheetLine.Lunch_End_Time__c);
            /*
            if (worksheetLine.Include_Lunch_Y_N__c != true) {
                worksheetLine.Cost_Qty__c -= TimeUtils.calculateHours(worksheetLine.Lunch_Start_Time__c, worksheetLine.Lunch_End_Time__c);
            }
             */
        } else {
            worksheetLine.Cost_Qty__c = CompanyMgmt.zeroIfNull(worksheetLine.Quantity__c);
        }
        /*
        if(worksheetLine.Cost_Qty__c == 0){
            worksheetLine.Cost_Qty__c = CompanyMgmt.zeroIfNull(worksheetLine.Quantity__c);
        }        
         */
    }

    public Decimal getUnitPrice(String category, Id resOrTypeId, Id uomId, Boolean isEmergency) {
        Decimal unitPrice = 0;
        if (isCalcBaseOnResType(category) == true) {
            unitPrice = ResourceTypeUtil.getUnitPrice(resOrTypeId, uomId, isEmergency);
        } else {
            unitPrice = ResourceService.getUnitPrice(resOrTypeId, uomId, isEmergency);
        }
        return unitPrice;
    }

    /* Ticket#19880 replaced by calcLaborCostWithFringeBenefitByResTypeAndRes
    public Decimal getLaborCostWithFringeBenefitByResTypeAndRes(Id resOrResTypeId, Id resId, Id payRuleId, Id serviceCenterId, Date scheduleDate) {
        Decimal unitCost = 0;
        if (resOrResTypeId != null && payRuleId != null) {
            if (payRuleLineByResTypeIdsByPayRuleIds.containsKey(payRuleId)) {
                Pay_Rule_Line__c payRuleLine = new Pay_Rule_Line__c();
                if(payRuleLineByResTypeIdsByPayRuleIds.get(payRuleId).containsKey(resOrResTypeId)) {
                    payRuleLine = payRuleLineByResTypeIdsByPayRuleIds.get(payRuleId).get(resOrResTypeId);
                }

                String payCode = getPayRulePayCodeByDate(payRuleLine, scheduleDate);
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

                //System.debug('Info: payRuleLine ' + payRuleLine);

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
                    //System.debug('Info:unitCost ' + unitCost);
                }
            }
        }
        return unitCost;
    }
    */
    
    public Decimal calcLaborCostWithFringeBenefitByResTypeAndRes(Id payRuleId, Id serviceCenterId, Id resOrResTypeId, Date schedscheduleDate, Billing_Worksheet_Line__c billingWorksheetLine){
        Decimal unitCost = 0;
        if (resOrResTypeId != null && payRuleId != null) {
            String lookupKey = payRuleId + ':' + resOrResTypeId;
            Pay_Rule_Line__c payRuleLine = new Pay_Rule_Line__c();
            //System.debug('Info: lookupKey: ' + lookupKey);
            if (PayRuleService.payRuleLineByPayRuleAndWorkAsResType.containsKey(lookupKey)) {
                payRuleLine = PayRuleService.payRuleLineByPayRuleAndWorkAsResType.get(lookupKey);
                //System.debug('Info: payRuleLine ' + payRuleLine);
                Decimal payRulePayRate = CompanyMgmt.zeroIfNull(payRuleLine.Rate__c);
                Service_Center__c serviceCenter = serviceCentersByIds.get(serviceCenterId);
                Decimal companyCompPct = CompanyMgmt.zeroIfNull(defaultCompanySetup.Workers_Comp_Pct__c) / 100;
                Decimal corpOverHead = CompanyMgmt.zeroIfNull(defaultCompanySetup.Corporate_Overhead__c);
                Decimal serviceCenterTaxRate = CompanyMgmt.zeroIfNull(serviceCenter.Payroll_Tax_Pct__c) / 100;
                Decimal lunchHours = TimeUtils.calculateHours(billingWorksheetLine.Lunch_Start_Time__c, billingWorksheetLine.Lunch_End_Time__c);
                Decimal totalHoursCalculated = 0;
                Decimal totalCost = 0;
                if(payRulePayRate > 0) {
                    Map<String, Decimal> hoursByRateCodes = PayRuleService.calcHoursWithRateCodes(payRuleId, resOrResTypeId, schedscheduleDate, billingWorksheetLine.Site_Start_Time__c, billingWorksheetLine.Site_End_Time__c, billingWorksheetLine.Lunch_Start_Time__c, billingWorksheetLine.Lunch_End_Time__c);
                    //System.debug('Info: hoursByRateCodes ' + hoursByRateCodes);
                    for (String rateCode : hoursByRateCodes.keySet()) {
                        if (rateCode == EnumUtil.TimeRateCode.REG.name()) {
                            /*
                            Decimal regHrs = hoursByRateCodes.get(rateCode);
                            if(lunchHours > 0) {
                                billingWorksheetLine.PW_Regular_Hour_Submitted__c = regHrs - lunchHours;
                                if(billingWorksheetLine.PW_Regular_Hour_Submitted__c < 0){
                                    billingWorksheetLine.PW_Regular_Hour_Submitted__c = 0;
                                    lunchHours = lunchHours - regHrs;
                                }
                            } else {
                                billingWorksheetLine.PW_Regular_Hour_Submitted__c = regHrs;
                            }
                             */
                            billingWorksheetLine.PW_Regular_Hour_Submitted__c = CompanyMgmt.zeroIfNull(hoursByRateCodes.get(rateCode));
                            Decimal regPayRate = payRulePayRate + CompanyMgmt.zeroIfNull(payRuleLine.Fringe__c);
                            Decimal payrollTaxAmt = CompanyMgmt.halfUpTo5D(regPayRate * serviceCenterTaxRate);
                            Decimal workerCompAmt = CompanyMgmt.halfUpTo5D(regPayRate * companyCompPct);
                            billingWorksheetLine.PW_Regular_Hour_Unit_Cost__c = regPayRate + payrollTaxAmt + workerCompAmt + corpOverHead;
                            totalHoursCalculated += billingWorksheetLine.PW_Regular_Hour_Submitted__c;
                            totalCost = totalCost + billingWorksheetLine.PW_Regular_Hour_Submitted__c * billingWorksheetLine.PW_Regular_Hour_Unit_Cost__c;
                        }
                        if (rateCode == EnumUtil.TimeRateCode.OT.name()) {
                            /*
                            Decimal otHours = hoursByRateCodes.get(rateCode);
                            if(lunchHours > 0) {
                                billingWorksheetLine.PW_Overtime_Hour_Submitted__c = otHours - lunchHours;
                                if(billingWorksheetLine.PW_Overtime_Hour_Submitted__c < 0){
                                    billingWorksheetLine.PW_Overtime_Hour_Submitted__c = 0;
                                    lunchHours = lunchHours - otHours;
                                }
                            } else {
                                billingWorksheetLine.PW_Overtime_Hour_Submitted__c = otHours;
                            }
                             */
                            billingWorksheetLine.PW_Overtime_Hour_Submitted__c = CompanyMgmt.zeroIfNull(hoursByRateCodes.get(rateCode));
                            Decimal OTPayRate = 0;
                            if (payRuleLine.Overtime_Rate_Multiple__c != null) {
                                OTPayRate = payRulePayRate * payRuleLine.Overtime_Rate_Multiple__c;
                            } else {
                                OTPayRate = payRulePayRate * 1.5;
                            }
                            OTPayRate = OTPayRate + CompanyMgmt.zeroIfNull(payRuleLine.OT_Fringe_Amount__c);
                            Decimal payrollTaxAmt = CompanyMgmt.halfUpTo5D(OTPayRate * serviceCenterTaxRate);
                            Decimal workerCompAmt = CompanyMgmt.halfUpTo5D(OTPayRate * companyCompPct);
                            billingWorksheetLine.PW_Overtime_Hour_Unit_Cost__c = OTPayRate + payrollTaxAmt + workerCompAmt + corpOverHead;

                            totalHoursCalculated += billingWorksheetLine.PW_Overtime_Hour_Submitted__c;
                            totalCost = totalCost + billingWorksheetLine.PW_Overtime_Hour_Submitted__c * billingWorksheetLine.PW_Overtime_Hour_Unit_Cost__c;
                        }
                        if (rateCode == EnumUtil.TimeRateCode.DT.name()) {
                            /*
                            Decimal dtHours = hoursByRateCodes.get(rateCode);
                            if(lunchHours > 0) {
                                billingWorksheetLine.PW_Double_Time_Hour_Submitted__c = dtHours - lunchHours;
                                if(billingWorksheetLine.PW_Double_Time_Hour_Submitted__c < 0){
                                    billingWorksheetLine.PW_Double_Time_Hour_Submitted__c = 0;
                                    lunchHours = lunchHours - dtHours;
                                }
                            } else {
                                billingWorksheetLine.PW_Double_Time_Hour_Submitted__c = dtHours;
                            }
                             */
                            billingWorksheetLine.PW_Double_Time_Hour_Submitted__c = CompanyMgmt.zeroIfNull(hoursByRateCodes.get(rateCode));
                            Decimal DTPayRate = 0;
                            if (payRuleLine.Double_Time_Rate_Multiple__c != null) {
                                DTPayRate = payRulePayRate * payRuleLine.Double_Time_Rate_Multiple__c;
                            } else {
                                DTPayRate = payRulePayRate * 2;
                            }
                            DTPayRate = DTPayRate + CompanyMgmt.zeroIfNull(payRuleLine.DT_Fringe_Amount__c);
                            Decimal payrollTaxAmt = CompanyMgmt.halfUpTo5D(DTPayRate * serviceCenterTaxRate);
                            Decimal workerCompAmt = CompanyMgmt.halfUpTo5D(DTPayRate * companyCompPct);
                            billingWorksheetLine.PW_Double_Time_Hour_Unit_Cost__c = DTPayRate + payrollTaxAmt + workerCompAmt + corpOverHead;
                            totalHoursCalculated += billingWorksheetLine.PW_Double_Time_Hour_Submitted__c;
                            totalCost = totalCost + billingWorksheetLine.PW_Double_Time_Hour_Submitted__c * billingWorksheetLine.PW_Double_Time_Hour_Unit_Cost__c;
                        }
                    }
                }

                if(totalHoursCalculated > 0){
                    unitCost = CompanyMgmt.halfUpTo5D(totalCost / totalHoursCalculated);
                }
            }
        }
        return unitCost;
    }

    //Ticket#22710
    /* Not needed yet, enable when get cost from Quote Line code is moved.
    public Decimal getLaborUnitCostsUsingFromSalesLine(Billing_Worksheet_Line__c billingWorksheetLine, Sales_Line__c salesLine){
        Decimal unitCost = 0;
        if(billingWorksheetLine.Category__c != 'Labor'){
            return unitCost;
        }
        if (salesLine.Bill_as_Lump_Sum__c != true && salesLine.Non_Billable__c != true) {
            if(CompanyMgmt.zeroIfNull(salesLine.Regular_Unit_Cost__c) > 0){
                unitCost = salesLine.Regular_Unit_Cost__c;
            } else {
                unitCost = CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c);
            }
        }
        else {
            if(CompanyMgmt.zeroIfNull(salesLine.Regular_Unit_Cost__c) > 0){
                unitCost = salesLine.Regular_Unit_Cost__c;
            } else {
                unitCost = CompanyMgmt.zeroIfNull(salesLine.xUnit_Cost__c);
            }
        }
        return unitCost;
    }
     */

    public void calcLaborUnitCost(Billing_Worksheet_Line__c billingWorksheetLine){
        if(billingWorksheetLine.Category__c != 'Labor' || CompanyMgmt.zeroIfNull(billingWorksheetLine.Regular_Unit_Cost__c) == 0){
            return;
        }

        Boolean isDayUOM = false;
        Unit_of_Measure__c unitOfMeasure = new Unit_of_Measure__c();
        if (!String.isBlank(billingWorksheetLine.Unit_of_Measure__c)) {
            if(!unitOfMeasuresByIds.containsKey(billingWorksheetLine.Unit_of_Measure__c)){
                Unit_of_Measure__c uom = UnitOfMeasuresSelector.newInstance().selectById(new Set<Id>{billingWorksheetLine.Unit_of_Measure__c})[0];
                unitOfMeasuresByIds.put(uom.Id, uom);
            }
            unitOfMeasure = unitOfMeasuresByIds.get(billingWorksheetLine.Unit_of_Measure__c);
            //all UOMs except HR should have Regular Cost
            if (unitOfMeasure.Hours_UOM__c != true) {
                billingWorksheetLine.Unit_Cost__c = billingWorksheetLine.Regular_Unit_Cost__c;
                isDayUOM = true;
            }
        }

        if (!isDayUOM) {
            //Calculate Unit Cost
            Decimal totalHours = 0;
            Decimal totalCost = 0;
            Decimal unitCost = 0;
            Decimal lineRegHr = CompanyMgmt.zeroIfNull(billingWorksheetLine.Regular_Hours__c);
            Decimal lineOTHr = CompanyMgmt.zeroIfNull(billingWorksheetLine.Overtime_Hours__c);
            Decimal lineDTHr = CompanyMgmt.zeroIfNull(billingWorksheetLine.Premium_Hours__c);
            Decimal lineRegCost = CompanyMgmt.zeroIfNull(billingWorksheetLine.Regular_Unit_Cost__c);
            Decimal lineOTCost = CompanyMgmt.zeroIfNull(billingWorksheetLine.Overtime_Unit_Cost__c);
            Decimal lineDTCost = CompanyMgmt.zeroIfNull(billingWorksheetLine.Double_Time_Unit_Cost__c);

            if (unitOfMeasure.Hours_UOM__c == true) {
                totalCost = CompanyMgmt.halfUpTo2D((lineRegHr * lineRegCost) +
                        (lineOTHr * lineOTCost) +
                        (lineDTHr * lineDTCost));
                totalHours = lineRegHr + lineOTHr + lineDTHr;
            }

            if (totalHours != 0) {
                unitCost = CompanyMgmt.halfUpTo5D(totalCost / totalHours);
            } else {
                unitCost = CompanyMgmt.zeroIfNull(billingWorksheetLine.Regular_Unit_Cost__c);
            }
            billingWorksheetLine.Unit_Cost__c = unitCost;
        }
        billingWorksheetLine.xUnit_Cost__c = billingWorksheetLine.Unit_Cost__c;
    }

    //Ticket#19964
    public void calcSubcontractorUnitCostAndPrice(Billing_Worksheet_Line__c billingWorksheetLine){
        Boolean unitCostFound = false;
        String source = '';
        if(billingWorksheetLine.Category__c != ResourceService.SUBCONTRACTORS_CATEGORY){
            return;
        }

        Sales_Line__c salesLine = new Sales_Line__c();
        if(String.isNotBlank(billingWorksheetLine.Sales_Line__c)){
            salesLine = salesLinesByIds.get(billingWorksheetLine.Sales_Line__c);
            if(CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c) > 0){
                unitCostFound = true;
                source = 'Order-' + salesLine.Sales_Order__r.Name;
            }
        }

        if(unitCostFound == false && String.isNotBlank(billingWorksheetLine.Quote_Line__c)){
            salesLine = salesLinesByIds.get(billingWorksheetLine.Quote_Line__c);
            if(CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c) > 0){
                unitCostFound = true;
                source = salesLine.Sales_Order__r.Name;
            }
        }

        if(unitCostFound == false && String.isNotBlank(billingWorksheetLine.Description__c)){
            salesLine = getSalesLineByLineDesc(billingWorksheetLine.Description__c);
            if(salesLine.Id != null && CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c) > 0){
                unitCostFound = true;
                if(salesLine.Sales_Order__r.Name.contains('Quote')){
                    source = salesLine.Sales_Order__r.Name;
                } else {
                    source = 'Order-' + salesLine.Sales_Order__r.Name;
                }
            }
        }

        if(unitCostFound == true){
            Decimal unitCost = salesLine.Unit_Cost__c;
            Decimal unitPrice = 0;

            if(String.isNotBlank(billingWorksheetLine.Markup_Option__c) && CompanyMgmt.zeroIfNull(billingWorksheetLine.Markup__c) > 0){
                if(billingWorksheetLine.Markup_Option__c == '%'){
                    unitPrice = CompanyMgmt.halfUpTo2D(unitCost + (unitCost * billingWorksheetLine.Markup__c / 100));
                } else if (billingWorksheetLine.Markup_Option__c == 'Amount'){
                    unitPrice = unitCost + billingWorksheetLine.Markup__c;
                }
            } else {
                unitPrice = unitCost;
            }

            if (billingWorksheetLine.Bill_as_Lump_Sum__c == true || billingWorksheetLine.Non_Billable__c == true) {
                billingWorksheetLine.xUnit_Cost__c = unitCost;
                billingWorksheetLine.xUnit_Price__c = unitPrice;
            } else {
                billingWorksheetLine.Unit_Cost__c = unitCost;
                billingWorksheetLine.Unit_Price__c = unitPrice;
            }
            billingWorksheetLine.Pricing_Source_2__c = source;
            billingWorksheetLine.Costing_Source__c = source;
        }
    }

    public Decimal getUnitCost(String category, Id resOrTypeId, Id uomId) {
        Decimal unitCost = 0;
        if (isCalcBaseOnResType(category) == true) {
            unitCost = ResourceTypeUtil.getUnitCost(resOrTypeId, uomId);
        } else {
            unitCost = ResourceService.getUnitCost(resOrTypeId, uomId);
        }
        return unitCost;
    }

    public void assignDescription(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        Boolean contractLineDescriptionFound = false;
        Sales_Order__c salesOrder = salesOrdersByIds.get(salesOrderId);
        if(String.isNotBlank(salesOrder.Contract__c) && worksheetLine.Contract_Line__c != null) {
            Contract_Line__c contractLine = ContractUtil.getContractLine(worksheetLine.Contract_Line__c);
            String billingDescription = ContractUtil.generateLineDescription(worksheetLine.Description__c, contractLine.Customer_Item_No__c, contractLine.Customer_Description__c);
            if(billingDescription != worksheetLine.Description__c){
                worksheetLine.Description__c = billingDescription;
                contractLineDescriptionFound = true;
            }
            //Ticket#22008
            else if (String.isNotBlank(contractLine.Customer_Description__c) && (contractLine.Customer_Description__c == worksheetLine.Description__c)) {
                contractLineDescriptionFound = true;
            }
        }

        if (!contractLineDescriptionFound) {
            Id resOrResTypeId = getResOrResTypeId(worksheetLine);
            if (isCalcBaseOnResType(worksheetLine.Category__c)) {
                Resource_Type__c resourceType = ResourceTypeUtil.getResourceType(worksheetLine.Resource_Type__c);
                if (String.isNotBlank(resourceType.Id)) {
                    worksheetLine.Description__c = resourceType.Description__c;
                }
            } else {
                if (ResourceService.resourcesByIds.containsKey(resOrResTypeId)) {
                    Resource__c resource = ResourceService.resourcesByIds.get(resOrResTypeId);
                    if (String.isNotBlank(resource.Description__c)) {
                        worksheetLine.Description__c = resource.Description__c;
                    }
                }
            }
        }

        if (!contractLineDescriptionFound) {
            Id resOrTypeId = null;
            Boolean wasteLineSpecialTreatment = false;
            if(isCalcBaseOnResType(worksheetLine.Category__c) == true && worksheetLine.Resource_Type__c != null) {
                resOrTypeId = worksheetLine.Resource_Type__c;
            } else if(isCalcBaseOnResType(worksheetLine.Category__c) == false && worksheetLine.Resource__c != null) {
                resOrTypeId = worksheetLine.Resource__c;

                if(worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                    wasteLineSpecialTreatment = true;
                }
            }

            Sales_Line__c salesLine = new Sales_Line__c();
            if (worksheetLine.Sales_Line__c != null) {
                salesLine = getSalesLine(worksheetLine.Sales_Line__c);
            }

            if (String.isBlank(salesLine.Id)) {
                if (wasteLineSpecialTreatment == true) {
                    salesLine = getWasteSalesLine(salesOrder, worksheetLine, false);
                } else if (worksheetLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY) {
                    salesLine = getSalesLineByLineDesc(worksheetLine.Description__c);
                } else {
                    salesLine = getSalesLine(salesOrder.Id, resOrTypeId, worksheetLine.Unit_of_Measure__c);
                }
            }

            if (String.isNotBlank(salesLine.Id)) {
                worksheetLine.Description__c = salesLine.Description__c;
            }
        }
    }

    public Sales_Line__c getWasteSalesLine(Sales_Order__c salesOrder, Billing_Worksheet_Line__c worksheetLine, Boolean useQuoteIdAsLookupKey){
        Sales_Line__c salesLine = new Sales_Line__c();
        Id lineLookupId = worksheetLine.Sales_Line__c;
        if(useQuoteIdAsLookupKey == true){
            lineLookupId = worksheetLine.Quote_Line__c;
        }
        if(String.isNotBlank(lineLookupId) && salesLinesByIds.containsKey(lineLookupId)){
            salesLine = salesLinesByIds.get(lineLookupId);
        } else {
            //Key = Sales Order Id:Res Id:Facility:Unit Weight Volume:Container Size
            String facilityId = 'null';
            /*Waste001
            String unitWeightVolId = 'null';
            String containerSizeId = 'null';
             */
            String uomId = 'null';
            if(String.isNotBlank(worksheetLine.Facility__c)){
                facilityId = worksheetLine.Facility__c;
            }

            /*Waste001
            if(String.isNotBlank(worksheetLine.Unit_Weight_Vol__c)){
                unitWeightVolId = worksheetLine.Unit_Weight_Vol__c;
            }
            if(String.isNotBlank(worksheetLine.Container_Size__c)){
                containerSizeId = worksheetLine.Container_Size__c;
            }
             */

            if(String.isNotBlank(worksheetLine.Unit_of_Measure__c)){
                uomId = worksheetLine.Unit_of_Measure__c;
            }
            String recordId = salesOrder.Id;
            if(useQuoteIdAsLookupKey == true){
                recordId = salesOrder.From_Sales_Quote__c;
            }
            /*Waste001
            String lookupKey = '';
            if(worksheetLine.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name() || worksheetLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) {
                lookupKey = recordId + ':' + worksheetLine.Resource__c + ':' + facilityId + ':' + unitWeightVolId + ':' + containerSizeId;
            } else {
                lookupKey = recordId + ':' + worksheetLine.Resource__c + ':' + facilityId + ':' + uomId;
            }
             */
            String lookupKey = recordId + ':' + worksheetLine.Resource__c + ':' + facilityId + ':' + uomId;
            //System.debug('Info: lookupKey ' + lookupKey);
            //for(String mapKey : wasteSalesLinesBySalesOrderResFacilityUwvContainerSize.keySet()){
            //    System.debug('Info: mapKey ' + mapKey);
            //    System.debug('Info: value ' + wasteSalesLinesBySalesOrderResFacilityUwvContainerSize.get(mapKey));
            //}
            if(wasteSalesLinesBySalesOrderResFacilityUwvContainerSize.containsKey(lookupKey)){
                salesLine = wasteSalesLinesBySalesOrderResFacilityUwvContainerSize.get(lookupKey);
            }
        }
        return salesLine;
    }

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

    public Id getResOrResTypeId(Billing_Worksheet_Line__c worksheetLine){
        if (isCalcBaseOnResType(worksheetLine.Category__c) == true) {
            return worksheetLine.Resource_Type__c;
        } else {
            return worksheetLine.Resource__c;
        }
    }

    public void validateContractLine(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine){
        if(String.isNotBlank(worksheetLine.Contract_Line__c)){
            Contract_Line__c contractLine = new Contract_Line__c();
            if (worksheetLine.TM__r != null) {
                contractLine = ContractUtil.getContractLine(worksheetLine.Contract_Line__c, worksheetLine.TM__r.Scheduled_Date__c);
                if (String.isNotBlank(contractLine.Id)) {
                    worksheetLine.Contract_Line__c = contractLine.Id;
                    worksheetLine.Contract_Line__r = new Contract_Line__c(Id = contractLine.Id, Name = contractLine.Name);
                    worksheetLine.Contract_Regular_Rate__c = contractLine.Regular_Rate__c;
                    worksheetLine.Contract_Overtime_Rate__c = contractLine.Overtime_Rate__c;
                    worksheetLine.Contract_Premium_Rate__c = contractLine.Premium_Rate__c;
                    if (worksheetLine.Category__c == ResourceService.LABOR_CATEGORY) {
                        worksheetLine.Unit_of_Measure__c = contractLine.Unit_of_Measure__c;
                        worksheetLine.Regular_Rate__c = contractLine.Regular_Rate__c;
                        worksheetLine.Overtime_Rate__c = contractLine.Overtime_Rate__c;
                        worksheetLine.Premium_Rate__c = contractLine.Premium_Rate__c;
                        calcLaborUnitPrice(worksheetLine);
                    } else if (worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                        worksheetLine.Unit_Price__c = contractLine.Regular_Rate__c;
                        worksheetLine.Min_Sell_Qty__c = contractLine.Min_Sell_Qty__c;
                        worksheetLine.Facility__c = contractLine.Facility__c;
                    } else {
                        worksheetLine.Unit_Price__c = contractLine.Regular_Rate__c;
                        worksheetLine.Unit_of_Measure__c = contractLine.Unit_of_Measure__c;
                    }
                    worksheetLine.Contract_Line__c = contractLine.Id;
                    worksheetLine.Pricing_Source_2__c = contractLine.Contract__r.Name;
                }
            }
        }
    }

    public void calculateLineTotals(Billing_Worksheet_Line__c worksheetLine, Boolean reCalCostQty) {
        //Sales_Order__c salesOrder = salesOrdersByIds.get(worksheetLine.Sales_Order__c);

        if(reCalCostQty == true) {
            calculateCostQty(worksheetLine);
        }

        Decimal unitPrice = 0;
        Decimal regulateRate = 0;
        Decimal overtimeRate = 0;
        Decimal doubleTimeRate = 0;
        Decimal unitCost = 0;

        Decimal regularHours = CompanyMgmt.zeroIfNull(worksheetLine.Regular_Hours__c);
        Decimal overtimeHours = CompanyMgmt.zeroIfNull(worksheetLine.Overtime_Hours__c);
        Decimal doubleTimeHours = CompanyMgmt.zeroIfNull(worksheetLine.Premium_Hours__c);
        Decimal qty = CompanyMgmt.zeroIfNull(worksheetLine.Quantity__c);
        Decimal minSellQty = CompanyMgmt.zeroIfNull(worksheetLine.Min_Sell_Qty__c);
        Decimal markup = CompanyMgmt.zeroIfNull(worksheetLine.Markup__c);
        Decimal costQty = CompanyMgmt.zeroIfNull(worksheetLine.Cost_Qty__c);
        //Decimal taxRate = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, worksheetLine.Tax_Group__c);

        if (worksheetLine.Bill_as_Lump_Sum__c != true && worksheetLine.Non_Billable__c != true) {
            unitPrice = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(worksheetLine.Unit_Price__c));
            unitCost = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(worksheetLine.Unit_Cost__c));
            regulateRate = CompanyMgmt.zeroIfNull(worksheetLine.Regular_Rate__c);
            overtimeRate = CompanyMgmt.zeroIfNull(worksheetLine.Overtime_Rate__c);
            doubleTimeRate = CompanyMgmt.zeroIfNull(worksheetLine.Premium_Rate__c);
        }
        else {
            unitPrice = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(worksheetLine.xUnit_Price__c));
            unitCost = CompanyMgmt.halfUpTo5D(CompanyMgmt.zeroIfNull(worksheetLine.xUnit_Cost__c));
            regulateRate = CompanyMgmt.zeroIfNull(worksheetLine.xRegular_Rate__c);
            overtimeRate = CompanyMgmt.zeroIfNull(worksheetLine.xOvertime_Rate__c);
            doubleTimeRate = CompanyMgmt.zeroIfNull(worksheetLine.xPremium_Rate__c);
        }

        /* move out
        if (salesOrder.Tax_Liable__c && worksheetLine.Tax_Group__c != null) {
            worksheetLine.Tax_Pct__c = taxRate;
        } else {
            worksheetLine.Tax_Pct__c = 0;
        }*/

        Decimal lineAmount = 0;
        if (worksheetLine.Category__c == 'Labor') {
            if(worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                lineAmount = CompanyMgmt.halfUpTo2D(regulateRate * regularHours)
                        + CompanyMgmt.halfUpTo2D(overtimeRate * overtimeHours)
                        + CompanyMgmt.halfUpTo2D(doubleTimeRate * doubleTimeHours);
            } else {
                lineAmount = regulateRate * qty;
            }
        }
        else {
            lineAmount = unitPrice * qty;
            if (worksheetLine.Category__c == 'Waste Disposal' && minSellQty > qty) {
                lineAmount = unitPrice * minSellQty;
            }

            if(worksheetLine.Category__c != ResourceService.SUBCONTRACTORS_CATEGORY) {
                if (worksheetLine.Markup_Option__c == '%') {
                    lineAmount += (lineAmount * markup / 100);
                } else if (worksheetLine.Markup_Option__c == 'Amount') {
                    lineAmount += markup;
                }
            }
        }
        Decimal lineCost = CompanyMgmt.halfUpTo2D(unitCost * costQty);

        worksheetLine.Line_Amount__c = CompanyMgmt.halfUpTo2D(lineAmount);
        worksheetLine.Tax__c = CompanyMgmt.halfUpTo2D(lineAmount * CompanyMgmt.zeroIfNull(worksheetLine.Tax_Pct__c) / 100);
        worksheetLine.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(worksheetLine.Line_Amount__c + worksheetLine.Tax__c);
        worksheetLine.Line_Cost__c = lineCost;
        worksheetLine.xLine_Amount__c = worksheetLine.Line_Amount__c;
        worksheetLine.xLine_Cost__c = worksheetLine.Line_Cost__c;

        if (worksheetLine.Bill_as_Lump_Sum__c == true || worksheetLine.Non_Billable__c == true) {
            worksheetLine.Line_Amount__c = 0;
            worksheetLine.Tax__c = 0;
            worksheetLine.Line_Amt_Incl_Tax__c = 0;
            //worksheetLine.Line_Cost__c = 0;
        }
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

    public Sales_Line__c getSalesLine(Id salesLineId) {
        return salesLinesByIds.get(salesLineId);
    }

    /*
    public String getPayRulePayCodeByDate(Pay_Rule_Line__c payRuleLine, Date scheduledDate) {
        String paycode = EnumUtil.TimeRateCode.REG.name();

        if (scheduledDate != null) {
            String dayName = '';
            dayName = TimeUtils.getDatetimeInUserTZ(scheduledDate).format('EEEE');
            //System.debug('Info: Default dayName ' + dayName);
            if (dayName == 'Sunday' && payRuleLine.Sunday_Pay_Code__c != null) paycode = payRuleLine.Sunday_Pay_Code__c;
            if (dayName == 'Saturday' && payRuleLine.Saturday_Pay_Code__c != null) paycode = payRuleLine.Saturday_Pay_Code__c;
            if (holidaysByDates.containsKey(scheduledDate)) {
                String holidayName = holidaysByDates.get(scheduledDate).Holiday__c;
                if(String.isNotBlank(payRuleLine.Holiday_with_Double_Time_Pay__c)){
                    if (payRuleLine.Holiday_with_Double_Time_Pay__c.contains(holidayName)) {
                        paycode = EnumUtil.TimeRateCode.DT.name();
                    }
                }

                if(String.isNotBlank(payRuleLine.Holidays_with_Overtime_Pay__c)) {
                    if (payRuleLine.Holidays_with_Overtime_Pay__c.contains(holidayName)) {
                        paycode = EnumUtil.TimeRateCode.OT.name();
                    }
                }
            }
        }
        return paycode;
    }
     */

    public ResourceUOMAssociation__c getWasteResUOMSetup(Billing_Worksheet_Line__c worksheetLine) {
        ResourceUOMAssociation__c wasteResUOMSetup = new ResourceUOMAssociation__c();
        Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = new Map<Id, List<ResourceUOMAssociation__c>>();
        if (worksheetLine.Category__c != 'Waste Disposal') {
            return null;
        }

        if (ResourceService.resourceUOMAssociationsByUOMIdsByResIds.containsKey(worksheetLine.Resource__c)) {
            resourceUOMAssociationsByUOMIds = ResourceService.resourceUOMAssociationsByUOMIdsByResIds.get(worksheetLine.Resource__c);
        }

        if (worksheetLine.System_Calculated_Line__c == true && worksheetLine.Resource__c == defaultCompanySetup.Default_Manifest_Fee_Resource__c) {
            if (resourceUOMAssociationsByUOMIds.containsKey(worksheetLine.Unit_of_Measure__c)) {
                List<ResourceUOMAssociation__c> resourceUOMAssociations = resourceUOMAssociationsByUOMIds.get(worksheetLine.Unit_of_Measure__c);
                if (resourceUOMAssociations.size() > 0) {
                    wasteResUOMSetup = resourceUOMAssociations[0];
                }
            }
            //return wasteResUOMSetup;
        } else {
            /*Waste001
            wasteResUOMSetup = ResourceService.getWasteResUOMSetup(worksheetLine.Resource__c,
                    worksheetLine.Unit_of_Measure__c,
                    worksheetLine.Unit_Weight_Vol__c,
                    worksheetLine.Container_Size__c,
                    worksheetLine.Facility__c,
                    worksheetLine.Cost_Method__c);
             */
            wasteResUOMSetup = ResourceService.getWasteResUOMSetup(worksheetLine.Resource__c,
                    worksheetLine.Unit_of_Measure__c,
                    worksheetLine.Facility__c);
        }

        return wasteResUOMSetup;
    }

    public void assignResourceTypeUOM(Billing_Worksheet_Line__c worksheetLine) {
        if (isCalcBaseOnResType(worksheetLine.Category__c) == true && worksheetLine.Resource_Type__c != null && worksheetLine.Unit_of_Measure__c != null) {
            ResourceTypeUOMAssociation__c resourceTypeUOMAssociation = ResourceTypeUtil.getResourceTypeUOMAssociation(worksheetLine.Resource_Type__c, worksheetLine.Unit_of_Measure__c);
            if(resourceTypeUOMAssociation.Id != null){
                worksheetLine.Resource_Type_UOM__c = resourceTypeUOMAssociation.Id;
            }
        }
    }

    public void assignResourceUOM(Billing_Worksheet_Line__c worksheetLine) {
        if (isCalcBaseOnResType(worksheetLine.Category__c) == false && worksheetLine.Resource__c != null && worksheetLine.Unit_of_Measure__c != null) {
            ResourceUOMAssociation__c resourceUOMAssociation = new ResourceUOMAssociation__c();
            if (worksheetLine.Category__c == 'Waste Disposal') {
                resourceUOMAssociation = getWasteResUOMSetup(worksheetLine);
            } else if(ResourceService.resourceUOMAssociationsByUOMIdsByResIds.containsKey(worksheetLine.Resource__c)){
                Map<Id, List<ResourceUOMAssociation__c>> resourceUOMAssociationsByUOMIds = ResourceService.resourceUOMAssociationsByUOMIdsByResIds.get(worksheetLine.Resource__c);
                if (resourceUOMAssociationsByUOMIds.containsKey(worksheetLine.Unit_of_Measure__c)) {
                    resourceUOMAssociation = resourceUOMAssociationsByUOMIds.get(worksheetLine.Unit_of_Measure__c)[0];
                }
            }
            worksheetLine.Resource_UOM__c = resourceUOMAssociation.Id;
        }
    }

    public void assignTaxPercent(Id salesOrderId, Billing_Worksheet_Line__c worksheetLine) {
        //Sales_Order__c  salesOrder = salesOrdersByIds.get(worksheetLine.Sales_Order__c);
        Sales_Order__c  salesOrder = salesOrdersByIds.get(salesOrderId);
        //if (salesOrder.Tax_Liable__c && worksheetLine.Tax_Group__c != null) {
        if (worksheetLine.Tax_Group__c != null && worksheetLine.Tax_Group__c == 'TX') {

            //worksheetLine.Tax_Pct__c = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, worksheetLine.Tax_Group__c);
            worksheetLine.Tax_Pct__c = TaxService.getTaxPct(salesOrder.Tax_Area__c, worksheetLine.Tax_Group__c);

        }
        else {
            worksheetLine.Tax_Pct__c = 0;
        }
    }

    public Id getEffectiveRateSheetId(Id priceListId, Date dt) {
        Id rateSheetId;
        for (Pricing_Rate_Sheet_Association__c pricingRateSheetAssociation : pricingRateSheetAssociations) {
            if (pricingRateSheetAssociation.Pricing__c == priceListId && dt >= pricingRateSheetAssociation.Effective_Date__c) {
                rateSheetId = pricingRateSheetAssociation.Rate_Sheet__c;
                break;
            }
        }
        return rateSheetId;
    }

    public Id getEffectiveRateSheetId(Date dt) {
        Id rateSheetId;
        for (Pricing_Rate_Sheet_Association__c pricingRateSheetAssociation : pricingRateSheetAssociations) {
            if (dt >= pricingRateSheetAssociation.Effective_Date__c) {
                rateSheetId = pricingRateSheetAssociation.Rate_Sheet__c;
                break;
            }
        }
        return rateSheetId;
    }

    public Rate_Sheet_Line__c getRateSheetLine(String useForType, Billing_Worksheet_Line__c worksheetLine, Id rateSheetId) {
        Rate_Sheet_Line__c rateSheetLine = new Rate_Sheet_Line__c();
        if (rateSheetId != null) {
            if (worksheetLine.Category__c == 'Waste Disposal') {
                /*Waste001
                Id lookupUOMId = null;
                if (worksheetLine.Category__c != 'Waste Disposal') return null;
                if (worksheetLine.Resource__c == null || worksheetLine.Cost_Method__c == null) return null;
                if (worksheetLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()) lookupUOMId = worksheetLine.Unit_Weight_Vol__c;
                if (worksheetLine.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name()) lookupUOMId = worksheetLine.Container_Size__c;
                rateSheetLine = RateSheetService.getWasteRateSheetLine(rateSheetId,
                        worksheetLine.Resource__c, worksheetLine.Cost_Method__c,
                        lookupUOMId, worksheetLine.Facility__c, worksheetLine.Container_Size__c);
                 */
                rateSheetLine = RateSheetService.getWasteRateSheetLine(rateSheetId, worksheetLine.Resource__c,
                        worksheetLine.Unit_of_Measure__c, worksheetLine.Facility__c);
            } else {
                Id resOrTypeId = null;
                if (isCalcBaseOnResType(worksheetLine.Category__c) == true) {
                    if (String.isNotBlank(worksheetLine.Resource_Type__c)) {
                        resOrTypeId = worksheetLine.Resource_Type__c;
                    }

                    if (useForType == 'Costing') {
                        if (String.isNotBlank(worksheetLine.Resource__c)) {
                            Resource__c res = ResourceService.resourcesByIds.get(worksheetLine.Resource__c);
                            if (String.isNotBlank(res.Resource_Type__c)) {
                                resOrTypeId = res.Resource_Type__c;
                            }
                        }
                    }
                } else if (isCalcBaseOnResType(worksheetLine.Category__c) == false && String.isNotBlank(worksheetLine.Resource__c)) {
                    resOrTypeId = worksheetLine.Resource__c;
                }
                rateSheetLine = RateSheetService.getRateSheetLine(rateSheetId, resOrTypeId, worksheetLine.Unit_of_Measure__c);
            }
        }
        return rateSheetLine;
    }

    //ticket 19130 << billing worksheet presumptive resources are not need for this phase, disable
    /*
    public List<Billing_Worksheet_Line__c> calculatePresumptiveChildLines(Billing_Worksheet_Line__c worksheetLine, Integer nextWorksheetLineNo) {
        List<Billing_Worksheet_Line__c> childLines = new List<Billing_Worksheet_Line__c>();
        if (mapPresumptiveResourcesByParentId.containsKey(worksheetLine.Resource_Type__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(worksheetLine.Resource_Type__c);
            childLines = insertPresumptiveChildLines(worksheetLine, presumptiveResources, nextWorksheetLineNo);
        } else if (mapPresumptiveResourcesByParentId.containsKey(worksheetLine.Resource__c)) { //is presumptive resource
            List<Presumptive_Resource__c> presumptiveResources = mapPresumptiveResourcesByParentId.get(worksheetLine.Resource__c);
            childLines = insertPresumptiveChildLines(worksheetLine, presumptiveResources, nextWorksheetLineNo);
        }
        return childLines;
    }

    private List<Billing_Worksheet_Line__c> insertPresumptiveChildLines(Billing_Worksheet_Line__c parentLine, List<Presumptive_Resource__c> presumptiveResources, Integer nextWorksheetLineNo) {
        List<Billing_Worksheet_Line__c> worksheetLines = new List<Billing_Worksheet_Line__c>();

        for (Presumptive_Resource__c presumptiveResource : presumptiveResources) {
            if (presumptiveResource.Child_Resource_Type__c != null || presumptiveResource.Child_Resource__c != null) {
                Billing_Worksheet_Line__c worksheetLine = new Billing_Worksheet_Line__c();
                worksheetLine.Line_No__c = nextWorksheetLineNo;
                worksheetLine.TM__c = parentLine.TM__c;
                worksheetLine.TM__r = parentLine.TM__r;
                worksheetLine.TM_Job_Task__c = parentLine.TM_Job_Task__c;
                worksheetLine.TM_Job_Task__r = parentLine.TM_Job_Task__r;
                worksheetLine.Sales_Order__c = parentLine.Sales_Order__c;
                worksheetLine.Sales_Order__r = parentLine.Sales_Order__r;
                worksheetLine.Sales_Order_Job_Task__c = parentLine.Sales_Order_Job_Task__c;
                worksheetLine.Sales_Order_Job_Task__r = parentLine.Sales_Order_Job_Task__r;

                if (presumptiveResource.Child_Resource_Type__c != null && ResourceTypeUtil.resourceTypesByIds.containsKey(presumptiveResource.Child_Resource_Type__c)) {
                    Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource_Type__c);
                    worksheetLine.Category__c = resourceType.Category__c;
                    worksheetLine.Resource_Type__c = resourceType.Id;
                    worksheetLine.Resource_Type__r = resourceType;
                    worksheetLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                    worksheetLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                    worksheetLine.Description__c = resourceType.Description__c;
                } else if (presumptiveResource.Child_Resource__c != null && ResourceService.resourcesByIds.containsKey(presumptiveResource.Child_Resource__c)) {
                    Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(presumptiveResource.Child_Resource__r.Resource_Type__c);
                    Resource__c resource = ResourceService.resourcesByIds.get(presumptiveResource.Child_Resource__c);
                    worksheetLine.Category__c = resource.Category__c;
                    if (resourceType != null) {
                        worksheetLine.Resource_Type__c = resourceType.Id;
                        worksheetLine.Resource_Type__r = resourceType;
                        worksheetLine.Description__c = resourceType.Description__c;
                    }
                    if (worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') {
                        worksheetLine.Resource_Name__c = resource.Description__c;
                    }
                    else {
                        worksheetLine.Description__c = resource.Description__c;
                    }
                    worksheetLine.Resource__c = resource.Id;
                    worksheetLine.Resource__r = resource;
                    worksheetLine.Unit_of_Measure__c = presumptiveResource.Child_Unit_of_Measure__c;
                    worksheetLine.Unit_of_Measure__r = presumptiveResource.Child_Unit_of_Measure__r;
                }

                if (worksheetLine.Category__c == 'Labor' || worksheetLine.Category__c == 'Equipment') {
                    if (worksheetLine.Resource__r != null) {
                        worksheetLine.Resource_Name__c = worksheetLine.Resource__r.Description__c;
                    }
                    worksheetLine.Service_Center__c = parentLine.Service_Center__c;
                    worksheetLine.Service_Center__r = parentLine.Service_Center__r;
                }

                worksheetLine.Tax_Group__c = parentLine.Tax_Group__c;
                worksheetLine.Parent_Line__c = parentLine.Id;
                worksheetLine.Parent_Line__r = new Billing_Worksheet_Line__c(Id = parentLine.Id, Line_No__c = parentLine.Line_No__c);

                worksheetLines.add(worksheetLine);
                nextWorksheetLineNo++;
            }
        }
        return worksheetLines;
    }
    */
    //ticket 19130 >>

    public void setSalesOrderByIdsMap(Set<Id> salesOrdIds) {
        salesOrdersByIds.putAll(SalesOrdersSelector.newInstance().selectById(salesOrdIds));
    }

    public void setUnitOfMeasureByIdsMap(Set<Id> uomIds) {
        unitOfMeasuresByIds.putAll(UnitOfMeasuresSelector.newInstance().selectById(uomIds));
    }

    public void setServiceCenterByIdsMap() {
        serviceCentersByIds.putAll(ServiceCentersSelector.newInstance().selectAll());
    }

    public void setSalesLinesByResOrTypeIdsBySalesOrderIdsMap(Set<Id> salesOrderIds) {
        List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesBySalesOrderId(salesOrderIds);
        for (Sales_Line__c salesLine : salesLines) {
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
                /*Waste001
                String mapKey = '';
                if(salesLine.Cost_Method__c == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name() || salesLine.Cost_Method__c == EnumUtil.CostMethod.CONTAINER.name()){
                    mapKey = salesLine.Sales_Order__c + ':' + salesLine.Resource__c + ':' + salesLine.Facility__c + ':' + salesLine.Unit_Weight_Vol__c
                            + ':' + salesLine.Container_Size__c;
                } else {
                    mapKey = salesLine.Sales_Order__c + ':' + salesLine.Resource__c + ':' + salesLine.Facility__c + ':' + salesLine.Unit_of_Measure__c;
                }
                 */
                String mapKey = salesLine.Sales_Order__c + ':' + salesLine.Resource__c + ':' + salesLine.Facility__c + ':' + salesLine.Unit_of_Measure__c;
                if(wasteSalesLinesBySalesOrderResFacilityUwvContainerSize.containsKey(mapKey)){
                    continue;
                } else {
                    wasteSalesLinesBySalesOrderResFacilityUwvContainerSize.put(mapKey, salesLine);
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

    /* Moved to Payrule Service
    public void setPayRuleLinesByResTypeIdsByPayRuleIdsMap(Set<Id> payRuleIds) {
        List<Pay_Rule__c> payRules = PayRulesSelector.newInstance().selectPayRulesByIdWithLines(payRuleIds);
        for (Pay_Rule__c payRule : payRules) {
            Map<Id, Pay_Rule_Line__c> payRuleLineByResTypeIds = new Map<Id, Pay_Rule_Line__c>();
            for (Pay_Rule_Line__c payRuleLine : payRule.Pay_Rule_Lines__r) {
                payRuleLineByResTypeIds.put(payRuleLine.Resource_Type__c, payRuleLine);
            }
            payRuleLineByResTypeIdsByPayRuleIds.put(payRule.Id, payRuleLineByResTypeIds);
            payRulesByIds.put(payRule.Id, payRule); //Ticket#19663
        }
    }
     */

    public void setHolidaysByIdsMap() {
        holidaysByDates = HolidaysSelector.newInstance().getHolidaysByDates();
    }

    public Boolean isCalcBaseOnResType(String lineCategory) {
        if(lineCategory == 'Labor' || lineCategory == 'Equipment' || lineCategory == 'Bundled') {
            return true;
        } else {
            return  false;
        }
    }

    public void setBillingRulesByAssumptions() {
        for (Billing_Rule__c billingRule : BillingRulesSelector.newInstance().selectByAssumptions()) {
            if (billingRule.Quote_Order_Assumption__c != null) {
                for (String assumption : billingRule.Quote_Order_Assumption__c.split(';')) { //Quote_Order_Assumption__c is a multi picklist
                    mapBillingRulesByAssumption.put(assumption, billingRule);
                }
            }
        }
    }

    public void validateSalesInvoice(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers) {
        Sales_Order__c salesOrder = salesOrdersByIds.get(salesOrderId);
        /*if (String.isBlank(salesOrder.Bill_to_Customer_No__r.AccountNumber)) {
            throw new DataException('Bill-to customer\'s NAV account number must not be blank.');
        }*/
        if (salesOrder.Bill_to_Customer_No__r.Payment_Term__c == null) {
            throw new DataException('Bill-to customer\'s payment term must not be blank.');
        }

        List<String> blankTaxAreaTMs = new List<String>();
        List<String> blankServiceCenterTMs = new List<String>();
        List<Integer> zeroQuantityLines = new List<Integer>();
        List<Integer> zeroUnitPriceLines = new List<Integer>();
        List<Integer> zeroAmountLines = new List<Integer>();
        List<Integer> nonZeroUnitPriceLines = new List<Integer>();
        //ticket 19433 <<
        Map<Id, Billing_Worksheet_Line__c> mapWorksheetLinesById = new Map<Id, Billing_Worksheet_Line__c>();
        //ticket 19433 >>
        for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
            for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                TM__c tm = tmsByIds.get(worksheetLine.TM__c);
                if (tm.Tax_Area__c == null) {
                    blankTaxAreaTMs.add(tm.Name);
                }
                if (tm.Service_Center__c == null) {
                    blankServiceCenterTMs.add(tm.Name);
                }

                if (worksheetLine.Quantity__c == 0 || worksheetLine.Quantity__c == null) {
                    zeroQuantityLines.add(worksheetLine.Line_No__c.intValue());
                }
                if (worksheetLine.Bill_as_Lump_Sum__c == true) {
                    //xUnit Price needed for Fuel Surcharge calculation for Fuel Fire Equipment Resource Type if line is bundled aka Bill as Lump Sum
                    if(worksheetLine.Category__c == ResourceService.EQUIPMENT_CATEGORY && worksheetLine.Resource_Type__r.Fuel_Fired_Equipment__c) {
                        if (worksheetLine.xUnit_Price__c == 0 || worksheetLine.xUnit_Price__c == null) {
                            zeroUnitPriceLines.add(worksheetLine.Line_No__c.intValue());
                        }
                        if (worksheetLine.xLine_Amount__c == 0 || worksheetLine.xLine_Amount__c == null) {
                            zeroAmountLines.add(worksheetLine.Line_No__c.intValue());
                        }
                    }
                    if ((worksheetLine.Unit_Price__c != 0 && worksheetLine.Unit_Price__c != null) || (worksheetLine.Line_Amount__c != 0 && worksheetLine.Line_Amount__c != null)) {
                        nonZeroUnitPriceLines.add(worksheetLine.Line_No__c.intValue());
                    }
                }
                else if (worksheetLine.Non_Billable__c != true) {
                    if (worksheetLine.Unit_Price__c == 0 || worksheetLine.Unit_Price__c == null) {
                        if(worksheetLine.Disposal_Billing_Method__c != 'Direct')
                        	zeroUnitPriceLines.add(worksheetLine.Line_No__c.intValue());
                    }
                    if (worksheetLine.Line_Amount__c == 0 || worksheetLine.Line_Amount__c == null) {
                         if(worksheetLine.Disposal_Billing_Method__c != 'Direct')
                        		zeroAmountLines.add(worksheetLine.Line_No__c.intValue());
                    }
                }

                //ticket 19433 <<
                mapWorksheetLinesById.put(worksheetLine.Id, worksheetLine);
                //ticket 19433 >>
            }
        }

        //ticket 19433 <<
        Set<String> missingBundledTMs = new Set<String>();
        for (Billing_Worksheet_Line__c worksheetLine : [SELECT Id, TM__r.Name FROM Billing_Worksheet_Line__c WHERE Sales_Order__c = :salesOrderId AND  Bundle_Line__c IN :mapWorksheetLinesById.keySet() AND Invoiced__c <> TRUE]) {
            if (!mapWorksheetLinesById.containsKey(worksheetLine.Id)) {
                missingBundledTMs.add(worksheetLine.TM__r.Name);
            }
        }
        //ticket 19433 >>

        List<String> errors = new List<String>();
        if (blankTaxAreaTMs.size() > 0) {
            errors.add(('Tax area must not be blank on T&Ms' + String.join(blankTaxAreaTMs, ', ') + '.'));
        }
        if (blankServiceCenterTMs.size() > 0) {
            errors.add(('Service center must not be blank on T&Ms' + String.join(blankServiceCenterTMs, ', ') + '.'));
        }
        if (zeroQuantityLines.size() > 0) {
            errors.add('Quantity must not be zero on worksheet lines ' + String.join(zeroQuantityLines, ', ') + '.');
        }
        if (zeroUnitPriceLines.size() > 0) {
            errors.add('Unit price must not be zero on worksheet lines ' + String.join(zeroUnitPriceLines, ', ') + '.');
        }
        if (nonZeroUnitPriceLines.size() > 0) {
            errors.add('Unit price must be zero on bundled lines ' + String.join(nonZeroUnitPriceLines, ', ') + '.');
        }
        if (zeroAmountLines.size() > 0) {
            errors.add('Amount must not be zero on worksheet lines ' + String.join(zeroAmountLines, ', ') + '.');
        }

        //ticket 19433 <<
        if (missingBundledTMs.size() > 0) {
            errors.add('You must include bundled lines in T&Ms ' + String.join(new List<String>(missingBundledTMs), ', ') + ' to invoice because they are bundled in a bundle line that you are invoicing.');
        }
        //ticket 19433 >>

        if (errors.size() > 0) {
            throw new DataException(String.join(errors, ' '));
        }
    }

    public static Sales_Invoice__c createSalesInvoice(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers) {
        Sales_Invoice__c salesInvoice = new Sales_Invoice__c();
        List<Sales_Invoice_Job_Task__c> jobTasks = new List<Sales_Invoice_Job_Task__c>();

        Set<Id> tmIds = new Set<Id>();
        Set<Id> tmlIds = new Set<Id>();
        //Set<Id> salesOrderJobTaskIds = new Set<Id>();

        List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectCreateInvoiceRequiredFieldsById(new Set<Id>{ salesOrderId });
        Sales_Order__c salesOrder = salesOrders[0];

        for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
            for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                if (worksheetLine.TM__c != null) {
                    tmIds.add(worksheetLine.TM__c);
                }
                if (worksheetLine.TM_Line__c != null) {
                    tmlIds.add(worksheetLine.TM_Line__c);
                }

                //Ticket#20749 //roll back 11/15/2021
                /*
                if(salesOrder.Contract__c != null && worksheetLine.TM__r.Scheduled_Date__c != null && worksheetLine.Contract_Line__c != null){
                    if(worksheetLine.TM__r.Scheduled_Date__c > salesOrder.Contract__r.EndDate){
                        throw new DataException('Contract linked with Line ' + worksheetLine.Line_No__c + ' expired on ' + salesOrder.Contract__r.EndDate);
                    }
                }
                 */
                //salesOrderJobTaskIds.add(worksheetLine.Sales_Order_Job_Task__c);
            }
        }

        //Invoice Versioning >>
        Map<Id, String> parentInvWithNextReversionInvNo = SalesInvoicesService.getParentInvIdWithNextReversionInvNum(tmIds, tmlIds);
        if(parentInvWithNextReversionInvNo.size() > 0) {
            for(Id parentInvId:parentInvWithNextReversionInvNo.keySet()){
                salesInvoice.Name = parentInvWithNextReversionInvNo.get(parentInvId);
                salesInvoice.Parent_Record__c = parentInvId;
            }
        }
        //Invoice Versioning <<

        //turn on systemCall to allow updating billing worksheet lines
        CompanyMgmt.systemCall = true;

        // Create Invoice header
        createSalesInvoiceHeader(salesInvoice, salesOrder);
        //if there is only one T&M, using TM site information as invoice site information.
        if(tmIds.size() == 1){
            List<TM__c> tms2 = TMsSelector.newInstance().selectByIds(tmIds);
            salesInvoice.Site_Name__c = tms2[0].Site_Name__c;
            salesInvoice.Site_Street__c = tms2[0].Site_Street__c;
            salesInvoice.Site_City__c = tms2[0].Site_City__c;
            salesInvoice.Site_State__c = tms2[0].Site_State__c;
            salesInvoice.Site_Postal_Code__c = tms2[0].Site_Postal_Code__c;
            salesInvoice.Site_Country__c = tms2[0].Site_Country__c;
            salesInvoice.Site_Contact__c = tms2[0].Site_Contact__c;
            salesInvoice.Site_Phone_No__c = tms2[0].Site_Phone_No__c;
            salesInvoice.Site_Email_Address__c = tms2[0].Site_Email_Address__c;
            salesInvoice.Site_Contact_2__c = tms2[0].Site_Contact_2__c;
            salesInvoice.Site_Scope__c = tms2[0].Site_Scope__c;
            salesInvoice.Customer_PO_No__c = tms2[0].Customer_PO_No__c;
        }
        insert salesInvoice;

        //create sales invoice job tasks
        Integer jobTaskLineNo = 1;
        Map<Id, Sales_Invoice_Job_Task__c> mapInvoiceJobTaskByOrderJobTaskId = new Map<Id, Sales_Invoice_Job_Task__c>();
        //for (Sales_Order_Job_Task__c salesOrderJobTask : SalesOrderJobTasksSelector.newInstance().selectById(salesOrderJobTaskIds)) {
        for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
            Sales_Order_Job_Task__c salesOrderJobTask = worksheetWrapper.SalesOrderJobTask;
            Sales_Invoice_Job_Task__c salesInvoiceJobTask = new Sales_Invoice_Job_Task__c();
            salesInvoiceJobTask.Name = salesOrderJobTask.Name;
            //salesInvoiceJobTask.Task_No_New__c = salesOrderJobTask.Task_No__c; //Ticket#20402 reversed
            salesInvoiceJobTask.Print_Order__c = salesOrderJobTask.Task_No__c; //Ticket#20402
            salesInvoiceJobTask.Line_No__c = jobTaskLineNo;
            salesInvoiceJobTask.Sales_Invoice__c = salesInvoice.Id;
            salesInvoiceJobTask.Billing_Type__c = salesOrderJobTask.Billing_Type__c;
            salesInvoiceJobTask.Tax_Group__c = salesOrderJobTask.Tax_Group__c;
            salesInvoiceJobTask.Tax_Pct__c = salesOrderJobTask.Tax_Pct__c;
            SalesInvoiceJobTask.Billing_Pct__c = salesOrderJobTask.Pct_To_Bill__c;
            SalesInvoiceJobTask.Billing_Amount__c = salesOrderJobTask.Amount_to_Bill__c;
            //ticket 19672 <<
            SalesInvoiceJobTask.Fixed_Price_Surcharge_Option__c = salesOrderJobTask.Fixed_Price_Surcharge_Option__c;
            //ticket 19672 >>
            salesInvoiceJobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
            mapInvoiceJobTaskByOrderJobTaskId.put(salesOrderJobTask.Id, salesInvoiceJobTask);
            jobTaskLineNo++;
        }
        insert mapInvoiceJobTaskByOrderJobTaskId.values();

        //create invoice lines
        List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
        //ticket 20551 <<
        Integer nextSalesInvoiceLineNo = 1;
        //ticket 20551 >>
        for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
            Sales_Invoice_Job_Task__c salesInvoiceJobTask = mapInvoiceJobTaskByOrderJobTaskId.get(worksheetWrapper.SalesOrderJobTask.Id);
            //ticket 20551 <<
            //salesInvoiceLines.addAll(createSalesInvoiceLines(salesInvoice, salesInvoiceJobTask, worksheetWrapper.WorksheetLines, 1));
            List<Sales_Invoice_Line__c> newSalesInvoiceLines = createSalesInvoiceLines(salesInvoice, salesInvoiceJobTask, worksheetWrapper.WorksheetLines, nextSalesInvoiceLineNo);
            salesInvoiceLines.addAll(newSalesInvoiceLines);

            for (Sales_Invoice_Line__c newSalesInvoiceLine : newSalesInvoiceLines) {
                if (newSalesInvoiceLine.Line_No__c.intValue() > nextSalesInvoiceLineNo) {
                    nextSalesInvoiceLineNo = newSalesInvoiceLine.Line_No__c.intValue();
                }
            }
            nextSalesInvoiceLineNo++;
            //ticket 20551 >>
        }

        //group invoices lines by job task to calculate manifest, surcharge lines, etc.
        Map<Id, ACVSalesInvoiceJobTaskWrapper> mapJobTaskWrappersById = new Map<Id, ACVSalesInvoiceJobTaskWrapper>();
        for (Sales_Invoice_Job_Task__c jobTask : mapInvoiceJobTaskByOrderJobTaskId.values()) {
            ACVSalesInvoiceJobTaskWrapper jobTaskWrapper = new ACVSalesInvoiceJobTaskWrapper();
            jobTaskWrapper.JobTask = jobTask;
            mapJobTaskWrappersById.put(jobTask.Id, jobTaskWrapper);
        }

        Integer nextInvoiceLineNo = 0;
        for (Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
            if (mapJobTaskWrappersById.containsKey(salesInvoiceLine.Sales_Invoice_Job_Task__c)) {
                ACVSalesInvoiceJobTaskWrapper jobTaskWrapper = mapJobTaskWrappersById.get(salesInvoiceLine.Sales_Invoice_Job_Task__c);
                jobTaskWrapper.SalesInvoiceLines.add(salesInvoiceLine);
            }
            if (salesInvoiceLine.Line_No__c.intValue() > nextInvoiceLineNo) {
                nextInvoiceLineNo = salesInvoiceLine.Line_No__c.intValue();
            }
        }
        nextInvoiceLineNo++;

        //calculate surcharge line, manifest lines and rinse out line
        for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : mapJobTaskWrappersById.values()) {
            System.debug('-------------->'+JSON.serialize(jobTaskWrapper.SalesInvoiceLines));
            //insert an invoice line for fixed price job
            if (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price') {
                Sales_Invoice_Line__c salesInvoiceLine = createFixedPriceInvoiceLine(salesInvoice, jobTaskWrapper.JobTask, nextInvoiceLineNo);
                jobTaskWrapper.SalesInvoiceLines.add(salesInvoiceLine);
                nextInvoiceLineNo++;
            }

            System.debug('--------------1>'+JSON.serialize(jobTaskWrapper.SalesInvoiceLines));

            //ticket 19672 <<
            //else {
            if (jobTaskWrapper.JobTask.Billing_Type__c != 'Fixed Price'
                    || (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price' && jobTaskWrapper.JobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge')) {
                //ticket 19672 >>
                calculateSurchargeLine(salesOrder, salesInvoice, jobTaskWrapper, nextInvoiceLineNo);
                nextInvoiceLineNo++;
            }
                        System.debug('--------------3>'+JSON.serialize(jobTaskWrapper.SalesInvoiceLines));

            /* move to TM creation
            createManifestFeeLine(salesInvoice, jobTaskWrapper, nextInvoiceLineNo);
            nextInvoiceLineNo++;
            */
        }

        salesInvoiceLines = new List<Sales_Invoice_Line__c>();
        for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : mapJobTaskWrappersById.values()) {
            salesInvoiceLines.addAll(jobTaskWrapper.SalesInvoiceLines);
        }

        insert salesInvoiceLines;


        //handle bundle lines
        Map<Id, Billing_Worksheet_Line__c> mapWorksheetLinesById = new Map<Id, Billing_Worksheet_Line__c>();
        Map<Id, Sales_Invoice_Line__c> mapSalesInvoiceLinesByWorksheetLineId = new Map<Id, Sales_Invoice_Line__c>();
        for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
            for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                mapWorksheetLinesById.put(worksheetLine.Id, worksheetLine);
            }
        }
        for (Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
            if (salesInvoiceLine.Billing_Worksheet_Line__c != null) {
                mapSalesInvoiceLinesByWorksheetLineId.put(salesInvoiceLine.Billing_Worksheet_Line__c, salesInvoiceLine);
            }
        }
        List<Sales_Invoice_Line__c> salesInvoiceLinesToUpdate = new List<Sales_Invoice_Line__c>();
        Map<Id, Id> resNewSCByResIds = new Map<Id, Id>();
        for (Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
            Boolean invoiceLineNeedsUpdate = false;
            //Check Resource SC change
            if((salesInvoiceLine.Category__c == ResourceService.LABOR_CATEGORY || salesInvoiceLine.Category__c == ResourceService.EQUIPMENT_CATEGORY) &&
                    String.isNotBlank(salesInvoiceLine.Resource__c)){
                if(ResourceService.resourcesByIds.containsKey(salesInvoiceLine.Resource__c)){
                    Resource__c res = ResourceService.resourcesByIds.get(salesInvoiceLine.Resource__c);
                    if (salesInvoiceLine.Service_Center__c != res.Service_Center__c && res.Service_Center__r.Temporary__c == false) {
                        salesInvoiceLine.Service_Center__c = res.Service_Center__c;
                        resNewSCByResIds.put(res.Id, res.Service_Center__c);
                        invoiceLineNeedsUpdate = true;
                    }
                }
            }
            //Check Resource SC Change

            if (salesInvoiceLine.Bill_as_Lump_Sum__c == true && salesInvoiceLine.Billing_Worksheet_Line__c != null) {
                if (mapWorksheetLinesById.containsKey(salesInvoiceLine.Billing_Worksheet_Line__c)) {
                    Billing_Worksheet_Line__c worksheetLine = mapWorksheetLinesById.get(salesInvoiceLine.Billing_Worksheet_Line__c);
                    if (worksheetLine.Bundle_Line__c != null) {
                        if (mapSalesInvoiceLinesByWorksheetLineId.containsKey(worksheetLine.Bundle_Line__c)) {
                            Sales_Invoice_Line__c parentSalesInvoiceLine = mapSalesInvoiceLinesByWorksheetLineId.get(worksheetLine.Bundle_Line__c);
                            salesInvoiceLine.Bundle_Line__c = parentSalesInvoiceLine.Id;
                            invoiceLineNeedsUpdate = true;
                        }
                    }
                }
            }

            if(invoiceLineNeedsUpdate == true){
                salesInvoiceLinesToUpdate.add(salesInvoiceLine);
            }
        }
        if (salesInvoiceLinesToUpdate.size() > 0) {
            update salesInvoiceLinesToUpdate;
        }

        Set<Id> tmLineIds = new Set<Id>();
        List<Billing_Worksheet_Line__c> worksheetLinesToUpdate = new List<Billing_Worksheet_Line__c>();
        for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
            for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {

                Billing_Worksheet_Line__c worksheetLineToUpdate = new Billing_Worksheet_Line__c(Id = worksheetLine.Id);
                //worksheetLine.To_Invoice__c = false;
                if (worksheetLine.Invoiced__c == true) {
                    worksheetLineToUpdate.Invoiced__c = true;

                    if (worksheetLine.TM_Line__c != null) {
                        tmLineIds.add(worksheetLine.TM_Line__c);
                    }
                }

                if((worksheetLine.Category__c == ResourceService.LABOR_CATEGORY || worksheetLine.Category__c == ResourceService.EQUIPMENT_CATEGORY) &&
                    resNewSCByResIds.containsKey(worksheetLine.Resource__c)){
                    if(worksheetLine.Service_Center__c != resNewSCByResIds.get(worksheetLine.Resource__c)){
                        worksheetLineToUpdate.Service_Center__c = resNewSCByResIds.get(worksheetLine.Resource__c);
                    }
                }

                worksheetLinesToUpdate.add(worksheetLineToUpdate);
            }
        }
        update worksheetLinesToUpdate;

        //update tm lines
        List<TM_Line__c> tmLinesToUpdate = new List<TM_Line__c>();
        for (Id tmLineId : tmLineIds) {
            tmLinesToUpdate.add(new TM_Line__c(Id = tmlineId, Invoiced__c = true, TM_line_sent_to_EQAI__c=true));//Ticket# US139238
        }

        //Ticket#24285 >>
        List<TM_Line__c> laborTMLines = [SELECT Id, Job_Start_Time__c, Job_End_Time__c, Site_Start_Time__c, Site_End_Time__c, Lunch_Start_Time__c, Lunch_End_Time__c
            FROM TM_Line__c WHERE Category__c = 'Labor' AND Invoiced__c = FALSE AND TM__c IN :tmIds AND Quantity__c = 0];
        for(TM_Line__c tmLine : laborTMLines){
            if(tmLine.Job_Start_Time__c == tmLine.Site_Start_Time__c && tmLine.Site_Start_Time__c == tmLine.Site_End_Time__c
                    && tmLine.Site_End_Time__c == tmLine.Job_End_Time__c && tmLine.Lunch_Start_Time__c == null && tmLine.Lunch_End_Time__c == null){
                tmLinesToUpdate.add(new TM_Line__c(Id = tmLine.Id, Invoiced__c = true, TM_line_sent_to_EQAI__c=true)); //Ticket# US139238
            }
        }
        //Ticket#24285 <<
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        update tmLinesToUpdate;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;

        //update sales order job task
        List<Sales_Order_Job_Task__c> salesOrderJobTasks = new List<Sales_Order_Job_Task__c>();
        for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
            Sales_Order_Job_Task__c salesOrderJobTask = new Sales_Order_Job_Task__c();
            salesOrderJobTask.Id = worksheetWrapper.SalesOrderJobTask.Id;
            salesOrderJobTask.Pct_To_Bill__c = null;
            salesOrderJobTask.Amount_To_Bill__c = null;
            salesOrderJobTasks.add(salesOrderJobTask);
        }
        update salesOrderJobTasks;

        // Update TM Status
        List<TM__c> tms = new List<TM__c>();
        Id fullyInvoicedRecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Fully Invoiced').getRecordTypeId();
        
    for (TM__c tm : [SELECT Id,Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c, (SELECT Id, Invoiced__c FROM TM_Lines__r WHERE Invoiced__c != TRUE) FROM TM__c WHERE Id IN :tmIds]) {
system.debug('inside ifBilling---->');
            if (tm.TM_Lines__r.size() == 0) {
if(tm.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == false){
                tm.Status__c = 'Fully Invoiced';
                                tm.RecordTypeId = fullyInvoicedRecordTypeId;
}
            else if(tm.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c == true){
                tm.Status__c = 'Sent to EQAI'; // ticket 75282 changes.
                tm.RecordTypeId = fullyInvoicedRecordTypeId;
            }
            }
            tm.Sales_Invoice__c = salesInvoice.Id;
            tms.add(tm);
        }
        CompanyMgmt.byPassTrigger = true;
        update tms;
        CompanyMgmt.byPassTrigger = false;

        //job task <<
        SalesInvoiceTriggersMgmt.updateTMInvoiceRelations(salesInvoiceLines);
        //job task >>
        return salesInvoice;
    }

    /*
        Ticket#20079
            - add Payment Term to contract
     */
    private static void createSalesInvoiceHeader(Sales_Invoice__c salesInvoice, Sales_Order__c salesOrder) {

        salesInvoice.Sales_Order__c = salesOrder.Id;
        salesInvoice.Document_Status__c = 'Open';
        salesInvoice.Bill_to_Customer__c = salesOrder.Bill_to_Customer_No__c;
        salesInvoice.Street__c = salesOrder.Bill_to_Customer_No__r.BillingStreet;
        salesInvoice.City__c = salesOrder.Bill_to_Customer_No__r.BillingCity;
        salesInvoice.State__c = salesOrder.Bill_to_Customer_No__r.BillingStateCode;
        salesInvoice.Postal_Code__c = salesOrder.Bill_to_Customer_No__r.BillingPostalCode;
        salesInvoice.Country__c = salesOrder.Bill_to_Customer_No__r.BillingCountryCode;
        //case 33537
        if(salesOrder.Bill_to_Customer_No__r.BillingCountryCode != null && salesOrder.Bill_to_Customer_No__r.BillingCountryCode == 'CA') {
            salesInvoice.Country__c = 'CAN';
        }
        salesInvoice.Salesperson__c = salesOrder.Bill_to_Customer_No__r.Salesperson__c;
        salesInvoice.Payment_Term__c = salesOrder.Bill_to_Customer_No__r.Payment_Term__c;
        //Ticket#15235 >>
        Decimal dueDateCalc = CompanyMgmt.zeroIfNull(salesOrder.Bill_to_Customer_No__r.Payment_Term__r.Due_Date_Calculation__c);
        if (String.isNotEmpty(salesOrder.Payment_Term__c)){
            salesInvoice.Payment_Term__c = salesOrder.Payment_Term__c;
            dueDateCalc = salesOrder.Payment_Term__r.Due_Date_Calculation__c;
        }
        //Ticket#15235 <<
        if(String.isNotBlank(salesOrder.Contract__c) && String.isNotBlank(salesOrder.Contract__r.Payment_Term__c)){
            salesInvoice.Payment_Term__c = salesOrder.Contract__r.Payment_Term__c;
            dueDateCalc = salesOrder.Contract__r.Payment_Term__r.Due_Date_Calculation__c;
        }
        salesInvoice.Posting_Date__c = Date.today();
        salesInvoice.Account_Executive__c = salesOrder.Account_Executives__c;
        salesInvoice.Customer_PO_No__c = salesOrder.Customer_PO_No__c;
        salesInvoice.Service_Center__c = salesOrder.Service_Center__c;
        salesInvoice.Subsidiary_Company__c = salesOrder.Subsidiary_Company__c;
        salesInvoice.Invoice_Date__c = Date.today();
        salesInvoice.Due_Date__c = CompanyMgmt.calcDate(salesInvoice.Invoice_Date__c, dueDateCalc); //Ticket#15235
        salesInvoice.Contact__c = salesOrder.Bill_to_Contact__c;
        salesInvoice.Site_Contact_2__c = salesOrder.Site_Contact_2__c;
        salesInvoice.Site_Name__c = salesOrder.Site_Name__c;
        salesInvoice.Site_Street__c = salesOrder.Site_Street__c;
        salesInvoice.Site_City__c = salesOrder.Site_City__c;
        salesInvoice.Site_State__c = salesOrder.Site_State__c;
        salesInvoice.Site_Postal_Code__c = salesOrder.Site_Postal_Code__c;
        salesInvoice.Site_Country__c = salesOrder.Site_Country__c;
        salesInvoice.Site_Contact__c = salesOrder.Site_Contact__c;
        salesInvoice.Site_Phone_No__c = salesOrder.Site_Phone_No__c;
        salesInvoice.Site_Email_Address__c = salesOrder.Site_Email_Address__c;
        salesInvoice.Tax_Liable__c = salesOrder.Tax_Liable__c;
        salesInvoice.Tax_Area__c = salesOrder.Tax_Area__c;
        salesInvoice.Contract__c = salesOrder.Contract__c;
        salesInvoice.Surcharge_Type__c = salesOrder.Surcharge_Type__c;       
        //salesInvoice.Surcharge_Pct__c = salesOrder.Surcharge_Pct__c;
        salesInvoice.Billing_Instructions__c = salesOrder.Billing_Instructions__c;
        salesInvoice.Customer_Billing_Instructions__c = salesOrder.Customer_Billing_Instructions__c;
        salesInvoice.Internal_Comments__c = salesOrder.Internal_Comments__c;
        salesInvoice.Site_Scope__c = salesOrder.Site_Scope__c;
        // TICKET US130968
        // if(salesOrder.Bill_to_Customer_No__r.Customer_Type__c == 'I/C'){
        //     salesInvoice.Approved__c = true;
        //     salesInvoice.Approval_Status__c = EnumUtil.ApprovalStatus.APPROVED.name();
        // }
        //Ticket#24560 >>
        salesInvoice.Operating_Expense_Cost_Pct__c = salesOrder.Operating_Expense_Cost_Pct__c;
        //Ticket#24560 <<
        
        //US135286 - Set surcharge percentage for EEC Fee or Fuel or ESIC Surcharge types from Surcharge Setup
        setSurchargePct(salesOrder, salesInvoice);


        
    }

    public static List<Sales_Invoice_Line__c> createSalesInvoiceLines(Sales_Invoice__c salesInvoice, Sales_Invoice_Job_Task__c salesInvoiceJobTask, List<Billing_Worksheet_Line__c> worksheetLines, Integer nextInvoiceLineNo) {
        List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
        for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
            if (worksheetLine.Category__c == 'Labor' && worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                if (worksheetLine.Regular_Hours__c != null && worksheetLine.Regular_Hours__c != 0) {
                    salesInvoiceLines.add(createLaborInvoiceLine(salesInvoice, salesInvoiceJobTask, worksheetLine, 'REG', nextInvoiceLineNo));
                    nextInvoiceLineNo++;
                }

                if (worksheetLine.Overtime_Hours__c != null && worksheetLine.Overtime_Hours__c != 0) {
                    salesInvoiceLines.add(createLaborInvoiceLine(salesInvoice, salesInvoiceJobTask, worksheetLine, 'OT', nextInvoiceLineNo));
                    nextInvoiceLineNo++;
                }
                if (worksheetLine.Premium_Hours__c != null && worksheetLine.Premium_Hours__c != 0) {
                    salesInvoiceLines.add(createLaborInvoiceLine(salesInvoice, salesInvoiceJobTask, worksheetLine, 'DT', nextInvoiceLineNo));
                    nextInvoiceLineNo++;
                }
            }
            else {
                if (worksheetLine.Quantity__c >= 0) {
                    System.debug('worksheetLine+++++++++' +worksheetLine);
                    salesInvoiceLines.add(createSalesInvoiceLine(salesInvoice, salesInvoiceJobTask, worksheetLine, nextInvoiceLineNo));
                    nextInvoiceLineNo++;
                }
            }
            worksheetLine.Invoiced__c = true;
        }
        return salesInvoiceLines;
    }

    private static Sales_Invoice_Line__c createSalesInvoiceLine(Sales_Invoice__c salesInvoice, Sales_Invoice_Job_Task__c jobTask, Billing_Worksheet_Line__c worksheetLine, Integer nextInvoiceLineNo) {
        Sales_Invoice_Line__c salesInvoiceLine = new Sales_Invoice_Line__c();
        Contract_Line__c contractLine = new Contract_Line__c();
        if(String.isNotBlank(worksheetLine.Contract_Line__c)){
            contractLine = ContractUtil.getContractLine(worksheetLine.Contract_Line__c);
        }

        salesInvoiceLine.Sales_Invoice__c = salesInvoice.Id;
        salesInvoiceLine.Line_No__c = nextInvoiceLineNo;
        salesInvoiceLine.Sales_Invoice_Job_Task__c = jobTask.Id;
        salesInvoiceLine.Billing_Worksheet_Line__c = worksheetLine.Id;

        salesInvoiceLine.Resource_Type__c = worksheetLine.Resource_Type__c;
        if (worksheetLine.Resource_Type__r.Fuel_Fired_Equipment__c) {
            salesInvoiceLine.Resource_Type__r = new Resource_Type__c(Id = worksheetLine.Resource_Type__c, Fuel_Fired_Equipment__c = worksheetLine.Resource_Type__r.Fuel_Fired_Equipment__c, Fleet_No_Required__c = worksheetLine.Resource_Type__r.Fleet_No_Required__c);
        }

        salesInvoiceLine.Resource__c = worksheetLine.Resource__c;
        if ((!worksheetLine.Resource_Type__r.Fleet_No_Required__c || worksheetLine.Service_Center__r.Equipment_Fleet_No_Not_Required__c) && (salesInvoiceLine.Resource__c == null)) {
            if (worksheetLine.Category__c == 'Equipment') {
                salesInvoiceLine.Resource__c = defaultCompanySetup.Default_Equipment_Resource__c;
            }
        }
        if (worksheetLine.Category__c == 'Bundled') {
            if (worksheetLine.Resource__c == null) {
                salesInvoiceLine.Resource__c = defaultCompanySetup.Default_Lump_Sum_Resource__c;
            }
        }

        if (worksheetLine.Service_Center__r.Temporary__c && salesInvoiceLine.Resource__c == null && worksheetLine.Category__c == 'Labor') {
            salesInvoiceLine.Resource__c = defaultCompanySetup.Default_Labor_Resource__c;
        }

        salesInvoiceLine.Description__c = worksheetLine.Description__c;
        /*
        if (String.isNotBlank(worksheetLine.Contract_Line__c)){
            salesInvoiceLine.Description__c = generateLineDescription(worksheetLine.Description__c, worksheetLine.Contract_Line__r.Customer_Item_No__c, worksheetLine.Contract_Line__r.Customer_Description__c);
        }
        */
        if (String.isNotBlank(contractLine.Id)){
            salesInvoiceLine.Description__c = generateLineDescription(worksheetLine.Description__c, contractLine.Customer_Item_No__c, contractLine.Customer_Description__c);
        }

        salesInvoiceLine.Category__c = worksheetLine.Category__c;
        salesInvoiceLine.Unit_of_Measure__c = worksheetLine.Unit_of_Measure__c;
        salesInvoiceLine.Tax_Group__c = worksheetLine.Tax_Group__c;
        //Ticket#27074 >>
        //salesInvoiceLine.Tax_Pct__c = worksheetLine.Tax_Pct__c;
        salesInvoiceLine.Tax_Pct__c = worksheetLine.Tax_Pct__c;
       /* if(salesInvoice.Tax_Liable__c == true){
            salesInvoiceLine.Tax_Pct__c = TaxService.getTaxPct(salesInvoice.Tax_Area__c, salesInvoiceLine.Tax_Group__c);
        } else {
            salesInvoiceLine.Tax_Pct__c = 0;
        }*/
        //Ticket#27074 <<
        salesInvoiceLine.TM__c = worksheetLine.TM__c;
        salesInvoiceLine.TM_Line__c = worksheetLine.TM_Line__c;
        salesInvoiceLine.Service_Center__c = worksheetLine.Service_Center__c; //AES-406
        salesInvoiceLine.Bill_as_Lump_Sum__c = worksheetLine.Bill_as_Lump_Sum__c;
        salesInvoiceLine.Non_Billable__c = worksheetLine.Non_Billable__c; //Ticket#13673
        salesInvoiceLine.Scheduled_Date__c = worksheetLine.TM__r.Scheduled_Date__c;
        salesInvoiceLine.Resource_Type_UOM__c = worksheetLine.Resource_Type_UOM__c;
        salesInvoiceLine.Resource_UOM__c = worksheetLine.Resource_UOM__c;
        salesInvoiceLine.Cost_Method__c = worksheetLine.Cost_Method__c;
        salesInvoiceLine.Unit_Weight_Vol__c = worksheetLine.Unit_Weight_Vol__c;
        salesInvoiceLine.Container_Size__c = worksheetLine.Container_Size__c;
        salesInvoiceLine.BOL_Manifest__c = worksheetLine.BOL_Manifest__c;
        salesInvoiceLine.Min_Sell_Qty__c = worksheetLine.Min_Sell_Qty__c;
        salesInvoiceLine.Quantity__c = worksheetLine.Quantity__c;
        salesInvoiceLine.Facility__c = worksheetLine.Facility__c;
        //US134409
        salesInvoiceLine.Profile_Id__c = worksheetLine.Profile_Id__c;
        salesInvoiceLine.Approval_Id__c = worksheetLine.Approval_Id__c;
        salesInvoiceLine.EQAI_Bill_Unit_Code__c = worksheetLine.EQAI_Bill_Unit_Code__c; 
        //Ticket#19386
        if(worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
            if(salesInvoiceLine.Quantity__c < salesInvoiceLine.Min_Sell_Qty__c){
                salesInvoiceLine.Recorded_Qty__c = salesInvoiceLine.Quantity__c;
                salesInvoiceLine.Quantity__c = salesInvoiceLine.Min_Sell_Qty__c;
            }
        }

        salesInvoiceLine.Unit_of_Measure__c = worksheetLine.Unit_of_Measure__c;
		salesInvoiceLine.Disposal_Billing_Method__c = worksheetLine.Disposal_Billing_Method__c;
        if (jobTask.Billing_Type__c == 'Fixed Price') {
            //ticket 19672 <<
            /*
            salesInvoiceLine.Unit_Price__c = 0;
            salesInvoiceLine.xUnit_Price__c = 0;
            salesInvoiceLine.Line_Amount__c = 0;
            salesInvoiceLine.Tax__c = 0;
            salesInvoiceLine.Line_Amt_Incl_Tax__c = 0;
            */
            if (jobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge'
                    && worksheetLine.Category__c == 'Misc. Charges And Taxes' && worksheetLine.System_Calculated_Line__c == true
                    && (worksheetLine.Resource__c == defaultCompanySetup.Default_Energy_Insurance_Resource__c || worksheetLine.Resource__c == defaultCompanySetup.Default_Fuel_Surcharge_Resource__c || worksheetLine.Resource__c == defaultCompanySetup.Default_ESIC_Surcharge_Resource__c)) {
                //ticket 19982 <<
                /*
                if (salesInvoiceLine.Quantity__c != 0) {
                    salesInvoiceLine.Unit_Price__c = CompanyMgmt.halfUpTo3D(CompanyMgmt.zeroIfNull(worksheetLine.Line_Amount__c) / salesInvoiceLine.Quantity__c);
                } else {
                    salesInvoiceLine.Unit_Price__c = 0;
                }
                */
                salesInvoiceLine.Unit_Price__c = calculateSalesInvoiceLineUnitPrice(worksheetLine);
                //ticket 19982 >>

                //ticket 20281 <<
                //salesInvoiceLine.xUnit_Price__c = worksheetLine.xUnit_Price__c;
                salesInvoiceLine.xUnit_Price__c = calculateSalesInvoiceLinexUnitPrice(worksheetLine);
                //ticket 20281 >>
                //Ticket#27074 salesInvoiceLine.Tax__c = CompanyMgmt.halfUpTo2D(worksheetLine.Tax__c);
                salesInvoiceLine.Line_Amount__c = CompanyMgmt.halfUpTo2D(worksheetLine.Line_Amount__c);
                salesInvoiceLine.xLine_Amount__c = CompanyMgmt.halfUpTo2D(worksheetLine.xLine_Amount__c);
                salesInvoiceLine.Tax__c = CompanyMgmt.halfUpTo2D(salesInvoiceLine.Line_Amount__c * CompanyMgmt.zeroIfNull(salesInvoiceLine.Tax_Pct__c) / 100); //Ticket#27074
                salesInvoiceLine.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(worksheetLine.Line_Amt_Incl_Tax__c);
            }
            else {
                salesInvoiceLine.Unit_Price__c = 0;
                salesInvoiceLine.xUnit_Price__c = worksheetLine.xUnit_Price__c;
                salesInvoiceLine.xLine_Amount__c = worksheetLine.xLine_Amount__c;
                salesInvoiceLine.Line_Amount__c = 0;
                salesInvoiceLine.Tax__c = 0;
                salesInvoiceLine.Line_Amt_Incl_Tax__c = 0;
            }
            //ticket 19672 >>
        }
        else {
            //ticket 19982 <<
            /*
            if (salesInvoiceLine.Quantity__c != 0) {
                salesInvoiceLine.Unit_Price__c = CompanyMgmt.halfUpTo3D(CompanyMgmt.zeroIfNull(worksheetLine.Line_Amount__c) / salesInvoiceLine.Quantity__c);
            } else {
                salesInvoiceLine.Unit_Price__c = 0;
            }
            */
            salesInvoiceLine.Unit_Price__c = calculateSalesInvoiceLineUnitPrice(worksheetLine);
            //ticket 19982 >>

            //ticket 20281 <<
            //salesInvoiceLine.xUnit_Price__c = worksheetLine.xUnit_Price__c;
            salesInvoiceLine.xUnit_Price__c = calculateSalesInvoiceLinexUnitPrice(worksheetLine);
            //ticket 20281 >>
            //Ticket#27074 
            salesInvoiceLine.Tax__c = CompanyMgmt.halfUpTo2D(worksheetLine.Tax__c);
            salesInvoiceLine.Line_Amount__c = CompanyMgmt.halfUpTo2D(worksheetLine.Line_Amount__c);
            salesInvoiceLine.xLine_Amount__c = CompanyMgmt.halfUpTo2D(worksheetLine.xLine_Amount__c);
            //salesInvoiceLine.Tax__c = CompanyMgmt.halfUpTo2D(salesInvoiceLine.Line_Amount__c * CompanyMgmt.zeroIfNull(salesInvoiceLine.Tax_Pct__c) / 100); //Ticket#27074
            salesInvoiceLine.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(worksheetLine.Line_Amt_Incl_Tax__c);

            //Ticket#22165 >>
            if (salesInvoiceLine.Bill_as_Lump_Sum__c || salesInvoiceLine.Non_Billable__c) {
                salesInvoiceLine.Unit_Price__c = 0;
                salesInvoiceLine.Tax__c = 0;
                salesInvoiceLine.Line_Amount__c = 0;
                salesInvoiceLine.Line_Amt_Incl_Tax__c = 0;
            }
            //Ticket#22165 <<

            //ticket 19672 << move out of the block
            /*
            //Occasionally Line Amount Include Tax is null in billing worksheet, this temp fix try to prevent posting error.
            if(CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amt_Incl_Tax__c) == 0 && CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amount__c) > 0){
                salesInvoiceLine.Line_Amt_Incl_Tax__c = salesInvoiceLine.Line_Amount__c + CompanyMgmt.zeroIfNull(salesInvoiceLine.Tax__c);
            }
            */
            //ticket 19672 >>
        }
        //ticket 19672 <<
        //Occasionally Line Amount Include Tax is null in billing worksheet, this temp fix try to prevent posting error.
        if(CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amt_Incl_Tax__c) == 0 && CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amount__c) > 0){
            salesInvoiceLine.Line_Amt_Incl_Tax__c = salesInvoiceLine.Line_Amount__c + CompanyMgmt.zeroIfNull(salesInvoiceLine.Tax__c);
        }
        //ticket 19672 >>

        salesInvoiceLine.Unit_Cost__c = worksheetLine.Unit_Cost__c;
        salesInvoiceLine.Cost_Qty__c = worksheetLine.Cost_Qty__c;
        salesInvoiceLine.Line_Cost__c = worksheetLine.Line_Cost__c;


        salesInvoiceLine.Pricing_Source_2__c = worksheetLine.Pricing_Source_2__c;

        return salesInvoiceLine;
    }

    //ticket 19982 <<
    private static Decimal calculateSalesInvoiceLineUnitPrice(Billing_Worksheet_Line__c worksheetLine) {
        Decimal unitPrice = 0;
        /*Ticet#23589
        if (worksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY) {
            Decimal qty = CompanyMgmt.zeroIfNull(worksheetLine.Quantity__c);
            Decimal minSellQty = CompanyMgmt.zeroIfNull(worksheetLine.Min_Sell_Qty__c);
            Decimal lineAmount = 0;
            if (minSellQty > qty) {
                lineAmount = unitPrice * minSellQty;
                if (qty > 0) {
                    unitPrice = CompanyMgmt.halfUpTo2D(lineAmount / qty);
                }
            }
            else {
                unitPrice = worksheetLine.Unit_Price__c;
            }
        }
         */
        /* Ticket#19964
        else if (worksheetLine.Category__c == 'Subcontractor') {
            Decimal markup = CompanyMgmt.zeroIfNull(worksheetLine.Markup__c);
            if (markup != 0) {
                Decimal qty = CompanyMgmt.zeroIfNull(worksheetLine.Quantity__c);
                Decimal lineAmount = 0;
                if (worksheetLine.Markup_Option__c == '%') {
                    lineAmount += (lineAmount * markup / 100);
                } else if (worksheetLine.Markup_Option__c == 'Amount') {
                    lineAmount += markup;
                }
                if (qty > 0) {
                    unitPrice = CompanyMgmt.halfUpTo2D(lineAmount / qty);
                }
            }
            else {
                unitPrice = worksheetLine.Unit_Price__c;
            }
        }
        */
        //ticket 20281 <<
        //else
        if (worksheetLine.Category__c == 'Labor') {
            unitPrice = worksheetLine.Regular_Rate__c;
        }
        //ticket 20281 >>
        else {
            unitPrice = worksheetLine.Unit_Price__c;
        }
        return unitPrice;
    }
    //ticket 19982 >>

    //ticket 20281 <<
    private static Decimal calculateSalesInvoiceLinexUnitPrice(Billing_Worksheet_Line__c worksheetLine) {
        Decimal xUnitPrice = 0;
        if (worksheetLine.Category__c == 'Labor') {
            xUnitPrice = worksheetLine.xRegular_Rate__c;
        }
        else {
            xUnitPrice = worksheetLine.xUnit_Price__c;
        }
        return xUnitPrice;
    }
    //ticket 20281 >>
    private static Sales_Invoice_Line__c createLaborInvoiceLine(Sales_Invoice__c salesInvoice, Sales_Invoice_Job_Task__c jobTask, Billing_Worksheet_Line__c worksheetLine, String rateCode, Integer nextInvoiceLineNo) {
        Sales_Invoice_Line__c salesInvoiceLine = new Sales_Invoice_Line__c();
        Contract_Line__c contractLine = new Contract_Line__c();
        if(String.isNotBlank(worksheetLine.Contract_Line__c)){
            contractLine = ContractUtil.getContractLine(worksheetLine.Contract_Line__c);
        }


        salesInvoiceLine.Sales_Invoice__c = salesInvoice.Id;
        salesInvoiceLine.Line_No__c = nextInvoiceLineNo;
        salesInvoiceLine.Sales_Invoice_Job_Task__c = jobTask.Id;
        salesInvoiceLine.Billing_Worksheet_Line__c = worksheetLine.Id;

        salesInvoiceLine.Resource__c = worksheetLine.Resource__c;
        salesInvoiceLine.Resource_Type__c = worksheetLine.Resource_Type__c;
        salesInvoiceLine.Category__c = worksheetLine.Category__c;
        salesInvoiceLine.Unit_of_Measure__c = worksheetLine.Unit_of_Measure__c;
        salesInvoiceLine.Tax_Group__c = worksheetLine.Tax_Group__c;
        //Ticket#27074 >>
        //salesInvoiceLine.Tax_Pct__c = worksheetLine.Tax_Pct__c;
        if(salesInvoice.Tax_Liable__c == true){
            salesInvoiceLine.Tax_Pct__c = TaxService.getTaxPct(salesInvoice.Tax_Area__c, salesInvoiceLine.Tax_Group__c);
        } else {
            salesInvoiceLine.Tax_Pct__c = 0;
        }
        //Ticket#27074 <<
        //salesInvoiceLine.Tax__c = worksheetLine.Tax__c;
        salesInvoiceLine.TM_Line__c = worksheetLine.TM_Line__c;
        salesInvoiceLine.TM__c = worksheetLine.TM__c;
        salesInvoiceLine.Service_Center__c = worksheetLine.Service_Center__c;
        salesInvoiceLine.Bill_as_Lump_Sum__c = worksheetLine.Bill_as_Lump_Sum__c;
        salesInvoiceLine.Non_Billable__c = worksheetLine.Non_Billable__c;
        salesInvoiceLine.Scheduled_Date__c = worksheetLine.TM__r.Scheduled_Date__c;
        salesInvoiceLine.Resource_Type_UOM__c = worksheetLine.Resource_Type_UOM__c;
        salesInvoiceLine.Resource_UOM__c = worksheetLine.Resource_UOM__c;

        Decimal notBilledCostQty = 0;
        Decimal extraHrs = 0;

        Decimal regularHours = CompanyMgmt.zeroIfNull(worksheetLine.Regular_Hours__c);
        Decimal overtimeHours = CompanyMgmt.zeroIfNull(worksheetLine.Overtime_Hours__c);
        Decimal doubleTimeHours = CompanyMgmt.zeroIfNull(worksheetLine.Premium_Hours__c);
        Decimal totalCostQty = CompanyMgmt.zeroIfNull(worksheetLine.Cost_Qty__c);

        if(regularHours + overtimeHours + doubleTimeHours < totalCostQty){
            notBilledCostQty = (totalCostQty - doubleTimeHours - overtimeHours - regularHours);
        } else if (regularHours + overtimeHours + doubleTimeHours > totalCostQty){
            extraHrs = regularHours + overtimeHours + doubleTimeHours - totalCostQty;
        }

        Decimal regularCostQty = regularHours;
        Decimal overtimeCostQty = overtimeHours;
        Decimal doubleTimeCostQty = doubleTimeHours;

        if(regularHours > 0) regularCostQty += notBilledCostQty;
        else if(overtimeHours > 0) overtimeCostQty += notBilledCostQty;
        else if(doubleTimeHours > 0) doubleTimeCostQty += notBilledCostQty;

        if(extraHrs > 0){
            if(regularHours > extraHrs) regularCostQty -= extraHrs;
            else if(overtimeHours > extraHrs) overtimeCostQty -= extraHrs;
            else if(doubleTimeHours > extraHrs) doubleTimeCostQty -= extraHrs;
        }

        salesInvoiceLine.Description__c = worksheetLine.Description__c;
        salesInvoiceLine.Time_Rate_Code__c = rateCode;
        Decimal costQty = 0;
        if (rateCode == 'REG') {
            costQty = regularCostQty;
            salesInvoiceLine.Quantity__c = worksheetLine.Regular_Hours__c;
            salesInvoiceLine.Unit_Price__c = worksheetLine.Regular_Rate__c;
            salesInvoiceLine.xUnit_Price__c = worksheetLine.xRegular_Rate__c;
            /*
            if (String.isNotBlank(worksheetLine.Contract_Line__c)){
                salesInvoiceLine.Description__c = generateLineDescription(worksheetLine.Description__c, worksheetLine.Contract_Line__r.Customer_Item_No__c, worksheetLine.Contract_Line__r.Customer_Description__c);
            }
             */
            if (String.isNotBlank(contractLine.Id)){
                salesInvoiceLine.Description__c = generateLineDescription(worksheetLine.Description__c, contractLine.Customer_Item_No__c, contractLine.Customer_Description__c);
            }
            //Ticket#22710 >>
            if(CompanyMgmt.zeroIfNull(worksheetLine.Regular_Unit_Cost__c) > 0) {
                salesInvoiceLine.Unit_Cost__c = worksheetLine.Regular_Unit_Cost__c;
            } else {
                salesInvoiceLine.Unit_Cost__c = worksheetLine.Unit_Cost__c;
            }
            //Ticket#22710 <<
        }
        else if (rateCode == 'OT') {
            costQty = overtimeCostQty;
            salesInvoiceLine.Quantity__c = worksheetLine.Overtime_Hours__c;
            salesInvoiceLine.Unit_Price__c = worksheetLine.Overtime_Rate__c;
            salesInvoiceLine.xUnit_Price__c = worksheetLine.xOvertime_Rate__c;
            salesInvoiceLine.Description__c += '-OT';
            /*
            if (String.isNotBlank(worksheetLine.Contract_Line__c)){
                salesInvoiceLine.Description__c = generateLineDescription(worksheetLine.Description__c, worksheetLine.Contract_Line__r.Customer_Overtime_Item_No__c, worksheetLine.Contract_Line__r.Customer_Overtime_Description__c);
            }
             */
            if (String.isNotBlank(contractLine.Id)){
                salesInvoiceLine.Description__c = generateLineDescription(worksheetLine.Description__c, contractLine.Customer_Overtime_Item_No__c, contractLine.Customer_Overtime_Description__c);
                //handle contract line with blank customer item no and customer description
                if(salesInvoiceLine.Description__c == worksheetLine.Description__c){
                    salesInvoiceLine.Description__c += '-OT';
                }
            }
            //Ticket#22710 >>
            if(CompanyMgmt.zeroIfNull(worksheetLine.Overtime_Unit_Cost__c) > 0) {
                salesInvoiceLine.Unit_Cost__c = worksheetLine.Overtime_Unit_Cost__c;
            } else {
                salesInvoiceLine.Unit_Cost__c = worksheetLine.Unit_Cost__c;
            }
            //Ticket#22710 <<
        }
        else if (rateCode == 'DT') {
            costQty = doubleTimeCostQty;
            salesInvoiceLine.Quantity__c = worksheetLine.Premium_Hours__c;
            salesInvoiceLine.Unit_Price__c = worksheetLine.Premium_Rate__c;
            salesInvoiceLine.xUnit_Price__c = worksheetLine.xPremium_Rate__c;
            salesInvoiceLine.Description__c += '-DT';
            /*
            if (String.isNotBlank(worksheetLine.Contract_Line__c)){
                salesInvoiceLine.Description__c = generateLineDescription(worksheetLine.Description__c, worksheetLine.Contract_Line__r.Customer_Premium_Item_No__c, worksheetLine.Contract_Line__r.Customer_Premium_Description__c);
            }
             */
            if (String.isNotBlank(contractLine.Id)){
                salesInvoiceLine.Description__c = generateLineDescription(worksheetLine.Description__c, contractLine.Customer_Premium_Item_No__c, contractLine.Customer_Premium_Description__c);
                //handle contract line with blank customer item no and customer description
                if(salesInvoiceLine.Description__c == worksheetLine.Description__c){
                    salesInvoiceLine.Description__c += '-DT';
                }
            }
            //Ticket#22710 >>
            if(CompanyMgmt.zeroIfNull(worksheetLine.Double_Time_Unit_Cost__c) > 0) {
                salesInvoiceLine.Unit_Cost__c = worksheetLine.Double_Time_Unit_Cost__c;
            } else {
                salesInvoiceLine.Unit_Cost__c = worksheetLine.Unit_Cost__c;
            }
            //Ticket#22710 <<
        }

        if (salesInvoiceLine.Bill_as_Lump_Sum__c || salesInvoiceLine.Non_Billable__c) {
            salesInvoiceLine.Unit_Price__c = 0;
        }

        if (jobTask.Billing_Type__c == 'Fixed Price') {
            salesInvoiceLine.Unit_Price__c = 0;
            //ticket 19672 <<
            //salesInvoiceLine.xUnit_Price__c = 0;
            //ticket 19672 >>
        }
        salesInvoiceLine.Line_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(salesInvoiceLine.Unit_Price__c) * CompanyMgmt.zeroIfNull(salesInvoiceLine.Quantity__c));
        salesInvoiceLine.xLine_Amount__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(salesInvoiceLine.xUnit_Price__c) * CompanyMgmt.zeroIfNull(salesInvoiceLine.Quantity__c));
        salesInvoiceLine.Tax__c = CompanyMgmt.halfUpTo2D(salesInvoiceLine.Line_Amount__c * CompanyMgmt.zeroIfNull(salesInvoiceLine.Tax_Pct__c) / 100);
        salesInvoiceLine.Line_Amt_Incl_Tax__c = salesInvoiceLine.Line_Amount__c + salesInvoiceLine.Tax__c;
        salesInvoiceLine.Cost_Qty__c = costQty;
        //salesInvoiceLine.Unit_Cost__c = worksheetLine.Unit_Cost__c; //Ticket#22710
        salesInvoiceLine.Line_Cost__c = CompanyMgmt.halfUpTo2D(companyMgmt.zeroIfNull(salesInvoiceLine.Unit_Cost__c) * salesInvoiceLine.Cost_Qty__c);
        salesInvoiceLine.Pricing_Source_2__c = worksheetLine.Pricing_Source_2__c; // W-000167
        return salesInvoiceLine;
    }

    private static String generateLineDescription(String lineDescription, String customerItemNo, String customerDescription) {
        String description = lineDescription;
        if (String.isNotBlank(customerItemNo) && String.isNotBlank(customerDescription)) {
            description = customerItemNo + ' - ' + customerDescription;
        } else if (String.isNotBlank(customerItemNo) && String.isNotBlank(lineDescription)) {
            description = lineDescription + ' - ' + customerItemNo;
        } else if (String.isNotBlank(customerDescription)) {
            description = customerDescription;
        }
        return description;
    }

    public static Sales_Invoice_Line__c createFixedPriceInvoiceLine(Sales_Invoice__c salesInvoice, Sales_Invoice_Job_Task__c jobTask, Integer nextInvoiceLineNo) {
        if (!ResourceService.resourcesByIds.containsKey(CompanySettingUtil.acvSetting.Fixed_Price_Job_Resource__c)) {
            throw new DataException('Fixed Price Job Resource is not set up.');
        }
        Resource__c fixedPriceJobResource = ResourceService.resourcesByIds.get(CompanySettingUtil.acvSetting.Fixed_Price_Job_Resource__c);

        Sales_Invoice_Line__c salesInvoiceLine = new Sales_Invoice_Line__c();
        salesInvoiceLine.Sales_Invoice__c = salesInvoice.Id;
        salesInvoiceLine.Line_No__c = nextInvoiceLineNo;
        salesInvoiceLine.Sales_Invoice_Job_Task__c = jobTask.Id;
        salesInvoiceLine.Resource__c = fixedPriceJobResource.Id;
        salesInvoiceLine.Description__c = fixedPriceJobResource.Description__c;
        salesInvoiceLine.Category__c = fixedPriceJobResource.Category__c;
        salesInvoiceLine.Unit_of_Measure__c = fixedPriceJobResource.Unit_of_Measure__c;
        salesInvoiceLine.Tax_Group__c = jobTask.Tax_Group__c;
        //Ticket#22015
        if(salesInvoiceLine.Tax_Group__c == 'NT') {
            salesInvoiceLine.Tax_Pct__c = 0;
        } else {
            salesInvoiceLine.Tax_Pct__c = jobTask.Tax_Pct__c;
        }
        salesInvoiceLine.Service_Center__c = salesInvoice.Service_Center__c; //AES-406
        salesInvoiceLine.Quantity__c = 1;
        salesInvoiceLine.Unit_Price__c = CompanyMgmt.zeroIfNull(jobTask.Billing_Amount__c);
        salesInvoiceLine.xUnit_Price__c = CompanyMgmt.zeroIfNull(salesInvoiceLine.Unit_Price__c);
        salesInvoiceLine.Unit_Cost__c = 0;
        salesInvoiceLine.Cost_Qty__c = 0;
        salesInvoiceLine.Line_Cost__c = 0;

        salesInvoiceLine.Line_Amount__c = salesInvoiceLine.Unit_Price__c * salesInvoiceLine.Quantity__c;
        salesInvoiceLine.xLine_Amount__c = salesInvoiceLine.xUnit_Price__c * salesInvoiceLine.Quantity__c;
        salesInvoiceLine.Tax__c = CompanyMgmt.halfUpTo2D(salesInvoiceLine.Line_Amount__c * salesInvoiceLine.Tax_Pct__c / 100);
        salesInvoiceLine.Line_Amt_Incl_Tax__c = salesInvoiceLine.Line_Amount__c + salesInvoiceLine.Tax__c;
        salesInvoiceLine.System_Calculated_Line__c = true; //disable user modifying the amount. The change of the amount should be done on the job task using billing % (to be implemented if required).
        return salesInvoiceLine;
    }

    public static void calculateSurchargeLine(Sales_Order__c salesOrder, Sales_Invoice__c salesInvoice, ACVSalesInvoiceJobTaskWrapper jobTaskWrapper, Integer nextInvoiceLineNo){

        if (String.isNotEmpty(salesInvoice.Surcharge_Type__c) && (salesInvoice.Surcharge_Type__c == 'EEC Fee' || salesInvoice.Surcharge_Type__c == 'Fuel Surcharge' || salesInvoice.Surcharge_Type__c == 'ESIC')) {
            Sales_Invoice_Line__c surchargeLine = new Sales_Invoice_Line__c();
            Decimal surchargeCostPct = 0; //Ticket#21883
            surchargeLine.Sales_Invoice__c = salesInvoice.Id;
            surchargeLine.Sales_Invoice_Job_Task__c = jobTaskWrapper.JobTask.Id;
            surchargeLine.Category__c = 'Misc. Charges And Taxes';
            surchargeLine.Line_No__c = nextInvoiceLineNo;
            surchargeLine.Tax_Group__c = 'TX';
            if (salesInvoice.Surcharge_Type__c == 'EEC Fee'){
                surchargeLine.Resource__c = defaultCompanySetup.Default_Energy_Insurance_Resource__c;
                surchargeLine.Description__c = defaultCompanySetup.Default_Energy_Insurance_Resource__r.Description__c;
                surchargeLine.Unit_of_Measure__c = defaultCompanySetup.Default_Energy_Insurance_Resource__r.Unit_of_Measure__c;
                //Ticket#21883 >>
                if(salesOrder.Subsidiary_Company__c != null && CompanyMgmt.zeroIfNull(salesOrder.Subsidiary_Company__r.EEC_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = salesOrder.Subsidiary_Company__r.EEC_Surcharge_Cost_Pct__c / 100;
                }
                if(salesOrder.Service_Center__c != null && CompanyMgmt.zeroIfNull(salesOrder.Service_Center__r.EEC_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = salesOrder.Service_Center__r.EEC_Surcharge_Cost_Pct__c / 100;
                }
                //Ticket#21883 <<
            }
            else if (salesInvoice.Surcharge_Type__c == 'Fuel Surcharge'){
                surchargeLine.Resource__c = defaultCompanySetup.Default_Fuel_Surcharge_Resource__c;
                surchargeLine.Description__c = defaultCompanySetup.Default_Fuel_Surcharge_Resource__r.Description__c;
                surchargeLine.Unit_of_Measure__c = defaultCompanySetup.Default_Fuel_Surcharge_Resource__r.Unit_of_Measure__c;
                //Ticket#21883 >>
                if(salesOrder.Subsidiary_Company__c != null && CompanyMgmt.zeroIfNull(salesOrder.Subsidiary_Company__r.Fuel_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = salesOrder.Subsidiary_Company__r.Fuel_Surcharge_Cost_Pct__c / 100;
                }
                if(salesOrder.Service_Center__c != null && CompanyMgmt.zeroIfNull(salesOrder.Service_Center__r.Fuel_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = salesOrder.Service_Center__r.Fuel_Surcharge_Cost_Pct__c / 100;
                }
                //Ticket#21883 <<
            }
            else{
                surchargeLine.Resource__c = defaultCompanySetup.Default_ESIC_Surcharge_Resource__c;
                surchargeLine.Description__c = defaultCompanySetup.Default_ESIC_Surcharge_Resource__r.Description__c;
                surchargeLine.Unit_of_Measure__c = defaultCompanySetup.Default_ESIC_Surcharge_Resource__r.Unit_of_Measure__c;
                //Ticket#21883 >>
                if(salesOrder.Subsidiary_Company__c != null && CompanyMgmt.zeroIfNull(salesOrder.Subsidiary_Company__r.ESIC_Surcharge_Cost_Pct__c) > 0){
                    surchargeCostPct = salesOrder.Subsidiary_Company__r.ESIC_Surcharge_Cost_Pct__c / 100;
                }
                if(salesOrder.Service_Center__c != null && CompanyMgmt.zeroIfNull(salesOrder.Service_Center__r.ESIC_Surcharge_Cost_Pct__c  ) > 0){
                    surchargeCostPct = salesOrder.Service_Center__r.ESIC_Surcharge_Cost_Pct__c   / 100;
                }

            }

            surchargeLine.Quantity__c = 1;
            Decimal unitPrice = 0;
            if (salesInvoice.Surcharge_Type__c == 'EEC Fee') {
                //ticket 19672 <<
                if (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price') {
                    if (jobTaskWrapper.JobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge') {
                        unitPrice = jobTaskWrapper.JobTask.Billing_Amount__c;
                    }
                }
                else {
                    //ticket 19672 >>
                    for (Sales_Invoice_Line__c salesInvoiceLine : jobTaskWrapper.SalesInvoiceLines) {
                        Boolean eiExempted = false;
                        //ticket 19942 <<
                        //if (salesInvoiceLine.Resource_Type__c != null && ResourceTypeUtil.resourceTypesByIds.containsKey(salesInvoiceLine.Resource_Type__c)) {
                        eiExempted = salesInvoiceLine.Non_Billable__c;
                        if (eiExempted != true && salesInvoiceLine.Resource_Type__c != null && ResourceTypeUtil.resourceTypesByIds.containsKey(salesInvoiceLine.Resource_Type__c)) {
                            //ticket 19942 >>
                            Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(salesInvoiceLine.Resource_Type__c);
                            eiExempted = resourceType.EEC_Surcharge_Exempted__c;
                        }
                        if (salesInvoiceLine.Resource__c != null && eiExempted != true && ResourceService.resourcesByIds.containsKey(salesInvoiceLine.Resource__c)) {
                            Resource__c resource = ResourceService.resourcesByIds.get(salesInvoiceLine.Resource__c);
                            eiExempted = resource.EEC_Surcharge_Exempted__c;
                        }
                        if (eiExempted != true) unitPrice += salesInvoiceLine.Line_Amount__c;
                    }
                    //ticket 19672 <<
                }
                //ticket 19672 >>
            }
            else if(salesInvoice.Surcharge_Type__c == 'ESIC'){
                for (Sales_Invoice_Line__c salesInvoiceLine : jobTaskWrapper.SalesInvoiceLines) {
                    	/*if(salesInvoiceLine.Resource_Type__c != null && ResourceTypeUtil.resourceTypesByIds.containsKey(salesInvoiceLine.Resource_Type__c)) {
                            //ticket 19942 >>
                            Resource_Type__c resourceType = ResourceTypeUtil.resourceTypesByIds.get(salesInvoiceLine.Resource_Type__c);
                            //eiExempted = resourceType.EEC_Surcharge_Exempted__c;
                        }*/
                     unitPrice += salesInvoiceLine.Line_Amount__c;
                }
            }
            else {
                for (Sales_Invoice_Line__c sil : jobTaskWrapper.SalesInvoiceLines) {
                    //ticket 19942 <<
                    if (sil.Non_Billable__c == true) continue;
                    //ticket 19942 >>
                    if (sil.Category__c == 'Equipment' && sil.Resource_Type__r.Fuel_Fired_Equipment__c) {
                        //ticket 19672 <<
                        //if (sil.Bill_as_Lump_Sum__c == true || sil.Non_Billable__c == true) {
                        //  unitPrice += CompanyMgmt.zeroIfNull(sil.Quantity__c) * CompanyMgmt.zeroIfNull(sil.xUnit_Price__c);
                        if (sil.Bill_as_Lump_Sum__c == true || sil.Non_Billable__c == true || jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price') {
                            unitPrice += CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(sil.Quantity__c) * CompanyMgmt.zeroIfNull(sil.xUnit_Price__c));
                            //ticket 19672 >>
                        } else {
                            unitPrice += sil.Line_Amount__c;
                        }
                    }
                }
            }
            unitPrice = salesInvoice.Surcharge_Pct__c > 0 ? (unitPrice * salesInvoice.Surcharge_Pct__c / 100).setScale(2) : 0;
            surchargeLine.Unit_Price__c = unitPrice;
            surchargeLine.xUnit_Price__c = unitPrice;
            surchargeLine.Line_Amount__c = unitPrice;
	         if(salesOrder.Tax_Liable__c){
                	surchargeLine.Tax_Group__c = 'TX';    
                	surchargeLine.Tax_Pct__c = TaxService.getTaxPct(salesOrder.Tax_Area__c, surchargeLine.Tax_Group__c);
                	surchargeLine.Tax__c = CompanyMgmt.halfUpTo2D(surchargeLine.Line_Amount__c * CompanyMgmt.zeroIfNull(surchargeLine.Tax_Pct__c) / 100);
                	surchargeLine.Line_Amt_Incl_Tax__c = surchargeLine.Line_Amount__c + surchargeLine.Tax__c;
                }else{
                	surchargeLine.Tax_Group__c = 'NT';    
                	surchargeLine.Tax_Pct__c = 0; 
                	surchargeLine.Tax__c = 0; 
                	surchargeLine.Line_Amt_Incl_Tax__c = unitPrice; 
                } 
	//Ticket#21883 >>
            surchargeLine.Unit_Cost__c = surchargeLine.Line_Amount__c * surchargeCostPct;
            surchargeLine.Line_Cost__c = surchargeLine.Unit_Cost__c;
            //surchargeLine.Unit_Cost__c = 0;
            //surchargeLine.Line_Cost__c = 0;
            //Ticket#21883 <<
            surchargeLine.System_Calculated_Line__c = true;

            //ticket 19942 <<
            //jobTaskWrapper.SalesInvoiceLines.add(surchargeLine);
            if (unitPrice > 0) {
                jobTaskWrapper.SalesInvoiceLines.add(surchargeLine);
            }
            //ticket 19942 >>

        }
    }

    public void calculateLaborHours(Id salesOrderId, List<Billing_Worksheet_Line__c> worksheetLines, Billing_Worksheet_Line__c updatedBillingWorksheetLine) {
        List<Billing_Worksheet_Line__c> worksheetLinesToProcess = new List<Billing_Worksheet_Line__c>();
        for(Billing_Worksheet_Line__c billingWorksheetLine : worksheetLines){
            if(billingWorksheetLine.Category__c == 'Labor' && billingWorksheetLine.Resource__c == updatedBillingWorksheetLine.Resource__c){
                worksheetLinesToProcess.add(billingWorksheetLine);
                System.debug('Info: billingWorksheetLine ' + billingWorksheetLine.Line_No__c + ' -- ' + billingWorksheetLine.Description__c);
            }
        }
        if(worksheetLinesToProcess.size() > 0){
            calculateLaborHours(salesOrderId, worksheetLinesToProcess);
        }
    }

    public void calculateLaborHours(Id salesOrderId, List<Billing_Worksheet_Line__c> worksheetLines) {
        Sales_Order__c salesOrder = salesOrdersByIds.get(salesOrderId);
        if (salesOrder.Billing_Rule_Not_Required__c == true) {
            return;
        }

        //Ticket#20496 >>
        Boolean weeklyTotalCalculationEnabled = false;
        if (salesOrder.Contract__r != null && salesOrder.Contract__r.Billing_Rule__c != null && salesOrder.Contract__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c == true) {
            weeklyTotalCalculationEnabled = true;
        } else if (salesOrder.Billing_Rule__c != null && salesOrder.Billing_Rule__r.Enable_Weekly_Total_Calculation__c == true){
            weeklyTotalCalculationEnabled = true;
        }
        //Ticket#20496 <<

        List<BillingLine> billingLines = new List<BillingLine>();
        Map<Integer, Billing_Worksheet_Line__c> mapBillingWorksheetLinesByLineNo = new Map<Integer, Billing_Worksheet_Line__c>();

        //Ticket#20496 >>
        Set<Id> weekNumberSet = new Set<Id>();
        Set<Id> laborResIds = new Set<Id>();
        Set<Id> billingWorksheetLineIds = new Set<Id>();
        Set<Id> billingWorksheetLineIdsNeedToBeUpdatedHere = new Set<Id>();
        /*
        Date earliestWorkDate = null;
        Date recentWorkDate = null;
         */
        //Ticket#20496 <<

        for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
            if (worksheetLine.Category__c == 'Labor') {
                if (tmsByIds.containsKey(worksheetLine.TM__c)) {
                    TM__c tm = tmsByIds.get(worksheetLine.TM__c);

                    BillingLine billingLine = initBillingLine(salesOrder, tm, worksheetLine);
                    billingLines.add(billingLine);
                    mapBillingWorksheetLinesByLineNo.put(worksheetLine.Line_No__c.intValue(), worksheetLine);
                    //Ticket#20496 >>
                    laborResIds.add(worksheetLine.Resource__c);
                    if(worksheetLine.Week_Number__c != null){
                        weekNumberSet.add(worksheetLine.Week_Number__c);
                    }

                    if(worksheetLine.Id != null){
                        billingWorksheetLineIds.add(worksheetLine.Id);
                    }

                    /*
                    if(earliestWorkDate == null || earliestWorkDate > tm.Scheduled_Date__c){
                        earliestWorkDate = tm.Scheduled_Date__c;
                    }

                    if(recentWorkDate == null || recentWorkDate < tm.Scheduled_Date__c){
                        recentWorkDate = tm.Scheduled_Date__c;
                    }
                     */
                    //Ticket#20496 <<
                }
            }
        }

        //Ticket#20496 >>
        if(billingLines.size() > 0 && weeklyTotalCalculationEnabled == true){
            /*
            //Get week number between earliestWorkDate and recentWorkDate plus the week after recentWorkDate
            Date tempStartDate, tempEndDate;
            tempStartDate = earliestWorkDate.toStartOfWeek().addDays(1);
            tempEndDate = recentWorkDate.toStartOfWeek().addDays(8);
            Map<Date, Week_Number__c> weekNumbersByWeekStartDate = new Map<Date, Week_Number__c>();
            List<Week_Number__c> weekNumbers = [SELECT Id, Name, Week_Start_Date__c FROM Week_Number__c WHERE Week_Start_Date__c >= :tempStartDate AND Week_Start_Date__c <= :tempEndDate];
            for(Week_Number__c weekNumber : weekNumbers){
                weekNumbersByWeekStartDate.put(weekNumber.Week_Start_Date__c, weekNumber);
            }

            billingLine.LunchStartTime = worksheetLine.Lunch_Start_Time__c;
            billingLine.LunchEndTime = worksheetLine.Lunch_End_Time__c;
            billingLine.IncludeLunch = worksheetLine.Include_Lunch_Y_N__c;
            billingLine.Quantity = worksheetLine.Quantity__c;
            billingLine.UnitOfMeasureId = worksheetLine.Unit_of_Measure__c;
            billingLine.UnitOfMeasure = worksheetLine.Unit_of_Measure__r;
            billingLine.RegularRate = worksheetLine.Regular_Rate__c;
            billingLine.OvertimeRate = worksheetLine.Overtime_Rate__c;
            billingLine.DoubleTimeRate = worksheetLine.Premium_Rate__c;
            billingLine.UnitPrice = worksheetLine.Unit_Price__c;
            billingLine.UnitCost = worksheetLine.Unit_Cost__c;
            billingLine.TaxPercent = worksheetLine.Tax_Pct__c;
             */

            Map<Id, Map<Id, Decimal>> numberOfHoursBilledByWeekNumberIdByResourceId = new Map<Id, Map<Id, Decimal>>();
            List<Billing_Worksheet_Line__c> billingWorksheetLines =
                [SELECT Id, Resource__c, Week_Number__c, Hour__c, Regular_Hours__c, Include_Lunch_Y_N__c,
                        Lunch_Start_Time__c, Lunch_End_Time__c, TM__r.T_M_Scheduled_Day__c, TM__r.Scheduled_Date__c,
                        Invoiced__c, TM__r.Name, Resource__r.Name, Resource__r.Description__c, Line_No__c,
                        Billing_Start_Time__c, Billing_End_Time__c, Unit_of_Measure__c,Quantity__c,Unit_of_Measure__r.Name, Unit_of_Measure__r.Hours_UOM__c,
                        Regular_Rate__c,Overtime_Rate__c,Premium_Rate__c,Unit_Price__c,Unit_Cost__c,Tax_Pct__c, TM__c, Resource_Type__c,
                        Sales_Order__c, Overtime_Hours__c, Premium_Hours__c, Min_Sell_Qty__c,Markup__c,Cost_Qty__c,
                        Bill_as_Lump_Sum__c,Non_Billable__c, xUnit_Price__c, xUnit_Cost__c, xRegular_Rate__c, xOvertime_Rate__c,
                        xPremium_Rate__c, Markup_Option__c, Line_Amount__c, Tax__c, Line_Amt_Incl_Tax__c, Line_Cost__c,
                        xLine_Amount__c, xLine_Cost__c, Category__c
                 FROM Billing_Worksheet_Line__c
                 WHERE Sales_Order__r.Billing_Rule__c = :salesOrder.Billing_Rule__c AND Category__c = 'Labor' AND Resource__c IN :laborResIds AND Week_Number__c IN :weekNumberSet
                        AND Id NOT IN :billingWorksheetLineIds
                 ORDER BY TM__r.Scheduled_Date__c ASC];

            /*
            for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
                System.debug('Info: billing line: ' + billingWorksheetLine.TM__r.Name + ' -- ' + billingWorksheetLine.TM__r.Scheduled_Date__c + ' -- ' + billingWorksheetLine.Resource__r.Name + ' -- ' + billingWorksheetLine.Resource__r.Description__c);
            }
             */

            for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
                if(billingWorksheetLine.Week_Number__c != null && billingWorksheetLine.Resource__c != null) {
                    if(billingWorksheetLine.Invoiced__c == true) {
                        Decimal weeklyTotal = CompanyMgmt.zeroIfNull(billingWorksheetLine.Regular_Hours__c);
                        Map<Id, Decimal> laborNumberOfHoursWorkedByWeekNumberId = new Map<Id, Decimal>();
                        //Overnight shift Sunday
                        /*
                        if(billingWorksheetLine.TM__r.T_M_Scheduled_Day__c == 'Sunday' &&
                                billingWorksheetLine.Job_End_Time__c < billingWorksheetLine.Job_Start_Time__c &&
                                billingWorksheetLine.Job_End_Time__c != TimeUtils.midNight()){
                            Decimal nextWkHours = TimeUtils.calculateHours(TimeUtils.midNight(), billingWorksheetLine.Job_End_Time__c);
                            weeklyTotal = weeklyTotal - nextWkHours;

                            //Handle lunch time
                            Decimal lunchHours = TimeUtils.calculateHours(billingWorksheetLine.Lunch_Start_Time__c, billingWorksheetLine.Lunch_End_Time__c);
                            if(billingWorksheetLine.Include_Lunch_Y_N__c != true && lunchHours > 0) {
                                //Lunch occurs on next week Monday
                                if (billingWorksheetLine.Lunch_Start_Time__c < billingWorksheetLine.Job_Start_Time__c) {
                                    nextWkHours = nextWkHours - lunchHours;
                                    weeklyTotal = weeklyTotal + lunchHours;
                                }
                            }

                            if(nextWkHours > 0){
                                Date nextWeekStartDate = billingWorksheetLine.TM__r.Scheduled_Date__c.addDays(1);
                                Week_Number__c nextWeekNumber = new Week_Number__c();
                                if(weekNumbersByWeekStartDate.containsKey(nextWeekStartDate)){
                                    nextWeekNumber = weekNumbersByWeekStartDate.get(nextWeekStartDate);
                                } else {
                                    nextWeekNumber = [SELECT Id FROM Week_Number__c WHERE Week_Start_Date__c = :nextWeekStartDate LIMIT 1];
                                }

                                if(numberOfHoursBilledByWeekNumberIdByResourceId.containsKey(billingWorksheetLine.Resource__c)){
                                    laborNumberOfHoursWorkedByWeekNumberId = numberOfHoursBilledByWeekNumberIdByResourceId.get(billingWorksheetLine.Resource__c);
                                    if(laborNumberOfHoursWorkedByWeekNumberId.containsKey(nextWeekNumber.Id)){
                                        nextWkHours = nextWkHours + laborNumberOfHoursWorkedByWeekNumberId.get(nextWeekNumber.Id);
                                    }
                                }
                                laborNumberOfHoursWorkedByWeekNumberId.put(nextWeekNumber.Id, nextWkHours);
                                numberOfHoursBilledByWeekNumberIdByResourceId.put(billingWorksheetLine.Resource__c, laborNumberOfHoursWorkedByWeekNumberId);
                            }
                        }
                         */

                        if (numberOfHoursBilledByWeekNumberIdByResourceId.containsKey(billingWorksheetLine.Resource__c)) {
                            laborNumberOfHoursWorkedByWeekNumberId = numberOfHoursBilledByWeekNumberIdByResourceId.get(billingWorksheetLine.Resource__c);
                            if (laborNumberOfHoursWorkedByWeekNumberId.containsKey(billingWorksheetLine.Week_Number__c)) {
                                weeklyTotal = weeklyTotal + laborNumberOfHoursWorkedByWeekNumberId.get(billingWorksheetLine.Week_Number__c);
                            }
                        }
                        laborNumberOfHoursWorkedByWeekNumberId.put(billingWorksheetLine.Week_Number__c, weeklyTotal);
                        numberOfHoursBilledByWeekNumberIdByResourceId.put(billingWorksheetLine.Resource__c, laborNumberOfHoursWorkedByWeekNumberId);
                    } else {
                        TM__c tm = new TM__c(Name = billingWorksheetLine.TM__r.Name, Scheduled_Date__c = billingWorksheetLine.TM__r.Scheduled_Date__c);
                        BillingLine billingLine = initBillingLine(salesOrder, tm, billingWorksheetLine);
                        billingLines.add(billingLine);
                        mapBillingWorksheetLinesByLineNo.put(billingWorksheetLine.Line_No__c.intValue(), billingWorksheetLine);
                        billingWorksheetLineIdsNeedToBeUpdatedHere.add(billingWorksheetLine.Id);
                    }
                }
            }

            if (billingLines.size() > 0) {
                //BillingService.calculateBillingLinesWeeklyTotalRule(billingLines, numberOfHoursBilledByWeekNumberIdByResourceId, weekNumbersByWeekStartDate);
                BillingLineWrapper[] billingLineWrappers = new List<BillingLineWrapper>();
                for (BillingLine billingLine : billingLines) {
                    billingLineWrappers.add(new BillingLineWrapper(billingLine));
                }

                //Sort by Scheduled Date and by Start Time(ASC)
                billingLineWrappers.sort();

                billingLines = new List<BillingLine>();
                for(BillingLineWrapper billingLineWrapper : billingLineWrappers){
                    //System.debug('Info: billLineWrapper ' + billingLineWrapper.billingLine.ScheduleDate);
                    billingLines.add(billingLineWrapper.billingLine);
                }

                //System.debug('Info: numberOfHoursBilledByWeekNumberIdByResourceId: ' + numberOfHoursBilledByWeekNumberIdByResourceId);
                BillingService.calculateBillingLinesWeeklyTotalRule(billingLines, numberOfHoursBilledByWeekNumberIdByResourceId);
                //List<Billing_Worksheet_Line__c> billingWorksheetLinesNeedToUpdatedHere = new List<Billing_Worksheet_Line__c>();
                Map<Id, Billing_Worksheet_Line__c> billingWorksheetLinesNeedToUpdatedHereById = new Map<Id, Billing_Worksheet_Line__c>();
                for (BillingLine billingLine : billingLines) {
                    if (mapBillingWorksheetLinesByLineNo.containsKey(billingLine.LineNumber)) {
                        Billing_Worksheet_Line__c worksheetLine = mapBillingWorksheetLinesByLineNo.get(billingLine.LineNumber);
                        System.debug('Info: billing Line calculated Line: ' + billingLine.LineNumber + ' BWL ' + worksheetLine.Line_No__c + 'TM ' + worksheetLine.TM__r.Name + ' - ' + billingLine.ScheduleDate + ' Reg: ' + billingLine.RegularHours + ' OT: ' + billingLine.OvertimeHours + ' DT: ' + billingLine.DoubleTimeHours);
                        worksheetLine.Regular_Hours__c = billingLine.RegularHours;
                        worksheetLine.Overtime_Hours__c = billingLine.OvertimeHours;
                        worksheetLine.Premium_Hours__c = billingLine.DoubleTimeHours;
                        calculateLineTotals(worksheetLine, false);
                        if(billingWorksheetLineIdsNeedToBeUpdatedHere.contains(worksheetLine.Id)){
                            billingWorksheetLinesNeedToUpdatedHereById.put(worksheetLine.Id, worksheetLine);
                            //billingWorksheetLinesNeedToUpdatedHere.add(worksheetLine);
                        }
                    }
                }
                if(billingWorksheetLinesNeedToUpdatedHereById.size() > 0){
                    CompanyMgmt.systemCall = true;
                    update billingWorksheetLinesNeedToUpdatedHereById.values();
                }
            }
        }

        if (billingLines.size() > 0 && weeklyTotalCalculationEnabled == false) {
            BillingService.initSetupData(billingLines);
            BillingService.calculateBillingLines(billingLines);
            for (BillingLine billingLine : billingLines) {
                if (mapBillingWorksheetLinesByLineNo.containsKey(billingLine.LineNumber)) {
                    Billing_Worksheet_Line__c worksheetLine = mapBillingWorksheetLinesByLineNo.get(billingLine.LineNumber);
                    worksheetLine.Regular_Hours__c = billingLine.RegularHours;
                    worksheetLine.Overtime_Hours__c = billingLine.OvertimeHours;
                    worksheetLine.Premium_Hours__c = billingLine.DoubleTimeHours;
                }
            }
        }
        //Ticket#20496 <<
    }

    private static BillingLine initBillingLine(Sales_Order__c salesOrder, TM__c tm, Billing_Worksheet_Line__c worksheetLine) {
        BillingLine billingLine = new BillingLine();
        billingLine.LineNumber = worksheetLine.Line_No__c.intValue();

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
        //Ticket#21540 >>
        else {
            /* Ticket#24650 >>
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
                throw new DataException('Order assumption ' + assumption + ' is not mapped to a billing rule. Please contact admin to set up the mapping for the assumption.');
            }
             */
            billingLine.BillingRule = BillingRuleService.getBillingRuleIdForSalesOrderAssumption(salesOrder);
            billingLine.BillingRuleId = billingLine.BillingRule.Id;
            // Ticket#24650 <<
        }
        //billingLine.BillingRuleId = salesOrder.Billing_Rule__c;
        billingLine.ScheduleDate = tm.Scheduled_Date__c;
        billingLine.StartTime = worksheetLine.Billing_Start_Time__c;
        billingLine.EndTime = worksheetLine.Billing_End_Time__c;
        billingLine.LunchStartTime = worksheetLine.Lunch_Start_Time__c;
        billingLine.LunchEndTime = worksheetLine.Lunch_End_Time__c;
        billingLine.IncludeLunch = worksheetLine.Include_Lunch_Y_N__c;
        billingLine.Quantity = worksheetLine.Quantity__c;
        billingLine.UnitOfMeasureId = worksheetLine.Unit_of_Measure__c;
        billingLine.UnitOfMeasure = worksheetLine.Unit_of_Measure__r;
        billingLine.RegularRate = worksheetLine.Regular_Rate__c;
        billingLine.OvertimeRate = worksheetLine.Overtime_Rate__c;
        billingLine.DoubleTimeRate = worksheetLine.Premium_Rate__c;
        billingLine.UnitPrice = worksheetLine.Unit_Price__c;
        billingLine.UnitCost = worksheetLine.Unit_Cost__c;
        billingLine.TaxPercent = worksheetLine.Tax_Pct__c;
        billingLine.ContractId = salesOrder.Contract__c;
        billingLine.TMStatus = null;
        billingLine.RegularHours = 0;
        billingLine.OvertimeHours = 0;
        billingLine.DoubleTimeHours = 0;
        billingLine.DayRateCode = '';
        //Ticket#20496 >>
        billingLine.resourceId = worksheetLine.Resource__c;
        billingLine.weekNumberId = worksheetLine.Week_Number__c;
        //Ticket#20496 <<
        return billingLine;
    }
    
    //DE36562
    public void populateWasteDisposalLineInfo(List<Billing_Worksheet_Line__c> worksheetLines){
        system.debug('inside populateWasteDisposalLineInfo******************');
        for(Billing_Worksheet_Line__c worksheetLine : worksheetLines){
            system.debug('worksheetLine name:::::'+worksheetLine.Name);
            if(worksheetLine.Category__c == 'Waste Disposal'){
                system.debug('worksheetLine category:::::'+worksheetLine.Category__c);
                if(worksheetLine.Sales_Line__c != null){
                    Sales_Line__c relatedSalesLine = getSalesLine(worksheetLine.Sales_Line__c);                    
                    if(relatedSalesLine.Disposal_Billing_Method__c != null){
                        worksheetLine.Disposal_Billing_Method__c = relatedSalesLine.Disposal_Billing_Method__c;
                    }
                }else{
                    if(worksheetLine.Quote_Line__c != null){
                        Sales_Line__c relatedSalesLine = getSalesLine(worksheetLine.Quote_Line__c);                    
                        if(relatedSalesLine.Disposal_Billing_Method__c != null){
                         	worksheetLine.Disposal_Billing_Method__c = relatedSalesLine.Disposal_Billing_Method__c;
                        }
                    }
                    else{
                    	worksheetLine.Disposal_Billing_Method__c = worksheetLine.TM__r.Sales_Order__r.Disposal_Billing_Method__c;
                    }
                }
                
                    
                
            }
        }

    }

    //US135286 - Surcharge percentage calculation
    public static void setSurchargePct(Sales_Order__c salesOrder, Sales_Invoice__c salesInvoice) {
        Boolean surchargeFound = false;
        if (salesOrder.Contract__c != null) {
                salesInvoice.Surcharge_Pct__c = salesOrder.Surcharge_Pct__c;
                surchargeFound = true;
        } else if (salesOrder.Surcharge_Type__c == null || salesOrder.Surcharge_Type__c == 'N/A') {
            salesInvoice.Surcharge_Pct__c = null;
        }

        if (salesInvoice.Surcharge_Type__c != null && (salesInvoice.Surcharge_Type__c == 'EEC Fee' || salesInvoice.Surcharge_Type__c == 'Fuel Surcharge' || salesInvoice.Surcharge_Type__c == 'ESIC') 
            && salesInvoice.Invoice_Date__c != null && surchargeFound == false) {
            List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectById(new Set<Id>{salesInvoice.Service_Center__c});
            if(serviceCenters != null && serviceCenters.size() > 0) {
                if (salesInvoice.Surcharge_Type__c == 'EEC Fee' && CompanyMgmt.zeroIfNull(serviceCenters[0].Energy_Environmental_Compliance_Pct__c) > 0) {
                    salesInvoice.Surcharge_Pct__c = serviceCenters[0].Energy_Environmental_Compliance_Pct__c;
                    surchargeFound = true;
                } else if (salesInvoice.Surcharge_Type__c == 'Fuel Surcharge' && CompanyMgmt.zeroIfNull(serviceCenters[0].Fuel_Surcharge_Pct__c) > 0) {
                    salesInvoice.Surcharge_Pct__c = serviceCenters[0].Fuel_Surcharge_Pct__c;
                    surchargeFound = true;
                } else if(salesOrder.Surcharge_Type__c == 'ESIC' && CompanyMgmt.zeroIfNull(serviceCenters[0].ESIC_Surcharge_Cost_Pct__c) > 0){
                    salesInvoice.Surcharge_Pct__c = serviceCenters[0].ESIC_Surcharge_Cost_Pct__c;
                    surchargeFound = true;
                }
            }  if(surchargeFound == false) {
                Surcharge_Setup__c surchargeSetup = SurchargeSetupsSelector.newInstance().selectByTypeAndEffectiveDate(salesInvoice.Invoice_Date__c, salesInvoice.Surcharge_Type__c, salesInvoice.Subsidiary_Company__c);
                if (surchargeSetup != null) {
                    salesInvoice.Surcharge_Pct__c = surchargeSetup.Surcharge_Pct__c;
                } else {
                    salesInvoice.Surcharge_Pct__c = null;
                }
            }
        }     
    }


}