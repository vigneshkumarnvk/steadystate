public with sharing class ACVSalesInvoiceController {


    @AuraEnabled
    public static String testStackCall() {
        return String.valueOf(Datetime.now());
    }

    @AuraEnabled
    public static String getSetupData() {
        try {
            SalesInvoiceSetupData setupData = new SalesInvoiceSetupData();
            User user = [SELECT Id, Name, Username, Super_User__c, Service_Center__c, Profile.Name FROM User WHERE Id = :UserInfo.getUserId()];
            setupData.CompanySetup = CompanyMgmt.getCompanySetup();
            setupData.User = user;

            return JSON.serialize(setupData);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String getSalesInvoice(Id salesInvoiceId) {
        try {
            Set<Id> salesInvoiceIds = new Set<Id>{ salesInvoiceId };
            List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectById(salesInvoiceIds);
            List<Sales_Invoice_Job_Task__c> salesInvoiceJobTasks = SalesInvoiceJobTasksSelector.newInstance().selectBySalesInvoiceId(salesInvoiceIds);
            List<Sales_Invoice_Line__c> salesInvoiceLines = SalesInvoiceLinesSelector.newInstance().selectByInvoiceId(salesInvoiceId);

            ACVSalesInvoiceWrapper salesInvoiceWrapper = new ACVSalesInvoiceWrapper(salesInvoices[0], salesInvoiceJobTasks, salesInvoiceLines);
            return JSON.serialize(salesInvoiceWrapper);
        }
        catch(Exception ex) {
            System.debug('Error: ' + ex.getStackTraceString());
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static void saveSalesInvoice(String JSONSalesInvoice, String JSONJobTaskWrappers) {
        try {
            Sales_Invoice__c salesInvoice = (Sales_Invoice__c)JSON.deserialize(JSONSalesInvoice, Sales_Invoice__c.class);
            List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers = (List<ACVSalesInvoiceJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesInvoiceJobTaskWrapper>.class);
            saveSalesInvoice(salesInvoice, jobTaskWrappers);
        }
        catch(Exception ex) {
                        system.debug('ex'+ex.getMessage());
		String errorMessage = ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')? ex.getMessage().substring( ex.getMessage().indexOf('FIELD_CUSTOM_VALIDATION_EXCEPTION,') + 'FIELD_CUSTOM_VALIDATION_EXCEPTION,'.length()): ex.getMessage();
		throw new AuraHandledException(errorMessage);        }
    }

    @AuraEnabled
    public static void postSalesInvoice(String JSONSalesInvoice, String JSONJobTaskWrappers) {
        try {
            Sales_Invoice__c salesInvoice = (Sales_Invoice__c)JSON.deserialize(JSONSalesInvoice, Sales_Invoice__c.class);
            List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers = (List<ACVSalesInvoiceJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesInvoiceJobTaskWrapper>.class);

            saveSalesInvoice(salesInvoice, jobTaskWrappers);

        }
        catch(Exception ex) {
            throw new DataException(ex.getMessage());
        }
    }

    private static void saveSalesInvoice(Sales_Invoice__c salesInvoice, List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers) {
        Company_Setup__c defaultCompanySetup = CompanySettingUtil.defaultCompanySetup;
        if(salesInvoice.Misc_Invoice__c == true) {
            CompanyMgmt.systemCall = true;
        }
        Savepoint sp = Database.setSavepoint();
        try {

            //Ticket#22853 >>
            if(salesInvoice.Id != null){
                List<Sales_Invoice__c> salesInvoices = [SELECT Id, Document_Status__c, LastModifiedDate FROM Sales_Invoice__c WHERE Id = :salesInvoice.Id];
                if(salesInvoices.size() > 0 && salesInvoices[0].Document_Status__c != salesInvoice.Document_Status__c){
                    throw new DataException('There is a newer version of the invoice in the database.  Please refresh the page to retrieve the updated invoice record!');
                }

                if(salesInvoice.LastModifiedDate < salesInvoices[0].LastModifiedDate) {
                    throw new DataException('Sales Invoice have been modified after you retrieved the data. Please refresh page and try again.');
                }

                Map<Id, Datetime> invoiceLineModifiedDatesByIds = new Map<Id, Datetime>();
                for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (Sales_Invoice_Line__c salesInvoiceLine : jobTaskWrapper.SalesInvoiceLines) {
                        invoiceLineModifiedDatesByIds.put(salesInvoice.Id, salesInvoiceLine.LastModifiedDate);
                    }
                }
                List<Sales_Invoice_Line__c> existingInvoiceLines = [SELECT Id, LastModifiedDate FROM Sales_Invoice_Line__c WHERE Id IN :invoiceLineModifiedDatesByIds.keySet()];
                for(Sales_Invoice_Line__c salesInvoiceLine : existingInvoiceLines){
                    if(invoiceLineModifiedDatesByIds.containsKey(salesInvoiceLine.Id) &&
                            invoiceLineModifiedDatesByIds.get(salesInvoiceLine.Id) < salesInvoiceLine.LastModifiedDate){
                        throw new DataException('Sales Invoice lines have been modified after you retrieved the data. Please refresh page and try again.');
                    }
                }
            }
            //Ticket#22853 <<

            if (salesInvoice.Document_Status__c == 'Posted') {
                //Save Invoice header information after document is posted.
                //AR Collection purpose fields: SPO No. Expected Payment Date and Corrected Customer PO No.
                update salesInvoice;

                //ticket 19631 <<
                List<Sales_Invoice_Line__c> salesInvoiceLinesToUpdate = new List<Sales_Invoice_Line__c>();
                for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (Sales_Invoice_Line__c salesInvoiceLine : jobTaskWrapper.SalesInvoiceLines) {
                        Sales_Invoice_Line__c salesInvoiceLineToUpdate = new Sales_Invoice_Line__c();
                        salesInvoiceLineToUpdate.Id = salesInvoiceLine.Id;
                        salesInvoiceLineToUpdate.Print_Line__c = salesInvoiceLine.Print_Line__c;
                        salesInvoiceLinesToUpdate.add(salesInvoiceLineToUpdate);
                    }
                }
                CompanyMgmt.byPassTrigger = true;
                update salesInvoiceLinesToUpdate;
                //ticket 19631 >>
            } else {

                //Ticket#20293 >>
                if(salesInvoice.Id != null) {
                    List<Sales_Invoice__c> salesInvoices = [SELECT Id, Document_Status__c FROM Sales_Invoice__c WHERE Id = :salesInvoice.Id];
                    if(salesInvoices.size() > 0 && salesInvoices[0].Document_Status__c != salesInvoice.Document_Status__c){
                        throw new DataException('There is a newer version of the invoice in the database.  Please refresh the page to retrieve the updated invoice record!');
                    }
                }
                //Ticket#20293 <<

                //Credit Memo created from Sales Order AKA Partial credit memo
                if (salesInvoice.Credit_Memo__c == true && salesInvoice.Misc_Invoice__c == true) {
                    if (String.isBlank(salesInvoice.Reversed_from_SI__c)) {
                        throw new DataException('Applies-to Invoice No. must not be blank for partial invoice!');
                    }
                }

                if (String.isNotBlank(salesInvoice.Bill_to_Customer__c)) {
                    List<Account> billToCusts = AccountsSelector.newInstance().selectById(new Set<Id>{
                            salesInvoice.Bill_to_Customer__c
                    });
                    if (billToCusts.size() > 0) {
                        if (String.isNotBlank(salesInvoice.Customer_PO_No__c)) {
                            AccountsService.validatePONumberFormat(billToCusts[0], salesInvoice.Customer_PO_No__c);
                        }
                    }
                }

                if (salesInvoice.Approval_Status__c == EnumUtil.ApprovalStatus.PENDING_APPROVAL.name()) {
                    throw new DataException('Invoice record cannot be modify, it is pending for approval!');
                }

                update salesInvoice;

                List<Sales_Invoice_Job_Task__c> salesInvoiceJobTasks = new List<Sales_Invoice_Job_Task__c>();
                List<Sales_Invoice_Line__c> salesInvoiceLines = new List<Sales_Invoice_Line__c>();

                //handle removed lines
                Set<Id> salesInvoiceLineIds = new Set<Id>();
                for (Sales_Invoice_Line__c salesInvoiceLine : [SELECT Id FROM Sales_Invoice_Line__c WHERE Sales_Invoice__c = :salesInvoice.Id]) {
                    salesInvoiceLineIds.add(salesInvoiceLine.Id);
                }

                for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    for (Sales_Invoice_Line__c salesInvoiceLine : jobTaskWrapper.SalesInvoiceLines) {
                        if (salesInvoiceLine.Sales_Invoice_Job_Task__c == null) {
                            throw new DataException('Sales lines must be associated with a job task.');
                        }
                        if (salesInvoiceLine.Id != null && salesInvoiceLineIds.contains(salesInvoiceLine.Id)) {
                            salesInvoiceLineIds.remove(salesInvoiceLine.Id);
                        }
                    }
                }

                if (salesInvoiceLineIds.size() > 0) {
                    delete [SELECT Id FROM Sales_Invoice_Line__c WHERE Id IN :salesInvoiceLineIds];
                }

                for (ACVSalesInvoiceJobTaskWrapper jobTaskWrapper : jobTaskWrappers) {
                    salesInvoiceJobTasks.add(jobTaskWrapper.JobTask);
                    for (Sales_Invoice_Line__c salesInvoiceLine : jobTaskWrapper.SalesInvoiceLines) {
                        //assign default resource to lump sum line if line's resource is blank
                        if(salesInvoiceLine.Category__c == ResourceService.LUMP_SUM_CATEGORY && String.isBlank(salesInvoiceLine.Resource__c)){
                            salesInvoiceLine.Resource__c = defaultCompanySetup.Default_Lump_Sum_Resource__c;
                        }

                        if(salesInvoiceLine.Category__c == ResourceService.SUBCONTRACTORS_CATEGORY && String.isBlank(salesInvoiceLine.Resource__c)){
                            salesInvoiceLine.Resource__c = defaultCompanySetup.Default_Subcontractor_Resource__c;
                        }
                        
                        salesInvoiceLines.add(salesInvoiceLine);
                    }
                }

                update salesInvoiceJobTasks;
                upsert salesInvoiceLines;

                if (salesInvoice.Misc_Invoice__c == true) {
                    Decimal appliedToBalance = 0;
                    Decimal creditAmountInclTax = 0;
                    List<Sales_Invoice__c> appliesToInvoices = new List<Sales_Invoice__c>();
                    if (String.isNotBlank(salesInvoice.Reversed_from_SI__c)) {
                        appliesToInvoices = [SELECT Id, Name, Balance__c FROM Sales_Invoice__c WHERE Id = :salesInvoice.Reversed_from_SI__c];
                        if (appliesToInvoices.size() > 0) {
                            appliedToBalance = appliesToInvoices[0].Balance__c;

                            for (Sales_Invoice_Line__c salesInvoiceLine : salesInvoiceLines) {
                                creditAmountInclTax = creditAmountInclTax + CompanyMgmt.zeroIfNull(salesInvoiceLine.Line_Amt_Incl_Tax__c);
                            }

                            creditAmountInclTax = Math.abs(creditAmountInclTax);
                            if (creditAmountInclTax > appliedToBalance) {
                                String message = 'Credit Memo amount: ' + creditAmountInclTax + ' is larger than remaining balance ' + appliedToBalance + ' on applies-to invoice# ' + appliesToInvoices[0].Name;
                                throw new DataException(message);
                            }
                        }
                    }
                }
            }
        } catch(Exception ex) {
            Database.rollback(sp);
            throw ex;
        }
    }

    @AuraEnabled
    public static String validateAppliesToDoc(String JSONSalesInvoice, String JSONJobTaskWrappers){
        try {
            Sales_Invoice__c salesInvoice = (Sales_Invoice__c)JSON.deserialize(JSONSalesInvoice, Sales_Invoice__c.class);
            List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers = (List<ACVSalesInvoiceJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesInvoiceJobTaskWrapper>.class);

            if(salesInvoice.Credit_Memo_Reason_Code__c == 'Customer is tax exempt') {
                String appliedToDocId = salesInvoice.Reversed_from_SI__c;
                List<Sales_Invoice__c> salesInvoices = [SELECT Id, Tax_Area__c, Invoice_Tax__c FROM Sales_Invoice__c WHERE Id = :appliedToDocId];
                if (salesInvoices.size() == 0) {
                    throw new DataException('The applies-to invoice is not found.');
                }

                Sales_Invoice__c appliesToInvoice = salesInvoices[0];
                SalesInvoicesService.reverseTaxAmount(appliesToInvoice, salesInvoice, jobTaskWrappers);
            }

            return JSON.serialize(jobTaskWrappers);
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String validatePaymentTerm(String JSONSalesInvoice){
        try {
            Sales_Invoice__c salesInvoice = (Sales_Invoice__c)JSON.deserialize(JSONSalesInvoice, Sales_Invoice__c.class);
            SalesInvoicesService.validatePaymentTerm(salesInvoice);
            return JSON.serialize(salesInvoice);
        } catch (Exception ex){
            throw new AuraHandledException(ex.getMessage());
        }
    }

    @AuraEnabled
    public static String calculateSalesInvoice(String JSONSalesInvoice, String JSONJobTaskWrappers) {
        try {
            Sales_Invoice__c salesInvoice = (Sales_Invoice__c)JSON.deserialize(JSONSalesInvoice, Sales_Invoice__c.class);
            List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers = (List<ACVSalesInvoiceJobTaskWrapper>)JSON.deserialize(JSONJobTaskWrappers, List<ACVSalesInvoiceJobTaskWrapper>.class);

            SalesInvoiceLinesService.calculateLineTotals(salesInvoice, jobTaskWrappers);
            return JSON.serialize(jobTaskWrappers);
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    private static void calculateSalesInvoice(Sales_Invoice__c salesInvoice, List<ACVSalesInvoiceJobTaskWrapper> jobTaskWrappers) {
        SalesInvoiceLinesService.calculateLineTotals(salesInvoice, jobTaskWrappers);
    }
}