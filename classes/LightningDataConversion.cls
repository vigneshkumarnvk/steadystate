public with sharing class LightningDataConversion {
    public static void updateTMStatus(Integer recordsToProcess) {
        //TM__c
        //disable lookup filter: Contact__c, Alternate_Site_Address__c, Sales_Order__c, From_Sales_Quote__c

        List<TM__c> tms;
        if (Test.isRunningTest()) { //since Received by Billing, Ready to Bill and Partially Invoiced are deactivated options. Cannot create test TM records with deactivated status.
            tms = [SELECT Status__c FROM TM__c LIMIT :recordsToProcess];
        }
        else {
            tms = [SELECT Status__c FROM TM__c WHERE Status__c = 'Received By Billing' OR Status__c = 'Ready to Bill' OR Status__c = 'Partially Invoiced' LIMIT :recordsToProcess];
        }
        if (tms.size() == 0) {
            System.debug('There are no more records.');
            return;
        }
        updateTMStatus(tms);
        system.debug('*** ' + tms.size() + ' records created/updated');
    }

    public static void createSalesOrderJobTasks(Integer recordsToProcess) {
        //Sales_Order__c
        //disable lookup filter: Bill_to_Contact__c, Alternate_Site_Address__c, Account_Executives__c, From_Sales_Quote__c
        //disable required fields: Project_Coordinator__c
        //Sales_Line__c
        //disable lookup filter: Bundle_Line__c

        List<Sales_Order__c> salesOrders = [SELECT Id, Document_Type__c, CMR_Description__c,
                (SELECT Id, Category__c, Resource__c, System_Calculated_Line__c, Sales_Order__c, Line_Amount__c, Unit_Price__c, Unit_Cost__c, Number_of_Day__c FROM Sales_Lines__r) FROM Sales_Order__c WHERE Number_of_Tasks__c = 0 LIMIT :recordsToProcess];
        if (salesOrders.size() == 0) {
            System.debug('There are no more records.');
            return;
        }
        createSalesOrderJobTasks(salesOrders);
        system.debug('*** ' + salesOrders.size() + ' records created/updated');
    }

    public static void createTMJobTasks(Integer recordsToProcess) {
        //TM__c
        //disable lookup filter: Contact__c, Alternate_Site_Address__c, Sales_Order__c, From_Sales_Quote__c

        //TM_Line__c


        List<TM__c> tms = [SELECT Id, Sales_Order__c, (SELECT Id, TM__c FROM TM_Lines__r) FROM TM__c WHERE Number_of_Tasks__c = 0 LIMIT :recordsToProcess];
        if (tms.size() == 0) {
            System.debug('There are no more records.');
            return;
        }
        createTMJobTasks(tms);

        system.debug('*** ' + tms.size() + ' records created/updated');
    }

    public static void createSalesInvoiceJobTasks(Integer recordsToProcess) {
        //Sales_Invoice__c
        //disable lookup filter: Tax_Area__c
        /*
        List<Sales_Invoice__c> salesInvoices = [SELECT Id, Sales_Order__c, (SELECT Id, Sales_Invoice__c FROM Sales_Invoice_Lines__r) FROM Sales_Invoice__c WHERE Number_of_Tasks__c = 0 LIMIT :recordsToProcess];
        if (salesInvoices.size() == 0) {
            System.debug('There are no more records.');
            return;
        }
        createSalesInvoiceJobTasks(salesInvoices);
        system.debug('*** ' + salesInvoices.size() + ' records created/updated');
        */
    }

    public static void insertEquipmentDetailLines(Integer recordsToProcess) {
        List<Sales_Line__c> salesLines = [SELECT Id, Sales_Order__c, Category__c, Resource_Type__c, Resource__c,
                Number_of_Day__c, Quantity__c, UOM_Qty__c, Unit_of_Measure__c, Bill_as_Lump_Sum__c, Non_Billable__c,
                Unit_Price__c, Unit_Cost__c, xUnit_Price__c, xUnit_Cost__c,
                System_Calculated_Line__c FROM Sales_Line__c WHERE Category__c = 'Equipment' AND Record_Updated__c != TRUE LIMIT :recordsToProcess];
        if (salesLines.size() == 0) {
            System.debug('There are no more records.');
            return;
        }
        insertEquipmentDetailLines(salesLines);
        system.debug('*** ' + salesLines.size() + ' records created/updated');
    }

    public static void createBillingWorksheetLines(Integer recordsToProcess) {
        String queryString = '';
        List<String> fieldNames;
        fieldNames = new List<String>(Schema.SObjectType.TM__c.getSObjectType().getDescribe().fields.getMap().keySet());
        queryString = 'SELECT ' + String.join(fieldNames, ' ,');
        fieldNames = new List<String>(Schema.SObjectType.TM_Line__c.getSObjectType().getDescribe().fields.getMap().keySet());
        queryString += ',(SELECT ' + String.join(fieldNames, ',') + ' FROM TM_Lines__r WHERE Invoiced__c != TRUE)';
        queryString += ' FROM TM__c WHERE (Status__c = \'Confirmed\' OR Status__c = \'Received By Billing\' OR Status__c = \'Ready to Bill\' OR Status__c = \'Partially Invoiced\') ';
        queryString += ' AND Billing_Worksheet_Line_Created__c != TRUE LIMIT ' + recordsToProcess;
        List<TM__c> tms = (List<TM__c>)Database.query(queryString);

        if (tms.size() == 0) {
            System.debug('There are no more records.');
            return;
        }
        createBillingWorksheetLines(tms);
        system.debug('*** ' + tms.size() + ' records created/updated');
    }

    public static void createTMInvoiceRelations(Integer recordsToProcess) {
        List<Sales_Invoice__c> salesInvoices = [SELECT Id, (SELECT Id, TM__c, Sales_Invoice__c FROM Sales_Invoice_Lines__r) FROM Sales_Invoice__c WHERE TM_Invoice_Relation_Created__c != TRUE LIMIT :recordsToProcess];
        if (salesInvoices.size() == 0) {
            System.debug('There are no more records.');
            return;
        }
        createTMInvoiceRelations(salesInvoices);
        system.debug('*** ' + salesInvoices.size() + ' records processed');
    }

    //----------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------
    public static void updateTMStatus(List<TM__c> tms) {
        Savepoint sp = Database.setSavepoint();
        try {
            Id confirmedRecordTypeId = Schema.SObjectType.TM__c.getRecordTypeInfosByName().get('Confirmed').getRecordTypeId();

            List<TM__c> tmsToUpdate = new List<TM__c>();
            for (TM__c tm : tms) {
                if (tm.Status__c == 'Received By Billing' || tm.Status__c == 'Ready to Bill' || tm.Status__c == 'Partially Invoiced') {
                    tm.Status__c = 'Confirmed';
                    tm.RecordTypeId = confirmedRecordTypeId;
                    tmsToUpdate.add(tm);
                }
            }
            if (tmsToUpdate.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                update tmsToUpdate;
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void createSalesOrderJobTasks(List<Sales_Order__c> salesOrders) {
        Savepoint sp = Database.setSavepoint();
        try {
            Company_Setup__c companySetup = CompanyMgmt.getCompanySetup();
            Id defaultEnergyInsuranceResourceId = companySetup.Default_Energy_Insurance_Resource__c;
            Id defaultFuelSurchargeResourceId = companySetup.Default_Fuel_Surcharge_Resource__c;

            Map<Id, Sales_Order_Job_Task__c> mapJobTasksByOrderId = new Map<Id, Sales_Order_Job_Task__c>();
            for (Sales_Order__c salesOrder : salesOrders) {
                Decimal surchargeAmount = 0;
                Decimal rollupAmount = 0;
                for (Sales_Line__c salesLine : salesOrder.Sales_Lines__r) {
                    if (salesLine.Category__c == 'Misc. Charges And Taxes' && salesLine.System_Calculated_Line__c == true && (salesLine.Resource__c == defaultEnergyInsuranceResourceId || salesLine.Resource__c == defaultFuelSurchargeResourceId)) {
                        surchargeAmount = CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                    }
                    rollupAmount += CompanyMgmt.zeroIfNull(salesLine.Line_Amount__c);
                }

                Sales_Order_Job_Task__c jobTask = new Sales_Order_Job_Task__c();
                jobTask.Sales_Order__c = salesOrder.Id;
                jobTask.Line_No__c =1;
                jobTask.Task_No__c = 1;
                jobTask.Billing_Type__c = 'T&M';

                String jobTaskName = 'Task';
                if (salesOrder.CMR_Description__c != null) {
                    jobTaskName = salesOrder.CMR_Description__c;
                    if (jobTaskName.length() > 30) {
                        jobTaskName = jobTaskName.substring(0, 29);
                    }

                    List<String> tokens = jobTaskName.split(' ');
                    for (Integer i = 0; i < tokens.size(); i++) {
                        tokens[i] = tokens[i].capitalize();
                    }
                    jobTaskName = String.join(tokens, ' ');
                }
                jobTask.Name = jobTaskName;
                jobTask.Surcharge_Amount__c = surchargeAmount;
                jobTask.Rolled_Up_Sales_Lines_Amount__c = rollupAmount;
                mapJobTasksByOrderId.put(salesOrder.Id, jobTask);
            }
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            insert mapJobTasksByOrderId.values();
            CompanyMgmt.byPassTrigger = false;
            CompanyMgmt.byPassLineTrigger = false;

            List<Sales_Line__c> salesLinesToUpdate = new List<Sales_Line__c>();
            for (Sales_Order__c salesOrder : salesOrders) {
                for (Sales_Line__c salesLine : salesOrder.Sales_Lines__r) {
                    Sales_Order_Job_Task__c jobTask = mapJobTasksByOrderId.get(salesLine.Sales_Order__c);
                    Sales_Line__c salesLineToUpdate = new Sales_Line__c();
                    salesLineToUpdate.Id = salesLine.Id;
                    salesLineToUpdate.Sales_Order_Job_Task__c = jobTask.Id;
                    salesLineToUpdate.Wizard_Question_Answered__c = true;
                    if (salesLine.Category__c == 'Materials' && (salesLine.Number_of_Day__c == null || salesLine.Number_of_Day__c == 0)) {
                        salesLineToUpdate.Number_of_Day__c = 1;
                    }
                    else if (salesLine.Category__c == 'Waste Disposal' && salesLine.System_Calculated_Line__c == true) {
                        salesLineToUpdate.xUnit_Price__c = salesLine.Unit_Price__c;
                        salesLineToUpdate.xUnit_Cost__c = salesLine.Unit_Cost__c;
                    }
                    salesLinesToUpdate.add(salesLineToUpdate);
                }
            }

            if (salesLinesToUpdate.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                update salesLinesToUpdate;
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void createTMJobTasks(List<TM__c> tms) {
        Savepoint sp = Database.setSavepoint();
        try {
            Set<Id> salesOrderIds = new Set<Id>();
            Set<Id> emTMIds = new Set<Id>();
            for (TM__c tm : tms) {
                if (tm.Sales_Order__c != null) {
                    salesOrderIds.add(tm.Sales_Order__c);
                }
                else {
                    emTMIds.add(tm.Id); //emergency TMs
                }
            }
            Map<Id, Sales_Order_Job_Task__c> mapSalesOrderJobTaskByOrderId = new Map<Id, Sales_Order_Job_Task__c>();
            for (Sales_Order_Job_Task__c salesOrderJobTask : [SELECT Id, Sales_Order__c, Name FROM Sales_Order_Job_Task__c WHERE Sales_Order__c IN :salesOrderIds]) {
                mapSalesOrderJobTaskByOrderId.put(salesOrderJobTask.Sales_Order__c, salesOrderJobTask);
            }
            Map<Id, TM_Job_Task__c> mapTMJobTaskByTMId = new Map<Id, TM_Job_Task__c>();
            for (Id tmId : emTMIds) {
                TM_Job_Task__c jobTask = new TM_Job_Task__c();
                jobTask.TM__c = tmId;
                jobTask.Line_No__c = 1;
                jobTask.Name = 'Task';
                jobTask.Billing_Type__c = 'T&M';
                mapTMJobTaskByTMId.put(jobTask.TM__c, jobTask);
            }
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            insert mapTMJobTaskByTMId.values();
            CompanyMgmt.byPassTrigger = false;
            CompanyMgmt.byPassLineTrigger = false;

            Map<Id, TM_Job_Task__c> mapJobTasksByTMId = new Map<Id, TM_Job_Task__c>();
            for (TM__c tm : tms) {
                if (tm.Sales_Order__c != null) {
                    Sales_Order_Job_Task__c salesOrderJobTask = mapSalesOrderJobTaskByOrderId.get(tm.Sales_Order__c);

                    TM_Job_Task__c jobTask = new TM_Job_Task__c();
                    jobTask.TM__c = tm.Id;
                    jobTask.Line_No__c = 1;
                    jobTask.Billing_Type__c = 'T&M';
                    jobTask.Name = salesOrderJobTask.Name;
                    jobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
                    mapJobTasksByTMId.put(TM.Id, jobTask);
                }
            }
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            insert mapJobTasksByTMId.values();
            CompanyMgmt.byPassTrigger = false;
            CompanyMgmt.byPassLineTrigger = false;

            List<TM_Line__c> tmLinesToUpdate = new List<TM_Line__c>();
            for (TM__c tm : tms) {
                for (TM_Line__c tmLine : tm.TM_Lines__r) {
                    TM_Job_Task__c jobTask;
                    if (tm.Sales_Order__c != null) {
                        jobTask = mapJobTasksByTMId.get(tmLine.TM__c);
                    }
                    else {
                        jobTask = mapTMJobTaskByTMId.get(tm.Id);
                    }
                    TM_Line__c tmLineToUpdate = new TM_Line__c();
                    tmLineToUpdate.Id = tmLine.Id;
                    tmLineToUpdate.TM_Job_Task__c = jobTask.Id;
                    tmLineToUpdate.Wizard_Question_Answered__c = true;
                    tmLinesToUpdate.add(tmLineToUpdate);
                }
            }

            if (tmLinesToUpdate.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                update tmLinesToUpdate;
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void createSalesInvoiceJobTasks(List<Sales_Invoice__c> salesInvoices) {
        Savepoint sp = Database.setSavepoint();
        try {
            Set<Id> tempSalesOrderIds = new Set<Id>();
            for (Sales_Invoice__c salesInvoice : salesInvoices) {
                if (salesInvoice.Sales_Order__c != null) {
                    tempSalesOrderIds.add(salesInvoice.Sales_Order__c);
                }
            }

            Set<Id> salesOrderIds = new Set<Id>();
            //handle partial sandbox copy issue where the source record of the lookup field is not copied
            for (Sales_Order__c salesOrder : [SELECT Id FROM Sales_Order__c WHERE Id IN :tempSalesOrderIds]) {
                salesOrderIds.add(salesOrder.Id);
            }

            Set<Id> missingSalesOrderInvoiceIds = new Set<Id>();
            for (Sales_Invoice__c salesInvoice : salesInvoices) {
                //if (salesInvoice.Sales_Order__c != null) {
                //    salesOrderIds.add(salesInvoice.Sales_Order__c);
                //}
                //else {
                //    invoiceIds.add(salesInvoice.Id);
                //}
                if (!salesOrderIds.contains(salesInvoice.Sales_Order__c)) {
                    missingSalesOrderInvoiceIds.add(salesInvoice.Id);
                }
            }
            Map<Id, Sales_Order_Job_Task__c> mapSalesOrderJobTaskByOrderId = new Map<Id, Sales_Order_Job_Task__c>();
            for (Sales_Order_Job_Task__c salesOrderJobTask : [SELECT Id, Sales_Order__c, Name FROM Sales_Order_Job_Task__c WHERE Sales_Order__c IN :salesOrderIds]) {
                mapSalesOrderJobTaskByOrderId.put(salesOrderJobTask.Sales_Order__c, salesOrderJobTask);
            }

            Map<Id, Sales_Invoice_Job_Task__c> mapJobTasksWithMissingSOByInvoiceId = new Map<Id, Sales_Invoice_Job_Task__c>();
            for (Id invoiceId : missingSalesOrderInvoiceIds) {
                Sales_Invoice_Job_Task__c jobTask = new Sales_Invoice_Job_Task__c();
                jobTask.Sales_Invoice__c = invoiceId;
                jobTask.Line_No__c = 1;
                jobTask.Name = 'Task';
                jobTask.Billing_Type__c = 'T&M';
                mapJobTasksWithMissingSOByInvoiceId.put(jobTask.Sales_Invoice__c, jobTask);
            }
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            insert mapJobTasksWithMissingSOByInvoiceId.values();
            CompanyMgmt.byPassTrigger = false;
            CompanyMgmt.byPassLineTrigger = false;

            Map<Id, Sales_Invoice_Job_Task__c> mapJobTasksByInvoiceId = new Map<Id, Sales_Invoice_Job_Task__c>();
            for (Sales_Invoice__c salesInvoice : salesInvoices) {
                //if (salesInvoice.Sales_Order__c != null) {
                if (salesOrderIds.contains(salesInvoice.Sales_Order__c)) {
                    Sales_Order_Job_Task__c salesOrderJobTask = mapSalesOrderJobTaskByOrderId.get(salesInvoice.Sales_Order__c);

                    Sales_Invoice_Job_Task__c jobTask = new Sales_Invoice_Job_Task__c();
                    jobTask.Sales_Invoice__c = salesInvoice.Id;
                    jobTask.Line_No__c = 1;
                    jobTask.Billing_Type__c = 'T&M';
                    jobTask.Name = salesOrderJobTask.Name;
                    jobTask.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
                    mapJobTasksByInvoiceId.put(salesInvoice.Id, jobTask);
                }
            }
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            insert mapJobTasksByInvoiceId.values();
            CompanyMgmt.byPassTrigger = false;
            CompanyMgmt.byPassLineTrigger = false;

            List<Sales_Invoice_Line__c> salesInvoiceLinesToUpdate = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice__c salesInvoice : salesInvoices) {
                for (Sales_Invoice_Line__c salesInvoiceLine : salesInvoice.Sales_Invoice_Lines__r) {
                    Sales_Invoice_Job_Task__c jobTask;
                    if (mapJobTasksByInvoiceId.containsKey(salesInvoice.Id)) {
                        jobTask = mapJobTasksByInvoiceId.get(salesInvoice.Id);
                    }
                    else {
                        jobTask = mapJobTasksWithMissingSOByInvoiceId.get(salesInvoice.Id);
                    }
                    Sales_Invoice_Line__c salesInvoiceLineToUpdate = new Sales_Invoice_Line__c();
                    salesInvoiceLineToUpdate.Id = salesInvoiceLine.Id;
                    salesInvoiceLineToUpdate.Sales_Invoice_Job_Task__c = jobTask.Id;
                    salesInvoiceLinesToUpdate.add(salesInvoiceLineToUpdate);
                }
            }

            if (salesInvoiceLinesToUpdate.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                update salesInvoiceLinesToUpdate;
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void insertEquipmentDetailLines(List<Sales_Line__c> salesLines) {
        Savepoint sp = Database.setSavepoint();
        try {
            Set<Id> salesOrderIds = new Set<Id>();
            for (Sales_Line__c salesLine : salesLines) {
                salesOrderIds.add(salesLine.Sales_Order__c);
            }
            Map<Id, Sales_Order__c> mapSalesOrdersById = new Map<Id, Sales_Order__c>();
            for (Sales_Order__c salesOrder : [SELECT Id, Estimated_Job_Start_Date__c, Estimated_Job_End_Date__c, Estimated_Job_Start_Time__c, Estimated_Job_End_Time__c FROM Sales_Order__c WHERE Id IN :salesOrderIds]) {
                mapSalesOrdersById.put(salesOrder.Id, salesOrder);
            }

            List<Sales_Line__c> salesLinesToUpdate = new List<Sales_Line__c>();
            List<Sales_Line_Detail__c> salesLineDetails = new List<Sales_Line_Detail__c>();
            for (Sales_Line__c salesLine : salesLines) {
                if (salesLine.Category__c == 'Equipment') {
                    Sales_Order__c salesOrder = mapSalesOrdersById.get(salesLine.Sales_Order__c);

                    Date scheduledDate = salesOrder.Estimated_Job_Start_Date__c;
                    for (Integer i = 0; i < salesLine.Number_of_Day__c.intValue(); i++) {
                        Sales_Line_Detail__c salesLineDetail = new Sales_Line_Detail__c();
                        salesLineDetail.Sales_Line__c = salesLine.Id;
                        salesLineDetail.Line_Number__c = (i + 1);
                        salesLineDetail.Scheduled_Date__c = scheduledDate;
                        salesLineDetail.Quantity__c = salesLine.Quantity__c;
                        salesLineDetail.UOM_Qty__c = salesLine.UOM_Qty__c;
                        salesLineDetail.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
                        salesLineDetail.Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
                        salesLineDetail.End_Time__c = salesOrder.Estimated_Job_End_Time__c;
                        if (salesLine.Bill_as_Lump_Sum__c == true || salesLine.Non_Billable__c == true) {
                            salesLineDetail.Unit_Price__c = CompanyMgmt.zeroIfNull(salesLine.xUnit_Price__c);
                            salesLineDetail.Unit_Cost__c = CompanyMgmt.zeroIfNull(salesLine.xUnit_Cost__c);
                        }
                        else {
                            salesLineDetail.Unit_Price__c = CompanyMgmt.zeroIfNull(salesLine.Unit_Price__c);
                            salesLineDetail.Unit_Cost__c = CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c);
                        }
                        salesLineDetail.Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c * salesLineDetail.Unit_Price__c);
                        salesLineDetail.Line_Cost__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c * salesLineDetail.Unit_Cost__c);
                        salesLineDetails.add(salesLineDetail);

                        scheduledDate = scheduledDate.addDays(1);
                    }

                    salesLine.Record_Updated__c = true;
                    salesLinesToUpdate.add(salesLine);
                }
            }

            if (salesLinesToUpdate.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                update salesLinesToUpdate;
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }

            if (salesLineDetails.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                insert salesLineDetails;
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void createBillingWorksheetLines(List<TM__c> tms) {
        Savepoint sp = Database.setSavepoint();
        Company_Setup__c companySetup = CompanyMgmt.getCompanySetup();
        Id energyInsuranceResourceId = companySetup.Default_Energy_Insurance_Resource__c;
        Id fuelSurchargeResourceId = companySetup.Default_Fuel_Surcharge_Resource__c;
        try {
            Set<Id> tmIds = new Set<Id>();
            for (TM__c tm : tms) {
                tmIds.add(tm.Id);
            }
            Map<Id, TM_Job_Task__c> mapTMJobTasksByTMId = new Map<Id, TM_Job_Task__c>();
            for (TM_Job_Task__c jobTask : [SELECT Id, TM__c, Sales_Order_Job_Task__c FROM TM_Job_Task__c WHERE TM__c IN :tmIds]) {
                mapTMJobTasksByTMId.put(jobTask.TM__c, jobTask);
            }

            Map<Id, Integer> mapNextLineNosByOrderId = new Map<Id, Integer>();
            for (TM__c tm : tms) {
                if (!mapNextLineNosByOrderId.containsKey(tm.Sales_Order__c)) {
                    mapNextLineNosByOrderId.put(tm.Sales_Order__c, 1);
                }
            }

            //handle missing source record in partial sandbox
            //sandbox <<
            Set<Id> tempSalesLineIds = new Set<Id>();
            Set<Id> tempQuoteLineIds = new Set<Id>();
            Set<Id> tempSalesBundleLineIds = new Set<Id>();
            Set<Id> tempContractLineIds = new Set<Id>();
            for (TM__c tm : tms) {
                if (tm.Status__c == 'Confirmed') {
                    for (TM_Line__c tmLine : tm.TM_Lines__r) {
                        if (tmLine.Invoiced__c != true) {
                            if (tmLine.Sales_Line__c != null) {
                                tempSalesLineIds.add(tmLine.Sales_Line__c);
                            }
                            if (tmLine.Sales_Bundle_Line__c != null) {
                                tempSalesBundleLineIds.add(tmLine.Sales_Bundle_Line__c);
                            }
                            if (tmLine.Quote_Line__c != null) {
                                tempQuoteLineIds.add(tmLine.Quote_Line__c);
                            }
                            if (tmLine.Contract_Line__c != null) {
                                tempContractLineIds.add(tmLine.Contract_Line__c);
                            }
                        }
                    }
                }
            }
            Set<Id> validSalesLineIds = new Set<Id>();
            for (Sales_Line__c salesLine : [SELECT Id FROM Sales_Line__c WHERE Id IN : tempSalesLineIds OR Id IN :tempQuoteLineIds OR Id IN :tempSalesBundleLineIds]) {
                validSalesLineIds.add(salesLine.Id);
            }
            Set<Id> validContractLineIds = new Set<Id>();
            for (Contract_Line__c contractLine : [SELECT Id FROM Contract_Line__c WHERE Id IN :tempContractLineIds]) {
                validContractLineIds.add(contractLine.Id);
            }
            //sandbox >>

            List<TM__c> tmsToUpdate = new List<TM__c>();
            Map<Id, Billing_Worksheet_Line__c> mapWorksheetLinesByTMLineId = new Map<Id, Billing_Worksheet_Line__c>();
            for (TM__c tm : tms) {
                if (tm.Status__c == 'Confirmed') {
                    for (TM_Line__c tmLine : tm.TM_Lines__r) {
                        if (tmLine.Invoiced__c != true) {
                            if (tmLine.System_Calculated_Line__c != true && tmLine.Category__c != 'Misc. Charges And Taxes'
                                    && tmLine.Resource__c != energyInsuranceResourceId
                                    && tmLine.Resource__c != fuelSurchargeResourceId) {

                                TM_Job_Task__c tmJobTask = mapTMJobTasksByTMId.get(tm.Id);
                                if (tmJobTask.Sales_Order_Job_Task__c != null) {
                                    Integer nextLineNo = mapNextLineNosByOrderId.get(tm.Sales_Order__c);

                                    Billing_Worksheet_Line__c worksheetLine = new Billing_Worksheet_Line__c();
                                    worksheetLine.Line_No__c = nextLineNo;
                                    worksheetLine.TM__c = tm.Id;
                                    worksheetLine.TM_Job_Task__c = tmJobTask.Id;
                                    worksheetLine.TM_Line__c = tmLine.Id;
                                    worksheetLine.Sales_Order__c = tm.Sales_Order__c;
                                    worksheetLine.Sales_Order_Job_Task__c = tmJobTask.Sales_Order_Job_Task__c;
                                    worksheetLine.Category__c = tmLine.Category__c;
                                    worksheetLine.Service_Center__c = tmLine.Service_Center__c;
                                    worksheetLine.Resource_Type__c = tmLine.Resource_Type__c;
                                    worksheetLine.Resource__c = tmLine.Resource__c;
                                    worksheetLine.Resource_Name__c = tmLine.Resource_Name__c;
                                    worksheetLine.Resource_Type_UOM__c = tmLine.Resource_Type_UOM__c;
                                    worksheetLine.Resource_UOM__c = tmLine.Resource_UOM__c;
                                    worksheetLine.Description__c = tmLine.Description__c;
                                    worksheetLine.Quantity__c = tmLine.Quantity__c;
                                    worksheetLine.Unit_of_Measure__c = tmLine.Unit_of_Measure__c;
                                    worksheetLine.Cost_Method__c = tmLine.Cost_Method__c;
                                    worksheetLine.Unit_Weight_Vol__c = tmLine.Unit_Weight_Vol__c;
                                    worksheetLine.Container_Size__c = tmLine.Container_Size__c;
                                    //sandbox <<
                                    if (validContractLineIds.contains(tmLine.Contract_Line__c)) {
                                        worksheetLine.Contract_Line__c = tmLine.Contract_Line__c;
                                    }
                                    worksheetLine.Facility__c = tmLine.Facility__c;
                                    worksheetLine.BOL_Manifest__c = tmLine.BOL_Manifest__c;
                                    worksheetLine.Tax_Group__c = tmLine.Tax_Group__c;
                                    worksheetLine.Tax_Pct__c = tmLine.Tax_Pct__c;
                                    worksheetLine.Fleet_No_Required__c = tmLine.Fleet_No_Required__c;
                                    worksheetLine.Fleet_No__c = tmLine.Fleet_No__c;

                                    worksheetLine.System_Calculated_Line__c = tmLine.System_Calculated_Line__c;
                                    worksheetLine.Flat_Pay_Line__c = tmLine.Flat_Pay_Line__c;
                                    //sandbox <<
                                    if (validSalesLineIds.contains(tmLine.Sales_Line__c)) {
                                        worksheetLine.Sales_Line__c = tmLine.Sales_Line__c;
                                    }
                                    //sandbox <<
                                    if (validSalesLineIds.contains(tmLine.Quote_Line__c)) {
                                        worksheetLine.Quote_Line__c = tmLine.Quote_Line__c;
                                    }
                                    //sandbox <<
                                    if (validSalesLineIds.contains(tmLine.Sales_Bundle_Line__c)) {
                                        worksheetLine.Sales_Bundle_Line__c = tmLine.Sales_Bundle_Line__c;
                                    }
                                    worksheetLine.TM_Parent_Line__c = tmLine.Parent_Line__c;
                                    worksheetLine.Regular_Hours__c = tmLine.Regular_Hours__c;
                                    worksheetLine.Overtime_Hours__c = tmLine.Overtime_Hours__c;
                                    worksheetLine.Premium_Hours__c = tmLine.Premium_Hours__c;
                                    worksheetLine.Regular_Rate__c = tmLine.Regular_Rate__c;
                                    worksheetLine.Overtime_Rate__c = tmLine.Overtime_Rate__c;
                                    worksheetLine.Premium_Rate__c = tmLine.Premium_Rate__c;
                                    worksheetLine.xRegular_Rate__c = tmLine.xRegular_Rate__c;
                                    worksheetLine.xOvertime_Rate__c = tmLine.xOvertime_Rate__c;
                                    worksheetLine.xPremium_Rate__c = tmLine.xPremium_Rate__c;
                                    worksheetLine.Contract_Regular_Rate__c = tmLine.Contract_Regular_Rate__c;
                                    worksheetLine.Contract_Overtime_Rate__c = tmLine.Contract_Overtime_Rate__c;
                                    worksheetLine.Contract_Premium_Rate__c = tmLine.Contract_Premium_Rate__c;
                                    worksheetLine.Overtime__c = tmLine.Overtime__c;
                                    worksheetLine.Job_Start_Time__c = tmLine.Job_Start_Time__c;
                                    worksheetLine.Job_End_Time__c = tmLine.Job_End_Time__c;
                                    worksheetLine.Site_Start_Time__c = tmLine.Site_Start_Time__c;
                                    worksheetLine.Site_End_Time__c = tmLine.Site_End_Time__c;
                                    worksheetLine.Lunch_Start_Time__c = tmLine.Lunch_Start_Time__c;
                                    worksheetLine.Lunch_End_Time__c = tmLine.Lunch_End_Time__c;
                                    worksheetLine.Include_Lunch_Y_N__c = tmLine.Include_Lunch_Y_N__c;
                                    worksheetLine.Billing_Start_Time__c = tmLine.Billing_Start_Time__c;
                                    worksheetLine.Billing_End_Time__c = tmLine.Billing_End_Time__c;
                                    worksheetLine.Total_Job_Hours__c = tmLine.Total_Job_Hours__c;
                                    worksheetLine.Total_Site_Hours__c = tmLine.Total_Site_Hours__c;
                                    worksheetLine.Hour__c = tmLine.Hour__c;

                                    worksheetLine.Unit_Price__c = tmLine.Unit_Price__c;
                                    worksheetLine.xUnit_Price__c = tmLine.xUnit_Price__c;
                                    worksheetLine.Unit_Cost__c = tmLine.Unit_Cost__c;
                                    worksheetLine.Bill_as_Lump_Sum__c = tmLine.Bill_as_Lump_Sum__c;
                                    worksheetLine.Non_Billable__c = tmLine.Non_Billable__c;
                                    worksheetLine.Pricing_Source_2__c = tmLine.Pricing_Source_2__c;
                                    worksheetLine.Min_Sell_Qty__c = tmLine.Min_Sell_Qty__c;
                                    worksheetLine.Markup_Option__c = tmLine.Markup_Option__c;
                                    worksheetLine.Markup__c = tmLine.Markup__c;
                                    worksheetLine.Cost_Qty__c = tmLine.Cost_Qty__c;
                                    worksheetLine.Cost_Unit_of_Measure__c = tmLine.Cost_Unit_of_Measure__c;
                                    worksheetLine.Drop_Off_R_O__c = tmLine.Drop_Off_R_O__c;
                                    worksheetLine.Drop_Off_Rental__c = tmLine.Drop_Off_Rental__c;
                                    worksheetLine.Price_O_W_Reason__c = tmLine.Price_OW_Reason__c;
                                    worksheetLine.Rent_Billing_Amount__c = tmLine.Rent_Billing_Amount__c;
                                    worksheetLine.Rent_Billing_Type__c = tmLine.Rent_Billing_Type__c;
                                    worksheetLine.Rental_Allowed__c = tmLine.Rental_Allowed__c;

                                    worksheetLine.Fuel_Surcharge__c = tmLine.Fuel_Surcharge__c;
                                    worksheetLine.Line_Cost__c = tmLine.Line_Cost__c;
                                    worksheetLine.xLine_Cost__c = tmLine.Line_Cost__c;
                                    worksheetLine.Line_Amount__c = tmLine.Line_Amount__c;
                                    worksheetLine.xLine_Amount__c = tmLine.Line_Amount__c;
                                    worksheetLine.Tax__c = tmLine.Tax__c;
                                    worksheetLine.Line_Amt_Incl_Tax__c = tmLine.Line_Amt_Incl_Tax__c;

                                    worksheetLine.Wizard_Question_Answered__c = true;
                                    mapWorksheetLinesByTMLineId.put(tmLine.Id, worksheetLine);

                                    mapNextLineNosByOrderId.put(tm.Sales_Order__c, nextLineNo + 1);
                                }
                            }
                        }
                    }
                }
                TM__c tmToUpdate = new TM__c();
                tmToUpdate.Id = tm.Id;
                tmToUpdate.Billing_Worksheet_Line_Created__c = true;
                tmsToUpdate.add(tmToUpdate);
            }


            if (mapWorksheetLinesByTMLineId.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                insert mapWorksheetLinesByTMLineId.values();
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }

            if (tmsToUpdate.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                update tmsToUpdate;
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }

            List<TM_Line__c> tmLinesToUpdate = new List<TM_Line__c>();
            for (TM__c tm : tms) {
                for (TM_Line__c tmLine : tm.TM_Lines__r) {
                    if (mapWorksheetLinesByTMLineId.containsKey(tmLine.Id)) {
                        Billing_Worksheet_Line__c worksheetLine = mapWorksheetLinesByTMLineId.get(tmLine.Id);
                        tmLine.Billing_Worksheet_Line__c = worksheetLine.Id;
                        tmLinesToUpdate.add(new TM_Line__c(Id = tmLine.Id, Billing_Worksheet_Line__c = worksheetLine.Id));
                    }
                }
            }
            if (tmLinesToUpdate.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = false;
                update tmLinesToUpdate;
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static void createTMInvoiceRelations(List<Sales_Invoice__c> salesInvoices) {
        Savepoint sp = Database.setSavepoint();
        try {
            List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
            for (Sales_Invoice__c salesInvoice : salesInvoices) {
                salesInvoiceLines.addAll(salesInvoice.Sales_Invoice_Lines__r);
                salesInvoice.TM_Invoice_Relation_Created__c = true;
            }
            SalesInvoiceTriggersMgmt.updateTMInvoiceRelations(salesInvoiceLines);
            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.byPassLineTrigger = true;
            update salesInvoices;
            CompanyMgmt.byPassTrigger = false;
            CompanyMgmt.byPassLineTrigger = false;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
}