public with sharing class ReverseInvoiceController {
    private final ApexPages.StandardController controller;
    public Sales_Invoice__c salesInvoice { get; set; }
    public String creditMemoNote { get; set; }

    public ReverseInvoiceController(ApexPages.StandardController controller) {
        this.controller = controller;
        Set<Id> salesInvoiceIds = new Set<Id>{ this.controller.getId() };
        this.salesInvoice = SalesInvoicesSelector.newInstance().selectById(salesInvoiceIds)[0];

    }

    public PageReference reverseSalesInvoice() {
        if (String.isEmpty(this.salesInvoice.Credit_Memo_Reason_Code__c)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a credit memo reason code to continue!'));
            return null;
        }

        if(String.isEmpty(creditMemoNote)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Credit Memo Note field must not be blank!'));
            return null;
        } else {
            String tempStr = creditMemoNote;
            tempStr = creditMemoNote.trim();
            if(tempStr.length() < 10){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Credit Memo Note field must be at least 10 characters long!'));
                return null;
            }
        }

        List<Sales_Invoice_Job_Task__c> jobTasks = SalesInvoiceJobTasksSelector.newInstance().selectBySalesInvoiceId(new Set<Id> { this.controller.getId() });
        List<Sales_Invoice_Line__c> invoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(this.controller.getId());

        List<String> errorList = SalesInvoiceMgmt.checkReverseSI(this.salesInvoice);
        if (errorList.size() > 0 && !test.isrunningtest()) {
            for (Integer i = 0; i < errorList.size(); i++) ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, errorList[i]));
            return null;
        } else {
            Savepoint sp = database.setSavePoint();
            try {
                Sales_Invoice__c newSalesInvoice = new Sales_Invoice__c();
                newSalesInvoice = this.salesInvoice.Clone(false, true);
                newSalesInvoice.Credit_Memo__c = true;
                newSalesInvoice.Reversed_from_SI__c = this.salesInvoice.Id;
                newSalesInvoice.Document_Status__c = 'Open';
                newSalesInvoice.Credit_Memo_Reason_Code__c = this.salesInvoice.Credit_Memo_Reason_Code__c;
                newSalesInvoice.Internal_Comments__c = String.isEmpty(newSalesInvoice.Internal_Comments__c) ? creditMemoNote : newSalesInvoice.Internal_Comments__c + '\n' + creditMemoNote; //15090
                newSalesInvoice.Sync_d__c = false;
                insert newSalesInvoice;

                Map<Integer, Sales_Invoice_Job_Task__c> mapNewJobTaskByLineNo = new Map<Integer, Sales_Invoice_Job_Task__c>();
                for (Sales_Invoice_Job_Task__c jobTask : jobTasks) {
                    Sales_Invoice_Job_Task__c newJobTask = jobTask.clone(false, true);
                    newJobTask.Sales_Invoice__c = newSalesInvoice.Id;
                    mapNewJobTaskByLineNo.put(newJobTask.Line_No__c.intValue(), newJobTask);
                }
                insert mapNewJobTaskByLineNo.values();

                List<Sales_Invoice_Line__c> newInvoiceLines = invoiceLines.deepClone();
                if (newInvoiceLines != null && newInvoiceLines.size() > 0) {
                    //ticket 20551 <<
                    //Map<Integer, Sales_Invoice_Line__c> mapBundleLinesByLineNo = new Map<Integer, Sales_Invoice_Line__c>();
                    Map<Integer, Map<Integer, Sales_Invoice_Line__c>> mapBundleLinesByLineNoByTaskLineNo = new Map<Integer, Map<Integer, Sales_Invoice_Line__c>>();
                    //ticket 20551 >>
                    List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();
                    for (Sales_Invoice_Line__c newInvoiceLine : newInvoiceLines) {
                        if (newInvoiceLine.Category__c == 'Bundled') {
                            //ticket 20551 <<
                            //mapBundleLinesByLineNo.put(newInvoiceLine.Line_No__c.intValue(), newInvoiceLine);
                            Map<Integer, Sales_Invoice_Line__c> mapBundleLinesByLineNo;
                            if (mapBundleLinesByLineNoByTaskLineNo.containsKey(newInvoiceLine.Sales_Invoice_Job_Task__r.Line_No__c.intValue())) {
                                mapBundleLinesByLineNo = mapBundleLinesByLineNoByTaskLineNo.get(newInvoiceLine.Sales_Invoice_Job_Task__r.Line_No__c.intValue());
                            }
                            else {
                                mapBundleLinesByLineNo = new Map<Integer, Sales_Invoice_Line__c>();
                                mapBundleLinesByLineNoByTaskLineNo.put(newInvoiceLine.Sales_Invoice_Job_Task__r.Line_No__c.intValue(), mapBundleLinesByLineNo);
                            }
                            mapBundleLinesByLineNo.put(newInvoiceLine.Line_No__c.intValue(), newInvoiceLine);
                            //ticket 20551 >>
                        }
                        else {
                            salesInvoiceLines.add(newInvoiceLine);
                        }

                        newInvoiceLine.Sales_Invoice__c = newSalesInvoice.Id;
                        newInvoiceLine.Quantity__c = -CompanyMgmt.zeroIfNull(newInvoiceLine.Quantity__c);
                        newInvoiceLine.Line_Amount__c = -CompanyMgmt.zeroIfNull(newInvoiceLine.Line_Amount__c);
                        newInvoiceLine.xLine_Amount__c = -CompanyMgmt.zeroIfNull(newInvoiceLine.xLine_Amount__c);
                        newInvoiceLine.Tax__c = -CompanyMgmt.zeroIfNull(newInvoiceLine.Tax__c);
                        newInvoiceLine.Line_Amt_Incl_Tax__c = -CompanyMgmt.zeroIfNull(newInvoiceLine.Line_Amt_Incl_Tax__c);

                        if (newInvoiceLine.Sales_Invoice_Job_Task__r != null && newInvoiceLine.Sales_Invoice_Job_Task__r.Line_No__c != null) {
                            Integer jobTaskLineNo = newInvoiceLine.Sales_Invoice_Job_Task__r.Line_No__c.intValue();
                            if (mapNewJobTaskByLineNo.containsKey(jobTaskLineNo)) {
                                Sales_Invoice_Job_Task__c newJobTask = mapNewJobTaskByLineNo.get(jobTaskLineNo);
                                newInvoiceLine.Sales_Invoice_Job_Task__c = newJobTask.Id;
                                //ticket 20551 <<
                                //newInvoiceLine.Sales_Invoice_Job_Task__r = new Sales_Invoice_Job_Task__c(Id = newJobTask.Id);
                                newInvoiceLine.Sales_Invoice_Job_Task__r = new Sales_Invoice_Job_Task__c(Id = newJobTask.Id, Line_No__c = newJobTask.Line_No__c);
                                //ticket 20551 >>
                            }
                        }
                    }
                    //ticket 20551 <<
                    //insert mapBundleLinesByLineNo.values();
                    List<Sales_Invoice_Line__c> bundleLinesToInsert = new List<Sales_Invoice_Line__c>();
                    for (Map<Integer, Sales_Invoice_Line__c> mapBundleLinesByLineNo : mapBundleLinesByLineNoByTaskLineNo.values()) {
                        for (Sales_Invoice_Line__c bundleLine : mapBundleLinesByLineNo.values()) {
                            bundleLinesToInsert.add(bundleLine);
                        }
                    }
                    insert bundleLinesToInsert;
                    //ticket 20551 >>

                    //link bundled lines
                    for (Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
                        if (salesInvoiceLine.Bundle_Line__r != null) {
                            //ticket 20551 <<
                            /*
                            Integer bundleLineNo = salesInvoiceLine.Bundle_Line__r.Line_No__c.intValue();
                            if (mapBundleLinesByLineNo.containsKey(bundleLineNo)) {
                                Sales_Invoice_Line__c bundleLine = mapBundleLinesByLineNo.get(bundleLineNo);
                                salesInvoiceLine.Bundle_Line__c = bundleLine.Id;
                                salesInvoiceLine.Bundle_Line__r = null;
                            }
                            */
                            Integer taskLineNo = salesInvoiceLine.Sales_Invoice_Job_Task__r.Line_No__c.intValue();
                            Integer bundleLineNo = salesInvoiceLine.Bundle_Line__r.Line_No__c.intValue();
                            if (mapBundleLinesByLineNoByTaskLineNo.containsKey(taskLineNo)) {
                                Map<Integer, Sales_Invoice_Line__c> mapBundleLinesByLineNo = mapBundleLinesByLineNoByTaskLineNo.get(taskLineNo);
                                if (mapBundleLinesByLineNo.containsKey(bundleLineNo)) {
                                    Sales_Invoice_Line__c bundleLine = mapBundleLinesByLineNo.get(bundleLineNo);
                                    salesInvoiceLine.Bundle_Line__c = bundleLine.Id;
                                    salesInvoiceLine.Bundle_Line__r = null;
                                }
                            }
                            //ticket 20551 >>
                        }
                    }
                    insert salesInvoiceLines;
                }

                // Update current SI

                //ticket 24187 <<
                //retrieve the sales invoice fields again to get the updated Reversed__c value to prevent multiple credit memos issues if user open the reverse page across multiple browser tabs.
                Set<Id> salesInvoiceIds = new Set<Id>{ this.controller.getId() };
                this.salesInvoice = SalesInvoicesSelector.newInstance().selectById(salesInvoiceIds)[0];
                if (this.salesInvoice.Reversed__c == true) {
                    throw new DataException('The sales invoice has already been reversed.');
                }
                //ticket 24187 >>

                this.salesInvoice.Reversed__c = true;
                this.salesInvoice.Reversed_by_CM_No__c = newSalesInvoice.Id;
                this.salesInvoice.Credit_Memo_Reason_Code__c = null;
                update this.salesInvoice;

                PageReference InvoicePage = new PageReference('/' + newSalesInvoice.Id);
                InvoicePage.setRedirect(true);
                return InvoicePage;
            } catch (exception e) {
                //ticket 24187 <<
                Database.rollback(sp);
                //ticket 24187 >>
                System.debug('Error: ' + e.getCause());
                System.debug('Error: ' + e.getStackTraceString());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));
                return null;
            }
        }
    }
}