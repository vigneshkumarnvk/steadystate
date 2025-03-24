/**
 * Created by Kevin on 1/9/2020, to convert the existing sales orders to be lighting compatible.
 */

public with sharing class SalesOrderLightningDataManagement {
    /*
    public final ApexPages.StandardController controller;
    public static Boolean SkipTrigger { set; get; }

    public SalesOrderLightningDataManagement(ApexPages.StandardController controller) {
        this.controller = controller;
    }

    public PageReference MakeSalesOrderLightningCompatible() {
        try { 
            Id salesOrderId = this.controller.getId();
            List<ACVSalesOrderWrapper> salesOrderWrappers = getSalesOrders(new Set<Id>{ salesOrderId });
            MakeSalesOrderLightningCompatible(salesOrderWrappers);
            return this.controller.view().setRedirect(true);
        }
        catch (exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }

    }

    @AuraEnabled
    public static void MakeSalesOrderLightningCompatible(List<ACVSalesOrderWrapper> salesOrderWrappers) {
        Savepoint sp = Database.setSavepoint();

        try {
            List<Sales_Line_Detail__c> salesLineDetailsToUpdate = new List<Sales_Line_Detail__c>();
            List<Sales_Line_Detail__c> salesLineDetailsToDelete = new List<Sales_Line_Detail__c>();

            List<Sales_Order__c> salesOrdersToUpdate = new List<Sales_Order__c>();
            Map<Id, Sales_Line__c> mapSalesLinesToUpdate = new Map<Id, Sales_Line__c>();

            for (ACVSalesOrderWrapper salesOrderWrapper : salesOrderWrappers) {
                Sales_Order__c salesOrder = salesOrderWrapper.SalesOrder;
                if (salesOrderWrapper.SalesLines != null) {
                    Id lumpSumLineId = null;
                    Integer lumpSumLineCount = 0;
                    for (Sales_Line__c salesLine : salesOrderWrapper.SalesLines) {
                        if (salesLine.Category__c == 'Lump Sum') {
                            lumpSumLineCount++;
                            lumpSumLineId = salesLine.Id;
                        }
                        else if (salesLine.Category__c == 'Labor') {
                            Decimal totalRegularHours = 0;
                            Decimal totalOvertimeHours = 0;
                            Decimal totalDoubleTimeHours = 0;

                            //backup the current regular/overtime/double time hours
                            if (salesLine.Hours_Saved_Lightning_Backup__c != true) {
                                salesLine.Regular_Hours_Lightning_Backup__c = salesLine.Regular_Hours__c;
                                salesLine.Overtime_Hours_Lightning_Backup__c = salesLine.Overtime_Hours__c;
                                salesLine.Premium_Hours_Lightning_Backup__c = salesLine.Premium_Hours__c;
                                salesLine.Hours_Saved_Lightning_Backup__c = true;
                            }

                            //delete exisiting
                            for (Sales_Line_Detail__c sld : salesLine.Sales_Line_Details__r) {
                                salesLineDetailsToDelete.add(sld);
                            }

                            Integer numberOfDays = 0;
                            Integer regularDays = 0;
                            Integer overtimeDays = 0;
                            Integer doubleTimeDays = 0;

                            if (salesLine.Number_of_Day__c != null) {
                                numberOfDays = salesLine.Number_of_Day__c.intValue();
                            }
                            if (numberOfDays == 0) {
                                throw new DataException('Sales line ' + salesLine.Id + ': number of days cannot be zero.');
                            }

                            if (salesLine.Regular_Hours_Lightning_Backup__c == null) {
                                salesLine.Regular_Hours_Lightning_Backup__c = 0;
                            }
                            if (salesLine.Overtime_Hours_Lightning_Backup__c == null) {
                                salesLine.Overtime_Hours_Lightning_Backup__c = 0;
                            }
                            if (salesLine.Premium_Hours_Lightning_Backup__c == null) {
                                salesLine.Premium_Hours_Lightning_Backup__c = 0;
                            }

                            if (salesLine.Regular_Day__c != null) {
                                regularDays = salesLine.Regular_Day__c.intValue();
                            }
                            if (salesLine.Overtime_Day__c != null) {
                                overtimeDays = salesLine.Overtime_Day__c.intValue();
                            }
                            if (salesLine.Premium_Day__c != null) {
                                doubleTimeDays = salesLine.Premium_Day__c.intValue();
                            }

                            if (regularDays + overtimeDays + doubleTimeDays > numberOfDays) {
                                throw new DataException('Sales line ' + salesLine.Id + ': total regular/overtime/double time days cannot exceed number of days.');
                            }
                            //some sales lines have 0 regular days.
                            if (regularDays == 0) {
                                regularDays = numberOfDays - overtimeDays - doubleTimeDays;
                            }

                            Integer lineNo = 0;
                            Date scheduledDate = salesOrder.Estimated_Job_Start_Date__c;

                            for (Integer i = 0; i < regularDays; i++) {
                                lineNo++;
                                Decimal regularHours = 0;
                                Decimal overtimeHours = 0;
                                Decimal doubleTimeHours = 0;

                                if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                                    regularHours = salesLine.Regular_Hours_Lightning_Backup__c;
                                    overtimeHours = salesLine.Overtime_Hours_Lightning_Backup__c;
                                    doubleTimeHours = salesLine.Premium_Hours_Lightning_Backup__c;
                                }

                                Sales_Line_Detail__c salesLineDetail = initSalesLineDetail(salesOrder, salesLine, lineNo, scheduledDate, regularHours, overtimeHours, doubleTimeHours);
                                salesLineDetailsToUpdate.add(salesLineDetail);

                                totalRegularHours += regularHours;
                                totalOvertimeHours += overtimeHours;
                                totalDoubleTimeHours += doubleTimeHours;
                                scheduledDate = scheduledDate.addDays(1);
                            }

                            for (Integer i = 0; i < overtimeDays; i++) {
                                lineNo++;
                                Decimal regularHours = 0;
                                Decimal overtimeHours = 0;
                                Decimal doubleTimeHours = 0;

                                if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                                    overtimeHours = salesLine.UOM_Qty__c;
                                }
                                Sales_Line_Detail__c salesLineDetail = initSalesLineDetail(salesOrder, salesLine, lineNo, scheduledDate, 0, overtimeHours, 0);
                                salesLineDetailsToUpdate.add(salesLineDetail);

                                totalRegularHours += regularHours;
                                totalOvertimeHours += overtimeHours;
                                totalDoubleTimeHours += doubleTimeHours;
                                scheduledDate = scheduledDate.addDays(1);
                            }

                            for (Integer i = 0; i < doubleTimeDays; i++) {
                                lineNo++;
                                Decimal regularHours = 0;
                                Decimal overtimeHours = 0;
                                Decimal doubleTimeHours = 0;

                                if (salesLine.Unit_of_Measure__r.Hours_UOM__c == true) {
                                    doubleTimeHours = salesLine.UOM_Qty__c;
                                }

                                Sales_Line_Detail__c salesLineDetail = initSalesLineDetail(salesOrder, salesLine, lineNo, scheduledDate, 0, 0, doubleTimeHours);
                                salesLineDetailsToUpdate.add(salesLineDetail);

                                totalRegularHours += regularHours;
                                totalOvertimeHours += overtimeHours;
                                totalDoubleTimeHours += doubleTimeHours;
                                scheduledDate = scheduledDate.addDays(1);
                            }

                            salesLine.Regular_Hours__c = totalRegularHours;
                            salesLine.Overtime_Hours__c = totalOvertimeHours;
                            salesLine.Premium_Hours__c = totalDoubleTimeHours;
                            mapSalesLinesToUpdate.put(salesLine.Id, salesLine);
                        }
                    }

                    if (lumpSumLineCount == 1) {
                        for (Sales_Line__c salesLine : salesOrderWrapper.SalesLines) {
                            if (salesLine.Bill_as_Lump_Sum__c == true) {
                                Sales_Line__c salesLine2;
                                if (mapSalesLinesToUpdate.containsKey(salesLine.Id)) {
                                    salesLine2 = mapSalesLinesToUpdate.get(salesLine.Id);
                                }
                                else {
                                    salesLine2 = salesLine;
                                }
                                salesLine2.Bundle_Line__c = lumpSumLineId;
                                SalesLinesService.calculateLineTotals(salesOrder, salesLine2);
                                mapSalesLinesToUpdate.put(salesLine2.Id, salesLine2);
                            }
                        }
                    }
                }
                salesOrder.Converted_to_Lightning__c = true;
                salesOrdersToUpdate.add(salesOrder);
            }


            CompanyMgmt.byPassTrigger = true;
            CompanyMgmt.systemCall = true;

            if (salesLineDetailsToDelete.size() > 0) {
                delete salesLineDetailsToDelete;
            }
            if (salesLineDetailsToUpdate.size() > 0) {
                insert salesLineDetailsToUpdate;
            }

            if (mapSalesLinesToUpdate.size() > 0) {
                update mapSalesLinesToUpdate.values();
            }
            
            if (salesOrdersToUpdate.size() > 0) {
                update salesOrdersToUpdate;
            }
            
            CompanyMgmt.byPassTrigger = false;
        }
        catch(exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    public static Sales_Line_Detail__c initSalesLineDetail(Sales_Order__c salesOrder, Sales_Line__c salesLine, Integer lineNo, Date scheduleDate, Decimal regularHours, Decimal overtimeHours, Decimal premiumHours) {
        Sales_Line_Detail__c salesLineDetail = new Sales_Line_Detail__c();
        salesLineDetail.Sales_Line__c = salesLine.Id;
        salesLineDetail.Line_Number__c = lineNo;
        salesLineDetail.Scheduled_Date__c = scheduleDate;
        salesLineDetail.Regular_Rate__c = CompanyMgmt.zeroIfNull(salesLine.Regular_Rate__c);
        salesLineDetail.Overtime_Rate__c = CompanyMgmt.zeroIfNull(salesLine.Overtime_Rate__c);
        salesLineDetail.Premium_Rate__c = CompanyMgmt.zeroIfNull(salesLine.Premium_Rate__c);
        salesLineDetail.Unit_Price__c = CompanyMgmt.zeroIfNull(salesLine.Unit_Price__c);
        salesLineDetail.Unit_Cost__c = CompanyMgmt.zeroIfNull(salesLine.Unit_Cost__c);
        salesLineDetail.Unit_of_Measure__c = salesLine.Unit_of_Measure__c;
        salesLineDetail.Unit_of_Measure__r = salesLine.Unit_of_Measure__r;
        salesLineDetail.Quantity__c = CompanyMgmt.zeroIfNull(salesLine.Quantity__c);
        salesLineDetail.UOM_Qty__c = CompanyMgmt.zeroIfNull(salesLine.UOM_Qty__c);
        if (salesLineDetail.UOM_Qty__c == 0) {
            salesLineDetail.UOM_Qty__c = 1;
        }

        salesLineDetail.Regular_Hours__c = regularHours;
        salesLineDetail.Overtime_Hours__c = overtimeHours;
        salesLineDetail.Premium_Hours__c = premiumHours;


        if (salesLineDetail.Unit_of_Measure__r != null && salesLineDetail.Unit_of_Measure__r.Hours_UOM__c == true) {
            salesLineDetail.Line_Amount__c =
                    CompanyMgmt.halfUpTo2D(salesLineDetail.Regular_Rate__c * salesLineDetail.Regular_Hours__c * salesLineDetail.Quantity__c)
                            + CompanyMgmt.halfUpTo2D(salesLineDetail.Overtime_Rate__c * salesLineDetail.Overtime_Hours__c * salesLineDetail.Quantity__c)
                            + CompanyMgmt.halfUpTo2D(salesLineDetail.Premium_Rate__c * salesLineDetail.Premium_Hours__c * salesLineDetail.Quantity__c);
        }
        else {
            salesLineDetail.Line_Amount__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c * salesLineDetail.Unit_Price__c);
        }
        salesLineDetail.Line_Cost__c = CompanyMgmt.halfUpTo2D(salesLineDetail.Unit_Cost__c * salesLineDetail.Quantity__c * salesLineDetail.UOM_Qty__c);
        return salesLineDetail;
    }



    //init xUnit_Cost__c xLine_Cost__c and xLine_Amount
    public static void UpdateXFields(List<Sales_Line__c> salesLines) {
    
       Savepoint sp = Database.setSavepoint();
       
       
       try {
           for (Sales_Line__c salesLine : salesLines) {
                if (salesLine.xUnit_Price__c == null || salesLine.xUnit_Price__c == 0) {
                    salesLine.xUnit_Price__c = salesLine.Unit_Price__c;
                }
               salesLine.xUnit_Cost__c = salesLine.Unit_Cost__c;
               salesLine.xLine_Cost__c = salesLine.Line_Cost__c;
               salesLine.xLine_Amount__c = salesLine.Line_Amount__c;
               salesLine.xUnit_Cost_Updated__c = true;
           }
           
           CompanyMgmt.ByPassTrigger = true;
           update salesLines;
           CompanyMgmt.ByPassTrigger = false;
       }
       catch(Exception ex) {
           Database.rollback(sp);
           throw ex;
       }       
    }

    public static List<ACVSalesOrderWrapper> getSalesOrders(Set<Id> salesOrderIds) {
        List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectById(salesOrderIds);
        List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesWithDetailsBySalesOrderId(salesOrderIds);

        Map<Id, ACVSalesOrderWrapper> mapSalesOrderWrappers = new Map<Id, ACVSalesOrderWrapper>();
        for (Sales_Order__c salesOrder : salesOrders) {
            if (!mapSalesOrderWrappers.containsKey(salesOrder.Id)) {
                ACVSalesOrderWrapper salesOrderWrapper = new ACVSalesOrderWrapper(salesOrder, new List<Sales_Line__c>());
                mapSalesOrderWrappers.put(salesOrder.Id, salesOrderWrapper);
            }
        }

        for (Sales_Line__c salesLine : salesLines) {
            if (mapSalesOrderWrappers.containsKey(salesLine.Sales_Order__c)) {
                mapSalesOrderWrappers.get(salesLine.Sales_Order__c).SalesLines.add(salesLine);
            }
        }

        return mapSalesOrderWrappers.values();
    }
    */
}