public with sharing class SalesOrderTriggersMgt {
    public static Map<String, Numbering_Series__c> mapNumberSeries = new Map<String, Numbering_Series__c>();
    public static Numbering_Series__c theNumberingSeries;
    public static Map<Id, Service_Center__c> mapServiceCenters = new Map<Id, Service_Center__c>();
    public static Map<Id,Account> mapAccounts = new Map<Id,Account>();
    public static Map<Id, Contract> contractsByIds = new Map<Id, Contract>(); //Ticket#28846
    public static void SOInsertUpdate(List<Sales_Order__c> SOList, Map<Id, Sales_Order__c> oldSOMap, Boolean isInsert) {
        if(CompanyMgmt.byPassTrigger == true) return;
        Map<String, Sales_Order__c> nameSOMap = new Map<String, Sales_Order__c>();
        if (isInsert) {
            for (Sales_Order__c theSO : SOList) {
                if (theSO.Name == null) {
                    if (theSO.Service_Center__c == null) {
                        throw new DataException('Service center cannot be blank on the sales order.');
                    }
                    List<Service_Center__c> scs = [
                            SELECT Id, Name, Sales_Order_No_Series__c, Sales_Order_No_Series__r.Name, Blocked__c
                            FROM Service_Center__c
                            WHERE Id = :theSO.Service_Center__c
                            LIMIT 1
                    ];
                    if (scs.size() == 0) {
                        throw new DataException('Service center ' + theSO.Service_Center__c + ' does not exist.');
                    }
                    Service_Center__c sc = scs[0];

                    //Ticket#19999
                    if(sc.Blocked__c == true){
                        throw new DataException('Service center ' + sc.Name + ' is blocked!');
                    }
                    //aura >>
                    
                    //Sales_Order_Type__c SOType = [SELECT Id, Name FROM Sales_Order_Type__c WHERE Id =: theSO.Sales_Order_Type__c LIMIT 1];
					if (sc.Sales_Order_No_Series__c == null) {
                        theSO.addError('Sales Order No. Series cannot be blank for Service Center: ' + sc.Name);
                    }
                    else {
                        mapNumberSeries = CompanyMgmt.getNumber(sc.Sales_Order_No_Series__r.Name);
                        theNumberingSeries = mapNumberSeries.get(sc.Sales_Order_No_Series__r.Name);                        
                        //theSO.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c) + '-' + sc.Name + '-' + SOType.Name;
                        theSO.Name = theNumberingSeries.Prefix__c + theNumberingSeries.Separator__c + String.valueOf(theNumberingSeries.Last_Number_Used__c);
                        update mapNumberSeries.values();
                    }
                }
            }
        }
        Set<Id> setSCIds = new Set<Id>();
        Set<Id> setAccountId = new Set<Id>();
        Set<Id> emergencyIds = new Set<Id>();
        //Ticket#28846 >>
        Set<Id> contractIds = new Set<Id>();
        //Ticket#28846 <<

        for (Sales_Order__c theSO : SOList) {
            if (!mapAccounts.containsKey(theSO.Bill_to_Customer_No__c)) {
                setAccountId.add(theSO.Bill_to_Customer_No__c);
            }
            if (!mapServiceCenters.containsKey(theSO.Service_Center__c)) {
                setSCIds.add(theSO.Service_Center__c);
            }
            contractIds.add(theSO.Contract__c); //Ticket#28846
        }

        if (setAccountId.size() > 0 ) {
            mapAccounts.putAll(new Map<Id, Account>([SELECT Id, Name, RecordTypeId, Inter_co_Account__c, Tax_Liable__c,
                    Tax_Area__c, Emergency__c,Sage_Customer_No__c, AccountNumber, Customer_Billing_Instructions__c, Billing_Instructions__c,
                    Subsidiary_Company__r.Name, Subsidiary_Company__c
                    FROM Account WHERE Id IN: setAccountId]));
        }
        for (Account acct: mapAccounts.values()){
            if(acct.Emergency__c && String.isBlank(acct.Sage_Customer_No__c)){
                emergencyIds.add(acct.Id);
            }
        }
        if (setSCIds.size() > 0) {
            mapServiceCenters.putAll(new Map<Id, Service_Center__c>(
                [SELECT Id, Name, Code__c, Subsidiary_Company__c, Subsidiary_Company__r.Name
                    FROM Service_Center__c WHERE Id IN: setSCIds]
            ));
        }

        //Ticket#28846 >>
        if(contractIds.size() > 0){
            contractsByIds.putAll([SELECT Id, Billing_Instructions__c, Description, SpecialTerms, Internal_Comments__c FROM Contract WHERE Id IN :contractIds]);
        }
        //Ticket#28846 <<

        //AES-394 >> Ticket#14616 updated
        //retrieve existing SO for ER customers
        Map<String, Integer> existingSOForERCustCount = new Map<String, Integer>();
        for(Sales_Order__c so : [SELECT Id, Bill_to_Customer_No__c, Bill_to_Customer_No__r.Name, Document_Type__c
        FROM Sales_Order__c WHERE Bill_to_Customer_No__c IN :emergencyIds AND Document_Type__c = 'Sales Order']){
            String mapKey = so.Bill_to_Customer_No__c + ':' + so.Document_Type__c;
            existingSOForERCustCount.put(mapKey, 1);
        }
        //AES-394 <<

        List<Sales_Order__c> salesOrderWithTaxInfoUpdate = new List<Sales_Order__c>();
        List<Sales_Order__c> salesOrderWithTMNeedToBeUpdated = new List<Sales_Order__c>(); //Sales Order Route
        Set<Id> salesOrderIdsWithManifestLineNeedToBeDeleted = new Set<Id>(); //Ticket#19546
        Set<Id> salesOrderIdsNeedToCreateManifestLines = new Set<Id>(); //Ticket#19546
        List<Sales_Order__c> salesOrderWithPayRuleChange = new List<Sales_Order__c>(); //Ticket#19663
        List<Sales_Order__c> salesOrdersWithSalesOrderTypeChange = new List<Sales_Order__c>(); //Ticket#19820
        List<Sales_Order__c> salesOrdersNeedBillingRuleUpdate = new List<Sales_Order__c>(); //Ticket#24650
        for (Sales_Order__c theSO : SOList) {
            Account acc = mapAccounts.get(theSO.Bill_to_Customer_No__c);
            Service_Center__c serviceCenter = mapServiceCenters.get(theSO.Service_Center__c);
            if (isInsert == true) {
                if (String.isBlank(acc.Sage_Customer_No__c) && acc.Emergency__c == false && acc.RecordTypeId != Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId() && !Test.isRunningTest()) { //AES-404
                    throw new DataException('Account Number must not be blank for customer: ' + acc.Name);
                }
                String mapKey = acc.Id + ':' + theSO.Document_Type__c;
                if(existingSOForERCustCount.containsKey(mapKey) && theSO.Document_Type__c == 'Sales Order'){ //Ticket#14616
                    throw new DataException('You have exceeded the number of Emergency Sales Orders. This customer is not approved. Please contact Accounts Receivable.');
                    //throw new DataException('You have exceeded the number of Emergency Sales Orders. This customer is not approved. Please contact Accounts Receivable.');
                } else {
                    existingSOForERCustCount.put(mapKey, 1);
                }
            } else {
                Sales_Order__c oldSalesOrder = oldSOMap.get(theSO.Id);
                if(theSO.Tax_Liable__c != oldSalesOrder.Tax_Liable__c ||
                        theSO.Tax_Area__c != oldSalesOrder.Tax_Area__c){
                    salesOrderWithTaxInfoUpdate.add(theSO);
                }

                if(theSO.Prevailing_Wage_Job__c != oldSalesOrder.Prevailing_Wage_Job__c){
                    salesOrderWithTMNeedToBeUpdated.add(theSO);
                }
                if(theSO.Manifest_And_Profile__c != true && oldSalesOrder.Manifest_And_Profile__c == true){
                    salesOrderIdsWithManifestLineNeedToBeDeleted.add(theSO.Id);
                }
                if(theSO.Manifest_And_Profile__c == true && oldSalesOrder.Manifest_And_Profile__c != true){
                    salesOrderIdsNeedToCreateManifestLines.add(theSO.Id);
                }

                if(theSO.Pay_Rule__c != oldSalesOrder.Pay_Rule__c){
                    salesOrderWithPayRuleChange.add(theSO);
                }

                if(theSO.Sales_Order_Type__r.Emergency_Response__c != oldSalesOrder.Sales_Order_Type__r.Emergency_Response__c){
                    salesOrdersWithSalesOrderTypeChange.add(theSO);
                }

                //Ticket#24650 >>
                if(theSO.Contract__c != oldSalesOrder.Contract__c || theSO.Service_Center__c != oldSalesOrder.Service_Center__c || theSO.Subsidiary_Company__c != oldSalesOrder.Subsidiary_Company__c
                    || theSO.Overtime_Rate__c != oldSalesOrder.Overtime_Rate__c || theSO.Portal_Basis__c != oldSalesOrder.Portal_Basis__c || theSO.Portal_Basis_Adv__c != oldSalesOrder.Portal_Basis_Adv__c
                    || theSO.Lump_Sum__c != oldSalesOrder.Lump_Sum__c || theSO.Daily_Rate__c != oldSalesOrder.Daily_Rate__c
                    || theSO.Default_Billing_Rule_2023__c != oldSalesOrder.Default_Billing_Rule_2023__c)
                {
                    salesOrdersNeedBillingRuleUpdate.add(theSO);
                }
                //Ticket#24650 <<
            }

            if (String.isBlank(theSO.Name)) {
                theSO.Name.addError('Sales Order No. cannot be blank');
            }

            if ((isInsert || (theSO.Name != oldSOMap.get(theSO.Id).Name)) && !String.isBlank(theSO.Name)) {
                if (nameSOMap.containsKey(theSO.Name.toUpperCase())) {
                    theSO.addError('Duplicate Sales Order No. is not allowed.  Sales Order: ' + theSO.Name);
                } else {
                    nameSOMap.put(theSO.Name.toUpperCase(), theSO);
                }
            }

            if (String.isBlank(theSO.Bill_to_Customer_No__c)) {
                theSO.Bill_to_Customer_No__c.addError('Bill-to Customer cannot be blank.');
            }

            if (String.isBlank(theSO.Document_Status__c)) {
                theSO.Document_Status__c.addError('Document Status cannot be blank.');
            }

            if (String.isBlank(theSO.Surcharge_Type__c) && !isInsert) {
                theSO.Surcharge_Type__c.addError('Surcharge Type cannot be blank.');
            }

            if (String.isBlank(theSO.Service_Center__c)) {
                theSO.Service_Center__c.addError('Service Center cannot be blank.');
            } else {
                theSO.Service_Center_Code__c = serviceCenter.Code__c; //Ticket#13316
            }

            if (String.isBlank(theSO.Subsidiary_Company__c)) { //Ticket#14553
                theSO.Subsidiary_Company__c.addError('Subsidiary Company cannot be blank.');
            }

            //Ticket#20977
            if(acc.Subsidiary_Company__c != serviceCenter.Subsidiary_Company__c){
                theSO.Bill_to_Customer_No__c.addError('You are not allowed to use '+ acc.Subsidiary_Company__r.Name +' bill-to customer for service center ' + serviceCenter.Name + ' which belong to ' + serviceCenter.Subsidiary_Company__r.Name);
            }

            if (!isInsert && (theSO.Name != oldSOMap.get(theSO.Id).Name)) {
                theSO.addError('You are not allowed to change Sales Order No: ' + theSO.Name);
            }

            //Ticket#13541
            if (theSO.Print_Site_Name__c == true && String.isBlank(theSO.Site_Name__c)) {
                theSO.Site_Name__c.addError('Site Name cannot be blank');
            }

            // test inter-co tax area
            if (theSO.Bill_to_Customer_No__c != null) {
                if(acc.Inter_co_Account__c == true){
                    //Tax_Liable__c default value is set to "checked" on field schema, causing all jobs to have checked value from NAV
                    theSO.Tax_Liable__c = acc.Tax_Liable__c;
                    theSO.Tax_Area__c = acc.Tax_Area__c;

                    if (theSO.Tax_Liable__c == true) {
                        //Ticket#21211 Inter_co_Account__c - re-labeled to Intra-Co
                        theSO.Tax_Liable__c.addError('Tax Liable must be No for Intra-Co Account.');
                    }
                }
            }

            if (theSO.Document_Type__c == 'Sales Quote') {
                if (!theSO.Name.contains('Quote-')) {
                    theSO.Name = 'Quote-' + theSO.Name;
                }
            } else if (theSO.Document_Type__c == 'Sales Order') {
                if (theSO.Name.contains('Quote-')) theSO.Name = theSO.Name.replace('Quote-', '');
            }

            //Change Record Id
            if (theSO.Document_Type__c == 'Sales Order') {
                theSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Order').getRecordTypeId();
            } else {
                theSO.RecordTypeId = Schema.SObjectType.Sales_Order__c.getRecordTypeInfosByName().get('Sales Quote').getRecordTypeId();
            }

            if(theSO.Include_Holiday__c == true || theSO.Include_Weekend__c == true){
                theSO.Pricing__c = false;
            } else {
                theSO.Pricing__c = true;
            }

            //Billing instruction >>
            theSO.Customer_Billing_Instructions__c = AccountsService.generateCustomerBillingInstructions(acc);
            //Billing instruction <<
            //Ticket#28846 >>
            if(theSO.Contract__c != null && contractsByIds.containsKey(theSO.Contract__c)){
                Contract contract = contractsByIds.get(theSO.Contract__c);
                //theSO.Sales_Order_Instructions__c = SalesOrdersService.generateSaleOrderBillingInstructions(theSO.Sales_Order_Instructions__c, contract.Billing_Instructions__c);
                theSO.Sales_Order_Instructions__c = SalesOrdersService.collectDescriptionsFromContract(theSO.Sales_Order_Instructions__c, contract);
            }
            //Ticket#28846 <<
        }


        if(salesOrderWithTaxInfoUpdate.size() > 0){
            BillingWorksheetService.calculateLineTax(salesOrderWithTaxInfoUpdate);
        }

        if(salesOrderWithTMNeedToBeUpdated.size() > 0){
            TMsService.updateTMDataWhenSalesOrderIsUpdated(salesOrderWithTMNeedToBeUpdated);
        }

        //Ticket#19546
        if(salesOrderIdsWithManifestLineNeedToBeDeleted.size() > 0){
            SalesOrdersService.deleteManifestLineFromRelatedRecords(salesOrderIdsWithManifestLineNeedToBeDeleted);
        }

        if(salesOrderIdsNeedToCreateManifestLines.size() > 0){
            SalesOrdersService.addManifestLineToRelatedRecords(salesOrderIdsNeedToCreateManifestLines);
        }

        //Ticket#19663
        if(salesOrderWithPayRuleChange.size() > 0){
            SalesOrdersService.validatePayRule(salesOrderWithPayRuleChange[0]);
            SalesOrdersService.reopenKronosProcessedTMLinesBySalesOrderId(salesOrderWithPayRuleChange[0].Id); //Ticket#23693
        }

        //Ticket#19820
        if(salesOrdersWithSalesOrderTypeChange.size() > 0){
            BillingWorksheetService.validateSalesOrderType(salesOrdersWithSalesOrderTypeChange[0]);
        }

        //Ticket#24650 >>
        if(salesOrdersNeedBillingRuleUpdate.size() > 0){
            SalesOrdersService.setBillingRuleforSalesOrders(salesOrdersNeedBillingRuleUpdate);
        }
        //Ticket#24650 <<

        for (Sales_Order__c theSO : [SELECT Name FROM Sales_Order__c WHERE Name IN :nameSOMap.keySet()]) {
            Sales_Order__c theNewSO = nameSOMap.get(theSO.Name.toUpperCase());
            theNewSO.addError('Duplicate Sales Order No. is not allowed. Sales Order: ' + theNewSO.Name);
        }
    }

    public static void SLInsertUpdate(List<Sales_Line__c> SIList, Map<Id, Sales_Line__c> oldSIMap) {
        if(CompanyMgmt.byPassTrigger == true) return;
        //System.debug('###SLInsertUpdate begin###');

        Set<Id> theQLIds = new Set<Id>();
        Map<Id, Sales_Line__c> theSLMap = new Map<Id, Sales_Line__c>();

        Set<Id> soIdSet = new Set<Id>();
        Map<Id, Sales_Order__c> salesOrderMap = new Map<Id, Sales_Order__c>();


        Set<Id> uomIdSet = new Set<Id>(); //14984
        Map<Id, Unit_of_Measure__c> unitOfMeasuresByIds = new Map<Id, Unit_of_Measure__c>(); //14984

        if (SIList != null && SIList.size() > 0) {
            //System.debug('##*SIList.size in if ' + SIList.size());
            for (Sales_Line__c theSL : SIList) {
                if (!String.isEmpty(theSL.Quote_Line__c)) theQLIds.add(theSL.Quote_Line__c);

                //Ticket#22299 >>
                if(theSL.Unit_of_Measure__c != null) {
                    uomIdSet.add(theSL.Unit_of_Measure__c);
                } else if(theSL.Category__c != 'Waste Disposal') {
                    theSL.Unit_of_Measure__c.addError('Unit of Measure cannot be blank for line# ' + theSL.Line_No__c);
                }
                else if(theSL.Category__c == 'Waste Disposal' && theSL.Approval_Id__c != null)
                {
                    theSL.Unit_of_Measure__c.addError('Unit of Measure cannot be blank for line# ' + theSL.Line_No__c);
                }
                //Ticket#22299 <<

                soIdSet.add(theSL.Sales_Order__c);
            }

            for (Sales_Line__c theSL : [
                    SELECT Id, Resource_Type__c, Resource_Type__r.Name, Unit_Price__c
                            , Unit_of_Measure__c, Unit_of_Measure__r.Name, Resource__c, Resource__r.Name
                    FROM Sales_Line__c
                    WHERE Id IN :theQLIds
            ]) {
                theSLMap.put(theSL.Id,theSL);
            }

            for (Sales_Order__c theSO : [SELECT Id, Document_Type__c, Duration__c FROM Sales_Order__c WHERE Id IN :soIdSet AND Document_Type__c = 'Sales Quote']) {
                salesOrderMap.put(theSO.Id, theSO);
            }

            //14984
            for(Unit_of_Measure__c unitOfMeasure: UnitOfMeasuresSelector.newInstance().selectById(uomIdSet)){
                unitOfMeasuresByIds.put(unitOfMeasure.Id, unitOfMeasure);
            }

            for (Sales_Line__c theSL : SIList) {
                //Steven cannot inert line in SO so I add this
                if (theSLMap.containsKey(theSL.Quote_Line__c)) {
                    if (theSL.Category__c == 'Labor') {
                        //if(theSL.Unit_Price__c != theSLMap.get(theSL.Quote_Line__c).Unit_Price__c) {
                        //    theSL.Unit_Price__c.addError('Regular Rate should be: ' + theSLMap.get(theSL.Quote_Line__c).Unit_Price__c + ' for Quote Line: ' + theSL.Line_No__c);
                        //}
                        if (theSL.Resource_Type__c != theSLMap.get(theSL.Quote_Line__c).Resource_Type__c) {
                            theSL.Resource_Type__c.addError('Labor Type should be: ' + theSLMap.get(theSL.Quote_Line__c).Resource_Type__r.Name + ' for Quote Line: ' + theSL.Line_No__c);
                        }
                        if (theSL.Unit_of_Measure__c != theSLMap.get(theSL.Quote_Line__c).Unit_of_Measure__c) {
                            theSL.Unit_of_Measure__c.addError('Unit of Measure should be: ' + theSLMap.get(theSL.Quote_Line__c).Unit_of_Measure__r.Name + ' for Quote Line: ' + theSL.Line_No__c);
                        }
                    }

                    else if (theSL.Category__c == 'Equipment') {
                        //if(theSL.Unit_Price__c != theSLMap.get(theSL.Quote_Line__c).Unit_Price__c) {
                        //    theSL.Unit_Price__c.addError('Unit Price should be: ' + theSLMap.get(theSL.Quote_Line__c).Unit_Price__c + ' for Quote Line: ' + theSL.Line_No__c);
                        //}
                        if (theSL.Resource_Type__c != theSLMap.get(theSL.Quote_Line__c).Resource_Type__c) {
                            theSL.Resource_Type__c.addError('Equipment Type should be: ' + theSLMap.get(theSL.Quote_Line__c).Resource_Type__r.Name + ' for Quote Line: ' + theSL.Line_No__c);
                        }
                        if (theSL.Unit_of_Measure__c != theSLMap.get(theSL.Quote_Line__c).Unit_of_Measure__c) {
                            theSL.Unit_of_Measure__c.addError('Unit of Measure should be:' + theSLMap.get(theSL.Quote_Line__c).Unit_of_Measure__r.Name + ' for Quote Line: ' + theSL.Line_No__c);
                        }
                    } else {
                        //if(theSL.Unit_Price__c != theSLMap.get(theSL.Quote_Line__c).Unit_Price__c) {
                        //    theSL.Unit_Price__c.addError('Unit Price should be: ' + theSLMap.get(theSL.Quote_Line__c).Unit_Price__c + ' for Quote Line: ' + theSL.Line_No__c);
                        //}
                        if (theSL.Resource__c != theSLMap.get(theSL.Quote_Line__c).Resource__c) {
                            theSL.Resource__c.addError('Resource should be same: ' + theSLMap.get(theSL.Quote_Line__c).Resource__r.Name + ' for Quote Line: ' + theSL.Line_No__c);
                        }
                       /* if (theSL.Unit_of_Measure__c != theSLMap.get(theSL.Quote_Line__c).Unit_of_Measure__c) {
                            system.debug('theSLMap.get(theSL.Quote_Line__c).Unit_of_Measure__c'+theSLMap.get(theSL.Quote_Line__c).Unit_of_Measure__c);
                            system.debug('theSL.Unit_of_Measure__c'+theSL.Unit_of_Measure__c);
                            theSL.Unit_of_Measure__c.addError('Unit of Measure should be: ' + theSLMap.get(theSL.Quote_Line__c).Unit_of_Measure__r.Name + ' for Quote Line: ' + theSL.Line_No__c);
                        }*/
                    }
                }

                //W-000391
                if(salesOrderMap.containsKey(theSL.Sales_Order__c)){
                    Sales_Order__c salesOrder = salesOrderMap.get(theSL.Sales_Order__c);
                    if(theSL.Category__c == ResourceService.LABOR_CATEGORY || theSL.Category__c == ResourceService.EQUIPMENT_CATEGORY || theSL.Category__c == ResourceService.MATERIALS_CATEGORY){
                        if (theSL.Number_of_Day__c != null && salesOrder.Duration__c != null) {
                            if (theSL.Number_of_Day__c > salesOrder.Duration__c || theSL.Number_of_Day__c <= 0) {
                                theSL.Number_of_Day__c.addError('Days needed must be within the duration of the job! Line: ' + theSL.Line_No__c);
                            }
                        }
                    }
                }
            }

            for (Sales_Line__c theSL : SIList) {
                //ticket 19130 <<
                /*
                if ((theSL.Category__c == 'Labor' || theSL.Category__c == 'Equipment') && (theSL.UOM_Qty__c == null || theSL.UOM_Qty__c == 0) && theSL.Parent_Line__c == null){
                    theSL.UOM_Qty__c.addError('UOM Qty. must not be empty or zero in order to save for Line No: ' + theSL.Line_No__c);
                }
                if ((theSL.Quantity__c == 0 || theSL.Quantity__c == null) && theSL.Parent_Line__c == null) {
                    theSL.Quantity__c.addError('Quantity must not be zero in order to save for Line No: ' + theSL.Line_No__c);
                }
                */
                if ((theSL.Category__c == 'Labor' || theSL.Category__c == 'Equipment') && (theSL.UOM_Qty__c == null || theSL.UOM_Qty__c == 0) && theSL.Is_Child_Resource__c != true){
                    theSL.UOM_Qty__c.addError('UOM Qty. must not be empty or zero in order to save for Line No: ' + theSL.Line_No__c);
                }
                if ((theSL.Quantity__c == 0 || theSL.Quantity__c == null) && theSL.Is_Child_Resource__c != true) {
                    theSL.Quantity__c.addError('Quantity must not be zero in order to save for line No: ' + theSL.Line_No__c);
                }
                //ticket 19130 >>
                //job task >>

                /* Ticket#19664 >>
                if(theSL.Category__c == 'Subcontractors'){
                    if(theSL.Bill_as_Lump_Sum__c == true || theSL.Non_Billable__c == true) theSL.Unit_Cost__c = theSL.xUnit_Price__c;
                    else theSL.Unit_Cost__c = theSL.Unit_Price__c;
                }
                 */

                //Ticket#19723
                //Prevent Resource and Resource Type miss match
                //Labor with Tran resource etc..
                if(theSL.Category__c != ResourceService.LUMP_SUM_CATEGORY){
                    if(ResourceService.isCalcBaseOnResType(theSL.Category__c) == true && String.isNotBlank(theSL.Resource__c)){
                        theSL.Category__c.addError('Resource field must be blank for Line No: ' + theSL.Line_No__c);
                    } else if (ResourceService.isCalcBaseOnResType(theSL.Category__c) == false && String.isNotBlank(theSL.Resource_Type__c)){
                        theSL.Category__c.addError('Resource Type field must be blank for Line No: ' + theSL.Line_No__c);
                    }
                }
            }

        }
    }
    //DE36096
    public static void beforDelateValidation(Boolean isBefore,Boolean isDelete)
    {
        if(isBefore && isDelete){           
            List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId()];
            if(profiles.size() > 0){
                if(profiles[0].Name == 'ACV Standard User'){
                    throw new DataException('You do not have permissions to delete a Quote/Order. Please reach out to you Salesforce Administrator team.');
                }
            }
        }
    }
    public static void handleAfterUpdate(List<Sales_Order__c> newList, Map<Id, Sales_Order__c> oldMap) {
        system.debug('entry--');
        List<Sales_Order__c> recordsToUpdate = new List<Sales_Order__c>();        
        for (Sales_Order__c newSO : newList) {
            Sales_Order__c oldSO = oldMap.get(newSO.Id);
            Boolean wasD365ProjectIdBlank = String.isBlank(oldSO.D365_Project_ID__c);
            Boolean isD365ProjectIdNowFilled = !String.isBlank(newSO.D365_Project_ID__c);            
            if (wasD365ProjectIdBlank && isD365ProjectIdNowFilled && newSO.Is_New_D365_Project__c && newSO.SO_sent_to_EQAI__c) {
                Sales_Order__c updatedSO = new Sales_Order__c(
                    Id = newSO.Id,
                    Is_New_D365_Project__c = false
                );
                recordsToUpdate.add(updatedSO);
            }
        }        
        if (!recordsToUpdate.isEmpty()) {
            update recordsToUpdate;
        }
    }
}