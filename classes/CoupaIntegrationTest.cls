@IsTest
private class CoupaIntegrationTest {
    /*
    @TestSetup
    static void initTestData(){
        Company_Setup__c companySetup = TestDataUtil.CompanySetupRecord;
    }
     */

    @IsTest
    static void testCallout(){
        Test.setMock(HttpCalloutMock.class, new CoupaResponseMock());
        HttpResponse res = CoupaIntegrationService.syncLookupValue('POST', 'Sales Order', 'SOABC', 'SOABC', true);
        //Integer coupaId = CoupaIntegrationService.getLookupValueByName('SO123123', '3');
        //CoupaIntegrationService.getPurchaseOrder();
    }
    @IsTest
    static void testGetLookupValueByNameCallout(){
        Test.setMock(HttpCalloutMock.class, new CoupaResponseMock());
        Integer coupaId = CoupaIntegrationService.getLookupValueByName('SO123123', '3');
    }
    @IsTest
    static void testGetPurchaseOrderCallout(){
        Test.setMock(HttpCalloutMock.class, new CoupaResponseMock());
        CoupaIntegrationService.getPurchaseOrder();
    }
}