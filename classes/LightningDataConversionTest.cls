@isTest
private class LightningDataConversionTest {
    private static testMethod void testCreateTMJobTasks() {
        NewTestData.createTestData();

        Test.startTest();
        LightningDataConversion.updateTMStatus(2);

        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM Billing_Worksheet_Line__c];
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM Sales_Invoice_Line__c];
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM Sales_Invoice_Job_Task__c];
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM TM_Job_Task__c];
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;
        LightningDataConversion.createTMJobTasks(2);
        Test.stopTest();
    }

    private static testMethod void testCreateSalesOrderJobTasks() {
        NewTestData.createTestData();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        delete [SELECT Id FROM Billing_Worksheet_Line__c];
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM Sales_Invoice_Line__c];
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        delete [SELECT Id FROM TM_Line__c WHERE TM__c = :tm.Id];
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM Sales_Invoice_Job_Task__c];
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM TM_Job_Task__c];
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM Sales_Order_Job_Task__c];
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;
        LightningDataConversion.createSalesOrderJobTasks(2);
        LightningDataConversion.insertEquipmentDetailLines(1000);
        Test.stopTest();
    }

    private static testMethod void testCreateSalesInvoiceJobTasks() {
        NewTestData.createTestData();

        Test.startTest();
        LightningDataConversion.createTMInvoiceRelations(2);
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM Sales_Invoice_Job_Task__c];
        LightningDataConversion.createSalesInvoiceJobTasks(2);
        Test.stopTest();
    }

    private static testMethod void testCreateBillingWorksheetLines() {
        NewTestData.createTestData();

        Test.startTest();
        CompanyMgmt.byPassTrigger = true;
        CompanyMgmt.byPassLineTrigger = true;
        delete [SELECT Id FROM Billing_Worksheet_Line__c];
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM Sales_Invoice_Line__c];
        CompanyMgmt.byPassTrigger = true;
        delete [SELECT Id FROM Sales_Invoice_Job_Task__c];
        CompanyMgmt.byPassTrigger = true;
        List<TM__c> tms = [SELECT Id FROM TM__c];
        for (TM__c tm : tms) {
            tm.Status__c = 'Confirmed';
        }
        update tms;
        CompanyMgmt.byPassTrigger = false;
        CompanyMgmt.byPassLineTrigger = false;

        LightningDataConversion.createBillingWorksheetLines(2);

        Test.stopTest();
    }

}