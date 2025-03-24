public with sharing class VoidSalesInvoiceController {
    private final ApexPages.StandardController controller;
    public Sales_Invoice__c salesInvoice { get; set; }

    public VoidSalesInvoiceController(ApexPages.StandardController controller) {
        this.controller = controller;
        Set<Id> salesInvoiceIds = new Set<Id>{ this.controller.getId() };
        this.salesInvoice = SalesInvoicesSelector.newInstance().selectById(salesInvoiceIds)[0];
    }

    public String docType {
        get {
            if (!this.salesInvoice.Credit_Memo__c) {
                return 'Billing Package';
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

    public PageReference voidSalesInvoice(){
        Set<string> setTM = new Set<string>();
        Set<string> setTML = new Set<string>();
        List<TM_Line__c> theTMLineList = new List<TM_Line__c>();
        List<TM_Line__c> zeroQtylaborLines = new List<TM_Line__c>(); //Ticket#24285
        // To differentiate from standard edit page
        CompanyMgmt.systemCall = true;

        if (this.salesInvoice.Document_Status__c != 'Open') {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'System can only void Open Billing Packages! + Billing Package Status is: ' + this.salesInvoice.Document_Status__c));
            return null;
        }

        // Savepoint
        Savepoint sp = Database.setSavepoint();

        try {
            //Set Sales Invoice to Void
            this.salesInvoice.Document_Status__c = 'Void';

            //Retainage Invoice
            if(this.salesInvoice.Credit_Memo__c != true){
                List<Retainage_Ledger_Entry__c> retainageLedgerEntries = new List<Retainage_Ledger_Entry__c>();
                if(this.salesInvoice.Retainage_Invoice__c == true){
                    retainageLedgerEntries = [SELECT Id, Invoiced__c, Closed_By_Invoice_No__c FROM Retainage_Ledger_Entry__c WHERE Closed_By_Invoice_No__c = :this.salesInvoice.Id LIMIT 1];
                    if(retainageLedgerEntries.size() > 0){
                        retainageLedgerEntries[0].Invoiced__c = false;
                        retainageLedgerEntries[0].Closed_By_Invoice_No__c = null;
                        update retainageLedgerEntries;
                    }
                } else {
                    retainageLedgerEntries = [SELECT Id FROM Retainage_Ledger_Entry__c WHERE Sales_Invoice__c = :this.salesInvoice.Id LIMIT 1];
                    if(retainageLedgerEntries.size() > 0){
                        delete retainageLedgerEntries;
                    }
                }
            } else {
                List<Retainage_Ledger_Entry__c> retainageLedgerEntries = new List<Retainage_Ledger_Entry__c>();
                if(this.salesInvoice.Reversed_from_SI__r.Retainage_Invoice__c == true){
                    retainageLedgerEntries = [SELECT Id, Sales_Invoice__r.Name, Closed_By_Invoice_No__c, Closed_By_Invoice_Reversed_By__c
                    FROM Retainage_Ledger_Entry__c
                    WHERE Closed_By_Invoice_Reversed_By__c = :this.salesInvoice.Id];
                    if(retainageLedgerEntries.size() > 0){
                        if(String.isNotBlank(retainageLedgerEntries[0].Closed_By_Invoice_No__c)){
                            throw new DataException('Credit Memo cannot be void! Retainage invoice already been created for Billing Package# ' + retainageLedgerEntries[0].Sales_Invoice__r.Name);
                        } else {
                            retainageLedgerEntries[0].Closed_By_Invoice_No__c = this.salesInvoice.Reversed_from_SI__c;
                            retainageLedgerEntries[0].Invoiced__c = true;
                            retainageLedgerEntries[0].Closed_By_Invoice_Reversed_By__c = null;
                            update retainageLedgerEntries;
                        }
                    }
                }
            }
            //Retainage Invoice

            if (this.salesInvoice.Credit_Memo__c) {
                if (this.salesInvoice.Reversed_from_SI__c != null){
                    Sales_Invoice__c theReversedFromSI = [SELECT Id, Name FROM Sales_Invoice__c WHERE Id = :this.salesInvoice.Reversed_from_SI__c];
                    theReversedFromSI.Reversed_by_CM_No__c = null;
                    theReversedFromSI.Reversed__c = false;
                    update theReversedFromSI;
                    this.salesInvoice.Reversed_from_SI__c = null;
                }
            }

            //Changed Void Sales Invoice Number
            this.salesInvoice.Name = 'VOID-' + this.salesInvoice.Name + '-' + this.salesInvoice.Id;

            update this.salesInvoice;


            List<Sales_Invoice_Job_Task__c> jobTasks = SalesInvoiceJobTasksSelector.newInstance().selectBySalesInvoiceId(new Set<Id>{ this.controller.getId() });
            List<Sales_Invoice_Line__c> invoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(this.controller.getId());

            for (Sales_Invoice_Job_Task__c jobTask : jobTasks) {
                jobTask.Voided__c = true;
            }
            update jobTasks;

            //Update T&M: set T&M status to Ready to Bill
            if (!this.salesInvoice.Credit_Memo__c){
                List<TM__c> theTMList = new List<TM__c>();
                Map<Id, Billing_Worksheet_Line__c> mapWorksheetLinesById = new Map<Id, Billing_Worksheet_Line__c>();
                if (invoiceLines != null && invoiceLines.size() > 0) {
                    for (Sales_Invoice_Line__c invoiceLine : invoiceLines) {
                        if (invoiceLine.TM__c != null && !setTM.contains(invoiceLine.TM__c)) {
                            setTM.add(invoiceLine.TM__c);
                        }
                        if (invoiceLine.TM_Line__c != null && !setTML.contains(invoiceLine.TM_Line__c)) {
                            setTML.add(invoiceLine.TM_Line__c);
                        }
                        if (invoiceLine.Billing_Worksheet_Line__c != null) {
                            //mapWorksheetLinesById.put(invoiceLine.Billing_Worksheet_Line__c, new Billing_Worksheet_Line__c(Id = invoiceLine.Billing_Worksheet_Line__c, Invoiced__c = false, To_Invoice__c = false));
                            //retain To Invoice flag
                            mapWorksheetLinesById.put(invoiceLine.Billing_Worksheet_Line__c, new Billing_Worksheet_Line__c(Id = invoiceLine.Billing_Worksheet_Line__c, Invoiced__c = false));
                        }
                    }

                    if (setTM.size() > 0) {
                        theTMList = [SELECT Id, Name, Status__c FROM TM__c WHERE Id IN:setTM];
                        if (theTMList != null && theTMList.size() > 0) {
                            for (TM__c TM : theTMList) {
                                TM.Status__c = 'Confirmed';
                                TM.Sales_Invoice__c = null;
                            }
                        }
                        theTMLineList = [SELECT Id, Name, Invoiced__c, To_Invoice__c, Sales_Invoice_Line__c FROM TM_Line__c WHERE Id IN:setTML];
                        if (theTMLineList != null && theTMLineList.size() > 0) {
                            for (TM_Line__c TML : theTMLineList) {
                                //retain To Invoice flag
                                //TML.To_Invoice__c = false;
                                TML.Invoiced__c = false;
                                TML.Sales_Invoice_Line__c = null;
                            }
                        }

                        //Ticket#24285 >>
                        zeroQtylaborLines = [SELECT Id, Invoiced__c, Sales_Invoice_Line__c FROM TM_Line__c WHERE TM__c IN :setTM AND Category__c = 'Labor' AND Quantity__c = 0];
                        for(TM_Line__c tmLine : zeroQtylaborLines){
                            tmLine.Invoiced__c = false;
                            tmLine.Sales_Invoice_Line__c = null;
                        }
                        //Ticket#24285 <<
                    }
                }

                //worksheet lines update need to happen before T&M update
                if (mapWorksheetLinesById.size() > 0) {
                    BillingWorksheetController.ByPassTrigger = true;
                    CompanyMgmt.systemCall = true;
                    update mapWorksheetLinesById.values();
                    BillingWorksheetController.ByPassTrigger = false;
                }

                //job task <<
                SalesInvoiceTriggersMgmt.updateTMInvoiceRelations(invoiceLines);
                //job task >>


                // Update T&M
                //handle old invoices which don't have billing worksheet lines <<
                /*
                CompanyMgmt.byPassTrigger = true;
                update theTMList;
                update theTMLineList;
                CompanyMgmt.byPassTrigger = false;
                */

                CompanyMgmt.byPassTrigger = true;
                CompanyMgmt.byPassLineTrigger = true;
                update theTMLineList;
                //Ticket#24285 >>
                if(zeroQtylaborLines.size() > 0){
                    update zeroQtylaborLines;
                }
                //Ticket#24285 <<
                CompanyMgmt.byPassTrigger = false;
                CompanyMgmt.byPassLineTrigger = false;

                if (mapWorksheetLinesById.size() == 0) {
                    update theTMList; //let TMTrigger create billing worksheet lines
                }
                else {
                    CompanyMgmt.byPassTrigger = true;
                    update theTMList;
                    CompanyMgmt.byPassTrigger = false;
                }

                //handle old invoices which don't have billing worksheet lines >>

            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully voided the Billing Package'));
        } catch (Exception e) {
            // Rollback
            Database.rollback(sp);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        return null;
    }
}