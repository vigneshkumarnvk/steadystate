public class ContractUtil {

    public static Map<Id, Map<Id, Map<Id, Contract_Line__c>>> contractLineByUOMIdsResOrTypeIdsByContractIds = new Map<Id, Map<Id, Map<Id, Contract_Line__c>>>();
    /*Waste001
    //String Key = Contract Id:Res Id:Facility:UOM:Min Sell UOM
    public static Map<String, Contract_Line__c> wasteContractLinesByContractResFacilityUomMinSellUOM = new Map<String, Contract_Line__c>();
     */
    //String Key = Contract Id:Res Id:Facility:UOM
    public static Map<String, Contract_Line__c> wasteContractLinesByContractResFacility = new Map<String, Contract_Line__c>();
    public static Map<Id, Contract_Line__c> contractLinesByIds = new Map<Id, Contract_Line__c>();

    public static void setContractLineByUOMIdsResOrTypeIdsByContractIdsMap(Set<Id> contractIds, Date workDate){
        List<Contract_Line__c> contractLines = ContractLinesSelector.newInstance().selectLinesByContractIdByWorkDate(contractIds, workDate);
        if(contractLines.size() > 0){
            contractLinesByIds.putAll(contractLines);
        }
        for(Contract_Line__c contractLine:contractLines) {
            /*Ticket#21616
            if(contractLine.Resource_Category__c == 'Waste Disposal'){
                if(contractLine.Resource__c != null){
                    String mapKey =  contractLine.Contract__c + ':' + contractLine.Resource__c + ':' + contractLine.Facility__c
                            + ':' + contractLine.Unit_of_Measure__c;
                    if(wasteContractLinesByContractResFacility.containsKey(mapKey)){
                        continue;
                    } else {
                        wasteContractLinesByContractResFacility.put(mapKey, contractLine);
                    }
                }
            }
             */

            Map<Id, Map<Id, Contract_Line__c>> contractLinesByUOMIdsByResOrTypeIds = new Map<Id, Map<Id, Contract_Line__c>>();
            Map<Id, Contract_Line__c> contractLinesByUOMIds = new Map<Id, Contract_Line__c>();
            if (contractLineByUOMIdsResOrTypeIdsByContractIds.containsKey(contractLine.Contract__c)) {
                contractLinesByUOMIdsByResOrTypeIds = contractLineByUOMIdsResOrTypeIdsByContractIds.get(contractLine.Contract__c);
            }

            if (contractLine.Resource_Type__c != null && contractLinesByUOMIdsByResOrTypeIds.containsKey(contractLine.Resource_Type__c)){
                contractLinesByUOMIds = contractLinesByUOMIdsByResOrTypeIds.get(contractLine.Resource_Type__c);
            } else if (contractLine.Resource__c != null && contractLinesByUOMIdsByResOrTypeIds.containsKey(contractLine.Resource__c)){
                contractLinesByUOMIds = contractLinesByUOMIdsByResOrTypeIds.get(contractLine.Resource__c);
            }

            if (contractLinesByUOMIds.containsKey(contractLine.Unit_of_Measure__c)){
                continue;
            } else {
                contractLinesByUOMIds.put(contractLine.Unit_of_Measure__c, contractLine);
                if(contractLine.Resource_Type__c != null) {
                    contractLinesByUOMIdsByResOrTypeIds.put(contractLine.Resource_Type__c, contractLinesByUOMIds);
                }
                else if (contractLine.Resource__c != null) {
                    contractLinesByUOMIdsByResOrTypeIds.put(contractLine.Resource__c, contractLinesByUOMIds);
                }
                contractLineByUOMIdsResOrTypeIdsByContractIds.put(contractLine.Contract__c, contractLinesByUOMIdsByResOrTypeIds);
            }
        }
    }

    public static Contract_Line__c getContractLine(Id contractLineId){
        Contract_Line__c contractLine = new Contract_Line__c();
        if(contractLinesByIds.containsKey(contractLineId)){
            contractLine = contractLinesByIds.get(contractLineId);
        }
        return contractLine;
    }

    public static Contract_Line__c getContractLine(Id contractId, Id resourceOrResourceTypeId, Id uomId){
        Contract_Line__c contractLine = new Contract_Line__c();
        if(contractLineByUOMIdsResOrTypeIdsByContractIds.containsKey(contractId)){
            Map<Id, Map<Id, Contract_Line__c>> contractLineByUOMIdsByResTypeId = contractLineByUOMIdsResOrTypeIdsByContractIds.get(contractId);
            if (contractLineByUOMIdsByResTypeId.containsKey(resourceOrResourceTypeId)) {
                Map<Id, Contract_Line__c> contractLinesByUOMIds = contractLineByUOMIdsByResTypeId.get(resourceOrResourceTypeId);
                if (contractLinesByUOMIds.containsKey(uomId)) contractLine = contractLinesByUOMIds.get(uomId);
            }
        }
        return contractLine;
    }

    /* Waste001 Depreciated */
    public static Contract_Line__c getContractLine(Id contractId, Id resourceOrResourceTypeId, Id uomId, String costMethod, Id containerUOMId, Id facilityId){
        String lookupKey = '';
        Contract_Line__c contractLine = new Contract_Line__c();
        if(costMethod == EnumUtil.CostMethod.UNIT_WEIGHT_VOL.name()){
            lookupKey = contractId + ':' + resourceOrResourceTypeId + ':' + facilityId + ':' + uomId + ':' + containerUOMId;
            if(!wasteContractLinesByContractResFacility.containsKey(lookupKey)){
                lookupKey = contractId + ':' + resourceOrResourceTypeId + ':' + facilityId + ':' + uomId + ':null';
            }
        } else {
            lookupKey = contractId + ':' + resourceOrResourceTypeId + ':' + facilityId + ':' + uomId + ':null';
        }
        if(wasteContractLinesByContractResFacility.size() > 0
                && ContractUtil.wasteContractLinesByContractResFacility.containsKey(lookupKey)) {
            contractLine = ContractUtil.wasteContractLinesByContractResFacility.get(lookupKey);
        }
        return contractLine;
    }

    public static Contract_Line__c getContractLine(Id contractId, Id resourceOrResourceTypeId, Id uomId, Id facilityId){
        String lookupKey = contractId + ':' + resourceOrResourceTypeId + ':' + facilityId + ':' + uomId;
        Contract_Line__c contractLine = new Contract_Line__c();
        if(wasteContractLinesByContractResFacility.size() > 0
                && ContractUtil.wasteContractLinesByContractResFacility.containsKey(lookupKey)) {
            contractLine = ContractUtil.wasteContractLinesByContractResFacility.get(lookupKey);
        }
        return contractLine;
    }

    public static String generateLineDescription(String lineDescription, String customerItemNo, String customerDescription){
        String description = lineDescription;
        if(String.isNotBlank(customerItemNo) && String.isNotBlank(customerDescription)){
            description = customerItemNo + ' - ' + customerDescription;
        } else if (String.isNotBlank(customerItemNo) && String.isNotBlank(lineDescription)){
            description = lineDescription + ' - ' + customerItemNo;
        } else if (String.isNotBlank(customerDescription)){
            description = customerDescription;
        }
        System.debug(description);
        return description;
    }

    public static void insertAccountContractAssociation(Id accountId, Id contractId){
        try {
            System.debug('Info: contractId ' + contractId);
            List<Account_Contract_Association__c> accountContractAssociations =
                    ContractsSelector.newInstance().selectAccountContractAssociationByAcctIdAndConttractId(accountId, contractId);
            if(accountContractAssociations.size() == 0){
                Account_Contract_Association__c accountContractAssociation = new Account_Contract_Association__c();
                accountContractAssociation.Account__c = accountId;
                accountContractAssociation.Contract__c = contractId;
                insert accountContractAssociation;
            }
        } catch(Exception e){
            throw e;
        }
    }

    public static void deleteAccountContractAssociation(Id accountId, Id contractId){
        try{
            List<Account_Contract_Association__c> accountContractAssociations =
                    ContractsSelector.newInstance().selectAccountContractAssociationByAcctIdAndConttractId(accountId, contractId);
            if(accountContractAssociations.size() > 0) {
                delete accountContractAssociations;
            }
        } catch (Exception e){
            throw e;
        }
    }

    //job task <<
    public static Contract_Line__c getContractLine(Id contractLineId, Date workDate){
        Contract_Line__c contractLine = new Contract_Line__c();
        if(contractLinesByIds.containsKey(contractLineId)){
            //Ticket#19511 >>
            Date contractLineEndDate = contractLinesByIds.get(contractLineId).End_Date__c;
            if (contractLineEndDate == null || contractLineEndDate >= workDate) {
                contractLine = contractLinesByIds.get(contractLineId);
            }
            //Ticket#19511 >>
        }
        return contractLine;
    }

    public static Contract_Line__c getContractLine(Id contractId, Id resourceOrResourceTypeId, Id uomId, Date workDate){
        Contract_Line__c contractLine = new Contract_Line__c();
        if(contractLineByUOMIdsResOrTypeIdsByContractIds.containsKey(contractId)){
            Map<Id, Map<Id, Contract_Line__c>> contractLineByUOMIdsByResTypeId = contractLineByUOMIdsResOrTypeIdsByContractIds.get(contractId);
            if (contractLineByUOMIdsByResTypeId.containsKey(resourceOrResourceTypeId)) {
                Map<Id, Contract_Line__c> contractLinesByUOMIds = contractLineByUOMIdsByResTypeId.get(resourceOrResourceTypeId);
                if (contractLinesByUOMIds.containsKey(uomId)) {
                    Contract_Line__c tempContractLine = new Contract_Line__c();
                    tempContractLine = contractLinesByUOMIds.get(uomId);
                    if (tempContractLine.End_Date__c == null || tempContractLine.End_Date__c >= workDate) {
                        contractLine = tempContractLine;
                    }
                }
            }
        }
        return contractLine;
    }
    //job task >>

    public static void updateSalesOrderSurchargeCharge(Map<Id, Contract> contractsByIds){
        List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectByContractIdsWithLines(contractsByIds.keySet());
        if(salesOrders.size() > 0) {
            List<Sales_Line__c> salesLinesToUpdate = new List<Sales_Line__c>();
            List<Sales_Line__c> salesLinesToRemove = new List<Sales_Line__c>();
            Company_Setup__c companySetup = CompanySettingUtil.defaultCompanySetup;
            Date orderQuoteDate = null;
            Set<Id> salesOrderIds = new Set<Id>();
            for(Sales_Order__c salesOrder : salesOrders){
                if(salesOrder.Quote_Date__c != null && salesOrder.Quote_Date__c > orderQuoteDate){
                    orderQuoteDate = salesOrder.Quote_Date__c;
                }
                salesOrderIds.add(salesOrder.Id);
            }

            //Ticket#21540 >>
            //List<Surcharge_Setup__c> surchargeSetups = SurchargeSetupsSelector.newInstance().selectByEffectiveDate(orderQuoteDate);
            List<Surcharge_Setup__c> surchargeSetups = SurchargeSetupsSelector.newInstance().selectByEffectiveDate(orderQuoteDate, salesOrders[0].Subsidiary_Company__c);
            //Ticket#21540 <<
            Map<String, List<Surcharge_Setup__c>> surchargeSetupsByType = new Map<String, List<Surcharge_Setup__c>>();
            for(Surcharge_Setup__c surchargeSetup : surchargeSetups){
                String surchargeType = surchargeSetup.Surcharge_Type__c;
                if(String.isNotBlank(surchargeType)){
                    List<Surcharge_Setup__c> tempSurchargeSetups = new List<Surcharge_Setup__c>();
                    if(surchargeSetupsByType.containsKey(surchargeType)){
                        tempSurchargeSetups = surchargeSetupsByType.get(surchargeType);
                    }
                    tempSurchargeSetups.add(surchargeSetup);
                    surchargeSetupsByType.put(surchargeType, tempSurchargeSetups);
                } 
            }

            //ticket 19672 <<
            List<Sales_Order_Job_Task__c> jobTasksToUpdate = new List<Sales_Order_Job_Task__c>();
            Map<Id, List<Sales_Order_Job_Task__c>> mapJobTasksByOrderId = new Map<Id, List<Sales_Order_Job_Task__c>>();
            for (Sales_Order_Job_Task__c jobTask : SalesOrderJobTasksSelector.newInstance().selectBySalesOrderId(salesOrderIds)) {
                List<Sales_Order_Job_Task__c> jobTasks;
                if (mapJobTasksByOrderId.containsKey(jobTask.Sales_Order__c)) {
                    jobTasks = mapJobTasksByOrderId.get(jobTask.Sales_Order__c);
                }
                else {
                    jobTasks = new List<Sales_Order_Job_Task__c>();
                    mapJobTasksByOrderId.put(jobTask.Sales_Order__c, jobTasks);
                }
                jobTasks.add(jobTask);
            }

            //prepare resource for calcSurchargeAmount() function.
            Set<Id> resIds = new Set<Id>();
            resIds.add(companySetup.Default_Energy_Insurance_Resource__c);
            resIds.add(companySetup.Default_Fuel_Surcharge_Resource__c);
            resIds.add(companySetup.Default_ESIC_Surcharge_Resource__c);
            ResourceService.setResourceMapsByIds(resIds);

            //ticket 19672 >>

            for(Sales_Order__c salesOrder : salesOrders) {
                Contract contract = contractsByIds.get(salesOrder.Contract__c);
                //ticket 19762 <<
                //List<Sales_Line__c> salesLines = salesOrder.Sales_Lines__r;
                //ticket 19762 >>
                String surchargeType = '';
                Decimal surchargePct = 0;
                if (contract.Surcharge_Type__c == null) {
                    surchargeType = 'EEC Fee';
                } else {
                    surchargeType = contract.Surcharge_Type__c;
                }

                surchargePct = CompanyMgmt.zeroIfNull(contract.Surcharge_Pct__c);

                if (surchargePct > 0) {
                    if (String.isBlank(contract.Surcharge_Type__c) || surchargeType == 'N/A') {
                        surchargePct = 0;
                    }
                }

                if (surchargeType != 'N/A' && surchargePct == 0) {
                    //Ticket#21540 >>
                    Boolean surchargePctFound = false;
                    if(surchargeType == 'EEC Fee' && CompanyMgmt.zeroIfNull(salesOrder.Service_Center__r.Energy_Environmental_Compliance_Pct__c) > 0){
                        surchargePct = salesOrder.Service_Center__r.Energy_Environmental_Compliance_Pct__c;
                        surchargePctFound = true;
                    }

                    if(surchargeType == 'Fuel Surcharge' && CompanyMgmt.zeroIfNull(salesOrder.Service_Center__r.Fuel_Surcharge_Pct__c) > 0){
                        surchargePct = salesOrder.Service_Center__r.Fuel_Surcharge_Pct__c;
                        surchargePctFound = true;
                    }
                    //Ticket#21540 <<
                    if(surchargePctFound == false) {
                        List<Surcharge_Setup__c> tempSurchargeSetups = surchargeSetupsByType.get(surchargeType);
                        for (Surcharge_Setup__c surchargeSetup : tempSurchargeSetups) {
                            if (surchargeSetup.Effective_Date__c <= salesOrder.Quote_Date__c) {
                                surchargePct = surchargeSetup.Surcharge_Pct__c;
                                break;
                            }
                        }
                    }
                }

                salesOrder.Surcharge_Type__c = surchargeType;
                salesOrder.Surcharge_Pct__c = surchargePct;


                //ticket 19672 <<
                /*
                List<Sales_Line__c> tempSalesLines = new List<Sales_Line__c>(salesLines);
                SalesOrdersService.calcSurchargeAmount(salesOrder, salesLines);
                Map<Id, Sales_Line__c> salesLinesByIds = new Map<Id, Sales_Line__c>();
                    for (Sales_Line__c salesLine : salesLines) {
                        if (String.isNotBlank(salesLine.Id)) {
                            salesLinesByIds.put(salesLine.Id, salesLine);
                        }
                    }
                    for (Sales_Line__c salesLine : tempSalesLines) {
                        if (salesLinesByIds.containsKey(salesLine.Id) == false) {
                            salesLinesToRemove.add(salesLine);
                        }
                    }

                    for (Sales_Line__c salesLine : salesLines) {
                        if (salesLine.Resource__c == companySetup.Default_Energy_Insurance_Resource__c ||
                                salesLine.Resource__c == companySetup.Default_Fuel_Surcharge_Resource__c) {
                            SalesLinesService.calculateLineTotals(salesOrder, salesLine);
                            salesLinesToUpdate.add(salesLine);
                        }
                    }
                */

                Map<Id, List<Sales_Line__c>> mapSalesLinesByJobTaskId = new Map<Id, List<Sales_Line__c>>();
                for (Sales_Line__c salesLine : salesOrder.Sales_Lines__r) {
                    if (salesLine.Sales_Order_Job_Task__c != null) {
                        List<Sales_Line__c> salesLines;
                        if (mapSalesLinesByJobTaskId.containsKey(salesLine.Sales_Order_Job_Task__c)) {
                            salesLines = mapSalesLinesByJobTaskId.get(salesLine.Sales_Order_Job_Task__c);
                        } else {
                            salesLines = new List<Sales_Line__c>();
                            mapSalesLinesByJobTaskId.put(salesLine.Sales_Order_Job_Task__c, salesLines);
                        }
                        salesLines.add(salesLine);
                    }
                }

                if (mapJobTasksByOrderId.containsKey(salesOrder.Id)) {
                    salesOrder.Surcharge_Amount__c = 0;

                    List<Sales_Order_Job_Task__c> jobTasks = mapJobTasksByOrderId.get(salesOrder.Id);
                    List<Sales_Line__c> salesLines = salesOrder.Sales_Lines__r;
                    List<Sales_Line__c> tempSalesLines = new List<Sales_Line__c>(salesLines);
                    SalesOrdersService.calcSurchargeAmount(salesOrder, jobTasks, salesLines);

                    Decimal taxPct = 0;
                    if (salesOrder.Tax_Area__c != null && salesOrder.Tax_Liable__c == true) {
                        taxPct = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, 'TX');
                    }
                    for (Sales_Order_Job_Task__c jobTask : jobTasks) {
                        List<Sales_Line__c> salesLines2 = mapSalesLinesByJobTaskId.get(jobTask.Id);
                        if (salesLines2 != null) { //salesLines2 = null should only happen in preprod instance because job task field was not copied when creating the sandbox
                            SalesOrdersService.calcJobTaskAmountFields(salesOrder, jobTask, salesLines2, taxPct);
                        }
                    }


                    jobTasksToUpdate.addAll(jobTasks);

                    Map<Id, Sales_Line__c> salesLinesByIds = new Map<Id, Sales_Line__c>();
                    for (Sales_Line__c salesLine : salesLines) {
                        if (String.isNotBlank(salesLine.Id)) {
                            salesLinesByIds.put(salesLine.Id, salesLine);
                        }
                    }
                    for (Sales_Line__c salesLine : tempSalesLines) {
                        if (salesLine.Sales_Order_Job_Task__c != null) { //handle preprod where Sales_Order_Job_Task__c is null
                            if (salesLinesByIds.containsKey(salesLine.Id) == false) {
                                salesLinesToRemove.add(salesLine);
                            }
                        }
                    }

                    for (Sales_Line__c salesLine : salesLines) {
                        if (salesLine.Resource__c == companySetup.Default_Energy_Insurance_Resource__c ||
                                salesLine.Resource__c == companySetup.Default_Fuel_Surcharge_Resource__c) {
                            SalesLinesService.calculateLineTotals(salesOrder, salesLine);
                            salesLinesToUpdate.add(salesLine);
                        }
                    }
                }
                //ticket 19672 >>
            }

            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;

            update salesOrders;

            //ticket 19672 <<
            update jobTasksToUpdate;
            //ticket 19672 >>

            if(salesLinesToUpdate.size() > 0){
                upsert salesLinesToUpdate;
            }
            if(salesLinesToRemove.size() > 0){
                delete salesLinesToRemove;
            }
        }
    }
}