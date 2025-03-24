@isTest
private class CustomerPortalControllerTest {

    private static testMethod void test() {
        SiteTestData.createData();
        
        CustomerPortalController.LoginInfo loginInfo = CustomerPortalController.login('kchen@micro-datanet.com', 'password');
        loginInfo = CustomerPortalController.checkSession(loginInfo.PortalLogin.Session_Token__c);
    }

}