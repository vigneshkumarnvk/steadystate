@IsTest
private class SalesLinesTest {

    @IsTest
    private static void testUpdateSalesLinesForBillAsLumpSumAllAction(){
        // Create mocks.
        fflib_ApexMocks mocks = new fflib_ApexMocks();
        Sales_Order__c theSO = new Sales_Order__c(
                Id = fflib_IDGenerator.generate(Sales_Order__c.SObjectType),
                Tax_Liable__c = true
        );
        Sales_Line__c salesLine1 = new Sales_Line__c(
                Id = fflib_IDGenerator.generate(Sales_Line__c.SObjectType),
                Sales_Order__c = theSO.Id,
                Category__c = 'Labor',
                Tax_Group__c = 'TX'
        );
        Sales_Line__c salesLine2 = new Sales_Line__c(
                Id = fflib_IDGenerator.generate(Sales_Line__c.SObjectType),
                Sales_Order__c = theSO.Id,
                Category__c = 'Materials',
                Tax_Group__c = 'TX'
        );
        List<Sales_Line__c> theSLList = new List<Sales_Line__c>{salesLine1,salesLine2};
        SalesLines.mapSalesOrders.put(theSO.Id, theSO);
        ISalesLines salesLineDomain = SalesLines.newInstance(theSLList);
        salesLineDomain.updateSalesLinesForBillAsLumpSumAllAction();

    }
}