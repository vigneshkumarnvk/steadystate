/*************************************************************************************************
* Name         :  ACVSalesOrderController 
* Description  :  Apex Class to save Quote/Order details
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Shahwaz Khan              01-09-2024             Task75619: Salesforce - Save ALL Site Addresses
  Shahwaz Khan              01-30-2024             Bug#77485: The Site name field should be updated
  Shahwaz Khan              03-12-2024             Task78375: Salesforce - 5/1 Need for Account Number Validation
  Sanjana                   03-12-2024             Task78376: Salesforce - 7/1 Need for Account Number Validation
* Prabhu Rathakrishnan      04-15-2024             Task84488:Change of Name in Site Address Still Sent Original Generator to EQAI
* Sanjana 					04-17-2024			   Bug 84716: Unable to create quote with adding contracts- Error is thrown.
* Andrew Simons             04-23-2024             Bug 84727: Fixed Sales order line billing description not updateing after removing the contract from sales order.
  Shahwaz Khan              04-24-2024             Bug#85795: Emergency Sales Order Issue
* Prabhu Rathakrishnan      06-25-2024             US116303:Salesforce - Updates to Opportunities and Sales Quotes
  Shahwaz Khan              07-10-2024             US117390 : Salesforce - Updates to Site Address
  Shahwaz Khan              07-10-2024             US117390 : Defect - Site Address update in Billing Package from salesforce not reflected in EQAI workorder 
  Pavithra P				08-21-2024             US118516 : [Continued] Salesforce - Assign Multiple Contacts to Sales Orders
* Prabhu Rathakrishnan      10-13-2024             US127188 - Salesforce - Modifications to allow ESIC Surcharge Type
* Sanjana Ravichandran      11-27-2024		   DE36665: [Unplanned] Tax Group Not Updating to NT When Deselecting Tax Liable Checkbox
*************************************************************************************************/
public with sharing class ACVSalesOrderController {

    @AuraEnabled
    public static String getSetupData() {
        try {
            Company_Setup__c companySetup = CompanyMgmt.getCompanySetup();
            Company_Setting__mdt  companySetting = CompanySettingUtil.acvSetting;
            User user = [SELECT Id, Name, Username, Super_User__c, Service_Center__c, Profile.Name FROM User WHERE Id = :userInfo.getUserId()];
            Service_Center__c serviceCenter = new Service_Center__c();
            if (user.Service_Center__c != null) {
                List<Service_Center__c> scs = [SELECT Id, Name, Description__c, Subsidiary_Company__c, Subsidiary_Company__r.Name, Price_List__c, Blocked__c, Prevent_New_and_Cloned_Sales_Orders__c FROM Service_Center__c WHERE Name = :user.Service_Center__c AND Blocked__c != TRUE LIMIT 1];
                if(scs.size() > 0){
                    serviceCenter = scs[0];
                }
            }

            Map<String, Object> mapSetupData = new Map<String, Object>();
            mapSetupData.put('CompanySetup', companySetup);
            mapSetupData.put('User', user);
            mapSetupData.put('ServiceCenter', serviceCenter);
            mapSetupData.put('CompanySetting', companySetting);
            return JSON.serialize(mapSetupData);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
     *  Ticket#19962
     *      - customer validation when clone.
     */
    @AuraEnabled
    public static void isValidCustomer(Id customerId) {
        try {
            //Ticket#19962
            SalesOrdersService.isValidCustomer(customerId);
            /*
            Boolean isValid = false;
            List<Account> customers = [SELECT Id,  Subsidiary_Company__r.Name, Type, Customer_Status__c, BillingStreet, BillingCity, BillingStateCode, BillingPostalCode,
            (SELECT Id, Contact_Type__c FROM Contacts WHERE Contact_Type__c INCLUDES('Billing', 'Quote'))
            FROM Account WHERE Id = :customerId];

            if (customers.size() > 0) {
                Account customer = customers[0];

                if (customer.Type != 'Customer' && customer.Type != 'Prospect') {
                    throw new DataException('You cannot create quotes/orders for none customer/prospect accounts.');
                }
                if (customer.Subsidiary_Company__r.Name != '1-ACV ENVIRO') {
                    throw new DataException(('Quotes/orders are not allowed for company ' + customer.Subsidiary_Company__r.Name));
                }
                if (customer.Customer_Status__c != 'Active') {
                    throw new DataException('The account is not active. You cannot create quotes/orders for inactive accounts.');
                }

                if (customer.BillingStreet == null || customer.BillingCity == null || customer.BillingStateCode == null || customer.BillingPostalCode == null) {
                    throw new DataException('Please complete all billing address fields for this account.');
                }

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
                    throw new DataException('Both quote contact and billing contact are required to create quotes/orders.');
                }
            }
            else {
                throw new DataException('Account ' +  customerId + 'is not found.');
            }
             */
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void isValidCustomerToCreateOpportunity(Id customerId) {
        try {
            
            Account customer = [SELECT Id, Customer_Status__c FROM Account WHERE Id = :customerId];
            
            if (customer != null) {
                /*if (customer.Customer_Status__c == 'Inactive') {
                    throw new DataException('The account is not active. You cannot create opportunity for inactive accounts.');
                }*/
            }
            else {
                throw new DataException('Account ' +  customerId + 'is not found.');
            }
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    @AuraEnabled
    public static Company_Setup__c getCompanySetup() {
        try {
            return CompanyMgmt.getCompanySetup();
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, Date> getWeekendAndHoliday(Date startDate, Integer duration, Id billingRuleId, Boolean includeWeekend, Boolean includeHoliday) {
        try {
            if (startDate == null) {
                return null;
            }

            Map<String, Date> dates = new Map<String, Date>();

            //billing.rule.fix <<
            if (billingRuleId == null) {
                billingRuleId = getCompanySetup().Default_Billing_Rule__c;
            }
            if (billingRuleId == null) {
                throw new DataException('Please setup a company default billing rule.');
            }
            //billing.rule.fix >>
            List<Billing_Rule__c> brs = BillingRulesSelector.newInstance().selectById(new Set<Id> { billingRuleId });
            Billing_Rule__c br;
            if (brs.size() > 0) {
                br = brs[0];
            }

            if (duration > 0) {
                WorkDays workdays = new WorkDays(startDate, duration, new BillingRule(br), includeWeekend, includeHoliday);
                Date endDate = workdays.calcEndDate();
                Date d = startDate;
                while (d < endDate) {
                    if (!dates.containsKey('WEEKEND')) {
                        if (workdays.isWeekend(d)) {
                            dates.put('WEEKEND', d);
                        }
                    }

                    if (!dates.containsKey('HOLIDAY')) {
                        if (workdays.isHoliday(d)) {
                            dates.put('HOLIDAY', d);
                        }
                    }

                    if (dates.containsKey('WEEKEND') && dates.containsKey('HOLIDAY')) {
                        break;
                    }

                    d = d.addDays(1);
                }
            }

            return dates;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String createNewSalesOrder(String documentType, Id customerId, String serviceCenter, Id contractId) {
        try {
            Sales_Order__c salesOrder = SalesOrdersService.createNewSalesQuoteOrSalesOrder(documentType, customerId, serviceCenter, contractId, null);
            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, new List<Sales_Order_Job_Task__c>(), new List<Sales_Line__c>());
            salesOrderWrapper.accountExecutivesIds = new List<Id>();
            List<Account> accounts = AccountsSelector.newInstance().selectById(new Set<Id>{salesOrder.Bill_to_Customer_No__c});
            salesOrder.Bill_to_Customer_No__r = accounts[0];
            if(salesOrder.Bill_to_Customer_No__c != null && salesOrder.Bill_to_Customer_No__r.Account_Executive_ids__c != null ){
            salesOrderWrapper.accountExecutivesIds = salesOrder.Bill_to_Customer_No__r.Account_Executive_ids__c.split(',');
        }
            if(salesOrder.Bill_to_Customer_No__r.Account_Executive__c != null)
                salesOrderWrapper.accountExecutivesIds.add(salesOrder.Bill_to_Customer_No__r.Account_Executive__c);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateSalesOrderType(String JSONSalesOrder, String JSONJobTaskWrappers) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            //Ticket#19820 >>
            if(salesOrder.Id != null){
                SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
                for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                        SalesLinesService.calcUnitPrice(salesOrder, salesLine);
                        SalesLinesService.calculateLineTotals(salesOrder, salesLine);
                    }
                }
                Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
                calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);
            }
            //Ticket#19820 >>

            /*
            //insert template lines associated with sales order type for new sales order creation
            if (salesOrder.Id == null && salesOrder.Sales_Order_Type__r != null && salesOrder.Sales_Order_Type__r.Job_Task_Template__c != null) {
                List<Job_Task_Template__c> jobTaskTemplates = JobTaskTemplatesSelector.newInstance().selectById(new Set<Id>{ salesOrder.Sales_Order_Type__r.Job_Task_Template__c });
                if (jobTaskTemplates.size() > 0) {
                    Id jobTaskTemplateId = jobTaskTemplates[0].Id;
                    List<Job_Task_Template_Line__c> jobTaskTemplateLines = JobTaskTemplateLinesSelector.newInstance().selectByTemplateId(new Set<Id>{ jobTaskTemplateId }, null);
                    if (jobTaskTemplateLines.size() > 0) {
                        ACVSalesOrderJobTaskWrapper jobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
                        Sales_Order_Job_Task__c jobTask = new Sales_Order_Job_Task__c();
                        jobTask.Line_No__c = 1;
                        jobTask.Job_Task_Template__c = jobTaskTemplateId;
                        jobTask.Job_Task_Template__r = jobTaskTemplates[0];
                        jobTask.Name = jobTaskTemplates[0].Name;
                        jobTaskWrapper.JobTask = jobTask;

                        Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
                        SalesOrdersService.createSalesLinesFromJobTaskTemplateLines(salesOrder, jobTaskWrapper, nextSalesLineNo, jobTaskTemplateLines);

                        SalesLinesService.initStaticVariables(salesOrder, jobTaskWrapper);
                        SalesLinesService.calculatePriceInfo(salesOrder, jobTaskWrapper);
                        if (salesOrder.Estimated_Job_Start_Date__c != null && salesOrder.Estimated_Job_End_Date__c != null) {
                            SalesLinesService.explodeSalesLineDetails(salesOrder, jobTaskWrapper);
                        }
                        jobTaskWrappers.add(jobTaskWrapper);

                        nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers); //get the last line no.
                        calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);
                    }
                }
            }
            */

            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String calculatePriceInfo(String JSONSalesOrder, String JSONJobTaskWrappers) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>) JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);
            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            SalesLinesService.calculatePriceInfo(salesOrder, jobTaskWrappers);
            return JSON.serialize(jobTaskWrappers);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String createSalesLinesFromJobTaskTemplateLines(String JSONSalesOrder, String JSONJobTaskWrapper, String JSONJobTaskTemplateLines, Integer nextSalesLineNo) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            ACVSalesOrderJobTaskWrapper jobTaskWrapper = (ACVSalesOrderJobTaskWrapper) JSON.deserialize(JSONJobTaskWrapper, ACVSalesOrderJobTaskWrapper.class);
            //ticket 19130 <<
            //record the starting new line no. any lines added after the line no are new lines
            Integer newLineStartNo = nextSalesLineNo;
            //ticket 19130 >>
            
            List<Job_Task_Template_Line__c> jobTaskTemplateLines;
            if (JSONJobTaskTemplateLines != null) {
                jobTaskTemplateLines = (List<Job_Task_Template_Line__c>) JSON.deserialize(JSONJobTaskTemplateLines, List<Job_Task_Template_Line__c>.class);
            }
            if (jobTaskTemplateLines.size() > 0) {
                //ticket 19130 <<
                /*
                ACVSalesOrderJobTaskWrapper tempJobTaskWrapper = new ACVSalesOrderJobTaskWrapper();
                tempJobTaskWrapper.JobTask = jobTaskWrapper.JobTask;
                SalesOrdersService.createSalesLinesFromJobTaskTemplateLines(salesOrder, tempJobTaskWrapper, nextSalesLineNo, jobTaskTemplateLines);
                */

                SalesOrdersService.createSalesLinesFromJobTaskTemplateLines(salesOrder, jobTaskWrapper, nextSalesLineNo, jobTaskTemplateLines);
                //reset the wizard question answered flag to prompt wizard again for the child lines
                Set<Integer> childSalesLineNos = new Set<Integer>();
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    if (salesLine.Line_No__c >= newLineStartNo) {
                        if (salesLine.Sales_Child_Lines__r != null && salesLine.Sales_Child_Lines__r.size() > 0) {
                            for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                                childSalesLineNos.add(relation.Child_Line__r.Line_No__c.intValue());
                            }
                        }
                    }
                }
                //ticket 19130 >>

                //include sales lines from both jobTaskWrapper and tempJobTaskWrapper to init variables.
                //ticket 19130 <<
                ACVSalesOrderJobTaskWrapper tempJobTaskWrapper2 = new ACVSalesOrderJobTaskWrapper();
                tempJobTaskWrapper2.JobTask = jobTaskWrapper.JobTask;
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    //ticket 19130 << reset the wizard question answered flag
                    //tempJobTaskWrapper2.SalesLines.add(salesLine);
                    if (childSalesLineNos.contains(salesLine.Line_No__c.intValue())) {
                        salesLine.Wizard_Question_Answered__c = false;
                    }
                    //add new lines to the temp job task wrapper to explode the detail lines
                    if (salesLine.Line_No__c >= newLineStartNo) {
                        tempJobTaskWrapper2.SalesLines.add(salesLine);
                    }
                    //ticket 19130 >>
                }
                //ticket 19130 <<
                /*
                for (Sales_Line__c salesLine : tempJobTaskWrapper.SalesLines) {
                    tempJobTaskWrapper2.SalesLines.add(salesLine);
                }
                */
                //ticket 19130 >>
				
                SalesLinesService.initStaticVariables(salesOrder, tempJobTaskWrapper2);
                //ticket 19130 <<
                /*
                SalesLinesService.calculatePriceInfo(salesOrder, tempJobTaskWrapper);
                if (salesOrder.Estimated_Job_Start_Date__c != null && salesOrder.Estimated_Job_End_Date__c != null) {
                    SalesLinesService.explodeSalesLineDetails(salesOrder, tempJobTaskWrapper);
                }
                jobTaskWrapper.SalesLines.addAll(tempJobTaskWrapper.SalesLines);
                nextSalesLineNo = getNextSalesLineNo(new List<ACVSalesOrderJobTaskWrapper>{ jobTaskWrapper }); //jobTaskWrapper contains max sales line no.
                */
                SalesLinesService.calculatePriceInfo(salesOrder, tempJobTaskWrapper2); 
                
                System.debug('$$$ Line 320 :');
                try {
                    if (salesOrder.Estimated_Job_Start_Date__c != null && salesOrder.Estimated_Job_End_Date__c != null) {
                        SalesLinesService.explodeSalesLineDetails(salesOrder, tempJobTaskWrapper2);
                    }
                } catch(Exception newEx) {
                    System.debug('$$$ exception :' + newEx.getMessage());
        		}    
                Map<Integer, Sales_Line__c> mapSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
                for (Sales_Line__c salesLine : tempJobTaskWrapper2.SalesLines) {
                    mapSalesLinesByLineNo.put(salesLine.Line_No__c.intValue(), salesLine);
                }
                for (Integer i = 0; i < jobTaskWrapper.SalesLines.size(); i++) {
                    Sales_Line__c salesLine = jobTaskWrapper.SalesLines[i];
                    if (mapSalesLinesByLineNo.containsKey(salesLine.Line_No__c.intValue())) {
                        jobTaskWrapper.SalesLines[i] = mapSalesLinesByLineNo.get(salesLine.Line_No__c.intValue());
                    }
                    if (salesLine.Line_No__c >= nextSalesLineNo) {
                        nextSalesLineNo = salesLine.Line_No__c.intValue() + 1;
                    }
                }
                //ticket 19130 >>
                calculateSalesOrder(salesOrder, jobTaskWrapper, nextSalesLineNo);
            }
            return JSON.serialize(jobTaskWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String cloneJobTask(String JSONSalesOrder, String JSONFromJobTaskWrapper, String JSONNewJobTaskWrapper, Integer nextSalesLineNo) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            ACVSalesOrderJobTaskWrapper fromJobTaskWrapper = (ACVSalesOrderJobTaskWrapper)JSON.deserialize(JSONFromJobTaskWrapper, ACVSalesOrderJobTaskWrapper.class);
            ACVSalesOrderJobTaskWrapper newJobTaskWrapper = (ACVSalesOrderJobTaskWrapper)JSON.deserialize(JSONNewJobTaskWrapper, ACVSalesOrderJobTaskWrapper.class);

            SalesOrdersService.cloneJobTask(salesOrder, fromJobTaskWrapper, newJobTaskWrapper, nextSalesLineNo);

            nextSalesLineNo = getNextSalesLineNo(new List<ACVSalesOrderJobTaskWrapper>{ newJobTaskWrapper }); //new job task contains max sales line no.

            SalesLinesService.initStaticVariables(salesOrder, newJobTaskWrapper);
            calculateSalesOrder(salesOrder, newJobTaskWrapper, nextSalesLineNo);
            return JSON.serialize(newJobTaskWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getSalesOrder(Id salesOrderId) {
        try {
            List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectById(new Set<Id> { salesOrderId });
            Sales_Order__c salesOrder;
            List<Contact> relatedContact;
            if (salesOrders.size() > 0) {
                salesOrder = salesOrders[0];
                if(salesOrder.Bill_To_Contacts__c != null){
                    List<Id> relatedContactIds = salesOrder.Bill_To_Contacts__c.split(',');
                    relatedContact = new List<Contact>([SELECT Id,Name FROM Contact WHERE Id IN: relatedContactIds]);
                }
            }
            //ticket 20566 << - exlcude TM__r relationship from job task to reduce size
            //List<Sales_Order_Job_Task__c> jobTasks = SalesOrderJobTasksSelector.newInstance().selectBySalesOrderId(new Set<Id> { salesOrderId });
            List<Sales_Order_Job_Task__c> jobTasks = SalesOrderJobTasksSelector.newInstance().selectBySalesOrderId2(new Set<Id> { salesOrderId });
            //ticket 20566 >>
            List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesWithDetailsBySalesOrderId(new set<Id> { salesOrderId });
            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTasks, salesLines);

            salesOrderWrapper.SObillToContacts = relatedContact;
            //ticket 20566 <<
            Set<Id> salesOrderJobTaskIds = new Set<Id>();
            for (Sales_Order_Job_Task__c jobTask : jobTasks) {
                salesOrderJobTaskIds.add(jobTask.Id);
            }
            Map<Id, Boolean> mapInvoicedByJobTaskId = new Map<Id, Boolean>();
            for (TM_Job_Task__c tmJobTask : [SELECT Id, Sales_Order_Job_Task__c, TM__r.Sales_Invoice__c FROM TM_Job_Task__c WHERE Sales_Order_Job_Task__c IN :salesOrderJobTaskIds]) {
                if (!mapInvoicedByJobTaskId.containsKey(tmJobTask.Sales_Order_Job_Task__c)) {
                    mapInvoicedByJobTaskId.put(tmJobTask.Sales_Order_Job_Task__c, false); //has TM
                }
                if (tmJobTask.TM__r.Sales_Invoice__c != null) {
                    mapInvoicedByJobTaskId.put(tmJobTask.Sales_Order_Job_Task__c, true); //has invoiced TM
                }
            }
            
            for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : salesOrderWrapper.JobTaskWrappers) {
                if (mapInvoicedByJobTaskId.containsKey(jobTaskWrapper.JobTask.Id)) {
                    jobTaskWrapper.HasTMs = true;
                    jobTaskWrapper.HasInvoices = mapInvoicedByJobTaskId.get(jobTaskWrapper.JobTask.Id);
                }
            }
            //ticket 20566 >>

            //ticket 20876 <<
            salesOrders = null;
            salesOrder = null;
            jobTasks = null;
            salesLines = null;
            mapInvoicedByJobTaskId = null;
            //ticket 20876 >>

            return JSON.serialize(salesOrderWrapper, false);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
     *  Ticket#19962
     *      - add customer validation to prevent prospect without billing information.
     *          - SalesOrdersService.isValidCustomer(salesOrder.Bill_to_Customer_No__c);
     */
    @AuraEnabled
    public static String validateCustomer(String JSONSalesOrder, String JSONJobTaskWrappers) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);
            Boolean isNewOrder = (salesOrder.Id == null);
            if(isNewOrder == false){
                List<Billing_Worksheet_Line__c> billingWorksheetLines = [SELECT Id FROM Billing_Worksheet_Line__c WHERE Sales_Order__c =:salesOrder.Id AND Invoiced__c = TRUE];
                if(billingWorksheetLines.size() > 0){
                    throw new DataException('Bill-to Customer cannot be changed because there are invoiced line linked to the Sales Order!');
                }
            }
            for(ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers){
                for(Sales_Line__c salesLine : jobTaskWrapper.SalesLines){
                    salesLine.Quote_Line__c = null;
                    salesLine.Contract_Line__c = null;
                }
            }
            SalesOrdersService.updateSalesOrderBillingAndTax(salesOrder, isNewOrder);

            if(salesOrder.Bill_to_Customer_No__r.Type == 'Prospect') {
                SalesOrdersService.isValidCustomer(salesOrder.Bill_to_Customer_No__c);
            }

            if(isNewOrder == false) {
                SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
                SalesLinesService.calculatePriceInfo(salesOrder, jobTaskWrappers);
            }
            //SalesLinesService.calculateLineTotals(salesOrder, jobTaskWrappers);
            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateSurchargeType(String JSONSalesOrder, String JSONJobTaskWrappers) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            SalesOrdersService.setSurchargePct(salesOrder);
            Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);
            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateSurchargePct(String JSONSalesOrder, String JSONJobTaskWrappers) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            if (salesOrder.Document_Type__c == 'Sales Quote' && salesOrder.Contract__c == null) {
                List<Profile> profiles = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
                String profileName = profiles[0].Name;
                if (profileName != 'System Administrator') {
                    //Ticket#21540 >>
                    //Surcharge_Setup__c surchargeSetup = SurchargeSetupsSelector.newInstance().selectByTypeAndEffectiveDate(salesOrder.Quote_Date__c, salesOrder.Surcharge_Type__c);
                    Surcharge_Setup__c surchargeSetup = SurchargeSetupsSelector.newInstance().selectByTypeAndEffectiveDate(salesOrder.Quote_Date__c, salesOrder.Surcharge_Type__c, salesOrder.Subsidiary_Company__c);
                    //Ticket#21540 <<
                    Decimal defaultSurchargePct = 0;
                    if (surchargeSetup != null) {
                        defaultSurchargePct = surchargeSetup.Surcharge_Pct__c;
                    }
                    if (salesOrder.Surcharge_Pct__c < defaultSurchargePct) {
                        throw new DataException('Surcharge percentage must be equal or greater than the company default percentage (' + defaultSurchargePct + '%).');
                    }
                }
            }

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
            calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);
            return JSON.serialize(jobTaskWrappers);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String calculateTax(String JSONSalesOrder, String JSONJobTaskWrapper) {
        try {
            Decimal tax = 0;
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            ACVSalesOrderJobTaskWrapper jobTaskWrapper = (ACVSalesOrderJobTaskWrapper)JSON.deserialize(JSONJobTaskWrapper, ACVSalesOrderJobTaskWrapper.class);
            if (salesOrder.Tax_Area__c != null && salesOrder.Tax_Liable__c == true) {
                jobTaskWrapper.JobTask.Tax_Pct__c = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, 'TX');
                //ticket 19672 <<
                //jobTaskWrapper.JobTask.Tax__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(jobTaskWrapper.JobTask.Fixed_Price__c) * jobTaskWrapper.JobTask.Tax_Pct__c / 100);
                Decimal totalAmount = CompanyMgmt.zeroIfNull(jobTaskWrapper.JobTask.Fixed_Price__c);
                if (jobTaskWrapper.JobTask.Fixed_Price_Surcharge_Option__c == 'Fixed Price Does Not Include Surcharge') {
                    totalAmount += CompanyMgmt.zeroIfNull(jobTaskWrapper.JobTask.Surcharge_Amount__c);
                }
                jobTaskWrapper.JobTask.Tax__c = CompanyMgmt.halfUpTo2D(totalAmount * jobTaskWrapper.JobTask.Tax_Pct__c / 100);
                //ticket 19672 >>
            }
            return JSON.serialize(jobTaskWrapper);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validateContract(String JSONSalesOrder, String JSONJobTaskWrappers) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            //re-calculate pricing >>
            for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    salesLine.Contract_Line__c = null;
                    salesLine.Quote_Line__c = null;
                }
            }
            //re-calculate pricing <<

            //contract pricing fix 11.10.2020 <<
            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            //contract pricing fix 11.10.2020 >>
            SalesLinesService.recalculateSalesLines(salesOrder, jobTaskWrappers);

            Company_Setup__c companySetup = CompanyMgmt.getCompanySetup();
            List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectById(new Set<Id> {salesOrder.Service_Center__c});

            if (salesOrder.Contract__c != null) {
                List<Contract> contracts = ContractsSelector.newInstance().selectById(new Set<Id>{ salesOrder.Contract__c });
                if (contracts.size() > 0) {
                    Contract contract = contracts[0];
                    salesOrder.Contract__r = contract;

                    if (contract.Billing_Rule__c != null) {
                        salesOrder.Billing_Rule__c = contract.Billing_Rule__c;
                        salesOrder.Billing_Rule__r = contract.Billing_Rule__r;
                    }
                    //Ticket#21540
                    else if (serviceCenters.size() > 0 && serviceCenters[0].Billing_Rule__c != null){
                        salesOrder.Billing_Rule__c = serviceCenters[0].Billing_Rule__c;
                        salesOrder.Billing_Rule__r = serviceCenters[0].Billing_Rule__r;
                    } else if (serviceCenters.size() > 0 && serviceCenters[0].Subsidiary_Company__c != null &&
                            serviceCenters[0].Subsidiary_Company__r.Billing_Rule__c != null){
                        salesOrder.Billing_Rule__c = serviceCenters[0].Subsidiary_Company__r.Billing_Rule__c;
                        salesOrder.Billing_Rule__r = serviceCenters[0].Subsidiary_Company__r.Billing_Rule__r;
                    } else {
                        salesOrder.Billing_Rule__c = companySetup.Default_Billing_Rule__c;
                        salesOrder.Billing_Rule__r = companySetup.Default_Billing_Rule__r;
                    }
                    //Ticket#21540

                    //Ticket#28846 >>
                    //salesOrder.Internal_Comments__c = contract.Internal_Comments__c;
                    salesOrder.Sales_Order_Instructions__c = SalesOrdersService.collectDescriptionsFromContract(salesOrder.Sales_Order_Instructions__c, contract);
                    //Ticket#28846 <<

                    if(contract.Surcharge_Type__c != null){
                        salesOrder.Surcharge_Type__c = contract.Surcharge_Type__c;
                        if(salesOrder.Surcharge_Type__c == 'N/A'){
                            salesOrder.Surcharge_Pct__c = null;
                        } else {
                            if(contract.Surcharge_Pct__c != null){
                                salesOrder.Surcharge_Pct__c = contract.Surcharge_Pct__c;
                            }
                            else {
                                SalesOrdersService.setSurchargePct(salesOrder);
                            }
                        }
                    }
                    else {
                        salesOrder.Surcharge_Type__c = 'EEC Fee';
                        SalesOrdersService.setSurchargePct(salesOrder);
                    }

                    //Ticket#20079
                    if(salesOrder.Payment_Term__c == null && salesOrder.Bill_to_Customer_No__r.Payment_Term__c != null){
                        salesOrder.Payment_Term__c = salesOrder.Bill_to_Customer_No__r.Payment_Term__c;
                    }
                }
            }
            else {
                //contract pricing fix 11.10.2020 <<
                Map<Id, Map<Id, ResourceTypeUOMAssociation__c>> resourceTypeUOMAssociationsByUOMIdsByResTypeIds = ResourceTypeUtil.resourceTypeUOMAssociationsByUOMIdsByResTypeIds;
                Map<Id, Map<Id, List<ResourceUOMAssociation__c>>> resourceUOMAssociationsByUOMIdsByResIds = ResourceService.resourceUOMAssociationsByUOMIdsByResIds;

                for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                        if (salesLine.Contract_Line__c != null) {
                            if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Bundled') {
                                if (resourceTypeUOMAssociationsByUOMIdsByResTypeIds.containsKey(salesLine.Resource_Type__c)) {
                                    Map<Id, ResourceTypeUOMAssociation__c> uomIds = resourceTypeUOMAssociationsByUOMIdsByResTypeIds.get(salesLine.Resource_Type__c);
                                    if (!uomIds.containsKey(salesLine.Unit_of_Measure__c)) {
                                        salesLine.Unit_of_Measure__c = null;
                                        SalesLinesService.assignUnitOfMeasure(salesLine);
                                        SalesLinesService.assignResourceTypeUOM(salesLine);
                                    }
                                }
                            } else {
                                if (resourceUOMAssociationsByUOMIdsByResIds.containsKey(salesLine.Resource__c)) {
                                    Map<Id, List<ResourceUOMAssociation__c>> uomIds = resourceUOMAssociationsByUOMIdsByResIds.get(salesLine.Resource__c);
                                    if (!uomIds.containsKey(salesLine.Unit_of_Measure__c)) {
                                        salesLine.Unit_of_Measure__c = null;
                                        SalesLinesService.assignUnitOfMeasure(salesLine);
                                        SalesLinesService.assignResourceUOM(salesLine);
                                    }
                                }
                            }
                            // //job task <<
                            // //SalesLinesService.assignDescription(salesLine);
                            // SalesLinesService.assignDescription(salesOrder, salesLine);
                            // //job task >>
                            // salesLine.Contract_Line__c = null;
                            // salesLine.Contract_Line__r = null;
                        }
                        //job task <<
                        SalesLinesService.assignDescription(salesOrder, salesLine);
                        //job task >>
                        salesLine.Contract_Line__c = null;
                        salesLine.Contract_Line__r = null;
                    }
                }

                //Ticket#21540 >>
                if (serviceCenters.size() > 0 && serviceCenters[0].Billing_Rule__c != null){
                    salesOrder.Billing_Rule__c = serviceCenters[0].Billing_Rule__c;
                    salesOrder.Billing_Rule__r = serviceCenters[0].Billing_Rule__r;
                } else if (serviceCenters.size() > 0 && serviceCenters[0].Subsidiary_Company__c != null &&
                        serviceCenters[0].Subsidiary_Company__r.Billing_Rule__c != null){
                    salesOrder.Billing_Rule__c = serviceCenters[0].Subsidiary_Company__r.Billing_Rule__c;
                    salesOrder.Billing_Rule__r = serviceCenters[0].Subsidiary_Company__r.Billing_Rule__r;
                } else {
                    salesOrder.Billing_Rule__c = companySetup.Default_Billing_Rule__c;
                    salesOrder.Billing_Rule__r = companySetup.Default_Billing_Rule__r;
                }
                //salesOrder.Billing_Rule__c = companySetup.Default_Billing_Rule__c;
                //salesOrder.Billing_Rule__r = companySetup.Default_Billing_Rule__r;
                //Ticket#21540 <<
                //contract pricing fix 11.10.2020 >>
                salesOrder.Surcharge_Type__c = 'EEC Fee';
                SalesOrdersService.setSurchargePct(salesOrder);

                //Ticket#28846 >>
                salesOrder.Sales_Order_Instructions__c = SalesOrdersService.generateSaleOrderBillingInstructions(salesOrder.Sales_Order_Instructions__c, '');
                //Ticket#28846 <<
            }

            Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
            calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);

            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //Ticket#21540
    @AuraEnabled
    public static String validateServiceCenter(String JSONSalesOrder, String JSONJobTaskWrappers){
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            SalesLinesService.recalculateSalesLines(salesOrder, jobTaskWrappers);

            Company_Setup__c companySetup = CompanyMgmt.getCompanySetup();
            List<Service_Center__c> serviceCenters = ServiceCentersSelector.newInstance().selectById(new Set<Id> {salesOrder.Service_Center__c});
            List<Contract> contracts = ContractsSelector.newInstance().selectById(new Set<Id>{ salesOrder.Contract__c });

            if (contracts.size() > 0) {
                Contract contract = contracts[0];
                if (contract.Billing_Rule__c != null) {
                    salesOrder.Billing_Rule__c = contract.Billing_Rule__c;
                    salesOrder.Billing_Rule__r = contract.Billing_Rule__r;
                } else if (serviceCenters.size() > 0 && serviceCenters[0].Billing_Rule__c != null){
                    salesOrder.Billing_Rule__c = serviceCenters[0].Billing_Rule__c;
                    salesOrder.Billing_Rule__r = serviceCenters[0].Billing_Rule__r;
                } else if (serviceCenters.size() > 0 && serviceCenters[0].Subsidiary_Company__c != null &&
                        serviceCenters[0].Subsidiary_Company__r.Billing_Rule__c != null){
                    salesOrder.Billing_Rule__c = serviceCenters[0].Subsidiary_Company__r.Billing_Rule__c;
                    salesOrder.Billing_Rule__r = serviceCenters[0].Subsidiary_Company__r.Billing_Rule__r;
                } else {
                    salesOrder.Billing_Rule__c = companySetup.Default_Billing_Rule__c;
                    salesOrder.Billing_Rule__r = companySetup.Default_Billing_Rule__r;
                }

                if(contract.Surcharge_Type__c != null){
                    salesOrder.Surcharge_Type__c = contract.Surcharge_Type__c;
                    if(salesOrder.Surcharge_Type__c == 'N/A'){
                        salesOrder.Surcharge_Pct__c = null;
                    } else {
                        if(contract.Surcharge_Pct__c != null){
                            salesOrder.Surcharge_Pct__c = contract.Surcharge_Pct__c;
                        }
                        else {
                            SalesOrdersService.setSurchargePct(salesOrder);
                        }
                    }
                }
                else {
                    salesOrder.Surcharge_Type__c = 'EEC Fee';
                    SalesOrdersService.setSurchargePct(salesOrder);
                }
            } else {
                if (serviceCenters.size() > 0 && serviceCenters[0].Billing_Rule__c != null){
                    salesOrder.Billing_Rule__c = serviceCenters[0].Billing_Rule__c;
                    salesOrder.Billing_Rule__r = serviceCenters[0].Billing_Rule__r;
                } else if (serviceCenters.size() > 0 && serviceCenters[0].Subsidiary_Company__c != null &&
                        serviceCenters[0].Subsidiary_Company__r.Billing_Rule__c != null){
                    salesOrder.Billing_Rule__c = serviceCenters[0].Subsidiary_Company__r.Billing_Rule__c;
                    salesOrder.Billing_Rule__r = serviceCenters[0].Subsidiary_Company__r.Billing_Rule__r;
                } else {
                    salesOrder.Billing_Rule__c = companySetup.Default_Billing_Rule__c;
                    salesOrder.Billing_Rule__r = companySetup.Default_Billing_Rule__r;
                }
                SalesOrdersService.setSurchargePct(salesOrder);
            }

            //Ticket#24560
            SalesOrdersService.setOperatingExpense(salesOrder);
            //Ticket#24560
            
            Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
            calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);

            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
     *   Ticket#24326
     *      when pass in duration is set to 0 - mean line's day needed does not need to be recalculate
     *      if pass in duration is not equals to 0 then system will recalculate all line duration using header duration value
     */
    @AuraEnabled
    public static String calculateEstimatedDateInfo(String JSONSalesOrder, String JSONJobTaskWrappers, Boolean recalculateDuration) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            //ticket 20876 <<
            JSONSalesOrder = null;
            JSONJobTaskWrappers = null;
            //ticket 20876 >>

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            if(recalculateDuration == true){
                SalesOrdersService.calcEstimatedDateInfo(salesOrder, jobTaskWrappers, salesOrder.Duration__c.intValue());
            } else {
                SalesOrdersService.calcEstimatedDateInfo(salesOrder, jobTaskWrappers, 0);
            }

            //explode labor lines <<
            //equipment schedule lines <<
            //Boolean hasLaborLines = false;
            Boolean explodeSalesLine = false;
            //equipment schedule lines >>
            for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    //equipment schedule lines <<
                    /*
                    if (salesLine.Category__c == 'Labor') {
                        hasLaborLines = true;
                    } else if (salesLine.Category__c == 'Equipment') {
                        if (salesLine.Unit_of_Measure__r != null && salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                            if (salesOrder.Estimated_Job_Start_Time__c != null && salesOrder.Estimated_Job_End_Time__c != null) {
                                Decimal hours = TimeUtils.calculateHours(salesOrder.Estimated_Job_Start_Time__c, salesOrder.Estimated_Job_End_Time__c);
                                salesLine.UOM_Qty__c = hours;
                            }
                        }
                    }*/
                    if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment') {
                        explodeSalesLine = true;
                    }
                    //equipment schedule lines >>
                }
            }

            //equipment schedule lines <<
            //if (hasLaborLines == true) {
            if (explodeSalesLine == true) {
                //equipment schedule lines <<
                SalesLinesService.explodeSalesLineDetails(salesOrder, jobTaskWrappers);
            }
            //explode labor lines >>


            Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
            //calculateSystemLines(salesOrder, jobTaskWrappers, nextSalesLineNo);
            calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);
            //Ticket#25378 >>
            SalesLinesService.recalculateSalesLines(salesOrder, jobTaskWrappers);
            //SalesLinesService.calculateLineTotals(salesOrder, jobTaskWrappers);
            //Ticket#25378 <<


            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    public static Integer getNextSalesLineNo(List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers) {
        Integer nextSalesLineNo = 0;
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                if (nextSalesLineNo < salesLine.Line_No__c.intValue()) {
                    nextSalesLineNo = salesLine.Line_No__c.intValue();
                }
            }
        }
        nextSalesLineNo++;
        return nextSalesLineNo;
    }

    @AuraEnabled
    public static String calculateSalesOrderJobTask(String JSONSalesOrder, String JSONJobTaskWrapper, Integer nextSalesLineNo) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            ACVSalesOrderJobTaskWrapper jobTaskWrapper = (ACVSalesOrderJobTaskWrapper) JSON.deserialize(JSONJobTaskWrapper, ACVSalesOrderJobTaskWrapper.class);
            JSONSalesOrder = null; //free memory from heap
            JSONJobTaskWrapper = null; //free memory from heap

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrapper);
            //SalesLinesService.recalculateSalesLineDetails(salesOrder, jobTaskWrapper, false); not needed, this is called in calculateSalesOrder() function

            calculateSalesOrder(salesOrder, jobTaskWrapper, nextSalesLineNo);

            //return JSON.serialize(jobTaskWrapper);
            JSONJobTaskWrapper = JSON.serialize(jobTaskWrapper);
            return JSONJobTaskWrapper;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String calculateSalesOrder(String JSONSalesOrder, String JSONJobTaskWrappers, Boolean calcSurchargePct, Integer nextSalesLineNo) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>) JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
	        List<Sales_Line__c> salesLines = new List<Sales_Line__c>();
            for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                salesLines.addAll(jobTaskWrapper.SalesLines);
            }
            
          /* for (Sales_Line__c salesLine : salesLines) {
                if (!salesOrder.Tax_Liable__c) {
                    salesLine.Tax_Group__c = 'NT';  
                    salesLine.Tax_Pct__c = 0;      
                } else {
                    salesLine.Tax_Group__c = 'TX';  
                }
	       }*/
            if (calcSurchargePct == true) {
                SalesOrdersService.setSurchargePct(salesOrder);
            }

            //Ticket#24560
            SalesOrdersService.setOperatingExpense(salesOrder);
            //Ticket#24560

            calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);
            
            //Ticket#24560
            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
            //return JSON.serialize(jobTaskWrappers);
            //Ticket#24560
        }
        catch(exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //** need to move this function to client side, too expensive to do on the server side, especially it takes all jobTaskWrappers
    private static void calculateSalesOrder(Sales_Order__c salesOrder, List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers, Integer nextSalesLineNo) {

        //ticket 19672 <<
        if (salesOrder.Surcharge_Type__c != 'EEC Fee' && salesOrder.Surcharge_Type__c != 'Fuel Surcharge' && salesOrder.Surcharge_Type__c != 'ESIC') {
            for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                jobTaskWrapper.JobTask.Fixed_Price_Surcharge_Option__c = null;
            }
        }
        //ticket 19672 >>

        //presumptive lines
        /*
        SalesLinesService.calculatePresumptiveSalesLines(salesOrder, jobTaskWrappers, nextSalesLineNo);
        nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
        */

        //before save calculation <<
        //ticket 19754 <<
        /*
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                SalesLinesService.recalculateSalesLineDetails(salesOrder, salesLine, false);
                SalesLinesService.calculateLineTotals(salesOrder, salesLine);
            }
        }
        */

        SalesLinesService.recalculateSalesLineDetails(salesOrder, jobTaskWrappers, false);
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                SalesLinesService.calculateLineTotals(salesOrder, salesLine);
            }
        }
        //ticket 19754 >>
        //before save calculation >>

        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            SalesLinesService.calculateSurchargeLine(salesOrder, jobTaskWrapper, nextSalesLineNo);
            nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
        }

        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            SalesLinesService.calculateManifestFeeLine(salesOrder, jobTaskWrapper, nextSalesLineNo);
            nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
        }

        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            SalesLinesService.calculateRinseOutFeeLine(salesOrder, jobTaskWrapper, nextSalesLineNo);
            nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
        }

        SalesLinesService.calculateLineTotals(salesOrder, jobTaskWrappers);

        Decimal taxPct = 0;
        if (salesOrder.Tax_Area__c != null && salesOrder.Tax_Liable__c == true) {
            taxPct = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, 'TX');
        }

        //ticket 19672 <<
        /*
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            if (jobTaskWrapper.JobTask.Billing_Type__c == 'Fixed Price') {
                jobTaskWrapper.JobTask.Total_Amount__c = CompanyMgmt.zeroIfNull(jobTaskWrapper.JobTask.Fixed_Price__c);
                jobTaskWrapper.JobTask.Total_Amount_Incl_Tax__c = jobTaskWrapper.JobTask.Total_Amount__c;
                jobTaskWrapper.JobTask.Tax_Pct__c = taxPct;
                jobTaskWrapper.JobTask.Tax__c = 0;
                if (jobTaskWrapper.JobTask.Tax_Group__c == 'TX') {
                    jobTaskWrapper.JobTask.Tax__c = CompanyMgmt.halfUpTo2D(CompanyMgmt.zeroIfNull(jobTaskWrapper.JobTask.Fixed_Price__c) * jobTaskWrapper.JobTask.Tax_Pct__c / 100);
                    jobTaskWrapper.JobTask.Total_Amount_Incl_Tax__c = jobTaskWrapper.JobTask.Total_Amount__c + jobTaskWrapper.JobTask.Tax__c;
                }
            }
            else {
                jobTaskWrapper.JobTask.Total_Amount__c = 0;
                jobTaskWrapper.JobTask.Total_Amount_Incl_Tax__c = 0;
                jobTaskWrapper.JobTask.Tax__c = 0;
                for(Sales_Line__c salesLine : jobTaskWrapper.SalesLines){
                    jobTaskWrapper.JobTask.Total_Amount__c = CompanyMgmt.zeroIfNull(jobTaskWrapper.JobTask.Total_Amount__c) + CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                    jobTaskWrapper.JobTask.Total_Amount_Incl_Tax__c = CompanyMgmt.zeroIfNull(jobTaskWrapper.JobTask.Total_Amount_Incl_Tax__c) + CompanyMgmt.zeroIfNull(salesLine.Line_Amt_Incl_Tax__c);
                    jobTaskWrapper.JobTask.Tax__c = CompanyMgmt.zeroIfNull(jobTaskWrapper.JobTask.Tax__c) + CompanyMgmt.zeroIfNull(salesLine.Tax__c);
                }
                //jobTaskWrapper.JobTask.Tax_Pct__c = null;
                //jobTaskWrapper.JobTask.Tax__c = null;
            }
        }
        */
        for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
            SalesOrdersService.calcJobTaskAmountFields(salesOrder, jobTaskWrapper.JobTask, jobTaskWrapper.SalesLines, taxPct);
        }
        //ticket 19672 >>
    }

    private static void calculateSalesOrder(Sales_Order__c salesOrder, ACVSalesOrderJobTaskWrapper jobTaskWrapper, Integer nextSalesLineNo) {
        calculateSalesOrder(salesOrder, new List<ACVSalesOrderJobTaskWrapper>{ jobTaskWrapper }, nextSalesLineNo);
    }

    @AuraEnabled
    public static String recalculateSalesLineDetails(String JSONSalesOrder, String JSONJobTaskWrappers, Boolean recalculateHours) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);

            SalesLinesService.recalculateSalesLineDetails(salesOrder, jobTaskWrappers, recalculateHours);

            Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
            //calculateSystemLines(salesOrder, jobTaskWrappers, nextSalesLineNo);
            calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);

            return JSON.serialize(jobTaskWrappers);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /*
     Ticket#17051 - update line pricing info once the rate sheet change is detected
     */
    @AuraEnabled
    public static String validateRateSheet(String JSONSalesOrder, String JSONJobTaskWrappers, String RateSheetId) {
        try{
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);
            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            SalesOrdersService.validateRateSheet(salesOrder, jobTaskWrappers, RateSheetId);
            SalesLinesService.recalculateSalesLineDetails(salesOrder, jobTaskWrappers, false);

            Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
            calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);

            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        } catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static String validatePayRule(String JSONSalesOrder, String JSONJobTaskWrappers) {
        try{
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);
            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            SalesLinesService.calcUnitCost(salesOrder, jobTaskWrappers);
            SalesLinesService.calculateLineTotals(salesOrder, jobTaskWrappers);
            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String saveSalesOrder(String JSONSalesOrder, String JSONJobTaskWrappers) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Id> contactIds = new List<Id>();
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            //ticket 20876 <<
            JSONSalesOrder = null;
            //ticket 20876 >>

            if(salesOrder.Expired__c == true){
                throw new DataException('Record Expired!');
            }
            //US141063
            if(!salesOrder.Is_New_D365_Project__c && salesOrder.D365_Project_ID__c == null){
                throw new DataException('Please select valid project id from D365 Lookup!');
            }

            if(salesOrder.Approval_Status__c == EnumUtil.ApprovalStatus.PENDING_APPROVAL.name()){
                throw new DataException('Record is locked for approval!');
            }

            //Ticket#27427 >>
            if(salesOrder.Id != null && salesOrder.Allow_Edit__c != true){
                throw new DataException('Editing Sales Order/Quote record is prevented!');
            }
            //Ticket#27427 <<

            Account billToAccount = [SELECT Id, Name, PO_Number_Type__c, Type FROM Account WHERE Id = :salesOrder.Bill_to_Customer_No__c LIMIT 1];
            if(salesOrder.Document_Type__c == 'Sales Order') {
                if (salesOrder.Document_Type__c == 'Sales Order' && String.isNotBlank(billToAccount.PO_Number_Type__c) && String.isBlank(salesOrder.Customer_PO_No__c)) {
                    throw new DataException('Customer PO No. field cannot be blank!');
                }
                if (String.isNotBlank(salesOrder.Customer_PO_No__c)) {
                    AccountsService.validatePONumberFormat(billToAccount, salesOrder.Customer_PO_No__c);
                }

                //Ticket#23587 >>
                System.debug('Info: salesOrder.From_Sales_Quote__c: ' + salesOrder.From_Sales_Quote__c + ' salesOrder.From_Sales_Quote__r.Service_Center__c: ' + salesOrder.From_Sales_Quote__r.Service_Center__c);
                if(salesOrder.From_Sales_Quote__c != null &&
                        salesOrder.Service_Center__c != salesOrder.From_Sales_Quote__r.Service_Center__c){
                    throw new DataException('Invalid \'From Quote\' data.  It is not a SC: ' + salesOrder.Service_Center__r.Name + ' quote!');
                }
                //Ticket#23587 <<
            }

			//US118516
            if(salesOrder.Bill_To_Contacts__c != null) {
                contactIds.addAll(salesOrder.Bill_To_Contacts__c.split(','));
            }
            salesOrder.Bill_To_Contacts_Link__c = SalesOrdersService.generateContactHyperLink(contactIds);
            if(billToAccount.Type == 'Prospect') {
                SalesOrdersService.isValidCustomer(salesOrder.Bill_to_Customer_No__c);
            }

            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);
            //ticket 20876 <<
            JSONJobTaskWrappers = null;
            //ticket 20876 >>

            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            List<Sales_Order_Job_Task__c> jobTasks = salesOrderWrapper.getJobTasks();
            List<Sales_Line__c> salesLines = salesOrderWrapper.SalesLines;

            Company_Setup__c companySetup = CompanyMgmt.getCompanySetup();

			Set<Id> resourceIds = new Set<ID>();
            Set<Id> resourceTypeIds = new Set<ID>();
            //Ticket#21908 >>
            for(Sales_Line__c salesLine : salesLines){
                if(ResourceService.isCalcBaseOnResType(salesLine.Category__c) == true){
                    if (salesLine.Resource_Type__r != null && salesLine.Resource_Type__r.Blocked__c == true) {
                        throw new DataException('Please remove line# ' + salesLine.Line_No__c + ' before continuing, resource type "' + salesLine.Resource_Type__r.Name + '" has been blocked.');
                    }
                } else {
                    if (salesLine.Resource__r != null && salesLine.Resource__r.Blocked__c == true) {
                        throw new DataException('Please remove line# ' + salesLine.Line_No__c + ' before continuing, resource "' + salesLine.Resource__r.Name + '" has been blocked.');
                    }
                }
                if(salesLine.Resource__c != null){
                resourceIds.add(salesLine.Resource__c);
                }
                if(salesLine.Resource_Type__c != null){
                    resourceTypeIds.add(salesLine.Resource_Type__c);
                }                
            }
            //US124006 - Validate UOM's are related to Resource or Resource_Type
            if(System.Label.ValidateUOM == 'True'){
                //US124006 - Validate UOM's are related to Resource or Resource_Type
                ResourceService.setResourceMapsByIds(resourceIds);
                for(Sales_Line__c salesLine : salesLines){
                    ResourceUOMAssociation__c hasValidResource = ResourceService.getResourceUOMAssociation(salesLine.Resource__c,salesLine.Unit_of_Measure__c);
                    Resource__c resourceRecord = ResourceService.getResource(salesLine.Resource__c);                    
                    if(salesLine.Category__c != null && System.Label.ExcludedCategory.contains(salesLine.Category__c)){
                        if((salesLine.Resource__c!= null && hasValidResource.Id == null) && (resourceRecord.Unit_of_Measure__c != salesLine.Unit_of_Measure__c)){
                            throw new DataException('Please remove line# ' + salesLine.Line_No__c + ' before continuing, resource "' + salesLine.Unit_of_Measure__r.Name + '" has been invalid.');
                        }                        
                    }                    
                }
            }
            //Ticket#21908 <<

            //Find out deleted sales lines
            Set<Id> xSalesLineIds = new Set<Id>();
            Set<Id> xJobTaskLineIds = new Set<Id>();
            if (salesOrder.Id != null) {
                for (Sales_Order_Job_Task__c jobTask : [SELECT Id FROM Sales_Order_Job_Task__c WHERE Sales_Order__c = :salesOrder.Id]) {
                    xJobTaskLineIds.add(jobTask.Id);
                }
                for (Sales_Line__c salesLine : [SELECT Id FROM Sales_Line__c WHERE Sales_Order__c = :salesOrder.Id]) {
                    xSalesLineIds.add(salesLine.Id);
                }
            }

            for (Sales_Line__c salesLine : salesLines) {
                if (salesLine.Id != null) {
                    xSalesLineIds.remove(salesLine.Id);
                }
            }
            if (xSalesLineIds.size() > 0) {
                //ticket 19130 <<
                delete [SELECT Id FROM Sales_Parent_Child_Relation__c WHERE Child_Line__c IN :xSalesLineIds];
                //ticket 19130 >>
                delete [SELECT Id FROM Sales_Line__c WHERE Sales_Order__c = :salesOrder.Id AND Id IN :xSalesLineIds];
            }

            for (Sales_Order_Job_Task__c jobTask : jobTasks) {
                if (jobTask.Id != null) {
                    xJobTaskLineIds.remove(jobTask.Id);
                }
            }
            if (xJobTaskLineIds.size() > 0) {
                /* comment out - update Sales_Order_Job_Task__c relationship to clear the field when the job task is deleted
                //update sales lines that are linked to the job tasks to be deleted, so the job tasks can be deleted
                List<Sales_Line__c> salesLines2 = [SELECT Id FROM Sales_Line__c WHERE Sales_Order__c = :salesOrder.Id AND Sales_Order_Job_Task__c IN :xJobTaskLineIds];
                if (salesLines2.size() > 0) {
                    for (Sales_Line__c salesLine : salesLines2) {
                        salesLine.Sales_Order_Job_Task__c = null;
                    }
                    update salesLines2;
                }
                */
                delete [SELECT Id FROM Sales_Order_Job_Task__c WHERE Sales_Order__c = :salesOrder.Id AND Id IN :xJobTaskLineIds];
            }
            //job task >>

            //find out deleted detail lines
            Set<Id> xSalesLineDetailIds = new Set<Id>();
            if (salesOrder.Id != null) {
                for (Sales_Line_Detail__c salesLineDetail : [SELECT Id FROM Sales_Line_Detail__c WHERE Sales_Line__r.Sales_Order__c = :salesOrder.Id]) {
                    xSalesLineDetailIds.add(salesLineDetail.Id);
                }
            }
            for (Sales_Line__c salesLine : salesLines) {
                if (salesLine.Sales_Line_Details__r != null) {
                    for (Sales_Line_Detail__c salesLineDetail : salesLine.Sales_Line_Details__r) {
                        if (salesLineDetail.Id != null) {
                            xSalesLineDetailIds.remove(salesLineDetail.Id);
                        }
                    }
                }
            }

            if (xSalesLineDetailIds.size() > 0) {
                delete [SELECT Id FROM Sales_Line_Detail__c WHERE Sales_Line__r.Sales_Order__c = :salesOrder.Id AND Id IN :xSalesLineDetailIds];
            }

            if (salesOrder.Id == null && salesOrder.Document_Type__c == 'Sales Order' && String.isNotEmpty(salesOrder.From_Sales_Quote__c)){
                SalesOrdersService.updateSQWhenNewSOCreated(salesOrder.From_Sales_Quote__c);
            }

            if (salesOrder.Id != null && salesOrder.Bill_to_Customer_No__c != null) {
                List<Sales_Order__c> salesOrders = salesOrdersSelector.newInstance().selectById(new Set<Id> { salesOrder.Id });
                if (salesOrders.size() > 0) {
                    if (salesOrders[0].Bill_to_Customer_No__c != salesOrder.Bill_to_Customer_No__c) {
                        SalesOrdersService.updateTMAndSISuperUserChangeBTC(salesOrder);
                    }
                }
            }


            //job task << //comment out tempariatl7y, causing save error if there is WD line, system gnereate a new manfiest line with quantity 0, resulted save error
            //calculateSalesOrder(salesOrder, jobTasks, salesLines, false);
            //calculate total surcharge amount for sales order
            salesOrder.Surcharge_Amount__c = 0;
            for (Sales_Line__c salesLine : salesLines) {
                if (salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true
                        && (salesLine.Resource__c == companySetup.Default_Energy_Insurance_Resource__c || salesLine.Resource__c == companySetup.Default_Fuel_Surcharge_Resource__c)) {
                    salesOrder.Surcharge_Amount__c += salesLine.Line_Amount__c;
                }
            }
            //job task >>

            SalesRecordApprovalProcess salesRecordAP = new SalesRecordApprovalProcess(salesOrder);
            salesRecordAP.setApprovalStatusOnSave();
			
            String siteAddress = salesOrder.Alternate_Site_Address__c;
            salesOrder.Alternate_Site_Address__c = (String.isNotBlank(siteAddress) && siteAddress.length() > 14 && siteAddress.startsWith('a1V'))?salesOrder.Alternate_Site_Address__c:null;
            
            upsert salesOrder;

            //job task <<
            Map<Integer, Sales_Order_Job_Task__c> mapJobTasksByLineNo = new Map<Integer, Sales_Order_Job_Task__c>();
            for (Sales_Order_Job_Task__c jobTask : jobTasks) {
                if (jobTask.Sales_Order__c == null) {
                    jobTask.Sales_Order__c = salesOrder.Id;
                    jobTask.Sales_Order__r = new Sales_Order__c(Id = salesOrder.Id);
                }
                mapJobTasksByLineNo.put(jobTask.Line_No__c.intValue(), jobTask);
            }
            upsert jobTasks;
            //job task >>

            //populate sales order id
            for (Sales_Line__c salesLine : salesLines) {
                if (salesLine.Sales_Order__c == null) {
                    salesLine.Sales_Order__c = salesOrder.Id;
                    salesLine.Sales_Order__r = new Sales_Order__c(Id = salesOrder.Id);
                }

                //07.29.20 << blank
                if (salesLine.Category__c == 'Materials' || salesLine.Category__c == 'Subcontractors' || salesLine.Category__c == 'Waste Disposal'
                        || salesLine.Category__c == 'Demurrage' || salesLine.Category__c == 'Misc. Charges And Taxes') {
                    salesLine.Resource_Type__c = null;
                    salesLine.Resource_Type__r = null;
                }
                //07.29.20 >>
            }

            Map<Integer, Sales_Line__c> mapSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
            Map<Integer, Sales_Line__c> mapChildLinesByLineNo = new Map<Integer, Sales_Line__c>();
            for (Sales_Line__c salesLine : salesLines) {
                //job task <<
                if (mapJobTasksByLineNo.containsKey(salesLine.Sales_Order_Job_Task__r.Line_No__c.intValue())) {
                    Sales_Order_Job_Task__c jobTask = mapJobTasksByLineNo.get(salesLine.Sales_Order_Job_Task__r.Line_No__c.intValue());
                    salesLine.Sales_Order_Job_Task__r = new Sales_Order_Job_Task__c(Id = jobTask.Id, Name = jobTask.Name);
                    salesLine.Sales_Order_Job_Task__c = jobTask.Id;
                }

                if (salesLine.Bundle_Line__r != null || salesLine.Parent_Line__r != null) {
                    mapChildLinesByLineNo.put(salesLine.Line_No__c.intValue(), salesLine.clone(false, true));
                    salesLine.Bundle_Line__c = null;
                    salesLine.Bundle_Line__r = null;
                    //ticket 19130 <<
                    /*
                    salesLine.Parent_Line__c = null;
                    salesLine.Parent_Line__r = null;
                    */
                    //ticket 19130 >>
                }
                mapSalesLinesByLineNo.put(salesLine.Line_No__c.intValue(), salesLine);
                //job task >>
            }
            CompanyMgmt.byPassTrigger = true; //bypass qty check in SalesOrderTriggersMgt.  Check is performed at the next step, update
            upsert mapSalesLinesByLineNo.values();
            CompanyMgmt.byPassTrigger = false;

            //job task <<
            //insert parent line
            List<Sales_Line__c> salesLinesToUpdate = new List<Sales_Line__c>();
            for (Sales_Line__c salesLine : salesLines) {
                if (mapChildLinesByLineNo.containsKey(salesLine.Line_No__c.intValue())) {
                    Sales_Line__c childLine = mapChildLinesByLineNo.get(salesLine.Line_No__c.intValue());
                    if (childLine.Bundle_Line__r != null) {
                        Sales_Line__c bundleLine = mapSalesLinesByLineNo.get(childLine.Bundle_Line__r.Line_No__c.intValue());
                        salesLine.Bundle_Line__c = bundleLine.Id;
                        salesLine.Bundle_Line__r = new Sales_Line__c(Id = bundleLine.Id, Line_No__c = bundleLine.Line_No__c);
                    }

                    //ticket 19130 <<
                    /*
                    if (childLine.Parent_Line__r != null) {
                        Sales_Line__c parentLine = mapSalesLinesByLineNo.get(childLine.Parent_Line__r.Line_No__c.intValue());
                        salesLine.Parent_Line__c = parentLine.Id;
                        salesLine.Parent_Line__r = new Sales_Line__c(Id = parentLine.Id, Line_No__c = parentLine.Line_No__c);
                    }
                    */
                    //ticket 19130 >>
                }
                salesLinesToUpdate.add(salesLine);
            }
            if (salesLinesToUpdate.size() > 0) {
                upsert salesLinesToUpdate;
            }

            //ticket 19130 <<
            List<Id> relationToDeleteIds = new List<Id>();
            Map<String, Sales_Parent_Child_Relation__c> mapExistingRelationsByKey = new Map<String, Sales_Parent_Child_Relation__c>();
            for (Sales_Parent_Child_Relation__c relation : [SELECT Id, Parent_Line__c, Child_Line__c FROM Sales_Parent_Child_Relation__c WHERE Parent_Line__r.Sales_Order__c = :salesOrder.Id]) {
                String key = relation.Parent_Line__c + ';' + relation.Child_Line__c;
                if (!mapExistingRelationsByKey.containsKey(key)) {
                    mapExistingRelationsByKey.put(key, relation);
                }
                else {
                    relationToDeleteIds.add(relation.Id); //duplicated parent-child if exists
                }
            }

            Map<String, Sales_Parent_Child_Relation__c> mapRelationsToUpsertByKey = new Map<String, Sales_Parent_Child_Relation__c>();
            for (Sales_Line__c salesLine : salesLines) {
                if (salesLine.Sales_Child_Lines__r != null) {
                    for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                        Sales_Line__c parentLine = mapSalesLinesByLineNo.get(relation.Parent_Line__r.Line_No__c.intValue());
                        Sales_Line__c childLine = mapSalesLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());

                        String key = parentLine.Id + ';' + childLine.Id;

                        Sales_Parent_Child_Relation__c relationToUpsert = new Sales_Parent_Child_Relation__c();
                        if (mapExistingRelationsByKey.containsKey(key)) {
                            relationToUpsert.Id = mapExistingRelationsByKey.get(key).Id;
                            mapExistingRelationsByKey.remove(key);
                        }
                        else {
                            relationToUpsert.Parent_Line__c = parentLine.Id;
                        }

                        relationToUpsert.Child_Line__c = childLine.Id;

                        if (!mapExistingRelationsByKey.containsKey(key)) {
                            mapRelationsToUpsertByKey.put(key, relationToUpsert);
                        }
                        else {
                            throw new DataException('Parent child relationship already exists: ' + key);
                        }
                    }
                }
            }
            upsert mapRelationsToUpsertByKey.values();

            if (mapExistingRelationsByKey.size() > 0) {
                for (Sales_Parent_Child_Relation__c relation : mapExistingRelationsByKey.values()) {
                    relationToDeleteIds.add(relation.Id);
                }
            }
            if (relationToDeleteIds.size() > 0) {
                delete [SELECT Id FROM Sales_Parent_Child_Relation__c WHERE Id IN :relationToDeleteIds];
            }
            //ticket 19130 >>

            if (salesLines != null) {
                for (Sales_Line__c salesLine : salesLines) {
                    if (salesLine.Sales_Order__c == null) {
                        salesLine.Sales_Order__c = salesOrder.Id;
                        salesLine.Sales_Order__r = new Sales_Order__c(Id = salesOrder.Id);
                    }

                    //rate.code.fix <<
                    if (salesLine.Category__c == 'Labor' && salesLine.Unit_of_Measure__r != null && salesLine.Unit_of_Measure__r.Name == 'DAY') {
                        if (salesLine.Sales_Line_Details__r != null) {
                            Integer regularDays = 0;
                            Integer overtimeDays = 0;
                            Integer doubleTimeDays = 0;
                            for (Integer i = 0; i < salesLine.Sales_Line_Details__r.size(); i++) {
                                Sales_Line_Detail__c salesLineDetail = salesLine.Sales_Line_Details__r[i];
                                if (salesLineDetail.Day_Rate_Code__c == EnumUtil.TimeRateCode.REG.name()) {
                                    regularDays++;
                                } else if (salesLineDetail.Day_Rate_Code__c == EnumUtil.TimeRateCode.OT.name()) {
                                    overtimeDays++;
                                } else if (salesLineDetail.Day_Rate_Code__c == EnumUtil.TimeRateCode.DT.name()) {
                                    doubleTimeDays++;
                                }
                            }
                            if ((regularDays + overtimeDays + doubleTimeDays) == 0) {
                                throw new DataException('REG/OT/DT days need to be recalculated on the sales line ' + salesLine.Line_No__c.intValue() + '. Please refresh the UOM, Quantity or UOM Qty to recalculate.' );
                            }
                            salesLine.Regular_Day__c = regularDays;
                            salesLine.Overtime_Day__c = overtimeDays;
                            salesLine.Premium_Day__c = doubleTimeDays;
                        }
                    }
                    //rate.code.fix >>
                }
                upsert salesLines;

                List<Sales_Line_Detail__c> salesLineDetails = new List<Sales_Line_Detail__c>();
                for (Sales_Line__c salesLine : salesLines) {

                    if (salesLine.Sales_Line_Details__r != null) {
                        Set<Date> scheduledDates = new Set<Date>();
                        for (Integer i = 0; i < salesLine.Sales_Line_Details__r.size(); i++) {
                            Sales_Line_Detail__c salesLineDetail = salesLine.Sales_Line_Details__r[i];

                            if (salesLineDetail.Scheduled_Date__c != null && scheduledDates.contains(salesLineDetail.Scheduled_Date__c)) {
                                throw new DataException('Duplicated scheduled date ' + salesLineDetail.Scheduled_Date__c.format() + ' on sales line #' + salesLine.Line_No__c.intValue() + '.');
                            }
                            scheduledDates.add(salesLineDetail.Scheduled_Date__c);

                            if (salesLineDetail.Sales_Line__c == null) {
                                salesLineDetail.Sales_Line__c = salesLine.Id;
                                //equipment schedule lines <<
                                salesLineDetail.Sales_Line__r = new Sales_Line__c(Id = salesLine.Id);
                                //equipment schedule lines >>
                            }
                            salesLineDetails.add(salesLineDetail);
                        }
                    }
                }

                if (salesLineDetails.size() > 0) {
                    upsert salesLineDetails;
                }
            }

            //ticket 20177 <<
            Map<Id, Sales_Order_Job_Task__c> mapSalesOrderJobTasksById = new Map<Id, Sales_Order_Job_Task__c>();
            for (Sales_Order_Job_Task__c jobTask : mapJobTasksByLineNo.values()) {
                mapSalesOrderJobTasksById.put(jobTask.Id, jobTask);
            }
            List<TM_Job_Task__c> tmJobTasksToUpdate = new List<TM_Job_Task__c>();
            for (TM_Job_Task__c tmJobTask : [SELECT Id, Name, Sales_Order_Job_Task__c FROM TM_Job_Task__c WHERE Sales_Order_Job_Task__c IN :mapSalesOrderJobTasksById.keySet() AND TM__r.Sales_Invoice__c = NULL]) { //not invoiced
                if (mapSalesOrderJobTasksById.containsKey(tmJobTask.Sales_Order_Job_Task__c)) {
                    Sales_Order_Job_Task__c salesOrderJobTask = mapSalesOrderJobTasksById.get(tmJobTask.Sales_Order_Job_Task__c);
                    if (tmJobTask.Name != salesOrderJobTask.Name) {
                        tmJobTask.Name = salesOrderJobTask.Name;
                        tmJobTasksToUpdate.add(tmJobTask);
                    }
                }
            }
            if (tmJobTasksToUpdate.size() > 0) {
                update tmJobTasksToUpdate;
            }
            //ticket 20177 >>

            if (salesOrder.Manifest_And_Profile__c != true) {
                //remove manifest fee lines if T&M lines are not invoiced yet.
                List<TM__c> tms = [SELECT Id,
                (SELECT Id FROM TM_Lines__r WHERE Invoiced__c != TRUE AND Category__c = 'Waste Disposal' AND System_Calculated_Line__c = TRUE AND Resource__c = :companySetup.Default_Manifest_Fee_Resource__c)
                FROM TM__c WHERE Sales_Order__c = :salesOrder.Id AND Status__c != 'Fully Invoiced' AND Status__c != 'Void' AND Status__c != 'Closed'];
                List<TM_Line__c> tmLinesToDelete = new List<TM_Line__c>();
                for (TM__c tm : tms) {
                    for (TM_Line__c tmLine : tm.TM_Lines__r) {
                        tmLinesToDelete.add(tmLine);
                    }
                }
                delete tmLinesToDelete;
            }
            //ticket 75619 >>
            if(System.Label.Release_Flag =='true')
            {
                salesOrder.Site_Name__c = String.isNotBlank(salesOrder.Site_Name__c)?salesOrder.Site_Name__c:salesOrder.Site_Street__c;
                List<Site_Address__c> siteList = [SELECT Id FROM Site_Address__c 
                                                  WHERE Customer__c=:salesOrder.Bill_to_Customer_No__c 
                                                  AND Site_Street__c=:salesOrder.Site_Street__c
                                                  AND Site_City__c=:salesOrder.Site_City__c
                                                  AND Site_State__c=:salesOrder.Site_State__c
                                                  AND Site_Postal_Code__c=:salesOrder.Site_Postal_Code__c
                                                  AND Site_Country__c=:salesOrder.Site_Country__c
                                                  AND Name=:salesOrder.Site_Name__c
                                                  AND EPA_ID__c=:salesOrder.EPA_ID__c LIMIT 1];
                //US117390
                if(salesOrder.EqaiGeneratorId__c != null)
                {
                    salesOrder.Site_Address_Changed__c = false;
                    update salesOrder;  
                }
                else if(salesOrder.SO_sent_to_EQAI__c && salesOrder.EqaiGeneratorId__c == null)
                {
                    updateSiteAddress(salesOrder);
                }
                else if(siteList.isEmpty() && salesOrder.EqaiGeneratorId__c == null)
                {
                    Site_Address__c newSiteAddress = New Site_Address__c();
                    newSiteAddress.Customer__c = salesOrder.Bill_to_Customer_No__c;
                    newSiteAddress.Name =String.isNotBlank(salesOrder.Site_Name__c)?salesOrder.Site_Name__c:salesOrder.Site_Street__c;
                    newSiteAddress.Site_Street__c=salesOrder.Site_Street__c;
                    newSiteAddress.Site_City__c=salesOrder.Site_City__c;
                    newSiteAddress.Site_State__c =salesOrder.Site_State__c;
                    newSiteAddress.Site_Postal_Code__c =salesOrder.Site_Postal_Code__c;
                    newSiteAddress.Site_Country__c=salesOrder.Site_Country__c;
                    newSiteAddress.Site_Contact__c = salesOrder.Site_Contact__c;
                    newSiteAddress.Contact__c=salesOrder.Site_Contact_2__c;
                    newSiteAddress.Site_Phone_No__c=salesOrder.Site_Phone_No__c;
                    newSiteAddress.Tax_Area__c = salesOrder.Tax_Area__c;
                    newSiteAddress.Print_Site_Name__c=salesOrder.Print_Site_Name__c;
                    insert newSiteAddress; 
                    salesOrder.Alternate_Site_Address__c =String.isNotBlank(newSiteAddress.Id)?newSiteAddress.Id:null;
                    update salesOrder; 
                }
                else if(siteList.size()>0 && salesOrder.EqaiGeneratorId__c == null)
                {
                    // Bug#77485
                    siteList[0].Name =salesOrder.Site_Name__c;
                    update siteList[0]; 
                    salesOrder.Alternate_Site_Address__c =String.isNotBlank(siteList[0].Id)?siteList[0].Id:null;
                    update salesOrder; 
                }
            }
            List<Billing_Worksheet_line__c> billingworksheetline = [SELECT Id,Sales_Line__c,Sales_Order__r.Tax_Area__c, Sales_Order__c, 
                                                                    Tax_Group__c,Sales_Line__r.Tax_Group__c,
                                                                    Sales_Order__r.Tax_Liable__c,Line_Amount__c,Line_Amt_Incl_Tax__c,
                                                                    Bill_as_Lump_Sum__c,Non_Billable__c
                                                                    FROM Billing_Worksheet_line__c
                                                                    WHERE Sales_Order__c = :salesOrder.Id AND T_M_Status__c = 'Confirmed'
                                                                   AND To_Invoice__c = false];
            List<Billing_Worksheet_line__c> updateBWLines = new  List<Billing_Worksheet_line__c>();
            for(Billing_Worksheet_line__c bwl : billingworksheetline)
            {
               Boolean chkFlag = false;
              if(bwl.Tax_Group__c != 'TX' && bwl.Sales_Order__r.Tax_Liable__c == True ) 
               {
                   bwl.Tax_Group__c = 'TX';
                   bwl.Tax_Pct__c = CompanyMgmt.getSalesTax(bwl.Sales_Order__r.Tax_Area__c, 'TX');
                   bwl.Tax__c = CompanyMgmt.halfUpTo2D(bwl.Line_Amount__c * CompanyMgmt.zeroIfNull(bwl.Tax_Pct__c) / 100);
                   bwl.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(bwl.Line_Amount__c + bwl.Tax__c);
                   chkFlag = True;
               }
                   
               else if(bwl.Tax_Group__c == 'TX' && bwl.Sales_Order__r.Tax_Liable__c == False)
               {
                   bwl.Tax_Group__c = 'NT';
                   bwl.Tax_Pct__c = 0;
                   bwl.Tax__c = 0;
                   bwl.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(bwl.Line_Amount__c + bwl.Tax__c);
                   chkFlag = True;
                   
               } 
                
              if(bwl.Sales_Line__c != null)
               {
                    String taxgroup = bwl.Sales_Line__r.Tax_Group__c;
                    if(bwl.Tax_Group__c == 'NT' && taxgroup == 'TX' )
                    {
                        bwl.Tax_Group__c = 'TX';
                        bwl.Tax_Pct__c = CompanyMgmt.getSalesTax(bwl.Sales_Order__r.Tax_Area__c, 'TX');
                   	    bwl.Tax__c = CompanyMgmt.halfUpTo2D(bwl.Line_Amount__c * CompanyMgmt.zeroIfNull(bwl.Tax_Pct__c) / 100); 
                        bwl.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(bwl.Line_Amount__c + bwl.Tax__c);
                        CompanyMgmt.systemCall = true;
						chkFlag = True;
						                       
                    }
                    else if(bwl.Tax_Group__c == 'TX' && taxgroup == 'NT')
                    {
                         bwl.Tax_Group__c = 'NT';
                         bwl.Tax_Pct__c = 0; 
                         bwl.Tax__c = 0;
                         bwl.Line_Amt_Incl_Tax__c = CompanyMgmt.halfUpTo2D(bwl.Line_Amount__c + bwl.Tax__c);
                         CompanyMgmt.systemCall = true;
                         chkFlag = True;
                                           
                    }
                 }
                if (bwl.Bill_as_Lump_Sum__c == true || bwl.Non_Billable__c == true) 
                {
                    bwl.Line_Amount__c = 0;
                    bwl.Tax__c = 0;
                    bwl.Line_Amt_Incl_Tax__c = 0;
                    chkFlag = True;

        		}
                if(chkFlag == True)
                     updateBWLines.add(bwl);
                   
            }
           if(!updateBWLines.isEmpty())
           {
               CompanyMgmt.systemCall = true;
               update updateBWLines;
               CompanyMgmt.systemCall = false;
           }
               

            return getSalesOrder(salesOrder.Id);
        }
        catch(Exception ex) {
        Database.rollback(sp);
		String errorMessage = ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')? ex.getMessage().substring( ex.getMessage().indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION,'.length()): ex.getMessage();
		throw new AuraHandledException(errorMessage);
	}        
}

    /*
     *   Ticket#20977 - Add Subsidiary Company into the filter.
     */
    @AuraEnabled
    public static List<Contract> getContracts(Id accountId) {
       try {
            List<Account> accounts = [SELECT Id, ParentId, Subsidiary_Company__r.Name FROM Account WHERE Id = :accountId and Subsidiary_Company__c != Null];
            if (accounts.size() > 0) {
                Set<Id> acctIds = new Set<Id>();
                acctIds.add(accounts[0].Id);
                if (accounts[0].ParentId != null) {
                    acctIds.add(accounts[0].ParentId);
                }
                List<Contract> contracts = new List<Contract>();
                for(Contract contract : ContractsSelector.newInstance().selectByAccountId(acctIds)){
                    if(contract.Subsidiary__c != Null)
                    {
                        if(contract.Subsidiary__c.contains(accounts[0].Subsidiary_Company__r.Name)){
                       		 contracts.add(contract);
                       } 
                    }
                   
                }
                return contracts;
            }
            return null;
        }
        catch(exception ex) {
           throw new AuraHandledException(ex.getMessage());
       }
    }
    
    @AuraEnabled
    public static Boolean isCustomerInActive(Id accountId) {
        List<Account> accts = [SELECT Id, Name, Type, AccountNumber,Sage_Customer_No__c,Customer_Status__c FROM Account WHERE Id = :accountId];
        if (accts.size() > 0){
            if(accts[0].Customer_Status__c == 'InActive'){
                return true;
            }
        }
        return false;
    }
    //Task#78375 Task#78376 Bug#84091
    @AuraEnabled
    public static Boolean allowNewSalesOrders(Id accountId) {
        try {
            List<Account> accts = [SELECT Id, Name, Type, AccountNumber,Sage_Customer_No__c,Customer_Status__c FROM Account WHERE Id = :accountId];
            if (accts.size() > 0 && System.Label.Release_Flag =='true') {
                if(accts[0].Type == 'Prospect'){
                    if(((accts[0].AccountNumber != null || accts[0].Sage_Customer_No__c != null) && System.Label.Account_Number_Validation =='false') ||(accts[0].Sage_Customer_No__c != null && System.Label.Account_Number_Validation =='true'))
                    {
                        return true;
                    } 
                }
                else if (accts[0].Type == 'Customer') {
                    if(accts[0].Customer_Status__c == 'Inactive'){
                        List<Sales_Order__c> sos = [SELECT Id FROM Sales_Order__c WHERE Document_Type__c = 'Sales Order' AND Bill_to_Customer_No__c = :accountId];
                        if (sos.size() > 0) {
                            return false;
                        }
                        else{
                            return true;
                        }
                    }
                    else if(((accts[0].AccountNumber != null && accts[0].Sage_Customer_No__c != null) && System.Label.Account_Number_Validation =='false') ||(accts[0].Sage_Customer_No__c != null && System.Label.Account_Number_Validation =='true'))
                    {
                        return true;
                    }
                    
                    else if(((accts[0].AccountNumber == null || accts[0].Sage_Customer_No__c == null) && System.Label.Account_Number_Validation =='false') ||(accts[0].Sage_Customer_No__c == null && System.Label.Account_Number_Validation =='true'))
                    {
                        if(accts[0].Customer_Status__c == 'Active'){
                        //Bug#85795
                        List<Sales_Order__c> sos = [SELECT Id FROM Sales_Order__c WHERE Document_Type__c = 'Sales Order' AND Bill_to_Customer_No__c = :accountId];
                        if (sos.size() == 0) {
                            return true;
                        }
                        }
                       
                    }
                    
                }
                return false;
            } else if(accts.size() > 0 && System.Label.Release_Flag =='false')
            {
                /*if(accts[0].Type == 'Prospect'){
                    if(accts[0].AccountNumber != null)
                    {
                        return true;
                    } 
                }
                else */if (accts[0].Type == 'Customer') {
                    /*if(accts[0].AccountNumber != null)
                    {
                        return true;
                    }*/
                    List<Sales_Order__c> sos = [SELECT Id FROM Sales_Order__c WHERE Document_Type__c = 'Sales Order' AND Bill_to_Customer_No__c = :accountId];
                    if (sos.size() == 0) {
                        return true;
                    }  
                }
                return false;  
            }
            else {
                throw new DataException('Invalid account id \'' + accountId + '.\'');
            }
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //Task#78375 Task#78376 Bug#84091
    /*@AuraEnabled
    public static Boolean allowNewSalesOrders(Id accountId) {
        try {
            List<Account> accts = [SELECT Id, Name, Type, AccountNumber,Sage_Customer_No__c FROM Account WHERE Id = :accountId];
            if (accts.size() > 0 && System.Label.Release_Flag =='true') {
                if(accts[0].Type == 'Prospect'){
                    if(((accts[0].AccountNumber != null || accts[0].Sage_Customer_No__c != null) && System.Label.Account_Number_Validation =='false') ||(accts[0].Sage_Customer_No__c != null && System.Label.Account_Number_Validation =='true'))
                    {
                        return true;
                    } 
                }
                else if (accts[0].Type == 'Customer') {
                    if(((accts[0].AccountNumber != null && accts[0].Sage_Customer_No__c != null) && System.Label.Account_Number_Validation =='false') ||(accts[0].Sage_Customer_No__c != null && System.Label.Account_Number_Validation =='true'))
                    {
                        return true;
                    }
                    else if(((accts[0].AccountNumber == null || accts[0].Sage_Customer_No__c == null) && System.Label.Account_Number_Validation =='false') ||(accts[0].Sage_Customer_No__c == null && System.Label.Account_Number_Validation =='true'))
                    {
                        //Bug#85795
                        List<Sales_Order__c> sos = [SELECT Id FROM Sales_Order__c WHERE Document_Type__c = 'Sales Order' AND Bill_to_Customer_No__c = :accountId];
                        if (sos.size() == 0) {
                            return true;
                        }  
                    }
                }
                return false;
            } else if(accts.size() > 0 && System.Label.Release_Flag =='false')
            {
                if(accts[0].Type == 'Prospect'){
                    if(accts[0].AccountNumber != null)
                    {
                        return true;
                    } 
                }
                else if (accts[0].Type == 'Customer') {
                    if(accts[0].AccountNumber != null)
                    {
                        return true;
                    }
                    List<Sales_Order__c> sos = [SELECT Id FROM Sales_Order__c WHERE Document_Type__c = 'Sales Order' AND Bill_to_Customer_No__c = :accountId];
                    if (sos.size() == 0) {
                        return true;
                    }  
                }
                return false;  
            }
            else {
                throw new DataException('Invalid account id \'' + accountId + '.\'');
            }
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }*/

    @AuraEnabled
    public static String validateFromSalesQuote(String JSONSalesOrder, String JSONJobTaskWrappers) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            //re-calculate pricing >>
            for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    salesLine.Contract_Line__c = null;
                    salesLine.Quote_Line__c = null;
                }
            }
            //re-calculate pricing <<

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            SalesLinesService.recalculateSalesLines(salesOrder, jobTaskWrappers);


            Company_Setup__c companySetup = CompanyMgmt.getCompanySetup();

            if (salesOrder.From_Sales_Quote__c != null) {
                List<Sales_Order__c> fromQuotes = SalesOrdersSelector.newInstance().selectById(new Set<Id>{ salesOrder.From_Sales_Quote__c });
                if (fromQuotes.size() > 0) {
                    Sales_Order__c fromQuote = fromQuotes[0];
                    salesOrder.From_Sales_Quote__r = fromQuote;
                }
            }

            Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);
            calculateSalesOrder(salesOrder, jobTaskWrappers, nextSalesLineNo);
            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //ticket 19130 05.12.2023 <<
    @AuraEnabled
    public static String prepareWizardQuestions(String JSONSalesOrder, String JSONJobTaskWrappers) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = (List<ACVSalesOrderJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesOrderJobTaskWrapper>.class);

            //ticket 19130 << not needed, all child lines should be calculated as lines are inserted or updated
            /*
            Integer nextSalesLineNo = 0;
            //Set<Id> resourceTypeIds = new Set<Id>();
            //Set<Id> resourceIds = new Set<Id>();
            for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    if (nextSalesLineNo < salesLine.Line_No__c) {
                        nextSalesLineNo = salesLine.Line_No__c.intValue();
                    }
                }
            }
            nextSalesLineNo++;

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            //find all parent resources that have child resources
            Map<Integer, List<Sales_Line__c>> mapChildLinesByParentLineNo = new Map<Integer, List<Sales_Line__c>>();
            //Map<Integer, Sales_Line__c> mapSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
            for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
                ACVSalesOrderJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    if (salesLine.Wizard_Question_Answered__c != true && salesLine.Parent_Line__r == null) {
                        List<Sales_Line__c> childLines = SalesLinesService.calculatePresumptiveChildLines(salesOrder, jobTaskWrapper.JobTask, salesLine, nextSalesLineNo);
                        mapChildLinesByParentLineNo.put(salesLine.Line_No__c.intValue(), childLines);
                        nextSalesLineNo += childLines.size();
                    }
                    //mapSalesLinesByLineNo.put(salesLine.Line_No__c.intValue(), salesLine);
                }
            }

            //insert new child lines to jobTaskWrapper
            if (mapChildLinesByParentLineNo.size() > 0) {
                for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
                    ACVSalesOrderJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];
                    List<Sales_Line__c> childLinesToInsert = new List<Sales_Line__c>();
                    for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                        if (mapChildLinesByParentLineNo.containsKey(salesLine.Line_No__c.intValue())) { //is a parent line
                            //check if the parent line already has child lines
                            Boolean childLinesExist = false;
                            for (Sales_Line__c salesLine2 : jobTaskWrapper.SalesLines) {
                                if (salesLine2.Parent_Line__r != null && salesLine2.Parent_Line__r.Line_No__c == salesLine.Line_No__c) {
                                    childLinesExist = true;
                                    break;
                                }
                            }
                            if (!childLinesExist) { //add the child lines
                                List<Sales_Line__c> newChildLines = mapChildLinesByParentLineNo.get(salesLine.Line_No__c.intValue());
                                childLinesToInsert.addAll(newChildLines);
                            }
                        }
                    }
                    for (Sales_Line__c childLine : childLinesToInsert) {
                        jobTaskWrapper.SalesLines.add(childLine);
                    }
                }
            }
            */
            //ticket 19130 >>

            //ticket 19130 <<
            /*
            Map<Integer, List<Map<String, Object>>> mapQuestionsByTaskIndex = new Map<Integer, List<Map<String, Object>>>();
            for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
                ACVSalesOrderJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];

                //group child lines by parent line no
                Map<Integer, List<Sales_Line__c>> mapChildSalesLinesByParentLineNo = new Map<Integer, List<Sales_Line__c>>();
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    if (salesLine.Parent_Line__r != null && salesLine.Parent_Line__r.Line_No__c != null) {
                        if (salesLine.Quantity__c == null || salesLine.Quantity__c == 0) {
                            Integer parentLineNo = salesLine.Parent_Line__r.Line_No__c.intValue();
                            List<Sales_Line__c> childSalesLines;
                            if (mapChildSalesLinesByParentLineNo.containsKey(parentLineNo)) {
                                childSalesLines = mapChildSalesLinesByParentLineNo.get(parentLineNo);
                            } else {
                                childSalesLines = new List<Sales_Line__c>();
                                mapChildSalesLinesByParentLineNo.put(parentLineNo, childSalesLines);
                            }
                            childSalesLines.add(salesLine);
                        }
                    }
                }

                //List<Job_Task_Template_Line__c> questions = new List<Job_Task_Template_Line__c>();
                List<Map<String, Object>> questions = new List<Map<String, Object>>();
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    if (salesLine.Wizard_Question_Answered__c != true) {
                        Integer salesLineNo = salesLine.Line_No__c.intValue();
                        if (mapChildSalesLinesByParentLineNo.containsKey(salesLineNo)) {
                            //String parentResourceDescription = salesLine.Description__c;
                            List<Sales_Line__c> childSalesLines = mapChildSalesLinesByParentLineNo.get(salesLineNo);
                            for (Sales_Line__c childSalesLine : childSalesLines) {
                                Map<String, Object> question = new Map<String, Object>();
                                question.put('Line_No__c', childSalesLine.Line_No__c.intValue());
                                question.put('Category__c', childSalesLine.Category__c);
                                question.put('Resource_Type__c', childSalesLine.Resource_Type__c);
                                question.put('Resource_Type__r', childSalesLine.Resource_Type__r);
                                question.put('Resource__c', childSalesLine.Resource__c);
                                question.put('Resource__r', childSalesLine.Resource__r);
                                question.put('Description__c', childSalesLine.Description__c);
                                question.put('Unit_of_Measure__c', childSalesLine.Unit_of_Measure__c);
                                question.put('Unit_of_Measure__r', childSalesLine.Unit_of_Measure__r);
                                question.put('Cost_Method__c', childSalesLine.Cost_Method__c);
                                question.put('Unit_Weight_Vol__c', childSalesLine.Unit_Weight_Vol__c);
                                question.put('Unit_Weight_Vol__r', childSalesLine.Unit_Weight_Vol__r);
                                question.put('Container_Size__c', childSalesLine.Container_Size__c);
                                question.put('Container_Size__r', childSalesLine.Container_Size__r);
                                question.put('Resource_Type_UOM__c', childSalesLine.Resource_Type_UOM__c);
                                question.put('Resource_Type_UOM__r', childSalesLine.Resource_Type_UOM__r);
                                question.put('Resource_UOM__c', childSalesLine.Resource_UOM__c);
                                question.put('Resource_UOM__r', childSalesLine.Resource_UOM__r);
                                question.put('Unit_Price__c', childSalesLine.Unit_Price__c);
                                question.put('xUnit_Price__c', childSalesLine.xUnit_Price__c);
                                question.put('Unit_Cost__c', childSalesLine.Unit_Cost__c);
                                question.put('xUnit_Cost__c', childSalesLine.xUnit_Cost__c);
                                question.put('Tax_Group__c', childSalesLine.Tax_Group__c);
                                question.put('Tax_Pct__c', childSalesLine.Tax_Pct__c);
                                question.put('Tax__c', childSalesLine.Tax__c);
                                question.put('Regular_Rate__c', childSalesLine.Regular_Rate__c);
                                question.put('Overtime_Rate__c', childSalesLine.Overtime_Rate__c);
                                question.put('Premium_Rate__c', childSalesLine.Premium_Rate__c);
                                question.put('xRegular_Rate__c', childSalesLine.xRegular_Rate__c);
                                question.put('xOvertime_Rate__c', childSalesLine.xOvertime_Rate__c);
                                question.put('xPremium_Rate__c', childSalesLine.xPremium_Rate__c);
                                question.put('Pricing_Source_2__c', childSalesLine.Pricing_Source_2__c);
                                question.put('Line_Amount__c', childSalesLine.Line_Amount__c);
                                question.put('xLine_Amount__c', childSalesLine.xLine_Amount__c);
                                question.put('Line_Amt_Incl_Tax__c', childSalesLine.Line_Amt_Incl_Tax__c);
                                question.put('Line_Cost__c', childSalesLine.Line_Cost__c);
                                question.put('xLine_Cost__c', childSalesLine.xLine_Cost__c);
                                question.put('Contract_Line__c', childSalesLine.Contract_Line__c);
                                question.put('Contract_Line__r', childSalesLine.Contract_Line__r);
                                question.put('Number_of_Day__c', salesOrder.Duration__c);
                                String questionDescription = 'Parent Line #' + salesLine.Line_No__c.intValue() + ': ' + salesLine.Description__c;
                                questionDescription += ', Quantity ' + salesLine.Quantity__c + '</br>';
                                questionDescription += '<span style="padding-left:50px;">Child resource ' + childSalesLine.Description__c + ' has ZERO quantity. Do you want to change the quantity?</span>';
                                question.put('Question__c', questionDescription);
                                question.put('Parent_Line__c', salesLine.Id);
                                question.put('Parent_Line__r', new Sales_Line__c(Id = salesLine.Id, Line_No__c = salesLine.Line_No__c));
                                questions.add(question);
                            }
                        }
                    }
                    if (questions.size() > 0) {
                        mapQuestionsByTaskIndex.put(i, questions); //by job task wrapper index
                    }
                }
            }
            */

            SalesLinesService.initStaticVariables(salesOrder, jobTaskWrappers);
            Integer nextSalesLineNo = getNextSalesLineNo(jobTaskWrappers);

            //ticket 19130 <<
            for (ACVSalesOrderJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                jobTaskWrapper.NextSalesLineNo = nextSalesLineNo;
            }
            //ticket 19130 >>

            //set the wizard question answered to false if resource type, resource, qty or uom changed <<
            Set<Id> salesLineIds = new Set<Id>();
            for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
                ACVSalesOrderJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    if (salesLine.Id != null) {
                        salesLineIds.add(salesLine.Id);
                    }
                }
            }

            Map<Id, Sales_Line__c> mapxSalesLinesById = new Map<Id, Sales_Line__c>();
            for (Sales_Line__c salesLine : [SELECT Id, Resource_Type__c, Resource__c, Quantity__c, Unit_of_Measure__c FROM Sales_Line__c WHERE Id IN :salesLineIds]) {
                mapxSalesLinesById.put(salesLine.Id, salesLine);
            }
            //set the wizard question answered to false if resource type, resource, qty or uom changed >>

            Map<Integer, List<Map<String, Object>>> mapQuestionsByTaskIndex = new Map<Integer, List<Map<String, Object>>>();
            for (Integer i = 0; i < jobTaskWrappers.size(); i++) {
                ACVSalesOrderJobTaskWrapper jobTaskWrapper = jobTaskWrappers[i];
                Map<Id, Sales_Line__c> mapSalesLinesByResourceId = new Map<Id, Sales_Line__c>();
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    //set the wizard question answered to false if resource type, resource, qty or uom changed <<
                    if (mapxSalesLinesById.containsKey(salesLine.Id)) {
                        Sales_Line__c xSalesLine = mapxSalesLinesById.get(salesLine.Id);
                        if (salesLine.Resource_Type__c != xSalesLine.Resource_Type__c || salesLine.Resource__c != xSalesLine.Resource__c || salesLine.Quantity__c != xSalesLine.Quantity__c || salesLine.Unit_of_Measure__c != xSalesLine.Unit_of_Measure__c) {
                            salesLine.Wizard_Question_Answered__c = false;
                        }
                    }
                    //set the wizard question answered to false if resource type, resource, qty or uom changed >>

                    Id resourceId = getSalesLineResourceTypeIdOrResourceId(salesLine);
                    mapSalesLinesByResourceId.put(resourceId, salesLine);
                }

                for (Integer j = 0; j < jobTaskWrapper.SalesLines.size(); j++) {
                    Sales_Line__c salesLine = jobTaskWrapper.SalesLines[j];
                    
                    //ticket 27075 <<
                    jobTaskWrapper.NextSalesLineNo = nextSalesLineNo;
                    //ticket 27075 >>
                    
                    if (salesLine.Wizard_Question_Answered__c == true) continue;

                    //track relationships at SQ/SO level, Resource level
                    Map<Id, Sales_Parent_Child_Relation__c> mapSalesParentRelationsByResourceId = new Map<Id, Sales_Parent_Child_Relation__c>();

                    //insert SQ/SO level parent-child relationship
                    if (salesLine.Sales_Child_Lines__r != null) {
                        for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                            Id childResourceId = getSalesLineResourceTypeIdOrResourceId(relation.Child_Line__r);
                            mapSalesParentRelationsByResourceId.put(childResourceId, relation);
                        }
                    }
                    salesLine = (Sales_Line__c)JSONUtils.attachListToParent(salesLine, mapSalesParentRelationsByResourceId.values(), 'Sales_Child_Lines__r');

                    //insert resource level parent-child relationship
                    System.debug('******************* nextSalesLineNo ' + nextSalesLineNo + ' , ' + jobTaskWrapper.NextSalesLineNo);
                    salesLine = SalesLinesService.calculatePresumptiveChildLines(salesOrder, jobTaskWrapper, salesLine, nextSalesLineNo);
                    jobTaskWrapper.SalesLines[j] = salesLine;
                    nextSalesLineNo = jobTaskWrapper.NextSalesLineNo;
                }

                //group parent lines by child resource
                Map<Integer, Sales_Line__c> mapSalesLinesByLineNo = new Map<Integer, Sales_Line__c>();
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    mapSalesLinesByLineNo.put(salesLine.Line_No__c.intValue(), salesLine);
                }

                //set wizard question answered, loop the lines twice to set Wizard_Question_Answered__c for level 1 and level 2 child resources
                for (Integer j = 0; j < 2; j++) {
                    for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                        if (salesLine.Sales_Child_Lines__r != null && salesLine.Sales_Child_Lines__r.size() > 0) {
                            for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                                Sales_Line__c childTMLine = mapSalesLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());
                                if (salesLine.Wizard_Question_Answered__c != true) {
                                    childTMLine.Wizard_Question_Answered__c = false;
                                }
                            }
                        }
                    }
                }

                Map<Integer, List<Sales_Line__c>> mapParentLinesByChildLineNo = new Map<Integer, List<Sales_Line__c>>();
                for (Sales_Line__c salesLine : jobTaskWrapper.SalesLines) {
                    if (salesLine.Sales_Child_Lines__r != null && salesLine.Sales_Child_Lines__r.size() > 0) {
                        for (Sales_Parent_Child_Relation__c relation : salesLine.Sales_Child_Lines__r) {
                            Sales_Line__c childSalesLine = mapSalesLinesByLineNo.get(relation.Child_Line__r.Line_No__c.intValue());

                            List<Sales_Line__c> parentLines;
                            if (mapParentLinesByChildLineNo.containsKey(childSalesLine.Line_No__c.intValue())) {
                                parentLines = mapParentLinesByChildLineNo.get(childSalesLine.Line_No__c.intValue());
                            } else {
                                parentLines = new List<Sales_Line__c>();
                                mapParentLinesByChildLineNo.put(childSalesLine.Line_No__c.intValue(), parentLines);
                            }
                            parentLines.add(salesLine);
                        }
                    }
                }

                List<Map<String, Object>> questions = new List<Map<String, Object>>();
                for (Integer childLineNo : mapParentLinesByChildLineNo.keySet()) {
                    Sales_Line__c childSalesLine = mapSalesLinesByLineNo.get(childLineNo);
                    if (childSalesLine.Wizard_Question_Answered__c != true) {
                        Map<String, Object> question = new Map<String, Object>();
                        question.put('Line_No__c', childSalesLine.Line_No__c.intValue());
                        question.put('Category__c', childSalesLine.Category__c);
                        question.put('Resource_Type__c', childSalesLine.Resource_Type__c);
                        question.put('Resource_Type__r', childSalesLine.Resource_Type__r);
                        question.put('Resource__c', childSalesLine.Resource__c);
                        question.put('Resource__r', childSalesLine.Resource__r);
                        question.put('Description__c', childSalesLine.Description__c);
                        question.put('Unit_of_Measure__c', childSalesLine.Unit_of_Measure__c);
                        question.put('Unit_of_Measure__r', childSalesLine.Unit_of_Measure__r);
                        /*Waste001
                        question.put('Cost_Method__c', childSalesLine.Cost_Method__c);
                        question.put('Unit_Weight_Vol__c', childSalesLine.Unit_Weight_Vol__c);
                        question.put('Unit_Weight_Vol__r', childSalesLine.Unit_Weight_Vol__r);
                        question.put('Container_Size__c', childSalesLine.Container_Size__c);
                        question.put('Container_Size__r', childSalesLine.Container_Size__r);
                         */
                        question.put('Resource_Type_UOM__c', childSalesLine.Resource_Type_UOM__c);
                        question.put('Resource_Type_UOM__r', childSalesLine.Resource_Type_UOM__r);
                        question.put('Resource_UOM__c', childSalesLine.Resource_UOM__c);
                        question.put('Resource_UOM__r', childSalesLine.Resource_UOM__r);
                        question.put('Unit_Price__c', childSalesLine.Unit_Price__c);
                        question.put('xUnit_Price__c', childSalesLine.xUnit_Price__c);
                        question.put('Unit_Cost__c', childSalesLine.Unit_Cost__c);
                        question.put('xUnit_Cost__c', childSalesLine.xUnit_Cost__c);
                        question.put('Tax_Group__c', childSalesLine.Tax_Group__c);
                        question.put('Tax_Pct__c', childSalesLine.Tax_Pct__c);
                        question.put('Tax__c', childSalesLine.Tax__c);
                        question.put('Regular_Rate__c', childSalesLine.Regular_Rate__c);
                        question.put('Overtime_Rate__c', childSalesLine.Overtime_Rate__c);
                        question.put('Premium_Rate__c', childSalesLine.Premium_Rate__c);
                        question.put('xRegular_Rate__c', childSalesLine.xRegular_Rate__c);
                        question.put('xOvertime_Rate__c', childSalesLine.xOvertime_Rate__c);
                        question.put('xPremium_Rate__c', childSalesLine.xPremium_Rate__c);
                        question.put('Pricing_Source_2__c', childSalesLine.Pricing_Source_2__c);
                        question.put('Line_Amount__c', childSalesLine.Line_Amount__c);
                        question.put('xLine_Amount__c', childSalesLine.xLine_Amount__c);
                        question.put('Line_Amt_Incl_Tax__c', childSalesLine.Line_Amt_Incl_Tax__c);
                        question.put('Line_Cost__c', childSalesLine.Line_Cost__c);
                        question.put('xLine_Cost__c', childSalesLine.xLine_Cost__c);
                        question.put('Contract_Line__c', childSalesLine.Contract_Line__c);
                        question.put('Contract_Line__r', childSalesLine.Contract_Line__r);
                        question.put('Number_of_Day__c', salesOrder.Duration__c);
                        question.put('Quantity__c', childSalesLine.Quantity__c);
                        //ticket 19130 <<
                        question.put('UOM_Qty__c', childSalesLine.UOM_Qty__c);
                        //ticket 19130 >>

                        //ticket 19130 <<
                        //String questionDescription = 'Update quantity for the child resource "' + childSalesLine.Description__c + '"?';
                        String questionDescription = 'Would you like to update the Quantity for, "' + childSalesLine.Description__c + '"?';
                        //ticket 19130 >>

                        question.put('Question__c', questionDescription);
                        questions.add(question);

                        Boolean isLevel2ChildResource = false;
                        List<Object> relations = new List<Object>();
                        for (Sales_Line__c parentSalesLine : mapParentLinesByChildLineNo.get(childLineNo)) {
                            Sales_Line__c childLine = new Sales_Line__c();
                            childLine.Id = childSalesLine.Id;
                            childLine.Line_No__c = childSalesLine.Line_No__c;

                            Sales_Line__c parentLine = new Sales_Line__c();
                            parentLine.Id = parentSalesLine.Id;
                            parentLine.Line_No__c = parentSalesLine.Line_No__c;
                            parentLine.Category__c = parentSalesLine.Category__c;
                            parentLine.Resource_Type__c = parentSalesLine.Resource_Type__c;
                            parentLine.Resource_Type__r = parentSalesLine.Resource_Type__r;
                            parentLine.Resource__c = parentSalesLine.Resource__c;
                            parentLine.Resource__r = parentSalesLine.Resource__r;
                            parentLine.Description__c = parentSalesLine.Description__c;
                            parentLine.Unit_of_Measure__c = parentSalesLine.Unit_of_Measure__c;
                            parentLine.Unit_of_Measure__r = parentSalesLine.Unit_of_Measure__r;
                            parentLine.Quantity__c = parentSalesLine.Quantity__c;

                            Map<String, Object> relation = new Map<String, Object>();
                            relation.put('Child_Line__r', childLine);
                            relation.put('Parent_Line__r', parentLine);
                            relations.add(relation);

                            if (isLevel2ChildResource != true) {
                                if (parentSalesLine.Is_Child_Resource__c == true) {
                                    isLevel2ChildResource = true;
                                }
                            }
                        }
                        question.put('Level2', isLevel2ChildResource);
                        question.put('Parent_Lines__r', new Map<String, Object>{ 'records' => relations} );
                    }
                }
                if (questions.size() > 0) {
                    //sort questions by leve 1 child resources and then level 2 child resources
                    List<Map<String, Object>> orderedQuestions = new List<Map<String, Object>>();
                    for (Integer j = 0; j < questions.size(); j++) {
                        Map<String, Object> question = questions[j];
                        if (question.get('Level2') != true) {
                            orderedQuestions.add(question);
                            questions.remove(j);
                            j--;
                        }
                    }
                    orderedQuestions.addAll(questions);
                    mapQuestionsByTaskIndex.put(i, orderedQuestions); //by job task wrapper index
                }
            }
            return JSON.serialize(mapQuestionsByTaskIndex);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //ticket 19130 05.12.2023 >>

    @AuraEnabled
    public static void isValidCustomerPONumber(Id customerId, String poNumber){
        try {
            List<Account> customers = [SELECT Id, PO_Number_Type__c, Name FROM Account WHERE Id = :customerId];
            if (customers.size() > 0) {
                Account customer = customers[0];
                AccountsService.validatePONumberFormat(customer, poNumber);
            }
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    //Ticket#24650
    @AuraEnabled
    public static String validateAssumptionChange(String JSONSalesOrder) {
        try {
            Sales_Order__c salesOrder = (Sales_Order__c) JSON.deserialize(JSONSalesOrder, Sales_Order__c.class);
            SalesOrdersService.setBillingRuleForSalesOrder(salesOrder);
            List<ACVSalesOrderJobTaskWrapper> jobTaskWrappers = new List<ACVSalesOrderJobTaskWrapper>();
            ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, jobTaskWrappers);
            return JSON.serialize(salesOrderWrapper);
        }
        catch(Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    //ticket 19130 05.13.2023 <<
    private static Id getSalesLineResourceTypeIdOrResourceId(Sales_Line__c salesLine) {
        if (salesLine.Category__c == 'Labor' || salesLine.Category__c == 'Equipment' || salesLine.Category__c == 'Bundled') {
            return salesLine.Resource_Type__c;
        }
        else {
            return salesLine.Resource__c;
        }
    }
    //ticket 19130 05.13.2023 >>
    //US117390 // US117390-Defect
    public static void updateSiteAddress(Sales_Order__c salesOrder)
    {
        List<Site_Address__c> currentAlternateSiteList = [SELECT Id, Customer__c, Name, Site_Street__c, Site_City__c, Site_State__c, Site_Postal_Code__c, Site_Country__c, Contact__c, Site_Phone_No__c, Tax_Area__c, Print_Site_Name__c 
                                                          FROM Site_Address__c 
                                                          WHERE Id = :salesOrder.Alternate_Site_Address__c 
                                                          LIMIT 1];        
        if (!currentAlternateSiteList.isEmpty()) {
            Site_Address__c currentAlternateSite = currentAlternateSiteList[0];
            // Check if any relevant fields have changed
            Boolean isChanged = currentAlternateSite.Name != salesOrder.Site_Name__c || 
                currentAlternateSite.Site_Street__c != salesOrder.Site_Street__c ||
                currentAlternateSite.Site_City__c != salesOrder.Site_City__c ||
                currentAlternateSite.Site_State__c != salesOrder.Site_State__c ||
                currentAlternateSite.Site_Postal_Code__c != salesOrder.Site_Postal_Code__c ||
                currentAlternateSite.Site_Country__c != salesOrder.Site_Country__c ||
                currentAlternateSite.Site_Phone_No__c != salesOrder.Site_Phone_No__c;
            
            if (salesOrder.SO_sent_to_EQAI__c && isChanged) {
                Site_Address__c existingSite = new Site_Address__c();
                existingSite.Id = salesOrder.Alternate_Site_Address__c;
                existingSite.Name = salesOrder.Site_Name__c;
                existingSite.Site_Street__c = salesOrder.Site_Street__c;
                existingSite.Site_City__c = salesOrder.Site_City__c;
                existingSite.Site_State__c = salesOrder.Site_State__c;
                existingSite.Site_Postal_Code__c = salesOrder.Site_Postal_Code__c;
                existingSite.Site_Country__c = salesOrder.Site_Country__c;
                existingSite.Site_Contact__c = salesOrder.Site_Contact__c;
                existingSite.Contact__c = salesOrder.Site_Contact_2__c;
                existingSite.Site_Phone_No__c = salesOrder.Site_Phone_No__c;
                existingSite.Tax_Area__c = salesOrder.Tax_Area__c;
                existingSite.Print_Site_Name__c = salesOrder.Print_Site_Name__c;
                update existingSite;   
                salesOrder.Site_Address_Changed__c = true;
                update salesOrder;
            }
        }
        else
        {
            Site_Address__c newSiteAddress = New Site_Address__c();
            newSiteAddress.Customer__c = salesOrder.Bill_to_Customer_No__c;
            newSiteAddress.Name =String.isNotBlank(salesOrder.Site_Name__c)?salesOrder.Site_Name__c:salesOrder.Site_Street__c;
            newSiteAddress.Site_Street__c=salesOrder.Site_Street__c;
            newSiteAddress.Site_City__c=salesOrder.Site_City__c;
            newSiteAddress.Site_State__c =salesOrder.Site_State__c;
            newSiteAddress.Site_Postal_Code__c =salesOrder.Site_Postal_Code__c;
            newSiteAddress.Site_Country__c=salesOrder.Site_Country__c;
            newSiteAddress.Site_Contact__c = salesOrder.Site_Contact__c;
            newSiteAddress.Contact__c=salesOrder.Site_Contact_2__c;
            newSiteAddress.Site_Phone_No__c=salesOrder.Site_Phone_No__c;
            newSiteAddress.Tax_Area__c = salesOrder.Tax_Area__c;
            newSiteAddress.Print_Site_Name__c=salesOrder.Print_Site_Name__c;
            insert newSiteAddress; 
            salesOrder.Alternate_Site_Address__c =String.isNotBlank(newSiteAddress.Id)?newSiteAddress.Id:null;
            salesOrder.Site_Address_Changed__c = true;
            update salesOrder;  
        }
    }
    @AuraEnabled
    public static String getAccountData(String accountRecordId) {
        try {
            List<Id> accountExecutivesIds = new List<Id>();
            String accountExecutiveIds = '';
            Integer totalAEs;
            Integer count = 0;
            List<Account> accounts = AccountsSelector.newInstance().selectById(new Set<Id>{accountRecordId});
            
            if(accounts[0] != null && accounts[0].Account_Executive__c != null ){
                accountExecutivesIds.add(accounts[0].Account_Executive__c);
            }  
            if(accounts[0] != null && accounts[0].Account_Executive_ids__c != null ){
                //accountExecutiveIds = '\''+ accounts[0].Account_Executive_ids__c +'\'';
                accountExecutivesIds.addAll(accounts[0].Account_Executive_ids__c.split(','));
            }
                totalAEs =accountExecutivesIds.size();
            for(String ae : accountExecutivesIds){
                accountExecutiveIds = accountExecutiveIds + '\''+ ae +'\'';
                if(count < totalAEs - 1)
                    accountExecutiveIds = accountExecutiveIds + ',';
                count++;    
            }
        System.debug(JSON.serialize(accountExecutivesIds));
            return accountExecutiveIds;
            
            //return JSON.serialize(accountExecutivesIds);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
       
    }
}