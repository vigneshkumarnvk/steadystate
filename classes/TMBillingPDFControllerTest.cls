@IsTest
private class TMBillingPDFControllerTest {
    @IsTest
    static void testBehavior() {
        NewTestData.createTestData();
        Test.startTest();
        TM__c tm = NewTestData.mapTMsByName.get(NewTestData.TEST_TM_NAME_01);
        Sales_Order__c salesOrder = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SO_NAME_01);
        Resource_Type__c resourceType = NewTestData.mapResourceTypesByName.get(NewTestData.RESOURCE_TYPE_SC_RATESHEET);
        Resource__c resource = NewTestData.mapResourceByName.get(NewTestData.RESOURCE_TYPE_SC_RATESHEET);
        TM_Line__c tmLine = new TM_Line__c();
        tmLine.TM__c = tm.Id;
        //tmLine.TM_Job_Task__c = jobTask.Id;
        //ticket 19130 <<
        //tmLine.Line_No__c = 6;
        tmLine.Line_No__c = 7;
        //ticket 19130 >>
        tmLine.Category__c = ResourceService.MATERIALS_CATEGORY;
        //tmLine.Resource_Type__c = resourceType.Id;
       // tmLine.Resource__c = resource.Id;
        tmLine.Unit_of_Measure__c = resourceType.Unit_of_Measure__c;
        tmLine.Quantity__c = 1;
        tmLine.Description__c = resourceType.Name;
        tmLine.Job_Start_Time__c = salesOrder.Estimated_Job_Start_Time__c;
        tmLine.Job_End_Time__c = salesOrder.Estimated_Job_End_Time__c;
        insert tmLine;
        PageReference pdfPage = Page.NewTMBillingPDF;
        Test.setCurrentPage(pdfPage);
        ApexPages.currentPage().getParameters().put('id', tm.Id);
        TMBillingPDFController billingPDFController = new TMBillingPDFController();

        Test.stopTest();
    }
    //test
}