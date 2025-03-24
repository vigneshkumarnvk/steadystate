/*************************************************************************************************
* Name         :  PrintSalesInvoiceConfirmationController
*
*
* Modification Log :
* Developer                 Date                   Description
* ---------------------------------------------------------------------------------------------------------------------
* Prabhu Rathakrishnan      12-14-2023             Task75275: Salesforce - Remove or disable the below on the Sales Invoice Object
*************************************************************************************************/
public with sharing class PrintSalesInvoiceConfirmationController {
    private final ApexPages.StandardController controller;
    public Sales_Invoice__c salesInvoice { get; set; }
    public String selPrintCopy { get; set; }
    public String selInvoiceType { get; set; }
    public List<Sales_Invoice_Job_Task__c> jobTasks { get; set; }

    public PrintSalesInvoiceConfirmationController(ApexPages.StandardController controller) {
        this.controller = controller;
        Set<Id> salesInvoiceIds = new Set<Id>{ this.controller.getId() };
        List<Sales_Invoice__c> salesInvoices = SalesInvoicesSelector.newInstance().selectById(salesInvoiceIds);
        if (salesInvoices.size() > 0) {
            this.salesInvoice = salesInvoices[0];
            this.jobTasks = SalesInvoiceJobTasksSelector.newInstance().selectBySalesInvoiceId(salesInvoiceIds);
           // validatePrintDocumentEligibility();
            for (Sales_Invoice_Job_Task__c jobTask : this.jobTasks) {
                if (jobTask.Invoice_Format__c == null) {
                    jobTask.Invoice_Format__c = 'Detail';
                }
            }
        }
        else {
            this.salesInvoice = new Sales_Invoice__c();
            this.jobTasks = new List<Sales_Invoice_Job_Task__c>();
        }
    }
    public void validatePrintDocumentEligibility(){
       /* if(this.salesInvoice.Service_Center__r.Include_SO_in_EQAI_Invoice_Integration__c){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Print Document function has been disabled for this Service Center'));
        }*/
    }

    public PageReference PrintNewSalesInvoice() {
        CompanyMgmt.byPassTrigger = true;
        update this.jobTasks;
		checkPrintingOrder();

        //ticket 19631 <<
        //PageReference redirectPage = new PageReference('/apex/NewSalesInvoicePdf?id=' + this.controller.getId() + '&PrintCopy=' + selPrintCopy + '&InvoiceType=' + selInvoiceType);
        //ticket 19127 <<
        //PageReference redirectPage = new PageReference('/apex/NewSalesInvoicePdf?id=' + this.controller.getId() + '&PrintCopy=' + selPrintCopy + '&InvoiceType=' + selInvoiceType + '&nonbillable=' + this.printNonBillableLines);
        PageReference redirectPage = new PageReference('/apex/NewSalesInvoicePdf?id=' + this.controller.getId() + '&PrintCopy=' + selPrintCopy);
        //ticket 19127 >>
        //ticket 19631 >>
        redirectPage.setRedirect(true);
        return redirectPage;
    }
    
    public String title {
        get {
            if (this.controller.getId() == null) {
                return 'New Invoice';
            } else {
                return this.salesInvoice.Name;
            }
        }
    }

    /*
     *  Ticket#20402 check printing order - prevent duplicate printer order.
     */
    private void checkPrintingOrder(){
        Set<Decimal> printOrders = new Set<Decimal>();
        for(Sales_Invoice_Job_Task__c salesInvoiceJobTask : this.jobTasks){
            if(salesInvoiceJobTask.Print_Order__c != null) {
                if (printOrders.contains(salesInvoiceJobTask.Print_Order__c)) {
                    throw new DataException('ERROR: There are more than one job task assigned with Print Order ' + salesInvoiceJobTask.Print_Order__c + ', please update the print order to continue!');
                } else {
                    printOrders.add(salesInvoiceJobTask.Print_Order__c);
                }
            }
        }
    }
}