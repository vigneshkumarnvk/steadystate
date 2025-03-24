@IsTest
private class SalesQuotePDFControllerTest {
    @IsTest
    static void testBehavior() {
        NewTestData.createTestData();
        Test.startTest();
        Sales_Order__c salesQuote = NewTestData.mapSalesOrdersByName.get(NewTestData.TEST_SQ_NAME);

        List<Sales_Line_Detail__c> salesLineDetails = new List<Sales_Line_Detail__c>();
        List<Sales_Line__c> salesLines = [SELECT Id, Category__c,  (SELECT Id FROM Sales_Line_Details__r) FROM Sales_Line__c WHERE Sales_Order__c = :salesQuote.Id];
        for (Sales_Line__c salesLine : salesLines) {
            if (salesLine.Category__c == 'Labor') {
                salesLine.Regular_Rate__c = 100;
                salesLine.Overtime_Rate__c = 100;
                salesLine.Premium_Rate__c = 100;
                for (Sales_Line_Detail__c salesLineDetail : salesLine.Sales_Line_Details__r) {
                    salesLineDetail.Regular_Hours__c =  1;
                    salesLineDetail.Overtime_Hours__c =  1;
                    salesLineDetail.Premium_Hours__c =  1;
                    salesLineDetails.add(salesLineDetail);
                }
            }
        }
        CompanyMgmt.byPassTrigger = true;
        update salesLines;
        CompanyMgmt.byPassTrigger = true;
        update salesLineDetails;

        PageReference quotePDFRef = Page.SalesQuotePDF;
        Test.setCurrentPage(quotePDFRef);
        quotePDFRef.getParameters().put('id', salesQuote.Id);
        quotePDFRef.getParameters().put('printEstimatedDuration', 'true');
        quotePDFRef.getParameters().put('download', 'true');

        ApexPages.StandardController StdCon = new ApexPages.StandardController(salesQuote);
        SalesQuotePDFController salesQuotePDFController = new SalesQuotePDFController(StdCon);
        quotePDFRef.getParameters().put('printType', 'Detail');
        quotePDFRef.getParameters().put('download', 'true');
        salesQuotePDFController = new SalesQuotePDFController(StdCon);

        quotePDFRef.getParameters().put('printType', 'Consolidated');
        quotePDFRef.getParameters().put('download', 'true');
        //duplicate sales lien for consolidate by description
        List<Sales_Line__c> existingSalesLines = SalesLinesSelector.newInstance().selectLinesBySalesOrderId(new Set<Id>{ salesQuote.Id });
        Sales_Line__c newSalesLine = existingSalesLines[0].clone(false, true);
        newSalesLine.Sales_Order__c = existingSalesLines[0].Sales_Order__c;
        newSalesLine.Sales_Order_Job_Task__c = existingSalesLines[0].Sales_Order_Job_Task__c;
        newSalesLine.Line_No__c = 100;
        insert newSalesLine;

        salesQuotePDFController = new SalesQuotePDFController(StdCon);
        Decimal subTotal = salesQuotePDFController.Subtotal;
        Decimal tax = salesQuotePDFController.Tax;
        Decimal total = salesQuotePDFController.Total;
        Test.stopTest();
    }
//test
}