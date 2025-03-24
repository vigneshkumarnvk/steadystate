@isTest
public with sharing class RecallEQAIBillingPackageTest {
    
    @isTest
    public static void RecallEQAIBillingPackageCtrlTest() {
        //test data

        NewTestData.createTestData();

        Test.startTest();
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
        salesInvoice.Document_Status__c = 'Sent to EQAI';
        salesInvoice.Recall_Submitted_EQAI_BPR_clicked__c = true;
        update salesInvoice;
        RecallEQAIBillingPackageCtrl.updateDocumentStatus(salesInvoice.Id);
        Test.stopTest();
    }

    @isTest
    public static void RecallSubmittedEQAIBillingPackageCtrlTest() {

        NewTestData.createTestData();

        Test.startTest();
        Sales_Invoice__c salesInvoice = NewTestData.mapSalesInvoicesByName.get('INVOICE01');
        salesInvoice.Document_Status__c = 'Sent to EQAI';
        salesInvoice.Recall_Submitted_EQAI_BPR_clicked__c = false;
        update salesInvoice;
        RecallSubmittedEQAIBillingPackageCtrl.createCaseRecord(salesInvoice.Id);
        Test.stopTest();
    }
}