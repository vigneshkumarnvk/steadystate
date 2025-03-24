/*************************************************************************************************
* Name         :  SalesOrdersService
* Description  :  
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan             16-05-2024             Task85892: Salesforce - Logic for MSG, Retail, National Accounts, US Ecology Internal Account.
* Prabhu Rathakrishnan      06-25-2024             US116303:Salesforce - Updates to Opportunities and Sales Quotes
* Andrew Simons 		   07-25-2024 			  Salesforce - removed logic for MSG/Retail/National Accounts - part 1
* Pavithra P			   08-21-2024             US118516 : [Continued] Salesforce - Assign Multiple Contacts to Sales Orders
*************************************************************************************************/
global with sharing class SalesOrdersService {

    global static void calcEstimatedDateInfo(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers, Integer duration) {
        service().calcEstimatedDateInfo(salesOrder, jobTaskWrappers, duration);
    }
    //job task >>

    global static void updateSQWhenNewSOCreated(Id salesQuoteId){
        service().updateSQWhenNewSOCreated(salesQuoteId);
    }

    //Ticket#.15225
    //ticket 19672 <<
    /*
    global static void createManifestFeeLines(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines){
        //aura <<
        //service().createManifestFeeLines(salesOrder, salesLines);
        service().addRemoveManifestFeeLines(salesOrder, salesLines);
        //aura <<
    }
    */
    //ticket 19672 >>

    global static String convertQuoteToOrder(Set<Id> salesOrderIds){
        return service().convertQuoteToOrder(salesOrderIds);
    }

    global static String cloneSalesOrder(Set<Id> salesOrderIds, String documentType, String serviceCenter, String billToCustomer, Id billToParentId, String jobDescription, String poNumber){
        return service().cloneSalesOrder(salesOrderIds, documentType, serviceCenter, billToCustomer, billToParentId, jobDescription, poNumber);
    }
    //job task >>

    global static void updateSalesLinesForBillAsLumpSumAllAction(List<Sales_Line__c> theSLList){
        service().updateSalesLinesForBillAsLumpSumAllAction(theSLList);
    }

    global static Sales_Order__c createNewSalesQuoteOrSalesOrder(String documentType, Id billToCustomer, String serviceCenter, String contract, String quote){
        return service().createNewSalesQuoteOrSalesOrder(documentType, billToCustomer, serviceCenter, contract, quote);
    }

    global static void updateSalesOrderBillingAndTax(Sales_Order__c theSO, Boolean isNewSO){
        service().updateSalesOrderBillingAndTax(theSO, isNewSO);
    }

    global static void setSurchargePct(Sales_Order__c salesOrder){
        service().setSurchargePct(salesOrder);
    }

    //ticket 19672 <<
    /*
    global static void calcSurchargeAmount(Sales_Order__c salesOrder, List<Sales_Line__c> salesLines){
        service().calcSurchargeAmount(salesOrder, salesLines);
        service().addRemoveSurchargeLine(salesOrder, salesLines);
    }
    */
    global static void calcSurchargeAmount(Sales_Order__c salesOrder, List<Sales_Order_Job_Task__c> jobTasks, List<Sales_Line__c> salesLines) {
        service().calcSurchargeAmount(salesOrder, jobTasks, salesLines);
    }
    global static void calcJobTaskAmountFields(Sales_Order__c salesOrder, Sales_Order_Job_Task__c jobTask, List<Sales_Line__c> salesLines, Decimal taxPct) {
        service().calcJobTaskAmountFields(salesOrder, jobTask, salesLines, taxPct);
    }
    //ticket 19672 >>

    global static void updateTMAndSISuperUserChangeBTC(Sales_Order__c theSO) {
        service().updateTMAndSISuperUserChangeBTC(theSO);
    }

    global static void createSalesLinesFromJobTaskTemplateLines(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo, List<Job_Task_Template_Line__c> jobTaskTemplateLines) {
        service().createSalesLinesFromJobTaskTemplateLines(salesOrder, jobTaskWrapper, nextSalesLineNo, jobTaskTemplateLines);
    }

    global static void cloneJobTask(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper fromJobTaskWrapper, ACVSalesOrderJobTaskWrapper newJobTaskWrapper, Integer nextSalesLineNo) {
        service().cloneJobTask(salesOrder, fromJobTaskWrapper, newJobTaskWrapper, nextSalesLineNo);
    }

    global static void validateRateSheet(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers, Id rateSheetId){
        if(String.isNotBlank(rateSheetId)){
            List<Rate_Sheet__c> rateSheets = [SELECT Id, Name FROM Rate_Sheet__c WHERE Id = :rateSheetId];
            if(rateSheets.size() > 0){
                salesOrder.Rate_Sheet__c = rateSheets[0].Id;
                salesOrder.Rate_Sheet__r = rateSheets[0];
            } else {
                throw new DataException('Rate sheet is not found with rate sheet id: ' + rateSheetId);
            }
        } else {
            salesOrder.Rate_Sheet__c = null;
            salesOrder.Rate_Sheet__r = null;
        }

        //SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                SalesLinesService.calcUnitPrice(salesOrder, salesLine);
                SalesLinesService.calcUnitCost(salesOrder, salesLine);
            }
        }
        SalesLinesService.updateTotals(salesOrder, jobTaskWrappers);
    }

    //Ticket#19546
    global static void deleteManifestLineFromRelatedRecords(Set<Id> salesOrderIds){
        Company_Setup__c defaultCompanySetup = CompanySettingUtil.defaultCompanySetup;
        CompanyMgmt.systemCall = true;
        CompanyMgmt.byPassLineTrigger = true;
        CompanyMgmt.byPassTrigger = true;
        List<Billing_Worksheet_Line__c> billingWorksheetOpenManifestLines = [SELECT Id FROM Billing_Worksheet_Line__c WHERE Invoiced__c != TRUE AND Sales_Order__c IN :salesOrderIds AND Resource__c = :defaultCompanySetup.Default_Manifest_Fee_Resource__c];
        if(billingWorksheetOpenManifestLines.size() > 0){
            delete billingWorksheetOpenManifestLines;
        }
        List<TM_Line__c> tmOpenManifestLines = [SELECT Id FROM TM_Line__c WHERE Invoiced__c != TRUE AND Resource__c = :defaultCompanySetup.Default_Manifest_Fee_Resource__c AND TM__r.Sales_Order__c IN :salesOrderIds AND TM__r.Status__c != 'Fully Invoiced' AND TM__r.Status__c != 'Void' AND TM__r.Status__c != 'Closed'];
        if(tmOpenManifestLines.size() > 0){
            delete tmOpenManifestLines;
        }
    }

    //Ticket#19546
    global static void addManifestLineToRelatedRecords(Set<Id> salesOrderIds){
        Company_Setup__c defaultCompanySetup = CompanySettingUtil.defaultCompanySetup;
        List<TM_Line__c> tmLines = [SELECT Id, Line_No__c, TM__c, Resource__c, Invoiced__c, Category__c, Billing_Worksheet_Line__c, TM_Job_Task__c, Billing_Worksheet_Line__r.Sales_Order__c, Billing_Worksheet_Line__r.Sales_Order_Job_Task__c FROM TM_Line__c WHERE TM__r.Sales_Order__c IN :salesOrderIds];
        Map<Id, Id> tmByTMJobTaskIdsNeedsManifestLine = new Map<Id, Id>();
        Map<Id, Id> tmJobTasksThatHasManifestLines = new Map<Id, Id>();
        Map<Id, TM_Line__c> tmLinesByTMJobTask = new Map<Id, TM_Line__c>();
        Map<Id, Decimal> tmNextLineNoByTMId = new Map<Id, Decimal>();
        for(TM_Line__c tmLine : tmLines){
            //Prepare last tm line no for related tms.
            Decimal lastTMLineNo = tmLine.Line_No__c;
            if(tmNextLineNoByTMId.containsKey(tmLine.TM__c)){
                if(tmNextLineNoByTMId.get(tmLine.TM__c) < lastTMLineNo){
                    tmNextLineNoByTMId.put(tmLine.TM__c, lastTMLineNo);
                }
            } else {
                tmNextLineNoByTMId.put(tmLine.TM__c, lastTMLineNo);
            }

            if(tmLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY) {
                if (tmLine.Resource__c == defaultCompanySetup.Default_Manifest_Fee_Resource__c) {
                    tmJobTasksThatHasManifestLines.put(tmLine.TM_Job_Task__c, tmLine.TM__c);
                } else {
                    if (tmLinesByTMJobTask.containsKey(tmLine.TM_Job_Task__c) == false) {
                        tmLinesByTMJobTask.put(tmLine.TM_Job_Task__c, tmLine);
                    }
                }
            }
        }

        for(TM_Line__c tmLine : tmLines){
            if(tmLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY &&
                    tmJobTasksThatHasManifestLines.containsKey(tmLine.TM_Job_Task__c) == false &&
                    tmLine.Resource__c != defaultCompanySetup.Default_Manifest_Fee_Resource__c &&
                    tmLine.Invoiced__c != true){
                tmByTMJobTaskIdsNeedsManifestLine.put(tmLine.TM_Job_Task__c, tmLine.TM__c);
            }
        }

        List<TM_Line__c> tmLinesToInsert = new List<TM_Line__c>();
        for(Id tmJobTaskId : tmByTMJobTaskIdsNeedsManifestLine.keySet()){
            TM_Line__c tmLine = new TM_Line__c();
            TM_Line__c wasteLine = tmLinesByTMJobTask.get(tmJobTaskId);
            Decimal nextLineNo = tmNextLineNoByTMId.get(wasteLine.TM__c) + 1;
            tmNextLineNoByTMId.put(wasteLine.TM__c, nextLineNo);
            tmLine.TM__c = wasteLine.TM__c;
            tmLine.Line_No__c = nextLineNo;
            tmLine.Resource__c = defaultCompanySetup.Default_Manifest_Fee_Resource__c;
            tmLine.Unit_of_Measure__c = defaultCompanySetup.Default_Manifest_Fee_Resource__r.Unit_of_Measure__c;
            tmLine.TM_Job_Task__c = tmJobTaskId;
            tmLine.Category__c = ResourceService.WASTE_DISPOSAL_CATEGORY;
            tmLine.Description__c = defaultCompanySetup.Default_Manifest_Fee_Resource__r.Description__c;
            tmLine.Quantity__c = 0;
            tmLine.System_Calculated_Line__c = true;
            tmLinesToInsert.add(tmLine);
        }

        Map<Id, TM_Line__c> newManifestLineByTMJobTaskId = new Map<Id, TM_Line__c>();
        if(tmLinesToInsert.size() > 0){
            CompanyMgmt.byPassLineTrigger = true;
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.systemCall = true;
            insert tmLinesToInsert;
            for(TM_Line__c tmLine : tmLinesToInsert){
                newManifestLineByTMJobTaskId.put(tmLine.TM_Job_Task__c, tmLine);
            }
        }

        List<Billing_Worksheet_Line__c> billingWorksheetLines = [SELECT Id, Line_No__c, TM__c, TM_Line__c, Sales_Order_Job_Task__c, Resource__c, Category__c, Sales_Order__c, TM_Job_Task__c, Sales_Order__r.Tax_Area__c, Sales_Order__r.Tax_Liable__c, Invoiced__c FROM Billing_Worksheet_Line__c WHERE Sales_Order__c IN :salesOrderIds];

        Map<String, Billing_Worksheet_Line__c> wasteBWLBySalesOrderJobTaskIdAndTMId = new Map<String, Billing_Worksheet_Line__c>();
        Set<String> salesOrderJobTaskAndTMThatHasManifestLines = new Set<String>();
        Set<String> salesOrderJobTaskAndTMThatNeedManifestLine = new Set<String>();
        Map<Id, Decimal> bwlNextLineNoBySalesOrderId = new Map<Id, Decimal>();
        //Ticket#28704 >>
        ResourceService.setResourceMapsByIds(new Set<Id>{defaultCompanySetup.Default_Manifest_Fee_Resource__c});
        Resource__c manifestResource = ResourceService.getResource(defaultCompanySetup.Default_Manifest_Fee_Resource__c);
        //Ticket#28704 <<
        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            //Prepare last billing worksheet line no for related sales order.
            Decimal lastTMLineNo = billingWorksheetLine.Line_No__c;
            if(bwlNextLineNoBySalesOrderId.containsKey(billingWorksheetLine.Sales_Order__c)){
                if(bwlNextLineNoBySalesOrderId.get(billingWorksheetLine.Sales_Order__c) < lastTMLineNo){
                    bwlNextLineNoBySalesOrderId.put(billingWorksheetLine.Sales_Order__c, lastTMLineNo);
                }
            } else {
                bwlNextLineNoBySalesOrderId.put(billingWorksheetLine.Sales_Order__c, lastTMLineNo);
            }

            if(billingWorksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY) {
                String salesOrderJobTaskAndTMId = billingWorksheetLine.Sales_Order_Job_Task__c + ':' + billingWorksheetLine.TM__c;
                if (billingWorksheetLine.Resource__c == defaultCompanySetup.Default_Manifest_Fee_Resource__c) {
                    salesOrderJobTaskAndTMThatHasManifestLines.add(salesOrderJobTaskAndTMId);
                } else {
                    if (wasteBWLBySalesOrderJobTaskIdAndTMId.containsKey(salesOrderJobTaskAndTMId) == false) {
                        wasteBWLBySalesOrderJobTaskIdAndTMId.put(salesOrderJobTaskAndTMId, billingWorksheetLine);
                    }
                }
            }
        }

        for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLines){
            if(billingWorksheetLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY){
                String salesOrderJobTaskAndTMId = billingWorksheetLine.Sales_Order_Job_Task__c + ':' + billingWorksheetLine.TM__c;
                if(salesOrderJobTaskAndTMThatHasManifestLines.contains(salesOrderJobTaskAndTMId) == false &&
                        billingWorksheetLine.Resource__c != defaultCompanySetup.Default_Manifest_Fee_Resource__c &&
                        billingWorksheetLine.Invoiced__c != true
                        ){
                    salesOrderJobTaskAndTMThatNeedManifestLine.add(salesOrderJobTaskAndTMId);
                }
            }
        }

        List<Billing_Worksheet_Line__c> billingWorksheetLinesToInsert = new List<Billing_Worksheet_Line__c>();
        for(String salesOrderJobTaskAndTMId : salesOrderJobTaskAndTMThatNeedManifestLine){
            Billing_Worksheet_Line__c wasteBWL = wasteBWLBySalesOrderJobTaskIdAndTMId.get(salesOrderJobTaskAndTMId);
            Decimal nextWorksheetLineNo = bwlNextLineNoBySalesOrderId.get(wasteBWL.Sales_Order__c) + 1;
            bwlNextLineNoBySalesOrderId.put(wasteBWL.Sales_Order__c, nextWorksheetLineNo);
            Billing_Worksheet_Line__c manifestFeeLine = new Billing_Worksheet_Line__c();
            manifestFeeLine.Line_No__c = nextWorksheetLineNo;
            manifestFeeLine.TM__c = wasteBWL.TM__c;
            manifestFeeLine.TM_Job_Task__c = wasteBWL.TM_Job_Task__c;
            if(newManifestLineByTMJobTaskId.containsKey(wasteBWL.TM_Job_Task__c)){
                manifestFeeLine.TM_Line__c = newManifestLineByTMJobTaskId.get(wasteBWL.TM_Job_Task__c).Id;
            }
            manifestFeeLine.Category__c = ResourceService.WASTE_DISPOSAL_CATEGORY;
            manifestFeeLine.Resource__c = defaultCompanySetup.Default_Manifest_Fee_Resource__c;
            manifestFeeLine.Description__c = defaultCompanySetup.Default_Manifest_Fee_Resource__r.Description__c;
            manifestFeeLine.Unit_of_Measure__c = defaultCompanySetup.Default_Manifest_Fee_Resource__r.Unit_of_Measure__c;
            /* Ticket#28704 >>
            manifestFeeLine.Unit_Price__c = defaultCompanySetup.Default_Manifest_Fee_Resource__r.Unit_Cost__c;
            manifestFeeLine.Unit_Cost__c = defaultCompanySetup.Default_Manifest_Fee_Resource__r.Unit_Cost__c;
             */
            manifestFeeLine.Unit_Price__c = ResourceService.getUnitPrice(manifestResource.Id, manifestResource.Unit_of_Measure__c, false);
            manifestFeeLine.Unit_Cost__c = ResourceService.getUnitCost(manifestResource.Id, manifestResource.Unit_of_Measure__c);
            //Ticket#28704 <<
            manifestFeeLine.Quantity__c = 0;
            manifestFeeLine.System_Calculated_Line__c = true;
            manifestFeeLine.Sales_Order_Job_Task__c = wasteBWL.Sales_Order_Job_Task__c;
            manifestFeeLine.Sales_Order__c = wasteBWL.Sales_Order__c;
            if(wasteBWL.Sales_Order__r.Tax_Liable__c == true){
                manifestFeeLine.Tax_Group__c = 'TX';
                manifestFeeLine.Tax_Pct__c = CompanyMgmt.getSalesTax(wasteBWL.Sales_Order__r.Tax_Area__c, 'TX');
            } else {
                manifestFeeLine.Tax_Group__c = 'NT';
                manifestFeeLine.Tax_Pct__c = 0;
            }
            billingWorksheetLinesToInsert.add(manifestFeeLine);
        }

        List<TM_Line__c> tmManifestFeeLinesToUpdate = new List<TM_Line__c>();
        if(billingWorksheetLinesToInsert.size() > 0){
            CompanyMgmt.byPassLineTrigger = true;
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.systemCall = true;
            insert billingWorksheetLinesToInsert;
            for(Billing_Worksheet_Line__c billingWorksheetLine : billingWorksheetLinesToInsert){
                if(newManifestLineByTMJobTaskId.containsKey(billingWorksheetLine.TM_Job_Task__c)){
                    TM_Line__c tmManifestLine = newManifestLineByTMJobTaskId.get(billingWorksheetLine.TM_Job_Task__c);
                    tmManifestLine.Billing_Worksheet_Line__c = billingWorksheetLine.Id;
                    tmManifestFeeLinesToUpdate.add(tmManifestLine);
                }
            }
        }
        if(tmManifestFeeLinesToUpdate.size() > 0){
            CompanyMgmt.byPassLineTrigger = true;
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.systemCall = true;
            update tmManifestFeeLinesToUpdate;
        }
    }

    //Ticket#19663
    global static void validatePayRule(Sales_Order__c salesOrder){
        List<Billing_Worksheet_Line__c> billingWorksheetLines = BillingWorksheetLinesSelector.newInstance().selectOpenLinesBySalesOrderId(new Set<Id>{salesOrder.Id});
        if(billingWorksheetLines.size() > 0) {
            BillingWorksheetService.calculateUnitCost(salesOrder.Id, billingWorksheetLines, true, salesOrder.Pay_Rule__c, true);
            CompanyMgmt.byPassLineTrigger = true;
            CompanyMgmt.byPassTrigger = true;
            update billingWorksheetLines;
        }
    }

    /*
     *  Ticket#19962
     *      - prospect(customer) validation when clone.
     *  Ticket#21357
     *      - check if all contacts are blocked.
     * Task85892: 
     *      - Logic for MSG, Retail, National Accounts
     */
    global static void isValidCustomer(Id customerId){
        List<Account> customers = [SELECT Id,Sage_Customer_No__c,Subsidiary_Company__r.Name, Subsidiary_Company__r.QtC_Enabled__c, Type, Customer_Status__c, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode,
        (SELECT Id, Contact_Type__c, Blocked__c FROM Contacts WHERE Contact_Type__c INCLUDES('Billing', 'Quote') AND Blocked__c != TRUE)
        FROM Account WHERE Id = :customerId];

        if (customers.size() > 0) {
            Account customer = customers[0];

            if (customer.Type != 'Customer' && customer.Type != 'Prospect') {
                throw new DataException('You cannot create quotes/orders for none customer/prospect accounts.');
            }
            if (customer.Subsidiary_Company__r.QtC_Enabled__c != true) {
                throw new DataException(('Quotes/orders are not allowed for company ' + customer.Subsidiary_Company__r.Name));
            }
            /*if (customer.Customer_Status__c == 'Inactive') {
                throw new DataException('The account is not active. You cannot create quotes/orders for inactive accounts.');
            }*/

            if (customer.BillingStreet == null || customer.BillingCity == null || customer.BillingStateCode == null || customer.BillingPostalCode == null) {
                throw new DataException('Please complete all billing address fields for this account.');
            }

           // if(customer.Sage_Customer_No__c !=null && CustomerDetailsService.getCustomerDetails(customer.Sage_Customer_No__c) == 'T')
            //{
              // throw new DataException('Salesforce cannot send National Account, MSG, or Retail Account customers to EQAI. Please create Work Order Quote/Work Order in EQAI directly.');  
            //}
            Boolean hasBillingContact = false;
            Boolean hasQuoteContact = false;
            for (Contact contact : customer.Contacts) {
                if (contact.Contact_Type__c.contains('Billing')) {
                    hasBillingContact = true;
                }
                if (contact.Contact_Type__c.contains('Quote')) {
                    hasQuoteContact = true;
                }
            }
            if (!hasBillingContact || !hasQuoteContact) {
                throw new DataException('Both active quote contact and billing contact are required to create quotes/orders for selected account.');
            }
        }
        else {
            throw new DataException('Account ' +  customerId + 'is not found.');
        }
    }
    
    /*
     *   Ticket#24650
     */
    global static void setBillingRuleforSalesOrders(List<Sales_Order__c> salesOrders){
        for(Sales_Order__c salesOrder : salesOrders){
            setBillingRuleForSalesOrder(salesOrder);
        }
    }

    /*
     *   Ticket#24650
     */
    global static void setBillingRuleForSalesOrder(Sales_Order__c salesOrder){
        if (salesOrder.Contract__r != null && salesOrder.Contract__r.Billing_Rule__c != null) {
            salesOrder.Billing_Rule__c = salesOrder.Contract__r.Billing_Rule__c;
        }
        else if (salesOrder.Service_Center__r != null && salesOrder.Service_Center__r.Billing_Rule__c != null){
            salesOrder.Billing_Rule__c = salesOrder.Service_Center__r.Billing_Rule__c;
        } else if (salesOrder.Subsidiary_Company__r != null && salesOrder.Subsidiary_Company__r.Billing_Rule__c != null){
            salesOrder.Billing_Rule__c = salesOrder.Subsidiary_Company__r.Billing_Rule__c;
        }
        else {
            salesOrder.Billing_Rule__c = BillingRuleService.getBillingRuleIdForSalesOrderAssumption(salesOrder).Id;
        }
    }    

    /*
     *  Ticket#23693 -
     */
    global static void reopenKronosProcessedTMLinesBySalesOrderId(Id salesOrderId){
        //Ticket#26574 >>
        //Date startOfWeek = TimeUtils.toStartOfWeek(System.today());
        Date startOfWeek = TimeUtils.calcStartDateForTMsThatNeedToBeResent(System.now());
        //Ticket#26574 <<
        List<TM_Line__c> tmLines = [SELECT Id, Kronos_Integration_Note__c, KronosTimeEntriesProcessed__c
                                        FROM TM_Line__c
                                        WHERE TM__r.Sales_Order__c = :salesOrderId AND Category__c = :ResourceService.LABOR_CATEGORY AND KronosTimeEntriesProcessed__c = TRUE
                                         AND TM__r.Scheduled_Date__c >= :startOfWeek AND TM__r.Scheduled_Date__c <= :System.today()
                                        AND (TM__r.Status__c = :TMsService.CONFIRMED_STATUS OR TM__r.Status__c = :TMsService.FULLY_INVOICED_STATUS)];
        for(TM_Line__c tmLine : tmLines){
            tmLine.KronosTimeEntriesProcessed__c = false;
            tmLine.Kronos_Integration_Note__c = System.today() + ' TM line reopen, due to pay rule change in sales order';
        }

        //Ticket#29552 Debug >>
        GF_Logger__c gfLogger = new GF_Logger__c();
        gfLogger.SourceRecordType__c = 'Sales Order';
        gfLogger.SourceRecordId__c = salesOrderId;
        gfLogger.Method__c = 'SalesOrderService.reopenKronosProcessedTMLinesBySalesOrderId';
        gfLogger.Stacktrace__c = 'TM Lines Size: ' + tmLines.size() + ' >> Start of Week: ' + startOfWeek + ' >> today date: ' + System.today() + ' >> System.now: ' + System.now();
        insert gfLogger;
        //Ticket#29552 Debug <<

        if(tmLines.size() > 0){
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            update tmLines;
            CompanyMgmt.byPassTrigger = false;
            CompanyMgmt.byPassLineTrigger = false;
        }
    }
    

    /*
     *   Ticket#24560
     */
    global static void setOperatingExpense(Sales_Order__c salesOrder){
        if(salesOrder.Service_Center__c != null && salesOrder.Quote_Date__c != null) {
            salesOrder.Operating_Expense_Cost_Pct__c = OperatingExpenseService.getOperatingExpense(salesOrder.Service_Center__c, salesOrder.Quote_Date__c);
            //System.debug('Info: setOperatingExpense ' + salesOrder.Operating_Expense_Cost_Pct__c);
        }
    }

    global static String collectDescriptionsFromContract(String salesOrderBillingInstructions, Contract contract){
        String contractDescriptions = '';
        String lineBreakChar = '\r\n';
        if(String.isNotBlank(contract.SpecialTerms)){
            contractDescriptions = contractDescriptions + contract.SpecialTerms.trim() + lineBreakChar;
        }
        if(String.isNotBlank(contract.Description)){
            contractDescriptions = contractDescriptions + contract.Description.trim()  + lineBreakChar;
        }
        if(String.isNotBlank(contract.Internal_Comments__c)){
            contractDescriptions =  contractDescriptions + contract.Internal_Comments__c.trim() + lineBreakChar;
        }
        if(String.isNotBlank(contract.Billing_Instructions__c)){
            contractDescriptions = contractDescriptions + contract.Billing_Instructions__c.trim() + lineBreakChar;
        }

        return generateSaleOrderBillingInstructions(salesOrderBillingInstructions, contractDescriptions);
    }

    /*
     *   Ticket#28846
     */
    global static String generateSaleOrderBillingInstructions(String salesOrderBillingInstructions, String contractBillingInstruction){
        String lineBreakChar = '\r\n';
        String lineSeparator = '>>>Contract Specific Instructions<<<';
        if(salesOrderBillingInstructions == null){
            salesOrderBillingInstructions = '';
        }

        String newString = '';
        List<String> strings = salesOrderBillingInstructions.split(lineSeparator);
        for(Integer i = 0; i <= strings.size() - 1; i++){
            if(i != 1){
                if(i==0 && String.isNotBlank(contractBillingInstruction)){
                    newString = lineSeparator + lineBreakChar + contractBillingInstruction.trim() + lineBreakChar + lineSeparator + lineBreakChar;
                    //System.debug('Debug i ' + i + ' >> ' + newString);
                }
                if(String.isNotBlank(strings[i]) == true){
                    String tempString = strings[i].trim();
                    //System.debug('Debug i ' + i + ' >> ' + tempString);
                    //newString = newString + strings[i];
                    newString = newString + tempString;
                    //System.debug('Debug i ' + i + ' >> ' + newString);
                }
            }
        }
        //System.debug('Debug generateSaleOrderBillingInstructions newString ' + newString);
        return newString;
    }

    //US118516
    global static string generateContactHyperLink(List<Id> contactIds){
        String hyperlinks = '';
                
        if(!contactIds.isEmpty()){
                Map<Id, Contact> contactMap = new Map<Id, Contact>([SELECT Id, Name FROM Contact WHERE Id IN :contactIds]);
                String baseUrl = URL.getOrgDomainURL().toExternalForm();
                for (String contactId : contactIds) {
                Contact contact = contactMap.get(contactId);
                if (contact != null) {
                    String recordUrl = baseUrl + '/' + contact.Id;
                    String hyperlink = '<a href="' + recordUrl + '">' + contact.Name + '</a>' + ',';
                    hyperlinks += hyperlink;
                }
                }                
            }
        return hyperlinks;
    }
    private static ISalesOrdersService service(){
        return (ISalesOrdersService) Application.Service.newInstance(ISalesOrdersService.class);
    }
}