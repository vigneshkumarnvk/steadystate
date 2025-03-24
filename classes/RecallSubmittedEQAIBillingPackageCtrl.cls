/******************************************************************************************************
* Class Name: RecallSubmittedEQAIBillingPackageCtrl
* Description: This class is utilized by the RecallSubmittedEQAIBillingPackageRequest LWC to create a case record for
                System Admin to recall the EQAI Billing Package for related Sales Invoice.
* ***************************************************************************************************
* Owner		        Task #			Date		Description
* Andrew Simons     82347           4/1/2024    Initial implementation
* Andrew Simons     84318           4/9/2024    added salesforce support record type
* ******************************************************************************************************/

public with sharing class RecallSubmittedEQAIBillingPackageCtrl {

    @AuraEnabled
    public static String createCaseRecord(Id invoiceId){

        Sales_Invoice__c salesInvoice = [SELECT Id, Name, Recall_Submitted_EQAI_BPR_clicked__c  FROM Sales_Invoice__c WHERE Id = :invoiceId];
        Group caseOwners = [SELECT Id FROM Group WHERE type='Queue' AND DeveloperName = 'Case_Owners'];
        RecordType salesforceSupport = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND DeveloperName = 'Case_Record' LIMIT 1];

        if(!salesInvoice.Recall_Submitted_EQAI_BPR_clicked__c) {
            System.debug(invoiceId);
            Case newCase = new Case();
            newCase.Reason = 'Recall EQAI Billing Package';
            newCase.Priority = 'Medium';
            newCase.Billing_Package_Number__c = salesInvoice.Name;
            newCase.OwnerId = caseOwners.Id;
            newCase.Subject = 'Recall Billing Package Number '+salesInvoice.Name;
            newCase.Description = 'Recall Billing Package Number '+salesInvoice.Name;
            newCase.Billing_Package__c = salesInvoice.Id;
            newCase.RecordTypeId = salesforceSupport.Id;
            insert newCase;

            salesInvoice.Recall_Submitted_EQAI_BPR_clicked__c = true;
            update salesInvoice;

            return 'Success';
        } else {
            return 'Exists';
        }

    }
}
