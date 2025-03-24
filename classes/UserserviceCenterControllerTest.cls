@isTest
private class UserserviceCenterControllerTest {
    private static testMethod void test() {
        Subsidiary_Company__c company = new Subsidiary_Company__c(Name = '1-REPUBLIC SERVICES');
        insert company;
        
        Service_Center__c serviceCenter = new Service_Center__c(Subsidiary_Company__c= company.Id, Name = '01', Code__c = '01');
        insert serviceCenter;
        
        User_Service_Center__c usc = new User_Service_Center__c(Name = '01', User__c = userInfo.getUserId(), Service_Center__c = serviceCenter.Id);
        insert usc;
        
        UserServiceCenterController.getUser(userInfo.getUserId());
        String JSONUserServiceCenters  = UserServiceCenterController.getUserServiceCenters(userInfo.getUserId());
        UserServiceCenterController.saveUserServiceCenters(userInfo.getUserId(), JSONUserServiceCenters);
        
        UserServiceCenterController.deleteUserServiceCenter(usc.Id);
    
    }

}