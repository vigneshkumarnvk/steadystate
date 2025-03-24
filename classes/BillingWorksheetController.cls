/*************************************************************************************************
* Name         :  BillingWorksheetController
* Description  :  Apex Class invoked on BillingWorksheet flow
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      12-06-2023             Task73775: Salesforce - Remove Invoice Workflow from Service Centers when selected as "Include Sales Orders in EQAI Invoice Integration"
Shahwaz Khan              16-05-2024             Task85892: Salesforce - Logic for MSG, Retail, National Accounts, US Ecology Internal Account.
Andrew Simons             06-12-2024             Salesforce - added method for retrieving resource custom metadata
Andrew Simons             07-25-2024             Salesforce - removed logic for MSG/Retail/National Accounts - part 1
Sanjana Ravichandran      10/15/2024             US128542: [Unplanned] SF - Profile approval lookup not on the billing worksheet T&M
Pavithra Periyasamy       15-10-2024             US128849: [Unplanned] Salesforce - Move Disposal validation to creation of billing worksheet
* Prabhu Rathakrishnan      10-22-2024             US126260   Salesforce - Reflect NA/MSG/Retail and Prevent BP flag in Salesforce account
* Shahwaz Khan              10/30/2024             US129137: Disposal UOM on SF disposal line(s) must align to selected profile approval 
* Prabhu Rathakrishnan      11-12-2024			 US131092: Salesforce - Add "Disposal Billing Method" field to Sales Lines level
* Sanjana Ravichandran		21/11/2024 			US129137: Disposal UOM on SF disposal line(s) must align to selected profile approval 
* Prabhu Rathakrishnan     11-25-2024           US131817 Salesforce - Only consider "Prevent Billing Project" for creation of new billing project (remove NA, Retail, MSG, Intercompany considerations)
  Shahwaz Khan              01-28-2024             US138859 Unable to save billing worksheet when a waste disposal line is added (non Adv Disposal Service Center)
* Vignesh Kumar				02-04-2025			   DE37758: (Unplanned) SF Case 124357, CLIN Length Error but CLIN Description is within character limitations
*************************************************************************************************/
public with sharing class BillingWorksheetController {
    public static Boolean ByPassTrigger { set; get; }
    
    @AuraEnabled
    public static String getSetupData(Id salesOrderId) {
        try {
            BillingWorksheetSetupData setupData = new BillingWorksheetSetupData(salesOrderId);
            return JSON.serialize(setupData);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /*
*  Ticket#21357 - add bill-to contact to the query.
*  Ticket#20496 - add billing rule - Enable Weekly Total Calculation
*/
    @AuraEnabled
    public static String getSalesOrder(Id salesOrderId) {
        try {
            Sales_Order__c salesOrder = [SELECT Id, Name, Bill_to_Customer_No__r.Name, Manifest_And_Profile__c,Disposal_Billing_Method__c,
                                         Contract__c, Tax_Area__c, Tax_Liable__c, Billing_Rule_Not_Required__c, Bill_to_Contact__r.Blocked__c,
                                         Billing_Rule__c, Billing_Rule__r.Enable_Weekly_Total_Calculation__c,
                                         Contract__r.Billing_Rule__c, Contract__r.Billing_Rule__r.Enable_Weekly_Total_Calculation__c,Service_Center__r.Advanced_Disposal__c,Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c
                                         FROM Sales_Order__c WHERE Id = :salesOrderId LIMIT 1];
            return JSON.serialize(salesOrder);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    /*
*  Ticket#24560 - add Operating_Expense_Cost_Pct__c field to Sales Order Job Task query.
*/
    @AuraEnabled
    public static String getUnbilledTasks(Id salesOrderId) {
        try {
            Set<Id> salesOrderIds = new Set<Id>{ salesOrderId };
                List<Sales_Order_Job_Task__c> salesOrderJobTasks = [SELECT Id,Sales_Order__r.Operating_Expense_Cost_Pct__c,
                                                                    (SELECT Id, TM__c, TM__r.Name, Sales_Order_Job_Task__c FROM TM_Job_Tasks__r WHERE TM__r.Status__c = 'Confirmed'),
                                                                    (SELECT Id, Category__c,Disposal_Billing_Method__c,TM__r.Sales_Order__r.Disposal_Billing_Method__c FROM Billing_Worksheet_Lines__r WHERE Invoiced__c != TRUE LIMIT 1)
                                                                    FROM Sales_Order_Job_Task__c WHERE Sales_Order__c = :salesOrderId];
            
            
            Set<Id> tmIds = new Set<Id>();
            Set<Id> salesOrderJobTaskIds = new Set<Id>();
            Set<Id> tmJobTaskIds= new Set<Id>();
            Set<String> fieldTMPDFNames = new Set<String>();
            for (Sales_Order_Job_Task__c salesOrderJobTask : salesOrderJobTasks) {
                Boolean hasLinesToBill = false;
                for (Billing_Worksheet_Line__c worksheetLine : salesOrderJobTask.Billing_Worksheet_Lines__r) {
                    //if (worksheetLine.Category__c != 'Lump Sum') {
                    hasLinesToBill = true;
                    break;
                    //}
                }
                
                if (!hasLinesToBill) continue;
                
                salesOrderJobTaskIds.add(salesOrderJobTask.Id);
                for (TM_Job_Task__c tmJobTask : salesOrderJobTask.TM_Job_Tasks__r) {
                    if (tmJobTask.Sales_Order_Job_Task__c == salesOrderJobTask.Id) {
                        tmIds.add(tmJobTask.TM__c);
                        tmJobTaskIds.add(tmJobTask.Id);
                        fieldTMPDFNames.add(tmJobTask.TM__r.Name + '%.pdf');
                    }
                }
            }
            
            //create wrappers
            Map<Id, BillingWorksheetWrapper> mapWorksheetsBySalesOrderJobTaskId =  new Map<Id, BillingWorksheetWrapper>();
            for (Sales_Order_Job_Task__c salesOrderJobTask : SalesOrderJobTasksSelector.newInstance().selectById(salesOrderJobTaskIds)) {
                BillingWorksheetWrapper worksheetWrapper = new BillingWorksheetWrapper();
                mapWorksheetsBySalesOrderJobTaskId.put(salesOrderJobTask.Id, worksheetWrapper);
                worksheetWrapper.SalesOrderJobTask = salesOrderJobTask;
            }
            
            //get lump sum lines by Sales Order Job Task Id
            for (Sales_Line__c lumpSumLine : SalesLinesSelector.newInstance().selectByCategories(salesOrderIds, new Set<String>{ 'Bundled' }, null)) {
                if (mapWorksheetsBySalesOrderJobTaskId.containsKey(lumpSumLine.Sales_Order_Job_Task__c)) {
                    BillingWorksheetWrapper worksheetWrapper = mapWorksheetsBySalesOrderJobTaskId.get(lumpSumLine.Sales_Order_Job_Task__c);
                    worksheetWrapper.LumpSumLines.add(lumpSumLine);
                }
            }
            
            //System.debug('**** tmIds: ' + JSON.serialize(tmIds));
            /*
//get Field TM PDF by Sales Order Job Task Id
for (TM__c tm : [SELECT Id, Name,
(SELECT Id, Sales_Order_Job_Task__c FROM TM_Job_Tasks__r),
(SELECT Id, Name FROM Attachments WHERE Name LIKE :fieldTMPDFNames ORDER BY CreatedDate DESC),
(SELECT Id, TM_Job_Task__c, TM_Job_Task__r.Sales_Order_Job_Task__c FROM TM_Lines__r WHERE Invoiced__c != TRUE)
FROM TM__c WHERE Id IN :tmIds AND Status__c != 'Fully Invoiced']) {
for (TM_Job_Task__c tmJobTask : tm.TM_Job_Tasks__r) {
Integer invoiceLineCount = 0;
for (TM_Line__c tmLine : tm.TM_Lines__r) {
if (tmLine.TM_Job_Task__c == tmJobTask.Id) {
invoiceLineCount++;
}
}

//if (invoiceLineCount > 0) {
if (mapWorksheetsBySalesOrderJobTaskId.containsKey(tmJobTask.Sales_Order_Job_Task__c)) {
BillingWorksheetWrapper worksheetWrapper = mapWorksheetsBySalesOrderJobTaskId.get(tmJobTask.Sales_Order_Job_Task__c);
BillingWorksheetWrapper.RelatedInfo relatedInfo = new BillingWorksheetWrapper.RelatedInfo();
relatedInfo.TM = tm;
if (tm.Attachments.size() > 0) {
relatedInfo.FieldTMPDFUrl = '/servlet/servlet.FileDownload?file=' + tm.Attachments[0].Id;
}
worksheetWrapper.RelatedInfos.add(relatedInfo);
}
//}
}
}*/
            
            Map<Id, Attachment> mapAttachmentsByTMId = new Map<Id, Attachment>();
            for (Attachment attachment : [SELECT Id, Name, ParentId FROM Attachment WHERE Name LIKE :fieldTMPDFNames AND ParentId IN :tmIds ORDER BY CreatedDate DESC]) {
                if (!mapAttachmentsByTMId.containsKey(attachment.ParentId)) {
                    mapAttachmentsByTMId.put(attachment.ParentId, attachment);
                }
            }
            
            for (TM_Job_Task__c tmJobTask : [SELECT Id, Line_No__c, Name, Billing_Type__c,
                                             Sales_Order_Job_Task__c, Sales_Order_Job_Task__r.Name, Sales_Order_Job_Task__r.Task_No__c, Sales_Order_Job_Task__r.Line_No__c,
                                             TM__c, TM__r.Name, TM__r.Scheduled_Date__c,
                                             (SELECT Id, Billing_Worksheet_Line__r.To_Invoice__c FROM T_M_Lines__r WHERE Billing_Worksheet_Line__r.Invoiced__c != TRUE ORDER BY Billing_Worksheet_Line__r.To_Invoice__c DESC NULLS LAST LIMIT 1) FROM TM_Job_Task__c WHERE TM__c IN :tmIds]) {
                                                 if (tmJobTask.T_M_Lines__r.size() > 0) {
                                                     if (mapWorksheetsBySalesOrderJobTaskId.containsKey(tmJobTask.Sales_Order_Job_Task__c)) {
                                                         BillingWorksheetWrapper worksheetWrapper = mapWorksheetsBySalesOrderJobTaskId.get(tmJobTask.Sales_Order_Job_Task__c);
                                                         BillingWorksheetWrapper.RelatedInfo relatedInfo = new BillingWorksheetWrapper.RelatedInfo();
                                                         relatedInfo.TM = tmJobTask.TM__r;
                                                         relatedInfo.TMJobTask = new TM_Job_Task__c(Id = tmJobTask.Id, Name = tmJobTask.Name, Sales_Order_Job_Task__c = tmJobTask.Sales_Order_Job_Task__c, Sales_Order_Job_Task__r = tmJobTask.Sales_Order_Job_Task__r);
                                                         if (mapAttachmentsByTMId.containsKey(relatedInfo.TM.Id)) {
                                                             Attachment attachment = mapAttachmentsByTMId.get(relatedInfo.TM.Id);
                                                             relatedInfo.FieldTMPDFUrl = '/servlet/servlet.FileDownload?file=' + attachment.Id;
                                                         }
                                                         relatedInfo.HasToInvoiceLines = tmJobTask.T_M_Lines__r[0].Billing_Worksheet_Line__r.To_Invoice__c;
                                                         worksheetWrapper.RelatedInfos.add(relatedInfo);
                                                     }
                                                 }
                                             }
            
            return JSON.serialize(mapWorksheetsBySalesOrderJobTaskId.values());
        } catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static Integer getNextWorksheetLineNo(Id salesOrderId) {
        try {
            Integer nextWorksheetLineNo = 0;
            List<AggregateResult> results = [SELECT MAX(Line_No__c) LineNo FROM Billing_Worksheet_Line__c WHERE Sales_Order__c = :salesOrderId];
            if (results[0].get('LineNo') != null) {
                nextWorksheetLineNo = ((Decimal)results[0].get('LineNo')).intValue();
            }
            nextWorksheetLineNo++;
            return nextWorksheetLineNo;
        } catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getCostPlusMESResourceId() {
        ResourceConfig__mdt config = [SELECT Value__c FROM ResourceConfig__mdt WHERE DeveloperName = 'CostPlusMESResourceId' LIMIT 1];
        return config.Value__c;
    }
    
    /* Not used
private static Integer getNextWorksheetLineNo(List<BillingWorksheetWrapper> worksheetWrappers) {
Integer nextWorksheetLineNo = 0;
for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
if (worksheetLine.Line_No__c.intValue() > nextWorksheetLineNo) {
nextWorksheetLineNo = worksheetLine.Line_No__c.intValue();
}
}
}
nextWorksheetLineNo++;
return nextWorksheetLineNo;
}
*/
    
    @AuraEnabled
    public static String getWorksheet(Id salesOrderId, Id salesOrderJobTaskId, Boolean queryFewerFields) {
        try {
            Set<Id> salesOrderJobTaskIds = new Set<Id>{ salesOrderJobTaskId };
                salesOrderJobTaskIds.add(salesOrderJobTaskId);
            List<BillingWorksheetWrapper> worksheetWrappers = getWorksheets(salesOrderJobTaskIds, null, queryFewerFields);
            BillingWorksheetWrapper worksheetWrapper;
            if (worksheetWrappers.size() > 0) {
                worksheetWrapper = worksheetWrappers[0];
            }
            
            return JSON.serialize(worksheetWrapper);
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String getWorksheetLines(Id salesOrderId, Id salesOrderJobTaskId, Id tmId, Boolean queryFewerFields) {
        try {
            Set<Id> salesOrderJobTaskIds = new Set<Id>{ salesOrderJobTaskId };
                salesOrderJobTaskIds.add(salesOrderJobTaskId);
            
            //ticket 20830 <<
            //List<BillingWorksheetWrapper> worksheetWrappers = getWorksheets(salesOrderJobTaskIds, new Set<Id>{ tmId }, queryFewerFields);
            Set<Id> tmIds = new Set<Id>();
            tmIds.add(tmId);
            
            //find TMs that have lines are bundled or bundling the selected TM's lines
            Map<Id, List<Billing_Worksheet_Line__c>> mapWorksheetLinesByTMId = new Map<Id, List<Billing_Worksheet_Line__c>>();
            for (Billing_Worksheet_Line__c worksheetLine : [SELECT Id, Category__c, TM__c, Bundle_Line__c, Bundle_Line__r.TM__c, Invoiced__c,Disposal_Billing_Method__c,Sales_Order__r.Disposal_Billing_Method__c
                                                            FROM Billing_Worksheet_Line__c
                                                            WHERE Sales_Order__c = :salesOrderId AND Sales_Order_Job_Task__c = :salesOrderJobTaskId
                                                            AND Invoiced__c != TRUE AND (Category__c = 'Bundled' OR Bundle_Line__c != NULL)]) {
                                                                List<Billing_Worksheet_Line__c> worksheetLines;
                                                                if (mapWorksheetLinesByTMId.containsKey(worksheetLine.TM__c)) {
                                                                    worksheetLines = mapWorksheetLinesByTMId.get(worksheetLine.TM__c);
                                                                }
                                                                else {
                                                                    worksheetLines = new List<Billing_Worksheet_Line__c>();
                                                                    mapWorksheetLinesByTMId.put(worksheetLine.TM__c, worksheetLines);
                                                                }
                                                                worksheetLines.add(worksheetLine);
                                                            }
            if (mapWorksheetLinesByTMId.size() > 0) {
                getTMIdsOfBundledLines(tmId, tmIds, mapWorksheetLinesByTMId);
            }
            
            List<BillingWorksheetWrapper> worksheetWrappers = getWorksheets(salesOrderJobTaskIds, tmIds, queryFewerFields);
            //ticket 20830 >>
            
            BillingWorksheetWrapper worksheetWrapper;
            if (worksheetWrappers.size() > 0) {
                worksheetWrapper = worksheetWrappers[0];
            }
            
            return JSON.serialize(worksheetWrapper);
        }
        catch (exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //ticket 20830 <<
    private static void getTMIdsOfBundledLines(Id tmId, Set<Id> tmIds, Map<Id, List<Billing_Worksheet_Line__c>> mapBillingWorksheetLinesByTMId) {
        if(mapBillingWorksheetLinesByTMId.containsKey(tmId)) { //Ticket#23789
            List<Billing_Worksheet_Line__c> worksheetLines = mapBillingWorksheetLinesByTMId.get(tmId);
            for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
                if (worksheetLine.TM__c == tmId && worksheetLine.Invoiced__c != true) { //use Invoiced__c to check off processed lines
                    tmIds.add(worksheetLine.TM__c);
                    worksheetLine.Invoiced__c = true;
                    
                    if (worksheetLine.Category__c == 'Bundled') {
                        getTMIdsOfBundledLines(worksheetLine.TM__c, tmIds, mapBillingWorksheetLinesByTMId);
                    } else if (worksheetLine.Bundle_Line__c != null) {
                        getTMIdsOfBundledLines(worksheetLine.Bundle_Line__r.TM__c, tmIds, mapBillingWorksheetLinesByTMId);
                    }
                }
            }
        }
    }
    //ticket 20830 >>
    
    private static List<BillingWorksheetWrapper> getWorksheets(Set<Id> salesOrderJobTaskIds, Set<Id> tmIds, Boolean queryFewerFields) {
        Map<Id, BillingWorksheetWrapper> mapWorksheetWrappersBySalesOrderTaskId = new Map<Id, BillingWorksheetWrapper>();
        List<Sales_Order_Job_Task__c> salesOrderJobTasks = SalesOrderJobTasksSelector.newInstance().selectById(salesOrderJobTaskIds);
        //List<Billing_Worksheet_Line__c> worksheetLines = BillingWorksheetLinesSelector.newInstance().selectBySalesOrderJobTaskId(salesOrderJobTaskIds, new List<String>{ 'Invoiced__c != TRUE' });
        
        List<String> filters = new List<String>();
        filters.add('Invoiced__c != TRUE');
        List<String> filters2 = new List<String>();
        if (tmIds != null) {
            for (Id tmId : tmIds) {
                filters2.add('TM__c = \'' + tmId + '\'');
            }
        }
        if (filters2.size() > 0) {
            filters.add('(' + String.join(filters2, ' OR ') + ')');
        }
        //List<Billing_Worksheet_Line__c> worksheetLines = BillingWorksheetLinesSelector.newInstance().selectBySalesOrderJobTaskId(salesOrderJobTaskIds, filters);
        List<Billing_Worksheet_Line__c> worksheetLines;
        if (queryFewerFields == true) {
            List<String> fields = new List<String>();
            fields.add('Id');
            fields.add('Name');
            fields.add('Line_No__c');
            fields.add('Category__c');
            fields.add('Resource_Type__c');
            fields.add('Resource_Type__r.Name');
            fields.add('Resource__c');
            fields.add('Resource__r.Name');
            fields.add('Description__c');
            fields.add('Unit_of_Measure__c');
            fields.add('Unit_of_Measure__r.Name');
            fields.add('Unit_of_Measure__r.Hours_UOM__c');
            fields.add('Quantity__c');
            fields.add('Unit_Price__c');
            fields.add('Unit_Cost__c');
            fields.add('Regular_Hours__c');
            fields.add('Overtime_Hours__c');
            fields.add('Premium_Hours__c');
            fields.add('Regular_Rate__c');
            fields.add('Overtime_Rate__c');
            fields.add('Premium_Rate__c');
            fields.add('Line_Amount__c');
            fields.add('Tax__c');
            fields.add('Line_Amt_Incl_Tax__c');
            fields.add('Line_Cost__c');
            fields.add('Service_Center__c');
            fields.add('Service_Center__r.Name');
            fields.add('Bill_as_Lump_Sum__c');
            fields.add('Non_Billable__c');
            fields.add('TM__c');
            fields.add('TM__r.Name');
            fields.add('TM__r.Scheduled_Date__c');
            fields.add('To_Invoice__c');
            fields.add('Sales_Order__c');
            fields.add('Bundle_Line__c');
            fields.add('Bundle_Line__r.Line_No__c');
            fields.add('Bundle_Line__r.TM__c');
            fields.add('Bundle_Line__r.TM__r.Name');
            fields.add('Sales_Order_Job_Task__c');
            fields.add('TM_Job_Task__c');
            //ticket 19586 <<
            fields.add('CreatedDate');
            //ticket 19586 >>
            fields.add('Pricing_Source_2__c'); //Ticket#20013
            
            fields.add('TM__r.Service_Center__r.Advanced_Disposal__c');//US128849
            fields.add('TM__r.Service_Center__c');
            fields.add('EQAI_Bill_Unit_Code__c');
            fields.add('Disposal_Billing_Method__c');
            if (filters == null) {
                filters = new List<String>();
            }
            filters.add('Sales_Order_Job_Task__c IN :salesOrderJobTaskIds');
            
            String queryString = 'SELECT ' + String.join(fields, ',')  + ' FROM Billing_Worksheet_Line__c WHERE ' + String.join(filters, ' AND ');
            worksheetLines = (List<Billing_Worksheet_Line__c>) Database.query(queryString);
        }
        else {
            worksheetLines = BillingWorksheetLinesSelector.newInstance().selectBySalesOrderJobTaskId(salesOrderJobTaskIds, filters);
        }
        
        Set<Id> salesOrderIds = new Set<Id>();
        for (Sales_Order_Job_Task__c salesOrderJobTask : salesOrderJobTasks) {
            BillingWorksheetWrapper worksheetWrapper = new BillingWorksheetWrapper();
            worksheetWrapper.SalesOrderJobTask = salesOrderJobTask;
            mapWorksheetWrappersBySalesOrderTaskId.put(salesOrderJobTask.Id, worksheetWrapper);
            salesOrderIds.add(salesOrderJobTask.Sales_Order__c);
        }
        
        for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
            BillingWorksheetWrapper worksheetWrapper;
            if (mapWorksheetWrappersBySalesOrderTaskId.containsKey(worksheetLine.Sales_Order_Job_Task__c)) {
                worksheetWrapper = mapWorksheetWrappersBySalesOrderTaskId.get(worksheetLine.Sales_Order_Job_Task__c);
                worksheetWrapper.WorksheetLines.add(worksheetLine);
            }
        }
        
        //get confirmed TMs with unbilled lines
        Map<Id, TM__c> mapTMsBySalesOrderJobTask;
        Integer count = 0;
        for (Sales_Order_Job_Task__c salesOrderJobTask : [SELECT Id, Name, Line_No__c, Sales_Order__r.Operating_Expense_Cost_Pct__c,
                                                          (SELECT Id, TM__c, TM__r.Name, TM__r.Scheduled_Date__c FROM TM_Job_Tasks__r WHERE TM__r.Status__c = 'Confirmed')
                                                          FROM Sales_Order_Job_Task__c WHERE Id IN :salesOrderJobTaskIds]) {
                                                              //if (salesOrderJobTask.TM_Job_Tasks__r.size() > 0) {
                                                              if (mapWorksheetWrappersBySalesOrderTaskId.containsKey(salesOrderJobTask.Id)) {
                                                                  BillingWorksheetWrapper worksheetWrapper = mapWorksheetWrappersBySalesOrderTaskId.get(salesOrderJobTask.Id);
                                                                  for (TM_Job_Task__c tmJobTask : salesOrderJobTask.TM_Job_Tasks__r) {
                                                                      BillingWorksheetWrapper.RelatedInfo relatedInfo = new BillingWorksheetWrapper.RelatedInfo();
                                                                      relatedInfo.TM = tmJobTask.TM__r;
                                                                      //relatedInfo.TMJobTasks.add(tmJobTask);
                                                                      relatedInfo.TMJobTask = tmJobTask;
                                                                      worksheetWrapper.RelatedInfos.add(relatedInfo);
                                                                      count++;
                                                                  }
                                                              }
                                                              //}
                                                          }
        return mapWorksheetWrappersBySalesOrderTaskId.values();
    }
    
    @AuraEnabled
    public static String getBundleLines(Id salesOrderJobTaskId) {
        try {
            //List<String> filters = new List<String>();
            //filters.add('Sales_Order_Job_Task__c=\'' + salesOrderJobTaskId + '\'');
            //List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectByCategories(null, new Set<String>{ 'Lump Sum' }, filters);
            List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesByJobTaskId(null, new Set<Id>{ salesOrderJobTaskId });
            List<Sales_Line__c> salesLines2 = new List<Sales_Line__c>();
            for (Sales_Line__c salesLine : salesLines) {
                if (salesLine.Category__c == 'Bundled') {
                    salesLines2.add(salesLine);
                }
                else if (salesLine.Bundle_Line__r != null){
                    salesLines2.add(salesLine);
                }
            }
            return JSON.serialize(salesLines2);
        }
        catch (exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String calculateManifestFeeLines(Id salesOrderId, String JSONWorksheet) {
        CompanyMgmt.systemCall = true;
        try {
            Sales_Order__c salesOrder = [SELECT Id, Tax_Area__c, Tax_Liable__c, Manifest_And_Profile__c FROM Sales_Order__c WHERE Id =:salesOrderId LIMIT 1];
            if(salesOrder.Manifest_And_Profile__c == true) {
                BillingWorksheetWrapper worksheetWrapper = (BillingWorksheetWrapper) JSON.deserialize(JSONWorksheet, BillingWorksheetWrapper.class);
                List<BillingWorksheetWrapper> billingWorksheetWrappers = new List<BillingWorksheetWrapper>();
                billingWorksheetWrappers.add(worksheetWrapper);
                calculateManifestFeeLines(salesOrder, billingWorksheetWrappers);
                return JSON.serialize(worksheetWrapper);
            } else {
                return JSONWorksheet;
            }
        } catch (Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    public static void calculateManifestFeeLines(Sales_Order__c salesOrder, List<BillingWorksheetWrapper> worksheetWrappers) {
        Company_Setup__c defaultCompanySetup = CompanyMgmt.getCompanySetup();
        Map<Id, Map<Id, Billing_Worksheet_Line__c>> mapManifestFeeLinesByTMIdByTaskId = new Map<Id, Map<Id, Billing_Worksheet_Line__c>>();
        Map<Id, Set<Id>> mapTMIdsByTaskId = new Map<Id, Set<Id>>();
        Map<Id, Sales_Order_Job_Task__c> mapSalesOrderJobTasksById = new Map<Id, Sales_Order_Job_Task__c>();
        Map<String, Id> tmJobTaskIdByTMIdSalesOrderJobTaskId = new Map<String, Id>();
        Map<Id, BillingWorksheetWrapper> billingWorksheetWrappersBySalesJobTaskIds = new Map<Id, BillingWorksheetWrapper>();
        
        Map<Id,TM__c> mapofObjectTM = New Map<Id,TM__c>(); //US138859
        //Ticket#28704 >>
        //Resource__c defaultManifestFeeResource = defaultCompanySetup.Default_Manifest_Fee_Resource__r;
        if(ResourceService.getResource(defaultCompanySetup.Default_Manifest_Fee_Resource__c).Id == null){
            ResourceService.setResourceMapsByIds(new Set<Id>{defaultCompanySetup.Default_Manifest_Fee_Resource__c});
        }
        Resource__c defaultManifestFeeResource = ResourceService.getResource(defaultCompanySetup.Default_Manifest_Fee_Resource__c);
        //Ticket#28704 <<
        
        Integer nextWorksheetLineNo = getNextWorksheetLineNo(salesOrder.Id);
        
        List<Billing_Worksheet_Line__c> invoicedManifestFeeLines = [SELECT Id, Line_No__c, Sales_Order_Job_Task__c, TM__c, Resource__c, Invoiced__c, Sales_Order__c, TM_Job_Task__c
                                                                    FROM Billing_Worksheet_Line__c WHERE Invoiced__c = TRUE AND Sales_Order__c = :salesOrder.Id];
        
        for(Billing_Worksheet_Line__c billingWorksheetLine: invoicedManifestFeeLines){
            if(billingWorksheetLine.Resource__c == defaultManifestFeeResource.Id){
                Map<Id, Billing_Worksheet_Line__c> mapManifestFeeLinesByTMId = new Map<Id, Billing_Worksheet_Line__c>();
                if (mapManifestFeeLinesByTMIdByTaskId.containsKey(billingWorksheetLine.Sales_Order_Job_Task__c)) {
                    mapManifestFeeLinesByTMId = mapManifestFeeLinesByTMIdByTaskId.get(billingWorksheetLine.Sales_Order_Job_Task__c);
                }
                mapManifestFeeLinesByTMId.put(billingWorksheetLine.TM__c, billingWorksheetLine);
                mapManifestFeeLinesByTMIdByTaskId.put(billingWorksheetLine.Sales_Order_Job_Task__c, mapManifestFeeLinesByTMId);
            }
            tmJobTaskIdByTMIdSalesOrderJobTaskId.put(billingWorksheetLine.TM__c + ':' + billingWorksheetLine.Sales_Order_Job_Task__c, billingWorksheetLine.TM_Job_Task__c);
        }
        
        //System.debug('Info: mapManifestFeeLinesByTMIdByTaskId key set: ' + mapManifestFeeLinesByTMIdByTaskId.keySet());
        //System.debug('Info: mapManifestFeeLinesByTMIdByTaskId values: ' + mapManifestFeeLinesByTMIdByTaskId.values());
        
        for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
            for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                //System.debug('Info: worksheetLine ' + worksheetLine.Line_No__c + ' -- ' + worksheetLine.Resource__r.Name);
                if (worksheetLine.Line_No__c.intValue() > nextWorksheetLineNo) {
                    nextWorksheetLineNo = worksheetLine.Line_No__c.intValue();
                }
                
                if (worksheetLine.Category__c == 'Waste Disposal') {
                    if (worksheetLine.System_Calculated_Line__c != true) {
                        Set<Id> tmIds = new Set<Id>();
                        if (mapTMIdsByTaskId.containsKey(worksheetWrapper.SalesOrderJobTask.Id)) {
                            tmIds = mapTMIdsByTaskId.get(worksheetWrapper.SalesOrderJobTask.Id);
                        }
                        tmIds.add(worksheetLine.TM__c);
                        mapofObjectTM.put(worksheetLine.TM__c,worksheetLine.TM__r); //US138859
                        mapTMIdsByTaskId.put(worksheetWrapper.SalesOrderJobTask.Id, tmIds);
                        tmJobTaskIdByTMIdSalesOrderJobTaskId.put(worksheetLine.TM__c + ':' + worksheetLine.Sales_Order_Job_Task__c, worksheetLine.TM_Job_Task__c);
                    }
                    
                    if (worksheetLine.Resource__c == defaultManifestFeeResource.Id){
                        Map<Id, Billing_Worksheet_Line__c> mapManifestFeeLinesByTMId = new Map<Id, Billing_Worksheet_Line__c>();
                        if (mapManifestFeeLinesByTMIdByTaskId.containsKey(worksheetWrapper.SalesOrderJobTask.Id)) {
                            mapManifestFeeLinesByTMId = mapManifestFeeLinesByTMIdByTaskId.get(worksheetWrapper.SalesOrderJobTask.Id);
                        }
                        mapManifestFeeLinesByTMId.put(worksheetLine.TM__c, worksheetLine);
                        mapManifestFeeLinesByTMIdByTaskId.put(worksheetWrapper.SalesOrderJobTask.Id, mapManifestFeeLinesByTMId);
                    }
                }
            }
            mapSalesOrderJobTasksById.put(worksheetWrapper.SalesOrderJobTask.Id, worksheetWrapper.SalesOrderJobTask);
            billingWorksheetWrappersBySalesJobTaskIds.put(worksheetWrapper.SalesOrderJobTask.Id, worksheetWrapper);
        }
        
        //System.debug('Info: mapTMIdsByTaskId keys: ' + mapTMIdsByTaskId.keySet());
        //System.debug('Info: mapTMIdsByTaskId values: ' + mapTMIdsByTaskId.values());
        
        for (Id salesOrderTaskId : mapTMIdsByTaskId.keySet()) {
            Map<Id, Billing_Worksheet_Line__c> mapManifestFeeLinesByTMId = mapManifestFeeLinesByTMIdByTaskId.get(salesOrderTaskId);
            Set<Id> tmIds = mapTMIdsByTaskId.get(salesOrderTaskId);
            
            
            for (Id tmId : tmIds) {
                Boolean manifestFeeLineExists = false;
                if (mapManifestFeeLinesByTMId != null && mapManifestFeeLinesByTMId.containsKey(tmId)) {
                    manifestFeeLineExists = true;
                }
                
                if (!manifestFeeLineExists) {
                    //System.debug('Info: manifestFeeLineExists salesOrderTaskId: ' + salesOrderTaskId);
                    //System.debug('Info: manifestFeeLineExists tmId: ' + tmId);
                    Sales_Order_Job_Task__c salesOrderJobTask = mapSalesOrderJobTasksById.get(salesOrderTaskId);
                    nextWorksheetLineNo += 1;
                    Billing_Worksheet_Line__c manifestFeeLine = new Billing_Worksheet_Line__c();
                    manifestFeeLine.Line_No__c = nextWorksheetLineNo;
                    manifestFeeLine.TM__c = tmId;
                    //US138859
                    manifestFeeLine.TM__r = mapofObjectTM.containsKey(tmId) ? mapofObjectTM.get(tmId) : null; 
                    manifestFeeLine.TM_Job_Task__c = tmJobTaskIdByTMIdSalesOrderJobTaskId.get(tmId + ':' + salesOrderTaskId);
                    manifestFeeLine.Category__c = 'Waste Disposal';
                    manifestFeeLine.Resource__c = defaultManifestFeeResource.Id;
                    manifestFeeLine.Resource__r = defaultManifestFeeResource;
                    manifestFeeLine.Description__c = defaultManifestFeeResource.Description__c;
                    manifestFeeLine.Unit_of_Measure__c = defaultManifestFeeResource.Unit_of_Measure__c;
                    manifestFeeLine.Unit_of_Measure__r = defaultManifestFeeResource.Unit_of_Measure__r;
                    //Ticket#28704 >>
                    //manifestFeeLine.Unit_Price__c = defaultManifestFeeResource.Unit_Cost__c;
                    //manifestFeeLine.Unit_Cost__c = defaultManifestFeeResource.Unit_Cost__c;
                    manifestFeeLine.Unit_Price__c = ResourceService.getUnitPrice(defaultManifestFeeResource.Id, defaultManifestFeeResource.Unit_of_Measure__c, false);
                    manifestFeeLine.Unit_Cost__c = ResourceService.getUnitCost(defaultManifestFeeResource.Id, defaultManifestFeeResource.Unit_of_Measure__c);
                    //Ticket#28704 <<
                    manifestFeeLine.Quantity__c = 0;
                    manifestFeeLine.System_Calculated_Line__c = true;
                    manifestFeeLine.Sales_Order_Job_Task__c = salesOrderJobTask.Id;
                    manifestFeeLine.Sales_Order__c = salesOrderJobTask.Sales_Order__c;
                    if(salesOrder.Tax_Liable__c == true){
                        manifestFeeLine.Tax_Group__c = 'TX';
                        manifestFeeLine.Tax_Pct__c = CompanyMgmt.getSalesTax(salesOrder.Tax_Area__c, 'TX');
                    } else {
                        manifestFeeLine.Tax_Group__c = 'NT';
                        manifestFeeLine.Tax_Pct__c = 0;
                    }
                    manifestFeeLine.To_Invoice__c = true;
                    if(billingWorksheetWrappersBySalesJobTaskIds.containsKey(salesOrderTaskId)){
                        billingWorksheetWrappersBySalesJobTaskIds.get(salesOrderTaskId).WorksheetLines.add(manifestFeeLine);
                    }
                }
            }
        }
    }
    
    @AuraEnabled
    public static String saveWorksheets(Id salesOrderId, String JSONWorksheets) {
        try {
            List<BillingWorksheetWrapper> worksheetWrappers = (List<BillingWorksheetWrapper>) JSON.deserialize(JSONWorksheets, List<BillingWorksheetWrapper>.class);
            
            saveWorksheets(salesOrderId, worksheetWrappers);
            
            Map<Id, BillingWorksheetWrapper> mapWorksheetWrappersByTaskId = new Map<Id, BillingWorksheetWrapper>();
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                mapWorksheetWrappersByTaskId.put(worksheetWrapper.SalesOrderJobTask.Id, worksheetWrapper);
            }
            //worksheetWrappers = getWorksheets(salesOrderJobTaskIds, null);
            
            //return only originally submitted worksheet lines
            List<BillingWorksheetWrapper> newWorksheetWrappers = getWorksheets(mapWorksheetWrappersByTaskId.keySet(), null, false);
            for (BillingWorksheetWrapper newWorksheetWrapper : newWorksheetWrappers) {
                BillingWorksheetWrapper worksheetWrapper = mapWorksheetWrappersByTaskId.get(newWorksheetWrapper.SalesOrderJobTask.Id);
                Set<Id> selectedTMIds = new Set<Id>();
                for (Integer i = 0; i < worksheetWrapper.RelatedInfos.size(); i++) {
                    selectedTMIds.add(worksheetWrapper.RelatedInfos[i].TM.Id);
                }
                for (Integer i = 0; i < newWorksheetWrapper.WorksheetLines.size(); i++) {
                    Billing_Worksheet_Line__c newWorksheetLine = newWorksheetWrapper.WorksheetLines[i];
                    if (!selectedTMIds.contains(newWorksheetLine.TM__c)) {
                        newWorksheetWrapper.WorksheetLines.remove(i);
                        i--;
                    }
                }
            }
            
            return JSON.serialize(newWorksheetWrappers);
        }
        catch(exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    private static void saveWorksheets(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers) {
        CompanyMgmt.systemCall = true;
        
        Savepoint sp = Database.setSavepoint();
        try {
            Company_Setup__c defaultCompanySetup = CompanyMgmt.getCompanySetup();
            
            /*
Set<Id> salesOrderJobTaskIds = new Set<Id>();
for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
salesOrderJobTaskIds.add(worksheetWrapper.SalesOrderJobTask.Id);
}

//handle deleted lines and bundle lines
Set<Id> worksheetLineIds = new Set<Id>();
//find the existing worksheet lines
for (Billing_Worksheet_Line__c worksheetLine : [SELECT Id FROM Billing_Worksheet_Line__c WHERE Sales_Order__c = :salesOrderId AND Sales_Order_Job_Task__c IN :salesOrderJobTaskIds AND TM__c IN :tmIds AND Invoiced__c != TRUE]) {
worksheetLineIds.add(worksheetLine.Id);
}
*/
            
            //ticket 20527 <<
            Set<Id> worksheetLineIds = new Set<Id>();
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.DeletedWorksheetLines) {
                    if (worksheetLine.Id != null) {
                        worksheetLineIds.add(worksheetLine.Id);
                    }
                }
                
                for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                    if (worksheetLine.Id != null) {
                        worksheetLineIds.add(worksheetLine.Id);
                    }
                }
            }
            List<Billing_Worksheet_Line__c> oldWorksheetLines = [SELECT Id, Line_No__c, Invoiced__c FROM Billing_Worksheet_Line__c WHERE Id IN :worksheetLineIds];
            for (Billing_Worksheet_Line__c worksheetLine : oldWorksheetLines) {
                if (worksheetLineIds.contains(worksheetLine.Id)) {
                    if (worksheetLine.Invoiced__c == true) {
                        throw new DataException('Worksheet line #' + worksheetLine.Line_No__c + ' has been invoiced after you retrieved the worksheet. ');
                    }
                }
            }
            //ticket 20527 >>
            
            //TM Status update <<
            Set<Id> allTMIds = new Set<Id>(); //include TM Id of deleted lines
            //TM Status update >>
            //ticket 19916 << - check if line number of the new lines are used by another user
            Set<Integer> newLineNumbers = new Set<Integer>();
            Integer nextWorksheetLineNo = 0;
            List<Billing_Worksheet_Line__c> worksheetLines = [SELECT Id, Line_No__c FROM Billing_Worksheet_Line__c WHERE Sales_Order__c = :salesOrderId ORDER BY Line_No__c DESC LIMIT 1];
            if (worksheetLines.size() > 0) {
                nextWorksheetLineNo = worksheetLines[0].Line_No__c.intValue();
            }
            
            List<Billing_Worksheet_Line__c> worksheetLinesToDelete = new List<Billing_Worksheet_Line__c>();
            Set<Id> tmLineToDeleteIds = new Set<Id>();
            //Ticket#20245 - Check T&M status change before save
            Set<Id> tempTMIds = new Set<Id>();
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.DeletedWorksheetLines) {
                    if (worksheetLine.Id != null) {
                        worksheetLinesToDelete.add(worksheetLine);
                        
                        if (worksheetLine.TM_Line__c != null) {
                            tmLineToDeleteIds.add(worksheetLine.TM_Line__c);
                            //TM Status update <<
                            if (worksheetLine.TM__c != null) {
                                allTMIds.add(worksheetLine.TM__c);
                            }
                            //TM Status update >>
                        }
                    }
                }
                
                for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                    //Ticket#20245 >>
                    if(worksheetLine.TM__c != null){
                        tempTMIds.add(worksheetLine.TM__c);
                    }
                    //Ticket#20245 <<
                    
                    if (worksheetLine.Id == null) {
                        newLineNumbers.add(worksheetLine.Line_No__c.intValue());
                    }
                    if (nextWorksheetLineNo < worksheetLine.Line_No__c.intValue()) {
                        nextWorksheetLineNo = worksheetLine.Line_No__c.intValue();
                    }
                }
            }
            nextWorksheetLineNo++;
            
            //Ticket#20245 >>
            if(tempTMIds.size() > 0){
                Set<String> tmNames = new Set<String>();
                for(TM__c tm : [SELECT Name, Status__c FROM TM__c WHERE Id IN :tempTMIds]){
                    if(tm.Status__c == TMsService.OPEN_STATUS || tm.Status__c == TMsService.SCHEDULED_STATUS || tm.Status__c == TMsService.MOBILE_REVIEW_STATUS){
                        tmNames.add(tm.Name);
                    }
                }
                
                if(tmNames.size() > 0){
                    String errorMsg = '';
                    for(String tmName : tmNames){
                        errorMsg = errorMsg + tmName + ',';
                    }
                    throw new DataException('Following T&M is no longer confirmed, please review! ' + errorMsg);
                }
            }
            //Ticket#20245 <<
            
            //delete worksheet lines
            if (worksheetLinesToDelete.size() > 0) {
                delete worksheetLinesToDelete;
            }
            
            //delete TM lines
            List<TM_Line__c> tmLinesToDelete = new List<TM_Line__c>();
            for (Id tmLineId : tmLineToDeleteIds) {
                tmLinesToDelete.add(new TM_Line__c(Id = tmLineId));
            }
            //ticket 19916 <<
            //delete tmLinesToDelete;
            TMsService.ByPassCreatingBillingWorksheetLines = true; //bypass calling createBillingWorksheet() function in TMsService.cls as a result of deleting tm lines.
            delete tmLinesToDelete;
            TMsService.ByPassCreatingBillingWorksheetLines = false;
            //ticket 19916 >>
            
            //ticket 19916 <<
            if (newLineNumbers.size() > 0) {
                Map<Integer, Integer> mapDuplicateLineNumbers = new Map<Integer, Integer>();
                for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
                    Integer worksheetLineNo = worksheetLine.Line_No__c.intValue();
                    if (newLineNumbers.contains(worksheetLineNo)) {
                        mapDuplicateLineNumbers.put(worksheetLineNo, nextWorksheetLineNo);
                        nextWorksheetLineNo++;
                    }
                }
                
                //duplicate line numbers exist
                if (mapDuplicateLineNumbers.size() > 0) {
                    for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                        for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                            if (mapDuplicateLineNumbers.containsKey(worksheetLine.Line_No__c.intValue())) {
                                worksheetLine.Line_No__c = mapDuplicateLineNumbers.get(worksheetLine.Line_No__c.intValue()); //assign new line number
                            }
                            if (worksheetLine.Bundle_Line__r != null) {
                                if (mapDuplicateLineNumbers.containsKey(worksheetLine.Bundle_Line__r.Line_No__c.intValue())) {
                                    worksheetLine.Bundle_Line__r.Line_No__c = worksheetLine.Bundle_Line__r.Line_No__c.intValue();
                                }
                            }
                            
                            //ticket 19130 <<
                            /*
if (worksheetLine.Parent_Line__r != null) {
if (mapDuplicateLineNumbers.containsKey(worksheetLine.Parent_Line__r.Line_No__c.intValue())) {
worksheetLine.Parent_Line__r.Line_No__c = mapDuplicateLineNumbers.get(worksheetLine.Parent_Line__r.Line_No__c.intValue());
}
}
*/
                            //ticket 19130 >>
                            
                            if (worksheetLine.Linked_Line__r != null) {
                                if (mapDuplicateLineNumbers.containsKey(worksheetLine.Linked_Line__r.Line_No__c.intValue())) {
                                    worksheetLine.Linked_Line__r.Line_No__c = mapDuplicateLineNumbers.get(worksheetLine.Linked_Line__r.Line_No__c.intValue());
                                }
                            }
                        }
                    }
                }
            }
            //ticket 19916 >>
            
            //calc manifest line
            Sales_Order__c salesOrder = (Sales_Order__c)JSON.deserialize(getSalesOrder(salesOrderId), Sales_Order__c.class);
            if(salesOrder.Manifest_And_Profile__c == true) {
                calculateManifestFeeLines(salesOrder, worksheetWrappers);
            }
            Map<Integer, Billing_Worksheet_Line__c> mapLinkedWorksheetLinesByLineNo = new Map<Integer, Billing_Worksheet_Line__c>();
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                    /*
if (worksheetLine.Id != null) {
if (worksheetLineIds.contains(worksheetLine.Id)) {
worksheetLineIds.remove(worksheetLine.Id); //if a worksheetLine is not included in the worksheet wrapper, it's been deleted by user
}
}
*/
                    
                    if (worksheetLine.Bundle_Line__r != null || worksheetLine.Parent_Line__r != null) {
                        mapLinkedWorksheetLinesByLineNo.put(worksheetLine.Line_No__c.intValue(), worksheetLine.clone(true, true));
                        worksheetLine.Bundle_Line__c = null;
                        worksheetLine.Bundle_Line__r = null;
                        //ticket 29772 <<
                        worksheetLine.Bill_as_Lump_Sum__c = false; //reset the flag so it won't trigger the new validation rule "Check Bundled". The flag will be recovered later in the code below from mapLinkedWorksheetLinesByLineNo
                        //ticket 29772 >>
                        
                        //ticket 19130 <<
                        /*
worksheetLine.Parent_Line__r = null;
worksheetLine.Parent_Line__c = null;
*/
                        //ticket 19130 >>
                        //ticket 19916 <<
                        worksheetLine.Linked_Line__r = null;
                        worksheetLine.Linked_Line__c = null;
                        //ticket 19916 >>
                    }
                }
            }
            /*
List<Billing_Worksheet_Line__c> billingWorksheetLinesToDelete = [SELECT Id FROM Billing_Worksheet_Line__c WHERE Sales_Order__c = :salesOrderId AND Sales_Order_Job_Task__c IN :salesOrderJobTaskIds AND Id IN :worksheetLineIds AND Invoiced__c != TRUE];
delete billingWorksheetLinesToDelete;
*/
            
            //insert lines without bundle and parent fields
            Map<Integer, Billing_Worksheet_Line__c> mapWorksheetLinesByLineNo = new Map<Integer, Billing_Worksheet_Line__c>();
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                    //subcontractor resource
                    if (worksheetLine.Category__c == 'Subcontractors' && worksheetLine.Resource__c == null) {
                        worksheetLine.Resource__c = defaultCompanySetup.Default_Subcontractor_Resource__c;
                    }
                    mapWorksheetLinesByLineNo.put(worksheetLine.Line_No__c.intValue(), worksheetLine);
                }
            }
            if (mapWorksheetLinesByLineNo.size() > 0) {
                upsert mapWorksheetLinesByLineNo.values();
            }
            
            
            //update tm lines
            Set<Id> tmIds = new Set<Id>();
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                    tmIds.add(worksheetLine.TM__c);
                }
            }
            //get last tm line no
            Map<Id, Integer> mapNextTMLineNoByTMId = new Map<Id, Integer>();
            for (AggregateResult result : [SELECT TM__c, MAX(Line_No__c) NextLineNo FROM TM_Line__c WHERE TM__c IN :tmIds GROUP BY TM__c]) {
                mapNextTMLineNoByTMId.put((Id) result.get('TM__c'), ((Decimal) result.get('NextLineNo')).intValue() + 1);
            }
            
            //insert/update tmLines
            Set<Id> sigToVoidTMIds = new Set<Id>();
            Map<Id, TM_Line__c> mapTMLinesToUpsertByWorksheetLineId = new Map<Id, TM_Line__c>();
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                    if (worksheetLine.TM_Line__c != null) {
                        if (worksheetLine.Invoiced__c != true) {
                            TM_Line__c tmLineToUpdate = copyWorksheetLineFieldsToTMLine(worksheetLine, new TM_Line__c(Id = worksheetLine.TM_Line__c));
                            mapTMLinesToUpsertByWorksheetLineId.put(worksheetLine.Id, tmLineToUpdate);
                        }
                    }
                    else {
                        Integer nextLineNo = mapNextTMLineNoByTMId.get(worksheetLine.TM__c);
                        TM_Line__c tmLineToInsert = createTMLineFromWorksheetLine(nextLineNo, worksheetLine);
                        mapNextTMLineNoByTMId.put(worksheetLine.TM__c, nextLineNo + 1);
                        mapTMLinesToUpsertByWorksheetLineId.put(worksheetLine.Id, tmLineToInsert);
                        //ticket 20229 <<
                        //sigToVoidTMIds.add(tmLineToInsert.TM__c);
                        if (worksheetLine.Category__c != 'Bundled') {
                            sigToVoidTMIds.add(tmLineToInsert.TM__c);
                        }
                        //ticket 20229 >>
                    }
                }
            }
            if (mapTMLinesToUpsertByWorksheetLineId.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                upsert mapTMLinesToUpsertByWorksheetLineId.values();
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;
            }
            
            if (sigToVoidTMIds.size() > 0) {
                List<Signature__c> signatures = [SELECT Id FROM Signature__c WHERE TM__c IN :sigToVoidTMIds AND Voided__c != TRUE];
                for (Signature__c signature : signatures) {
                    signature.Voided__c = true;
                    signature.Void_Reason__c = 'New T&M lines are added from billing worksheet';
                }
                if (signatures.size() > 0) {
                    CompanyMgmt.byPassTrigger = true;
                    update signatures;
                    CompanyMgmt.byPassTrigger = false;
                }
            }
            
            //update TM status <<
            List<TM__c> tmsToUpdate = new List<TM__c>();
            List<TM__c> tms = [SELECT Id, Status__c, Name, Total_Lines__c, (SELECT Id FROM TM_Lines__r WHERE Invoiced__c != TRUE) FROM TM__c WHERE Id IN :allTMIds];
            for (TM__c tm : tms) {
                if (tm.TM_Lines__r.size() == 0) {
                    if (tm.Status__c == 'Confirmed' && tm.Total_Lines__c > 0) {
                        tm.Status__c = 'Fully Invoiced';
                        tmsToUpdate.add(tm);
                    }
                }
                else {
                    if (tm.Status__c != 'Confirmed') {
                        tm.Status__c = 'Confirmed';
                        tmsToUpdate.add(tm);
                    }
                }
            }
            if (tmsToUpdate.size() > 0) {
                CompanyMgmt.byPassTrigger = true;
                update tmsToUpdate;
                CompanyMgmt.byPassTrigger = false;
            }
            //update TM status >>
            
            //update bundle, parent, and TM_Line__c fields
            List<Billing_Worksheet_Line__c> worksheetLinesToUpdate = new List<Billing_Worksheet_Line__c>();
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
                    Boolean updateWorksheetLine = false;
                    if (mapLinkedWorksheetLinesByLineNo.containsKey(worksheetLine.Line_No__c.intValue())) {
                        Billing_Worksheet_Line__c linkedWorksheetLine = mapLinkedWorksheetLinesByLineNo.get(worksheetLine.Line_No__c.intValue());
                        worksheetLine.Bundle_Line__c = linkedWorksheetLine.Bundle_Line__c;
                        worksheetLine.Bundle_Line__r = linkedWorksheetLine.Bundle_Line__r;
                        //ticket 29772 <<
                        worksheetLine.Bill_as_Lump_Sum__c = linkedWorksheetLine.Bill_as_Lump_Sum__c;
                        //ticket 29772 >>
                        
                        //ticket 19130 <<
                        /*
worksheetLine.Parent_Line__c = linkedWorksheetLine.Parent_Line__c;
worksheetLine.Parent_Line__r = linkedWorksheetLine.Parent_Line__r;
*/
                        //ticket 19130 >>
                        
                        //ticket 19916 <<
                        worksheetLine.Linked_Line__c = linkedWorksheetLine.Linked_Line__c;
                        worksheetLine.Linked_Line__r = linkedWorksheetLine.Linked_Line__r;
                        //ticket 19916 >>
                        if (worksheetLine.Bundle_Line__r != null) {
                            if (mapWorksheetLinesByLineNo.containsKey(worksheetLine.Bundle_Line__r.Line_No__c.intValue())) {
                                Billing_Worksheet_Line__c bundleLine = mapWorksheetLinesByLineNo.get(worksheetLine.Bundle_Line__r.Line_No__c.intValue());
                                worksheetLine.Bundle_Line__c = bundleLine.Id;
                                worksheetLine.Bundle_Line__r.Id = bundleLine.Id;
                            }
                        }
                        
                        //ticket 19130 <<
                        /*
if (worksheetLine.Parent_Line__r != null) {
if (mapWorksheetLinesByLineNo.containsKey(worksheetLine.Parent_Line__r.Line_No__c.intValue())) {
Billing_Worksheet_Line__c parentLine = mapWorksheetLinesByLineNo.get(worksheetLine.Parent_Line__r.Line_No__c.intValue());
worksheetLine.Parent_Line__c = parentLine.Id;
worksheetLine.Parent_Line__r.Id = parentLine.Id;
}
}
*/
                        //ticket 19130 >>
                        
                        //ticket 19916 <<
                        if (worksheetLine.Linked_Line__r != null) {
                            if (mapWorksheetLinesByLineNo.containsKey(worksheetLine.Linked_Line__r.Line_No__c.intValue())) {
                                Billing_Worksheet_Line__c linkedLine = mapWorksheetLinesByLineNo.get(worksheetLine.Linked_Line__r.Line_No__c.intValue());
                                worksheetLine.Linked_Line__c = linkedLine.Id;
                                worksheetLine.Linked_Line__r.Id = linkedLine.Id;
                            }
                        }
                        //ticket 19916 >>
                        updateWorksheetLine = true;
                    }
                    
                    if (mapTMLinesToUpsertByWorksheetLineId.containsKey(worksheetLine.Id)) {
                        worksheetLine.TM_Line__c = mapTMLinesToUpsertByWorksheetLineId.get(worksheetLine.Id).Id;
                        updateWorksheetLine = true;
                    }
                    
                    if (updateWorksheetLine == true) {
                        worksheetLinesToUpdate.add(worksheetLine);
                    }
                }
            }
            if (worksheetLinesToUpdate.size() > 0) {
                update worksheetLinesToUpdate;
            }
            
            //update sales order job task
            List<Sales_Order_Job_Task__c> salesOrderJobTasks = new List<Sales_Order_Job_Task__c>();
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                Sales_Order_Job_Task__c salesOrderJobTask = new Sales_Order_Job_Task__c();
                salesOrderJobTask.Id = worksheetWrapper.SalesOrderJobTask.Id;
                salesOrderJobTask.Pct_To_Bill__c = worksheetWrapper.SalesOrderJobTask.Pct_To_Bill__c;
                salesOrderJobTask.Amount_To_Bill__c = worksheetWrapper.SalesOrderJobTask.Amount_To_Bill__c;
                salesOrderJobTasks.add(salesOrderJobTask);
            }
            update salesOrderJobTasks;
            
            
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    
    @AuraEnabled
    public static String validateResourceType(Id salesOrderId, String JSONWorksheetLine) {
        try {
            Billing_Worksheet_Line__c worksheetLine = (Billing_Worksheet_Line__c)JSON.deserialize(JSONWorksheetLine, Billing_Worksheet_Line__c.class);
            BillingWorksheetService.initStaticVariables(salesOrderId, new List<Billing_Worksheet_Line__c> { worksheetLine });
            BillingWorksheetService.validateResourceType(salesOrderId, worksheetLine);
            return JSON.serialize(worksheetLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String validateResource(Id salesOrderId, String JSONWorksheetLine) {
        try {
            Billing_Worksheet_Line__c worksheetLine = (Billing_Worksheet_Line__c)JSON.deserialize(JSONWorksheetLine, Billing_Worksheet_Line__c.class);
            BillingWorksheetService.initStaticVariables(salesOrderId, new List<Billing_Worksheet_Line__c> { worksheetLine });
            BillingWorksheetService.validateResource(salesOrderId, worksheetLine);
            return JSON.serialize(worksheetLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //ticket 19130 << temporary disable, not needed for this phase
    /*
@AuraEnabled
public static String calculatePresumptiveChildLines(Id salesOrderId, String JSONWorksheetLine, Integer nextWorksheetLineNo) {
try {
Billing_Worksheet_Line__c worksheetLine = (Billing_Worksheet_Line__c)JSON.deserialize(JSONWorksheetLine, Billing_Worksheet_Line__c.class);
BillingWorksheetService.initStaticVariables(salesOrderId, new List<Billing_Worksheet_Line__c> { worksheetLine });
List<Billing_Worksheet_Line__c> childLines = BillingWorksheetService.calculatePresumptiveChildLines(worksheetLine, nextWorksheetLineNo);
return JSON.serialize(childLines);
}
catch(exception ex) {
throw new AuraHandledException(ex.getMessage());
}
}
*/
    //ticket 19130 >>
    
    @AuraEnabled
    public static String calculatePriceAndCost(Id salesOrderId, String JSONWorksheetLine) {
        try {
            Billing_Worksheet_Line__c worksheetLine = (Billing_Worksheet_Line__c)JSON.deserialize(JSONWorksheetLine, Billing_Worksheet_Line__c.class);
            BillingWorksheetService.initStaticVariables(salesOrderId, new List<Billing_Worksheet_Line__c> { worksheetLine });
            BillingWorksheetService.calculatePriceAndCost(salesOrderId, worksheetLine);
            return JSON.serialize(worksheetLine);
        }
        catch(exception ex) {
            System.debug('ERROR: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String calculatePriceInfo(Id salesOrderId, String JSONWorksheets) {
        try {
            List<BillingWorksheetWrapper> worksheets = (List<BillingWorksheetWrapper>) JSON.deserialize(JSONWorksheets, List<BillingWorksheetWrapper>.class);
            BillingWorksheetService.initStaticVariables(salesOrderId, worksheets);
            BillingWorksheetService.calculatePriceAndCost(salesOrderId, worksheets);
            return JSON.serialize(worksheets);
        }
        catch(exception ex) {
            System.debug('ERROR: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String validateTaxGroup(Id salesOrderId, String JSONWorksheetLine) {
        try {
            Billing_Worksheet_Line__c worksheetLine = (Billing_Worksheet_Line__c)JSON.deserialize(JSONWorksheetLine, Billing_Worksheet_Line__c.class);
            BillingWorksheetService.initStaticVariables(salesOrderId, new List<Billing_Worksheet_Line__c> { worksheetLine });
            BillingWorksheetService.assignTaxPercent(salesOrderId, worksheetLine);
            return JSON.serialize(worksheetLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String validateContractLine(Id salesOrderId, String JSONWorksheetLine) {
        try {
            Billing_Worksheet_Line__c worksheetLine = (Billing_Worksheet_Line__c)JSON.deserialize(JSONWorksheetLine, Billing_Worksheet_Line__c.class);
            BillingWorksheetService.initStaticVariables(salesOrderId, new List<Billing_Worksheet_Line__c> { worksheetLine });
            BillingWorksheetService.validateContractLine(salesOrderId, worksheetLine);
            return JSON.serialize(worksheetLine);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String populateLinesInfo(Id salesOrderId, String JSONWorksheetLines) {
        try {
            List<Billing_Worksheet_Line__c> worksheetLines = (List<Billing_Worksheet_Line__c>)JSON.deserialize(JSONWorksheetLines, List<Billing_Worksheet_Line__c>.class);
            BillingWorksheetService.initStaticVariables(salesOrderId, worksheetLines);
            BillingWorksheetService.populateLinesInfo(salesOrderId, worksheetLines);
            return JSON.serialize(worksheetLines);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String calculateLaborHours(Id salesOrderId, String JSONWorksheetLine) {
        try {
            Billing_Worksheet_Line__c worksheetLine = (Billing_Worksheet_Line__c)JSON.deserialize(JSONWorksheetLine, Billing_Worksheet_Line__c.class);
            BillingWorksheetService.initStaticVariables(salesOrderId, new List<Billing_Worksheet_Line__c> { worksheetLine });
            BillingWorksheetService.calculateLaborHours(salesOrderId, worksheetLine);
            return JSON.serialize(worksheetLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //Ticket#20496
    @AuraEnabled
    public static String calculateLaborHoursUsingWeeklyRule(Id salesOrderId, String JSONWorksheetLines, String JSONUpdatedWorksheetLine) {
        try {
            Billing_Worksheet_Line__c updatedWorksheetLine = (Billing_Worksheet_Line__c)JSON.deserialize(JSONUpdatedWorksheetLine, Billing_Worksheet_Line__c.class);
            List<Billing_Worksheet_Line__c> worksheetLines = (List<Billing_Worksheet_Line__c>)JSON.deserialize(JSONWorksheetLines, List<Billing_Worksheet_Line__c>.class);
            BillingWorksheetService.initStaticVariables(salesOrderId, worksheetLines);
            BillingWorksheetService.calculateLaborHours(salesOrderId, worksheetLines, updatedWorksheetLine);
            return JSON.serialize(worksheetLines);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static String calculateLineTotals(String JSONWorksheetLine) {
        try {
            Billing_Worksheet_Line__c worksheetLine = (Billing_Worksheet_Line__c)JSON.deserialize(JSONWorksheetLine, Billing_Worksheet_Line__c.class);
            BillingWorksheetService.calculateLineTotals(worksheetLine);
            return JSON.serialize(worksheetLine);
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    //ticket 19130 << temporary disable, not needed for this phase
    /*
@AuraEnabled
public static String prepareWizardQuestions(Id salesOrderId, String JSONWorksheets, Integer nextWorksheetLineNo) {
try {
List<BillingWorksheetWrapper> worksheets = (List<BillingWorksheetWrapper>)JSON.deserialize(JSONWorksheets, List<BillingWorksheetWrapper>.class);

BillingWorksheetService.initStaticVariables(salesOrderId, worksheets);

//find all parent resources that have child resources
Map<Integer, List<Billing_Worksheet_Line__c>> mapChildLinesByParentLineNo = new Map<Integer, List<Billing_Worksheet_Line__c>>();
Map<Integer, Billing_Worksheet_Line__c> mapWorksheetLinesByLineNo = new Map<Integer, Billing_Worksheet_Line__c>();
for (Integer i = 0; i < worksheets.size(); i++) {
BillingWorksheetWrapper worksheetWrapper = worksheets[i];
for (Billing_Worksheet_Line__c worksheetLine : worksheetWrapper.WorksheetLines) {
if (worksheetLine.Wizard_Question_Answered__c != true && worksheetLine.Parent_Line__r == null) {
List<Billing_Worksheet_Line__c> childLines = BillingWorksheetService.calculatePresumptiveChildLines(worksheetLine, nextWorksheetLineNo);
mapChildLinesByParentLineNo.put(worksheetLine.Line_No__c.intValue(), childLines);
nextWorksheetLineNo += childLines.size();
}
mapWorksheetLinesByLineNo.put(worksheetLine.Line_No__c.intValue(), worksheetLine);
}
}

//insert new child lines to jobTaskWrapper
if (mapChildLinesByParentLineNo.size() > 0) {
for (Integer i = 0; i < worksheets.size(); i++) {
BillingWorksheetWrapper worksheet = worksheets[i];
List<Billing_Worksheet_Line__c> childLinesToInsert = new List<Billing_Worksheet_Line__c>();
for (Billing_Worksheet_Line__c worksheetLine : worksheet.WorksheetLines) {
if (mapChildLinesByParentLineNo.containsKey(worksheetLine.Line_No__c.intValue())) { //is a parent line
//check if the parent line already has child lines
Boolean childLinesExist = false;
for (Billing_Worksheet_Line__c worksheetLine2 : worksheet.WorksheetLines) {
if (worksheetLine2.Parent_Line__r != null && worksheetLine2.Parent_Line__r.Line_No__c == worksheetLine.Line_No__c) {
childLinesExist = true;
break;
}
}
if (!childLinesExist) { //add the child lines
List<Billing_Worksheet_Line__c> newChildLines = mapChildLinesByParentLineNo.get(worksheetLine.Line_No__c.intValue());
childLinesToInsert.addAll(newChildLines);
}
}
}
for (Billing_Worksheet_Line__c childLine : childLinesToInsert) {
worksheet.WorksheetLines.add(childLine);
}
}
}

//Map<Integer, List<Job_Task_Template_Line__c>> mapQuestionsByTaskIndex = new Map<Integer, List<Job_Task_Template_Line__c>>();
Map<Integer, List<Map<String, Object>>> mapQuestionsByTaskIndex = new Map<Integer, List<Map<String, Object>>>();
for (Integer i = 0; i < worksheets.size(); i++) {
BillingWorksheetWrapper worksheet = worksheets[i];

//group child lines by parent line no
Map<Integer, List<Billing_Worksheet_Line__c>> mapChildWorksheetLinesByParentLineNo = new Map<Integer, List<Billing_Worksheet_Line__c>>();
for (Billing_Worksheet_Line__c worksheetLine : worksheet.WorksheetLines) {
if (worksheetLine.Parent_Line__r != null && worksheetLine.Parent_Line__r.Line_No__c != null) {
if (worksheetLine.Quantity__c == null || worksheetLine.Quantity__c == 0) {
Integer parentLineNo = worksheetLine.Parent_Line__r.Line_No__c.intValue();
List<Billing_Worksheet_Line__c> childWorksheetLines;
if (mapChildWorksheetLinesByParentLineNo.containsKey(parentLineNo)) {
childWorksheetLines = mapChildWorksheetLinesByParentLineNo.get(parentLineNo);
} else {
childWorksheetLines = new List<Billing_Worksheet_Line__c>();
mapChildWorksheetLinesByParentLineNo.put(parentLineNo, childWorksheetLines);
}
childWorksheetLines.add(worksheetLine);
}
}
}

List<Map<String, Object>> questions = new List<Map<String, Object>>();
for (Billing_Worksheet_Line__c worksheetLine : worksheet.WorksheetLines) {
if (worksheetLine.Wizard_Question_Answered__c != true) {
Integer worksheetLineNo = worksheetLine.Line_No__c.intValue();
if (mapChildWorksheetLinesByParentLineNo.containsKey(worksheetLineNo)) {
List<Billing_Worksheet_Line__c> childWorksheetLines = mapChildWorksheetLinesByParentLineNo.get(worksheetLineNo);
for (Billing_Worksheet_Line__c childWorksheetLine : childWorksheetLines) {
Map<String, Object> question = new Map<String, Object>();
question.put('Line_No__c', childWorksheetLine.Line_No__c.intValue());
question.put('Category__c', childWorksheetLine.Category__c);
question.put('Resource_Type__c', childWorksheetLine.Resource_Type__c);
question.put('Resource_Type__r', childWorksheetLine.Resource_Type__r);
question.put('Resource__c', childWorksheetLine.Resource__c);
question.put('Resource__r', childWorksheetLine.Resource__r);
question.put('Description__c', childWorksheetLine.Description__c);
question.put('Unit_of_Measure__c', childWorksheetLine.Unit_of_Measure__c);
question.put('Unit_of_Measure__r', childWorksheetLine.Unit_of_Measure__r);
question.put('Cost_Method__c', childWorksheetLine.Cost_Method__c);
question.put('Unit_Weight_Vol__c', childWorksheetLine.Unit_Weight_Vol__c);
question.put('Unit_Weight_Vol__r', childWorksheetLine.Unit_Weight_Vol__r);
question.put('Container_Size__c', childWorksheetLine.Container_Size__c);
question.put('Container_Size__r', childWorksheetLine.Container_Size__r);
question.put('Resource_Type_UOM__c', childWorksheetLine.Resource_Type_UOM__c);
question.put('Resource_Type_UOM__r', childWorksheetLine.Resource_Type_UOM__r);
question.put('Resource_UOM__c', childWorksheetLine.Resource_UOM__c);
question.put('Resource_UOM__r', childWorksheetLine.Resource_UOM__r);
question.put('Unit_Price__c', childWorksheetLine.Unit_Price__c);
question.put('xUnit_Price__c', childWorksheetLine.xUnit_Price__c);
question.put('Unit_Cost__c', childWorksheetLine.Unit_Cost__c);
question.put('xUnit_Cost__c', childWorksheetLine.xUnit_Cost__c);
question.put('Tax_Group__c', childWorksheetLine.Tax_Group__c);
question.put('Tax_Pct__c', childWorksheetLine.Tax_Pct__c);
question.put('Tax__c', childWorksheetLine.Tax__c);
question.put('Regular_Rate__c', childWorksheetLine.Regular_Rate__c);
question.put('Overtime_Rate__c', childWorksheetLine.Overtime_Rate__c);
question.put('Premium_Rate__c', childWorksheetLine.Premium_Rate__c);
question.put('xRegular_Rate__c', childWorksheetLine.xRegular_Rate__c);
question.put('xOvertime_Rate__c', childWorksheetLine.xOvertime_Rate__c);
question.put('xPremium_Rate__c', childWorksheetLine.xPremium_Rate__c);
question.put('Pricing_Source_2__c', childWorksheetLine.Pricing_Source_2__c);
question.put('Line_Amount__c', childWorksheetLine.Line_Amount__c);
question.put('xLine_Amount__c', childWorksheetLine.xLine_Amount__c);
question.put('Line_Amt_Incl_Tax__c', childWorksheetLine.Line_Amt_Incl_Tax__c);
question.put('Line_Cost__c', childWorksheetLine.Line_Cost__c);
question.put('xLine_Cost__c', childWorksheetLine.xLine_Cost__c);
question.put('Contract_Line__c', childWorksheetLine.Contract_Line__c);
question.put('Contract_Line__r', childWorksheetLine.Contract_Line__r);
//child follows the parent lines' TM

question.put('TM__c', worksheetLine.TM__c);
question.put('TM__r', worksheetLine.TM__r);
question.put('TM_Job_Task__c', worksheetLine.TM_Job_Task__c);
question.put('TM_Job_Task__r', worksheetLine.TM_Job_Task__r);

String questionDescription = 'Parent Line #' + worksheetLine.Line_No__c.intValue() + ': ' + worksheetLine.Description__c;
questionDescription += ', Quantity ';
if (worksheetLine.Category__c == 'Lbor' || worksheetLine.Category__c == 'Equipment') {
questionDescription += '1';
}
else {
questionDescription += worksheetLine.Quantity__c;
}
questionDescription += '</br>';
questionDescription += '<span style="padding-left:50px;">Child resource ' + childWorksheetLine.Description__c + ' has ZERO quantity. Do you want to change the quantity?</span>';
question.put('Question__c', questionDescription);
question.put('Parent_Line__c', worksheetLine.Id);
question.put('Parent_Line__r', new Billing_Worksheet_Line__c(Id = worksheetLine.Id, Line_No__c = worksheetLine.Line_No__c));
questions.add(question);
}
}
}

if (questions.size() > 0) {
mapQuestionsByTaskIndex.put(i, questions); //by job task wrapper index
}
}
}

return JSON.serialize(mapQuestionsByTaskIndex);
}
catch(exception ex) {
throw new AuraHandledException(ex.getMessage());
}
}
*/
    //ticket 19130 >>
    
    @AuraEnabled
    //public static Id createSalesInvoice(Id salesOrderId, String JSONWorksheets, String JSONSelectedLineNos) {
    public static Id createSalesInvoice(Id salesOrderId, String JSONWorksheets) {
        Map<Integer, Integer> LineNoMap = new Map<Integer, Integer>();
        try {
            //85892
            Sales_Order__c salesOrder = [SELECT ID,Bill_to_Customer_No__r.Sage_Customer_No__c, Bill_to_Customer_No__r.MsgRetailNational__c
                                         FROM Sales_Order__c 
                                         WHERE ID=:salesOrderId Limit 1];
            
            if(salesOrder.Bill_to_Customer_No__r.Sage_Customer_No__c != null) {
                
                CustomerDetailsService.EQAIflagStatus customerDetails = CustomerDetailsService.getCustomerDetails(salesOrder.Bill_to_Customer_No__r.Sage_Customer_No__c);
                
                // Retrieve the related Account record
                Account acc = [SELECT Id, MsgRetailNational__c,MSG__c,Retail__c,National_Account__c,Intercompany__c, Prevent_Billing_Project__c
                               FROM Account
                               WHERE Id = :salesOrder.Bill_to_Customer_No__r.Id LIMIT 1];
                
                if(customerDetails.msg == 'T') {
                    acc.MSG__c = true;
                } 
                else
                {
                    acc.MSG__c = false;
                }
                if(customerDetails.retail == 'T') {
                    acc.Retail__c = true;
                } 
                else
                {
                    acc.Retail__c = false;
                }
                if(customerDetails.nationalAccount == 'T') {
                    acc.National_Account__c = true;
                } 
                else
                {
                    acc.National_Account__c = false;
                }
                if(customerDetails.customerFlag == 'T') {
                    acc.MsgRetailNational__c = true;
                } 
                else
                {
                    acc.MsgRetailNational__c = false;
                }
                if(customerDetails.preventBPFlag == 'T')
                {
                    acc.Prevent_Billing_Project__c = true;
                }
                
                else {
                    acc.Prevent_Billing_Project__c = false;
                }
                if(customerDetails.eq_flag == 'T')
                {
                    acc.Intercompany__c = true;
                }
                
                else {
                    acc.Intercompany__c = false;
                }
                update acc;
            }
            
            system.debug(salesOrder.Bill_to_Customer_No__r);
            List<BillingWorksheetWrapper> worksheetWrappers = (List<BillingWorksheetWrapper>)JSON.deserialize(JSONWorksheets, List<BillingWorksheetWrapper>.class);
            //remove lines that are not selected to invoice
            for (BillingWorksheetWrapper worksheetWrapper : worksheetWrappers) {
                for (Integer i = 0; i < worksheetWrapper.WorksheetLines.size(); i++) {
                    Billing_Worksheet_Line__c worksheetLine = worksheetWrapper.WorksheetLines[i];
                    if (worksheetLine.To_Invoice__c != true) {
                        worksheetWrapper.WorksheetLines.remove(i);
                        i--;
                    }
                    else {
                        /*
if (worksheetLine.Bill_as_Lump_Sum__c == true || worksheetLine.Non_Billable__c == true) {
if (worksheetLine.xUnit_Cost__c == 0 || worksheetLine.xUnit_Cost__c == null) {
throw new DataException('Worksheet line #' + worksheetLine.Line_No__c + ' must not have zero unit cost.');
}
}
else {
if (worksheetLine.Unit_Cost__c == 0 || worksheetLine.Unit_Cost__c == null) {
throw new DataException('Worksheet line #' + worksheetLine.Line_No__c + ' must not have zero unit cost.');
}
}*/
                        if (worksheetLine.Category__c != 'Bundled' && worksheetLine.Category__c != 'Demurrage' && worksheetLine.Category__c != 'Misc. Charges And Taxes') {
                            if (worksheetLine.Unit_Cost__c == 0 || worksheetLine.Unit_Cost__c == null) {
                                 if(worksheetLine.Disposal_Billing_Method__c != 'Direct')
                               		 throw new DataException('Worksheet line #' + worksheetLine.Line_No__c + ' must not have zero unit cost.');
                            }
                        }
                    }
                    LineNoMap.put(i , Integer.valueOf(worksheetLine.Line_No__c));	//DE37758
                }
            }
            for (Integer i = 0; i < worksheetWrappers.size(); i++) {
                if (worksheetWrappers[i].WorksheetLines.size() == 0) {
                    worksheetWrappers.remove(i);
                    i--;
                }
            }
            
            if (worksheetWrappers.size() == 0) {
                throw new DataException('There is nothing to invoice.');
            }
            
            //return createSalesInvoice(salesOrderId, worksheetLines);
            return createSalesInvoice(salesOrderId, worksheetWrappers);
        }
        catch(exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            String LineNo = ex.getMessage().subStringBetween('exception on row ', '; first error');	
            String errMsg = 'An error occured in Line #: ' + String.valueOf(LineNoMap.get(Integer.valueOf(LineNo))) + '.';	//DE37758
            String errorMessage = ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? errMsg + ex.getMessage().substring( ex.getMessage().indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION,'.length()): ex.getMessage();
            throw new AuraHandledException(errorMessage);
        }
    }
    
    @AuraEnabled
    public static id createSalesInvoiceFromWorksheetLines(Id salesOrderId, String JSONSalesOrderJobTaskIds, String JSONWorksheetLineIds) {
        try {
            List<Id> salesOrderJobTaskIds = (List<Id>)JSON.deserialize(JSONSalesOrderJobTaskIds, List<Id>.class);
            List<Id> worksheetLineIds = (List<Id>)JSON.deserialize(JSONWorksheetLineIds, List<Id>.class);
            
            
            List<Sales_Order_Job_Task__c> salesOrderJobTasks = SalesOrderJobTasksSelector.newInstance().selectById(new Set<Id>(salesOrderJobTaskIds));
            List<Billing_Worksheet_Line__c> worksheetLines = BillingWorksheetLinesSelector.newInstance().selectById(new Set<Id>(worksheetLineIds));
            
            Map<Id, BillingWorksheetWrapper> mapWorksheetWrappersBySalesOrderTaskId = new Map<Id, BillingWorksheetWrapper>();
            Set<Id> salesOrderIds = new Set<Id>();
            for (Sales_Order_Job_Task__c salesOrderJobTask : salesOrderJobTasks) {
                BillingWorksheetWrapper worksheetWrapper = new BillingWorksheetWrapper();
                worksheetWrapper.SalesOrderJobTask = salesOrderJobTask;
                mapWorksheetWrappersBySalesOrderTaskId.put(salesOrderJobTask.Id, worksheetWrapper);
            }
            
            for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
                if (worksheetLine.Invoiced__c == true) {
                    throw new DataException('Worksheet line ' + worksheetLine.Line_No__c + ' is already invoiced.');
                }
                BillingWorksheetWrapper worksheetWrapper;
                if (mapWorksheetWrappersBySalesOrderTaskId.containsKey(worksheetLine.Sales_Order_Job_Task__c)) {
                    worksheetWrapper = mapWorksheetWrappersBySalesOrderTaskId.get(worksheetLine.Sales_Order_Job_Task__c);
                    worksheetWrapper.WorksheetLines.add(worksheetLine);
                }
            }
            
            for (Id salesOrderJobTaskId : mapWorksheetWrappersBySalesOrderTaskId.keySet()) {
                BillingWorksheetWrapper worksheetWrapper = mapWorksheetWrappersBySalesOrderTaskId.get(salesOrderJobTaskId);
                if (worksheetWrapper.WorksheetLines.size() == 0) {
                    mapWorksheetWrappersBySalesOrderTaskId.remove(salesOrderJobTaskId);
                }
            }
            
            return createSalesInvoice(salesOrderId, mapWorksheetWrappersBySalesOrderTaskId.values());
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        
    }
    
    //private static Id createSalesInvoice(Id salesOrderId, List<Billing_Worksheet_Line__c> worksheetLines) {
    private static Id createSalesInvoice(Id salesOrderId, List<BillingWorksheetWrapper> worksheetWrappers) {
        Savepoint sp = Database.setSavepoint();
        CompanyMgmt.systemCall = true;
        try {
            /* not needed, create manifest fee line should already happen in saveWorksheet()
List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectById(new Set<Id>{ salesOrderId });
Sales_Order__c salesOrder = salesOrders[0];
if(salesOrder.Manifest_And_Profile__c == true && Test.isRunningTest() == false) {
calculateManifestFeeLines(salesOrder, worksheetWrappers);
}*/
            Sales_Invoice__c salesInvoice = BillingWorksheetService.createSalesInvoice(salesOrderId, worksheetWrappers);
            return salesInvoice.Id;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }
    
    @AuraEnabled
    public static String getTMBillingPDFUrl(String ids) {
        try {
            List<String> jobTaskIds = (List<String>) JSON.deserialize(ids, List<String>.class);
            String pdfUrl = Url.getSalesforceBaseUrl() + '/NewTMBillingPDF?ids=' + String.join(jobTaskIds, ';');
            return pdfUrl;
        }
        catch(exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }
    
    private static TM_Line__c createTMLineFromWorksheetLine(Integer lineNo, Billing_Worksheet_Line__c worksheetLine) {
        TM_Line__c tmLine = new TM_Line__c();
        tmLine.Line_No__c = lineNo;
        tmLine.TM__c = worksheetLine.TM__c;
        tmLine.From_Billing_Worksheet__c = true;
        return  copyWorksheetLineFieldsToTMLine(worksheetLine, tmLine);
    }
    
    private static TM_Line__c copyWorksheetLineFieldsToTMLine(Billing_Worksheet_Line__c worksheetLine, TM_Line__c tmLine) {
        tmLine.TM_Job_Task__c = worksheetLine.TM_Job_Task__c;
        tmLine.Category__c = worksheetLine.Category__c;
        tmLine.Resource_Type__c = worksheetLine.Resource_Type__c;
        tmLine.Resource__c = worksheetLine.Resource__c;
        tmLine.Service_Center__c = worksheetLine.Service_Center__c;
        tmLine.Unit_of_Measure__c = worksheetLine.Unit_of_Measure__c;
        tmLine.Description__c = worksheetLine.Description__c;
        tmLine.Resource_Name__c = worksheetLine.Resource_Name__c;
        tmLine.Quantity__c = worksheetLine.Quantity__c;
        /*Waste001
tmLine.Cost_Method__c = worksheetLine.Cost_Method__c;
tmLine.Unit_Weight_Vol__c = worksheetLine.Unit_Weight_Vol__c;
tmLine.Container_Size__c = worksheetLine.Container_Size__c;
*/
        tmLine.Cost_Method__c = null;
        tmLine.Unit_Weight_Vol__c = null;
        tmLine.Container_Size__c = null;
        
        tmLine.Facility__c = worksheetLine.Facility__c;
        tmLine.BOL_Manifest__c = worksheetLine.BOL_Manifest__c;
        tmLine.Resource_Type_UOM__c = worksheetLine.Resource_Type_UOM__c;
        tmLine.Resource_UOM__c = worksheetLine.Resource_UOM__c;
        tmLine.Billing_Worksheet_Line__c = worksheetLine.TM_Line__c;
        tmLine.Job_Start_Time__c = worksheetLine.Job_Start_Time__c;
        tmLine.Job_End_Time__c = worksheetLine.Job_End_Time__c;
        tmLine.Site_Start_Time__c = worksheetLine.Site_Start_Time__c;
        tmLine.Site_End_Time__c = worksheetLine.Site_End_Time__c;
        tmLine.Total_Job_Hours__c = worksheetLine.Total_Job_Hours__c;
        tmLine.Total_Site_Hours__c = worksheetLine.Total_Site_Hours__c;
        tmLine.Bill_as_Lump_Sum__c = worksheetLine.Bill_as_Lump_Sum__c;
        tmLine.Non_Billable__c = worksheetLine.Non_Billable__c;
        //US128542
        tmLine.Approval_Id__c = worksheetLine.Approval_Id__c;
        //US129137
        tmLine.EQAI_Bill_Unit_Code__c = worksheetLine.EQAI_Bill_Unit_Code__c;
        //Ticket#19334 >>
        tmLine.Include_Lunch_Y_N__c = worksheetLine.Include_Lunch_Y_N__c;
        tmLine.Lunch_Start_Time__c = worksheetLine.Lunch_Start_Time__c;
        tmLine.Lunch_End_Time__c = worksheetLine.Lunch_End_Time__c;
        if(tmLine.Category__c == ResourceService.LABOR_CATEGORY || tmLine.Category__c == ResourceService.EQUIPMENT_CATEGORY) {
            tmLine.Lunch__c = TimeUtils.generateLunchHourString(tmLine.Lunch_Start_Time__c, tmLine.Lunch_End_Time__c);
            if(worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                if(tmLine.Category__c == ResourceService.LABOR_CATEGORY) {
                    tmLine.Quantity__c = CompanyMgmt.zeroIfNull(worksheetLine.Total_Job_Hours__c) - TimeUtils.calculateHours(worksheetLine.Lunch_Start_Time__c, worksheetLine.Lunch_End_Time__c);
                }
                else {
                    if(CompanyMgmt.zeroIfNull(worksheetLine.Total_Job_Hours__c) > 0) {
                        tmLine.Quantity__c = CompanyMgmt.zeroIfNull(worksheetLine.Total_Job_Hours__c);
                    }
                }
            }
        }
        //Ticket#19334 >>
        /*
if(worksheetLine.Category__c == ResourceService.LABOR_CATEGORY || worksheetLine.Category__c == ResourceService.EQUIPMENT_CATEGORY){
if(worksheetLine.Unit_of_Measure__r.Hours_UOM__c == true) {
tmLine.Quantity__c = CompanyMgmt.zeroIfNull(worksheetLine.Total_Job_Hours__c) - TimeUtils.calculateHours(worksheetLine.Lunch_Start_Time__c, worksheetLine.Lunch_End_Time__c);
}
}
*/
        tmLine.Billing_Worksheet_Line__c = worksheetLine.Id;
        
        //ticket 19535 <<
        tmLine.Sales_Line__c = worksheetLine.Sales_Line__c;
        //ticket 19535 >>
        //Ticket#20286
        tmLine.Contract_Line__c = worksheetLine.Contract_Line__c;
        tmLine.Quote_Line__c = worksheetLine.Quote_Line__c;
        //Ticket#20286
        return tmLine;
    }
    
    @Future
    public static void createSalesInvoiceAsync(Id salesOrderId) {
        
        Set<Id> jobTaskIds = new Set<Id>();
        Set<Id> worksheetLineIds = new Set<Id>();
        
        List<Billing_Worksheet_Line__c> worksheetLines = [SELECT Id, Sales_Order_Job_Task__c FROM Billing_Worksheet_Line__c WHERE Sales_Order__c = :salesOrderId AND To_Invoice__c = TRUE AND Invoiced__c != TRUE];
        for (Billing_Worksheet_Line__c worksheetLine : worksheetLines) {
            jobTaskIds.add(worksheetLine.Sales_Order_Job_Task__c);
            worksheetLineIds.add(worksheetLine.Id);
        }
        createSalesInvoiceFromWorksheetLines(salesOrderId, JSON.serialize(jobTaskIds), JSON.serialize(worksheetLineIds));
    }
    
    
  @AuraEnabled
    public static Map<String, List<String>> getValidUOMs() {
        Map<String, List<String>> uomMapping = new Map<String, List<String>>();
        
        List<Sales_Line_EQAI_Mapping__mdt> mappings = [
            SELECT EQAI_Field_Value__c, Salesforce_Field_Value__c 
            FROM Sales_Line_EQAI_Mapping__mdt
        ];
        
        for (Sales_Line_EQAI_Mapping__mdt mapping : mappings) {
            if (!uomMapping.containsKey(mapping.EQAI_Field_Value__c)) {
                uomMapping.put(mapping.EQAI_Field_Value__c, new List<String>());
            }
            uomMapping.get(mapping.EQAI_Field_Value__c).add(mapping.Salesforce_Field_Value__c);
        }
        
        return uomMapping;
    }
    
     @AuraEnabled
    public static List<String> getValidBillUnitCode(String billUnitCode) {
        List<String> validUOMs = new List<String>();
        
        if (String.isNotBlank(billUnitCode)) {
            List<Sales_Line_EQAI_Mapping__mdt> mappings = [
                SELECT Salesforce_Field_Value__c 
                FROM Sales_Line_EQAI_Mapping__mdt
                WHERE EQAI_Field_Value__c = :billUnitCode
            ];
            
            for (Sales_Line_EQAI_Mapping__mdt mapping : mappings) {
                validUOMs.add(mapping.Salesforce_Field_Value__c);
            }
        }
        system.debug('validUOMs'+validUOMs);
        return validUOMs;
    }
    
    
    
}