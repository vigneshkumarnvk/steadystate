public class InvoiceApprovalEmailContent {

    public Id invoiceRecordId {get; set;}

    public InvoiceApprovalEmailContent(){}

    public SalesInvoice salesInvoicesWrapper{
        get{
            SalesInvoice salesInvoice = new SalesInvoice();

            List<Sales_Invoice__c> invoiceList = SalesInvoicesSelector.newInstance().selectByIdWithLinesAndProcessSteps(new Set<Id>{invoiceRecordId});
            if(invoiceList.size() > 0){
                Sales_Invoice__c invoiceRecord = invoiceList[0];

                List<Sales_Invoice_Line__c> invoiceLines = new List<Sales_Invoice_Line__c>();
                invoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(invoiceRecord.Id);

                Id serviceCenterId = invoiceRecord.Service_Center__c != null ? invoiceRecord.Service_Center__c : null;
                //Id orderTypeId = null;
                Id orderTypeId = invoiceRecord.Sales_Order__r.Sales_Order_Type__c != null ? invoiceRecord.Sales_Order__r.Sales_Order_Type__c : null;

                Decimal approvedProfitMargin = 0;
                //Map<Id, Sales_Invoice_Line__c> approvedInvoiceLinesByTMLineIds = new Map<Id, Sales_Invoice_Line__c>();
                Map<String, Sales_Invoice_Line__c> approvedInvoiceLinesByTMLineIdsAndRateType = new Map<String, Sales_Invoice_Line__c>();
                if(invoiceRecord.Worksheet__c == true){
                    List<Sales_Invoice__c> parentInvoices = SalesInvoicesSelector.newInstance().selectByIdWithSILines(new Set<Id>{invoiceRecord.Parent_Record__c});
                    List<Sales_Invoice_Line__c> parentInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(invoiceRecord.Parent_Record__c);
                    if(parentInvoices.size() > 0) approvedProfitMargin = CompanyMgmt.zeroIfNull(parentInvoices[0].Approved_Profit_Margin__c);
                    //for(Sales_Invoice_Line__c salesInvoiceLine:parentInvoices[0].Sales_Invoice_Lines__r){
                    for(Sales_Invoice_Line__c salesInvoiceLine:parentInvoiceLines){
                        //approvedInvoiceLinesByTMLineIds.put(salesInvoiceLine.TM_Line__c, salesInvoiceLine);
                        approvedInvoiceLinesByTMLineIdsAndRateType.put(salesInvoiceLine.TM_Line__c + ':' + salesInvoiceLine.Time_Rate_Code__c, salesInvoiceLine);
                    }
                } else {
                    Set<Id> tmLineIds = new Set<Id>();
                    //for(Sales_Invoice_Line__c salesInvoiceLine: invoiceRecord.Sales_Invoice_Lines__r){
                    for(Sales_Invoice_Line__c salesInvoiceLine: invoiceLines){
                        if(salesInvoiceLine.TM_Line__c != null) tmLineIds.add(salesInvoiceLine.TM_Line__c);
                    }
                    List<Sales_Invoice_Line__c> approvedCreditMemoWorksheets = SalesInvoiceLinesSelector.newInstance().selectApprovedCreditMemoWorksheetByTMLineIds(tmLineIds);

                    if(approvedCreditMemoWorksheets.size() > 0){
                        //List<Sales_Invoice__c> approvedCMWWithLines = SalesInvoicesSelector.newInstance().selectByIdWithSILines(new Set<Id>{approvedCreditMemoWorksheets[0].Sales_Invoice__c});
                        List<Sales_Invoice_Line__c> approvedCMLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(approvedCreditMemoWorksheets[0].Sales_Invoice__c);
                        if(approvedCreditMemoWorksheets.size() > 0) approvedProfitMargin = CompanyMgmt.zeroIfNull(approvedCreditMemoWorksheets[0].Sales_Invoice__r.Approved_Profit_Margin__c);

                        for(Sales_Invoice_Line__c salesInvoiceLine:approvedCMLines){
                            //approvedInvoiceLinesByTMLineIds.put(salesInvoiceLine.TM_Line__c, salesInvoiceLine);
                            approvedInvoiceLinesByTMLineIdsAndRateType.put(salesInvoiceLine.TM_Line__c + ':' + salesInvoiceLine.Time_Rate_Code__c, salesInvoiceLine);
                        }
                    }
                }

                if(invoiceRecord.Worksheet__c == true){
                    salesInvoice.docType = 'Credit Memo Worksheet';
                } else if(invoiceRecord.Credit_Memo__c == true){
                    salesInvoice.docType = 'Credit Memo';
                } else {
                    salesInvoice.docType = 'Invoice';
                }
                salesInvoice.invoiceNo = invoiceRecord.Name;

                if(invoiceRecord.Worksheet__c == true){
                    salesInvoice.parentRecordNo = invoiceRecord.Parent_Record__r.Name;
                    salesInvoice.linkToOriginalInvoice = System.Url.getSalesforceBaseUrl().toExternalForm() + '/' + invoiceRecord.Parent_Record__c;
                }

                salesInvoice.serviceCenter = invoiceRecord.Service_Center__r.Name;
                salesInvoice.approvedProfitMargin = approvedProfitMargin;
                salesInvoice.newProfitMargin = invoiceRecord.Invoice_Profit_Prct__c;
                salesInvoice.invoiceTotalInclTax = invoiceRecord.Invoice_Amt_Incl_Tax__c;
                salesInvoice.marginDifference = salesInvoice.newProfitMargin - salesInvoice.approvedProfitMargin;
                salesInvoice.billToCustomer = invoiceRecord.Bill_to_Customer__r.Name;
                salesInvoice.createdBy = invoiceRecord.CreatedBy.Name;
                salesInvoice.salesOrderOwner = invoiceRecord.Sales_Order__r.Owner.Name;
                List<Approval_Tree__c> approvalTrees = ApprovalTreesSelector.newInstance().
                        getApprovalTreeByDocTypeBySrvCtrByOrderType(
                                'SALES_INVOICE',
                                serviceCenterId,
                                orderTypeId);
                Map<Integer, String> approverByLevels = new Map<Integer, String>();
                for(Approval_Tree__c approvalTree:approvalTrees){
                    approverByLevels.put(approvalTree.Level__c.intValue(), approvalTree.Approver__r.Name);
                }
                salesInvoice.approverByLevels = approverByLevels;

                List<String> approvalComment = new List<String>();
                for(ProcessInstanceHistory processInstanceHistory: invoiceRecord.ProcessSteps){
                    approvalComment.add(processInstanceHistory.Actor.Name + ': ' + processInstanceHistory.Comments);
                }
                salesInvoice.approvalComments = approvalComment;


                List<SalesInvoiceLine> salesInvoiceLines = new List<SalesInvoiceLine>();
                //for(Sales_Invoice_Line__c recordLine:invoiceRecord.Sales_Invoice_Lines__r){
                Integer insertedLine = 0;
                for(Sales_Invoice_Line__c recordLine:invoiceLines){
                    if(insertedLine <= 500){
                        insertedLine += 1;
                        SalesInvoiceLine salesInvoiceLine = new SalesInvoiceLine();
                        salesInvoiceLine.lineNo = recordLine.Line_No__c;

                        if(recordLine.Category__c == 'Misc. Charges And Taxes'){
                            salesInvoiceLine.category = 'MCT';
                        } else if(recordLine.Category__c == 'Waste Disposal'){
                            salesInvoiceLine.category = 'WD';
                        } else {
                            salesInvoiceLine.category = recordLine.Category__c;
                        }

                        salesInvoiceLine.resType = recordLine.Resource_Type__r.Name;
                        if(recordLine.Category__c == 'Labor'){
                            if(String.isNotBlank(recordLine.Resource__r.Description__c)){
                                salesInvoiceLine.resName = recordLine.Resource__r.Name + '/' + recordLine.Resource__r.Description__c;
                            } else {
                                salesInvoiceLine.resName = recordLine.Resource__r.Name;
                            }
                        } else {
                            salesInvoiceLine.resName = recordLine.Resource__r.Name;
                        }
                        salesInvoiceLine.description = recordLine.Description__c;
                        salesInvoiceLine.quantity = recordLine.Quantity__c;
                        salesInvoiceLine.unitCost = recordLine.Unit_Cost__c;
                        salesInvoiceLine.unitPrice = recordLine.Unit_Price__c;
                        salesInvoiceLine.unitOfMeasure = recordLine.Unit_of_Measure__r.Name;
                        salesInvoiceLine.lineCost = recordLine.Line_Cost__c;
                        salesInvoiceLine.lineAmount = recordLine.Line_Amount__c;
                        salesInvoiceLine.lineAmountInclTax = recordLine.Line_Amt_Incl_Tax__c;

                        //if(approvedInvoiceLinesByTMLineIds.containsKey(recordLine.TM_Line__c)){
                        String mapKey = recordLine.TM_Line__c + ':' + recordLine.Time_Rate_Code__c;
                        if(approvedInvoiceLinesByTMLineIdsAndRateType.containsKey(mapKey)){
                            //Sales_Invoice_Line__c approvedInvoiceLine = approvedInvoiceLinesByTMLineIds.get(recordLine.TM_Line__c);
                            Sales_Invoice_Line__c approvedInvoiceLine = approvedInvoiceLinesByTMLineIdsAndRateType.get(mapKey);
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
                            salesInvoiceLine.approvedUnitOfMeasure = recordLine.Unit_of_Measure__r.Name;
                        }
                        salesInvoiceLines.add(salesInvoiceLine);
                        if(insertedLine == 500){
                            salesInvoiceLine = new SalesInvoiceLine();
                            salesInvoiceLine.description = 'There are more than 500 lines, please login into Salesforce to review all invoice lines.';
                        }
                    }
                }
                salesInvoice.salesInvoiceLines = salesInvoiceLines;

            }

            return salesInvoice;
        }
    }

    public class SalesInvoice{
        public String docType{get; set;}
        public String invoiceNo{get; set;}
        public String parentRecordNo {get; set;}
        public String serviceCenter{get; set;}
        public String billToCustomer {get; set;}
        public String createdBy{get; set;}
        public String salesOrderOwner{get; set;}
        public String linkToOriginalInvoice {get; set;}
        public Decimal newProfitMargin{get; set;}
        public Decimal approvedProfitMargin{get; set;}
        public Decimal marginDifference{get; set;}
        public Decimal invoiceTotalInclTax{get; set;}
        public List<SalesInvoiceLine> salesInvoiceLines{get; set;}
        public Map<Integer, String> approverByLevels {get; set;}
        public List<String> approvalComments {get; set;}
    }

    public class SalesInvoiceLine{
        public Decimal lineNo {get; set;}
        public String category {get; set;}
        public String resType {get; set;}
        public String resName {get; set;}
        public String description {get; set;}
        public Decimal quantity {get; set;}
        public Decimal approvedQuantity {get; set;}
        public Decimal quantityDifference {get; set;}
        public Decimal unitCost {get; set;}
        public Decimal approvedUnitCost {get; set;}
        public Decimal unitCostDifference{get; set;}
        public Decimal unitPrice {get; set;}
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
    }
}