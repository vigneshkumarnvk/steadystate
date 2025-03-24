/******************************************************************************************************
* Class Name: RecallEQAIBillingPackageCtrl
* Description: This class is utilized by the RecallEQAIBillingPackage LWC to update the Sales Invoice Document Status to 'Open'
* ***************************************************************************************************
* Owner		        Task #			Date		Description
* Andrew Simons           82347             4/1/2024         Initial implementation
* ******************************************************************************************************/

public with sharing class RecallEQAIBillingPackageCtrl {
    
    @AuraEnabled
    public static String updateDocumentStatus(Id invoiceId) {

        Sales_Invoice__c salesInvoice = [SELECT Id, Name, Recall_Submitted_EQAI_BPR_clicked__c, Recall_EQAI_Billing_Package_clicked__c, Document_Status__c  FROM Sales_Invoice__c WHERE Id = :invoiceId];

        if(salesInvoice.Document_Status__c == 'Sent to EQAI' && salesInvoice.Recall_Submitted_EQAI_BPR_clicked__c) {
            salesInvoice.Document_Status__c = 'Open';

            salesInvoice.Recall_EQAI_Billing_Package_clicked__c = true;
            //reset the button clicked status
            salesInvoice.Recall_Submitted_EQAI_BPR_clicked__c = false;
            update salesInvoice;
        }
        return 'Open';
    }
}
