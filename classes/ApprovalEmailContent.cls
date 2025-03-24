public with sharing class ApprovalEmailContent {
    public Id recordId {get; set;}

    public ApprovalEmailContent(){}
    
    public ApprovalEmailContent(Id recordId){
        this.recordId = recordId;
    }

    public EmailContent emailContentWrapper{
        get{
            EmailContent emailContent = new EmailContent();
            if(recordId != null){
                String objectAPIName = recordId.getSobjectType().getDescribe().getName();
                if(objectAPIName == 'Sales_Invoice__c') emailContent = getSalesInvoiceContent();
                if(objectAPIName == 'Sales_Order__c') emailContent = getSalesOrderContent();
            }
            return emailContent;
        }
    }

    public class EmailContent{
        public String docType{get; set;}
        public String invoiceNo{get; set;}
        public String serviceCenter{get; set;}
        public String billToCustomer {get; set;}
        public String createdBy{get; set;}
        public String salesOrderOwner{get; set;}
        public String payRule{get; set;}
        public String scopeOfWork{get; set;}
        public Decimal newProfitMargin{get; set;}
        public Decimal approvedProfitMargin{get; set;}
        public Decimal marginDifference{get; set;}
        public Decimal invoiceTotalInclTax{get; set;}
        public Decimal duration{get; set;}
        public List<LineContent> lineContents{get; set;}
        public Map<String, List<LineContent>> lineContentsByJobTasks {get; set;}
        public Map<Integer, String> approverByLevels {get; set;}
        public List<String> approvalComments {get; set;}
    }

    public class LineContent{
        public String jobTaskName {get; set;}
        public Decimal jobTaskNo {get; set;}
        public Decimal lineNo {get; set;}
        public String category {get; set;}
        public String resType {get; set;}
        public String resName {get; set;}
        public Decimal quantity {get; set;}
        public Decimal uomQty {get; set;}
        public Decimal approvedQuantity {get; set;}
        public Decimal quantityDifference {get; set;}
        public Decimal unitCost {get; set;}
        public Decimal approvedUnitCost {get; set;}
        public Decimal unitCostDifference{get; set;}
        public Decimal unitPrice {get; set;}
        public Decimal regularRate {get; set;}
        public Decimal overtimeRate {get; set;}
        public Decimal doubleTimeRate {get; set;}
        public Decimal daysNeeded {get; set;}
        public Decimal approvedUnitPrice {get; set;}
        public Decimal unitPriceDifference {get; set;}
        public String unitOfMeasure {get; set;}
        public String approvedUnitOfMeasure {get; set;}
        public Decimal lineCost{get; set;}
        public Decimal approvedLineCost {get; set;}
        public Decimal lineCostDifference {get; set;}
        public Decimal lineAmount {get; set;}
        public Decimal approvedLineAmount {get; set;}
        public Decimal lineAmountDifference {get; set;}
        public Decimal lineAmountInclTax {get; set;}
        public List<LineContent> relatedLines {get; set;}
    }

    public EmailContent getSalesOrderContent(){
        EmailContent emailContent = new EmailContent();
        List<Sales_Order__c> salesOrders = SalesOrdersSelector.newInstance().selectByIdWithLinesAndProcessSteps(new Set<Id>{recordId});
        List<Sales_Line__c> salesLines = SalesLinesSelector.newInstance().selectLinesBySalesOrderId(new Set<Id>{recordId});
        Map<Id, Sales_Line__c> salesLinesByIds = new Map<Id, Sales_Line__c>();
        salesLinesByIds.putAll(salesLines);
        List<Sales_Line_Detail__c> salesLineDetails = [SELECT Id, Unit_of_Measure__r.Name, Unit_of_Measure__r.Hours_UOM__c, Sales_Line__c, Sales_Line__r.Category__c,
                Unit_of_Measure__c, Regular_Rate__c, Regular_Hours__c, Overtime_Rate__c, Overtime_Hours__c,
                Premium_Hours__c, Premium_Rate__c FROM Sales_Line_Detail__c WHERE Sales_Line__c IN :salesLinesByIds.keySet()];

        Map<Id, Map<String, Decimal>> hoursByTimeTypeBySalesLineIds = new Map<Id, Map<String, Decimal>>();
        for(Sales_Line_Detail__c salesLineDetail : salesLineDetails){
            if(salesLineDetail.Sales_Line__r.Category__c == ResourceService.LABOR_CATEGORY && salesLineDetail.Unit_of_Measure__r.Hours_UOM__c == true){
                Map<String, Decimal> hoursByTimeType = new Map<String, Decimal>();
                if(hoursByTimeTypeBySalesLineIds.containsKey(salesLineDetail.Sales_Line__c)){
                    hoursByTimeType = hoursByTimeTypeBySalesLineIds.get(salesLineDetail.Sales_Line__c);
                } else {
                    hoursByTimeType.put('REG', 0);
                    hoursByTimeType.put('OT', 0);
                    hoursByTimeType.put('DT', 0);
                }

                if(CompanyMgmt.zeroIfNull(salesLineDetail.Regular_Hours__c) > 0){
                    Decimal hours = salesLineDetail.Regular_Hours__c;
                    hoursByTimeType.put('REG', hoursByTimeType.get('REG') + hours);
                }

                if(CompanyMgmt.zeroIfNull(salesLineDetail.Overtime_Hours__c) > 0){
                    Decimal hours = salesLineDetail.Overtime_Hours__c;
                    hoursByTimeType.put('OT', hoursByTimeType.get('OT') + hours);
                }

                if(CompanyMgmt.zeroIfNull(salesLineDetail.Premium_Hours__c) > 0){
                    Decimal hours = salesLineDetail.Premium_Hours__c;
                    hoursByTimeType.put('DT', hoursByTimeType.get('DT') + hours);
                }

                hoursByTimeTypeBySalesLineIds.put(salesLineDetail.Sales_Line__c, hoursByTimeType);
            }
        }

        if(salesOrders.size() > 0){
            Sales_Order__c salesOrder = salesOrders[0];
            String docType = salesOrder.Document_Type__c == 'Sales Order' ? 'SALES_ORDER' : 'SALES_QUOTE';
            emailContent.docType = salesOrder.Document_Type__c;
            emailContent.invoiceNo = salesOrder.Name;
            emailContent.serviceCenter = salesOrder.Service_Center__r.Name;
            emailContent.approvedProfitMargin = CompanyMgmt.zeroIfNull(salesOrder.Approved_Profit_Margin__c);
            emailContent.newProfitMargin = CompanyMgmt.zeroIfNull(salesOrder.Total_Profit_Pct__c);
            //emailContent.invoiceTotalInclTax = CompanyMgmt.zeroIfNull(salesOrder.Total_Amount_Incl_Tax__c);
            emailContent.invoiceTotalInclTax = CompanyMgmt.zeroIfNull(salesOrder.Order_Total_Amount_Incl_Tax__c);
            emailContent.marginDifference = emailContent.newProfitMargin - emailContent.approvedProfitMargin;
            emailContent.billToCustomer = salesOrder.Bill_to_Customer_No__r.Name;
            emailContent.createdBy = salesOrder.CreatedBy.Name;
            emailContent.salesOrderOwner = salesOrder.Owner.Name;
            emailContent.payRule = salesOrder.Pay_Rule__r.Name;
            emailContent.scopeOfWork = salesOrder.Site_Scope__c;
            emailContent.duration = salesOrder.Duration__c;
            List<Approval_Tree__c> approvalTrees = ApprovalTreesSelector.newInstance().
                    getApprovalTreeByDocTypeBySrvCtrByOrderType(
                            docType,
                            salesOrder.Service_Center__c,
                            salesOrder.Sales_Order_Type__c);
            Map<Integer, String> approverByLevels = new Map<Integer, String>();
            for(Approval_Tree__c approvalTree:approvalTrees){
                approverByLevels.put(approvalTree.Level__c.intValue(), approvalTree.Approver__r.Name);
            }
            emailContent.approverByLevels = approverByLevels;
            List<String> approvalComment = new List<String>();
            for(ProcessInstanceHistory processInstanceHistory: salesOrder.ProcessSteps){
                approvalComment.add('<td>' + processInstanceHistory.Actor.Name + '</td> ' +
                        '<td>' + processInstanceHistory.Comments + '</td>' +
                        '<td>' + processInstanceHistory.CreatedDate + '</td>');
            }
            emailContent.approvalComments = approvalComment;
            List<LineContent> contentLines = new List<LineContent>();
            Map<Integer, List<LineContent>> relatedLinesBySalesLineId = new Map<Integer, List<ApprovalEmailContent.LineContent>>();
            for(Sales_Line__c recordLine : salesLines){
                if(recordLine.Category__c == ResourceService.LABOR_CATEGORY && hoursByTimeTypeBySalesLineIds.containsKey(recordLine.Id)){
                    Map<String, Decimal> hoursByTimeType = hoursByTimeTypeBySalesLineIds.get(recordLine.Id);
                    for(String timeType : hoursByTimeType.keySet()){
                        Decimal hours = hoursByTimeType.get(timeType);
                        if(hours > 0) {
                            generateLineContent(recordLine, timeType, hours, contentLines, relatedLinesBySalesLineId);
                        }
                    }
                } else {
                    generateLineContent(recordLine, '', 0, contentLines, relatedLinesBySalesLineId);
                }
            }

            //System.debug('Info: relatedLinesBySalesLineId ' + relatedLinesBySalesLineId);

            Map<String, List<LineContent>> lineContentByJobTasks = new Map<String, List<ApprovalEmailContent.LineContent>>();
            for(LineContent lineContent : contentLines){
                if(relatedLinesBySalesLineId.containsKey(lineContent.lineNo.intValue())){
                    //System.debug('Info: lineContent: ' + lineContent);
                    lineContent.relatedLines = relatedLinesBySalesLineId.get(lineContent.lineNo.intValue());
                }

                List<LineContent> lineContents = new List<ApprovalEmailContent.LineContent>();
                String jobTaskDescription = 'Task ' + lineContent.jobTaskNo + ' - ' + lineContent.jobTaskName;
                if(lineContentByJobTasks.containsKey(jobTaskDescription)){
                    lineContents = lineContentByJobTasks.get(jobTaskDescription);
                }

                lineContents.add(lineContent);
                lineContentByJobTasks.put(jobTaskDescription, lineContents);
            }

            //System.debug('Info: lineContent: ' + contentLines);

            emailContent.lineContents = contentLines;
            emailContent.lineContentsByJobTasks = lineContentByJobTasks;

            //if(1==1) throw new DataException('xxxx');
        }

        return emailContent;
    }

    public EmailContent getSalesInvoiceContent(){

        EmailContent emailContent = new EmailContent();

        List<Sales_Invoice__c> invoiceList = SalesInvoicesSelector.newInstance().selectByIdWithLinesAndProcessSteps(new Set<Id>{recordId});
        if(invoiceList.size() > 0){
            Sales_Invoice__c invoiceRecord = invoiceList[0];
            Id serviceCenterId = invoiceRecord.Service_Center__c != null ? invoiceRecord.Service_Center__c : null;
            Id orderTypeId = invoiceRecord.Sales_Order__r.Sales_Order_Type__c != null ? invoiceRecord.Sales_Order__r.Sales_Order_Type__c : null;

            Decimal approvedProfitMargin = 0;
            Map<Id, Sales_Invoice_Line__c> approvedInvoiceLinesByTMLineIds = new Map<Id, Sales_Invoice_Line__c>();
            if(invoiceRecord.Worksheet__c == true){
                List<Sales_Invoice__c> parentInvoices = SalesInvoicesSelector.newInstance().selectByIdWithSILines(new Set<Id>{invoiceRecord.Parent_Record__c});
                if(parentInvoices.size() > 0) approvedProfitMargin = CompanyMgmt.zeroIfNull(parentInvoices[0].Approved_Profit_Margin__c);
                for(Sales_Invoice_Line__c salesInvoiceLine:parentInvoices[0].Sales_Invoice_Lines__r){
                    approvedInvoiceLinesByTMLineIds.put(salesInvoiceLine.TM_Line__c, salesInvoiceLine);
                }
            } else {
                Set<Id> tmLineIds = new Set<Id>();
                for(Sales_Invoice_Line__c salesInvoiceLine: invoiceRecord.Sales_Invoice_Lines__r){
                    tmLineIds.add(salesInvoiceLine.TM_Line__c);
                }
                List<Sales_Invoice_Line__c> approvedCreditMemoWorksheets = SalesInvoiceLinesSelector.newInstance().selectApprovedCreditMemoWorksheetByTMLineIds(tmLineIds);

                if(approvedCreditMemoWorksheets.size() > 0){
                    List<Sales_Invoice__c> approvedCMWWithLines = SalesInvoicesSelector.newInstance().selectByIdWithSILines(new Set<Id>{approvedCreditMemoWorksheets[0].Sales_Invoice__c});
                    approvedProfitMargin = CompanyMgmt.zeroIfNull(approvedCreditMemoWorksheets[0].Sales_Invoice__r.Approved_Profit_Margin__c);

                    for(Sales_Invoice_Line__c salesInvoiceLine:approvedCMWWithLines[0].Sales_Invoice_Lines__r){
                        approvedInvoiceLinesByTMLineIds.put(salesInvoiceLine.TM_Line__c, salesInvoiceLine);
                    }
                }
            }

            if(invoiceRecord.Worksheet__c == true){
                emailContent.docType = 'Credit Memo Worksheet';
            } else if(invoiceRecord.Credit_Memo__c == true){
                emailContent.docType = 'Credit Memo';
            } else {
                emailContent.docType = 'Invoice';
            }
            emailContent.invoiceNo = invoiceRecord.Name;
            emailContent.serviceCenter = invoiceRecord.Service_Center__r.Name;
            emailContent.approvedProfitMargin = approvedProfitMargin;
            emailContent.newProfitMargin = CompanyMgmt.zeroIfNull(invoiceRecord.Invoice_Profit_Prct__c);
            emailContent.invoiceTotalInclTax = CompanyMgmt.zeroIfNull(invoiceRecord.Invoice_Amt_Incl_Tax__c);
            emailContent.marginDifference = emailContent.newProfitMargin - emailContent.approvedProfitMargin;
            emailContent.billToCustomer = invoiceRecord.Bill_to_Customer__r.Name;
            emailContent.createdBy = invoiceRecord.CreatedBy.Name;
            emailContent.salesOrderOwner = invoiceRecord.Sales_Order__r.Owner.Name;
            List<Approval_Tree__c> approvalTrees = ApprovalTreesSelector.newInstance().
                    getApprovalTreeByDocTypeBySrvCtrByOrderType(
                            'SALES_INVOICE',
                            serviceCenterId,
                            orderTypeId);
            Map<Integer, String> approverByLevels = new Map<Integer, String>();
            for(Approval_Tree__c approvalTree:approvalTrees){
                approverByLevels.put(approvalTree.Level__c.intValue(), approvalTree.Approver__r.Name);
            }
            emailContent.approverByLevels = approverByLevels;

            List<String> approvalComment = new List<String>();
            for(ProcessInstanceHistory processInstanceHistory: invoiceRecord.ProcessSteps){
                approvalComment.add(processInstanceHistory.Actor.Name + ': ' + processInstanceHistory.Comments);
            }
            emailContent.approvalComments = approvalComment;


            List<LineContent> salesInvoiceLines = new List<LineContent>();
            for(Sales_Invoice_Line__c recordLine:invoiceRecord.Sales_Invoice_Lines__r){
                LineContent salesInvoiceLine = new LineContent();
                salesInvoiceLine.lineNo = recordLine.Line_No__c;
                salesInvoiceLine.category = recordLine.Category__c;
                salesInvoiceLine.resType = recordLine.Resource_Type__r.Name;
                salesInvoiceLine.resName = recordLine.Resource__r.Name;
                salesInvoiceLine.quantity = recordLine.Quantity__c;
                salesInvoiceLine.unitCost = recordLine.Unit_Cost__c;
                salesInvoiceLine.unitPrice = recordLine.Unit_Price__c;
                salesInvoiceLine.unitOfMeasure = recordLine.Unit_of_Measure__r.Name;
                salesInvoiceLine.lineCost = recordLine.Line_Cost__c;
                salesInvoiceLine.lineAmount = recordLine.Line_Amount__c;
                salesInvoiceLine.lineAmountInclTax = recordLine.Line_Amt_Incl_Tax__c;

                if(approvedInvoiceLinesByTMLineIds.containsKey(recordLine.TM_Line__c)){
                    Sales_Invoice_Line__c approvedInvoiceLine = approvedInvoiceLinesByTMLineIds.get(recordLine.TM_Line__c);
                    salesInvoiceLine.approvedUnitOfMeasure = approvedInvoiceLine.Unit_of_Measure__r.Name;
                    salesInvoiceLine.approvedQuantity = CompanyMgmt.zeroIfNull(approvedInvoiceLine.Quantity__c);
                    salesInvoiceLine.quantityDifference = CompanyMgmt.zeroIfNull(salesInvoiceLine.quantity) - salesInvoiceLine.approvedQuantity;
                    salesInvoiceLine.approvedUnitPrice = CompanyMgmt.zeroIfNull(approvedInvoiceLine.Unit_Price__c);
                    salesInvoiceLine.unitPriceDifference = CompanyMgmt.zeroIfNull(salesInvoiceLine.unitPrice) - salesInvoiceLine.approvedUnitPrice;
                    salesInvoiceLine.approvedUnitCost = CompanyMgmt.zeroIfNull(approvedInvoiceLine.Unit_Cost__c);
                    salesInvoiceLine.unitCostDifference = CompanyMgmt.zeroIfNull(salesInvoiceLine.unitCost) - salesInvoiceLine.approvedUnitCost;
                    salesInvoiceLine.approvedLineAmount = CompanyMgmt.zeroIfNull(approvedInvoiceLine.Line_Amount__c);
                    salesInvoiceLine.lineAmountDifference = CompanyMgmt.zeroIfNull(salesInvoiceLine.lineAmount) - salesInvoiceLine.approvedLineAmount;
                    salesInvoiceLine.approvedLineCost = CompanyMgmt.zeroIfNull(approvedInvoiceLine.Line_Cost__c);
                    salesInvoiceLine.lineCostDifference = CompanyMgmt.zeroIfNull(salesInvoiceLine.lineCost) - salesInvoiceLine.approvedLineCost;
                } else {
                    salesInvoiceLine.approvedQuantity = 0;
                    salesInvoiceLine.quantityDifference = 0;
                    salesInvoiceLine.approvedUnitPrice = 0;
                    salesInvoiceLine.unitPriceDifference = 0;
                    salesInvoiceLine.approvedUnitCost = 0;
                    salesInvoiceLine.unitCostDifference = 0;
                    salesInvoiceLine.approvedLineAmount = 0;
                    salesInvoiceLine.lineAmountDifference = 0;
                    salesInvoiceLine.approvedLineCost = 0;
                    salesInvoiceLine.lineCostDifference = 0;
                }

                salesInvoiceLines.add(salesInvoiceLine);
            }
            emailContent.lineContents = salesInvoiceLines;
        }
        return emailContent;
    }

    public void generateLineContent(Sales_Line__c recordLine, String timeType, Decimal timeTypeTotalHours, List<LineContent> contentLines, Map<Integer, List<LineContent>> relatedLinesBySalesLineId){
        LineContent contentLine = new LineContent();
        contentLine.lineNo = recordLine.Line_No__c;
        //Category Lump Sum is renamed to Bundled
        if(recordLine.Category__c == 'Lump Sum'){
            contentLine.category = 'Bundled';
        } else {
            contentLine.category = recordLine.Category__c;
        }
        contentLine.resType = recordLine.Resource_Type__r.Name;
        contentLine.resName = recordLine.Resource__r.Name;
        if(recordLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY ||
                recordLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY){
            contentLine.resName = recordLine.Description__c;
        }

        if(recordLine.Category__c == ResourceService.LUMP_SUM_CATEGORY){
            contentLine.resType = recordLine.Description__c;
        }

        contentLine.unitPrice = recordLine.Unit_Price__c;

        if(recordLine.Category__c == ResourceService.LABOR_CATEGORY){
            contentLine.unitPrice = recordLine.Regular_Rate__c;
            contentLine.overtimeRate = recordLine.Overtime_Rate__c;
            contentLine.doubleTimeRate = recordLine.Premium_Rate__c;
        }

        contentLine.daysNeeded = recordLine.Number_of_Day__c;
        contentLine.quantity = recordLine.Quantity__c;
        if(recordLine.Category__c == ResourceService.WASTE_DISPOSAL_CATEGORY &&
                CompanyMgmt.zeroIfNull(recordLine.Quantity__c) < CompanyMgmt.zeroIfNull(recordLine.Min_Sell_Qty__c)){
            contentLine.quantity = recordLine.Min_Sell_Qty__c;
        }

        contentLine.unitOfMeasure = recordLine.Unit_of_Measure__r.Name;

        if (recordLine.Bill_as_Lump_Sum__c == true) {
            contentLine.unitCost = recordLine.xUnit_Cost__c;
            contentLine.lineCost = recordLine.xLine_Cost__c;
        } else {
            contentLine.unitCost = recordLine.Unit_Cost__c;
            contentLine.lineCost = recordLine.Line_Cost__c;
        }

        contentLine.lineAmount = recordLine.Line_Amount__c;
        contentLine.lineAmountInclTax = recordLine.Line_Amt_Incl_Tax__c;

        if(recordLine.Category__c == ResourceService.LABOR_CATEGORY && timeTypeTotalHours > 0){
            if(timeType == 'REG'){
                contentLine.unitPrice = recordLine.Regular_Rate__c;
            } else if (timeType == 'OT'){
                contentLine.unitPrice = recordLine.Overtime_Rate__c;
                contentLine.resType = contentLine.resType + '-OT';
            } else if (timeType == 'DT'){
                contentLine.unitPrice = recordLine.Premium_Rate__c;
                contentLine.resType = contentLine.resType + '-DT';
            }
            //contentLine.daysNeeded = null;
            contentLine.uomQty = timeTypeTotalHours;
            if(CompanyMgmt.zeroIfNull(contentLine.daysNeeded) > 0){
                contentLine.uomQty = CompanyMgmt.halfUpTo2D(contentLine.uomQty / contentLine.daysNeeded);
            }
            contentLine.lineCost = timeTypeTotalHours * contentLine.unitCost;
            contentLine.lineAmount = timeTypeTotalHours * contentLine.unitPrice;
        }

        if((recordLine.Category__c == ResourceService.LABOR_CATEGORY || recordLine.Category__c == ResourceService.EQUIPMENT_CATEGORY || recordLine.Category__c == ResourceService.MATERIALS_CATEGORY) &&
                timeTypeTotalHours == 0){
            contentLine.uomQty = recordLine.UOM_Qty__c;

            /*
            if(CompanyMgmt.zeroIfNull(recordLine.Number_of_Day__c) > 0) {
                if (CompanyMgmt.zeroIfNull(recordLine.UOM_Qty__c) > 0) {
                    contentLine.uomQty = contentLine.uomQty * contentLine.daysNeeded;
                } else if (CompanyMgmt.zeroIfNull(recordLine.Quantity__c) > 0) {
                    contentLine.quantity = contentLine.quantity * contentLine.daysNeeded;
                }

                if(recordLine.Category__c == ResourceService.EQUIPMENT_CATEGORY && recordLine.Unit_of_Measure__r.Hours_UOM__c != true){
                    contentLine.quantity = contentLine.daysNeeded * CompanyMgmt.zeroIfNull(recordLine.Quantity__c);
                    contentLine.uomQty = null;
                }
            }
             */

            if(contentLine.uomQty == 0){
                contentLine.uomQty = null;
            }
        }

        contentLine.jobTaskName = recordLine.Sales_Order_Job_Task__r.Name;
        contentLine.jobTaskNo = recordLine.Sales_Order_Job_Task__r.Task_No__c;

        if(String.isNotBlank(recordLine.Bundle_Line__c)){
            //System.debug('Info: Bundle_Line__c Line No. ' + recordLine.Bundle_Line__r.Line_No__c.intValue());
            List<LineContent> relatedLines = new List<ApprovalEmailContent.LineContent>();
            if(relatedLinesBySalesLineId.containsKey(recordLine.Bundle_Line__r.Line_No__c.intValue())){
                relatedLines = relatedLinesBySalesLineId.get(recordLine.Bundle_Line__r.Line_No__c.intValue());
            }
            contentLine.unitPrice = 0;
            contentLine.lineAmount = 0;
            relatedLines.add(contentLine);
            relatedLinesBySalesLineId.put(recordLine.Bundle_Line__r.Line_No__c.intValue(), relatedLines);
        } else {
            contentLines.add(contentLine);
        }
    }
}