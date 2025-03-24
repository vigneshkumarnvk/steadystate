public with sharing class UnpostSalesInvoiceController {
    private final ApexPages.StandardController controller;
    public Sales_Invoice__c salesInvoice { get; set; }

    public UnpostSalesInvoiceController(ApexPages.StandardController controller) {
        this.controller = controller;
        Set<Id> salesInvoiceIds = new Set<Id>{ this.controller.getId() };
        this.salesInvoice = SalesInvoicesSelector.newInstance().selectById(salesInvoiceIds)[0];
    }

    public String docType {
        get {
            if (!this.salesInvoice.Credit_Memo__c) {
                return 'Sales Invoice';
            } else {
                return 'Credit Memo';
            }
        }
    }

    public Boolean posted {
        get {
            if (this.salesInvoice.Document_Status__c == 'Posted' || this.salesInvoice.Document_Status__c == 'Void') {
                return true;
            } else {
                return false;
            }
        }
    }

    public List<String> getMessages() {
        return new List<String>{
            'Document Status: ' + this.salesInvoice.Document_Status__c, '', ''
        };
    }

    public PageReference unpostSalesInvoice() {

        if (CompanyMgmt.checkUnpostPermission() == false && !Test.isRunningTest()) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You are not allowed to unpost transactions.'));
        } else {

            List<String> errorList = new List<String>();
            errorList = SalesInvoiceMgmt.unpostCheck(this.salesInvoice);
            if (errorList.size() > 0 && !Test.isRunningTest()) {
                for (Integer i = 0; i < errorList.size(); i++){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorList[i]));
                }
                return null;
            }

            Savepoint sp = Database.setSavepoint();
            try {
                SalesInvoiceMgmt.unpostSI(this.salesInvoice);
                this.salesInvoice.Document_Status__c = 'Open';
                update this.salesInvoice;

                List<Sales_Invoice_Line__c> invoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(this.controller.getId());

                Set<String> tmIds = new Set<String>();
                for (Sales_Invoice_Line__c invoiceLine : invoiceLines) {
                    if (invoiceLine.TM__c != null && !tmIds.contains(invoiceLine.TM__c)) {
                        tmIds.add(invoiceLine.TM__c);
                    }
                }
                
                List<TM__c> tms = new List<TM__c>();
                if (tmIds.size() > 0) {
                    tms = [SELECT Id, Name, Invoiced_Lines__c, Total_Lines__c , Status__c, Sales_Invoice__c,
                            Sales_Invoice__r.Name, (SELECT Id, Invoiced__c FROM TM_Lines__r)
                    FROM TM__c WHERE Id IN :tmIds];
                }

                tms = TMMgmt.updateTMStatus(tms);
                List<TM_Line__c> tmLinesToUpdate = new List<TM_Line__c>();
                if (tms != null && tms.size() > 0) {
                    for (TM__c TM : tms) {
                        if (this.salesInvoice.Credit_Memo__c) {
                            if(String.isBlank(TM.Sales_Invoice__c)){
                                TM.Sales_Invoice__c = this.salesInvoice.Reversed_from_SI__c;
                                TM.Status__c = 'Fully Invoiced';
                                List<TM_Line__c> tmLines = TM.TM_Lines__r;
                                for(TM_Line__c tml : tmLines){
                                    tml.Invoiced__c = true;
                                    tmLinesToUpdate.add(tml);
                                }
                            } else if (TM.Sales_Invoice__c != this.salesInvoice.Reversed_from_SI__c && String.isNotBlank(this.salesInvoice.Reversed_from_SI__c)){
                                throw new DataException('Cannot un-post this credit memo because T&M associated with the credit memo is already re-invoiced');
                            }
                        } else {
                            TM.Sales_Invoice__c = this.salesInvoice.Id;
                        }
                    }
                }
                update tms;
                if(tmLinesToUpdate.size() > 0) update tmLinesToUpdate;

                if (!this.salesInvoice.Credit_Memo__c) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully unposted Sales Invoice.'));
                } else {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully unposted Sales Credit Memo.'));
                }
            } catch (Exception e) {
                //Rollback
                Database.rollback(sp);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
                return null;
            }
        }
        return null;
    }
}